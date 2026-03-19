namespace UrbanArtDropFinder.Infrastructure.Authentication;

public sealed class ExternalProviderAuthenticationOptions
{
    public const string SectionName = "Authentication:ExternalProviders";

    public IList<string> AllowedCallbackOrigins { get; set; } = [];

    public IDictionary<string, ExternalProviderDefinitionOptions> Providers { get; set; } =
        new Dictionary<string, ExternalProviderDefinitionOptions>(StringComparer.OrdinalIgnoreCase);
}

public sealed class ExternalProviderDefinitionOptions
{
    public bool? Enabled { get; set; }

    public string? DisplayName { get; set; }

    public string? ClientId { get; set; }

    public string? ClientSecret { get; set; }

    public string AuthorizationEndpoint { get; set; } = string.Empty;

    public string TokenEndpoint { get; set; } = string.Empty;

    public string UserInfoEndpoint { get; set; } = string.Empty;

    public string? RedirectUri { get; set; }

    public string RedirectPath { get; set; } = "/api/auth/provider/callback";

    public string Scope { get; set; } = "openid profile email";

    public string ResponseType { get; set; } = "code";

    public bool? UsePkce { get; set; }

    public string ClientIdParameterName { get; set; } = "client_id";

    public string ClientSecretParameterName { get; set; } = "client_secret";

    public string AccessTokenPath { get; set; } = "access_token";

    public string IdTokenPath { get; set; } = "id_token";

    public string SubjectPath { get; set; } = "sub";

    public string EmailPath { get; set; } = "email";

    public string DisplayNamePath { get; set; } = "name";

    public bool? SendAccessTokenAsQueryParameterForUserInfo { get; set; }

    public string UserInfoAccessTokenParameterName { get; set; } = "access_token";

    public IDictionary<string, string> AuthorizationParameters { get; set; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    public IDictionary<string, string> TokenParameters { get; set; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    public IDictionary<string, string> UserInfoQueryParameters { get; set; } =
        new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);

    internal ExternalProviderDefinitionOptions MergeWith(ExternalProviderDefinitionOptions? overrideOptions)
    {
        if (overrideOptions is null)
        {
            return Clone();
        }

        return new ExternalProviderDefinitionOptions
        {
            Enabled = overrideOptions.Enabled ?? Enabled,
            DisplayName = FirstNonEmpty(overrideOptions.DisplayName, DisplayName),
            ClientId = FirstNonEmpty(overrideOptions.ClientId, ClientId),
            ClientSecret = FirstNonEmpty(overrideOptions.ClientSecret, ClientSecret),
            AuthorizationEndpoint = FirstNonEmpty(overrideOptions.AuthorizationEndpoint, AuthorizationEndpoint) ?? string.Empty,
            TokenEndpoint = FirstNonEmpty(overrideOptions.TokenEndpoint, TokenEndpoint) ?? string.Empty,
            UserInfoEndpoint = FirstNonEmpty(overrideOptions.UserInfoEndpoint, UserInfoEndpoint) ?? string.Empty,
            RedirectUri = FirstNonEmpty(overrideOptions.RedirectUri, RedirectUri),
            RedirectPath = FirstNonEmpty(overrideOptions.RedirectPath, RedirectPath) ?? "/api/auth/provider/callback",
            Scope = FirstNonEmpty(overrideOptions.Scope, Scope) ?? "openid profile email",
            ResponseType = FirstNonEmpty(overrideOptions.ResponseType, ResponseType) ?? "code",
            UsePkce = overrideOptions.UsePkce ?? UsePkce,
            ClientIdParameterName = FirstNonEmpty(overrideOptions.ClientIdParameterName, ClientIdParameterName) ?? "client_id",
            ClientSecretParameterName = FirstNonEmpty(overrideOptions.ClientSecretParameterName, ClientSecretParameterName) ?? "client_secret",
            AccessTokenPath = FirstNonEmpty(overrideOptions.AccessTokenPath, AccessTokenPath) ?? "access_token",
            IdTokenPath = FirstNonEmpty(overrideOptions.IdTokenPath, IdTokenPath) ?? "id_token",
            SubjectPath = FirstNonEmpty(overrideOptions.SubjectPath, SubjectPath) ?? "sub",
            EmailPath = FirstNonEmpty(overrideOptions.EmailPath, EmailPath) ?? "email",
            DisplayNamePath = FirstNonEmpty(overrideOptions.DisplayNamePath, DisplayNamePath) ?? "name",
            SendAccessTokenAsQueryParameterForUserInfo =
                overrideOptions.SendAccessTokenAsQueryParameterForUserInfo ?? SendAccessTokenAsQueryParameterForUserInfo,
            UserInfoAccessTokenParameterName =
                FirstNonEmpty(overrideOptions.UserInfoAccessTokenParameterName, UserInfoAccessTokenParameterName) ?? "access_token",
            AuthorizationParameters = MergeDictionaries(AuthorizationParameters, overrideOptions.AuthorizationParameters),
            TokenParameters = MergeDictionaries(TokenParameters, overrideOptions.TokenParameters),
            UserInfoQueryParameters = MergeDictionaries(UserInfoQueryParameters, overrideOptions.UserInfoQueryParameters)
        };
    }

    internal ExternalProviderDefinitionOptions Clone() =>
        new()
        {
            Enabled = Enabled,
            DisplayName = DisplayName,
            ClientId = ClientId,
            ClientSecret = ClientSecret,
            AuthorizationEndpoint = AuthorizationEndpoint,
            TokenEndpoint = TokenEndpoint,
            UserInfoEndpoint = UserInfoEndpoint,
            RedirectUri = RedirectUri,
            RedirectPath = RedirectPath,
            Scope = Scope,
            ResponseType = ResponseType,
            UsePkce = UsePkce,
            ClientIdParameterName = ClientIdParameterName,
            ClientSecretParameterName = ClientSecretParameterName,
            AccessTokenPath = AccessTokenPath,
            IdTokenPath = IdTokenPath,
            SubjectPath = SubjectPath,
            EmailPath = EmailPath,
            DisplayNamePath = DisplayNamePath,
            SendAccessTokenAsQueryParameterForUserInfo = SendAccessTokenAsQueryParameterForUserInfo,
            UserInfoAccessTokenParameterName = UserInfoAccessTokenParameterName,
            AuthorizationParameters = MergeDictionaries(AuthorizationParameters, null),
            TokenParameters = MergeDictionaries(TokenParameters, null),
            UserInfoQueryParameters = MergeDictionaries(UserInfoQueryParameters, null)
        };

    private static string? FirstNonEmpty(string? preferred, string? fallback)
        => !string.IsNullOrWhiteSpace(preferred) ? preferred : fallback;

    private static IDictionary<string, string> MergeDictionaries(
        IEnumerable<KeyValuePair<string, string>> primary,
        IEnumerable<KeyValuePair<string, string>>? secondary)
    {
        var merged = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        foreach (var entry in primary)
        {
            merged[entry.Key] = entry.Value;
        }

        if (secondary is null)
        {
            return merged;
        }

        foreach (var entry in secondary)
        {
            merged[entry.Key] = entry.Value;
        }

        return merged;
    }
}
