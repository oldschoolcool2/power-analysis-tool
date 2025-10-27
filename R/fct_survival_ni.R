#' Statistical Functions for Time-to-Event Equivalence/Non-Inferiority Testing
#'
#' Functions for sample size and power calculations for time-to-event equivalence
#' and non-inferiority studies using hazard ratio-based methods.
#'
#' @name survival_ni
NULL

# Hazard Ratio Margin Interpretation Thresholds ----
# Thresholds for clinical interpretation of HR margins in non-inferiority/equivalence testing
HR_MARGIN_VERY_STRINGENT <- 1.15
HR_MARGIN_STRINGENT <- 1.25
HR_MARGIN_MODERATE <- 1.50

# Numerical tolerance for log-scale comparisons
LOG_EFFECT_TOLERANCE <- 1e-10


#' Calculate Sample Size for Time-to-Event Non-Inferiority Test
#'
#' Calculates required sample size for a non-inferiority test using hazard ratios
#' based on the method of Schoenfeld/Freedman adapted for non-inferiority testing.
#'
#' @param power Desired power (0-1)
#' @param hr_expected Expected true hazard ratio
#' @param hr_margin Non-inferiority margin (on HR scale, e.g., 1.25)
#' @param k Proportion in exposed/treatment group (0-1)
#' @param pE Overall event rate (0-1)
#' @param alpha Significance level (default 0.025 for one-sided NI test)
#' @param ratio Allocation ratio n2/n1 (default 1 for equal allocation)
#'
#' @return Total sample size required
#' @export
ssize_survival_ni <- function(power, hr_expected, hr_margin, k, pE, alpha = 0.025, ratio = 1) {
  logger::log_debug(
    "ssize_survival_ni called",
    power = power,
    hr_expected = hr_expected,
    hr_margin = hr_margin,
    k = k,
    pE = pE,
    alpha = alpha,
    ratio = ratio
  )

  tryCatch(
    {
      # Validate inputs
      if (power <= 0 || power >= 1) stop("Power must be between 0 and 1")
      if (hr_expected <= 0) stop("Expected HR must be positive")
      if (hr_margin <= 0) stop("NI margin must be positive")
      if (k <= 0 || k >= 1) stop("Proportion exposed must be between 0 and 1")
      if (pE <= 0 || pE >= 1) stop("Event rate must be between 0 and 1")
      if (alpha <= 0 || alpha >= 1) stop("Alpha must be between 0 and 1")
      if (ratio <= 0) stop("Allocation ratio must be positive")

  # Convert to z-scores
  z_alpha <- qnorm(1 - alpha)  # One-sided test for NI
  z_beta <- qnorm(power)

  # Effect size: difference between expected HR and margin on log scale
  # For NI test: H0: log(HR) >= log(margin) vs H1: log(HR) < log(margin)
  log_effect <- log(hr_expected) - log(hr_margin)

      # If expected HR is worse than margin, we cannot demonstrate NI
      if (abs(log_effect) < LOG_EFFECT_TOLERANCE) {
        logger::log_warn("ssize_survival_ni: expected HR equals margin", hr_expected = hr_expected, hr_margin = hr_margin)
        warning("Expected HR equals the margin - cannot demonstrate non-inferiority")
        return(Inf)
      }

      # Calculate required number of events using Schoenfeld formula adapted for NI
      # d = (z_alpha + z_beta)^2 / (log_effect)^2
      d_events <- ((z_alpha + z_beta)^2) / (log_effect^2)

      # Convert events to total sample size
      # Accounting for allocation ratio
      # Adjusted allocation: k_adj for unequal allocation
      k_adj <- ratio / (1 + ratio)

      # Total N needed to observe d events
      # n = d / (pE * variance_factor)
      # For Cox model: variance_factor = 4 * k * (1-k) for equal allocation
      # For unequal allocation: variance_factor = 4 * k_adj * (1-k_adj)
      variance_factor <- 4 * k_adj * (1 - k_adj)

      n_total <- d_events / (pE * variance_factor)
      result <- ceiling(n_total)

      logger::log_debug("ssize_survival_ni completed", n_total = result, d_events = d_events)
      return(result)
    },
    error = function(e) {
      logger::log_error(
        "ssize_survival_ni failed",
        error_class = class(e)[1],
        error_msg = conditionMessage(e),
        hr_expected = hr_expected,
        hr_margin = hr_margin
      )
      stop(e)
    }
  )
}

#' Calculate Sample Size for Time-to-Event Equivalence Test
#'
#' Calculates required sample size for an equivalence test using hazard ratios.
#' Equivalence requires demonstrating both HR < upper_margin AND HR > lower_margin.
#'
#' @param power Desired power (0-1)
#' @param hr_expected Expected true hazard ratio (should be near 1.0 for equivalence)
#' @param hr_lower Lower equivalence margin (e.g., 0.8)
#' @param hr_upper Upper equivalence margin (e.g., 1.25)
#' @param k Proportion in exposed/treatment group (0-1)
#' @param pE Overall event rate (0-1)
#' @param alpha Significance level (default 0.05 for two one-sided tests)
#' @param ratio Allocation ratio n2/n1 (default 1)
#'
#' @return Total sample size required
#' @export
ssize_survival_equiv <- function(power, hr_expected, hr_lower, hr_upper, k, pE,
                                  alpha = 0.05, ratio = 1) {

  # Validate inputs
  if (power <= 0 || power >= 1) stop("Power must be between 0 and 1")
  if (hr_expected <= 0) stop("Expected HR must be positive")
  if (hr_lower <= 0 || hr_upper <= 0) stop("Equivalence margins must be positive")
  if (hr_lower >= hr_upper) stop("Lower margin must be less than upper margin")
  if (k <= 0 || k >= 1) stop("Proportion exposed must be between 0 and 1")
  if (pE <= 0 || pE >= 1) stop("Event rate must be between 0 and 1")
  if (alpha <= 0 || alpha >= 1) stop("Alpha must be between 0 and 1")

  # For equivalence, use two one-sided tests (TOST)
  # Need to test both:
  #   1. HR < upper_margin (NI test)
  #   2. HR > lower_margin (reverse NI test)

  # Calculate sample size for each test
  # Test 1: Upper bound (regular NI)
  n_upper <- ssize_survival_ni(power, hr_expected, hr_upper, k, pE, alpha/2, ratio)

  # Test 2: Lower bound (reverse NI - HR must be > lower margin)
  # This is equivalent to testing 1/HR < 1/lower_margin
  hr_expected_inv <- 1 / hr_expected
  hr_margin_inv <- 1 / hr_lower
  n_lower <- ssize_survival_ni(power, hr_expected_inv, hr_margin_inv, k, pE, alpha/2, ratio)

  # Take the maximum (more conservative)
  return(max(n_upper, n_lower))
}

#' Calculate Power for Time-to-Event Non-Inferiority Test
#'
#' Calculates power for a non-inferiority test given sample size and parameters.
#'
#' @param n Total sample size
#' @param hr_expected Expected true hazard ratio
#' @param hr_margin Non-inferiority margin (on HR scale)
#' @param k Proportion in exposed/treatment group (0-1)
#' @param pE Overall event rate (0-1)
#' @param alpha Significance level (default 0.025)
#' @param ratio Allocation ratio n2/n1 (default 1)
#'
#' @return Power (0-1)
#' @export
power_survival_ni <- function(n, hr_expected, hr_margin, k, pE, alpha = 0.025, ratio = 1) {

  # Validate inputs
  if (n <= 0) stop("Sample size must be positive")
  if (hr_expected <= 0) stop("Expected HR must be positive")
  if (hr_margin <= 0) stop("NI margin must be positive")
  if (k <= 0 || k >= 1) stop("Proportion exposed must be between 0 and 1")
  if (pE <= 0 || pE >= 1) stop("Event rate must be between 0 and 1")
  if (alpha <= 0 || alpha >= 1) stop("Alpha must be between 0 and 1")

  # Z-score for alpha
  z_alpha <- qnorm(1 - alpha)

  # Effect size
  log_effect <- log(hr_expected) - log(hr_margin)

  # If expected HR equals or exceeds margin, power is undefined
  if (abs(log_effect) < LOG_EFFECT_TOLERANCE || hr_expected >= hr_margin) {
    return(0)
  }

  # Adjusted allocation
  k_adj <- ratio / (1 + ratio)
  variance_factor <- 4 * k_adj * (1 - k_adj)

  # Expected number of events
  d_expected <- n * pE * variance_factor

  # Standard error of log(HR)
  se_log_hr <- 1 / sqrt(d_expected)

  # Non-centrality parameter
  ncp <- log_effect / se_log_hr

  # Power calculation
  z_beta <- ncp - z_alpha
  power <- pnorm(z_beta)

  return(power)
}

#' Calculate Minimal Detectable NI Margin
#'
#' Calculates the minimal detectable non-inferiority margin given sample size and power.
#'
#' @param n Total sample size
#' @param hr_expected Expected true hazard ratio
#' @param power Desired power (0-1)
#' @param k Proportion in exposed/treatment group (0-1)
#' @param pE Overall event rate (0-1)
#' @param alpha Significance level (default 0.025)
#' @param ratio Allocation ratio n2/n1 (default 1)
#'
#' @return Minimal detectable NI margin (on HR scale)
#' @export
mde_survival_ni <- function(n, hr_expected, power, k, pE, alpha = 0.025, ratio = 1) {

  # Validate inputs
  if (n <= 0) stop("Sample size must be positive")
  if (hr_expected <= 0) stop("Expected HR must be positive")
  if (power <= 0 || power >= 1) stop("Power must be between 0 and 1")
  if (k <= 0 || k >= 1) stop("Proportion exposed must be between 0 and 1")
  if (pE <= 0 || pE >= 1) stop("Event rate must be between 0 and 1")
  if (alpha <= 0 || alpha >= 1) stop("Alpha must be between 0 and 1")

  # Z-scores
  z_alpha <- qnorm(1 - alpha)
  z_beta <- qnorm(power)

  # Adjusted allocation
  k_adj <- ratio / (1 + ratio)
  variance_factor <- 4 * k_adj * (1 - k_adj)

  # Expected number of events
  d_expected <- n * pE * variance_factor

  # Standard error of log(HR)
  se_log_hr <- 1 / sqrt(d_expected)

  # Solve for margin
  # log(margin) = log(hr_expected) - (z_alpha + z_beta) * se_log_hr
  log_margin <- log(hr_expected) + (z_alpha + z_beta) * se_log_hr

  margin <- exp(log_margin)

  return(margin)
}

#' Interpret Hazard Ratio Margin
#'
#' Provides interpretation of a hazard ratio margin for non-inferiority/equivalence testing.
#'
#' @param hr_margin Hazard ratio margin
#' @param test_type "non-inferiority" or "equivalence"
#'
#' @return HTML formatted interpretation text
#' @export
interpret_hr_margin <- function(hr_margin, test_type = "non-inferiority") {

  if (test_type == "non-inferiority") {
    if (hr_margin < HR_MARGIN_VERY_STRINGENT) {
      severity <- "very stringent"
      color <- "#2e7d32"
    } else if (hr_margin < HR_MARGIN_STRINGENT) {
      severity <- "stringent"
      color <- "#66bb6a"
    } else if (hr_margin < HR_MARGIN_MODERATE) {
      severity <- "moderate"
      color <- "#ff9800"
    } else {
      severity <- "liberal"
      color <- "#d32f2f"
    }

    pct_increase <- round((hr_margin - 1) * 100, 1)

    interpretation <- paste0(
      "A margin of HR = ", round(hr_margin, 3), " means you are willing to accept up to a ",
      pct_increase, "% increase in hazard rate as 'non-inferior'. ",
      "This is considered a <strong style='color: ", color, ";'>", severity, "</strong> margin."
    )

  } else {  # equivalence
    if (hr_margin < HR_MARGIN_VERY_STRINGENT) {
      severity <- "very narrow"
      color <- "#2e7d32"
    } else if (hr_margin < HR_MARGIN_STRINGENT) {
      severity <- "narrow"
      color <- "#66bb6a"
    } else if (hr_margin < HR_MARGIN_MODERATE) {
      severity <- "moderate"
      color <- "#ff9800"
    } else {
      severity <- "wide"
      color <- "#d32f2f"
    }

    lower <- round(1 / hr_margin, 3)
    upper <- round(hr_margin, 3)

    interpretation <- paste0(
      "Equivalence margins of HR = [", lower, ", ", upper, "] means you will declare ",
      "equivalence if the true HR lies within this range. ",
      "This is considered a <strong style='color: ", color, ";'>", severity, "</strong> equivalence region."
    )
  }

  return(HTML(interpretation))
}

#' Calculate Number of Events Needed
#'
#' Calculates the required number of events for a time-to-event NI/equivalence test.
#'
#' @param power Desired power
#' @param hr_expected Expected HR
#' @param hr_margin NI margin
#' @param alpha Alpha level
#'
#' @return Number of events required
#' @export
events_survival_ni <- function(power, hr_expected, hr_margin, alpha = 0.025) {
  z_alpha <- qnorm(1 - alpha)
  z_beta <- qnorm(power)
  log_effect <- log(hr_expected) - log(hr_margin)

  if (abs(log_effect) < LOG_EFFECT_TOLERANCE) {
    return(Inf)
  }

  d_events <- ((z_alpha + z_beta)^2) / (log_effect^2)
  return(ceiling(d_events))
}
