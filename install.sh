#!/usr/bin/env bash
# ========================================
# lobsterai-team installer for macOS / Linux
# Per Mechanical Rock 2026 bash best practice:
#   - env shebang (portable across distros)
#   - set -euo pipefail (strict mode)
#   - trap cleanup (capture exit code)
#   - idempotent (test -d before mkdir)
# ========================================

set -euo pipefail

# Trap ERR for error tracing (per Xygeni 2026 / NinjaOne 2026)
trap 'echo "[ERR] install.sh failed at line $LINENO (exit $?)" >&2' ERR

# TTY check for color output (per Linux style guides)
if [[ -t 1 ]]; then
    C_RED=$'\033[0;31m'; C_GREEN=$'\033[0;32m'; C_YELLOW=$'\033[0;33m'; C_CYAN=$'\033[0;36m'; C_OFF=$'\033[0m'
else
    C_RED=''; C_GREEN=''; C_YELLOW=''; C_CYAN=''; C_OFF=''
fi

# Defaults (override via env or flags)
WORKSPACE_ROOT="${LOBSTERAI_WORKSPACE:-$HOME/software-dev-Lob}"
SKIP_DASHBOARD=0
SKIP_SKILL_LINK=0
FORCE=0
DRY_RUN=0

# Parse flags
while [[ $# -gt 0 ]]; do
    case "$1" in
        --workspace-root) WORKSPACE_ROOT="$2"; shift 2 ;;
        --skip-dashboard) SKIP_DASHBOARD=1; shift ;;
        --skip-skill-link) SKIP_SKILL_LINK=1; shift ;;
        --force) FORCE=1; shift ;;
        --dry-run) DRY_RUN=1; shift ;;
        -h|--help)
            echo "Usage: install.sh [--workspace-root PATH] [--skip-dashboard] [--skip-skill-link] [--force] [--dry-run]"
            exit 0
            ;;
        *) echo "Unknown flag: $1" >&2; exit 1 ;;
    esac
done

# Helper: run or dry-run
do_or_print() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "[DRY-RUN] would run: $*"
    else
        "$@"
    fi
}

TEAM_ROOT="$WORKSPACE_ROOT/lobsterai-team"
LOG_DIR="$TEAM_ROOT/logs"
DASHBOARD_DIR="$TEAM_ROOT/dashboard"
OPENCLAW_SKILLS_DIR="$HOME/.openclaw/skills"
BIN_DIR="$TEAM_ROOT/bin"

# Announce dry-run mode early
if [[ $DRY_RUN -eq 1 ]]; then
    echo "[lobsterai-team] DRY-RUN mode: no changes will be made" >&2
fi

# Capture exit code
exit_code=0
cleanup() {
    local rc=$?
    if [[ $rc -ne 0 ]]; then
        echo "[ERR] install failed with exit code $rc" >&2
    fi
    exit $rc
}
trap cleanup EXIT

step() { echo -e "${C_CYAN}[lobsterai-team] $1${C_OFF}"; }
ok() { echo -e "${C_GREEN}[OK] $1${C_OFF}"; }
warn() { echo -e "${C_YELLOW}[WARN] $1${C_OFF}" >&2; }
err() { echo -e "${C_RED}[ERR] $1${C_OFF}" >&2; exit_code=1; }

# === Step 1: Verify Docker ===
step "1/6 Checking Docker availability..."
if ! command -v docker >/dev/null 2>&1; then
    err "docker command not found. Install Docker first."
else
    if docker version --format "{{.Server.Version}}" >/dev/null 2>&1; then
        docker_version=$(docker version --format "{{.Server.Version}}" 2>/dev/null)
        ok "Docker $docker_version"
    else
        warn "Docker installed but daemon not running. Start Docker first."
    fi
fi

# === Step 2: Verify workspace root ===
step "2/6 Verifying workspace root $WORKSPACE_ROOT..."
if [[ ! -d "$WORKSPACE_ROOT" ]]; then
    err "workspace root $WORKSPACE_ROOT does not exist. Use --workspace-root to override."
else
    ok "workspace root exists"
fi

# === Step 3: Create team root (idempotent) ===
step "3/6 Verifying team root at $TEAM_ROOT..."
if [[ ! -d "$TEAM_ROOT" ]]; then
    do_or_print mkdir -p "$TEAM_ROOT"
    ok "created $TEAM_ROOT"
else
    ok "team root already exists"
fi

# === Step 4: Verify sub-directories ===
step "4/6 Verifying lobsterai-team sub-directories..."
for sub in skills dashboard bin playbooks logs; do
    if [[ ! -d "$TEAM_ROOT/$sub" ]]; then
        do_or_print mkdir -p "$TEAM_ROOT/$sub"
        ok "created $sub/"
    else
        ok "$sub/ exists"
    fi
done

# === Step 5: Link skills to OpenClaw shared dir (best effort) ===
if [[ $SKIP_SKILL_LINK -eq 0 ]]; then
    step "5/6 Linking skills to $OPENCLAW_SKILLS_DIR..."
    if [[ ! -d "$OPENCLAW_SKILLS_DIR" ]]; then
        do_or_print mkdir -p "$OPENCLAW_SKILLS_DIR" 2>/dev/null || warn "could not create OpenClaw skills dir"
    fi
    if [[ -d "$TEAM_ROOT/skills" ]]; then
        for skill_dir in "$TEAM_ROOT/skills"/*/; do
            [[ -f "$skill_dir/SKILL.md" ]] || continue
            skill_name=$(basename "$skill_dir")
            link="$OPENCLAW_SKILLS_DIR/$skill_name"
            if [[ -L "$link" || -e "$link" ]] && [[ $FORCE -eq 0 ]]; then
                ok "skill $skill_name already linked (use --force to re-link)"
            else
                do_or_print rm -rf "$link"
                if [[ $DRY_RUN -eq 1 ]] || ln -s "$skill_dir" "$link" 2>/dev/null; then
                    [[ $DRY_RUN -eq 1 ]] && echo "[DRY-RUN] would link $skill_name -> $link" || ok "linked $skill_name -> $link"
                else
                    warn "could not link $skill_name (check permissions)"
                fi
            fi
        done
    fi
else
    step "5/6 Skipping skill linking (--skip-skill-link)"
fi

# === Step 6: Start dashboard (optional) ===
if [[ $SKIP_DASHBOARD -eq 0 ]]; then
    step "6/6 Starting dashboard..."
    if [[ -f "$DASHBOARD_DIR/start-dashboard.sh" ]]; then
        bash "$DASHBOARD_DIR/start-dashboard.sh" 2>/dev/null || warn "dashboard start script returned non-zero"
    elif [[ -f "$DASHBOARD_DIR/server.py" ]]; then
        python3 "$DASHBOARD_DIR/server.py" &
        ok "dashboard started in background (PID $!)"
    else
        warn "dashboard server not found"
    fi
else
    step "6/6 Skipping dashboard (--skip-dashboard)"
fi

# === Summary ===
echo
echo -e "${C_GREEN}========================================${C_OFF}"
echo -e "${C_GREEN}lobsterai-team install complete${C_OFF}"
echo -e "${C_GREEN}========================================${C_OFF}"
echo "Team root: $TEAM_ROOT"
echo "OpenClaw skills: $OPENCLAW_SKILLS_DIR"
echo "Dashboard: http://127.0.0.1:8080"
echo
echo "Next steps:"
echo "  lobster-team version"
echo "  lobster-team status"
echo "  lobster-team run lobster-pm python3 --version"

exit $exit_code
