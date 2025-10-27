#' Export Utility Functions
#'
#' Helper functions for managing export operations across all analysis modules.
#' These utilities handle input extraction, filename generation, and common
#' export operations.
#'
#' @name utils_export
NULL

#' Extract Analysis Inputs for Export
#'
#' Centralizes input extraction logic for all analysis types. Extracts values
#' from Shiny input objects and module reactive values, returning a standardized
#' structure suitable for passing to export builder functions.
#'
#' @param analysis_type String identifier for the analysis module
#' @param input Shiny input object
#' @param reactive_vals Named list of reactive value objects from modules
#'   Expected keys: tab1_vals, tab8_vals, tab9_vals, tab10_vals
#'
#' @return List or nested list containing module inputs ready for export builders
#'
#' @details
#' Different modules store inputs differently:
#' - Standard modules (single, two-group, etc.): Use tab*_vals$inputs()
#' - Direct input modules: Extract directly from Shiny input object
#' - Complex modules (mediation, multi-bias): Use nested reactive structures
#'
#' @export
extract_analysis_inputs <- function(analysis_type, input, reactive_vals) {
  switch(analysis_type,
    # Single proportion analyses - use module reactive values
    "power_single" = reactive_vals$tab1_vals$inputs(),
    "ss_single" = reactive_vals$tab1_vals$inputs(),

    # Two-group, survival, continuous, matched, non-inferiority
    # These use direct Shiny input values, so return NULL
    # (builder functions will access input directly)
    "power_twogrp" = NULL,
    "ss_twogrp" = NULL,
    "power_survival" = NULL,
    "ss_survival" = NULL,
    "match_casecontrol" = NULL,
    "power_continuous" = NULL,
    "ss_continuous" = NULL,
    "noninf" = NULL,

    # Time-to-event equivalence/non-inferiority - use module reactive values
    "survival_ni_equiv" = reactive_vals$tab9_vals$inputs(),

    # Mediation analysis - use module reactive values
    "mediation_analysis" = reactive_vals$tab8_vals$inputs(),

    # Multi-bias sensitivity - use entire reactive state
    "sensitivity_multi_bias" = reactive_vals$tab10_vals(),

    # Default
    NULL
  )
}

#' Generate Export Filename
#'
#' Creates standardized filenames for CSV and PDF exports based on analysis type
#' and current date.
#'
#' @param analysis_type String identifier for the analysis module
#' @param format Export format: "csv" or "pdf"
#'
#' @return Character string with filename (e.g., "Power-Analysis-Power (Single)-2025-10-27.csv")
#'
#' @export
generate_export_filename <- function(analysis_type, format = c("csv", "pdf")) {
  format <- match.arg(format)

  # Get display name for the analysis type
  display_name <- get_page_display_name(analysis_type)

  # Build filename
  ext <- switch(format,
    csv = ".csv",
    pdf = ".pdf"
  )

  paste0("Power-Analysis-", display_name, "-", Sys.Date(), ext)
}

#' Get Page Display Name
#'
#' Converts internal page identifiers to human-readable display names for
#' filenames, titles, and UI display.
#'
#' @param page String identifier for the page/module
#'
#' @return Character string with display name
#'
#' @details
#' This function was previously defined inline in app_server.R. It has been
#' extracted to utils_export.R for reusability across export functions.
#'
#' @export
get_page_display_name <- function(page) {
  switch(page,
    "power_single" = "Power (Single)",
    "ss_single" = "Sample Size (Single)",
    "power_twogrp" = "Power (Two-Group)",
    "ss_twogrp" = "Sample Size (Two-Group)",
    "power_survival" = "Power (Survival)",
    "ss_survival" = "Sample Size (Survival)",
    "match_casecontrol" = "Matched Case-Control",
    "power_continuous" = "Power (Continuous)",
    "ss_continuous" = "Sample Size (Continuous)",
    "noninf" = "Non-Inferiority",
    "survival_ni_equiv" = "Time-to-Event NI-Equiv",
    "mediation_analysis" = "Mediation Analysis",
    "sensitivity_multi_bias" = "Multi-Bias Sensitivity",
    "vif_calculator" = "VIF Calculator",
    "Unknown"
  )
}

#' Check if Analysis Type Supports PDF Export
#'
#' Determines whether a given analysis type has PDF export functionality
#' implemented.
#'
#' @param analysis_type String identifier for the analysis module
#'
#' @return Logical indicating if PDF export is supported
#'
#' @details
#' Currently only "power_single" and "ss_single" have PDF export templates.
#' This function can be used to conditionally show/hide PDF export buttons
#' or display appropriate notifications.
#'
#' @export
supports_pdf_export <- function(analysis_type) {
  analysis_type %in% c("power_single", "ss_single")
}

#' Get Missing Export Modules
#'
#' Returns a list of modules that are missing CSV or PDF export functionality.
#' Useful for tracking implementation progress.
#'
#' @param export_type Either "csv" or "pdf"
#'
#' @return Character vector of module identifiers missing the specified export
#'
#' @export
get_missing_exports <- function(export_type = c("csv", "pdf")) {
  export_type <- match.arg(export_type)

  all_modules <- c(
    "power_single", "ss_single",
    "power_twogrp", "ss_twogrp",
    "power_survival", "ss_survival",
    "match_casecontrol",
    "power_continuous", "ss_continuous",
    "noninf",
    "survival_ni_equiv",
    "mediation_analysis",
    "sensitivity_multi_bias",
    "vif_calculator"
  )

  if (export_type == "csv") {
    # All modules have CSV export as of 2025-10-27
    return(character(0))
  } else {
    # PDF export only available for single proportion
    return(setdiff(all_modules, c("power_single", "ss_single")))
  }
}

#' Prepare Module Reactive Values for Export
#'
#' Helper function to gather all reactive value objects needed for export
#' operations. This simplifies the call to extract_analysis_inputs().
#'
#' @param tab1_vals Reactive values from single proportion module
#' @param tab8_vals Reactive values from mediation module
#' @param tab9_vals Reactive values from time-to-event NI/equiv module
#' @param tab10_vals Reactive values from multi-bias sensitivity module
#'
#' @return Named list of reactive value objects
#'
#' @export
prepare_reactive_vals <- function(tab1_vals = NULL,
                                   tab8_vals = NULL,
                                   tab9_vals = NULL,
                                   tab10_vals = NULL) {
  list(
    tab1_vals = tab1_vals,
    tab8_vals = tab8_vals,
    tab9_vals = tab9_vals,
    tab10_vals = tab10_vals
  )
}
