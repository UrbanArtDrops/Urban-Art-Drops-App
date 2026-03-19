# Authentication Provider Configuration Guide

This guide explains how to configure Google, Facebook, Instagram, TikTok, and Microsoft sign-in for Urban Art Drops without Firebase.

The implementation uses the following flow:

1. The Flutter client asks the backend to start provider authentication.
2. The backend creates the provider authorization URL.
3. The Flutter client opens the system browser.
4. The provider redirects back to the backend callback.
5. The backend exchanges the authorization code for tokens, resolves the external identity, and creates the Urban Art Drops session.
6. The backend redirects the browser back to the Flutter callback with a one-time `provider_session`.
7. The Flutter client completes the flow by calling the backend completion endpoint.

## Step 1: Collect the runtime URLs

Define the URLs for the environment you want to configure.

Example for local development:

- Backend base URL: `http://localhost:5143`
- Flutter Web origin: `http://localhost:8080`
- Backend provider callback: `http://localhost:5143/api/auth/provider/callback`
- Flutter Web callback page: `http://localhost:8080/auth.html`
- Android/native callback scheme: `urbanartdrops-auth://oauth/callback`

Example for production:

- Backend base URL: `https://api.example.com`
- Flutter Web origin: `https://app.example.com`
- Backend provider callback: `https://api.example.com/api/auth/provider/callback`
- Flutter Web callback page: `https://app.example.com/auth.html`
- Android/native callback scheme: `urbanartdrops-auth://oauth/callback`

Important:

- The provider redirects to the backend callback, not directly to `auth.html`.
- `auth.html` is only the final Flutter Web callback page after the backend has completed token exchange.

## Step 2: Decide which providers to enable

The application supports these provider keys:

- `google`
- `facebook`
- `instagram`
- `tiktok`
- `microsoft`

Enable only the providers you actually configure. Leave the others disabled.

## Step 3: Create an application in the provider portal

For each provider:

1. Create a new OAuth or OIDC application in the provider developer portal.
2. Choose a web application or server-side application type where available.
3. Register the backend callback URL from Step 1 as the redirect URI.
4. If the provider asks for allowed origins, add the Flutter Web origin from Step 1.
5. Save the generated client id and client secret.

Use these provider-specific notes:

- Google:
  Register the backend callback as an authorized redirect URI. Add the web origin as an authorized JavaScript origin if Google asks for it.
- Facebook:
  Configure Facebook Login for Web and add the backend callback as a valid OAuth redirect URI.
- Instagram:
  Use the Instagram Basic Display style flow that matches the configured defaults. Instagram does not provide email in the current default mapping.
- TikTok:
  Configure the redirect URI exactly and verify the approved scopes in the TikTok developer portal. TikTok uses PKCE in the current default configuration.
- Microsoft:
  Register the backend callback in the Azure app registration and allow the delegated profile scopes used by the application.

## Step 4: Configure the backend provider settings

Provider settings live under:

- `Authentication:ExternalProviders`

The most important settings are:

- `AllowedCallbackOrigins`
- `Providers:<provider>:Enabled`
- `Providers:<provider>:ClientId`
- `Providers:<provider>:ClientSecret`

The application already contains built-in defaults for:

- authorization endpoint
- token endpoint
- user info endpoint
- default scopes
- default field mappings
- PKCE behavior

You only need to override those defaults when a provider setup requires a different value.

## Step 5: Configure local development safely

Do not store provider secrets in source control.

Use `dotnet user-secrets` or environment variables.

Example with `dotnet user-secrets` for Google:

```powershell
cd C:\src\Urban-Art-Drops-App\backend\src\UrbanArtDropFinder.Api
dotnet user-secrets set "Authentication:ExternalProviders:AllowedCallbackOrigins:0" "http://localhost:8080"
dotnet user-secrets set "Authentication:ExternalProviders:Providers:google:Enabled" "true"
dotnet user-secrets set "Authentication:ExternalProviders:Providers:google:ClientId" "<google-client-id>"
dotnet user-secrets set "Authentication:ExternalProviders:Providers:google:ClientSecret" "<google-client-secret>"
```

Example with environment variables:

```powershell
$env:Authentication__ExternalProviders__AllowedCallbackOrigins__0 = "http://localhost:8080"
$env:Authentication__ExternalProviders__Providers__google__Enabled = "true"
$env:Authentication__ExternalProviders__Providers__google__ClientId = "<google-client-id>"
$env:Authentication__ExternalProviders__Providers__google__ClientSecret = "<google-client-secret>"
```

Repeat this pattern for `facebook`, `instagram`, `tiktok`, or `microsoft`.

## Step 6: Override advanced provider settings only when needed

Override advanced settings only if the provider portal or tenant configuration requires it.

Examples:

- `Authentication:ExternalProviders:Providers:google:RedirectUri`
- `Authentication:ExternalProviders:Providers:microsoft:Scope`
- `Authentication:ExternalProviders:Providers:tiktok:AuthorizationParameters:<key>`
- `Authentication:ExternalProviders:Providers:facebook:UserInfoQueryParameters:fields`

Use this when:

- the public backend URL differs from the runtime request host
- a reverse proxy rewrites the public URL
- a provider requires tenant-specific scopes or endpoints
- the provider response fields differ from the defaults

## Step 7: Verify the Flutter callback setup

The frontend already contains the required callback handlers.

Check these files:

- `frontend/web/auth.html`
- `frontend/android/app/src/main/AndroidManifest.xml`
- `frontend/lib/shared/services/external_provider_auth_launcher.dart`

Expected behavior:

- Flutter Web uses `https://<web-origin>/auth.html`
- Android/native clients use `urbanartdrops-auth://oauth/callback`

If you change the callback scheme, update both the Flutter launcher and the Android manifest.

## Step 8: Start the application

Start backend and frontend with the correct local URLs.

Backend:

```powershell
dotnet run --project .\backend\src\UrbanArtDropFinder.Api
```

Frontend Web:

```powershell
cd .\frontend
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:5143
```

If you use another frontend origin, add it to `AllowedCallbackOrigins`.

## Step 9: Test provider login

For each enabled provider:

1. Open the login page.
2. Click the provider login button.
3. Complete sign-in in the browser window.
4. Confirm that the browser returns to the app.
5. Confirm that the app receives a signed-in Urban Art Drops session.

Repeat the same process for provider registration if self-service registration should be supported for that role.

## Step 10: Test privileged provider accounts with MFA

If the provider-linked account has role `Admin` or `Moderator`:

1. Start provider login.
2. Complete the provider sign-in.
3. Confirm that the application does not issue the final access token immediately.
4. Confirm that the MFA step is shown.
5. Complete MFA setup or verification.
6. Confirm that the final Urban Art Drops session is created afterward.

## Step 11: Troubleshoot common errors

`External provider '<provider>' is not configured`

- The provider is disabled.
- `ClientId` is missing.
- Required endpoints are missing after overrides.

`The external provider callback URL origin is not allowed`

- The frontend callback URL is not in `AllowedCallbackOrigins`.
- The frontend was started on another host or port.

`The external provider session is invalid or has expired`

- The browser flow took too long.
- The API was restarted during the login flow.
- The flow was completed twice with the same `provider_session`.

`The external provider callback did not return an authorization code`

- The provider returned an error instead of a code.
- The redirect URI configured in the provider portal does not match the backend callback.

`The external provider did not return a usable identity payload`

- The provider user info endpoint is blocked or misconfigured.
- The field mappings for subject, email, or display name do not match the provider response.

`Provider login works on native but not on Flutter Web`

- `frontend/web/auth.html` is missing from the served web assets.
- The frontend origin is missing from `AllowedCallbackOrigins`.
- The web app is not running on the same origin used during provider initiation.

## Step 12: Production hardening

Before going live:

1. Move all provider secrets to a secure secret store.
2. Set the production backend callback URL explicitly if a reverse proxy is involved.
3. Restrict `AllowedCallbackOrigins` to the exact production frontend origins.
4. Enable only the providers that have completed provider review and app approval.
5. Verify the complete login and registration flow in a production-like environment.
6. Verify MFA for provider-linked `Admin` and `Moderator` accounts.

## Minimal example

This is a minimal development example for enabling Google:

```json
{
  "Authentication": {
    "ExternalProviders": {
      "AllowedCallbackOrigins": [
        "http://localhost:8080"
      ],
      "Providers": {
        "google": {
          "Enabled": true,
          "ClientId": "<google-client-id>",
          "ClientSecret": "<google-client-secret>"
        }
      }
    }
  }
}
```

Do not commit real credentials into `appsettings.json` or `appsettings.Development.json`.
