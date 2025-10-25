# How to use Docker security scanning with Trivy

**Type:** How-To Guide
**Audience:** Developers, DevOps Engineers, Security Team
**Last Updated:** 2025-10-25

## Overview

This guide explains how to use Trivy security scanning in the Power Analysis Tool project. Trivy automatically scans Docker images, code repositories, and configuration files for vulnerabilities, secrets, and misconfigurations.

## Prerequisites

- GitHub repository with Actions enabled
- Docker installed locally (for local testing)
- Basic understanding of CI/CD workflows

## Security Scanning Workflows

The project includes comprehensive security scanning through GitHub Actions:

### 1. Automated Security Scanning Workflow

**File:** `.github/workflows/security-scanning.yml`

**Triggers:**
- Pull requests to master/main
- Pushes to master/main
- Weekly schedule (Mondays at 9:00 AM UTC)
- Manual workflow dispatch

**Scans performed:**
- Development Docker image scan
- Production Docker image scan
- Repository filesystem scan (dependencies, secrets)
- Configuration scan (Dockerfile, docker-compose.yml)

### 2. Quick Security Check in Quality Workflow

**File:** `.github/workflows/quality-checks.yml`

A lightweight security check runs as part of the Docker build job to catch obvious issues early.

## Viewing Security Results

### GitHub Security Tab

1. Navigate to your repository on GitHub
2. Click on the "Security" tab
3. Click "Code scanning alerts"
4. Filter by tool: "Trivy"
5. Review findings by severity (Critical, High, Medium, Low)

### Workflow Logs

1. Go to "Actions" tab
2. Select "Docker Security Scanning" workflow
3. Click on a specific run
4. View detailed scan results in job logs

### SARIF Reports

Security findings are uploaded as SARIF (Static Analysis Results Interchange Format) reports, which integrate with GitHub's security features.

## Understanding Scan Results

### Vulnerability Scanning

Trivy scans for:
- OS package vulnerabilities (Alpine, Debian, Ubuntu, etc.)
- Language-specific package vulnerabilities (R packages via renv.lock)
- Application dependencies

**Example output:**
```
alpine:3.19 (alpine 3.19.0)
==========================
Total: 2 (CRITICAL: 1, HIGH: 1)

┌─────────────┬────────────────┬──────────┬───────────────────┬───────────────┬───────────────────────────────────┐
│   Library   │ Vulnerability  │ Severity │ Installed Version │ Fixed Version │            Title                  │
├─────────────┼────────────────┼──────────┼───────────────────┼───────────────┼───────────────────────────────────┤
│ curl        │ CVE-2023-xxxxx │ CRITICAL │ 8.1.0-r0          │ 8.1.1-r0      │ curl: arbitrary code execution    │
└─────────────┴────────────────┴──────────┴───────────────────┴───────────────┴───────────────────────────────────┘
```

### Secret Scanning

Detects accidentally committed secrets:
- API keys
- Private keys
- Tokens
- Passwords
- AWS credentials

**Example finding:**
```
Dockerfile (secrets)
====================
Total: 1 (SECRET: 1)

┌──────────┬───────────────┬──────────┬──────┬──────────────────┐
│ Category │    RuleID     │ Severity │ Line │     Match        │
├──────────┼───────────────┼──────────┼──────┼──────────────────┤
│ Secret   │ aws-secret-   │ CRITICAL │  45  │ AWS Secret Key   │
│          │ access-key    │          │      │ found            │
└──────────┴───────────────┴──────────┴──────┴──────────────────┘
```

### Misconfiguration Scanning

Checks for Docker and IaC best practices:
- Running containers as root
- Using latest tags
- Missing health checks
- Exposed sensitive ports

## Build Policies

### Critical Vulnerabilities

**Policy:** Build FAILS on CRITICAL vulnerabilities

**Rationale:** Critical vulnerabilities pose immediate security risks and must be addressed before deployment.

**Action:** Fix or acknowledge before merging.

### High/Medium Vulnerabilities

**Policy:** Build PASSES but reports findings

**Rationale:** These should be addressed but may not require immediate blocking.

**Action:** Review and create follow-up issues.

### Unfixed Vulnerabilities

**Policy:** Reported but don't fail build

**Configuration:** `ignore-unfixed: false`

**Rationale:** Awareness of unfixed vulnerabilities helps with risk assessment, even when patches aren't yet available.

## How to Fix Common Issues

### Updating Base Image

If vulnerabilities are in the base image (rocker/shiny):

```dockerfile
# Update the base image version in Dockerfile
ARG R_VERSION=4.4.1  # Update to newer version
ARG BASE_IMAGE_DIGEST=sha256:newdigest...
```

**Steps:**
1. Check for newer rocker/shiny releases
2. Pull new image: `docker pull rocker/shiny:4.4.1`
3. Get digest: `docker inspect rocker/shiny:4.4.1 | grep RepoDigests`
4. Update Dockerfile ARG values
5. Test locally
6. Commit and push

### Updating System Packages

If vulnerabilities are in apt packages:

```dockerfile
RUN apt-get update && apt-get upgrade -y && apt-get install -y \
    cmake \
    curl \
    # ... other packages
```

### Updating R Dependencies

If vulnerabilities are in R packages:

```bash
# Update renv.lock locally
Rscript -e "renv::update()"

# Test the application
docker-compose up --build

# Commit updated renv.lock
git add renv.lock
git commit -m "fix(deps): update R packages to address security vulnerabilities"
```

## Ignoring False Positives

If Trivy reports a false positive or accepted risk:

### 1. Add to .trivyignore file

```bash
# .trivyignore
CVE-2023-12345  # False positive - package not used in production runtime
CVE-2023-67890  # Accepted risk - workaround in place, waiting for upstream fix
```

### 2. Document the decision

Create an entry in your security documentation explaining:
- Why the vulnerability is being ignored
- What assessment was performed
- When it should be reviewed again

### 3. Commit the change

```bash
git add .trivyignore
git commit -m "security: ignore CVE-2023-12345 (false positive)"
```

**IMPORTANT:** Every ignored CVE must have a documented justification.

## Running Scans Locally

### Scan Docker Image

```bash
# Build the image
docker build -t power-analysis-tool:local .

# Scan with Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest image power-analysis-tool:local
```

### Scan Repository

```bash
# Scan current directory
docker run --rm -v $(pwd):/src aquasec/trivy:latest fs /src
```

### Scan Dockerfile

```bash
# Scan for misconfigurations
docker run --rm -v $(pwd):/src aquasec/trivy:latest config /src/Dockerfile
```

### Install Trivy Locally

```bash
# macOS
brew install aquasecurity/trivy/trivy

# Linux
wget https://github.com/aquasecurity/trivy/releases/download/v0.48.0/trivy_0.48.0_Linux-64bit.tar.gz
tar zxvf trivy_0.48.0_Linux-64bit.tar.gz
sudo mv trivy /usr/local/bin/

# Then scan directly
trivy image power-analysis-tool:local
trivy fs .
trivy config Dockerfile
```

## Advanced Configuration

### Custom Severity Levels

Edit `.github/workflows/security-scanning.yml`:

```yaml
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@0.28.0
  with:
    severity: 'CRITICAL,HIGH'  # Only scan for critical and high
```

### Skip Specific Checks

```yaml
- name: Run Trivy scanner
  uses: aquasecurity/trivy-action@0.28.0
  with:
    skip-dirs: 'tests/,docs/'  # Skip test and doc directories
```

### Custom Policy File

Create `.trivy/policy.rego`:

```rego
package trivy

deny[msg] {
    input.PkgName == "curl"
    msg := "curl package must be updated"
}
```

Apply in workflow:

```yaml
- name: Run Trivy scanner with policy
  uses: aquasecurity/trivy-action@0.28.0
  with:
    policy: '.trivy/policy.rego'
```

## Troubleshooting

### Rate Limiting

**Issue:** GitHub API rate limit exceeded

**Solution:**
```yaml
env:
  GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

### Cache Issues

**Issue:** Outdated vulnerability database

**Solution:** Trivy automatically updates its database. To force refresh in local scans:
```bash
trivy image --reset power-analysis-tool:local
```

### Permission Errors

**Issue:** Cannot upload SARIF to Security tab

**Solution:** Ensure workflow has correct permissions:
```yaml
permissions:
  contents: read
  security-events: write
```

## Weekly Security Reviews

The workflow runs automatically every Monday at 9:00 AM UTC to catch:
- New vulnerabilities in existing dependencies
- Updated CVE databases
- New security advisories

**Recommended action:** Review weekly scan results and triage findings.

## Integration with Pull Requests

Security scans run automatically on PRs:

1. Developer creates PR
2. Security scanning workflow triggers
3. Results posted to PR checks
4. Critical vulnerabilities block merge
5. Developer fixes issues
6. Re-scan passes
7. PR can be merged

## Best Practices

1. **Review scan results weekly** - Even if builds are passing
2. **Document all ignored vulnerabilities** - In .trivyignore with justification
3. **Keep base images updated** - Update rocker/shiny regularly
4. **Pin versions** - Use digest pinning for reproducibility
5. **Test locally before pushing** - Run Trivy locally to catch issues early
6. **Separate dev and prod concerns** - Different thresholds for dev vs production
7. **Monitor security advisories** - Subscribe to R and Docker security feeds

## Related Documentation

- [Dockerfile best practices](../004-explanation/001-docker-multistage-build-explanation.md)
- [CI/CD pipeline overview](../003-reference/002-ci-cd-pipeline-reference.md)
- [Trivy official documentation](https://aquasecurity.github.io/trivy/)

## References

- [Trivy GitHub Actions](https://github.com/aquasecurity/trivy-action)
- [SARIF format specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/sarif-v2.1.0.html)
- [GitHub Code Scanning](https://docs.github.com/en/code-security/code-scanning)
- [Docker Security Best Practices](https://docs.docker.com/develop/security-best-practices/)
