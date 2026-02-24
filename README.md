# docker-sonarr-custom

Custom Sonarr Docker image built from source, using the linuxserver.io base image infrastructure (s6-overlay, Alpine 3.23).

Builds from `AlexMasson/Sonarr_working` (private repo, branch `feature/external_hook`).

## How it works

GitHub Actions workflow:
1. Checks out this repo + `AlexMasson/Sonarr_working`
2. Multi-stage Docker build (SDK .NET 10 → Node 20 → Alpine 3.23 linuxserver base)
3. Pushes to `ghcr.io/alexmasson/sonarr-custom` with tags: `latest`, commit SHA, date

## Setup

The workflow needs a `SONARR_REPO_TOKEN` secret (a PAT with `repo` scope) to access the private `Sonarr_working` repo. Set it in the repo settings under Settings > Secrets > Actions.

## Deploy on server

```yaml
services:
  sonarr:
    image: ghcr.io/alexmasson/sonarr-custom:latest
    container_name: sonarr-custom
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Europe/Paris
    volumes:
      - ./config:/config
      - /path/to/tvseries:/tv
      - /path/to/downloads:/downloads
    ports:
      - 8989:8989
    restart: unless-stopped
```

## Runtime architecture

Same as linuxserver/docker-sonarr:
- Base: Alpine 3.23 + s6-overlay
- App at `/app/sonarr/bin`
- Config at `/config`
- Port 8989
- PUID/PGID support
- Read-only filesystem support
