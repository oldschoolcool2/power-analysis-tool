#' Result Card UI Components
#'
#' Visual components for displaying analysis results with color-coded interpretations,
#' key findings callouts, and clear visual hierarchy.

# Power Interpretation Thresholds ----
# Standard power thresholds based on Cohen (1988)
POWER_ADEQUATE <- 0.80      # Standard threshold for adequate power
POWER_MARGINAL <- 0.70      # Lower bound for marginal power
POWER_EXCELLENT <- 0.90     # Threshold for excellent power


#' Create a visual result summary card
#'
#' @param title Card title (e.g., "Required Sample Size", "Achieved Power")
#' @param value Main value to display prominently
#' @param subtitle Optional subtitle text
#' @param status One of "success", "warning", "danger", "info" (determines color)
#' @param icon Optional icon name (e.g., "check-circle", "exclamation-triangle")
#'
#' @return HTML div with styled card
#'
#' @examples
#' create_result_card("Required Sample Size", "N = 450", "Power = 0.80", "success")
#' create_result_card("Achieved Power", "0.52", "Underpowered", "danger", "exclamation-triangle")
#'
#' @importFrom shiny tags icon
create_result_card <- function(title, value, subtitle = NULL, status = "info", icon_name = NULL) {
  # Determine color based on status
  color_map <- list(
    success = list(bg = "var(--color-success-100)", border = "var(--color-success-600)", text = "var(--color-success-700)"),
    warning = list(bg = "var(--color-warning-100)", border = "var(--color-warning-600)", text = "var(--color-warning-700)"),
    danger = list(bg = "var(--color-error-100)", border = "var(--color-error-600)", text = "var(--color-error-700)"),
    info = list(bg = "var(--color-info-100)", border = "var(--color-info-600)", text = "var(--color-info-700)")
  )

  colors <- color_map[[status]]

  tags$div(
    class = "result-summary-card",
    style = sprintf(
      "background: %s; border-left: 4px solid %s; padding: 1.5rem; margin: 1.5rem 0; border-radius: var(--border-radius-lg); box-shadow: var(--shadow-sm);",
      colors$bg, colors$border
    ),
    tags$div(
      class = "result-card-content",
      style = "display: flex; align-items: center; gap: 1rem;",

      # Icon (if provided)
      if (!is.null(icon_name)) {
        tags$div(
          class = "result-card-icon",
          style = sprintf("font-size: 2.5rem; color: %s;", colors$text),
          icon(icon_name)
        )
      },

      # Content
      tags$div(
        class = "result-card-text",
        style = "flex: 1;",
        tags$div(
          class = "result-card-title",
          style = sprintf("font-size: var(--font-size-sm); font-weight: var(--font-weight-medium); color: %s; text-transform: uppercase; letter-spacing: 0.05em; margin-bottom: 0.25rem;", colors$text),
          title
        ),
        tags$div(
          class = "result-card-value",
          style = "font-size: var(--font-size-3xl); font-weight: var(--font-weight-bold); color: var(--text-primary); margin-bottom: 0.25rem;",
          value
        ),
        if (!is.null(subtitle)) {
          tags$div(
            class = "result-card-subtitle",
            style = "font-size: var(--font-size-sm); color: var(--text-secondary);",
            subtitle
          )
        }
      )
    )
  )
}


#' Create a key finding callout
#'
#' @param text The finding text to display
#' @param type One of "success", "warning", "info", "danger"
#' @param icon_name Optional icon name
#'
#' @return HTML div with styled callout
#'
#' @examples
#' create_key_finding("You need 450 participants to detect this effect", "info", "chart-bar")
#' create_key_finding("With 200 participants, power drops below target", "warning",
#'                    "exclamation-triangle")
#'
#' @importFrom shiny tags icon
create_key_finding <- function(text, type = "info", icon_name = NULL) {
  # Icon defaults based on type
  if (is.null(icon_name)) {
    icon_name <- switch(type,
      success = "check-circle",
      warning = "exclamation-triangle",
      info = "info-circle",
      danger = "exclamation-circle",
      "info-circle"
    )
  }

  # Emoji alternatives for visual interest
  emoji_map <- list(
    success = "\U2705",  # ✅
    warning = "\U26A0\UFE0F",  # ⚠️
    info = "\U1F4CA",  # 📊
    danger = "\U1F6AB"  # 🚫
  )

  emoji <- emoji_map[[type]]

  tags$div(
    class = paste0("key-finding key-finding-", type),
    style = "margin: 1rem 0; padding: 0.75rem 1rem; border-radius: var(--border-radius-md); display: flex; align-items: center; gap: 0.75rem;",
    tags$span(
      class = "key-finding-icon",
      style = "font-size: 1.25rem;",
      emoji
    ),
    tags$span(
      class = "key-finding-text",
      style = "font-weight: var(--font-weight-medium); color: var(--text-primary);",
      text
    )
  )
}


#' Determine power status and appropriate styling
#'
#' @param power Power as proportion (0-1) or percentage (0-100)
#' @param as_percentage If TRUE, treats power as percentage, otherwise as proportion
#'
#' @return List with status ("success", "warning", "danger"), color, and interpretation
#'
#' @examples
#' get_power_status(0.85) # Returns "success"
#' get_power_status(75, as_percentage = TRUE) # Returns "warning"
#' get_power_status(0.52) # Returns "danger"
get_power_status <- function(power, as_percentage = FALSE) {
  # Convert to proportion if needed
  if (as_percentage) {
    power <- power / 100
  }

  # Determine status
  status <- if (power >= POWER_ADEQUATE) {
    "success"
  } else if (power >= POWER_MARGINAL) {
    "warning"
  } else {
    "danger"
  }

  # Interpretation text
  interpretation <- if (power >= POWER_EXCELLENT) {
    "Excellent power (≥90%)"
  } else if (power >= POWER_ADEQUATE) {
    "Adequate power (≥80%)"
  } else if (power >= POWER_MARGINAL) {
    "Marginal power (70-79%)"
  } else if (power >= 0.50) {
    "Low power (50-69%)"
  } else {
    "Very low power (<50%)"
  }

  list(
    status = status,
    interpretation = interpretation,
    icon = if (power >= POWER_ADEQUATE) "check-circle" else if (power >= POWER_MARGINAL) "exclamation-triangle" else "times-circle"
  )
}


#' Create a comparison card for multiple scenarios
#'
#' @param scenarios List of lists, each containing title, value, and optional subtitle
#'
#' @return HTML div with side-by-side scenario comparison
#'
#' @examples
#' create_comparison_card(list(
#'   list(title = "Scenario A", value = "n=400", subtitle = "Power: 78\%"),
#'   list(title = "Scenario B", value = "n=600", subtitle = "Power: 89\%")
#' ))
#'
#' @importFrom shiny tags
create_comparison_card <- function(scenarios) {
  tags$div(
    class = "comparison-card",
    style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem; margin: 1.5rem 0;",
    lapply(scenarios, function(scenario) {
      tags$div(
        class = "comparison-scenario",
        style = "background: var(--bg-card); border: var(--border-default); border-radius: var(--border-radius-lg); padding: 1rem; text-align: center;",
        tags$div(
          class = "scenario-title",
          style = "font-size: var(--font-size-sm); font-weight: var(--font-weight-semibold); color: var(--text-secondary); margin-bottom: 0.5rem;",
          scenario$title
        ),
        tags$div(
          class = "scenario-value",
          style = "font-size: var(--font-size-2xl); font-weight: var(--font-weight-bold); color: var(--text-primary); margin-bottom: 0.25rem;",
          scenario$value
        ),
        if (!is.null(scenario$subtitle)) {
          tags$div(
            class = "scenario-subtitle",
            style = "font-size: var(--font-size-sm); color: var(--text-secondary);",
            scenario$subtitle
          )
        }
      )
    })
  )
}


#' Create a recommendations panel
#'
#' @param recommendations Character vector of recommendation texts
#' @param title Panel title (default: "Recommendations")
#'
#' @return HTML div with recommendations list
#'
#' @examples
#' create_recommendations_panel(c(
#'   "Your ICC (0.05) is typical for clinical outcomes",
#'   "Consider a discontinuation rate of 0.20 for 12-month studies"
#' ))
#'
#' @importFrom shiny tags icon
create_recommendations_panel <- function(recommendations, title = "Recommendations") {
  tags$div(
    class = "recommendations-panel",
    style = "background: var(--color-primary-100); border-radius: var(--border-radius-lg); padding: 1.25rem; margin: 1.5rem 0;",
    tags$div(
      class = "recommendations-header",
      style = "display: flex; align-items: center; gap: 0.5rem; margin-bottom: 1rem;",
      tags$span(
        style = "font-size: 1.25rem; color: var(--color-primary-700);",
        icon("lightbulb")
      ),
      tags$h4(
        style = "margin: 0; font-size: var(--font-size-lg); font-weight: var(--font-weight-semibold); color: var(--text-primary);",
        title
      )
    ),
    tags$ul(
      class = "recommendations-list",
      style = "margin: 0; padding-left: 1.5rem; color: var(--text-primary);",
      lapply(recommendations, function(rec) {
        tags$li(style = "margin-bottom: 0.5rem;", rec)
      })
    )
  )
}


#' Create a copy-to-clipboard button
#'
#' @param target_id ID of the element to copy content from
#' @param button_text Button label (default: "Copy to Clipboard")
#' @param class Additional CSS classes
#'
#' @return HTML button element
#'
#' @examples
#' create_copy_button("result_text", "Copy Results")
#'
#' @importFrom shiny tags icon
create_copy_button <- function(target_id, button_text = "Copy to Clipboard", class = NULL) {
  btn_class <- paste("copy-button btn btn-sm btn-outline-secondary", class)

  tags$button(
    class = btn_class,
    type = "button",
    `data-copy-target` = target_id,
    icon("copy"),
    tags$span(class = "copy-button-text ms-2", button_text)
  )
}


#' Create enhanced result text with visual cards
#'
#' This is a wrapper that combines traditional text with new visual elements
#'
#' @param main_card_config List with title, value, subtitle, status for main card
#' @param text_content HTML or text content for detailed results
#' @param key_findings Optional character vector of key findings
#' @param recommendations Optional character vector of recommendations
#' @param show_copy_button Whether to show copy-to-clipboard button (default TRUE)
#'
#' @return HTML tagList with all components
#'
#' @importFrom shiny tagList tags
create_enhanced_results <- function(main_card_config,
                                   text_content = NULL,
                                   key_findings = NULL,
                                   recommendations = NULL,
                                   show_copy_button = TRUE) {
  # Generate unique ID for copyable content
  result_id <- paste0("results-", gsub("\\.", "-", make.names(Sys.time())))

  result <- tagList()

  # Copy button at the top
  if (show_copy_button) {
    result <- tagList(
      result,
      tags$div(
        class = "copy-button-wrapper",
        style = "margin-bottom: 1rem; text-align: right;",
        create_copy_button(result_id, "Copy Results to Clipboard")
      )
    )
  }

  # Wrapper for all copyable content
  result <- tagList(
    result,
    tags$div(
      id = result_id,
      class = "copyable-results",

      # Main result card
      do.call(create_result_card, main_card_config),

      # Key findings
      if (!is.null(key_findings) && length(key_findings) > 0) {
        lapply(key_findings, function(kf) {
          create_key_finding(kf$text, kf$type, kf$icon)
        })
      },

      # Detailed text content
      if (!is.null(text_content)) {
        tags$div(
          class = "detailed-results",
          style = "margin-top: 1.5rem;",
          text_content
        )
      },

      # Recommendations
      if (!is.null(recommendations) && length(recommendations) > 0) {
        create_recommendations_panel(recommendations)
      }
    )
  )

  result
}
