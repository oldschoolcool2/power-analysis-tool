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
#' @importFrom shinyBS bsTooltip
mod_10_sensitivity_analyses_ui <- function(id){
  ns <- NS(id)
  tagList(

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
      bsTooltip(
        ns("effect_type"),
        "Select the type of effect estimate you want to evaluate. Different effect measures require different E-value calculations.",
        "right"
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

    # Initialize E-value modules for each effect type
    evalue_vals_rr <- evalue_server("evalue_rr", effect_type = "RR")
    evalue_vals_or <- evalue_server("evalue_or", effect_type = "OR")
    evalue_vals_hr <- evalue_server("evalue_hr", effect_type = "HR")
    evalue_vals_md <- evalue_server("evalue_md", effect_type = "MD")

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
