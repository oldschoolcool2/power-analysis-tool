#' Single Proportion Analysis Functions
#'
#' Business logic and validation for single proportion power and sample size calculations
#'
#' @name fct_single_proportion
NULL

#' Validate Single Proportion Inputs
#'
#' Validates all inputs for single proportion power and sample size calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param n Sample size (for power calculations)
#' @param p Expected proportion (%)
#' @param p0 Null hypothesis proportion (%)
#' @param alpha Significance level (0-1)
#' @param power Power level (0-100)
#' @param discon Discontinuation rate (%)
#' @param calc_mode Calculation mode ("power", "calc_n", "calc_effect")
#' @param n_fixed Fixed sample size (for effect size calculations)
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
#' # Valid power calculation
#' validate_single_proportion_inputs(
#'   n = 230, p = 1, p0 = 0, alpha = 0.05, discon = 10, calc_mode = "power"
#' )
#'
#' # Invalid: proportions too close
#' validate_single_proportion_inputs(
#'   n = 230, p = 0.1, p0 = 0.05, alpha = 0.05, discon = 10, calc_mode = "power"
#' )
#' }
validate_single_proportion_inputs <- function(n = NULL,
                                              p = NULL,
                                              p0 = NULL,
                                              alpha = NULL,
                                              power = NULL,
                                              discon = NULL,
                                              calc_mode = "power",
                                              n_fixed = NULL) {

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

  # === Power Calculation Mode ===
  if (calc_mode == "power") {
    # Validate sample size
    if (is.null(n) || is.na(n) || n <= 0) {
      messages <- c(messages, "ERROR: Sample size must be positive")
      valid <- FALSE
    } else if (n < 10) {
      messages <- c(messages, "WARNING: Very small sample size (< 10) may yield unreliable results")
    } else if (n > 1e6) {
      messages <- c(messages, "WARNING: Very large sample size (> 1 million) - check if this is correct")
    }

    # Validate proportions
    if (is.null(p) || is.na(p) || p < 0 || p > 100) {
      messages <- c(messages, "ERROR: Expected proportion must be between 0 and 100%")
      valid <- FALSE
    }

    if (is.null(p0) || is.na(p0) || p0 < 0 || p0 > 100) {
      messages <- c(messages, "ERROR: Reference proportion must be between 0 and 100%")
      valid <- FALSE
    }

    # Check if proportions are meaningfully different
    if (valid && !is.null(p) && !is.null(p0)) {
      effect_size <- abs(p - p0)
      if (effect_size < 0.01) {
        messages <- c(messages, "ERROR: Proportions are identical or nearly identical (< 0.01% difference)")
        valid <- FALSE
      } else if (effect_size < 0.5) {
        messages <- c(messages, "WARNING: Very small effect size (< 0.5%) may require extremely large sample")
      } else if (effect_size < 2) {
        messages <- c(messages, "NOTE: Small effect size (< 2%) will require large sample for adequate power")
      }
    }

    # Validate alpha
    if (is.null(alpha) || is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1 (exclusive)")
      valid <- FALSE
    } else if (alpha > 0.10) {
      messages <- c(messages, "WARNING: Significance level > 0.10 is unusually liberal")
    } else if (alpha < 0.001) {
      messages <- c(messages, "NOTE: Significance level < 0.001 is very conservative")
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

    # Validate proportions (same as power calculation)
    if (is.null(p) || is.na(p) || p < 0 || p > 100) {
      messages <- c(messages, "ERROR: Expected proportion must be between 0 and 100%")
      valid <- FALSE
    }

    if (is.null(p0) || is.na(p0) || p0 < 0 || p0 > 100) {
      messages <- c(messages, "ERROR: Reference proportion must be between 0 and 100%")
      valid <- FALSE
    }

    # Check effect size
    if (valid && !is.null(p) && !is.null(p0)) {
      effect_size <- abs(p - p0)
      if (effect_size < 0.01) {
        messages <- c(messages, "ERROR: Proportions are identical or nearly identical (< 0.01% difference)")
        valid <- FALSE
      } else if (effect_size < 0.5) {
        messages <- c(messages, "WARNING: Very small effect size (< 0.5%) will require extremely large sample")
      }
    }

    # Validate alpha
    if (is.null(alpha) || is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1 (exclusive)")
      valid <- FALSE
    }
  }

  # === Effect Size Calculation Mode ===
  if (calc_mode == "calc_effect") {
    # Validate fixed sample size
    if (is.null(n_fixed) || is.na(n_fixed) || n_fixed <= 0) {
      messages <- c(messages, "ERROR: Fixed sample size must be positive")
      valid <- FALSE
    } else if (n_fixed < 10) {
      messages <- c(messages, "WARNING: Very small sample size (< 10) limits detectable effects")
    }

    # Validate reference proportion
    if (is.null(p0) || is.na(p0) || p0 < 0 || p0 > 100) {
      messages <- c(messages, "ERROR: Reference proportion must be between 0 and 100%")
      valid <- FALSE
    }

    # Validate power
    if (is.null(power) || is.na(power) || power <= 0 || power >= 100) {
      messages <- c(messages, "ERROR: Power must be between 0 and 100% (exclusive)")
      valid <- FALSE
    }

    # Validate alpha
    if (is.null(alpha) || is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1 (exclusive)")
      valid <- FALSE
    }
  }

  # === Common Validations (all modes) ===

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
        "Single proportion input validation failed",
        function = "validate_single_proportion_inputs",
        calc_mode = calc_mode,
        error_count = length(error_msgs),
        errors = paste(error_msgs, collapse = "; ")
      )
    }
  }

  # Return validation result
  validation_result(valid, messages)
}
