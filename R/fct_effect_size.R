#' Effect Size Calculation Functions
#'
#' Business logic for calculating effect measures (RR, OR, RD) from proportions.
#' These are pure functions with no Shiny reactivity.

#' Calculate Effect Measures from Two Proportions
#'
#' Calculates Risk Difference (RD), Relative Risk (RR), and Odds Ratio (OR)
#' from two proportions. Safely handles edge cases like p2 = 0.
#'
#' @param p1 Proportion in group 1 (0-1)
#' @param p2 Proportion in group 2 (0-1)
#'
#' @return List with three elements:
#'   \item{risk_diff}{Risk difference (p1 - p2) as percentage}
#'   \item{relative_risk}{Relative risk (p1 / p2), NA if p2 = 0}
#'   \item{odds_ratio}{Odds ratio, NA if either p is 0 or 1}
#'
#' @examples
#' calc_effect_measures(0.15, 0.10)
#' # $risk_diff: 5
#' # $relative_risk: 1.5
#' # $odds_ratio: 1.625
#'
#' @noRd
calc_effect_measures <- function(p1, p2) {
  # Validate inputs
  if (is.null(p1) || is.null(p2) || length(p1) == 0 || length(p2) == 0) {
    return(list(RD = NA_real_, RR = NA_real_, OR = NA_real_))
  }
  
  # Take first element if vectors
  if (length(p1) > 1) p1 <- p1[1]
  if (length(p2) > 1) p2 <- p2[1]
  
  # Convert to numeric and validate
  p1 <- as.numeric(p1)
  p2 <- as.numeric(p2)
  
  if (is.na(p1) || is.na(p2)) {
    return(list(RD = NA_real_, RR = NA_real_, OR = NA_real_))
  }
  
  risk_diff <- (p1 - p2) * 100

  # Relative Risk: undefined when p2 = 0
  relative_risk <- if (isTRUE(all.equal(p2, 0))) NA_real_ else p1 / p2

  # Odds Ratio: undefined when either rate is 0% or 100%
  odds1 <- if (isTRUE(all.equal(p1, 0)) || isTRUE(all.equal(p1, 1))) NA_real_ else p1 / (1 - p1)
  odds2 <- if (isTRUE(all.equal(p2, 0)) || isTRUE(all.equal(p2, 1))) NA_real_ else p2 / (1 - p2)
  odds_ratio <- if (is.na(odds1) || is.na(odds2)) NA_real_ else odds1 / odds2

  # Return with uppercase keys to match format_effect_measures expectations
  list(
    RD = risk_diff,
    RR = relative_risk,
    OR = odds_ratio
  )
}
