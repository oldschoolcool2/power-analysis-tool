# ==============================================================================
# Multi-Stage Dockerfile for R/Shiny Power Analysis Tool
# ==============================================================================
# Stage 1: Base dependencies (shared by dev and prod)
# Stage 2: Development environment (includes testing tools)
# Stage 3: Production runtime (minimal, optimized)
# ==============================================================================

# Build arguments for version management
ARG R_VERSION=4.4.0
ARG BASE_IMAGE=rocker/shiny
# Digest pinning for reproducible builds (rocker/shiny:4.4.0 as of 2025-10-25)
# Update periodically for security patches: docker pull rocker/shiny:4.4.0 && docker inspect rocker/shiny:4.4.0 | grep -A 1 RepoDigests
ARG BASE_IMAGE_DIGEST=sha256:a76bfc201e36b5da0727d99737a2e7bf0d9df56e812c6fb08774c59f17dac048

# ------------------------------------------------------------------------------
# Stage 1: Base - System dependencies and renv setup
# ------------------------------------------------------------------------------
FROM ${BASE_IMAGE}:${R_VERSION}@${BASE_IMAGE_DIGEST} AS base

# Re-declare ARGs after FROM to use in LABELs
ARG R_VERSION
ARG BASE_IMAGE

# Image metadata following OCI annotation standards
LABEL org.opencontainers.image.title="Power Analysis Tool"
LABEL org.opencontainers.image.description="R/Shiny application for statistical power analysis and sample size calculation"
LABEL org.opencontainers.image.authors="Development Team"
LABEL org.opencontainers.image.documentation="https://github.com/your-repo/power-analysis-tool/docs"
LABEL org.opencontainers.image.base.name="${BASE_IMAGE}:${R_VERSION}"
LABEL maintainer="Development Team"

USER root

# Install system dependencies for building R packages
# Only including dependencies actually needed by packages in renv.lock
# Packages sorted alphabetically for easier maintenance and duplicate detection
# curl is included for health checks
RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    libcurl4-openssl-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# Install renv for package management
RUN R --quiet -e "install.packages('renv', repos = c(CRAN = 'https://cloud.r-project.org'))" && \
    R -e "cat('renv installed at:', find.package('renv'), '\n')"

# Set working directory
WORKDIR /srv/shiny-server

# Copy renv configuration files FIRST (for Docker layer caching)
# This layer only rebuilds when dependencies change
COPY renv.lock renv.lock
COPY .Rprofile .Rprofile
COPY renv/activate.R renv/activate.R
COPY renv/settings.json renv/settings.json

# Create cache directory and restore packages
# This is the heavy operation that gets cached
# Explicitly load renv from system library before activating project
# Using cache mount to persist downloads across builds
RUN --mount=type=cache,target=/opt/renv/cache \
    mkdir -p /opt/renv/cache && \
    Rscript -e "library(renv, lib.loc = '/usr/local/lib/R/site-library'); renv::restore()"

# Configure renv runtime environment (after restore to avoid bootstrap conflicts)
ENV RENV_CONFIG_SANDBOX_ENABLED=FALSE
ENV RENV_PATHS_LIBRARY=/usr/local/lib/R/site-library
ENV RENV_PATHS_CACHE=/opt/renv/cache

# Install TinyTeX for PDF generation (after renv restore)
RUN R --quiet -e "tinytex::install_tinytex()"

# Install LaTeX packages using R/tinytex (avoids PATH issues)
# Packages sorted alphabetically for easier maintenance
RUN R --quiet -e "tinytex::tlmgr_install(c('booktabs', 'float', 'threeparttable'))"

# ------------------------------------------------------------------------------
# Stage 2: Development - Includes testing and code quality tools
# ------------------------------------------------------------------------------
FROM base AS development

USER root

# Install code quality and testing tools
# These are development dependencies, not in renv.lock
# Packages sorted alphabetically for easier maintenance
RUN R --quiet -e "install.packages(c('covr', 'here', 'lintr', 'precommit', 'styler'), repos = 'https://cloud.r-project.org')"

# Create cache directory with proper permissions for shiny user
RUN mkdir -p /srv/shiny-server/app_cache && \
    chown -R shiny:shiny /srv/shiny-server/app_cache

# Copy application code INCLUDING tests
COPY --chown=shiny:shiny app.R app.R
COPY --chown=shiny:shiny analysis-report.Rmd analysis-report.Rmd
COPY --chown=shiny:shiny R/ R/
COPY --chown=shiny:shiny www/ www/
COPY --chown=shiny:shiny tests/ tests/

USER shiny

EXPOSE 3838

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]

# ------------------------------------------------------------------------------
# Stage 3: Production - Minimal runtime, no dev tools or tests
# ------------------------------------------------------------------------------
FROM base AS production

USER root

# Create cache directory with proper permissions for shiny user
RUN mkdir -p /srv/shiny-server/app_cache && \
    chown -R shiny:shiny /srv/shiny-server/app_cache

# Copy ONLY application code (no tests, no dev tools)
COPY --chown=shiny:shiny app.R app.R
COPY --chown=shiny:shiny analysis-report.Rmd analysis-report.Rmd
COPY --chown=shiny:shiny R/ R/
COPY --chown=shiny:shiny www/ www/

USER shiny

EXPOSE 3838

# Health check to ensure the Shiny app is responding
# Checks every 30s, timeout after 3s, waits 10s on startup, fails after 3 retries
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:3838/ || exit 1

CMD ["R", "-e", "shiny::runApp('/srv/shiny-server/app.R', host='0.0.0.0', port=3838)"]
