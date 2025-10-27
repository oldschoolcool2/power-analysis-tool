#' Mediation Analysis Functions
#'
#' Business logic and validation for mediation analysis power and sample size calculations
#'
#' @name fct_mediation_validation
NULL

#' Validate Mediation Analysis Inputs
#'
#' Validates all inputs for mediation analysis power, sample size, and MDE calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param n Sample size (for power/MDE calculations)
#' @param power Power level (0-100)
#' @param path_a Standardized path coefficient from X to M
#' @param path_b Standardized path coefficient from M to Y|X
#' @param path_c_prime Direct effect from X to Y|M (optional)
#' @param se_a Standard error of path a (optional)
#' @param se_b Standard error of path b (optional)
#' @param alpha Significance level (0-1)
#' @param sided Test type ("two.sided" or "one.sided")
#' @param calc_mode Calculation mode ("calc_power", "calc_n", or "calc_mde")
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
#' validate_mediation_inputs(
#'   n = 200, path_a = 0.3, path_b = 0.3, alpha = 0.05,
#'   sided = "two.sided", calc_mode = "calc_power"
#' )
#'
#' # Invalid: path coefficients outside realistic range
#' validate_mediation_inputs(
#'   n = 200, path_a = 5.0, path_b = 0.3, alpha = 0.05,
#'   sided = "two.sided", calc_mode = "calc_power"
#' )
#' }
validate_mediation_inputs <- function(n = NULL,
                                      power = NULL,
                                      path_a = NULL,
                                      path_b = NULL,
                                      path_c_prime = NULL,
                                      se_a = NULL,
                                      se_b = NULL,
                                      alpha = NULL,
                                      sided = NULL,
                                      calc_mode = "calc_power") {
  messages <- character(0)
  valid <- TRUE

  # Define allowlists for categorical inputs
  VALID_CALC_MODES <- c("calc_power", "calc_n", "calc_mde")
  VALID_SIDED <- c("two.sided", "one.sided")

  # Validate calculation mode
  if (!is.null(calc_mode)) {
    if (!calc_mode %in% VALID_CALC_MODES) {
      messages <- c(messages, "ERROR: Invalid calculation mode. Must be 'calc_power', 'calc_n', or 'calc_mde'")
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

  # Validate sample size
  if (!is.null(n)) {
    if (is.na(n) || n <= 0) {
      messages <- c(messages, "ERROR: Sample size must be positive")
      valid <- FALSE
    } else if (n < 50) {
      messages <- c(messages, "WARNING: Very small sample (< 50) may not satisfy asymptotic assumptions for mediation analysis")
    } else if (n < 100) {
      messages <- c(messages, "NOTE: Sample size < 100 may have low power for detecting small indirect effects")
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

  # Validate path a (X → M)
  if (!is.null(path_a)) {
    if (is.na(path_a)) {
      messages <- c(messages, "ERROR: Path a coefficient is required")
      valid <- FALSE
    } else if (abs(path_a) > 2) {
      messages <- c(messages, "WARNING: Path a coefficient very large (|a| > 2). Standardized coefficients typically range from -1 to 1")
    } else if (abs(path_a) < 0.1) {
      messages <- c(messages, "WARNING: Very small path a coefficient (|a| < 0.1). Indirect effect may be negligible")
    } else if (abs(path_a) >= 0.1 && abs(path_a) < 0.3) {
      messages <- c(messages, "NOTE: Small effect size for path a (|a| = ", round(abs(path_a), 2), ")")
    } else if (abs(path_a) >= 0.5) {
      messages <- c(messages, "NOTE: Large effect size for path a (|a| = ", round(abs(path_a), 2), ")")
    }
  }

  # Validate path b (M → Y|X)
  if (!is.null(path_b)) {
    if (is.na(path_b)) {
      # path_b may be NA only for calc_mde mode
      if (!is.null(calc_mode) && calc_mode != "calc_mde") {
        messages <- c(messages, "ERROR: Path b coefficient is required for this calculation mode")
        valid <- FALSE
      }
    } else if (abs(path_b) > 2) {
      messages <- c(messages, "WARNING: Path b coefficient very large (|b| > 2). Standardized coefficients typically range from -1 to 1")
    } else if (abs(path_b) < 0.1) {
      messages <- c(messages, "WARNING: Very small path b coefficient (|b| < 0.1). Indirect effect may be negligible")
    } else if (abs(path_b) >= 0.1 && abs(path_b) < 0.3) {
      messages <- c(messages, "NOTE: Small effect size for path b (|b| = ", round(abs(path_b), 2), ")")
    } else if (abs(path_b) >= 0.5) {
      messages <- c(messages, "NOTE: Large effect size for path b (|b| = ", round(abs(path_b), 2), ")")
    }
  }

  # Validate path c' (direct effect - optional)
  if (!is.null(path_c_prime) && !is.na(path_c_prime)) {
    if (abs(path_c_prime) > 2) {
      messages <- c(messages, "WARNING: Direct effect very large (|c'| > 2). Standardized coefficients typically range from -1 to 1")
    }
  }

  # Validate standard errors (optional)
  if (!is.null(se_a) && !is.na(se_a)) {
    if (se_a <= 0) {
      messages <- c(messages, "ERROR: Standard error of path a must be positive")
      valid <- FALSE
    } else if (se_a > 1) {
      messages <- c(messages, "WARNING: Very large SE for path a (> 1). This is unusual for standardized coefficients")
    }
  }

  if (!is.null(se_b) && !is.na(se_b)) {
    if (se_b <= 0) {
      messages <- c(messages, "ERROR: Standard error of path b must be positive")
      valid <- FALSE
    } else if (se_b > 1) {
      messages <- c(messages, "WARNING: Very large SE for path b (> 1). This is unusual for standardized coefficients")
    }
  }

  # Validate alpha
  if (!is.null(alpha)) {
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1")
      valid <- FALSE
    }
  }

  # Cross-field validations
  if (!is.null(path_a) && !is.null(path_b) && !is.na(path_a) && !is.na(path_b)) {
    # Calculate indirect effect (a * b)
    indirect_effect <- abs(path_a * path_b)

    if (indirect_effect < 0.01) {
      messages <- c(messages, "WARNING: Indirect effect very small (|a*b| < 0.01). Large sample size may be required")
    } else if (indirect_effect < 0.05) {
      messages <- c(messages, "NOTE: Small indirect effect (|a*b| = ", round(indirect_effect, 3), "). Consider whether this is practically meaningful")
    } else if (indirect_effect >= 0.1) {
      messages <- c(messages, "NOTE: Moderate to large indirect effect (|a*b| = ", round(indirect_effect, 3), ")")
    }

    # Check sign consistency (for mediation, paths typically same sign for consistent mediation)
    if (sign(path_a) != sign(path_b)) {
      messages <- c(messages, "NOTE: Paths a and b have opposite signs (inconsistent mediation/suppression). This is valid but less common")
    }

    # Compare indirect effect to direct effect
    if (!is.null(path_c_prime) && !is.na(path_c_prime)) {
      direct_effect <- abs(path_c_prime)
      if (indirect_effect > direct_effect * 2) {
        messages <- c(messages, "NOTE: Indirect effect much larger than direct effect. This suggests strong mediation")
      } else if (direct_effect > indirect_effect * 2) {
        messages <- c(messages, "NOTE: Direct effect much larger than indirect effect. Mediation may be weak")
      }
    }
  }

  # Sample size and effect size considerations
  if (!is.null(n) && !is.null(path_a) && !is.null(path_b) &&
      !is.na(n) && !is.na(path_a) && !is.na(path_b)) {
    indirect_effect <- abs(path_a * path_b)

    if (n < 100 && indirect_effect < 0.05) {
      messages <- c(messages, "WARNING: Small sample (< 100) combined with small indirect effect (< 0.05). Power will be very low")
    }
  }

  # Calculation mode specific validations
  if (!is.null(calc_mode)) {
    if (calc_mode == "calc_n" && !is.null(power)) {
      if (power >= 99.9) {
        messages <- c(messages, "WARNING: Power ≥ 99.9% will require extremely large sample size")
      }
    }

    if (calc_mode == "calc_mde" && !is.null(n)) {
      if (n < 100) {
        messages <- c(messages, "NOTE: Small sample (< 100) may only detect large effects")
      }
    }
  }

  # Log validation failures
  if (!valid) {
    error_msgs <- messages[grepl("^ERROR:", messages)]
    if (length(error_msgs) > 0) {
      logger::log_warn(
        "Mediation validation failed",
        errors = paste(error_msgs, collapse = "; "),
        calc_mode = calc_mode %||% "unknown"
      )
    }
  }

  validation_result(valid, messages)
}
