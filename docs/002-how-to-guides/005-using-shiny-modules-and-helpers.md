# How to use Shiny modules and helper functions

**Type:** How-To
**Audience:** Developers
**Last Updated:** 2025-10-25

## Overview

This guide shows you how to use the newly created Shiny modules and helper functions to eliminate code duplication when adding new analysis types or maintaining existing ones.

## Prerequisites

- Familiarity with Shiny application structure
- Understanding of reactive programming concepts
- Basic knowledge of R modules

## What modules and helpers are available

### Modules (R/modules/)

**001-missing-data-module.R**
- Provides reusable UI and server logic for missing data adjustment
- Used in 6 sample size calculations
- Reduces 210+ lines to ~35 lines of module calls

### Helper Functions (R/helpers/)

**001-plot-helpers.R**
- `create_power_curve_plot()` - Standard power curve generation
- `generate_n_sequence()` - Sample size sequences for plots
- `create_power_curve_plot_twogroup()` - Two-group specific plots
- Consolidates ~880 lines of duplicated plotly code

**002-result-text-helpers.R**
- `create_result_header()` - Standard result header
- `format_missing_data_text()` - Missing data adjustment display
- `format_numeric()` - Consistent number formatting
- `create_power_single_result_text()` - Power analysis results
- `create_sample_size_result_text()` - Sample size results
- `format_effect_measures()` - RR, OR, RD display
- `format_hazard_ratio()` - Survival analysis interpretation
- `format_cohens_d()` - Continuous outcome interpretation

**R/input_components.R** (extended)
- `create_numeric_input_with_tooltip()` - Numeric input with tooltip
- Replaces 30+ instances of `numericInput()` + `bsTooltip()`

---

## How to use the missing data module

### Step 1: Add the module UI in your conditional panel

**Before (repeated 6 times, ~40 lines each):**
```r
checkboxInput("adjust_missing_ss_single", "Adjust for Missing Data", value = FALSE),
conditionalPanel(
  condition = "input.adjust_missing_ss_single",
  create_enhanced_slider("missing_pct_ss_single", "Expected Missingness (%):",
                        min = 5, max = 50, value = 20, step = 5, post = "%",
                        tooltip = "Percentage of participants..."),
  radioButtons_fixed("missing_mechanism_ss_single", "Missing Data Mechanism:", ...),
  radioButtons_fixed("missing_analysis_ss_single", "Planned Analysis Approach:", ...),
  conditionalPanel(
    condition = "input.missing_analysis_ss_single == 'multiple_imputation'",
    numericInput("mi_imputations_ss_single", "Number of Imputations (m):", ...),
    create_enhanced_slider("mi_r_squared_ss_single", "Expected Imputation Model R²:", ...)
  )
)
```

**After (1 line):**
```r
missing_data_ui(NS("ss_single", "missing_data"))
```

### Step 2: Add the module server logic

In your server function, call the module server:

```r
server <- function(input, output, session) {

  # Initialize missing data module for this analysis type
  missing_data_values_ss_single <- missing_data_server("ss_single-missing_data")

  # ... rest of server logic ...
}
```

### Step 3: Access missing data values reactively

**Before (direct input access):**
```r
if (input$adjust_missing_ss_single) {
  missing_adj <- calc_missing_data_inflation(
    n_calculated,
    input$missing_pct_ss_single,
    input$missing_mechanism_ss_single,
    input$missing_analysis_ss_single,
    ifelse(input$missing_analysis_ss_single == "multiple_imputation",
           input$mi_imputations_ss_single, 5),
    ifelse(input$missing_analysis_ss_single == "multiple_imputation",
           input$mi_r_squared_ss_single, 0.5)
  )
  n_final <- missing_adj$n_inflated
}
```

**After (module-based access):**
```r
# Use the helper function from the module
missing_result <- calculate_missing_inflation(
  n_calculated = sample_size_after_discon,
  missing_params = missing_data_values_ss_single,
  calc_missing_data_inflation = calc_missing_data_inflation
)
n_final <- missing_result$n_inflated
```

---

## How to use numeric input with tooltip helper

### Step 1: Replace numericInput + bsTooltip pairs

**Before (2 lines, repeated 30+ times):**
```r
numericInput("power_n", "Available Sample Size:", 230, min = 1, step = 1),
bsTooltip("power_n", "Total number of participants available for the study", "right"),
```

**After (1 line):**
```r
create_numeric_input_with_tooltip(
  "power_n", "Available Sample Size:", 230,
  min = 1, step = 1,
  tooltip = "Total number of participants available for the study"
),
```

### Benefits:
- Reduces from 2 lines to 1
- Consistent tooltip placement (always "right")
- Optional tooltip (pass `tooltip = NULL` to skip)
- More readable and maintainable

---

## How to use plot helper functions

### Step 1: Generate sample size sequence

**Before (repeated 11 times):**
```r
n_current <- input$power_n
n_seq <- seq(max(10, floor(n_current * 0.25)),
            floor(n_current * 4),
            length.out = 100)
```

**After:**
```r
n_current <- input$power_n
n_seq <- generate_n_sequence(n_current)
```

### Step 2: Calculate power values

This step remains the same (calculation logic is specific to each analysis type):

```r
pow <- vapply(n_seq, function(n) {
  pwr.p.test(
    sig.level = input$power_alpha,
    power = NULL,
    h = ES.h(1 / input$power_p, 0),
    alt = "greater",
    n = n
  )$power
}, FUN.VALUE = numeric(1))
```

### Step 3: Create the plot

**Before (50+ lines of plotly code):**
```r
plot_ly() %>%
  add_trace(
    x = n_seq, y = pow, type = "scatter", mode = "lines",
    line = list(color = "#2B5876", width = 3),
    name = "Power Curve",
    hovertemplate = paste0(
      "<b>Sample Size:</b> %{x:.0f}<br>",
      "<b>Power:</b> %{y:.3f}<br>",
      "<extra></extra>"
    )
  ) %>%
  add_trace(
    x = range(n_seq), y = c(0.8, 0.8),
    type = "scatter", mode = "lines",
    line = list(color = "red", width = 2, dash = "dash"),
    name = "80% Power Target",
    hovertemplate = "<b>Target Power:</b> 80%<extra></extra>"
  ) %>%
  add_trace(
    x = c(n_current, n_current), y = c(0, 1),
    type = "scatter", mode = "lines",
    line = list(color = "green", width = 2, dash = "dot"),
    name = "Current N",
    hovertemplate = paste0("<b>Current N:</b> ", n_current, "<extra></extra>")
  ) %>%
  layout(
    title = list(text = "Interactive Power Curve", font = list(size = 16)),
    xaxis = list(title = "Sample Size (N)", gridcolor = "#e0e0e0"),
    yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
    hovermode = "closest",
    plot_bgcolor = "#f8f9fa",
    paper_bgcolor = "white",
    legend = list(x = 0.7, y = 0.2)
  ) %>%
  config(displayModeBar = TRUE, displaylogo = FALSE)
```

**After (1 function call):**
```r
create_power_curve_plot(
  n_seq = n_seq,
  power_vals = pow,
  n_current = n_current,
  target_power = 0.8,
  plot_title = "Interactive Power Curve (Single Proportion)",
  xaxis_title = "Sample Size (N)",
  n_reference_label = "Current N"
)
```

---

## How to use result text helper functions

### Step 1: Use formatting helpers for consistent output

**Before:**
```r
text3 <- p(paste0(
  "Based on the Binomial distribution and a true event incidence rate of 1 in ",
  format(incidence_rate, digits = 0, nsmall = 0), " (or ",
  format(1 / incidence_rate * 100, digits = 2, nsmall = 2), "%), with ",
  format(ceiling(sample_size), digits = 0, nsmall = 0),
  " participants, the probability of observing at least one event is ",
  format(power * 100, digits = 0, nsmall = 0), "% (α = ",
  input$power_alpha, ")."
))
```

**After:**
```r
create_power_single_result_text(
  incidence_rate = input$power_p,
  sample_size = input$power_n,
  power = calculated_power,
  alpha = input$power_alpha,
  discon = input$power_discon / 100
)
```

### Step 2: Format missing data adjustment

**Before (10+ lines):**
```r
if (input$adjust_missing_ss_single) {
  missing_data_text <- HTML(paste0(
    "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
    "<strong>Missing Data Adjustment:</strong> ",
    missing_adj$interpretation,
    "<br><strong>Sample size before missing data adjustment:</strong> ",
    sample_size_after_discon,
    "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
    "</p>"
  ))
}
```

**After (1 function call):**
```r
missing_text <- format_missing_data_text(missing_adj, n_before = sample_size_after_discon)
```

### Step 3: Use the complete sample size result template

```r
result_html <- create_sample_size_result_text(
  main_text = "Your customized main paragraph here...",
  n_base = sample_size_base,
  n_after_discon = sample_size_after_discon,
  n_final = sample_size_final,
  discon = input$ss_discon / 100,
  missing_adj = missing_adj_result,  # or NULL if not applicable
  additional_info = format_effect_measures(effect_vals)  # optional
)
```

---

## Complete example: Refactoring one analysis tab

Here's how to refactor the "Sample Size (Single)" tab using all new modules and helpers:

### UI Section

**Before (~84 lines):**
```r
conditionalPanel(
  condition = "input.sidebar_page == 'ss_single'",
  h2(class = "page-title", "Sample Size Calculator (Single Proportion)"),
  helpText("Calculate required sample size..."),
  hr(),

  radioButtons_fixed("ss_single_calc_mode", "Calculation Mode:", ...),

  conditionalPanel(
    condition = "input.ss_single_calc_mode == 'calc_n'",
    numericInput("ss_p", "Expected Event Rate (per 100):", 10, min = 0.1, max = 100, step = 0.1),
    bsTooltip("ss_p", "Number of events expected per 100 participants", "right")
  ),

  create_segmented_power("ss_power", "Desired Power:", selected = 80, ...),
  create_segmented_alpha("ss_alpha", "Significance Level (α):", selected = 0.05, ...),
  create_enhanced_slider("ss_discon", "Withdrawal/Discontinuation Rate (%):", ...),

  # 40 lines of missing data UI
  checkboxInput("adjust_missing_ss_single", "Adjust for Missing Data", ...),
  conditionalPanel(...),

  hr(),
  div(class = "btn-group-custom",
    actionButton("example_ss_single", "Load Example", ...),
    actionButton("reset_ss_single", "Reset", ...)
  )
)
```

**After (~35 lines, 58% reduction):**
```r
conditionalPanel(
  condition = "input.sidebar_page == 'ss_single'",
  h2(class = "page-title", "Sample Size Calculator (Single Proportion)"),
  helpText("Calculate required sample size..."),
  hr(),

  radioButtons_fixed("ss_single_calc_mode", "Calculation Mode:", ...),

  conditionalPanel(
    condition = "input.ss_single_calc_mode == 'calc_n'",
    create_numeric_input_with_tooltip(
      "ss_p", "Expected Event Rate (per 100):", 10,
      min = 0.1, max = 100, step = 0.1,
      tooltip = "Number of events expected per 100 participants"
    )
  ),

  create_segmented_power("ss_power", "Desired Power:", selected = 80, ...),
  create_segmented_alpha("ss_alpha", "Significance Level (α):", selected = 0.05, ...),
  create_enhanced_slider("ss_discon", "Withdrawal/Discontinuation Rate (%):", ...),

  # 1 line for missing data UI
  missing_data_ui(NS("ss_single", "missing_data")),

  hr(),
  div(class = "btn-group-custom",
    actionButton("example_ss_single", "Load Example", ...),
    actionButton("reset_ss_single", "Reset", ...)
  )
)
```

### Server Section

**Before (~120 lines for result_text):**
```r
output$result_text <- renderUI({
  if (!v$doAnalysis) return()
  isolate({
    if (input$tabset == "Sample Size (Single)") {
      # 30 lines of calculation
      sample_size_base <- pwr.p.test(...)$n
      sample_size_after_discon <- ceiling(sample_size_base * (1 + discon))

      # 40 lines of missing data adjustment
      if (input$adjust_missing_ss_single) {
        missing_adj <- calc_missing_data_inflation(...)
        sample_size_final <- missing_adj$n_inflated
        missing_data_text <- HTML(paste0(...))  # 10 lines
      } else {
        sample_size_final <- sample_size_after_discon
        missing_data_text <- HTML("")
      }

      # 50 lines of HTML text generation
      text0 <- hr()
      text1 <- h1("Results of this analysis")
      text2 <- h4("(This text can be copy/pasted...)")
      text3 <- p(paste0("To detect an event rate of ...", ...))
      HTML(paste0(text0, text1, text2, text3, missing_data_text))
    }
  })
})
```

**After (~40 lines, 67% reduction):**
```r
# Initialize module
missing_data_vals <- missing_data_server("ss_single-missing_data")

output$result_text <- renderUI({
  if (!v$doAnalysis) return()
  isolate({
    if (input$tabset == "Sample Size (Single)") {
      # Calculate base sample size
      sample_size_base <- pwr.p.test(
        sig.level = input$ss_alpha,
        power = input$ss_power / 100,
        h = ES.h(1 / input$ss_p, 0),
        alt = "greater",
        n = NULL
      )$n

      # Apply discontinuation adjustment
      discon <- input$ss_discon / 100
      sample_size_after_discon <- ceiling(sample_size_base * (1 + discon))

      # Apply missing data adjustment using module
      missing_result <- calculate_missing_inflation(
        n_calculated = sample_size_after_discon,
        missing_params = missing_data_vals,
        calc_missing_data_inflation = calc_missing_data_inflation
      )

      # Generate result text using helper
      main_text <- paste0(
        "To detect an event rate of 1 in ", format_numeric(input$ss_p, as_integer = TRUE),
        " with ", format_numeric(input$ss_power, digits = 0), "% power at α = ",
        input$ss_alpha, ", you need ", format_numeric(sample_size_base, as_integer = TRUE),
        " participants."
      )

      create_sample_size_result_text(
        main_text = main_text,
        n_base = sample_size_base,
        n_after_discon = sample_size_after_discon,
        n_final = missing_result$n_inflated,
        discon = discon,
        missing_adj = if (missing_data_vals()$adjust_missing) missing_result else NULL
      )
    }
  })
})
```

### Power Curve Plot

**Before (~55 lines):**
```r
output$power_plot <- renderPlotly({
  if (!v$doAnalysis) return()
  isolate({
    if (input$tabset == "Sample Size (Single)") {
      # Generate sequence
      n_required <- pwr.p.test(...)$n
      n_seq <- seq(max(10, floor(n_required * 0.25)), floor(n_required * 3), length.out = 100)

      # Calculate power
      pow <- vapply(n_seq, function(n) {
        pwr.p.test(sig.level = input$ss_alpha, power = NULL,
                   h = ES.h(1 / input$ss_p, 0), alt = "greater", n = n)$power
      }, FUN.VALUE = numeric(1))

      # Create plot (40 lines)
      plot_ly() %>% add_trace(...) %>% add_trace(...) %>% layout(...)
    }
  })
})
```

**After (~15 lines, 73% reduction):**
```r
output$power_plot <- renderPlotly({
  if (!v$doAnalysis) return()
  isolate({
    if (input$tabset == "Sample Size (Single)") {
      # Calculate required N
      n_required <- pwr.p.test(
        sig.level = input$ss_alpha,
        power = input$ss_power / 100,
        h = ES.h(1 / input$ss_p, 0),
        alt = "greater",
        n = NULL
      )$n

      # Generate sequence
      n_seq <- generate_n_sequence_for_ss(n_required)

      # Calculate power for each N
      pow <- vapply(n_seq, function(n) {
        pwr.p.test(sig.level = input$ss_alpha, power = NULL,
                   h = ES.h(1 / input$ss_p, 0), alt = "greater", n = n)$power
      }, FUN.VALUE = numeric(1))

      # Create plot using helper
      create_power_curve_plot(
        n_seq = n_seq,
        power_vals = pow,
        n_current = ceiling(n_required),
        target_power = input$ss_power / 100,
        plot_title = "Interactive Power Curve (Single Proportion)",
        n_reference_label = "Required N"
      )
    }
  })
})
```

---

## Benefits summary

| Aspect | Before | After | Improvement |
|--------|--------|-------|-------------|
| **UI Code** | 84 lines | 35 lines | 58% reduction |
| **Server Result Text** | 120 lines | 40 lines | 67% reduction |
| **Server Plot Code** | 55 lines | 15 lines | 73% reduction |
| **Total for One Tab** | 259 lines | 90 lines | 65% reduction |
| **Maintainability** | Low (fix in 11 places) | High (fix once) | Major improvement |
| **Consistency** | Manual | Automatic | Guaranteed |
| **Testing** | Difficult | Easy (test modules) | Much easier |

---

## Troubleshooting

### Module namespace issues

If you get errors like "object not found":

**Problem:** Incorrect namespace construction

```r
# Wrong
missing_data_ui("missing_data")

# Correct
missing_data_ui(NS("ss_single", "missing_data"))
```

### Reactive values not updating

**Problem:** Forgetting to call the reactive

```r
# Wrong
if (missing_data_vals$adjust_missing) { ... }

# Correct
if (missing_data_vals()$adjust_missing) { ... }
```

### Plot not rendering

**Problem:** Missing required parameters

```r
# Make sure all required parameters are provided
create_power_curve_plot(
  n_seq = n_seq,           # Required
  power_vals = pow,         # Required
  n_current = n_current     # Required
  # Optional: target_power, plot_title, etc.
)
```

---

## Next steps

- Review the complete refactored example in this guide
- Start refactoring one analysis tab at a time
- Test thoroughly after each refactoring
- Consider creating additional helper functions for analysis-specific logic
- Document any new patterns you discover

---

**Related Documentation:**
- [Code Duplication Analysis Report](/docs/004-explanation/003-code-duplication-and-refactoring-analysis.md)
- [CLAUDE.md](/CLAUDE.md) - Documentation standards

**References:**
- [Shiny Modules Documentation](https://shiny.rstudio.com/articles/modules.html)
- [Context7 Shiny Best Practices](/rstudio/shiny)
