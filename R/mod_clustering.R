# Design Effect for Clustering Module
#
# A reusable Shiny module for clustered data adjustment UI and reactive values.
# This module implements Design Effect (DE) calculations for clustered/hierarchical data,
# following DRY (Don't Repeat Yourself) and SOLID principles.
#
# Usage:
#   UI:   clustering_ui(NS(id, "clustering"))
#   Server: clustering_values <- clustering_server(id, "clustering")
#
# Returns: Reactive list with clustering parameters
#
# Statistical Background:
#   Design Effect (DE) = 1 + (m - 1) × ICC
#   Where:
#     m = average cluster size
#     ICC = intraclass correlation coefficient
#
#   Effective sample size = N_total / DE
#   Required total N = N_unclustered × DE

# UI Function ----
clustering_ui <- function(id) {
  ns <- NS(id)

  tagList(
    checkboxInput(
      ns("adjust_clustering"),
      "Adjust for Clustered Data (Design Effect)",
      value = FALSE
    ),
    conditionalPanel(
      condition = sprintf("input['%s']", ns("adjust_clustering")),

      # Number of clusters
      create_numeric_input_with_tooltip(
        ns("n_clusters"),
        "Number of Clusters:",
        value = 20,
        min = 2,
        step = 1,
        tooltip = "Number of independent clusters (e.g., hospitals, clinics, practices, regions). Minimum of 2 clusters required."
      ),

      # Average cluster size
      create_numeric_input_with_tooltip(
        ns("cluster_size"),
        "Average Cluster Size (m):",
        value = 25,
        min = 2,
        step = 1,
        tooltip = "Average number of participants per cluster. For unequal clusters, use the arithmetic mean cluster size."
      ),

      # ICC selection method
      radioButtons_fixed(
        ns("icc_method"),
        "ICC Specification Method:",
        choices = c(
          "Select from typical values" = "select",
          "Enter custom ICC" = "custom"
        ),
        selected = "select"
      ),
      bsTooltip(
        ns("icc_method"),
        "Choose whether to use typical ICC values from literature or enter your own ICC estimate",
        "right"
      ),

      # Conditional: Select from typical values
      conditionalPanel(
        condition = sprintf("input['%s'] == 'select'", ns("icc_method")),

        selectInput(
          ns("icc_domain"),
          "Clinical Domain:",
          choices = c(
            "Behavioral Outcomes" = "behavioral",
            "Clinical/Physiological Outcomes" = "clinical",
            "Process Measures (e.g., adherence)" = "process",
            "General Practice/Primary Care" = "gp"
          ),
          selected = "clinical"
        ),
        bsTooltip(
          ns("icc_domain"),
          "Different outcome types have different typical ICC values. Select the domain most relevant to your outcome.",
          "right"
        ),

        # Display the ICC value that will be used
        uiOutput(ns("icc_selected_display"))
      ),

      # Conditional: Custom ICC
      conditionalPanel(
        condition = sprintf("input['%s'] == 'custom'", ns("icc_method")),

        create_enhanced_slider(
          ns("icc_custom"),
          "Intraclass Correlation Coefficient (ICC):",
          min = 0.001,
          max = 0.500,
          value = 0.05,
          step = 0.001,
          tooltip = "ICC measures the proportion of variance due to clustering. Values typically range from 0.001 to 0.30. Higher ICC = more clustering effect."
        )
      ),

      hr(),

      # Design effect summary (calculated dynamically)
      uiOutput(ns("design_effect_summary"))
    )
  )
}

# Server Function ----
clustering_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Typical ICC values from literature (meta-analyses 2024)
    # Source: Comprehensive Feature Analysis 2025, Section 2 (Clustered Data and Design Effects)
    icc_values <- list(
      behavioral = 0.025,  # Range: 0.01-0.05, using midpoint
      clinical = 0.05,     # Range: 0.01-0.10, using midpoint
      process = 0.20,      # Range: 0.10-0.30, using midpoint
      gp = 0.017           # Meta-analysis average for GP practices
    )

    # Reactive: Get current ICC value
    current_icc <- reactive({
      if (input$icc_method == "select") {
        icc_values[[input$icc_domain]]
      } else {
        input$icc_custom
      }
    })

    # Display selected ICC
    output$icc_selected_display <- renderUI({
      req(input$icc_method == "select")
      icc <- current_icc()

      domain_name <- switch(input$icc_domain,
        "behavioral" = "Behavioral Outcomes",
        "clinical" = "Clinical/Physiological Outcomes",
        "process" = "Process Measures",
        "gp" = "General Practice/Primary Care",
        "Selected Domain"
      )

      icc_range <- switch(input$icc_domain,
        "behavioral" = "0.01-0.05",
        "clinical" = "0.01-0.10",
        "process" = "0.10-0.30",
        "gp" = "0.017 (meta-analysis)",
        "varies"
      )

      div(
        class = "alert alert-info",
        style = "margin-top: 10px; padding: 10px;",
        tags$strong("Selected ICC: ", sprintf("%.3f", icc)),
        tags$br(),
        tags$small(
          sprintf("Typical range for %s: %s", domain_name, icc_range)
        )
      )
    })

    # Calculate and display design effect summary
    output$design_effect_summary <- renderUI({
      req(input$adjust_clustering)

      m <- input$cluster_size
      icc <- current_icc()
      n_clusters <- input$n_clusters

      # Calculate design effect
      de <- 1 + (m - 1) * icc

      # Total sample size if using these clusters
      n_total <- n_clusters * m

      # Effective sample size (equivalent unclustered N)
      n_effective <- ceiling(n_total / de)

      # Percentage inflation needed
      inflation_pct <- round((de - 1) * 100, 1)

      # Interpretation
      de_interpretation <- if (de < 1.5) {
        list(color = "#28a745", text = "Low clustering effect")
      } else if (de < 2.5) {
        list(color = "#ffc107", text = "Moderate clustering effect")
      } else {
        list(color = "#dc3545", text = "Strong clustering effect")
      }

      div(
        class = "alert",
        style = sprintf("background-color: %s15; border-left: 4px solid %s; padding: 12px;",
                       de_interpretation$color, de_interpretation$color),
        tags$h5("Design Effect Summary", style = "margin-top: 0;"),
        tags$p(
          tags$strong("Design Effect (DE): "), sprintf("%.3f", de),
          tags$br(),
          tags$span(
            style = sprintf("color: %s; font-weight: 600;", de_interpretation$color),
            de_interpretation$text
          )
        ),
        tags$p(
          tags$strong("Impact: "),
          sprintf("Clustering inflates required sample size by %.1f%%", inflation_pct),
          tags$br(),
          tags$small(
            sprintf("With %d clusters of average size %d (total N = %d), ",
                   n_clusters, m, n_total),
            sprintf("the effective sample size is approximately %d participants.", n_effective)
          )
        ),
        tags$hr(style = "margin: 8px 0;"),
        tags$small(
          tags$strong("Formula: "),
          sprintf("DE = 1 + (m - 1) × ICC = 1 + (%d - 1) × %.3f = %.3f",
                 m, icc, de)
        )
      )
    })

    # Return reactive list of all clustering parameters
    return(
      reactive({
        list(
          adjust_clustering = input$adjust_clustering,
          n_clusters = as.numeric(input$n_clusters),
          cluster_size = as.numeric(input$cluster_size),
          icc_method = input$icc_method,
          icc_domain = input$icc_domain,
          icc_custom = as.numeric(input$icc_custom),
          icc_value = as.numeric(current_icc())
        )
      })
    )
  })
}

# Helper function to calculate design effect inflation
# (This consolidates repeated calculation logic from server)
#
# @param n_calculated Base sample size from power/effect calculation
# @param clustering_params Reactive list from clustering_server()
#
# @return List with n_inflated, design_effect, and interpretation HTML
calculate_clustering_inflation <- function(n_calculated, clustering_params) {

  params <- clustering_params()

  if (!params$adjust_clustering || is.null(params$adjust_clustering)) {
    return(list(
      n_inflated = n_calculated,
      design_effect = 1.0,
      n_increase = 0,
      pct_increase = 0,
      n_effective = n_calculated,
      interpretation = ""
    ))
  }

  # Extract parameters
  m <- params$cluster_size
  icc <- params$icc_value
  n_clusters <- params$n_clusters

  # Calculate design effect
  # DE = 1 + (m - 1) × ICC
  design_effect <- 1 + (m - 1) * icc

  # Inflate sample size
  # N_required = N_unclustered × DE
  n_inflated <- ceiling(n_calculated * design_effect)
  n_increase <- n_inflated - n_calculated
  pct_increase <- round((design_effect - 1) * 100, 1)

  # Calculate required number of clusters
  n_clusters_required <- ceiling(n_inflated / m)

  # Effective sample size (for reporting)
  n_effective <- ceiling(n_inflated / design_effect)

  # Get ICC source description
  icc_source <- if (params$icc_method == "select") {
    domain_name <- switch(params$icc_domain,
      "behavioral" = "behavioral outcomes",
      "clinical" = "clinical/physiological outcomes",
      "process" = "process measures",
      "gp" = "general practice settings",
      "selected domain"
    )
    sprintf("typical ICC for %s", domain_name)
  } else {
    "custom ICC"
  }

  # Build interpretation text
  interpretation <- sprintf(
    paste0(
      "Accounting for clustered data (ICC = %.3f from %s, average cluster size = %d), ",
      "the design effect is %.2f. This inflates the required sample size by %.1f%% ",
      "(add %d participants). You will need approximately <strong>%d clusters</strong> ",
      "with an average of <strong>%d participants per cluster</strong>, ",
      "for a total of <strong>N = %d</strong>."
    ),
    icc, icc_source, m, design_effect, pct_increase, n_increase,
    n_clusters_required, m, n_inflated
  )

  list(
    n_inflated = n_inflated,
    design_effect = round(design_effect, 3),
    n_increase = n_increase,
    pct_increase = pct_increase,
    n_effective = n_effective,
    n_clusters_required = n_clusters_required,
    cluster_size = m,
    icc = icc,
    interpretation = interpretation
  )
}
