# Urban Art Drops V1 Architecture

## Runtime
- Backend: ASP.NET Core HTTP API on .NET 9
- Data: SQL Server / LocalDB for all runtime environments
- Frontend: Flutter Android, iOS, Web
- Deployment: one self-hosted container host (dev/prod)

## Security
- Local auth with min length 16 and special character
- Provider login and provider registration (Google, Facebook, Instagram, TikTok, Microsoft)
- Provider auth uses a backend-coordinated OAuth 2.0 / OIDC browser flow instead of Firebase: the Flutter client asks the API for an authorization URL, opens the system browser, and completes the login only after the backend callback has exchanged the authorization code and resolved the external identity
- App-based MFA for Admin and Moderator is enforced by the authentication boundary before an access token is issued
- Exponential login backoff: 15s, 30s, 60s, 120s
- Local and provider self-service registration always create an approved Hunter account first; Hunters request Artist or Drop-Maker access later from the main profile area, and admins approve or reject those role applications in user management
- Local login no longer asks the client to pick a role; the API returns the stored role and identity payload for the session
- The API now issues bearer access tokens for local login and enforces authorization policies at the endpoint boundary for admin, moderation, artist and drop-creator workflows
- Moderation and admin actions no longer trust caller-supplied user headers; the backend resolves the acting user from validated JWT claims
- The Flutter client persists the authenticated session locally and restores it on startup so route guards and API calls continue to use the server-issued access token across app reloads
- Provider login follows the same JWT session path as local login; privileged provider accounts also pass through the same MFA challenge and completion flow
- External provider sessions are short-lived server-side pending/completed login states held in memory; the browser callback only returns an opaque completion session back to the app, never raw provider tokens
- The login and provider-registration screens render only those providers that the backend currently exposes as login-ready, so the public UI reflects actual runtime configuration instead of a static provider list
- Signed-in users manage their own profile under `My profile`, including email address, display name, profile image, and app-based MFA lifecycle actions
- Hunter profiles also expose self-service role application actions for Artist and Drop-Maker access, plus the current pending application state and request timestamp
- Profile images are stored as binary blobs in SQL and served through dedicated media endpoints instead of file-system paths
- The profile area also surfaces persisted in-app notifications so ownership-impacting system events can be reviewed without relying on external mail delivery

## Core Domain Rules
- Art piece requires title, description and at least one photo before publish
- Art pieces support a dedicated optional subtitle field that is stored separately from the title and exposed across artist, discovery and drop-maker flows
- Drop requires location, location photo and at least one item before publish
- Each drop item has unique QR token
- One claim per hunter per drop
- Anonymous nickname cannot collide with registered usernames
- Art piece photos and drop location photos are stored as binary payloads in the database and served through media endpoints
- 3D artwork assets are stored as binary payloads in the database, exposed through dedicated media endpoints and surfaced to the Flutter client as downloadable asset references
- Art piece CRUD supports full metadata updates for artist assignment, asset type, title, description, publish state and photo set
- Art piece CRUD also supports 3D model upload, replacement and download, while model artworks require a stored asset before publish
- The authenticated art-piece manager scope is ownership-aware: artists only receive their own art pieces for management, while admins retain the global cross-artist view
- The Flutter artist workspace uploads local artwork photos as data URLs, which the API resolves into persisted binary media records
- Admin users can use the same management flows to edit any art piece and any drop across the platform instead of being limited to their own ownership scope
- The Flutter drop-maker wizard creates a persisted draft drop before placement, so item quantities and backend-generated QR tokens are available mid-process
- Persisted draft drops can be paused after QR generation and resumed later from the My Drops list by reopening the wizard with the stored drop identifier
- Re-entering the quantity step of the drop-maker wizard preserves existing claimed and reusable QR items instead of recreating the entire item set on every update
- The drop-maker wizard finishes the flow by updating location coordinates, uploading local location photos as data URLs and optionally publishing the completed drop
- Drops persist an optional drop-maker comment plus an explicit selection of target social channels so publication intent remains part of the domain model instead of UI-only state
- Drop detail now loads persisted comments from the API, allows eligible signed-in roles to post comments, and exposes report actions for comments and linked art pieces
- Reported comments and art pieces are persisted with reason and timestamp metadata so the moderation queue can be resolved without losing audit context
- Artists can access reported drop comments that belong to drops created from their own art pieces, drop-makers can access reported drop comments for their own drops, and moderator/admin users continue to manage the global queue and art-piece moderation actions
- Every drop item now exposes a public claim URL that points to the web claim route with the QR token as query parameter
- Claim preview and claim completion can resolve the drop item directly from the QR token, so app-deep links and browser fallback share the same backend flow

## Discovery and Map Rendering
- Fully claimed drops are rendered as exact-position pins
- Not fully claimed drops are rendered as map radius overlays (no pin)
- The unclaimed drop radius is read from admin configuration (`UnclaimedDropRadiusKm`)
- Clicking a drop mini-map in the drop list opens the map view and focuses that drop
- Drop-list and My Drops mini-maps mirror the same radius-overlay rule for not fully claimed drops

## Operations
- Alerts via SMTP mail for reported content and account approval requests
- Moderator and admin users resolve reports in a dedicated moderation queue with comment hide, report dismissal, and art-piece depublish actions
- Runtime startup applies EF Core migrations against the configured SQL database and only bootstraps application configuration defaults
- Debug and sample content seeding is disabled; a fresh database starts without demo users, art pieces, drops, comments, or reports
- External providers are configured centrally under `Authentication:ExternalProviders`; built-in provider defaults are supplied for Google, Facebook, Instagram, TikTok, and Microsoft and can be overridden per environment with client ids, secrets, scopes, endpoints, redirect URIs, PKCE, and JSON field mappings
- Flutter Web completes browser auth through `web/auth.html`, while native/desktop clients use the custom callback scheme `urbanartdrops-auth://oauth/callback`
- When no admin exists yet, the platform exposes a one-time bootstrap flow that creates the first approved and verified local admin account; later admin and moderator assignments stay inside admin user management
- Admin user management can edit both user name and email address, in addition to approval, blocking and role changes
- Self-service profile changes update the persisted account record directly; the Flutter session mirrors changed email, display name, and profile image URL locally after save
- When an admin edits, publishes, depublishes, or deletes an art piece or drop, the impacted artist or drop-maker receives a persisted in-app notification linked to that entity
- JWT signing keys must be supplied outside source control for stable environments; local development can fall back to an ephemeral in-memory signing key for the running process
- Admin configuration is persisted in SQL and currently drives SMTP host, public app base URL, map radii and exact-position rendering behavior
- The admin configuration screen also shows the current external-provider status snapshot from backend configuration, including login visibility, client-id presence, client-secret presence, and PKCE usage
- Backup target: daily with 14-day retention
- Log retention target: 30 days
