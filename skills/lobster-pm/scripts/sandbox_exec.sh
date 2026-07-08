#!/usr/bin/env bash
# ========================================
# lobster-pm sandbox wrapper (macOS / Linux)
# Runs PM's commands inside an isolated Docker container
# Image: python:3.12-alpine (lightweight, for analysis + docs)
# ========================================

set -euo pipefail

ROLE="lobster-pm"
IMAGE="python:3.12-alpine"
WORKSPACE_HOST="${WORKSPACE_HOST:-$HOME/software-dev-Lob}"
WORKSPACE_CONT="/workspace"
LOG_DIR="$(dirname "$(readlink -f "$0")")/../../logs/$ROLE"
LOG_DIR="$(cd "$(dirname "$LOG_DIR")" && pwd)/$(basename "$LOG_DIR")"

mkdir -p "$LOG_DIR"

timestamp="$(date +%Y%m%d-%H%M%S)"
logFile="$LOG_DIR/$timestamp.log"

# Pull image if missing
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "[sandbox] pulling image $IMAGE ..."
    docker pull "$IMAGE" >/dev/null
fi

echo "[sandbox] $ROLE running: $*"
echo "[sandbox] log: $logFile"

# Build docker run
docker run --rm \
    --read-only \
    --tmpfs /tmp:rw,size=200m \
    --cap-drop=ALL \
    --network=bridge \
    -v "$WORKSPACE_HOST:$WORKSPACE_CONT:rw" \
    -w "$WORKSPACE_CONT" \
    -e "ROLE_NAME=$ROLE" \
    -e "ROLE_TYPE=expert" \
    "$IMAGE" \
    "$@" 2>&1 | tee "$logFile"
exit "${PIPESTATUS[0]}"
