# lobsterai-team-data (lightweight)
# Base image for lobster-data role.
# Per lobster-data SKILL.md: needs pandas, sqlalchemy, openpyxl, duckdb, jsonschema, pydantic.
# Per M1 review (2026-07-08): non-root user + LABEL + HEALTHCHECK added.
# Removed (compile-heavy, OOM during build): scipy, scikit-learn, matplotlib, seaborn, plotly.
# If ML tasks need them, install at runtime via 'pip install --target /workspace/.libs <pkg>'.

FROM python:3.12-alpine

# Minimal system deps
RUN apk add --no-cache \
    bash \
    curl \
    git \
    jq \
    && rm -rf /var/cache/apk/*

# Install Python data stack (no compilation, just pure-Python or pre-built wheels)
RUN pip install --no-cache-dir --break-system-packages \
    pandas==2.2.3 \
    numpy==1.26.4 \
    sqlalchemy==2.0.36 \
    openpyxl==3.1.5 \
    duckdb==1.1.3 \
    pydantic==2.9.2 \
    jsonschema==4.23.0 \
    && pip cache purge

# Verify
RUN python3 -c "import pandas, numpy, sqlalchemy, openpyxl, duckdb, pydantic, jsonschema; print('Core data libs OK')"

# --- M1 review fixes: non-root user + OCI labels + HEALTHCHECK ---

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup -h /workspace

# Ensure /workspace is owned by appuser
RUN mkdir -p /workspace && chown -R appuser:appgroup /workspace

# OCI image-spec standard labels (per Sysdig / Snyk 2026 best practices)
LABEL org.opencontainers.image.title="lobsterai-team-data" \
      org.opencontainers.image.description="Data engineer role sandbox image for lobsterai-team (pandas, sqlalchemy, duckdb)" \
      org.opencontainers.image.version="1.0.0" \
      org.opencontainers.image.source="https://github.com/lobsterai-team/lobsterai-team" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.authors="lobsterai-team" \
      org.opencontainers.image.documentation="file:///H:/software-dev-Lob/lobsterai-team/skills/lobster-data/SKILL.md"

# Switch to non-root user
USER appuser

# Healthcheck (per Sysdig 5.4)
HEALTHCHECK --interval=60s --timeout=5s --retries=2 \
    CMD python3 -c "import pandas, duckdb, jsonschema; print('OK')" || exit 1

WORKDIR /workspace

CMD ["/bin/sh"]
