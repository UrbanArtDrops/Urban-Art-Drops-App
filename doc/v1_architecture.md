# Urban Art Drops V1 Architecture

## Runtime
- Backend: ASP.NET Core HTTP API on .NET 9
- Data: SQL Server / LocalDB for all runtime environments
- Frontend: Flutter Android, iOS, Web
- Deployment: one self-hosted container host (dev/prod)

## Security
- Local auth with min length 16 and special character
- Provider login (Google, Facebook, Instagram, TikTok)
- MFA for Admin and Moderator (planned app-based challenge in auth boundary)
- Exponential login backoff: 15s, 30s, 60s, 120s
- Local self-registration stores the requested account role in the database at creation time; Hunters are auto-approved while Artist and Drop-Maker accounts remain pending until an admin approves them
- Local login no longer asks the client to pick a role; the API returns the stored role and identity payload for the session

## Core Domain Rules
- Art piece requires title, description and at least one photo before publish
- Drop requires location, location photo and at least one item before publish
- Each drop item has unique QR token
- One claim per hunter per drop
- Anonymous nickname cannot collide with registered usernames
- Art piece photos and drop location photos are stored as binary payloads in the database and served through media endpoints
- 3D artwork assets are stored as binary payloads in the database, exposed through dedicated media endpoints and surfaced to the Flutter client as downloadable asset references
- Art piece CRUD supports full metadata updates for artist assignment, asset type, title, description, publish state and photo set
- Art piece CRUD also supports 3D model upload, replacement and download, while model artworks require a stored asset before publish
- The Flutter artist workspace uploads local artwork photos as data URLs, which the API resolves into persisted binary media records
- The Flutter drop-maker wizard creates a persisted draft drop before placement, so item quantities and backend-generated QR tokens are available mid-process
- Persisted draft drops can be paused after QR generation and resumed later from the My Drops list by reopening the wizard with the stored drop identifier
- Re-entering the quantity step of the drop-maker wizard preserves existing claimed and reusable QR items instead of recreating the entire item set on every update
- The drop-maker wizard finishes the flow by updating location coordinates, uploading local location photos as data URLs and optionally publishing the completed drop
- Drop detail now loads persisted comments from the API, allows eligible signed-in roles to post comments, and exposes report actions for comments and linked art pieces
- Reported comments and art pieces are persisted with reason and timestamp metadata so the moderation queue can be resolved without losing audit context
- Artists can access reported drop comments that belong to drops created from their own art pieces, while moderator and admin users continue to manage the global queue and art-piece moderation actions

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
- Backup target: daily with 14-day retention
- Log retention target: 30 days
