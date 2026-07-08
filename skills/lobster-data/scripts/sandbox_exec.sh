#!/usr/bin/env bash
# ========================================
# lobster-data sandbox wrapper (macOS / Linux)
# Runs Data's commands inside an isolated Docker container
# Image: lobsterai-team-data:latest
# ========================================

set -euo pipefail

ROLE="lobster-data"
IMAGE="lobsterai-team-data:latest"
WORKSPACE_HOST="${WORKSPACE_HOST:-$HOME/software-dev-Lob}"
WORKSPACE_CONT="/workspace"
LOG_DIR="$(dirname "$(readlink -f "$0")")/../../logs/$ROLE"
LOG_DIR="$(cd "$(dirname "$LOG_DIR")" && pwd)/$(basename "$LOG_DIR")"

mkdir -p "$LOG_DIR"

timestamp="$(date +%Y%m%d-%H%M%S)"
logFile="$LOG_DIR/$timestamp.log"

# Pull image if missing
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "[sandbox] pulling image $IMAGE (this may take a minute) ..."
    docker pull "$IMAGE" >/dev/null
fi

echo "[sandbox] $ROLE running: $*"
echo "[sandbox] log: $logFile"

docker run --rm \
    --read-only \
    --tmpfs /tmp:rw,size=500m \
    --tmpfs /root:rw,size=200m \
    --cap-drop=ALL \
    --security-opt no-new-privileges \
    --network=bridge \
    -v "$WORKSPACE_HOST:$WORKSPACE_CONT:rw" \
    -w "$WORKSPACE_CONT" \
    -e "ROLE_NAME=$ROLE" \
    -e "ROLE_TYPE=expert" \
    "$IMAGE" \
    "$@" 2>&1 | tee "$logFile"
exit "${PIPESTATUS[0]}"
