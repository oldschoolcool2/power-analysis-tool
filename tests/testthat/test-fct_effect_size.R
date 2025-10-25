# Tests for Effect Size Calculation Functions
# File: R/fct_effect_size.R

test_that("calc_effect_measures works with normal proportions", {
  result <- calc_effect_measures(0.15, 0.10)

  expect_type(result, "list")
  expect_named(result, c("risk_diff", "relative_risk", "odds_ratio"))

  # Risk difference: (0.15 - 0.10) * 100 = 5%
  expect_equal(result$risk_diff, 5)

  # Relative risk: 0.15 / 0.10 = 1.5
  expect_equal(result$relative_risk, 1.5)

  # Odds ratio: (0.15/0.85) / (0.10/0.90) ≈ 1.588
  expect_gt(result$odds_ratio, 1.5)
  expect_lt(result$odds_ratio, 1.7)
})

test_that("calc_effect_measures handles p2 = 0", {
  result <- calc_effect_measures(0.1, 0)

  # RR is undefined when p2 = 0
  expect_true(is.na(result$relative_risk))

  # RD should still work
  expect_equal(result$risk_diff, 10)

  # OR is undefined when p2 = 0
  expect_true(is.na(result$odds_ratio))
})

test_that("calc_effect_measures handles p1 = 0", {
  result <- calc_effect_measures(0, 0.1)

  # RR = 0 / 0.1 = 0
  expect_equal(result$relative_risk, 0)

  # RD = (0 - 0.1) * 100 = -10
  expect_equal(result$risk_diff, -10)

  # OR is undefined when p1 = 0
  expect_true(is.na(result$odds_ratio))
})

test_that("calc_effect_measures handles p1 = 1", {
  result <- calc_effect_measures(1, 0.5)

  # RR = 1 / 0.5 = 2
  expect_equal(result$relative_risk, 2)

  # RD = (1 - 0.5) * 100 = 50
  expect_equal(result$risk_diff, 50)

  # OR is undefined when p1 = 1
  expect_true(is.na(result$odds_ratio))
})

test_that("calc_effect_measures handles p2 = 1", {
  result <- calc_effect_measures(0.5, 1)

  # RR = 0.5 / 1 = 0.5
  expect_equal(result$relative_risk, 0.5)

  # RD = (0.5 - 1) * 100 = -50
  expect_equal(result$risk_diff, -50)

  # OR is undefined when p2 = 1
  expect_true(is.na(result$odds_ratio))
})

test_that("calc_effect_measures handles equal proportions", {
  result <- calc_effect_measures(0.3, 0.3)

  # RR = 1
  expect_equal(result$relative_risk, 1)

  # RD = 0
  expect_equal(result$risk_diff, 0)

  # OR = 1
  expect_equal(result$odds_ratio, 1)
})

test_that("calc_effect_measures protective effect", {
  result <- calc_effect_measures(0.05, 0.15)

  # RR < 1 (protective)
  expect_lt(result$relative_risk, 1)
  expect_gt(result$relative_risk, 0)

  # RD < 0 (benefit)
  expect_equal(result$risk_diff, -10)

  # OR < 1
  expect_lt(result$odds_ratio, 1)
  expect_gt(result$odds_ratio, 0)
})

test_that("calc_effect_measures with very small proportions", {
  result <- calc_effect_measures(0.001, 0.0005)

  # Should still calculate correctly
  expect_equal(result$risk_diff, 0.05)
  expect_equal(result$relative_risk, 2)
  expect_type(result$odds_ratio, "double")
  expect_false(is.na(result$odds_ratio))
})

test_that("calc_effect_measures with large effect", {
  result <- calc_effect_measures(0.80, 0.20)

  # Large RR
  expect_equal(result$relative_risk, 4)

  # Large RD
  expect_equal(result$risk_diff, 60)

  # Large OR
  expect_gt(result$odds_ratio, 10)
})

test_that("calc_effect_measures returns proper list structure", {
  result <- calc_effect_measures(0.3, 0.2)

  expect_length(result, 3)
  expect_true(all(c("risk_diff", "relative_risk", "odds_ratio") %in% names(result)))
  expect_type(result$risk_diff, "double")
  expect_type(result$relative_risk, "double")
  expect_type(result$odds_ratio, "double")
})

test_that("calc_effect_measures is consistent with manual calculation", {
  # Manual calculation for p1=0.25, p2=0.15
  p1 <- 0.25
  p2 <- 0.15

  rd_manual <- (p1 - p2) * 100  # 10
  rr_manual <- p1 / p2  # 1.667
  or_manual <- (p1/(1-p1)) / (p2/(1-p2))  # 1.882

  result <- calc_effect_measures(p1, p2)

  expect_equal(result$risk_diff, rd_manual)
  expect_equal(result$relative_risk, rr_manual, tolerance = 0.001)
  expect_equal(result$odds_ratio, or_manual, tolerance = 0.001)
})
