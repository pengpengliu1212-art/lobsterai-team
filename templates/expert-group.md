# Expert Group Template — lobsterai-team v1.0

> Standard 7-role Team collaboration template. All projects reuse this, trimmed by need.

## Team Members

| Role ID | Role | role-type | Responsibility slice |
|---|---|---|---|
| `gm` | General Manager | **lead** | Dispatch + 3-gate acceptance |
| `lobster-pm` | PM | expert | Groom + final accept (user value) |
| `lobster-architect` | Architect | expert | Design + tech selection |
| `lobster-coder` | Coder | expert | Implement + unit tests |
| `lobster-qa` | QA | expert | Tests + acceptance gate |
| `lobster-devops` | DevOps | expert | Deploy + monitor + security |
| `lobster-data` | Data engineer | expert | ETL + analytics + ML + DB |

## Standard SOP (7-stage pipeline)

```
[老板 brief]
   ↓
[GM] receive brief + write delivery contract
   ↓
[PM] groom: user stories + acceptance criteria
   ↓
[Architect] design + tech selection
   ↓
[Coder] implement + unit tests (in Docker sandbox)
   ↓
[QA] automated tests + acceptance checklist
   ↓
[PM] final accept (user perspective)
   ↓
[GM] 3-gate acceptance + archive
   ↓
[DevOps] deploy + monitor (only after QA + PM pass)
   ↓
[Data] metrics + reports (on demand)
```

## Lead dispatch rules

1. **Lead dispatches serially** — GM spawns one expert at a time, not parallel
   (avoids context chaos)
2. **Experts can parallelize internally** — one expert's sub-tasks can run in parallel
   (e.g. Coder modifying 3 files at once)
3. **Handoff is hard-validated** — every expert output is schema-checked + acceptance-list checked
4. **PM is at both ends** — grooming (don't let Coder self-decompose) and final accept
   (don't let Coder self-judge "done")
5. **DevOps is last** — only joins after QA + PM pass, avoids premature optimization

## Tool permission boundaries (allowed-tools)

```yaml
gm:                 [all]                   # GM: all tools
lobster-pm:         [read, write_doc, sessions_send, sessions_history]
lobster-architect:  [read, write_doc, search, sessions_history]
lobster-coder:      [read, write_code, exec_in_sandbox, sessions_send]
lobster-qa:         [read, run_test, write_report, exec_in_sandbox]
lobster-devops:     [read, exec_in_sandbox, cron, write_doc]
lobster-data:       [read, exec_in_sandbox, write_doc, search]
```

**Hard constraints**:
- PM cannot `write_code` (cannot change code)
- Coder cannot `write_doc` (cannot write product docs)
- QA cannot `write_code` (cannot self-repair; must reject)
- Only Lead (`gm`) has `all`

## Output contracts (per role, mandatory)

| Role | Input contract | Output contract | Failure escalation |
|---|---|---|---|
| PM | brief | `user_stories[]` + `acceptance_criteria[]` | GM |
| Architect | PM output | `design.md` + `tech_decisions{}` | GM |
| Coder | Architect output | `diff.patch` + `tests_pass: true` | GM |
| QA | Coder output | `test_results{}` + `verdict: pass/fail` | GM |
| PM | QA output | `accept: true/false` + `issues[]` | GM |
| GM | all | `delivery.md` + 3-piece set archive | 老板 |
| DevOps | GM accept | `deploy_log` + `health_check{}` | GM |
| Data | any | `analysis_report` + `sql[]` | GM |

## Trimming rules (smaller tasks)

- **Small** (< 3 files): drop Architect → PM → Coder → QA → PM
- **Data only**: drop Architect + QA → PM → Coder+Data → PM
- **Docs only**: drop Coder + QA + DevOps → PM → Architect → PM
- **Hotfix**: drop PM + Architect → Coder → QA → GM (post-archive later)

## Exception handling

1. **Expert cross-role** (PM writes code) → GM rejects + escalates
2. **Expert fails 3 retries** → auto-escalate to boss with full context
3. **Context loss between experts** → use `sessions_history` to fetch prior context
4. **Lead offline** (GM crashes) → boss takes over, new session restarts pipeline
