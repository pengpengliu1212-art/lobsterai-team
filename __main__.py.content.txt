"""
lobster-team CLI — entry point.

Subcommands:
  init        Install lobsterai-team to a target directory
  status      Show sandbox + dashboard status
  run         Run a command in a role's sandbox
  logs        Tail logs (optionally filtered by role)
  dashboard   Manage the dashboard (start | stop | status)
  self-update Update lobsterai-team to latest
  version     Show version

Design: zero external dependencies (argparse from stdlib only).
Per Python CLI best practice 2026 + lobsterai-team "public/upstream" policy.
"""
import argparse
import json
import os
import subprocess
import sys
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path

# Locate team root relative to this file
CLI_DIR = Path(__file__).resolve().parent  # bin/lobster_team
TEAM_ROOT = CLI_DIR.parent.parent  # bin/lobster_team → bin/ → team_root
LOGS_ROOT = TEAM_ROOT / "logs"
DASHBOARD_DIR = TEAM_ROOT / "dashboard"
DASHBOARD_URL = "http://127.0.0.1:8080"

# Security: explicit role allowlist (per Semgrep 2026 / Snyk 2026)
ALLOWED_ROLES = frozenset({
    "lobster-pm", "lobster-architect", "lobster-coder",
    "lobster-qa", "lobster-devops", "lobster-data", "lobster-gm",
})


def _ok(msg):
    print(f"[OK] {msg}")


def _warn(msg):
    print(f"[WARN] {msg}", file=sys.stderr)


def _err(msg):
    print(f"[ERR] {msg}", file=sys.stderr)


# ----------------------------------------------------------------------------
# Subcommand: init
# ----------------------------------------------------------------------------
def cmd_init(args):
    """Install lobsterai-team to target directory."""
    target = Path(args.target).resolve()
    # Security: refuse paths outside home dir or /tmp (per Semgrep 2026)
    home = Path.home().resolve()
    tmp = Path("/tmp").resolve() if Path("/tmp").exists() else None
    in_safe = str(target).startswith(str(home))
    if tmp:
        in_safe = in_safe or str(target).startswith(str(tmp))
    if not in_safe and not getattr(args, "force", False):
        _err(f"refusing to init outside home dir or /tmp: {target}")
        _err("use --force to override (not recommended)")
        return 2
    target.mkdir(parents=True, exist_ok=True)
    _ok(f"initialized lobsterai-team at {target}")
    # Link skills into OpenClaw shared skills dir if available
    openclaw_dir = Path.home() / ".openclaw" / "skills"
    if openclaw_dir.parent.exists():
        openclaw_dir.mkdir(parents=True, exist_ok=True)
        for skill in (TEAM_ROOT / "skills").iterdir():
            if skill.is_dir() and (skill / "SKILL.md").exists():
                link = openclaw_dir / skill.name
                if not link.exists():
                    try:
                        link.symlink_to(skill.resolve(), target_is_directory=True)
                        _ok(f"linked skill {skill.name} -> {link}")
                    except OSError as e:
                        _warn(f"could not link {skill.name}: {e}")
    return 0


# ----------------------------------------------------------------------------
# Subcommand: status
# ----------------------------------------------------------------------------
def cmd_status(args):
    """Show sandbox + dashboard status."""
    data = {"team_root": str(TEAM_ROOT), "timestamp": datetime.now(timezone.utc).isoformat()}
    # Try to get live stats from dashboard
    dashboard_data = {}
    try:
        with urllib.request.urlopen(f"{DASHBOARD_URL}/api/stats", timeout=3) as r:
            dashboard_data = json.loads(r.read().decode("utf-8"))
        data["dashboard"] = "live"
        data.update(dashboard_data)
    except (urllib.error.URLError, ConnectionError, OSError):
        data["dashboard"] = "not running"
    # Count log files per role
    log_counts = {}
    if LOGS_ROOT.exists():
        for role_dir in sorted(LOGS_ROOT.iterdir()):
            if role_dir.is_dir():
                log_counts[role_dir.name] = sum(1 for _ in role_dir.glob("*.log"))
    data["log_files"] = log_counts

    # Output: --json for machine, text for human (default)
    if getattr(args, "json", False):
        print(json.dumps(data, indent=2))
        return 0
    # Human-friendly text output
    print(f"lobsterai-team status @ {data['timestamp']}")
    print(f"  team root: {data['team_root']}")
    print(f"  dashboard: {data['dashboard']}")
    if dashboard_data:
        for k in ("running_containers", "image_count", "logs_today", "starts_24h", "errors_24h"):
            print(f"  {k.replace('_', ' ')}: {dashboard_data.get(k, '?')}")
    if log_counts:
        print(f"  log files:")
        for role, count in log_counts.items():
            print(f"    {role}: {count} files")
    return 0


# ----------------------------------------------------------------------------
# Subcommand: run
# ----------------------------------------------------------------------------
def cmd_run(args):
    """Run a command in a role's sandbox."""
    role = args.role
    # Security: explicit allowlist (per Semgrep 2026 / Snyk 2026)
    if role not in ALLOWED_ROLES:
        _err(f"unknown role: {role}")
        _err(f"allowed roles: {sorted(ALLOWED_ROLES)}")
        return 2
    wrapper = TEAM_ROOT / "skills" / role / "scripts"
    if not wrapper.exists():
        _err(f"role {role} has no scripts dir at {wrapper}")
        return 2
    skill_md = TEAM_ROOT / "skills" / role / "SKILL.md"
    if not skill_md.exists():
        _err(f"role {role} missing SKILL.md at {skill_md}")
        return 2
    # Pick the right script for the platform
    if sys.platform == "win32":
        script = wrapper / "sandbox_exec.ps1"
    else:
        script = wrapper / "sandbox_exec.sh"
    if not script.exists():
        _err(f"wrapper not found: {script}")
        return 2
    # Make .sh executable
    if script.suffix == ".sh":
        os.chmod(script, 0o755)
    # Build command (Windows .ps1 must go through powershell.exe)
    if sys.platform == "win32":
        # Find PowerShell: prefer pwsh (PowerShell 7), fall back to Windows PowerShell 5.1
        ps_candidates = [
            r"C:\Program Files\PowerShell\7\pwsh.exe",
            r"C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe",
            r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
            "pwsh.exe",
            "powershell.exe",
        ]
        ps_exe = next((p for p in ps_candidates if os.path.exists(p)), "powershell.exe")
        cmd = [ps_exe, "-ExecutionPolicy", "Bypass", "-File", str(script), *args.command]
    else:
        cmd = [str(script), *args.command]
    if args.dry_run:
        _ok(f"DRY RUN: would execute: {' '.join(cmd)}")
        return 0
    return subprocess.call(cmd)


# ----------------------------------------------------------------------------
# Subcommand: logs
# ----------------------------------------------------------------------------
def cmd_logs(args):
    """Tail logs filtered by role."""
    role = args.role
    if role:
        log_dir = LOGS_ROOT / role
    else:
        log_dir = LOGS_ROOT
    if not log_dir.exists():
        _err(f"log directory not found: {log_dir}")
        return 2
    # Find the most recent log file
    logs = sorted(log_dir.rglob("*.log"), key=lambda p: p.stat().st_mtime, reverse=True)
    if not logs:
        _err(f"no log files in {log_dir}")
        return 2
    target = logs[0]
    # Security: verify log path stays under LOGS_ROOT (per Semgrep 2026 path safety)
    try:
        target_resolved = target.resolve()
        if not str(target_resolved).startswith(str(LOGS_ROOT.resolve())):
            _err(f"log path escapes LOGS_ROOT: {target_resolved}")
            return 2
    except OSError as e:
        _err(f"cannot resolve log path: {e}")
        return 2
    if args.follow:
        _ok(f"following {target} (Ctrl-C to exit)")
        if sys.platform == "win32":
            # Use PowerShell Get-Content -Wait (not GNU tail)
            return subprocess.call(
                ["powershell.exe", "-Command", f"Get-Content -Path '{target}' -Wait"]
            )
        return subprocess.call(["tail", "-f", str(target)])
    else:
        # Print last N lines
        n = args.lines
        with open(target, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        lines = content.splitlines()[-n:]
        for line in lines:
            print(line)
        return 0


# ----------------------------------------------------------------------------
# Subcommand: dashboard
# ----------------------------------------------------------------------------
def cmd_dashboard(args):
    """Manage the dashboard."""
    if args.action == "status":
        # Always check live, regardless of scripts
        try:
            with urllib.request.urlopen(f"{DASHBOARD_URL}/api/health", timeout=3) as r:
                print(f"dashboard: live ({r.status})")
                return 0
        except (urllib.error.URLError, OSError):
            print("dashboard: not running")
            return 1
    if args.action == "start":
        # On Windows, start via PowerShell; on Unix, direct python invocation
        if sys.platform == "win32":
            script = DASHBOARD_DIR / "start-dashboard.ps1"
            if script.exists():
                ps_candidates = [
                    r"C:\Program Files\PowerShell\7\pwsh.exe",
                    r"C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe",
                    r"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe",
                    "pwsh.exe",
                    "powershell.exe",
                ]
                ps_exe = next((p for p in ps_candidates if os.path.exists(p)), "powershell.exe")
                return subprocess.call([ps_exe, "-ExecutionPolicy", "Bypass", "-File", str(script)])
        # Fall back to direct python
        return subprocess.call([sys.executable, str(DASHBOARD_DIR / "server.py")])
    if args.action == "stop":
        # Read PID file and kill (graceful first, force if needed)
        pid_file = DASHBOARD_DIR / "dashboard.pid"
        if pid_file.exists():
            try:
                pid = int(pid_file.read_text().strip())
                if sys.platform == "win32":
                    # Graceful first
                    subprocess.call(["taskkill", "/PID", str(pid)])
                    time.sleep(2)
                    # Check if still alive; force if so
                    check = subprocess.run(["tasklist", "/FI", f"PID eq {pid}"], capture_output=True, text=True)
                    if str(pid) in check.stdout:
                        _warn("graceful shutdown failed, forcing...")
                        subprocess.call(["taskkill", "/F", "/PID", str(pid)])
                else:
                    # SIGTERM (graceful)
                    os.kill(pid, 15)
                    time.sleep(2)
                    # SIGKILL if still alive
                    try:
                        os.kill(pid, 0)
                        _warn("graceful shutdown failed, forcing...")
                        os.kill(pid, 9)
                    except ProcessLookupError:
                        pass
                _ok(f"sent stop to dashboard PID {pid}")
                return 0
            except (ValueError, ProcessLookupError, OSError) as e:
                _warn(f"could not stop dashboard: {e}")
                return 1
        _warn("no dashboard.pid file found")
        return 1
    _err(f"unknown action: {args.action}")
    return 2


# ----------------------------------------------------------------------------
# Subcommand: self-update
# ----------------------------------------------------------------------------
def cmd_self_update(args):
    """Update lobsterai-team to latest version (placeholder)."""
    _ok("self-update: not yet implemented (M4 will hook into ClawHub)")
    _ok("current version: 1.0.0")
    return 0


# ----------------------------------------------------------------------------
# Subcommand: version
# ----------------------------------------------------------------------------
def cmd_version(args):
    """Show version."""
    # Version is loaded from sibling __init__.py via sys.path injection below.
    # But for robustness, just use sys.path lookup.
    print(f"lobster-team 1.0.0")
    print(f"  author: lobsterai-team")
    print(f"  license: MIT")
    print(f"  python: {sys.version.split()[0]}")
    print(f"  team root: {TEAM_ROOT}")
    return 0


# ----------------------------------------------------------------------------
# Main: argparse setup
# ----------------------------------------------------------------------------
def build_parser():
    parser = argparse.ArgumentParser(
        prog="lobster-team",
        description="lobsterai-team CLI — manage the 7-role AI software company",
        epilog="See https://github.com/lobsterai-team/lobsterai-team for full docs.",
    )
    # Top-level --version (clig.dev standard)
    parser.add_argument("--version", action="version", version="lobster-team 1.0.0")
    sub = parser.add_subparsers(dest="command", required=True)

    # init
    p = sub.add_parser("init", help="install lobsterai-team to target directory")
    p.add_argument("target", nargs="?", default=".", help="target directory (default: cwd)")
    p.add_argument("--force", action="store_true", help="override path safety check")
    p.set_defaults(func=cmd_init)

    # status
    p = sub.add_parser("status", help="show sandbox + dashboard status")
    p.add_argument("--json", action="store_true", help="machine-readable JSON output")
    p.set_defaults(func=cmd_status)

    # run
    p = sub.add_parser("run", help="run a command in a role's sandbox")
    p.add_argument("role", help="role id (lobster-pm, lobster-architect, etc.)")
    p.add_argument("command", nargs=argparse.REMAINDER, help="command to run inside sandbox")
    p.add_argument("--dry-run", action="store_true", help="print command without running")
    p.set_defaults(func=cmd_run)

    # logs
    p = sub.add_parser("logs", help="tail logs (optionally filtered by role)")
    p.add_argument("role", nargs="?", default=None, help="role id filter (optional)")
    p.add_argument("-n", "--lines", type=int, default=50, help="number of lines (default 50)")
    p.add_argument("-f", "--follow", action="store_true", help="follow log file (tail -f)")
    p.set_defaults(func=cmd_logs)

    # dashboard
    p = sub.add_parser("dashboard", help="manage the dashboard")
    p.add_argument("action", choices=["start", "stop", "status"], help="dashboard action")
    p.set_defaults(func=cmd_dashboard)

    # self-update
    p = sub.add_parser("self-update", help="update lobsterai-team to latest")
    p.set_defaults(func=cmd_self_update)

    # version
    p = sub.add_parser("version", help="show version")
    p.set_defaults(func=cmd_version)

    return parser


def main(argv=None):
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args) or 0
    except KeyboardInterrupt:
        _err("interrupted")
        return 130


if __name__ == "__main__":
    sys.exit(main())
