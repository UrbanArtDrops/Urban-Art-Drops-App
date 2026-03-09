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
