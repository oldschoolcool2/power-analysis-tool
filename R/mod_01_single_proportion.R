#' 01_single_proportion UI Function
#'
#' @description Single Proportion power and sample size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr div actionButton icon
mod_01_single_proportion_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PAGE 1: Single Proportion - Power Analysis
    conditionalPanel(
      condition = "input.sidebar_page == 'power_single' || input.sidebar_page == null",
      h2(class = "page-title", "Single Proportion: Power Analysis"),
      helpText("Calculate power for testing a proportion against a reference value"),
      hr(),
      create_numeric_input_with_tooltip(
        ns("power_n"),
        "Available Sample Size:",
        value = 230,
        min = 1,
        step = 1,
        tooltip = "Total number of participants available for the study",
        validation_type = "sample_size"
      ),
      create_numeric_input_with_tooltip(
        ns("power_p"),
        "Expected Proportion (%):",
        value = 1,
        min = 0,
        max = 100,
        step = 0.1,
        tooltip = "Expected proportion in your study (e.g., 1% = 1 event per 100 participants)"
      ),
      create_numeric_input_with_tooltip(
        ns("power_p0"),
        "Reference Proportion (%):",
        value = 0,
        min = 0,
        max = 100,
        step = 0.1,
        tooltip = "Null hypothesis proportion (e.g., historical rate, standard of care). Use 0 for rare event detection."
      ),
      create_progressive_disclosure(
        ns("power_advanced"),
        "Advanced Options",
        tagList(
          create_enhanced_slider(
            ns("power_discon"),
            "Withdrawal/Discontinuation Rate (%):",
            min = 0, max = 50, value = 10, step = 1, post = "%",
            tooltip = "Expected percentage of participants who will withdraw or discontinue"
          ),
          create_segmented_alpha(
            ns("power_alpha"),
            "Significance Level (α):",
            selected = 0.05,
            tooltip = "Type I error rate (typically 0.05). Lower values are more conservative."
          )
        ),
        icon_name = "cog",
        initially_open = FALSE
      ),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_power_single"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_power_single"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    ),

    # PAGE 2: Single Proportion - Sample Size
    conditionalPanel(
      condition = "input.sidebar_page == 'ss_single'",
      h2(class = "page-title", "Single Proportion: Sample Size Calculation"),
      helpText("Calculate required sample size OR minimal detectable effect size"),
      hr(),
      bslib::tooltip(
        radioButtons_fixed(
          ns("ss_single_calc_mode"),
          "Calculation Mode:",
          choices = c(
            "Calculate Sample Size (given effect size)" = "calc_n",
            "Calculate Effect Size (given sample size)" = "calc_effect"
          ),
          selected = "calc_n"
        ),
        "Choose whether to calculate required sample size or minimal detectable effect size",
        placement = "right"
      ),
      hr(),
      create_segmented_power(
        ns("ss_power"),
        "Desired Power:",
        selected = 80,
        tooltip = "Probability of detecting the effect if it exists (typically 80% or 90%)"
      ),
      create_numeric_input_with_tooltip(
        ns("ss_p0"),
        "Reference Proportion (%):",
        value = 0,
        min = 0,
        max = 100,
        step = 0.1,
        tooltip = "Null hypothesis proportion (e.g., historical rate, standard of care). Use 0 for rare event detection."
      ),
      conditionalPanel(
        condition = paste0("input['", ns("ss_single_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(
          ns("ss_p"),
          "Expected Proportion (%):",
          value = 1,
          min = 0,
          max = 100,
          step = 0.1,
          tooltip = "Expected proportion in your study (e.g., 1% = 1 event per 100 participants)"
        )
      ),
      conditionalPanel(
        condition = paste0("input['", ns("ss_single_calc_mode"), "'] == 'calc_effect'"),
        create_numeric_input_with_tooltip(
          ns("ss_n_fixed"),
          "Available Sample Size:",
          value = 500,
          min = 10,
          step = 1,
          tooltip = "Fixed sample size available for the study"
        )
      ),
      create_progressive_disclosure(
        ns("ss_advanced"),
        "Advanced Options",
        tagList(
          create_enhanced_slider(
            ns("ss_discon"),
            "Withdrawal/Discontinuation Rate (%):",
            min = 0, max = 50, value = 10, step = 1, post = "%",
            tooltip = "Expected percentage of participants who will withdraw or discontinue"
          ),
          create_segmented_alpha(
            ns("ss_alpha"),
            "Significance Level (α):",
            selected = 0.05,
            tooltip = "Type I error rate (typically 0.05). Lower values are more conservative."
          ),
          hr(),
          h4("Missing Data Adjustment"),
          missing_data_ui(ns("missing_data")),
          hr(),
          h4("Clustering Adjustment"),
          clustering_ui(ns("clustering")),
          hr(),
          h4("Multiple Testing Corrections"),
          multiple_testing_ui(ns("multiple_testing"))
        ),
        icon_name = "cog",
        initially_open = FALSE
      ),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_ss_single"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_ss_single"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 01_single_proportion Server Functions
#'
#' @noRd
#'
#' @importFrom shiny observeEvent updateNumericInput updateSliderInput updateRadioButtons
#' @importFrom shiny reactive renderUI renderPlot req validate need isolate
mod_01_single_proportion_server <- function(id, parent_session = NULL){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Log module initialization
    log_module_event("single_proportion", "init", session)

    # Use parent session for rendering to shared outputs
    if (is.null(parent_session)) {
      parent_session <- session$parent
    }

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")

    # Initialize clustering module for sample size tab
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module for sample size tab
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    logger::log_debug(
      "Single proportion module sub-modules initialized",
      module = "single_proportion",
      session_id = session$token
    )

    # Example button - Power Analysis
    observeEvent(input$example_power_single, {
      logger::log_info(
        "Loading example data for single proportion power analysis",
        module = "single_proportion",
        action = "load_example",
        page = "power",
        session_id = session$token
      )
      updateNumericInput(session, "power_n", value = 1500)
      updateNumericInput(session, "power_p", value = 0.2)  # 0.2% expected
      updateNumericInput(session, "power_p0", value = 0)   # 0% reference (rare event)
      updateSliderInput(session, "power_discon", value = 15)
      updateRadioButtons(session, "power_alpha", selected = "0.05")
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_power_single, {
      logger::log_info(
        "Resetting single proportion power analysis inputs",
        module = "single_proportion",
        action = "reset",
        page = "power",
        session_id = session$token
      )
      updateNumericInput(session, "power_n", value = 230)
      updateNumericInput(session, "power_p", value = 1)    # 1% expected
      updateNumericInput(session, "power_p0", value = 0)   # 0% reference
      updateSliderInput(session, "power_discon", value = 10)
      updateRadioButtons(session, "power_alpha", selected = "0.05")
    })

    # Example button - Sample Size
    observeEvent(input$example_ss_single, {
      logger::log_info(
        "Loading example data for single proportion sample size",
        module = "single_proportion",
        action = "load_example",
        page = "sample_size",
        session_id = session$token
      )
      updateRadioButtons(session, "ss_single_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "ss_power", selected = "80")
      updateNumericInput(session, "ss_p", value = 0.2)   # 0.2% expected
      updateNumericInput(session, "ss_p0", value = 0)    # 0% reference (rare event)
      updateSliderInput(session, "ss_discon", value = 15)
      updateRadioButtons(session, "ss_alpha", selected = "0.05")
    })

    # Reset button - Sample Size
    observeEvent(input$reset_ss_single, {
      logger::log_info(
        "Resetting single proportion sample size inputs",
        module = "single_proportion",
        action = "reset",
        page = "sample_size",
        session_id = session$token
      )
      updateRadioButtons(session, "ss_single_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "ss_power", selected = "80")
      updateNumericInput(session, "ss_p", value = 1)      # 1% expected
      updateNumericInput(session, "ss_p0", value = 0)     # 0% reference
      updateNumericInput(session, "ss_n_fixed", value = 500)
      updateSliderInput(session, "ss_discon", value = 10)
      updateRadioButtons(session, "ss_alpha", selected = "0.05")
    })

    # Define allowlists for categorical inputs (security best practice)
    VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
    VALID_POWER <- c("70", "80", "90", "95")
    VALID_CALC_MODES <- c("calc_n", "calc_effect")

    # Raw reactive inputs (not debounced)
    # This separates input collection from validation
    inputs_raw <- reactive({
      # Use req() to prevent execution until inputs are available
      # This is more efficient than validate() for simple presence checks
      req(input$power_n)
      req(input$power_p)
      req(input$power_p0)
      req(input$power_alpha)
      req(input$power_discon)

      # Validate and sanitize numeric inputs with proper type checking
      tryCatch({
        list(
          # Power calculation inputs
          power_n = validate_numeric_input(
            input$power_n,
            "Sample size",
            min = 1,
            max = 1e7
          ),
          power_p = validate_proportion_input(
            input$power_p,
            "Expected proportion"
          ),
          power_p0 = validate_proportion_input(
            input$power_p0,
            "Reference proportion"
          ),
          power_alpha = as.numeric(validate_choice_input(
            input$power_alpha,
            VALID_ALPHA,
            "Significance level"
          )),
          power_discon = validate_proportion_input(
            input$power_discon,
            "Discontinuation rate"
          ),

          # Sample size calculation inputs
          ss_single_calc_mode = validate_choice_input(
            input$ss_single_calc_mode %||% "calc_n",
            VALID_CALC_MODES,
            "Calculation mode"
          ),
          ss_power = as.numeric(validate_choice_input(
            input$ss_power %||% "80",
            VALID_POWER,
            "Power level"
          )),
          ss_p = validate_proportion_input(
            input$ss_p %||% 1,
            "Expected proportion",
            allow_null = TRUE
          ),
          ss_p0 = validate_proportion_input(
            input$ss_p0 %||% 0,
            "Reference proportion"
          ),
          ss_n_fixed = validate_numeric_input(
            input$ss_n_fixed %||% 500,
            "Fixed sample size",
            min = 10,
            max = 1e7,
            allow_null = TRUE
          ),
          ss_discon = validate_proportion_input(
            input$ss_discon %||% 10,
            "Discontinuation rate"
          ),
          ss_alpha = as.numeric(validate_choice_input(
            input$ss_alpha %||% "0.05",
            VALID_ALPHA,
            "Significance level"
          ))
        )
      }, error = function(e) {
        # If validation fails, log the error (in production) and return defaults
        if (golem::app_prod()) {
          logger::log_warn(
            "Input validation failed in single proportion module",
            error = conditionMessage(e)
          )
        }

        # Return safe defaults if validation fails
        list(
          power_n = 230,
          power_p = 1,
          power_p0 = 0,
          power_alpha = 0.05,
          power_discon = 10,
          ss_single_calc_mode = "calc_n",
          ss_power = 80,
          ss_p = 1,
          ss_p0 = 0,
          ss_n_fixed = 500,
          ss_discon = 10,
          ss_alpha = 0.05
        )
      })
    })

    # Debounced inputs - wait 500ms after last change before updating
    # This prevents excessive recalculation while user is typing
    inputs <- inputs_raw %>% debounce(500)

    # Register cleanup handler
    onStop(function() {
      log_module_event("single_proportion", "cleanup", session)
    })

    # Return reactive values for parent app_server
    list(
      inputs = reactive({
        # Log reactive execution at TRACE level (only when debugging)
        log_reactive_execution("single_proportion_inputs", session)
        inputs()
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals
    )
  })
}

## To be copied in the UI
# mod_01_single_proportion_ui("single_proportion_1")

## To be copied in the server
# mod_01_single_proportion_server("single_proportion_1")
