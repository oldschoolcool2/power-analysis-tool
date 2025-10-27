#' Multiple-Bias Sensitivity Analysis Module
#'
#' A reusable Shiny module for multiple-bias sensitivity analysis UI and calculations.
#' Allows assessment of multiple biases jointly (unmeasured confounding, selection bias,
#' and differential misclassification) to understand how combinations of biases could
#' affect study results.
#'
#' Usage:
#'   UI:   multi_bias_ui(NS(id, "multi_bias"))
#'   Server: multi_bias_values <- multi_bias_server(id, "multi_bias")
#'
#' Returns: Reactive list with multi-bias parameters and results
#'
#' Statistical Background:
#'   Multi-bias E-values represent the minimum value that all sensitivity
#'   parameters would need to take on simultaneously for an observed association
#'   to be explained away as null. This recognizes that real studies often face
#'   multiple sources of bias acting together.
#'
#' @references
#' Smith, L.H., & VanderWeele, T.J. (2019). Bounding bias due to selection.
#' Epidemiology, 30(4), 509-516.

# UI Function ----
multi_bias_ui <- function(id) {
  ns <- NS(id)

  tagList(
    helpText(
      "Multiple-bias sensitivity analysis allows you to assess the joint impact of ",
      "unmeasured confounding, selection bias, and differential misclassification. ",
      "This approach recognizes that studies are typically affected by multiple biases acting together."
    ),

    hr(),

    h3("Select Bias Types to Include"),

    helpText(
      "Choose which types of bias you want to consider in your sensitivity analysis. ",
      "You can select one or more bias types."
    ),

    bslib::tooltip(
      checkboxInput(
        ns("include_confounding"),
        "Unmeasured Confounding",
        value = TRUE
      ),
      "Include unmeasured confounding in the analysis. This represents confounders not adjusted for in your study.",
      placement = "right"
    ),

    bslib::tooltip(
      checkboxInput(
        ns("include_selection"),
        "Selection Bias",
        value = FALSE
      ),
      "Include selection bias, which occurs when the study sample differs systematically from the target population.",
      placement = "right"
    ),

    conditionalPanel(
      condition = sprintf("input['%s']", ns("include_selection")),
      div(
        style = "margin-left: 25px;",
        bslib::tooltip(
          radioButtons(
            ns("selection_type"),
            "Selection Bias Type:",
            choices = c(
              "General population" = "general",
              "Selected population only" = "selected"
            ),
            selected = "general",
            inline = TRUE
          ),
          "General: Making inference about the total population. Selected: Making inference only about the selected population.",
          placement = "right"
        )
      )
    ),

    bslib::tooltip(
      checkboxInput(
        ns("include_misclass"),
        "Differential Misclassification",
        value = FALSE
      ),
      "Include differential misclassification bias, which occurs when measurement error differs between exposure groups.",
      placement = "right"
    ),

    conditionalPanel(
      condition = sprintf("input['%s']", ns("include_misclass")),
      div(
        style = "margin-left: 25px;",
        bslib::tooltip(
          radioButtons(
            ns("misclass_type"),
            "Misclassification Type:",
            choices = c(
              "Outcome misclassification" = "outcome",
              "Exposure misclassification" = "exposure"
            ),
            selected = "outcome",
            inline = TRUE
          ),
          "Choose whether the misclassification affects the outcome or exposure variable.",
          placement = "right"
        ),

        conditionalPanel(
          condition = sprintf("input['%s'] == 'exposure'", ns("misclass_type")),
          div(
            style = "margin-top: 10px;",
            checkboxInput(
              ns("outcome_rare"),
              "Outcome is rare (<15%)",
              value = TRUE
            ),
            checkboxInput(
              ns("exposure_rare"),
              "Exposure is rare (<15%)",
              value = TRUE
            )
          )
        )
      )
    ),

    hr(),

    h3("Effect Estimate"),

    helpText(
      "Enter your observed effect estimate and confidence interval. ",
      "The effect should be expressed as a risk ratio (RR). ",
      "If you have an odds ratio (OR) or hazard ratio (HR), you may approximate it as RR if the outcome is rare."
    ),

    create_numeric_input_with_tooltip(
      ns("rr"),
      "Risk Ratio (RR):",
      value = 3.0,
      min = 0.01,
      max = 20,
      step = 0.1,
      tooltip = "The observed risk ratio from your study. RR > 1 indicates increased risk, RR < 1 indicates protective effect."
    ),

    bslib::tooltip(
      checkboxInput(
        ns("include_ci"),
        "Include Confidence Interval",
        value = FALSE
      ),
      "Optionally provide confidence intervals for more complete sensitivity analysis",
      placement = "right"
    ),

    conditionalPanel(
      condition = sprintf("input['%s']", ns("include_ci")),
      create_numeric_input_with_tooltip(
        ns("ci_lower"),
        "Lower 95% CI:",
        value = 2.0,
        min = 0.01,
        max = 20,
        step = 0.1,
        tooltip = "Lower bound of 95% confidence interval"
      ),
      create_numeric_input_with_tooltip(
        ns("ci_upper"),
        "Upper 95% CI:",
        value = 4.5,
        min = 0.01,
        max = 20,
        step = 0.1,
        tooltip = "Upper bound of 95% confidence interval"
      )
    ),

    hr(),

    h3("Analysis Type"),

    bslib::tooltip(
      radioButtons(
        ns("analysis_type"),
        "Choose analysis:",
        choices = c(
          "Multi-bias E-value" = "evalue",
          "Bias-adjusted bound" = "bound"
        ),
        selected = "evalue",
        inline = FALSE
      ),
      "E-value: Calculate minimum bias strength to explain away effect. Bound: Calculate adjusted effect given specific bias values.",
      placement = "right"
    ),

    helpText(
      tags$strong("Multi-bias E-value:"), " Calculates the minimum value all bias parameters must take simultaneously to explain away your observed effect.", tags$br(),
      tags$strong("Bias-adjusted bound:"), " Calculates what your effect estimate would be after adjusting for biases of specific magnitudes you specify."
    ),

    # Conditional UI for bound calculation (bias parameter inputs)
    conditionalPanel(
      condition = sprintf("input['%s'] == 'bound'", ns("analysis_type")),
      hr(),
      h4("Specify Bias Parameters"),
      helpText(
        "Enter the magnitude of each bias parameter. These should be expressed as risk ratios. ",
        "For example, RRUcY = 2 means the unmeasured confounder increases outcome risk 2-fold."
      ),
      uiOutput(ns("bias_parameters_ui"))
    ),

    hr(),

    actionButton(
      ns("calculate"),
      "Calculate Multi-Bias Analysis",
      icon = icon("calculator"),
      class = "btn-primary"
    ),

    hr(),

    # Results display
    uiOutput(ns("multi_bias_results"))
  )
}

# Server Function ----
multi_bias_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Reactive multi_bias object based on selected biases
    multi_bias_obj <- reactive({
      req(input$include_confounding || input$include_selection || input$include_misclass)

      tryCatch({
        create_multi_bias(
          include_confounding = input$include_confounding,
          include_selection = input$include_selection,
          include_misclass = input$include_misclass,
          selection_type = if (input$include_selection) input$selection_type else "general",
          misclass_type = if (input$include_misclass) input$misclass_type else "outcome",
          outcome_rare = if (input$include_misclass && input$misclass_type == "exposure") {
            input$outcome_rare
          } else {
            TRUE
          },
          exposure_rare = if (input$include_misclass && input$misclass_type == "exposure") {
            input$exposure_rare
          } else {
            TRUE
          }
        )
      }, error = function(e) {
        NULL
      })
    })

    # Get required bias parameters for UI
    output$bias_parameters_ui <- renderUI({
      req(multi_bias_obj())

      parms <- get_multi_bias_parameters(multi_bias_obj())

      # Create numeric inputs for each parameter with descriptive tooltips
      lapply(parms, function(parm) {
        create_numeric_input_with_tooltip(
          ns(parm),
          paste0(parm, ":"),
          value = 1.5,
          min = 0.1,
          max = 10,
          step = 0.1,
          tooltip = get_parameter_tooltip(parm)
        )
      })
    })

    # Perform calculation when button is clicked
    calculation_result <- eventReactive(input$calculate, {
      req(input$rr)
      req(multi_bias_obj())

      # Get CI values
      ci_lo <- if (input$include_ci) input$ci_lower else NA
      ci_hi <- if (input$include_ci) input$ci_upper else NA

      # Validate inputs
      validation <- validate_multi_bias_inputs(
        rr = input$rr,
        lo = ci_lo,
        hi = ci_hi,
        include_confounding = input$include_confounding,
        include_selection = input$include_selection,
        include_misclass = input$include_misclass
      )

      if (!validation$valid) {
        return(list(
          valid = FALSE,
          messages = validation$messages
        ))
      }

      # Perform calculation based on analysis type
      result <- tryCatch({
        if (input$analysis_type == "evalue") {
          # Calculate multi-bias E-value
          calc_multi_evalue(
            multi_bias_obj = multi_bias_obj(),
            rr = input$rr,
            lo = ci_lo,
            hi = ci_hi
          )
        } else {
          # Calculate bias-adjusted bound
          # Get bias parameter values from inputs
          parms <- get_multi_bias_parameters(multi_bias_obj())
          bias_parm_values <- lapply(parms, function(p) input[[p]])
          names(bias_parm_values) <- parms

          calc_multi_bound(
            multi_bias_obj = multi_bias_obj(),
            rr = input$rr,
            lo = ci_lo,
            hi = ci_hi,
            bias_parms = bias_parm_values
          )
        }
      }, error = function(e) {
        list(
          valid = FALSE,
          messages = paste("ERROR:", e$message)
        )
      })

      # Add validation warnings if any
      if (length(validation$messages) > 0) {
        result$validation_messages <- validation$messages
      }

      result$valid <- TRUE
      result$analysis_type <- input$analysis_type
      result
    })

    # Display results
    output$multi_bias_results <- renderUI({
      result <- calculation_result()

      if (is.null(result)) {
        return(NULL)
      }

      if (!is.null(result$valid) && !result$valid) {
        # Show error messages
        return(
          div(
            class = "alert alert-danger",
            style = "margin-top: 15px;",
            tags$strong("Error:"),
            tags$ul(
              lapply(result$messages, function(msg) tags$li(msg))
            )
          )
        )
      }

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

      # Format and display results based on analysis type
      result_html <- if (result$analysis_type == "evalue") {
        format_multi_evalue_result(result)
      } else {
        format_multi_bound_result(result)
      }

      tagList(
        warnings_html,
        result_html,
        hr(),
        div(
          class = "alert alert-info",
          style = "margin-top: 20px;",
          tags$strong(icon("info-circle"), " Interpretation Guide:"),
          tags$ul(
            tags$li(
              tags$strong("Multi-bias E-value:"),
              " Represents the minimum strength each bias parameter must have simultaneously to explain away the effect. ",
              "Higher values indicate greater robustness to multiple biases."
            ),
            tags$li(
              tags$strong("Bias-adjusted bound:"),
              " Shows what the effect estimate would be if biases of the specified magnitudes were present. ",
              "If the bound crosses the null (RR = 1), those biases could fully explain the observed effect."
            )
          )
        )
      )
    })

    # Return reactive values
    return(
      reactive({
        list(
          include_confounding = input$include_confounding,
          include_selection = input$include_selection,
          include_misclass = input$include_misclass,
          selection_type = input$selection_type,
          misclass_type = input$misclass_type,
          rr = input$rr,
          include_ci = input$include_ci,
          ci_lower = if (input$include_ci) input$ci_lower else NA,
          ci_upper = if (input$include_ci) input$ci_upper else NA,
          analysis_type = input$analysis_type,
          results = if (!is.null(calculation_result())) calculation_result() else NULL
        )
      })
    )
  })
}
