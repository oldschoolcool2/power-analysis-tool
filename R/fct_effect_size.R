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
  risk_diff <- (p1 - p2) * 100

  # Relative Risk: undefined when p2 = 0
  relative_risk <- if (p2 == 0) NA_real_ else p1 / p2

  # Odds Ratio: undefined when either rate is 0% or 100%
  odds1 <- if (p1 %in% c(0, 1)) NA_real_ else p1 / (1 - p1)
  odds2 <- if (p2 %in% c(0, 1)) NA_real_ else p2 / (1 - p2)
  odds_ratio <- if (is.na(odds1) || is.na(odds2)) NA_real_ else odds1 / odds2

  list(
    risk_diff = risk_diff,
    relative_risk = relative_risk,
    odds_ratio = odds_ratio
  )
}
