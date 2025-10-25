# Plot Helper Functions
#
# Consolidates repeated plotly power curve generation code that appears
# 11 times throughout the application (once per analysis type).
#
# This follows DRY principles by extracting common plotting logic
# into reusable functions.

#' Create Standard Power Curve Plot
#'
#' Generates a standardized interactive Plotly power curve with consistent
#' styling across all analysis types. Replaces ~80 lines of duplicated
#' code per analysis type.
#'
#' @param n_seq Numeric vector of sample sizes
#' @param power_vals Numeric vector of power values corresponding to n_seq
#' @param n_current Current or required sample size (for reference line)
#' @param target_power Target power level (default 0.8 for 80%)
#' @param plot_title Title for the plot
#' @param xaxis_title Title for x-axis (default "Sample Size (N)")
#' @param n_reference_label Label for the vertical reference line
#'
#' @return A plotly object
#'
#' @examples
#' n_seq <- seq(50, 500, length.out = 100)
#' power_vals <- sapply(n_seq, function(n) pwr.p.test(n = n, ...)$power)
#' create_power_curve_plot(n_seq, power_vals, n_current = 230)
create_power_curve_plot <- function(n_seq,
                                   power_vals,
                                   n_current,
                                   target_power = 0.8,
                                   plot_title = "Interactive Power Curve",
                                   xaxis_title = "Sample Size (N)",
                                   n_reference_label = "Current N") {

  # Validate inputs
  if (length(n_seq) != length(power_vals)) {
    stop("n_seq and power_vals must have the same length")
  }

  # Create the base plotly object with power curve
  p <- plot_ly() %>%
    add_trace(
      x = n_seq,
      y = power_vals,
      type = "scatter",
      mode = "lines",
      line = list(color = "#2B5876", width = 3),
      name = "Power Curve",
      hovertemplate = paste0(
        "<b>Sample Size:</b> %{x:.0f}<br>",
        "<b>Power:</b> %{y:.3f}<br>",
        "<extra></extra>"
      )
    ) %>%
    # Add target power reference line (horizontal)
    add_trace(
      x = range(n_seq),
      y = c(target_power, target_power),
      type = "scatter",
      mode = "lines",
      line = list(color = "red", width = 2, dash = "dash"),
      name = sprintf("%.0f%% Power Target", target_power * 100),
      hovertemplate = sprintf("<b>Target Power:</b> %.0f%%<extra></extra>", target_power * 100)
    ) %>%
    # Add current/required N reference line (vertical)
    add_trace(
      x = c(n_current, n_current),
      y = c(0, 1),
      type = "scatter",
      mode = "lines",
      line = list(color = "green", width = 2, dash = "dot"),
      name = n_reference_label,
      hovertemplate = paste0("<b>", n_reference_label, ":</b> ", round(n_current), "<extra></extra>")
    ) %>%
    # Apply consistent layout styling
    layout(
      title = list(text = plot_title, font = list(size = 16)),
      xaxis = list(title = xaxis_title, gridcolor = "#e0e0e0"),
      yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
      hovermode = "closest",
      plot_bgcolor = "#f8f9fa",
      paper_bgcolor = "white",
      legend = list(x = 0.7, y = 0.2)
    ) %>%
    config(displayModeBar = TRUE, displaylogo = FALSE)

  return(p)
}


#' Generate Sample Size Sequence for Power Curve
#'
#' Creates a sequence of sample sizes for power curve generation,
#' centered around a reference value (current or required N).
#'
#' @param n_reference Reference sample size (current or required)
#' @param min_multiplier Minimum as fraction of reference (default 0.25)
#' @param max_multiplier Maximum as multiple of reference (default 4)
#' @param n_points Number of points to generate (default 100)
#' @param absolute_min Absolute minimum sample size (default 10)
#'
#' @return Numeric vector of sample sizes
#'
#' @examples
#' generate_n_sequence(n_reference = 230)
#' # Returns: seq from ~58 to 920 with 100 points
generate_n_sequence <- function(n_reference,
                                min_multiplier = 0.25,
                                max_multiplier = 4,
                                n_points = 100,
                                absolute_min = 10) {

  n_min <- max(absolute_min, floor(n_reference * min_multiplier))
  n_max <- floor(n_reference * max_multiplier)

  seq(n_min, n_max, length.out = n_points)
}


#' Generate Sample Size Sequence for Sample Size Calculations
#'
#' Variant for sample size calculation plots where the range
#' is typically narrower around the required N.
#'
#' @param n_required Required sample size from calculation
#' @param min_multiplier Minimum as fraction of required (default 0.25)
#' @param max_multiplier Maximum as multiple of required (default 3)
#' @param n_points Number of points to generate (default 100)
#' @param absolute_min Absolute minimum sample size (default 10)
#'
#' @return Numeric vector of sample sizes
generate_n_sequence_for_ss <- function(n_required,
                                       min_multiplier = 0.25,
                                       max_multiplier = 3,
                                       n_points = 100,
                                       absolute_min = 10) {

  n_min <- max(absolute_min, floor(n_required * min_multiplier))
  n_max <- floor(n_required * max_multiplier)

  seq(n_min, n_max, length.out = n_points)
}


#' Create Power Curve Plot for Two-Group Designs
#'
#' Specialized variant for two-group comparisons where the x-axis
#' can represent total N or N per group.
#'
#' @param n_seq Numeric vector of sample sizes
#' @param power_vals Numeric vector of power values
#' @param n_current Current or required sample size
#' @param target_power Target power level (default 0.8)
#' @param plot_title Title for the plot
#' @param per_group If TRUE, x-axis labeled as "per group" (default FALSE)
#'
#' @return A plotly object
create_power_curve_plot_twogroup <- function(n_seq,
                                             power_vals,
                                             n_current,
                                             target_power = 0.8,
                                             plot_title = "Interactive Power Curve",
                                             per_group = FALSE) {

  xaxis_label <- if (per_group) {
    "Sample Size per Group (n)"
  } else {
    "Total Sample Size (N)"
  }

  create_power_curve_plot(
    n_seq = n_seq,
    power_vals = power_vals,
    n_current = n_current,
    target_power = target_power,
    plot_title = plot_title,
    xaxis_title = xaxis_label,
    n_reference_label = if (per_group) "Current n" else "Current N"
  )
}


#' Create Empty Plot with Message
#'
#' Returns an empty plotly object with a centered message.
#' Useful for showing informative messages when plots can't be generated.
#'
#' @param message Message to display
#'
#' @return A plotly object
create_empty_plot <- function(message = "No data available") {
  plot_ly() %>%
    layout(
      title = list(text = message, font = list(size = 14)),
      xaxis = list(visible = FALSE),
      yaxis = list(visible = FALSE),
      plot_bgcolor = "#f8f9fa",
      paper_bgcolor = "white"
    ) %>%
    config(displayModeBar = FALSE)
}
