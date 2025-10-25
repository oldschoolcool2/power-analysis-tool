# Tests for Propensity Score Sample Size and Power Calculation Functions
# File: R/fct_propensity_score.R

test_that("calculate_bhattacharyya_coefficient works with typical parameters", {
  ps_params_treated <- list(a = 2, b = 1)
  ps_params_control <- list(a = 1, b = 2)

  result <- calculate_bhattacharyya_coefficient(ps_params_treated, ps_params_control)

  expect_type(result, "double")
  expect_gte(result, 0)
  expect_lte(result, 1)
})

test_that("estimate_ps_distribution_params returns correct structure", {
  result <- estimate_ps_distribution_params(
    treatment_prop = 0.5,
    overlap_phi = 0.8
  )

  expect_type(result, "list")
  expect_named(result, c("treated", "control", "overlap_coefficient"))

  expect_named(result$treated, c("a", "b"))
  expect_named(result$control, c("a", "b"))

  expect_type(result$treated$a, "double")
  expect_type(result$treated$b, "double")
  expect_type(result$control$a, "double")
  expect_type(result$control$b, "double")

  expect_gt(result$treated$a, 0)
  expect_gt(result$treated$b, 0)
  expect_gt(result$control$a, 0)
  expect_gt(result$control$b, 0)
})

test_that("estimate_ps_distribution_params handles perfect overlap", {
  result <- estimate_ps_distribution_params(
    treatment_prop = 0.5,
    overlap_phi = 1.0
  )

  # With perfect overlap, distributions should be very similar
  # (Not necessarily identical due to empirical calibration, but close)
  expect_type(result, "list")
  expect_equal(result$overlap_coefficient, 1.0)
})

test_that("estimate_ps_distribution_params handles poor overlap", {
  result <- estimate_ps_distribution_params(
    treatment_prop = 0.5,
    overlap_phi = 0.2
  )

  # With poor overlap, distributions should be more separated
  expect_type(result, "list")
  expect_equal(result$overlap_coefficient, 0.2)

  # Parameters should be different between treated and control
  expect_false(isTRUE(all.equal(result$treated$a, result$control$a)))
})

test_that("calculate_n_li_2025 returns correct structure", {
  result <- calculate_n_li_2025(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE",
    outcome_var = 1
  )

  expect_type(result, "list")
  expect_named(result, c("n_required", "n_effective", "vif", "var_base", "var_adjusted",
                         "overlap_penalty", "confounding_penalty", "weight_multiplier",
                         "overlap_phi", "rho_squared", "method"))

  expect_type(result$n_required, "double")
  expect_gt(result$n_required, 0)
  expect_equal(result$method, "Li et al. (2025)")
})

test_that("calculate_n_li_2025 increases with lower overlap", {
  n_high_overlap <- calculate_n_li_2025(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.9,  # High overlap
    rho_squared = 0.1,
    weight_type = "ATE"
  )$n_required

  n_low_overlap <- calculate_n_li_2025(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.4,  # Low overlap
    rho_squared = 0.1,
    weight_type = "ATE"
  )$n_required

  # Lower overlap should require larger sample size
  expect_gt(n_low_overlap, n_high_overlap)
})

test_that("calculate_n_li_2025 increases with higher confounding", {
  n_low_confounding <- calculate_n_li_2025(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.05,  # Low confounding
    weight_type = "ATE"
  )$n_required

  n_high_confounding <- calculate_n_li_2025(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.30,  # High confounding
    weight_type = "ATE"
  )$n_required

  # Higher confounding should require larger sample size
  expect_gt(n_high_confounding, n_low_confounding)
})

test_that("calculate_n_li_2025 varies by weight type", {
  params <- list(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1
  )

  n_ate <- calculate_n_li_2025(weight_type = "ATE", effect_size = params$effect_size,
                                alpha = params$alpha, power = params$power,
                                treatment_prop = params$treatment_prop,
                                overlap_phi = params$overlap_phi,
                                rho_squared = params$rho_squared)$n_required

  n_ato <- calculate_n_li_2025(weight_type = "ATO", effect_size = params$effect_size,
                                alpha = params$alpha, power = params$power,
                                treatment_prop = params$treatment_prop,
                                overlap_phi = params$overlap_phi,
                                rho_squared = params$rho_squared)$n_required

  # ATO (overlap weights) should be more efficient than ATE
  expect_lt(n_ato, n_ate)
})

test_that("calculate_n_li_2025 increases with smaller effect size", {
  n_large_effect <- calculate_n_li_2025(
    effect_size = 0.5,  # Large effect
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )$n_required

  n_small_effect <- calculate_n_li_2025(
    effect_size = 0.2,  # Small effect
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )$n_required

  # Smaller effect should require larger sample
  expect_gt(n_small_effect, n_large_effect)
})

test_that("calculate_power_li_2025 returns power in [0, 1]", {
  power <- calculate_power_li_2025(
    n = 500,
    effect_size = 0.3,
    alpha = 0.05,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )

  expect_type(power, "double")
  expect_gte(power, 0)
  expect_lte(power, 1)
})

test_that("calculate_power_li_2025 increases with larger sample size", {
  power_small <- calculate_power_li_2025(
    n = 100,
    effect_size = 0.3,
    alpha = 0.05,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )

  power_large <- calculate_power_li_2025(
    n = 500,
    effect_size = 0.3,
    alpha = 0.05,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )

  expect_gt(power_large, power_small)
})

test_that("calculate_power_li_2025 and calculate_n_li_2025 are consistent", {
  # Calculate sample size for 80% power
  result <- calculate_n_li_2025(
    effect_size = 0.3,
    alpha = 0.05,
    power = 0.80,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )

  # Use that sample size to calculate power
  power <- calculate_power_li_2025(
    n = result$n_required,
    effect_size = 0.3,
    alpha = 0.05,
    treatment_prop = 0.5,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )

  # Should be close to 80% (within 5% tolerance due to rounding)
  expect_equal(power, 0.80, tolerance = 0.05)
})

test_that("interpret_overlap_coefficient provides correct categories", {
  excellent <- interpret_overlap_coefficient(0.95)
  good <- interpret_overlap_coefficient(0.80)
  fair <- interpret_overlap_coefficient(0.60)
  poor <- interpret_overlap_coefficient(0.35)
  very_poor <- interpret_overlap_coefficient(0.15)

  expect_equal(excellent$level, "Excellent Overlap")
  expect_equal(good$level, "Good Overlap")
  expect_equal(fair$level, "Fair Overlap")
  expect_equal(poor$level, "Poor Overlap")
  expect_equal(very_poor$level, "Very Poor Overlap")

  # All should have required fields
  for (interp in list(excellent, good, fair, poor, very_poor)) {
    expect_named(interp, c("level", "color", "icon", "message"))
    expect_type(interp$level, "character")
    expect_type(interp$color, "character")
    expect_type(interp$message, "character")
  }
})

test_that("interpret_rho_squared provides correct categories", {
  weak <- interpret_rho_squared(0.01)
  moderate <- interpret_rho_squared(0.08)
  strong <- interpret_rho_squared(0.20)
  very_strong <- interpret_rho_squared(0.35)

  expect_equal(weak$level, "Weak Confounding")
  expect_equal(moderate$level, "Moderate Confounding")
  expect_equal(strong$level, "Strong Confounding")
  expect_equal(very_strong$level, "Very Strong Confounding")

  # All should have required fields
  for (interp in list(weak, moderate, strong, very_strong)) {
    expect_named(interp, c("level", "color", "icon", "message"))
  }
})

test_that("compare_ps_methods requires estimate_vif_propensity_score function", {
  # This function calls estimate_vif_propensity_score which may be in app_server.R
  # If it's not available as a package function, this test will be skipped
  skip_if_not(exists("estimate_vif_propensity_score"), "estimate_vif_propensity_score not available")

  result <- compare_ps_methods(
    n_rct = 200,
    treatment_prev_pct = 50,
    c_stat = 0.75,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE"
  )

  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 3)
  expect_named(result, c("Method", "Sample_Size", "VIF", "Increase_vs_RCT", "Accounts_For"))
})

test_that("generate_ps_sensitivity_analysis requires estimate_vif_propensity_score function", {
  skip_if_not(exists("estimate_vif_propensity_score"), "estimate_vif_propensity_score not available")

  result <- generate_ps_sensitivity_analysis(
    n_rct = 200,
    treatment_prev_pct = 50,
    c_stat = 0.75,
    overlap_phi = 0.8,
    rho_squared = 0.1,
    weight_type = "ATE",
    method = "Both"
  )

  expect_s3_class(result, "data.frame")
  expect_gt(nrow(result), 0)
  expect_true(all(c("Overlap", "Rho_Squared", "N_Li_2025", "VIF_Li") %in% names(result)))
})
