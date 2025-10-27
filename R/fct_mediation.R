#' Mediation Analysis Power Calculation Helper Functions
#'
#' @description Functions for calculating power and sample size for mediation analysis

# Effect Size Interpretation Thresholds for Mediation Analysis ----
# Path coefficient thresholds (standardized)
PATH_COEF_NEGLIGIBLE <- 0.1
PATH_COEF_SMALL <- 0.3
PATH_COEF_MEDIUM <- 0.5

# Indirect effect thresholds (based on Kenny, 2008)
INDIRECT_EFFECT_NEGLIGIBLE <- 0.01
INDIRECT_EFFECT_SMALL <- 0.09
INDIRECT_EFFECT_MEDIUM <- 0.25


#' Calculate Sobel Test Standard Error for Indirect Effect
#'
#' @param a Path coefficient X → M (treatment to mediator)
#' @param b Path coefficient M → Y|X (mediator to outcome controlling for X)
#' @param se_a Standard error of path a
#' @param se_b Standard error of path b
#'
#' @return Standard error of the indirect effect (a × b)
#' @noRd
calc_sobel_se <- function(a, b, se_a, se_b) {
  # Sobel's first-order approximation
  # SE(ab) = sqrt(a^2 * se_b^2 + b^2 * se_a^2)
  se_ab <- sqrt(a^2 * se_b^2 + b^2 * se_a^2)
  return(se_ab)
}

#' Calculate Power for Mediation Analysis (Sobel Test)
#'
#' @param n Sample size
#' @param a Path coefficient X → M
#' @param b Path coefficient M → Y|X
#' @param se_a Standard error of path a (if NULL, estimated from n)
#' @param se_b Standard error of path b (if NULL, estimated from n)
#' @param alpha Significance level (default 0.05)
#' @param alternative Test type: "two.sided" or "one.sided" (default "two.sided")
#'
#' @return Power to detect the indirect effect
#' @noRd
calc_mediation_power <- function(n, a, b, se_a = NULL, se_b = NULL,
                                  alpha = 0.05, alternative = "two.sided") {

  # Estimate standard errors if not provided
  # Conservative approximation: SE ≈ 1/sqrt(n) for standardized coefficients
  if (is.null(se_a)) {
    se_a <- 1 / sqrt(n)
  }
  if (is.null(se_b)) {
    se_b <- 1 / sqrt(n)
  }

  # Indirect effect
  ab <- a * b

  # Sobel standard error
  se_ab <- calc_sobel_se(a, b, se_a, se_b)

  # Non-centrality parameter
  ncp <- abs(ab) / se_ab

  # Critical value
  if (alternative == "two.sided") {
    z_crit <- qnorm(1 - alpha / 2)
  } else {
    z_crit <- qnorm(1 - alpha)
  }

  # Power calculation
  if (alternative == "two.sided") {
    power <- pnorm(ncp - z_crit) + pnorm(-ncp - z_crit)
  } else {
    power <- pnorm(ncp - z_crit)
  }

  return(power)
}

#' Calculate Required Sample Size for Mediation Analysis
#'
#' @param a Path coefficient X → M
#' @param b Path coefficient M → Y|X
#' @param power Desired power (default 0.80)
#' @param alpha Significance level (default 0.05)
#' @param alternative Test type: "two.sided" or "one.sided"
#'
#' @return Required sample size
#' @noRd
calc_mediation_n <- function(a, b, power = 0.80, alpha = 0.05,
                              alternative = "two.sided") {

  # Use uniroot to solve for n
  # Search range: from 10 to 100,000
  result <- tryCatch({
    uniroot(
      function(n) {
        calc_mediation_power(n, a, b, alpha = alpha, alternative = alternative) - power
      },
      lower = 10,
      upper = 100000,
      extendInt = "yes"
    )
  }, error = function(e) {
    return(NULL)
  })

  if (is.null(result)) {
    return(NA)
  }

  return(ceiling(result$root))
}

#' Calculate Minimal Detectable Indirect Effect
#'
#' @param n Available sample size
#' @param a Path coefficient X → M
#' @param power Desired power
#' @param alpha Significance level
#' @param alternative Test type
#'
#' @return Minimal detectable b coefficient (given a)
#' @noRd
calc_mediation_mde <- function(n, a, power = 0.80, alpha = 0.05,
                                alternative = "two.sided") {

  # Use uniroot to solve for b
  # Search range for b: from 0.01 to 2.0 (standardized coefficients)
  result <- tryCatch({
    uniroot(
      function(b) {
        calc_mediation_power(n, a, b, alpha = alpha, alternative = alternative) - power
      },
      lower = 0.01,
      upper = 2.0,
      extendInt = "yes"
    )
  }, error = function(e) {
    return(NULL)
  })

  if (is.null(result)) {
    return(NA)
  }

  return(result$root)
}

#' Interpret Effect Size for Path Coefficients
#'
#' @param coef Path coefficient value (standardized)
#'
#' @return Character string with interpretation
#' @noRd
interpret_path_coefficient <- function(coef) {
  abs_coef <- abs(coef)

  if (abs_coef < PATH_COEF_NEGLIGIBLE) {
    return("Negligible")
  } else if (abs_coef < PATH_COEF_SMALL) {
    return("Small")
  } else if (abs_coef < PATH_COEF_MEDIUM) {
    return("Medium")
  } else {
    return("Large")
  }
}

#' Interpret Indirect Effect Size
#'
#' @param ab Indirect effect (a × b)
#'
#' @return Character string with interpretation
#' @noRd
interpret_indirect_effect <- function(ab) {
  abs_ab <- abs(ab)

  if (abs_ab < INDIRECT_EFFECT_NEGLIGIBLE) {
    return("Negligible")
  } else if (abs_ab < INDIRECT_EFFECT_SMALL) {
    return("Small")
  } else if (abs_ab < INDIRECT_EFFECT_MEDIUM) {
    return("Medium")
  } else {
    return("Large")
  }
}

#' Format Mediation Results for Display
#'
#' @param a Path a coefficient
#' @param b Path b coefficient
#' @param c_prime Direct effect
#' @param n Sample size
#' @param power Power (if calculated)
#' @param alpha Significance level
#'
#' @return HTML formatted string with results
#' @noRd
format_mediation_results <- function(a, b, c_prime = NULL, n, power = NULL, alpha = 0.05) {

  # Calculate indirect effect
  ab <- a * b

  # Interpretations
  a_interp <- interpret_path_coefficient(a)
  b_interp <- interpret_path_coefficient(b)
  ab_interp <- interpret_indirect_effect(ab)

  # Build HTML
  result_html <- paste0(
    "<div class='mediation-results'>",
    "<h4>Mediation Model Summary</h4>",
    "<div class='path-diagram'>",
    "<p><strong>Path Coefficients:</strong></p>",
    "<ul>",
    "<li><strong>a</strong> (X → M): ", format_numeric(a, 3),
    " <span class='interpretation'>(", a_interp, ")</span></li>",
    "<li><strong>b</strong> (M → Y|X): ", format_numeric(b, 3),
    " <span class='interpretation'>(", b_interp, ")</span></li>"
  )

  if (!is.null(c_prime)) {
    c_interp <- interpret_path_coefficient(c_prime)
    result_html <- paste0(
      result_html,
      "<li><strong>c'</strong> (X → Y|M, direct): ", format_numeric(c_prime, 3),
      " <span class='interpretation'>(", c_interp, ")</span></li>"
    )
  }

  result_html <- paste0(
    result_html,
    "</ul>",
    "<p><strong>Indirect Effect (a × b):</strong> ", format_numeric(ab, 3),
    " <span class='interpretation highlight'>(", ab_interp, ")</span></p>"
  )

  if (!is.null(power)) {
    result_html <- paste0(
      result_html,
      "<p><strong>Power:</strong> ", format_numeric(power * 100, 1),
      "% (α = ", alpha, ")</p>"
    )
  }

  result_html <- paste0(
    result_html,
    "<p><strong>Sample Size:</strong> N = ", format_numeric(n, 0), "</p>",
    "</div>",
    "</div>"
  )

  return(HTML(result_html))
}

#' Generate Sample Size Sequence for Mediation Power Curve
#'
#' @param n_current Current sample size
#' @param n_points Number of points in sequence (default 50)
#'
#' @return Numeric vector of sample sizes
#' @noRd
generate_mediation_n_sequence <- function(n_current, n_points = 50) {
  # Range: 50% to 200% of current N
  n_min <- max(10, ceiling(n_current * 0.5))
  n_max <- ceiling(n_current * 2.0)

  # Generate sequence
  seq(n_min, n_max, length.out = n_points)
}
