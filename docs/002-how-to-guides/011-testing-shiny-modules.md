# How to test Shiny modules

**Type:** How-To Guide
**Audience:** Developers
**Last Updated:** 2025-10-25

## Overview

This guide shows you how to write comprehensive tests for Shiny modules in a golem-based package structure. Testing modules is critical for maintaining application quality and catching bugs before they reach production.

You'll learn how to:
- Test business logic functions (`fct_*.R`)
- Test utility functions (`utils_*.R`)
- Test module server logic with testServer()
- Mock reactivity and dependencies
- Achieve good test coverage
- Run tests efficiently during development

---

## Testing Philosophy

### Test Pyramid for Shiny Apps

```
                    /\
                   /  \
                  /    \
                 / E2E  \    ← End-to-End (few, slow, brittle)
                /________\
               /          \
              /Integration \  ← Module Integration (some, moderate)
             /______________\
            /                \
           /   Unit Tests     \ ← Business Logic (many, fast, reliable)
          /____________________\
```

**Our Testing Strategy:**

1. **Many Unit Tests** (80% of tests)
   - Test `fct_*.R` business logic functions
   - Test `utils_*.R` helper functions
   - Fast, reliable, easy to write
   - No Shiny reactivity involved

2. **Some Integration Tests** (15% of tests)
   - Test module server functions with `testServer()`
   - Test reactive logic
   - Mock external dependencies
   - Moderate complexity

3. **Few E2E Tests** (5% of tests)
   - Test critical user workflows
   - Use shinytest2 for full app testing
   - Slow but valuable for key paths
   - Not covered in this guide (see shinytest2 docs)

---

## Prerequisites

### Required Packages

Your golem app should already have these in `DESCRIPTION`:

```
Suggests:
    testthat (>= 3.0.0),
    shiny,
    mockery
```

If not, add them:

```r
usethis::use_package("testthat", type = "Suggests")
usethis::use_package("mockery", type = "Suggests")
```

### Test Infrastructure

When you ran `golem::create_golem()`, it set up:

```
tests/
├── testthat/
│   └── test-*.R files go here
└── testthat.R  # Test runner configuration
```

The `tests/testthat.R` file should contain:

```r
library(testthat)
library(powerAnalysisTool)

test_check("powerAnalysisTool")
```

---

## Part 1: Testing Business Logic Functions

These are the easiest and most important tests to write.

### Example: Testing a Calculation Function

Let's test a function from `R/fct_effect_measures.R`:

**Function to test:**

```r
#' Calculate Effect Measures
#'
#' @param p1 Proportion in group 1 (0-1)
#' @param p2 Proportion in group 2 (0-1)
#' @return List with RR, OR, RD
#' @export
calc_effect_measures <- function(p1, p2) {
  # Input validation
  if (!is.numeric(p1) || !is.numeric(p2)) {
    stop("Both p1 and p2 must be numeric")
  }
  if (p1 < 0 || p1 > 1 || p2 < 0 || p2 > 1) {
    stop("Proportions must be between 0 and 1")
  }

  # Calculate measures
  RR <- if (p2 == 0) NA_real_ else p1 / p2
  OR <- if (p2 == 0 || p1 == 1 || p2 == 1) {
    NA_real_
  } else {
    (p1 / (1 - p1)) / (p2 / (1 - p2))
  }
  RD <- p1 - p2

  list(RR = RR, OR = OR, RD = RD)
}
```

**Test file:** `tests/testthat/test-fct_effect_measures.R`

```r
test_that("calc_effect_measures works with valid proportions", {
  result <- calc_effect_measures(0.3, 0.2)

  expect_type(result, "list")
  expect_named(result, c("RR", "OR", "RD"))

  # Check calculations
  expect_equal(result$RR, 1.5)
  expect_equal(result$RD, 0.1)
  expect_equal(result$OR, (0.3/0.7) / (0.2/0.8), tolerance = 0.001)
})

test_that("calc_effect_measures handles edge cases", {
  # p2 = 0 (division by zero)
  result <- calc_effect_measures(0.5, 0)
  expect_true(is.na(result$RR))
  expect_true(is.na(result$OR))
  expect_equal(result$RD, 0.5)

  # p1 = 0
  result <- calc_effect_measures(0, 0.3)
  expect_equal(result$RR, 0)
  expect_true(is.na(result$OR))
  expect_equal(result$RD, -0.3)

  # p1 = p2
  result <- calc_effect_measures(0.5, 0.5)
  expect_equal(result$RR, 1)
  expect_equal(result$OR, 1)
  expect_equal(result$RD, 0)
})

test_that("calc_effect_measures validates inputs", {
  expect_error(
    calc_effect_measures("not a number", 0.5),
    "must be numeric"
  )

  expect_error(
    calc_effect_measures(0.5, "not a number"),
    "must be numeric"
  )

  expect_error(
    calc_effect_measures(-0.1, 0.5),
    "between 0 and 1"
  )

  expect_error(
    calc_effect_measures(0.5, 1.5),
    "between 0 and 1"
  )
})
```

### Best Practices for Business Logic Tests

**✅ DO:**

- Test happy path (normal valid inputs)
- Test edge cases (zeros, ones, boundaries)
- Test error cases (invalid inputs)
- Use descriptive test names
- Group related tests in one file
- Use `expect_equal()` with `tolerance` for floating point
- Test one behavior per test

**❌ DON'T:**

- Test Shiny reactivity in these tests
- Test multiple unrelated functions in one test
- Use hard-coded magic numbers without comments
- Skip edge case testing
- Ignore warnings about floating point comparison

### Running Business Logic Tests

```r
# Run all tests
devtools::test()

# Run one file
devtools::test_file("tests/testthat/test-fct_effect_measures.R")

# Run with coverage
covr::package_coverage()
```

---

## Part 2: Testing Utility Functions

Utility functions are similar to business logic but often involve formatting or UI elements.

### Example: Testing a Text Formatting Function

**Function to test:** `R/utils_text.R`

```r
#' Format P-Value
#'
#' @param p Numeric p-value
#' @return Character string
#' @noRd
format_p_value <- function(p) {
  if (!is.numeric(p) || length(p) != 1) {
    stop("p must be a single numeric value")
  }
  if (is.na(p)) return("NA")
  if (p < 0.001) return("< 0.001")
  if (p >= 0.999) return("> 0.999")
  sprintf("%.3f", p)
}
```

**Test file:** `tests/testthat/test-utils_text.R`

```r
test_that("format_p_value formats correctly", {
  expect_equal(format_p_value(0.05), "0.050")
  expect_equal(format_p_value(0.123456), "0.123")
  expect_equal(format_p_value(0.0001), "< 0.001")
  expect_equal(format_p_value(0.9999), "> 0.999")
})

test_that("format_p_value handles edge cases", {
  expect_equal(format_p_value(0), "< 0.001")
  expect_equal(format_p_value(1), "> 0.999")
  expect_equal(format_p_value(NA_real_), "NA")
})

test_that("format_p_value validates inputs", {
  expect_error(format_p_value("not numeric"), "must be a single numeric")
  expect_error(format_p_value(c(0.05, 0.1)), "must be a single numeric")
})
```

### Testing UI Helper Functions

For functions that return HTML/Shiny tags:

**Function to test:** `R/utils_ui.R`

```r
#' Create Info Icon with Tooltip
#'
#' @param text Tooltip text
#' @return Shiny tag
#' @noRd
info_icon <- function(text) {
  shiny::tags$span(
    class = "info-icon",
    title = text,
    shiny::icon("info-circle")
  )
}
```

**Test file:** `tests/testthat/test-utils_ui.R`

```r
test_that("info_icon creates correct HTML structure", {
  result <- info_icon("Help text")

  expect_s3_class(result, "shiny.tag")
  expect_equal(result$name, "span")
  expect_equal(result$attribs$class, "info-icon")
  expect_equal(result$attribs$title, "Help text")

  # Check icon is present
  expect_length(result$children, 1)
  icon_tag <- result$children[[1]]
  expect_s3_class(icon_tag, "shiny.tag")
})

test_that("info_icon escapes HTML in text", {
  result <- info_icon("<script>alert('xss')</script>")
  html <- as.character(result)
  expect_false(grepl("<script>", html, fixed = TRUE))
})
```

---

## Part 3: Testing Module Server Logic

This is where it gets more interesting. We use `shiny::testServer()` to test reactive logic.

### Understanding testServer()

`testServer()` creates a fake Shiny session and lets you:
- Set input values
- Access reactive values
- Trigger observers
- Check output values
- Mock external dependencies

### Example: Testing a Simple Module

**Module to test:** `R/mod_01_sample_size_two_group.R` (simplified)

```r
mod_01_sample_size_two_group_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive calculation
    sample_size <- reactive({
      req(input$p1, input$p2, input$alpha, input$power)

      # Validate inputs
      if (input$p1 <= 0 || input$p1 >= 1) return(NULL)
      if (input$p2 <= 0 || input$p2 >= 1) return(NULL)
      if (abs(input$p1 - input$p2) < 0.01) return(NULL)

      # Calculate
      fct_calculate_sample_size_two_group(
        p1 = input$p1,
        p2 = input$p2,
        alpha = input$alpha,
        power = input$power,
        alternative = input$alternative
      )
    })

    # Output
    output$result_text <- renderText({
      result <- sample_size()
      if (is.null(result)) return("Invalid inputs")

      sprintf(
        "Required sample size: %d per group (total: %d)",
        result$n_per_group,
        result$n_total
      )
    })

    return(sample_size)
  })
}
```

**Test file:** `tests/testthat/test-mod_01_sample_size_two_group.R`

```r
test_that("mod_01_sample_size_two_group calculates correctly", {
  testServer(mod_01_sample_size_two_group_server, {
    # Set inputs
    session$setInputs(
      p1 = 0.3,
      p2 = 0.2,
      alpha = 0.05,
      power = 0.8,
      alternative = "two.sided"
    )

    # Get result
    result <- sample_size()

    # Verify
    expect_type(result, "list")
    expect_true("n_per_group" %in% names(result))
    expect_true("n_total" %in% names(result))
    expect_true(result$n_per_group > 0)
    expect_equal(result$n_total, result$n_per_group * 2)

    # Check output text
    expect_match(output$result_text, "Required sample size")
    expect_match(output$result_text, "per group")
  })
})

test_that("mod_01_sample_size_two_group handles invalid inputs", {
  testServer(mod_01_sample_size_two_group_server, {
    # p1 out of range
    session$setInputs(
      p1 = 1.5,
      p2 = 0.2,
      alpha = 0.05,
      power = 0.8,
      alternative = "two.sided"
    )

    result <- sample_size()
    expect_null(result)
    expect_match(output$result_text, "Invalid inputs")

    # p1 and p2 too close
    session$setInputs(
      p1 = 0.201,
      p2 = 0.200,
      alpha = 0.05,
      power = 0.8,
      alternative = "two.sided"
    )

    result <- sample_size()
    expect_null(result)
  })
})

test_that("mod_01_sample_size_two_group updates on input change", {
  testServer(mod_01_sample_size_two_group_server, {
    # Initial inputs
    session$setInputs(
      p1 = 0.3,
      p2 = 0.2,
      alpha = 0.05,
      power = 0.8,
      alternative = "two.sided"
    )

    result1 <- sample_size()

    # Change power
    session$setInputs(power = 0.9)

    result2 <- sample_size()

    # Higher power requires larger sample size
    expect_gt(result2$n_per_group, result1$n_per_group)
  })
})
```

### Best Practices for Module Server Tests

**✅ DO:**

- Use `session$setInputs()` to set multiple inputs at once
- Test reactivity updates (change inputs, check outputs change)
- Test validation logic
- Test return values from the module
- Use descriptive test names that describe the scenario

**❌ DON'T:**

- Test business logic here (test it separately in `fct_*.R` tests)
- Make tests depend on specific calculation results (mock the fct_ function)
- Test UI rendering in detail (that's for E2E tests)
- Use real external data sources (mock them)

---

## Part 4: Mocking Dependencies

When a module calls external functions or APIs, mock them to isolate your test.

### Why Mock?

- Tests run faster (no real API calls)
- Tests are deterministic (no flaky network issues)
- Tests are isolated (don't depend on external state)
- Can test error conditions easily

### Example: Mocking a Business Logic Function

**Module with dependency:**

```r
mod_analysis_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    result <- reactive({
      # This calls an expensive calculation function
      fct_run_power_analysis(
        n = input$n,
        effect_size = input$effect_size,
        alpha = input$alpha
      )
    })

    output$power <- renderText({
      sprintf("Power: %.3f", result()$power)
    })
  })
}
```

**Test with mocking:**

```r
library(mockery)

test_that("mod_analysis_server displays mocked results", {
  # Create a mock function
  mock_power_analysis <- mock(
    list(power = 0.85, effect_size = 0.5)
  )

  # Replace the real function with the mock
  stub(
    mod_analysis_server,
    "fct_run_power_analysis",
    mock_power_analysis
  )

  testServer(mod_analysis_server, {
    session$setInputs(
      n = 100,
      effect_size = 0.5,
      alpha = 0.05
    )

    # Verify mock was called with correct args
    expect_called(mock_power_analysis, 1)
    expect_args(
      mock_power_analysis,
      1,
      n = 100,
      effect_size = 0.5,
      alpha = 0.05
    )

    # Check output uses mocked value
    expect_match(output$power, "Power: 0.850")
  })
})
```

### Mocking External Data Sources

**Module that reads data:**

```r
mod_data_loader_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    data <- reactive({
      req(input$file_path)
      utils_read_csv(input$file_path)
    })

    output$preview <- renderTable({
      head(data())
    })
  })
}
```

**Test with mocked data:**

```r
test_that("mod_data_loader_server displays data preview", {
  # Mock data frame
  mock_data <- data.frame(
    x = 1:5,
    y = letters[1:5]
  )

  # Mock the read function
  mock_read <- mock(mock_data)
  stub(mod_data_loader_server, "utils_read_csv", mock_read)

  testServer(mod_data_loader_server, {
    session$setInputs(file_path = "/fake/path.csv")

    # Verify correct data loaded
    expect_identical(data(), mock_data)

    # Verify function was called with correct path
    expect_args(mock_read, 1, "/fake/path.csv")
  })
})
```

### Mocking Reactive Values from Other Modules

Sometimes modules communicate through reactive values:

```r
# Module A provides data
mod_a_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    data <- reactive({ mtcars })
    return(data)
  })
}

# Module B uses data from Module A
mod_b_server <- function(id, data_from_a) {
  moduleServer(id, function(input, output, session) {
    output$summary <- renderPrint({
      summary(data_from_a())
    })
  })
}
```

**Testing Module B:**

```r
test_that("mod_b_server uses data from module A", {
  # Create a mock reactive
  mock_data <- reactive({
    data.frame(x = 1:10, y = 11:20)
  })

  testServer(mod_b_server, args = list(data_from_a = mock_data), {
    # Output should use mocked data
    output_text <- output$summary
    expect_match(output_text, "x")
    expect_match(output_text, "y")
  })
})
```

---

## Part 5: Test Coverage

### Measuring Coverage

```r
# Install covr if needed
install.packages("covr")

# Generate coverage report
coverage <- covr::package_coverage()
print(coverage)

# View in browser
covr::report(coverage)
```

### Coverage Targets

**Recommended minimum coverage:**

- **Business logic (`fct_*.R`)**: 90%+ coverage
- **Utilities (`utils_*.R`)**: 80%+ coverage
- **Module servers (`mod_*.R`)**: 70%+ coverage
- **Overall package**: 80%+ coverage

### What to Focus On

**High priority (must test):**
- Statistical calculations
- Data validation
- Error handling
- Critical user workflows

**Medium priority (should test):**
- UI helper functions
- Text formatting
- Plotting functions
- Module reactivity

**Low priority (optional):**
- Simple getter/setter functions
- Trivial wrappers
- Auto-generated code

### Coverage Report Example

```r
> covr::package_coverage()

powerAnalysisTool Coverage: 82.45%
R/fct_effect_measures.R: 95.00%
R/fct_sample_size.R: 88.50%
R/utils_text.R: 100.00%
R/utils_plot.R: 65.00%  # ⚠️ Need more tests
R/mod_01_sample_size_two_group.R: 78.00%
```

### Improving Low Coverage

1. **Identify untested lines:**
   ```r
   # View detailed report
   covr::report()
   # Red lines = not covered
   ```

2. **Write targeted tests:**
   ```r
   # Add tests for the red lines
   test_that("utils_plot handles missing data", {
     result <- plot_power_curve(data_with_na)
     expect_s3_class(result, "ggplot")
   })
   ```

3. **Check coverage again:**
   ```r
   covr::package_coverage()
   ```

---

## Part 6: Testing Workflow

### During Development

**Test-Driven Development (TDD) approach:**

1. Write a failing test
2. Write minimal code to pass
3. Refactor
4. Repeat

**Example TDD session:**

```r
# 1. Write failing test
test_that("calc_odds_ratio works", {
  expect_equal(calc_odds_ratio(0.3, 0.2), 1.71, tolerance = 0.01)
})

# Run test - it fails (function doesn't exist yet)
devtools::test_file("tests/testthat/test-fct_effect_measures.R")
# ❌ Error: could not find function "calc_odds_ratio"

# 2. Write minimal implementation
calc_odds_ratio <- function(p1, p2) {
  (p1 / (1 - p1)) / (p2 / (1 - p2))
}

# Run test again
devtools::test_file("tests/testthat/test-fct_effect_measures.R")
# ✅ Test passed!

# 3. Add input validation
calc_odds_ratio <- function(p1, p2) {
  if (!is.numeric(p1) || !is.numeric(p2)) {
    stop("Inputs must be numeric")
  }
  if (p1 < 0 || p1 > 1 || p2 < 0 || p2 > 1) {
    stop("Proportions must be between 0 and 1")
  }
  (p1 / (1 - p1)) / (p2 / (1 - p2))
}

# 4. Add tests for validation
test_that("calc_odds_ratio validates inputs", {
  expect_error(calc_odds_ratio(-0.1, 0.5))
  expect_error(calc_odds_ratio("text", 0.5))
})
```

### Before Committing

**Pre-commit checklist:**

```r
# 1. Run all tests
devtools::test()

# 2. Check for warnings
devtools::check()

# 3. Verify coverage hasn't dropped
coverage <- covr::package_coverage()
print(coverage)

# 4. Run R CMD check (full validation)
devtools::check()
```

### Continuous Integration

**GitHub Actions workflow** (`.github/workflows/R-CMD-check.yaml`):

```yaml
on:
  push:
    branches: [main, master]
  pull_request:
    branches: [main, master]

name: R-CMD-check

jobs:
  R-CMD-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          use-public-rspm: true

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck, any::covr

      - name: Run tests
        run: |
          devtools::test()
        shell: Rscript {0}

      - name: Check coverage
        run: |
          covr::codecov()
        shell: Rscript {0}
```

---

## Part 7: Common Testing Patterns

### Pattern 1: Testing Input Validation

**Template:**

```r
test_that("function_name validates inputs", {
  # Test wrong type
  expect_error(function_name("string"), "must be numeric")

  # Test out of range
  expect_error(function_name(-1), "must be positive")

  # Test NULL
  expect_error(function_name(NULL), "cannot be NULL")

  # Test NA
  expect_error(function_name(NA), "cannot be NA")

  # Test empty vector
  expect_error(function_name(numeric(0)), "cannot be empty")
})
```

### Pattern 2: Testing Calculations

**Template:**

```r
test_that("function_name calculates correctly", {
  # Known result (hand-calculated or from reference)
  result <- function_name(input1, input2)
  expect_equal(result, 42.0, tolerance = 0.001)

  # Mathematical property (e.g., symmetry)
  result1 <- function_name(a, b)
  result2 <- function_name(b, a)
  expect_equal(result1, result2)

  # Edge case (e.g., zero)
  result <- function_name(0, 5)
  expect_equal(result, 0)

  # Boundary condition
  result <- function_name(1, 1)
  expect_equal(result, 1)
})
```

### Pattern 3: Testing Reactive Updates

**Template:**

```r
test_that("module updates when inputs change", {
  testServer(mod_example_server, {
    # Set initial inputs
    session$setInputs(x = 1, y = 2)
    initial_result <- output$result

    # Change an input
    session$setInputs(x = 10)
    updated_result <- output$result

    # Verify output changed
    expect_false(identical(initial_result, updated_result))

    # Verify direction of change
    expect_gt(as.numeric(updated_result), as.numeric(initial_result))
  })
})
```

### Pattern 4: Testing Error Messages

**Template:**

```r
test_that("function_name provides helpful error messages", {
  expect_error(
    function_name(invalid_input),
    regexp = "expected behavior",
    class = "specific_error_class"  # optional
  )

  # Verify error message is informative
  err <- tryCatch(
    function_name(invalid_input),
    error = function(e) e$message
  )
  expect_match(err, "what went wrong")
  expect_match(err, "what to do instead")
})
```

### Pattern 5: Testing Plots

**Template:**

```r
test_that("plot_function creates valid ggplot", {
  plot <- plot_function(data)

  # Check it's a ggplot object
  expect_s3_class(plot, "gg")
  expect_s3_class(plot, "ggplot")

  # Check layers (optional)
  expect_equal(length(plot$layers), 2)

  # Check data is used (optional)
  expect_equal(nrow(plot$data), nrow(data))

  # Check labels (optional)
  expect_equal(plot$labels$x, "Expected X Label")
  expect_equal(plot$labels$y, "Expected Y Label")
})

test_that("plot_function handles edge cases", {
  # Empty data
  expect_error(plot_function(data.frame()), "cannot be empty")

  # Missing columns
  expect_error(
    plot_function(data.frame(x = 1:10)),
    "missing required column"
  )

  # All NA
  data_na <- data.frame(x = rep(NA, 10), y = rep(NA, 10))
  expect_error(plot_function(data_na), "cannot be all NA")
})
```

---

## Part 8: Advanced Topics

### Testing Asynchronous Operations

If your module uses `promises` or async operations:

```r
library(promises)

test_that("async module handles promises", {
  testServer(mod_async_server, {
    session$setInputs(trigger = TRUE)

    # Wait for promise to resolve
    later::run_now()

    # Check result
    expect_equal(output$result, "completed")
  })
})
```

### Testing Modules with File Uploads

```r
test_that("module handles file upload", {
  # Create a temporary file
  temp_file <- tempfile(fileext = ".csv")
  write.csv(mtcars, temp_file, row.names = FALSE)

  testServer(mod_file_upload_server, {
    # Mock file input
    session$setInputs(
      file = list(
        name = "test.csv",
        size = file.size(temp_file),
        type = "text/csv",
        datapath = temp_file
      )
    )

    # Check data was loaded
    expect_equal(nrow(data()), nrow(mtcars))
  })

  # Clean up
  unlink(temp_file)
})
```

### Testing Modules with Downloads

```r
test_that("module generates download correctly", {
  testServer(mod_download_server, {
    # Trigger download preparation
    session$setInputs(prepare = TRUE)

    # Check download handler exists
    expect_true("download_button" %in% names(output))

    # Test download content (advanced)
    # This requires more setup with shinytest2
  })
})
```

### Testing with Real External Data (Integration Tests)

Sometimes you want integration tests with real data:

```r
test_that("module works with real dataset", {
  skip_if_not(file.exists("data/real_data.csv"), "Real data not available")
  skip_on_cran()  # Don't run on CRAN
  skip_on_ci()    # Don't run on CI

  testServer(mod_analysis_server, {
    session$setInputs(
      data_source = "data/real_data.csv",
      run_analysis = TRUE
    )

    # This is slow, so we mark it to be skipped usually
    result <- analysis_result()
    expect_s3_class(result, "data.frame")
  })
})
```

---

## Part 9: Troubleshooting Tests

### Common Issues

#### Issue 1: "could not find function 'req'"

**Problem:** Shiny functions not available in test

**Solution:** Load shiny in test file

```r
library(shiny)

test_that("module uses req()", {
  testServer(mod_example_server, {
    # Now req() is available
    session$setInputs(x = NULL)
    expect_null(result())
  })
})
```

#### Issue 2: "object of type 'closure' is not subsettable"

**Problem:** Trying to access reactive value without calling it

**Solution:** Call reactive as a function

```r
# ❌ Wrong
result <- my_reactive
expect_equal(result$value, 10)

# ✅ Correct
result <- my_reactive()
expect_equal(result$value, 10)
```

#### Issue 3: Tests pass individually but fail together

**Problem:** Tests have side effects or shared state

**Solution:** Clean up after each test

```r
test_that("test 1", {
  options(my_option = "value1")
  # ... test code ...
  options(my_option = NULL)  # Clean up
})

test_that("test 2", {
  # Won't be affected by test 1
})
```

#### Issue 4: Mock not working

**Problem:** Function not being mocked correctly

**Solution:** Check the namespace and function name

```r
# If function is from another package
stub(
  my_module,
  "package::function_name",
  mock_function
)

# If function is from your package
stub(
  my_module,
  "powerAnalysisTool::function_name",
  mock_function
)
```

#### Issue 5: "Error: Can't access reactive value outside reactive context"

**Problem:** Trying to call reactive outside testServer()

**Solution:** Call reactive inside testServer() or make it not reactive

```r
# ❌ Wrong
testServer(mod_example_server, {
  result <- my_reactive()
})
expect_equal(result, 10)  # Outside testServer!

# ✅ Correct
testServer(mod_example_server, {
  result <- my_reactive()
  expect_equal(result, 10)  # Inside testServer
})
```

---

## Part 10: Testing Checklist

Use this checklist when writing tests for a new module:

### Business Logic Functions (`fct_*.R`)

- [ ] Test with valid inputs (happy path)
- [ ] Test with edge cases (zeros, boundaries, extremes)
- [ ] Test with invalid inputs (wrong type, out of range, NULL, NA)
- [ ] Test mathematical properties (symmetry, identity, etc.)
- [ ] Test error messages are informative
- [ ] Test return value structure
- [ ] Coverage > 90%

### Utility Functions (`utils_*.R`)

- [ ] Test with typical inputs
- [ ] Test with edge cases
- [ ] Test with invalid inputs
- [ ] Test return value format
- [ ] Coverage > 80%

### Module Server (`mod_*.R`)

- [ ] Test with valid inputs
- [ ] Test input validation
- [ ] Test reactive updates
- [ ] Test output rendering
- [ ] Test module return value
- [ ] Mock external dependencies
- [ ] Coverage > 70%

### General

- [ ] All tests pass: `devtools::test()`
- [ ] No warnings: `devtools::check()`
- [ ] Coverage meets targets
- [ ] Test names are descriptive
- [ ] Tests are independent (no shared state)
- [ ] Fast tests (< 1s per test ideally)
- [ ] Tests document expected behavior

---

## Quick Reference

### Running Tests

```r
# All tests
devtools::test()

# One file
devtools::test_file("tests/testthat/test-fct_example.R")

# One test
devtools::test_file(
  "tests/testthat/test-fct_example.R",
  filter = "calculates correctly"
)

# With coverage
covr::package_coverage()

# Coverage report in browser
covr::report()
```

### Common Expectations

```r
# Equality
expect_equal(x, y)
expect_equal(x, y, tolerance = 0.001)
expect_identical(x, y)

# Type checks
expect_type(x, "list")
expect_s3_class(x, "data.frame")
expect_true(is.numeric(x))

# Errors and warnings
expect_error(code, "error message")
expect_warning(code, "warning message")
expect_silent(code)

# Values
expect_null(x)
expect_true(x)
expect_false(x)
expect_length(x, 10)
expect_named(x, c("a", "b", "c"))

# Comparisons
expect_gt(x, y)  # greater than
expect_lt(x, y)  # less than
expect_gte(x, y) # greater than or equal
expect_lte(x, y) # less than or equal

# Matching
expect_match(x, "pattern")
expect_match(x, "^starts with")
expect_match(x, "ends with$")
```

### Test Structure Template

```r
# tests/testthat/test-example.R

# Setup (if needed)
example_data <- data.frame(x = 1:10, y = 11:20)

test_that("function does X correctly", {
  result <- function_name(example_data)
  expect_equal(result, expected_value)
})

test_that("function handles edge case Y", {
  result <- function_name(edge_case_input)
  expect_true(is.valid(result))
})

test_that("function validates input Z", {
  expect_error(function_name(invalid_input), "helpful message")
})

# Cleanup (if needed)
rm(example_data)
```

---

## Next Steps

After reading this guide:

1. **Start with business logic**: Write tests for one `fct_*.R` file
2. **Add utility tests**: Test one `utils_*.R` file
3. **Try module testing**: Test one simple module with `testServer()`
4. **Check coverage**: Run `covr::package_coverage()` and aim for 80%
5. **Set up CI**: Add GitHub Actions to run tests automatically
6. **Make it a habit**: Write tests as you write code (TDD)

**Related Documentation:**
- [How to add a new analysis type](008-add-new-analysis-type.md) - Shows where to add tests in the workflow
- [How to reorganize as R package with golem](009-reorganize-as-r-package-with-golem.md) - Testing setup during migration
- [Package structure reference](../003-reference/002-package-structure-reference.md) - Where test files go

**External References:**
- [testthat documentation](https://testthat.r-lib.org/)
- [Mastering Shiny - Testing](https://mastering-shiny.org/scaling-testing.html)
- [Engineering Production-Grade Shiny Apps - Testing](https://engineering-shiny.org/testing.html)
- [shiny::testServer documentation](https://shiny.rstudio.com/reference/shiny/latest/testServer.html)
- [mockery package](https://github.com/r-lib/mockery)
- [covr package](https://covr.r-lib.org/)

---

**Last Updated:** 2025-10-25
**Version:** 1.0
**Status:** Complete
