# Documentation Page UI Helper Functions
# This file contains the R functions to generate the documentation center

#' Create Documentation Page UI
#'
#' Generates the documentation center with cards for different topics
#'
#' @return HTML div element containing documentation page
create_documentation_page <- function() {
  tags$div(
    class = "documentation-page",

    # Header
    tags$div(
      class = "documentation-header",
      tags$h1(class = "documentation-title", "Documentation"),
      tags$p(class = "documentation-subtitle",
        "Comprehensive guides and documentation for the Power Analysis Tool"
      )
    ),

    # Documentation Cards Grid
    tags$div(
      class = "doc-card-grid",

      # Card 1: Getting Started
      create_doc_card(
        icon = icon("rocket"),
        title = "Getting Started",
        description = "Learn the basics of power analysis and sample size calculations with step-by-step tutorials.",
        link = "www/doc/getting-started.html",
        link_text = "Read Vignette"
      ),

      # Card 2: Propensity Score Methods
      create_doc_card(
        icon = icon("balance-scale-right"),
        title = "Propensity Score Sample Size",
        description = "Advanced methods for observational studies using Li et al. (2025) and Austin (2021) approaches for accounting for overlap and confounding.",
        link = "www/doc/propensity-score-calculations.html",
        link_text = "Read Vignette"
      ),

      # Card 3: Missing Data Adjustments
      create_doc_card(
        icon = icon("database"),
        title = "Missing Data Adjustments",
        description = "Complete Case Analysis vs Multiple Imputation strategies with practical decision frameworks and budget analysis.",
        link = "www/doc/missing-data-adjustments.html",
        link_text = "Read Vignette"
      ),

      # Card 4: Design Effects & Clustering
      create_doc_card(
        icon = icon("project-diagram"),
        title = "Design Effects in Clustered Studies",
        description = "ICC selection, sample size inflation for clustered data, and trade-offs between cluster size and number of clusters.",
        link = "www/doc/design-effects-clustering.html",
        link_text = "Read Vignette"
      ),

      # Card 5: Minimal Detectable Effects
      create_doc_card(
        icon = icon("bullseye"),
        title = "Minimal Detectable Effect Sizes",
        description = "Understanding feasibility constraints and determining the smallest effects you can reliably detect given budget limitations.",
        link = "www/doc/minimal-detectable-effects.html",
        link_text = "Read Vignette"
      ),

      # Card 6: Power Curves
      create_doc_card(
        icon = icon("chart-line"),
        title = "Interactive Power Curves",
        description = "Visualizing trade-offs in study design with power curves across effect sizes and sample sizes.",
        link = "www/doc/interactive-power-curves.html",
        link_text = "Read Vignette"
      ),

      # Card 7: Study Design Types
      create_doc_card(
        icon = icon("sitemap"),
        title = "Study Design Reference",
        description = "Technical specifications for single proportion, two-group comparisons, survival analysis, and matched designs.",
        link = "www/doc/study-design-reference.html",
        link_text = "Read Vignette"
      ),

      # Card 8: Statistical Methods
      create_doc_card(
        icon = icon("calculator"),
        title = "Statistical Methods",
        description = "Detailed methodology for effect measures, power calculations, and sample size formulas used in the tool.",
        link = "www/doc/statistical-methods.html",
        link_text = "Read Vignette"
      ),

      # Card 9: FAQ
      create_doc_card(
        icon = icon("question-circle"),
        title = "Frequently Asked Questions",
        description = "Common questions about power analysis, study design, and using the tool effectively.",
        link = "#faq",
        link_text = "View FAQ",
        new_window = FALSE
      )
    )
  )
}

#' Create Individual Documentation Card
#'
#' @param icon Icon object (from shiny::icon())
#' @param title Card title
#' @param description Card description
#' @param link Link URL or anchor
#' @param link_text Link button text
#' @param new_window Open link in new window (default: TRUE for vignettes)
#' @return HTML div element containing a documentation card
create_doc_card <- function(icon, title, description, link, link_text = "Learn More", new_window = TRUE) {

  # Determine if this is a vignette (opens in new window)
  open_action <- if (new_window) {
    sprintf("window.open('%s', '_blank')", link)
  } else {
    sprintf("window.location.href='%s'", link)
  }

  tags$div(
    class = "doc-card",
    onclick = open_action,
    tabindex = "0",
    role = "button",
    `aria-label` = paste("Navigate to", title),

    tags$div(
      class = "doc-card-icon",
      icon
    ),

    tags$h3(class = "doc-card-title", title),

    tags$p(class = "doc-card-description", description),

    tags$a(
      href = link,
      class = "doc-card-link",
      onclick = "event.stopPropagation()",
      target = if (new_window) "_blank" else NULL,
      rel = if (new_window) "noopener noreferrer" else NULL,
      link_text,
      tags$span(HTML("&rarr;"))
    )
  )
}
