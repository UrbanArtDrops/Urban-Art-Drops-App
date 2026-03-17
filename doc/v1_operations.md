# V1 Operations

## Environments
- dev
- prod

## Required configuration
- ConnectionStrings__SqlServer
- SMTP host settings
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
- Local registration persists the selected account type directly on the user account record
- Hunters are approved immediately after registration, while Artist and Drop-Maker accounts remain pending until admin approval
- Local login consumes the stored backend role and identity payload instead of accepting a client-side role selection
- Admin accounts are only created or assigned through the user-management flow

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
- Artwork photos are selected locally in the client and stored as binary media in the backend database
- Model-based artworks additionally upload a binary 3D asset that remains replaceable in edit mode and downloadable from the detail view

## Drop-Maker Wizard
- Drop creation in the web client is a multi-step process: artwork review, artwork selection, production confirmation, quantity capture, QR review, placement and optional publish
- The wizard persists a draft drop through `POST /api/drops` before the QR step so the backend becomes the source of truth for item and token generation
- After the QR step, the wizard can be paused and later resumed from My Drops by reopening the stored draft drop
- Returning to the quantity step updates the draft by preserving claimed items and keeping existing reusable QR tokens whenever possible
- Final placement writes coordinates and location photos through `PUT /api/drops/{id}` and can publish the drop immediately afterwards
