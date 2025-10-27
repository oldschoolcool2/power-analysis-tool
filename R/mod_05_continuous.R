#' 05_continuous UI Function
#'
#' @description Continuous Outcomes (t-test) power and sample size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr div actionButton icon radioButtons
mod_05_continuous_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PAGE 8: Continuous Outcomes - Power Analysis
    conditionalPanel(
      condition = "input.sidebar_page == 'power_continuous'",
      h2(class = "page-title", "Continuous Outcomes (t-test): Power Analysis"),
      helpText("Calculate power for comparing means between two groups (e.g., BMI, blood pressure, QoL scores)"),
      hr(),
      create_numeric_input_with_tooltip(
        ns("cont_pow_n1"),
        "Sample Size Group 1:",
        value = 100,
        min = 2,
        step = 1,
        tooltip = "Number of participants in treatment/exposed group"
      ),
      create_numeric_input_with_tooltip(
        ns("cont_pow_n2"),
        "Sample Size Group 2:",
        value = 100,
        min = 2,
        step = 1,
        tooltip = "Number of participants in control/unexposed group"
      ),
      create_numeric_input_with_tooltip(
        ns("cont_pow_d"),
        "Effect Size (Cohen's d):",
        value = 0.5,
        min = 0.01,
        max = 5,
        step = 0.1,
        tooltip = "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8"
      ),
      create_segmented_alpha(
        ns("cont_pow_alpha"),
        "Significance Level (α):",
        selected = 0.05,
        tooltip = "Type I error rate (typically 0.05)"
      ),
      bslib::tooltip(
        radioButtons_fixed(
          ns("cont_pow_sided"),
          "Test Type:",
          choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
          selected = "two.sided"
        ),
        "Two-sided: test if groups differ. One-sided: test directional hypothesis",
        placement = "right"
      ),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_cont_pow"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_cont_pow"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    ),

    # PAGE 9: Continuous Outcomes - Sample Size
    conditionalPanel(
      condition = "input.sidebar_page == 'ss_continuous'",
      h2(class = "page-title", "Continuous Outcomes (t-test): Sample Size Calculation"),
      helpText("Calculate required sample size OR minimal detectable effect size"),
      hr(),
      bslib::tooltip(
        radioButtons_fixed(
          ns("cont_ss_calc_mode"),
          "Calculation Mode:",
          choices = c(
            "Calculate Sample Size (given effect size)" = "calc_n",
            "Calculate Effect Size (given sample size)" = "calc_effect"
          ),
          selected = "calc_n"
        ),
        "Choose whether to calculate required sample size or minimal detectable effect size (Cohen's d)",
        placement = "right"
      ),
      hr(),
      create_segmented_power(
        ns("cont_ss_power"),
        "Desired Power:",
        selected = 80,
        tooltip = "Probability of detecting the effect if it exists"
      ),
      conditionalPanel(
        condition = paste0("input['", ns("cont_ss_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(
          ns("cont_ss_d"),
          "Effect Size (Cohen's d):",
          value = 0.5,
          min = 0.01,
          max = 5,
          step = 0.1,
          tooltip = "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8"
        )
      ),
      conditionalPanel(
        condition = paste0("input['", ns("cont_ss_calc_mode"), "'] == 'calc_effect'"),
        create_numeric_input_with_tooltip(
          ns("cont_ss_n1_fixed"),
          "Available Sample Size (Group 1):",
          value = 100,
          min = 2,
          step = 1,
          tooltip = "Fixed sample size available for Group 1"
        )
      ),
      create_numeric_input_with_tooltip(
        ns("cont_ss_ratio"),
        "Allocation Ratio (n2/n1):",
        value = 1,
        min = 0.1,
        max = 10,
        step = 0.1,
        tooltip = "Ratio of Group 2 to Group 1 sample size. 1 = equal groups"
      ),
      create_segmented_alpha(
        ns("cont_ss_alpha"),
        "Significance Level (α):",
        selected = 0.05,
        tooltip = "Type I error rate (typically 0.05)"
      ),
      radioButtons_fixed(
        ns("cont_ss_sided"),
        "Test Type:",
        choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
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
        actionButton(ns("example_cont_ss"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_cont_ss"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 05_continuous Server Functions
#'
#' @noRd
mod_05_continuous_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Log module initialization
    log_module_event("continuous", "init", session)

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module for sample size tab
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    logger::log_debug(
      "Continuous module sub-modules initialized",
      module = "continuous",
      session_id = session$token
    )

    # Example button - Power Analysis
    observeEvent(input$example_cont_pow, {
      logger::log_info(
        "Loading example data for continuous power analysis",
        module = "continuous",
        action = "load_example",
        page = "power",
        session_id = session$token
      )
      updateNumericInput(session, "cont_pow_n1", value = 150)
      updateNumericInput(session, "cont_pow_n2", value = 150)
      updateNumericInput(session, "cont_pow_d", value = 0.4)
      updateRadioButtons(session, "cont_pow_alpha", selected = "0.05")
      updateRadioButtons(session, "cont_pow_sided", selected = "two.sided")
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_cont_pow, {
      logger::log_info(
        "Resetting continuous power analysis inputs",
        module = "continuous",
        action = "reset",
        page = "power",
        session_id = session$token
      )
      updateNumericInput(session, "cont_pow_n1", value = 100)
      updateNumericInput(session, "cont_pow_n2", value = 100)
      updateNumericInput(session, "cont_pow_d", value = 0.5)
      updateRadioButtons(session, "cont_pow_alpha", selected = "0.05")
      updateRadioButtons(session, "cont_pow_sided", selected = "two.sided")
    })

    # Example button - Sample Size
    observeEvent(input$example_cont_ss, {
      logger::log_info(
        "Loading example data for continuous sample size",
        module = "continuous",
        action = "load_example",
        page = "sample_size",
        session_id = session$token
      )
      updateRadioButtons(session, "cont_ss_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "cont_ss_power", selected = "90")
      updateNumericInput(session, "cont_ss_d", value = 0.4)
      updateNumericInput(session, "cont_ss_ratio", value = 1)
      updateRadioButtons(session, "cont_ss_alpha", selected = "0.05")
      updateRadioButtons(session, "cont_ss_sided", selected = "two.sided")
    })

    # Reset button - Sample Size
    observeEvent(input$reset_cont_ss, {
      logger::log_info(
        "Resetting continuous sample size inputs",
        module = "continuous",
        action = "reset",
        page = "sample_size",
        session_id = session$token
      )
      updateRadioButtons(session, "cont_ss_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "cont_ss_power", selected = "80")
      updateNumericInput(session, "cont_ss_d", value = 0.5)
      updateNumericInput(session, "cont_ss_n1_fixed", value = 100)
      updateNumericInput(session, "cont_ss_ratio", value = 1)
      updateRadioButtons(session, "cont_ss_alpha", selected = "0.05")
      updateRadioButtons(session, "cont_ss_sided", selected = "two.sided")
    })

    # Define allowlists for categorical inputs (security best practice)
    VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
    VALID_POWER <- c("70", "80", "90", "95")
    VALID_TEST_TYPES <- c("one.sided", "two.sided")
    VALID_CALC_MODES <- c("calc_n", "calc_effect")

    # Raw reactive inputs (not debounced)
    inputs_raw <- reactive({
      # Use req() to prevent execution until inputs are available
      req(input$cont_pow_n1)
      req(input$cont_pow_n2)
      req(input$cont_pow_d)
      req(input$cont_pow_alpha)
      req(input$cont_pow_sided)

      # Validate and sanitize numeric inputs with proper type checking
      tryCatch({
        list(
          # Power analysis inputs
          cont_pow_n1 = validate_numeric_input(
            input$cont_pow_n1,
            "Sample size group 1",
            min = 1,
            max = 1e7
          ),
          cont_pow_n2 = validate_numeric_input(
            input$cont_pow_n2,
            "Sample size group 2",
            min = 1,
            max = 1e7
          ),
          cont_pow_d = validate_numeric_input(
            input$cont_pow_d,
            "Cohen's d",
            min = -10,
            max = 10
          ),
          cont_pow_alpha = as.numeric(validate_choice_input(
            input$cont_pow_alpha,
            VALID_ALPHA,
            "Significance level"
          )),
          cont_pow_sided = validate_choice_input(
            input$cont_pow_sided,
            VALID_TEST_TYPES,
            "Test type"
          ),

          # Sample size calculation inputs
          cont_ss_calc_mode = validate_choice_input(
            input$cont_ss_calc_mode %||% "calc_n",
            VALID_CALC_MODES,
            "Calculation mode"
          ),
          cont_ss_power = as.numeric(validate_choice_input(
            input$cont_ss_power %||% "80",
            VALID_POWER,
            "Power level"
          )),
          cont_ss_d = validate_numeric_input(
            input$cont_ss_d %||% 0.5,
            "Cohen's d",
            min = -10,
            max = 10
          ),
          cont_ss_n1_fixed = validate_numeric_input(
            input$cont_ss_n1_fixed %||% 100,
            "Fixed sample size group 1",
            min = 10,
            max = 1e7,
            allow_null = TRUE
          ),
          cont_ss_ratio = validate_numeric_input(
            input$cont_ss_ratio %||% 1,
            "Allocation ratio",
            min = 0.01,
            max = 100
          ),
          cont_ss_alpha = as.numeric(validate_choice_input(
            input$cont_ss_alpha %||% "0.05",
            VALID_ALPHA,
            "Significance level"
          )),
          cont_ss_sided = validate_choice_input(
            input$cont_ss_sided %||% "two.sided",
            VALID_TEST_TYPES,
            "Test type"
          )
        )
      }, error = function(e) {
        # If validation fails, log the error (in production) and return defaults
        if (golem::app_prod()) {
          logger::log_warn(
            "Input validation failed in continuous outcome module",
            error = conditionMessage(e)
          )
        }

        # Return safe defaults if validation fails
        list(
          cont_pow_n1 = 100,
          cont_pow_n2 = 100,
          cont_pow_d = 0.5,
          cont_pow_alpha = 0.05,
          cont_pow_sided = "two.sided",
          cont_ss_calc_mode = "calc_n",
          cont_ss_power = 80,
          cont_ss_d = 0.5,
          cont_ss_n1_fixed = 100,
          cont_ss_ratio = 1,
          cont_ss_alpha = 0.05,
          cont_ss_sided = "two.sided"
        )
      })
    })

    # Debounced inputs - wait 500ms after last change before updating
    inputs <- inputs_raw %>% debounce(500)

    # Register cleanup handler
    onStop(function() {
      log_module_event("continuous", "cleanup", session)
    })

    # Return reactive values
    list(
      inputs = reactive({
        # Log reactive execution at TRACE level (only when debugging)
        log_reactive_execution("continuous_inputs", session)
        inputs()
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals
    )
  })
}
