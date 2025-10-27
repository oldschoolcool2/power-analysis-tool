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

    # Log module initialization
    log_module_event("mediation", "init", session)

    # Example button
    observeEvent(input$example_med, {
      logger::log_info(
        "Loading example data for mediation analysis",
        module = "mediation",
        action = "load_example",
        session_id = session$token
      )
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
      logger::log_info(
        "Resetting mediation analysis inputs",
        module = "mediation",
        action = "reset",
        session_id = session$token
      )
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

    # Register cleanup handler
    onStop(function() {
      log_module_event("mediation", "cleanup", session)
    })

    # Define allowlists for categorical inputs (security best practice)
    VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
    VALID_POWER <- c("70", "80", "90", "95")
    VALID_SIDED <- c("two.sided", "one.sided")
    VALID_CALC_MODES <- c("calc_power", "calc_n", "calc_mde")

    # Raw reactive inputs (not debounced)
    inputs_raw <- reactive({
      # Use req() to prevent execution until inputs are available
      req(input$calc_mode)
      req(input$path_a)
      req(input$med_alpha)
      req(input$med_sided)

      # Log reactive execution at TRACE level (only when debugging)
      log_reactive_execution("mediation_inputs", session)

      # Validate and sanitize inputs
      tryCatch({
        result <- list(
          calc_mode = validate_choice_input(
            input$calc_mode,
            VALID_CALC_MODES,
            "Calculation mode"
          ),
          path_a = validate_numeric_input(
            input$path_a,
            "Path a coefficient",
            min = -2,
            max = 2
          ),
          path_c_prime = validate_numeric_input(
            input$path_c_prime %||% 0,
            "Direct effect",
            min = -2,
            max = 2,
            allow_null = TRUE
          ),
          med_alpha = as.numeric(validate_choice_input(
            input$med_alpha,
            VALID_ALPHA,
            "Significance level"
          )),
          med_sided = validate_choice_input(
            input$med_sided,
            VALID_SIDED,
            "Test type"
          )
        )

        # Add mode-specific parameters
        if (result$calc_mode == "calc_power") {
          req(input$med_n)
          req(input$path_b)
          result$med_n <- validate_numeric_input(
            input$med_n,
            "Sample size",
            min = 10,
            max = 1e7
          )
          result$path_b <- validate_numeric_input(
            input$path_b,
            "Path b coefficient",
            min = -2,
            max = 2
          )
        } else if (result$calc_mode == "calc_n") {
          req(input$med_power)
          req(input$path_b)
          result$med_power <- as.numeric(validate_choice_input(
            input$med_power,
            VALID_POWER,
            "Power level"
          ))
          result$path_b <- validate_numeric_input(
            input$path_b,
            "Path b coefficient",
            min = -2,
            max = 2
          )
        } else if (result$calc_mode == "calc_mde") {
          req(input$med_n)
          req(input$med_power)
          result$med_n <- validate_numeric_input(
            input$med_n,
            "Sample size",
            min = 10,
            max = 1e7
          )
          result$med_power <- as.numeric(validate_choice_input(
            input$med_power,
            VALID_POWER,
            "Power level"
          ))
          # path_b is not needed for calc_mde - it's what we're solving for
        }

        # Optional parameters (SE)
        result$se_a <- if (!is.null(input$se_a) && !is.na(input$se_a)) {
          validate_numeric_input(input$se_a, "SE of path a", min = 0.001, max = 1, allow_null = TRUE)
        } else {
          NA_real_
        }

        result$se_b <- if (!is.null(input$se_b) && !is.na(input$se_b)) {
          validate_numeric_input(input$se_b, "SE of path b", min = 0.001, max = 1, allow_null = TRUE)
        } else {
          NA_real_
        }

        result

      }, error = function(e) {
        # If validation fails, log the error (in production) and return defaults
        if (golem::app_prod()) {
          logger::log_warn(
            "Input validation failed in mediation module",
            error = conditionMessage(e)
          )
        }

        # Return safe defaults
        list(
          calc_mode = "calc_power",
          med_n = 200,
          med_power = 80,
          path_a = 0.3,
          path_b = 0.3,
          path_c_prime = 0.1,
          se_a = NA_real_,
          se_b = NA_real_,
          med_alpha = 0.05,
          med_sided = "two.sided"
        )
      })
    })

    # Apply debouncing to reduce reactive churn
    inputs <- inputs_raw %>% debounce(500)

    # Return reactive values
    list(
      inputs = inputs  # Return debounced version
    )
  })
}
