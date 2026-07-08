# Roster — 7 Roles at a Glance

| # | Role ID | role-type | What they do | When to call |
|---|---|---|---|---|
| 1 | `gm` | **lead** | Task dispatch, expert orchestration, 3-gate acceptance | Always on (this agent) |
| 2 | `lobster-pm` | expert | User-story grooming + final user-value acceptance | Start (groom) + end (accept) |
| 3 | `lobster-architect` | expert | System design + tech selection | After PM, before Coder |
| 4 | `lobster-coder` | expert | Full-stack / backend / mobile implementation | After Architect |
| 5 | `lobster-qa` | expert | Automated tests + acceptance gate | After Coder |
| 6 | `lobster-devops` | expert | Deploy + monitor + security compliance | After QA + PM accept |
| 7 | `lobster-data` | expert | ETL + analytics + ML models + DB | On-demand (data tasks) |

## Tool permissions (allowed-tools per role)

```yaml
gm:                 [all]
lobster-pm:         [read, write_doc, sessions_send, sessions_history]
lobster-architect:  [read, write_doc, search, sessions_history]
lobster-coder:      [read, write_code, exec_in_sandbox, sessions_send]
lobster-qa:         [read, run_test, write_report, exec_in_sandbox]
lobster-devops:     [read, exec_in_sandbox, cron, write_doc]
lobster-data:       [read, exec_in_sandbox, write_doc, search]
```

**Key constraints**:
- PM cannot `write_code` (physically cannot change code)
- Coder cannot `write_doc` (cannot write product docs)
- QA cannot `write_code` (cannot self-repair; must reject)
- Only Lead (`gm`) has `all`

## Standard 7-stage pipeline

```
老板 brief
   ↓
GM: receive brief, write delivery contract
   ↓
PM: groom → user stories + acceptance criteria
   ↓
Architect: design + tech decisions
   ↓
Coder: implement + unit tests (in sandbox)
   ↓
QA: automated tests + acceptance gate
   ↓
PM: final accept (user perspective)
   ↓
GM: 3-gate acceptance + archive
   ↓
DevOps: deploy + monitor (after QA + PM pass)
   ↓
Data: metrics + reports (on demand)
```

## Trimming rules (smaller tasks)

- **Small** (< 3 files): drop Architect → PM → Coder → QA → PM
- **Data only**: drop Architect + QA → PM → Coder+Data → PM
- **Docs only**: drop Coder + QA + DevOps → PM → Architect → PM
- **Hotfix**: drop PM + Architect → Coder → QA → GM
