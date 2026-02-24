<#
.SYNOPSIS
    Build and push the custom Sonarr Docker image to GHCR.
.DESCRIPTION
    Runs from the parent __arr/ directory as Docker build context.
    Builds the image from local Sonarr source and pushes to ghcr.io/alexmasson/sonarr-custom.
.PARAMETER Tag
    Image tag (default: latest)
.PARAMETER NoPush
    Build only, don't push
#>
param(
    [string]$Tag = "latest",
    [switch]$NoPush
)

$ErrorActionPreference = "Stop"
$ImageName = "ghcr.io/alexmasson/sonarr-custom"
$BuildDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$Version = (git -C "$PSScriptRoot\..\Sonarr" rev-parse --short HEAD 2>$null) ?? "local"
$ContextDir = Split-Path $PSScriptRoot -Parent  # __arr/

Write-Host "=== Building $ImageName`:$Tag ===" -ForegroundColor Cyan
Write-Host "  Context:    $ContextDir"
Write-Host "  Dockerfile: docker-sonarr-custom/Dockerfile"
Write-Host "  Version:    $Version"
Write-Host "  Date:       $BuildDate"
Write-Host ""

docker build `
    -f "$PSScriptRoot\Dockerfile" `
    --build-arg "BUILD_DATE=$BuildDate" `
    --build-arg "VERSION=$Version" `
    -t "${ImageName}:${Tag}" `
    -t "${ImageName}:${Version}" `
    $ContextDir

if ($LASTEXITCODE -ne 0) {
    Write-Error "Docker build failed"
    exit 1
}

Write-Host "`n=== Build complete ===" -ForegroundColor Green

if (-not $NoPush) {
    Write-Host "`n=== Pushing to GHCR ===" -ForegroundColor Cyan

    # Login to GHCR (uses gh CLI token)
    $token = gh auth token
    $token | docker login ghcr.io -u AlexMasson --password-stdin

    docker push "${ImageName}:${Tag}"
    docker push "${ImageName}:${Version}"

    Write-Host "`n=== Push complete ===" -ForegroundColor Green
    Write-Host "  $ImageName`:$Tag"
    Write-Host "  $ImageName`:$Version"
} else {
    Write-Host "  Skipped push (use without -NoPush to push)"
}
