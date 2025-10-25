#' Calculate Sample Size Inflation for Missing Data
#'
#' Business logic for calculating sample size inflation to account for missing data.
#' Supports complete case analysis and multiple imputation approaches.
#'
#' @param n_required Required sample size without missingness
#' @param missing_pct Percentage of expected missing data (0-100)
#' @param mechanism Missing data mechanism: "mcar", "mar", or "mnar"
#' @param analysis_type Analysis approach: "complete_case" or "multiple_imputation"
#' @param mi_imputations Number of imputations for MI (default 5)
#' @param mi_r_squared R-squared for MI recovery (default 0.5)
#'
#' @return List with inflation factor, inflated sample size, and interpretation
#'
#' @noRd
calc_missing_data_inflation <- function(n_required, missing_pct, mechanism = "mar", analysis_type = "complete_case", mi_imputations = 5, mi_r_squared = 0.5) {
  if (missing_pct == 0) {
    return(list(
      n_inflated = n_required,
      inflation_factor = 1.0,
      n_increase = 0,
      pct_increase = 0,
      interpretation = "No adjustment needed (0% missingness assumed)",
      mi_comparison = NULL,
      mi_recommendations = NULL
    ))
  }

  p_missing <- missing_pct / 100

  # Calculate inflation based on analysis type
  if (analysis_type == "complete_case") {
    # Complete case analysis: conservative inflation
    # N_inflated = N_required / (1 - p_missing)
    inflation_factor <- 1 / (1 - p_missing)
    n_inflated <- ceiling(n_required * inflation_factor)
    n_increase <- n_inflated - n_required
    pct_increase <- round((inflation_factor - 1) * 100, 1)

    # Interpretation text based on mechanism
    mechanism_text <- switch(mechanism,
      "mcar" = "MCAR (minimal bias expected)",
      "mar" = "MAR (bias controllable with observed covariates)",
      "mnar" = "MNAR (potential for substantial bias; sensitivity analysis recommended)",
      "MAR"  # default
    )

    interpretation <- sprintf(
      "Assuming %s%% missingness (%s) with complete-case analysis, inflate sample size by %s%% (add %s participants) to ensure adequate complete-case sample.",
      missing_pct, mechanism_text, pct_increase, n_increase
    )

    # No MI-specific output for CCA
    mi_comparison <- NULL
    mi_recommendations <- NULL

  } else if (analysis_type == "multiple_imputation") {
    # Multiple Imputation: Enhanced with proper formula and comparison output
    # Based on Rubin (1987) and van Buuren (2018)

    # Fraction of missing information (FMI or lambda)
    # FMI depends on both missingness rate and imputation model quality
    # Formula: λ = (1 + 1/m) × γ, where γ ≈ (1 - R²) × p_missing
    gamma <- (1 - mi_r_squared) * p_missing
    fmi <- (1 + 1/mi_imputations) * gamma

    # Relative efficiency of MI vs complete data (not vs complete case!)
    # RE = (1 + λ/m)^(-1) where λ is the fraction of missing information
    # This gives the variance inflation factor for MI estimates
    relative_efficiency <- 1 / (1 + fmi / mi_imputations)

    # Sample size inflation for MI approach
    # Start with CCA inflation, then adjust for MI efficiency gains
    cca_inflation <- 1 / (1 - p_missing)

    # MI recovers some information, so the inflation is less than CCA
    # The effective inflation is reduced by the square root of relative efficiency
    # This is based on the variance inflation framework
    mi_efficiency_factor <- 1 / sqrt(relative_efficiency)
    inflation_factor <- cca_inflation * sqrt(mi_efficiency_factor)

    # Calculate sample sizes
    n_inflated <- ceiling(n_required * inflation_factor)
    n_increase <- n_inflated - n_required
    pct_increase <- round((inflation_factor - 1) * 100, 1)

    # Also calculate what CCA would require for comparison
    n_cca <- ceiling(n_required * cca_inflation)
    efficiency_gain <- n_cca - n_inflated

    # Check if m is adequate (rule of thumb: m >= % missing)
    m_adequate <- mi_imputations >= ceiling(missing_pct)
    m_recommended <- max(ceiling(missing_pct), 10)  # At least 10, or %missing

    # Effective sample size after MI
    n_effective <- ceiling(n_inflated * (1 - p_missing) * relative_efficiency)

    mechanism_text <- switch(mechanism,
      "mcar" = "MCAR (minimal bias, MI highly efficient)",
      "mar" = "MAR (MI can provide unbiased estimates with good imputation model)",
      "mnar" = "MNAR (MI may reduce but not eliminate bias; sensitivity analysis required)",
      "MAR"  # default
    )

    interpretation <- sprintf(
      "Assuming %s%% missingness (%s) with multiple imputation (m=%s imputations, R²=%s), inflate sample size by %s%% (add %s participants). MI recovers information lost to missingness, requiring fewer participants than complete-case analysis.",
      missing_pct, mechanism_text, mi_imputations, mi_r_squared, pct_increase, n_increase
    )

    # MI-specific comparison output
    mi_comparison <- list(
      cca_n = n_cca,
      mi_n = n_inflated,
      efficiency_gain = efficiency_gain,
      cca_inflation = round(cca_inflation, 3),
      mi_inflation = round(inflation_factor, 3),
      relative_efficiency = round(relative_efficiency, 3),
      fmi = round(fmi, 3),
      n_effective = n_effective
    )

    # MI-specific recommendations
    mi_recommendations <- list(
      m_adequate = m_adequate,
      m_current = mi_imputations,
      m_recommended = m_recommended,
      r_squared_quality = if (mi_r_squared >= 0.7) "strong" else if (mi_r_squared >= 0.5) "moderate" else if (mi_r_squared >= 0.3) "weak" else "very weak"
    )
  }

  list(
    n_inflated = n_inflated,
    inflation_factor = round(inflation_factor, 3),
    n_increase = n_increase,
    pct_increase = pct_increase,
    interpretation = interpretation,
    mi_comparison = mi_comparison,
    mi_recommendations = mi_recommendations
  )
}
