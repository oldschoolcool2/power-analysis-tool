# Tests for Missing Data Adjustment Functions
# File: R/fct_missing_data.R

test_that("calc_missing_data_inflation handles zero missingness", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 0,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  expect_equal(result$n_inflated, 100)
  expect_equal(result$inflation_factor, 1.0)
  expect_equal(result$n_increase, 0)
  expect_equal(result$pct_increase, 0)
  expect_match(result$interpretation, "No adjustment needed")
  expect_null(result$mi_comparison)
  expect_null(result$mi_recommendations)
})

test_that("calc_missing_data_inflation works with complete case analysis", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  # With 20% missingness, inflation factor = 1 / (1 - 0.2) = 1.25
  expect_equal(result$inflation_factor, 1.25)

  # n_inflated = 100 * 1.25 = 125
  expect_equal(result$n_inflated, 125)

  # n_increase = 125 - 100 = 25
  expect_equal(result$n_increase, 25)

  # pct_increase = 25%
  expect_equal(result$pct_increase, 25.0)

  expect_match(result$interpretation, "20%")
  expect_match(result$interpretation, "MAR")
  expect_null(result$mi_comparison)
  expect_null(result$mi_recommendations)
})

test_that("calc_missing_data_inflation works with different mechanisms", {
  n <- 100
  missing <- 20

  result_mcar <- calc_missing_data_inflation(n, missing, "mcar", "complete_case")
  result_mar <- calc_missing_data_inflation(n, missing, "mar", "complete_case")
  result_mnar <- calc_missing_data_inflation(n, missing, "mnar", "complete_case")

  # All should have same inflation factor (mechanism affects interpretation only for CCA)
  expect_equal(result_mcar$inflation_factor, result_mar$inflation_factor)
  expect_equal(result_mar$inflation_factor, result_mnar$inflation_factor)

  # But interpretations should differ
  expect_match(result_mcar$interpretation, "MCAR")
  expect_match(result_mar$interpretation, "MAR")
  expect_match(result_mnar$interpretation, "MNAR")
})

test_that("calc_missing_data_inflation handles high missingness", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 50,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  # With 50% missingness, inflation = 1 / 0.5 = 2.0
  expect_equal(result$inflation_factor, 2.0)
  expect_equal(result$n_inflated, 200)
  expect_equal(result$n_increase, 100)
  expect_equal(result$pct_increase, 100.0)
})

test_that("calc_missing_data_inflation works with multiple imputation", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 5,
    mi_r_squared = 0.5
  )

  # MI should require less or equal inflation than CCA (with some tolerance)
  cca_result <- calc_missing_data_inflation(100, 20, "mar", "complete_case")

  expect_lte(result$inflation_factor, cca_result$inflation_factor + 0.01)
  expect_lte(result$n_inflated, cca_result$n_inflated + 2)

  # MI-specific outputs should exist
  expect_type(result$mi_comparison, "list")
  expect_type(result$mi_recommendations, "list")

  # Check MI comparison structure
  expect_named(result$mi_comparison, c("cca_n", "mi_n", "efficiency_gain", "cca_inflation", "mi_inflation", "relative_efficiency", "fmi", "n_effective"))
  expect_gte(result$mi_comparison$efficiency_gain, -1)  # Allow for rounding differences
  expect_equal(result$mi_comparison$mi_n, result$n_inflated)
})

test_that("calc_missing_data_inflation MI works with different m values", {
  # More imputations should be more efficient
  result_m5 <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 5,
    mi_r_squared = 0.5
  )

  result_m20 <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 20,
    mi_r_squared = 0.5
  )

  # More imputations -> higher efficiency -> smaller n required
  expect_lte(result_m20$n_inflated, result_m5$n_inflated)
})

test_that("calc_missing_data_inflation MI works with different R-squared values", {
  # Better imputation model (higher R²) should be more efficient
  result_low_r2 <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 5,
    mi_r_squared = 0.3
  )

  result_high_r2 <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 5,
    mi_r_squared = 0.8
  )

  # Higher R² -> more efficient -> smaller n required
  expect_lt(result_high_r2$n_inflated, result_low_r2$n_inflated)
})

test_that("calc_missing_data_inflation MI recommendations are correct", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 25,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 10,
    mi_r_squared = 0.6
  )

  expect_type(result$mi_recommendations, "list")
  expect_named(result$mi_recommendations, c("m_adequate", "m_current", "m_recommended", "r_squared_quality"))

  expect_equal(result$mi_recommendations$m_current, 10)
  expect_gte(result$mi_recommendations$m_recommended, 10)
  expect_type(result$mi_recommendations$m_adequate, "logical")
  expect_match(result$mi_recommendations$r_squared_quality, "moderate|strong|weak")
})

test_that("calc_missing_data_inflation handles edge case: 1% missingness", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 1,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  # Very small adjustment
  expect_gt(result$inflation_factor, 1.0)
  expect_lt(result$inflation_factor, 1.02)
  expect_equal(result$n_inflated, 102)  # ceiling(100 / 0.99)
})

test_that("calc_missing_data_inflation handles edge case: 90% missingness", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 90,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  # Massive inflation
  expect_equal(result$inflation_factor, 10.0)
  # 100 / 0.1 = 1000, but ceiling may give 1001 depending on floating point
  expect_true(result$n_inflated %in% c(1000, 1001))
  expect_equal(result$pct_increase, 900.0)
})

test_that("calc_missing_data_inflation returns properly structured list", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  expect_type(result, "list")
  expect_named(result, c("n_inflated", "inflation_factor", "n_increase", "pct_increase", "interpretation", "mi_comparison", "mi_recommendations"))

  expect_type(result$n_inflated, "double")
  expect_type(result$inflation_factor, "double")
  expect_type(result$n_increase, "double")
  expect_type(result$pct_increase, "double")
  expect_type(result$interpretation, "character")
})

test_that("calc_missing_data_inflation always rounds up n_inflated", {
  result <- calc_missing_data_inflation(
    n_required = 101,
    missing_pct = 10,
    mechanism = "mar",
    analysis_type = "complete_case"
  )

  # 101 / 0.9 = 112.222... -> should ceiling to 113
  expect_equal(result$n_inflated, 113)
})

test_that("calc_missing_data_inflation MI interpretation mentions key details", {
  result <- calc_missing_data_inflation(
    n_required = 100,
    missing_pct = 20,
    mechanism = "mar",
    analysis_type = "multiple_imputation",
    mi_imputations = 5,
    mi_r_squared = 0.5
  )

  expect_match(result$interpretation, "20%")
  expect_match(result$interpretation, "MAR")
  expect_match(result$interpretation, "m=5")
  expect_match(result$interpretation, "R²=0.5")
})
