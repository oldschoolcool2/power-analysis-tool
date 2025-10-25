# Sidebar Navigation UI Helper Functions
# This file contains the R function to generate the hierarchical sidebar HTML

#' Generate Hierarchical Sidebar Navigation
#'
#' Creates the HTML structure for the sidebar navigation with collapsible groups
#'
#' @return HTML div element containing the complete sidebar
create_sidebar_nav <- function() {
  tags$div(
    class = "sidebar",
    role = "navigation",
    `aria-label` = "Main navigation",

    # Sidebar Header
    tags$div(
      class = "sidebar-header",
      tags$a(
        href = "#",
        class = "sidebar-logo",
        tags$span(class = "sidebar-logo-icon", HTML("&#9889;")),
        tags$div(
          class = "sidebar-logo-text",
          tags$h1("Power Analysis"),
          tags$p("for Real-World Evidence")
        )
      )
    ),

    # Navigation Menu
    tags$nav(
      class = "sidebar-nav",

      # Group 1: Single Proportion
      tags$div(
        class = "nav-group",
        tags$div(
          class = "nav-group-header",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("chart-pie")),
            tags$span(class = "nav-group-label", "Single Proportion")
          ),
          tags$span(class = "nav-group-chevron", HTML("&#9656;")) # ▸
        ),
        tags$div(
          class = "nav-group-children",
          tags$a(
            href = "#",
            class = "nav-item active",
            `data-page` = "power_single",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", icon("bolt")),
            "Power Analysis"
          ),
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "ss_single",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", icon("calculator")),
            "Sample Size"
          )
        )
      ),

      # Group 2: Two-Group Comparisons
      tags$div(
        class = "nav-group",
        tags$div(
          class = "nav-group-header",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("users")),
            tags$span(class = "nav-group-label", "Two-Group Comparisons")
          ),
          tags$span(class = "nav-group-chevron", HTML("&#9656;"))
        ),
        tags$div(
          class = "nav-group-children",
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "power_twogrp",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", HTML("&#9889;")),
            "Power Analysis"
          ),
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "ss_twogrp",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", HTML("&#128207;")),
            "Sample Size"
          )
        )
      ),

      # Group 3: Survival Analysis
      tags$div(
        class = "nav-group",
        tags$div(
          class = "nav-group-header",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("chart-line")),
            tags$span(class = "nav-group-label", "Survival Analysis (Cox)")
          ),
          tags$span(class = "nav-group-chevron", HTML("&#9656;"))
        ),
        tags$div(
          class = "nav-group-children",
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "power_survival",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", HTML("&#9889;")),
            "Power Analysis"
          ),
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "ss_survival",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", HTML("&#128207;")),
            "Sample Size"
          )
        )
      ),

      # Group 4: Matched Case-Control (single item)
      tags$div(
        class = "nav-group",
        tags$a(
          href = "#",
          class = "nav-item-single",
          `data-page` = "match_casecontrol",
          role = "button",
          tabindex = "0",
          tags$span(class = "nav-group-icon", icon("link")),
          tags$span(class = "nav-group-label", "Matched Case-Control")
        )
      ),

      # Group 5: Continuous Outcomes
      tags$div(
        class = "nav-group",
        tags$div(
          class = "nav-group-header",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("chart-area")),
            tags$span(class = "nav-group-label", "Continuous Outcomes")
          ),
          tags$span(class = "nav-group-chevron", HTML("&#9656;"))
        ),
        tags$div(
          class = "nav-group-children",
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "power_continuous",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", icon("bolt")),
            "Power Analysis (t-tests)"
          ),
          tags$a(
            href = "#",
            class = "nav-item",
            `data-page` = "ss_continuous",
            role = "button",
            tabindex = "0",
            tags$span(class = "nav-item-icon", icon("calculator")),
            "Sample Size"
          )
        )
      ),

      # Group 6: Non-Inferiority (single item)
      tags$div(
        class = "nav-group",
        tags$a(
          href = "#",
          class = "nav-item-single",
          `data-page` = "noninf",
          role = "button",
          tabindex = "0",
          tags$span(class = "nav-group-icon", icon("balance-scale")),
          tags$span(class = "nav-group-label", "Non-Inferiority Testing")
        )
      ),

      # Group 7: Propensity Score Methods (single item)
      tags$div(
        class = "nav-group",
        tags$a(
          href = "#",
          class = "nav-item-single",
          `data-page` = "vif_calculator",
          role = "button",
          tabindex = "0",
          tags$span(class = "nav-group-icon", icon("chart-bar")),
          tags$span(class = "nav-group-label", "Propensity Score VIF")
        )
      )
    ),

    # Sidebar Footer
    tags$div(
      class = "sidebar-footer",
      tags$p(class = "sidebar-footer-text", "v1.0.0 | RWE Tools")
    )
  )
}
