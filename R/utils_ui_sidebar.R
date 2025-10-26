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

      # ========================================================================
      # PARENT GROUP: Power Analysis
      # ========================================================================
      tags$div(
        class = "nav-group nav-group-parent",
        tags$div(
          class = "nav-group-header nav-group-header-parent",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$span(class = "nav-group-chevron", icon("caret-right")),
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("bolt")),
            tags$span(class = "nav-group-label", "Power Analysis")
          )
        ),
        tags$div(
          class = "nav-group-children nav-group-children-parent",

          # Child Group 1: Single Proportion
          tags$div(
            class = "nav-group nav-group-child",
            tags$div(
              class = "nav-group-header nav-group-header-child",
              role = "button",
              tabindex = "0",
              `aria-expanded` = "false",
              tags$span(class = "nav-group-chevron", icon("caret-right")),
              tags$div(
                class = "nav-group-title",
                tags$span(class = "nav-group-icon", icon("chart-pie")),
                tags$span(class = "nav-group-label", "Single Proportion")
              )
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

          # Child Group 2: Two-Group Comparisons
          tags$div(
            class = "nav-group nav-group-child",
            tags$div(
              class = "nav-group-header nav-group-header-child",
              role = "button",
              tabindex = "0",
              `aria-expanded` = "false",
              tags$span(class = "nav-group-chevron", icon("caret-right")),
              tags$div(
                class = "nav-group-title",
                tags$span(class = "nav-group-icon", icon("people-arrows")),
                tags$span(class = "nav-group-label", "Two-Group Comparisons")
              )
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

          # Child Group 3: Survival Analysis
          tags$div(
            class = "nav-group nav-group-child",
            tags$div(
              class = "nav-group-header nav-group-header-child",
              role = "button",
              tabindex = "0",
              `aria-expanded` = "false",
              tags$span(class = "nav-group-chevron", icon("caret-right")),
              tags$div(
                class = "nav-group-title",
                tags$span(class = "nav-group-icon", icon("chart-line")),
                tags$span(class = "nav-group-label", "Survival Analysis (Cox)")
              )
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

          # Child Group 4: Matched Case-Control (single item)
          tags$div(
            class = "nav-group nav-group-child",
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

          # Child Group 5: Continuous Outcomes
          tags$div(
            class = "nav-group nav-group-child",
            tags$div(
              class = "nav-group-header nav-group-header-child",
              role = "button",
              tabindex = "0",
              `aria-expanded` = "false",
              tags$span(class = "nav-group-chevron", icon("caret-right")),
              tags$div(
                class = "nav-group-title",
                tags$span(class = "nav-group-icon", icon("chart-area")),
                tags$span(class = "nav-group-label", "Continuous Outcomes")
              )
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

          # Child Group 6: Non-Inferiority (single item)
          tags$div(
            class = "nav-group nav-group-child",
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

          # Child Group 7: Propensity Score Methods (single item)
          tags$div(
            class = "nav-group nav-group-child",
            tags$a(
              href = "#",
              class = "nav-item-single",
              `data-page` = "vif_calculator",
              role = "button",
              tabindex = "0",
              tags$span(class = "nav-group-icon", icon("chart-bar")),
              tags$span(class = "nav-group-label", "Propensity Score Calculator")
            )
          ),

          # Child Group 8: Mediation Analysis (single item)
          tags$div(
            class = "nav-group nav-group-child",
            tags$a(
              href = "#",
              class = "nav-item-single",
              `data-page` = "mediation_analysis",
              role = "button",
              tabindex = "0",
              tags$span(class = "nav-group-icon", icon("project-diagram")),
              tags$span(class = "nav-group-label", "Mediation Analysis")
            )
          ),

          # Child Group 9: Time-to-Event Equivalence/NI (single item)
          tags$div(
            class = "nav-group nav-group-child",
            tags$a(
              href = "#",
              class = "nav-item-single",
              `data-page` = "survival_ni_equiv",
              role = "button",
              tabindex = "0",
              tags$span(class = "nav-group-icon", icon("heartbeat")),
              tags$span(class = "nav-group-label", "Time-to-Event Equivalence/NI")
            )
          )

        ) # End of Power Analysis parent children
      ), # End of Power Analysis parent group

      # ========================================================================
      # PARENT GROUP: Sensitivity Analysis
      # ========================================================================
      tags$div(
        class = "nav-group nav-group-parent",
        tags$div(
          class = "nav-group-header nav-group-header-parent",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$span(class = "nav-group-chevron", icon("caret-right")),
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("shield-alt")),
            tags$span(class = "nav-group-label", "Sensitivity Analysis")
          )
        ),
        tags$div(
          class = "nav-group-children nav-group-children-parent",

          # Child: E-value Calculator (single item)
          tags$div(
            class = "nav-group nav-group-child",
            tags$a(
              href = "#",
              class = "nav-item-single",
              `data-page` = "sensitivity_evalue",
              role = "button",
              tabindex = "0",
              tags$span(class = "nav-group-icon", icon("shield-alt")),
              tags$span(class = "nav-group-label", "E-value Calculator")
            )
          )

        ) # End of Sensitivity Analysis parent children
      ), # End of Sensitivity Analysis parent group

      # ========================================================================
      # PARENT GROUP: Resources
      # ========================================================================
      tags$div(
        class = "nav-group nav-group-parent",
        tags$div(
          class = "nav-group-header nav-group-header-parent",
          role = "button",
          tabindex = "0",
          `aria-expanded` = "false",
          tags$span(class = "nav-group-chevron", icon("caret-right")),
          tags$div(
            class = "nav-group-title",
            tags$span(class = "nav-group-icon", icon("book")),
            tags$span(class = "nav-group-label", "Resources")
          )
        ),
        tags$div(
          class = "nav-group-children nav-group-children-parent",

          # Child: Documentation (single item)
          tags$div(
            class = "nav-group nav-group-child",
            tags$a(
              href = "#",
              class = "nav-item-single",
              `data-page` = "documentation",
              role = "button",
              tabindex = "0",
              tags$span(class = "nav-group-icon", icon("book")),
              tags$span(class = "nav-group-label", "Documentation")
            )
          )

        ) # End of Resources parent children
      ) # End of Resources parent group

    ),

    # Sidebar Footer
    tags$div(
      class = "sidebar-footer",
      tags$p(class = "sidebar-footer-text", "v1.0.0 | RWE Tools")
    )
  )
}
