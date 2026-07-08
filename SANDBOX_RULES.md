# lobsterai-team Sandbox Rules

> **Effective 2026-07-08**: every dev, test, and CI command runs in a Docker sandbox.
> No host-level code execution. No exceptions.

---

## Governance

- **approved_by**: GM (lobsterai-team) on 2026-07-08
- **next_review**: 2026-10-08 (90 days) OR when team grows 2x OR new compliance requirement
- **owner**: GM
- **version**: 1.0.0 (initial policy)
- **changelog**: see end of file

---

## 1. The rule (one sentence)

**All development, testing, and debugging commands for lobsterai-team MUST run inside a Docker sandbox via the `sandbox_exec.{ps1,sh}` wrappers. No host-level execution.**

---

## 2. Why (per 5-round best-practice research 2026-07-08)

1. **Reproducibility** (per OneUptime 2026) — public images + pinned versions = same result every time
2. **Isolation** (per Northflank / Guideflow 2026) — sandbox prevents "works on my machine" failures + AI agent untrusted code risk
3. **Read-only root** (per Docker Compose Tip 2026) — attacker can't modify binaries if root is read-only
4. **Capability drop** (per Sysdig 2026) — `--cap-drop=ALL` reduces attack surface
5. **Universal upstream images** (per Python Docker / Node Docker docs) — official images are most up-to-date, CVE-patched, and reproducible

---

## 3. Public (upstream) image per role

| Role | Image | Pre-installed | Runtime install (if needed) |
|---|---|---|---|
| `lobster-pm` | `python:3.12-alpine` | python3, pip | (none) |
| `lobster-architect` | `python:3.12-alpine` | python3, pip | (none) |
| `lobster-coder` | `node:20-alpine` | node 20, npm, corepack | `corepack enable && pnpm install` (in workspace) |
| `lobster-qa` | `node:20-alpine` | node 20, npm, corepack | (uses coder's `node_modules` in `/workspace`) |
| `lobster-devops` | `alpine:latest` | bash, curl, wget, jq | `apk add --root=/workspace/.apks git openssh-client` (in workspace) |
| `lobster-data` | `python:3.12-alpine` | python3, pip | `pip install --target=/workspace/.libs pandas duckdb` |

All images are **Docker Hub official** (no custom build required).

Override any role's image with `LOBSTERAI_IMAGE` environment variable:

```powershell
$env:LOBSTERAI_IMAGE = "python:3.13-alpine"
.\skills\lobster-pm\scripts\sandbox_exec.ps1 python3 --version
```

---

## 4. Sandbox configuration (all wrappers apply these)

| Setting | Value | Rationale (per source) |
|---|---|---|
| `--read-only` | true | Docker Compose Tip 2026 — attacker can't modify binaries |
| `--cap-drop=ALL` | true | Sysdig 2026 — minimum capabilities |
| `--security-opt no-new-privileges` | true | OneUptime 2026 — no privilege escalation |
| `--network=bridge` | true | B-mode (boss 2026-07-08) — controlled, not isolated |
| `--tmpfs /tmp:rw` | 200-500m | Per role — writable scratch space |
| `-v H:/software-dev-Lob:/workspace:rw` | always | Only writable mount (code lives here) |
| `--rm` | true | Container removed after each command (no accumulation) |
| Non-root user | per image | Dockerfile `USER` directive (M1 review fix) |
| IMDS block | devops only | 169.254.169.254 — host credential exposure risk |

---

## 5. Workspace is the only writable surface

Per Docker Compose Tip 2026 + OneUptime 2026 read-only pattern:

- `/` is **read-only** (image filesystem)
- `/tmp` is **tmpfs** (RAM-backed, ephemeral)
- `/workspace` is the **host bind-mount** (`H:/software-dev-Lob` → `/workspace`)
- Special writable mounts:
  - `lobster-devops`: `/workspace/.tools` (for git/curl/ssh binaries)
  - `lobster-data`: `/workspace/.libs` (for pip --target Python packages)

**All dev/test state lives in `/workspace`** — survives container restarts (it's a bind mount).

---

## 6. Anti-patterns (forbidden)

❌ **Running dev tools on host PowerShell directly** (e.g., `python script.py` instead of `sandbox_exec.ps1 python3 script.py`)
❌ **Using `latest` tag in production** (per OneUptime 2026 — pin by digest)
❌ **Installing tools globally in container** (`--read-only` root makes this impossible anyway)
❌ **Bypassing sandbox for "just this once"** (defeats the whole point)
❌ **Building custom images unless absolutely necessary** (use upstream first, add notes if blocked)
❌ **Using `python:3.12` instead of `python:3.12-alpine`** (alpine is smaller, fewer CVEs — per Minimus 2026)
❌ **Hardcoding `latest` in Dockerfile** (use digest pinning for production)

---

## 7. Workflow (dev / test / debug)

```powershell
# 1. Run a script in Coder's sandbox
cd H:\software-dev-Lob
.\lobsterai-team\skills\lobster-coder\scripts\sandbox_exec.ps1 pnpm test

# 2. Run an ad-hoc Python check
.\lobsterai-team\skills\lobster-pm\scripts\sandbox_exec.ps1 python3 -c "import json; print(json.dumps({'ok': True}))"

# 3. Run a data analysis (data libs in /workspace/.libs)
.\lobsterai-team\skills\lobster-data\scripts\sandbox_exec.ps1 python3 -c "import pandas, duckdb; print(pandas.__version__, duckdb.__version__)"

# 4. Install a data lib in workspace (one-time)
.\lobsterai-team\skills\lobster-data\scripts\sandbox_exec.ps1 sh -c "pip install --target=/workspace/.libs pandas duckdb jsonschema"

# 5. Debug interactively (read-only check)
.\lobsterai-team\skills\lobster-qa\scripts\sandbox_exec.ps1 sh
# then in container:
# ls /workspace
# cat /workspace/lobsterai-team/skills/lobster-pm/SKILL.md
```

---

## 8. Override (escape hatch)

To run a non-sandbox command (e.g., for **lobsterai-team tooling itself** like the dashboard, file ops, git on host):

```powershell
# Explicit bypass — document WHY in commit message
$env:LOBSTERAI_BYPASS_SANDBOX = "1"
```

This sets the gate so the GM can audit. Bypasses are logged in `logs/sandbox-bypass.log`.

**Default**: bypass is **off**. Any host-level command requires explicit `$env:LOBSTERAI_BYPASS_SANDBOX = "1"`.

**TODO (M3)**: implement the actual audit logger. For now, the bypass is documented but silently used. M3 will add:
- `scripts/log-bypass.ps1` script that appends a timestamped line to `logs/sandbox-bypass.log`
- Dashboard "Bypasses today" card showing recent bypasses
- Cron job that emails GM if > 5 bypasses per day

---

## 9. Deprecated images (lobsterai-team-devops, lobsterai-team-data)

Per M2 policy (2026-07-08), the custom Docker images built from `images/devops/Dockerfile` and `images/data/Dockerfile` are **DEPRECATED** in favor of public upstream images.

- They still exist (for one-time builds, archives) but no wrapper defaults to them
- Override via `$env:LOBSTERAI_IMAGE = "lobsterai-team-devops:latest"` if you need them
- Owner: GM. Removal date: 2026-08-01 (4 weeks for transition)

---

## 10. CI / pipeline integration (future)

When the lobsterai-team grows to need CI:
- All CI jobs run `sandbox_exec.{ps1,sh}` instead of host toolchain
- Per role: dedicated CI step calls the wrapper
- Artifacts (test results, SBOMs) copied from `/workspace` to CI storage
- No host-level dependencies installed in CI runner

---

## 5-round best-practice sources

1. **Reproducible Docker images** ([OneUptime 2026](https://oneuptime.com/blog/post/2026-02-08-how-to-build-reproducible-docker-images-with-locked-dependencies/view)) — pin by digest + lock app deps
2. **Read-only + tmpfs** ([Docker Compose Tip 2026](https://lours.me/posts/compose-tip-043-read-only-rootfs)) — root read-only + tmpfs for needed writable
3. **Sandbox environment 2026** ([Guideflow](https://www.guideflow.com/blog/what-is-sandbox-environment) + [Northflank](https://northflank.com/blog/what-is-a-sandbox-environment)) — enforceable boundaries
4. **Monorepo Docker** ([OneUptime 2026](https://oneuptime.com/blog/post/2026-01-30-docker-multi-stage-monorepos/view)) — build context + multi-stage
5. **Containerized dev workflow** ([Portainer 2026](https://www.portainer.io/blog/devops-containers) + [Wonderment](https://www.wondermentapps.com/blog/best-practices-for-devops)) — eliminate "works on my machine"

Per boss 2026-07-08: "沙盒要改成公版的，以后所有的开发测试都要在里面做"

---

## Changelog

- **2026-07-08 v1.0.0** — Initial policy. Boss approved "sandbox-first, public images" rule. GM.
