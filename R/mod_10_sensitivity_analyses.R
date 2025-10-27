#' Sensitivity Analyses Module
#'
#' A module for post-hoc sensitivity analyses techniques used in the report phase
#' of research. This module currently includes E-value sensitivity analysis for
#' assessing robustness of effect estimates to unmeasured confounding.
#'
#' Unlike power/sample size modules (protocol phase), sensitivity analyses are
#' conducted after data collection to evaluate the robustness of findings.

#' Sensitivity Analyses UI Function
#'
#' @description A Shiny module for sensitivity analyses in the report phase
#'
#' @param id Character string. Module namespace ID.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList conditionalPanel h2 h3 h4 hr helpText p strong div actionButton icon
mod_10_sensitivity_analyses_ui <- function(id){
  ns <- NS(id)
  tagList(

    # ============================================================
    # MULTIPLE BIAS SENSITIVITY ANALYSIS
    # ============================================================

    conditionalPanel(
      condition = "input.sidebar_page == 'sensitivity_multi_bias'",
      h2(class = "page-title", "Multiple-Bias Sensitivity Analysis"),

      helpText(
        "Multiple-bias sensitivity analysis assesses the joint impact of unmeasured confounding, ",
        "selection bias, and differential misclassification. This analysis is performed in the ",
        strong("report phase"), " after data collection to evaluate how combinations of biases ",
        "could affect your observed findings."
      ),

      hr(),

      multi_bias_ui(ns("multi_bias")),

      hr(),

      div(
        class = "alert alert-info",
        style = "margin-top: 20px;",
        tags$strong(icon("info-circle"), " When to Use Multiple-Bias Analysis:"),
        tags$ul(
          tags$li(strong("Report Phase:"), "After completing your analysis and obtaining effect estimates"),
          tags$li(strong("Multiple Threats:"), "When your study may be affected by more than one type of bias"),
          tags$li(strong("Comprehensive Assessment:"), "To understand how combinations of biases work together"),
          tags$li(strong("Realistic Scenarios:"), "Studies are rarely affected by just one bias in isolation")
        ),
        tags$p(
          style = "margin-top: 10px;",
          strong("Note:"), " Multi-bias E-values represent the minimum value that ",
          strong("all"), " bias parameters must take on simultaneously to explain away your results."
        )
      ),

      hr(),

      div(class = "btn-group-custom",
        actionButton(ns("example_multi_bias"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_multi_bias"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    ),

    # ============================================================
    # E-VALUE SENSITIVITY ANALYSIS
    # ============================================================

    conditionalPanel(
      condition = "input.sidebar_page == 'sensitivity_evalue'",
      h2(class = "page-title", "E-value Sensitivity Analysis"),

      helpText(
        "E-values assess the robustness of your effect estimates to potential unmeasured confounding. ",
        "This analysis is typically performed in the ", strong("report phase"), " after data collection and analysis, ",
        "to evaluate how strong an unmeasured confounder would need to be to explain away your observed findings."
      ),

      hr(),

      h3("Select Effect Measure Type"),

      helpText(
        "Choose the type of effect measure you want to assess for sensitivity to unmeasured confounding:"
      ),

      bslib::tooltip(
        radioButtons(
          ns("effect_type"),
          "Effect Measure:",
          choices = c(
            "Relative Risk (RR)" = "RR",
            "Odds Ratio (OR)" = "OR",
            "Hazard Ratio (HR)" = "HR",
            "Mean Difference (MD)" = "MD"
          ),
          selected = "RR"
        ),
        "Select the type of effect estimate you want to evaluate. Different effect measures require different E-value calculations.",
        placement = "right"
      ),

      hr(),

      # Conditional E-value UI based on effect type
      conditionalPanel(
        condition = sprintf("input['%s'] == 'RR'", ns("effect_type")),
        h3("Relative Risk (RR) E-value"),
        helpText("Use this when your analysis reported a relative risk (common in cohort studies and RCTs)."),
        evalue_ui(ns("evalue_rr"), effect_type = "RR")
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'OR'", ns("effect_type")),
        h3("Odds Ratio (OR) E-value"),
        helpText("Use this when your analysis reported an odds ratio (common in case-control studies and logistic regression)."),
        evalue_ui(ns("evalue_or"), effect_type = "OR")
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'HR'", ns("effect_type")),
        h3("Hazard Ratio (HR) E-value"),
        helpText("Use this when your analysis reported a hazard ratio (common in survival analysis and Cox regression)."),
        evalue_ui(ns("evalue_hr"), effect_type = "HR")
      ),

      conditionalPanel(
        condition = sprintf("input['%s'] == 'MD'", ns("effect_type")),
        h3("Mean Difference (MD) E-value"),
        helpText("Use this when your analysis reported a mean difference (common in continuous outcome analyses)."),
        evalue_ui(ns("evalue_md"), effect_type = "MD")
      ),

      hr(),

      div(
        class = "alert alert-info",
        style = "margin-top: 20px;",
        tags$strong(icon("info-circle"), " When to Use E-values:"),
        tags$ul(
          tags$li(strong("Report Phase:"), "After completing your analysis and obtaining effect estimates"),
          tags$li(strong("Sensitivity Analysis:"), "To assess robustness of findings to unmeasured confounding"),
          tags$li(strong("Observational Studies:"), "Particularly important when randomization is not possible"),
          tags$li(strong("Publication:"), "Many journals now request E-values for observational research")
        ),
        tags$p(
          style = "margin-top: 10px;",
          strong("Note:"), " E-values do NOT replace good study design. They help quantify how strong ",
          "unmeasured confounding would need to be to explain away your results."
        )
      ),

      hr(),

      div(class = "btn-group-custom",
        actionButton(ns("example_evalue"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
        actionButton(ns("reset_evalue"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
      )
    )
  )
}

#' Sensitivity Analyses Server Functions
#'
#' @noRd
#'
#' @importFrom shiny moduleServer observeEvent updateRadioButtons updateCheckboxInput
mod_10_sensitivity_analyses_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Initialize Multi-Bias module
    multi_bias_vals <- multi_bias_server("multi_bias")

    # Initialize E-value modules for each effect type
    evalue_vals_rr <- evalue_server("evalue_rr", effect_type = "RR")
    evalue_vals_or <- evalue_server("evalue_or", effect_type = "OR")
    evalue_vals_hr <- evalue_server("evalue_hr", effect_type = "HR")
    evalue_vals_md <- evalue_server("evalue_md", effect_type = "MD")

    # Load Example button for Multi-Bias Analysis
    observeEvent(input$example_multi_bias, {
      # Example: Study with potential confounding and selection bias
      # RR = 3.0 (95% CI: 2.0, 4.5)
      session$sendInputMessage("multi_bias-include_confounding", list(value = TRUE))
      session$sendInputMessage("multi_bias-include_selection", list(value = TRUE))
      session$sendInputMessage("multi_bias-include_misclass", list(value = FALSE))
      session$sendInputMessage("multi_bias-selection_type", list(value = "general"))
      session$sendInputMessage("multi_bias-rr", list(value = 3.0))
      session$sendInputMessage("multi_bias-include_ci", list(value = TRUE))
      session$sendInputMessage("multi_bias-ci_lower", list(value = 2.0))
      session$sendInputMessage("multi_bias-ci_upper", list(value = 4.5))
      session$sendInputMessage("multi_bias-analysis_type", list(value = "evalue"))
    })

    # Reset button for Multi-Bias Analysis
    observeEvent(input$reset_multi_bias, {
      session$sendInputMessage("multi_bias-include_confounding", list(value = TRUE))
      session$sendInputMessage("multi_bias-include_selection", list(value = FALSE))
      session$sendInputMessage("multi_bias-include_misclass", list(value = FALSE))
      session$sendInputMessage("multi_bias-rr", list(value = 3.0))
      session$sendInputMessage("multi_bias-include_ci", list(value = FALSE))
      session$sendInputMessage("multi_bias-analysis_type", list(value = "evalue"))
    })

    # Load Example button - uses classic smoking-lung cancer example from VanderWeele & Ding (2017)
    observeEvent(input$example_evalue, {
      # Get current effect type
      current_type <- input$effect_type

      # Load example based on current effect type
      if (current_type == "RR") {
        # Example: Smoking and lung cancer (Wynder & Graham, 1950)
        # RR = 10.73 (95% CI: 8.02, 14.36)
        session$sendInputMessage("evalue_rr-calculate_evalue", list(value = TRUE))
        session$sendInputMessage("evalue_rr-effect_estimate", list(value = 10.73))
        session$sendInputMessage("evalue_rr-include_ci", list(value = TRUE))
        session$sendInputMessage("evalue_rr-ci_lower", list(value = 8.02))
        session$sendInputMessage("evalue_rr-ci_upper", list(value = 14.36))
      } else if (current_type == "OR") {
        # Example: Breastfeeding and infant death by respiratory infection
        # OR = 3.9 (95% CI: 1.8, 8.7)
        session$sendInputMessage("evalue_or-calculate_evalue", list(value = TRUE))
        session$sendInputMessage("evalue_or-effect_estimate", list(value = 3.9))
        session$sendInputMessage("evalue_or-include_ci", list(value = TRUE))
        session$sendInputMessage("evalue_or-ci_lower", list(value = 1.8))
        session$sendInputMessage("evalue_or-ci_upper", list(value = 8.7))
        session$sendInputMessage("evalue_or-outcome_rare", list(value = TRUE))
      } else if (current_type == "HR") {
        # Example: Treatment effect on survival
        # HR = 1.8 (95% CI: 1.3, 2.5)
        session$sendInputMessage("evalue_hr-calculate_evalue", list(value = TRUE))
        session$sendInputMessage("evalue_hr-effect_estimate", list(value = 1.8))
        session$sendInputMessage("evalue_hr-include_ci", list(value = TRUE))
        session$sendInputMessage("evalue_hr-ci_lower", list(value = 1.3))
        session$sendInputMessage("evalue_hr-ci_upper", list(value = 2.5))
        session$sendInputMessage("evalue_hr-outcome_rare", list(value = TRUE))
      } else if (current_type == "MD") {
        # Example: Mean difference in blood pressure
        # MD = 0.5 (SE = 0.1)
        session$sendInputMessage("evalue_md-calculate_evalue", list(value = TRUE))
        session$sendInputMessage("evalue_md-effect_estimate", list(value = 0.5))
        session$sendInputMessage("evalue_md-include_ci", list(value = TRUE))
        session$sendInputMessage("evalue_md-ci_lower", list(value = 0.3))
        session$sendInputMessage("evalue_md-ci_upper", list(value = 0.7))
        session$sendInputMessage("evalue_md-md_se", list(value = 0.1))
      }
    })

    # Reset button
    observeEvent(input$reset_evalue, {
      # Reset to RR as default
      updateRadioButtons(session, "effect_type", selected = "RR")

      # Note: The evalue module handles its own resets via checkbox state
      # We could add explicit reset logic here if needed in the future
    })

    # Return reactive values if needed by parent app
    return(
      reactive({
        list(
          multi_bias = multi_bias_vals(),
          effect_type = input$effect_type,
          evalue_rr = evalue_vals_rr(),
          evalue_or = evalue_vals_or(),
          evalue_hr = evalue_vals_hr(),
          evalue_md = evalue_vals_md()
        )
      })
    )
  })
}
