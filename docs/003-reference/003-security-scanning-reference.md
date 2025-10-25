# Security Scanning Reference

**Type:** Reference
**Audience:** Developers, Security Team, DevOps
**Last Updated:** 2025-10-25

## Overview

Quick reference for Docker security scanning with Trivy in the Power Analysis Tool project.

## Workflow Files

| File | Purpose | Trigger |
|------|---------|---------|
| `.github/workflows/security-scanning.yml` | Comprehensive security scanning | PR, push, weekly schedule, manual |
| `.github/workflows/quality-checks.yml` | Quick security check in build pipeline | PR, push |
| `.trivyignore` | Vulnerability exceptions and false positives | N/A |

## Scan Types

### Image Scanning

Scans Docker container images for vulnerabilities in:
- Base OS packages (Alpine Linux)
- Language dependencies (R packages)
- Application libraries

**Command:**
```bash
trivy image <image-name>
```

### Filesystem Scanning

Scans repository files for:
- Dependency vulnerabilities
- Hardcoded secrets
- Configuration issues

**Command:**
```bash
trivy fs <path>
```

### Configuration Scanning

Scans infrastructure-as-code files:
- Dockerfile misconfigurations
- Docker Compose issues
- Security best practice violations

**Command:**
```bash
trivy config <path>
```

## Scanners

| Scanner | Purpose | Default |
|---------|---------|---------|
| `vuln` | Vulnerability detection | Enabled |
| `secret` | Secret detection | Enabled |
| `misconfig` | Misconfiguration detection | Enabled |
| `license` | License compliance | Disabled |

## Severity Levels

| Level | Description | Build Impact |
|-------|-------------|--------------|
| `CRITICAL` | Immediate security risk, active exploits exist | **FAILS BUILD** |
| `HIGH` | Serious vulnerability, should be fixed soon | Reported only |
| `MEDIUM` | Moderate risk, fix when possible | Reported only |
| `LOW` | Minor issue, low priority | Not reported by default |

## Exit Codes

| Exit Code | Meaning | Usage |
|-----------|---------|-------|
| `0` | Report only, don't fail | Used for informational scans |
| `1` | Fail build on findings | Used for CRITICAL vulnerabilities |

## Workflow Jobs

### security-scanning.yml

#### trivy-scan
Scans Docker images (development and production targets)

**Outputs:**
- SARIF reports uploaded to GitHub Security tab
- Table output in workflow logs
- Build failure on CRITICAL vulnerabilities

#### trivy-repo-scan
Scans repository filesystem

**Outputs:**
- SARIF report for repository scan
- Detects secrets and vulnerable dependencies
- Build failure on CRITICAL issues

#### trivy-config-scan
Scans configuration files

**Outputs:**
- SARIF report for configuration scan
- Detects Docker and IaC misconfigurations
- Informational only (doesn't fail build)

### quality-checks.yml

#### docker-build
Quick security scan as part of build verification

**Outputs:**
- Table output for CRITICAL and HIGH findings
- Summary message linking to full scan
- Non-blocking (informational)

## Configuration Options

### Common Flags

```yaml
image-ref: string           # Docker image to scan
scan-type: string           # Type: fs, config, image
format: string              # Output format: table, json, sarif
severity: string            # Comma-separated: CRITICAL,HIGH,MEDIUM,LOW
scanners: string            # Comma-separated: vuln,secret,misconfig
ignore-unfixed: boolean     # Ignore vulnerabilities without fixes
exit-code: integer          # 0 = report only, 1 = fail on findings
```

### Example Configuration

```yaml
- name: Scan with custom settings
  uses: aquasecurity/trivy-action@0.28.0
  with:
    image-ref: 'myimage:tag'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    scanners: 'vuln,secret'
    ignore-unfixed: false
    exit-code: 1
```

## File Locations

```
.
├── .github/
│   └── workflows/
│       ├── security-scanning.yml      # Main security workflow
│       └── quality-checks.yml         # Build pipeline with security
├── .trivyignore                       # Ignored vulnerabilities
└── docs/
    ├── 002-how-to-guides/
    │   └── 006-security-scanning-with-trivy.md
    └── 003-reference/
        └── 003-security-scanning-reference.md  # This file
```

## Environment Variables

| Variable | Purpose | Example |
|----------|---------|---------|
| `GITHUB_TOKEN` | Authenticate to GitHub API | Auto-provided in Actions |
| `TRIVY_NO_PROGRESS` | Suppress progress bar | `true` |
| `TRIVY_CACHE_DIR` | Cache directory location | `.trivycache/` |

## Output Formats

### Table (Human-Readable)

```bash
trivy image -f table myimage:tag
```

Example output:
```
myimage:tag (alpine 3.19.0)
===========================
Total: 5 (CRITICAL: 2, HIGH: 3)

┌─────────┬────────────────┬──────────┬──────────┬──────────┐
│ Library │ Vulnerability  │ Severity │ Installed│ Fixed    │
├─────────┼────────────────┼──────────┼──────────┼──────────┤
│ curl    │ CVE-2023-12345 │ CRITICAL │ 8.1.0    │ 8.1.1    │
└─────────┴────────────────┴──────────┴──────────┴──────────┘
```

### SARIF (GitHub Security Tab)

```bash
trivy image -f sarif -o results.sarif myimage:tag
```

Uploaded automatically by workflow to Security → Code scanning alerts

### JSON (Machine-Readable)

```bash
trivy image -f json myimage:tag
```

Useful for programmatic processing and integration

## Permissions Required

GitHub Actions workflows require specific permissions:

```yaml
permissions:
  contents: read           # Read repository contents
  security-events: write   # Upload SARIF to Security tab
  actions: read            # Read workflow information
```

## Cache Configuration

Trivy caches vulnerability databases for performance:

```yaml
cache:
  paths:
    - .trivycache/
```

Cache is automatically managed in GitHub Actions using `type=gha`

## Ignoring Vulnerabilities

### .trivyignore Syntax

```bash
# Ignore specific CVE
CVE-2023-12345

# Ignore with expiration date
CVE-2023-67890 exp:2025-12-31

# Platform-specific ignore
CVE-2023-11111 platform=linux/amd64

# Package-specific ignore
CVE-2023-22222 pkg=curl
```

### Best Practices

1. **Always document why** - Add comment explaining the reason
2. **Set expiration dates** - Review ignored CVEs periodically
3. **Be specific** - Use platform/package filters when possible
4. **Track in issues** - Create GitHub issue for each ignored CVE

## Scan Schedule

| Event | Frequency | Purpose |
|-------|-----------|---------|
| Pull Request | On every PR | Prevent vulnerable code from merging |
| Push to main | On every push | Verify main branch security |
| Weekly Scan | Monday 9 AM UTC | Catch new vulnerabilities |
| Manual | On-demand | Ad-hoc security verification |

## GitHub Security Integration

### Code Scanning Alerts

Navigate to: **Security → Code scanning alerts**

Filters:
- Tool: Trivy
- Category: trivy-dev-image, trivy-prod-image, trivy-repository, trivy-config
- Severity: Critical, High, Medium, Low
- State: Open, Dismissed

### Dismissing Alerts

1. Click on alert
2. Click "Dismiss alert" dropdown
3. Select reason:
   - False positive
   - Won't fix
   - Used in tests
4. Add comment explaining decision
5. Optionally create issue for tracking

## Common Vulnerability Sources

### Base Image (rocker/shiny)

- Update ARG R_VERSION in Dockerfile
- Update ARG BASE_IMAGE_DIGEST
- Test compatibility with new version

### System Packages (apt)

- Review and update package versions
- Consider removing unused packages
- Use `apt-get upgrade` for security patches

### R Dependencies (renv.lock)

- Update via `renv::update()`
- Test application thoroughly
- Commit updated renv.lock

## Troubleshooting

### Issue: Rate Limiting

**Error:** `API rate limit exceeded`

**Solution:** Ensure GITHUB_TOKEN is configured (auto-provided in Actions)

### Issue: SARIF Upload Failed

**Error:** `Resource not accessible by integration`

**Solution:** Check workflow permissions include `security-events: write`

### Issue: Cache Not Working

**Error:** Scans are slow or re-downloading database

**Solution:** Verify cache configuration uses `type=gha` for GitHub Actions

### Issue: False Positives

**Error:** Vulnerability reported but not applicable

**Solution:** Add to `.trivyignore` with clear justification comment

## Version Information

| Component | Version | Notes |
|-----------|---------|-------|
| Trivy Action | 0.28.0 | aquasecurity/trivy-action |
| GitHub Action | v4 | actions/checkout |
| CodeQL Action | v3 | github/codeql-action/upload-sarif |
| Docker Buildx | v3 | docker/setup-buildx-action |
| Docker Build/Push | v6 | docker/build-push-action |

## Related Resources

- [How-To Guide: Security Scanning](../002-how-to-guides/006-security-scanning-with-trivy.md)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [GitHub Security Features](https://docs.github.com/en/code-security)
- [SARIF Specification](https://docs.oasis-open.org/sarif/sarif/v2.1.0/)

## Quick Commands

### Local Scanning

```bash
# Scan Docker image
trivy image power-analysis-tool:local

# Scan repository
trivy fs .

# Scan Dockerfile
trivy config Dockerfile

# Scan with specific severity
trivy image --severity CRITICAL,HIGH myimage:tag

# Scan and output JSON
trivy image -f json -o results.json myimage:tag

# Scan and ignore unfixed
trivy image --ignore-unfixed myimage:tag
```

### GitHub CLI

```bash
# View security alerts
gh api /repos/OWNER/REPO/code-scanning/alerts

# Dismiss alert
gh api /repos/OWNER/REPO/code-scanning/alerts/ALERT_ID \
  -X PATCH \
  -f state=dismissed \
  -f dismissed_reason=false_positive
```

## Support and Maintenance

- **Weekly Review:** Check Monday automated scan results
- **Quarterly Audit:** Review all ignored vulnerabilities
- **Version Updates:** Keep Trivy action and base images current
- **Documentation:** Update this reference when configuration changes
