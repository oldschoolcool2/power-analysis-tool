# Code Coverage Quick Start Guide

> **TL;DR:** Run `./run_coverage.sh --docker` to get a full coverage report.

---

## The Error You Just Encountered

**Error:** `there is no package called 'testthat'`

**Why?** Running locally requires renv to be set up first. The packages exist in Docker but not in your local R environment.

**Solution:** Use Docker (recommended) or set up renv locally.

---

## Quick Commands

### Recommended: Use Docker

```bash
# Full coverage report with HTML
./run_coverage.sh --docker

# Quick summary (faster, good for CI)
./run_coverage.sh --docker --summary
```

**Why Docker?**
- ✅ All packages pre-installed
- ✅ Reproducible environment
- ✅ No local setup needed
- ✅ Same environment as production

### Alternative: Local Execution

**First-time setup:**

```bash
# Install packages using renv (one time only)
R -e "renv::restore()"

# This will take 5-10 minutes to download and compile packages
```

**Then run coverage:**

```bash
# Full report
./run_coverage.sh

# Quick summary
./run_coverage.sh --summary
```

---

## What to Expect

### First Run (Docker Build)

The first `./run_coverage.sh --docker` will:

1. **Build Docker image** (5-10 minutes)
   - Downloads R packages
   - Installs covr, here, testthat
   - Sets up testing environment

2. **Run coverage analysis** (1-2 minutes)
   - Executes all tests
   - Calculates coverage
   - Generates reports

3. **Output:**
   - Console summary with percentage
   - File-by-file breakdown
   - HTML report in `tests/coverage_report/`

### Subsequent Runs

Much faster! Docker caches the build:
- ⚡ ~30 seconds for summary mode
- ⚡ ~1-2 minutes for full report

---

## Understanding the Output

### Console Output Example

```
==============================================================================
  COVERAGE SUMMARY
==============================================================================

Overall Coverage: 85.67%

Status: GOOD ✓ (Target: 80%+)

==============================================================================
  FILE-BY-FILE BREAKDOWN
==============================================================================

✓ R/input_components.R          92.31% ( 60/ 65 lines)
✓ app.R                         87.45% (710/812 lines)
✓ R/help_content.R              80.00% ( 24/ 30 lines)
⚠ R/header_ui.R                 65.12% ( 28/ 43 lines)
✗ R/sidebar_ui.R                45.83% ( 11/ 24 lines)
```

**Legend:**
- ✓ = Good coverage (≥80%)
- ⚠ = Fair coverage (60-79%)
- ✗ = Poor coverage (<60%)

### HTML Report

Open in browser: `tests/coverage_report/coverage_report.html`

**Features:**
- Line-by-line color coding
- Green = covered by tests
- Red = not covered
- Click through files to explore

---

## Coverage Thresholds

| Level | % | Meaning |
|-------|---|---------|
| 🎉 Excellent | ≥90% | Great test suite! |
| ✅ Good | ≥80% | Acceptable quality |
| ⚠️ Fair | ≥70% | Needs improvement |
| ❌ Fail | <70% | Blocks CI/CD |

**CI/CD Behavior:**
- Coverage ≥70%: Tests pass ✅
- Coverage <70%: Tests fail ❌ (blocks merge)

---

## Common Workflows

### 1. Check Current Coverage

```bash
./run_coverage.sh --docker --summary
```

Output:
```
Code Coverage: 85.67%
✓ Coverage meets threshold (≥70%)
```

### 2. Generate Full Report

```bash
./run_coverage.sh --docker
```

Then open: `tests/coverage_report/coverage_report.html`

### 3. Improve Coverage

**Identify gaps:**
```bash
./run_coverage.sh --docker
# Review HTML report - red lines need tests
```

**Add tests:**
```bash
vim tests/testthat/test-my-feature.R
```

**Re-check coverage:**
```bash
./run_coverage.sh --docker --summary
```

### 4. Pre-Commit Check

Before committing code:

```bash
# Quick check
./run_coverage.sh --docker --summary

# If coverage drops, add more tests
# Then re-run until it passes
```

---

## Troubleshooting

### Issue: Docker build fails

**Solution:**
```bash
# Clean rebuild
docker-compose build --no-cache development

# Or prune everything and rebuild
docker system prune -a
docker-compose build development
```

### Issue: "renv library not found" (local mode)

**Solution:**
```bash
# Option 1: Use Docker instead
./run_coverage.sh --docker

# Option 2: Set up renv
R -e "renv::restore()"
```

### Issue: Coverage script times out

**Solution:**
```bash
# Increase timeout or run with more verbose output
docker-compose run --rm development Rscript tests/run_coverage.R
```

### Issue: HTML report not opening

**Solution:**
```bash
# Manually open the file
# macOS:
open tests/coverage_report/coverage_report.html

# Linux:
xdg-open tests/coverage_report/coverage_report.html

# Windows:
start tests/coverage_report/coverage_report.html
```

---

## Files Created

```
power-analysis-tool/
├── .covrignore                    # Coverage exclusions
├── run_coverage.sh                # Main coverage runner script
├── tests/
│   ├── run_coverage.R             # Full coverage analysis
│   ├── coverage_summary.R         # Quick summary
│   └── coverage_report/           # Generated reports (git-ignored)
│       └── coverage_report.html   # Interactive report
└── docs/
    └── 002-how-to-guides/
        └── 005-code-coverage-tracking.md  # Complete guide
```

---

## Next Steps

1. **Run your first coverage analysis:**
   ```bash
   ./run_coverage.sh --docker
   ```

2. **Review the output:**
   - Check console for overall percentage
   - Open HTML report for details

3. **Identify areas to improve:**
   - Files with <80% coverage
   - Critical business logic paths
   - Error handling code

4. **Add tests:**
   - Focus on high-value code first
   - Test edge cases
   - Don't chase 100% - aim for 80-90%

5. **Re-run to verify:**
   ```bash
   ./run_coverage.sh --docker --summary
   ```

---

## Documentation

**Quick Reference:**
- This file (COVERAGE_QUICKSTART.md)

**Detailed Guide:**
- [docs/002-how-to-guides/005-code-coverage-tracking.md](docs/002-how-to-guides/005-code-coverage-tracking.md)

**Test Suite:**
- [tests/README.md](tests/README.md)

---

## Tips

✅ **Do:**
- Run coverage before committing
- Use Docker for consistency
- Focus on critical code paths
- Review HTML reports periodically

❌ **Don't:**
- Chase 100% coverage obsessively
- Write meaningless tests
- Skip coverage checks in CI/CD
- Ignore coverage trends

---

**Questions?** See the detailed guide: `docs/002-how-to-guides/005-code-coverage-tracking.md`
