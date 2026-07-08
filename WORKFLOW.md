# lobsterai-team WORKFLOW — 6-step process

> **Owner**: GM (General Manager, lobsterai-team)
> **Last verified**: 2026-07-09
> **Version**: 1.0.0 (initial)

This document describes how lobsterai-team's 7 expert agents + GM (the "AI software company")
work in a sandboxed environment to deliver any software project, from brief to production.

---

## 1. The 3 distinct things (most common confusion)

| Thing | What it is | Example in lobsterai-team |
|---|---|---|
| **lobsterai-team 7 experts** | Virtual dev team (PM/Architect/Coder/QA/DevOps/Data/GM) | `skills/lobster-{pm,architect,...}/SKILL.md` |
| **lobsterai-team software** | Product the experts build + test (analogous to a startup's website/app) | 6 sandbox wrappers + dashboard + CLI |
| **CI** | Automated test executor (replaces running tests by hand) | `.github/workflows/test.yml` |

> **The boss's insight (2026-07-08)**: "CI is what the **QA role** uses. CI does NOT replace the QA role."
> CI is a **tool**; the QA role decides **what** to test, **how** to test, and **what the results mean**.

---

## 2. The 6-step process

### Step 1: Production folder (PM → GM)

- Create the project folder on the production host.
- Example: `H:\software-dev-Lob\my-new-project\`
- Owner: **GM** (with PM's brief).

### Step 2: Sandbox folder (GM)

- **Same** folder, inside a Docker sandbox container.
- `git clone https://github.com/<owner>/my-new-project.git` to the sandbox's `/workspace`.
- Owner: **GM**.

### Step 3: 7 experts do the work in the sandbox (GM dispatches)

| Phase | Role | What it does |
|---|---|---|
| 1. Groom | **PM** | Breaks brief into user stories + acceptance criteria |
| 2. Design | **Architect** | Picks tech stack, writes ADRs, makes design.md |
| 3. Build | **Coder** | Implements + unit tests (inside the sandbox) |
| 4. Test | **QA** | Writes integration + E2E tests, owns test coverage |
| 5. Deploy | **DevOps** | Configures CI pipeline (`.github/workflows/...yml`), secrets, environments |
| 6. Analyze | **Data** | If data involved, writes ETL + analysis scripts |
| 7. Verify | **GM** | 3-gate acceptance, archive, tag version |

Owner: **GM dispatches each role**; **7 experts** work concurrently where possible.

### Step 4: Sandbox test + CI/CD integration + 1 version = 1 Git commit

- Sandbox runs 6-role smoke test + 7-wrapper security verification.
- QA writes tests for the product, DevOps configures the CI pipeline.
- One version = one git commit. Commit message = which expert(s) contributed.
- `git push origin dev` → CI runs on GitHub Actions.
- Owner: **QA + DevOps** (CI quality) + **GM** (push decision).

### Step 5: Boss reviews E2E (Boss)

- The boss (or designated reviewer) inspects the sandbox.
- Confirms the **end-to-end** test passes the business case.
- Sign-off required before merge to main.

### Step 6: Deploy first version + Git tag (GM)

- `git checkout main && git merge dev --no-ff` (PR review happens here too).
- `git tag v0.1.0` (first version).
- Boss runs `git pull origin main` on the production host → production updated.
- Owner: **GM** (merge) + **Boss** (pull on production).

---

## 3. CI / role matrix (where each role touches CI)

| Role | Writes | Reads | Owns |
|---|---|---|---|
| **GM** | workflow doc, release tags | CI status, run logs | merge decision, version tags |
| **PM** | user stories, ACs | CI results | nothing CI-specific |
| **Architect** | design.md, ADRs | CI logs (when design fails) | design-fit-in-CI |
| **Coder** | product code | CI failure logs | code that passes CI |
| **QA** | **integration tests, E2E tests, test coverage config** | **CI logs, failure analyses** | **CI test content** |
| **DevOps** | **CI workflow files (`.github/workflows/*.yml`), secrets, deploy config** | CI logs, infra logs | **CI tool itself** |
| **Data** | data tests, schema tests | CI data-validation results | data quality |

> **QA writes the tests; DevOps configures the runner; Coder writes the code; GM watches and merges.**

---

## 4. Sandbox configuration

Per `SANDBOX_RULES.md`:

- `--read-only` root filesystem
- `--cap-drop=ALL`
- `--security-opt no-new-privileges` (DevOps + Data)
- `--cpus=2 --memory=2g --pids-limit=256` (resource limits)
- `H:/software-dev-Lob` mounted at `/workspace` (only writable surface)
- Default Docker seccomp profile
- Public upstream images by default; digest-pinned when `LOBSTERAI_PRODUCTION=1`

---

## 5. End-to-end verification checklist (run by GM before merge)

- [ ] Sandbox 6-role smoke test passes (`./bin/lobster-team run lobster-{pm,architect,coder,qa,devops,data} <cmd>`)
- [ ] `install.sh` runs idempotently 3 times without error
- [ ] `lobster-team status --json` returns valid JSON with `team_root` and `dashboard` keys
- [ ] Sandbox security flags verified (`cap_drop` + `read_only`)
- [ ] `bash install.sh` + `install.ps1` both succeed (cross-platform)
- [ ] CI workflow YAML is valid and runs on `push:branches:main` and `pull_request`
- [ ] All 7 roles' `SKILL.md` files have frontmatter (name, version, allowed-tools, role-type)

---

## 6. Branch strategy (trunk-based with dev branch)

```
main    ← production (H 盘 lobsterai-team checked out to this)
  ↑
  | merge --no-ff (after PR + CI green + E2E sign-off)
  |
dev     ← sandbox work + sandbox-tested + CI-green
  ↑
  | cut from main (per project)
  |
projects/<name>   ← optional, for parallel large projects
```

- **`main`** is always production-ready. Boss pulls `main` = production update.
- **`dev`** is the active working branch. All sandbox commits land here.
- **CI green is required** before merge to `main`.
- Boss review of E2E is required before merge to `main`.

---

## 7. Failure handling

| Failure | Escalation |
|---|---|
| Sandbox 6-role smoke test fails | Coder fixes in sandbox → re-test → push dev |
| CI red on push to dev | DevOps + Coder look at logs → fix → push dev |
| E2E sign-off fails | Boss comments → GM dispatches fix team → re-test |
| 3 retries on same failure | Auto-escalate to boss |
| Production rollback needed | `git revert <tag> && git push origin main` |

---

## 8. First version (v0.1.0) checklist

This very document is the first version of the lobsterai-team 6-step process. The first
"real" project to use it is **lobsterai-team v1.0 itself**.

| Step | Status |
|---|---|
| 1. Production folder (H:\software-dev-Lob\lobsterai-team) | ✅ exists |
| 2. Sandbox folder (docker container, /workspace = H:\software-dev-Lob) | ✅ exists |
| 3. 7 experts in sandbox | ✅ SKILL.md files exist for all 7 |
| 4. Sandbox test + CI + 1 version = 1 commit | 🔄 in progress (this dev branch) |
| 5. Boss reviews E2E | ⏳ pending |
| 6. Deploy first version + Git tag | ⏳ pending (target: v0.1.0 after this commit) |

---

## 9. Related documents

- `PLAN.md` — build plan (M0-M4)
- `SANDBOX_RULES.md` — sandbox policy ("all dev/test in sandbox")
- `ROSTER.md` — 7 roles at a glance
- `templates/expert-group.md` — 7-role team SOP
- `playbooks/feat-0to1.md` — feature 0-to-1 playbook
- `playbooks/incident-postmortem.md` — incident response
- `playbooks/weekly-report.md` — weekly stakeholder report

---

**Changelog**

- 2026-07-09 v1.0.0 — Initial 6-step workflow doc (this file).
- Owner: GM (lobsterai-team)
- Trigger for update: any change to the 6-step process or CI/role matrix
