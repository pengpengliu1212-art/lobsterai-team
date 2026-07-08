# Playbook: weekly-report — Weekly Stakeholder Update

---
name: weekly-report
version: 1.0.0
owner: PM (lobsterai-team) + GM
applies_to: every Friday (end of work week)
last_verified: 2026-07-08
triggers: [weekly-friday, gm-prompt-status]
see_also:
  - ../ROSTER.md
  - ./feat-0to1.md
  - ./incident-postmortem.md
---

> When: every Friday (or end of work week) — lobsterai-team writes a weekly report to GM + boss.
> Goal: communicate progress, blockers, metrics, and next-week priorities in 5-15 minutes of read time.

---

## Golden questions (self-test)

Before publishing the weekly report, answer:

1. [ ] Did RAG status reflect actual schedule / quality / scope / team health?
2. [ ] Was headline 1-2 sentences max (executive summary)?
3. [ ] Were "Completed" entries outcomes not activities (e.g., "launched X" not "worked on X")?
4. [ ] Were DORA metrics included (DF / LT / MTTR / CFR) with week-over-week trend?
5. [ ] Were blockers specific (with impact + owner + due date)?
6. [ ] Were "Upcoming" priorities ordered (top 3)?
7. [ ] Were "Decisions needed" listed with recommendation?
8. [ ] Was "Wins" section included (per Rootly 2026 "where did we get lucky?")?
9. [ ] Did GM review + format before distribution?
10. [ ] Was read time ≤ 15 minutes?

If any unchecked → report quality is not yet acceptable.

---

## 1. Audience and cadence (per Centercode 2026 + Teamwork)

**Primary audience**: GM (immediate manager) + boss (final stakeholder)
**Secondary audience**: cross-team collaborators (read-only)
**Cadence**: weekly (per PMI 2026: matches pace of change)
**Read time target**: 5-15 minutes (per Tosea 2026: "PMs spend 3-5h/week writing reports")
**Distribution**: markdown file in workspace + short summary in chat

**Tailoring** (per Planisware 2026):
- GM: detailed metrics + blockers + decisions needed
- Boss: 1-paragraph headline + RAG status + key decisions

---

## 2. Report structure (7 sections, per Centercode 2026)

```
# Weekly Report — lobsterai-team — Week of YYYY-MM-DD

1. RAG Status (1 line)
2. Headline (1-2 sentences)
3. Completed this week (PM-managed list)
4. DORA metrics (DevOps-managed)
5. Blockers (anyone can add; GM reviews)
6. Upcoming week (PM-managed priorities)
7. Decisions needed from GM (architect-managed)
```

---

## 3. Workflow (numbered)

### Step 1: PM assembles report (Wednesday)

- **Input**: all experts' daily progress + GitHub activity + dashboard logs
- **Output**: draft at `/workspace/.lobsterai/gm/{timestamp}-weekly-report.md`

### Step 2: DevOps adds DORA metrics (Thursday)

- **Pull from**: dashboard + GitHub API + incident tracker
- **Format**: table with 4 DORA metrics + week-over-week trend

### Step 3: Architect adds "decisions needed" (Thursday)

- **From**: pending ADRs + open questions
- **Format**: list of decisions with recommendation + impact

### Step 4: GM reviews + formats (Friday morning)

- **GM consolidates**, edits, sends
- **Distribution**: workspace + chat summary

### Step 5: 1-on-1 with boss if needed (Friday afternoon)

- **Trigger**: any SEV1/SEV2 in last week, or critical decision pending
- **Format**: 15-30 min walkthrough, not a meeting

---

## 4. DORA metrics (per larridin 2026 + DORA Report)

| Metric | Definition | Elite | High | Medium | Low |
|---|---|---|---|---|---|
| **Deployment Frequency** | How often code reaches production | Multiple per day | Daily-Weekly | Weekly-Monthly | < Monthly |
| **Lead Time for Changes** | Commit → Production | < 1 hour | 1 day-1 week | 1 week-1 month | > 1 month |
| **Failed Deployment Recovery Time** | Time to recover from failed deploy (renamed from MTTR) | < 1 hour | < 1 day | 1 day-1 week | > 1 week |
| **Change Failure Rate** | % of deployments requiring rollback or fix-forward | 0-15% | 16-30% | 16-30% | 46-60% |

**Per larridin 2026**: "DORA measures delivery outcomes, not developer activity. They do not count lines of code or commits or hours worked. They measure how frequently code ships, how quickly it reaches production, how reliably it performs, and how fast the team recovers when it does not."

**DORA + DX Core 4** (per getdx 2026): DORA covers Speed + Quality. Core 4 adds Effectiveness (Developer Experience Index) + Impact (R&D time allocation). Use both for full picture.

---

## 5. RAG status (per monday.com 2026)

Use **Red/Amber/Green** for each major dimension:

| Dimension | R | A | G |
|---|---|---|---|
| **Schedule** | Missed commit date | Risk of miss | On track |
| **Quality** | Tests failing, prod incident | Coverage <70% | All tests pass, coverage >70% |
| **Scope** | >20% scope creep | Some additions | In scope |
| **Team health** | Blocker unresolved >7d | Blocker <7d | No blockers |

**Overall RAG**: red if any R, amber if any A, green otherwise.

---

## 6. Template (markdown)

```markdown
# Weekly Report — lobsterai-team — Week of YYYY-MM-DD

**Author:** PM
**Status:** Draft / Final
**Date:** YYYY-MM-DD

## RAG Status

- Schedule: 🟢
- Quality: 🟢
- Scope: 🟢
- Team health: 🟡
- **Overall:** 🟢

## Headline

[1-2 sentences. What was the most important thing this week?]

## Completed this week

- [PM-managed list. Per Centercode 2026: outcomes not activities.]
- ✅ Shipped user profile editing (US-123)
- ✅ Closed 3 production incidents, 0 SEV1
- ✅ Onboarded 1 new expert skill (lobster-data)

## DORA metrics

| Metric | This week | Last week | Trend | Target |
|---|---|---|---|---|
| Deployment Frequency | 3/week | 2/week | ↑ | Daily |
| Lead Time for Changes | 4h | 6h | ↓ | <1h |
| Failed Deployment Recovery | 12min | N/A (no failures) | — | <1h |
| Change Failure Rate | 0% | 0% | → | <15% |

## OKR progress (if applicable)

| Objective | Key Result | Score | Trend |
|---|---|---|---|
| Improve deployment speed | Reduce lead time to <1h | 0.6 | ↑ |
| Improve reliability | Reduce CFR to <15% | 0.9 | → |

## Blockers

[Specific impact per item, per Centercode 2026]
- 🟡 Boss approval needed for [X] (impact: blocks [Y] by [date])
- 🟡 Coder waiting on Architect design for [Z] (impact: 1-day delay on [W])

## Upcoming week (PM priorities)

1. [Top priority: explicit next-week deliverable]
2. [Second priority]
3. [Third priority]

## Decisions needed from GM

[Architect-managed, with recommendation]
- **D-001**: Approve [X] vs [Y]? (impact: 1-week delay if not by Mon)
  - Recommendation: [Z] because [reason]
- **D-002**: [etc.]

## Risks (forward-looking)

- [New risks identified this week that GM should know about]

## Wins (per Rootly 2026 "where did we get lucky?")

- [Things that went well that we should keep doing]
```

---

## 7. Anti-patterns (lobsterai-team does NOT do)

- ❌ **Information overload** (per Teamwork 2026: "status report is not a project journal")
- ❌ **Activity-focused** (per Centercode 2026: "focus on outcomes not activities" — "worked on profile" ❌, "launched profile editing" ✅)
- ❌ **Vague blockers** ("some technical issues" ❌, "API rate limits blocking data sync testing, need infra review by Thursday" ✅)
- ❌ **Same template forever** (per Teamwork 2026: "first version is never right, ask stakeholders")
- ❌ **Reactive only** — report only bad news; pair with action plan (per monday 2026)
- ❌ **One report fits all** — executives get headlines, engineers get detail (per Planisware 2026)
- ❌ **Skipping wins section** — celebrating what works is part of learning culture (per Rootly 2026)

---

## 8. Effort-scaling (per Anthropic)

- 1 weekly report → max 4 sub-calls (PM drafts + DevOps metrics + Architect decisions + GM review)
- If team grows >10 → add per-team sub-reports that roll up to lobsterai-team

---

## 9. Failure modes (escalate to GM)

| Symptom | Escalation |
|---|---|
| PM doesn't have time to write report | GM takes over or skips week (rare) |
| Same blocker reported 3 weeks running | GM halts pipeline, addresses blocker directly |
| DORA metrics all R | GM halts new feature work, focuses on remediation |
| Boss questions RAG status | GM provides written context, escalates if disagreement |
| Postmortem action items >50% overdue | GM triggers accountability review |

---

## 10. Variations (per EM-Tools 2026)

For retrospectives or sprint reviews, swap the structure to:

### 4Ls (Liked, Learned, Lacked, Longed For)

- **Liked**: positive experiences this week
- **Learned**: growth moments
- **Lacked**: missing resources or support
- **Longed For**: wishes for the future

### Sailboat (visual)

- **Wind**: what propels forward
- **Anchors**: what holds back
- **Rocks**: risks ahead
- **Island**: goal

### Mad / Sad / Glad

- **Mad**: frustrations
- **Sad**: disappointments
- **Glad**: celebrations

These are better for retrospectives. Use the standard 7-section template for stakeholder weekly reports.

---

## Artifacts (written to project tree)

```
/workspace/.lobsterai/gm/{timestamp}-weekly-report.md
/workspace/.lobsterai/gm/{timestamp}-dora-metrics.json  # raw metrics
/workspace/progress.md
```

---

## 5-round best-practice sources

1. **Status report format** (Centercode 2026 + Teamwork + Tosea) — outcomes not activities + audience-tailored + cadence matches pace
2. **DORA metrics** (larridin 2026 + Faros AI + DORA Report + Thoughtworks) — 4 metrics + Elite benchmarks + outcome-oriented
3. **Standups vs async** (Atlassian + Slack + Spinach 2026) — focus on blockers + cadence adapts to context
4. **OKR tracking** (Asana 2026 + Mooncamp + Lattice) — 0.0-1.0 scoring + weekly check-ins + 3-5 objectives
5. **Retrospectives** (EM-Tools 2026 + Indeed Engineering + Harness) — 3-column + variations + action item discipline

Per **monday 2026** — pair bad news with action plan, present solutions not just problems
Per **Centercode 2026** — "focus on outcomes rather than activities"
