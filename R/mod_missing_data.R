# Missing Data Adjustment Module
#
# A reusable Shiny module for missing data adjustment UI and reactive values.
# This module replaces 6 identical 35-40 line blocks across the application,
# following DRY (Don't Repeat Yourself) and SOLID principles.
#
# Usage:
#   UI:   missing_data_ui(NS(id, "missing_data"))
#   Server: missing_data_values <- missing_data_server(id, "missing_data")
#
# Returns: Reactive list with missing data parameters

# UI Function ----
missing_data_ui <- function(id) {
  ns <- NS(id)

  tagList(
    checkboxInput(
      ns("adjust_missing"),
      "Adjust for Missing Data",
      value = FALSE
    ),
    conditionalPanel(
      condition = sprintf("input['%s']", ns("adjust_missing")),

      # Missing percentage slider
      create_enhanced_slider(
        ns("missing_pct"),
        "Expected Missingness (%):",
        min = 5,
        max = 50,
        value = 20,
        step = 5,
        post = "%",
        tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"
      ),

      # Missing mechanism selection
      radioButtons_fixed(
        ns("missing_mechanism"),
        "Missing Data Mechanism:",
        choices = c(
          "MCAR (Missing Completely At Random)" = "mcar",
          "MAR (Missing At Random)" = "mar",
          "MNAR (Missing Not At Random)" = "mnar"
        ),
        selected = "mar"
      ),
      bsTooltip(
        ns("missing_mechanism"),
        "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
        "right"
      ),

      # Analysis approach selection
      radioButtons_fixed(
        ns("missing_analysis"),
        "Planned Analysis Approach:",
        choices = c(
          "Complete Case Analysis" = "complete_case",
          "Multiple Imputation (MI)" = "multiple_imputation"
        ),
        selected = "complete_case"
      ),
      bsTooltip(
        ns("missing_analysis"),
        "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
        "right"
      ),

      # Multiple imputation parameters (conditional)
      conditionalPanel(
        condition = sprintf("input['%s'] == 'multiple_imputation'", ns("missing_analysis")),

        numericInput(
          ns("mi_imputations"),
          "Number of Imputations (m):",
          5,
          min = 3,
          max = 100,
          step = 1
        ),
        bsTooltip(
          ns("mi_imputations"),
          "Typical values: 5-20. More imputations increase precision but require more computation",
          "right"
        ),

        create_enhanced_slider(
          ns("mi_r_squared"),
          "Expected Imputation Model R²:",
          min = 0.1,
          max = 0.9,
          value = 0.5,
          step = 0.1,
          tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed"
        )
      )
    )
  )
}

# Server Function ----
missing_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Return reactive list of all missing data parameters
    # This allows the parent app to access these values reactively
    return(
      reactive({
        list(
          adjust_missing = input$adjust_missing,
          missing_pct = input$missing_pct,
          missing_mechanism = input$missing_mechanism,
          missing_analysis = input$missing_analysis,
          mi_imputations = input$mi_imputations,
          mi_r_squared = input$mi_r_squared
        )
      })
    )
  })
}

# Helper function to calculate missing data inflation
# (This consolidates repeated calculation logic from server)
#
# @param n_calculated Base sample size from power/effect calculation
# @param missing_params Reactive list from missing_data_server()
# @param calc_missing_data_inflation Function reference from parent app
#
# @return List with n_inflated and interpretation HTML
calculate_missing_inflation <- function(n_calculated, missing_params, calc_missing_data_inflation) {

  params <- missing_params()

  if (!params$adjust_missing || is.null(params$adjust_missing)) {
    return(list(
      n_inflated = n_calculated,
      interpretation = HTML("")
    ))
  }

  # Calculate inflation using existing helper function
  missing_adj <- calc_missing_data_inflation(
    n = n_calculated,
    missing_pct = params$missing_pct,
    mechanism = params$missing_mechanism,
    analysis_approach = params$missing_analysis,
    m_imputations = ifelse(
      params$missing_analysis == "multiple_imputation",
      params$mi_imputations,
      5
    ),
    r_squared = ifelse(
      params$missing_analysis == "multiple_imputation",
      params$mi_r_squared,
      0.5
    )
  )

  return(missing_adj)
}
