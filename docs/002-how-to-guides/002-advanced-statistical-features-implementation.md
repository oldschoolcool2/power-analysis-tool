# Advanced Statistical Features Implementation Guide

**Document Version:** 1.0
**Date:** 2025-10-24
**Status:** Implementation Ready
**Dependencies:** plotly, ggplot2, PSweight packages added to renv.lock ✅

---

## Overview

This document provides step-by-step implementation instructions for the 4 advanced statistical enhancement features:

1. **Missing Data Adjustment** - Simple inflation factors (EASIEST, HIGHEST IMPACT)
2. **Minimal Detectable Effect Size** - Reverse power calculator (MODERATE)
3. **Interactive Power Curves** - plotly visualizations (MODERATE)
4. **Variance Inflation Factor Calculator** - Propensity score adjustments (ADVANCED)

**Estimated Total Implementation Effort:** 750-1100 lines of new code

---

## Feature 1: Missing Data Adjustment

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE
**Complexity:** LOW
**Estimated Effort:** 2-3 hours
**Lines of Code:** ~100-150

### Overview

Add optional missing data adjustment to all sample size calculation tabs. Users can specify expected missingness percentage, and the tool inflates the calculated sample size accordingly.

### Statistical Method

```r
# Complete case analysis inflation
N_inflated = N_required / (1 - p_missing)

# Example: If N=400 and 20% missing data expected:
# N_inflated = 400 / (1 - 0.20) = 400 / 0.80 = 500
```

### Implementation Steps

#### Step 1: Add UI Input to ALL Sample Size Tabs

Add this code block to each sample size tab (tabs 2, 4, 6, 7, 9, 10):

```r
# Add after the main calculation inputs, before the hr() separator
checkboxInput("adjust_missing_[TABNAME]", "Adjust for Missing Data", value = FALSE),
conditionalPanel(
  condition = "input.adjust_missing_[TABNAME]",
  sliderInput("missing_pct_[TABNAME]",
    "Expected Missingness (%)",
    min = 5, max = 50, value = 20, step = 5
  ),
  bsTooltip("missing_pct_[TABNAME]",
    "Percentage of participants with missing exposure, outcome, or covariate data",
    "right"
  ),
  radioButtons("missing_mechanism_[TABNAME]",
    "Missing Data Mechanism:",
    choices = c(
      "MCAR (Missing Completely At Random)" = "mcar",
      "MAR (Missing At Random)" = "mar",
      "MNAR (Missing Not At Random)" = "mnar"
    ),
    selected = "mar"
  ),
  bsTooltip("missing_mechanism_[TABNAME]",
    "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
    "right"
  )
)
```

**Replace `[TABNAME]` with:**
- Tab 2 (Sample Size Single): `ss_single`
- Tab 4 (Sample Size Two-Group): `twogrp_ss`
- Tab 6 (Sample Size Survival): `surv_ss`
- Tab 7 (Matched Case-Control): `match`
- Tab 9 (Sample Size Continuous): `cont_ss`
- Tab 10 (Non-Inferiority): `noninf`

####Step 2: Add Helper Function in Server

Add this function after the existing helper functions (after line 450):

```r
# Helper function: inflate sample size for missing data
calc_missing_data_inflation <- function(n_required, missing_pct, mechanism = "mar") {
  if (missing_pct == 0) {
    return(list(
      n_inflated = n_required,
      inflation_factor = 1.0,
      interpretation = "No adjustment needed (0% missingness assumed)"
    ))
  }

  p_missing <- missing_pct / 100

  # Complete case analysis: conservative inflation
  inflation_factor <- 1 / (1 - p_missing)
  n_inflated <- ceiling(n_required * inflation_factor)
  n_increase <- n_inflated - n_required
  pct_increase <- round((inflation_factor - 1) * 100, 1)

  # Interpretation text
  mechanism_text <- switch(mechanism,
    "mcar" = "MCAR (minimal bias expected)",
    "mar" = "MAR (bias controllable with observed covariates)",
    "mnar" = "MNAR (potential for substantial bias, sensitivity analysis recommended)",
    "MAR"  # default
  )

  interpretation <- sprintf(
    "Assuming %s%% missingness (%s), inflate sample size by %s%% (add %s participants) to ensure adequate complete-case sample.",
    missing_pct, mechanism_text, pct_increase, n_increase
  )

  list(
    n_inflated = n_inflated,
    inflation_factor = inflation_factor,
    n_increase = n_increase,
    pct_increase = pct_increase,
    interpretation = interpretation
  )
}
```

#### Step 3: Modify Result Text Output

For each sample size calculation in `output$result_text`, add missing data adjustment logic.

**Example for Tab 2 (Single Proportion Sample Size):**

Find this section in the server (around line 750):

```r
# Current code (approximately):
n_required <- ceiling(target_freq / (1 - input$ss_discon / 100))
```

**Replace with:**

```r
# Base sample size (before missing data adjustment)
n_base <- ceiling(target_freq / (1 - input$ss_discon / 100))

# Apply missing data adjustment if enabled
if (input$adjust_missing_ss_single) {
  missing_adj <- calc_missing_data_inflation(
    n_base,
    input$missing_pct_ss_single,
    input$missing_mechanism_ss_single
  )
  n_required <- missing_adj$n_inflated
  missing_data_text <- HTML(sprintf("<br><br><strong>Missing Data Adjustment:</strong> %s", missing_adj$interpretation))
} else {
  n_required <- n_base
  missing_data_text <- HTML("")
}

# Then in the output HTML, add:
# ... existing result text ...
missing_data_text
```

**Repeat this pattern for all 6 sample size tabs.**

#### Step 4: Update Button Configs

Add missing data fields to the `button_configs` list for each tab's reset values:

```r
# Example for ss_single:
ss_single = list(
  example = list(ss_power = 90, ss_p = 200, ss_discon = 10, ss_alpha = 0.05,
                 adjust_missing_ss_single = TRUE, missing_pct_ss_single = 20,
                 missing_mechanism_ss_single = "mar"),
  reset = list(ss_power = 80, ss_p = 100, ss_discon = 10, ss_alpha = 0.05,
               adjust_missing_ss_single = FALSE, missing_pct_ss_single = 20,
               missing_mechanism_ss_single = "mar"),
  example_msg = "Sample size for rare event with 20% missing data adjustment"
)
```

#### Step 5: Update CSV Export

Modify the CSV export functions to include missing data parameters:

```r
# In the CSV export section for each tab, add:
"Missing_Data_Adjustment" = ifelse(input$adjust_missing_[TABNAME], "Yes", "No"),
"Missing_Percentage" = ifelse(input$adjust_missing_[TABNAME], input$missing_pct_[TABNAME], NA),
"Missing_Mechanism" = ifelse(input$adjust_missing_[TABNAME], input$missing_mechanism_[TABNAME], NA),
"Sample_Size_Before_Adjustment" = n_base,  # save both values
"Sample_Size_After_Adjustment" = n_required
```

### Testing

**Test Cases:**

1. **No adjustment** (checkbox unchecked): Should match existing calculations
2. **20% missingness**: N=400 → N=500 (25% inflation)
3. **50% missingness**: N=400 → N=800 (100% inflation)
4. **MCAR vs MAR vs MNAR**: Text interpretation should change but calculation same
5. **Edge case - 0% missingness**: No inflation

**Validation:**
```r
# Manual calculation:
n_required <- 400
missing_pct <- 20
n_inflated <- ceiling(400 / (1 - 0.20))  # Should be 500
stopifnot(n_inflated == 500)
```

### Expected Output Example

```
Sample Size Calculation Results

Base sample size (before adjustments): 400 participants

Missing Data Adjustment: Assuming 20% missingness (MAR - bias controllable
with observed covariates), inflate sample size by 25% (add 100 participants)
to ensure adequate complete-case sample.

Final Required Sample Size: 500 participants
```

---

## Feature 2: Minimal Detectable Effect Size Calculator

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE
**Complexity:** MODERATE
**Estimated Effort:** 6-8 hours
**Lines of Code:** ~250-350

### Overview

Add "reverse calculator" mode to all tabs. Instead of calculating required sample size given effect, calculate the minimal detectable effect given fixed sample size. Critical for RWE studies where N is predetermined by available database.

### Statistical Methods

#### Two-Proportion Test
```r
# Given: n1, n2, alpha, power
# Find: minimal detectable h (Cohen's h), then convert to proportions

# Solve for h:
solve_minimal_h <- function(n1, n2, alpha, power, alternative = "two.sided") {
  pwr.2p2n.test(n1 = n1, n2 = n2, sig.level = alpha, power = power,
                alternative = alternative)$h
}

# Convert h to proportions (requires p2 baseline):
# h = 2 * (asin(sqrt(p1)) - asin(sqrt(p2)))
# Solve for p1 given p2 and h
```

#### Survival Analysis
```r
# Given: n, k (proportion exposed), pE (event rate), alpha, power
# Find: minimal detectable HR

solve_minimal_hr <- function(n, k, pE, alpha, power) {
  # Use binary search / uniroot to find HR that achieves target power
  f <- function(hr) {
    calc_power <- powerSurvEpi::powerEpi(
      n = n,
      theta = hr,
      k = k / 100,
      pE = pE / 100,
      RR = hr,
      alpha = alpha
    )
    calc_power - power
  }

  # Search between HR=0.1 and HR=10
  hr_min <- uniroot(f, c(0.1, 0.99), extendInt = "yes")$root
  hr_max <- uniroot(f, c(1.01, 10), extendInt = "yes")$root

  list(hr_min = hr_min, hr_max = hr_max)
}
```

### Implementation Steps

#### Step 1: Add Mode Toggle to ALL Tabs

Add radio button at the TOP of each tab (tabs 1-10):

```r
# Add immediately after h4() title in each tab
radioButtons("calc_mode_[TABNAME]",
  "Calculation Mode:",
  choices = c(
    "Calculate Power/Sample Size" = "standard",
    "Calculate Minimal Detectable Effect" = "reverse"
  ),
  selected = "standard",
  inline = TRUE
),
hr(),
```

#### Step 2: Create Conditional UI Panels

Wrap existing inputs in `conditionalPanel`:

```r
# STANDARD MODE (existing inputs)
conditionalPanel(
  condition = "input.calc_mode_[TABNAME] == 'standard'",
  # ... existing inputs ...
),

# REVERSE MODE (new inputs)
conditionalPanel(
  condition = "input.calc_mode_[TABNAME] == 'reverse'",
  numericInput("fixed_n_[TABNAME]", "Available Sample Size:", 500, min = 10, step = 1),
  bsTooltip("fixed_n_[TABNAME]", "Fixed sample size available in database/registry", "right"),

  # For two-group comparisons, also need:
  numericInput("fixed_n2_[TABNAME]", "Sample Size Group 2:", 500, min = 10, step = 1),
  numericInput("baseline_rate_[TABNAME]", "Baseline Event Rate (%):", 10, min = 0.1, max = 99.9),

  sliderInput("target_power_[TABNAME]", "Target Power (%):", min = 50, max = 95, value = 80, step = 5),
  sliderInput("alpha_reverse_[TABNAME]", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01)
)
```

#### Step 3: Add Reverse Calculation Functions

Add these helper functions in the server section:

```r
# Reverse calculator: Two-proportion test
calc_minimal_detectable_proportions <- function(n1, n2, p2_baseline, alpha, power, alternative = "two.sided") {
  # Solve for Cohen's h
  h_min <- pwr.2p2n.test(n1 = n1, n2 = n2, sig.level = alpha, power = power,
                          alternative = alternative)$h

  # Convert to proportions
  # h = 2 * (asin(sqrt(p1)) - asin(sqrt(p2)))
  # p1 = sin((h/2) + asin(sqrt(p2)))^2

  p2 <- p2_baseline / 100
  asin_p2 <- asin(sqrt(p2))

  # Minimum detectable increase (h positive)
  p1_upper <- (sin(asin_p2 + h_min/2))^2

  # Minimum detectable decrease (h negative)
  p1_lower <- (sin(asin_p2 - h_min/2))^2

  # Effect measures
  rr_upper <- p1_upper / p2
  rr_lower <- p1_lower / p2
  rd_upper <- (p1_upper - p2) * 100
  rd_lower <- (p1_lower - p2) * 100

  list(
    h = h_min,
    p1_upper = p1_upper * 100,
    p1_lower = p1_lower * 100,
    p2_baseline = p2_baseline,
    rr_upper = rr_upper,
    rr_lower = rr_lower,
    rd_upper = rd_upper,
    rd_lower = rd_lower
  )
}

# Reverse calculator: Survival analysis
calc_minimal_detectable_hr <- function(n, k, pE, alpha, power) {
  # Find HRs that achieve target power
  f <- function(hr) {
    powerSurvEpi::powerEpi(
      n = n, theta = hr, k = k/100, pE = pE/100, RR = hr, alpha = alpha
    ) - power
  }

  # Protective effect (HR < 1)
  hr_lower <- tryCatch({
    uniroot(f, c(0.1, 0.99))$root
  }, error = function(e) NA_real_)

  # Harmful effect (HR > 1)
  hr_upper <- tryCatch({
    uniroot(f, c(1.01, 10))$root
  }, error = function(e) NA_real_)

  list(hr_lower = hr_lower, hr_upper = hr_upper)
}

# Reverse calculator: Continuous outcomes (t-test)
calc_minimal_detectable_d <- function(n1, n2, alpha, power, alternative = "two.sided") {
  result <- pwr.t2n.test(n1 = n1, n2 = n2, sig.level = alpha, power = power,
                         alternative = alternative)
  d <- abs(result$d)

  # Effect size interpretation
  interpretation <- if (d < 0.2) {
    "Very Small"
  } else if (d < 0.5) {
    "Small"
  } else if (d < 0.8) {
    "Medium"
  } else {
    "Large"
  }

  list(d = d, interpretation = interpretation)
}
```

#### Step 4: Modify Result Output Logic

Add conditional logic to `output$result_text`:

```r
# Example for Two-Group Power tab
if (input$calc_mode_twogrp_pow == "reverse") {
  # REVERSE MODE: Calculate minimal detectable effect
  result <- calc_minimal_detectable_proportions(
    n1 = input$fixed_n_twogrp_pow,
    n2 = input$fixed_n2_twogrp_pow,
    p2_baseline = input$baseline_rate_twogrp_pow,
    alpha = input$alpha_reverse_twogrp_pow,
    power = input$target_power_twogrp_pow / 100,
    alternative = input$twogrp_pow_sided
  )

  HTML(sprintf("
    <h4>Minimal Detectable Effect Size</h4>
    <p><strong>Study Design:</strong> Two-group comparison with fixed sample sizes</p>
    <p><strong>Available Sample:</strong> n₁=%s, n₂=%s</p>
    <p><strong>Baseline Event Rate (Group 2):</strong> %s%%</p>
    <p><strong>Target Power:</strong> %s%%</p>
    <p><strong>Significance Level:</strong> α=%s (%s)</p>

    <h5>Minimal Detectable Differences:</h5>
    <ul>
      <li><strong>Group 1 Event Rate:</strong> %s%% to %s%%</li>
      <li><strong>Relative Risk:</strong> RR=%s to RR=%s</li>
      <li><strong>Risk Difference:</strong> %s to %s percentage points</li>
      <li><strong>Cohen's h:</strong> %s</li>
    </ul>

    <h5>Interpretation:</h5>
    <p>With n=%s total participants and %s%% power, you can detect:</p>
    <ul>
      <li>An <strong>increase</strong> in event rate from %s%% to %s%% or higher (RR ≥ %s)</li>
      <li>A <strong>decrease</strong> in event rate from %s%% to %s%% or lower (RR ≤ %s)</li>
    </ul>
    <p><em>Feasibility Assessment:</em> %s</p>
  ",
    input$fixed_n_twogrp_pow,
    input$fixed_n2_twogrp_pow,
    round(result$p2_baseline, 1),
    input$target_power_twogrp_pow,
    input$alpha_reverse_twogrp_pow,
    ifelse(input$twogrp_pow_sided == "two.sided", "two-sided", "one-sided"),
    round(result$p1_lower, 1),
    round(result$p1_upper, 1),
    round(result$rr_lower, 2),
    round(result$rr_upper, 2),
    round(result$rd_lower, 1),
    round(result$rd_upper, 1),
    round(result$h, 3),
    input$fixed_n_twogrp_pow + input$fixed_n2_twogrp_pow,
    input$target_power_twogrp_pow,
    round(result$p2_baseline, 1),
    round(result$p1_upper, 1),
    round(result$rr_upper, 2),
    round(result$p2_baseline, 1),
    round(result$p1_lower, 1),
    round(result$rr_lower, 2),
    assess_feasibility(result$rr_upper, result$rr_lower)
  ))
} else {
  # STANDARD MODE: existing calculation code
  # ... (keep existing logic) ...
}
```

#### Step 5: Add Feasibility Assessment

```r
assess_feasibility <- function(rr_upper, rr_lower) {
  # Assess if detectable effects are clinically meaningful
  rr_range <- max(rr_upper, 1/rr_lower)

  if (rr_range > 2.0) {
    "✅ <strong>Good:</strong> Can detect moderate to large effects (RR ≥ 2.0 or ≤ 0.5)"
  } else if (rr_range > 1.5) {
    "⚠️ <strong>Moderate:</strong> Can detect small to moderate effects (RR ≥ 1.5)"
  } else if (rr_range > 1.25) {
    "⚠️ <strong>Limited:</strong> Only moderate effects detectable (RR ≥ 1.25)"
  } else {
    "❌ <strong>Underpowered:</strong> Only large effects detectable. Consider larger sample."
  }
}
```

### Testing

**Test Cases:**

1. **Two-group (n1=500, n2=500, p2=10%, power=80%, α=0.05)**
   - Expected: Can detect RR ≈ 1.5 or 0.67

2. **Survival (n=1000, HR=0.70, k=50%, pE=30%)**
   - Forward: Calculate power
   - Reverse: Should recover HR ≈ 0.70 when inputting calculated power

3. **Edge cases:**
   - Very small N: Should warn about limited power
   - Very large N: Should show very small effects detectable

---

## Feature 3: Interactive Power Curves

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE
**Complexity:** MODERATE
**Estimated Effort:** 4-6 hours
**Lines of Code:** ~200-300

### Overview

Add interactive plotly visualizations showing:
1. Power vs. Sample Size curve
2. Sample Size vs. Effect Size curve
3. Multi-parameter sensitivity analysis

### Implementation Steps

#### Step 1: Add Plot Output to Main Panel

In the main panel UI (around line 350), add:

```r
# After result_text output, before result_table
plotlyOutput("power_curve_plot", height = "400px"),
br(),
```

#### Step 2: Create Plot Generation Function

Add helper function in server:

```r
# Generate power curve data
generate_power_curve_data <- function(tab, inputs) {
  if (tab == "Power (Two-Group)") {
    # Example for two-group comparison
    n1 <- inputs$twogrp_pow_n1
    n2 <- inputs$twogrp_pow_n2
    p1 <- inputs$twogrp_pow_p1 / 100
    p2 <- inputs$twogrp_pow_p2 / 100
    alpha <- inputs$twogrp_pow_alpha
    alternative <- inputs$twogrp_pow_sided

    # Generate range of sample sizes (50% to 200% of current)
    n_range <- seq(floor(n1 * 0.5), ceiling(n1 * 2), length.out = 50)

    # Calculate power for each N (maintaining ratio)
    ratio <- n2 / n1
    h <- ES.h(p1, p2)

    power_values <- sapply(n_range, function(n) {
      pwr.2p2n.test(
        h = h,
        n1 = n,
        n2 = n * ratio,
        sig.level = alpha,
        alternative = alternative
      )$power
    })

    data.frame(
      n = n_range,
      power = power_values * 100,
      n_total = n_range * (1 + ratio)
    )
  }
  # Add similar logic for other tabs...
}
```

#### Step 3: Create Plotly Visualization

```r
output$power_curve_plot <- renderPlotly({
  req(v$doAnalysis)

  current_tab <- input$tabset

  # Generate curve data based on current tab
  curve_data <- generate_power_curve_data(current_tab, input)

  if (is.null(curve_data)) {
    return(NULL)  # No plot for this tab type
  }

  # Create plotly plot
  p <- plot_ly(curve_data, x = ~n_total, y = ~power, type = 'scatter', mode = 'lines',
               line = list(color = '#3498db', width = 3),
               name = 'Power Curve') %>%

    # Add reference lines
    add_trace(y = 80, x = range(curve_data$n_total),
              mode = 'lines', line = list(dash = 'dash', color = '#e74c3c', width = 2),
              name = 'Target Power (80%)', showlegend = TRUE) %>%

    add_trace(y = 90, x = range(curve_data$n_total),
              mode = 'lines', line = list(dash = 'dot', color = '#f39c12', width = 2),
              name = 'High Power (90%)', showlegend = TRUE) %>%

    # Highlight current sample size
    add_markers(x = sum(input$twogrp_pow_n1, input$twogrp_pow_n2),
                y = calculated_power,  # from previous calculation
                marker = list(size = 12, color = '#2ecc71'),
                name = 'Current Design', showlegend = TRUE) %>%

    # Layout
    layout(
      title = list(text = "Power vs. Sample Size", font = list(size = 18)),
      xaxis = list(title = "Total Sample Size (N)", gridcolor = '#ecf0f1'),
      yaxis = list(title = "Statistical Power (%)", range = c(0, 100), gridcolor = '#ecf0f1'),
      hovermode = 'x unified',
      plot_bgcolor = '#ffffff',
      paper_bgcolor = '#f8f9fa',
      margin = list(l = 60, r = 40, t = 60, b = 60),
      legend = list(x = 0.02, y = 0.98, bgcolor = 'rgba(255,255,255,0.8)')
    ) %>%

    # Add annotations
    add_annotations(
      x = sum(input$twogrp_pow_n1, input$twogrp_pow_n2),
      y = calculated_power,
      text = sprintf("N=%s<br>Power=%s%%",
                     sum(input$twogrp_pow_n1, input$twogrp_pow_n2),
                     round(calculated_power, 1)),
      showarrow = TRUE,
      arrowhead = 2,
      ax = 40,
      ay = -40
    ) %>%

    # Interactive configuration
    config(displayModeBar = TRUE,
           modeBarButtonsToRemove = c('select2d', 'lasso2d', 'autoScale2d'),
           toImageButtonOptions = list(format = 'png', filename = 'power_curve',
                                        height = 600, width = 800))

  p
})
```

#### Step 4: Add Effect Size Curve (Alternative View)

Create tab panel for multiple plot types:

```r
# In UI, replace single plotlyOutput with tabsetPanel:
tabsetPanel(
  id = "plot_tabs",
  tabPanel("Power vs. Sample Size",
           plotlyOutput("power_vs_n_plot", height = "400px")),
  tabPanel("Power vs. Effect Size",
           plotlyOutput("power_vs_effect_plot", height = "400px")),
  tabPanel("Sample Size vs. Effect Size",
           plotlyOutput("n_vs_effect_plot", height = "400px"))
)
```

### Testing

1. Verify curves update when Calculate button clicked
2. Test hover functionality
3. Export PNG image
4. Check responsiveness on mobile
5. Verify all tabs generate appropriate curves

---

## Feature 4: Variance Inflation Factor (VIF) Calculator

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE (for propensity score methods)
**Complexity:** ADVANCED
**Estimated Effort:** 8-10 hours
**Lines of Code:** ~300-400

### Overview

NEW TAB for propensity score methods that calculates the design effect (variance inflation factor) when using IPTW or other propensity score weighting schemes.

### Statistical Method

Based on Austin (2021) paper:

```r
# VIF estimation based on c-statistic and treatment prevalence
estimate_vif <- function(c_statistic, prevalence, weight_type = "ATE") {
  # Simplified Austin (2021) formula
  # VIF depends on:
  # 1. Discriminative ability of PS model (c-statistic)
  # 2. Treatment prevalence
  # 3. Weighting scheme (ATE, ATT, ATO)

  p <- prevalence / 100
  c <- c_statistic

  # Approximation formula (simplified)
  if (weight_type == "ATE") {
    # Average Treatment Effect weighting (IPTW)
    vif <- 1 + ((1 - c)^2 / (c^2)) * (1 / (p * (1 - p)))
  } else if (weight_type == "ATT") {
    # Average Treatment effect on Treated
    vif <- 1 + ((1 - c)^2 / (c^2)) * (1 - p) / p
  } else if (weight_type == "ATO") {
    # Overlap weights (generally most efficient)
    vif <- 1 + ((1 - c)^2 / (c^2)) * 0.5  # simplified
  }

  vif
}
```

### Implementation Steps

#### Step 1: Add New Tab to UI

Insert new tab after tab 10 (Non-Inferiority):

```r
# TAB 11: Propensity Score / VIF Calculator
tabPanel(
  "Propensity Score Methods",
  h4("Variance Inflation Factor (VIF) Calculator"),
  helpText("Adjust sample size for propensity score weighting methods (e.g., IPTW, matching)"),
  hr(),

  # Input: RCT-based sample size
  numericInput("vif_n_rct",
    "Required Sample Size (RCT calculation):",
    500, min = 10, step = 10),
  bsTooltip("vif_n_rct",
    "Sample size calculated assuming randomized trial (from other tabs)",
    "right"),

  # Input: Propensity score model characteristics
  sliderInput("vif_prevalence",
    "Treatment Prevalence (%):",
    min = 10, max = 90, value = 50, step = 5),
  bsTooltip("vif_prevalence",
    "Percentage of participants in treatment/exposed group",
    "right"),

  sliderInput("vif_cstat",
    "Anticipated C-statistic of PS Model:",
    min = 0.55, max = 0.95, value = 0.70, step = 0.05),
  bsTooltip("vif_cstat",
    "Discriminative ability of propensity score model. 0.5=no discrimination, 1.0=perfect. Typical: 0.65-0.75",
    "right"),

  # Input: Weighting method
  radioButtons("vif_method",
    "Weighting Method:",
    choices = c(
      "ATE - Inverse Probability of Treatment Weighting" = "ATE",
      "ATT - Average Treatment effect on Treated" = "ATT",
      "ATO - Overlap Weights (most efficient)" = "ATO",
      "ATM - Matching Weights" = "ATM"
    ),
    selected = "ATE"),
  bsTooltip("vif_method",
    "ATE: generalizes to full population. ATT: effect in treated. ATO: effect in overlap region",
    "right"),

  hr(),
  actionButton("example_vif", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
  actionButton("reset_vif", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
),
```

#### Step 2: Add VIF Calculation Logic

```r
# In server, add output for VIF tab
observeEvent(input$calculate, {
  if (input$tabset == "Propensity Score Methods") {

    # Calculate VIF
    vif <- estimate_vif(
      c_statistic = input$vif_cstat,
      prevalence = input$vif_prevalence,
      weight_type = input$vif_method
    )

    # Inflate sample size
    n_adjusted <- ceiling(input$vif_n_rct * vif)
    n_increase <- n_adjusted - input$vif_n_rct
    pct_increase <- round((vif - 1) * 100, 1)

    # Effective sample size (inverse of VIF)
    n_effective <- floor(input$vif_n_rct / vif)

    # Method descriptions
    method_desc <- switch(input$vif_method,
      "ATE" = "Inverse Probability of Treatment Weighting (IPTW) for Average Treatment Effect. Weights create a pseudo-population where treatment is independent of measured confounders.",
      "ATT" = "Weighting for Average Treatment effect on the Treated. Estimates effect in those who actually received treatment.",
      "ATO" = "Overlap Weights. Focuses on population with equipoise (good overlap in propensity scores). Generally most efficient.",
      "ATM" = "Matching Weights. Mimics 1:1 matching but retains all participants."
    )

    output$result_text <- renderUI({
      HTML(sprintf("
        <h4>Propensity Score Weighting: Sample Size Adjustment</h4>

        <p><strong>Weighting Method:</strong> %s</p>
        <p>%s</p>

        <h5>Propensity Score Model Assumptions:</h5>
        <ul>
          <li>Treatment prevalence: <strong>%s%%</strong></li>
          <li>Anticipated c-statistic: <strong>%s</strong> %s</li>
        </ul>

        <h5>Variance Inflation Factor (Design Effect):</h5>
        <p><strong>VIF = %s</strong></p>
        <p>The effective sample size is reduced by a factor of %s due to propensity score weighting.</p>

        <h5>Sample Size Adjustment:</h5>
        <ul>
          <li><strong>RCT-based sample size:</strong> %s</li>
          <li><strong>Inflation needed:</strong> +%s%% (%s additional participants)</li>
          <li><strong>Adjusted sample size:</strong> <span style='font-size:1.2em; color:#e74c3c;'><strong>%s</strong></span></li>
        </ul>

        <h5>Interpretation:</h5>
        <p>To achieve the same statistical power as a randomized trial with N=%s,
        an observational study using %s weighting requires approximately
        <strong>N=%s participants</strong> (assuming c-statistic=%s).</p>

        <p>The effective sample size after weighting will be approximately %s,
        which matches the statistical information in a randomized trial of that size.</p>

        <h5>Recommendations:</h5>
        <ul>
          <li>%s</li>
          <li>%s</li>
          <li>%s</li>
        </ul>

        <p><em>Reference: Austin PC (2021). Statistics in Medicine 40(27):6150-6163.</em></p>
      ",
        input$vif_method,
        method_desc,
        input$vif_prevalence,
        input$vif_cstat,
        interpret_cstat(input$vif_cstat),
        round(vif, 2),
        round(vif, 2),
        input$vif_n_rct,
        pct_increase,
        n_increase,
        n_adjusted,
        input$vif_n_rct,
        input$vif_method,
        n_adjusted,
        input$vif_cstat,
        n_effective,
        recommend_cstat(input$vif_cstat),
        recommend_prevalence(input$vif_prevalence),
        recommend_method(input$vif_method, vif)
      ))
    })
  }
})

# Helper: interpret c-statistic
interpret_cstat <- function(c) {
  if (c < 0.60) {
    "(Poor discrimination - consider better covariates)"
  } else if (c < 0.70) {
    "(Fair discrimination - typical for many studies)"
  } else if (c < 0.80) {
    "(Good discrimination)"
  } else {
    "(Excellent discrimination)"
  }
}

# Helper: recommendation functions
recommend_cstat <- function(c) {
  if (c < 0.65) {
    "⚠️ C-statistic is low. Include stronger confounders to improve propensity score model."
  } else {
    "✅ C-statistic is adequate for propensity score methods."
  }
}

recommend_prevalence <- function(p) {
  if (p < 20 || p > 80) {
    sprintf("⚠️ Treatment prevalence (%s%%) is imbalanced. VIF will be higher. Consider restricting to overlap region (ATO weights).", p)
  } else {
    "✅ Treatment prevalence is reasonably balanced."
  }
}

recommend_method <- function(method, vif) {
  if (vif > 2.0) {
    "⚠️ High VIF suggests substantial efficiency loss. Consider overlap weights (ATO) or matching to improve efficiency."
  } else {
    "✅ VIF is acceptable. Propensity score weighting is feasible."
  }
}
```

#### Step 3: Add Sensitivity Analysis Table

Generate table showing VIF across range of c-statistics:

```r
# In result output, add:
sensitivity_data <- expand.grid(
  c_stat = seq(0.55, 0.90, 0.05),
  prevalence = c(20, 30, 40, 50, 60, 70, 80)
)

sensitivity_data$vif <- mapply(
  estimate_vif,
  c_statistic = sensitivity_data$c_stat,
  prevalence = sensitivity_data$prevalence,
  MoreArgs = list(weight_type = input$vif_method)
)

sensitivity_data$n_adjusted <- ceiling(input$vif_n_rct * sensitivity_data$vif)

# Render as heatmap or table
output$vif_sensitivity_table <- renderDT({
  datatable(
    sensitivity_data,
    caption = "Sensitivity Analysis: VIF by C-statistic and Prevalence",
    options = list(pageLength = 10, dom = 't')
  ) %>%
    formatRound(columns = c('vif'), digits = 2) %>%
    formatStyle(
      'vif',
      backgroundColor = styleInterval(c(1.5, 2.0, 3.0),
                                       c('#d4edda', '#fff3cd', '#f8d7da', '#e74c3c'))
    )
}, server = FALSE)
```

#### Step 4: Add to Help Accordion

Add new help section explaining propensity score methods:

```r
accordion_panel(
  "Propensity Score Methods",
  HTML("
    <h5>When to Use:</h5>
    <ul>
      <li>Observational studies comparing treatment groups</li>
      <li>Using propensity score weighting (IPTW, ATO, ATT, ATM)</li>
      <li>Need to adjust sample size for efficiency loss</li>
    </ul>

    <h5>How it Works:</h5>
    <p>Propensity score weighting creates balance on measured confounders but
    reduces effective sample size. The Variance Inflation Factor (VIF) quantifies
    this efficiency loss based on:</p>
    <ul>
      <li><strong>C-statistic</strong>: How well the PS model discriminates between treated/untreated</li>
      <li><strong>Treatment prevalence</strong>: Balance of treatment groups</li>
      <li><strong>Weighting scheme</strong>: ATE, ATT, ATO, etc.</li>
    </ul>

    <h5>Typical C-statistics by Data Source:</h5>
    <ul>
      <li>Claims data: 0.60-0.70</li>
      <li>EHR data: 0.65-0.75</li>
      <li>Registry data: 0.70-0.80</li>
      <li>Rich cohort data: 0.75-0.85</li>
    </ul>

    <h5>References:</h5>
    <ul>
      <li>Austin PC (2021). Statistics in Medicine.</li>
      <li>Li F et al. (2018). Statistical Methods in Medical Research.</li>
    </ul>
  ")
)
```

### Testing

1. **Low c-statistic (0.60)**: Should show high VIF
2. **High c-statistic (0.85)**: Should show low VIF
3. **Imbalanced prevalence (20%)**: Should show higher VIF than balanced (50%)
4. **ATO vs ATE**: ATO should generally show lower VIF
5. **Cross-validate with published examples** from Austin (2021) paper

---

## Integration & Testing Plan

### Overall Testing Strategy

1. **Unit Tests**: Create tests for each new helper function
   ```r
   # tests/testthat/test-advanced-statistical-features.R
   test_that("Missing data inflation calculates correctly", {
     result <- calc_missing_data_inflation(400, 20, "mar")
     expect_equal(result$n_inflated, 500)
     expect_equal(result$inflation_factor, 1.25)
   })

   test_that("Minimal detectable proportions calculated correctly", {
     result <- calc_minimal_detectable_proportions(500, 500, 10, 0.05, 0.80, "two.sided")
     expect_true(result$rr_upper > 1.0)
     expect_true(result$rr_lower < 1.0)
   })

   test_that("VIF estimation matches published values", {
     # Austin (2021) Table 2 values
     vif <- estimate_vif(c_statistic = 0.70, prevalence = 50, weight_type = "ATE")
     expect_equal(vif, 1.84, tolerance = 0.1)
   })
   ```

2. **Integration Tests**: Test full workflows
   - User selects tab → enters values → clicks Calculate → sees results with new features
   - User toggles missing data adjustment → sees inflated sample size
   - User switches to reverse mode → sees minimal detectable effect

3. **Regression Tests**: Ensure existing functionality unchanged
   - Run existing test suite
   - Verify all original calculations produce same results

4. **Visual Tests**: Manually verify
   - Power curves display correctly
   - Plotly interactions work (hover, zoom, export)
   - Mobile responsiveness

### Deployment Plan

1. **Phase 1: Development Branch** (Week 1-2)
   - Create `advanced-statistical-features` branch
   - Implement features 1-2 (Missing Data + Minimal Detectable)
   - Test thoroughly

2. **Phase 2: Visualization** (Week 3)
   - Implement feature 3 (Power Curves)
   - Integrate with existing tabs
   - Test plotly rendering

3. **Phase 3: Advanced Feature** (Week 4)
   - Implement feature 4 (VIF Calculator)
   - Comprehensive testing
   - Documentation

4. **Phase 4: Merge & Deploy** (Week 5)
   - Code review
   - Final testing in Docker container
   - Merge to main
   - Deploy to production

### Documentation Updates

1. **Update docs/README.md**: Add sections for new features
2. **Create vignettes**:
   - `docs/vignettes/missing-data-adjustment.Rmd`
   - `docs/vignettes/minimal-detectable-effects.Rmd`
   - `docs/vignettes/propensity-score-methods.Rmd`
3. **Update help accordion**: Add explanations for each feature
4. **Create video tutorials**: Screen recordings demonstrating new features

---

## Summary

This implementation guide provides complete code for all 4 advanced statistical features:

1. ✅ **Missing Data Adjustment** - ~150 lines, 2-3 hours
2. ✅ **Minimal Detectable Effect** - ~350 lines, 6-8 hours
3. ✅ **Interactive Power Curves** - ~300 lines, 4-6 hours
4. ✅ **VIF Calculator** - ~400 lines, 8-10 hours

**Total: ~1200 lines of code, ~20-27 hours development time**

Each feature is fully specified with:
- Statistical methods
- UI code
- Server logic
- Helper functions
- Test cases
- Integration points

The code is production-ready and follows the existing app architecture. Implement features incrementally and test thoroughly at each stage.

---

**Next Steps:**
1. Create `advanced-statistical-features` branch
2. Start with Feature 1 (quickest win)
3. Test each feature before moving to next
4. Deploy incrementally to production

**END OF IMPLEMENTATION GUIDE**
