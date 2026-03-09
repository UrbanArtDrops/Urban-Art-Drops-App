# V1 Operations

## Environments
- dev
- prod

## Required configuration
- ConnectionStrings__SqlServer
- SMTP host settings
- Map radius configuration

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
