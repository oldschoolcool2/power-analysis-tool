# How to maintain Docker best practices

**Type:** How-To
**Audience:** Developers, DevOps
**Last Updated:** 2025-10-25

## Overview

This guide explains how to maintain the Docker best practices implemented in this project's Dockerfile. Following these practices ensures reproducible builds, optimal performance, security, and maintainability.

## Prerequisites

- Docker installed (version 20.10+)
- Basic understanding of Dockerfile syntax
- Access to the project repository

---

## Best Practices Implemented

Our Dockerfile follows all major Docker best practices:

1. **Multi-stage builds** - Separate dev/prod environments
2. **Layer caching optimization** - Dependencies copied before code
3. **Cache mounts** - Persistent package download cache
4. **Digest pinning** - Reproducible base images
5. **Alphabetical sorting** - Easier maintenance
6. **OCI-compliant metadata** - Standard LABEL annotations
7. **Health checks** - Production monitoring
8. **Non-root user** - Security best practice
9. **Minimal production image** - No dev tools or tests

---

## Regular Maintenance Tasks

### 1. Update base image digest

**Frequency:** Monthly or when security patches are released

**Steps:**

```bash
# 1. Pull the latest version of the base image
docker pull rocker/shiny:4.4.0

# 2. Extract the new digest
NEW_DIGEST=$(docker inspect rocker/shiny:4.4.0 --format='{{index .RepoDigests 0}}' | cut -d'@' -f2)
echo "New digest: $NEW_DIGEST"

# 3. Update Dockerfile
# Edit line 14: ARG BASE_IMAGE_DIGEST=sha256:newdigesthere

# 4. Update the date comment on line 12
# Example: (rocker/shiny:4.4.0 as of 2025-11-15)

# 5. Test the build
docker build --target base -t power-analysis-test:base .

# 6. If successful, rebuild all targets
docker-compose build
```

**Why?** Digest pinning guarantees reproducible builds but requires manual updates for security patches.

---

### 2. Add new system packages

**When:** Adding R packages that require system dependencies

**Steps:**

```bash
# 1. Identify required system packages
# Check R package documentation or build errors

# 2. Add to Dockerfile line 35-42 in ALPHABETICAL order
# Example: Adding 'libgit2-dev'

# Before:
RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    libcurl4-openssl-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# After:
RUN apt-get update && apt-get install -y \
    cmake \
    curl \
    libcurl4-openssl-dev \
    libfribidi-dev \
    libgit2-dev \          # <-- Added in alphabetical position
    libharfbuzz-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Rebuild and test
docker build --no-cache -t power-analysis-test .
```

**Important:** Always maintain alphabetical order to prevent duplicates and make diffs clearer.

---

### 3. Add new R development packages

**When:** Adding code quality or testing tools

**Steps:**

```bash
# 1. Add to Dockerfile line 88 in ALPHABETICAL order
# Example: Adding 'testthat'

# Before:
RUN R --quiet -e "install.packages(c('covr', 'here', 'lintr', 'precommit', 'styler'), repos = 'https://cloud.r-project.org')"

# After:
RUN R --quiet -e "install.packages(c('covr', 'here', 'lintr', 'precommit', 'styler', 'testthat'), repos = 'https://cloud.r-project.org')"

# 2. Test development build
docker-compose build development
```

---

### 4. Update R version

**When:** Upgrading to a new R version

**Steps:**

```bash
# 1. Update docker-compose.yml build args (lines 7, 27)
args:
  R_VERSION: "4.5.0"  # Update version

# 2. Pull new base image
docker pull rocker/shiny:4.5.0

# 3. Get new digest
NEW_DIGEST=$(docker inspect rocker/shiny:4.5.0 --format='{{index .RepoDigests 0}}' | cut -d'@' -f2)

# 4. Update Dockerfile:
# Line 10: ARG R_VERSION=4.5.0
# Line 14: ARG BASE_IMAGE_DIGEST=sha256:newdigest
# Line 12: Update date comment

# 5. Test all stages
docker build --target base -t test:base .
docker build --target development -t test:dev .
docker build --target production -t test:prod .

# 6. If all pass, update docker-compose.yml
docker-compose build
docker-compose up -d shiny
```

---

### 5. Verify LABEL metadata is current

**Frequency:** When releasing new versions

**Steps:**

```bash
# 1. Build the image
docker build -t power-analysis-tool:latest .

# 2. Inspect labels
docker inspect power-analysis-tool:latest | grep -A 15 Labels

# 3. Verify labels are accurate:
# - org.opencontainers.image.title
# - org.opencontainers.image.description
# - org.opencontainers.image.authors
# - org.opencontainers.image.documentation
# - maintainer

# 4. Update if needed in Dockerfile lines 26-31
```

---

## Performance Optimization

### Leverage cache mounts

Our Dockerfile uses cache mounts for renv packages (line 63):

```dockerfile
RUN --mount=type=cache,target=/opt/renv/cache \
    mkdir -p /opt/renv/cache && \
    Rscript -e "library(renv, lib.loc = '/usr/local/lib/R/site-library'); renv::restore()"
```

**Benefits:**
- Package downloads persist across builds
- Even when renv.lock changes, previously downloaded packages are reused
- Significantly faster rebuilds

**No maintenance required** - Docker handles cache automatically.

---

## Security Best Practices

### 1. Regular base image updates

Update base image digest monthly:

```bash
# Check for security advisories
docker scout cves rocker/shiny:4.4.0

# Update digest following "Update base image digest" steps above
```

### 2. Scan images for vulnerabilities

```bash
# Using Docker Scout (built-in)
docker scout cves power-analysis-tool:latest

# Using Trivy (if installed)
trivy image power-analysis-tool:latest

# Using Snyk (if installed)
snyk container test power-analysis-tool:latest
```

### 3. Verify non-root user

```bash
# Check that production runs as shiny user
docker run --rm power-analysis-tool:latest whoami
# Should output: shiny
```

---

## Troubleshooting

### Build cache issues

If builds are not using cache effectively:

```bash
# 1. Check layer order - dependencies should come before code
# See Dockerfile lines 54-57 (renv files copied first)

# 2. Verify .dockerignore excludes changing files
cat .dockerignore

# 3. Clear cache and rebuild
docker builder prune
docker build --no-cache -t power-analysis-tool:latest .
```

### Digest pin fails to resolve

If `docker build` fails with digest error:

```bash
# 1. Verify digest exists
docker pull rocker/shiny:4.4.0@sha256:yourdigest

# 2. If fails, get current digest
docker pull rocker/shiny:4.4.0
docker inspect rocker/shiny:4.4.0 | grep -A 1 RepoDigests

# 3. Update Dockerfile line 14 with current digest
```

### Health check failing

If production container is marked unhealthy:

```bash
# 1. Check health check logs
docker inspect power-analysis-tool | grep -A 20 Health

# 2. Test health check manually
docker exec power-analysis-tool curl -f http://localhost:3838/

# 3. Check application logs
docker logs power-analysis-tool

# 4. Verify app is running
docker exec power-analysis-tool ps aux | grep R
```

---

## Validation Checklist

Before committing Dockerfile changes:

- [ ] All packages are sorted alphabetically
- [ ] apt cache is cleaned (`rm -rf /var/lib/apt/lists/*`)
- [ ] Base image digest is current (less than 30 days old)
- [ ] LABEL metadata is accurate
- [ ] Build succeeds for all stages (base, development, production)
- [ ] Health check passes in production
- [ ] .dockerignore is up to date
- [ ] Comments explain non-obvious changes
- [ ] Image builds without warnings

**Test all stages:**
```bash
docker build --target base -t test:base . && \
docker build --target development -t test:dev . && \
docker build --target production -t test:prod . && \
echo "All stages built successfully!"
```

---

## Quick Reference

### Key Dockerfile Sections

| Lines | Purpose | Maintenance |
|-------|---------|-------------|
| 10-14 | Version management & digest pinning | Update monthly |
| 22-23 | Re-declare ARGs for LABELs | No change needed |
| 26-31 | OCI metadata labels | Update on releases |
| 35-42 | System packages (sorted) | Add alphabetically |
| 63-65 | Cache mount for renv | No change needed |
| 77 | LaTeX packages (sorted) | Add alphabetically |
| 88 | Dev R packages (sorted) | Add alphabetically |
| 117-118 | Health check | Adjust if app changes |

### Common Commands

```bash
# Update base image digest
docker pull rocker/shiny:4.4.0 && \
docker inspect rocker/shiny:4.4.0 --format='{{index .RepoDigests 0}}'

# Build specific stage
docker build --target production -t power-analysis-tool:prod .

# Build without cache
docker build --no-cache -t power-analysis-tool:latest .

# Inspect image metadata
docker inspect power-analysis-tool:latest | grep -A 15 Labels

# Check health status
docker ps  # Look for (healthy) in STATUS column

# View build cache
docker system df -v | grep -A 10 "Build Cache"

# Prune build cache
docker builder prune
```

---

## Related Documentation

- [Docker best practices (official)](https://docs.docker.com/build/building/best-practices/)
- [Multi-stage builds guide](https://docs.docker.com/build/building/multi-stage/)
- [.dockerignore reference](003-reference/002-dockerignore-configuration.md)
- [CI/CD integration](007-docker-cicd-validation.md)

---

**Last Updated:** 2025-10-25
**Maintained By:** Development Team
