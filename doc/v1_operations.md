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

## Media storage
- Drop and art photos are persisted as binary data in SQL tables
- 3D artwork assets are persisted as binary data in SQL tables with file name and content type metadata
- Clients receive media URLs from API responses and load image content through `/api/media/*` endpoints
- Artwork detail screens and the drop-maker wizard use the asset media URL to trigger real client-side downloads for 3D production files

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

## Artist Workspace
- Artists manage artworks end-to-end in the web client: create, inspect, edit, publish, depublish and delete
- Artwork photos are selected locally in the client and stored as binary media in the backend database
- Model-based artworks additionally upload a binary 3D asset that remains replaceable in edit mode and downloadable from the detail view

## Drop-Maker Wizard
- Drop creation in the web client is a multi-step process: artwork review, artwork selection, production confirmation, quantity capture, QR review, placement and optional publish
- The wizard persists a draft drop through `POST /api/drops` before the QR step so the backend becomes the source of truth for item and token generation
- Returning to the quantity step updates the draft by preserving claimed items and keeping existing reusable QR tokens whenever possible
- Final placement writes coordinates and location photos through `PUT /api/drops/{id}` and can publish the drop immediately afterwards
