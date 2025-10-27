#' 06_non_inferiority UI Function
#'
#' @description Non-Inferiority Testing sample size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr div actionButton icon radioButtons
mod_06_non_inferiority_ui <- function(id) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = "input.sidebar_page == 'noninf'",
      h2(class = "page-title", "Non-Inferiority Testing"),
      helpText("Calculate sample size OR minimal detectable non-inferiority margin"),
      hr(),
      bslib::tooltip(
        radioButtons_fixed(ns("noninf_calc_mode"), "Calculation Mode:",
          choices = c("Calculate Sample Size (given margin)" = "calc_n", "Calculate Margin (given sample size)" = "calc_effect"),
          selected = "calc_n"),
        "Choose whether to calculate required sample size or minimal detectable non-inferiority margin",
        placement = "right"
      ),
      hr(),
      create_segmented_power(ns("noninf_power"), "Desired Power:", selected = 80, tooltip = "Probability of demonstrating non-inferiority if true"),
      create_numeric_input_with_tooltip(ns("noninf_p1"), "Event Rate Test Group (%):", 10, min = 0, max = 100, step = 0.1, tooltip = "Expected event rate in test/generic group (as percentage)"),
      create_numeric_input_with_tooltip(ns("noninf_p2"), "Event Rate Reference Group (%):", 10, min = 0, max = 100, step = 0.1, tooltip = "Expected event rate in reference/branded group (as percentage)"),
      conditionalPanel(condition = paste0("input['", ns("noninf_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(ns("noninf_margin"), "Non-Inferiority Margin (%):", 5, min = 0.1, max = 50, step = 0.5, tooltip = "Maximum clinically acceptable difference (percentage points). Test is non-inferior if difference < margin.")),
      conditionalPanel(condition = paste0("input['", ns("noninf_calc_mode"), "'] == 'calc_effect'"),
        create_numeric_input_with_tooltip(ns("noninf_n1_fixed"), "Available Sample Size (Test Group):", 500, min = 10, step = 10, tooltip = "Fixed sample size available for test/generic group")),
      create_numeric_input_with_tooltip(ns("noninf_ratio"), "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1, tooltip = "Ratio of Reference to Test group size. 1 = equal groups"),
      create_segmented_alpha(ns("noninf_alpha"), "Significance Level (α):", choices = c("0.01" = 0.01, "0.025" = 0.025, "0.05" = 0.05, "0.10" = 0.10), selected = 0.025, tooltip = "Type I error rate (typically 0.025 for one-sided non-inferiority test)"),
      hr(),
      missing_data_ui(ns("missing_data")),
      hr(),
      h4("Clustering Adjustment"),
      clustering_ui(ns("clustering")),
      hr(),
      h4("Multiple Testing Corrections"),
      multiple_testing_ui(ns("multiple_testing")),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_noninf"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_noninf"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm"))
    )
  )
}

#' 06_non_inferiority Server Functions
#'
#' @noRd
mod_06_non_inferiority_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Log module initialization
    log_module_event("non_inferiority", "init", session)

    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    logger::log_debug(
      "Non-inferiority module sub-modules initialized",
      module = "non_inferiority",
      session_id = session$token
    )

    observeEvent(input$example_noninf, {
      logger::log_info(
        "Loading example data for non-inferiority",
        module = "non_inferiority",
        action = "load_example",
        session_id = session$token
      )
      updateRadioButtons(session, "noninf_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "noninf_power", selected = "80")
      updateNumericInput(session, "noninf_p1", value = 10)
      updateNumericInput(session, "noninf_p2", value = 10)
      updateNumericInput(session, "noninf_margin", value = 3)
      updateNumericInput(session, "noninf_ratio", value = 1)
      updateRadioButtons(session, "noninf_alpha", selected = "0.025")
    })

    observeEvent(input$reset_noninf, {
      logger::log_info(
        "Resetting non-inferiority inputs",
        module = "non_inferiority",
        action = "reset",
        session_id = session$token
      )
      updateRadioButtons(session, "noninf_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "noninf_power", selected = "80")
      updateNumericInput(session, "noninf_p1", value = 10)
      updateNumericInput(session, "noninf_p2", value = 10)
      updateNumericInput(session, "noninf_margin", value = 5)
      updateNumericInput(session, "noninf_n1_fixed", value = 500)
      updateNumericInput(session, "noninf_ratio", value = 1)
      updateRadioButtons(session, "noninf_alpha", selected = "0.025")
    })

    # Register cleanup handler
    onStop(function() {
      log_module_event("non_inferiority", "cleanup", session)
    })

    # Define allowlists for categorical inputs (security best practice)
    VALID_ALPHA <- c("0.01", "0.025", "0.05", "0.10")
    VALID_POWER <- c("70", "80", "90", "95")
    VALID_CALC_MODES <- c("calc_n", "calc_effect")

    # Raw reactive inputs (not debounced)
    inputs_raw <- reactive({
      # Use req() to prevent execution until inputs are available
      req(input$noninf_calc_mode)
      req(input$noninf_power)
      req(input$noninf_p1)
      req(input$noninf_p2)
      req(input$noninf_ratio)
      req(input$noninf_alpha)

      # Log reactive execution at TRACE level (only when debugging)
      log_reactive_execution("non_inferiority_inputs", session)

      # Validate and sanitize inputs
      tryCatch({
        result <- list(
          noninf_calc_mode = validate_choice_input(
            input$noninf_calc_mode,
            VALID_CALC_MODES,
            "Calculation mode"
          ),
          noninf_power = as.numeric(validate_choice_input(
            input$noninf_power,
            VALID_POWER,
            "Power level"
          )),
          noninf_p1 = validate_proportion_input(
            input$noninf_p1,
            "Event rate in test group"
          ),
          noninf_p2 = validate_proportion_input(
            input$noninf_p2,
            "Event rate in reference group"
          ),
          noninf_ratio = validate_numeric_input(
            input$noninf_ratio,
            "Allocation ratio",
            min = 0.1,
            max = 10
          ),
          noninf_alpha = as.numeric(validate_choice_input(
            input$noninf_alpha,
            VALID_ALPHA,
            "Significance level"
          ))
        )

        # Add mode-specific parameters
        if (result$noninf_calc_mode == "calc_n") {
          req(input$noninf_margin)
          result$noninf_margin <- validate_numeric_input(
            input$noninf_margin,
            "Non-inferiority margin",
            min = 0.1,
            max = 50
          )
        } else if (result$noninf_calc_mode == "calc_effect") {
          req(input$noninf_n1_fixed)
          result$noninf_n1_fixed <- validate_numeric_input(
            input$noninf_n1_fixed,
            "Fixed sample size",
            min = 10,
            max = 1e7
          )
        }

        result

      }, error = function(e) {
        # If validation fails, log the error (in production) and return defaults
        if (golem::app_prod()) {
          logger::log_warn(
            "Input validation failed in non-inferiority module",
            error = conditionMessage(e)
          )
        }

        # Return safe defaults
        list(
          noninf_calc_mode = "calc_n",
          noninf_power = 80,
          noninf_p1 = 10,
          noninf_p2 = 10,
          noninf_margin = 5,
          noninf_n1_fixed = 500,
          noninf_ratio = 1,
          noninf_alpha = 0.025
        )
      })
    })

    # Apply debouncing to reduce reactive churn
    inputs <- inputs_raw %>% debounce(500)

    list(
      inputs = inputs,  # Return debounced version
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals
    )
  })
}
