#' 04_matched_case_control UI Function
#'
#' @description Matched Case-Control Study power, sample size, and effect size analysis
#'
#' @param id Module namespace ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 h4 helpText hr div actionButton icon radioButtons HTML tabsetPanel tabPanel br
mod_04_matched_case_control_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PAGE 7: Matched Case-Control
    conditionalPanel(
      condition = "input.sidebar_page == 'match_casecontrol'",
      h2(class = "page-title", "Matched Case-Control Study"),
      helpText("Comprehensive power, sample size, and effect size analysis for matched designs"),
      hr(),

      # Modern tabbed interface for different analysis types
      tabsetPanel(
        id = ns("match_analysis_type"),
        type = "pills",
        selected = "sample_size",  # Set default tab

        # TAB 1: Sample Size Calculation
        tabPanel(
          title = "Sample Size",
          value = "sample_size",
          icon = icon("calculator"),
          br(),
          h4("Calculate Required Sample Size"),
          helpText("Determine the number of matched pairs needed to detect a specified odds ratio with desired power"),
          hr(),

          create_segmented_power(
            ns("match_power_ss"),
            "Desired Power:",
            selected = 80,
            tooltip = "Probability of detecting the effect if it exists (typically 80% or 90%)"
          ),

          create_numeric_input_with_tooltip(
            ns("match_or_ss"),
            "Target Odds Ratio (OR):",
            value = 2.0,
            min = 0.01,
            max = 20,
            step = 0.1,
            tooltip = "Expected odds ratio to detect (OR < 1 protective, OR > 1 risk factor)",
            validation_type = "odds_ratio",
            help_content = HTML("
              <strong>Odds Ratio (OR)</strong><br>
              Measure of association between exposure and outcome in case-control studies.<br><br>
              <strong>Interpretation:</strong><br>
              • OR = 1.0: No association<br>
              • OR < 1.0: Protective factor (e.g., 0.50 = 50% lower odds)<br>
              • OR > 1.0: Risk factor (e.g., 2.0 = 2× higher odds)<br><br>
              <strong>Examples:</strong><br>
              <em>Smoking & lung cancer:</em> OR = 10-20 (strong)<br>
              <em>Diet & diabetes:</em> OR = 1.5-2.0 (moderate)<br>
              <em>Vaccine protection:</em> OR = 0.3-0.6 (protective)<br><br>
              <strong>Note:</strong> OR approximates relative risk when outcome is rare (<10%)
            ")
          ),

          create_enhanced_slider(
            ns("match_p0_ss"),
            "Exposure Probability in Controls (%):",
            min = 5, max = 95, value = 20, step = 5, post = "%",
            tooltip = "Expected proportion of controls exposed to the risk factor"
          )
        ),

        # TAB 2: Power Analysis (NEW!)
        tabPanel(
          title = "Power Analysis",
          value = "power",
          icon = icon("chart-line"),
          br(),
          h4("Calculate Statistical Power"),
          helpText("Determine the power given available sample size and expected effect size"),
          hr(),

          create_numeric_input_with_tooltip(
            ns("match_n_pairs_power"),
            "Available Number of Matched Pairs:",
            value = 100,
            min = 10,
            step = 5,
            tooltip = "Number of matched case-control pairs available for the study"
          ),

          create_numeric_input_with_tooltip(
            ns("match_or_power"),
            "Expected Odds Ratio (OR):",
            value = 2.0,
            min = 0.01,
            max = 20,
            step = 0.1,
            tooltip = "Anticipated effect size to detect (OR < 1 protective, OR > 1 risk factor)",
            validation_type = "odds_ratio",
            help_content = HTML("
              <strong>Odds Ratio (OR)</strong><br>
              Measure of association between exposure and outcome in case-control studies.<br><br>
              <strong>Interpretation:</strong><br>
              • OR = 1.0: No association<br>
              • OR < 1.0: Protective factor (e.g., 0.50 = 50% lower odds)<br>
              • OR > 1.0: Risk factor (e.g., 2.0 = 2× higher odds)<br><br>
              <strong>Examples:</strong><br>
              <em>Smoking & lung cancer:</em> OR = 10-20 (strong)<br>
              <em>Diet & diabetes:</em> OR = 1.5-2.0 (moderate)<br>
              <em>Vaccine protection:</em> OR = 0.3-0.6 (protective)<br><br>
              <strong>Note:</strong> OR approximates relative risk when outcome is rare (<10%)
            ")
          ),

          create_enhanced_slider(
            ns("match_p0_power"),
            "Exposure Probability in Controls (%):",
            min = 5, max = 95, value = 20, step = 5, post = "%",
            tooltip = "Expected proportion of controls exposed to the risk factor"
          )
        ),

        # TAB 3: Minimal Detectable Effect
        tabPanel(
          title = "Detectable Effect",
          value = "mde",
          icon = icon("bullseye"),
          br(),
          h4("Calculate Minimal Detectable Odds Ratio"),
          helpText("Determine the smallest effect size detectable with available sample and desired power"),
          hr(),

          create_numeric_input_with_tooltip(
            ns("match_n_pairs_mde"),
            "Available Number of Matched Pairs:",
            value = 100,
            min = 10,
            step = 5,
            tooltip = "Fixed number of matched case-control pairs available for the study"
          ),

          create_segmented_power(
            ns("match_power_mde"),
            "Desired Power:",
            selected = 80,
            tooltip = "Probability of detecting the effect if it exists (typically 80% or 90%)"
          ),

          create_enhanced_slider(
            ns("match_p0_mde"),
            "Exposure Probability in Controls (%):",
            min = 5, max = 95, value = 20, step = 5, post = "%",
            tooltip = "Expected proportion of controls exposed to the risk factor"
          )
        )
      ),

      # Common parameters section (applies to all analysis types)
      hr(),
      h4("Common Parameters"),
      helpText("These parameters apply to all analysis types above"),

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

      bslib::tooltip(
        radioButtons_fixed(
          ns("match_sided"),
          "Test Type:",
          choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
          selected = "two.sided"
        ),
        "Two-sided: test if groups differ. One-sided: test directional hypothesis",
        placement = "right"
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
        actionButton(ns("example_match"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_match"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' 04_matched_case_control Server Functions
#'
#' @noRd
#' @importFrom shiny req
mod_04_matched_case_control_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Initialize missing data module
    missing_data_vals <- missing_data_server("missing_data")
    clustering_vals <- clustering_server("clustering")

    # Initialize multiple testing module
    multiple_testing_vals <- multiple_testing_server("multiple_testing")

    # Example button - updates based on active tab
    observeEvent(input$example_match, {
      # Guard against NULL or invalid analysis type
      req(input$match_analysis_type)

      if (isTRUE(input$match_analysis_type == "sample_size")) {
        updateRadioButtons(session, "match_power_ss", selected = "80")
        updateNumericInput(session, "match_or_ss", value = 2.5)
        updateSliderInput(session, "match_p0_ss", value = 30)
      } else if (isTRUE(input$match_analysis_type == "power")) {
        updateNumericInput(session, "match_n_pairs_power", value = 100)
        updateNumericInput(session, "match_or_power", value = 2.5)
        updateSliderInput(session, "match_p0_power", value = 30)
      } else if (isTRUE(input$match_analysis_type == "mde")) {
        updateNumericInput(session, "match_n_pairs_mde", value = 100)
        updateRadioButtons(session, "match_power_mde", selected = "80")
        updateSliderInput(session, "match_p0_mde", value = 30)
      }

      # Common parameters
      updateNumericInput(session, "match_ratio", value = 1)
      updateRadioButtons(session, "match_alpha", selected = "0.05")
      updateRadioButtons(session, "match_sided", selected = "two.sided")
    })

    # Reset button - resets based on active tab
    observeEvent(input$reset_match, {
      # Guard against NULL or invalid analysis type
      req(input$match_analysis_type)

      if (isTRUE(input$match_analysis_type == "sample_size")) {
        updateRadioButtons(session, "match_power_ss", selected = "80")
        updateNumericInput(session, "match_or_ss", value = 2.0)
        updateSliderInput(session, "match_p0_ss", value = 20)
      } else if (isTRUE(input$match_analysis_type == "power")) {
        updateNumericInput(session, "match_n_pairs_power", value = 100)
        updateNumericInput(session, "match_or_power", value = 2.0)
        updateSliderInput(session, "match_p0_power", value = 20)
      } else if (isTRUE(input$match_analysis_type == "mde")) {
        updateNumericInput(session, "match_n_pairs_mde", value = 100)
        updateRadioButtons(session, "match_power_mde", selected = "80")
        updateSliderInput(session, "match_p0_mde", value = 20)
      }

      # Common parameters
      updateNumericInput(session, "match_ratio", value = 1)
      updateRadioButtons(session, "match_alpha", selected = "0.05")
      updateRadioButtons(session, "match_sided", selected = "two.sided")
    })

    # Return reactive values based on active tab
    list(
      inputs = reactive({
        # Determine analysis mode from active tab (with fallback to sample_size)
        analysis_type <- if (is.null(input$match_analysis_type) || input$match_analysis_type == "") {
          "sample_size"
        } else {
          input$match_analysis_type
        }

        # Base list with common parameters (with safe defaults)
        result <- list(
          match_analysis_type = analysis_type,
          match_ratio = if (!is.null(input$match_ratio)) as.numeric(input$match_ratio) else 1,
          match_alpha = if (!is.null(input$match_alpha)) as.numeric(input$match_alpha) else 0.05,
          match_sided = if (!is.null(input$match_sided)) input$match_sided else "two.sided"
        )

        # Add tab-specific parameters
        if (analysis_type == "sample_size") {
          result$match_power <- if (!is.null(input$match_power_ss)) as.numeric(input$match_power_ss) else 80
          result$match_or <- if (!is.null(input$match_or_ss)) as.numeric(input$match_or_ss) else 2.0
          result$match_p0 <- if (!is.null(input$match_p0_ss)) as.numeric(input$match_p0_ss) else 20
          result$match_calc_mode <- "calc_n"  # For backward compatibility
        } else if (analysis_type == "power") {
          result$match_n_pairs <- if (!is.null(input$match_n_pairs_power)) as.numeric(input$match_n_pairs_power) else 100
          result$match_or <- if (!is.null(input$match_or_power)) as.numeric(input$match_or_power) else 2.0
          result$match_p0 <- if (!is.null(input$match_p0_power)) as.numeric(input$match_p0_power) else 20
          result$match_calc_mode <- "calc_power"  # New mode
        } else if (analysis_type == "mde") {
          result$match_n_pairs <- if (!is.null(input$match_n_pairs_mde)) as.numeric(input$match_n_pairs_mde) else 100
          result$match_power <- if (!is.null(input$match_power_mde)) as.numeric(input$match_power_mde) else 80
          result$match_p0 <- if (!is.null(input$match_p0_mde)) as.numeric(input$match_p0_mde) else 20
          result$match_calc_mode <- "calc_effect"  # For backward compatibility
        }

        result
      }),
      missing_data_vals = missing_data_vals,
      clustering_vals = clustering_vals,
      multiple_testing_vals = multiple_testing_vals
    )
  })
}
