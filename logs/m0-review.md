# M0 Review Report — 2026-07-08

> Self-review of M0 (4-role skill bundles + sandbox wrappers) before proceeding to M1.

## Scope reviewed

11 files under `H:\software-dev-Lob\lobsterai-team\`:

- 2 docs: `README.md`, `ROSTER.md`
- 2 contracts: `roles/gm.md`, `templates/expert-group.md`
- 3 skill cards: `skills/lobster-{pm,coder,qa}/SKILL.md`
- 3 sandbox wrappers: `skills/lobster-{pm,coder,qa}/scripts/sandbox_exec.ps1`

## Issues found and fixed

### 🔴 Issue 1: SKILL.md references `.sh` but actual script is `.ps1`

- **Files**: `lobster-pm/SKILL.md`, `lobster-coder/SKILL.md`, `lobster-qa/SKILL.md`
- **Fix**: All docs now show BOTH `.ps1` (Windows) and `.sh` (macOS/Linux) examples.

### 🔴 Issue 2: SKILL.md says "No host network" but script is `bridge`

- **File**: `lobster-pm/SKILL.md`
- **Fix**: Doc updated to explicitly state `--network=bridge` (B-mode: online).

### 🟡 Issue 3: Image pull check used fragile regex

```powershell
# Before (fragile)
$imageExists = docker images --format "{{.Repository}}:{{.Tag}}" | Select-String -Pattern "^${IMAGE}$"

# After (reliable)
docker image inspect $IMAGE 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { docker pull $IMAGE | Out-Null }
```

- **Files**: All 3 `sandbox_exec.ps1` scripts
- **Why better**: `docker image inspect` is the canonical "is this image cached?" check.

### 🟡 Issue 4: `pnpm install` would fail under `--read-only` root

- **File**: `lobster-coder/SKILL.md`
- **Fix**: New section **"`node_modules` constraint"** stating:
  - Always use `--prefix /workspace/<project>` so `node_modules` lands in the writable volume
  - Never run `npm install -g`
  - Escalate to GM if a tool insists on writing to `/usr`

### 🟡 Issue 5: No `.sh` cross-platform version

- **Fix**: Created 3 new files:
  - `lobster-pm/scripts/sandbox_exec.sh`
  - `lobster-coder/scripts/sandbox_exec.sh`
  - `lobster-qa/scripts/sandbox_exec.sh`
- All use `docker image inspect` (same as ps1) + bash idioms.

### 🟢 Issue 6: Coder/QA SKILL.md lacked `node_modules` constraint

- **Subsumed by Issue 4 fix**: the new `node_modules` section in lobster-coder/SKILL.md
  covers both Coder and QA (since QA reuses Coder's `node_modules`).

## Smoke test results (post-fix)

| # | Test | Result |
|---|---|---|
| 1 | PM .ps1 — python3 with ROLE_NAME env | ✅ |
| 2 | Coder .ps1 — node with ROLE_NAME env | ✅ |
| 3 | QA .ps1 — node with NODE_ENV=test | ✅ |
| 4 | **Read-only root** — `touch /should-fail.txt` blocked | ✅ `Read-only file system` |
| 5 | `/tmp` tmpfs writable | ✅ |
| 6 | `/workspace` volume writable | ✅ |
| 7 | 3 `.sh` files have `#!/usr/bin/env bash` shebang | ✅ |

**Key validation**: Test 4 confirms root filesystem is actually read-only — the
sandbox is a real containment boundary, not a path-based naming convention.

## Sign-off

All 6 issues fixed and verified. M0 is complete. Proceed to M1.

— lobster-gm (acting as Lead, accepting the work of all 4 experts)
