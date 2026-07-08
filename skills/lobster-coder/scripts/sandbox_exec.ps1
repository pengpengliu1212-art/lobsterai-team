#!/usr/bin/env pwsh
# ========================================
# lobster-coder sandbox wrapper (Windows) — "public image" version
# Per M2 2026-07-08: sandbox-first dev policy
# Image: node:20-alpine (Docker Hub official)
# Tools we install in workspace (if missing): pnpm (via corepack)
# ========================================

$ErrorActionPreference = "Stop"

$ROLE = "lobster-coder"
$IMAGE = if ($env:LOBSTERAI_IMAGE) { $env:LOBSTERAI_IMAGE } else { "node:20-alpine" }
$WORKSPACE_HOST = "H:\software-dev-Lob"
$WORKSPACE_CONT = "/workspace"
$LOG_DIR = "H:\software-dev-Lob\lobsterai-team\logs\$ROLE"

if (-not (Test-Path $LOG_DIR)) { New-Item -ItemType Directory -Force -Path $LOG_DIR | Out-Null }

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$logFile = Join-Path $LOG_DIR "$timestamp.log"

if ($args.Count -eq 0) {
    Write-Error "[sandbox] $ROLE requires at least 1 arg (e.g., node --version)"
    exit 2
}

# Production mode: pin by digest (immutable)
$PRODUCTION_MODE = if ($env:LOBSTERAI_PRODUCTION -eq "1") { $true } else { $false }
$DIGEST_PINNED_IMAGES = @{
    "python:3.12-alpine"        = "python:3.12-alpine@sha256:6d43704baacd1bfbe7c295d7f13079d5d8104ed33568873133f8fc69980419df"
    "node:20-alpine"             = "node:20-alpine@sha256:fb4cd12c85ee03686f6af5362a0b0d56d50c58a04632e6c0fb8363f609372293"
    "alpine:latest"              = "alpine:latest@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b"
    "lobsterai-team-devops:latest" = ""
    "lobsterai-team-data:latest"   = ""
}
if ($PRODUCTION_MODE -and $DIGEST_PINNED_IMAGES.ContainsKey($IMAGE) -and $DIGEST_PINNED_IMAGES[$IMAGE]) {
    $IMAGE = $DIGEST_PINNED_IMAGES[$IMAGE]
    Write-Host "[sandbox] production mode: using digest-pinned image"
}

docker image inspect $IMAGE 2>&1 | Tee-Object -FilePath $logFile -Append | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[sandbox] pulling image $IMAGE ..." -ForegroundColor Yellow
    docker pull $IMAGE 2>&1 | Tee-Object -FilePath $logFile -Append
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[sandbox] docker pull FAILED for $IMAGE (exit code $LASTEXITCODE). Check network or image name."
        exit $LASTEXITCODE
    }
}

Write-Host "[sandbox] $ROLE running: $($args -join ' ')"
Write-Host "[sandbox] image: $IMAGE (public/upstream)"
Write-Host "[sandbox] log: $logFile"

$dockerArgs = @(
    "run", "--rm",
    "--read-only",
    "--tmpfs", "/tmp:rw,size=500m",
    "--tmpfs", "/root:rw,size=200m",
    "--cap-drop=ALL",
    "--cpus=2",
    "--memory=2g",
    "--pids-limit=256",
    "--network=bridge",
    "-v", "${WORKSPACE_HOST}:${WORKSPACE_CONT}:rw",
    "-w", $WORKSPACE_CONT,
    "-e", "ROLE_NAME=$ROLE",
    "-e", "ROLE_TYPE=expert",
    "-e", "NODE_ENV=development",
    $IMAGE
) + $args

& docker @dockerArgs 2>&1 | Tee-Object -FilePath $logFile -Append
exit $LASTEXITCODE
