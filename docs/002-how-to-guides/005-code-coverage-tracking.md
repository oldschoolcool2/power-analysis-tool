# How to Track Code Coverage

**Type:** How-To Guide
**Audience:** Developers, Contributors
**Last Updated:** 2025-10-25

## Overview

This guide explains how to measure and track code coverage for the Power Analysis Tool using the `covr` package. Code coverage helps identify which parts of your code are tested and which areas need more test coverage.

---

## Prerequisites

- Docker installed (recommended), OR
- R ≥ 4.2.0 with `covr` and `here` packages installed locally

---

## Quick Start

### Option 1: Using the Wrapper Script (Recommended)

The easiest way to run coverage analysis:

```bash
# Full coverage report with HTML output
./run_coverage.sh

# Quick summary only (faster, no HTML report)
./run_coverage.sh --summary

# Run in Docker container
./run_coverage.sh --docker

# Docker + summary mode
./run_coverage.sh --docker --summary
```

### Option 2: Direct R Script Execution

Run the R scripts directly:

```bash
# Full coverage report
Rscript tests/run_coverage.R

# Quick summary
Rscript tests/coverage_summary.R
```

### Option 3: Docker Compose

Run coverage analysis in the development container:

```bash
# Build the development image (includes covr package)
docker-compose build development

# Run full coverage analysis
docker-compose run --rm development Rscript tests/run_coverage.R

# Run quick summary
docker-compose run --rm development Rscript tests/coverage_summary.R
```

---

## Understanding the Output

### Console Output

The coverage script provides several sections:

1. **Coverage Summary**
   - Overall coverage percentage
   - Status indicator (Excellent/Good/Fair/Needs Improvement)

2. **File-by-File Breakdown**
   - Coverage percentage for each R file
   - Lines covered vs. total lines
   - Status icons: ✓ (good), ⚠ (warning), ✗ (needs work)

3. **Uncovered Lines**
   - Specific line numbers that lack test coverage
   - Organized by file

4. **Recommendations**
   - Actionable suggestions for improving coverage
   - Files that need more tests

### HTML Report

The full coverage analysis generates an interactive HTML report:

```
tests/coverage_report/coverage_report.html
```

Open this file in a browser to:
- See line-by-line coverage with color coding
- Click through different files
- Identify specific lines that need tests

---

## Coverage Thresholds

The project uses these coverage thresholds:

| Threshold | Percentage | Status |
|-----------|------------|--------|
| **Target** | ≥90% | Excellent - Keep it up! |
| **Good** | ≥80% | Acceptable - Room for improvement |
| **Warning** | ≥70% | Marginal - Add more tests |
| **Fail** | <70% | Unacceptable - Immediate action required |

### CI/CD Behavior

- Coverage **≥70%**: Tests pass ✓
- Coverage **<70%**: Tests fail ✗ (blocks commits/PRs)

---

## What Gets Measured

### Included in Coverage

The following files are analyzed for test coverage:

- `app.R` - Main application logic
- `R/` directory:
  - `R/input_components.R` - Input UI components
  - `R/header_ui.R` - Header UI
  - `R/help_content.R` - Help system
  - `R/sidebar_ui.R` - Sidebar navigation

### Excluded from Coverage

The `.covrignore` file excludes:

- Test files themselves (`tests/`)
- Documentation (`docs/`)
- Static assets (`www/`)
- Development tools (`check_antipatterns.R`, `validate_code_quality.R`)
- Package infrastructure (`renv/`)

**Rationale:** We measure application code coverage, not test code or infrastructure.

---

## Interpreting Coverage Results

### Good Coverage Indicators

✓ **Helper functions:** 90-100% coverage
- Pure functions with clear inputs/outputs
- Easy to test thoroughly

✓ **Business logic:** 80-95% coverage
- Statistical calculations
- Effect measure computations
- Input validation

✓ **Error handling:** 70-85% coverage
- Edge cases covered
- Invalid input scenarios tested

### Expected Lower Coverage

Some code naturally has lower coverage:

- **Shiny reactive logic:** Complex to test, focus on critical paths
- **UI rendering code:** Often tested manually or with E2E tests
- **Initialization code:** Runs once, may not be worth extensive testing
- **Trivial functions:** Getters/setters with minimal logic

### Coverage ≠ Quality

Important reminders:

- **100% coverage doesn't guarantee bug-free code**
- **Focus on meaningful tests, not coverage percentage**
- **Test critical paths and edge cases first**
- **Don't write tests just to increase coverage**

---

## Common Workflows

### 1. Local Development Cycle

```bash
# 1. Write new feature
vim app.R

# 2. Write tests
vim tests/testthat/test-new-feature.R

# 3. Run tests
Rscript -e "testthat::test_dir('tests/testthat')"

# 4. Check coverage
./run_coverage.sh --summary

# 5. Review uncovered lines and add more tests
./run_coverage.sh  # Generate HTML report

# 6. Iterate until coverage is acceptable
```

### 2. Pre-Commit Check

Before committing code, ensure coverage is acceptable:

```bash
# Quick coverage check
./run_coverage.sh --summary

# If coverage is below threshold, add more tests
# Then re-run until it passes
```

### 3. CI/CD Pipeline

Add to your CI/CD configuration:

```yaml
# Example GitHub Actions
- name: Check Code Coverage
  run: ./run_coverage.sh --docker --summary
```

### 4. Coverage Report Review

Periodically review detailed coverage:

```bash
# Generate full report
./run_coverage.sh

# Open in browser
open tests/coverage_report/coverage_report.html

# Identify areas needing attention
# Add tests for uncovered critical paths
```

---

## Improving Coverage

### Strategy 1: Focus on Low-Hanging Fruit

Target files with <80% coverage:

```bash
# Run coverage to see file breakdown
./run_coverage.sh

# Prioritize files with:
# - Low coverage (< 80%)
# - High importance (core logic)
# - Many uncovered lines (easy wins)
```

### Strategy 2: Test Critical Paths First

Focus on high-value areas:

1. **Statistical calculations** - Verify correctness
2. **Input validation** - Prevent bad inputs
3. **Effect measures** - Core business logic
4. **Error handling** - Graceful failures

### Strategy 3: Add Tests for Uncovered Lines

The coverage report shows specific uncovered lines:

```r
# Example: app.R line 450 is uncovered
# Review the code at that line
# Write a test that executes that line

test_that("handles zero event rate correctly", {
  # This test covers the previously uncovered line 450
  result <- calc_effect_measures(0, 0.05)
  expect_true(is.na(result$relative_risk))
})
```

### Strategy 4: Use Coverage-Driven Development

1. Write a test that fails (uncovered functionality)
2. Run coverage - see the line is uncovered
3. Implement the functionality
4. Re-run coverage - see the line is now covered
5. Refactor and ensure coverage stays high

---

## Troubleshooting

### Issue: `covr` Package Not Found

**Solution:** Install the package:

```r
# Local installation
install.packages('covr')

# Or build Docker development image
docker-compose build development
```

### Issue: `here` Package Not Found

**Solution:** Install the package:

```r
install.packages('here')
```

### Issue: Coverage Script Fails

**Error:** `Error: No tests found`

**Solution:** Ensure you're running from the project root:

```bash
cd /path/to/power-analysis-tool
./run_coverage.sh
```

### Issue: HTML Report Not Generated

**Possible causes:**

1. Missing `DT` package: `install.packages('DT')`
2. File system permissions: Check write access to `tests/coverage_report/`
3. Browser not opening: Open the HTML file manually

### Issue: Coverage Suddenly Drops

**Investigate:**

1. Did you add new code without tests?
2. Did tests get deleted or skipped?
3. Run with verbose output: `Rscript tests/run_coverage.R`
4. Review the file-by-file breakdown to identify culprits

### Issue: Docker Build Takes Too Long

**Solution:** The `.dockerignore` file already optimizes build context. If still slow:

1. Use BuildKit: `DOCKER_BUILDKIT=1 docker-compose build`
2. Prune Docker cache: `docker system prune -a`
3. Check network connectivity (package downloads)

---

## Best Practices

### DO

✓ Run coverage locally before committing
✓ Focus on testing critical business logic
✓ Write tests for edge cases and error conditions
✓ Use coverage to identify gaps in test suite
✓ Review HTML report periodically for insights
✓ Set coverage thresholds in CI/CD
✓ Keep the `.covrignore` file updated

### DON'T

✗ Chase 100% coverage as the primary goal
✗ Write meaningless tests just to boost coverage
✗ Ignore coverage trends over time
✗ Test UI rendering code extensively (use E2E tests instead)
✗ Commit code that drops coverage below threshold
✗ Sacrifice test quality for coverage quantity

---

## Integration with Existing Testing

### Relationship to Other Test Types

The coverage analysis complements other testing:

| Test Type | Tool | Coverage Impact | Purpose |
|-----------|------|-----------------|---------|
| **Unit Tests** | `testthat` | High | Tests helper functions, increases coverage |
| **Server Tests** | `testServer()` | Medium | Tests reactive logic, some coverage |
| **E2E Tests** | `shinytest2` | Low | Tests UI interactions, minimal coverage impact |

**Note:** `shinytest2` doesn't contribute to `covr` metrics, but is still valuable for UI testing.

### Running Tests and Coverage Together

```bash
# Run unit tests only
Rscript -e "testthat::test_dir('tests/testthat')"

# Run unit tests + coverage
./run_coverage.sh

# Run all tests including E2E
Rscript -e "testthat::test_dir('tests/testthat')"
# shinytest2 tests run separately via testServer() or app drivers
```

---

## Advanced Usage

### Running Coverage on Specific Files

```r
# Load covr
library(covr)

# Test coverage for a specific file
file_coverage <- file_coverage("app.R", "tests/testthat/test-power-analysis.R")
print(file_coverage)
```

### Generating Coverage Reports in Different Formats

```r
# Codecov format (for CI integration)
cov <- package_coverage()
covr::codecov(coverage = cov)

# Coveralls format
covr::coveralls(coverage = cov)

# Simple percentage
covr::percent_coverage(cov)
```

### Excluding Specific Lines from Coverage

Add `# nocov start` and `# nocov end` comments:

```r
# This code is excluded from coverage analysis
# nocov start
if (interactive()) {
  message("Debug mode enabled")
}
# nocov end
```

Use sparingly - only for code that's genuinely untestable.

---

## Coverage Metrics Explained

### Overall Coverage

**Formula:** `(Covered Lines / Total Lines) × 100%`

**Interpretation:**
- **90%+** = Excellent test suite
- **80-90%** = Good coverage, some gaps
- **70-80%** = Fair coverage, room for improvement
- **<70%** = Insufficient testing

### Line Coverage

Measures whether each line of code was executed during tests.

**Color coding in HTML report:**
- **Green** = Line executed by tests ✓
- **Red** = Line never executed ✗
- **Orange** = Line partially executed (branches)

### Branch Coverage

(Not tracked by default, but available)

Measures whether all conditional branches (`if`, `else`) are tested.

---

## Files and Directories

```
power-analysis-tool/
├── .covrignore                     # Files excluded from coverage
├── run_coverage.sh                 # Wrapper script for coverage
├── tests/
│   ├── run_coverage.R              # Full coverage analysis script
│   ├── coverage_summary.R          # Quick summary script
│   ├── coverage_report/            # Generated HTML reports
│   │   └── coverage_report.html   # Interactive coverage report
│   └── testthat/                   # Test files
│       ├── test-power-analysis.R
│       ├── test-calculations-advanced.R
│       └── ...
└── Dockerfile                      # Includes covr in dev stage
```

---

## Example Output

### Successful Coverage Run

```
==============================================================================
  Power Analysis Tool - Code Coverage Analysis
==============================================================================

Running code coverage analysis...

==============================================================================
  COVERAGE SUMMARY
==============================================================================

Overall Coverage: 87.34%

Status: GOOD ✓ (Target: 80%+)

==============================================================================
  FILE-BY-FILE BREAKDOWN
==============================================================================

✓ R/input_components.R                      95.23% ( 60/ 63 lines)
✓ app.R                                     88.91% (721/811 lines)
✓ R/help_content.R                          82.14% ( 23/ 28 lines)
⚠ R/header_ui.R                             67.44% ( 29/ 43 lines)
✗ R/sidebar_ui.R                            45.83% ( 11/ 24 lines)

==============================================================================
  RECOMMENDATIONS
==============================================================================

Files needing more test coverage:

  • R/header_ui.R (67.4% coverage)
    → Add ~5 more tested lines to reach 80% coverage

  • R/sidebar_ui.R (45.8% coverage)
    → Add ~15 more tested lines to reach 80% coverage
```

---

## Related Documentation

- **[001-contributing.md](001-contributing.md)** - Contributing guidelines
- **[004-end-to-end-testing-with-shinytest2.md](004-end-to-end-testing-with-shinytest2.md)** - E2E testing guide
- **[../003-reference/002-testing-framework.md](../003-reference/002-testing-framework.md)** - Testing reference

---

## External Resources

- **covr package documentation:** https://covr.r-lib.org/
- **R Packages book - Testing:** https://r-pkgs.org/testing-design.html
- **covr GitHub repository:** https://github.com/r-lib/covr
- **Codecov integration:** https://about.codecov.io/

---

**Last Updated:** 2025-10-25
**Maintained By:** Development Team
