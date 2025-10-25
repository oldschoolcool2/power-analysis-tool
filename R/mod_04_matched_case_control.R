#' 04_matched_case_control UI Function
#'
#' @description Matched Case-Control Study sample size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr div actionButton icon radioButtons
mod_04_matched_case_control_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PAGE 7: Matched Case-Control
    conditionalPanel(
      condition = "input.sidebar_page == 'match_casecontrol'",
      h2(class = "page-title", "Matched Case-Control Study"),
      helpText("Calculate sample size OR minimal detectable odds ratio"),
      hr(),
      radioButtons_fixed(
        ns("match_calc_mode"),
        "Calculation Mode:",
        choices = c(
          "Calculate Sample Size (given odds ratio)" = "calc_n",
          "Calculate Odds Ratio (given sample size)" = "calc_effect"
        ),
        selected = "calc_n"
      ),
      bsTooltip(
        ns("match_calc_mode"),
        "Choose whether to calculate required sample size or minimal detectable odds ratio",
        "right"
      ),
      hr(),
      create_segmented_power(
        ns("match_power"),
        "Desired Power:",
        selected = 80,
        tooltip = "Probability of detecting the effect if it exists"
      ),
      conditionalPanel(
        condition = paste0("input['", ns("match_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(
          ns("match_or"),
          "Odds Ratio (OR):",
          value = 2.0,
          min = 0.01,
          max = 20,
          step = 0.1,
          tooltip = "Expected odds ratio to detect (OR < 1 protective, OR > 1 risk factor)"
        )
      ),
      conditionalPanel(
        condition = paste0("input['", ns("match_calc_mode"), "'] == 'calc_effect'"),
        create_numeric_input_with_tooltip(
          ns("match_n_pairs_fixed"),
          "Available Number of Matched Pairs:",
          value = 100,
          min = 10,
          step = 5,
          tooltip = "Fixed number of matched case-control pairs available"
        )
      ),
      create_enhanced_slider(
        ns("match_p0"),
        "Exposure Probability in Controls (%):",
        min = 5, max = 95, value = 20, step = 5, post = "%",
        tooltip = "Expected proportion of controls exposed to the risk factor"
      ),
      create_numeric_input_with_tooltip(
        ns("match_ratio"),
        "Controls per Case:",
        value = 1,
        min = 1,
        max = 5,
        step = 1,
        tooltip = "Number of matched controls per case (typically 1:1, 2:1, or 3:1)"
      ),
      create_segmented_alpha(
        ns("match_alpha"),
        "Significance Level (α):",
        selected = 0.05,
        tooltip = "Type I error rate (typically 0.05)"
      ),
      radioButtons_fixed(
        ns("match_sided"),
        "Test Type:",
        choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
        selected = "two.sided"
      ),
      bsTooltip(ns("match_sided"), "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
      hr(),
      missing_data_ui(ns("missing_data")),
      hr(),
      h4("Clustering Adjustment"),
      clustering_ui(ns("clustering")),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_match"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_match"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 04_matched_case_control Server Functions
#'
#' @noRd
mod_04_matched_case_control_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Initialize missing data module
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Example button
    observeEvent(input$example_match, {
      updateRadioButtons(session, "match_calc_mode", selected = "calc_n")
      update_segmented_power(session, "match_power", value = 80)
      updateNumericInput(session, "match_or", value = 2.5)
      updateSliderInput(session, "match_p0", value = 30)
      updateNumericInput(session, "match_ratio", value = 1)
      update_segmented_alpha(session, "match_alpha", value = 0.05)
      updateRadioButtons(session, "match_sided", selected = "two.sided")
    })

    # Reset button
    observeEvent(input$reset_match, {
      updateRadioButtons(session, "match_calc_mode", selected = "calc_n")
      update_segmented_power(session, "match_power", value = 80)
      updateNumericInput(session, "match_or", value = 2.0)
      updateNumericInput(session, "match_n_pairs_fixed", value = 100)
      updateSliderInput(session, "match_p0", value = 20)
      updateNumericInput(session, "match_ratio", value = 1)
      update_segmented_alpha(session, "match_alpha", value = 0.05)
      updateRadioButtons(session, "match_sided", selected = "two.sided")
    })

    # Return reactive values
    list(
      inputs = reactive({
        list(
          match_calc_mode = input$match_calc_mode,
          match_power = input$match_power,
          match_or = input$match_or,
          match_n_pairs_fixed = input$match_n_pairs_fixed,
          match_p0 = input$match_p0,
          match_ratio = input$match_ratio,
          match_alpha = input$match_alpha,
          match_sided = input$match_sided
        )
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals
    )
  })
}
