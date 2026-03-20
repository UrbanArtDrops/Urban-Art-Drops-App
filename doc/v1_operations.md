# V1 Operations

## Environments
- dev
- prod

## Required configuration
- ConnectionStrings__SqlServer
- Authentication__Jwt__Issuer
- Authentication__Jwt__Audience
- Authentication__Jwt__SigningKey
- Authentication__ExternalProviders__AllowedCallbackOrigins
- Authentication__ExternalProviders__Providers__<provider>__Enabled
- Authentication__ExternalProviders__Providers__<provider>__ClientId
- Authentication__ExternalProviders__Providers__<provider>__ClientSecret
- SMTP host settings
- Public app base URL setting
- Map radius configuration
  - `MainMapRadiusKm` (default 30)
  - `MiniMapRadiusKm` (default 5)
  - `UnclaimedDropRadiusKm` (default 3)
  - `ShowExactPositionWhenFullyClaimed`
- Drop-list and My Drops mini-maps read `UnclaimedDropRadiusKm` to render not fully claimed drops as a radius instead of a pin

## Database bootstrap
- The API requires `ConnectionStrings__SqlServer` and will not start without a SQL Server or LocalDB connection string
- On startup the API applies pending EF Core migrations to the configured relational database
- Only the application configuration row is bootstrapped automatically; demo users, demo drops and other sample content are no longer seeded

## Media storage
- Drop and art photos are persisted as binary data in SQL tables
- 3D artwork assets are persisted as binary data in SQL tables with file name and content type metadata
- Clients receive media URLs from API responses and load image content through `/api/media/*` endpoints
- Artwork detail screens and the drop-maker wizard use the asset media URL to trigger real client-side downloads for 3D production files

## Authentication
- Step-by-step provider setup is documented in `doc/auth_provider_setup.md`
- Local and provider self-service registration always create an approved Hunter account
- Provider registration still persists provider and provider subject on the linked account record, but role upgrades happen later through the user profile
- Hunters request Artist or Drop-Maker access from `My profile`, and admin user management approves or rejects those pending role applications
- Local login consumes the stored backend role and identity payload instead of accepting a client-side role selection
- Provider login consumes the stored provider link and returns the same JWT session payload as local login
- `GET /api/auth/providers` returns only the providers that are currently login-ready according to backend configuration, and the public auth screens render exactly that list
- Provider login and registration start with `POST /api/auth/provider-login/begin` or `POST /api/auth/provider-register/begin`, redirect through the configured provider, and finish through the backend callback `/api/auth/provider/callback` plus the one-time completion endpoint `POST /api/auth/provider/complete`
- The Flutter client follows the same browser-driven pattern as common Firebase federated-auth examples, but keeps the full token exchange on the backend and only receives the final application session
- Each enabled provider can override endpoints, scopes, redirect URIs, PKCE behavior, token field names, and user-info JSON paths through `Authentication:ExternalProviders`
- If no admin exists yet, `/api/bootstrap/status` exposes the bootstrap state and `/api/bootstrap/admin` can create the first approved and verified local admin account
- After the first admin exists, admin and moderator accounts are created or assigned only through the user-management flow
- Local login returns a JWT bearer token with expiry metadata and the Flutter client attaches that token automatically to protected API calls
- Admin and Moderator logins require a TOTP-based MFA challenge; the login call returns a setup or verification challenge and the access token is only issued after `/api/auth/mfa/complete`
- While an MFA setup or verification challenge is active, the login screen hides the other authentication forms and shows only the MFA step
- Authenticated users can call `/api/profile` to read or update their own email address, display name, and optional profile image without entering the admin area
- Authenticated users can start MFA setup through `/api/profile/mfa/setup` and disable an existing authenticator through `/api/profile/mfa/disable`
- Hunters can submit role applications through `POST /api/profile/role-application`, and the profile response includes the pending target role plus the request timestamp
- Startup route guards redirect unauthenticated users away from protected artist, drop-maker, moderation and admin screens to `/auth/login`
- The drawer navigation hides login/register entries for authenticated sessions and exposes a logout action instead
- Admin endpoints require an authenticated admin token; moderation endpoints require a moderator/admin token or the scoped artist/drop-maker ownership rules enforced by the API
- For local development without an explicit signing key, the API can run with an ephemeral process-local JWT key; use user-secrets or environment variables when sessions must survive API restarts
- Local IDE launch profiles must set `ASPNETCORE_ENVIRONMENT=Development` or `DOTNET_ENVIRONMENT=Development` so the development-only JWT fallback is available during debugging
- Local IDE launch profiles must use the API project directory as the working directory so `appsettings.json` and `appsettings.Development.json` are loaded and the SQL connection string is available at startup
- Flutter Web must serve `frontend/web/auth.html` so the browser callback can hand the `provider_session` back into the app; Android declares the custom scheme `urbanartdrops-auth://oauth/callback` for native callback handling
- `GET /api/admin/configuration` now returns the persisted app configuration together with the current provider-status snapshot used by the admin settings screen
- Admin user management supports editing both user name and email address after account creation
- Admin user management also exposes approve/reject actions for pending Hunter role applications to Artist or Drop-Maker
- Admin role-application approvals and rejections update the affected user row directly from the API response instead of depending on an immediate full reload of the user list, and backend validation messages are surfaced in the UI
- The admin user list renders each account with role, approval and suspension icons plus the stored profile image when one is available
- Admin user management blocks self-lockout by preventing an admin from suspending their own account or revoking their own approval in both the API and the UI
- Profile images are served from `/api/media/user-profile-images/{id}` and remain inside the SQL-backed persistence model
- In-app profile notifications are available through `GET /api/profile/notifications` and can be acknowledged through `POST /api/profile/notifications/{notificationId}/mark-read`
- The profile screen loads `/api/profile` and `/api/profile/notifications` independently so a notification-loading failure does not hide the main profile data; the notification section shows a retry action instead

## Backup
- Daily backup job
- 14-day retention
- Encrypted and offsite storage (policy target)

## Monitoring and alerts
- Health endpoint: /api/health
- Mail alerts for:
- account approval requests
- reported comments
- reported art pieces

## Test isolation
- Integration tests override the runtime SQL registration with an in-memory EF Core database inside the test host
- Production and local runtime keep the relational SQL path enabled at all times

## Moderation
- Public users can report drop comments and linked art pieces from the drop detail page
- Moderators and admins process reports through `GET /api/moderation/reports`
- Artists can review and resolve reported comments for drops that reference their own art pieces
- Drop-makers can review and resolve reported comments for drops they created
- Comment moderation supports hide and dismiss flows through the moderation endpoints
- Art-piece moderation supports depublish and dismiss flows through the moderation endpoints

## Artist Workspace
- Artists manage artworks end-to-end in the web client: create, inspect, edit, publish, depublish and delete
- The artist artwork manager loads only art pieces created by the signed-in artist; admins use the same screen with full global scope
- Admins can open the same full artwork management screen to inspect and manage all artworks across artists
- Admin-triggered art-piece changes create persisted in-app notifications for the impacted artist accounts
- Artwork metadata includes an optional subtitle that is editable in the artist workspace and reused in discovery and drop creation screens
- Artwork photos are selected locally in the client and stored as binary media in the backend database
- Model-based artworks additionally upload a binary 3D asset that remains replaceable in edit mode and downloadable from the detail view

## Drop-Maker Wizard
- Drop creation in the web client is a multi-step process: artwork review, artwork selection, production confirmation, quantity capture, QR review, placement and optional publish
- The wizard persists a draft drop through `POST /api/drops` before the QR step so the backend becomes the source of truth for item and token generation
- QR review now shows the public claim URL for each generated item instead of only the raw token
- After the QR step, the wizard can be paused and later resumed from My Drops by reopening the stored draft drop
- Returning to the quantity step updates the draft by preserving claimed items and keeping existing reusable QR tokens whenever possible
- Draft and persisted drops store an optional drop-maker comment plus a selected list of social channels
- Final placement writes coordinates and location photos through `PUT /api/drops/{id}` and can publish the drop immediately afterwards
- Admins can open the same drop management area to inspect and manage all drops across drop-makers, and admin-triggered drop changes create persisted in-app notifications for the impacted drop-maker accounts

## Claim Flow
- `GET /api/claims/by-token/{qrToken}` returns a claim preview for app and browser fallback
- `POST /api/claims/by-token` resolves the QR token to the drop item and executes the claim
- Authenticated hunters claim under their JWT identity; anonymous users can only claim with a nickname and cannot impersonate a registered user id
- Public claim URLs use the persisted admin configuration field `PublicAppBaseUrl`; when it is empty the API falls back to the current request origin
