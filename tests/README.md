# Test Suite for Power Analysis Tool

This directory contains the comprehensive test suite for the Power Analysis Tool, including unit tests, server tests, and end-to-end tests.

## Test Organization

```
tests/
├── testthat/                           # All testthat tests
│   ├── testthat.R                      # Test runner entry point
│   ├── setup-shinytest2.R              # E2E test setup and helpers
│   │
│   # Unit Tests (Pure R functions)
│   ├── test-power-analysis.R           # Core calculation tests
│   ├── test-calculations-advanced.R    # Advanced statistical tests
│   │
│   # End-to-End Tests (Full user workflows)
│   ├── test-shinytest2-sample-size.R   # Sample Size tab E2E tests
│   ├── test-shinytest2-mde.R           # MDE tab E2E tests
│   ├── test-shinytest2-power.R         # Power Calculation tab E2E tests
│   └── test-shinytest2-integration.R   # Cross-functional E2E tests
│
└── testthat/_snaps/                    # Test snapshots (auto-generated)
    ├── test-shinytest2-sample-size/    # Sample Size tab snapshots
    ├── test-shinytest2-mde/            # MDE tab snapshots
    └── ...
```

## Test Layers

We use a three-layer testing strategy:

### 1. Unit Tests (testthat)

**Purpose:** Test pure R functions in isolation

**Files:**
- `test-power-analysis.R` - Core statistical calculations
- `test-calculations-advanced.R` - Advanced features

**Run:**
```r
testthat::test_file("tests/testthat/test-power-analysis.R")
```

**Characteristics:**
- ✅ Fast execution
- ✅ Easy to debug
- ✅ Test edge cases
- ❌ Don't test UI or reactivity

### 2. Server Tests (testServer)

**Purpose:** Test Shiny reactive logic

**Files:**
- Currently integrated within unit test files
- Use `testServer()` for reactive expressions

**Run:**
```r
# Included in unit test runs
testthat::test_file("tests/testthat/test-power-analysis.R")
```

**Characteristics:**
- ✅ Test reactive logic
- ✅ No browser required
- ✅ Moderate speed
- ❌ Don't test UI rendering

### 3. End-to-End Tests (shinytest2)

**Purpose:** Test complete user workflows in browser

**Files:**
- `test-shinytest2-sample-size.R` - Sample Size tab
- `test-shinytest2-mde.R` - MDE (Minimal Detectable Effect) tab
- `test-shinytest2-power.R` - Power Calculation tab
- `test-shinytest2-integration.R` - Cross-tab workflows

**Run:**
```r
# All E2E tests
testthat::test_dir("tests/testthat", filter = "shinytest2")

# Specific tab
testthat::test_file("tests/testthat/test-shinytest2-sample-size.R")
```

**Characteristics:**
- ✅ Test entire stack
- ✅ Catch integration issues
- ✅ Visual regression testing
- ⚠️ Slower execution
- ⚠️ Requires Chrome/Chromium

## Running Tests

### All Tests

```r
# From R console
devtools::test()

# Or
testthat::test_dir("tests/testthat")
```

### By Type

```r
# Unit tests only (exclude shinytest2)
testthat::test_dir("tests/testthat", filter = "^test-(?!shinytest2)")

# E2E tests only
testthat::test_dir("tests/testthat", filter = "shinytest2")
```

### Specific File

```r
testthat::test_file("tests/testthat/test-power-analysis.R")
```

### In RStudio

Use keyboard shortcut: `Ctrl+Shift+T` (Windows/Linux) or `Cmd+Shift+T` (Mac)

## Writing Tests

### Unit Tests

```r
test_that("calc_effect_measures handles valid inputs", {
  result <- calc_effect_measures(0.15, 0.10)

  expect_type(result, "list")
  expect_named(result, c("RR", "OR", "RD"))
  expect_true(result$RR > 1)
})
```

### E2E Tests

```r
test_that("Sample Size calculation workflow", {
  app <- AppDriver$new(app_dir = "../../")

  app$set_inputs(tabs = "sample_size")
  app$set_inputs(p1 = 0.15, p2 = 0.10, alpha = 0.05, power = 0.80)
  app$wait_for_idle()

  app$expect_values(output = "results")
  app$get_screenshot("sample-size-results")

  app$stop()
})
```

## Test Coverage

### Current Coverage (2025-10-25)

- **Unit tests:** Core calculations, helper functions
- **E2E tests:** All three main tabs (Sample Size, MDE, Power)
- **Integration tests:** Tab navigation, responsive design, performance

### Testing Philosophy

For Shiny applications, we focus on:
- **Unit test coverage** for helper functions and calculations
- **E2E test coverage** for all critical user workflows
- **Visual regression testing** via screenshots
- **Manual QA** for UX and edge cases

**Why we don't use code coverage metrics (covr):**
- Shiny apps are interaction-driven, not package-driven
- Line coverage doesn't measure reactive behavior
- E2E tests provide better quality signals
- Coverage percentage can be misleading for UI-heavy code

## Debugging Failed Tests

### Unit Test Failures

```r
# Run specific test with detailed output
testthat::test_file("tests/testthat/test-power-analysis.R", reporter = "progress")
```

### E2E Test Failures

```r
# Run with visible browser for debugging
app <- AppDriver$new(
  app_dir = "../../",
  view = TRUE  # Opens Chrome window
)
```

### Snapshot Failures

```r
# Review snapshot changes
testthat::snapshot_review()

# Accept changes if expected
testthat::snapshot_accept()
```

## Continuous Integration

Tests run automatically on:
- Every push to repository
- Every pull request
- Scheduled nightly builds (if configured)

## Best Practices

### Do

✅ Write descriptive test names
✅ Test one behavior per test
✅ Use setup files for shared code
✅ Clean up after tests (especially E2E)
✅ Wait for app to be idle in E2E tests
✅ Take screenshots for visual regression

### Don't

❌ Make tests depend on each other
❌ Use hard-coded sleep times
❌ Test implementation details
❌ Commit failing tests
❌ Skip tests without good reason
❌ Leave debug code in tests

## Troubleshooting

### Chrome not found (E2E tests)

```r
# Set Chrome path
Sys.setenv(CHROMOTE_CHROME = "/usr/bin/chromium")
```

### Tests timeout

```r
# Increase timeout in E2E tests
app$wait_for_idle(timeout = 30000)  # 30 seconds
```

### Flaky E2E tests

- Always use `wait_for_idle()` instead of `Sys.sleep()`
- Limit snapshot scope to specific outputs
- Check for non-deterministic calculations

### Tests pass locally but fail on CI

- Use consistent screen sizes
- Set `options(shiny.snapshotsortc = TRUE)`
- Check locale differences

## Resources

### Documentation

- [How-to Guide: End-to-End Testing](../docs/002-how-to-guides/004-end-to-end-testing-with-shinytest2.md)
- [Explanation: Testing Strategy](../docs/004-explanation/004-testing-strategy-and-shinytest2.md)

### External References

- [testthat documentation](https://testthat.r-lib.org/)
- [shinytest2 documentation](https://rstudio.github.io/shinytest2/)
- [Testing chapter in Mastering Shiny](https://mastering-shiny.org/scaling-testing.html)

## Contributing

When adding new features:

1. Write unit tests for new functions
2. Add E2E tests for new UI workflows
3. Update this README if test structure changes
4. Ensure all tests pass before submitting PR

See [Contributing Guide](../docs/002-how-to-guides/001-contributing.md) for more details.

---

**Last Updated:** 2025-10-25
**Test Framework:** testthat + shinytest2
**Maintained By:** Development Team
