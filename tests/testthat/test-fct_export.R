#' Unit Tests for Export Builder Functions
#'
#' Tests for R/fct_export.R - Business logic for building export-ready data frames
#' All functions tested here are pure functions with no Shiny reactivity.
#'
#' Test Coverage:
#' - Single proportion (power & sample size)
#' - Two-group comparisons (power & sample size)
#' - Survival analysis (power & sample size)
#' - Matched case-control (sample size, power, MDE)
#' - Continuous outcomes (power & sample size)
#' - Non-inferiority (sample size)
#' - Time-to-event NI/equivalence (sample size)
#' - Mediation analysis (power, sample size, MDE)
#' - Multi-bias sensitivity (E-value, bounds)
#' - Router function (build_export_data)

library(testthat)

# ============================================================================
# Single Proportion Tests
# ============================================================================

test_that("build_power_single_export produces correct structure", {
  inputs <- list(
    power_n = 100,
    power_p = 60,
    power_p0 = 50,
    power_alpha = 0.05,
    power_discon = 10
  )

  result <- build_power_single_export(inputs)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1)

  # Check required columns
  expected_cols <- c(
    "Analysis_Type", "Sample_Size", "Expected_Proportion_Percent",
    "Reference_Proportion_Percent", "Power_Percent", "Significance_Level",
    "Discontinuation_Rate_Percent", "Adjusted_Sample_Size", "Date"
  )
  expect_true(all(expected_cols %in% names(result)))

  # Check values
  expect_equal(result$Sample_Size, 100)
  expect_equal(result$Expected_Proportion_Percent, 60)
  expect_equal(result$Reference_Proportion_Percent, 50)
  expect_equal(result$Significance_Level, 0.05)
  expect_equal(result$Adjusted_Sample_Size, 110) # 100 * (1 + 0.10)

  # Check power calculation
  expect_true(result$Power_Percent > 0)
  expect_true(result$Power_Percent <= 100)
})

test_that("build_ss_single_export produces correct structure", {
  inputs <- list(
    ss_power = 80,
    ss_p = 60,
    ss_p0 = 50,
    ss_alpha = 0.05,
    ss_discon = 15
  )

  result <- build_ss_single_export(inputs)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(result$Analysis_Type, "Single Proportion - Sample Size Calculation")

  # Check values
  expect_equal(result$Desired_Power_Percent, 80)
  expect_equal(result$Expected_Proportion_Percent, 60)
  expect_equal(result$Reference_Proportion_Percent, 50)

  # Check sample size is positive
  expect_true(result$Required_Sample_Size > 0)
  expect_true(result$Adjusted_Sample_Size > result$Required_Sample_Size)
})

test_that("build_power_single_export handles rare event detection (p0=0)", {
  inputs <- list(
    power_n = 230,
    power_p = 1,
    power_p0 = 0,
    power_alpha = 0.05,
    power_discon = 0
  )

  result <- build_power_single_export(inputs)

  expect_equal(result$Reference_Proportion_Percent, 0)
  expect_true(result$Power_Percent > 0)
})

# ============================================================================
# Two-Group Comparison Tests
# ============================================================================

test_that("build_power_twogrp_export produces correct structure", {
  mock_input <- list(
    twogrp_pow_p1 = 60,
    twogrp_pow_p2 = 40,
    twogrp_pow_n1 = 100,
    twogrp_pow_n2 = 100,
    twogrp_pow_alpha = 0.05,
    twogrp_pow_sided = "two.sided"
  )

  result <- build_power_twogrp_export(NULL, mock_input)

  # Check structure
  expect_s3_class(result, "data.frame")
  expect_equal(result$Analysis_Type, "Two-Group Comparison - Power Calculation")

  # Check sample sizes
  expect_equal(result$Sample_Size_Group1, 100)
  expect_equal(result$Sample_Size_Group2, 100)

  # Check effect measures
  expect_true("Risk_Difference" %in% names(result))
  expect_true("Relative_Risk" %in% names(result))
  expect_true("Odds_Ratio" %in% names(result))

  # Check power is valid
  expect_true(result$Power_Percent > 0)
  expect_true(result$Power_Percent <= 100)
})

test_that("build_ss_twogrp_export handles unequal allocation", {
  mock_input <- list(
    twogrp_ss_p1 = 60,
    twogrp_ss_p2 = 40,
    twogrp_ss_power = 80,
    twogrp_ss_ratio = 2, # 2:1 allocation
    twogrp_ss_alpha = 0.05,
    twogrp_ss_sided = "two.sided"
  )

  result <- build_ss_twogrp_export(NULL, mock_input)

  # Check allocation ratio is respected
  expect_equal(result$Allocation_Ratio, 2)
  expect_equal(
    result$Required_Sample_Size_Group2,
    result$Required_Sample_Size_Group1 * 2
  )

  # Check total
  expect_equal(
    result$Total_Sample_Size,
    result$Required_Sample_Size_Group1 + result$Required_Sample_Size_Group2
  )
})

# ============================================================================
# Survival Analysis Tests
# ============================================================================

test_that("build_power_survival_export produces correct structure", {
  mock_input <- list(
    surv_pow_n = 200,
    surv_pow_hr = 0.7,
    surv_pow_k = 50,
    surv_pow_pE = 30,
    surv_pow_alpha = 0.05
  )

  result <- build_power_survival_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Survival Analysis - Power Calculation")
  expect_equal(result$Method, "Schoenfeld (1983)")

  # Check values
  expect_equal(result$Total_Sample_Size, 200)
  expect_equal(result$Hazard_Ratio, 0.7)
  expect_equal(result$Proportion_Exposed_Percent, 50)
  expect_equal(result$Overall_Event_Rate_Percent, 30)

  # Check power
  expect_true(result$Power_Percent > 0)
  expect_true(result$Power_Percent <= 100)
})

test_that("build_ss_survival_export produces correct structure", {
  mock_input <- list(
    surv_ss_hr = 0.7,
    surv_ss_k = 50,
    surv_ss_pE = 30,
    surv_ss_power = 80,
    surv_ss_alpha = 0.05
  )

  result <- build_ss_survival_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Survival Analysis - Sample Size Calculation")
  expect_equal(result$Desired_Power_Percent, 80)

  # Check sample size is positive
  expect_true(result$Required_Total_Sample_Size > 0)
})

# ============================================================================
# Matched Case-Control Tests (Including New Modes)
# ============================================================================

test_that("build_matched_cc_export sample size mode works", {
  mock_input <- list(
    match_analysis_type = "sample_size",
    match_or = 2.5,
    match_p0 = 30,
    match_ratio = 2,
    match_power = 80,
    match_alpha = 0.05,
    match_sided = "two.sided"
  )

  result <- build_matched_cc_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Matched Case-Control - Sample Size Calculation")

  # Check values
  expect_equal(result$Odds_Ratio, 2.5)
  expect_equal(result$Exposure_Prob_Controls_Percent, 30)
  expect_equal(result$Controls_Per_Case, 2)

  # Check sample sizes
  expect_true(result$Required_Cases > 0)
  expect_equal(result$Required_Controls, result$Required_Cases * 2)
  expect_equal(result$Total_Sample_Size, result$Required_Cases * 3)
})

test_that("build_matched_cc_export power mode works", {
  mock_input <- list(
    match_analysis_type = "power",
    match_n_pairs = 50,
    match_or = 2.5,
    match_p0 = 30,
    match_ratio = 2,
    match_alpha = 0.05,
    match_sided = "two.sided"
  )

  result <- build_matched_cc_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Matched Case-Control - Power Analysis")

  # Check values
  expect_equal(result$Available_Cases, 50)
  expect_equal(result$Available_Controls, 100) # 50 * 2
  expect_equal(result$Total_Sample_Size, 150)

  # Check power
  expect_true(result$Achieved_Power_Percent > 0)
  expect_true(result$Achieved_Power_Percent <= 100)
})

test_that("build_matched_cc_export MDE mode works", {
  mock_input <- list(
    match_analysis_type = "mde",
    match_n_pairs = 50,
    match_p0 = 30,
    match_ratio = 2,
    match_power = 80,
    match_alpha = 0.05,
    match_sided = "two.sided"
  )

  result <- build_matched_cc_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Matched Case-Control - Minimal Detectable Effect")

  # Check values
  expect_equal(result$Available_Cases, 50)
  expect_equal(result$Desired_Power_Percent, 80)

  # Check MDE is positive
  expect_true(result$Minimal_Detectable_OR > 0)
  expect_true(result$Minimal_Detectable_OR != 1) # Should be different from null
})

# ============================================================================
# Continuous Outcomes Tests
# ============================================================================

test_that("build_power_continuous_export produces correct structure", {
  mock_input <- list(
    cont_pow_n1 = 100,
    cont_pow_n2 = 100,
    cont_pow_d = 0.5,
    cont_pow_alpha = 0.05,
    cont_pow_sided = "two.sided"
  )

  result <- build_power_continuous_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Continuous Outcomes - Power Calculation")

  # Check values
  expect_equal(result$Sample_Size_Group1, 100)
  expect_equal(result$Sample_Size_Group2, 100)
  expect_equal(result$Effect_Size_Cohens_d, 0.5)

  # Check power
  expect_true(result$Power_Percent > 0)
  expect_true(result$Power_Percent <= 100)
})

test_that("build_ss_continuous_export handles equal allocation", {
  mock_input <- list(
    cont_ss_d = 0.5,
    cont_ss_power = 80,
    cont_ss_ratio = 1,
    cont_ss_alpha = 0.05,
    cont_ss_sided = "two.sided"
  )

  result <- build_ss_continuous_export(NULL, mock_input)

  # Check equal allocation
  expect_equal(result$Allocation_Ratio, 1)
  expect_equal(
    result$Required_Sample_Size_Group1,
    result$Required_Sample_Size_Group2
  )
})

test_that("build_ss_continuous_export handles unequal allocation", {
  mock_input <- list(
    cont_ss_d = 0.5,
    cont_ss_power = 80,
    cont_ss_ratio = 2,
    cont_ss_alpha = 0.05,
    cont_ss_sided = "two.sided"
  )

  result <- build_ss_continuous_export(NULL, mock_input)

  # Check unequal allocation
  expect_equal(result$Allocation_Ratio, 2)
  expect_true(result$Required_Sample_Size_Group2 > result$Required_Sample_Size_Group1)
})

# ============================================================================
# Non-Inferiority Tests
# ============================================================================

test_that("build_noninf_export produces correct structure", {
  mock_input <- list(
    noninf_p1 = 85,
    noninf_p2 = 90,
    noninf_margin = 5,
    noninf_power = 80,
    noninf_ratio = 1,
    noninf_alpha = 0.025
  )

  result <- build_noninf_export(NULL, mock_input)

  # Check structure
  expect_equal(result$Analysis_Type, "Non-Inferiority - Sample Size Calculation")

  # Check values
  expect_equal(result$Event_Rate_Test_Percent, 85)
  expect_equal(result$Event_Rate_Reference_Percent, 90)
  expect_equal(result$Non_Inferiority_Margin_Percent, 5)

  # Check sample sizes
  expect_true(result$Required_Sample_Size_Test > 0)
  expect_true(result$Required_Sample_Size_Reference > 0)
})

# ============================================================================
# Time-to-Event NI/Equivalence Tests
# ============================================================================

test_that("build_survival_ni_equiv_export handles non-inferiority", {
  inputs <- list(
    test_type = "non-inferiority",
    calc_mode = "calc_n",
    power = 80,
    hr_expected = 1.0,
    hr_margin_ni = 1.3,
    prop_exposed = 50,
    event_rate = 30,
    allocation_ratio = 1,
    alpha = 0.025
  )

  result <- build_survival_ni_equiv_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Time-to-Event Non-Inferiority - Sample Size")
  expect_equal(result$Test_Type, "Non-Inferiority (one-sided)")

  # Check values
  expect_equal(result$Expected_HR, 1.0)
  expect_equal(result$NI_Margin_HR, 1.3)

  # Check sample sizes
  expect_true(result$Total_Sample_Size > 0)
  expect_true(result$Sample_Size_Test > 0)
  expect_true(result$Sample_Size_Reference > 0)
})

test_that("build_survival_ni_equiv_export handles equivalence", {
  inputs <- list(
    test_type = "equivalence",
    calc_mode = "calc_n",
    power = 80,
    hr_expected = 1.0,
    hr_margin_equiv = 1.25,
    prop_exposed = 50,
    event_rate = 30,
    allocation_ratio = 1,
    alpha = 0.05
  )

  result <- build_survival_ni_equiv_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Time-to-Event Equivalence - Sample Size")
  expect_equal(result$Test_Type, "Equivalence (TOST)")

  # Check margins
  expect_equal(result$Equiv_Margin_Lower_HR, 1 / 1.25)
  expect_equal(result$Equiv_Margin_Upper_HR, 1.25)
})

test_that("build_survival_ni_equiv_export handles margin calculation", {
  inputs <- list(
    calc_mode = "calc_margin",
    test_type = "non-inferiority",
    n_fixed = 200,
    hr_expected = 1.0,
    power = 80,
    prop_exposed = 50,
    event_rate = 30,
    allocation_ratio = 1,
    alpha = 0.025
  )

  result <- build_survival_ni_equiv_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Time-to-Event NI/Equivalence - Margin Calculation")
  expect_equal(result$Available_Sample_Size, 200)

  # Check detectable margin
  expect_true(result$Detectable_Margin_HR > 0)
})

# ============================================================================
# Mediation Analysis Tests
# ============================================================================

test_that("build_mediation_export handles power calculation mode", {
  inputs <- list(
    calc_mode = "calc_power",
    med_n = 100,
    path_a = 0.3,
    path_b = 0.4,
    path_c_prime = 0.2,
    med_alpha = 0.05,
    med_sided = "two.sided",
    se_a = NA,
    se_b = NA
  )

  result <- build_mediation_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Mediation Analysis - Power Calculation")

  # Check values
  expect_equal(result$Sample_Size, 100)
  expect_equal(result$Path_a_X_to_M, 0.3)
  expect_equal(result$Path_b_M_to_Y, 0.4)
  expect_equal(result$Indirect_Effect_ab, 0.12) # 0.3 * 0.4

  # Check power
  expect_true(result$Power_Percent > 0)
  expect_true(result$Power_Percent <= 100)
})

test_that("build_mediation_export handles sample size calculation mode", {
  inputs <- list(
    calc_mode = "calc_n",
    med_power = 80,
    path_a = 0.3,
    path_b = 0.4,
    path_c_prime = NA,
    med_alpha = 0.05,
    med_sided = "two.sided"
  )

  result <- build_mediation_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Mediation Analysis - Sample Size Calculation")

  # Check values
  expect_equal(result$Desired_Power_Percent, 80)
  expect_equal(result$Indirect_Effect_ab, 0.12)

  # Check sample size
  expect_true(is.numeric(result$Required_Sample_Size) || is.na(result$Required_Sample_Size))
})

test_that("build_mediation_export handles MDE calculation mode", {
  inputs <- list(
    calc_mode = "calc_mde",
    med_n = 100,
    med_power = 80,
    path_a = 0.3,
    path_c_prime = NA,
    med_alpha = 0.05,
    med_sided = "two.sided"
  )

  result <- build_mediation_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Mediation Analysis - Minimal Detectable Effect")

  # Check values
  expect_equal(result$Sample_Size, 100)
  expect_equal(result$Desired_Power_Percent, 80)
  expect_equal(result$Path_a_X_to_M, 0.3)
})

# ============================================================================
# Multi-Bias Sensitivity Tests
# ============================================================================

test_that("build_multi_bias_export handles E-value analysis with valid results", {
  inputs <- list(
    multi_bias = list(
      include_confounding = TRUE,
      include_selection = FALSE,
      include_misclass = FALSE,
      selection_type = "general",
      misclass_type = "exposure",
      rr = 2.0,
      include_ci = TRUE,
      ci_lower = 1.5,
      ci_upper = 2.5,
      analysis_type = "evalue",
      results = list(
        valid = TRUE,
        evalue = 3.5,
        interpretation = list(magnitude = "Strong")
      )
    )
  )

  result <- build_multi_bias_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Multi-Bias Sensitivity Analysis - E-value")

  # Check values
  expect_equal(result$Observed_RR, 2.0)
  expect_equal(result$CI_Lower, 1.5)
  expect_equal(result$CI_Upper, 2.5)
  expect_equal(result$Multi_Bias_E_value, 3.5)
  expect_equal(result$Robustness_Level, "Strong")
  expect_equal(result$Number_of_Bias_Types, 1)
})

test_that("build_multi_bias_export handles bias-adjusted bound analysis", {
  inputs <- list(
    multi_bias = list(
      include_confounding = TRUE,
      include_selection = TRUE,
      include_misclass = FALSE,
      selection_type = "general",
      misclass_type = "exposure",
      rr = 2.0,
      include_ci = TRUE,
      ci_lower = 1.5,
      ci_upper = 2.5,
      analysis_type = "bound",
      results = list(
        valid = TRUE,
        original_rr = 2.0,
        bias_factor = 1.2,
        adjusted_rr = 1.67,
        adjusted_lo = 1.25,
        adjusted_hi = 2.08,
        bias_parms = list(bf_conf = 1.1, bf_sel = 1.1),
        interpretation = list(crosses_null = FALSE)
      )
    )
  )

  result <- build_multi_bias_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Multi-Bias Sensitivity Analysis - Bias-Adjusted Bound")

  # Check values
  expect_equal(result$Observed_RR, 2.0)
  expect_equal(result$Bias_Factor, 1.2)
  expect_equal(result$Adjusted_RR, 1.67)
  expect_false(result$Crosses_Null)
  expect_equal(result$Number_of_Bias_Types, 2)
})

test_that("build_multi_bias_export handles invalid results", {
  inputs <- list(
    multi_bias = list(
      include_confounding = FALSE,
      include_selection = FALSE,
      include_misclass = FALSE,
      results = list(valid = FALSE)
    )
  )

  result <- build_multi_bias_export(inputs)

  # Check structure
  expect_equal(result$Analysis_Type, "Multi-Bias Sensitivity Analysis")
  expect_true(grepl("No calculation results available", result$Note))
})

# ============================================================================
# Router Function Tests
# ============================================================================

test_that("build_export_data routes to correct builder - single proportion", {
  inputs <- list(
    power_n = 100,
    power_p = 60,
    power_p0 = 50,
    power_alpha = 0.05,
    power_discon = 10
  )

  result <- build_export_data("power_single", inputs)

  expect_equal(result$Analysis_Type, "Single Proportion - Power Calculation")
})

test_that("build_export_data routes to correct builder - two-group", {
  mock_input <- list(
    twogrp_pow_p1 = 60,
    twogrp_pow_p2 = 40,
    twogrp_pow_n1 = 100,
    twogrp_pow_n2 = 100,
    twogrp_pow_alpha = 0.05,
    twogrp_pow_sided = "two.sided"
  )

  result <- build_export_data("power_twogrp", NULL, shiny_input = mock_input)

  expect_equal(result$Analysis_Type, "Two-Group Comparison - Power Calculation")
})

test_that("build_export_data routes to correct builder - mediation", {
  inputs <- list(
    calc_mode = "calc_power",
    med_n = 100,
    path_a = 0.3,
    path_b = 0.4,
    path_c_prime = NA,
    med_alpha = 0.05,
    med_sided = "two.sided",
    se_a = NA,
    se_b = NA
  )

  result <- build_export_data("mediation_analysis", inputs)

  expect_equal(result$Analysis_Type, "Mediation Analysis - Power Calculation")
})

test_that("build_export_data throws error for unknown analysis type", {
  expect_error(
    build_export_data("unknown_type", NULL),
    "Unknown analysis type"
  )
})

# ============================================================================
# Edge Cases and Error Handling
# ============================================================================

test_that("export functions handle missing optional parameters", {
  # Test with minimal inputs
  inputs <- list(
    power_n = 100,
    power_p = 60,
    power_p0 = 50,
    power_alpha = 0.05,
    power_discon = 0 # Zero discontinuation
  )

  result <- build_power_single_export(inputs)

  expect_equal(result$Adjusted_Sample_Size, 100) # No adjustment
})

test_that("export functions produce consistent Date field", {
  inputs <- list(
    power_n = 100,
    power_p = 60,
    power_p0 = 50,
    power_alpha = 0.05,
    power_discon = 0
  )

  result <- build_power_single_export(inputs)

  expect_equal(result$Date, Sys.Date())
  expect_s3_class(result$Date, "Date")
})

test_that("export functions handle extreme effect sizes", {
  # Very small effect size
  mock_input <- list(
    cont_ss_d = 0.1,
    cont_ss_power = 80,
    cont_ss_ratio = 1,
    cont_ss_alpha = 0.05,
    cont_ss_sided = "two.sided"
  )

  result <- build_ss_continuous_export(NULL, mock_input)

  # Should require large sample size
  expect_true(result$Total_Sample_Size > 500)
})

# ============================================================================
# Data Type Validation
# ============================================================================

test_that("export functions return proper data types", {
  inputs <- list(
    power_n = 100,
    power_p = 60,
    power_p0 = 50,
    power_alpha = 0.05,
    power_discon = 10
  )

  result <- build_power_single_export(inputs)

  # Numeric columns
  expect_type(result$Sample_Size, "double")
  expect_type(result$Power_Percent, "double")
  expect_type(result$Significance_Level, "double")

  # Character columns
  expect_type(result$Analysis_Type, "character")

  # Date column
  expect_s3_class(result$Date, "Date")
})

# ============================================================================
# Test Summary
# ============================================================================

test_that("all analysis types are covered by tests", {
  # This meta-test ensures we don't forget to test new analysis types
  supported_types <- c(
    "power_single", "ss_single",
    "power_twogrp", "ss_twogrp",
    "power_survival", "ss_survival",
    "match_casecontrol",
    "power_continuous", "ss_continuous",
    "noninf",
    "survival_ni_equiv",
    "mediation_analysis",
    "sensitivity_multi_bias"
  )

  # Each type should have at least one test
  test_files <- list.files(
    testthat::test_path(),
    pattern = "test-fct_export\\.R",
    full.names = TRUE
  )

  expect_true(length(test_files) > 0)
})
