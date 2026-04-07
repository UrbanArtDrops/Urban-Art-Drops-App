using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.Extensions.Configuration;
using UrbanArtDropFinder.Application.Abstractions;

namespace UrbanArtDropFinder.Infrastructure.Services;

/// <summary>Publishes drop announcements to social media endpoints configured per channel.</summary>
public sealed class ConfiguredSocialMediaPublisher(
    IConfiguration configuration,
    IHttpClientFactory httpClientFactory) : ISocialMediaPublisher
{
    public async Task<SocialMediaPublishResult> PublishDropAsync(
        SocialMediaPublishRequest request,
        CancellationToken cancellationToken)
    {
        var providerSection = configuration.GetSection($"SocialMedia:Providers:{request.Channel}");
        if (!providerSection.GetValue<bool>("Enabled"))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{request.Channel}' is not enabled.",
                null);
        }

        var publishEndpoint = providerSection["PublishEndpoint"]?.Trim();
        if (string.IsNullOrWhiteSpace(publishEndpoint))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{request.Channel}' has no publish endpoint configured.",
                null);
        }

        var tokenSecretName = providerSection["AccessTokenSecretName"]?.Trim();
        var accessToken = string.IsNullOrWhiteSpace(tokenSecretName)
            ? null
            : configuration[tokenSecretName];
        if (string.IsNullOrWhiteSpace(accessToken))
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Skipped,
                $"Social channel '{request.Channel}' has no access token secret configured.",
                null);
        }

        try
        {
            using var httpRequest = new HttpRequestMessage(HttpMethod.Post, publishEndpoint)
            {
                Content = JsonContent.Create(new
                {
                    dropId = request.DropId,
                    channel = request.Channel,
                    artPieceTitle = request.ArtPieceTitle,
                    dropMakerDisplayName = request.DropMakerDisplayName,
                    dropMakerComment = request.DropMakerComment,
                    publicDropUrl = request.PublicDropUrl
                })
            };
            httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", accessToken);

            using var response = await httpClientFactory
                .CreateClient("social-media")
                .SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                return new SocialMediaPublishResult(
                    SocialMediaPublishOutcome.Failed,
                    $"Social channel '{request.Channel}' returned HTTP {(int)response.StatusCode}.",
                    null);
            }

            var externalPostId = await TryReadExternalPostIdAsync(response, cancellationToken);
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Published,
                $"Social channel '{request.Channel}' published the drop.",
                externalPostId);
        }
        catch (Exception exception)
        {
            return new SocialMediaPublishResult(
                SocialMediaPublishOutcome.Failed,
                exception.Message,
                null);
        }
    }

    private static async Task<string?> TryReadExternalPostIdAsync(
        HttpResponseMessage response,
        CancellationToken cancellationToken)
    {
        try
        {
            var payload = await response.Content.ReadFromJsonAsync<Dictionary<string, object?>>(
                cancellationToken: cancellationToken);
            if (payload is null)
            {
                return null;
            }

            return payload.TryGetValue("id", out var id) ? id?.ToString() : null;
        }
        catch
        {
            return null;
        }
    }
}
