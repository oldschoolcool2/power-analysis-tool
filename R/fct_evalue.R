#' Calculate E-value for Sensitivity Analysis
#'
#' Business logic for calculating E-values to assess robustness of effect
#' estimates to unmeasured confounding. E-values quantify the minimum strength
#' of association that an unmeasured confounder would need to have with both
#' the treatment and outcome to fully explain away an observed association.
#'
#' @details
#' E-values provide a standardized way to assess the robustness of study findings
#' to potential unmeasured confounding. Higher E-values indicate greater robustness.
#'
#' Interpretation Guidelines:
#'   - E-value = 1.0: No unmeasured confounding needed (result is null)
#'   - E-value < 1.5: Weak, easily explained by minor confounding
#'   - E-value 1.5-2.0: Moderate, requires moderate confounding
#'   - E-value > 2.0: Strong, requires strong confounding to explain away
#'   - E-value > 3.0: Very robust to unmeasured confounding
#'
#' @references
#' VanderWeele, T.J., & Ding, P. (2017). Sensitivity Analysis in Observational
#' Research: Introducing the E-Value. Annals of Internal Medicine, 167(4):268-274.
#' doi:10.7326/M16-2607


#' Calculate E-value from Relative Risk
#'
#' @param rr Point estimate of relative risk
#' @param lo Lower confidence limit (optional)
#' @param hi Upper confidence limit (optional)
#' @param true_value Null value for RR (default 1)
#'
#' @return List with E-values and interpretation
#'
#' @examples
#' # RR = 2.0 with 95% CI [1.5, 2.8]
#' result <- calc_evalue_rr(2.0, lo = 1.5, hi = 2.8)
#'
#' @noRd
calc_evalue_rr <- function(rr, lo = NA, hi = NA, true_value = 1) {
  # Input validation
  if (!is.numeric(rr) || rr <= 0) {
    stop("RR must be a positive number")
  }

  # Calculate E-values using EValue package
  result <- EValue::evalues.RR(
    est = rr,
    lo = lo,
    hi = hi,
    true = true_value
  )

  # Extract values
  evalue_point <- result[2, 1]  # E-value for point estimate
  evalue_ci <- if (!is.na(lo) && !is.na(result[2, 2])) {
    result[2, 2]  # E-value for confidence interval
  } else {
    NA
  }

  # Interpretation
  interpretation <- interpret_evalue(evalue_point, evalue_ci)

  list(
    evalue_point = evalue_point,
    evalue_ci = evalue_ci,
    rr_converted = result[1, 1],  # Original RR
    interpretation = interpretation,
    result_matrix = result
  )
}


#' Calculate E-value from Odds Ratio
#'
#' @param or Point estimate of odds ratio
#' @param lo Lower confidence limit (optional)
#' @param hi Upper confidence limit (optional)
#' @param rare Logical, whether outcome is rare (<15%) (default TRUE)
#' @param true_value Null value for OR (default 1)
#'
#' @return List with E-values and interpretation
#'
#' @details
#' For rare outcomes, OR approximates RR. For common outcomes, the function
#' converts OR to RR before calculating E-values.
#'
#' @examples
#' # OR = 2.5 with 95% CI [1.8, 3.5], common outcome
#' result <- calc_evalue_or(2.5, lo = 1.8, hi = 3.5, rare = FALSE)
#'
#' @noRd
calc_evalue_or <- function(or, lo = NA, hi = NA, rare = TRUE, true_value = 1) {
  # Input validation
  if (!is.numeric(or) || or <= 0) {
    stop("OR must be a positive number")
  }

  # Calculate E-values using EValue package
  result <- EValue::evalues.OR(
    est = or,
    lo = lo,
    hi = hi,
    rare = rare,
    true = true_value
  )

  # Extract values
  evalue_point <- result[2, 1]  # E-value for point estimate
  evalue_ci <- if (!is.na(lo) && !is.na(result[2, 2])) {
    result[2, 2]  # E-value for confidence interval
  } else {
    NA
  }

  # RR (converted if not rare)
  rr_converted <- result[1, 1]

  # Interpretation
  interpretation <- interpret_evalue(evalue_point, evalue_ci)

  # Add note about OR to RR conversion if not rare
  if (!rare) {
    interpretation$notes <- paste0(
      interpretation$notes,
      " Note: For common outcomes, OR was converted to RR (",
      format_numeric(rr_converted, 2),
      ") before calculating E-values."
    )
  }

  list(
    evalue_point = evalue_point,
    evalue_ci = evalue_ci,
    or_original = or,
    rr_converted = rr_converted,
    interpretation = interpretation,
    result_matrix = result
  )
}


#' Calculate E-value from Hazard Ratio
#'
#' @param hr Point estimate of hazard ratio
#' @param lo Lower confidence limit (optional)
#' @param hi Upper confidence limit (optional)
#' @param rare Logical, whether outcome is rare (default TRUE)
#' @param true_value Null value for HR (default 1)
#'
#' @return List with E-values and interpretation
#'
#' @examples
#' # HR = 1.8 with 95% CI [1.3, 2.5]
#' result <- calc_evalue_hr(1.8, lo = 1.3, hi = 2.5)
#'
#' @noRd
calc_evalue_hr <- function(hr, lo = NA, hi = NA, rare = TRUE, true_value = 1) {
  # Input validation
  if (!is.numeric(hr) || hr <= 0) {
    stop("HR must be a positive number")
  }

  # Calculate E-values using EValue package
  result <- EValue::evalues.HR(
    est = hr,
    lo = lo,
    hi = hi,
    rare = rare,
    true = true_value
  )

  # Extract values
  evalue_point <- result[2, 1]  # E-value for point estimate
  evalue_ci <- if (!is.na(lo) && !is.na(result[2, 2])) {
    result[2, 2]  # E-value for confidence interval
  } else {
    NA
  }

  # RR (converted if not rare)
  rr_converted <- result[1, 1]

  # Interpretation
  interpretation <- interpret_evalue(evalue_point, evalue_ci)

  list(
    evalue_point = evalue_point,
    evalue_ci = evalue_ci,
    hr_original = hr,
    rr_converted = rr_converted,
    interpretation = interpretation,
    result_matrix = result
  )
}


#' Calculate E-value from Mean Difference (Continuous Outcomes)
#'
#' @param md Point estimate of mean difference
#' @param se Standard error of mean difference (optional)
#' @param sd Standard deviation for standardization (optional, for Cohen's d)
#' @param true_value Null value for MD (default 0)
#'
#' @return List with E-values and interpretation
#'
#' @details
#' For continuous outcomes, the function converts the mean difference to the
#' risk ratio scale before calculating E-values.
#'
#' @examples
#' # Mean difference = 0.5 with SE = 0.1
#' result <- calc_evalue_md(0.5, se = 0.1)
#'
#' @noRd
calc_evalue_md <- function(md, se = NA, sd = NA, true_value = 0) {
  # Input validation
  if (!is.numeric(md)) {
    stop("Mean difference must be numeric")
  }

  # Calculate E-values using EValue package
  result <- EValue::evalues.MD(
    est = md,
    se = se,
    true = true_value
  )

  # Extract values
  evalue_point <- result[2, 1]  # E-value for point estimate
  evalue_ci <- if (!is.na(se) && !is.na(result[2, 2])) {
    result[2, 2]  # E-value for confidence interval
  } else {
    NA
  }

  # RR scale conversion
  rr_converted <- result[1, 1]

  # Interpretation
  interpretation <- interpret_evalue(evalue_point, evalue_ci)

  # Add note about MD to RR conversion
  interpretation$notes <- paste0(
    interpretation$notes,
    " Note: Mean difference was converted to risk ratio scale (RR = ",
    format_numeric(rr_converted, 2),
    ") for E-value calculation."
  )

  list(
    evalue_point = evalue_point,
    evalue_ci = evalue_ci,
    md_original = md,
    rr_converted = rr_converted,
    interpretation = interpretation,
    result_matrix = result
  )
}


#' Interpret E-value Magnitude
#'
#' @param evalue_point E-value for point estimate
#' @param evalue_ci E-value for confidence interval (optional)
#'
#' @return List with interpretation components
#'
#' @noRd
interpret_evalue <- function(evalue_point, evalue_ci = NA) {

  # Categorize E-value magnitude
  if (evalue_point < 1.5) {
    magnitude <- "weak"
    css_class <- "evalue-weak"
    robustness <- "Weak robustness: Minor unmeasured confounding could explain away the effect."
    icon <- "⚠️"
  } else if (evalue_point < 2.0) {
    magnitude <- "moderate"
    css_class <- "evalue-moderate"
    robustness <- "Moderate robustness: Requires moderate unmeasured confounding to explain away the effect."
    icon <- "⚡"
  } else if (evalue_point < 3.0) {
    magnitude <- "strong"
    css_class <- "evalue-strong"
    robustness <- "Strong robustness: Requires strong unmeasured confounding to explain away the effect."
    icon <- "✓"
  } else {
    magnitude <- "very strong"
    css_class <- "evalue-very-strong"
    robustness <- "Very strong robustness: Effect is highly robust to unmeasured confounding."
    icon <- "✓✓"
  }

  # Interpretation text
  main_text <- sprintf(
    "The E-value of <strong>%.2f</strong> indicates that an unmeasured confounder would need to be associated with both the exposure and outcome by a risk ratio of %.2f-fold each, above and beyond the measured confounders, to explain away the observed effect.",
    evalue_point, evalue_point
  )

  # CI interpretation if available
  ci_text <- if (!is.na(evalue_ci)) {
    sprintf(
      " The E-value for the confidence interval is <strong>%.2f</strong>, indicating the minimum confounding strength needed to shift the confidence interval to include the null.",
      evalue_ci
    )
  } else {
    ""
  }

  # Practical guidance
  guidance <- paste0(
    "<br><br><strong>Practical Interpretation:</strong> ",
    robustness,
    " Consider whether unmeasured confounders of this magnitude are plausible in your study context."
  )

  list(
    magnitude = magnitude,
    css_class = css_class,
    icon = icon,
    robustness = robustness,
    main_text = main_text,
    ci_text = ci_text,
    guidance = guidance,
    notes = ""
  )
}


#' Format E-value Results as HTML
#'
#' @param evalue_result Result from calc_evalue_* functions
#' @param effect_type Type of effect measure ("RR", "OR", "HR", "MD")
#'
#' @return HTML formatted string with E-value results
#'
#' @noRd
format_evalue_result <- function(evalue_result, effect_type = "RR") {

  interp <- evalue_result$interpretation

  # Build HTML output using CSS classes for proper dark mode support
  html_output <- paste0(
    "<div class='evalue-result-card ", interp$css_class, "'>",
    "<h4>",
    interp$icon, " E-value Sensitivity Analysis</h4>",
    "<p>", interp$main_text, interp$ci_text, "</p>",
    "<p><strong>E-value (point estimate):</strong> ",
    format_numeric(evalue_result$evalue_point, 2), "</p>"
  )

  # Add CI E-value if available
  if (!is.na(evalue_result$evalue_ci)) {
    html_output <- paste0(
      html_output,
      "<p><strong>E-value (confidence interval):</strong> ",
      format_numeric(evalue_result$evalue_ci, 2), "</p>"
    )
  }

  # Add guidance
  html_output <- paste0(html_output, interp$guidance)

  # Add notes if any
  if (nchar(interp$notes) > 0) {
    html_output <- paste0(
      html_output,
      "<p class='evalue-notes'>",
      interp$notes,
      "</p>"
    )
  }

  html_output <- paste0(html_output, "</div>")

  HTML(html_output)
}


#' Validate E-value Inputs
#'
#' @param effect_estimate Effect estimate value
#' @param lo Lower confidence limit
#' @param hi Upper confidence limit
#' @param effect_type Type of effect ("RR", "OR", "HR", "MD")
#'
#' @return List with 'valid' (logical) and 'messages' (character vector)
#'
#' @noRd
validate_evalue_inputs <- function(effect_estimate, lo = NA, hi = NA, effect_type = "RR") {
  valid <- TRUE
  messages <- character(0)

  # Check effect estimate
  if (effect_type %in% c("RR", "OR", "HR")) {
    # Ratio measures must be positive
    if (is.na(effect_estimate) || effect_estimate <= 0) {
      valid <- FALSE
      messages <- c(messages, paste0("ERROR: ", effect_type, " must be a positive number."))
    }

    # Warn if effect is null
    if (!is.na(effect_estimate) && abs(effect_estimate - 1) < 0.01) {
      messages <- c(messages, "WARNING: Effect estimate is very close to null (1.0). E-value will be minimal.")
    }
  } else if (effect_type == "MD") {
    # Mean difference can be any numeric value
    if (is.na(effect_estimate) || !is.numeric(effect_estimate)) {
      valid <- FALSE
      messages <- c(messages, "ERROR: Mean difference must be numeric.")
    }

    # Warn if effect is null
    if (!is.na(effect_estimate) && abs(effect_estimate) < 0.001) {
      messages <- c(messages, "WARNING: Mean difference is very close to zero. E-value will be minimal.")
    }
  }

  # Check confidence interval consistency
  if (!is.na(lo) && !is.na(hi)) {
    if (effect_type %in% c("RR", "OR", "HR")) {
      # For ratios, CI should straddle the estimate
      if (lo > effect_estimate || hi < effect_estimate) {
        messages <- c(messages, "WARNING: Confidence interval does not contain the point estimate.")
      }
      if (lo >= hi) {
        valid <- FALSE
        messages <- c(messages, "ERROR: Lower confidence limit must be less than upper limit.")
      }
    } else if (effect_type == "MD") {
      # For differences, similar check
      if (lo >= hi) {
        valid <- FALSE
        messages <- c(messages, "ERROR: Lower confidence limit must be less than upper limit.")
      }
    }
  }

  list(
    valid = valid,
    messages = messages
  )
}
