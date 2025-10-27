#' 02_two_group UI Function
#'
#' @description Two-Group Comparison power and sample size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr div actionButton icon radioButtons
mod_02_two_group_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PAGE 3: Two-Group - Power Analysis
    conditionalPanel(
      condition = "input.sidebar_page == 'power_twogrp'",
      h2(class = "page-title", "Two-Group Comparison: Power Analysis"),
      helpText("Calculate power for comparing two proportions (e.g., exposed vs. unexposed in cohort studies)"),
      hr(),
      create_numeric_input_with_tooltip(
        ns("twogrp_pow_n1"),
        "Sample Size Group 1:",
        value = 200,
        min = 1,
        step = 1,
        tooltip = "Number of participants in exposed/treatment group"
      ),
      create_numeric_input_with_tooltip(
        ns("twogrp_pow_n2"),
        "Sample Size Group 2:",
        value = 200,
        min = 1,
        step = 1,
        tooltip = "Number of participants in unexposed/control group"
      ),
      create_numeric_input_with_tooltip(
        ns("twogrp_pow_p1"),
        "Event Rate Group 1 (%):",
        value = 10,
        min = 0,
        max = 100,
        step = 0.1,
        tooltip = "Expected event rate in exposed/treatment group (as percentage)"
      ),
      create_numeric_input_with_tooltip(
        ns("twogrp_pow_p2"),
        "Event Rate Group 2 (%):",
        value = 5,
        min = 0,
        max = 100,
        step = 0.1,
        tooltip = "Expected event rate in unexposed/control group (as percentage)"
      ),
      create_segmented_alpha(ns("twogrp_pow_alpha"), "Significance Level (α):",
                            selected = 0.05,
                            tooltip = "Type I error rate (typically 0.05)"),
      bslib::tooltip(
        radioButtons_fixed(ns("twogrp_pow_sided"), "Test Type:",
          choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
          selected = "two.sided"
        ),
        "Two-sided: test if groups differ. One-sided: test if Group 1 > Group 2",
        placement = "right"
      ),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_twogrp_pow"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_twogrp_pow"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    ),

    # PAGE 4: Two-Group - Sample Size
    conditionalPanel(
      condition = "input.sidebar_page == 'ss_twogrp'",
      h2(class = "page-title", "Two-Group Comparison: Sample Size Calculation"),
      helpText("Calculate required sample size OR minimal detectable effect size"),
      hr(),
      bslib::tooltip(
        radioButtons_fixed(ns("twogrp_ss_calc_mode"),
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
      create_segmented_power(ns("twogrp_ss_power"), "Desired Power:",
                            selected = 80,
                            tooltip = "Probability of detecting the effect if it exists"),
      conditionalPanel(
        condition = paste0("input['", ns("twogrp_ss_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(ns("twogrp_ss_p1"), "Event Rate Group 1 (%):", 10,
                                         min = 0, max = 100, step = 0.1,
                                         tooltip = "Expected event rate in exposed/treatment group (as percentage)"),
        create_numeric_input_with_tooltip(ns("twogrp_ss_p2"), "Event Rate Group 2 (%):", 5,
                                         min = 0, max = 100, step = 0.1,
                                         tooltip = "Expected event rate in unexposed/control group (as percentage)")
      ),
      conditionalPanel(
        condition = paste0("input['", ns("twogrp_ss_calc_mode"), "'] == 'calc_effect'"),
        create_numeric_input_with_tooltip(ns("twogrp_ss_n1_fixed"), "Available Sample Size (Group 1):", 500,
                                         min = 10, step = 1,
                                         tooltip = "Fixed sample size available for Group 1"),
        create_numeric_input_with_tooltip(ns("twogrp_ss_p2_baseline"), "Baseline Event Rate Group 2 (%):", 10,
                                         min = 0, max = 100, step = 0.1,
                                         tooltip = "Expected event rate in control/unexposed group (as percentage)")
      ),
      create_numeric_input_with_tooltip(ns("twogrp_ss_ratio"), "Allocation Ratio (n2/n1):", 1,
                                       min = 0.1, max = 10, step = 0.1,
                                       tooltip = "Ratio of Group 2 to Group 1 sample size. 1 = equal groups, 2 = twice as many in Group 2"),
      create_segmented_alpha(ns("twogrp_ss_alpha"), "Significance Level (α):",
                            selected = 0.05,
                            tooltip = "Type I error rate (typically 0.05)"),
      radioButtons_fixed(ns("twogrp_ss_sided"), "Test Type:",
        choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
        selected = "two.sided"
      ),
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
        actionButton(ns("example_twogrp_ss"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_twogrp_ss"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 02_two_group Server Functions
#'
#' @noRd
#'
#' @importFrom shiny observeEvent updateNumericInput updateSliderInput updateRadioButtons
#' @importFrom shiny reactive renderUI renderPlot req validate need isolate
mod_02_two_group_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Log module initialization
    log_module_event("two_group", "init", session)

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")

    # Initialize clustering module for sample size tab
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module for sample size tab
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    logger::log_debug(
      "Two-group module sub-modules initialized",
      module = "two_group",
      session_id = session$token
    )

    # Example button - Power Analysis
    observeEvent(input$example_twogrp_pow, {
      logger::log_info(
        "Loading example data for two-group power analysis",
        module = "two_group",
        action = "load_example",
        page = "power",
        session_id = session$token
      )
      updateNumericInput(session, "twogrp_pow_n1", value = 300)
      updateNumericInput(session, "twogrp_pow_n2", value = 300)
      updateNumericInput(session, "twogrp_pow_p1", value = 15)
      updateNumericInput(session, "twogrp_pow_p2", value = 10)
      updateRadioButtons(session, "twogrp_pow_alpha", selected = "0.05")
      updateRadioButtons(session, "twogrp_pow_sided", selected = "two.sided")
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_twogrp_pow, {
      logger::log_info(
        "Resetting two-group power analysis inputs",
        module = "two_group",
        action = "reset",
        page = "power",
        session_id = session$token
      )
      updateNumericInput(session, "twogrp_pow_n1", value = 200)
      updateNumericInput(session, "twogrp_pow_n2", value = 200)
      updateNumericInput(session, "twogrp_pow_p1", value = 10)
      updateNumericInput(session, "twogrp_pow_p2", value = 5)
      updateRadioButtons(session, "twogrp_pow_alpha", selected = "0.05")
      updateRadioButtons(session, "twogrp_pow_sided", selected = "two.sided")
    })

    # Example button - Sample Size
    observeEvent(input$example_twogrp_ss, {
      logger::log_info(
        "Loading example data for two-group sample size",
        module = "two_group",
        action = "load_example",
        page = "sample_size",
        session_id = session$token
      )
      updateRadioButtons(session, "twogrp_ss_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "twogrp_ss_power", selected = "80")
      updateNumericInput(session, "twogrp_ss_p1", value = 15)
      updateNumericInput(session, "twogrp_ss_p2", value = 10)
      updateNumericInput(session, "twogrp_ss_ratio", value = 1)
      updateRadioButtons(session, "twogrp_ss_alpha", selected = "0.05")
      updateRadioButtons(session, "twogrp_ss_sided", selected = "two.sided")
    })

    # Reset button - Sample Size
    observeEvent(input$reset_twogrp_ss, {
      logger::log_info(
        "Resetting two-group sample size inputs",
        module = "two_group",
        action = "reset",
        page = "sample_size",
        session_id = session$token
      )
      updateRadioButtons(session, "twogrp_ss_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "twogrp_ss_power", selected = "80")
      updateNumericInput(session, "twogrp_ss_p1", value = 10)
      updateNumericInput(session, "twogrp_ss_p2", value = 5)
      updateNumericInput(session, "twogrp_ss_n1_fixed", value = 500)
      updateNumericInput(session, "twogrp_ss_p2_baseline", value = 10)
      updateNumericInput(session, "twogrp_ss_ratio", value = 1)
      updateRadioButtons(session, "twogrp_ss_alpha", selected = "0.05")
      updateRadioButtons(session, "twogrp_ss_sided", selected = "two.sided")
    })

    # Define allowlists for categorical inputs (security best practice)
    VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
    VALID_POWER <- c("70", "80", "90", "95")
    VALID_TEST_TYPES <- c("one.sided", "two.sided")
    VALID_CALC_MODES <- c("calc_n", "calc_effect")

    # Raw reactive inputs (not debounced)
    inputs_raw <- reactive({
      # Use req() to prevent execution until inputs are available
      req(input$twogrp_pow_n1)
      req(input$twogrp_pow_n2)
      req(input$twogrp_pow_p1)
      req(input$twogrp_pow_p2)
      req(input$twogrp_pow_alpha)
      req(input$twogrp_pow_sided)

      # Validate and sanitize numeric inputs with proper type checking
      tryCatch({
        list(
          # Power analysis inputs
          twogrp_pow_n1 = validate_numeric_input(
            input$twogrp_pow_n1,
            "Sample size group 1",
            min = 1,
            max = 1e7
          ),
          twogrp_pow_n2 = validate_numeric_input(
            input$twogrp_pow_n2,
            "Sample size group 2",
            min = 1,
            max = 1e7
          ),
          twogrp_pow_p1 = validate_proportion_input(
            input$twogrp_pow_p1,
            "Event rate group 1"
          ),
          twogrp_pow_p2 = validate_proportion_input(
            input$twogrp_pow_p2,
            "Event rate group 2"
          ),
          twogrp_pow_alpha = as.numeric(validate_choice_input(
            input$twogrp_pow_alpha,
            VALID_ALPHA,
            "Significance level"
          )),
          twogrp_pow_sided = validate_choice_input(
            input$twogrp_pow_sided,
            VALID_TEST_TYPES,
            "Test type"
          ),

          # Sample size calculation inputs
          twogrp_ss_calc_mode = validate_choice_input(
            input$twogrp_ss_calc_mode %||% "calc_n",
            VALID_CALC_MODES,
            "Calculation mode"
          ),
          twogrp_ss_power = as.numeric(validate_choice_input(
            input$twogrp_ss_power %||% "80",
            VALID_POWER,
            "Power level"
          )),
          twogrp_ss_p1 = validate_proportion_input(
            input$twogrp_ss_p1 %||% 10,
            "Event rate group 1"
          ),
          twogrp_ss_p2 = validate_proportion_input(
            input$twogrp_ss_p2 %||% 5,
            "Event rate group 2"
          ),
          twogrp_ss_n1_fixed = validate_numeric_input(
            input$twogrp_ss_n1_fixed %||% 500,
            "Fixed sample size group 1",
            min = 10,
            max = 1e7,
            allow_null = TRUE
          ),
          twogrp_ss_p2_baseline = validate_proportion_input(
            input$twogrp_ss_p2_baseline %||% 10,
            "Baseline proportion group 2",
            allow_null = TRUE
          ),
          twogrp_ss_ratio = validate_numeric_input(
            input$twogrp_ss_ratio %||% 1,
            "Allocation ratio",
            min = 0.01,
            max = 100
          ),
          twogrp_ss_alpha = as.numeric(validate_choice_input(
            input$twogrp_ss_alpha %||% "0.05",
            VALID_ALPHA,
            "Significance level"
          )),
          twogrp_ss_sided = validate_choice_input(
            input$twogrp_ss_sided %||% "two.sided",
            VALID_TEST_TYPES,
            "Test type"
          )
        )
      }, error = function(e) {
        # If validation fails, log the error (in production) and return defaults
        if (golem::app_prod()) {
          logger::log_warn(
            "Input validation failed in two-group module",
            error = conditionMessage(e)
          )
        }

        # Return safe defaults if validation fails
        list(
          twogrp_pow_n1 = 200,
          twogrp_pow_n2 = 200,
          twogrp_pow_p1 = 10,
          twogrp_pow_p2 = 5,
          twogrp_pow_alpha = 0.05,
          twogrp_pow_sided = "two.sided",
          twogrp_ss_calc_mode = "calc_n",
          twogrp_ss_power = 80,
          twogrp_ss_p1 = 10,
          twogrp_ss_p2 = 5,
          twogrp_ss_n1_fixed = 500,
          twogrp_ss_p2_baseline = 10,
          twogrp_ss_ratio = 1,
          twogrp_ss_alpha = 0.05,
          twogrp_ss_sided = "two.sided"
        )
      })
    })

    # Debounced inputs - wait 500ms after last change before updating
    inputs <- inputs_raw %>% debounce(500)

    # Register cleanup handler
    onStop(function() {
      log_module_event("two_group", "cleanup", session)
    })

    # Return reactive values
    list(
      inputs = reactive({
        # Log reactive execution at TRACE level (only when debugging)
        log_reactive_execution("two_group_inputs", session)
        inputs()
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals
    )
  })
}

## To be copied in the UI
# mod_02_two_group_ui("two_group_1")

## To be copied in the server
# mod_02_two_group_server("two_group_1")
