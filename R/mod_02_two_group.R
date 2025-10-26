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
      radioButtons_fixed(ns("twogrp_pow_sided"), "Test Type:",
        choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
        selected = "two.sided"
      ),
      bsTooltip(ns("twogrp_pow_sided"), "Two-sided: test if groups differ. One-sided: test if Group 1 > Group 2", "right"),
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
      radioButtons_fixed(ns("twogrp_ss_calc_mode"),
        "Calculation Mode:",
        choices = c(
          "Calculate Sample Size (given effect size)" = "calc_n",
          "Calculate Effect Size (given sample size)" = "calc_effect"
        ),
        selected = "calc_n"
      ),
      bsTooltip(ns("twogrp_ss_calc_mode"),
        "Choose whether to calculate required sample size or minimal detectable effect size",
        "right"
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

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")

    # Initialize clustering module for sample size tab
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module for sample size tab
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    # Example button - Power Analysis
    observeEvent(input$example_twogrp_pow, {
      updateNumericInput(session, "twogrp_pow_n1", value = 300)
      updateNumericInput(session, "twogrp_pow_n2", value = 300)
      updateNumericInput(session, "twogrp_pow_p1", value = 15)
      updateNumericInput(session, "twogrp_pow_p2", value = 10)
      updateRadioButtons(session, "twogrp_pow_alpha", selected = "0.05")
      updateRadioButtons(session, "twogrp_pow_sided", selected = "two.sided")
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_twogrp_pow, {
      updateNumericInput(session, "twogrp_pow_n1", value = 200)
      updateNumericInput(session, "twogrp_pow_n2", value = 200)
      updateNumericInput(session, "twogrp_pow_p1", value = 10)
      updateNumericInput(session, "twogrp_pow_p2", value = 5)
      updateRadioButtons(session, "twogrp_pow_alpha", selected = "0.05")
      updateRadioButtons(session, "twogrp_pow_sided", selected = "two.sided")
    })

    # Example button - Sample Size
    observeEvent(input$example_twogrp_ss, {
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

    # Return reactive values
    list(
      inputs = reactive({
        list(
          # Power analysis inputs
          twogrp_pow_n1 = as.numeric(input$twogrp_pow_n1),
          twogrp_pow_n2 = as.numeric(input$twogrp_pow_n2),
          twogrp_pow_p1 = as.numeric(input$twogrp_pow_p1),
          twogrp_pow_p2 = as.numeric(input$twogrp_pow_p2),
          twogrp_pow_alpha = as.numeric(input$twogrp_pow_alpha),
          twogrp_pow_sided = input$twogrp_pow_sided,
          # Sample size inputs
          twogrp_ss_calc_mode = input$twogrp_ss_calc_mode,
          twogrp_ss_power = as.numeric(input$twogrp_ss_power),
          twogrp_ss_p1 = as.numeric(input$twogrp_ss_p1),
          twogrp_ss_p2 = as.numeric(input$twogrp_ss_p2),
          twogrp_ss_n1_fixed = as.numeric(input$twogrp_ss_n1_fixed),
          twogrp_ss_p2_baseline = as.numeric(input$twogrp_ss_p2_baseline),
          twogrp_ss_ratio = as.numeric(input$twogrp_ss_ratio),
          twogrp_ss_alpha = as.numeric(input$twogrp_ss_alpha),
          twogrp_ss_sided = input$twogrp_ss_sided
        )
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
