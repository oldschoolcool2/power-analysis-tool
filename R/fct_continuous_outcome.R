#' Continuous Outcome Analysis Functions
#'
#' Business logic and validation for continuous outcome power and sample size calculations
#'
#' @name fct_continuous_outcome
NULL

#' Validate Continuous Outcome Inputs
#'
#' Validates all inputs for continuous outcome (Cohen's d) power and sample size calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param n1 Sample size group 1 (for power calculations)
#' @param n2 Sample size group 2 (for power calculations)
#' @param cohens_d Cohen's d effect size
#' @param alpha Significance level (0-1)
#' @param power Power level (0-100)
#' @param alloc_ratio Allocation ratio (n2/n1)
#' @param test_type Test type ("one_sided" or "two_sided")
#' @param calc_mode Calculation mode ("power", "calc_n", "calc_effect")
#'
#' @return List with validation results
#' @export
validate_continuous_outcome_inputs <- function(n1 = NULL,
                                               n2 = NULL,
                                               cohens_d = NULL,
                                               alpha = NULL,
                                               power = NULL,
                                               alloc_ratio = NULL,
                                               test_type = NULL,
                                               calc_mode = "power") {

  messages <- character(0)
  valid <- TRUE

  # Validate calculation mode against allowlist
  VALID_CALC_MODES <- c("power", "calc_n", "calc_effect")
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

  # === Validate Cohen's d (power and sample size modes) ===
  if (calc_mode %in% c("power", "calc_n")) {
    if (is.null(cohens_d) || is.na(cohens_d)) {
      messages <- c(messages, "ERROR: Cohen's d must be provided")
      valid <- FALSE
    } else if (cohens_d == 0) {
      messages <- c(messages, "ERROR: Cohen's d cannot be zero (no effect)")
      valid <- FALSE
    } else if (cohens_d < 0) {
      messages <- c(messages, "WARNING: Cohen's d is negative - ensure directionality is correct")
    } else {
      # Interpret Cohen's d magnitude
      abs_d <- abs(cohens_d)
      if (abs_d < 0.2) {
        messages <- c(messages, "WARNING: Cohen's d < 0.2 is a very small effect - will require large sample")
      } else if (abs_d < 0.5) {
        messages <- c(messages, "NOTE: Cohen's d < 0.5 is a small to medium effect")
      } else if (abs_d > 2.0) {
        messages <- c(messages, "WARNING: Cohen's d > 2.0 is very large - verify this is realistic")
      }
    }
  }

  # === Power Calculation Mode ===
  if (calc_mode == "power") {
    # Validate sample sizes
    if (is.null(n1) || is.na(n1) || n1 <= 0) {
      messages <- c(messages, "ERROR: Sample size group 1 must be positive")
      valid <- FALSE
    } else if (n1 < 10) {
      messages <- c(messages, "WARNING: Very small sample size group 1 (< 10) may yield unreliable results")
    }

    if (is.null(n2) || is.na(n2) || n2 <= 0) {
      messages <- c(messages, "ERROR: Sample size group 2 must be positive")
      valid <- FALSE
    } else if (n2 < 10) {
      messages <- c(messages, "WARNING: Very small sample size group 2 (< 10) may yield unreliable results")
    }

    # Check sample size balance
    if (valid && !is.null(n1) && !is.null(n2)) {
      ratio <- max(n1, n2) / min(n1, n2)
      if (ratio > 10) {
        messages <- c(messages, "WARNING: Sample sizes are very imbalanced (ratio > 10:1) - may reduce power")
      }
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

  # === Effect Size Calculation Mode ===
  if (calc_mode == "calc_effect") {
    # Validate sample sizes
    if (is.null(n1) || is.na(n1) || n1 <= 0) {
      messages <- c(messages, "ERROR: Sample size group 1 must be positive")
      valid <- FALSE
    }

    if (is.null(n2) || is.na(n2) || n2 <= 0) {
      messages <- c(messages, "ERROR: Sample size group 2 must be positive")
      valid <- FALSE
    }

    # Validate power
    if (is.null(power) || is.na(power) || power <= 0 || power >= 100) {
      messages <- c(messages, "ERROR: Power must be between 0 and 100% (exclusive)")
      valid <- FALSE
    }
  }

  # === Common Validations ===

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
        "Continuous outcome input validation failed",
        function = "validate_continuous_outcome_inputs",
        calc_mode = calc_mode,
        error_count = length(error_msgs),
        errors = paste(error_msgs, collapse = "; ")
      )
    }
  }

  # Return validation result
  validation_result(valid, messages)
}
