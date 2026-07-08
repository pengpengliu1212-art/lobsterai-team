# M1 Review Report — 2026-07-08 21:30

> Review of M1 deliverables: 3 new role skill bundles (Architect / DevOps / Data) + 2 Dockerfiles + 6 sandbox wrappers + 2 schemas.

## Scope reviewed

| M | Files | Status |
|---|---|---|
| M1.1 Architect | SKILL.md + adr-template.md + tech-decisions-schema.json + sandbox_exec.{ps1,sh} | ✅ |
| M1.2 DevOps | SKILL.md + security-checklist.md + incident-runbook.md + sandbox_exec.{ps1,sh} + Dockerfile | ✅ |
| M1.3 Data | SKILL.md + sql-style-guide.md + analysis-schema.json + sandbox_exec.{ps1,sh} + Dockerfile | ✅ |

## 5 rounds of best-practice research

1. **Google eng-practices + CodeAnt** — PR review speed, major-issues-first, "every line", context, "good things" recognition
2. **Anthropic multi-agent + Claude Code review** — strict JSON schema, audit log, transport-layer trust tags, schema validation is deterministic (prompt-based is probabilistic)
3. **Container security 2026 (Sysdig / Docker / OX)** — minimal base image, multi-stage build, SBOM, non-root, signed images
4. **PowerShell script injection (Microsoft)** — never `Invoke-Expression`, single-quote strings, parameter binding, validate with regex, sign scripts
5. **JSON Schema validation (OpenAI CFG / AWS / Zuplo)** — `additionalProperties: false`, Strict Mode, schema-versioning, test schemas, multi-agent safe chaining

## Issues found

### 🔴 Must fix (correctness / security)

#### 1. `tech-decisions-schema.json` missing `additionalProperties: false`

**File**: `skills/lobster-architect/assets/tech-decisions-schema.json`

**Problem**: Other schemas (analysis-schema.json) explicitly set `"additionalProperties": false`. This one does not, so the schema allows unknown keys — defeating the purpose of strict validation.

**Fix**: Add `"additionalProperties": false` at the top-level object.

#### 2. Dockerfiles missing non-root user

**Files**: `images/devops/Dockerfile`, `images/data/Dockerfile`

**Problem**: Per Docker / Sysdig 2026 best practices, production images must `USER 10001` (non-root). Our images run as root by default.

**Fix**: Add:
```dockerfile
RUN adduser -D -u 10001 appuser 2>/dev/null || true
USER appuser
```

#### 3. PowerShell wrapper swallows `docker pull` errors

**Files**: `sandbox_exec.ps1` × 3 (architect / devops / data)

**Problem**: `docker pull $IMAGE | Out-Null` — if pull fails (network, auth, image missing), exit code 0 is forced and we proceed with no image. Next `docker run` will fail with cryptic "image not found" instead of a clear pull error.

**Fix**:
```powershell
docker pull $IMAGE 2>&1 | Tee-Object -FilePath $logFile
if ($LASTEXITCODE -ne 0) {
    Write-Error "[sandbox] docker pull failed for $IMAGE"
    exit $LASTEXITCODE
}
```

### 🟡 Should fix (best practice)

#### 4. `architect/SKILL.md` missing `Original prompt:` convention

**Problem**: lobster-pm, lobster-coder, lobster-qa, lobster-devops, lobster-data all mention the `Original prompt:` line preservation in progress.md. lobster-architect doesn't.

**Fix**: Add to Progress tracking section.

#### 5. `architect/SKILL.md` missing explicit 4-element sub-agent contract

**Problem**: Anthropic's contract = objective + output format + guidance on tools/sources + clear task boundaries. lobster-architect mentions "Workflow" (10 steps) and "Output contract" but doesn't name the 4 elements explicitly.

**Fix**: Add a `## Sub-agent contract (Anthropic 4 elements)` section.

#### 6. Dockerfiles missing `LABEL` and `HEALTHCHECK`

**Files**: `images/devops/Dockerfile`, `images/data/Dockerfile`

**Problem**: Per Docker 2026 best practices, images should have `LABEL maintainer=...` and `HEALTHCHECK CMD ...` for metadata + liveness.

**Fix**:
```dockerfile
LABEL maintainer="lobsterai-team" \
      version="1.0.0" \
      role="lobsterai-team-devops" \
      description="DevOps role sandbox image"
HEALTHCHECK --interval=60s --timeout=5s --retries=2 \
    CMD sh -c 'which kubectl && which helm && which git'
```

#### 7. `.ps1` wrappers lack input validation

**Files**: sandbox_exec.ps1 × 6 (across all 4 roles)

**Problem**: The `$args` from the agent is passed directly into the docker run command. While trust is high (LLM is calling itself), per Microsoft script-injection guidance, parameter binding with type checks is best practice.

**Fix**: Add basic parameter count check + log clear error if called with no args:
```powershell
if ($args.Count -eq 0) {
    Write-Error "[sandbox] $ROLE called with no args"
    exit 1
}
```

### 🟢 Nice to have (defer)

#### 8. `devops/SKILL.md` could explicitly mention "Lethal Trifecta" mitigation

Anthropic's "Lethal Trifecta" pattern (input + output + tools = risk) is implicit in our sandbox constraints but not named.

#### 9. `data/SKILL.md` could explicitly mention `extra='forbid'` in Pydantic

The schema validation is set up; explicit `extra='forbid'` in Pydantic models would catch unknown keys at construction time.

## What passed review

- ✅ All 5 轮 best-practice research done (per owner's "≥ 5 rounds" rule)
- ✅ All 3 new roles follow Anthropic template (frontmatter + Identity + Deliverables + Workflow + Guardrails + Effort-scaling + Failure modes + Artifacts + Self-check)
- ✅ All output contracts are JSON-serializable
- ✅ All schemas use semantic versioning (`schema_version` + `prompt_version`)
- ✅ All sandbox wrappers use `--read-only` + `--cap-drop=ALL` + `--tmpfs`
- ✅ Custom DevOps image (git, ssh, kubectl, helm) built and verified
- ✅ Custom Data image (pandas, duckdb, jsonschema) built and verified
- ✅ DevOps SKILL.md enforces QA + PM gate before deploy
- ✅ Data SKILL.md enforces human approval for destructive ops + PII
- ✅ Architect SKILL.md references MADR template (not Nygard) for cross-team compatibility
- ✅ All bash wrappers use `set -euo pipefail` (strict mode)

## M1 review fixes applied (2026-07-08 22:30)

All 9 issues (3 must + 4 should + 2 nice) have been fixed and verified:

| # | Severity | Issue | Fix | Verified |
|---|---|---|---|---|
| 1 | 🔴 | tech-decisions-schema.json missing `additionalProperties: false` | Added at top + 2 nested levels | ✅ jsonschema rejects top + nested extras |
| 2 | 🔴 | 2 Dockerfiles missing non-root user | Added `addgroup/adduser/USER appuser` | ✅ `whoami` returns `appuser` |
| 3 | 🔴 | 3 .ps1 wrappers swallow `docker pull` errors | `if ($LASTEXITCODE -ne 0) { Write-Error; exit }` | ✅ Pull failure now fails fast |
| 4 | 🟡 | architect SKILL.md missing `Original prompt:` line | Added to Progress tracking | ✅ |
| 5 | 🟡 | architect SKILL.md missing 4-element contract | Added new "Sub-agent contract" section | ✅ |
| 6 | 🟡 | 2 Dockerfiles missing LABEL + HEALTHCHECK | Added OCI labels + HEALTHCHECK CMD | ✅ `docker inspect` shows both |
| 7 | 🟡 | 6 .ps1 wrappers missing input validation | Added `if ($args.Count -eq 0) { Write-Error; exit 2 }` | ✅ No-args call fails clearly |
| 8 | 🟢 | devops SKILL.md missing Lethal Trifecta | Added new "Lethal Trifecta mitigation" section | ✅ |
| 9 | 🟢 | data SKILL.md missing Pydantic `extra='forbid'` | Added new "Pydantic pattern" section with full example | ✅ |

**Verified smoke tests**:
- All 6 sandbox wrappers run with args ✅
- All 6 wrappers reject empty-args with clear error ✅
- Both custom images run as `appuser` (non-root) ✅
- Both custom images have OCI LABELs ✅
- Both custom images have HEALTHCHECK ✅
- schema validates valid + rejects top + nested extras ✅
- schema enforces minLength on rationale ✅

— lobster-gm (acting as Lead, accepting review fixes)

**M1.1-1.3 code is production-quality with 7 minor fixes recommended before M1.4.**

The 3 "must fix" issues (schema strictness, non-root user, pull error handling) should be addressed before any real task is run. The 4 "should fix" issues improve maintainability. The 2 "nice to have" can defer to M2.

— lobster-gm (acting as Lead, accepting review of 3 expert outputs)
