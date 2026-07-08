# lobsterai-team-devops
# Base image for lobster-devops role.
# Per lobster-devops SKILL.md: needs git, openssh-client, curl, kubectl, helm.
# Per M1 review (2026-07-08): non-root user + LABEL + HEALTHCHECK added.

FROM python:3.12-alpine

# Install devops tools
RUN apk add --no-cache \
    bash \
    curl \
    wget \
    jq \
    git \
    openssh-client \
    openssl \
    ca-certificates \
    tzdata \
    && rm -rf /var/cache/apk/*

# kubectl (pinned version, immutable)
ARG KUBECTL_VERSION=v1.31.0
RUN curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
        -o /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# helm (pinned version, immutable)
ARG HELM_VERSION=v3.15.4
RUN curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" \
        | tar -xz -C /tmp \
    && mv /tmp/linux-amd64/helm /usr/local/bin/helm \
    && rm -rf /tmp/linux-amd64 \
    && chmod +x /usr/local/bin/helm

# Verify installs
RUN git --version \
    && curl --version \
    && kubectl version --client \
    && helm version

# --- M1 review fixes: non-root user + OCI labels + HEALTHCHECK ---

# Create non-root user (Alpine uses addgroup/adduser with -S for system)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup -h /workspace

# Ensure /workspace is owned by appuser (read-write, since sandbox mounts here)
RUN mkdir -p /workspace && chown -R appuser:appgroup /workspace

# OCI image-spec standard labels (per Sysdig / Snyk 2026 best practices)
LABEL org.opencontainers.image.title="lobsterai-team-devops" \
      org.opencontainers.image.description="DevOps / SRE role sandbox image for lobsterai-team" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/lobsterai-team/lobsterai-team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="lobsterai-team" \
      org.opencontainers.image.documentation="file:///H:/software-dev-Lob/lobsterai-team/skills/lobster-devops/SKILL.md"

# Switch to non-root user (per Docker / Sysdig 2026 best practice)
USER appuser

# Healthcheck (per Sysdig 5.4 — include health/liveness checks)
HEALTHCHECK --interval=60s --timeout=5s --retries=2 \
    CMD sh -c 'which kubectl && which helm && which git && which curl' || exit 1

# Set working dir
WORKDIR /workspace

CMD ["/bin/sh"]
