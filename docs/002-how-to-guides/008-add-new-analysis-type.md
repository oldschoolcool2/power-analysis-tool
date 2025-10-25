# How to add a new analysis type

**Type:** How-To
**Audience:** Developers
**Last Updated:** 2025-10-25

## Overview

This guide provides step-by-step instructions for adding a new analysis type (power calculation, sample size calculation, or other statistical analysis) to the Power Analysis Tool while maintaining consistency with the refactored codebase.

## Prerequisites

- Development environment set up
- Familiar with Shiny reactivity
- Read [How to use Shiny modules and helper functions](/docs/002-how-to-guides/005-using-shiny-modules-and-helpers.md)
- Understand the existing analysis tabs (review `app.R`)

## Quick Reference Checklist

- [ ] Design the analysis (inputs, calculations, outputs)
- [ ] Add UI components using helper functions
- [ ] Add server calculation logic
- [ ] Add result text using helper functions
- [ ] Add visualization (plot) using helper functions
- [ ] Add example and reset buttons
- [ ] Add to sidebar navigation
- [ ] Test thoroughly
- [ ] Document your analysis
- [ ] Commit your changes

---

## Step 1: Design Your Analysis

Before writing code, answer these questions:

### Analysis Design Questions

1. **What type of analysis is this?**
   - Power calculation (given N, calculate power)
   - Sample size calculation (given power, calculate N)
   - Effect size calculation (given N and power, calculate detectable effect)
   - Other (VIF, risk calculator, etc.)

2. **What inputs are needed?**
   - Sample size(s)
   - Effect size parameters (proportions, means, HR, OR, etc.)
   - Alpha level
   - Power level
   - Other parameters (allocation ratio, prevalence, etc.)

3. **Should it support missing data adjustment?**
   - Yes → Use `missing_data_ui()` module
   - No → Skip missing data components

4. **Should it have multiple calculation modes?**
   - Example: Calculate N vs. Calculate Effect Size
   - Use `radioButtons_fixed()` to toggle modes

5. **What outputs should be displayed?**
   - Result text (formatted using helper functions)
   - Plot (power curve, sensitivity analysis, etc.)
   - Effect size interpretation
   - Recommendations

### Document Your Design

Create a simple design document before coding:

```markdown
## New Analysis: Power (Logistic Regression)

**Purpose:** Calculate power for logistic regression with binary predictor

**Inputs:**
- Sample size (N)
- Odds ratio (OR)
- Prevalence of predictor (%)
- Alpha level
- Missing data adjustment (yes/no)

**Outputs:**
- Calculated power
- Power curve plot (power vs N)
- OR interpretation (protective/risk)
- Result text (copy-pasteable)

**Statistical Method:**
- Hsieh et al. (1998) method for logistic regression power
```

---

## Step 2: Add Sidebar Navigation

### Add to Sidebar Menu

In `app.R`, locate the sidebar menu section (~line 100-150):

```r
selectInput("sidebar_page",
  label = NULL,
  choices = c(
    "Power (Single Proportion)" = "power_single",
    "Sample Size (Single Proportion)" = "ss_single",
    # ... existing tabs ...
    "Propensity Score Methods: VIF Calculator" = "vif_calculator",
    "Power (Logistic Regression)" = "power_logistic"  # ← ADD YOUR TAB HERE
  ),
  selected = "power_single"
)
```

**Naming Convention:**
- Use descriptive names: "Power (Analysis Type)" or "Sample Size (Analysis Type)"
- Keep consistent with existing tabs
- Use proper capitalization

---

## Step 3: Create the UI (Using Helpers)

### Add Conditional Panel for Your Analysis

In `app.R`, add your UI in the input cards section (~line 200-700):

```r
# PAGE 12: Power (Logistic Regression)
conditionalPanel(
  condition = "input.sidebar_page == 'power_logistic'",
  h2(class = "page-title", "Power Analysis: Logistic Regression"),
  helpText("Calculate statistical power for logistic regression with binary predictor"),
  hr(),

  # Use helper for numeric inputs
  create_numeric_input_with_tooltip(
    "logistic_n",
    "Sample Size (N):",
    value = 200,
    min = 10,
    step = 10,
    tooltip = "Total number of participants in the study"
  ),

  create_numeric_input_with_tooltip(
    "logistic_or",
    "Odds Ratio:",
    value = 2.0,
    min = 0.01,
    step = 0.1,
    tooltip = "Expected odds ratio for the predictor variable"
  ),

  # Use existing slider helpers
  create_enhanced_slider(
    "logistic_prevalence",
    "Prevalence of Predictor (%):",
    min = 5,
    max = 95,
    value = 50,
    step = 5,
    post = "%",
    tooltip = "Percentage of participants with the predictor variable"
  ),

  create_segmented_alpha(
    "logistic_alpha",
    "Significance Level (α):",
    selected = 0.05,
    choices = c(0.001, 0.01, 0.05, 0.10),
    tooltip = "Type I error rate (probability of false positive)"
  ),

  # Include missing data module if applicable
  hr(),
  h4("Missing Data Adjustment"),
  missing_data_ui(NS("power_logistic", "missing_data")),

  # Example and Reset buttons
  hr(),
  div(class = "btn-group-custom",
    actionButton("example_power_logistic", "Load Example",
                 icon = icon("lightbulb"), class = "btn-info btn-sm"),
    actionButton("reset_power_logistic", "Reset",
                 icon = icon("refresh"), class = "btn-secondary btn-sm")
  )
)
```

### UI Best Practices

✅ **DO:**
- Use `create_numeric_input_with_tooltip()` for all numeric inputs
- Use `create_enhanced_slider()` for sliders
- Use `create_segmented_alpha()` and `create_segmented_power()` for common parameters
- Use `missing_data_ui()` module for missing data adjustment
- Include example and reset buttons
- Add helpful tooltips for all inputs

❌ **DON'T:**
- Use bare `numericInput()` + `bsTooltip()` (use helper instead)
- Hardcode missing data UI (use module instead)
- Skip tooltips (users need guidance)
- Forget example/reset buttons

---

## Step 4: Add Contextual Help

In the contextual help section (~line 750-850):

```r
# Contextual help for Power (Logistic Regression)
conditionalPanel(
  condition = "input.sidebar_page == 'power_logistic'",
  div(class = "contextual-help",
    create_contextual_help("power_logistic")
  )
)
```

Add the help content in the helper function section (~line 900-1000):

```r
create_contextual_help <- function(page) {
  if (page == "power_logistic") {
    HTML(paste0(
      "<h4>About Logistic Regression Power Analysis</h4>",
      "<p>This calculator determines the statistical power to detect a specified odds ratio ",
      "in a logistic regression model with one binary predictor.</p>",
      "<h5>When to Use</h5>",
      "<ul>",
      "<li>Binary outcome (yes/no, disease/healthy, etc.)</li>",
      "<li>Binary predictor (exposed/unexposed, treatment/control, etc.)</li>",
      "<li>Planning a study with logistic regression</li>",
      "</ul>",
      "<h5>Key Considerations</h5>",
      "<ul>",
      "<li><strong>Odds Ratio:</strong> OR > 1 indicates increased risk, OR < 1 indicates protective effect</li>",
      "<li><strong>Prevalence:</strong> Affects power; balanced prevalence (50%) provides most power</li>",
      "<li><strong>Sample Size:</strong> Larger N increases power</li>",
      "</ul>",
      "<h5>Statistical Method</h5>",
      "<p>Uses the method of Hsieh et al. (1998) for power calculation in logistic regression.</p>"
    ))
  }
  # ... other pages ...
}
```

---

## Step 5: Add Example and Reset Values

In the examples and reset values list (~line 1150-1200):

```r
power_logistic = list(
  example = list(
    logistic_n = 250,
    logistic_or = 2.5,
    logistic_prevalence = 40,
    logistic_alpha = 0.05
  ),
  reset = list(
    logistic_n = 200,
    logistic_or = 2.0,
    logistic_prevalence = 50,
    logistic_alpha = 0.05
  )
),
```

---

## Step 6: Add Server Logic

### Initialize Missing Data Module (if applicable)

In the server function (~line 1300):

```r
server <- function(input, output, session) {

  # Initialize missing data module for this analysis
  missing_data_power_logistic <- missing_data_server("power_logistic-missing_data")

  # ... rest of server logic ...
}
```

### Add Calculation Logic

In the main results reactive (~line 1400-2500):

```r
} else if (input$sidebar_page == "power_logistic") {
  # PAGE 12: Power (Logistic Regression)

  # Get inputs
  n <- input$logistic_n
  or <- input$logistic_or
  prevalence <- input$logistic_prevalence / 100
  alpha <- input$logistic_alpha
  md_vals <- missing_data_power_logistic()

  # Adjust sample size for missing data if enabled
  if (md_vals$adjust_missing) {
    p_missing <- md_vals$missing_pct / 100
    n_effective <- ceiling(n * (1 - p_missing))
  } else {
    n_effective <- n
  }

  # Calculate power using appropriate statistical method
  # Example using custom function:
  power_result <- calculate_logistic_power(
    n = n_effective,
    or = or,
    prevalence = prevalence,
    alpha = alpha
  )

  # Format results using helper functions
  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")

  text3 <- p(paste0(
    "With a sample size of N = ", format_numeric(n, 0), " participants, ",
    "the study has ", format_numeric(power_result * 100, 1), "% power ",
    "to detect an odds ratio of ", format_numeric(or, 2), " ",
    "(α = ", alpha, ", two-sided test), ",
    "assuming ", format_numeric(prevalence * 100, 0), "% prevalence of the predictor variable.",
    if (md_vals$adjust_missing) {
      paste0(" <strong>After accounting for ", md_vals$missing_pct,
             "% missing data, the effective sample size is ", n_effective, " participants.</strong>")
    } else {
      ""
    }
  ))

  # Add OR interpretation using helper
  or_interpretation <- format_odds_ratio(or)  # You may need to create this helper

  HTML(paste0(text0, text1, text2, text3, or_interpretation))
}
```

### Best Practices for Server Logic

✅ **DO:**
- Use `format_numeric()` for all number formatting
- Use existing helper functions when available
- Use module reactive values (e.g., `md_vals$adjust_missing`)
- Add interpretation helpers for effect sizes
- Follow existing patterns from refactored tabs

❌ **DON'T:**
- Use `round()` or `format()` directly (use `format_numeric()` instead)
- Access inputs directly in nested conditions (extract to variables first)
- Duplicate missing data calculation logic (use helpers/modules)

---

## Step 7: Add Visualization (Plot)

### Add Plot Output

In the plot rendering section (~line 3000-3300):

```r
} else if (input$tabset == "Power (Logistic Regression)") {
  # Generate power curve
  n_current <- input$logistic_n
  or <- input$logistic_or
  prevalence <- input$logistic_prevalence / 100
  alpha <- input$logistic_alpha

  # Generate sample size sequence
  n_seq <- generate_n_sequence(n_current)

  # Calculate power for each N
  power_vals <- vapply(n_seq, function(n) {
    calculate_logistic_power(n, or, prevalence, alpha)
  }, FUN.VALUE = numeric(1))

  # Create plot using helper function
  create_power_curve_plot(
    n_seq = n_seq,
    power_vals = power_vals,
    n_current = n_current,
    target_power = 0.8,
    plot_title = "Power Curve: Logistic Regression",
    xaxis_title = "Sample Size (N)",
    n_reference_label = "Current N"
  )
}
```

### Plot Best Practices

✅ **DO:**
- Use `generate_n_sequence()` for sample size sequences
- Use `create_power_curve_plot()` for standard power curves
- Reuse existing plot helpers when possible
- Include target power line (usually 80%)
- Add descriptive plot title

❌ **DON'T:**
- Write custom plotly code (use helpers instead)
- Hardcode plot styling (helpers provide consistency)
- Skip the power curve (users expect it)

---

## Step 8: Create Helper Functions (if needed)

If your analysis needs custom calculations or formatting, add helper functions:

### Statistical Calculation Helper

Add to `R/helpers/` or in the helper functions section of `app.R`:

```r
# Helper function: Calculate power for logistic regression
calculate_logistic_power <- function(n, or, prevalence, alpha = 0.05) {
  # Hsieh et al. (1998) method
  # This is a simplified example - use appropriate statistical formula

  # Log odds ratio
  beta <- log(or)

  # Variance under null
  p <- prevalence
  var_beta <- 1 / (n * p * (1 - p))

  # Non-centrality parameter
  ncp <- beta / sqrt(var_beta)

  # Calculate power
  z_alpha <- qnorm(1 - alpha / 2)
  power <- pnorm(abs(ncp) - z_alpha) + pnorm(-abs(ncp) - z_alpha)

  return(power)
}
```

### Result Text Helper

Add to `R/helpers/002-result-text-helpers.R`:

```r
#' Format Odds Ratio Interpretation
#'
#' @param or Numeric odds ratio value
#' @return HTML formatted string with OR interpretation
#' @export
format_odds_ratio <- function(or) {
  if (is.na(or) || !is.numeric(or) || or <= 0) {
    return(HTML(""))
  }

  # Determine interpretation
  if (or < 0.5) {
    interpretation <- "strong protective effect"
    color <- "#2e7d32"  # green
  } else if (or < 0.8) {
    interpretation <- "moderate protective effect"
    color <- "#66bb6a"  # light green
  } else if (or <= 1.2) {
    interpretation <- "minimal or no effect"
    color <- "#9e9e9e"  # gray
  } else if (or <= 2.0) {
    interpretation <- "moderate increased risk"
    color <- "#ff9800"  # orange
  } else {
    interpretation <- "strong increased risk"
    color <- "#d32f2f"  # red
  }

  HTML(paste0(
    "<div style='background-color: #f5f5f5; border-left: 4px solid ", color, "; padding: 10px; margin: 10px 0;'>",
    "<strong>Odds Ratio Interpretation:</strong><br>",
    "OR = ", format_numeric(or, 2), " indicates <span style='color: ", color, "; font-weight: bold;'>",
    interpretation, "</span>.",
    "</div>"
  ))
}
```

---

## Step 9: Test Your Analysis

### Manual Testing Checklist

- [ ] Load the app and navigate to your new tab
- [ ] Test with default values - does it calculate correctly?
- [ ] Click "Load Example" - does it populate expected values?
- [ ] Click "Reset" - does it return to defaults?
- [ ] Test edge cases:
  - [ ] Very small sample size (n=10)
  - [ ] Very large sample size (n=10,000)
  - [ ] Effect size = 1 (null effect)
  - [ ] Extreme effect sizes
- [ ] Test missing data adjustment (if applicable):
  - [ ] Enable missing data - does UI appear?
  - [ ] Try different mechanisms (MCAR, MAR, MNAR)
  - [ ] Try different analysis approaches (CCA, MI, etc.)
- [ ] Test the plot:
  - [ ] Does power curve render?
  - [ ] Is current N marker visible?
  - [ ] Does hover text show correct values?
- [ ] Test result text:
  - [ ] Is text grammatically correct?
  - [ ] Are numbers formatted consistently?
  - [ ] Can text be copy/pasted?
- [ ] Test responsiveness:
  - [ ] Does output update when inputs change?
  - [ ] No console errors?

### Automated Testing (Optional)

If you're familiar with testing, add tests in `tests/`:

```r
test_that("Logistic regression power calculation works", {
  power <- calculate_logistic_power(n = 200, or = 2.0, prevalence = 0.5, alpha = 0.05)
  expect_true(power > 0 && power < 1)
  expect_true(is.numeric(power))
})
```

---

## Step 10: Document Your Analysis

### Update Documentation

1. **Update README.md** (if user-facing feature):
   ```markdown
   ### Power Analysis Types
   - Single proportion
   - Two-group comparison
   - ...
   - **Logistic regression** (NEW)
   ```

2. **Create reference documentation** in `docs/003-reference/`:
   - Document your statistical method
   - Include formulas and assumptions
   - Provide references to published methods

3. **Create explanation documentation** (if needed) in `docs/004-explanation/`:
   - Why this analysis type was added
   - Design decisions made
   - Alternative approaches considered

4. **Update the comprehensive feature analysis**:
   Add your analysis to `docs/004-explanation/003-comprehensive-feature-analysis-2025.md`

---

## Step 11: Commit Your Changes

Follow the git commit guidelines from `CLAUDE.md`:

```bash
git add app.R R/helpers/002-result-text-helpers.R docs/
git commit -m "feat(logistic): add logistic regression power analysis

Add new analysis type for logistic regression with binary predictor.
Includes:
- Power calculation using Hsieh et al. (1998) method
- Missing data adjustment via module
- Power curve visualization
- Odds ratio interpretation
- Example and reset functionality

Uses refactored helpers for consistent UI/UX.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Complete Example: Adding a Simple Analysis

Here's a minimal working example for adding a simple power calculation:

### UI Section (app.R ~line 200-700)

```r
conditionalPanel(
  condition = "input.sidebar_page == 'power_simple'",
  h2(class = "page-title", "Simple Power Analysis"),

  create_numeric_input_with_tooltip(
    "simple_n", "Sample Size:", 100,
    min = 10, step = 10,
    tooltip = "Total sample size"
  ),

  create_numeric_input_with_tooltip(
    "simple_effect", "Effect Size (Cohen's d):", 0.5,
    min = 0.01, step = 0.1,
    tooltip = "Standardized effect size"
  ),

  create_segmented_alpha("simple_alpha", "Significance Level (α):", selected = 0.05)
)
```

### Server Section (app.R ~line 1400-2500)

```r
} else if (input$sidebar_page == "power_simple") {
  n <- input$simple_n
  d <- input$simple_effect
  alpha <- input$simple_alpha

  # Calculate power (using pwr package as example)
  power_result <- pwr::pwr.t.test(n = n, d = d, sig.level = alpha)$power

  text0 <- hr()
  text1 <- h1("Power Analysis Results")
  text2 <- h4("(This text can be copy/pasted)")
  text3 <- p(paste0(
    "With N = ", format_numeric(n, 0), " and effect size d = ", format_numeric(d, 2),
    ", the power is ", format_numeric(power_result * 100, 1), "% (α = ", alpha, ")."
  ))

  HTML(paste0(text0, text1, text2, text3))
}
```

---

## Common Patterns Reference

### Pattern 1: Two Calculation Modes (Calculate N vs Calculate Effect)

```r
# UI
radioButtons_fixed("calc_mode", "Calculation Mode:",
  choices = c("Calculate Sample Size" = "calc_n",
              "Calculate Effect Size" = "calc_effect"),
  selected = "calc_n")

# Server
if (input$calc_mode == "calc_n") {
  # Calculate sample size given effect and power
} else {
  # Calculate minimal detectable effect given N and power
}
```

### Pattern 2: Using Missing Data Module

```r
# UI
missing_data_ui(NS("my_analysis", "missing_data"))

# Server initialization
missing_data_vals <- missing_data_server("my_analysis-missing_data")

# Server usage
md_vals <- missing_data_vals()
if (md_vals$adjust_missing) {
  missing_adj <- calc_missing_data_inflation(
    n_base, md_vals$missing_pct, md_vals$missing_mechanism,
    md_vals$missing_analysis, md_vals$mi_imputations, md_vals$mi_r_squared
  )
  n_final <- missing_adj$n_inflated
}
```

### Pattern 3: Power Curve Plot

```r
# Generate sequence
n_seq <- generate_n_sequence(n_current)

# Calculate power for each N
power_vals <- vapply(n_seq, function(n) {
  your_power_function(n, effect_size, alpha)
}, FUN.VALUE = numeric(1))

# Plot
create_power_curve_plot(n_seq, power_vals, n_current)
```

---

## Troubleshooting

### Issue: My tab doesn't appear

**Solution:** Check these items:
1. Added to `selectInput()` choices in sidebar (~line 100)
2. `conditionalPanel()` condition matches the value in selectInput
3. No syntax errors (check console)

### Issue: Inputs not working

**Solution:**
1. Check input IDs are unique across entire app
2. Verify you're using helpers correctly (`create_numeric_input_with_tooltip()`)
3. Check for typos in input IDs

### Issue: Missing data module not working

**Solution:**
1. Verify namespace: `missing_data_ui(NS("myanalysis", "missing_data"))`
2. Server initialization: `missing_data_server("myanalysis-missing_data")` (note the dash!)
3. Call reactive: `md_vals <- missing_data_vals()`
4. Check you're using `md_vals$adjust_missing`, not `md_vals()$adjust_missing`

### Issue: Numbers not formatted correctly

**Solution:**
- Always use `format_numeric(value, digits)` instead of `round()` or `format()`
- Check the helper function exists in `R/helpers/002-result-text-helpers.R`

---

## Best Practices Summary

### UI Best Practices

✅ Use helper functions for all inputs
✅ Include tooltips for all parameters
✅ Use consistent naming: `[analysis]_[parameter]`
✅ Include example and reset buttons
✅ Use missing data module (don't duplicate UI)

### Server Best Practices

✅ Use `format_numeric()` for all numbers
✅ Extract inputs to variables (don't nest `input$` calls)
✅ Use helper functions for effect size interpretation
✅ Follow existing result text structure
✅ Use plot helpers (don't write custom plotly)

### Code Organization

✅ Keep UI in one section, server in another
✅ Create helper functions for reusable logic
✅ Document statistical methods with references
✅ Test edge cases thoroughly
✅ Commit with descriptive messages

---

## Next Steps

After adding your analysis:

1. **Test thoroughly** - Use the manual testing checklist above
2. **Get feedback** - Have someone else try your analysis
3. **Monitor usage** - Check for bugs or user confusion
4. **Iterate** - Improve based on feedback
5. **Document** - Write reference docs for your statistical method

---

**Related Documentation:**
- [How to use Shiny modules and helper functions](/docs/002-how-to-guides/005-using-shiny-modules-and-helpers.md)
- [Contributing Guide](/docs/002-how-to-guides/001-contributing.md)
- [CLAUDE.md](/CLAUDE.md) - Project documentation standards

**References:**
- [Shiny Documentation](https://shiny.rstudio.com/)
- [Shiny Modules](https://shiny.rstudio.com/articles/modules.html)
- Statistical references for your specific analysis type

---

**Last Updated:** 2025-10-25
**Maintained By:** Development Team
