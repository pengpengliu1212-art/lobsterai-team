# DevOps Security Checklist

> Per OWASP Agentic Top 10, SLSA Framework, and Anthropic "Trustworthy Agents".
> lobster-devops runs this before every deploy.

## Pre-deploy (required)

### Build provenance (SLSA L1 minimum)

- [ ] SBOM generated (SPDX or CycloneDX format)
- [ ] Provenance attestation generated (in-toto / SLSA format)
- [ ] Artifact signed (Sigstore / Cosign preferred over PGP)
- [ ] Build is reproducible from source + dependencies

### Dependency security

- [ ] All `actions@` references pinned by SHA, not tag
- [ ] All `package.json` / `requirements.txt` / `go.mod` dependencies pinned to specific versions or hashes
- [ ] No known critical CVEs in dependencies (run `npm audit` / `pip-audit` / `govulncheck`)
- [ ] Lock file committed (package-lock.json / poetry.lock / go.sum)

### Container security

- [ ] Base image from trusted registry (Docker Hub official / gcr.io / quay.io)
- [ ] Base image scanned (Trivy / Snyk / Grype)
- [ ] No `--privileged` in container run
- [ ] `--read-only` filesystem
- [ ] `--cap-drop=ALL`
- [ ] `--security-opt no-new-privileges` (if supported)
- [ ] No `latest` tag in production
- [ ] Multi-stage build (no build tools in final image)

### Sandbox safety (per Anthropic + Docker)

- [ ] IMDS endpoint `169.254.169.254` blocked
- [ ] Network egress default-deny with explicit allowlist
- [ ] Only deploy artifacts mounted (not full filesystem)
- [ ] `--tmpfs` for temporary files (no persistent host writes)
- [ ] Seccomp profile attached (default or custom strict)
- [ ] AppArmor profile attached (if Linux)

## Runtime (per "Lethal Trifecta" mitigation)

- [ ] All agent outputs validated before execution (no direct exec)
- [ ] All agent inputs marked with delimiters (Spotlighting pattern)
- [ ] Tool calls logged with inputs and outputs (audit trail)
- [ ] No shared mutable state between agent invocations
- [ ] Secrets never passed via environment variables in tool args (use secret manager)

## Observability (per AI SRE best practices)

- [ ] Structured traces for every agent action (prompt, model, tools, output)
- [ ] Logs include trace ID for correlation
- [ ] Metrics: latency, error rate, cost per request
- [ ] Alerts: anomaly detection on distribution shift
- [ ] Dashboard: per-agent health + cost

## Incident readiness

- [ ] Runbook exists for every common failure mode
- [ ] On-call rotation defined (PagerDuty / Opsgenie)
- [ ] Status page auto-update from alerts
- [ ] Postmortem template accessible
- [ ] Blameless culture documented and signed by leadership

## Compliance (per regulatory framework)

- [ ] GDPR: data processing legal basis documented
- [ ] SOC 2: access controls + audit logging
- [ ] ISO 42001: AI management system in place
- [ ] NIST AI RMF: risk assessment + governance

## Post-deploy (required)

- [ ] Health check endpoint returns 200 within 5 minutes
- [ ] Latency p99 within SLO
- [ ] Error rate within SLO
- [ ] Rollback plan tested and ready
- [ ] Deploy log archived with all artifacts
