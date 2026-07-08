# ADR-NNNN: [Short Title of Decision]

**Status:** Proposed | Accepted | Deprecated | Superseded
**Date:** YYYY-MM-DD
**Deciders:** [Who needs to sign off — typically GM + relevant expert]
**Last verified:** YYYY-MM-DD
**Owner:** [Single name, not "the team"]

## Context and Problem Statement

[What is the situation? What forces are at play? Why are we making this decision now?]

[Describe the context in 2-3 short paragraphs. Future readers should understand the
problem without reading the entire codebase.]

## Decision Drivers

* [Driver 1 — e.g., "Must handle 10K req/s"]
* [Driver 2 — e.g., "Team has no Kubernetes experience"]
* [Driver 3 — e.g., "Budget limits us to managed services"]
* [Driver 4 — e.g., "Must ship in 2 weeks"]

## Considered Options

### Option A: [Name]

[1-paragraph description of how this option would work.]

| Dimension | Assessment |
|-----------|------------|
| Complexity | Low / Medium / High |
| Cost (initial) | $X / month |
| Cost (ongoing) | $X / month |
| Scalability | Low / Medium / High |
| Team familiarity | Low / Medium / High |
| Time to market | Days / Weeks / Months |
| Maintenance burden | Low / Medium / High |

**Pros:**
- [Pro 1]
- [Pro 2]

**Cons:**
- [Con 1]
- [Con 2]

### Option B: [Name]

[Same format as Option A]

### Option C: [Name] (optional)

[Same format]

## Trade-off Analysis

[Key trade-offs between options with clear reasoning. Why Option A wins (or loses).]

[Use a comparison table or bullet list — whichever is clearer for this decision.]

## Decision

We chose **Option A: [Name]** because [1-2 sentence summary of primary reason].

[Optional: "with the following conditions:" — any caveats or follow-ups.]

## Consequences

### Positive

- [What becomes easier]
- [What unlocks future work]

### Negative

- [What becomes harder]
- [What we'll need to learn]
- [What risks we accept]

### Neutral

- [What stays the same]
- [What we'll need to revisit as system grows]

## Action Items

1. [ ] [Implementation step — typically becomes a Coder task]
2. [ ] [Follow-up — typically becomes another ADR or playbook]
3. [ ] [Documentation update]

## External Dependencies

- [Vendor / framework / regulatory doc that this decision depends on]
- [Drift trigger — what would make us revisit this decision]

## Notes

[Optional: links to discussions, prototypes, benchmarks that informed this decision]

[Optional: supersession — if this ADR replaces a previous one, link to it here and
to the previous ADR's "Superseded by" field.]
