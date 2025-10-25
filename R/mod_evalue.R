#' E-value Sensitivity Analysis Module
#'
#' A reusable Shiny module for E-value sensitivity analysis UI and calculations.
#' E-values quantify the minimum strength of association that an unmeasured
#' confounder would need to have with both the treatment and outcome to fully
#' explain away an observed association.
#'
#' This module helps researchers assess the robustness of their planned effect
#' sizes to potential unmeasured confounding during study design.
#'
#' Usage:
#'   UI:   evalue_ui(NS(id, "evalue"))
#'   Server: evalue_values <- evalue_server(id, "evalue", effect_type)
#'
#' @param effect_type One of: "RR" (relative risk), "OR" (odds ratio),
#'                    "HR" (hazard ratio), "MD" (mean difference)
#'
#' Returns: Reactive list with E-value parameters and results
#'
#' Statistical Background:
#'   E-value = minimum strength of confounder-exposure and confounder-outcome
#'   associations (on RR scale) needed to explain away the observed effect.
#'
#'   Interpretation:
#'     - E-value < 1.5: Weak robustness (minor confounding could explain away effect)
#'     - E-value 1.5-2.0: Moderate robustness
#'     - E-value > 2.0: Strong robustness
#'     - E-value > 3.0: Very strong robustness
#'
#' @references
#' VanderWeele, T.J., & Ding, P. (2017). Sensitivity Analysis in Observational
#' Research: Introducing the E-Value. Annals of Internal Medicine, 167(4):268-274.

# UI Function ----
evalue_ui <- function(id, effect_type = "RR") {
  ns <- NS(id)

  # Determine appropriate labels based on effect type
  if (effect_type == "RR") {
    effect_label <- "Relative Risk (RR):"
    effect_tooltip <- "The relative risk you plan to detect or have observed. RR > 1 indicates increased risk, RR < 1 indicates protective effect."
    null_value <- 1
  } else if (effect_type == "OR") {
    effect_label <- "Odds Ratio (OR):"
    effect_tooltip <- "The odds ratio you plan to detect or have observed. OR > 1 indicates increased odds, OR < 1 indicates reduced odds."
    null_value <- 1
  } else if (effect_type == "HR") {
    effect_label <- "Hazard Ratio (HR):"
    effect_tooltip <- "The hazard ratio you plan to detect or have observed. HR > 1 indicates increased hazard, HR < 1 indicates reduced hazard."
    null_value <- 1
  } else if (effect_type == "MD") {
    effect_label <- "Mean Difference:"
    effect_tooltip <- "The mean difference (standardized or unstandardized) you plan to detect or have observed."
    null_value <- 0
  } else {
    effect_label <- "Effect Estimate:"
    effect_tooltip <- "The effect size you plan to detect or have observed."
    null_value <- 1
  }

  tagList(
    checkboxInput(
      ns("calculate_evalue"),
      "Calculate E-value Sensitivity Analysis",
      value = FALSE
    ),
    conditionalPanel(
      condition = sprintf("input['%s']", ns("calculate_evalue")),

      helpText(
        "E-values assess how robust your effect estimate is to potential unmeasured confounding. ",
        "Higher E-values indicate greater robustness."
      ),

      # Effect estimate input (ratio measures)
      if (effect_type %in% c("RR", "OR", "HR")) {
        create_numeric_input_with_tooltip(
          ns("effect_estimate"),
          effect_label,
          value = 2.0,
          min = 0.01,
          max = 20,
          step = 0.1,
          tooltip = effect_tooltip
        )
      } else {
        # Mean difference
        create_numeric_input_with_tooltip(
          ns("effect_estimate"),
          effect_label,
          value = 0.5,
          min = -10,
          max = 10,
          step = 0.1,
          tooltip = effect_tooltip
        )
      },

      # Optional: Confidence interval
      checkboxInput(
        ns("include_ci"),
        "Include Confidence Interval",
        value = FALSE
      ),
      bsTooltip(
        ns("include_ci"),
        "Optionally provide confidence intervals to calculate E-values for the CI bounds",
        "right"
      ),

      conditionalPanel(
        condition = sprintf("input['%s']", ns("include_ci")),

        if (effect_type %in% c("RR", "OR", "HR")) {
          tagList(
            create_numeric_input_with_tooltip(
              ns("ci_lower"),
              "Lower 95% CI:",
              value = 1.5,
              min = 0.01,
              max = 20,
              step = 0.1,
              tooltip = "Lower bound of 95% confidence interval"
            ),
            create_numeric_input_with_tooltip(
              ns("ci_upper"),
              "Upper 95% CI:",
              value = 2.8,
              min = 0.01,
              max = 20,
              step = 0.1,
              tooltip = "Upper bound of 95% confidence interval"
            )
          )
        } else {
          tagList(
            create_numeric_input_with_tooltip(
              ns("ci_lower"),
              "Lower 95% CI:",
              value = 0.3,
              min = -10,
              max = 10,
              step = 0.1,
              tooltip = "Lower bound of 95% confidence interval"
            ),
            create_numeric_input_with_tooltip(
              ns("ci_upper"),
              "Upper 95% CI:",
              value = 0.7,
              min = -10,
              max = 10,
              step = 0.1,
              tooltip = "Upper bound of 95% confidence interval"
            )
          )
        }
      ),

      # Additional options for OR and HR
      if (effect_type %in% c("OR", "HR")) {
        tagList(
          hr(),
          checkboxInput(
            ns("outcome_rare"),
            "Outcome is rare (<15%)",
            value = TRUE
          ),
          bsTooltip(
            ns("outcome_rare"),
            "For rare outcomes, OR/HR approximates RR. For common outcomes, conversion to RR is performed.",
            "right"
          )
        )
      },

      # Additional options for mean difference
      if (effect_type == "MD") {
        conditionalPanel(
          condition = sprintf("input['%s']", ns("include_ci")),
          create_numeric_input_with_tooltip(
            ns("md_se"),
            "Standard Error (optional):",
            value = 0.1,
            min = 0.001,
            max = 10,
            step = 0.01,
            tooltip = "Standard error of the mean difference. Used to calculate E-value for confidence interval."
          )
        )
      },

      hr(),

      # E-value results display
      uiOutput(ns("evalue_results"))
    )
  )
}

# Server Function ----
evalue_server <- function(id, effect_type = "RR") {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Calculate E-value results
    evalue_calc <- reactive({
      req(input$calculate_evalue)
      req(input$effect_estimate)

      # Get inputs
      effect_est <- input$effect_estimate
      ci_lo <- if (input$include_ci) input$ci_lower else NA
      ci_hi <- if (input$include_ci) input$ci_upper else NA

      # Validate inputs
      validation <- validate_evalue_inputs(
        effect_estimate = effect_est,
        lo = ci_lo,
        hi = ci_hi,
        effect_type = effect_type
      )

      if (!validation$valid) {
        return(list(
          valid = FALSE,
          messages = validation$messages
        ))
      }

      # Calculate E-values based on effect type
      result <- tryCatch({
        if (effect_type == "RR") {
          calc_evalue_rr(rr = effect_est, lo = ci_lo, hi = ci_hi)
        } else if (effect_type == "OR") {
          rare <- ifelse(is.null(input$outcome_rare), TRUE, input$outcome_rare)
          calc_evalue_or(or = effect_est, lo = ci_lo, hi = ci_hi, rare = rare)
        } else if (effect_type == "HR") {
          rare <- ifelse(is.null(input$outcome_rare), TRUE, input$outcome_rare)
          calc_evalue_hr(hr = effect_est, lo = ci_lo, hi = ci_hi, rare = rare)
        } else if (effect_type == "MD") {
          se <- if (input$include_ci && !is.null(input$md_se)) input$md_se else NA
          calc_evalue_md(md = effect_est, se = se)
        } else {
          stop("Unsupported effect type")
        }
      }, error = function(e) {
        list(
          valid = FALSE,
          messages = paste("ERROR:", e$message)
        )
      })

      # Add validation messages if any
      if (length(validation$messages) > 0) {
        result$validation_messages <- validation$messages
      }

      result$valid <- TRUE
      result
    })

    # Display E-value results
    output$evalue_results <- renderUI({
      req(input$calculate_evalue)

      result <- evalue_calc()

      if (!is.null(result$valid) && !result$valid) {
        # Show error messages
        div(
          class = "alert alert-danger",
          style = "margin-top: 15px;",
          tags$strong("Error:"),
          tags$ul(
            lapply(result$messages, function(msg) tags$li(msg))
          )
        )
      } else {
        # Show validation warnings if any
        warnings_html <- if (!is.null(result$validation_messages) && length(result$validation_messages) > 0) {
          div(
            class = "alert alert-warning",
            style = "margin-top: 10px; padding: 10px;",
            tags$ul(
              style = "margin-bottom: 0;",
              lapply(result$validation_messages, function(msg) tags$li(msg))
            )
          )
        } else {
          HTML("")
        }

        # Format and display E-value results
        tagList(
          warnings_html,
          format_evalue_result(result, effect_type)
        )
      }
    })

    # Return reactive list of E-value parameters and results
    return(
      reactive({
        list(
          calculate_evalue = input$calculate_evalue,
          effect_estimate = input$effect_estimate,
          include_ci = input$include_ci,
          ci_lower = if (input$include_ci) input$ci_lower else NA,
          ci_upper = if (input$include_ci) input$ci_upper else NA,
          outcome_rare = if (effect_type %in% c("OR", "HR")) input$outcome_rare else NA,
          md_se = if (effect_type == "MD" && input$include_ci) input$md_se else NA,
          results = if (input$calculate_evalue) evalue_calc() else NULL
        )
      })
    )
  })
}
