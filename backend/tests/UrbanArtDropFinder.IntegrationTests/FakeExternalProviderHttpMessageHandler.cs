using System.Net;
using System.Text;
using System.Text.Json;

namespace UrbanArtDropFinder.IntegrationTests;

internal sealed class FakeExternalProviderHttpMessageHandler : HttpMessageHandler
{
    protected override async Task<HttpResponseMessage> SendAsync(
        HttpRequestMessage request,
        CancellationToken cancellationToken)
    {
        if (request.RequestUri is null)
        {
            return new HttpResponseMessage(HttpStatusCode.BadRequest);
        }

        if (request.Method == HttpMethod.Post &&
            request.RequestUri.AbsolutePath.Equals("/oauth/token", StringComparison.OrdinalIgnoreCase))
        {
            var formBody = request.Content is null
                ? string.Empty
                : await request.Content.ReadAsStringAsync(cancellationToken);
            var parsedBody = ParseFormBody(formBody);
            var code = parsedBody.TryGetValue("code", out var resolvedCode)
                ? resolvedCode
                : "default-code";
            return CreateJsonResponse(
                new
                {
                    access_token = $"access-token::{code}",
                    token_type = "Bearer",
                    expires_in = 3600
                });
        }

        if (request.Method == HttpMethod.Get &&
            request.RequestUri.AbsolutePath.Equals("/oauth/userinfo", StringComparison.OrdinalIgnoreCase))
        {
            var accessToken = request.Headers.Authorization?.Parameter?.Trim();
            if (string.IsNullOrWhiteSpace(accessToken))
            {
                var queryParameters = ParseQueryString(request.RequestUri.Query);
                queryParameters.TryGetValue("access_token", out accessToken);
            }

            var providerCode = accessToken?.Replace("access-token::", string.Empty, StringComparison.Ordinal);
            var payload = providerCode switch
            {
                "hunter-login" => new { sub = "provider-subject-hunter-login", email = "provider.hunter.login@example.com", name = "Provider Hunter" },
                "hunter-register" => new { sub = "provider-subject-hunter-register", email = "provider.hunter.register@example.com", name = "Registered Hunter" },
                "moderator-login" => new { sub = "provider-subject-moderator-login", email = "provider.moderator.login@example.com", name = "Moderator Provider" },
                _ => new { sub = "provider-subject-default", email = "default.provider@example.com", name = "Default Provider" }
            };

            return CreateJsonResponse(payload);
        }

        return new HttpResponseMessage(HttpStatusCode.NotFound);
    }

    private static HttpResponseMessage CreateJsonResponse(object payload)
    {
        var json = JsonSerializer.Serialize(payload);
        return new HttpResponseMessage(HttpStatusCode.OK)
        {
            Content = new StringContent(json, Encoding.UTF8, "application/json")
        };
    }

    private static Dictionary<string, string> ParseFormBody(string body)
    {
        return body.Split('&', StringSplitOptions.RemoveEmptyEntries)
            .Select(part => part.Split('=', 2))
            .Where(parts => parts.Length == 2)
            .ToDictionary(
                parts => Uri.UnescapeDataString(parts[0].Replace('+', ' ')),
                parts => Uri.UnescapeDataString(parts[1].Replace('+', ' ')),
                StringComparer.OrdinalIgnoreCase);
    }

    private static Dictionary<string, string> ParseQueryString(string query)
    {
        var trimmed = query.TrimStart('?');
        if (string.IsNullOrWhiteSpace(trimmed))
        {
            return new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        }

        return ParseFormBody(trimmed);
    }
}
