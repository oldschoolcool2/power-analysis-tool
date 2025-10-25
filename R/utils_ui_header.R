# Header UI Component
# Statistical Power Analysis Tool
#
# This file contains the UI function for creating the application header
# with branding, navigation, and theme toggle.

#' Create Application Header
#'
#' Creates a professional header bar with app branding, actions, and theme toggle
#'
#' @return A Shiny tag element representing the header
#'
#' @export
create_app_header <- function() {
  tags$div(
    class = "app-header",

    # Left side: Branding
    tags$div(
      class = "app-header-brand",

      # Logo/Icon
      tags$span(
        class = "app-header-logo",
        icon("chart-line", class = "fa-2x")
      ),

      # Title and subtitle
      tags$div(
        class = "app-header-title",
        tags$div(
          class = "app-header-title-main",
          "Statistical Power Analysis Tool"
        ),
        tags$div(
          class = "app-header-title-sub",
          "for Real-World Evidence Studies"
        )
      )
    ),

    # Right side: Actions
    tags$div(
      class = "app-header-actions",

      # Theme Toggle Button
      tags$button(
        id = "theme-toggle",
        class = "theme-toggle-button",
        type = "button",
        `aria-label` = "Toggle theme",
        title = "Toggle theme (Ctrl+Shift+D)",
        tags$span(class = "theme-toggle-icon", icon("moon")),
        tags$span(class = "theme-toggle-text", "Dark")
      ),

      # Help Button - triggers modal
      actionButton(
        "show_help_modal",
        label = tags$span(
          icon("question-circle"),
          tags$span(class = "btn-text", "Help")
        ),
        class = "app-header-action-btn",
        `aria-label` = "Show help documentation"
      )
    )
  )
}
