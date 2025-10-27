# Input Validation & Sanitization Implementation - Handoff Document

**Type:** Quality Report
**Audience:** Developers
**Last Updated:** 2025-10-27
**Status:** Phase 1 Complete - 7 modules remaining

## Overview

This document provides a handoff for continuing the implementation of comprehensive input validation and sanitization across all analysis modules, following golem framework and Shiny best practices.

---

## What Has Been Completed (Phase 1)

### 1. Foundation: Core Validation Utilities ✅

**File Created:** `R/utils_validation.R`

**Functions Implemented:**
- `validate_numeric_input()` - Server-side numeric validation with range checking
- `validate_choice_input()` - Allowlist-based categorical input validation
- `validate_proportion_input()` - Specialized 0-100% validation
- `validate_integer_input()` - Whole number validation with range checking
- `validation_result()` - Standardized validation result structure
- `validate_cross_field()` - Multi-input logical validation helper
- `safe_numeric()` - Safe coercion with defaults

**Why This Matters:**
- Prevents client-side validation bypass (security)
- Provides consistent error messages
- Enables proper type checking before calculations
- Supports production error logging

---

### 2. Production Error Sanitization ✅

**File Modified:** `R/run_app.R`

**Changes:**
- Added environment-based error sanitization
- Production mode (`R_CONFIG_ACTIVE=production`) enables `shiny.sanitize.errors = TRUE`
- Development mode shows full error messages for debugging
- Logging of environment configuration

**Configuration:**
```r
# Set environment variable before deploying
Sys.setenv(R_CONFIG_ACTIVE = "production")
```

**Why This Matters:**
- Prevents information leakage in production deployments
- Protects application internals from exposure
- Maintains debugging capability in development

---

### 3. Input Update Optimization ✅

**File Modified:** `R/utils_ui_inputs.R`

**Function Enhanced:** `create_numeric_input_with_tooltip()`

**Changes:**
- Added `updateOn = "blur"` parameter (default)
- Updates documentation for new parameter
- Affects ALL 30+ numeric inputs across the app

**Behavior:**
- `"blur"` - Updates when user leaves input field (default, reduces reactive churn)
- `"change"` - Updates immediately on every keystroke (legacy behavior)

**Why This Matters:**
- Reduces unnecessary recalculations while user is typing
- Improves app performance and responsiveness
- Reduces server load

---

### 4. Complete Example: Single Proportion Module ✅

**Files Created:**
- `R/fct_single_proportion.R` - Validation function

**Files Modified:**
- `R/mod_01_single_proportion.R` - Complete refactor
- `R/app_server.R` - Updated validation logic for tabs

**Refactoring Applied:**

#### A. Module-Level Validation (`fct_single_proportion.R`)

Created `validate_single_proportion_inputs()` with:
- Input allowlisting for calculation modes
- Range validation for all numeric inputs
- Cross-field validation (proportions must differ)
- Effect size warnings (small effects need large samples)
- Discontinuation rate warnings (> 50% flagged)
- Structured validation results (errors/warnings/notes)

#### B. Server-Side Input Processing (`mod_01_single_proportion.R`)

**Pattern Implemented:**
```r
# 1. Define allowlists
VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
VALID_POWER <- c("70", "80", "90", "95")
VALID_CALC_MODES <- c("calc_n", "calc_effect")

# 2. Create raw reactive with req() guards
inputs_raw <- reactive({
  req(input$power_n)  # Fast fail if NULL
  req(input$power_p)
  # ... etc

  # 3. Validate and sanitize each input
  tryCatch({
    list(
      power_n = validate_numeric_input(
        input$power_n,
        "Sample size",
        min = 1,
        max = 1e7
      ),
      power_alpha = as.numeric(validate_choice_input(
        input$power_alpha,
        VALID_ALPHA,
        "Significance level"
      )),
      # ... etc
    )
  }, error = function(e) {
    # Log in production, return safe defaults
    if (golem::app_prod()) {
      logger::log_warn("Input validation failed", error = e$message)
    }
    list(power_n = 230, power_p = 1, ...)  # Safe defaults
  })
})

# 4. Apply debouncing
inputs <- inputs_raw %>% debounce(500)
```

**Benefits:**
- `req()` prevents execution until inputs available (performance)
- Type validation catches manipulation attempts (security)
- Allowlisting prevents invalid categorical choices (security)
- Debouncing reduces reactive churn (performance)
- Graceful degradation with safe defaults (robustness)
- Production logging for debugging (observability)

#### C. App-Level Validation (`app_server.R`)

**Pattern Implemented:**
```r
if (page == "power_single") {
  req(tab1_vals$inputs())  # Guard against NULL
  tab1_inputs <- tab1_vals$inputs()

  # Use dedicated validation function
  validation <- validate_single_proportion_inputs(
    n = tab1_inputs$power_n,
    p = tab1_inputs$power_p,
    # ... etc
    calc_mode = "power"
  )

  # Block execution on errors
  if (!validation$valid) {
    validate(need(FALSE, paste(validation$errors, collapse = "\n")))
  }

  # Show warnings as non-blocking notifications
  if (length(validation$warnings) > 0) {
    showNotification(
      paste(validation$warnings, collapse = "\n"),
      type = "warning",
      duration = 5
    )
  }
}
```

**Benefits:**
- Separates validation from UI logic (maintainability)
- Errors block execution (data integrity)
- Warnings inform without blocking (user experience)
- Notes provide additional context (user education)

---

## Remaining Work (Phase 2)

### Modules to Refactor (7 remaining)

Apply the **same pattern** as `mod_01_single_proportion.R` to:

1. **`R/mod_02_two_group.R`** - Two-Group Comparison
2. **`R/mod_03_survival.R`** - Survival Analysis
3. **`R/mod_04_correlation.R`** - Correlation Analysis
4. **`R/mod_05_matched_case_control.R`** - Matched Case-Control
5. **`R/mod_06_time_to_event.R`** - Time-to-Event NI/Equivalence
6. **`R/mod_07_continuous_outcome.R`** - Continuous Outcome
7. **`R/mod_multiple_testing.R`** - Multiple Testing (already has validator, needs refactoring)

Additionally, these modules already have validators but need module refactoring:
- **`R/mod_multi_bias.R`** - Multi-Bias Sensitivity
- **`R/mod_evalue.R`** - E-Value Calculator
- **`R/mod_clustering.R`** - Clustering adjustment

---

## Step-by-Step Refactoring Guide

For each module, follow these steps:

### Step 1: Create Validation Function

**File:** `R/fct_<module_name>.R`

**Template:**
```r
#' Validate <Module Name> Inputs
#'
#' @param ... Module-specific parameters
#' @return Validation result list
#' @export
validate_<module>_inputs <- function(...) {
  messages <- character(0)
  valid <- TRUE

  # Define allowlists
  VALID_CHOICES <- c(...)

  # Validate categorical inputs
  if (!choice %in% VALID_CHOICES) {
    messages <- c(messages, "ERROR: Invalid choice")
    valid <- FALSE
  }

  # Validate numeric inputs
  if (is.null(n) || is.na(n) || n <= 0) {
    messages <- c(messages, "ERROR: Sample size must be positive")
    valid <- FALSE
  }

  # Add warnings for edge cases
  if (n < 10) {
    messages <- c(messages, "WARNING: Very small sample size")
  }

  # Cross-field validation
  if (p1 == p2) {
    messages <- c(messages, "ERROR: Proportions must differ")
    valid <- FALSE
  }

  # Return structured result
  validation_result(valid, messages)
}
```

**Refer to:** `R/fct_single_proportion.R` for complete example

---

### Step 2: Refactor Module Server

**File:** `R/mod_<number>_<module_name>.R`

**Changes:**

#### A. Define Allowlists (top of server function)
```r
VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
VALID_POWER <- c("70", "80", "90", "95")
VALID_<SPECIFIC_CHOICES> <- c(...)
```

#### B. Create Raw Reactive with req() and Validation
```r
inputs_raw <- reactive({
  # req() guards
  req(input$param1)
  req(input$param2)

  # Validate and sanitize
  tryCatch({
    list(
      param1 = validate_numeric_input(
        input$param1,
        "Parameter 1",
        min = 0,
        max = 100
      ),
      param2 = validate_choice_input(
        input$param2,
        VALID_CHOICES,
        "Parameter 2"
      ),
      # ... etc
    )
  }, error = function(e) {
    # Log and return defaults
    if (golem::app_prod()) {
      logger::log_warn("Validation failed", error = e$message)
    }
    list(param1 = default1, param2 = default2, ...)
  })
})
```

#### C. Apply Debouncing
```r
# Debounce 500ms
inputs <- inputs_raw %>% debounce(500)
```

#### D. Return Debounced Inputs
```r
list(
  inputs = inputs,  # Return debounced version
  # ... other reactive values
)
```

**Refer to:** Lines 233-351 in `R/mod_01_single_proportion.R`

---

### Step 3: Update App Server Validation

**File:** `R/app_server.R`

**Location:** Inside `validate_inputs()` function (starts ~line 395)

**Find the existing validation block for the module:**
```r
} else if (page == "<module_page>") {
  module_inputs <- module_vals$inputs()
  validate(
    need(module_inputs$param > 0, "Param must be positive"),
    # ... old validation logic
  )
```

**Replace with:**
```r
} else if (page == "<module_page>") {
  # Add req() guard
  req(module_vals$inputs())
  module_inputs <- module_vals$inputs()

  # Use dedicated validation function
  validation <- validate_<module>_inputs(
    param1 = module_inputs$param1,
    param2 = module_inputs$param2,
    # ... all relevant params
    calc_mode = module_inputs$calc_mode
  )

  # Block on errors
  if (!validation$valid) {
    validate(
      need(FALSE, paste(validation$errors, collapse = "\n"))
    )
  }

  # Show warnings
  if (length(validation$warnings) > 0) {
    showNotification(
      paste(validation$warnings, collapse = "\n"),
      type = "warning",
      duration = 5
    )
  }
```

**Refer to:** Lines 400-475 in `R/app_server.R` for complete example

---

## Module-Specific Guidance

### mod_02_two_group.R

**Allowlists:**
- Test types: `c("one_sided", "two_sided")`
- Calculation modes: `c("calc_n", "calc_power")`

**Key Validations:**
- Both sample sizes > 0
- Both proportions 0-100%
- Proportions must differ (`p1 != p2`)
- Allocation ratio > 0
- Warn if allocation ratio extreme (< 0.1 or > 10)
- Warn if effect size < 5%

**Cross-Field:**
```r
# Check if effect size is clinically meaningful
effect_size <- abs(p1 - p2)
if (effect_size < 5) {
  messages <- c(messages, "WARNING: Small effect size may require very large sample")
}

# Check allocation ratio
if (alloc_ratio < 0.1 || alloc_ratio > 10) {
  messages <- c(messages, "WARNING: Extreme allocation ratio may reduce power")
}
```

---

### mod_03_survival.R

**Allowlists:**
- Test types: `c("one_sided", "two_sided")`
- Calculation modes: `c("calc_n", "calc_power")`

**Key Validations:**
- Hazard ratio > 0
- Hazard ratio != 1 (cannot calculate power at null)
- Proportion exposed: 0-100%
- Event rate: 0-100%
- Warn if HR > 2 and proportion exposed < 10%

**Cross-Field:**
```r
# HR and exposure compatibility
if (HR > 2 && prop_exposed < 10) {
  messages <- c(messages, "WARNING: Large HR with low exposure may be unstable")
}

# Check if HR meaningfully different from 1
if (abs(HR - 1) < 0.05) {
  messages <- c(messages, "ERROR: Hazard ratio too close to null (1.0)")
  valid <- FALSE
}
```

---

### mod_05_matched_case_control.R

**Allowlists:**
- Calculation modes: `c("calc_n", "calc_power", "calc_effect")`

**Key Validations:**
- Matched pairs (n_pairs) > 0
- Exposure probability: 0-100% (NULL allowed)
- Odds ratio > 0 and != 1
- Matching ratio (n_controls_per_case) >= 1

**Special Considerations:**
- This module has iterative root-finding calculations
- Consider adding `bindCache()` for performance:
```r
results <- reactive({
  # ... calculation
}) %>% bindCache(
  inputs()$calc_mode,
  inputs()$n_pairs,
  inputs()$p0,
  # ... all dependencies
)
```

---

### mod_06_time_to_event.R

**Allowlists:**
- Test types: `c("non_inferiority", "equivalence")`
- Calculation modes: `c("calc_n", "calc_power")`

**Key Validations:**
- Non-inferiority margin > 0 and < 100%
- Equivalence margins (lower < upper)
- Hazard ratio > 0
- Allocation ratio > 0
- Warn if margin too wide (> 20%)

**Cross-Field:**
```r
# Check margin appropriateness
if (test_type == "non_inferiority" && ni_margin > 20) {
  messages <- c(messages, "WARNING: Non-inferiority margin > 20% is quite liberal")
}

# For equivalence, check margins make sense
if (test_type == "equivalence") {
  if (lower_margin >= upper_margin) {
    messages <- c(messages, "ERROR: Lower margin must be < upper margin")
    valid <- FALSE
  }
}
```

---

### mod_07_continuous_outcome.R

**Allowlists:**
- Effect measures: `c("cohens_d", "mean_difference")`

**Key Validations:**
- Cohen's d > 0 and != 0
- Mean difference != 0
- Standard deviation > 0
- Warn if Cohen's d < 0.2 (very small effect)
- Warn if Cohen's d > 2.0 (very large effect, check data)

**Cross-Field:**
```r
# Effect size interpretation
if (cohens_d < 0.2) {
  messages <- c(messages, "WARNING: Cohen's d < 0.2 is a very small effect")
} else if (cohens_d > 2.0) {
  messages <- c(messages, "WARNING: Cohen's d > 2.0 is very large - verify this is correct")
}
```

---

## Testing Checklist

For each refactored module, verify:

### Functional Testing
- [ ] Valid inputs calculate correctly
- [ ] Invalid inputs show appropriate error messages
- [ ] Warnings display as notifications (non-blocking)
- [ ] Debouncing works (no recalculation while typing)
- [ ] req() guards prevent NULL errors
- [ ] Categorical inputs reject invalid values
- [ ] Numeric inputs reject out-of-range values

### Edge Cases
- [ ] NULL inputs handled gracefully
- [ ] NA values handled gracefully
- [ ] Extreme values (very large/small) trigger warnings
- [ ] Cross-field validations work (e.g., p1 != p2)
- [ ] Calculation mode switches work correctly

### Security Testing
- [ ] Browser console manipulation of inputs rejected
- [ ] Invalid categorical choices rejected (bypass attempt)
- [ ] Type coercion failures handled gracefully

### Performance Testing
- [ ] Debouncing reduces calculation frequency
- [ ] req() guards prevent unnecessary reactive execution
- [ ] No memory leaks from reactive expressions

---

## Common Pitfalls to Avoid

### 1. Missing req() Guards
**Wrong:**
```r
inputs_raw <- reactive({
  list(param = input$param)
})
```

**Correct:**
```r
inputs_raw <- reactive({
  req(input$param)  # Guard against NULL
  list(param = input$param)
})
```

---

### 2. Forgetting Debouncing
**Wrong:**
```r
list(inputs = inputs_raw)
```

**Correct:**
```r
inputs <- inputs_raw %>% debounce(500)
list(inputs = inputs)
```

---

### 3. Not Using Allowlists
**Wrong:**
```r
calc_mode = input$calc_mode  # Accepts any string
```

**Correct:**
```r
calc_mode = validate_choice_input(
  input$calc_mode,
  c("calc_n", "calc_power"),
  "Calculation mode"
)
```

---

### 4. Silent Validation Failures
**Wrong:**
```r
tryCatch({
  # ... validation
}, error = function(e) {
  list(...)  # Silent failure
})
```

**Correct:**
```r
tryCatch({
  # ... validation
}, error = function(e) {
  if (golem::app_prod()) {
    logger::log_warn("Validation failed", error = e$message)
  }
  list(...)  # Logged failure
})
```

---

### 5. Not Separating Errors from Warnings
**Wrong:**
```r
validate(
  need(n > 0, "Sample size must be positive"),
  need(n < 1000, "Sample size is very large")  # Should be warning
)
```

**Correct:**
```r
validation <- validate_module_inputs(n = n)

# Errors block execution
if (!validation$valid) {
  validate(need(FALSE, paste(validation$errors, collapse = "\n")))
}

# Warnings don't block
if (length(validation$warnings) > 0) {
  showNotification(
    paste(validation$warnings, collapse = "\n"),
    type = "warning"
  )
}
```

---

## Environment Configuration

### Development
```r
# .Renviron or config.yml
R_CONFIG_ACTIVE=default

# Enables:
# - Full error messages
# - Validation warnings logged to console
# - Error sanitization DISABLED
```

### Production
```r
# .Renviron or config.yml
R_CONFIG_ACTIVE=production

# Enables:
# - Sanitized error messages (generic)
# - Validation failures logged via logger package
# - Error sanitization ENABLED
```

---

## Documentation Updates Needed

After completing all refactoring:

1. **Update NAMESPACE**
   ```bash
   devtools::document()
   ```

2. **Update function documentation**
   - Run roxygen2 on all new validation functions
   - Ensure examples are present and working

3. **Create quality report**
   - Document what changed
   - Performance improvements measured
   - Security enhancements documented

4. **Update main README**
   - Add note about validation improvements
   - Document production configuration requirements

---

## Next Session Prompt

Use this prompt to continue the work in the next session:

```
Continue implementing input validation and sanitization best practices for the remaining 7 modules in the power analysis tool.

Reference the handoff document at:
docs/reports/quality/input-validation-implementation-handoff.md

Already completed:
✅ R/utils_validation.R - Core validation utilities
✅ R/run_app.R - Error sanitization
✅ R/utils_ui_inputs.R - updateOn parameter
✅ R/mod_01_single_proportion.R - Complete refactor (example)
✅ R/fct_single_proportion.R - Validation function
✅ R/app_server.R - Updated validation for single proportion

Next to do (in order):
1. R/mod_02_two_group.R
2. R/mod_03_survival.R
3. R/mod_04_correlation.R
4. R/mod_05_matched_case_control.R
5. R/mod_06_time_to_event.R
6. R/mod_07_continuous_outcome.R
7. R/mod_multiple_testing.R

For each module:
1. Create R/fct_<module>.R with validate_<module>_inputs() function
2. Refactor R/mod_<module>.R server function:
   - Add allowlists
   - Add req() guards
   - Use validation utilities
   - Apply debouncing
3. Update R/app_server.R validation logic for that module

Follow the pattern in mod_01_single_proportion.R exactly.
Use the module-specific guidance in the handoff document.

Start with mod_02_two_group.R and implement all 3 steps, then move to the next module.
```

---

## File Locations Reference

**Created Files:**
- `R/utils_validation.R` - Core validation utilities
- `R/fct_single_proportion.R` - Single proportion validation
- `docs/reports/quality/input-validation-implementation-handoff.md` - This document

**Modified Files:**
- `R/run_app.R` - Lines 8-29 (error sanitization)
- `R/utils_ui_inputs.R` - Lines 282-333 (updateOn parameter)
- `R/mod_01_single_proportion.R` - Lines 233-351 (complete refactor)
- `R/app_server.R` - Lines 400-475 (validation logic)

**Files to Modify (Phase 2):**
- `R/fct_two_group.R` (create)
- `R/mod_02_two_group.R` (refactor)
- `R/fct_survival.R` (create)
- `R/mod_03_survival.R` (refactor)
- `R/fct_correlation.R` (create)
- `R/mod_04_correlation.R` (refactor)
- `R/fct_matched_case_control.R` (create)
- `R/mod_05_matched_case_control.R` (refactor)
- `R/fct_time_to_event.R` (create)
- `R/mod_06_time_to_event.R` (refactor)
- `R/fct_continuous_outcome.R` (create)
- `R/mod_07_continuous_outcome.R` (refactor)
- `R/mod_multiple_testing.R` (refactor only - validator exists)
- `R/app_server.R` (update validation for each module)

---

## Resources

**Shiny Documentation:**
- req() function: https://shiny.rstudio.com/reference/shiny/latest/req.html
- debounce() function: https://shiny.rstudio.com/reference/shiny/latest/debounce.html
- Input validation: https://mastering-shiny.org/action-feedback.html#validate

**Golem Framework:**
- Engineering Shiny Apps: https://engineering-shiny.org/
- Golem documentation: https://thinkr-open.github.io/golem/

**Security Best Practices:**
- OWASP Input Validation: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- Shiny Security Guide: https://www.datanovia.com/learn/tools/shiny-apps/best-practices/security-guidelines.html

---

**Implementation Status:** Phase 1 Complete (1/8 modules)
**Estimated Effort:** ~30-45 minutes per module
**Total Remaining:** ~3.5-5 hours

**Last Updated:** 2025-10-27
**Next Review:** After Phase 2 completion
