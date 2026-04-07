using System.Collections.Concurrent;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

/// <summary>Publishes drop announcements to configured social media providers.</summary>
public sealed class ConfiguredSocialMediaPublisher(
    IConfiguration configuration,
    IHttpClientFactory httpClientFactory,
    IClock clock) : ISocialMediaPublisher
{
    private const string FacebookChannel = "Facebook";
    private const string InstagramChannel = "Instagram";
    private const string TikTokChannel = "TikTok";
    private static readonly TimeSpan DefaultBreakDuration = TimeSpan.FromMinutes(1);
    private readonly ConcurrentDictionary<string, CircuitState> _circuitStates = new(StringComparer.OrdinalIgnoreCase);

    public async Task<SocialMediaPublishResult> PublishDropAsync(
        SocialMediaPublishRequest request,
        CancellationToken cancellationToken)
    {
        var channel = NormalizeChannel(request.Channel);
        var providerSection = configuration.GetSection($"SocialMedia:Providers:{channel}");
        if (!providerSection.GetValue<bool>("Enabled"))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{channel}' is not enabled.",
                null);
        }

        if (TryGetOpenCircuitResult(channel, out var circuitResult))
        {
            return circuitResult;
        }

        var tokenSecretName = providerSection["AccessTokenSecretName"]?.Trim();
        var accessToken = string.IsNullOrWhiteSpace(tokenSecretName)
            ? null
            : configuration[tokenSecretName];
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{channel}' has no access token secret configured.",
                null);
        }

        SocialMediaPublishResult result;
        try
        {
            result = await PublishByProviderAsync(
                request with { Channel = channel },
                providerSection,
                accessToken,
                cancellationToken);
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception exception)
        {
            result = new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Failed,
                exception.Message,
                null);
        }

        if (result.Outcome == SocialMediaPublishOutcome.Published)
        {
            ResetCircuit(channel);
        }
        else if (result.Outcome == SocialMediaPublishOutcome.Failed)
        {
            RegisterFailure(channel);
        }

        return result;
    }

    private Task<SocialMediaPublishResult> PublishByProviderAsync(
        SocialMediaPublishRequest request,
        IConfigurationSection providerSection,
        string accessToken,
        CancellationToken cancellationToken)
    {
        var providerKind = NormalizeChannel(providerSection["ProviderKind"] ?? request.Channel);
        return providerKind switch
        {
            FacebookChannel => PublishFacebookAsync(request, providerSection, accessToken, cancellationToken),
            InstagramChannel => PublishInstagramAsync(request, providerSection, accessToken, cancellationToken),
            TikTokChannel => PublishTikTokAsync(request, providerSection, accessToken, cancellationToken),
            _ => PublishGenericAsync(request, providerSection, accessToken, cancellationToken)
        };
    }

    private async Task<SocialMediaPublishResult> PublishFacebookAsync(
        SocialMediaPublishRequest request,
        IConfigurationSection providerSection,
        string accessToken,
        CancellationToken cancellationToken)
    {
        var pageId = providerSection["PageId"]?.Trim();
        if (string.IsNullOrWhiteSpace(pageId))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                "Facebook publishing requires SocialMedia:Providers:Facebook:PageId.",
                null);
        }

        var publishUri = ResolveEndpoint(
            providerSection,
            defaultBaseUrl: "https://graph.facebook.com/v20.0",
            defaultPath: $"{Uri.EscapeDataString(pageId)}/feed");
        var caption = BuildCaption(request);

        using var response = await SendWithRetryAsync(
            () =>
            {
                var contentFields = new Dictionary<string, string>
                {
                    ["message"] = caption
                };
                if (!string.IsNullOrWhiteSpace(request.PublicDropUrl))
                {
                    contentFields["link"] = request.PublicDropUrl!;
                }

                return CreateFormRequest(publishUri, accessToken, contentFields);
            },
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            return CreateHttpFailure(request.Channel, response.StatusCode);
        }

        var externalPostId = await TryReadJsonValueAsync(response, cancellationToken, "id");
        return new SocialMediaPublishResult(
            SocialMediaPublishOutcome.Published,
            $"Social channel '{request.Channel}' published the drop.",
            externalPostId);
    }

    private async Task<SocialMediaPublishResult> PublishInstagramAsync(
        SocialMediaPublishRequest request,
        IConfigurationSection providerSection,
        string accessToken,
        CancellationToken cancellationToken)
    {
        var businessAccountId = providerSection["BusinessAccountId"]?.Trim()
            ?? providerSection["InstagramBusinessAccountId"]?.Trim();
        if (string.IsNullOrWhiteSpace(businessAccountId))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                "Instagram publishing requires SocialMedia:Providers:Instagram:BusinessAccountId.",
                null);
        }

        var imageUrl = request.ImageUrls.FirstOrDefault(url => !string.IsNullOrWhiteSpace(url));
        if (string.IsNullOrWhiteSpace(imageUrl))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                "Instagram publishing requires at least one public image URL.",
                null);
        }

        var mediaUri = ResolveEndpoint(
            providerSection,
            "MediaEndpoint",
            defaultBaseUrl: "https://graph.facebook.com/v20.0",
            defaultPath: $"{Uri.EscapeDataString(businessAccountId)}/media");
        using var mediaResponse = await SendWithRetryAsync(
            () => CreateFormRequest(
                mediaUri,
                accessToken,
                new Dictionary<string, string>
                {
                    ["image_url"] = imageUrl,
                    ["caption"] = BuildCaption(request)
                }),
            cancellationToken);

        if (!mediaResponse.IsSuccessStatusCode)
        {
            return CreateHttpFailure(request.Channel, mediaResponse.StatusCode);
        }

        var creationId = await TryReadJsonValueAsync(mediaResponse, cancellationToken, "id");
        if (string.IsNullOrWhiteSpace(creationId))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Failed,
                "Instagram media container response did not contain an id.",
                null);
        }

        var publishUri = ResolveEndpoint(
            providerSection,
            "PublishEndpoint",
            defaultBaseUrl: "https://graph.facebook.com/v20.0",
            defaultPath: $"{Uri.EscapeDataString(businessAccountId)}/media_publish");
        using var publishResponse = await SendWithRetryAsync(
            () => CreateFormRequest(
                publishUri,
                accessToken,
                new Dictionary<string, string>
                {
                    ["creation_id"] = creationId
                }),
            cancellationToken);

        if (!publishResponse.IsSuccessStatusCode)
        {
            return CreateHttpFailure(request.Channel, publishResponse.StatusCode);
        }

        var externalPostId = await TryReadJsonValueAsync(publishResponse, cancellationToken, "id");
        return new SocialMediaPublishResult(
            SocialMediaPublishOutcome.Published,
            $"Social channel '{request.Channel}' published the drop.",
            externalPostId);
    }

    private async Task<SocialMediaPublishResult> PublishTikTokAsync(
        SocialMediaPublishRequest request,
        IConfigurationSection providerSection,
        string accessToken,
        CancellationToken cancellationToken)
    {
        var imageUrls = request.ImageUrls
            .Where(url => !string.IsNullOrWhiteSpace(url))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToList();
        if (imageUrls.Count == 0)
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                "TikTok photo publishing requires at least one public image URL.",
                null);
        }

        var publishUri = ResolveEndpoint(
            providerSection,
            defaultBaseUrl: "https://open.tiktokapis.com",
            defaultPath: "v2/post/publish/content/init/");
        var title = Truncate(request.ArtPieceTitle, 90);
        var caption = Truncate(BuildCaption(request), 2200);
        var privacyLevel = providerSection["PrivacyLevel"]?.Trim();
        if (string.IsNullOrWhiteSpace(privacyLevel))
        {
            privacyLevel = "PUBLIC_TO_EVERYONE";
        }

        using var response = await SendWithRetryAsync(
            () => CreateJsonRequest(
                publishUri,
                accessToken,
                new
                {
                    post_info = new
                    {
                        title,
                        description = caption,
                        disable_comment = providerSection.GetValue<bool?>("DisableComment") ?? false,
                        privacy_level = privacyLevel,
                        auto_add_music = providerSection.GetValue<bool?>("AutoAddMusic") ?? false
                    },
                    source_info = new
                    {
                        source = "PULL_FROM_URL",
                        photo_cover_index = providerSection.GetValue<int?>("PhotoCoverIndex") ?? 0,
                        photo_images = imageUrls
                    },
                    post_mode = "DIRECT_POST",
                    media_type = "PHOTO"
                }),
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            return CreateHttpFailure(request.Channel, response.StatusCode);
        }

        var externalPostId = await TryReadJsonValueAsync(response, cancellationToken, "data", "publish_id");
        return new SocialMediaPublishResult(
            SocialMediaPublishOutcome.Published,
            $"Social channel '{request.Channel}' published the drop.",
            externalPostId);
    }

    private async Task<SocialMediaPublishResult> PublishGenericAsync(
        SocialMediaPublishRequest request,
        IConfigurationSection providerSection,
        string accessToken,
        CancellationToken cancellationToken)
    {
        var publishEndpoint = providerSection["PublishEndpoint"]?.Trim();
        if (string.IsNullOrWhiteSpace(publishEndpoint))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{request.Channel}' has no publish endpoint configured.",
                null);
        }

        using var response = await SendWithRetryAsync(
            () => CreateJsonRequest(
                new Uri(publishEndpoint, UriKind.Absolute),
                accessToken,
                new
                {
                    dropId = request.DropId,
                    channel = request.Channel,
                    artPieceTitle = request.ArtPieceTitle,
                    dropMakerDisplayName = request.DropMakerDisplayName,
                    dropMakerComment = request.DropMakerComment,
                    publicDropUrl = request.PublicDropUrl,
                    imageUrls = request.ImageUrls
                }),
            cancellationToken);

        if (!response.IsSuccessStatusCode)
        {
            return CreateHttpFailure(request.Channel, response.StatusCode);
        }

        var externalPostId = await TryReadJsonValueAsync(response, cancellationToken, "id");
        return new SocialMediaPublishResult(
            SocialMediaPublishOutcome.Published,
            $"Social channel '{request.Channel}' published the drop.",
            externalPostId);
    }

    private async Task<HttpResponseMessage> SendWithRetryAsync(
        Func<HttpRequestMessage> requestFactory,
        CancellationToken cancellationToken)
    {
        var maxAttempts = Math.Clamp(configuration.GetValue<int?>("SocialMedia:Retry:MaxAttempts") ?? 3, 1, 5);
        var baseDelay = TimeSpan.FromMilliseconds(
            Math.Clamp(configuration.GetValue<int?>("SocialMedia:Retry:BaseDelayMilliseconds") ?? 250, 0, 5000));
        Exception? lastException = null;

        for (var attempt = 1; attempt <= maxAttempts; attempt += 1)
        {
            try
            {
                using var httpRequest = requestFactory();
                var response = await httpClientFactory
                    .CreateClient("social-media")
                    .SendAsync(httpRequest, cancellationToken);
                if (!IsTransient(response.StatusCode) || attempt == maxAttempts)
                {
                    return response;
                }

                response.Dispose();
            }
            catch (Exception exception) when (IsTransient(exception) && attempt < maxAttempts)
            {
                lastException = exception;
            }

            if (baseDelay > TimeSpan.Zero)
            {
                await Task.Delay(baseDelay * attempt, cancellationToken);
            }
        }

        throw lastException ?? new InvalidOperationException("Social media publishing failed after all retry attempts.");
    }

    private bool TryGetOpenCircuitResult(string channel, out SocialMediaPublishResult result)
    {
        if (_circuitStates.TryGetValue(channel, out var state) &&
            state.OpenUntilUtc.HasValue &&
            state.OpenUntilUtc.Value > clock.UtcNow)
        {
            result = new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{channel}' circuit breaker is open until {state.OpenUntilUtc.Value:O}.",
                null);
            return true;
        }

        result = null!;
        return false;
    }

    private void RegisterFailure(string channel)
    {
        var failureThreshold = Math.Clamp(
            configuration.GetValue<int?>("SocialMedia:CircuitBreaker:FailureThreshold") ?? 3,
            1,
            20);
        var breakDuration = TimeSpan.FromSeconds(
            Math.Clamp(
                configuration.GetValue<int?>("SocialMedia:CircuitBreaker:BreakDurationSeconds") ?? (int)DefaultBreakDuration.TotalSeconds,
                1,
                3600));

        var state = _circuitStates.GetOrAdd(channel, _ => new CircuitState());
        lock (state)
        {
            state.ConsecutiveFailures += 1;
            if (state.ConsecutiveFailures >= failureThreshold)
            {
                state.OpenUntilUtc = clock.UtcNow.Add(breakDuration);
            }
        }
    }

    private void ResetCircuit(string channel)
    {
        var state = _circuitStates.GetOrAdd(channel, _ => new CircuitState());
        lock (state)
        {
            state.ConsecutiveFailures = 0;
            state.OpenUntilUtc = null;
        }
    }

    private static HttpRequestMessage CreateFormRequest(
        Uri uri,
        string accessToken,
        IDictionary<string, string> formFields)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, uri)
        {
            Content = new FormUrlEncodedContent(formFields)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        return request;
    }

    private static HttpRequestMessage CreateJsonRequest(
        Uri uri,
        string accessToken,
        object payload)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, uri)
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);
        return request;
    }

    private static Uri ResolveEndpoint(
        IConfigurationSection providerSection,
        string endpointKey = "PublishEndpoint",
        string defaultBaseUrl = "",
        string defaultPath = "")
    {
        var configuredEndpoint = providerSection[endpointKey]?.Trim();
        if (!string.IsNullOrWhiteSpace(configuredEndpoint))
        {
            return new Uri(configuredEndpoint, UriKind.Absolute);
        }

        var apiBaseUrl = providerSection["ApiBaseUrl"]?.Trim();
        if (string.IsNullOrWhiteSpace(apiBaseUrl))
        {
            apiBaseUrl = defaultBaseUrl;
        }

        if (!apiBaseUrl.EndsWith("/", StringComparison.Ordinal))
        {
            apiBaseUrl += "/";
        }

        return new Uri(new Uri(apiBaseUrl, UriKind.Absolute), defaultPath);
    }

    private static SocialMediaPublishResult CreateHttpFailure(string channel, HttpStatusCode statusCode)
        => new(
            SocialMediaPublishOutcome.Failed,
            $"Social channel '{channel}' returned HTTP {(int)statusCode}.",
            null);

    private static async Task<string?> TryReadJsonValueAsync(
        HttpResponseMessage response,
        CancellationToken cancellationToken,
        params string[] path)
    {
        try
        {
            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            var current = document.RootElement;
            foreach (var segment in path)
            {
                if (current.ValueKind != JsonValueKind.Object ||
                    !current.TryGetProperty(segment, out current))
                {
                    return null;
                }
            }

            return current.ValueKind == JsonValueKind.String
                ? current.GetString()
                : current.ToString();
        }
        catch
        {
            return null;
        }
    }

    private static bool IsTransient(HttpStatusCode statusCode)
        => statusCode is HttpStatusCode.RequestTimeout
            or HttpStatusCode.TooManyRequests
            or HttpStatusCode.BadGateway
            or HttpStatusCode.ServiceUnavailable
            or HttpStatusCode.GatewayTimeout
            || (int)statusCode >= 500;

    private static bool IsTransient(Exception exception)
        => exception is HttpRequestException or TaskCanceledException;

    private static string BuildCaption(SocialMediaPublishRequest request)
    {
        var lines = new List<string>
        {
            $"{request.ArtPieceTitle} by {request.DropMakerDisplayName}"
        };
        if (!string.IsNullOrWhiteSpace(request.DropMakerComment))
        {
            lines.Add(request.DropMakerComment.Trim());
        }

        if (!string.IsNullOrWhiteSpace(request.PublicDropUrl))
        {
            lines.Add(request.PublicDropUrl.Trim());
        }

        return string.Join(Environment.NewLine, lines);
    }

    private static string NormalizeChannel(string channel)
    {
        var normalized = channel.Trim();
        return normalized.Equals("facebook", StringComparison.OrdinalIgnoreCase)
            ? FacebookChannel
            : normalized.Equals("instagram", StringComparison.OrdinalIgnoreCase)
                ? InstagramChannel
                : normalized.Equals("tiktok", StringComparison.OrdinalIgnoreCase)
                    ? TikTokChannel
                    : normalized;
    }

    private static string Truncate(string value, int maxLength)
        => value.Length <= maxLength ? value : value[..maxLength];

    private sealed class CircuitState
    {
        public int ConsecutiveFailures { get; set; }

        public DateTimeOffset? OpenUntilUtc { get; set; }
    }
}
