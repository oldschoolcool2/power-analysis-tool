#' Survival Equivalence/Non-Inferiority Functions
#'
#' Business logic and validation for time-to-event equivalence and non-inferiority testing
#'
#' @name fct_survival_equivalence
NULL

#' Validate Survival Equivalence/Non-Inferiority Inputs
#'
#' Validates all inputs for time-to-event equivalence and non-inferiority calculations.
#' Returns a structured validation result with errors, warnings, and notes.
#'
#' @param test_type Test type ("non-inferiority" or "equivalence")
#' @param calc_mode Calculation mode ("calc_n" or "calc_margin")
#' @param power Power level (0-100)
#' @param hr_expected Expected hazard ratio
#' @param hr_margin_ni Non-inferiority margin (HR > 1)
#' @param hr_margin_equiv Equivalence margin (HR > 1)
#' @param n_fixed Fixed sample size (for margin calculation)
#' @param prop_exposed Proportion exposed/treated (%)
#' @param event_rate Overall event rate (%)
#' @param allocation_ratio Allocation ratio (n2/n1)
#' @param alpha Significance level (0-1)
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
#' # Valid non-inferiority sample size calculation
#' validate_survival_equivalence_inputs(
#'   test_type = "non-inferiority", calc_mode = "calc_n",
#'   power = 80, hr_expected = 0.95, hr_margin_ni = 1.25,
#'   prop_exposed = 50, event_rate = 30, allocation_ratio = 1, alpha = 0.025
#' )
#'
#' # Invalid: expected HR worse than margin
#' validate_survival_equivalence_inputs(
#'   test_type = "non-inferiority", calc_mode = "calc_n",
#'   power = 80, hr_expected = 1.30, hr_margin_ni = 1.25,
#'   prop_exposed = 50, event_rate = 30, allocation_ratio = 1, alpha = 0.025
#' )
#' }
validate_survival_equivalence_inputs <- function(test_type = NULL,
                                                 calc_mode = NULL,
                                                 power = NULL,
                                                 hr_expected = NULL,
                                                 hr_margin_ni = NULL,
                                                 hr_margin_equiv = NULL,
                                                 n_fixed = NULL,
                                                 prop_exposed = NULL,
                                                 event_rate = NULL,
                                                 allocation_ratio = NULL,
                                                 alpha = NULL) {
  messages <- character(0)
  valid <- TRUE

  # Define allowlists for categorical inputs
  VALID_TEST_TYPES <- c("non-inferiority", "equivalence")
  VALID_CALC_MODES <- c("calc_n", "calc_margin")

  # Validate test type
  if (!is.null(test_type)) {
    if (!test_type %in% VALID_TEST_TYPES) {
      messages <- c(messages, "ERROR: Invalid test type. Must be 'non-inferiority' or 'equivalence'")
      valid <- FALSE
    }
  }

  # Validate calculation mode
  if (!is.null(calc_mode)) {
    if (!calc_mode %in% VALID_CALC_MODES) {
      messages <- c(messages, "ERROR: Invalid calculation mode. Must be 'calc_n' or 'calc_margin'")
      valid <- FALSE
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

  # Validate expected HR
  if (!is.null(hr_expected)) {
    if (is.na(hr_expected) || hr_expected <= 0) {
      messages <- c(messages, "ERROR: Expected hazard ratio must be positive")
      valid <- FALSE
    } else if (hr_expected > 10) {
      messages <- c(messages, "WARNING: Very large expected HR (> 10). Verify this is correct")
    }
  }

  # Validate non-inferiority margin
  if (!is.null(hr_margin_ni) && !is.na(hr_margin_ni)) {
    if (hr_margin_ni <= 1.0) {
      messages <- c(messages, "ERROR: Non-inferiority margin must be > 1.0 (e.g., 1.25 for 25% acceptable increase)")
      valid <- FALSE
    } else if (hr_margin_ni > 2.0) {
      messages <- c(messages, "WARNING: Very large non-inferiority margin (> 2.0 = 100% increase). This may be too liberal")
    } else if (hr_margin_ni >= 1.0 && hr_margin_ni < 1.15) {
      messages <- c(messages, "NOTE: Very stringent margin (< 15% increase). Large sample size may be required")
    } else if (hr_margin_ni >= 1.15 && hr_margin_ni <= 1.25) {
      messages <- c(messages, "NOTE: Stringent margin (15-25% increase). Typical for regulatory studies")
    } else if (hr_margin_ni > 1.50) {
      messages <- c(messages, "WARNING: Liberal margin (> 50% increase). May be difficult to justify clinically")
    }
  }

  # Validate equivalence margin
  if (!is.null(hr_margin_equiv) && !is.na(hr_margin_equiv)) {
    if (hr_margin_equiv <= 1.0) {
      messages <- c(messages, "ERROR: Equivalence margin must be > 1.0")
      valid <- FALSE
    } else if (hr_margin_equiv > 2.0) {
      messages <- c(messages, "WARNING: Very wide equivalence region (> ±100%). This may be too liberal")
    } else if (hr_margin_equiv >= 1.0 && hr_margin_equiv < 1.15) {
      messages <- c(messages, "NOTE: Narrow equivalence region. Large sample size may be required")
    } else if (hr_margin_equiv >= 1.15 && hr_margin_equiv <= 1.25) {
      messages <- c(messages, "NOTE: Moderate equivalence region. Typical for clinical trials")
    }
  }

  # Validate fixed sample size (for margin calculation)
  if (!is.null(n_fixed) && !is.na(n_fixed)) {
    if (n_fixed < 50) {
      messages <- c(messages, "ERROR: Sample size must be at least 50")
      valid <- FALSE
    } else if (n_fixed < 100) {
      messages <- c(messages, "WARNING: Small sample size (< 100) may have low power")
    }
  }

  # Validate proportion exposed
  if (!is.null(prop_exposed)) {
    if (is.na(prop_exposed) || prop_exposed <= 0 || prop_exposed >= 100) {
      messages <- c(messages, "ERROR: Proportion exposed must be between 0 and 100%")
      valid <- FALSE
    } else if (prop_exposed < 20 || prop_exposed > 80) {
      messages <- c(messages, "WARNING: Extreme allocation (< 20% or > 80%) may reduce power efficiency")
    }
  }

  # Validate event rate
  if (!is.null(event_rate)) {
    if (is.na(event_rate) || event_rate <= 0 || event_rate >= 100) {
      messages <- c(messages, "ERROR: Event rate must be between 0 and 100%")
      valid <- FALSE
    } else if (event_rate < 10) {
      messages <- c(messages, "WARNING: Low event rate (< 10%) will require very large sample size or long follow-up")
    } else if (event_rate > 70) {
      messages <- c(messages, "NOTE: High event rate (> 70%). Ensure follow-up time is appropriate")
    }
  }

  # Validate allocation ratio
  if (!is.null(allocation_ratio)) {
    if (is.na(allocation_ratio) || allocation_ratio <= 0) {
      messages <- c(messages, "ERROR: Allocation ratio must be positive")
      valid <- FALSE
    } else if (allocation_ratio < 0.5 || allocation_ratio > 2) {
      messages <- c(messages, "WARNING: Allocation ratio far from 1:1 may reduce power efficiency")
    }
  }

  # Validate alpha
  if (!is.null(alpha)) {
    if (is.na(alpha) || alpha <= 0 || alpha >= 1) {
      messages <- c(messages, "ERROR: Significance level must be between 0 and 1")
      valid <- FALSE
    } else if (!is.null(test_type)) {
      if (test_type == "non-inferiority" && alpha != 0.025) {
        messages <- c(messages, "NOTE: Alpha = 0.025 is typical for one-sided non-inferiority tests")
      } else if (test_type == "equivalence" && alpha != 0.05) {
        messages <- c(messages, "NOTE: Alpha = 0.05 is typical for equivalence tests (two one-sided tests)")
      }
    }
  }

  # Cross-field validations
  if (!is.null(test_type) && !is.null(hr_expected)) {
    if (test_type == "non-inferiority") {
      # For NI, expected HR should be ≤ 1 (new treatment not worse)
      if (!is.null(hr_margin_ni) && !is.na(hr_expected) && !is.na(hr_margin_ni)) {
        if (hr_expected >= hr_margin_ni) {
          messages <- c(messages, "ERROR: Expected HR must be better than (less than) the non-inferiority margin to demonstrate NI")
          valid <- FALSE
        } else if (hr_expected > hr_margin_ni * 0.9) {
          messages <- c(messages, "WARNING: Expected HR very close to margin. Power may be low")
        }
      }

      if (hr_expected > 1.2) {
        messages <- c(messages, "WARNING: Expected HR > 1.2 suggests new treatment may be worse. Consider if non-inferiority testing is appropriate")
      }
    } else if (test_type == "equivalence") {
      # For equivalence, expected HR should be very close to 1
      if (!is.null(hr_margin_equiv) && !is.na(hr_expected) && !is.na(hr_margin_equiv)) {
        lower_bound <- 1 / hr_margin_equiv
        upper_bound <- hr_margin_equiv

        if (hr_expected < lower_bound || hr_expected > upper_bound) {
          messages <- c(messages, "ERROR: Expected HR must be within equivalence bounds [",
                       round(lower_bound, 2), ", ", round(upper_bound, 2), "] to demonstrate equivalence")
          valid <- FALSE
        }
      }

      if (abs(hr_expected - 1.0) > 0.15) {
        messages <- c(messages, "WARNING: Expected HR notably different from 1.0. Consider if equivalence testing is appropriate")
      }
    }
  }

  # Sample size and event rate considerations
  if (!is.null(n_fixed) && !is.null(event_rate) && !is.na(n_fixed) && !is.na(event_rate)) {
    expected_events <- n_fixed * (event_rate / 100)
    if (expected_events < 100) {
      messages <- c(messages, "WARNING: Expected number of events (", round(expected_events),
                   ") < 100. Power may be low")
    }
  }

  # Log validation failures
  if (!valid) {
    error_msgs <- messages[grepl("^ERROR:", messages)]
    if (length(error_msgs) > 0) {
      logger::log_warn(
        "Survival equivalence validation failed",
        errors = paste(error_msgs, collapse = "; "),
        test_type = test_type %||% "unknown",
        calc_mode = calc_mode %||% "unknown"
      )
    }
  }

  validation_result(valid, messages)
}
