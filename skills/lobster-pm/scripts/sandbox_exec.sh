#!/usr/bin/env bash
# ========================================
# lobster-pm sandbox wrapper (macOS / Linux)
# Runs lobster-pm's commands inside an isolated Docker container
# Image: python:3.12-alpine
# ========================================

set -eu

ROLE="lobster-pm"
IMAGE="python:3.12-alpine"
WORKSPACE_HOST="${WORKSPACE_HOST:-$HOME/software-dev-Lob}"
WORKSPACE_CONT="/workspace"

# Pull image if missing
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    docker pull "$IMAGE" >/dev/null
fi

echo "[sandbox] $ROLE running: $*"

# Build docker run; direct invocation without pipe so exit code is unambiguous
exec docker run --rm \
    --read-only \
    --tmpfs /tmp:rw,size=200m \
    --cap-drop=ALL \
    --network=bridge \
    -v "$WORKSPACE_HOST:$WORKSPACE_CONT:rw" \
    -w "$WORKSPACE_CONT" \
    -e "ROLE_NAME=$ROLE" \
    -e "ROLE_TYPE=expert" \
    "$IMAGE" \
    "$@"
