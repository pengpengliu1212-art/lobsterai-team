# Incident Response Runbook (AI / Agent Systems)

> Per Google SRE postmortem culture, PagerDuty AI SRE Agent, and Anthropic "Trustworthy Agents".

## 5-Step Triage (first 15 minutes)

### Step 1: Acknowledge (minute 0-2)

- Declare incident in incident channel (`#inc-YYYY-MM-DD-<slug>`)
- Get on-call bridge (Zoom / meet / phone)
- Assign Incident Commander (IC) — typically the on-call DevOps
- Set severity (SEV1 / SEV2 / SEV3 / SEV4)

### Step 2: Assess (minute 2-5)

Answer:

- **What is broken?** (specific symptom, not "AI is broken")
- **Blast radius?** (how many users affected, which services)
- **When did it start?** (check deploy log, alert timestamp)
- **What changed?** (recent deploy / config / dependency update)

### Step 3: Mitigate (minute 5-30)

Priority: **stop the bleeding**, do not diagnose.

Common mitigations (in order of speed):

1. **Rollback** to last known good version (target: < 5 min)
2. **Feature flag off** the failing capability
3. **Drain traffic** from affected nodes
4. **Increase capacity** (scale up, if saturation is the cause)
5. **Disable dependency** (if third-party is failing)

If mitigation unclear → **escalate to GM / boss**, do not guess.

### Step 4: Communicate (every 15 minutes)

- Status page update
- Stakeholder message (severity-appropriate)
- Incident channel updates (timestamped, factual, no speculation)

### Step 5: Document (start at minute 0, update continuously)

Open `incident-report.md` immediately. Do not wait for resolution.

## AI-Specific Failure Layers (per Tian Pan 2026)

LLM incidents have **layer-specific** root causes. Apply different fixes:

| Layer | Symptom | Fix |
|---|---|---|
| **Retrieval** | "AI doesn't know X" | Check index health, refresh embeddings, verify chunk pipeline |
| **Quality** | "AI output is wrong" | Check prompt version, eval dataset, model version |
| **Performance** | "AI is slow" | Check token usage, model latency, rate limits, queue depth |
| **Cost spike** | "Token bill exploded" | Check for prompt loops, retry storms, large context abuse |
| **Data incident** | "AI leaked PII" | Check input sanitization, output filtering, prompt injection |

Generic "AI is broken" is not a diagnosis — name the layer.

## Version Snapshot (required in every postmortem)

For AI incidents, capture **full version snapshot** at incident start:

- Model version (e.g., `claude-sonnet-4-6`)
- Prompt version (git SHA)
- Retrieval index version
- Tool schema version
- Eval dataset version
- Guardrail version

Without complete snapshot, you cannot reproduce or validate the fix.

## Postmortem (Blameless, per Google SRE)

After resolution, within 1 week:

### Structure

```markdown
# Incident Report: [Title]

**Date:** YYYY-MM-DD
**Severity:** SEV1 / SEV2 / SEV3 / SEV4
**Duration:** Xh Ym
**Author:** [Name]
**Reviewers:** [Names]

## Summary

[1-2 sentences: what happened, who was affected, how it was resolved]

## Impact

- Users affected: [number]
- Services affected: [list]
- Data affected: [type]
- Cost: [if any]

## Timeline (UTC)

- HH:MM — [event]
- HH:MM — [event]
- HH:MM — Mitigation applied
- HH:MM — Resolved

## Root Cause

[Layer-specific: retrieval / quality / performance / cost / data]

## Why We Missed It

- [What alerting failed]
- [What testing didn't cover]
- [What design assumption was wrong]

## Action Items

| Layer | Owner | Action | Due |
|---|---|---|---|
| Data | @name | Add eval case for X | YYYY-MM-DD |
| Prompt | @name | Tighten Y constraint | YYYY-MM-DD |
| Policy | @name | Block Z in production | YYYY-MM-DD |

## What Went Well

- [Things that worked — keep doing these]

## What Didn't

- [Things that failed — fix these]
```

### Blameless language rules

- ❌ "Alice broke X" → ✅ "X broke; here's why the system allowed it"
- ❌ "Bob missed Y" → ✅ "Y was missed; here's how we'll catch it next time"
- ❌ "Team didn't test Z" → ✅ "Our test plan didn't cover Z; here's the gap"

### Joint sign-off

CIO + CDO (or equivalent) jointly sign the action items. Without this, the
postmortem is a polite document nobody acts on.

## Common AI Failure Modes & Responses

### Prompt injection via external data

- **Symptom**: AI produces unexpected output after reading user file
- **Mitigation**: Spotlighting (mark external content), input sanitization
- **Long-term**: Tool result wrapping with clear trust boundary

### Retry storm / infinite loop

- **Symptom**: Token bill spikes 100x, same tool called repeatedly
- **Mitigation**: Token budget per session, circuit breaker
- **Long-term**: Loop detection in agent runtime, max-iterations limit

### Eval gap (silent quality degradation)

- **Symptom**: User complaints about "weird" AI output, no error in logs
- **Mitigation**: Distribution shift detection (compare input embeddings to baseline)
- **Long-term**: Add eval cases for the failure mode

### Cost spike (token abuse)

- **Symptom**: Daily bill 10x normal
- **Mitigation**: Rate limit per user/session, alert on cost threshold
- **Long-term**: Budget enforcement at agent runtime

## Runbook Self-Check

Before declaring incident resolved:

- [ ] All 5 triage steps documented with timestamps
- [ ] Layer-specific root cause named (not "AI broken")
- [ ] Full version snapshot captured
- [ ] Action items have named owners + due dates
- [ ] Blameless language used throughout
- [ ] Joint sign-off from leadership
- [ ] Runbook updated with any new lessons learned
