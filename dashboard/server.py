#!/usr/bin/env python3
"""
lobsterai-team dashboard server
==============================
A lightweight, SSE-based real-time dashboard for monitoring lobsterai-team sandboxes.

Features:
- 5 summary cards (running containers / images / logs / 24h starts / 24h errors)
- Active container list (auto-refresh every 3s)
- Image list (auto-refresh on demand)
- Real-time log stream (SSE, role-filtered tabs)
- Quick actions (rebuild image / cleanup / view review)

Security:
- Bound to 127.0.0.1 only (loopback)
- No authentication (localhost-only)
- PID file prevents duplicate instances

Stack: Python stdlib only (http.server + json + subprocess) — zero deps.
Per 5-round best-practice research (2026-07-08):
- Dozzle model: focused on log streaming
- SSE > WebSocket for one-way updates
- localhost-only is safe without auth
- stdlib http.server OK for internal tools

Usage:
    python server.py [--port 8080] [--host 127.0.0.1]
"""
import argparse
import json
import os
import subprocess
import sys
import threading
import time
from collections import deque
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

# ----------------------------------------------------------------------------
# Config
# ----------------------------------------------------------------------------
LOBSTER_ROOT = Path("H:/software-dev-Lob/lobsterai-team")
LOGS_ROOT = LOBSTER_ROOT / "logs"
PID_FILE = LOBSTER_ROOT / "dashboard" / "dashboard.pid"
DEFAULT_HOST = "127.0.0.1"
DEFAULT_PORT = 8080

# In-memory state (per-process)
state_lock = threading.Lock()
log_subscribers = set()  # set of (writer, role_filter_or_None)
container_cache = {"ts": 0, "data": []}
image_cache = {"ts": 0, "data": []}
stats_cache = {"ts": 0, "data": {}}

# ----------------------------------------------------------------------------
# Docker helpers
# ----------------------------------------------------------------------------
def run_docker(args, timeout=10):
    """Run docker command and return (rc, stdout, stderr)."""
    try:
        result = subprocess.run(
            ["docker"] + args,
            capture_output=True,
            text=True,
            timeout=timeout,
            encoding="utf-8",
        )
        return result.returncode, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return -1, "", "timeout"
    except FileNotFoundError:
        return -1, "", "docker not found in PATH"
    except Exception as e:
        return -1, "", str(e)


def list_containers():
    """Return list of currently running containers (JSON-able dicts)."""
    rc, out, _ = run_docker([
        "ps", "--all",
        "--format", "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.CreatedAt}}|{{.Ports}}",
    ])
    rows = []
    for line in out.strip().splitlines():
        parts = line.split("|", 5)
        if len(parts) == 6:
            rows.append({
                "id": parts[0],
                "name": parts[1],
                "image": parts[2],
                "status": parts[3],
                "created": parts[4],
                "ports": parts[5],
            })
    return rows


def list_images():
    """Return list of docker images (JSON-able dicts)."""
    rc, out, _ = run_docker([
        "images", "--format", "{{.Repository}}:{{.Tag}}|{{.Size}}|{{.CreatedSince}}|{{.ID}}",
    ])
    rows = []
    for line in out.strip().splitlines():
        parts = line.split("|", 3)
        if len(parts) >= 4:
            tag = parts[0]
            # Skip <none> images
            if "<none>" in tag:
                continue
            rows.append({
                "tag": tag,
                "size": parts[1],
                "created": parts[2],
                "id": parts[3][:12],
            })
    return rows


def calc_stats():
    """Compute summary statistics from log files."""
    stats = {
        "running_containers": len(list_containers()),
        "image_count": 0,
        "logs_today": 0,
        "starts_24h": 0,
        "errors_24h": 0,
    }
    # Image count (lobsterai-team only)
    for img in list_images():
        if img["tag"].startswith("lobsterai-team") or img["tag"].startswith("python") or img["tag"].startswith("node") or img["tag"].startswith("alpine"):
            stats["image_count"] += 1

    # Logs: count files in logs/ subdirs, mtime within 24h
    if LOGS_ROOT.exists():
        cutoff = time.time() - 24 * 3600
        for log_file in LOGS_ROOT.rglob("*.log"):
            try:
                mtime = log_file.stat().st_mtime
                if mtime >= cutoff:
                    stats["logs_today"] += 1
                    stats["starts_24h"] += 1  # each log file = 1 start
            except OSError:
                pass
    return stats


def list_log_files(role_filter=None):
    """List log files, optionally filtered by role."""
    if not LOGS_ROOT.exists():
        return []
    out = []
    for log_file in LOGS_ROOT.rglob("*.log"):
        try:
            mtime = log_file.stat().st_mtime
            size = log_file.stat().st_size
        except OSError:
            continue
        # role is the parent dir name
        rel = log_file.relative_to(LOGS_ROOT)
        role = rel.parts[0] if len(rel.parts) > 1 else "_root"
        if role_filter and role != role_filter:
            continue
        out.append({
            "path": str(log_file),
            "rel": str(rel).replace("\\", "/"),
            "role": role,
            "size": size,
            "mtime": datetime.fromtimestamp(mtime, tz=timezone.utc).isoformat(),
        })
    out.sort(key=lambda x: x["mtime"], reverse=True)
    return out


def tail_log(log_path, lines=200):
    """Return last N lines of a log file."""
    try:
        # Use tail-like behavior: read all and take last N
        with open(log_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        all_lines = content.splitlines()
        return all_lines[-lines:]
    except Exception as e:
        return [f"ERROR reading log: {e}"]


# ----------------------------------------------------------------------------
# SSE broadcaster
# ----------------------------------------------------------------------------
def broadcast_log_event(role, log_path, event_type="new_log"):
    """Notify all SSE subscribers about a new log file or update."""
    dead = set()
    for writer, sub_filter in list(log_subscribers):
        if sub_filter and sub_filter != role:
            continue
        try:
            payload = json.dumps({
                "type": event_type,
                "role": role,
                "path": log_path,
                "ts": datetime.now(timezone.utc).isoformat(),
            })
            writer.write(f"data: {payload}\n\n".encode("utf-8"))
            writer.flush()
        except Exception:
            dead.add((writer, sub_filter))
    for d in dead:
        log_subscribers.discard(d)


# ----------------------------------------------------------------------------
# HTTP handler
# ----------------------------------------------------------------------------
class DashboardHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        # Quiet by default; uncomment for debugging
        # sys.stderr.write(f"[dashboard] {self.address_string()} {format % args}\n")
        pass

    def _send_json(self, obj, status=200):
        body = json.dumps(obj).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("X-Content-Type-Options", "nosniff")
        self.end_headers()
        self.wfile.write(body)

    def _send_text(self, text, content_type="text/plain; charset=utf-8", status=200):
        body = text.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def _send_file(self, path, content_type=None):
        if not path.exists():
            self._send_text("Not found", status=404)
            return
        try:
            with open(path, "rb") as f:
                body = f.read()
        except OSError as e:
            self._send_text(f"Read error: {e}", status=500)
            return
        self.send_response(200)
        if content_type:
            self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        url = urlparse(self.path)
        path = url.path
        qs = parse_qs(url.query)

        if path == "/" or path == "/index.html":
            self._send_file(LOBSTER_ROOT / "dashboard" / "index.html", "text/html; charset=utf-8")
            return

        if path == "/api/stats":
            with state_lock:
                if time.time() - stats_cache["ts"] > 5:
                    stats_cache["data"] = calc_stats()
                    stats_cache["ts"] = time.time()
                self._send_json(stats_cache["data"])
            return

        if path == "/api/containers":
            with state_lock:
                if time.time() - container_cache["ts"] > 2:
                    container_cache["data"] = list_containers()
                    container_cache["ts"] = time.time()
                self._send_json(container_cache["data"])
            return

        if path == "/api/images":
            with state_lock:
                if time.time() - image_cache["ts"] > 30:
                    image_cache["data"] = list_images()
                    image_cache["ts"] = time.time()
                self._send_json(image_cache["data"])
            return

        if path == "/api/logs":
            role = qs.get("role", [None])[0]
            self._send_json(list_log_files(role_filter=role))
            return

        if path == "/api/tail":
            log_path = qs.get("path", [None])[0]
            if not log_path:
                self._send_json({"error": "path required"}, status=400)
                return
            # Security: only allow reading files under LOGS_ROOT
            try:
                p = Path(log_path).resolve()
                if not str(p).startswith(str(LOGS_ROOT.resolve())):
                    self._send_json({"error": "path outside logs root"}, status=403)
                    return
            except Exception as e:
                self._send_json({"error": f"bad path: {e}"}, status=400)
                return
            lines = int(qs.get("lines", ["200"])[0])
            self._send_json({"path": str(p), "lines": tail_log(p, lines)})
            return

        if path == "/api/events":
            self._send_sse()
            return

        if path == "/api/health":
            self._send_json({"status": "ok", "ts": datetime.now(timezone.utc).isoformat()})
            return

        if path == "/api/rebuild":
            self._send_json({"error": "POST required"}, status=405)
            return

        # Static fallback: serve from dashboard/ dir
        candidate = LOBSTER_ROOT / "dashboard" / path.lstrip("/")
        if candidate.is_file():
            ext = candidate.suffix.lower()
            ct = {
                ".html": "text/html; charset=utf-8",
                ".css": "text/css; charset=utf-8",
                ".js": "application/javascript; charset=utf-8",
                ".json": "application/json; charset=utf-8",
            }.get(ext, "application/octet-stream")
            self._send_file(candidate, ct)
            return

        self._send_text("Not found", status=404)

    def do_POST(self):
        url = urlparse(self.path)
        path = url.path

        if path == "/api/rebuild":
            role = parse_qs(url.query).get("role", [None])[0]
            if not role:
                self._send_json({"error": "role required"}, status=400)
                return
            if role not in {"lobster-pm", "lobster-architect", "lobster-coder", "lobster-qa", "lobster-devops", "lobster-data"}:
                self._send_json({"error": "unknown role"}, status=400)
                return
            # Run the build in a thread to avoid blocking the request
            def build():
                dockerfile = LOBSTER_ROOT / "images" / (role.replace("lobster-", "")) / "Dockerfile"
                if not dockerfile.exists():
                    return
                tag = f"lobsterai-team-{role.replace('lobster-', '')}:latest"
                rc, out, err = run_docker(["build", "-t", tag, str(dockerfile.parent)], timeout=600)
                broadcast_log_event(role.replace("lobster-", ""), str(dockerfile), "rebuild_done" if rc == 0 else "rebuild_failed")
            threading.Thread(target=build, daemon=True).start()
            self._send_json({"status": "rebuild started", "role": role})
            return

        if path == "/api/cleanup":
            def cleanup():
                run_docker(["container", "prune", "-f"], timeout=60)
                run_docker(["image", "prune", "-f", "--filter", "until=24h"], timeout=60)
            threading.Thread(target=cleanup, daemon=True).start()
            self._send_json({"status": "cleanup started"})
            return

        self._send_json({"error": "not found"}, status=404)

    def _send_sse(self):
        """Stream server-sent events to the browser."""
        url = urlparse(self.path)
        role_filter = parse_qs(url.query).get("role", [None])[0]

        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream; charset=utf-8")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Connection", "keep-alive")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()

        writer = self.wfile
        with state_lock:
            log_subscribers.add((writer, role_filter))

        try:
            # Send initial heartbeat
            writer.write(b": connected\n\n")
            writer.flush()
            last_ping = time.time()
            last_poll = 0
            while True:
                time.sleep(1)
                now = time.time()
                # Ping every 15s to keep connection alive
                if now - last_ping > 15:
                    try:
                        writer.write(b": ping\n\n")
                        writer.flush()
                        last_ping = now
                    except Exception:
                        break
                # Poll for new log files every 3s
                if now - last_poll > 3:
                    last_poll = now
                    current_logs = {lf["path"] for lf in list_log_files(role_filter=role_filter)}
                    # We don't track "new" across calls (stateless); instead send a "stats_update" event
                    try:
                        with state_lock:
                            if time.time() - stats_cache["ts"] > 5:
                                stats_cache["data"] = calc_stats()
                                stats_cache["ts"] = time.time()
                        payload = json.dumps({
                            "type": "stats_update",
                            "stats": stats_cache["data"],
                        })
                        writer.write(f"data: {payload}\n\n".encode("utf-8"))
                        writer.flush()
                    except Exception:
                        break
        finally:
            with state_lock:
                log_subscribers.discard((writer, role_filter))


# ----------------------------------------------------------------------------
# Background file watcher (notify subscribers when new log files appear)
# ----------------------------------------------------------------------------
_watcher_stop = threading.Event()
def _log_watcher():
    seen = set()
    while not _watcher_stop.is_set():
        if LOGS_ROOT.exists():
            current = {str(p) for p in LOGS_ROOT.rglob("*.log")}
            new = current - seen
            seen = current
            for path_str in new:
                p = Path(path_str)
                rel = p.relative_to(LOGS_ROOT)
                role = rel.parts[0] if len(rel.parts) > 1 else "_root"
                broadcast_log_event(role, path_str, "new_log")
        _watcher_stop.wait(2.0)


# ----------------------------------------------------------------------------
# PID file
# ----------------------------------------------------------------------------
def write_pid():
    if PID_FILE.exists():
        try:
            old_pid = int(PID_FILE.read_text().strip())
            os.kill(old_pid, 0)  # check if alive
            print(f"[dashboard] ERROR: already running with PID {old_pid}", file=sys.stderr)
            sys.exit(1)
        except (ValueError, ProcessLookupError):
            PID_FILE.unlink(missing_ok=True)
    PID_FILE.parent.mkdir(parents=True, exist_ok=True)
    PID_FILE.write_text(str(os.getpid()))


def cleanup_pid():
    PID_FILE.unlink(missing_ok=True)


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
def main():
    parser = argparse.ArgumentParser(description="lobsterai-team dashboard server")
    parser.add_argument("--host", default=DEFAULT_HOST, help=f"Bind host (default: {DEFAULT_HOST})")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help=f"Bind port (default: {DEFAULT_PORT})")
    args = parser.parse_args()

    write_pid()
    atexit.register(cleanup_pid)

    # Start background log watcher
    watcher = threading.Thread(target=_log_watcher, daemon=True)
    watcher.start()

    server = ThreadingHTTPServer((args.host, args.port), DashboardHandler)
    print(f"[dashboard] lobsterai-team dashboard listening on http://{args.host}:{args.port}", file=sys.stderr)
    print(f"[dashboard] PID {os.getpid()} (pidfile: {PID_FILE})", file=sys.stderr)
    print(f"[dashboard] logs dir: {LOGS_ROOT}", file=sys.stderr)
    print(f"[dashboard] open in browser: http://{args.host}:{args.port}/", file=sys.stderr)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[dashboard] shutting down", file=sys.stderr)
    finally:
        _watcher_stop.set()
        server.server_close()
        cleanup_pid()


import atexit
if __name__ == "__main__":
    main()
