#' 08_mediation UI Function
#'
#' @description Mediation Analysis power and sample size calculations
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 h4 helpText hr div actionButton icon radioButtons
mod_08_mediation_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # Mediation Analysis - Power/Sample Size
    conditionalPanel(
      condition = "input.sidebar_page == 'mediation_analysis'",
      h2(class = "page-title", "Mediation Analysis: Power & Sample Size"),
      helpText("Calculate power or sample size for testing indirect effects in mediation models (X → M → Y)"),
      hr(),

      # Calculation Mode Selector
      bslib::tooltip(
        radioButtons_fixed(
          ns("calc_mode"),
          "Calculation Mode:",
          choices = c(
            "Calculate Power (given sample size)" = "calc_power",
            "Calculate Sample Size (given power)" = "calc_n",
            "Calculate Minimal Detectable Effect (given N and power)" = "calc_mde"
          ),
          selected = "calc_power"
        ),
        "Choose what to calculate: power, required sample size, or minimal detectable indirect effect",
        placement = "right"
      ),

      hr(),

      # Sample size input (for power and MDE calculations)
      conditionalPanel(
        condition = paste0("input['", ns("calc_mode"), "'] == 'calc_power' || input['", ns("calc_mode"), "'] == 'calc_mde'"),
        create_numeric_input_with_tooltip(
          ns("med_n"),
          "Sample Size (N):",
          value = 200,
          min = 10,
          step = 10,
          tooltip = "Total sample size for the study"
        )
      ),

      # Power input (for sample size and MDE calculations)
      conditionalPanel(
        condition = paste0("input['", ns("calc_mode"), "'] == 'calc_n' || input['", ns("calc_mode"), "'] == 'calc_mde'"),
        create_segmented_power(
          ns("med_power"),
          "Desired Power:",
          selected = 80,
          tooltip = "Probability of detecting the indirect effect if it exists (typically 80%)"
        )
      ),

      # Path Coefficients
      h4("Path Coefficients (Standardized)"),
      helpText("Enter expected standardized path coefficients for the mediation model"),

      create_numeric_input_with_tooltip(
        ns("path_a"),
        "Path a (X → M):",
        value = 0.3,
        min = -2,
        max = 2,
        step = 0.05,
        tooltip = "Effect of independent variable (X) on mediator (M). Cohen's d: Small=0.2, Medium=0.5, Large=0.8"
      ),

      # Path b input (not shown for MDE mode - this is what we're solving for)
      conditionalPanel(
        condition = paste0("input['", ns("calc_mode"), "'] != 'calc_mde'"),
        create_numeric_input_with_tooltip(
          ns("path_b"),
          "Path b (M → Y|X):",
          value = 0.3,
          min = -2,
          max = 2,
          step = 0.05,
          tooltip = "Effect of mediator (M) on outcome (Y), controlling for X. Cohen's d: Small=0.2, Medium=0.5, Large=0.8"
        )
      ),

      create_numeric_input_with_tooltip(
        ns("path_c_prime"),
        "Path c' (X → Y|M, direct effect) [Optional]:",
        value = 0.1,
        min = -2,
        max = 2,
        step = 0.05,
        tooltip = "Direct effect of X on Y controlling for M. Used for comparison only, not required for power calculation"
      ),

      # Advanced Options (collapsed by default)
      hr(),
      tags$details(
        tags$summary(
          class = "advanced-options-header",
          icon("cog"),
          " Advanced Options"
        ),
        tags$div(
          class = "advanced-options-content",
          helpText("Specify standard errors if known (otherwise estimated from sample size)"),

          create_numeric_input_with_tooltip(
            ns("se_a"),
            "Standard Error of Path a [Optional]:",
            value = NA,
            min = 0.001,
            max = 1,
            step = 0.01,
            tooltip = "If known, enter SE for path a. Otherwise, estimated as 1/√N"
          ),

          create_numeric_input_with_tooltip(
            ns("se_b"),
            "Standard Error of Path b [Optional]:",
            value = NA,
            min = 0.001,
            max = 1,
            step = 0.01,
            tooltip = "If known, enter SE for path b. Otherwise, estimated as 1/√N"
          )
        )
      ),

      hr(),

      # Statistical Parameters
      create_segmented_alpha(
        ns("med_alpha"),
        "Significance Level (α):",
        selected = 0.05,
        tooltip = "Type I error rate (typically 0.05 for two-sided tests)"
      ),

      bslib::tooltip(
        radioButtons_fixed(
          ns("med_sided"),
          "Test Type:",
          choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
          selected = "two.sided"
        ),
        "Two-sided: test if indirect effect ≠ 0. One-sided: test if indirect effect > 0",
        placement = "right"
      ),

      hr(),

      # Example and Reset Buttons
      div(class = "btn-group-custom",
        actionButton(ns("example_med"), "Load Example",
                     icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_med"), "Reset",
                     icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 08_mediation Server Functions
#'
#' @noRd
mod_08_mediation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Example button
    observeEvent(input$example_med, {
      # Example: Drug → Adherence → Clinical Outcome
      updateRadioButtons(session, "calc_mode", selected = "calc_n")
      updateRadioButtons(session, "med_power", selected = "80")
      updateNumericInput(session, "path_a", value = 0.39)
      updateNumericInput(session, "path_b", value = 0.39)
      updateNumericInput(session, "path_c_prime", value = 0.07)
      updateRadioButtons(session, "med_alpha", selected = "0.05")
      updateRadioButtons(session, "med_sided", selected = "two.sided")

      # Show notification with context
      showNotification(
        "Example loaded: Mediation analysis for Drug → Adherence → Clinical Outcome.
        Path coefficients from Preacher & Hayes (2008) example.",
        type = "message",
        duration = 5
      )
    })

    # Reset button
    observeEvent(input$reset_med, {
      updateRadioButtons(session, "calc_mode", selected = "calc_power")
      updateNumericInput(session, "med_n", value = 200)
      updateRadioButtons(session, "med_power", selected = "80")
      updateNumericInput(session, "path_a", value = 0.3)
      updateNumericInput(session, "path_b", value = 0.3)
      updateNumericInput(session, "path_c_prime", value = 0.1)
      updateNumericInput(session, "se_a", value = NA)
      updateNumericInput(session, "se_b", value = NA)
      updateRadioButtons(session, "med_alpha", selected = "0.05")
      updateRadioButtons(session, "med_sided", selected = "two.sided")
    })

    # Return reactive values
    list(
      inputs = reactive({
        list(
          calc_mode = input$calc_mode,
          med_n = as.numeric(input$med_n),
          med_power = as.numeric(input$med_power),
          path_a = as.numeric(input$path_a),
          path_b = as.numeric(input$path_b),
          path_c_prime = as.numeric(input$path_c_prime),
          se_a = as.numeric(input$se_a),
          se_b = as.numeric(input$se_b),
          med_alpha = as.numeric(input$med_alpha),
          med_sided = input$med_sided
        )
      })
    )
  })
}
