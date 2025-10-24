# Code Quality Tools & Pre-commit Hooks

This document describes the code quality tools configured for this R Shiny application.

## Overview

We use modern R code quality tools to maintain consistent, readable, and error-free code:

- **lintr** - Static code analysis to catch errors and enforce style
- **styler** - Automatic code formatting following tidyverse style guide
- **pre-commit** - Git hooks to run checks before commits
- **GitHub Actions** - Automated CI/CD quality checks on pull requests

## Quick Start

### Option 1: Using Docker (Recommended)

All quality tools are pre-installed in the Docker container:

```bash
# Build the Docker image
docker-compose build

# Run styler inside container
docker-compose run --rm app Rscript -e "styler::style_dir('.')"

# Run lintr inside container
docker-compose run --rm app Rscript -e "lintr::lint_dir('.')"
```

### Option 2: Local Installation

If you have R installed locally with proper system dependencies:

```r
# Install quality tools
install.packages(c("lintr", "styler", "precommit"))

# Format code
styler::style_file("app.R")
styler::style_dir(".")

# Lint code
lintr::lint("app.R")
lintr::lint_dir(".")

# Setup pre-commit hooks
precommit::use_precommit()
precommit::install_precommit()
```

**System Requirements:**
- `libxml2-dev` (for lintr's XML parsing)
- `libcurl4-openssl-dev`
- `libssl-dev`

Install on Ubuntu/Debian:
```bash
sudo apt-get install libxml2-dev libcurl4-openssl-dev libssl-dev
```

## Configuration Files

### `.lintr`

Configures which linting rules to apply. Current configuration:

```r
linters: linters_with_tags(
    tags = c("best_practices", "common_mistakes", "readability", "correctness"),
    # Overly strict linters disabled for gradual adoption
    object_length_linter = NULL,
    line_length_linter = NULL,
    indentation_linter = NULL,
    T_and_F_symbol_linter = NULL
  )
```

**Enabled linter categories:**
- `best_practices` - Catches R anti-patterns
- `common_mistakes` - Identifies likely bugs
- `readability` - Improves code clarity
- `correctness` - Ensures valid R syntax

**Temporarily disabled (can enable later):**
- `object_length_linter` - Variable name length limits
- `line_length_linter` - 80-character line limit
- `T_and_F_symbol_linter` - Enforce TRUE/FALSE over T/F

### `.editorconfig`

Cross-editor settings for consistent formatting:
- UTF-8 encoding
- LF line endings
- 2-space indentation for R files
- Trim trailing whitespace

### `.pre-commit-config.yaml`

Git hooks that run automatically before commits:

**General hooks:**
- Trim trailing whitespace
- Ensure files end with newline
- Check YAML syntax
- Prevent large files (>1MB)
- Detect private keys

**R-specific hooks:**
- `style-files` - Auto-format with styler (tidyverse style)
- `lintr` - Lint R code (warning mode initially)
- `parsable-R` - Ensure R files are syntactically valid
- `no-browser-statement` - Catch debug statements
- `no-debug-statement` - Catch debug() calls

**Docker hooks:**
- `hadolint` - Lint Dockerfile

## Pre-commit Hooks Setup

### Installation

```bash
# Install pre-commit framework (Python)
pip install pre-commit

# Or via system package manager
# Ubuntu/Debian:
sudo apt-get install pre-commit

# macOS:
brew install pre-commit

# Install hooks in your repo
pre-commit install
```

### Usage

Hooks run automatically on `git commit`. To run manually:

```bash
# Run on staged files
pre-commit run

# Run on all files
pre-commit run --all-files

# Run specific hook
pre-commit run style-files --all-files

# Skip hooks (emergency use only!)
git commit --no-verify
```

### Updating hooks

```bash
# Update to latest hook versions
pre-commit autoupdate

# Re-install after config changes
pre-commit install --install-hooks
```

## GitHub Actions CI/CD

The `.github/workflows/quality-checks.yml` workflow runs on:
- Pull requests to `master`/`main`
- Pushes to `master`/`main`
- Manual dispatch

**Jobs:**
1. **lint-and-style** - Checks code formatting and linting
2. **test** - Runs testthat test suite
3. **docker-build** - Validates Docker image builds

**What it does:**
- ✅ Verifies all code follows tidyverse style (styler)
- ✅ Checks for common R mistakes and bad practices (lintr)
- ✅ Runs all unit tests
- ✅ Ensures Docker image builds successfully
- ✅ Uses caching for fast builds

**Viewing results:**
1. Go to GitHub repository
2. Click "Actions" tab
3. Select workflow run
4. Review job outputs

## Common Workflows

### Before Committing

```r
# 1. Format your code
styler::style_file("app.R")

# 2. Check for lint issues
lints <- lintr::lint("app.R")
print(lints)

# 3. Fix issues manually or review
# 4. Commit (pre-commit hooks will run automatically)
```

### Fixing Lint Issues

```r
# Get detailed lint report
lints <- lintr::lint_dir(".", exclusions = list("renv/"))

# Review each issue
print(lints)

# Common fixes:
# - Use TRUE/FALSE instead of T/F
# - Add spaces around operators: x<-1 → x <- 1
# - Use snake_case for variables: myVar → my_var
# - Remove trailing whitespace
# - Fix line lengths (break long lines)
```

### Reviewing Style Changes

```r
# Preview changes without modifying files
styler::style_dir(".", dry = "on")

# Apply changes
styler::style_dir(".")

# Review in git
git diff
```

### Gradual Adoption Strategy

The linter configuration uses a **gradual adoption** approach:

**Phase 1 (Current):** Catch critical issues
- Focus on `best_practices`, `common_mistakes`, `correctness`
- Style linters in warning mode (non-blocking)

**Phase 2:** Enforce style consistency
- Enable `line_length_linter`
- Enable `T_and_F_symbol_linter`
- Make lintr blocking in pre-commit hooks

**Phase 3:** Full strict mode
- Enable all linters
- Zero tolerance for warnings in CI

To progress to next phase:
```r
# Edit .lintr file, remove NULL assignments for linters to enable
# Example:
linters: linters_with_tags(
    tags = c("best_practices", "common_mistakes", "readability", "correctness", "style"),
    # Re-enable gradually
    T_and_F_symbol_linter = lintr::T_and_F_symbol_linter(),
    object_length_linter = lintr::object_length_linter(30)
  )
```

## Integrations

### RStudio

lintr and styler integrate with RStudio:

**styler Addin:**
1. Addins menu → "Style active file"
2. Select code → Addins → "Style selection"

**lintr Markers:**
- Lint issues appear in RStudio's "Markers" pane
- Click to jump to issue location

### VS Code

Install the **R** extension:
1. `Ctrl+Shift+X` → Search "R"
2. Enable linting in settings:
   ```json
   "r.lsp.enabled": true,
   "r.lsp.diagnostics": true
   ```

### vim/Neovim

Use **ALE** or **nvim-lint** with lintr:
```vim
" .vimrc
let g:ale_linters = {'r': ['lintr']}
let g:ale_fixers = {'r': ['styler']}
```

## Troubleshooting

### Pre-commit hooks fail

```bash
# Check which hook failed
pre-commit run --all-files

# View detailed error
pre-commit run --verbose style-files

# Update hooks
pre-commit autoupdate

# Clean and reinstall
pre-commit clean
pre-commit install
```

### lintr fails locally but works in CI

**Cause:** Missing system dependencies (libxml2-dev)

**Solution:** Use Docker for consistency
```bash
docker-compose run --rm app Rscript -e "lintr::lint_dir('.')"
```

### styler changes indentation

**Expected:** tidyverse style uses 2-space indentation

**If you prefer 4 spaces:**
```r
# Create custom style
my_style <- function() {
  styler::tidyverse_style(indent_by = 4)
}

styler::style_file("app.R", transformers = my_style())
```

### Too many lint warnings

**Gradual approach:**
1. Start with critical issues only (current `.lintr` config)
2. Fix one category at a time
3. Enable stricter rules incrementally

**Exclude files:**
```r
# In .lintr
exclusions: list(
  "renv/",
  "tests/testthat.R",
  "legacy_code.R"  # Add problematic files temporarily
)
```

## Best Practices

### When to Run Quality Checks

- ✅ **Before every commit** (automated via pre-commit hooks)
- ✅ **Before pull requests** (run `pre-commit run --all-files`)
- ✅ **After major refactoring** (verify style consistency)
- ✅ **When onboarding new developers** (ensure familiarity with tools)

### Commit Message for Style Changes

```bash
# Good
git commit -m "style: apply tidyverse formatting with styler"

# Also good
git commit -m "refactor: fix lintr warnings in validation functions"

# Include context
git commit -m "style: convert indentation to 2 spaces (tidyverse)

- Applied styler::style_dir()
- Fixes 147 indentation inconsistencies
- No functional changes"
```

### Handling False Positives

Some lint warnings may be intentional:

```r
# Suppress specific linter for a line
my_var <- function() { ... }  # lintr: object_name_linter.

# Suppress for entire file (use sparingly!)
# lintr: skip_file
```

## References

- **lintr documentation:** https://lintr.r-lib.org/
- **styler documentation:** https://styler.r-lib.org/
- **Tidyverse style guide:** https://style.tidyverse.org/
- **pre-commit framework:** https://pre-commit.com/
- **R pre-commit hooks:** https://github.com/lorenzwalthert/precommit

## Maintenance

### Updating Tools

```r
# Update R packages
install.packages(c("lintr", "styler", "precommit"))

# Update pre-commit hooks
pre-commit autoupdate
```

### Monitoring Code Quality

**GitHub Actions** provides automated quality metrics:
- View trends in Actions tab
- Set up branch protection rules requiring checks to pass
- Monitor test coverage (if `covr` is added)

**Local metrics:**
```r
# Count lint issues
length(lintr::lint_dir("."))

# Check which files need styling
styled <- styler::style_dir(".", dry = "on")
sum(styled$changed)
```

---

**Questions or Issues?**
- Check existing GitHub issues
- Refer to CLAUDE.md for project-specific guidance
- Run `lintr::available_linters()` to see all available checks
