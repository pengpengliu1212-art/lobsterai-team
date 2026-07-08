#!/usr/bin/env bash
# ========================================
# lobster-devops sandbox wrapper (macOS / Linux)
# Runs DevOps commands inside an isolated Docker container
# Image: alpine:latest
# Security: IMDS endpoint (169.254.169.254) blocked via iptables in container
# ========================================

set -euo pipefail

ROLE="lobster-devops"
IMAGE="lobsterai-team-devops:latest"
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

docker run --rm \
    --read-only \
    --tmpfs /tmp:rw,size=300m \
    --tmpfs /root:rw,size=100m \
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
