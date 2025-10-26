#' Multiple Testing Correction Module
#'
#' A reusable Shiny module for multiple testing correction UI and calculations.
#' Helps researchers adjust alpha levels and sample sizes when planning to conduct
#' multiple statistical tests, controlling for Family-Wise Error Rate (FWER) or
#' False Discovery Rate (FDR).
#'
#' This module is essential for:
#'   - Multiple primary outcomes
#'   - Multiple endpoints (primary + secondary)
#'   - Subgroup analyses
#'   - Interim analyses
#'   - Multiple pairwise comparisons
#'
#' Usage:
#'   UI:   multiple_testing_ui(NS(id, "multiple_testing"))
#'   Server: mt_values <- multiple_testing_server(id, "multiple_testing")
#'
#' Returns: Reactive list with multiple testing parameters and adjusted values
#'
#' Statistical Background:
#'   When conducting k tests at alpha = 0.05, the probability of at least one
#'   Type I error increases: P(≥1 error) = 1 - (1 - α)^k
#'
#'   For k = 5 tests: P(≥1 error) = 23% (not 5%)!
#'
#'   Multiple testing corrections adjust alpha to control this inflation.
#'
#' @references
#' Bonferroni, C.E. (1936). Teoria statistica delle classi e calcolo delle
#' probabilita. Pubblicazioni del R Istituto Superiore di Scienze Economiche
#' e Commerciali di Firenze, 8, 3-62.
#'
#' Holm, S. (1979). A simple sequentially rejective multiple test procedure.
#' Scandinavian Journal of Statistics, 6(2), 65-70.
#'
#' Benjamini, Y., & Hochberg, Y. (1995). Controlling the false discovery rate:
#' a practical and powerful approach to multiple testing. Journal of the Royal
#' Statistical Society: Series B, 57(1), 289-300.

# UI Function ----
multiple_testing_ui <- function(id) {
  ns <- NS(id)

  tagList(
    checkboxInput(
      ns("adjust_multiple_testing"),
      "Adjust for Multiple Testing",
      value = FALSE
    ),
    bsTooltip(
      ns("adjust_multiple_testing"),
      "Enable this if you plan to conduct multiple statistical tests (e.g., multiple outcomes, subgroups, or endpoints)",
      "right"
    ),

    conditionalPanel(
      condition = sprintf("input['%s']", ns("adjust_multiple_testing")),

      helpText(
        HTML(paste0(
          "<strong>Why adjust?</strong> Multiple testing inflates Type I error. ",
          "Without correction, 5 tests at α=0.05 give ~23% chance of ≥1 false positive! ",
          "<a href='https://en.wikipedia.org/wiki/Multiple_comparisons_problem' target='_blank'>Learn more</a>"
        ))
      ),

      # Number of tests
      create_numeric_input_with_tooltip(
        ns("n_tests"),
        "Number of Statistical Tests:",
        value = 3,
        min = 1,
        max = 100,
        step = 1,
        tooltip = paste0(
          "Total number of hypothesis tests you plan to conduct. ",
          "Examples: 3 primary outcomes, 5 subgroups, 4 time points. ",
          "Include all tests, not just primary endpoint."
        )
      ),

      # Correction method
      selectInput(
        ns("correction_method"),
        "Correction Method:",
        choices = c(
          "Bonferroni (most conservative, controls FWER)" = "bonferroni",
          "Holm (recommended, controls FWER)" = "holm",
          "Hochberg (controls FWER)" = "hochberg",
          "Benjamini-Hochberg (controls FDR, more power)" = "BH",
          "Benjamini-Yekutieli (controls FDR, for dependent tests)" = "BY",
          "None (not recommended for multiple tests)" = "none"
        ),
        selected = "holm"
      ),
      bsTooltip(
        ns("correction_method"),
        HTML(paste0(
          "<strong>FWER:</strong> Family-Wise Error Rate - probability of ≥1 false positive<br>",
          "<strong>FDR:</strong> False Discovery Rate - expected proportion of false positives<br><br>",
          "<strong>Bonferroni:</strong> α_adj = α/k (most conservative)<br>",
          "<strong>Holm:</strong> Sequential, more powerful than Bonferroni<br>",
          "<strong>BH:</strong> Good for exploratory studies, maintains power"
        )),
        "right"
      ),

      # Method description helper text
      uiOutput(ns("method_description")),

      hr(),

      # Results summary
      uiOutput(ns("mt_summary")),

      # Additional guidance
      uiOutput(ns("mt_guidance"))
    )
  )
}

# Server Function ----
multiple_testing_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Calculate multiple testing adjustment
    mt_calc <- reactive({
      req(input$adjust_multiple_testing)
      req(input$n_tests)

      # Get current inputs
      n_tests <- input$n_tests
      method <- input$correction_method

      # Use alpha from parent context (typically 0.05)
      # This will be provided by the parent tab
      alpha <- 0.05

      # Validate inputs
      validation <- validate_multiple_testing_inputs(
        n_tests = n_tests,
        alpha = alpha,
        method = method
      )

      if (!validation$valid) {
        return(list(
          valid = FALSE,
          messages = validation$messages
        ))
      }

      # Calculate adjusted alpha
      result <- tryCatch({
        calc_adjusted_alpha(
          alpha = alpha,
          n_tests = n_tests,
          method = method
        )
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

    # Display method description
    output$method_description <- renderUI({
      req(input$correction_method)

      method_info <- get_correction_method_info(input$correction_method)

      div(
        class = "alert alert-info",
        style = "margin-top: 10px; padding: 10px; font-size: 0.9em;",
        tags$strong(method_info$full_name),
        tags$br(),
        tags$small(method_info$description),
        tags$br(),
        tags$small(
          tags$strong("Best for: "), method_info$when_to_use
        )
      )
    })

    # Display multiple testing summary
    output$mt_summary <- renderUI({
      req(input$adjust_multiple_testing)

      result <- mt_calc()

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
        warnings_html <- if (!is.null(result$validation_messages) &&
                            length(result$validation_messages) > 0) {
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

        # Format and display results
        tagList(
          warnings_html,
          format_multiple_testing_summary(result)
        )
      }
    })

    # Display guidance
    output$mt_guidance <- renderUI({
      req(input$adjust_multiple_testing)

      result <- mt_calc()

      if (is.null(result$valid) || !result$valid) {
        return(NULL)
      }

      # Provide context-specific guidance
      n_tests <- input$n_tests
      method <- tolower(input$correction_method)

      guidance_text <- if (n_tests == 1) {
        "With only 1 test, no multiple testing correction is needed."
      } else if (n_tests <= 3 && method %in% c("bonferroni", "holm")) {
        paste0("Good choice: ", result$method_name,
               " correction is appropriate for ", n_tests, " tests.")
      } else if (n_tests > 10 && method == "bonferroni") {
        paste0("⚠️ Consider switching to Holm or Benjamini-Hochberg. ",
               "Bonferroni with ", n_tests,
               " tests is very conservative and may result in low power.")
      } else if (n_tests > 5 && method %in% c("bh", "fdr")) {
        paste0("Good choice: Benjamini-Hochberg (FDR) is well-suited for ",
               n_tests, " tests, especially in exploratory analyses.")
      } else {
        paste0("Using ", result$method_name, " correction for ", n_tests, " tests.")
      }

      div(
        class = "alert alert-secondary",
        style = "margin-top: 15px; padding: 10px; font-size: 0.9em;",
        tags$strong("📋 Planning Tip:"), " ", guidance_text
      )
    })

    # Return reactive list of multiple testing parameters
    return(
      reactive({
        list(
          adjust_multiple_testing = input$adjust_multiple_testing,
          n_tests = as.numeric(input$n_tests),
          correction_method = input$correction_method,
          results = if (input$adjust_multiple_testing) mt_calc() else NULL
        )
      })
    )
  })
}


#' Helper function to apply multiple testing adjustment to sample size
#'
#' This function should be called in the parent tab to inflate sample size
#' based on multiple testing correction.
#'
#' @param n_base Base sample size (before adjustment)
#' @param mt_params Reactive list from multiple_testing_server()
#' @param power Target power level (default 0.80)
#'
#' @return List with adjusted sample size and interpretation
#'
#' @noRd
apply_multiple_testing_to_n <- function(n_base, mt_params, power = 0.80) {

  params <- mt_params()

  if (!params$adjust_multiple_testing || is.null(params$adjust_multiple_testing)) {
    return(list(
      n_adjusted = n_base,
      n_increase = 0,
      pct_increase = 0,
      interpretation = ""
    ))
  }

  # Get results from multiple testing calculation
  mt_result <- params$results

  if (is.null(mt_result) || !mt_result$valid) {
    return(list(
      n_adjusted = n_base,
      n_increase = 0,
      pct_increase = 0,
      interpretation = "Multiple testing adjustment could not be calculated."
    ))
  }

  # Calculate adjusted sample size
  n_adjustment <- calc_n_multiple_testing(
    n_base = n_base,
    alpha_original = mt_result$alpha_original,
    alpha_adjusted = mt_result$alpha_adjusted,
    power = power
  )

  # Build interpretation text
  interpretation <- sprintf(
    paste0(
      "<strong>Multiple Testing Adjustment:</strong> ",
      "Using %s correction for %d tests (adjusted α = %.4f), ",
      "%s"
    ),
    mt_result$method_name,
    mt_result$n_tests,
    mt_result$alpha_adjusted,
    n_adjustment$interpretation
  )

  list(
    n_adjusted = n_adjustment$n_adjusted,
    n_increase = n_adjustment$n_increase,
    pct_increase = n_adjustment$pct_increase,
    inflation_factor = n_adjustment$inflation_factor,
    method = mt_result$method_name,
    n_tests = mt_result$n_tests,
    alpha_adjusted = mt_result$alpha_adjusted,
    interpretation = interpretation
  )
}
