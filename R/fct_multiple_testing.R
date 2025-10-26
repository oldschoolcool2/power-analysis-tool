#' Multiple Testing Correction Calculations
#'
#' Business logic for calculating adjusted alpha levels and sample size inflation
#' due to multiple testing corrections. These functions help researchers properly
#' account for multiple comparisons to control family-wise error rate (FWER) or
#' false discovery rate (FDR).
#'
#' @details
#' Multiple testing corrections are essential when conducting multiple statistical
#' tests to avoid inflated Type I error rates. Different correction methods offer
#' varying levels of conservatism and power.
#'
#' Common correction methods:
#'   - Bonferroni: Most conservative, controls FWER
#'   - Holm: Less conservative than Bonferroni, controls FWER
#'   - Hochberg: Similar to Holm but slightly less conservative
#'   - Benjamini-Hochberg (BH): Controls FDR, less conservative, more power
#'   - Benjamini-Yekutieli (BY): Controls FDR under dependency
#'
#' FWER (Family-Wise Error Rate): Probability of making ≥1 Type I errors
#' FDR (False Discovery Rate): Expected proportion of false positives among rejections
#'
#' @references
#' Bonferroni, C.E. (1936). Teoria statistica delle classi e calcolo delle
#' probabilita. Pubblicazioni del R Istituto Superiore di Scienze Economiche
#' e Commerciali di Firenze, 8, 3-62.
#'
#' Holm, S. (1979). A simple sequentially rejective multiple test procedure.
#' Scandinavian Journal of Statistics, 6(2), 65-70.
#'
#' Hochberg, Y. (1988). A sharper Bonferroni procedure for multiple tests of
#' significance. Biometrika, 75(4), 800-802.
#'
#' Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate:
#' a practical and powerful approach to multiple testing. Journal of the Royal
#' Statistical Society: Series B, 57(1), 289-300.
#'
#' Benjamini, Y., & Yekutieli, D. (2001). The control of the false discovery
#' rate in multiple testing under dependency. Annals of Statistics, 29(4), 1165-1188.


#' Calculate Adjusted Alpha Level for Multiple Testing
#'
#' @param alpha Original alpha level (typically 0.05)
#' @param n_tests Number of statistical tests to be conducted
#' @param method Correction method: "bonferroni", "holm", "hochberg", "BH", "BY", "none"
#'
#' @return List with adjusted alpha and interpretation details
#'
#' @examples
#' # Bonferroni correction for 5 tests at alpha = 0.05
#' result <- calc_adjusted_alpha(0.05, 5, "bonferroni")
#' # Adjusted alpha = 0.01
#'
#' @noRd
calc_adjusted_alpha <- function(alpha = 0.05, n_tests = 1, method = "bonferroni") {

  # Input validation
  if (!is.numeric(alpha) || alpha <= 0 || alpha >= 1) {
    stop("Alpha must be between 0 and 1")
  }

  if (!is.numeric(n_tests) || n_tests < 1) {
    stop("Number of tests must be at least 1")
  }

  n_tests <- as.integer(n_tests)

  # Calculate adjusted alpha based on method
  alpha_adj <- switch(tolower(method),
    "bonferroni" = alpha / n_tests,
    "holm" = alpha / n_tests,  # For sample size, use most conservative (first test)
    "hochberg" = alpha / n_tests,  # Similar to Holm for planning
    "bh" = alpha,  # BH doesn't adjust alpha directly; controls FDR instead
    "fdr" = alpha,  # Alias for BH
    "by" = alpha,  # BY also controls FDR
    "none" = alpha,
    alpha / n_tests  # Default to Bonferroni
  )

  # Calculate sample size inflation factor
  # For power to remain constant, we need to use the adjusted alpha
  # This generally requires more participants (except for FDR methods)
  inflation_factor <- if (tolower(method) %in% c("bh", "fdr", "by", "none")) {
    1.0  # FDR methods and no correction don't inflate sample size much
  } else {
    # For FWER methods, inflation depends on method conservatism
    sqrt(n_tests)  # Approximation for power-based inflation
  }

  # Get method details
  method_info <- get_correction_method_info(method)

  # Interpretation
  interpretation <- interpret_multiple_testing(
    alpha_original = alpha,
    alpha_adjusted = alpha_adj,
    n_tests = n_tests,
    method = method,
    method_info = method_info
  )

  list(
    alpha_original = alpha,
    alpha_adjusted = alpha_adj,
    n_tests = n_tests,
    method = method,
    method_name = method_info$name,
    controls = method_info$controls,
    inflation_factor = inflation_factor,
    interpretation = interpretation
  )
}


#' Get Multiple Testing Correction Method Information
#'
#' @param method Correction method name
#'
#' @return List with method details
#'
#' @noRd
get_correction_method_info <- function(method) {

  method_lower <- tolower(method)

  info <- switch(method_lower,
    "bonferroni" = list(
      name = "Bonferroni",
      full_name = "Bonferroni Correction",
      controls = "FWER",
      conservatism = "Very Conservative",
      description = "Divides alpha by the number of tests. Most conservative method.",
      power_impact = "High (substantial power loss with many tests)",
      when_to_use = "When you need strong control of Type I error and tests are independent"
    ),
    "holm" = list(
      name = "Holm",
      full_name = "Holm-Bonferroni Sequential Procedure",
      controls = "FWER",
      conservatism = "Conservative",
      description = "Sequential method that is uniformly more powerful than Bonferroni.",
      power_impact = "Moderate to High (less than Bonferroni)",
      when_to_use = "Preferred over Bonferroni; more power while controlling FWER"
    ),
    "hochberg" = list(
      name = "Hochberg",
      full_name = "Hochberg Step-Up Procedure",
      controls = "FWER",
      conservatism = "Conservative",
      description = "Step-up method, slightly less conservative than Holm under certain conditions.",
      power_impact = "Moderate",
      when_to_use = "When tests are positively correlated"
    ),
    "bh" = ,
    "fdr" = list(
      name = "Benjamini-Hochberg",
      full_name = "Benjamini-Hochberg FDR Control",
      controls = "FDR",
      conservatism = "Liberal (more power)",
      description = "Controls False Discovery Rate instead of FWER. Allows some false positives.",
      power_impact = "Low (maintains good power)",
      when_to_use = "Exploratory studies, when some false positives are acceptable"
    ),
    "by" = list(
      name = "Benjamini-Yekutieli",
      full_name = "Benjamini-Yekutieli FDR Control",
      controls = "FDR",
      conservatism = "Moderate",
      description = "Controls FDR even when tests are dependent/correlated.",
      power_impact = "Moderate",
      when_to_use = "When tests are dependent and you want FDR control"
    ),
    "none" = list(
      name = "None",
      full_name = "No Correction",
      controls = "None",
      conservatism = "Not Conservative",
      description = "No adjustment for multiple testing. Not recommended for multiple tests.",
      power_impact = "None (original power maintained)",
      when_to_use = "Only when conducting a single primary test"
    ),
    # Default to Bonferroni info
    list(
      name = "Bonferroni",
      full_name = "Bonferroni Correction",
      controls = "FWER",
      conservatism = "Very Conservative",
      description = "Divides alpha by the number of tests.",
      power_impact = "High",
      when_to_use = "Strong Type I error control needed"
    )
  )

  info
}


#' Interpret Multiple Testing Adjustment Results
#'
#' @param alpha_original Original alpha level
#' @param alpha_adjusted Adjusted alpha level
#' @param n_tests Number of tests
#' @param method Correction method
#' @param method_info Method information from get_correction_method_info()
#'
#' @return List with interpretation components
#'
#' @noRd
interpret_multiple_testing <- function(alpha_original, alpha_adjusted, n_tests,
                                       method, method_info) {

  # Determine severity of correction
  alpha_ratio <- alpha_original / alpha_adjusted

  if (alpha_ratio < 1.5 || tolower(method) %in% c("none", "bh", "fdr", "by")) {
    severity <- "minimal"
    color <- "#28a745"  # green
    icon <- "ℹ️"
  } else if (alpha_ratio < 3) {
    severity <- "moderate"
    color <- "#ffc107"  # yellow
    icon <- "⚠️"
  } else if (alpha_ratio < 10) {
    severity <- "substantial"
    color <- "#fd7e14"  # orange
    icon <- "⚠️⚠️"
  } else {
    severity <- "severe"
    color <- "#dc3545"  # red
    icon <- "⚠️⚠️⚠️"
  }

  # Build main interpretation text
  if (n_tests == 1 || tolower(method) == "none") {
    main_text <- sprintf(
      "No adjustment needed for %d test. Using original α = %.4f.",
      n_tests, alpha_original
    )
  } else {
    main_text <- sprintf(
      "Using <strong>%s correction</strong> for %d tests: adjusted α = <strong>%.4f</strong> (original α = %.4f). This is a %.1f-fold reduction in alpha.",
      method_info$name, n_tests, alpha_adjusted, alpha_original, alpha_ratio
    )
  }

  # Power impact warning
  power_warning <- if (severity %in% c("substantial", "severe") &&
                       !tolower(method) %in% c("bh", "fdr", "by", "none")) {
    paste0(
      "<br><br><strong style='color: ", color, ";'>⚠️ Power Impact:</strong> ",
      "With ", n_tests, " tests and ", method_info$name, " correction, ",
      "you may need substantially larger sample sizes to maintain adequate power. ",
      "Consider using Benjamini-Hochberg (FDR) correction if some false positives are acceptable."
    )
  } else {
    ""
  }

  # Method guidance
  method_guidance <- sprintf(
    "<br><br><strong>Method Details:</strong> %s controls <strong>%s</strong>. %s",
    method_info$name, method_info$controls, method_info$description
  )

  list(
    severity = severity,
    color = color,
    icon = icon,
    main_text = main_text,
    power_warning = power_warning,
    method_guidance = method_guidance,
    method_info = method_info
  )
}


#' Calculate Required Sample Size with Multiple Testing Correction
#'
#' This function adjusts the sample size calculation to account for multiple testing.
#' When using adjusted alpha levels, more participants are typically needed to
#' maintain the same power.
#'
#' @param n_base Base sample size (calculated for single test)
#' @param alpha_original Original alpha level
#' @param alpha_adjusted Adjusted alpha level from multiple testing correction
#' @param power Target power (default 0.80)
#'
#' @return List with adjusted sample size and details
#'
#' @details
#' The relationship between sample size and alpha for a fixed power is approximately:
#'   n_adjusted / n_base ≈ (z_alpha/2,adjusted / z_alpha/2,original)^2
#'
#' This is an approximation that works well for two-sided tests.
#'
#' @noRd
calc_n_multiple_testing <- function(n_base, alpha_original, alpha_adjusted, power = 0.80) {

  # Calculate z-scores for original and adjusted alpha
  z_original <- qnorm(1 - alpha_original / 2)
  z_adjusted <- qnorm(1 - alpha_adjusted / 2)

  # Sample size inflation factor
  # Based on: n ~ (z_alpha/2 + z_beta)^2
  # For fixed power (fixed z_beta), n_adj/n_orig = (z_adj/z_orig)^2
  inflation_factor <- (z_adjusted / z_original)^2

  # Adjusted sample size
  n_adjusted <- ceiling(n_base * inflation_factor)
  n_increase <- n_adjusted - n_base
  pct_increase <- round((inflation_factor - 1) * 100, 1)

  # Build interpretation
  interpretation <- if (inflation_factor > 1.1) {
    sprintf(
      "To maintain %.0f%% power with adjusted α = %.4f (vs. original α = %.4f), ",
      power * 100, alpha_adjusted, alpha_original
    ) %>%
    paste0(
      sprintf("sample size increases by <strong>%.1f%%</strong> ", pct_increase),
      sprintf("(add %d participants). ", n_increase),
      sprintf("Required N = <strong>%d</strong> (vs. base N = %d).", n_adjusted, n_base)
    )
  } else {
    sprintf(
      "Minimal sample size adjustment needed. Required N = %d (base N = %d).",
      n_adjusted, n_base
    )
  }

  list(
    n_base = n_base,
    n_adjusted = n_adjusted,
    n_increase = n_increase,
    pct_increase = pct_increase,
    inflation_factor = round(inflation_factor, 3),
    alpha_original = alpha_original,
    alpha_adjusted = alpha_adjusted,
    power = power,
    interpretation = interpretation
  )
}


#' Validate Multiple Testing Inputs
#'
#' @param n_tests Number of tests
#' @param alpha Alpha level
#' @param method Correction method
#'
#' @return List with 'valid' (logical) and 'messages' (character vector)
#'
#' @noRd
validate_multiple_testing_inputs <- function(n_tests, alpha, method) {
  valid <- TRUE
  messages <- character(0)

  # Validate number of tests
  if (is.na(n_tests) || !is.numeric(n_tests) || n_tests < 1) {
    valid <- FALSE
    messages <- c(messages, "ERROR: Number of tests must be at least 1.")
  } else if (n_tests > 100) {
    messages <- c(messages,
      paste0("WARNING: Planning ", n_tests, " tests is unusual. ",
             "Consider whether all tests are truly needed. ",
             "With this many tests, Benjamini-Hochberg (FDR) correction is recommended."))
  } else if (n_tests > 20) {
    messages <- c(messages,
      paste0("NOTE: With ", n_tests, " tests, consider FDR-controlling methods ",
             "(Benjamini-Hochberg) instead of FWER methods for better power."))
  }

  # Validate alpha
  if (is.na(alpha) || !is.numeric(alpha) || alpha <= 0 || alpha >= 1) {
    valid <- FALSE
    messages <- c(messages, "ERROR: Alpha must be between 0 and 1.")
  }

  # Validate method
  valid_methods <- c("bonferroni", "holm", "hochberg", "bh", "fdr", "by", "none")
  if (!tolower(method) %in% valid_methods) {
    valid <- FALSE
    messages <- c(messages,
      paste0("ERROR: Invalid correction method. Must be one of: ",
             paste(valid_methods, collapse = ", ")))
  }

  # Method-specific warnings
  if (n_tests > 10 && tolower(method) == "bonferroni") {
    messages <- c(messages,
      paste0("TIP: Bonferroni correction with ", n_tests,
             " tests is very conservative. Consider Holm or Benjamini-Hochberg for more power."))
  }

  if (n_tests == 1 && tolower(method) != "none") {
    messages <- c(messages,
      "NOTE: Only 1 test specified. Multiple testing correction is not needed. Set method to 'None'.")
  }

  list(
    valid = valid,
    messages = messages
  )
}


#' Format Multiple Testing Summary as HTML
#'
#' @param mt_result Result from calc_adjusted_alpha()
#'
#' @return HTML formatted string
#'
#' @noRd
format_multiple_testing_summary <- function(mt_result) {

  interp <- mt_result$interpretation

  # Build HTML output
  html_output <- paste0(
    "<div style='background-color: ", interp$color, "15; ",
    "border-left: 4px solid ", interp$color, "; ",
    "padding: 15px; margin: 15px 0;'>",
    "<h5 style='margin-top: 0; color: ", interp$color, ";'>",
    interp$icon, " Multiple Testing Correction</h5>",
    "<p>", interp$main_text, "</p>"
  )

  # Add alpha details
  html_output <- paste0(
    html_output,
    "<p><strong>Method:</strong> ", mt_result$method_name,
    " (controls ", mt_result$controls, ")<br>",
    "<strong>Number of tests:</strong> ", mt_result$n_tests, "<br>",
    "<strong>Adjusted α:</strong> ", format_numeric(mt_result$alpha_adjusted, 4), "<br>",
    "<strong>Original α:</strong> ", format_numeric(mt_result$alpha_original, 4),
    "</p>"
  )

  # Add warnings and guidance
  html_output <- paste0(
    html_output,
    interp$power_warning,
    interp$method_guidance,
    "</div>"
  )

  HTML(html_output)
}


#' Get Recommended Correction Method Based on Context
#'
#' @param n_tests Number of tests
#' @param study_type Type of study ("confirmatory", "exploratory")
#' @param tests_independent Logical, are tests independent?
#'
#' @return Character, recommended method name
#'
#' @noRd
get_recommended_correction <- function(n_tests = 1,
                                      study_type = "confirmatory",
                                      tests_independent = TRUE) {

  if (n_tests == 1) {
    return("none")
  }

  if (study_type == "exploratory" && n_tests > 5) {
    return("BH")  # Benjamini-Hochberg for exploratory with many tests
  }

  if (study_type == "confirmatory" && tests_independent) {
    if (n_tests <= 5) {
      return("holm")  # Holm is good balance for few tests
    } else {
      return("BH")  # Even for confirmatory, BH is reasonable with many tests
    }
  }

  if (!tests_independent) {
    return("BY")  # Benjamini-Yekutieli handles dependent tests
  }

  # Default
  "holm"
}
