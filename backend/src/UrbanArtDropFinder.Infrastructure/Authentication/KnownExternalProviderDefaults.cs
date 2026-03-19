namespace UrbanArtDropFinder.Infrastructure.Authentication;

internal static class KnownExternalProviderDefaults
{
    public static ExternalProviderDefinitionOptions? Get(string provider)
    {
        var normalizedProvider = provider.Trim().ToLowerInvariant();
        return normalizedProvider switch
        {
            "google" => new ExternalProviderDefinitionOptions
            {
                DisplayName = "Google",
                AuthorizationEndpoint = "https://accounts.google.com/o/oauth2/v2/auth",
                TokenEndpoint = "https://oauth2.googleapis.com/token",
                UserInfoEndpoint = "https://openidconnect.googleapis.com/v1/userinfo",
                Scope = "openid profile email",
                UsePkce = true
            },
            "facebook" => new ExternalProviderDefinitionOptions
            {
                DisplayName = "Facebook",
                AuthorizationEndpoint = "https://www.facebook.com/v23.0/dialog/oauth",
                TokenEndpoint = "https://graph.facebook.com/v23.0/oauth/access_token",
                UserInfoEndpoint = "https://graph.facebook.com/me",
                Scope = "email public_profile",
                UsePkce = false,
                SubjectPath = "id",
                DisplayNamePath = "name",
                SendAccessTokenAsQueryParameterForUserInfo = true,
                UserInfoQueryParameters = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["fields"] = "id,name,email"
                }
            },
            "instagram" => new ExternalProviderDefinitionOptions
            {
                DisplayName = "Instagram",
                AuthorizationEndpoint = "https://api.instagram.com/oauth/authorize",
                TokenEndpoint = "https://api.instagram.com/oauth/access_token",
                UserInfoEndpoint = "https://graph.instagram.com/me",
                Scope = "user_profile",
                UsePkce = false,
                SubjectPath = "id",
                EmailPath = string.Empty,
                DisplayNamePath = "username",
                SendAccessTokenAsQueryParameterForUserInfo = true,
                UserInfoQueryParameters = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["fields"] = "id,username"
                }
            },
            "tiktok" => new ExternalProviderDefinitionOptions
            {
                DisplayName = "TikTok",
                AuthorizationEndpoint = "https://www.tiktok.com/v2/auth/authorize/",
                TokenEndpoint = "https://open.tiktokapis.com/v2/oauth/token/",
                UserInfoEndpoint = "https://open.tiktokapis.com/v2/user/info/",
                Scope = "user.info.basic",
                UsePkce = true,
                ClientIdParameterName = "client_key",
                SubjectPath = "data.user.open_id",
                EmailPath = string.Empty,
                DisplayNamePath = "data.user.display_name",
                UserInfoQueryParameters = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    ["fields"] = "open_id,display_name"
                }
            },
            "microsoft" => new ExternalProviderDefinitionOptions
            {
                DisplayName = "Microsoft",
                AuthorizationEndpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/authorize",
                TokenEndpoint = "https://login.microsoftonline.com/common/oauth2/v2.0/token",
                UserInfoEndpoint = "https://graph.microsoft.com/oidc/userinfo",
                Scope = "openid profile email User.Read",
                UsePkce = true
            },
            _ => null
        };
    }
}
