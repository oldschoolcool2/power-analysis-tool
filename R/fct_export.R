#' Export Data Building Functions
#'
#' Business logic for building export-ready data.frames from analysis results.
#' These are pure functions with no Shiny reactivity, making them testable.
#'
#' @name fct_export
NULL

#' Build Export Data for Any Analysis Type
#'
#' Central router that delegates to module-specific export builders.
#' This function provides a single entry point for generating export data
#' across all analysis modules.
#'
#' @param analysis_type String identifier for the analysis module
#'   (e.g., "power_single", "mediation_analysis", "vif_calculator")
#' @param inputs List or nested list containing module inputs
#' @param shiny_input Optional Shiny input object (for modules that need direct access)
#'
#' @return data.frame with analysis results ready for CSV/PDF export
#'
#' @details
#' Supported analysis types:
#' - "power_single": Single proportion power calculation
#' - "ss_single": Single proportion sample size calculation
#' - "power_twogrp": Two-group power calculation
#' - "ss_twogrp": Two-group sample size calculation
#' - "power_survival": Survival analysis power calculation
#' - "ss_survival": Survival analysis sample size calculation
#' - "match_casecontrol": Matched case-control sample size
#' - "power_continuous": Continuous outcomes power calculation
#' - "ss_continuous": Continuous outcomes sample size calculation
#' - "noninf": Non-inferiority sample size calculation
#' - "survival_ni_equiv": Time-to-event NI/equivalence sample size
#' - "mediation_analysis": Mediation analysis (all modes)
#' - "sensitivity_multi_bias": Multi-bias sensitivity analysis
#'
#' @export
#' @importFrom pwr pwr.p.test ES.h pwr.2p2n.test pwr.t2n.test pwr.t.test pwr.2p.test
#' @importFrom powerSurvEpi powerEpi.default ssizeEpi.default
#' @importFrom epiR epi.sscc
build_export_data <- function(analysis_type, inputs, shiny_input = NULL) {
  # Log export data building request
  logger::log_info(
    "Building export data",
    analysis_type = analysis_type,
    has_shiny_input = !is.null(shiny_input),
    input_class = class(inputs)[1]
  )

  result <- tryCatch(
    {
      export_df <- switch(analysis_type,
        # Single proportion analyses
        "power_single" = build_power_single_export(inputs),
        "ss_single" = build_ss_single_export(inputs),

        # Two-group comparisons
        "power_twogrp" = build_power_twogrp_export(inputs, shiny_input),
        "ss_twogrp" = build_ss_twogrp_export(inputs, shiny_input),

        # Survival analysis (Cox regression)
        "power_survival" = build_power_survival_export(inputs, shiny_input),
        "ss_survival" = build_ss_survival_export(inputs, shiny_input),

        # Matched case-control
        "match_casecontrol" = build_matched_cc_export(inputs, shiny_input),

        # Continuous outcomes (t-tests)
        "power_continuous" = build_power_continuous_export(inputs, shiny_input),
        "ss_continuous" = build_ss_continuous_export(inputs, shiny_input),

        # Non-inferiority
        "noninf" = build_noninf_export(inputs, shiny_input),

        # Time-to-event equivalence/non-inferiority
        "survival_ni_equiv" = build_survival_ni_equiv_export(inputs),

        # Mediation analysis
        "mediation_analysis" = build_mediation_export(inputs),

        # Multi-bias sensitivity analysis
        "sensitivity_multi_bias" = build_multi_bias_export(inputs),

        # Default: return error message
        stop(paste("Unknown analysis type:", analysis_type))
      )

      # Log successful export data generation
      logger::log_info(
        "Export data built successfully",
        analysis_type = analysis_type,
        rows = nrow(export_df),
        cols = ncol(export_df)
      )

      export_df
    },
    error = function(e) {
      # Log export data building failure
      logger::log_error(
        "Failed to build export data",
        analysis_type = analysis_type,
        error_class = class(e)[1],
        error_msg = conditionMessage(e)
      )

      # Re-throw the error
      stop(e)
    }
  )

  result
}

#' Build Power Single Proportion Export
#' @noRd
build_power_single_export <- function(inputs) {
  logger::log_debug(
    "Building single proportion power export",
    n = inputs$power_n,
    p = inputs$power_p,
    p0 = inputs$power_p0
  )

  tab1_inputs <- inputs

  power <- pwr::pwr.p.test(
    sig.level = tab1_inputs$power_alpha,
    power = NULL,
    h = pwr::ES.h(tab1_inputs$power_p / 100, tab1_inputs$power_p0 / 100),
    alternative = "greater",
    n = tab1_inputs$power_n
  )$power

  logger::log_debug(
    "Single proportion power calculated",
    power = power,
    power_percent = power * 100
  )

  data.frame(
    Analysis_Type = "Single Proportion - Power Calculation",
    Sample_Size = tab1_inputs$power_n,
    Expected_Proportion_Percent = tab1_inputs$power_p,
    Reference_Proportion_Percent = tab1_inputs$power_p0,
    Power_Percent = power * 100,
    Significance_Level = tab1_inputs$power_alpha,
    Discontinuation_Rate_Percent = tab1_inputs$power_discon,
    Adjusted_Sample_Size = ceiling(tab1_inputs$power_n * (1 + tab1_inputs$power_discon / 100)),
    Date = Sys.Date()
  )
}

#' Build Sample Size Single Proportion Export
#' @noRd
build_ss_single_export <- function(inputs) {
  tab1_inputs <- inputs

  sample_size <- pwr::pwr.p.test(
    sig.level = tab1_inputs$ss_alpha,
    power = tab1_inputs$ss_power / 100,
    h = pwr::ES.h(tab1_inputs$ss_p / 100, tab1_inputs$ss_p0 / 100),
    alternative = "greater",
    n = NULL
  )$n

  data.frame(
    Analysis_Type = "Single Proportion - Sample Size Calculation",
    Desired_Power_Percent = tab1_inputs$ss_power,
    Expected_Proportion_Percent = tab1_inputs$ss_p,
    Reference_Proportion_Percent = tab1_inputs$ss_p0,
    Required_Sample_Size = ceiling(sample_size),
    Significance_Level = tab1_inputs$ss_alpha,
    Discontinuation_Rate_Percent = tab1_inputs$ss_discon,
    Adjusted_Sample_Size = ceiling(sample_size * (1 + tab1_inputs$ss_discon / 100)),
    Date = Sys.Date()
  )
}

#' Build Power Two-Group Export
#' @noRd
build_power_twogrp_export <- function(inputs, shiny_input) {
  p1 <- shiny_input$twogrp_pow_p1 / 100
  p2 <- shiny_input$twogrp_pow_p2 / 100

  power <- pwr::pwr.2p2n.test(
    h = pwr::ES.h(p1, p2),
    n1 = shiny_input$twogrp_pow_n1,
    n2 = shiny_input$twogrp_pow_n2,
    sig.level = shiny_input$twogrp_pow_alpha,
    alternative = shiny_input$twogrp_pow_sided
  )$power

  eff <- calc_effect_measures(p1, p2)

  data.frame(
    Analysis_Type = "Two-Group Comparison - Power Calculation",
    Sample_Size_Group1 = shiny_input$twogrp_pow_n1,
    Sample_Size_Group2 = shiny_input$twogrp_pow_n2,
    Event_Rate_Group1_Percent = shiny_input$twogrp_pow_p1,
    Event_Rate_Group2_Percent = shiny_input$twogrp_pow_p2,
    Power_Percent = power * 100,
    Significance_Level = shiny_input$twogrp_pow_alpha,
    Test_Type = shiny_input$twogrp_pow_sided,
    Risk_Difference = eff$risk_diff,
    Relative_Risk = eff$relative_risk,
    Odds_Ratio = eff$odds_ratio,
    Date = Sys.Date()
  )
}

#' Build Sample Size Two-Group Export
#' @noRd
build_ss_twogrp_export <- function(inputs, shiny_input) {
  p1 <- shiny_input$twogrp_ss_p1 / 100
  p2 <- shiny_input$twogrp_ss_p2 / 100

  n1 <- solve_n1_for_ratio(
    pwr::ES.h(p1, p2),
    shiny_input$twogrp_ss_ratio,
    shiny_input$twogrp_ss_alpha,
    shiny_input$twogrp_ss_power / 100,
    shiny_input$twogrp_ss_sided
  )
  n2 <- n1 * shiny_input$twogrp_ss_ratio

  eff <- calc_effect_measures(p1, p2)

  data.frame(
    Analysis_Type = "Two-Group Comparison - Sample Size Calculation",
    Desired_Power_Percent = shiny_input$twogrp_ss_power,
    Event_Rate_Group1_Percent = shiny_input$twogrp_ss_p1,
    Event_Rate_Group2_Percent = shiny_input$twogrp_ss_p2,
    Required_Sample_Size_Group1 = ceiling(n1),
    Required_Sample_Size_Group2 = ceiling(n2),
    Total_Sample_Size = ceiling(n1 + n2),
    Allocation_Ratio = shiny_input$twogrp_ss_ratio,
    Significance_Level = shiny_input$twogrp_ss_alpha,
    Test_Type = shiny_input$twogrp_ss_sided,
    Risk_Difference = eff$risk_diff,
    Relative_Risk = eff$relative_risk,
    Odds_Ratio = eff$odds_ratio,
    Date = Sys.Date()
  )
}

#' Build Power Survival Export
#' @noRd
build_power_survival_export <- function(inputs, shiny_input) {
  n <- shiny_input$surv_pow_n
  hr <- shiny_input$surv_pow_hr
  k <- shiny_input$surv_pow_k / 100
  pE <- shiny_input$surv_pow_pE / 100

  power <- powerSurvEpi::powerEpi.default(
    n = n,
    theta = hr,
    p = k,
    psi = pE,
    rho2 = 0,
    alpha = shiny_input$surv_pow_alpha
  )

  data.frame(
    Analysis_Type = "Survival Analysis - Power Calculation",
    Total_Sample_Size = n,
    Hazard_Ratio = hr,
    Proportion_Exposed_Percent = shiny_input$surv_pow_k,
    Overall_Event_Rate_Percent = shiny_input$surv_pow_pE,
    Power_Percent = power * 100,
    Significance_Level = shiny_input$surv_pow_alpha,
    Method = "Schoenfeld (1983)",
    Date = Sys.Date()
  )
}

#' Build Sample Size Survival Export
#' @noRd
build_ss_survival_export <- function(inputs, shiny_input) {
  hr <- shiny_input$surv_ss_hr
  k <- shiny_input$surv_ss_k / 100
  pE <- shiny_input$surv_ss_pE / 100
  power <- shiny_input$surv_ss_power / 100

  n_est <- powerSurvEpi::ssizeEpi.default(
    power = power,
    theta = hr,
    p = k,
    psi = pE,
    rho2 = 0,
    alpha = shiny_input$surv_ss_alpha
  )

  data.frame(
    Analysis_Type = "Survival Analysis - Sample Size Calculation",
    Desired_Power_Percent = shiny_input$surv_ss_power,
    Hazard_Ratio = hr,
    Proportion_Exposed_Percent = shiny_input$surv_ss_k,
    Overall_Event_Rate_Percent = shiny_input$surv_ss_pE,
    Required_Total_Sample_Size = ceiling(n_est),
    Significance_Level = shiny_input$surv_ss_alpha,
    Method = "Schoenfeld (1983)",
    Date = Sys.Date()
  )
}

#' Build Matched Case-Control Export
#' @noRd
build_matched_cc_export <- function(inputs, shiny_input) {
  analysis_type <- shiny_input$match_analysis_type
  m <- shiny_input$match_ratio
  sided_val <- ifelse(identical(shiny_input$match_sided, "two.sided"), 2, 1)

  if (analysis_type == "sample_size") {
    # Sample Size Calculation
    or <- shiny_input$match_or
    p0 <- shiny_input$match_p0 / 100
    power <- shiny_input$match_power / 100

    result <- epiR::epi.sscc(
      OR = or,
      p0 = p0,
      n = NA,
      power = power,
      r = m,
      phi.coef = 0,
      design = 1,
      sided.test = sided_val,
      conf.level = 1 - shiny_input$match_alpha
    )

    n_cases <- ceiling(result$n.total)

    data.frame(
      Analysis_Type = "Matched Case-Control - Sample Size Calculation",
      Desired_Power_Percent = power * 100,
      Odds_Ratio = or,
      Exposure_Prob_Controls_Percent = p0 * 100,
      Controls_Per_Case = m,
      Required_Cases = n_cases,
      Required_Controls = n_cases * m,
      Total_Sample_Size = n_cases * (1 + m),
      Significance_Level = shiny_input$match_alpha,
      Test_Type = shiny_input$match_sided,
      Date = Sys.Date()
    )

  } else if (analysis_type == "power") {
    # Power Analysis (NEW!)
    n_cases <- shiny_input$match_n_pairs
    or <- shiny_input$match_or
    p0 <- shiny_input$match_p0 / 100

    result <- epiR::epi.sscc(
      OR = or,
      p0 = p0,
      n = n_cases,
      power = NA,
      r = m,
      phi.coef = 0,
      design = 1,
      sided.test = sided_val,
      conf.level = 1 - shiny_input$match_alpha
    )

    power_achieved <- result$power * 100

    data.frame(
      Analysis_Type = "Matched Case-Control - Power Analysis",
      Available_Cases = n_cases,
      Available_Controls = n_cases * m,
      Total_Sample_Size = n_cases * (1 + m),
      Odds_Ratio = or,
      Exposure_Prob_Controls_Percent = p0 * 100,
      Controls_Per_Case = m,
      Achieved_Power_Percent = power_achieved,
      Significance_Level = shiny_input$match_alpha,
      Test_Type = shiny_input$match_sided,
      Date = Sys.Date()
    )

  } else {
    # Minimal Detectable Effect (MDE)
    n_cases <- shiny_input$match_n_pairs
    p0 <- shiny_input$match_p0 / 100
    power <- shiny_input$match_power / 100

    # Binary search for minimal detectable OR
    or_lower <- 0.1
    or_upper <- 10.0
    max_iter <- 100

    for (i in 1:max_iter) {
      or_mid <- (or_lower + or_upper) / 2
      result <- tryCatch({
        epiR::epi.sscc(
          OR = or_mid,
          p0 = p0,
          n = n_cases,
          power = NA,
          r = m,
          phi.coef = 0,
          design = 1,
          sided.test = sided_val,
          conf.level = 1 - shiny_input$match_alpha
        )
      }, error = function(e) list(power = 0))

      power_achieved <- result$power
      if (is.null(power_achieved) || is.na(power_achieved)) power_achieved <- 0

      if (abs(power_achieved - power) < 0.01) {
        break
      } else if (power_achieved > power) {
        if (or_mid < 1) {
          or_lower <- or_mid
        } else {
          or_upper <- or_mid
        }
      } else {
        if (or_mid < 1) {
          or_upper <- or_mid
        } else {
          or_lower <- or_mid
        }
      }
    }

    or_detectable <- or_mid

    data.frame(
      Analysis_Type = "Matched Case-Control - Minimal Detectable Effect",
      Available_Cases = n_cases,
      Available_Controls = n_cases * m,
      Total_Sample_Size = n_cases * (1 + m),
      Desired_Power_Percent = power * 100,
      Exposure_Prob_Controls_Percent = p0 * 100,
      Controls_Per_Case = m,
      Minimal_Detectable_OR = or_detectable,
      Significance_Level = shiny_input$match_alpha,
      Test_Type = shiny_input$match_sided,
      Date = Sys.Date()
    )
  }
}

#' Build Power Continuous Outcomes Export
#' @noRd
build_power_continuous_export <- function(inputs, shiny_input) {
  n1 <- shiny_input$cont_pow_n1
  n2 <- shiny_input$cont_pow_n2
  d <- shiny_input$cont_pow_d

  power <- pwr::pwr.t2n.test(
    n1 = n1,
    n2 = n2,
    d = d,
    sig.level = shiny_input$cont_pow_alpha,
    alternative = shiny_input$cont_pow_sided
  )$power

  data.frame(
    Analysis_Type = "Continuous Outcomes - Power Calculation",
    Sample_Size_Group1 = n1,
    Sample_Size_Group2 = n2,
    Effect_Size_Cohens_d = d,
    Power_Percent = power * 100,
    Significance_Level = shiny_input$cont_pow_alpha,
    Test_Type = shiny_input$cont_pow_sided,
    Date = Sys.Date()
  )
}

#' Build Sample Size Continuous Outcomes Export
#' @noRd
build_ss_continuous_export <- function(inputs, shiny_input) {
  d <- shiny_input$cont_ss_d
  power <- shiny_input$cont_ss_power / 100
  ratio <- shiny_input$cont_ss_ratio

  if (ratio == 1) {
    n <- pwr::pwr.t.test(
      d = d,
      sig.level = shiny_input$cont_ss_alpha,
      power = power,
      type = "two.sample",
      alternative = shiny_input$cont_ss_sided
    )$n
    n1 <- n
    n2 <- n
  } else {
    f <- function(n1) {
      n2 <- n1 * ratio
      pwr::pwr.t2n.test(
        n1 = n1,
        n2 = n2,
        d = d,
        sig.level = shiny_input$cont_ss_alpha,
        alternative = shiny_input$cont_ss_sided
      )$power - power
    }

    n1 <- tryCatch(
      {
        uniroot(f, c(2, 1e6), extendInt = "yes")$root
      },
      error = function(e) {
        pwr::pwr.t.test(
          d = d,
          sig.level = shiny_input$cont_ss_alpha,
          power = power,
          type = "two.sample",
          alternative = shiny_input$cont_ss_sided
        )$n
      }
    )
    n2 <- n1 * ratio
  }

  data.frame(
    Analysis_Type = "Continuous Outcomes - Sample Size Calculation",
    Desired_Power_Percent = shiny_input$cont_ss_power,
    Effect_Size_Cohens_d = d,
    Required_Sample_Size_Group1 = ceiling(n1),
    Required_Sample_Size_Group2 = ceiling(n2),
    Total_Sample_Size = ceiling(n1 + n2),
    Allocation_Ratio = ratio,
    Significance_Level = shiny_input$cont_ss_alpha,
    Test_Type = shiny_input$cont_ss_sided,
    Date = Sys.Date()
  )
}

#' Build Non-Inferiority Export
#' @noRd
build_noninf_export <- function(inputs, shiny_input) {
  p1 <- shiny_input$noninf_p1 / 100
  p2 <- shiny_input$noninf_p2 / 100
  margin <- shiny_input$noninf_margin / 100
  power <- shiny_input$noninf_power / 100
  ratio <- shiny_input$noninf_ratio

  h <- pwr::ES.h(p1, p2 + margin)

  if (ratio == 1) {
    n <- pwr::pwr.2p.test(
      h = abs(h),
      sig.level = shiny_input$noninf_alpha,
      power = power,
      alternative = "two.sided"
    )$n
    n1 <- n
    n2 <- n
  } else {
    f <- function(n1) {
      n2 <- n1 * ratio
      pwr::pwr.2p2n.test(
        h = abs(h),
        n1 = n1,
        n2 = n2,
        sig.level = shiny_input$noninf_alpha,
        alternative = "two.sided"
      )$power - power
    }

    n1 <- tryCatch(
      {
        uniroot(f, c(2, 1e6), extendInt = "yes")$root
      },
      error = function(e) {
        pwr::pwr.2p.test(
          h = abs(h),
          sig.level = shiny_input$noninf_alpha,
          power = power,
          alternative = "less"
        )$n
      }
    )
    n2 <- n1 * ratio
  }

  data.frame(
    Analysis_Type = "Non-Inferiority - Sample Size Calculation",
    Desired_Power_Percent = shiny_input$noninf_power,
    Event_Rate_Test_Percent = shiny_input$noninf_p1,
    Event_Rate_Reference_Percent = shiny_input$noninf_p2,
    Non_Inferiority_Margin_Percent = shiny_input$noninf_margin,
    Required_Sample_Size_Test = ceiling(n1),
    Required_Sample_Size_Reference = ceiling(n2),
    Total_Sample_Size = ceiling(n1 + n2),
    Allocation_Ratio = ratio,
    Significance_Level = shiny_input$noninf_alpha,
    Date = Sys.Date()
  )
}

#' Build Time-to-Event NI/Equivalence Export
#' @noRd
build_survival_ni_equiv_export <- function(inputs) {
  tab9_inputs <- inputs
  test_type <- tab9_inputs$test_type
  calc_mode <- tab9_inputs$calc_mode

  if (calc_mode == "calc_n") {
    power <- tab9_inputs$power / 100
    hr_expected <- tab9_inputs$hr_expected
    prop_exposed <- tab9_inputs$prop_exposed / 100
    event_rate <- tab9_inputs$event_rate / 100
    ratio <- tab9_inputs$allocation_ratio
    alpha <- tab9_inputs$alpha

    if (test_type == "non-inferiority") {
      hr_margin <- tab9_inputs$hr_margin_ni

      n_total <- ssize_survival_ni(
        power = power,
        hr_expected = hr_expected,
        hr_margin = hr_margin,
        k = prop_exposed,
        pE = event_rate,
        alpha = alpha,
        ratio = ratio
      )

      n_test <- ceiling(n_total / (1 + ratio))
      n_ref <- n_total - n_test
      d_events <- events_survival_ni(power, hr_expected, hr_margin, alpha)

      data.frame(
        Analysis_Type = "Time-to-Event Non-Inferiority - Sample Size",
        Test_Type = "Non-Inferiority (one-sided)",
        Expected_HR = hr_expected,
        NI_Margin_HR = hr_margin,
        Desired_Power_Percent = tab9_inputs$power,
        Significance_Level = alpha,
        Prop_Exposed_Percent = tab9_inputs$prop_exposed,
        Event_Rate_Percent = tab9_inputs$event_rate,
        Allocation_Ratio = ratio,
        Total_Sample_Size = n_total,
        Sample_Size_Test = n_test,
        Sample_Size_Reference = n_ref,
        Required_Events = d_events,
        Date = Sys.Date()
      )
    } else {
      hr_margin <- tab9_inputs$hr_margin_equiv
      hr_lower <- 1 / hr_margin
      hr_upper <- hr_margin

      n_total <- ssize_survival_equiv(
        power = power,
        hr_expected = hr_expected,
        hr_lower = hr_lower,
        hr_upper = hr_upper,
        k = prop_exposed,
        pE = event_rate,
        alpha = alpha,
        ratio = ratio
      )

      n_test <- ceiling(n_total / (1 + ratio))
      n_ref <- n_total - n_test
      d_events <- events_survival_ni(power, hr_expected, hr_upper, alpha / 2)

      data.frame(
        Analysis_Type = "Time-to-Event Equivalence - Sample Size",
        Test_Type = "Equivalence (TOST)",
        Expected_HR = hr_expected,
        Equiv_Margin_Lower_HR = hr_lower,
        Equiv_Margin_Upper_HR = hr_upper,
        Desired_Power_Percent = tab9_inputs$power,
        Significance_Level = alpha,
        Prop_Exposed_Percent = tab9_inputs$prop_exposed,
        Event_Rate_Percent = tab9_inputs$event_rate,
        Allocation_Ratio = ratio,
        Total_Sample_Size = n_total,
        Sample_Size_Test = n_test,
        Sample_Size_Reference = n_ref,
        Required_Events = d_events,
        Date = Sys.Date()
      )
    }
  } else {
    # Margin calculation mode
    n_fixed <- tab9_inputs$n_fixed
    hr_expected <- tab9_inputs$hr_expected
    power <- tab9_inputs$power / 100
    prop_exposed <- tab9_inputs$prop_exposed / 100
    event_rate <- tab9_inputs$event_rate / 100
    ratio <- tab9_inputs$allocation_ratio
    alpha <- tab9_inputs$alpha

    margin_detectable <- mde_survival_ni(
      n = n_fixed,
      hr_expected = hr_expected,
      power = power,
      k = prop_exposed,
      pE = event_rate,
      alpha = alpha,
      ratio = ratio
    )

    data.frame(
      Analysis_Type = "Time-to-Event NI/Equivalence - Margin Calculation",
      Test_Type = tab9_inputs$test_type,
      Available_Sample_Size = n_fixed,
      Expected_HR = hr_expected,
      Detectable_Margin_HR = margin_detectable,
      Desired_Power_Percent = tab9_inputs$power,
      Significance_Level = alpha,
      Prop_Exposed_Percent = tab9_inputs$prop_exposed,
      Event_Rate_Percent = tab9_inputs$event_rate,
      Allocation_Ratio = ratio,
      Date = Sys.Date()
    )
  }
}

#' Build Mediation Analysis Export
#' @noRd
build_mediation_export <- function(inputs) {
  med_inputs <- inputs

  # Extract common values
  calc_mode <- med_inputs$calc_mode
  a <- med_inputs$path_a
  b <- med_inputs$path_b
  c_prime <- med_inputs$path_c_prime
  alpha <- med_inputs$med_alpha
  alternative <- med_inputs$med_sided

  # Handle standard errors (use input or estimate from N)
  se_a <- if (!is.na(med_inputs$se_a)) med_inputs$se_a else NULL
  se_b <- if (!is.na(med_inputs$se_b)) med_inputs$se_b else NULL

  # Calculate based on mode
  if (calc_mode == "calc_power") {
    # Calculate power given N
    n <- med_inputs$med_n
    power <- calc_mediation_power(n, a, b, se_a, se_b, alpha, alternative)

    data.frame(
      Analysis_Type = "Mediation Analysis - Power Calculation",
      Sample_Size = n,
      Power_Percent = power * 100,
      Path_a_X_to_M = a,
      Path_b_M_to_Y = b,
      Indirect_Effect_ab = a * b,
      Path_c_prime_Direct = ifelse(!is.na(c_prime), c_prime, NA),
      SE_Path_a = ifelse(!is.null(se_a), se_a, 1 / sqrt(n)),
      SE_Path_b = ifelse(!is.null(se_b), se_b, 1 / sqrt(n)),
      Significance_Level = alpha,
      Test_Type = alternative,
      Date = Sys.Date()
    )
  } else if (calc_mode == "calc_n") {
    # Calculate sample size given power
    power <- med_inputs$med_power / 100
    n_required <- calc_mediation_n(a, b, power, alpha, alternative)

    data.frame(
      Analysis_Type = "Mediation Analysis - Sample Size Calculation",
      Required_Sample_Size = ifelse(!is.na(n_required), ceiling(n_required), NA),
      Desired_Power_Percent = med_inputs$med_power,
      Path_a_X_to_M = a,
      Path_b_M_to_Y = b,
      Indirect_Effect_ab = a * b,
      Path_c_prime_Direct = ifelse(!is.na(c_prime), c_prime, NA),
      Significance_Level = alpha,
      Test_Type = alternative,
      Date = Sys.Date()
    )
  } else if (calc_mode == "calc_mde") {
    # Calculate minimal detectable effect
    n <- med_inputs$med_n
    power <- med_inputs$med_power / 100
    b_min <- calc_mediation_mde(n, a, power, alpha, alternative)
    ab_min <- a * b_min

    data.frame(
      Analysis_Type = "Mediation Analysis - Minimal Detectable Effect",
      Sample_Size = n,
      Desired_Power_Percent = med_inputs$med_power,
      Path_a_X_to_M = a,
      Path_b_M_to_Y_Minimum = ifelse(!is.na(b_min), b_min, NA),
      Indirect_Effect_ab_Minimum = ifelse(!is.na(ab_min), ab_min, NA),
      Path_c_prime_Direct = ifelse(!is.na(c_prime), c_prime, NA),
      Significance_Level = alpha,
      Test_Type = alternative,
      Date = Sys.Date()
    )
  }
}

#' Build Multi-Bias Sensitivity Analysis Export
#' @noRd
build_multi_bias_export <- function(inputs) {
  # Get module data (already extracted from reactive values)
  tab10_vals_data <- inputs
  multi_bias_data <- tab10_vals_data$multi_bias

  # Extract bias configuration
  include_confounding <- multi_bias_data$include_confounding
  include_selection <- multi_bias_data$include_selection
  include_misclass <- multi_bias_data$include_misclass
  selection_type <- multi_bias_data$selection_type
  misclass_type <- multi_bias_data$misclass_type
  rr <- multi_bias_data$rr
  include_ci <- multi_bias_data$include_ci
  ci_lower <- multi_bias_data$ci_lower
  ci_upper <- multi_bias_data$ci_upper
  analysis_type <- multi_bias_data$analysis_type

  # Build bias types list
  bias_types <- character(0)
  if (include_confounding) bias_types <- c(bias_types, "Unmeasured Confounding")
  if (include_selection) bias_types <- c(bias_types, paste0("Selection Bias (", selection_type, ")"))
  if (include_misclass) bias_types <- c(bias_types, paste0("Misclassification (", misclass_type, ")"))
  bias_types_str <- paste(bias_types, collapse = "; ")

  # Extract results
  mb_results <- multi_bias_data$results

  if (!is.null(mb_results) && !is.null(mb_results$valid) && mb_results$valid) {
    if (analysis_type == "evalue") {
      # E-value analysis export
      data.frame(
        Analysis_Type = "Multi-Bias Sensitivity Analysis - E-value",
        Bias_Types = bias_types_str,
        Observed_RR = rr,
        CI_Lower = ifelse(include_ci, ci_lower, NA),
        CI_Upper = ifelse(include_ci, ci_upper, NA),
        Multi_Bias_E_value = mb_results$evalue,
        Number_of_Bias_Types = length(bias_types),
        Robustness_Level = mb_results$interpretation$magnitude,
        Date = Sys.Date(),
        stringsAsFactors = FALSE
      )
    } else {
      # Bias-adjusted bound analysis export
      # Format bias parameters as a string
      bias_parms_str <- paste(
        names(mb_results$bias_parms),
        "=",
        sapply(mb_results$bias_parms, function(x) sprintf("%.2f", x)),
        collapse = "; "
      )

      data.frame(
        Analysis_Type = "Multi-Bias Sensitivity Analysis - Bias-Adjusted Bound",
        Bias_Types = bias_types_str,
        Observed_RR = mb_results$original_rr,
        CI_Lower = ifelse(include_ci, ci_lower, NA),
        CI_Upper = ifelse(include_ci, ci_upper, NA),
        Bias_Parameters = bias_parms_str,
        Bias_Factor = mb_results$bias_factor,
        Adjusted_RR = mb_results$adjusted_rr,
        Adjusted_CI_Lower = ifelse(!is.na(mb_results$adjusted_lo), mb_results$adjusted_lo, NA),
        Adjusted_CI_Upper = ifelse(!is.na(mb_results$adjusted_hi), mb_results$adjusted_hi, NA),
        Crosses_Null = mb_results$interpretation$crosses_null,
        Number_of_Bias_Types = length(bias_types),
        Date = Sys.Date(),
        stringsAsFactors = FALSE
      )
    }
  } else {
    # No valid results available - create placeholder
    data.frame(
      Analysis_Type = "Multi-Bias Sensitivity Analysis",
      Note = "No calculation results available. Please run analysis first.",
      Date = Sys.Date(),
      stringsAsFactors = FALSE
    )
  }
}
