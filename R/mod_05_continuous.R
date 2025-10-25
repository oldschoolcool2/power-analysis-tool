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
      radioButtons_fixed(
        ns("cont_pow_sided"),
        "Test Type:",
        choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
        selected = "two.sided"
      ),
      bsTooltip(ns("cont_pow_sided"), "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
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
      radioButtons_fixed(
        ns("cont_ss_calc_mode"),
        "Calculation Mode:",
        choices = c(
          "Calculate Sample Size (given effect size)" = "calc_n",
          "Calculate Effect Size (given sample size)" = "calc_effect"
        ),
        selected = "calc_n"
      ),
      bsTooltip(
        ns("cont_ss_calc_mode"),
        "Choose whether to calculate required sample size or minimal detectable effect size (Cohen's d)",
        "right"
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

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Example button - Power Analysis
    observeEvent(input$example_cont_pow, {
      updateNumericInput(session, "cont_pow_n1", value = 150)
      updateNumericInput(session, "cont_pow_n2", value = 150)
      updateNumericInput(session, "cont_pow_d", value = 0.4)
      update_segmented_alpha(session, "cont_pow_alpha", value = 0.05)
      updateRadioButtons(session, "cont_pow_sided", selected = "two.sided")
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_cont_pow, {
      updateNumericInput(session, "cont_pow_n1", value = 100)
      updateNumericInput(session, "cont_pow_n2", value = 100)
      updateNumericInput(session, "cont_pow_d", value = 0.5)
      update_segmented_alpha(session, "cont_pow_alpha", value = 0.05)
      updateRadioButtons(session, "cont_pow_sided", selected = "two.sided")
    })

    # Example button - Sample Size
    observeEvent(input$example_cont_ss, {
      updateRadioButtons(session, "cont_ss_calc_mode", selected = "calc_n")
      update_segmented_power(session, "cont_ss_power", value = 90)
      updateNumericInput(session, "cont_ss_d", value = 0.4)
      updateNumericInput(session, "cont_ss_ratio", value = 1)
      update_segmented_alpha(session, "cont_ss_alpha", value = 0.05)
      updateRadioButtons(session, "cont_ss_sided", selected = "two.sided")
    })

    # Reset button - Sample Size
    observeEvent(input$reset_cont_ss, {
      updateRadioButtons(session, "cont_ss_calc_mode", selected = "calc_n")
      update_segmented_power(session, "cont_ss_power", value = 80)
      updateNumericInput(session, "cont_ss_d", value = 0.5)
      updateNumericInput(session, "cont_ss_n1_fixed", value = 100)
      updateNumericInput(session, "cont_ss_ratio", value = 1)
      update_segmented_alpha(session, "cont_ss_alpha", value = 0.05)
      updateRadioButtons(session, "cont_ss_sided", selected = "two.sided")
    })

    # Return reactive values
    list(
      inputs = reactive({
        list(
          # Power analysis inputs
          cont_pow_n1 = input$cont_pow_n1,
          cont_pow_n2 = input$cont_pow_n2,
          cont_pow_d = input$cont_pow_d,
          cont_pow_alpha = input$cont_pow_alpha,
          cont_pow_sided = input$cont_pow_sided,
          # Sample size inputs
          cont_ss_calc_mode = input$cont_ss_calc_mode,
          cont_ss_power = input$cont_ss_power,
          cont_ss_d = input$cont_ss_d,
          cont_ss_n1_fixed = input$cont_ss_n1_fixed,
          cont_ss_ratio = input$cont_ss_ratio,
          cont_ss_alpha = input$cont_ss_alpha,
          cont_ss_sided = input$cont_ss_sided
        )
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals
    )
  })
}
