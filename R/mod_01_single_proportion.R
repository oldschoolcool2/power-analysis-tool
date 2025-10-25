#' 01_single_proportion UI Function
#'
#' @description Single Proportion (Rule of 3) power and sample size analysis
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
      helpText("Calculate power for detecting a single event rate (e.g., post-marketing surveillance)"),
      hr(),
      create_numeric_input_with_tooltip(
        ns("power_n"),
        "Available Sample Size:",
        value = 230,
        min = 1,
        step = 1,
        tooltip = "Total number of participants available for the study"
      ),
      create_numeric_input_with_tooltip(
        ns("power_p"),
        "Event Frequency (1 in x):",
        value = 100,
        min = 1,
        step = 1,
        tooltip = "Expected frequency of the event. E.g., 100 means 1 event per 100 participants"
      ),
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
      radioButtons_fixed(
        ns("ss_single_calc_mode"),
        "Calculation Mode:",
        choices = c(
          "Calculate Sample Size (given effect size)" = "calc_n",
          "Calculate Effect Size (given sample size)" = "calc_effect"
        ),
        selected = "calc_n"
      ),
      bsTooltip(
        ns("ss_single_calc_mode"),
        "Choose whether to calculate required sample size or minimal detectable effect size",
        "right"
      ),
      hr(),
      create_segmented_power(
        ns("ss_power"),
        "Desired Power:",
        selected = 80,
        tooltip = "Probability of detecting the effect if it exists (typically 80% or 90%)"
      ),
      conditionalPanel(
        condition = paste0("input['", ns("ss_single_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(
          ns("ss_p"),
          "Event Frequency (1 in x):",
          value = 100,
          min = 1,
          step = 1,
          tooltip = "Expected frequency of the event. E.g., 100 means 1 event per 100 participants"
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
      missing_data_ui(ns("missing_data")),
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
mod_01_single_proportion_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")

    # Example button - Power Analysis
    observeEvent(input$example_power_single, {
      updateNumericInput(session, "power_n", value = 1500)
      updateNumericInput(session, "power_p", value = 500)
      updateSliderInput(session, "power_discon", value = 15)
      update_segmented_alpha(session, "power_alpha", value = 0.05)
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_power_single, {
      updateNumericInput(session, "power_n", value = 230)
      updateNumericInput(session, "power_p", value = 100)
      updateSliderInput(session, "power_discon", value = 10)
      update_segmented_alpha(session, "power_alpha", value = 0.05)
    })

    # Example button - Sample Size
    observeEvent(input$example_ss_single, {
      updateRadioButtons(session, "ss_single_calc_mode", selected = "calc_n")
      update_segmented_power(session, "ss_power", value = 80)
      updateNumericInput(session, "ss_p", value = 500)
      updateSliderInput(session, "ss_discon", value = 15)
      update_segmented_alpha(session, "ss_alpha", value = 0.05)
    })

    # Reset button - Sample Size
    observeEvent(input$reset_ss_single, {
      updateRadioButtons(session, "ss_single_calc_mode", selected = "calc_n")
      update_segmented_power(session, "ss_power", value = 80)
      updateNumericInput(session, "ss_p", value = 100)
      updateNumericInput(session, "ss_n_fixed", value = 500)
      updateSliderInput(session, "ss_discon", value = 10)
      update_segmented_alpha(session, "ss_alpha", value = 0.05)
    })

    # Note: The actual calculation logic will remain in app_server.R for now
    # and will be migrated in a future step when we extract business logic to fct_*.R files
  })
}

## To be copied in the UI
# mod_01_single_proportion_ui("single_proportion_1")

## To be copied in the server
# mod_01_single_proportion_server("single_proportion_1")
