# lobsterai-team

> Multi-agent software development team as a reusable, sandbox-isolated package.

A team of 7 specialized AI agents (PM / Architect / Coder / QA / DevOps / Data / GM) that
collaborate on software tasks following a strict Lead-Expert SOP. Each agent is a **self-contained
skill bundle** (SKILL.md + scripts + references + assets + tests) that runs inside our own
Docker sandbox (independent of OpenClaw's built-in sandbox).

## Quick start

```bash
# Install (idempotent)
./install.sh                                  # macOS / Linux
.\install.ps1                                 # Windows PowerShell

# Use the CLI
./bin/lobster-team version
./bin/lobster-team status
./bin/lobster-team run lobster-pm python3 --version
./bin/lobster-team logs lobster-pm
./bin/lobster-team dashboard start
```

Open the dashboard: <http://127.0.0.1:8080>

## Production mode (digest-pinned images)

```bash
export LOBSTERAI_PRODUCTION=1
./bin/lobster-team run lobster-pm python3 --version   # uses image@sha256:...
unset LOBSTERAI_PRODUCTION
```

## What you get

- **7 role skill bundles** under `skills/lobster-{pm,architect,coder,qa,devops,data,gm}/`
- **6 sandbox wrappers** (`sandbox_exec.{ps1,sh}`) using public Docker Hub images
- **3 playbooks** (`playbooks/feat-0to1.md`, `incident-postmortem.md`, `weekly-report.md`)
- **SANDBOX_RULES.md** — "all dev/test in sandbox" policy
- **install.{sh,ps1}** — cross-platform installers
- **bin/lobster-team** — CLI (zero dependencies, Python stdlib argparse)
- **dashboard** — lightweight SSE-based real-time monitor

## Sandbox policy

All dev, test, and CI commands run in Docker. No host-level execution.

- `--read-only` root filesystem
- `--cap-drop=ALL`
- `--security-opt no-new-privileges` (DevOps + Data)
- Resource limits: `--cpus=2 --memory=2g --pids-limit=256`
- Writable mount: `H:/software-dev-Lob:/workspace`
- Default seccomp profile (Docker)
- Public images by default; digest-pinned in production mode

## CI

GitHub Actions workflow at `.github/workflows/test.yml`:

- Smoke test all 6 expert roles
- Role allowlist rejection
- Init path safety
- Install idempotency (3x)
- Seccomp + cap-drop + read-only verification via `docker inspect`
- Cross-platform (ubuntu + windows)

## Status

| Milestone | Status |
|---|---|
| M0 — 4 role skill bundles | ✅ |
| M1 — 3 more role bundles + review fixes | ✅ |
| M2 — 3 playbooks + sandbox policy | ✅ |
| M3 — install + CLI + review fixes | ✅ |
| M3 review-of-review | ✅ |
| M4 — ClawHub publish | 🚧 |

## Documentation

- [M0 review](logs/m0-review.md)
- [M1 review](logs/m1-review.md)
- [M2 review](logs/m2-review.md)
- [M3 review](logs/m3-review.md)
- [M3 review-of-review](logs/m3-review-of-review.md)
- [Full M0-M3 review](logs/m0-m3-full-review.md)
- [PLAN.md](PLAN.md) — full build plan

## License

MIT
