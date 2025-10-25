# Testing Quick Reference

## Running Tests

### All Tests
```bash
R -e "devtools::test()"
# or
R -e "testthat::test_dir('tests/testthat')"
```

### Unit Tests Only
```bash
R -e "testthat::test_dir('tests/testthat', filter = '^test-(?!shinytest2)')"
```

### E2E Tests Only
```bash
R -e "testthat::test_dir('tests/testthat', filter = 'shinytest2')"
```

### Specific Test File
```bash
R -e "testthat::test_file('tests/testthat/test-power-analysis.R')"
```

### In RStudio
Press `Ctrl+Shift+T` (Windows/Linux) or `Cmd+Shift+T` (Mac)

## Test Organization

```
tests/testthat/
├── test-power-analysis.R           # Unit tests: calculations
├── test-calculations-advanced.R    # Unit tests: advanced features
├── test-shinytest2-sample-size.R   # E2E: Sample Size tab
├── test-shinytest2-mde.R           # E2E: MDE tab
├── test-shinytest2-power.R         # E2E: Power Calculation tab
└── test-shinytest2-integration.R   # E2E: Cross-functional
```

## Testing Strategy

### Three Layers

1. **Unit Tests** (testthat)
   - Test pure R functions
   - Fast, isolated, easy to debug
   - Example: `calc_effect_measures()`

2. **Server Tests** (testServer)
   - Test reactive logic
   - No browser required
   - Example: Reactive expressions

3. **E2E Tests** (shinytest2)
   - Test user workflows
   - Browser-based
   - Example: Complete tab interactions

### What We Test

✅ **Unit level:** Calculations, validations, helpers
✅ **Server level:** Reactive expressions, observers
✅ **E2E level:** User workflows, UI interactions, plots
✅ **Visual:** Screenshots for regression testing

### What We Don't Track

❌ **Code coverage percentage** - Not meaningful for Shiny apps
❌ **Line-by-line coverage** - Doesn't measure reactive behavior
❌ **Coverage metrics** - False confidence

## Quality Signals

Instead of coverage %, we track:

- ✅ All E2E tests passing
- ✅ Unit tests cover edge cases
- ✅ Visual regressions caught
- ✅ No production bugs
- ✅ Refactoring is safe

## Documentation

- **How-to:** [docs/002-how-to-guides/004-end-to-end-testing-with-shinytest2.md](docs/002-how-to-guides/004-end-to-end-testing-with-shinytest2.md)
- **Why:** [docs/004-explanation/004-testing-strategy-and-shinytest2.md](docs/004-explanation/004-testing-strategy-and-shinytest2.md)
- **Details:** [tests/README.md](tests/README.md)

## Common Tasks

### Writing a New Unit Test
```r
test_that("function handles edge case", {
  result <- my_function(edge_case_input)
  expect_equal(result, expected_output)
})
```

### Writing a New E2E Test
```r
test_that("workflow description", {
  app <- AppDriver$new(app_dir = "../../")
  app$set_inputs(input_id = value)
  app$wait_for_idle()
  app$expect_values(output = "output_id")
  app$stop()
})
```

### Debugging E2E Tests
```r
# Open visible browser
app <- AppDriver$new(app_dir = "../../", view = TRUE)

# Check current state
app$get_values()

# Take screenshot
app$get_screenshot("debug")
```

### Reviewing Snapshot Changes
```r
# Review
testthat::snapshot_review()

# Accept
testthat::snapshot_accept()
```

## CI/CD

Tests run automatically on:
- Every push
- Every pull request
- Scheduled builds (if configured)

## Troubleshooting

**E2E tests fail locally:**
- Ensure Chrome/Chromium is installed
- Check `renv::restore()` completed
- Try increasing timeouts

**Tests pass locally, fail on CI:**
- Check screen size consistency
- Verify locale settings
- Look for timing issues

**Flaky tests:**
- Use `wait_for_idle()` instead of `Sys.sleep()`
- Limit snapshot scope
- Check for non-deterministic code

---

**Last Updated:** 2025-10-25
**For detailed guides, see:** `docs/` directory
