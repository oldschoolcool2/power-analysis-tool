# How to Run End-to-End Tests with shinytest2

**Type:** How-To
**Audience:** Developers, Contributors
**Last Updated:** 2025-10-25

## Overview

This guide shows you how to run, write, and maintain end-to-end (E2E) tests for the Power Analysis Tool using shinytest2. E2E tests simulate real user interactions with the Shiny application in a headless Chrome browser, ensuring the entire application works correctly from the user's perspective.

## Prerequisites

- R >= 4.2.0 installed
- Chrome or Chromium browser installed
- Development environment set up (see `001-contributing.md`)
- Basic understanding of testthat framework

## Quick Start

### Running All E2E Tests

To run all end-to-end tests:

```bash
# From the project root directory
R -e "testthat::test_dir('tests/testthat', filter = 'shinytest2')"
```

Or using devtools:

```r
# In R console
devtools::test(filter = "shinytest2")
```

### Running Tests for a Specific Tab

To test only the Sample Size tab:

```r
testthat::test_file("tests/testthat/test-shinytest2-sample-size.R")
```

To test only the MDE tab:

```r
testthat::test_file("tests/testthat/test-shinytest2-mde.R")
```

To test only the Power Calculation tab:

```r
testthat::test_file("tests/testthat/test-shinytest2-power.R")
```

### Running Integration Tests

```r
testthat::test_file("tests/testthat/test-shinytest2-integration.R")
```

## Understanding Test Structure

### Test File Organization

```
tests/testthat/
├── setup-shinytest2.R               # Setup and helper functions
├── test-shinytest2-sample-size.R    # Sample Size tab tests
├── test-shinytest2-mde.R            # MDE tab tests
├── test-shinytest2-power.R          # Power Calculation tab tests
└── test-shinytest2-integration.R    # Cross-functional tests
```

### Test Anatomy

Each test follows the GIVEN-WHEN-THEN pattern:

```r
test_that("Sample Size calculation works with valid inputs", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-calculation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")

  # WHEN: User enters valid proportions
  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle()

  # THEN: Results should be calculated
  app$expect_values(output = "results")

  app$stop()
})
```

## Writing New E2E Tests

### Step 1: Choose the Right Test File

- **Tab-specific behavior** → Use the corresponding tab test file
- **Cross-tab workflows** → Use `test-shinytest2-integration.R`
- **New tab** → Create new file following naming convention

### Step 2: Use the Page Object Model Helper

The `PowerAnalysisApp` class in `setup-shinytest2.R` provides reusable methods:

```r
test_that("Example using Page Object Model", {
  app <- AppDriver$new(app_dir = "../../")
  power_app <- PowerAnalysisApp$new(app)

  # Use helper methods for cleaner tests
  power_app$
    switch_to_tab("sample_size")$
    set_sample_size_inputs(p1 = 0.15, p2 = 0.10, alpha = 0.05, power = 0.80)$
    expect_no_errors()

  power_app$app$stop()
})
```

### Step 3: Follow Best Practices

**Do:**
- Test user behavior, not implementation details
- Use descriptive test names that explain the scenario
- Wait for the app to be idle before assertions
- Take screenshots for visual regression testing
- Clean up by calling `app$stop()`

**Don't:**
- Test internal reactive logic (use `testServer()` instead)
- Make tests depend on each other
- Hard-code timing assumptions (use `wait_for_idle()`)
- Test every possible input combination (use boundary values)

### Step 4: Write the Test

```r
test_that("Clear description of what you're testing", {
  # GIVEN: Initial state
  app <- AppDriver$new(app_dir = "../../", name = "unique-test-name")

  # WHEN: User action
  app$set_inputs(input_id = value)
  app$wait_for_idle()

  # THEN: Expected outcome
  app$expect_values(output = "expected_output")

  # Optional: Screenshot for visual regression
  app$get_screenshot("descriptive-name")

  app$stop()
})
```

## Working with Snapshots

### Creating Initial Snapshots

On first run, shinytest2 creates snapshot files:

```
tests/testthat/_snaps/
├── test-shinytest2-sample-size/
│   ├── sample-size-valid-inputs.png
│   └── sample-size-valid-inputs.json
└── test-shinytest2-mde/
    └── ...
```

### Reviewing Snapshot Changes

When test output changes:

```r
# Review all changed snapshots
testthat::snapshot_review()

# Accept changes if they're expected
testthat::snapshot_accept()
```

### Snapshot Best Practices

- **Review carefully** before accepting snapshot changes
- **Limit scope** using focused `expect_values()`:
  ```r
  # Good: Only check relevant output
  app$expect_values(output = "results")

  # Avoid: Checking everything can cause spurious failures
  app$expect_values()
  ```
- **Use semantic screenshots** with descriptive names

## Debugging Failed Tests

### Viewing the App in a Browser

Run tests with visible browser:

```r
app <- AppDriver$new(
  app_dir = "../../",
  view = TRUE  # Opens visible browser window
)
```

### Inspecting App State

```r
# Get current input values
current_inputs <- app$get_values(input = TRUE)
print(current_inputs)

# Get current output values
current_outputs <- app$get_values(output = TRUE)
print(current_outputs)

# Take screenshot at any point
app$get_screenshot("debug-screenshot")
```

### Increasing Wait Timeouts

```r
# If tests fail due to slow rendering
app$wait_for_idle(timeout = 30000)  # 30 seconds
```

### Checking for JavaScript Errors

```r
# Get browser console logs
logs <- app$get_logs()
print(logs)
```

## Common Testing Scenarios

### Testing Input Validation

```r
test_that("App validates proportion ranges", {
  app <- AppDriver$new(app_dir = "../../")

  app$set_inputs(p1 = 1.5)  # Invalid: > 1
  app$wait_for_idle()

  # Expect validation error or prevention
  # Implementation depends on app design

  app$stop()
})
```

### Testing Calculations

```r
test_that("Sample size calculation is correct", {
  app <- AppDriver$new(app_dir = "../../")

  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle()

  # Compare with known expected value
  results <- app$get_value(output = "results")
  # Add assertions based on expected output format

  app$stop()
})
```

### Testing Plot Rendering

```r
test_that("Power curve renders", {
  app <- AppDriver$new(app_dir = "../../")

  app$set_inputs(p1 = 0.15, p2 = 0.10, wait_ = FALSE)
  app$wait_for_idle()

  # Check plot exists
  plot_output <- app$get_value(output = "plot_power_curve")
  expect_true(!is.null(plot_output))

  # Visual regression with screenshot
  app$get_screenshot("power-curve-visual")

  app$stop()
})
```

### Testing Tab Navigation

```r
test_that("User can navigate to all tabs", {
  app <- AppDriver$new(app_dir = "../../")

  tabs <- c("sample_size", "mde", "power")

  for (tab in tabs) {
    app$set_inputs(tabs = tab)
    app$wait_for_idle()

    current_tab <- app$get_value(input = "tabs")
    expect_equal(current_tab, tab)
  }

  app$stop()
})
```

## Performance Considerations

### Running Tests in Parallel

shinytest2 supports parallel test execution:

```r
# In tests/testthat.R or via environment variable
Sys.setenv("TESTTHAT_MAX_PARALLEL" = 4)

testthat::test_dir("tests/testthat")
```

### Reducing Test Time

**Strategies:**
1. **Limit snapshots** to only what's necessary
2. **Reuse AppDriver instances** within a test file (carefully)
3. **Skip slow tests** during development:
   ```r
   test_that("Slow test", {
     skip_on_ci()  # Skip on CI
     # or
     skip("WIP - too slow for regular runs")
   })
   ```

## Continuous Integration

### GitHub Actions Example

Add to `.github/workflows/test.yml`:

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v2

      - uses: r-lib/actions/setup-r@v2

      - name: Install system dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y chromium-browser

      - name: Install R dependencies
        run: |
          install.packages("renv")
          renv::restore()
        shell: Rscript {0}

      - name: Run E2E tests
        run: |
          testthat::test_dir("tests/testthat", filter = "shinytest2")
        shell: Rscript {0}

      - name: Upload test artifacts
        if: failure()
        uses: actions/upload-artifact@v2
        with:
          name: test-snapshots
          path: tests/testthat/_snaps/
```

## Troubleshooting

### "Chrome not found" Error

**Solution:**
```r
# Set Chrome path explicitly
Sys.setenv(CHROMOTE_CHROME = "/usr/bin/chromium")
```

### Tests Pass Locally but Fail on CI

**Common causes:**
- Different screen sizes → Use consistent dimensions
- Locale differences → Set `options(shiny.snapshotsortc = TRUE)`
- Timing issues → Increase timeout values on CI

### Snapshots Keep Changing

**Solutions:**
1. Use `expect_values()` with specific outputs only
2. Preprocess snapshot data to remove timestamps/random values
3. Check for non-deterministic calculations

### App Doesn't Start

**Debugging steps:**
```r
# 1. Check app runs normally
shiny::runApp()

# 2. Check for missing dependencies
renv::status()

# 3. Look at AppDriver logs
app <- AppDriver$new(app_dir = "../../", view = TRUE)
logs <- app$get_logs()
print(logs)
```

## Advanced Topics

### Custom Expectations

Create custom expectations in `setup-shinytest2.R`:

```r
expect_calculation_within_tolerance <- function(app, output_id, expected, tolerance = 0.01) {
  actual <- app$get_value(output = output_id)
  expect_true(
    abs(actual - expected) < tolerance,
    info = paste0("Expected ", expected, " ± ", tolerance, ", got ", actual)
  )
}
```

### Testing Downloads

```r
test_that("Report downloads successfully", {
  app <- AppDriver$new(app_dir = "../../")

  app$set_inputs(/* prepare data */)

  # Note: Download testing requires special handling
  # shinytest2 doesn't directly support file downloads yet

  app$stop()
})
```

### Testing with Different Locales

```r
test_that("App works in different locales", {
  withr::with_locale(c(LC_ALL = "fr_FR.UTF-8"), {
    app <- AppDriver$new(app_dir = "../../")
    # Test app behavior
    app$stop()
  })
})
```

## Resources

### Official Documentation
- [shinytest2 documentation](https://rstudio.github.io/shinytest2/)
- [Testing Shiny chapter in Mastering Shiny](https://mastering-shiny.org/scaling-testing.html)

### Tutorials
- [End-to-end testing with shinytest2: Part 1](https://www.jumpingrivers.com/blog/end-to-end-testing-shinytest2-part-1/)
- [End-to-end testing with shinytest2: Part 2](https://www.jumpingrivers.com/blog/end-to-end-testing-shinytest2-part-2/)
- [End-to-end testing with shinytest2: Part 3](https://www.jumpingrivers.com/blog/end-to-end-testing-shinytest2-part-3/)

### Best Practices
- [Page Object Model for UI testing](https://martinfowler.com/bliki/PageObject.html)
- [Testing Best Practices (Appsilon)](https://www.appsilon.com/post/how-to-write-tests-with-shiny-testserver)

## Next Steps

After mastering E2E testing:
1. Set up CI/CD to run tests automatically
2. Add visual regression testing for plots
3. Measure and improve test coverage
4. Consider adding performance benchmarks

---

**Related Documentation:**
- `001-contributing.md` - Development setup
- `../003-reference/` - API reference for tested functions
- `../004-explanation/` - Why we chose shinytest2

**References:**
- [shinytest2 GitHub repository](https://github.com/rstudio/shinytest2)
- [testthat documentation](https://testthat.r-lib.org/)
