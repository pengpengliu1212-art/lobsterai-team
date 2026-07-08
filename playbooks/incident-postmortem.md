# Playbook: incident-postmortem — When Production Breaks

---
name: incident-postmortem
version: 1.0.0
owner: GM (lobsterai-team) + DevOps
applies_to: any SEV1 / SEV2 incident (SEV3 optional)
last_verified: 2026-07-08
triggers: [sev1-incident, sev2-incident, sev3-review]
see_also:
  - ../ROSTER.md
  - ../templates/expert-group.md
  - ./feat-0to1.md
---

> When: DevOps detects a production issue, or monitoring alerts, or a user reports a problem.
> Goal: stop the bleeding, restore service, document learning — all in a blameless system-focused way.

---

## Golden questions (self-test)

Before declaring this playbook "followed correctly", answer:

1. [ ] Was the incident channel created with a unique slug (`#inc-YYYY-MM-DD-<slug>`)?
2. [ ] Was IC assigned within 5 minutes of detect?
3. [ ] Was first status page ack posted within 30 minutes of detect?
4. [ ] Were updates posted every 30-60 minutes (even if "no news")?
5. [ ] Was severity matrix pinned in on-call channel?
6. [ ] Was MTTR clock stopped only when IC verified health check green for ≥15 min?
7. [ ] Was postmortem doc published within 48h of resolution?
8. [ ] Were action items: named owner + verifiable verb + specific outcome + tracker + deadline?
9. [ ] Did postmortem meeting happen within 1 week?
10. [ ] Was language blameless (no individual blame)?

If any unchecked for SEV1/SEV2 → playbook was NOT followed.

---

## 1. Severity classification (per incident.io 2026 / Google SRE)

When in doubt, declare the LOWER number. Over-declaring briefly mobilizes extra resources; missing a SEV1 because someone hesitated costs you customers.

| Severity | Definition | Response | Examples |
|---|---|---|---|
| **SEV1** | Complete outage OR data loss OR >10% users affected OR any security breach | Page on-call immediately, IC assigned <5 min, all-hands if unresolved in 30 min, status page <15 min | Checkout flow down for all users; database data corruption |
| **SEV2** | Major feature degraded, 1-10% users affected, revenue at risk but not halted, no data loss | Page on-call, response <15 min, status page <30 min, target resolution <4h | 30% of API requests returning 500; payment webhooks failing |
| **SEV3** | Degraded experience, workaround exists, <1% users affected, no revenue impact | Logged during business hours, assigned to service owner, target resolution <2 business days | One region elevated latency; one customer's slow dashboard |
| **SEV4** | Cosmetic or edge-case issue, no functional impact | Triage during business hours, add to backlog | UI rendering bug affecting <1% users |

**Hard rule**: SEV1 + SEV2 always require a postmortem. SEV3 only if the team wants to learn. SEV4 never.

---

## 2. Incident response — 5 phases (per ITOC360 + Google SRE IMAG)

```
[Detection] → [Triage] → [Response] → [Resolution] → [Post-Incident Review]
```

### Phase 1: Detection (0-5 min)

- **Source**: monitor alert OR user report OR PagerDuty page
- **Who**: DevOps + on-call engineer
- **Action**: declare severity in `#inc-YYYY-MM-DD-<slug>` channel, assign IC

### Phase 2: Triage (5-15 min)

- **Goal**: assess blast radius, decide mitigation strategy
- **Roles** (per Google SRE IMAG — Incident Management Action Group):
  - **IC (Incident Commander)** — orchestrates, decides, does NOT touch prod
  - **Operations Lead (OL)** — actually runs commands in sandbox
  - **Communications Lead (CL)** — status page + stakeholder updates every 30 min
  - **Scribe** — writes timeline + decisions to incident doc

If I lack critical data to decide → **IC escalates to GM**, do not guess (per Anthropic "agents know when they don't have enough data").

### Phase 3: Response (15 min - 4h)

- **Priority**: stop the bleeding, NOT diagnose root cause
- **Common mitigations** (in order of speed, per bugstack 2026):
  1. **Rollback** to last known good version (target: <5 min)
  2. **Feature flag off** the failing capability
  3. **Drain traffic** from affected nodes
  4. **Increase capacity** (scale up if saturation)
  5. **Disable dependency** (if third-party failing)
- **Update cadence**: every 30 min minimum, even if "no news" (per Rootly 2026)

### Phase 4: Resolution

Resolution ≠ alert clears. Resolution = **IC verifies** that:
- [ ] Service restored to normal baseline
- [ ] Underlying cause addressed OR documented as hypothesis
- [ ] Health checks green for ≥15 min
- [ ] Status page updated to "resolved"
- [ ] MTTR clock stopped with timestamp

### Phase 5: Post-Incident Review (within 48h)

- **Trigger**: SEV1 + SEV2 always, SEV3 if team wants learning
- **Blameless language** (per Google SRE — see §4 below)
- **Output**: postmortem doc + action items in JIRA with owners + due dates
- **Review meeting**: 30-60 min, within 1 week of incident

---

## 3. Workflow (numbered, lobsterai-team specific)

### Step 1: DevOps detects (alert / PagerDuty / user report)

- **Auto-actions**:
  - Create `#inc-YYYY-MM-DD-<slug>` channel
  - Page on-call
  - Pre-fill incident doc with: detect time, severity (default SEV2), affected services

### Step 2: IC assigned + severity confirmed

- **IC = on-call DevOps** (unless P0, then GM or designated senior)
- **IC's first 5 minutes**: confirm severity, assign roles, declare in channel

### Step 3: Mitigate (Operations Lead runs commands in sandbox)

- **ALL mitigation commands via `sandbox_exec.{ps1,sh}`** — NEVER host-level
- **Lethal Trifecta mitigation** (per Anthropic "Trustworthy agents"):
  - Input: only signed/pinned artifacts (not arbitrary user input)
  - Output: validated against schema before execution
  - Tools: scoped to deploy (no host access, no prod data modification without backup)

### Step 4: Update stakeholders (Communications Lead)

- **First ack within 15-30 min** (even if "investigating", per Rootly 2026)
- **Cadence**: every 30-60 min
- **Templates** (per Rootly 2026):
  - Investigating: "Status: Investigating. Issue: [brief]. Impact: [scope]. Next update by: [time]"
  - Identified: "Status: In Progress. Issue: [brief]. Root Cause: [what we found]. Actions: [what we're doing]. Next update: [time]"
  - Monitoring: "Status: Monitoring. Issue: [brief]. Resolution: [actions]. Impact Duration: [total time]"

### Step 5: Resolve

- IC verifies health checks green
- Status page → "resolved"
- Stop MTTR clock

### Step 6: Postmortem (within 48h, per Google SRE)

- **Schedule** postmortem meeting (30-60 min)
- **Invite** IC + OL + CL + Scribe + relevant Engineers + GM
- **Blameless facilitator** (NOT the IC) — usually GM or rotating role

### Step 7: Action items (per incident.io 5 elements)

Every action item must have ALL 5:

1. **Named individual owner** (not "the team")
2. **Verifiable verb** (not "improve")
3. **Specific outcome** (measurable)
4. **Home in real task tracker** (JIRA / GitHub Issues)
5. **Deadline** (date, not "soon")

❌ Bad: "Improve monitoring"
✅ Good: "Alice: add alert for DB replication lag >30s in Datadog, by 2026-07-15"

### Step 8: Track + close the loop

- **30-day check**: did the action item actually fix the problem?
- **Repeat incident rate** target: <5% (per incident.io benchmark)
- **Postmortem completion time** target: <48h from resolution
- **Action item completion rate** target: >50% (below = theater per incident.io)

---

## 4. Blameless language (per Google SRE + incident.io 2026)

**Golden rule**: "Systems fail. Humans make mistakes. It's normal. The goal is to fix the system, not punish people."

### Blame-oriented → Blameless translations

| ❌ Blame | ✅ Blameless |
|---|---|
| "Engineer X deployed a buggy change" | "The CI/CD pipeline did not catch the bug before production" |
| "The on-call was slow to respond" | "Alert noise caused fatigue, delaying triage of a critical signal" |
| "The team missed a warning sign" | "Warning signs were not documented in runbooks, making them easy to miss under pressure" |
| "Bob broke the prod database" | "Our migration runbook lacked the rollback step that would have prevented downtime" |
| "QA should have caught this" | "The test plan didn't cover this code path; let's add it to the regression suite" |

The first column produces "retrain the engineer" action items. The second produces **fixable system changes**.

---

## 5. Postmortem doc template (per Google SRE + OneUptime 2026)

```markdown
# Postmortem: [Incident Title]

**Date:** YYYY-MM-DD
**Severity:** SEV1 / SEV2 / SEV3
**Duration:** Xh Ym (detect to resolve)
**Author:** [Scribe name]
**Reviewers:** [IC + OL + CL + GM + relevant engineers]
**Status:** Draft / Reviewed / Published

## Executive Summary

[3-4 sentences max. For someone with 30 seconds. What happened, who was affected, how it was resolved.]

## Impact

- Users affected: [number + %]
- Services affected: [list]
- Data affected: [type + amount, or "none"]
- Revenue impact: [estimate or "none"]
- MTTD (Mean Time To Detect): Xm
- MTTR (Mean Time To Resolve): Xh Ym

## Timeline (UTC)

- HH:MM — [event, e.g., "alert fired: API p99 latency >5s"]
- HH:MM — [event, e.g., "IC assigned: @alice"]
- HH:MM — [event, e.g., "root cause identified: DB connection pool exhausted"]
- HH:MM — [event, e.g., "mitigation applied: increased pool size to 600"]
- HH:MM — [event, e.g., "IC verified health check green"]
- HH:MM — [event, e.g., "status page: resolved"]

## Root Cause (5 Whys)

1. Why did [symptom]?
2. Why did [that]?
3. Why did [that]?
4. Why did [that]?
5. Why did [that]?
**Root cause:** [single sentence]

## Contributing Factors

- [Factor 1: e.g., "no automated scaling"]
- [Factor 2: e.g., "no alert for pool exhaustion"]
- [Factor 3: e.g., "missing database retry logic"]

## What Went Well

- [Things that worked — keep doing these. Per Rootly 2026: "where did we get lucky?"]

## What Didn't

- [Things that failed — fix these]

## Action Items

| Layer | Owner | Action | Deadline | JIRA |
|---|---|---|---|---|
| Process | @alice | Add alert for X | 2026-07-15 | PROJ-123 |
| Tooling | @bob | Add circuit breaker | 2026-08-01 | PROJ-124 |
| Design | @carol | Add load test | 2026-08-15 | PROJ-125 |
| Policy | @dave | Add runbook step | 2026-07-20 | PROJ-126 |

## Lessons Learned

- [Insight 1]
- [Insight 2]
- [Insight 3]

## Follow-up Schedule

- 1-week review: YYYY-MM-DD, check high-priority items
- 1-month review: YYYY-MM-DD, verify all items complete
- 3-month review: YYYY-MM-DD, check for repeat incidents

## Completion Criteria

This postmortem is complete when:
- [ ] All high-priority action items deployed to production
- [ ] Medium-priority items scheduled in sprint planning
- [ ] Runbook updates merged and reviewed
- [ ] Postmortem published to internal wiki
```

---

## 6. Anti-patterns (lobsterai-team does NOT do)

- ❌ **Finger-pointing** in postmortem (violates blameless culture)
- ❌ **"Improve monitoring"** as action item (vague, unverifiable)
- ❌ **Skipping postmortem** for SEV1/SEV2 (mandatory)
- ❌ **Postmortem > 1 week after incident** (memory fades, per Google SRE)
- ❌ **Action items without named owner** ("the team" owns nothing)
- ❌ **"Untested" runbook updates** (per bugstack 2026: "test them quarterly")
- ❌ **Same incident twice** (repeat rate >5% = postmortems are theater)
- ❌ **IC doing hands-on technical work** (per Google SRE IMAG: IC coordinates, OL executes)

---

## 7. Communication cadence (per Rootly 2026)

| Time | Channel | Audience | Template |
|---|---|---|---|
| T+0 | PagerDuty / on-call | Internal responders | "Investigating" |
| T+15-30min | Status page | External users + stakeholders | "Investigating. Impact: [scope]. Next update: [time]" |
| T+30min | Status page | Same | "Identified. Root cause: [what we found]. Next: [what we're doing]" |
| Every 30-60min | Status page | Same | Progress update (even if "no news") |
| T+resolution | Status page | Same | "Resolved. Impact Duration: [time]. Postmortem scheduled: [date]" |
| T+48h | Internal wiki | Engineering team | Full postmortem doc published |
| T+1 week | Postmortem meeting | IC + OL + CL + relevant engineers + GM | 30-60 min review |
| T+1 month | Sprint planning | Engineering team | Action items integrated into backlog |
| T+3 months | Engineering review | Leadership | Repeat incident rate check |

---

## 8. Severity matrix (pinned in on-call channel)

```
| Severity | Page | Response | Status page | MTTR target | Postmortem |
|---|---|---|---|---|---|
| SEV1 | Immediate | All-hands | <15 min | <4h | Mandatory |
| SEV2 | Immediate | Page on-call | <30 min | <4h | Mandatory |
| SEV3 | Business hours | Service owner | None | <2 biz days | Optional |
| SEV4 | Backlog | - | None | - | Never |
```

---

## 9. Role boundaries during incident

| Role | During incident | After incident |
|---|---|---|
| **IC (DevOps on-call)** | Coordinates, decides, does NOT touch prod | Owns postmortem doc |
| **Operations Lead** | Runs commands in sandbox | Provides timeline data |
| **Communications Lead** | Status page + stakeholder updates | Owns external comms |
| **Scribe** | Live document, timestamps, decisions | Edits postmortem timeline |
| **GM** | Escalation point, resources, postmortem approval | Action item review |
| **Engineers (Coder/Architect/Data)** | On-call rotation OR consulted for specific issues | Own specific action items |

---

## 10. Failure modes (escalate to GM)

| Symptom | Escalation |
|---|---|
| IC cannot reach GM | GM appoints deputy IC |
| 3 retries on same mitigation | IC halts auto-retry, escalates to GM |
| IC lacks data to decide | IC asks GM to gather more context |
| Action item owner unresponsive for 7 days | GM reassigns or removes |
| Postmortem disputed by anyone | GM arbitrates, not the disputed person |
| Same incident type recurs within 30 days | GM triggers root-cause re-investigation |

---

## Artifacts (written to project tree)

```
/workspace/.lobsterai/devops/{timestamp}-incident-report.md
/workspace/.lobsterai/devops/{timestamp}-postmortem.md
/workspace/progress.md
```

---

## 5-round best-practice sources

1. **Incident management 2026** (incident.io) — severity matrix + auto communication + MTTR benchmarks
2. **Blameless postmortem culture** (Google SRE + SREschool + incident.io) — psychological safety + system thinking + "human error is start not end"
3. **Incident Command System (IMAG)** (Google SRE) — IC + OL + CL roles + 3Cs
4. **Postmortem action items** (incident.io 2026) — 5 elements + completion rate + repeat incident rate
5. **Incident communication** (Rootly 2026 + OneUptime) — update cadence + templates + postmortem completion <48h

Per **bugstack 2026** — runbooks tested quarterly, written for 3 AM, in-repo not wiki
