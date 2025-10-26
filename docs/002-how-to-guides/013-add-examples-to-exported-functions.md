# How to add examples to exported functions

**Type:** How-To
**Audience:** Developers
**Last Updated:** 2025-10-26

## Overview

This guide shows you how to add runnable examples to exported functions in your R package. Examples are **required** by CRAN for all exported functions and help users understand how to use your functions.

## Prerequisites

- Familiarity with roxygen2 documentation syntax
- Functions already documented with `@param`, `@return`, and `@description`
- Understanding of which functions are exported (check NAMESPACE file)

## Goal

Add properly formatted, runnable examples to all exported functions to meet CRAN requirements.

---

## Understanding the requirement

### Why examples are required

- CRAN policy requires all exported functions to have examples
- Examples serve as executable documentation
- They verify that your function works as advertised
- Users learn by seeing working code

### What makes a good example

- **Runnable**: Must execute without errors
- **Self-contained**: Uses built-in data or simple inputs
- **Realistic**: Demonstrates actual use cases
- **Clear**: Shows typical usage patterns
- **Brief**: Usually 3-10 lines per example

---

## Step 1: Locate your function's roxygen block

Find the roxygen documentation block above your function in the R/ directory.

Example location: `R/fct_survival_ni.R`

```r
#' Calculate sample size for survival non-inferiority test
#'
#' @param hr Hazard ratio for non-inferiority margin
#' @param alpha Significance level (default 0.05)
#' @param power Statistical power (default 0.80)
#' @param p Proportion allocated to treatment group (default 0.5)
#'
#' @return List containing required events and sample size per group
#' @export
ssize_survival_ni <- function(hr, alpha = 0.05, power = 0.80, p = 0.5) {
  # function body...
}
```

---

## Step 2: Add the @examples tag

Add the `@examples` tag **after** `@export` and **before** the function definition.

### Template structure

```r
#' @examples
#' # Brief description of what this example shows
#' result <- function_name(
#'   param1 = value1,
#'   param2 = value2
#' )
#' print(result)
```

### Important formatting rules

1. **Start with `#'` prefix** - Every line in roxygen blocks needs this
2. **Use real values** - No placeholders like "your_value_here"
3. **Comments use single `#`** - Inside examples: `#' # This is a comment`
4. **Keep code simple** - Focus on common use cases
5. **Test before committing** - Examples must run without errors

---

## Step 3: Write examples for different function types

### Example 1: Statistical calculation function

For functions that perform calculations (most common in this package):

```r
#' @examples
#' # Calculate sample size for 80% power
#' result <- ssize_survival_ni(
#'   hr = 0.75,
#'   alpha = 0.05,
#'   power = 0.80,
#'   p = 0.5
#' )
#' print(result$n_per_group)
#'
#' # Higher power requires larger sample
#' result_90 <- ssize_survival_ni(
#'   hr = 0.75,
#'   power = 0.90
#' )
#' print(result_90$n_per_group)
```

### Example 2: Interpretation/formatting function

For functions that interpret or format results:

```r
#' @examples
#' # Interpret a strong non-inferiority margin
#' interpret_hr_margin(hr = 0.75)
#'
#' # Interpret a weak margin
#' interpret_hr_margin(hr = 0.95)
#'
#' # Superiority test (HR < 1 expected)
#' interpret_hr_margin(hr = 0.85, test_type = "superiority")
```

### Example 3: Shiny UI function

For functions that generate UI elements (use `\dontrun{}`):

```r
#' @examples
#' \dontrun{
#' # This function is designed for use within a Shiny app
#' ui <- fluidPage(
#'   create_app_header()
#' )
#' }
```

**When to use `\dontrun{}`:**
- Shiny UI functions (no display outside apps)
- Functions requiring external resources
- Interactive functions that need user input
- Functions that write to disk

**Note:** Always provide justification in a comment.

### Example 4: Main app launcher

For the `run_app()` function:

```r
#' @examples
#' \dontrun{
#' # Launch the application
#' run_app()
#' }
```

### Example 5: Propensity score functions

For complex statistical functions with list inputs:

```r
#' @examples
#' # Calculate overlap between two propensity score distributions
#' ps_treated <- list(a = 2, b = 5)
#' ps_control <- list(a = 5, b = 2)
#'
#' overlap <- calculate_bhattacharyya_coefficient(
#'   ps_params_treated = ps_treated,
#'   ps_params_control = ps_control
#' )
#' print(overlap)
#'
#' # Perfect overlap (same distributions)
#' same_dist <- list(a = 3, b = 3)
#' calculate_bhattacharyya_coefficient(same_dist, same_dist)
```

---

## Step 4: Add examples to all exported functions

### Current exported functions needing examples

Based on the NAMESPACE file, add examples to these 16 functions:

1. **Propensity Score Functions** (`R/fct_propensity_score.R`):
   - `calculate_bhattacharyya_coefficient()`
   - `calculate_n_li_2025()`
   - `calculate_power_li_2025()`
   - `compare_ps_methods()`
   - `estimate_ps_distribution_params()`
   - `generate_ps_sensitivity_analysis()`
   - `interpret_overlap_coefficient()`
   - `interpret_rho_squared()`

2. **Survival Non-Inferiority Functions** (`R/fct_survival_ni.R`):
   - `events_survival_ni()`
   - `interpret_hr_margin()`
   - `mde_survival_ni()`
   - `power_survival_ni()`
   - `ssize_survival_equiv()`
   - `ssize_survival_ni()`

3. **UI Function** (`R/app_ui.R`):
   - `create_app_header()`

4. **App Launcher** (location varies):
   - `run_app()`

---

## Step 5: Test your examples

### Option 1: Test during development

```r
# Load your package
devtools::load_all()

# Run examples for a specific function
devtools::run_examples("ssize_survival_ni")
```

### Option 2: Test via documentation rebuild

```r
# Regenerate documentation and check examples
devtools::document()
devtools::check(cran = TRUE)
```

### Option 3: Test individual example code

Copy the example code (without `#'` prefix) into R console and run it.

---

## Step 6: Regenerate documentation

After adding examples to your R source files:

```r
# Update man/ files and NAMESPACE
devtools::document()
```

This will:
- Regenerate .Rd files in `man/` with your examples
- Update NAMESPACE if needed
- Show warnings if examples have issues

---

## Common issues and solutions

### Issue: "Code in examples must not write to the user's home directory"

**Solution:** Use `tempdir()` for any file operations:

```r
#' @examples
#' # Save results to temporary directory
#' temp_file <- file.path(tempdir(), "results.csv")
#' write.csv(data, temp_file)
#' unlink(temp_file)  # Clean up
```

### Issue: "Examples take too long to run"

**Solution:** Use `\donttest{}` for slow examples:

```r
#' @examples
#' # Quick example
#' result <- my_function(simple_input)
#'
#' \donttest{
#' # Longer computation example
#' big_result <- my_function(complex_input)
#' }
```

### Issue: "Example requires data not available"

**Solution:** Create minimal example data inline:

```r
#' @examples
#' # Create minimal test data
#' test_params <- list(a = 2, b = 3)
#' result <- my_function(test_params)
```

### Issue: "Example fails during R CMD check"

**Solution:**
1. Test the example code interactively
2. Check for hard-coded paths or system-specific code
3. Ensure all required packages are in Imports or Suggests
4. Verify numeric precision (use `round()` if comparing floats)

---

## Verification checklist

Before committing, verify:

- [ ] All 16 exported functions have `@examples` tags
- [ ] Examples use realistic input values
- [ ] Examples run without errors locally
- [ ] `devtools::document()` completes successfully
- [ ] `devtools::check()` shows 0 errors, 0 warnings
- [ ] Examples demonstrate the main use case for each function
- [ ] Complex or slow examples use `\donttest{}`
- [ ] Interactive/Shiny examples use `\dontrun{}`

---

## Quick reference template

Copy this template for each function:

```r
#' Function title
#'
#' Function description goes here.
#'
#' @param param1 Description of param1
#' @param param2 Description of param2
#'
#' @return Description of what's returned
#' @export
#'
#' @examples
#' # Basic usage example
#' result <- function_name(
#'   param1 = typical_value1,
#'   param2 = typical_value2
#' )
#' print(result)
#'
#' # Alternative usage showing different scenario
#' result2 <- function_name(param1 = different_value)
#' print(result2)
function_name <- function(param1, param2) {
  # Function implementation
}
```

---

## Batch workflow for adding examples

For efficiency when adding examples to many functions:

1. **List all functions needing examples:**
   ```bash
   grep "^export(" NAMESPACE | sed 's/export(//' | sed 's/)//'
   ```

2. **Open each source file in R/:**
   - Start with one category (e.g., all survival functions)
   - Add examples to all functions in that file
   - Test with `devtools::run_examples()`

3. **Document and check:**
   ```r
   devtools::document()
   devtools::check()
   ```

4. **Commit each file category separately:**
   ```bash
   git add R/fct_survival_ni.R man/ssize_survival_ni.Rd man/power_survival_ni.Rd ...
   git commit -m "docs: add examples to survival non-inferiority functions"
   ```

---

## Resources

- [Writing R Extensions - Documentation](https://cran.r-project.org/doc/manuals/r-release/R-exts.html#Documenting-functions)
- [roxygen2 documentation](https://roxygen2.r-lib.org/articles/rd.html)
- [R Packages (2e) - Documentation](https://r-pkgs.org/man.html)

---

**Related Documentation:**
- `docs/003-reference/` - Function reference documentation
- `CLAUDE.md` - Project documentation guidelines

**Next Steps:**
After adding examples, proceed to:
- Run `devtools::check(cran = TRUE)` locally
- Test on win-builder with `devtools::check_win_devel()`
- Review `cran-comments.md` before submission
