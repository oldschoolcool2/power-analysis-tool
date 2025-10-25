# Docker CI/CD validation reference

**Type:** Reference
**Audience:** DevOps, CI/CD Engineers
**Last Updated:** 2025-10-25

## Overview

This document provides reference implementations for validating Docker best practices in CI/CD pipelines. These examples can be integrated into GitHub Actions, GitLab CI, or other CI/CD platforms.

---

## GitHub Actions Workflow

### Complete Workflow Example

Create `.github/workflows/docker-validation.yml`:

```yaml
name: Docker Build and Validation

on:
  push:
    branches: [ master, develop ]
    paths:
      - 'Dockerfile'
      - 'docker-compose.yml'
      - '.dockerignore'
      - 'renv.lock'
      - '.github/workflows/docker-validation.yml'
  pull_request:
    branches: [ master ]
    paths:
      - 'Dockerfile'
      - 'docker-compose.yml'
      - '.dockerignore'
      - 'renv.lock'

jobs:
  lint-dockerfile:
    name: Lint Dockerfile
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Lint Dockerfile with hadolint
        uses: hadolint/hadolint-action@v3.1.0
        with:
          dockerfile: Dockerfile
          failure-threshold: warning
          ignore: DL3008,DL3015  # Ignore pinning apt versions (we clean cache)

  build-and-test:
    name: Build and Test Docker Images
    runs-on: ubuntu-latest
    needs: lint-dockerfile
    strategy:
      matrix:
        target: [base, development, production]
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build ${{ matrix.target }} stage
        uses: docker/build-push-action@v5
        with:
          context: .
          target: ${{ matrix.target }}
          tags: power-analysis-tool:${{ matrix.target }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          load: true

      - name: Test production image health
        if: matrix.target == 'production'
        run: |
          # Start container
          docker run -d --name test-app \
            -p 3838:3838 \
            power-analysis-tool:production

          # Wait for health check to pass (max 60 seconds)
          timeout=60
          while [ $timeout -gt 0 ]; do
            health=$(docker inspect --format='{{.State.Health.Status}}' test-app)
            if [ "$health" = "healthy" ]; then
              echo "✓ Health check passed"
              exit 0
            fi
            echo "Waiting for health check... ($timeout seconds remaining)"
            sleep 5
            timeout=$((timeout-5))
          done

          echo "✗ Health check failed"
          docker logs test-app
          exit 1

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: build-and-test
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build production image
        uses: docker/build-push-action@v5
        with:
          context: .
          target: production
          tags: power-analysis-tool:scan
          load: true

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: power-analysis-tool:scan
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH'

      - name: Upload Trivy results to GitHub Security
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Run Trivy vulnerability scanner (table output)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: power-analysis-tool:scan
          format: 'table'
          severity: 'CRITICAL,HIGH'
          exit-code: '1'  # Fail on critical/high vulnerabilities

  validate-best-practices:
    name: Validate Docker Best Practices
    runs-on: ubuntu-latest
    needs: lint-dockerfile
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Check packages are alphabetically sorted
        run: |
          # Extract apt-get packages
          apt_packages=$(grep -A 20 'apt-get install' Dockerfile | grep -E '^\s+[a-z]' | tr -d '\\' | sed 's/^[[:space:]]*//')

          # Check if sorted
          sorted_packages=$(echo "$apt_packages" | sort)

          if [ "$apt_packages" != "$sorted_packages" ]; then
            echo "✗ apt-get packages are not alphabetically sorted"
            echo "Expected order:"
            echo "$sorted_packages"
            exit 1
          fi
          echo "✓ apt-get packages are alphabetically sorted"

      - name: Check base image uses digest pinning
        run: |
          if ! grep -q '@sha256:' Dockerfile; then
            echo "✗ Base image does not use digest pinning"
            exit 1
          fi
          echo "✓ Base image uses digest pinning"

      - name: Check LABEL metadata exists
        run: |
          required_labels=(
            "org.opencontainers.image.title"
            "org.opencontainers.image.description"
            "org.opencontainers.image.authors"
          )

          for label in "${required_labels[@]}"; do
            if ! grep -q "LABEL $label" Dockerfile; then
              echo "✗ Missing required LABEL: $label"
              exit 1
            fi
          done
          echo "✓ All required LABELs present"

      - name: Check cache mount is used
        run: |
          if ! grep -q 'RUN --mount=type=cache' Dockerfile; then
            echo "✗ No cache mounts found (performance optimization missing)"
            exit 1
          fi
          echo "✓ Cache mounts are used"

      - name: Check health check exists in production
        run: |
          # Extract production stage and check for HEALTHCHECK
          awk '/FROM.*AS production/,/^FROM/' Dockerfile | grep -q 'HEALTHCHECK'
          if [ $? -ne 0 ]; then
            echo "✗ Production stage missing HEALTHCHECK"
            exit 1
          fi
          echo "✓ Production stage has HEALTHCHECK"

      - name: Check non-root user
        run: |
          # Check that we switch to non-root user
          if ! grep -q 'USER shiny' Dockerfile; then
            echo "✗ Container runs as root (security issue)"
            exit 1
          fi
          echo "✓ Container runs as non-root user"

      - name: Check apt cache is cleaned
        run: |
          if ! grep -q 'rm -rf /var/lib/apt/lists/\*' Dockerfile; then
            echo "✗ apt cache is not cleaned (image size issue)"
            exit 1
          fi
          echo "✓ apt cache is cleaned"

  image-size-check:
    name: Check Image Size
    runs-on: ubuntu-latest
    needs: build-and-test
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Build production image
        uses: docker/build-push-action@v5
        with:
          context: .
          target: production
          tags: power-analysis-tool:size-check
          load: true

      - name: Check image size
        run: |
          size_mb=$(docker images power-analysis-tool:size-check --format "{{.Size}}" | sed 's/GB/*1024/;s/MB//' | bc)
          max_size_mb=2000  # 2GB limit for production image

          if (( $(echo "$size_mb > $max_size_mb" | bc -l) )); then
            echo "✗ Image size ($size_mb MB) exceeds limit ($max_size_mb MB)"
            exit 1
          fi
          echo "✓ Image size ($size_mb MB) is within limit ($max_size_mb MB)"

      - name: Compare dev vs prod image sizes
        run: |
          # Build dev image
          docker build --target development -t power-analysis-tool:dev .

          dev_size=$(docker images power-analysis-tool:dev --format "{{.Size}}")
          prod_size=$(docker images power-analysis-tool:size-check --format "{{.Size}}")

          echo "Development image: $dev_size"
          echo "Production image: $prod_size"
          echo "✓ Multi-stage build working correctly"
```

---

## GitLab CI Pipeline

Create `.gitlab-ci.yml`:

```yaml
stages:
  - lint
  - build
  - test
  - security

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

lint:dockerfile:
  stage: lint
  image: hadolint/hadolint:latest-alpine
  script:
    - hadolint Dockerfile --ignore DL3008 --ignore DL3015
  only:
    changes:
      - Dockerfile
      - docker-compose.yml
      - .dockerignore

build:base:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build --target base -t $CI_REGISTRY_IMAGE:base-$CI_COMMIT_SHA .
  only:
    changes:
      - Dockerfile
      - renv.lock
      - .Rprofile

build:production:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build --target production -t $CI_REGISTRY_IMAGE:prod-$CI_COMMIT_SHA .
    - docker tag $CI_REGISTRY_IMAGE:prod-$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
  artifacts:
    reports:
      dotenv: build.env

test:health:
  stage: test
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker run -d --name test-app -p 3838:3838 $CI_REGISTRY_IMAGE:prod-$CI_COMMIT_SHA
    - |
      timeout=60
      while [ $timeout -gt 0 ]; do
        health=$(docker inspect --format='{{.State.Health.Status}}' test-app)
        if [ "$health" = "healthy" ]; then
          echo "Health check passed"
          exit 0
        fi
        sleep 5
        timeout=$((timeout-5))
      done
      echo "Health check failed"
      docker logs test-app
      exit 1
  dependencies:
    - build:production

security:scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --severity CRITICAL,HIGH --exit-code 1 $CI_REGISTRY_IMAGE:prod-$CI_COMMIT_SHA
  dependencies:
    - build:production
  allow_failure: true
```

---

## Local Validation Script

Create `scripts/validate-docker.sh`:

```bash
#!/bin/bash
set -e

echo "=== Docker Best Practices Validation ==="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    exit 1
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo "1. Checking Dockerfile exists..."
[ -f Dockerfile ] || check_fail "Dockerfile not found"
check_pass "Dockerfile found"

echo ""
echo "2. Linting Dockerfile with hadolint..."
if command -v hadolint &> /dev/null; then
    hadolint Dockerfile --ignore DL3008 --ignore DL3015 || check_fail "hadolint found issues"
    check_pass "Dockerfile passes hadolint"
else
    check_warn "hadolint not installed, skipping"
fi

echo ""
echo "3. Checking apt-get packages are alphabetically sorted..."
apt_packages=$(grep -A 20 'apt-get install' Dockerfile | grep -E '^\s+[a-z]' | tr -d '\\' | sed 's/^[[:space:]]*//')
sorted_packages=$(echo "$apt_packages" | sort)
if [ "$apt_packages" = "$sorted_packages" ]; then
    check_pass "apt-get packages are sorted"
else
    check_fail "apt-get packages are not sorted alphabetically"
fi

echo ""
echo "4. Checking base image uses digest pinning..."
if grep -q '@sha256:' Dockerfile; then
    check_pass "Base image uses digest pinning"
else
    check_fail "Base image missing digest pinning"
fi

echo ""
echo "5. Checking LABEL metadata..."
required_labels=("org.opencontainers.image.title" "org.opencontainers.image.description")
for label in "${required_labels[@]}"; do
    if grep -q "LABEL $label" Dockerfile; then
        check_pass "Found LABEL: $label"
    else
        check_fail "Missing LABEL: $label"
    fi
done

echo ""
echo "6. Checking cache mounts are used..."
if grep -q 'RUN --mount=type=cache' Dockerfile; then
    check_pass "Cache mounts are used"
else
    check_warn "No cache mounts found (performance optimization missing)"
fi

echo ""
echo "7. Checking health check in production..."
if awk '/FROM.*AS production/,/^FROM/' Dockerfile | grep -q 'HEALTHCHECK'; then
    check_pass "Production stage has HEALTHCHECK"
else
    check_fail "Production stage missing HEALTHCHECK"
fi

echo ""
echo "8. Checking non-root user..."
if grep -q 'USER shiny' Dockerfile; then
    check_pass "Container runs as non-root user"
else
    check_fail "Container runs as root"
fi

echo ""
echo "9. Checking apt cache cleanup..."
if grep -q 'rm -rf /var/lib/apt/lists/\*' Dockerfile; then
    check_pass "apt cache is cleaned"
else
    check_fail "apt cache is not cleaned"
fi

echo ""
echo "10. Building all stages..."
docker build --target base -t power-analysis-test:base . > /dev/null || check_fail "Base stage build failed"
check_pass "Base stage built successfully"

docker build --target development -t power-analysis-test:dev . > /dev/null || check_fail "Development stage build failed"
check_pass "Development stage built successfully"

docker build --target production -t power-analysis-test:prod . > /dev/null || check_fail "Production stage build failed"
check_pass "Production stage built successfully"

echo ""
echo "11. Testing production health check..."
docker run -d --name test-health power-analysis-test:prod > /dev/null
sleep 15  # Wait for startup

health=$(docker inspect --format='{{.State.Health.Status}}' test-health 2>/dev/null || echo "none")
docker rm -f test-health > /dev/null 2>&1

if [ "$health" = "healthy" ]; then
    check_pass "Health check passed"
elif [ "$health" = "none" ]; then
    check_warn "Health check not configured or not yet run"
else
    check_fail "Health check failed (status: $health)"
fi

echo ""
echo "12. Checking image sizes..."
dev_size=$(docker images power-analysis-test:dev --format "{{.Size}}")
prod_size=$(docker images power-analysis-test:prod --format "{{.Size}}")
echo "   Development: $dev_size"
echo "   Production:  $prod_size"
check_pass "Image sizes checked"

echo ""
echo -e "${GREEN}=== All validations passed! ===${NC}"
```

Make it executable:

```bash
chmod +x scripts/validate-docker.sh
```

Run it:

```bash
./scripts/validate-docker.sh
```

---

## Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

# Check if Dockerfile was modified
if git diff --cached --name-only | grep -q "Dockerfile"; then
    echo "Dockerfile modified, running validation..."

    # Check packages are sorted
    if ! grep -A 20 'apt-get install' Dockerfile | grep -E '^\s+[a-z]' | sort -c 2>/dev/null; then
        echo "ERROR: apt-get packages are not alphabetically sorted"
        exit 1
    fi

    # Run hadolint if available
    if command -v hadolint &> /dev/null; then
        hadolint Dockerfile --ignore DL3008 --ignore DL3015 || exit 1
    fi

    echo "Dockerfile validation passed"
fi
```

---

## Makefile Integration

Add to `Makefile`:

```makefile
.PHONY: docker-validate docker-build docker-test docker-security

# Validate Dockerfile best practices
docker-validate:
	@echo "Validating Dockerfile..."
	@hadolint Dockerfile --ignore DL3008 --ignore DL3015
	@echo "Checking package sorting..."
	@grep -A 20 'apt-get install' Dockerfile | grep -E '^\s+[a-z]' | tr -d '\\' | sort -c
	@echo "✓ Validation passed"

# Build all stages
docker-build:
	@echo "Building all Docker stages..."
	docker build --target base -t power-analysis-tool:base .
	docker build --target development -t power-analysis-tool:dev .
	docker build --target production -t power-analysis-tool:prod .
	@echo "✓ All stages built"

# Test production image
docker-test:
	@echo "Testing production image..."
	docker run -d --name test-app -p 3838:3838 power-analysis-tool:prod
	@sleep 15
	@docker inspect --format='{{.State.Health.Status}}' test-app | grep -q healthy || \
		(docker logs test-app && docker rm -f test-app && exit 1)
	docker rm -f test-app
	@echo "✓ Tests passed"

# Security scan
docker-security:
	@echo "Running security scan..."
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		aquasec/trivy:latest image --severity HIGH,CRITICAL power-analysis-tool:prod
	@echo "✓ Security scan complete"

# Full validation pipeline
docker-ci: docker-validate docker-build docker-test docker-security
	@echo "✓ Full CI validation passed"
```

Usage:

```bash
make docker-validate  # Quick validation
make docker-build     # Build all stages
make docker-test      # Test production
make docker-security  # Security scan
make docker-ci        # Full pipeline
```

---

## Continuous Monitoring

### Docker Scout Integration

Enable Docker Scout in CI/CD:

```yaml
- name: Analyze image with Docker Scout
  uses: docker/scout-action@v1
  with:
    command: cves
    image: power-analysis-tool:production
    only-severities: critical,high
    exit-code: true
```

### Automated Digest Updates

Create `.github/workflows/update-digest.yml`:

```yaml
name: Update Base Image Digest

on:
  schedule:
    - cron: '0 0 1 * *'  # Monthly on 1st
  workflow_dispatch:

jobs:
  update-digest:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Pull latest base image
        run: docker pull rocker/shiny:4.4.0

      - name: Get new digest
        id: digest
        run: |
          DIGEST=$(docker inspect rocker/shiny:4.4.0 --format='{{index .RepoDigests 0}}' | cut -d'@' -f2)
          echo "digest=$DIGEST" >> $GITHUB_OUTPUT

      - name: Update Dockerfile
        run: |
          sed -i "s/ARG BASE_IMAGE_DIGEST=.*/ARG BASE_IMAGE_DIGEST=${{ steps.digest.outputs.digest }}/" Dockerfile
          DATE=$(date +%Y-%m-%d)
          sed -i "s/as of [0-9-]*/as of $DATE/" Dockerfile

      - name: Create Pull Request
        uses: peter-evans/create-pull-request@v5
        with:
          commit-message: "chore(docker): update base image digest"
          title: "Update rocker/shiny base image digest"
          body: |
            Auto-generated PR to update base image digest.

            New digest: ${{ steps.digest.outputs.digest }}
          branch: update-docker-digest
```

---

## Key Metrics to Track

### Build Performance

- **Build time** (should decrease with cache)
- **Cache hit rate** (higher is better)
- **Layer count** (fewer is better for size)
- **Image size** (production < development)

### Security Metrics

- **CVE count** (critical + high severity)
- **Base image age** (days since last update)
- **Security scan frequency** (daily/weekly)

### Quality Metrics

- **Lint violations** (should be zero)
- **Best practice compliance** (100%)
- **Health check success rate** (should be 100%)

---

## Related Documentation

- [Maintain Docker best practices](../002-how-to-guides/007-maintain-docker-best-practices.md)
- [.dockerignore configuration](002-dockerignore-configuration.md)
- [Docker official best practices](https://docs.docker.com/build/building/best-practices/)

---

**Last Updated:** 2025-10-25
**Maintained By:** DevOps Team
