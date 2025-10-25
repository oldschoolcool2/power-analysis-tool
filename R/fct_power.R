#' Power and Sample Size Calculation Functions
#'
#' Business logic for power/sample size calculations.
#' These are pure functions with no Shiny reactivity.

#' Solve for n1 Given Allocation Ratio (Unequal Groups)
#'
#' Solves for the sample size in group 1 when groups have unequal allocation.
#' Uses root-finding to determine n1 such that the power equals the target.
#'
#' @param h Cohen's h effect size
#' @param ratio Allocation ratio (n2/n1)
#' @param sig.level Significance level (alpha)
#' @param power Target power (0-1)
#' @param alternative "two.sided", "less", or "greater"
#'
#' @return Sample size for group 1
#'
#' @details
#' Uses uniroot() to solve for n1 where pwr.2p2n.test(...) = power.
#' Falls back to equal-n approximation if root-finding fails.
#'
#' @noRd
#' @importFrom pwr pwr.2p2n.test pwr.2p.test
solve_n1_for_ratio <- function(h, ratio, sig.level, power, alternative) {
  f <- function(n1) {
    n2 <- n1 * ratio
    pwr::pwr.2p2n.test(
      h = h, n1 = n1, n2 = n2, sig.level = sig.level,
      alternative = alternative
    )$power - power
  }
  tryCatch(
    {
      uniroot(f, c(2, 1e6), extendInt = "yes")$root
    },
    error = function(e) {
      # Fallback to equal-n approximation if root-finding fails
      warning("Root-finding failed; using equal-n approximation")
      pwr::pwr.2p.test(h = h, sig.level = sig.level, power = power, alternative = alternative)$n
    }
  )
}
