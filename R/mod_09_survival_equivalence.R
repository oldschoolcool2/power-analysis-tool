#' 09_survival_equivalence UI Function
#'
#' @description Time-to-Event Equivalence/Non-Inferiority Testing
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 h4 helpText hr div actionButton icon radioButtons HTML
mod_09_survival_equivalence_ui <- function(id) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = "input.sidebar_page == 'survival_ni_equiv'",
      h2(class = "page-title", "Time-to-Event Equivalence/Non-Inferiority Testing"),
      helpText("Calculate sample size or margin for equivalence or non-inferiority studies with time-to-event outcomes"),
      hr(),

      # Test Type Selection
      radioButtons_fixed(
        ns("test_type"),
        "Test Type:",
        choices = c(
          "Non-Inferiority (one-sided)" = "non-inferiority",
          "Equivalence (two one-sided tests)" = "equivalence"
        ),
        selected = "non-inferiority"
      ),
      bsTooltip(
        ns("test_type"),
        "Non-inferiority tests if new treatment is not worse than margin. Equivalence tests if treatments are similar within margins.",
        "right"
      ),
      hr(),

      # Calculation Mode
      radioButtons_fixed(
        ns("calc_mode"),
        "Calculation Mode:",
        choices = c(
          "Calculate Sample Size (given margin)" = "calc_n",
          "Calculate Margin (given sample size)" = "calc_margin"
        ),
        selected = "calc_n"
      ),
      bsTooltip(
        ns("calc_mode"),
        "Choose whether to calculate required sample size or minimal detectable margin",
        "right"
      ),
      hr(),

      # Power (always shown)
      create_segmented_power(
        ns("power"),
        "Desired Power:",
        selected = 80,
        tooltip = "Probability of demonstrating non-inferiority/equivalence if true"
      ),

      # Expected HR
      create_numeric_input_with_tooltip(
        ns("hr_expected"),
        "Expected Hazard Ratio (HR):",
        value = 0.95,
        min = 0.01,
        max = 10,
        step = 0.05,
        tooltip = "Expected true hazard ratio. For NI, typically close to 1.0 (e.g., 0.90-1.0). For equivalence, should be near 1.0.",
        validation_type = "hazard_ratio",
        help_content = HTML("
          <strong>Expected Hazard Ratio</strong><br>
          The true HR you expect to observe in your study.<br><br>
          <strong>Guidance:</strong><br>
          • For NI studies: Often 0.90-1.0 (assuming new treatment slightly better or equal)<br>
          • For equivalence: Should be very close to 1.0 (e.g., 0.95-1.05)<br>
          • Must be better than the margin to demonstrate NI/equivalence
        ")
      ),

      # Margin inputs (conditional on mode and test type)
      conditionalPanel(
        condition = paste0("input['", ns("calc_mode"), "'] == 'calc_n' && input['", ns("test_type"), "'] == 'non-inferiority'"),
        create_numeric_input_with_tooltip(
          ns("hr_margin_ni"),
          "Non-Inferiority Margin (HR):",
          value = 1.25,
          min = 1.0,
          max = 3.0,
          step = 0.05,
          tooltip = "Maximum acceptable HR (upper bound). Typical values: 1.15 (stringent) to 1.50 (liberal)",
          help_content = HTML("
            <strong>Non-Inferiority Margin</strong><br>
            The maximum HR you are willing to accept as 'non-inferior'.<br><br>
            <strong>Common values:</strong><br>
            • HR = 1.15: Very stringent (15% increase acceptable)<br>
            • HR = 1.25: Stringent (25% increase acceptable)<br>
            • HR = 1.33: Moderate (33% increase acceptable)<br>
            • HR = 1.50: Liberal (50% increase acceptable)<br><br>
            <strong>Regulatory context:</strong><br>
            FDA/EMA often expect margins justified by clinical importance, typically 1.15-1.25 for cardiovascular outcomes.
          ")
        )
      ),

      conditionalPanel(
        condition = paste0("input['", ns("calc_mode"), "'] == 'calc_n' && input['", ns("test_type"), "'] == 'equivalence'"),
        create_numeric_input_with_tooltip(
          ns("hr_margin_equiv"),
          "Equivalence Margin (HR):",
          value = 1.20,
          min = 1.0,
          max = 2.0,
          step = 0.05,
          tooltip = "Equivalence margins will be [1/margin, margin]. E.g., 1.20 gives [0.83, 1.20]",
          help_content = HTML("
            <strong>Equivalence Margin</strong><br>
            Defines the equivalence region as [1/margin, margin].<br><br>
            <strong>Examples:</strong><br>
            • Margin = 1.15: Equivalence region [0.87, 1.15]<br>
            • Margin = 1.20: Equivalence region [0.83, 1.20]<br>
            • Margin = 1.25: Equivalence region [0.80, 1.25]<br><br>
            Narrower regions are more stringent.
          ")
        )
      ),

      # Sample size input (for margin calculation mode)
      conditionalPanel(
        condition = paste0("input['", ns("calc_mode"), "'] == 'calc_margin'"),
        create_numeric_input_with_tooltip(
          ns("n_fixed"),
          "Available Sample Size:",
          value = 500,
          min = 50,
          step = 10,
          tooltip = "Total sample size available for the study"
        )
      ),

      # Common parameters
      create_enhanced_slider(
        ns("prop_exposed"),
        "Proportion Exposed/Treated (%):",
        min = 10,
        max = 90,
        value = 50,
        step = 5,
        post = "%",
        tooltip = "Proportion of participants in the test/new treatment group"
      ),

      create_enhanced_slider(
        ns("event_rate"),
        "Overall Event Rate (%):",
        min = 5,
        max = 95,
        value = 30,
        step = 5,
        post = "%",
        tooltip = "Expected proportion of participants experiencing the event during follow-up"
      ),

      create_numeric_input_with_tooltip(
        ns("allocation_ratio"),
        "Allocation Ratio (n2/n1):",
        value = 1,
        min = 0.1,
        max = 10,
        step = 0.1,
        tooltip = "Ratio of Reference to Test group size. 1 = equal groups, 2 = twice as many in reference group"
      ),

      create_segmented_alpha(
        ns("alpha"),
        "Significance Level (α):",
        choices = c("0.01" = 0.01, "0.025" = 0.025, "0.05" = 0.05, "0.10" = 0.10),
        selected = 0.025,
        tooltip = "Type I error rate. Typically 0.025 for one-sided NI test, 0.05 for equivalence (TOST)"
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
        actionButton(ns("example"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 09_survival_equivalence Server Functions
#'
#' @noRd
#'
#' @importFrom shiny observeEvent updateNumericInput updateSliderInput updateRadioButtons
#' @importFrom shiny reactive moduleServer
mod_09_survival_equivalence_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Initialize modules
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    # Example button
    observeEvent(input$example, {
      updateRadioButtons(session, "test_type", selected = "non-inferiority")
      updateRadioButtons(session, "calc_mode", selected = "calc_n")
      update_segmented_power(session, "power", value = 80)
      updateNumericInput(session, "hr_expected", value = 0.95)
      updateNumericInput(session, "hr_margin_ni", value = 1.25)
      updateSliderInput(session, "prop_exposed", value = 50)
      updateSliderInput(session, "event_rate", value = 40)
      updateNumericInput(session, "allocation_ratio", value = 1)
      update_segmented_alpha(session, "alpha", value = 0.025)
    })

    # Reset button
    observeEvent(input$reset, {
      updateRadioButtons(session, "test_type", selected = "non-inferiority")
      updateRadioButtons(session, "calc_mode", selected = "calc_n")
      update_segmented_power(session, "power", value = 80)
      updateNumericInput(session, "hr_expected", value = 0.95)
      updateNumericInput(session, "hr_margin_ni", value = 1.25)
      updateNumericInput(session, "hr_margin_equiv", value = 1.20)
      updateNumericInput(session, "n_fixed", value = 500)
      updateSliderInput(session, "prop_exposed", value = 50)
      updateSliderInput(session, "event_rate", value = 30)
      updateNumericInput(session, "allocation_ratio", value = 1)
      update_segmented_alpha(session, "alpha", value = 0.025)
    })

    # Return reactive values
    list(
      inputs = reactive({
        list(
          test_type = input$test_type,
          calc_mode = input$calc_mode,
          power = as.numeric(input$power),
          hr_expected = as.numeric(input$hr_expected),
          hr_margin_ni = as.numeric(input$hr_margin_ni),
          hr_margin_equiv = as.numeric(input$hr_margin_equiv),
          n_fixed = as.numeric(input$n_fixed),
          prop_exposed = as.numeric(input$prop_exposed),
          event_rate = as.numeric(input$event_rate),
          allocation_ratio = as.numeric(input$allocation_ratio),
          alpha = as.numeric(input$alpha)
        )
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals,
      evalue_vals = evalue_vals
    )
  })
}
