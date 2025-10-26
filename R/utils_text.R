# Result Text Formatting Helpers
#
# Consolidates repeated HTML text generation patterns for displaying
# analysis results. These functions follow DRY principles by extracting
# common formatting and text generation logic.

#' Create Standard Result Header
#'
#' Generates the standard header shown at the top of all result outputs.
#'
#' @return HTML tags for result header
create_result_header <- function() {
  tagList(
    hr(),
    h1("Results of this analysis"),
    h4("(This text can be copy/pasted into your synopsis or protocol)")
  )
}


#' Format Missing Data Adjustment Text
#'
#' Creates a styled callout box showing missing data adjustment details.
#' This replaces duplicated HTML formatting across 6 sample size calculations.
#' Supports both complete-case analysis and multiple imputation methods.
#'
#' @param missing_adj List returned from calc_missing_data_inflation()
#' @param n_before Sample size before missing data adjustment
#'
#' @return HTML paragraph with styled missing data information
#'
#' @examples
#' missing_adj <- calc_missing_data_inflation(100, 20, "mar", "complete_case", 5, 0.5)
#' format_missing_data_text(missing_adj, n_before = 100)
format_missing_data_text <- function(missing_adj, n_before) {
  base_text <- paste0(
    "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
    "<strong>Missing Data Adjustment:</strong> ",
    missing_adj$interpretation,
    "<br><strong>Sample size before missing data adjustment:</strong> ", n_before,
    "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
    "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase
  )

  # Add MI-specific comparison and recommendations if using multiple imputation
  if (!is.null(missing_adj$mi_comparison) && !is.null(missing_adj$mi_recommendations)) {
    mi_comp <- missing_adj$mi_comparison
    mi_rec <- missing_adj$mi_recommendations

    # MI comparison section
    comparison_section <- paste0(
      "<br><br><strong style='text-decoration: underline;'>MI Efficiency Comparison:</strong>",
      "<br>• Complete-case analysis would require: <strong>", mi_comp$cca_n, " participants</strong> (", mi_comp$cca_inflation, "× inflation)",
      "<br>• Multiple imputation requires: <strong>", mi_comp$mi_n, " participants</strong> (", mi_comp$mi_inflation, "× inflation)",
      "<br>• <span style='color: #28a745; font-weight: bold;'>Efficiency gain: ", mi_comp$efficiency_gain, " fewer participants vs. CCA</span>",
      "<br>• Relative efficiency: ", mi_comp$relative_efficiency,
      "<br>• Fraction of missing information (FMI): ", mi_comp$fmi,
      "<br>• Effective N after MI: ~", mi_comp$n_effective
    )

    # MI recommendations section
    m_status_color <- if (mi_rec$m_adequate) "#28a745" else "#dc3545"
    m_status_text <- if (mi_rec$m_adequate) "✓ Adequate" else "⚠ Below recommended"

    recommendations_section <- paste0(
      "<br><br><strong style='text-decoration: underline;'>MI Recommendations (NEW Feature):</strong>",
      "<br>• Number of imputations (m): ", mi_rec$m_current,
      " - <span style='color: ", m_status_color, "; font-weight: bold;'>", m_status_text, "</span>",
      if (!mi_rec$m_adequate) {
        paste0("<br>&nbsp;&nbsp;<em>Recommended: At least m = ", mi_rec$m_recommended, " imputations for robust results</em>")
      } else {
        ""
      },
      "<br>• Imputation model quality: <strong>", mi_rec$r_squared_quality, "</strong>",
      if (mi_rec$r_squared_quality %in% c("weak", "very weak")) {
        "<br>&nbsp;&nbsp;<em style='color: #dc3545;'>⚠ Consider improving imputation model or using CCA</em>"
      } else {
        ""
      },
      "<br>• <em>Rule of thumb: m ≥ % missing (White et al. 2011)</em>"
    )

    base_text <- paste0(base_text, comparison_section, recommendations_section)
  }

  HTML(paste0(base_text, "</p>"))
}


#' Format Numeric Value with Appropriate Precision
#'
#' Formats numeric values for display with appropriate decimal places.
#'
#' @param value Numeric value to format
#' @param digits Number of significant digits (default 2)
#' @param nsmall Minimum decimal places (default 2)
#' @param as_percent If TRUE, multiply by 100 and add % (default FALSE)
#' @param as_integer If TRUE, round to integer (default FALSE)
#'
#' @return Character string with formatted value
#'
#' @examples
#' format_numeric(0.8234, digits = 2) # "0.82"
#' format_numeric(0.8234, as_percent = TRUE) # "82.34%"
#' format_numeric(230.7, as_integer = TRUE) # "231"
format_numeric <- function(value,
                          digits = 2,
                          nsmall = 2,
                          as_percent = FALSE,
                          as_integer = FALSE) {

  if (is.na(value) || is.null(value)) {
    return("NA")
  }

  # Ensure digits is at least 1 (R's format() requires this)
  if (digits < 1) {
    digits <- 1
    # When digits is 0 for percentages, we want 0 decimal places
    if (as_percent && nsmall == 2) {
      nsmall <- 0
    }
  }

  if (as_integer) {
    return(format(ceiling(value), digits = 1, nsmall = 0))
  }

  if (as_percent) {
    return(paste0(format(value * 100, digits = digits, nsmall = nsmall), "%"))
  }

  format(value, digits = digits, nsmall = nsmall)
}


#' Create Power Analysis Result Text (Single Proportion)
#'
#' Generates formatted result text for single proportion power analysis.
#' Enhanced with visual result cards and color-coded power interpretation.
#'
#' @param incidence_rate Event rate (1 in X format)
#' @param sample_size Sample size
#' @param power Calculated power
#' @param alpha Significance level
#' @param discon Discontinuation rate (as proportion, e.g., 0.10)
#'
#' @return HTML formatted text
create_power_single_result_text <- function(incidence_rate,
                                           sample_size,
                                           power,
                                           alpha,
                                           discon) {
  # Get power status for color coding
  power_status <- get_power_status(power)

  # Main result card configuration
  main_card <- list(
    title = "Achieved Power",
    value = format_numeric(power, as_percent = TRUE, digits = 1),
    subtitle = power_status$interpretation,
    status = power_status$status,
    icon_name = power_status$icon
  )

  # Key findings
  key_findings <- list(
    list(
      text = paste0(
        "With ", format_numeric(sample_size, as_integer = TRUE),
        " participants, you have a ", format_numeric(power, as_percent = TRUE, digits = 0),
        " probability of observing at least one event"
      ),
      type = "info",
      icon = "chart-bar"
    )
  )

  # Add warning if power is low
  if (power < 0.80) {
    key_findings <- c(key_findings, list(
      list(
        text = paste0(
          "Power is below the conventional 80% threshold. Consider increasing sample size to ",
          ceiling(sample_size / power * 0.80),
          " participants for adequate power"
        ),
        type = "warning",
        icon = "exclamation-triangle"
      )
    ))
  }

  # Recommendations
  recommendations <- c(
    paste0(
      "Accounting for ", format_numeric(discon, as_percent = TRUE, digits = 0),
      " discontinuation, the adjusted sample size is ",
      format_numeric(ceiling(sample_size * (1 + discon)), as_integer = TRUE),
      " participants"
    )
  )

  # Add recommendation about rare event
  if (incidence_rate > 200) {
    recommendations <- c(recommendations,
      paste0(
        "For very rare events (1 in ", format_numeric(incidence_rate, as_integer = TRUE),
        "), consider extended follow-up or enrichment strategies"
      )
    )
  }

  # Detailed text content
  text_content <- tagList(
    create_result_header(),
    p(paste0(
      "Based on the Binomial distribution and a true event incidence rate of 1 in ",
      format_numeric(incidence_rate, as_integer = TRUE), " (or ",
      format_numeric(1 / incidence_rate, as_percent = TRUE), "), with ",
      format_numeric(sample_size, as_integer = TRUE),
      " participants, the probability of observing at least one event is ",
      format_numeric(power, as_percent = TRUE, digits = 0), " (α = ",
      alpha, "). Accounting for a possible withdrawal or discontinuation rate of ",
      format_numeric(discon, as_percent = TRUE, digits = 0), ", the adjusted sample size is ",
      format_numeric(ceiling(sample_size * (1 + discon)), as_integer = TRUE),
      " to maintain this power."
    ))
  )

  # Use enhanced results layout
  create_enhanced_results(
    main_card_config = main_card,
    text_content = text_content,
    key_findings = key_findings,
    recommendations = recommendations
  )
}


#' Create Sample Size Result Text (Generic Template)
#'
#' Generates formatted result text for sample size calculations.
#' This is a more flexible template that can be customized per analysis type.
#'
#' @param main_text Main paragraph describing the calculation
#' @param n_base Base sample size before adjustments
#' @param n_after_discon Sample size after discontinuation adjustment
#' @param n_final Final sample size after all adjustments
#' @param discon Discontinuation rate (as proportion)
#' @param missing_adj Missing data adjustment object (or NULL)
#' @param additional_info Optional additional HTML content
#'
#' @return HTML formatted text
create_sample_size_result_text <- function(main_text,
                                           n_base,
                                           n_after_discon,
                                           n_final,
                                           discon,
                                           missing_adj = NULL,
                                           additional_info = NULL) {

  result <- tagList(
    create_result_header(),
    p(main_text)
  )

  # Add discontinuation adjustment note if applicable
  if (discon > 0) {
    result <- tagList(
      result,
      p(paste0(
        "After accounting for a withdrawal/discontinuation rate of ",
        format_numeric(discon, as_percent = TRUE, digits = 0),
        ", the required sample size increases from ",
        format_numeric(n_base, as_integer = TRUE), " to ",
        format_numeric(n_after_discon, as_integer = TRUE), "."
      ))
    )
  }

  # Add missing data adjustment if applicable
  if (!is.null(missing_adj)) {
    result <- tagList(
      result,
      format_missing_data_text(missing_adj, n_before = n_after_discon)
    )
  }

  # Add final recommendation
  result <- tagList(
    result,
    p(strong(paste0(
      "Recommended total sample size: ",
      format_numeric(n_final, as_integer = TRUE), " participants"
    )))
  )

  # Add any additional information
  if (!is.null(additional_info)) {
    result <- tagList(result, additional_info)
  }

  HTML(as.character(result))
}


#' Create Effect Measures Display
#'
#' Formats effect measures (RR, OR, RD) for two-group comparisons.
#'
#' @param effect_measures List with RR, OR, RD values
#'
#' @return HTML formatted text
format_effect_measures <- function(effect_measures) {
  tagList(
    h4("Effect Measures"),
    p(paste0(
      strong("Risk Difference (RD): "),
      format_numeric(effect_measures$RD, digits = 3),
      if (!is.na(effect_measures$RD) && effect_measures$RD > 0) {
        paste0(" (", format_numeric(effect_measures$RD, as_percent = TRUE, digits = 1), " absolute increase)")
      } else if (!is.na(effect_measures$RD) && effect_measures$RD < 0) {
        paste0(" (", format_numeric(abs(effect_measures$RD), as_percent = TRUE, digits = 1), " absolute decrease)")
      } else {
        ""
      },
      "<br>",
      strong("Relative Risk (RR): "),
      if (!is.na(effect_measures$RR)) {
        format_numeric(effect_measures$RR, digits = 2)
      } else {
        "Not calculable (baseline rate = 0)"
      },
      "<br>",
      strong("Odds Ratio (OR): "),
      if (!is.na(effect_measures$OR)) {
        format_numeric(effect_measures$OR, digits = 2)
      } else {
        "Not calculable"
      }
    ))
  )
}


#' Create Hazard Ratio Interpretation
#'
#' Formats hazard ratio interpretation for survival analysis.
#'
#' @param hr Hazard ratio value
#'
#' @return HTML formatted text
format_hazard_ratio <- function(hr) {
  interpretation <- if (hr < 1) {
    paste0(
      "A hazard ratio of ", format_numeric(hr, digits = 2),
      " indicates a ", format_numeric((1 - hr), as_percent = TRUE, digits = 0),
      " reduction in the hazard rate."
    )
  } else if (hr > 1) {
    paste0(
      "A hazard ratio of ", format_numeric(hr, digits = 2),
      " indicates a ", format_numeric((hr - 1), as_percent = TRUE, digits = 0),
      " increase in the hazard rate."
    )
  } else {
    "A hazard ratio of 1.0 indicates no difference between groups."
  }

  tagList(
    h4("Effect Size Interpretation"),
    p(interpretation)
  )
}


#' Create Cohen's d Interpretation
#'
#' Formats Cohen's d interpretation for continuous outcomes.
#'
#' @param d Cohen's d value
#'
#' @return HTML formatted text
format_cohens_d <- function(d) {
  magnitude <- if (abs(d) < 0.2) {
    "trivial"
  } else if (abs(d) < 0.5) {
    "small"
  } else if (abs(d) < 0.8) {
    "medium"
  } else {
    "large"
  }

  tagList(
    h4("Effect Size Interpretation"),
    p(paste0(
      "Cohen's d = ", format_numeric(d, digits = 2),
      " represents a ", strong(magnitude), " effect size."
    ))
  )
}

#' Format Minimal Detectable Effect
#'
#' Creates a formatted box showing minimal detectable effect measures
#'
#' @param p1 Proportion in group 1
#' @param p2 Proportion in group 2
#' @param effect_measures List with RR, OR, RD
#' @param h Cohen's h value
#'
#' @return HTML formatted text
format_minimal_detectable_effect <- function(p1, p2, effect_measures, h) {
  risk_diff <- effect_measures$RD * 100

  HTML(paste0(
    "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
    "<strong>Minimal Detectable Effect:</strong><br>",
    "<strong>Group 1 Event Rate:</strong> ", format(p1 * 100, digits = 2), "%<br>",
    "<strong>Group 2 Event Rate:</strong> ", format(p2 * 100, digits = 2), "%<br>",
    "<strong>Risk Difference:</strong> ", format(abs(risk_diff), digits = 2), " percentage points<br>",
    "<strong>Relative Risk:</strong> ", ifelse(is.na(effect_measures$RR), "N/A", format(effect_measures$RR, digits = 3)), "<br>",
    "<strong>Odds Ratio:</strong> ", ifelse(is.na(effect_measures$OR), "N/A", format(effect_measures$OR, digits = 3)), "<br>",
    "<strong>Cohen's h:</strong> ", format(h, digits = 3),
    "</p>"
  ))
}


#' Create Survival Power Analysis Result Text
#'
#' Generates formatted result text for survival analysis power calculations.
#'
#' @param n Total sample size
#' @param hr Hazard ratio
#' @param k Proportion exposed (as proportion, e.g., 0.5)
#' @param pE Overall event rate (as proportion)
#' @param power Calculated power (as proportion)
#' @param alpha Significance level
#'
#' @return HTML formatted text
create_survival_power_result_text <- function(n, hr, k, pE, power, alpha) {
  tagList(
    create_result_header(),
    p(paste0(
      "For a survival analysis with N = ", n, " total participants, ",
      format_numeric(k, as_percent = TRUE, digits = 1), " exposed/treated, an overall event rate of ",
      format_numeric(pE, as_percent = TRUE, digits = 1), ", and an expected hazard ratio of ",
      format_numeric(hr, digits = 2), ", the study has ",
      format_numeric(power, as_percent = TRUE, digits = 1), " power to detect this effect using Cox regression at α = ",
      alpha, " (two-sided test). This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
    )),
    format_hazard_ratio(hr)
  )
}


#' Create Continuous Outcomes Power Analysis Result Text
#'
#' Generates formatted result text for continuous outcomes power calculations.
#'
#' @param n1 Sample size for group 1
#' @param n2 Sample size for group 2
#' @param d Effect size (Cohen's d)
#' @param power Calculated power (as proportion)
#' @param alpha Significance level
#' @param sided Test type ("two.sided", "greater", "less")
#'
#' @return HTML formatted text
create_continuous_power_result_text <- function(n1, n2, d, power, alpha, sided) {
  tagList(
    create_result_header(),
    p(paste0(
      "For a two-group comparison of continuous outcomes with sample sizes of n1 = ",
      n1, " and n2 = ", n2, ", and an expected effect size of Cohen's d = ",
      format_numeric(d, digits = 2), " (standardized mean difference), the study has ",
      format_numeric(power, as_percent = TRUE, digits = 1), " power to detect this difference using a two-sample t-test at α = ",
      alpha, " (", sided, " test). ",
      "Cohen's d represents the difference in means divided by the pooled standard deviation."
    )),
    format_cohens_d(d)
  )
}


#' Create Time-to-Event NI Sample Size Result Text
#'
#' Generates formatted result text for time-to-event non-inferiority sample size calculations.
#'
#' @param n_total Total sample size required
#' @param n_test Sample size for test group
#' @param n_ref Sample size for reference group
#' @param d_events Number of events required
#' @param hr_expected Expected hazard ratio
#' @param hr_margin Non-inferiority margin
#' @param power Desired power (as proportion)
#' @param alpha Significance level
#' @param prop_exposed Proportion in exposed/treatment group (as proportion)
#' @param event_rate Overall event rate (as proportion)
#'
#' @return HTML formatted text
create_survival_ni_samplesize_text <- function(n_total, n_test, n_ref, d_events,
                                                hr_expected, hr_margin, power, alpha,
                                                prop_exposed, event_rate) {
  # Calculate percent increase acceptable
  pct_increase <- round((hr_margin - 1) * 100, 1)

  tagList(
    create_result_header(),
    p(paste0(
      "For a time-to-event non-inferiority study with an expected hazard ratio of HR = ",
      format_numeric(hr_expected, digits = 3), " and a non-inferiority margin of HR = ",
      format_numeric(hr_margin, digits = 3), " (accepting up to ", pct_increase,
      "% increase in hazard as 'non-inferior'), the required total sample size is <strong>N = ",
      n_total, "</strong> participants (",
      n_test, " in test group, ",
      n_ref, " in reference group) to achieve ",
      format_numeric(power, as_percent = TRUE, digits = 1), " power at α = ",
      alpha, " (one-sided test). "
    )),
    p(paste0(
      "This calculation assumes an overall event rate of ",
      format_numeric(event_rate, as_percent = TRUE, digits = 1), " during the study follow-up period, ",
      "which translates to approximately <strong>", d_events,
      " events</strong> needed to achieve the target power. ",
      "The method is based on the Schoenfeld (1983) approach adapted for non-inferiority testing."
    )),
    format_hazard_ratio(hr_expected),
    HTML(paste0(
      "<div style='background-color: #e3f2fd; border-left: 4px solid #2196f3; padding: 10px; margin: 15px 0;'>",
      "<strong>Non-Inferiority Margin Interpretation:</strong><br>",
      "A margin of HR = ", format_numeric(hr_margin, digits = 3),
      " means you will declare the test treatment 'non-inferior' if the upper bound ",
      "of the 95% confidence interval for HR is below ", format_numeric(hr_margin, digits = 3), ". ",
      "This margin should be justified based on clinical importance and regulatory guidance.",
      "</div>"
    ))
  )
}


#' Create Time-to-Event Equivalence Sample Size Result Text
#'
#' Generates formatted result text for time-to-event equivalence sample size calculations.
#'
#' @param n_total Total sample size required
#' @param n_test Sample size for test group
#' @param n_ref Sample size for reference group
#' @param d_events Number of events required
#' @param hr_expected Expected hazard ratio
#' @param hr_lower Lower equivalence margin
#' @param hr_upper Upper equivalence margin
#' @param power Desired power (as proportion)
#' @param alpha Significance level
#' @param prop_exposed Proportion in exposed/treatment group (as proportion)
#' @param event_rate Overall event rate (as proportion)
#'
#' @return HTML formatted text
create_survival_equiv_samplesize_text <- function(n_total, n_test, n_ref, d_events,
                                                   hr_expected, hr_lower, hr_upper,
                                                   power, alpha, prop_exposed, event_rate) {
  tagList(
    create_result_header(),
    p(paste0(
      "For a time-to-event equivalence study with an expected hazard ratio of HR = ",
      format_numeric(hr_expected, digits = 3), " and equivalence margins of [",
      format_numeric(hr_lower, digits = 3), ", ",
      format_numeric(hr_upper, digits = 3), "], the required total sample size is <strong>N = ",
      n_total, "</strong> participants (",
      n_test, " in test group, ",
      n_ref, " in reference group) to achieve ",
      format_numeric(power, as_percent = TRUE, digits = 1), " power at α = ",
      alpha, " (two one-sided tests - TOST procedure). "
    )),
    p(paste0(
      "This calculation assumes an overall event rate of ",
      format_numeric(event_rate, as_percent = TRUE, digits = 1), " during the study follow-up period, ",
      "which translates to approximately <strong>", d_events,
      " events</strong> needed. ",
      "Equivalence will be declared if the 90% confidence interval for HR lies entirely within [",
      format_numeric(hr_lower, digits = 3), ", ",
      format_numeric(hr_upper, digits = 3), "]."
    )),
    format_hazard_ratio(hr_expected),
    HTML(paste0(
      "<div style='background-color: #e8f5e9; border-left: 4px solid #4caf50; padding: 10px; margin: 15px 0;'>",
      "<strong>Equivalence Margins Interpretation:</strong><br>",
      "Equivalence margins of [", format_numeric(hr_lower, digits = 3), ", ",
      format_numeric(hr_upper, digits = 3), "] define the region where treatments are considered 'equivalent'. ",
      "The true HR must lie within this range with high confidence to declare equivalence. ",
      "These margins should be justified based on clinical importance.",
      "</div>"
    ))
  )
}


#' Create Time-to-Event NI Margin Calculation Result Text
#'
#' Generates formatted result text for minimal detectable NI margin calculations.
#'
#' @param margin_detectable Minimal detectable margin (HR)
#' @param n_total Total sample size
#' @param hr_expected Expected hazard ratio
#' @param power Desired power (as proportion)
#' @param alpha Significance level
#' @param event_rate Overall event rate (as proportion)
#'
#' @return HTML formatted text
create_survival_ni_margin_text <- function(margin_detectable, n_total, hr_expected,
                                            power, alpha, event_rate) {
  # Calculate percent increase
  pct_increase <- round((margin_detectable - 1) * 100, 1)

  # Determine interpretation
  if (margin_detectable < 1.15) {
    interpretation <- "very stringent"
    color <- "#2e7d32"
  } else if (margin_detectable < 1.25) {
    interpretation <- "stringent"
    color <- "#66bb6a"
  } else if (margin_detectable < 1.50) {
    interpretation <- "moderate"
    color <- "#ff9800"
  } else {
    interpretation <- "liberal"
    color <- "#d32f2f"
  }

  tagList(
    create_result_header(),
    p(paste0(
      "With a fixed total sample size of N = ", n_total, " participants, ",
      "an expected hazard ratio of HR = ", format_numeric(hr_expected, digits = 3), ", ",
      "and ", format_numeric(power, as_percent = TRUE, digits = 1), " power at α = ",
      alpha, " (one-sided), the <strong>minimal detectable non-inferiority margin is HR = ",
      format_numeric(margin_detectable, digits = 3), "</strong>."
    )),
    p(paste0(
      "This means with this sample size, you can demonstrate non-inferiority if the true HR ",
      "is better than (lower than) ", format_numeric(margin_detectable, digits = 3),
      " with the specified power. This margin represents accepting up to a ",
      pct_increase, "% increase in hazard rate as 'non-inferior', which is considered a ",
      "<strong style='color: ", color, ";'>", interpretation, "</strong> margin."
    )),
    HTML(paste0(
      "<div style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin: 15px 0;'>",
      "<strong>Feasibility Assessment:</strong><br>",
      "Consider whether this detectable margin (HR = ", format_numeric(margin_detectable, digits = 3),
      ") is clinically acceptable for your research question. If this margin is too liberal, ",
      "you may need to increase your sample size.",
      "</div>"
    ))
  )
}
