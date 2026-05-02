#' Two-Group Comparison Analysis Functions
#'
#' Business logic and validation for two-group comparison power and sample size calculations
#'
#' @name fct_two_group
NULL

#' Validate Two-Group Comparison Inputs
#'
#' Validates all inputs for two-group comparison power and sample size calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param n1 Sample size group 1 (for power calculations)
#' @param n2 Sample size group 2 (for power calculations)
#' @param p1 Event rate group 1 (%)
#' @param p2 Event rate group 2 (%)
#' @param alpha Significance level (0-1)
#' @param power Power level (0-100)
#' @param alloc_ratio Allocation ratio (n2/n1)
#' @param discon Discontinuation rate (%)
#' @param test_type Test type ("one_sided" or "two_sided")
#' @param calc_mode Calculation mode ("power", "calc_n")
#'
#' @return List with components:
#'   \describe{
#'     \item{valid}{Logical - TRUE if all validations passed}
#'     \item{messages}{Character vector of all messages}
#'     \item{errors}{Character vector of error messages only}
#'     \item{warnings}{Character vector of warning messages only}
#'     \item{notes}{Character vector of informational messages only}
#'   }
#'
#' @export
validate_two_group_inputs <- function(n1 = NULL,
                                      n2 = NULL,
                                      p1 = NULL,
                                      p2 = NULL,
                                      alpha = NULL,
                                      power = NULL,
                                      alloc_ratio = NULL,
                                      discon = NULL,
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

  # === Power Calculation Mode ===
  if (calc_mode == "power") {
    # Validate sample sizes
    if (is.null(n1) || is.na(n1) || n1 <= 0) {
      messages <- c(messages, "ERROR: Sample size group 1 must be positive")
      valid <- FALSE
    } else if (n1 < 10) {
      messages <- c(messages, "WARNING: Very small sample size group 1 (< 10) may yield unreliable results")
    } else if (n1 > 1e6) {
      messages <- c(messages, "WARNING: Very large sample size group 1 (> 1 million) - check if this is correct")
    }

    if (is.null(n2) || is.na(n2) || n2 <= 0) {
      messages <- c(messages, "ERROR: Sample size group 2 must be positive")
      valid <- FALSE
    } else if (n2 < 10) {
      messages <- c(messages, "WARNING: Very small sample size group 2 (< 10) may yield unreliable results")
    } else if (n2 > 1e6) {
      messages <- c(messages, "WARNING: Very large sample size group 2 (> 1 million) - check if this is correct")
    }

    # Check sample size balance
    if (valid && !is.null(n1) && !is.null(n2)) {
      ratio <- max(n1, n2) / min(n1, n2)
      if (ratio > 10) {
        messages <- c(messages, "WARNING: Sample sizes are very imbalanced (ratio > 10:1) - may reduce power")
      } else if (ratio > 5) {
        messages <- c(messages, "NOTE: Sample sizes are imbalanced (ratio > 5:1)")
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
    if (is.null(alloc_ratio) || is.na(alloc_ratio) || alloc_ratio <= 0) {
      messages <- c(messages, "ERROR: Allocation ratio must be positive")
      valid <- FALSE
    } else if (alloc_ratio < 0.1 || alloc_ratio > 10) {
      messages <- c(messages, "WARNING: Extreme allocation ratio (< 0.1 or > 10) may significantly reduce power")
    } else if (alloc_ratio < 0.5 || alloc_ratio > 2) {
      messages <- c(messages, "NOTE: Allocation ratio differs substantially from 1:1")
    }
  }

  # === Common Validations (all modes) ===

  # Validate event rates
  if (is.null(p1) || is.na(p1) || p1 < 0 || p1 > 100) {
    messages <- c(messages, "ERROR: Event rate group 1 must be between 0 and 100%")
    valid <- FALSE
  }

  if (is.null(p2) || is.na(p2) || p2 < 0 || p2 > 100) {
    messages <- c(messages, "ERROR: Event rate group 2 must be between 0 and 100%")
    valid <- FALSE
  }

  # Check if event rates are different
  if (valid && !is.null(p1) && !is.null(p2)) {
    effect_size <- abs(p1 - p2)
    if (effect_size < 0.01) {
      messages <- c(messages, "ERROR: Event rates are identical or nearly identical (< 0.01% difference)")
      valid <- FALSE
    } else if (effect_size < 0.5) {
      messages <- c(messages, "WARNING: Very small effect size (< 0.5%) will require extremely large sample")
    } else if (effect_size < 5) {
      messages <- c(messages, "WARNING: Small effect size (< 5%) may require very large sample")
    } else if (effect_size < 10) {
      messages <- c(messages, "NOTE: Moderate effect size (< 10%) will require substantial sample")
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

  # Validate discontinuation rate
  if (!is.null(discon)) {
    if (is.na(discon) || discon < 0 || discon > 100) {
      messages <- c(messages, "ERROR: Discontinuation rate must be between 0 and 100%")
      valid <- FALSE
    } else if (discon > 50) {
      messages <- c(messages, "WARNING: Discontinuation rate > 50% is very high")
    } else if (discon > 30) {
      messages <- c(messages, "NOTE: Discontinuation rate > 30% may substantially inflate required sample")
    }
  }

  # Log validation failures (only errors)
  if (!valid) {
    error_msgs <- messages[grepl("^ERROR:", messages)]
    if (length(error_msgs) > 0) {
      logger::log_warn(
        "Two-group comparison input validation failed",
        fn = "validate_two_group_inputs",
        calc_mode = calc_mode,
        error_count = length(error_msgs),
        errors = paste(error_msgs, collapse = "; ")
      )
    }
  }

  # Return validation result
  validation_result(valid, messages)
}
