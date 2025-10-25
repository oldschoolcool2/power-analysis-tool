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
  HTML(paste0(
    "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
    "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
    missing_adj$interpretation,
    "<br><strong>Sample size before missing data adjustment:</strong> ", n_before,
    "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
    "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
    "</p>"
  ))
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

  if (as_integer) {
    return(format(ceiling(value), digits = 0, nsmall = 0))
  }

  if (as_percent) {
    return(paste0(format(value * 100, digits = digits, nsmall = nsmall), "%"))
  }

  format(value, digits = digits, nsmall = nsmall)
}


#' Create Power Analysis Result Text (Single Proportion)
#'
#' Generates formatted result text for single proportion power analysis.
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
  tagList(
    create_result_header(),
    p(paste0(
      "Based on the Binomial distribution and a true event incidence rate of 1 in ",
      format_numeric(incidence_rate, as_integer = TRUE), " (or ",
      format_numeric(1 / incidence_rate, as_percent = TRUE), "%), with ",
      format_numeric(sample_size, as_integer = TRUE),
      " participants, the probability of observing at least one event is ",
      format_numeric(power, as_percent = TRUE, digits = 0), " (α = ",
      alpha, "). Accounting for a possible withdrawal or discontinuation rate of ",
      format_numeric(discon, as_percent = TRUE, digits = 0), "%, the adjusted sample size is ",
      format_numeric(ceiling(sample_size * (1 + discon)), as_integer = TRUE),
      " to maintain this power."
    ))
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
        "%, the required sample size increases from ",
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
    "<strong>Minimal Detectable Effect (Tier 1 Enhancement):</strong><br>",
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
      format_numeric(pE, as_percent = TRUE, digits = 1), "%, and an expected hazard ratio of ",
      format_numeric(hr, digits = 2), ", the study has ",
      format_numeric(power, as_percent = TRUE, digits = 1), " power to detect this effect using Cox regression at α = ",
      alpha, " (two-sided test). This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
    )),
    format_hazard_ratio(hr)
  )
}
