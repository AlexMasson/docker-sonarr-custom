# syntax=docker/dockerfile:1

# ============================================================
# Stage 1: Build Sonarr backend from source
# ============================================================
FROM mcr.microsoft.com/dotnet/sdk:10.0-alpine AS builder

WORKDIR /src

COPY Sonarr/global.json Sonarr/global.json
COPY Sonarr/src/ Sonarr/src/

RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet restore Sonarr/src/NzbDrone.Console/Sonarr.Console.csproj \
        -r linux-musl-x64

RUN --mount=type=cache,target=/root/.nuget/packages \
    dotnet publish Sonarr/src/NzbDrone.Console/Sonarr.Console.csproj \
        -f net10.0 \
        -c Release \
        -r linux-musl-x64 \
        --self-contained \
        --no-restore \
        -p:TreatWarningsAsErrors=false \
        -o /build/sonarr/bin

# ============================================================
# Stage 2: Build Sonarr frontend
# ============================================================
FROM node:20-alpine AS frontend

WORKDIR /app

COPY Sonarr/package.json Sonarr/yarn.lock ./
COPY Sonarr/tsconfig.json ./
COPY Sonarr/frontend/ frontend/

RUN yarn install --frozen-lockfile && yarn build

# ============================================================
# Stage 3: Final image — identical to linuxserver/docker-sonarr
# ============================================================
FROM ghcr.io/linuxserver/baseimage-alpine:3.23

ARG BUILD_DATE
ARG VERSION
LABEL build_version="AlexMasson custom build:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="AlexMasson"

ENV XDG_CONFIG_HOME="/config/xdg" \
    SONARR_CHANNEL="v4-stable" \
    SONARR_BRANCH="main" \
    COMPlus_EnableDiagnostics=0 \
    TMPDIR=/run/sonarr-temp

RUN apk add --no-cache \
        icu-libs \
        sqlite-libs \
        xmlstarlet

COPY --from=builder /build/sonarr/bin /app/sonarr/bin
COPY --from=frontend /app/_output/UI /app/sonarr/bin/UI

RUN rm -rf /app/sonarr/bin/Sonarr.Update && \
    echo -e "UpdateMethod=docker\nBranch=${SONARR_BRANCH}\nPackageVersion=${VERSION:-LocalBuild}\nPackageAuthor=AlexMasson" > /app/sonarr/package_info && \
    printf "AlexMasson custom version: ${VERSION}\nBuild-date: ${BUILD_DATE}" > /build_version

COPY root/ /

EXPOSE 8989
VOLUME /config
