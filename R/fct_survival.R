#' Survival Analysis Functions
#'
#' Business logic and validation for survival analysis power and sample size calculations
#'
#' @name fct_survival
NULL

#' Validate Survival Analysis Inputs
#'
#' Validates all inputs for survival analysis power and sample size calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param n Sample size (for power calculations)
#' @param hr Hazard ratio
#' @param prop_exposed Proportion exposed (\%)
#' @param event_rate Overall event rate (\%)
#' @param alpha Significance level (0-1)
#' @param power Power level (0-100)
#' @param alloc_ratio Allocation ratio
#' @param test_type Test type ("one_sided" or "two_sided")
#' @param calc_mode Calculation mode ("power", "calc_n")
#'
#' @return List with validation results
#' @export
validate_survival_inputs <- function(n = NULL,
                                     hr = NULL,
                                     prop_exposed = NULL,
                                     event_rate = NULL,
                                     alpha = NULL,
                                     power = NULL,
                                     alloc_ratio = NULL,
                                     test_type = NULL,
                                     calc_mode = "power") {

  messages <- character(0)
  valid <- TRUE

  # Validate calculation mode against allowlist
  VALID_CALC_MODES <- c("power", "calc_n")
  if (!calc_mode %in% VALID_CALC_MODES) {
    messages <- c(messages, sprintf(
      "ERROR: Invalid calculation mode '%s'. Must be one of: %s",
      calc_mode,
      paste(VALID_CALC_MODES, collapse = ", ")
    ))
    valid <- FALSE
  }

  # Validate test type against allowlist
  VALID_TEST_TYPES <- c("one_sided", "two_sided")
  if (!is.null(test_type) && !test_type %in% VALID_TEST_TYPES) {
    messages <- c(messages, sprintf(
      "ERROR: Invalid test type '%s'. Must be one of: %s",
      test_type,
      paste(VALID_TEST_TYPES, collapse = ", ")
    ))
    valid <- FALSE
  }

  # === Validate Hazard Ratio (all modes) ===
  if (is.null(hr) || is.na(hr) || hr <= 0) {
    messages <- c(messages, "ERROR: Hazard ratio must be positive")
    valid <- FALSE
  } else {
    # Check if HR is meaningfully different from 1
    if (abs(hr - 1) < 0.05) {
      messages <- c(messages, "ERROR: Hazard ratio too close to null (1.0) - difference < 0.05")
      valid <- FALSE
    } else if (abs(hr - 1) < 0.1) {
      messages <- c(messages, "WARNING: Hazard ratio close to null (1.0) - may require very large sample")
    }

    # Warn about extreme HR values
    if (hr > 5) {
      messages <- c(messages, "WARNING: Hazard ratio > 5 is very large - verify this is realistic")
    } else if (hr < 0.2) {
      messages <- c(messages, "WARNING: Hazard ratio < 0.2 is very small - verify this is realistic")
    }
  }

  # === Power Calculation Mode ===
  if (calc_mode == "power") {
    # Validate sample size
    if (is.null(n) || is.na(n) || n <= 0) {
      messages <- c(messages, "ERROR: Sample size must be positive")
      valid <- FALSE
    } else if (n < 20) {
      messages <- c(messages, "WARNING: Very small sample size (< 20) may yield unreliable results for survival analysis")
    } else if (n > 1e6) {
      messages <- c(messages, "WARNING: Very large sample size (> 1 million) - check if this is correct")
    }
  }

  # === Sample Size Calculation Mode ===
  if (calc_mode == "calc_n") {
    # Validate power
    if (is.null(power) || is.na(power) || power <= 0 || power >= 100) {
      messages <- c(messages, "ERROR: Power must be between 0 and 100% (exclusive)")
      valid <- FALSE
    } else if (power < 50) {
      messages <- c(messages, "WARNING: Power < 50% is unusually low - consider 80% or higher")
    } else if (power > 95) {
      messages <- c(messages, "NOTE: Power > 95% may require very large sample size")
    }

    # Validate allocation ratio
    if (!is.null(alloc_ratio)) {
      if (is.na(alloc_ratio) || alloc_ratio <= 0) {
        messages <- c(messages, "ERROR: Allocation ratio must be positive")
        valid <- FALSE
      } else if (alloc_ratio < 0.1 || alloc_ratio > 10) {
        messages <- c(messages, "WARNING: Extreme allocation ratio (< 0.1 or > 10) may significantly reduce power")
      }
    }
  }

  # === Common Validations ===

  # Validate proportion exposed
  if (!is.null(prop_exposed)) {
    if (is.na(prop_exposed) || prop_exposed < 0 || prop_exposed > 100) {
      messages <- c(messages, "ERROR: Proportion exposed must be between 0 and 100%")
      valid <- FALSE
    } else if (prop_exposed < 5) {
      messages <- c(messages, "WARNING: Very low proportion exposed (< 5%) may require large sample")
    } else if (prop_exposed > 95) {
      messages <- c(messages, "WARNING: Very high proportion exposed (> 95%) - little unexposed for comparison")
    }

    # Cross-field validation: HR and exposure compatibility
    if (valid && !is.null(hr) && hr > 2 && prop_exposed < 10) {
      messages <- c(messages, "WARNING: Large HR (> 2) with low exposure (< 10%) may produce unstable estimates")
    }
  }

  # Validate event rate
  if (!is.null(event_rate)) {
    if (is.na(event_rate) || event_rate < 0 || event_rate > 100) {
      messages <- c(messages, "ERROR: Event rate must be between 0 and 100%")
      valid <- FALSE
    } else if (event_rate < 5) {
      messages <- c(messages, "WARNING: Very low event rate (< 5%) will require large sample or long follow-up")
    } else if (event_rate > 90) {
      messages <- c(messages, "NOTE: Very high event rate (> 90%) - most participants experience event")
    }
  }

  # Validate alpha
  if (!is.null(alpha)) {
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1 (exclusive)")
      valid <- FALSE
    } else if (alpha > 0.10) {
      messages <- c(messages, "WARNING: Significance level > 0.10 is unusually liberal")
    } else if (alpha < 0.001) {
      messages <- c(messages, "NOTE: Significance level < 0.001 is very conservative")
    }
  }

  # Log validation failures (only errors)
  if (!valid) {
    error_msgs <- messages[grepl("^ERROR:", messages)]
    if (length(error_msgs) > 0) {
      logger::log_warn(
        "Survival analysis input validation failed",
        fn = "validate_survival_inputs",
        calc_mode = calc_mode,
        error_count = length(error_msgs),
        errors = paste(error_msgs, collapse = "; ")
      )
    }
  }

  # Return validation result
  validation_result(valid, messages)
}
