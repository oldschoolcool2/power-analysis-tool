#' Matched Case-Control Analysis Functions
#'
#' Business logic and validation for matched case-control power and sample size calculations
#'
#' @name fct_matched_case_control
NULL

#' Validate Matched Case-Control Inputs
#'
#' Validates all inputs for matched case-control power, sample size, and effect size calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param n_pairs Number of matched pairs (for power/MDE calculations)
#' @param or_value Odds ratio
#' @param p0 Exposure probability in controls (%)
#' @param alpha Significance level (0-1)
#' @param power Power level (0-100)
#' @param ratio Controls per case (matching ratio)
#' @param sided Test type ("two.sided" or "one.sided")
#' @param calc_mode Calculation mode ("calc_n", "calc_power", "calc_effect")
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
#' validate_matched_case_control_inputs(
#'   or_value = 2.0, p0 = 20, alpha = 0.05, power = 80,
#'   ratio = 1, sided = "two.sided", calc_mode = "calc_n"
#' )
#'
#' # Invalid: OR = 1 (null hypothesis)
#' validate_matched_case_control_inputs(
#'   or_value = 1.0, p0 = 20, alpha = 0.05, power = 80,
#'   ratio = 1, sided = "two.sided", calc_mode = "calc_n"
#' )
#' }
validate_matched_case_control_inputs <- function(n_pairs = NULL,
                                                  or_value = NULL,
                                                  p0 = NULL,
                                                  alpha = NULL,
                                                  power = NULL,
                                                  ratio = NULL,
                                                  sided = NULL,
                                                  calc_mode = "calc_n") {
  messages <- character(0)
  valid <- TRUE

  # Define allowlists for categorical inputs
  VALID_CALC_MODES <- c("calc_n", "calc_power", "calc_effect")
  VALID_SIDED <- c("two.sided", "one.sided")

  # Validate calculation mode
  if (!is.null(calc_mode)) {
    if (!calc_mode %in% VALID_CALC_MODES) {
      messages <- c(messages, "ERROR: Invalid calculation mode")
      valid <- FALSE
    }
  }

  # Validate test type
  if (!is.null(sided)) {
    if (!sided %in% VALID_SIDED) {
      messages <- c(messages, "ERROR: Invalid test type. Must be 'two.sided' or 'one.sided'")
      valid <- FALSE
    }
  }

  # Validate n_pairs (for power and MDE calculations)
  if (!is.null(n_pairs)) {
    if (is.na(n_pairs) || n_pairs <= 0) {
      messages <- c(messages, "ERROR: Number of matched pairs must be positive")
      valid <- FALSE
    } else if (n_pairs < 10) {
      messages <- c(messages, "WARNING: Very small sample (< 10 pairs) may have low power and unstable estimates")
    } else if (n_pairs < 30) {
      messages <- c(messages, "NOTE: Sample size < 30 pairs may not satisfy asymptotic assumptions")
    }
  }

  # Validate odds ratio
  if (!is.null(or_value)) {
    if (is.na(or_value) || or_value <= 0) {
      messages <- c(messages, "ERROR: Odds ratio must be positive")
      valid <- FALSE
    } else if (abs(or_value - 1.0) < 0.01) {
      messages <- c(messages, "ERROR: Odds ratio too close to 1.0 (null hypothesis). Cannot calculate power for no effect")
      valid <- FALSE
    } else if (or_value > 0.9 && or_value < 1.1) {
      messages <- c(messages, "WARNING: Odds ratio very close to 1.0 (weak effect). Very large sample size may be required")
    } else if (or_value > 10) {
      messages <- c(messages, "WARNING: Very large odds ratio (> 10). Verify this is the expected effect size")
    } else if (or_value < 0.1) {
      messages <- c(messages, "WARNING: Very strong protective effect (OR < 0.1). Verify this is the expected effect size")
    } else if ((or_value > 1.0 && or_value < 1.5) || (or_value < 1.0 && or_value > 0.67)) {
      messages <- c(messages, "NOTE: Small to moderate effect size. Ensure adequate sample size for detection")
    }
  }

  # Validate exposure probability in controls
  if (!is.null(p0)) {
    if (is.na(p0) || p0 < 0 || p0 > 100) {
      messages <- c(messages, "ERROR: Exposure probability must be between 0 and 100%")
      valid <- FALSE
    } else if (p0 < 5 || p0 > 95) {
      messages <- c(messages, "WARNING: Extreme exposure probability (< 5% or > 95%) may affect power and stability")
    } else if (p0 >= 5 && p0 <= 15) {
      messages <- c(messages, "NOTE: Low exposure probability. Consider whether sample can reliably capture exposed controls")
    }
  }

  # Validate alpha
  if (!is.null(alpha)) {
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1")
      valid <- FALSE
    }
  }

  # Validate power
  if (!is.null(power)) {
    if (is.na(power) || power <= 0 || power >= 100) {
      messages <- c(messages, "ERROR: Power must be between 0 and 100%")
      valid <- FALSE
    } else if (power < 70) {
      messages <- c(messages, "WARNING: Power < 70% is generally considered too low for reliable inference")
    } else if (power > 95) {
      messages <- c(messages, "NOTE: Very high power (> 95%) may require unnecessarily large sample size")
    }
  }

  # Validate matching ratio (controls per case)
  if (!is.null(ratio)) {
    if (is.na(ratio) || ratio < 1 || ratio != floor(ratio)) {
      messages <- c(messages, "ERROR: Controls per case must be a whole number ≥ 1")
      valid <- FALSE
    } else if (ratio > 4) {
      messages <- c(messages, "WARNING: Matching ratio > 4 provides diminishing returns in power. Consider cost vs. benefit")
    }
  }

  # Cross-field validations
  if (!is.null(or_value) && !is.null(p0) && !is.na(or_value) && !is.na(p0) && or_value > 0 && p0 >= 0 && p0 <= 100) {
    # Check if large OR with very low exposure probability
    if (or_value > 3 && p0 < 10) {
      messages <- c(messages, "WARNING: Large OR (> 3) with low exposure (< 10%) may be difficult to detect reliably")
    }

    # Check if effect size and exposure probability are compatible
    if (or_value < 1) {  # Protective effect
      # Calculate implied exposure in cases
      p_case_implied <- (or_value * (p0/100)) / (1 - (p0/100) + or_value * (p0/100)) * 100
      if (p_case_implied < 1) {
        messages <- c(messages, "NOTE: Strong protective effect with low baseline exposure. Ensure sufficient exposed cases")
      }
    }
  }

  # Power and sample size specific validations
  if (!is.null(calc_mode)) {
    if (calc_mode == "calc_n" && !is.null(power)) {
      if (power >= 99.9) {
        messages <- c(messages, "WARNING: Power ≥ 99.9% will require extremely large sample size")
      }
    }

    if (calc_mode == "calc_power" && !is.null(n_pairs)) {
      if (n_pairs < 50 && !is.null(or_value) && abs(or_value - 1.0) < 0.5) {
        messages <- c(messages, "NOTE: Small sample (< 50 pairs) with moderate effect may have limited power")
      }
    }
  }

  # Log validation failures
  if (!valid) {
    error_msgs <- messages[grepl("^ERROR:", messages)]
    if (length(error_msgs) > 0) {
      logger::log_warn(
        "Matched case-control validation failed",
        errors = paste(error_msgs, collapse = "; "),
        calc_mode = calc_mode %||% "unknown"
      )
    }
  }

  validation_result(valid, messages)
}
