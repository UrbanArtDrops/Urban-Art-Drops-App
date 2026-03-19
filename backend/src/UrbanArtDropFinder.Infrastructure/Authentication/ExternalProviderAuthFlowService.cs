using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using UrbanArtDropFinder.Application.Abstractions;
using UrbanArtDropFinder.Application.Auth;
using UrbanArtDropFinder.Contracts.Auth;
using UrbanArtDropFinder.Domain.Users;

namespace UrbanArtDropFinder.Infrastructure.Authentication;

public sealed class ExternalProviderAuthFlowService
{
    private const string PendingCachePrefix = "external-provider-auth:pending:";
    private const string CompletedCachePrefix = "external-provider-auth:completed:";
    private static readonly TimeSpan PendingSessionLifetime = TimeSpan.FromMinutes(10);

    private readonly ExternalProviderAuthenticationOptions _options;
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IMemoryCache _memoryCache;
    private readonly ITokenGenerator _tokenGenerator;
    private readonly AuthApplicationService _authApplicationService;
    private readonly IClock _clock;
    private readonly IHostEnvironment _hostEnvironment;
    private readonly ILogger<ExternalProviderAuthFlowService> _logger;

    public ExternalProviderAuthFlowService(
        IOptions<ExternalProviderAuthenticationOptions> options,
        IHttpClientFactory httpClientFactory,
        IMemoryCache memoryCache,
        ITokenGenerator tokenGenerator,
        AuthApplicationService authApplicationService,
        IClock clock,
        IHostEnvironment hostEnvironment,
        ILogger<ExternalProviderAuthFlowService> logger)
    {
        _options = options.Value;
        _httpClientFactory = httpClientFactory;
        _memoryCache = memoryCache;
        _tokenGenerator = tokenGenerator;
        _authApplicationService = authApplicationService;
        _clock = clock;
        _hostEnvironment = hostEnvironment;
        _logger = logger;
    }

    public BeginExternalProviderAuthResponse BeginLogin(
        BeginExternalProviderLoginRequest request,
        HttpRequest httpRequest)
    {
        var provider = ResolveProvider(request.Provider);
        var callbackUri = ValidateClientCallbackUri(request.CallbackUrl, httpRequest);
        var redirectUri = BuildProviderRedirectUri(provider, httpRequest);
        var state = _tokenGenerator.GenerateSecureToken();
        var codeVerifier = provider.UsePkce == true ? _tokenGenerator.GenerateSecureToken(64) : null;
        var expiresAtUtc = _clock.UtcNow.Add(PendingSessionLifetime);
        var pendingSession = new PendingExternalProviderAuthSession(
            Provider: request.Provider.Trim().ToLowerInvariant(),
            Mode: ExternalProviderAuthFlowMode.Login,
            CallbackUrl: callbackUri.ToString(),
            RedirectUri: redirectUri,
            State: state,
            CodeVerifier: codeVerifier,
            RequestedEmail: null,
            RequestedUserName: null,
            RequestedRole: null,
            ExpiresAtUtc: expiresAtUtc);

        _memoryCache.Set(
            PendingCachePrefix + state,
            pendingSession,
            expiresAtUtc);

        var authorizationUrl = BuildAuthorizationUrl(provider, pendingSession);
        return new BeginExternalProviderAuthResponse(authorizationUrl, expiresAtUtc);
    }

    public BeginExternalProviderAuthResponse BeginRegistration(
        BeginExternalProviderRegistrationRequest request,
        HttpRequest httpRequest)
    {
        var provider = ResolveProvider(request.Provider);
        var callbackUri = ValidateClientCallbackUri(request.CallbackUrl, httpRequest);
        var redirectUri = BuildProviderRedirectUri(provider, httpRequest);
        var state = _tokenGenerator.GenerateSecureToken();
        var codeVerifier = provider.UsePkce == true ? _tokenGenerator.GenerateSecureToken(64) : null;
        var expiresAtUtc = _clock.UtcNow.Add(PendingSessionLifetime);
        var pendingSession = new PendingExternalProviderAuthSession(
            Provider: request.Provider.Trim().ToLowerInvariant(),
            Mode: ExternalProviderAuthFlowMode.Register,
            CallbackUrl: callbackUri.ToString(),
            RedirectUri: redirectUri,
            State: state,
            CodeVerifier: codeVerifier,
            RequestedEmail: request.Email.Trim(),
            RequestedUserName: request.UserName.Trim(),
            RequestedRole: request.Role,
            ExpiresAtUtc: expiresAtUtc);

        _memoryCache.Set(
            PendingCachePrefix + state,
            pendingSession,
            expiresAtUtc);

        var authorizationUrl = BuildAuthorizationUrl(provider, pendingSession);
        return new BeginExternalProviderAuthResponse(authorizationUrl, expiresAtUtc);
    }

    public async Task<ExternalProviderCallbackResult> HandleCallbackAsync(
        HttpRequest httpRequest,
        CancellationToken cancellationToken)
    {
        var state = httpRequest.Query["state"].ToString().Trim();
        if (string.IsNullOrWhiteSpace(state))
        {
            return ExternalProviderCallbackResult.Failure("The external provider callback is missing the state parameter.");
        }

        if (!_memoryCache.TryGetValue(PendingCachePrefix + state, out PendingExternalProviderAuthSession? pendingSession) ||
            pendingSession is null)
        {
            return ExternalProviderCallbackResult.Failure("The external provider session is invalid or has expired.");
        }

        _memoryCache.Remove(PendingCachePrefix + state);

        AuthResult authResult;
        try
        {
            var error = httpRequest.Query["error"].ToString().Trim();
            if (!string.IsNullOrWhiteSpace(error))
            {
                var errorDescription = httpRequest.Query["error_description"].ToString().Trim();
                authResult = new AuthResult(
                    false,
                    string.IsNullOrWhiteSpace(errorDescription)
                        ? $"External provider sign-in failed: {error}."
                        : errorDescription);
            }
            else
            {
                var authorizationCode = httpRequest.Query["code"].ToString().Trim();
                if (string.IsNullOrWhiteSpace(authorizationCode))
                {
                    authResult = new AuthResult(false, "The external provider callback did not return an authorization code.");
                }
                else
                {
                    authResult = await ExchangeAndAuthenticateAsync(
                        pendingSession,
                        authorizationCode,
                        httpRequest,
                        cancellationToken);
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "External provider callback processing failed for provider {Provider}.", pendingSession.Provider);
            authResult = new AuthResult(false, "The external provider sign-in could not be completed.");
        }

        var completionSessionId = _tokenGenerator.GenerateSecureToken();
        _memoryCache.Set(
            CompletedCachePrefix + completionSessionId,
            authResult,
            _clock.UtcNow.Add(PendingSessionLifetime));

        var redirectUrl = QueryHelpers.AddQueryString(
            pendingSession.CallbackUrl,
            "provider_session",
            completionSessionId);
        return ExternalProviderCallbackResult.Success(redirectUrl);
    }

    public AuthResult? ConsumeCompletedAuthResult(string providerSessionId)
    {
        var normalizedSessionId = providerSessionId.Trim();
        if (string.IsNullOrWhiteSpace(normalizedSessionId))
        {
            return null;
        }

        if (!_memoryCache.TryGetValue(CompletedCachePrefix + normalizedSessionId, out AuthResult? result) || result is null)
        {
            return null;
        }

        _memoryCache.Remove(CompletedCachePrefix + normalizedSessionId);
        return result;
    }

    private async Task<AuthResult> ExchangeAndAuthenticateAsync(
        PendingExternalProviderAuthSession pendingSession,
        string authorizationCode,
        HttpRequest httpRequest,
        CancellationToken cancellationToken)
    {
        var provider = ResolveProvider(pendingSession.Provider);
        var tokenDocument = await ExchangeAuthorizationCodeAsync(
            provider,
            pendingSession,
            authorizationCode,
            cancellationToken);

        var accessToken = ReadJsonValue(tokenDocument.RootElement, provider.AccessTokenPath);
        var idToken = ReadJsonValue(tokenDocument.RootElement, provider.IdTokenPath);
        if (string.IsNullOrWhiteSpace(accessToken) && string.IsNullOrWhiteSpace(idToken))
        {
            return new AuthResult(false, "The external provider token response did not include an access token.");
        }

        JsonDocument? userInfoDocument = null;
        try
        {
            userInfoDocument = await TryReadUserInfoDocumentAsync(provider, accessToken, idToken, cancellationToken);
            if (userInfoDocument is null)
            {
                return new AuthResult(false, "The external provider did not return a usable identity payload.");
            }

            var providerSubject = ReadJsonValue(userInfoDocument.RootElement, provider.SubjectPath);
            if (string.IsNullOrWhiteSpace(providerSubject))
            {
                return new AuthResult(false, "The external provider identity does not expose a subject identifier.");
            }

            var providerEmail = ReadJsonValue(userInfoDocument.RootElement, provider.EmailPath);
            return pendingSession.Mode switch
            {
                ExternalProviderAuthFlowMode.Login => await _authApplicationService.LoginProviderAsync(
                    new LoginProviderRequest(
                        pendingSession.Provider,
                        providerSubject,
                        providerEmail ?? string.Empty),
                    cancellationToken),
                ExternalProviderAuthFlowMode.Register => await RegisterExternalAccountAsync(
                    pendingSession,
                    providerSubject,
                    providerEmail,
                    cancellationToken),
                _ => new AuthResult(false, "Unsupported external provider flow.")
            };
        }
        finally
        {
            userInfoDocument?.Dispose();
            tokenDocument.Dispose();
        }
    }

    private async Task<AuthResult> RegisterExternalAccountAsync(
        PendingExternalProviderAuthSession pendingSession,
        string providerSubject,
        string? providerEmail,
        CancellationToken cancellationToken)
    {
        var resolvedEmail = !string.IsNullOrWhiteSpace(providerEmail)
            ? providerEmail.Trim()
            : pendingSession.RequestedEmail;
        if (string.IsNullOrWhiteSpace(resolvedEmail) ||
            string.IsNullOrWhiteSpace(pendingSession.RequestedUserName) ||
            pendingSession.RequestedRole is null)
        {
            return new AuthResult(false, "Provider registration requires email, user name, and target role.");
        }

        return await _authApplicationService.RegisterProviderAsync(
            new RegisterProviderRequest(
                pendingSession.Provider,
                providerSubject,
                resolvedEmail,
                pendingSession.RequestedUserName,
                pendingSession.RequestedRole.Value),
            cancellationToken);
    }

    private async Task<JsonDocument> ExchangeAuthorizationCodeAsync(
        ExternalProviderDefinitionOptions provider,
        PendingExternalProviderAuthSession pendingSession,
        string authorizationCode,
        CancellationToken cancellationToken)
    {
        var formFields = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["grant_type"] = "authorization_code",
            ["code"] = authorizationCode,
            ["redirect_uri"] = pendingSession.RedirectUri,
            [provider.ClientIdParameterName] = provider.ClientId!
        };

        if (!string.IsNullOrWhiteSpace(provider.ClientSecret))
        {
            formFields[provider.ClientSecretParameterName] = provider.ClientSecret;
        }

        if (!string.IsNullOrWhiteSpace(pendingSession.CodeVerifier))
        {
            formFields["code_verifier"] = pendingSession.CodeVerifier;
        }

        foreach (var parameter in provider.TokenParameters)
        {
            formFields[parameter.Key] = parameter.Value;
        }

        var client = _httpClientFactory.CreateClient("external-auth");
        using var response = await client.PostAsync(
            provider.TokenEndpoint,
            new FormUrlEncodedContent(formFields),
            cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException(
                $"The external provider token exchange failed with status {(int)response.StatusCode}: {responseBody}");
        }

        return JsonDocument.Parse(responseBody);
    }

    private async Task<JsonDocument?> TryReadUserInfoDocumentAsync(
        ExternalProviderDefinitionOptions provider,
        string? accessToken,
        string? idToken,
        CancellationToken cancellationToken)
    {
        if (!string.IsNullOrWhiteSpace(provider.UserInfoEndpoint) && !string.IsNullOrWhiteSpace(accessToken))
        {
            var queryParameters = provider.UserInfoQueryParameters.ToDictionary(
                entry => entry.Key,
                entry => entry.Value,
                StringComparer.OrdinalIgnoreCase);
            if (provider.SendAccessTokenAsQueryParameterForUserInfo == true)
            {
                queryParameters[provider.UserInfoAccessTokenParameterName] = accessToken;
            }

            var userInfoUri = BuildUri(provider.UserInfoEndpoint, queryParameters);
            var client = _httpClientFactory.CreateClient("external-auth");
            using var request = new HttpRequestMessage(HttpMethod.Get, userInfoUri);
            if (provider.SendAccessTokenAsQueryParameterForUserInfo != true)
            {
                request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
            }

            using var response = await client.SendAsync(request, cancellationToken);
            var body = await response.Content.ReadAsStringAsync(cancellationToken);
            if (response.IsSuccessStatusCode)
            {
                return JsonDocument.Parse(body);
            }

            _logger.LogWarning(
                "External provider user info request failed with status {StatusCode}. Falling back to ID token payload when available.",
                (int)response.StatusCode);
        }

        if (string.IsNullOrWhiteSpace(idToken))
        {
            return null;
        }

        return ParseJwtPayload(idToken);
    }

    private string BuildAuthorizationUrl(
        ExternalProviderDefinitionOptions provider,
        PendingExternalProviderAuthSession pendingSession)
    {
        var queryParameters = new Dictionary<string, string>(StringComparer.Ordinal)
        {
            ["response_type"] = provider.ResponseType,
            [provider.ClientIdParameterName] = provider.ClientId!,
            ["redirect_uri"] = pendingSession.RedirectUri,
            ["scope"] = provider.Scope,
            ["state"] = pendingSession.State
        };

        foreach (var parameter in provider.AuthorizationParameters)
        {
            queryParameters[parameter.Key] = parameter.Value;
        }

        if (!string.IsNullOrWhiteSpace(pendingSession.CodeVerifier))
        {
            queryParameters["code_challenge"] = BuildCodeChallenge(pendingSession.CodeVerifier);
            queryParameters["code_challenge_method"] = "S256";
        }

        return BuildUri(provider.AuthorizationEndpoint, queryParameters).ToString();
    }

    private ExternalProviderDefinitionOptions ResolveProvider(string provider)
    {
        if (string.IsNullOrWhiteSpace(provider))
        {
            throw new InvalidOperationException("An external provider must be specified.");
        }

        var normalizedProvider = provider.Trim().ToLowerInvariant();
        var defaults = KnownExternalProviderDefaults.Get(normalizedProvider);
        _options.Providers.TryGetValue(normalizedProvider, out var configuredProvider);

        var resolvedProvider = defaults?.MergeWith(configuredProvider) ?? configuredProvider?.Clone();
        if (resolvedProvider is null || resolvedProvider.Enabled != true)
        {
            throw new InvalidOperationException(
                $"External provider '{normalizedProvider}' is not configured. Enable it under {ExternalProviderAuthenticationOptions.SectionName}:{normalizedProvider}.");
        }

        if (string.IsNullOrWhiteSpace(resolvedProvider.ClientId) ||
            string.IsNullOrWhiteSpace(resolvedProvider.AuthorizationEndpoint) ||
            string.IsNullOrWhiteSpace(resolvedProvider.TokenEndpoint))
        {
            throw new InvalidOperationException(
                $"External provider '{normalizedProvider}' is missing required configuration values.");
        }

        return resolvedProvider;
    }

    private Uri ValidateClientCallbackUri(string callbackUrl, HttpRequest httpRequest)
    {
        if (!Uri.TryCreate(callbackUrl, UriKind.Absolute, out var callbackUri))
        {
            throw new InvalidOperationException("The external provider callback URL must be absolute.");
        }

        if (callbackUri.Scheme == Uri.UriSchemeHttp || callbackUri.Scheme == Uri.UriSchemeHttps)
        {
            var allowedOrigins = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                $"{httpRequest.Scheme}://{httpRequest.Host}"
            };

            foreach (var origin in _options.AllowedCallbackOrigins)
            {
                var normalizedOrigin = origin?.Trim();
                if (!string.IsNullOrWhiteSpace(normalizedOrigin))
                {
                    allowedOrigins.Add(normalizedOrigin.TrimEnd('/'));
                }
            }

            if (IsDevelopmentLocalhostCallback(callbackUri))
            {
                return callbackUri;
            }

            var callbackOrigin = callbackUri.GetLeftPart(UriPartial.Authority).TrimEnd('/');
            if (!allowedOrigins.Contains(callbackOrigin))
            {
                throw new InvalidOperationException("The external provider callback URL origin is not allowed.");
            }

            return callbackUri;
        }

        if (string.Equals(callbackUri.Scheme, "file", StringComparison.OrdinalIgnoreCase))
        {
            throw new InvalidOperationException("The external provider callback URL scheme is not allowed.");
        }

        return callbackUri;
    }

    private bool IsDevelopmentLocalhostCallback(Uri callbackUri)
    {
        if (!(_hostEnvironment.IsDevelopment() || _hostEnvironment.IsEnvironment("Testing")))
        {
            return false;
        }

        return string.Equals(callbackUri.Host, "localhost", StringComparison.OrdinalIgnoreCase) ||
               string.Equals(callbackUri.Host, "127.0.0.1", StringComparison.OrdinalIgnoreCase);
    }

    private static string BuildCodeChallenge(string codeVerifier)
    {
        var verifierBytes = Encoding.UTF8.GetBytes(codeVerifier);
        var hashBytes = SHA256.HashData(verifierBytes);
        return Base64UrlEncode(hashBytes);
    }

    private static string Base64UrlEncode(byte[] bytes) =>
        Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');

    private static Uri BuildUri(string baseUri, IEnumerable<KeyValuePair<string, string>> queryParameters)
    {
        var uriString = QueryHelpers.AddQueryString(
            baseUri,
            queryParameters.Select(entry => new KeyValuePair<string, string?>(entry.Key, entry.Value)));
        return new Uri(uriString, UriKind.Absolute);
    }

    private static string? ReadJsonValue(JsonElement element, string? path)
    {
        if (string.IsNullOrWhiteSpace(path))
        {
            return null;
        }

        var current = element;
        foreach (var segment in path.Split('.', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            if (current.ValueKind != JsonValueKind.Object ||
                !current.TryGetProperty(segment, out current))
            {
                return null;
            }
        }

        return current.ValueKind switch
        {
            JsonValueKind.String => current.GetString(),
            JsonValueKind.Number => current.ToString(),
            JsonValueKind.True => bool.TrueString,
            JsonValueKind.False => bool.FalseString,
            JsonValueKind.Null => null,
            _ => current.ToString()
        };
    }

    private static JsonDocument ParseJwtPayload(string idToken)
    {
        var parts = idToken.Split('.');
        if (parts.Length < 2)
        {
            throw new InvalidOperationException("The external provider ID token is invalid.");
        }

        var payloadBytes = Base64UrlDecode(parts[1]);
        return JsonDocument.Parse(payloadBytes);
    }

    private static byte[] Base64UrlDecode(string value)
    {
        var padded = value.Replace('-', '+').Replace('_', '/');
        padded = padded.PadRight(padded.Length + ((4 - padded.Length % 4) % 4), '=');
        return Convert.FromBase64String(padded);
    }

    private static string BuildProviderRedirectUri(
        ExternalProviderDefinitionOptions provider,
        HttpRequest httpRequest)
    {
        if (Uri.TryCreate(provider.RedirectUri, UriKind.Absolute, out var absoluteRedirectUri))
        {
            return absoluteRedirectUri.ToString();
        }

        var redirectPath = string.IsNullOrWhiteSpace(provider.RedirectUri)
            ? provider.RedirectPath
            : provider.RedirectUri;
        if (string.IsNullOrWhiteSpace(redirectPath))
        {
            redirectPath = "/api/auth/provider/callback";
        }

        return $"{httpRequest.Scheme}://{httpRequest.Host}{redirectPath}";
    }

    private sealed record PendingExternalProviderAuthSession(
        string Provider,
        ExternalProviderAuthFlowMode Mode,
        string CallbackUrl,
        string RedirectUri,
        string State,
        string? CodeVerifier,
        string? RequestedEmail,
        string? RequestedUserName,
        UserRole? RequestedRole,
        DateTimeOffset ExpiresAtUtc);

    private enum ExternalProviderAuthFlowMode
    {
        Login = 0,
        Register = 1
    }
}

public sealed record ExternalProviderCallbackResult(bool IsSuccess, string? RedirectUrl, string? ErrorMessage)
{
    public static ExternalProviderCallbackResult Success(string redirectUrl) =>
        new(true, redirectUrl, null);

    public static ExternalProviderCallbackResult Failure(string errorMessage) =>
        new(false, null, errorMessage);
}
