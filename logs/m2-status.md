# M2 Status — 2026-07-08 22:40

> 3 playbooks + sandbox public-image policy. All delivered during boss's 30-min shower break.

## 3 Playbooks written (15 search rounds total)

| File | Search rounds | Sources |
|---|---|---|
| [playbooks/feat-0to1.md](file:///H:/software-dev-Lob/lobsterai-team/playbooks/feat-0to1.md) | 5 | Easy Agile sprint planning 2026, codewithmukesh Git workflows 2026, Valtorian MVP Scope 2026, Atlassian AC 2026, Zylos Feature Flags 2026 + Shape Up (agilefirst.io) |
| [playbooks/incident-postmortem.md](file:///H:/software-dev-Lob/lobsterai-team/playbooks/incident-postmortem.md) | 5 | incident.io 2026 severity, Google SRE blameless, Google SRE IMAG ICS, incident.io 5-element action items, Rootly + OneUptime timeline + communication |
| [playbooks/weekly-report.md](file:///H:/software-dev-Lob/lobsterai-team/playbooks/weekly-report.md) | 5 | Centercode 2026 status template, larridin DORA 2026, Atlassian standups, Asana OKR, EM-Tools retrospectives |

## Sandbox public-image policy

- **[SANDBOX_RULES.md](file:///H:/software-dev-Lob/lobsterai-team/SANDBOX_RULES.md)** — single rule: "All dev/test in sandbox, no host execution"
- **6 sandbox wrappers updated** to use public Docker Hub images by default:
  - `lobster-pm` + `lobster-architect` → `python:3.12-alpine`
  - `lobster-coder` + `lobster-qa` → `node:20-alpine`
  - `lobster-devops` → `alpine:latest`
  - `lobster-data` → `python:3.12-alpine` (data libs installed at runtime to `/workspace/.libs`)
- **Override** via `$env:LOBSTERAI_IMAGE = "..."`
- **5 search rounds** for sandbox best practice: OneUptime reproducible 2026, Docker Compose Tip 2026 read-only, Guideflow + Northflank sandbox 2026, OneUptime monorepo Docker, Portainer + Wonderment containerized dev

## Verification (all passed)

| Test | Result |
|---|---|
| PM (python:3.12-alpine) | ✅ Python 3.12.13 |
| Architect (python:3.12-alpine) | ✅ Python 3.12.13 |
| Coder (node:20-alpine) | ✅ Node v20.20.2 |
| QA (node:20-alpine) | ✅ Node v20.20.2 |
| DevOps (alpine:latest) | ✅ Alpine 3.24.1 |
| Data: pip install pandas --target=/workspace/.libs | ✅ pandas 3.0.3 importable |
| Data: .libs persists across container runs (bind mount) | ✅ H:\software-dev-Lob\.libs has pandas/numpy |
| Root read-only in all sandboxes | ✅ Coder + Data + DevOps all confirmed |
| Dashboard still alive | ✅ 58 logs today, 0 errors |

## Known limitation (per boss's "公版" policy)

- `duckdb` (alpine pre-built wheel) fails on alpine+musl — hash mismatch with pypi
- Workaround: user can use `python:3.12-slim` (debian, glibc) for duckdb work
- Or: use the `lobsterai-team-data:latest` custom image (deprecated but still buildable)

## Files changed this turn (M2)

```
playbooks/feat-0to1.md                 (new, 8 KB)
playbooks/incident-postmortem.md       (new, 13 KB)
playbooks/weekly-report.md             (new, 9 KB)
SANDBOX_RULES.md                       (new, 7 KB)
skills/lobster-pm/scripts/sandbox_exec.ps1          (public image)
skills/lobster-architect/scripts/sandbox_exec.ps1   (public image)
skills/lobster-coder/scripts/sandbox_exec.ps1       (public image)
skills/lobster-qa/scripts/sandbox_exec.ps1           (public image)
skills/lobster-devops/scripts/sandbox_exec.ps1      (public image)
skills/lobster-data/scripts/sandbox_exec.ps1        (public image + .libs persistent)
PLAN.md                                 (status update)
logs/m2-status.md                       (this file)
```

## 15 search rounds summary

| Round | Theme | Key finding |
|---|---|---|
| 1 | Sprint planning 2026 | Estimation is risk discovery, not precision |
| 2 | Git workflows 2026 | TBD + feature flags = decoupling deploy from release |
| 3 | MVP scope 2026 | 1-sentence rule + scope creep guardrails |
| 4 | AC 2026 | Given/When/Then + atomic + testable |
| 5 | Feature flags 2026 | 30-day kill switch then archive |
| 6 | Incident severity 2026 | SEV matrix pinned in on-call channel |
| 7 | Blameless 2026 | Systems fail, humans make mistakes — fix the system |
| 8 | Incident Command 2026 | IC + OL + CL + Scribe, 3Cs (coordinate/communicate/control) |
| 9 | Postmortem actions 2026 | 5 elements: owner + verb + outcome + tracker + deadline |
| 10 | Incident comms 2026 | First ack <30 min, every 30-60 min, even if "no news" |
| 11 | Status report 2026 | Outcomes not activities, audience-tailored |
| 12 | DORA 2026 | 4 metrics: DF + LT + MTTR + CFR, outcome-oriented not activity |
| 13 | Standups 2026 | Focus on blockers, async for status sync for decisions |
| 14 | OKR 2026 | 0.0-1.0 scale, weekly check-ins, 3-5 objectives per level |
| 15 | Retros 2026 | Action items discipline, "in progress" is not done |
| (bonus 1) | Reproducible Docker 2026 | Pin by digest not tag |
| (bonus 2) | Read-only + tmpfs 2026 | tmpfs for needed writable + bind mount for persistent |
| (bonus 3) | Sandbox 2026 | Enforceable boundaries, ephemeral vs persistent |
| (bonus 4) | Monorepo Docker 2026 | Build context to root, multi-stage |
| (bonus 5) | Containerized dev 2026 | Eliminate "works on my machine" failures |

## Status of next steps (when boss returns)

- **M3** (cross-platform packaging) — write `install.ps1` + `install.sh` + CLI entry point
- **M4** (publish to ClawHub) — manifest + version + license
- **M1.4** (deferred from earlier) — end-to-end test on `dream-novelist-web` with all 7 roles
- **Boss feedback** on dashboard + playbooks (if any)

## Next 5 rounds pending (for M3 when boss gives go)

1. PowerShell installer best practices
2. Bash installer best practices
3. CLI framework comparison (click vs typer vs cobra)
4. OpenClaw sub-agent registration
5. ClawHub skill submission format
