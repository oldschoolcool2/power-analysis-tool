#' Non-Inferiority Testing Functions
#'
#' Business logic and validation for non-inferiority testing sample size and margin calculations
#'
#' @name fct_non_inferiority
NULL

#' Validate Non-Inferiority Inputs
#'
#' Validates all inputs for non-inferiority testing calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param p1 Event rate in test group (%)
#' @param p2 Event rate in reference group (%)
#' @param margin Non-inferiority margin (percentage points)
#' @param n1_fixed Fixed sample size in test group (for margin calculation)
#' @param alpha Significance level (0-1)
#' @param power Power level (0-100)
#' @param ratio Allocation ratio (n2/n1)
#' @param calc_mode Calculation mode ("calc_n" or "calc_effect")
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
#'
#' @examples
#' \dontrun{
#' # Valid sample size calculation
#' validate_non_inferiority_inputs(
#'   p1 = 10, p2 = 10, margin = 5, alpha = 0.025, power = 80,
#'   ratio = 1, calc_mode = "calc_n"
#' )
#'
#' # Invalid: margin too large
#' validate_non_inferiority_inputs(
#'   p1 = 10, p2 = 10, margin = 25, alpha = 0.025, power = 80,
#'   ratio = 1, calc_mode = "calc_n"
#' )
#' }
validate_non_inferiority_inputs <- function(p1 = NULL,
                                            p2 = NULL,
                                            margin = NULL,
                                            n1_fixed = NULL,
                                            alpha = NULL,
                                            power = NULL,
                                            ratio = NULL,
                                            calc_mode = "calc_n") {
  messages <- character(0)
  valid <- TRUE

  # Define allowlists for categorical inputs
  VALID_CALC_MODES <- c("calc_n", "calc_effect")

  # Validate calculation mode
  if (!is.null(calc_mode)) {
    if (!calc_mode %in% VALID_CALC_MODES) {
      messages <- c(messages, "ERROR: Invalid calculation mode. Must be 'calc_n' or 'calc_effect'")
      valid <- FALSE
    }
  }

  # Validate event rates
  if (!is.null(p1)) {
    if (is.na(p1) || p1 < 0 || p1 > 100) {
      messages <- c(messages, "ERROR: Event rate in test group must be between 0 and 100%")
      valid <- FALSE
    } else if (p1 < 0.1) {
      messages <- c(messages, "WARNING: Very low event rate (< 0.1%) may require extremely large sample size")
    } else if (p1 > 50) {
      messages <- c(messages, "NOTE: High event rate (> 50%). Ensure non-inferiority testing is appropriate")
    }
  }

  if (!is.null(p2)) {
    if (is.na(p2) || p2 < 0 || p2 > 100) {
      messages <- c(messages, "ERROR: Event rate in reference group must be between 0 and 100%")
      valid <- FALSE
    } else if (p2 < 0.1) {
      messages <- c(messages, "WARNING: Very low event rate (< 0.1%) may require extremely large sample size")
    } else if (p2 > 50) {
      messages <- c(messages, "NOTE: High event rate (> 50%). Ensure non-inferiority testing is appropriate")
    }
  }

  # Validate non-inferiority margin
  if (!is.null(margin)) {
    if (is.na(margin) || margin <= 0 || margin > 50) {
      messages <- c(messages, "ERROR: Non-inferiority margin must be between 0 and 50 percentage points")
      valid <- FALSE
    } else if (margin > 20) {
      messages <- c(messages, "WARNING: Very large margin (> 20 percentage points). This may be too liberal")
    } else if (margin < 1) {
      messages <- c(messages, "WARNING: Very small margin (< 1 percentage point) will require very large sample size")
    } else if (margin >= 3 && margin <= 10) {
      messages <- c(messages, "NOTE: Margin in typical range (3-10 percentage points) for clinical trials")
    }
  }

  # Validate fixed sample size (for margin calculation)
  if (!is.null(n1_fixed)) {
    if (is.na(n1_fixed) || n1_fixed <= 0) {
      messages <- c(messages, "ERROR: Sample size must be positive")
      valid <- FALSE
    } else if (n1_fixed < 50) {
      messages <- c(messages, "WARNING: Very small sample (< 50) may have low power")
    } else if (n1_fixed < 100) {
      messages <- c(messages, "NOTE: Sample size < 100 may not satisfy asymptotic assumptions")
    }
  }

  # Validate alpha
  if (!is.null(alpha)) {
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1")
      valid <- FALSE
    } else if (alpha > 0.05) {
      messages <- c(messages, "NOTE: Alpha > 0.05 is unusual for non-inferiority testing")
    } else if (alpha == 0.025) {
      messages <- c(messages, "NOTE: Alpha = 0.025 is typical for one-sided non-inferiority tests")
    }
  }

  # Validate power
  if (!is.null(power)) {
    if (is.na(power) || power <= 0 || power >= 100) {
      messages <- c(messages, "ERROR: Power must be between 0 and 100%")
      valid <- FALSE
    } else if (power < 70) {
      messages <- c(messages, "WARNING: Power < 70% is generally considered too low")
    } else if (power > 95) {
      messages <- c(messages, "NOTE: Very high power (> 95%) may require unnecessarily large sample size")
    }
  }

  # Validate allocation ratio
  if (!is.null(ratio)) {
    if (is.na(ratio) || ratio <= 0) {
      messages <- c(messages, "ERROR: Allocation ratio must be positive")
      valid <- FALSE
    } else if (ratio < 0.5 || ratio > 2) {
      messages <- c(messages, "WARNING: Allocation ratio far from 1:1 may reduce power efficiency")
    }
  }

  # Cross-field validations
  if (!is.null(p1) && !is.null(p2) && !is.na(p1) && !is.na(p2)) {
    # Check if event rates are very different
    diff <- abs(p1 - p2)
    if (diff > 10) {
      messages <- c(messages, "WARNING: Large difference in event rates (> 10 percentage points). Consider if non-inferiority is appropriate")
    }

    # Check if test group has much higher event rate (unexpected for non-inferiority)
    if (p1 > p2 + 5) {
      messages <- c(messages, "WARNING: Test group has notably higher event rate than reference. Non-inferiority may be difficult to demonstrate")
    }

    # Check margin relative to event rates
    if (!is.null(margin) && !is.na(margin)) {
      # Margin should be clinically meaningful but not too large relative to event rates
      if (margin > p2 * 0.5) {
        messages <- c(messages, "WARNING: Margin is > 50% of reference event rate. This may be too liberal")
      }

      # If test is better than reference, warn about non-inferiority vs superiority
      if (p1 < p2 - margin) {
        messages <- c(messages, "NOTE: Test group appears superior to reference. Consider superiority testing instead")
      }

      # Check if margin is larger than the difference
      if (diff < margin) {
        messages <- c(messages, "NOTE: Non-inferiority margin (", round(margin, 2), "%) is larger than expected difference (", round(diff, 2), "%)")
      }
    }
  }

  # Calculation mode specific validations
  if (!is.null(calc_mode)) {
    if (calc_mode == "calc_n" && !is.null(power)) {
      if (power >= 99.9) {
        messages <- c(messages, "WARNING: Power ≥ 99.9% will require extremely large sample size")
      }
    }

    if (calc_mode == "calc_effect" && !is.null(n1_fixed)) {
      if (n1_fixed < 100 && !is.null(power) && power > 85) {
        messages <- c(messages, "NOTE: Small sample (< 100) may have limited ability to detect small margins")
      }
    }
  }

  # Log validation failures
  if (!valid) {
    error_msgs <- messages[grepl("^ERROR:", messages)]
    if (length(error_msgs) > 0) {
      logger::log_warn(
        "Non-inferiority validation failed",
        errors = paste(error_msgs, collapse = "; "),
        calc_mode = calc_mode %||% "unknown"
      )
    }
  }

  validation_result(valid, messages)
}
