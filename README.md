# docker-sonarr-custom

Custom Sonarr Docker image built from source, using the linuxserver.io base image infrastructure (s6-overlay, Alpine 3.23).

## What this does

- Multi-stage build: compiles Sonarr .NET backend + React frontend from source
- Packages into `ghcr.io/linuxserver/baseimage-alpine:3.23` — identical runtime to the official linuxserver/sonarr image
- Pushes to `ghcr.io/alexmasson/sonarr-custom` via GitHub Actions

## Build locally

```bash
# From this directory, with Sonarr source at ../Sonarr
docker build --build-arg BUILD_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ) --build-arg VERSION=local -t sonarr-custom:local .
```

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

## GitHub Actions

On push to `main`, the workflow:
1. Checks out this repo + AlexMasson/Sonarr (branch `v5-develop`)
2. Builds the Docker image
3. Pushes to `ghcr.io/alexmasson/sonarr-custom` with tags: `latest`, commit SHA, date

## Architecture

Same as linuxserver/docker-sonarr:
- Base: Alpine 3.23 + s6-overlay
- App at `/app/sonarr/bin`
- Config at `/config`
- Port 8989
- PUID/PGID support
- Read-only filesystem support
