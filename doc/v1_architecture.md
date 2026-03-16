# Urban Art Drops V1 Architecture

## Runtime
- Backend: ASP.NET Core HTTP API on .NET 9
- Data: SQL Server Express (fallback InMemory for local bootstrap)
- Frontend: Flutter Android, iOS, Web
- Deployment: one self-hosted container host (dev/prod)

## Security
- Local auth with min length 16 and special character
- Provider login (Google, Facebook, Instagram, TikTok)
- MFA for Admin and Moderator (planned app-based challenge in auth boundary)
- Exponential login backoff: 15s, 30s, 60s, 120s

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
- Re-entering the quantity step of the drop-maker wizard preserves existing claimed and reusable QR items instead of recreating the entire item set on every update
- The drop-maker wizard finishes the flow by updating location coordinates, uploading local location photos as data URLs and optionally publishing the completed drop

## Discovery and Map Rendering
- Fully claimed drops are rendered as exact-position pins
- Not fully claimed drops are rendered as map radius overlays (no pin)
- The unclaimed drop radius is read from admin configuration (`UnclaimedDropRadiusKm`)
- Clicking a drop mini-map in the drop list opens the map view and focuses that drop

## Operations
- Alerts via SMTP mail for reported content and account approval requests
- Backup target: daily with 14-day retention
- Log retention target: 30 days
