# Playbook: feat-0to1 — New Feature from Brief to Production

---
name: feat-0to1
version: 1.0.0
owner: GM (lobsterai-team)
applies_to: any new feature brief from the boss
last_verified: 2026-07-08
triggers: [boss-feature-brief, lobsterai-team-pipeline]
see_also:
  - ../ROSTER.md
  - ../templates/expert-group.md
  - ./incident-postmortem.md
---

> When: GM receives a new-feature brief from the boss and dispatches the 7-role team.
> Goal: ship a real, working feature end-to-end (0 → 1) within 6 weeks, with evidence.

---

## Golden questions (self-test)

Before declaring this playbook "followed correctly", answer:

1. [ ] Did GM write the 1-sentence MVP rule (specific user / outcome / workflow)?
2. [ ] Did PM produce user_stories + acceptance_criteria (Given/When/Then)?
3. [ ] Did Architect produce design.md with 5-phase framework + ≥1 Mermaid diagram?
4. [ ] Did Coder produce diff.patch + tests_pass: true (all in Docker sandbox)?
5. [ ] Did QA produce verdict: pass with coverage ≥ 70%?
6. [ ] Did PM final-accept from user perspective?
7. [ ] Did GM 3-gate accept + archive 3-piece set?
8. [ ] Did DevOps deploy behind feature flag (0% rollout, health check green)?

If any unchecked → feature is NOT done. Reject + retry.

---

## 1. The 1-sentence MVP rule (per MVP Scope 2026)

Before any work begins, force clarity:

> **"The MVP helps [specific user] achieve [specific outcome] through [one primary workflow]."**

If GM cannot fill in this sentence, **GM goes back to boss** for clarification. Do not guess.

---

## 2. Shape Up cycle (per agilefirst.io 2026)

6-week cycle, NOT 2-week sprints. Forces focus, prevents scope creep.

```
| Week 1-2  | Shaping (GM + PM + Architect together)        |
| Week 3-5  | Building (Coder + QA + Architect on call)    |
| Week 6    | Cooling (PM final accept + DevOps deploy)    |
```

---

## 3. Workflow (numbered)

### Step 1: GM receives brief + writes delivery contract

- **Input**: boss's 1-sentence brief (from 1-sentence MVP rule)
- **Output**: `/workspace/.lobsterai/gm/{timestamp}-brief.md` with:
  - Goal (1 sentence)
  - Scope (in / out)
  - Acceptance criteria seed (or note "PM to derive")
  - Risk register
  - Stop conditions

If brief has no scope, no ACs, no constraints → **GM goes back to boss**.

### Step 2: PM grooms (early pass)

- **Input**: GM's brief
- **Output**: `/workspace/.lobsterai/pm/{timestamp}-grooming.json` with:
  - `user_stories[]` (as_a / i_want / so_that)
  - `acceptance_criteria[]` (verifiable, atomic, BDD-style)
  - `out_of_scope[]` (explicit non-goals)
  - `non_functional_requirements` (latency, throughput, scale)

PM writes acceptance criteria in **Given/When/Then** format (BDD-style) per [Atlassian](https://www.atlassian.com/work-management/project-management/acceptance-criteria):

```
Given [precondition]
When [action]
Then [expected result]
```

PM's ACs must be **atomic, testable, positive**. PM escalates to GM if brief has no measurable ACs.

### Step 3: Architect designs

- **Input**: PM's user stories + ACs + out-of-scope
- **Output**: `/workspace/.lobsterai/architect/{timestamp}-design.md` + ADR files
  - 5-phase framework: Requirements / High-Level / Deep Dive / Scale/Reliability / Trade-off Analysis
  - At least 1 Mermaid diagram (component or sequence)
  - 2+ alternatives per tech decision in `tech-decisions.json`

Architect must address NFRs (latency / throughput / cost) explicitly.

### Step 4: Coder implements (in Docker sandbox)

- **Input**: Architect's design + PM's ACs
- **Output**: `diff.patch` + `tests_pass: true`
- **Tools used (mandatory)**: `sandbox_exec.{ps1,sh}` — NEVER host-level
- **Per AC**: smallest delta that moves AC from red to green, then test
- **Per Anthropic effort-scaling**: at most 4 sub-agents per task

Coder must **not** self-judge "done". Only QA does.

### Step 5: QA validates (in Docker sandbox)

- **Input**: Coder's diff + PM's ACs
- **Output**: `verdict: "pass" | "fail"` with `test_results{}` + per-AC check
- **Coverage threshold**: 70% (configurable)
- **If fail**: reject, send back to Coder (no self-repair)

### Step 6: PM final accept (user perspective)

- **Input**: Coder's diff + QA verdict
- **Output**: `accept: true | false` with `issues[]`
- PM re-reads their original grooming output, runs **user-scenario check** against actual diff

### Step 7: GM 3-gate acceptance

1. Start gate: brief was clear ✓
2. Key-deliverable gate: each expert's output passed schema validation ✓
3. Acceptance gate: all PM ACs verified, 3-piece set archived ✓

### Step 8: DevOps deploy (only after PM accept)

- **Prerequisites**: QA `verdict: pass` + PM `accept: true`
- **Strategy**: blue/green or canary (per DevOps playbook)
- **Feature flag**: behind a flag, 0% rollout initially (per Zylos 2026)
- **Health check**: must return 200 within 5 min of deploy

### Step 9: PM tracks success (post-launch)

- **30-day metric check**: was the 1-sentence MVP hypothesis validated?
- **Feedback loop**: real users vs. assumptions from brief
- **Feature flag lifecycle**: kill switch active 30 days, then archive (per LaunchDarkly best practice)

---

## 4. Role boundaries (hard rules)

| Role | Writes | Refuses |
|---|---|---|
| GM | brief, dispatch, archive | code, tests, design |
| PM | user stories, ACs, final accept | code, design, tests |
| Architect | design.md, ADRs | code, tests, grooming |
| Coder | diff.patch, unit tests | docs, design, judging done |
| QA | test report, verdict | code, design, accepting user value |
| DevOps | deploy, monitor | code, design, tests |
| Data | ETL, analysis, ML | code (outside scripts/), deploy |

If any role is asked to do another's work → refuse + escalate to GM.

---

## 5. Anti-patterns (lobsterai-team does NOT do)

- ❌ **"80% complete" status** (Shovel Method: 100% done or 100% not done)
- ❌ **"We can add this later"** (per Valtorian 2026: too-minimum MVP fails)
- ❌ **Self-judging "done"** without user evidence (Anthropic: trust boundary)
- ❌ **Long-lived feature branches** > 1-2 days (per Trunk-Based Development)
- ❌ **PR > 400 lines** (per codewithmukesh 2026 / Google eng-practices)
- ❌ **Feature flag without expiry** (per LaunchDarkly: 30-day kill switch then archive)
- ❌ **Skip QA, just ship** (even if boss asks)
- ❌ **Scope creep mid-cycle** (Shape Up 6-week cycle is fixed)

---

## 6. Exit criteria (per Shape Up)

The feature is "done" only when ALL:

- [ ] All PM acceptance criteria verified by PM final-accept
- [ ] QA `verdict: pass` (all tests + coverage ≥ 70%)
- [ ] 3-piece set archived (`brief.md` / `test-report.md` / `delivery.md`)
- [ ] Feature flag deployed at 0% (or 1% internal-only) with health check green
- [ ] DevOps post-deploy monitoring shows no P0 incidents in first 24h
- [ ] PM 30-day check completed: hypothesis validated or feature removed

If any unchecked → feature is NOT done. Reject + retry.

---

## 7. Effort-scaling rules (per Anthropic)

- 1 feature task → max 7 expert calls (1 per role)
- 1 grooming → 1 expert call (PM only)
- 1 design → max 4 sub-calls (Architect)
- 1 implementation → max 4 sub-calls (Coder)
- 1 validation → max 4 sub-calls (QA)

If task needs more sub-calls → escalate to GM, request scope reduction.

---

## 8. Failure modes (escalate to GM)

| Symptom | Escalation |
|---|---|
| Brief has no measurable ACs | GM goes back to boss for clarity |
| ACs not testable (subjective) | GM rejects, PM re-decomposes |
| 3 retries on same trade-off | GM arbitrates with boss |
| Coder's `tests_pass: false` 3 times | GM halts pipeline, may need boss input |
| QA reports pass but PM sees no user value | PM rejects, GM investigates |
| Feature flag rollout causes error spike | DevOps auto-rollback + GM alert |
| Scope creep mid-cycle | Shape Up 6-week cycle is fixed; new request = new cycle |

---

## Artifacts (written to project tree)

```
/workspace/.lobsterai/gm/{timestamp}-brief.md
/workspace/.lobsterai/pm/{timestamp}-grooming.json
/workspace/.lobsterai/pm/{timestamp}-acceptance.json
/workspace/.lobsterai/architect/{timestamp}-design.md
/workspace/.lobsterai/architect/{timestamp}-tech-decisions.json
/workspace/docs/adr/ADR-NNNN-{slug}.md
/workspace/.lobsterai/coder/{timestamp}-{slug}.json
/workspace/.lobsterai/coder/{timestamp}-{slug}.diff
/workspace/.lobsterai/qa/{timestamp}-verdict.json
/workspace/.lobsterai/devops/{timestamp}-deploy-log.json
/workspace/.lobsterai/gm/{timestamp}-delivery.md
/workspace/progress.md                       # append-only
```

## 5-round best-practice sources

1. **Sprint planning 2026** (Easy Agile + 4PMTI) — estimation + capacity + ceremony
2. **Git workflows 2026** (codewithmukesh + Medium) — TBD + GitHub Flow + PR size + feature flag
3. **MVP scope 2026** (Valtorian + Bolder Apps + Classic Informatics) — 1-sentence rule + scope creep
4. **Acceptance criteria 2026** (Testomat + Atlassian + Plane) — Given/When/Then + atomic + testable
5. **Feature flags 2026** (Zylos + DigitalApplied + GrowthBook + Unleash) — progressive delivery + 30-day lifecycle

Per **Shape Up 2026** (agilefirst.io) — 6-week cycle + shaping + betting table
