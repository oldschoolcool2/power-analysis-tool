# Input Component Helpers
# Statistical Power Analysis Tool
#
# This file contains helper functions for creating modern, styled input components
# including segmented controls (for significance level selection) and enhanced sliders.

#' Create Radio Buttons Without Label Tag
#'
#' Wrapper around radioButtons that replaces the <label> tag with a <div>
#' to fix accessibility validation errors. Radio button groups should not
#' use <label for="..."> tags since the 'for' attribute would point to a
#' container div, not an actual input element.
#'
#' @param inputId The input slot that will be used to access the value
#' @param label Display label text for the radio group (or NULL for no label)
#' @param choices List of values to select from
#' @param selected The initially selected value
#' @param inline If TRUE, render choices inline
#' @param ... Additional arguments passed to radioButtons
#'
#' @return A Shiny tag element with div instead of label
radioButtons_fixed <- function(inputId, label, choices, selected = NULL, inline = FALSE, ...) {
  # Create standard radioButtons with NULL label to avoid the problematic <label> tag
  rb <- radioButtons(inputId = inputId, label = NULL, choices = choices,
                     selected = selected, inline = inline, ...)

  # If a label was provided, add it as a styled div (not a <label> tag)
  if (!is.null(label) && label != "") {
    # Create a div that looks like a label but doesn't have the accessibility issue
    label_div <- tags$div(
      class = "control-label",
      style = "margin-bottom: 5px;",
      label
    )

    # Insert the label div as the first child
    rb$children <- c(list(label_div), rb$children)
  }

  return(rb)
}


#' Create Segmented Control for Significance Level (Alpha)
#'
#' Replaces slider input with a precise button group/segmented control.
#' Users can select common alpha values with a single click.
#'
#' @param inputId The input slot that will be used to access the value
#' @param label Display label for the input
#' @param choices Named vector of choices (e.g., c("0.01" = 0.01, "0.05" = 0.05))
#' @param selected The initially selected value
#' @param tooltip Optional tooltip text to display
#'
#' @return A Shiny tag element with segmented control styling
#'
#' @examples
#' create_segmented_alpha("power_alpha", "Significance Level (α):",
#'                        selected = 0.05, tooltip = "Type I error rate")
create_segmented_alpha <- function(inputId,
                                   label = "Significance Level (α):",
                                   choices = c("0.01" = 0.01,
                                             "0.025" = 0.025,
                                             "0.05" = 0.05,
                                             "0.10" = 0.10),
                                   selected = 0.05,
                                   tooltip = NULL) {

  # Create the segmented control container
  container <- tags$div(
    class = "form-group segmented-control-wrapper",

    # Radio buttons with segmented control styling
    # Label is passed to radioButtons_fixed which creates it without 'for' attribute
    tags$div(
      class = "segmented-control",
      radioButtons_fixed(
        inputId = inputId,
        label = label,
        choices = choices,
        selected = selected,
        inline = TRUE
      )
    )
  )

  # Add tooltip if provided
  if (!is.null(tooltip)) {
    container <- bslib::tooltip(
      container,
      tooltip,
      placement = "right"
    )
  }

  return(container)
}


#' Create Segmented Control for Power Level
#'
#' Similar to create_segmented_alpha but for power level selection.
#' Common power values are 70%, 80%, 90%, 95%.
#'
#' @param inputId The input slot that will be used to access the value
#' @param label Display label for the input
#' @param choices Named vector of choices (in percentage form)
#' @param selected The initially selected value (as percentage, e.g., 80)
#' @param tooltip Optional tooltip text to display
#'
#' @return A Shiny tag element with segmented control styling
create_segmented_power <- function(inputId,
                                   label = "Desired Power:",
                                   choices = c("70%" = 70,
                                             "80%" = 80,
                                             "90%" = 90,
                                             "95%" = 95),
                                   selected = 80,
                                   tooltip = NULL) {

  # Create the segmented control container
  container <- tags$div(
    class = "form-group segmented-control-wrapper",

    # Radio buttons with segmented control styling
    # Label is passed to radioButtons_fixed which creates it without 'for' attribute
    tags$div(
      class = "segmented-control",
      radioButtons_fixed(
        inputId = inputId,
        label = label,
        choices = choices,
        selected = selected,
        inline = TRUE
      )
    )
  )

  # Add tooltip if provided
  if (!is.null(tooltip)) {
    container <- bslib::tooltip(
      container,
      tooltip,
      placement = "right"
    )
  }

  return(container)
}


#' Create Enhanced Slider Input
#'
#' Wraps a standard sliderInput with better styling, including:
#' - Clear label above slider
#' - Value display
#' - Better spacing and visual hierarchy
#'
#' @param inputId The input slot that will be used to access the value
#' @param label Display label for the input
#' @param min Minimum value
#' @param max Maximum value
#' @param value Initial value
#' @param step Step size
#' @param post Optional string to append to value display (e.g., "%")
#' @param tooltip Optional tooltip text to display
#'
#' @return A Shiny tag element with enhanced slider styling
#'
#' @examples
#' create_enhanced_slider("withdrawal_rate", "Withdrawal Rate:",
#'                       min = 0, max = 50, value = 10, step = 1,
#'                       post = "%", tooltip = "Expected dropout rate")
create_enhanced_slider <- function(inputId,
                                  label,
                                  min,
                                  max,
                                  value,
                                  step = 1,
                                  post = NULL,
                                  tooltip = NULL) {

  # Create the enhanced slider container
  container <- tags$div(
    class = "form-group enhanced-slider-wrapper",

    # Slider input (standard Shiny slider)
    sliderInput(
      inputId = inputId,
      label = label,
      min = min,
      max = max,
      value = value,
      step = step,
      post = post
    )
  )

  # Add tooltip if provided
  if (!is.null(tooltip)) {
    container <- bslib::tooltip(
      container,
      tooltip,
      placement = "right"
    )
  }

  return(container)
}


#' Create Primary Action Button
#'
#' Creates a full-width primary button (typically for "Calculate" actions).
#'
#' @param inputId The input slot that will be used to access the button
#' @param label Display label for the button
#' @param icon Optional icon to display
#'
#' @return A Shiny action button with primary styling
create_primary_button <- function(inputId,
                                  label = "Calculate",
                                  icon = icon("calculator")) {

  actionButton(
    inputId = inputId,
    label = label,
    icon = icon,
    class = "btn-primary btn-lg",
    width = "100%"
  )
}


#' Create Button Group (Secondary Actions)
#'
#' Creates a horizontal button group for secondary actions like "Load Example" and "Reset".
#'
#' @param buttons List of button definitions (each with id, label, icon, class)
#'
#' @return A Shiny tag element with button group styling
#'
#' @examples
#' create_button_group(list(
#'   list(id = "load_example", label = "Load Example", icon = "lightbulb"),
#'   list(id = "reset", label = "Reset", icon = "refresh")
#' ))
create_button_group <- function(buttons) {

  button_elements <- lapply(buttons, function(btn) {
    actionButton(
      inputId = btn$id,
      label = btn$label,
      icon = icon(btn$icon),
      class = paste("btn-secondary btn-sm", btn$class %||% "")
    )
  })

  tags$div(
    class = "btn-group-custom",
    button_elements
  )
}


#' Create Numeric Input with Optional Tooltip and Validation
#'
#' Creates a numericInput and optionally attaches a tooltip and real-time validation.
#' This consolidates the repeated pattern of numericInput with tooltips
#' that appears 30+ times throughout the application.
#'
#' @param inputId The input slot that will be used to access the value
#' @param label Display label for the input
#' @param value Initial/default value
#' @param min Minimum allowed value
#' @param max Maximum allowed value
#' @param step Increment step size
#' @param tooltip Optional tooltip text to display (NULL means no tooltip)
#' @param validation_type Optional validation type for real-time validation
#'   (e.g., "sample_size", "power", "proportion", "hazard_ratio", "event_rate")
#'
#' @return A tagList containing numericInput and optional tooltip
#'
#' @importFrom shiny numericInput tagList
#' @importFrom bslib tooltip
#'
#' @examples
#' create_numeric_input_with_tooltip(
#'   "sample_size", "Sample Size:", 230, min = 1, step = 1,
#'   tooltip = "Total number of participants available for the study",
#'   validation_type = "sample_size"
#' )
#' create_numeric_input_with_tooltip(
#'   "hr", "Hazard Ratio:", 0.75, min = 0.01, max = 100, step = 0.01,
#'   tooltip = "Expected hazard ratio between groups",
#'   validation_type = "hazard_ratio"
#' )
create_numeric_input_with_tooltip <- function(inputId,
                                              label,
                                              value = 100,
                                              min = NULL,
                                              max = NULL,
                                              step = 1,
                                              tooltip = NULL,
                                              validation_type = NULL,
                                              help_content = NULL) {

  # Create the numeric input
  # Build arguments list, only including min/max if not NULL
  input_args <- list(
    inputId = inputId,
    label = label,
    value = value,
    step = step
  )
  
  if (!is.null(min)) input_args$min <- min
  if (!is.null(max)) input_args$max <- max
  
  input_element <- do.call(numericInput, input_args)

  # Add validation attribute if validation type is specified
  if (!is.null(validation_type)) {
    # Find the input element and add data-validate attribute
    input_tag <- input_element$children[[2]]  # The actual input is the second child
    if (!is.null(input_tag) && inherits(input_tag, "shiny.tag")) {
      input_tag$attribs$`data-validate` <- validation_type
    }
  }

  # Wrap with contextual help icon if help_content is provided
  if (!is.null(help_content)) {
    input_element <- create_input_with_help_icon(inputId, input_element, help_content)
  }

  # Add tooltip if provided
  if (!is.null(tooltip) && tooltip != "") {
    return(
      bslib::tooltip(
        input_element,
        tooltip,
        placement = "right"
      )
    )
  }

  return(input_element)
}


#' Create Progressive Disclosure Section
#'
#' Creates a collapsible section for advanced options using progressive disclosure.
#' This reduces cognitive load by hiding complex options until needed.
#'
#' @param id Unique identifier for the collapsible section
#' @param title Section title (default: "Advanced Options")
#' @param content Shiny UI content to display when expanded
#' @param icon_name Optional icon name (default: "sliders")
#' @param initially_open Whether the section should start expanded (default: FALSE)
#'
#' @return A Shiny tag element with collapsible section
#'
#' @examples
#' create_progressive_disclosure(
#'   "advanced_opts",
#'   "Advanced Options",
#'   tagList(
#'     sliderInput("discon", "Discontinuation Rate:", 0, 50, 10),
#'     radioButtons("alpha", "Alpha:", c("0.05" = 0.05, "0.01" = 0.01))
#'   )
#' )
#'
#' @importFrom shiny tags icon
create_progressive_disclosure <- function(id,
                                         title = "Advanced Options",
                                         content,
                                         icon_name = "sliders",
                                         initially_open = FALSE) {

  collapse_class <- if (initially_open) "collapse show" else "collapse"

  tags$div(
    class = "progressive-disclosure-wrapper",
    style = "margin: var(--space-4) 0;",

    # Toggle button
    tags$button(
      class = "btn btn-outline-secondary btn-block progressive-disclosure-toggle",
      type = "button",
      `data-bs-toggle` = "collapse",
      `data-bs-target` = paste0("#", id),
      `aria-expanded` = tolower(as.character(initially_open)),
      `aria-controls` = id,
      style = "width: 100%; text-align: left; display: flex; align-items: center; justify-content: space-between; padding: var(--space-3) var(--space-4); border-radius: var(--border-radius-md); transition: all var(--transition-base);",

      tags$span(
        style = "display: flex; align-items: center; gap: var(--space-2);",
        icon(icon_name),
        title
      ),
      icon("chevron-down", class = "toggle-icon")
    ),

    # Collapsible content
    tags$div(
      id = id,
      class = collapse_class,
      style = "margin-top: var(--space-3);",
      tags$div(
        class = "progressive-disclosure-content",
        style = "padding: var(--space-4); background: var(--bg-card); border: var(--border-subtle); border-radius: var(--border-radius-md); box-shadow: var(--shadow-sm);",
        content
      )
    )
  )
}


#' Create Tabbed Options Section
#'
#' Creates a tabbed interface for organizing related options into groups.
#'
#' @param id Unique identifier for the tabbed section
#' @param tabs List of tab definitions, each with title and content
#'
#' @return A Shiny tag element with tabbed interface
#'
#' @examples
#' create_tabbed_options(
#'   "analysis_opts",
#'   list(
#'     list(title = "Basic", content = tagList(numericInput("n", "N:", 100))),
#'     list(title = "Advanced", content = tagList(sliderInput("alpha", "Alpha:", 0, 1, 0.05)))
#'   )
#' )
#'
#' @importFrom shiny tags
create_tabbed_options <- function(id, tabs) {
  tab_ids <- paste0(id, "_tab", seq_along(tabs))

  # Tab navigation
  nav_tabs <- tags$ul(
    class = "nav nav-tabs",
    role = "tablist",
    lapply(seq_along(tabs), function(i) {
      active_class <- if (i == 1) "nav-link active" else "nav-link"
      aria_selected <- if (i == 1) "true" else "false"

      tags$li(
        class = "nav-item",
        role = "presentation",
        tags$button(
          class = active_class,
          id = paste0(tab_ids[i], "-tab"),
          `data-bs-toggle` = "tab",
          `data-bs-target` = paste0("#", tab_ids[i]),
          type = "button",
          role = "tab",
          `aria-controls` = tab_ids[i],
          `aria-selected` = aria_selected,
          tabs[[i]]$title
        )
      )
    })
  )

  # Tab content
  tab_content <- tags$div(
    class = "tab-content",
    style = "padding: var(--space-4) 0;",
    lapply(seq_along(tabs), function(i) {
      active_class <- if (i == 1) "tab-pane fade show active" else "tab-pane fade"

      tags$div(
        class = active_class,
        id = tab_ids[i],
        role = "tabpanel",
        `aria-labelledby` = paste0(tab_ids[i], "-tab"),
        tabs[[i]]$content
      )
    })
  )

  tags$div(
    class = "tabbed-options-wrapper",
    nav_tabs,
    tab_content
  )
}


#' Create Input with Contextual Help Icon
#'
#' Wraps an input element with a "?" help icon that shows detailed contextual help.
#' The help icon appears next to the label and opens a popover with examples and guidance.
#'
#' @param inputId The input element's ID
#' @param input_element The Shiny input element to wrap
#' @param help_content HTML content to display in the help popover (can include examples, formulas, etc.)
#'
#' @return A Shiny tag element with input and help icon
#'
#' @examples
#' create_input_with_help_icon(
#'   "icc",
#'   numericInput("icc", "ICC:", 0.05),
#'   HTML("<strong>Intraclass Correlation Coefficient</strong><br>
#'         Measures similarity within clusters.<br>
#'         <em>Example:</em> ICC = 0.05 is typical for community interventions")
#' )
#'
#' @importFrom shiny tags HTML icon
create_input_with_help_icon <- function(inputId, input_element, help_content) {
  help_icon_id <- paste0(inputId, "_help_icon")

  # Modify the label to include the help icon
  # The input element structure: list with children, first child is the label
  if (length(input_element$children) > 0 && inherits(input_element$children[[1]], "shiny.tag")) {
    label_element <- input_element$children[[1]]

    # Add help icon to the label
    label_element$children <- list(
      label_element$children,  # Original label text
      tags$button(
        id = help_icon_id,
        class = "contextual-help-icon",
        type = "button",
        style = "margin-left: 6px; background: none; border: none; color: var(--color-primary); cursor: pointer; font-size: 14px; padding: 0; vertical-align: middle;",
        icon("question-circle"),  # Changed from circle-question to question-circle
        `data-bs-toggle` = "popover",
        `data-bs-placement` = "right",
        `data-bs-trigger` = "click focus",
        `data-bs-html` = "true",
        `data-bs-content` = as.character(help_content),
        title = "Help",
        tabindex = "0",
        onclick = "event.preventDefault();"
      )
    )

    input_element$children[[1]] <- label_element
  }

  return(input_element)
}
