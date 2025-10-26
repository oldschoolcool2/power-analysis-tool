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
      radioButtons_fixed(ns("noninf_calc_mode"), "Calculation Mode:",
        choices = c("Calculate Sample Size (given margin)" = "calc_n", "Calculate Margin (given sample size)" = "calc_effect"),
        selected = "calc_n"),
      bsTooltip(ns("noninf_calc_mode"), "Choose whether to calculate required sample size or minimal detectable non-inferiority margin", "right"),
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
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    observeEvent(input$example_noninf, {
      updateRadioButtons(session, "noninf_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "noninf_power", selected = "80")
      updateNumericInput(session, "noninf_p1", value = 10)
      updateNumericInput(session, "noninf_p2", value = 10)
      updateNumericInput(session, "noninf_margin", value = 3)
      updateNumericInput(session, "noninf_ratio", value = 1)
      updateRadioButtons(session, "noninf_alpha", selected = "0.025")
    })
    
    observeEvent(input$reset_noninf, {
      updateRadioButtons(session, "noninf_calc_mode", selected = "calc_n")
      updateRadioButtons(session, "noninf_power", selected = "80")
      updateNumericInput(session, "noninf_p1", value = 10)
      updateNumericInput(session, "noninf_p2", value = 10)
      updateNumericInput(session, "noninf_margin", value = 5)
      updateNumericInput(session, "noninf_n1_fixed", value = 500)
      updateNumericInput(session, "noninf_ratio", value = 1)
      updateRadioButtons(session, "noninf_alpha", selected = "0.025")
    })

    list(
      inputs = reactive({
        list(noninf_calc_mode = input$noninf_calc_mode, noninf_power = as.numeric(input$noninf_power),
             noninf_p1 = as.numeric(input$noninf_p1), noninf_p2 = as.numeric(input$noninf_p2), noninf_margin = as.numeric(input$noninf_margin),
             noninf_n1_fixed = as.numeric(input$noninf_n1_fixed), noninf_ratio = as.numeric(input$noninf_ratio), noninf_alpha = as.numeric(input$noninf_alpha))
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals
    )
  })
}
