# lobsterai-team — Build Plan

> Per 老板 rules (2026-07-08 21:13): each task MUST do at least 5 rounds of best-practice
> research. Token budget is large (180M/mo). Goal is quality, not token saving.

## Status

- ✅ **M0** — 4 role skill bundles + sandbox wrappers + review fix
  - 4 SKILL.md rewritten per Anthropic template + OpenClaw official examples
  - 3 sandbox wrappers (.ps1 + .sh), 6 review issues fixed, 7 smoke tests passed
- ✅ **M1** — 7 role skill bundles + end-to-end test
  - M1.1 Architect (5 search rounds)
  - M1.2 DevOps (5 search rounds)
  - M1.3 Data (5 search rounds)
  - M1 review (9 issues found, all fixed)
- ✅ **M2** — 3 core playbooks + sandbox public-image policy (15 search rounds)
  - feat-0to1.md
  - incident-postmortem.md
  - weekly-report.md
  - All 6 sandbox wrappers switched to public (upstream) Docker Hub images
  - SANDBOX_RULES.md written (all dev/test in sandbox)
- ✅ Dashboard (lightweight SSE-based web) running on http://127.0.0.1:8080
- ⏳ **M3** — Cross-platform packaging
- ⏳ **M4** — Publish to ClawHub SkillHub

## M1 — Fill out 7 roles + end-to-end test

### M1.1 — `lobster-architect` skill bundle

**5 rounds of research required**:

1. Context7 → look up OpenClaw `architecture` skill (read full SKILL.md)
2. Context7 → look up MetaGPT `Architect` role class (find prompt + tools)
3. Web search → "ADR template Nygard lightweight" + "C4 model architecture"
4. Web search → "Anthropic sub-agent technical design contract" + "OpenAI function calling schema"
5. GitHub → search `MetaGPT metagpt/roles/architect.py` for actual prompt

**Deliverables**:
- `skills/lobster-architect/SKILL.md` (per Anthropic template)
- `skills/lobster-architect/scripts/sandbox_exec.ps1` (Python image)
- `skills/lobster-architect/scripts/sandbox_exec.sh`
- `skills/lobster-architect/references/adr-template.md`
- `skills/lobster-architect/assets/design-schema.json`

### M1.2 — `lobster-devops` skill bundle

**5 rounds of research required**:

1. Context7 → look up OpenClaw `deploy-checklist` skill
2. Web search → "DevOps agent responsibilities CI/CD IaC observability"
3. Web search → "Anthropic safety sub-agent security compliance agent"
4. Web search → "GitHub Actions security best practices 2026"
5. Tavily → "DevOps agent prompt engineering best practices multi-agent"

**Deliverables**:
- `skills/lobster-devops/SKILL.md`
- `skills/lobster-devops/scripts/sandbox_exec.ps1` (Alpine + curl + ssh)
- `skills/lobster-devops/scripts/sandbox_exec.sh`
- `skills/lobster-devops/references/security-checklist.md`
- `skills/lobster-devops/references/deploy-runbook.md`

### M1.3 — `lobster-data` skill bundle

**5 rounds of research required**:

1. Context7 → look up MetaGPT `DataInterpreter` class
2. Web search → "Data agent schema validation SQL generation best practices"
3. Web search → "Anthropic code execution sub-agent data analysis"
4. Web search → "ETL agent prompt engineering structured output"
5. GitHub → search `MetaGPT metagpt/roles/di/data_interpreter.py`

**Deliverables**:
- `skills/lobster-data/SKILL.md`
- `skills/lobster-data/scripts/sandbox_exec.ps1` (Python + pandas + sqlalchemy)
- `skills/lobster-data/scripts/sandbox_exec.sh`
- `skills/lobster-data/references/sql-style-guide.md`
- `skills/lobster-data/assets/analysis-schema.json`

### M1.4 — End-to-end test

**5 rounds of research required**:

1. Web search → "Anthropic multi-agent evaluation methodology"
2. Web search → "integration testing multi-agent system failure injection"
3. Web search → "LangSmith LangGraph observability agent tracing"
4. Web search → "sandbox agent error recovery retry strategies"
5. Web search → "CI/CD for LLM agent pipelines regression testing"

**Deliverables**:
- Run a real task end-to-end on `dream-novelist-web`
- Document pass/fail in `logs/m1-e2e-test.md`
- Identify any 3-fail cases and fix

## M2 — Playbooks

### M2.1 — `feat-0to1.md` (new feature from brief)

5 rounds: feature decomposition, MVP scoping, OpenClaw task delegation patterns, etc.

### M2.2 — `incident-postmortem.md`

5 rounds: incident response, blameless postmortem, root cause analysis

### M2.3 — `weekly-report.md`

5 rounds: PM reporting, OKR tracking, stakeholder communication

## M3 — Cross-platform packaging

### M3.1 — `install.ps1`

5 rounds: PowerShell installer best practices, registry changes, path handling

### M3.2 — `install.sh`

5 rounds: bash installer best practices, sudo, systemd, launchd

### M3.3 — CLI entry point

5 rounds: Node CLI, Python CLI, OpenClaw sub-agent registration

## M4 — Publish to ClawHub

### M4.1 — SkillHub manifest

5 rounds: ClawHub submission, version semantics, license

### M4.2 — Documentation site

5 rounds: GitHub Pages, MkDocs, Docusaurus

### M4.3 — Marketing

5 rounds: README, demo videos, social posts

## Working agreement

For every task in this plan:

1. **At least 5 rounds of best-practice research** before writing code
2. **Cite sources** in code comments / doc comments
3. **Smoke test** after every change
4. **Self-review** at end of each milestone
5. **Update this plan** as we learn

If a task needs more than 5 rounds, do more — never less.
