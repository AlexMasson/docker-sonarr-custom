# syntax=docker/dockerfile:1

# ============================================================
# Stage 1: Build Sonarr from source
# ============================================================
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS builder

ARG TARGETPLATFORM

WORKDIR /src

# Copy solution and restore
COPY Sonarr/src/NuGet.Config Sonarr/src/NuGet.Config
COPY Sonarr/src/Sonarr.sln Sonarr/src/Sonarr.sln
COPY Sonarr/src/Directory.Build.props Sonarr/src/Directory.Build.props
COPY Sonarr/src/Directory.Build.targets Sonarr/src/Directory.Build.targets
COPY Sonarr/global.json Sonarr/global.json

# Copy all project files for restore
COPY Sonarr/src/ Sonarr/src/

RUN --mount=type=cache,target=/root/.nuget/packages \
    RUNTIME="linux-musl-x64" && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then RUNTIME="linux-musl-arm64"; fi && \
    dotnet restore Sonarr/src/Sonarr.sln -r "$RUNTIME"

# Build and publish
COPY Sonarr/ Sonarr/

RUN --mount=type=cache,target=/root/.nuget/packages \
    RUNTIME="linux-musl-x64" && \
    if [ "$TARGETPLATFORM" = "linux/arm64" ]; then RUNTIME="linux-musl-arm64"; fi && \
    dotnet publish Sonarr/src/NzbDrone.Console/Sonarr.Console.csproj \
        -c Release \
        -r "$RUNTIME" \
        --self-contained \
        --no-restore \
        -o /build/sonarr/bin && \
    # Build frontend
    echo "Backend build complete"

# Build frontend
FROM node:20-alpine AS frontend

WORKDIR /src
COPY Sonarr/package.json Sonarr/package.json
COPY Sonarr/frontend/ Sonarr/frontend/

WORKDIR /src/Sonarr
RUN yarn install --frozen-lockfile && yarn build

# ============================================================
# Stage 2: Final image — identical to linuxserver/docker-sonarr
# ============================================================
FROM ghcr.io/linuxserver/baseimage-alpine:3.23

ARG BUILD_DATE
ARG VERSION
LABEL build_version="AlexMasson custom build:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="AlexMasson"

# Environment — same as linuxserver
ENV XDG_CONFIG_HOME="/config/xdg" \
    SONARR_CHANNEL="v4-stable" \
    SONARR_BRANCH="main" \
    COMPlus_EnableDiagnostics=0 \
    TMPDIR=/run/sonarr-temp

RUN \
    echo "**** install packages ****" && \
    apk add --no-cache \
        icu-libs \
        sqlite-libs \
        xmlstarlet

# Copy built Sonarr binaries
COPY --from=builder /build/sonarr/bin /app/sonarr/bin

# Copy built frontend
COPY --from=frontend /src/Sonarr/_output/UI /app/sonarr/bin/UI

# Remove update mechanism (not needed in Docker)
RUN rm -rf /app/sonarr/bin/Sonarr.Update

# Write package info
RUN echo -e "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${VERSION:-LocalBuild}\nPackageAuthor=AlexMasson" > /app/sonarr/package_info && \
    printf "AlexMasson custom version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version

# Add s6-overlay service definitions (identical to linuxserver)
COPY root/ /

EXPOSE 8989
VOLUME /config
