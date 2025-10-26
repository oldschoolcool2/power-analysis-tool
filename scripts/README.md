# Scripts

This directory contains development utilities, validation scripts, and maintenance tools that support the development process but are not part of the core application.

## Purpose

Development and maintenance scripts that don't belong in the root directory or the R/ source code directory.

## Contents

- **check_antipatterns.R** - Code quality validation script
- **validate_code_quality.R** - Code quality validation script
- **check_dependencies.R** - Dependency checking and validation
- **run_dev_app.R** - Development mode application launcher

## Usage

These scripts are typically run manually during development or as part of CI/CD pipelines. They are not required for normal application operation.

### Running Scripts

```r
# From project root
source("scripts/check_antipatterns.R")
source("scripts/validate_code_quality.R")
source("scripts/check_dependencies.R")

# Development mode launcher
source("scripts/run_dev_app.R")
```

## Organization

- **Code quality**: Scripts that check code style, antipatterns, and quality metrics
- **Dependency management**: Scripts that validate and check package dependencies
- **Development utilities**: Helper scripts for local development

---

**Last Updated:** 2025-10-26
