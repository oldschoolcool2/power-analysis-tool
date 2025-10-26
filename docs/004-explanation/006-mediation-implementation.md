# Mediation Analysis Implementation Guide

**Status:** 80% Complete - Remaining Steps Below
**Date:** 2025-10-26

## What's Been Completed

✅ Created `R/fct_mediation.R` - Statistical helper functions
✅ Created `R/mod_08_mediation.R` - UI and server module
✅ Added to sidebar navigation (`R/utils_ui_sidebar.R`)
✅ Added to `app_ui.R` - Module UI integration
✅ Added to `app_server.R` - Module server initialization (line 52)
✅ Added contextual help content (`R/utils_ui_help.R`)

## Remaining Implementation Steps

### Step 1: Add Result Calculation Logic to app_server.R

**Location:** Find the large `observe({ ... })` or `reactive({ ... })` block that handles `output$result_text`

**Add this code after the VIF calculator section** (look for `sidebar_page == 'vif_calculator'` and add after it):

```r
} else if (input$sidebar_page == "mediation_analysis") {
  # ============================================================
  # MEDIATION ANALYSIS
  # ============================================================

  # Get module inputs
  med_inputs <- tab8_vals$inputs()

  # Extract values
  calc_mode <- med_inputs$calc_mode
  a <- med_inputs$path_a
  b <- med_inputs$path_b
  c_prime <- med_inputs$path_c_prime
  alpha <- med_inputs$med_alpha
  alternative <- med_inputs$med_sided

  # Handle standard errors (use input or estimate from N)
  se_a <- if (!is.na(med_inputs$se_a)) med_inputs$se_a else NULL
  se_b <- if (!is.na(med_inputs$se_b)) med_inputs$se_b else NULL

  # Calculate based on mode
  if (calc_mode == "calc_power") {
    # Calculate power given N
    n <- med_inputs$med_n
    power <- calc_mediation_power(n, a, b, se_a, se_b, alpha, alternative)

    # Build result text
    result_html <- HTML(paste0(
      "<h1>Mediation Analysis Results: Power Calculation</h1>",
      "<hr>",
      "<h4>(Copy/paste this text into your protocol)</h4>",
      "<p>With a sample size of <strong>N = ", format_numeric(n, 0), "</strong> participants, ",
      "the study has <strong>", format_numeric(power * 100, 1), "% power</strong> to detect ",
      "an indirect effect of <strong>a × b = ", format_numeric(a * b, 3), "</strong> ",
      "(α = ", alpha, ", ", ifelse(alternative == "two.sided", "two-sided test", "one-sided test"), ").</p>",
      "<p><strong>Path Coefficients:</strong></p>",
      "<ul>",
      "<li>Path a (X → M): ", format_numeric(a, 3), " <em>(", interpret_path_coefficient(a), ")</em></li>",
      "<li>Path b (M → Y|X): ", format_numeric(b, 3), " <em>(", interpret_path_coefficient(b), ")</em></li>",
      "<li>Indirect effect (a × b): ", format_numeric(a * b, 3), " <em>(", interpret_indirect_effect(a * b), ")</em></li>"
    ))

    if (!is.na(c_prime)) {
      result_html <- HTML(paste0(result_html,
        "<li>Direct effect c' (X → Y|M): ", format_numeric(c_prime, 3), " <em>(", interpret_path_coefficient(c_prime), ")</em></li>"
      ))
    }

    result_html <- HTML(paste0(result_html,
      "</ul>",
      "<p><strong>Interpretation:</strong> The indirect effect represents the amount by which the outcome (Y) ",
      "changes when the independent variable (X) is held constant and the mediator (M) changes by the amount it would have ",
      "changed had X increased by one unit.</p>"
    ))

  } else if (calc_mode == "calc_n") {
    # Calculate sample size given power
    power <- med_inputs$med_power / 100
    n_required <- calc_mediation_n(a, b, power, alpha, alternative)

    if (is.na(n_required)) {
      result_html <- HTML(paste0(
        "<h1>Mediation Analysis: Sample Size Calculation</h1>",
        "<hr>",
        "<p style='color: #dc3545;'><strong>Error:</strong> Unable to calculate required sample size. ",
        "The indirect effect may be too small or the power target may be unachievable. ",
        "Consider increasing effect sizes or reducing power target.</p>"
      ))
    } else {
      result_html <- HTML(paste0(
        "<h1>Mediation Analysis Results: Sample Size Calculation</h1>",
        "<hr>",
        "<h4>(Copy/paste this text into your protocol)</h4>",
        "<p>To achieve <strong>", format_numeric(power * 100, 0), "% power</strong> to detect ",
        "an indirect effect of <strong>a × b = ", format_numeric(a * b, 3), "</strong>, ",
        "a sample size of <strong>N = ", format_numeric(n_required, 0), " participants</strong> is required ",
        "(α = ", alpha, ", ", ifelse(alternative == "two.sided", "two-sided test", "one-sided test"), ").</p>",
        "<p><strong>Path Coefficients:</strong></p>",
        "<ul>",
        "<li>Path a (X → M): ", format_numeric(a, 3), " <em>(", interpret_path_coefficient(a), ")</em></li>",
        "<li>Path b (M → Y|X): ", format_numeric(b, 3), " <em>(", interpret_path_coefficient(b), ")</em></li>",
        "<li>Indirect effect (a × b): ", format_numeric(a * b, 3), " <em>(", interpret_indirect_effect(a * b), ")</em></li>",
        "</ul>"
      ))
    }

  } else if (calc_mode == "calc_mde") {
    # Calculate minimal detectable effect
    n <- med_inputs$med_n
    power <- med_inputs$med_power / 100
    b_min <- calc_mediation_mde(n, a, power, alpha, alternative)

    if (is.na(b_min)) {
      result_html <- HTML(paste0(
        "<h1>Mediation Analysis: Minimal Detectable Effect</h1>",
        "<hr>",
        "<p style='color: #dc3545;'><strong>Error:</strong> Unable to calculate minimal detectable effect. ",
        "The sample size may be too small or the path a coefficient may be too weak.</p>"
      ))
    } else {
      ab_min <- a * b_min
      result_html <- HTML(paste0(
        "<h1>Mediation Analysis Results: Minimal Detectable Effect</h1>",
        "<hr>",
        "<h4>(Copy/paste this text into your protocol)</h4>",
        "<p>With <strong>N = ", format_numeric(n, 0), " participants</strong> and ",
        "<strong>", format_numeric(power * 100, 0), "% power</strong>, ",
        "the smallest detectable indirect effect is <strong>a × b = ", format_numeric(ab_min, 3), "</strong> ",
        "(α = ", alpha, ", ", ifelse(alternative == "two.sided", "two-sided test", "one-sided test"), ").</p>",
        "<p><strong>Path Coefficients:</strong></p>",
        "<ul>",
        "<li>Path a (X → M): ", format_numeric(a, 3), " <em>(", interpret_path_coefficient(a), ")</em> [Given]</li>",
        "<li>Path b (M → Y|X): ", format_numeric(b_min, 3), " <em>(", interpret_path_coefficient(b_min), ")</em> [Minimal detectable]</li>",
        "<li>Indirect effect (a × b): ", format_numeric(ab_min, 3), " <em>(", interpret_indirect_effect(ab_min), ")</em></li>",
        "</ul>",
        "<p><strong>Interpretation:</strong> Given the available sample size and path a, the study can detect ",
        "indirect effects of magnitude ", format_numeric(ab_min, 3), " or larger with ", format_numeric(power * 100, 0), "% power.</p>"
      ))
    }
  }

  output$result_text <- renderUI({
    result_html
  })
}
```

### Step 2: Add Plot Rendering Logic

**Location:** Find the `output$power_plot <- renderPlotly({ ... })` section

**Add this code inside the renderPlotly block** (look for the vif_calculator plot section and add after it):

```r
} else if (input$sidebar_page == "mediation_analysis") {
  # Mediation Analysis Power Curve
  med_inputs <- tab8_vals$inputs()
  calc_mode <- med_inputs$calc_mode
  a <- med_inputs$path_a
  b <- med_inputs$path_b
  alpha <- med_inputs$med_alpha
  alternative <- med_inputs$med_sided

  if (calc_mode == "calc_power") {
    # Power curve varying N
    n_current <- med_inputs$med_n
    n_seq <- generate_mediation_n_sequence(n_current, n_points = 50)

    power_vals <- vapply(n_seq, function(n) {
      calc_mediation_power(n, a, b, alpha = alpha, alternative = alternative)
    }, FUN.VALUE = numeric(1))

    # Create power curve plot
    plot_ly() %>%
      add_trace(
        x = n_seq,
        y = power_vals * 100,
        type = "scatter",
        mode = "lines",
        line = list(color = "#2B5876", width = 3),
        name = "Power",
        hovertemplate = paste0(
          "<b>Sample Size:</b> %{x:.0f}<br>",
          "<b>Power:</b> %{y:.1f}%<br>",
          "<extra></extra>"
        )
      ) %>%
      add_trace(
        x = c(n_current, n_current),
        y = c(0, 100),
        type = "scatter",
        mode = "lines",
        line = list(color = "#FF6B6B", width = 2, dash = "dash"),
        name = "Current N",
        hoverinfo = "skip",
        showlegend = TRUE
      ) %>%
      add_trace(
        x = c(min(n_seq), max(n_seq)),
        y = c(80, 80),
        type = "scatter",
        mode = "lines",
        line = list(color = "#4ECDC4", width = 2, dash = "dot"),
        name = "80% Power",
        hoverinfo = "skip",
        showlegend = TRUE
      ) %>%
      layout(
        title = paste0("Power Curve: Mediation Analysis (a=", format_numeric(a, 2), ", b=", format_numeric(b, 2), ")"),
        xaxis = list(title = "Sample Size (N)", gridcolor = "#E0E0E0"),
        yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
        hovermode = "closest",
        plot_bgcolor = "#FFFFFF",
        paper_bgcolor = "#FFFFFF"
      ) %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)

  } else if (calc_mode == "calc_n") {
    # Power curve showing achieved power at different sample sizes
    power_target <- med_inputs$med_power / 100
    n_required <- calc_mediation_n(a, b, power_target, alpha, alternative)

    if (!is.na(n_required)) {
      n_seq <- seq(max(10, n_required * 0.5), n_required * 1.5, length.out = 50)

      power_vals <- vapply(n_seq, function(n) {
        calc_mediation_power(n, a, b, alpha = alpha, alternative = alternative)
      }, FUN.VALUE = numeric(1))

      plot_ly() %>%
        add_trace(
          x = n_seq,
          y = power_vals * 100,
          type = "scatter",
          mode = "lines",
          line = list(color = "#2B5876", width = 3),
          name = "Power",
          hovertemplate = paste0(
            "<b>Sample Size:</b> %{x:.0f}<br>",
            "<b>Power:</b> %{y:.1f}%<br>",
            "<extra></extra>"
          )
        ) %>%
        add_trace(
          x = c(n_required, n_required),
          y = c(0, 100),
          type = "scatter",
          mode = "lines",
          line = list(color = "#FF6B6B", width = 2, dash = "dash"),
          name = paste0("Required N (", format_numeric(n_required, 0), ")"),
          hoverinfo = "skip",
          showlegend = TRUE
        ) %>%
        add_trace(
          x = c(min(n_seq), max(n_seq)),
          y = c(power_target * 100, power_target * 100),
          type = "scatter",
          mode = "lines",
          line = list(color = "#4ECDC4", width = 2, dash = "dot"),
          name = paste0("Target Power (", format_numeric(power_target * 100, 0), "%)"),
          hoverinfo = "skip",
          showlegend = TRUE
        ) %>%
        layout(
          title = paste0("Power Curve: Required Sample Size (a=", format_numeric(a, 2), ", b=", format_numeric(b, 2), ")"),
          xaxis = list(title = "Sample Size (N)", gridcolor = "#E0E0E0"),
          yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
          hovermode = "closest",
          plot_bgcolor = "#FFFFFF",
          paper_bgcolor = "#FFFFFF"
        ) %>%
        config(displayModeBar = TRUE, displaylogo = FALSE)
    }

  } else if (calc_mode == "calc_mde") {
    # Power curve showing power for different effect sizes
    n <- med_inputs$med_n
    power_target <- med_inputs$med_power / 100

    # Vary path b from small to large
    b_seq <- seq(0.05, 0.8, length.out = 50)

    power_vals <- vapply(b_seq, function(b_val) {
      calc_mediation_power(n, a, b_val, alpha = alpha, alternative = alternative)
    }, FUN.VALUE = numeric(1))

    b_min <- calc_mediation_mde(n, a, power_target, alpha, alternative)

    plot_ly() %>%
      add_trace(
        x = a * b_seq,  # Show indirect effect on x-axis
        y = power_vals * 100,
        type = "scatter",
        mode = "lines",
        line = list(color = "#2B5876", width = 3),
        name = "Power",
        hovertemplate = paste0(
          "<b>Indirect Effect (a×b):</b> %{x:.3f}<br>",
          "<b>Power:</b> %{y:.1f}%<br>",
          "<extra></extra>"
        )
      ) %>%
      add_trace(
        x = c(a * b_min, a * b_min),
        y = c(0, 100),
        type = "scatter",
        mode = "lines",
        line = list(color = "#FF6B6B", width = 2, dash = "dash"),
        name = "Minimal Detectable",
        hoverinfo = "skip",
        showlegend = TRUE
      ) %>%
      add_trace(
        x = c(min(a * b_seq), max(a * b_seq)),
        y = c(power_target * 100, power_target * 100),
        type = "scatter",
        mode = "lines",
        line = list(color = "#4ECDC4", width = 2, dash = "dot"),
        name = paste0("Target Power (", format_numeric(power_target * 100, 0), "%)"),
        hoverinfo = "skip",
        showlegend = TRUE
      ) %>%
      layout(
        title = paste0("Power Curve: Detectable Indirect Effects (N=", format_numeric(n, 0), ")"),
        xaxis = list(title = "Indirect Effect (a × b)", gridcolor = "#E0E0E0"),
        yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
        hovermode = "closest",
        plot_bgcolor = "#FFFFFF",
        paper_bgcolor = "#FFFFFF"
      ) %>%
      config(displayModeBar = TRUE, displaylogo = FALSE)
  }
}
```

### Step 3: Update get_page_display_name Function

**Location:** In `app_server.R`, find the `get_page_display_name <- function(page)` definition

**Add this line to the switch statement:**

```r
"mediation_analysis" = "Mediation Analysis",
```

### Step 4: Update Quick Preview Footer

**Location:** In `app_server.R`, find the `observe({ ... })` block that updates the preview footer text

**Add this condition:**

```r
} else if (page == "mediation_analysis") {
  paste0("Preview: Mediation with a=", input$`tab8-path_a`,
         ", b=", input$`tab8-path_b`,
         " (indirect effect=", round(input$`tab8-path_a` * input$`tab8-path_b`, 3), ")")
```

## Testing Checklist

After implementing the above:

- [ ] Run the app and navigate to Mediation Analysis
- [ ] Test "Calculate Power" mode:
  - [ ] Enter sample size and path coefficients
  - [ ] Click Calculate
  - [ ] Verify power result displays
  - [ ] Verify power curve plots correctly
- [ ] Test "Calculate Sample Size" mode:
  - [ ] Enter power and path coefficients
  - [ ] Verify sample size calculation
  - [ ] Verify power curve shows required N
- [ ] Test "Calculate Minimal Detectable Effect" mode:
  - [ ] Enter sample size and path a
  - [ ] Verify minimal path b calculation
  - [ ] Verify plot shows detectable effects
- [ ] Test Example button - should load example values
- [ ] Test Reset button - should restore defaults
- [ ] Verify contextual help expands and displays correctly
- [ ] Test edge cases:
  - [ ] Very small effect sizes
  - [ ] Very large sample sizes
  - [ ] Path coefficients near zero
  - [ ] Negative path coefficients

## Documentation Updates Needed

After testing, update these files:

1. `docs/004-explanation/003-comprehensive-feature-analysis-2025.md`
   - Mark Mediation Analysis (NEW 3) as ✅ **COMPLETED**
   - Add implementation details
   - Update status in Tier 2 section

2. `README.md`
   - Add "Mediation Analysis" to the list of analysis types
   - Update feature count

3. Create `docs/003-reference/xxx-mediation-analysis-methods.md`
   - Document the statistical methods used
   - Explain Sobel test approach
   - Provide formulas and references

## Known Limitations

- Currently implements Sobel test only (analytical approach)
- Does not support multiple mediators
- Does not support Monte Carlo simulation (bootstrap) methods
- Path coefficients must be standardized
- Assumes linear relationships

## Future Enhancements

1. **Monte Carlo simulation** - More accurate power estimates via bootstrapping
2. **Multiple mediators** - Parallel and serial mediation models
3. **Moderated mediation** - Interaction effects in mediation
4. **Categorical mediators/outcomes** - Binary or ordinal variables
5. **Longitudinal mediation** - Time-lagged mediation models

## References

- Preacher & Hayes (2008). Asymptotic and resampling strategies for assessing and comparing indirect effects.
- Fritz & MacKinnon (2007). Required sample size to detect the mediated effect.
- Schoemann et al. (2017). Determining power and sample size for simple and complex mediation models.

---

**Implementation Date:** 2025-10-26
**Implemented By:** Claude Code
**Estimated Completion Time:** 30-60 minutes for remaining steps
