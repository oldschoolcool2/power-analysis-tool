# Tests for Power and Sample Size Calculation Functions
# File: R/fct_power.R

test_that("solve_n1_for_ratio works with equal allocation", {
  # For ratio = 1, should match equal-n calculation
  h <- 0.5
  ratio <- 1
  sig.level <- 0.05
  power <- 0.80
  alternative <- "two.sided"

  result <- solve_n1_for_ratio(h, ratio, sig.level, power, alternative)

  # Should be a positive number
  expect_type(result, "double")
  expect_gt(result, 0)

  # Should be reasonable (for h=0.5, typically n~63 per group)
  expect_gt(result, 50)
  expect_lt(result, 100)
})

test_that("solve_n1_for_ratio works with unequal allocation (2:1)", {
  h <- 0.5
  ratio <- 2  # n2 = 2*n1
  sig.level <- 0.05
  power <- 0.80
  alternative <- "two.sided"

  result <- solve_n1_for_ratio(h, ratio, sig.level, power, alternative)

  expect_type(result, "double")
  expect_gt(result, 0)

  # With 2:1 allocation, n1 should be smaller than equal allocation
  equal_n <- pwr::pwr.2p.test(h = h, sig.level = sig.level, power = power)$n
  expect_lt(result, equal_n)
})

test_that("solve_n1_for_ratio works with unequal allocation (1:2)", {
  h <- 0.5
  ratio <- 0.5  # n2 = 0.5*n1 (i.e., n1 > n2)
  sig.level <- 0.05
  power <- 0.80
  alternative <- "two.sided"

  result <- solve_n1_for_ratio(h, ratio, sig.level, power, alternative)

  expect_type(result, "double")
  expect_gt(result, 0)

  # With 1:2 allocation (more in group 1), n1 should be larger or similar
  equal_n <- pwr::pwr.2p.test(h = h, sig.level = sig.level, power = power)$n
  expect_gte(result, equal_n * 0.99)  # Allow small tolerance due to numerical methods
})

test_that("solve_n1_for_ratio works with different effect sizes", {
  # Small effect size should require larger n
  h_small <- 0.2
  h_large <- 0.8

  n_small <- solve_n1_for_ratio(h_small, ratio = 1, sig.level = 0.05, power = 0.80, alternative = "two.sided")
  n_large <- solve_n1_for_ratio(h_large, ratio = 1, sig.level = 0.05, power = 0.80, alternative = "two.sided")

  expect_gt(n_small, n_large)
})

test_that("solve_n1_for_ratio works with different power levels", {
  # Higher power should require larger n
  power_low <- 0.70
  power_high <- 0.90

  n_low <- solve_n1_for_ratio(h = 0.5, ratio = 1, sig.level = 0.05, power = power_low, alternative = "two.sided")
  n_high <- solve_n1_for_ratio(h = 0.5, ratio = 1, sig.level = 0.05, power = power_high, alternative = "two.sided")

  expect_gt(n_high, n_low)
})

test_that("solve_n1_for_ratio works with different alpha levels", {
  # Stricter alpha should require larger n
  alpha_lenient <- 0.10
  alpha_strict <- 0.01

  n_lenient <- solve_n1_for_ratio(h = 0.5, ratio = 1, sig.level = alpha_lenient, power = 0.80, alternative = "two.sided")
  n_strict <- solve_n1_for_ratio(h = 0.5, ratio = 1, sig.level = alpha_strict, power = 0.80, alternative = "two.sided")

  expect_gt(n_strict, n_lenient)
})

test_that("solve_n1_for_ratio works with one-sided tests", {
  h <- 0.5
  ratio <- 1
  sig.level <- 0.05
  power <- 0.80

  n_two_sided <- solve_n1_for_ratio(h, ratio, sig.level, power, alternative = "two.sided")
  n_one_sided <- solve_n1_for_ratio(h, ratio, sig.level, power, alternative = "greater")

  # One-sided test should require smaller n
  expect_lt(n_one_sided, n_two_sided)
})

test_that("solve_n1_for_ratio handles extreme allocation ratios", {
  h <- 0.5
  sig.level <- 0.05
  power <- 0.80

  # Very unbalanced allocation (5:1)
  result <- solve_n1_for_ratio(h, ratio = 5, sig.level, power, "two.sided")

  expect_type(result, "double")
  expect_gt(result, 0)
  expect_lt(result, 1e6)  # Should not explode to infinity
})

test_that("solve_n1_for_ratio handles very small effect sizes", {
  h <- 0.05  # Very small effect
  ratio <- 1
  sig.level <- 0.05
  power <- 0.80

  result <- solve_n1_for_ratio(h, ratio, sig.level, power, "two.sided")

  expect_type(result, "double")
  expect_gt(result, 100)  # Should require large sample
})

test_that("solve_n1_for_ratio handles very large effect sizes", {
  h <- 1.5  # Very large effect
  ratio <- 1
  sig.level <- 0.05
  power <- 0.80

  result <- solve_n1_for_ratio(h, ratio, sig.level, power, "two.sided")

  expect_type(result, "double")
  expect_gt(result, 2)  # Should require minimal sample
  expect_lt(result, 50)
})

test_that("solve_n1_for_ratio gives warnings when appropriate", {
  # This might trigger the fallback warning in some edge cases
  # Testing that it doesn't error out
  h <- 0.01  # Extremely small effect
  ratio <- 10  # Very unbalanced

  expect_no_error({
    result <- solve_n1_for_ratio(h, ratio, sig.level = 0.05, power = 0.80, "two.sided")
  })
})

test_that("solve_n1_for_ratio is consistent with pwr package for equal allocation", {
  h <- 0.5
  ratio <- 1
  sig.level <- 0.05
  power <- 0.80

  n_custom <- solve_n1_for_ratio(h, ratio, sig.level, power, "two.sided")
  n_pwr <- pwr::pwr.2p.test(h = h, sig.level = sig.level, power = power)$n

  # Should be very close (within 1% tolerance)
  expect_equal(n_custom, n_pwr, tolerance = 0.01)
})

test_that("solve_n1_for_ratio produces n1 that gives correct power", {
  h <- 0.5
  ratio <- 1.5
  sig.level <- 0.05
  power_target <- 0.80

  n1 <- solve_n1_for_ratio(h, ratio, sig.level, power_target, "two.sided")
  n2 <- n1 * ratio

  # Verify that this n1 and n2 produce the target power
  actual_power <- pwr::pwr.2p2n.test(h = h, n1 = n1, n2 = n2, sig.level = sig.level)$power

  # Should match within 1%
  expect_equal(actual_power, power_target, tolerance = 0.01)
})
