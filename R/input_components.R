# Input Component Helpers
# Statistical Power Analysis Tool
#
# This file contains helper functions for creating modern, styled input components
# including segmented controls (for significance level selection) and enhanced sliders.

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

    # Label
    tags$label(
      class = "control-label",
      `for` = inputId,
      label
    ),

    # Radio buttons with segmented control styling
    tags$div(
      class = "segmented-control",
      radioButtons(
        inputId = inputId,
        label = NULL,  # Label already added above
        choices = choices,
        selected = selected,
        inline = TRUE
      )
    )
  )

  # Add tooltip if provided
  if (!is.null(tooltip)) {
    container <- tagList(
      container,
      bsTooltip(inputId, tooltip, "right")
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

    # Label
    tags$label(
      class = "control-label",
      `for` = inputId,
      label
    ),

    # Radio buttons with segmented control styling
    tags$div(
      class = "segmented-control",
      radioButtons(
        inputId = inputId,
        label = NULL,
        choices = choices,
        selected = selected,
        inline = TRUE
      )
    )
  )

  # Add tooltip if provided
  if (!is.null(tooltip)) {
    container <- tagList(
      container,
      bsTooltip(inputId, tooltip, "right")
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
    container <- tagList(
      container,
      bsTooltip(inputId, tooltip, "right")
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
