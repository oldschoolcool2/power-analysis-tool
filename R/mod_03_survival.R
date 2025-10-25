#' 03_survival UI Function
#'
#' @description Survival Analysis (Cox Regression) power and sample size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr div actionButton icon radioButtons HTML
mod_03_survival_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PAGE 5: Survival Analysis - Power Analysis
    conditionalPanel(
      condition = "input.sidebar_page == 'power_survival'",
      h2(class = "page-title", "Survival Analysis (Cox): Power Analysis"),
      helpText("Calculate power for time-to-event outcomes using Cox regression (common in RWE studies)"),
      hr(),
      create_numeric_input_with_tooltip(
        ns("surv_pow_n"),
        "Total Sample Size:",
        value = 500,
        min = 10,
        step = 10,
        tooltip = "Total number of participants in the study"
      ),
      create_numeric_input_with_tooltip(
        ns("surv_pow_hr"),
        "Hazard Ratio (HR):",
        value = 0.7,
        min = 0.01,
        max = 10,
        step = 0.05,
        tooltip = "Expected hazard ratio (HR < 1 indicates protective effect, HR > 1 indicates risk)",
        validation_type = "hazard_ratio",
        help_content = HTML("
          <strong>Hazard Ratio (HR)</strong><br>
          Ratio of hazard rates between two groups in time-to-event analysis.<br><br>
          <strong>Interpretation:</strong><br>
          • HR = 1.0: No effect (equal hazard)<br>
          • HR < 1.0: Protective effect (e.g., 0.70 = 30% reduction)<br>
          • HR > 1.0: Increased risk (e.g., 1.50 = 50% increase)<br><br>
          <strong>Examples:</strong><br>
          <em>Cardiovascular trials:</em> HR = 0.75-0.85 (moderate)<br>
          <em>Oncology trials:</em> HR = 0.65-0.80 (typical)<br>
          <em>Minimal clinically important:</em> HR ≤ 0.85 or ≥ 1.15
        ")
      ),
      create_enhanced_slider(
        ns("surv_pow_k"),
        "Proportion Exposed (%):",
        min = 10, max = 90, value = 50, step = 5, post = "%",
        tooltip = "Proportion of participants in the exposed/treatment group"
      ),
      create_enhanced_slider(
        ns("surv_pow_pE"),
        "Overall Event Rate (%):",
        min = 5, max = 95, value = 30, step = 5, post = "%",
        tooltip = "Expected proportion of participants experiencing the event during follow-up"
      ),
      create_segmented_alpha(
        ns("surv_pow_alpha"),
        "Significance Level (α):",
        selected = 0.05,
        tooltip = "Type I error rate (typically 0.05)"
      ),
      hr(),
      h4("E-value Sensitivity Analysis"),
      evalue_ui(ns("evalue"), effect_type = "HR"),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_surv_pow"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_surv_pow"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    ),

    # PAGE 6: Survival Analysis - Sample Size
    conditionalPanel(
      condition = "input.sidebar_page == 'ss_survival'",
      h2(class = "page-title", "Survival Analysis (Cox): Sample Size Calculation"),
      helpText("Calculate required sample size OR minimal detectable hazard ratio"),
      hr(),
      radioButtons_fixed(
        ns("surv_ss_calc_mode"),
        "Calculation Mode:",
        choices = c(
          "Calculate Sample Size (given hazard ratio)" = "calc_n",
          "Calculate Hazard Ratio (given sample size)" = "calc_effect"
        ),
        selected = "calc_n"
      ),
      bsTooltip(
        ns("surv_ss_calc_mode"),
        "Choose whether to calculate required sample size or minimal detectable hazard ratio",
        "right"
      ),
      hr(),
      create_segmented_power(
        ns("surv_ss_power"),
        "Desired Power:",
        selected = 80,
        tooltip = "Probability of detecting the effect if it exists"
      ),
      conditionalPanel(
        condition = paste0("input['", ns("surv_ss_calc_mode"), "'] == 'calc_n'"),
        create_numeric_input_with_tooltip(
          ns("surv_ss_hr"),
          "Hazard Ratio (HR):",
          value = 0.7,
          min = 0.01,
          max = 10,
          step = 0.05,
          tooltip = "Expected hazard ratio to detect"
        )
      ),
      conditionalPanel(
        condition = paste0("input['", ns("surv_ss_calc_mode"), "'] == 'calc_effect'"),
        create_numeric_input_with_tooltip(
          ns("surv_ss_n_fixed"),
          "Available Sample Size:",
          value = 500,
          min = 10,
          step = 10,
          tooltip = "Fixed total sample size available for the study"
        )
      ),
      create_enhanced_slider(
        ns("surv_ss_k"),
        "Proportion Exposed (%):",
        min = 10, max = 90, value = 50, step = 5, post = "%",
        tooltip = "Proportion of participants in the exposed/treatment group"
      ),
      create_enhanced_slider(
        ns("surv_ss_pE"),
        "Overall Event Rate (%):",
        min = 5, max = 95, value = 30, step = 5, post = "%",
        tooltip = "Expected proportion of participants experiencing the event during follow-up"
      ),
      create_segmented_alpha(
        ns("surv_ss_alpha"),
        "Significance Level (α):",
        selected = 0.05,
        tooltip = "Type I error rate (typically 0.05)"
      ),
      hr(),
      missing_data_ui(ns("missing_data")),
      hr(),
      h4("Clustering Adjustment"),
      clustering_ui(ns("clustering")),
      hr(),
      h4("E-value Sensitivity Analysis"),
      evalue_ui(ns("evalue_ss"), effect_type = "HR"),
      hr(),
      div(class = "btn-group-custom",
        actionButton(ns("example_surv_ss"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_surv_ss"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 03_survival Server Functions
#'
#' @noRd
#'
#' @importFrom shiny observeEvent updateNumericInput updateSliderInput updateRadioButtons
#' @importFrom shiny reactive renderUI renderPlot req validate need isolate
mod_03_survival_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Initialize missing data module for sample size tab
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Initialize E-value modules
    evalue_vals_pow <- evalue_server("evalue", effect_type = "HR")
    evalue_vals_ss <- evalue_server("evalue_ss", effect_type = "HR")

    # Example button - Power Analysis
    observeEvent(input$example_surv_pow, {
      updateNumericInput(session, "surv_pow_n", value = 800)
      updateNumericInput(session, "surv_pow_hr", value = 0.65)
      updateSliderInput(session, "surv_pow_k", value = 50)
      updateSliderInput(session, "surv_pow_pE", value = 40)
      update_segmented_alpha(session, "surv_pow_alpha", value = 0.05)
    })

    # Reset button - Power Analysis
    observeEvent(input$reset_surv_pow, {
      updateNumericInput(session, "surv_pow_n", value = 500)
      updateNumericInput(session, "surv_pow_hr", value = 0.7)
      updateSliderInput(session, "surv_pow_k", value = 50)
      updateSliderInput(session, "surv_pow_pE", value = 30)
      update_segmented_alpha(session, "surv_pow_alpha", value = 0.05)
    })

    # Example button - Sample Size
    observeEvent(input$example_surv_ss, {
      updateRadioButtons(session, "surv_ss_calc_mode", selected = "calc_n")
      update_segmented_power(session, "surv_ss_power", value = 90)
      updateNumericInput(session, "surv_ss_hr", value = 0.65)
      updateSliderInput(session, "surv_ss_k", value = 50)
      updateSliderInput(session, "surv_ss_pE", value = 40)
      update_segmented_alpha(session, "surv_ss_alpha", value = 0.05)
    })

    # Reset button - Sample Size
    observeEvent(input$reset_surv_ss, {
      updateRadioButtons(session, "surv_ss_calc_mode", selected = "calc_n")
      update_segmented_power(session, "surv_ss_power", value = 80)
      updateNumericInput(session, "surv_ss_hr", value = 0.7)
      updateNumericInput(session, "surv_ss_n_fixed", value = 500)
      updateSliderInput(session, "surv_ss_k", value = 50)
      updateSliderInput(session, "surv_ss_pE", value = 30)
      update_segmented_alpha(session, "surv_ss_alpha", value = 0.05)
    })

    # Return reactive values
    list(
      inputs = reactive({
        list(
          # Power analysis inputs
          surv_pow_n = input$surv_pow_n,
          surv_pow_hr = input$surv_pow_hr,
          surv_pow_k = input$surv_pow_k,
          surv_pow_pE = input$surv_pow_pE,
          surv_pow_alpha = input$surv_pow_alpha,
          # Sample size inputs
          surv_ss_calc_mode = input$surv_ss_calc_mode,
          surv_ss_power = input$surv_ss_power,
          surv_ss_hr = input$surv_ss_hr,
          surv_ss_n_fixed = input$surv_ss_n_fixed,
          surv_ss_k = input$surv_ss_k,
          surv_ss_pE = input$surv_ss_pE,
          surv_ss_alpha = input$surv_ss_alpha
        )
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      evalue_vals_pow = evalue_vals_pow,
      evalue_vals_ss = evalue_vals_ss
    )
  })
}
