#' Calculate Multiple-Bias Sensitivity Analysis
#'
#' Business logic for multiple-bias sensitivity analysis using the EValue package.
#' Allows assessment of multiple biases jointly (unmeasured confounding,
#' selection bias, and differential misclassification) to understand how
#' combinations of biases could affect study results.
#'
#' @details
#' Multiple-bias E-values represent the minimum value that all sensitivity
#' parameters would need to take on simultaneously for an observed association
#' to be explained away as null. This approach recognizes that real studies
#' are often subject to multiple sources of bias acting together.
#'
#' @references
#' Smith, L.H., & VanderWeele, T.J. (2019). Bounding bias due to selection.
#' Epidemiology, 30(4), 509-516.
#'
#' Mathur, M.B., & VanderWeele, T.J. (2020). Robust metrics and sensitivity
#' analyses for meta-analyses of heterogeneous effects. Epidemiology, 31(3), 356-358.


#' Create Multi-Bias Specification
#'
#' Creates a multi_bias object combining different bias types for sensitivity analysis.
#'
#' @param include_confounding Logical, include unmeasured confounding
#' @param include_selection Logical, include selection bias
#' @param include_misclass Logical, include misclassification bias
#' @param selection_type Character, "general" or "selected" population
#' @param misclass_type Character, "outcome" or "exposure" misclassification
#' @param outcome_rare Logical, for exposure misclassification (rare outcome assumption)
#' @param exposure_rare Logical, for exposure misclassification (rare exposure assumption)
#'
#' @return A multi_bias object from the EValue package
#'
#' @noRd
create_multi_bias <- function(include_confounding = TRUE,
                              include_selection = FALSE,
                              include_misclass = FALSE,
                              selection_type = "general",
                              misclass_type = "outcome",
                              outcome_rare = TRUE,
                              exposure_rare = TRUE) {

  # Build list of bias specifications
  biases <- list()

  if (include_confounding) {
    biases <- c(biases, list(EValue::confounding()))
  }

  if (include_selection) {
    biases <- c(biases, list(EValue::selection(selection_type)))
  }

  if (include_misclass) {
    if (misclass_type == "outcome") {
      biases <- c(biases, list(EValue::misclassification("outcome")))
    } else if (misclass_type == "exposure") {
      biases <- c(biases, list(EValue::misclassification("exposure",
                                                          rare_outcome = outcome_rare,
                                                          rare_exposure = exposure_rare)))
    }
  }

  # Check that at least one bias is included
  if (length(biases) == 0) {
    stop("At least one bias type must be selected")
  }

  # Create multi_bias object
  do.call(EValue::multi_bias, biases)
}


#' Calculate Multi-Bias E-value
#'
#' Calculates the multi-bias E-value for a given effect estimate.
#'
#' @param multi_bias_obj A multi_bias object from create_multi_bias()
#' @param rr Point estimate as risk ratio
#' @param lo Lower confidence limit (optional)
#' @param hi Upper confidence limit (optional)
#' @param true_rr True risk ratio under the null (default 1)
#'
#' @return List with multi-bias E-value and interpretation
#'
#' @noRd
calc_multi_evalue <- function(multi_bias_obj, rr, lo = NA, hi = NA, true_rr = 1) {

  # Input validation
  if (!is.numeric(rr) || rr <= 0) {
    stop("RR must be a positive number")
  }

  # Calculate multi-bias E-value
  result <- tryCatch({
    if (!is.na(lo) && !is.na(hi)) {
      EValue::multi_evalue(
        multi_bias_obj,
        est = EValue::RR(rr, lo, hi),
        true_rr = true_rr
      )
    } else {
      EValue::multi_evalue(
        multi_bias_obj,
        est = EValue::RR(rr),
        true_rr = true_rr
      )
    }
  }, error = function(e) {
    stop(paste("Multi-bias E-value calculation failed:", e$message))
  })

  # Extract E-value
  evalue <- result[1, "evalue"]

  # Interpretation
  interpretation <- interpret_multi_evalue(
    evalue = evalue,
    rr = rr,
    multi_bias_obj = multi_bias_obj
  )

  list(
    evalue = evalue,
    rr = rr,
    lo = lo,
    hi = hi,
    interpretation = interpretation,
    multi_bias_obj = multi_bias_obj,
    result_table = result
  )
}


#' Calculate Multi-Bias Bound
#'
#' Calculates adjusted effect bounds given specific bias parameter values.
#'
#' @param multi_bias_obj A multi_bias object
#' @param rr Observed risk ratio
#' @param lo Lower confidence limit (optional)
#' @param hi Upper confidence limit (optional)
#' @param bias_parms Named list of bias parameter values
#' @param true_rr True risk ratio under the null (default 1)
#'
#' @return List with bias-adjusted bounds and interpretation
#'
#' @noRd
calc_multi_bound <- function(multi_bias_obj, rr, lo = NA, hi = NA,
                              bias_parms = list(), true_rr = 1) {

  # Input validation
  if (!is.numeric(rr) || rr <= 0) {
    stop("RR must be a positive number")
  }

  if (length(bias_parms) == 0) {
    stop("Bias parameters must be specified")
  }

  # Calculate bias-adjusted bound (bias factor)
  # multi_bound returns a single numeric value (the bias factor)
  bias_factor <- tryCatch({
    do.call(EValue::multi_bound,
            c(list(multi_bias_obj,
                  EValue::RR(rr)),
              bias_parms))
  }, error = function(e) {
    stop(paste("Multi-bias bound calculation failed:", e$message))
  })

  # Calculate adjusted RR by dividing original RR by bias factor
  # The bias factor represents how much the observed RR could be attenuated
  bound_est <- rr / bias_factor
  
  # Calculate adjusted confidence bounds if provided
  # Apply the same bias factor to the confidence limits
  bound_lo <- if (!is.na(lo)) lo / bias_factor else NA
  bound_hi <- if (!is.na(hi)) hi / bias_factor else NA

  # Interpretation
  interpretation <- interpret_multi_bound(
    original_rr = rr,
    adjusted_rr = bound_est,
    bias_parms = bias_parms
  )

  list(
    original_rr = rr,
    bias_factor = bias_factor,
    adjusted_rr = bound_est,
    adjusted_lo = bound_lo,
    adjusted_hi = bound_hi,
    bias_parms = bias_parms,
    interpretation = interpretation
  )
}


#' Interpret Multi-Bias E-value
#'
#' @param evalue Multi-bias E-value
#' @param rr Observed risk ratio
#' @param multi_bias_obj The multi_bias object
#'
#' @return List with interpretation components
#'
#' @noRd
interpret_multi_evalue <- function(evalue, rr, multi_bias_obj) {

  # Determine bias types included
  bias_summary <- summary(multi_bias_obj)
  n_biases <- length(bias_summary$biases)
  bias_names <- vapply(bias_summary$biases, function(b) b$type, character(1))

  # Format bias list for text
  bias_text <- if (n_biases == 1) {
    bias_names[1]
  } else if (n_biases == 2) {
    paste(bias_names[1], "and", bias_names[2])
  } else {
    paste(paste(bias_names[-n_biases], collapse = ", "),
          ", and", bias_names[n_biases])
  }

  # Categorize E-value magnitude (similar to single bias)
  if (evalue < 1.5) {
    magnitude <- "weak"
    css_class <- "multi-bias-weak"
    robustness <- "Weak robustness: Minor bias combinations could explain away the effect."
    icon <- "⚠️"
  } else if (evalue < 2.0) {
    magnitude <- "moderate"
    css_class <- "multi-bias-moderate"
    robustness <- "Moderate robustness: Requires moderate bias combinations to explain away the effect."
    icon <- "⚡"
  } else if (evalue < 3.0) {
    magnitude <- "strong"
    css_class <- "multi-bias-strong"
    robustness <- "Strong robustness: Requires strong bias combinations to explain away the effect."
    icon <- "✓"
  } else {
    magnitude <- "very strong"
    css_class <- "multi-bias-very-strong"
    robustness <- "Very strong robustness: Effect is highly robust to multiple bias combinations."
    icon <- "✓✓"
  }

  # Main interpretation text
  main_text <- sprintf(
    "The multi-bias E-value of <strong>%.2f</strong> indicates that all bias parameters (%s) would need to take on a minimum value of %.2f simultaneously to explain away the observed risk ratio of %.2f as null.",
    evalue, bias_text, evalue, rr
  )

  # Practical guidance
  guidance <- paste0(
    "<br><br><strong>Practical Interpretation:</strong> ",
    robustness,
    " Consider whether combinations of biases of this magnitude are plausible in your study context. ",
    "The multi-bias approach acknowledges that studies are typically affected by multiple biases acting together."
  )

  list(
    magnitude = magnitude,
    css_class = css_class,
    icon = icon,
    robustness = robustness,
    main_text = main_text,
    guidance = guidance,
    n_biases = n_biases,
    bias_text = bias_text
  )
}


#' Interpret Multi-Bias Bound
#'
#' @param original_rr Original observed RR
#' @param adjusted_rr Bias-adjusted RR
#' @param bias_parms List of bias parameter values
#'
#' @return List with interpretation components
#'
#' @noRd
interpret_multi_bound <- function(original_rr, adjusted_rr, bias_parms) {

  # Direction and magnitude of adjustment
  direction <- if (adjusted_rr > original_rr) {
    "increased"
  } else if (adjusted_rr < original_rr) {
    "decreased"
  } else {
    "unchanged"
  }

  pct_change <- abs((adjusted_rr - original_rr) / original_rr * 100)

  # Determine if still significant (moved toward or past null of 1)
  crosses_null <- (original_rr > 1 && adjusted_rr < 1) ||
                  (original_rr < 1 && adjusted_rr > 1)

  # Format bias parameters for display
  bias_parm_text <- paste(
    names(bias_parms),
    "=",
    format_numeric(unlist(bias_parms), 2),
    collapse = ", "
  )

  # Main interpretation
  if (crosses_null) {
    main_text <- sprintf(
      "After adjusting for the specified bias parameters (%s), the observed risk ratio of <strong>%.2f</strong> becomes <strong>%.2f</strong>, crossing the null value of 1.0. This suggests that the observed effect could be fully explained by the specified combination of biases.",
      bias_parm_text, original_rr, adjusted_rr
    )
    css_class <- "multi-bias-null"
    icon <- "⚠️"
  } else {
    main_text <- sprintf(
      "After adjusting for the specified bias parameters (%s), the observed risk ratio of <strong>%.2f</strong> becomes <strong>%.2f</strong> (%.1f%% %s). The effect remains in the same direction, suggesting residual association after accounting for these biases.",
      bias_parm_text, original_rr, adjusted_rr, pct_change, direction
    )
    css_class <- "multi-bias-adjusted"
    icon <- "ℹ️"
  }

  # Guidance
  guidance <- paste0(
    "<br><br><strong>Interpretation:</strong> ",
    "This bound shows what the effect estimate would be if the biases you specified were present. ",
    if (crosses_null) {
      "Since the adjusted estimate crosses the null, these bias magnitudes are sufficient to explain away the observed effect."
    } else {
      "Since the adjusted estimate does not cross the null, even these bias magnitudes would not fully explain away the observed effect."
    }
  )

  list(
    css_class = css_class,
    icon = icon,
    main_text = main_text,
    guidance = guidance,
    direction = direction,
    pct_change = pct_change,
    crosses_null = crosses_null
  )
}


#' Format Multi-Bias E-value Result as HTML
#'
#' @param multi_evalue_result Result from calc_multi_evalue()
#'
#' @return HTML formatted string
#'
#' @noRd
format_multi_evalue_result <- function(multi_evalue_result) {

  interp <- multi_evalue_result$interpretation

  # Build HTML output
  html_output <- paste0(
    "<div class='multi-bias-result-card ", interp$css_class, "'>",
    "<h4>", interp$icon, " Multi-Bias E-value Sensitivity Analysis</h4>",
    "<p>", interp$main_text, "</p>",
    "<p><strong>Multi-bias E-value:</strong> ",
    format_numeric(multi_evalue_result$evalue, 2), "</p>",
    "<p><strong>Observed Risk Ratio:</strong> ",
    format_numeric(multi_evalue_result$rr, 2), "</p>",
    "<p><strong>Number of bias types:</strong> ", interp$n_biases, "</p>",
    interp$guidance,
    "</div>"
  )

  HTML(html_output)
}


#' Format Multi-Bias Bound Result as HTML
#'
#' @param multi_bound_result Result from calc_multi_bound()
#'
#' @return HTML formatted string
#'
#' @noRd
format_multi_bound_result <- function(multi_bound_result) {

  interp <- multi_bound_result$interpretation

  # Build HTML output
  html_output <- paste0(
    "<div class='multi-bias-result-card ", interp$css_class, "'>",
    "<h4>", interp$icon, " Bias-Adjusted Estimate</h4>",
    "<p>", interp$main_text, "</p>",
    "<p><strong>Bias Factor:</strong> ",
    format_numeric(multi_bound_result$bias_factor, 2), "</p>",
    "<p><strong>Original RR:</strong> ",
    format_numeric(multi_bound_result$original_rr, 2), "</p>",
    "<p><strong>Adjusted RR:</strong> ",
    format_numeric(multi_bound_result$adjusted_rr, 2), " ",
    "(attenuated by factor of ", format_numeric(multi_bound_result$bias_factor, 2), ")</p>"
  )

  # Add CI if available
  if (!is.na(multi_bound_result$adjusted_lo) && !is.na(multi_bound_result$adjusted_hi)) {
    html_output <- paste0(
      html_output,
      "<p><strong>Adjusted 95% CI:</strong> [",
      format_numeric(multi_bound_result$adjusted_lo, 2), ", ",
      format_numeric(multi_bound_result$adjusted_hi, 2), "]</p>"
    )
  }

  html_output <- paste0(html_output, interp$guidance, "</div>")

  HTML(html_output)
}


#' Get Required Parameters for Multi-Bias Object
#'
#' Extracts the parameter names required by a multi_bias object for use in UI
#'
#' @param multi_bias_obj A multi_bias object
#'
#' @return Character vector of parameter names
#'
#' @noRd
get_multi_bias_parameters <- function(multi_bias_obj) {
  # Get parameter names from the multi_bias object
  # The parameters are stored in the "parameters" attribute
  parms_df <- attr(multi_bias_obj, "parameters")
  if (is.null(parms_df)) {
    return(character(0))
  }
  # Return the argument column which contains the parameter names for multi_bound()
  parms_df$argument
}


#' Validate Multi-Bias Inputs
#'
#' @param rr Risk ratio
#' @param lo Lower CI (optional)
#' @param hi Upper CI (optional)
#' @param include_confounding Logical
#' @param include_selection Logical
#' @param include_misclass Logical
#'
#' @return List with 'valid' (logical) and 'messages' (character vector)
#'
#' @noRd
validate_multi_bias_inputs <- function(rr, lo = NA, hi = NA,
                                       include_confounding = FALSE,
                                       include_selection = FALSE,
                                       include_misclass = FALSE) {
  valid <- TRUE
  messages <- character(0)

  # Check that at least one bias is selected
  if (!include_confounding && !include_selection && !include_misclass) {
    valid <- FALSE
    messages <- c(messages, "ERROR: At least one bias type must be selected.")
  }

  # Check RR
  if (is.na(rr) || !is.numeric(rr) || rr <= 0) {
    valid <- FALSE
    messages <- c(messages, "ERROR: Risk ratio must be a positive number.")
  }

  # Warn if RR is close to null
  if (!is.na(rr) && abs(rr - 1) < 0.01) {
    messages <- c(messages, "WARNING: Risk ratio is very close to null (1.0). E-value will be minimal.")
  }

  # Check CI consistency
  if (!is.na(lo) && !is.na(hi)) {
    if (lo > rr || hi < rr) {
      messages <- c(messages, "WARNING: Confidence interval does not contain the point estimate.")
    }
    if (lo >= hi) {
      valid <- FALSE
      messages <- c(messages, "ERROR: Lower confidence limit must be less than upper limit.")
    }
  }

  list(
    valid = valid,
    messages = messages
  )
}
