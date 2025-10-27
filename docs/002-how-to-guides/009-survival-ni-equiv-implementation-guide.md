# Time-to-Event Equivalence/NI Implementation Guide

**Type:** How-To
**Audience:** Developers
**Last Updated:** 2025-10-26
**Status:** In Progress (80% complete)

## Overview

This guide documents the implementation of the Time-to-Event Equivalence/Non-Inferiority testing feature (Tier 2, Feature #4 from comprehensive-feature-analysis-2025.md).

## Completed Components

### ✅ 1. Statistical Helper Functions (`R/fct_survival_ni.R`)

Created comprehensive functions for:
- `ssize_survival_ni()` - Sample size for non-inferiority tests
- `ssize_survival_equiv()` - Sample size for equivalence tests (TOST)
- `power_survival_ni()` - Power calculation for NI tests
- `mde_survival_ni()` - Minimal detectable margin calculation
- `interpret_hr_margin()` - Margin interpretation helper
- `events_survival_ni()` - Required events calculation

**Statistical Method:** Schoenfeld (1983) adapted for non-inferiority testing with HR margins.

### ✅ 2. Module Structure (`R/mod_09_survival_equivalence.R`)

**UI Features:**
- Test type selector: Non-inferiority vs. Equivalence
- Calculation mode: Sample size vs. Margin
- Expected HR input with validation and help content
- Margin inputs (conditional on test type)
- Standard survival parameters (proportion exposed, event rate, allocation ratio)
- Missing data adjustment module
- Clustering adjustment module
- E-value sensitivity analysis module
- Example and Reset buttons

**Server Features:**
- Module initialization with all sub-modules
- Example and reset button handlers
- Reactive inputs exported for app_server.R

### ✅ 3. Result Text Helpers (`R/utils_text.R`)

Added three new helper functions:
- `create_survival_ni_samplesize_text()` - NI sample size results
- `create_survival_equiv_samplesize_text()` - Equivalence sample size results
- `create_survival_ni_margin_text()` - Minimal detectable margin results

### ✅ 4. Integration

- ✅ Added module to `R/app_ui.R` (line 222)
- ✅ Initialized module server in `R/app_server.R` (line 55)
- ✅ Added page mapping to `get_page_display_name()` (line 91)
- ✅ Added sidebar navigation in `R/utils_ui_sidebar.R` (lines 242-254)

## Remaining Work

### ❌ 5. Calculation Logic (app_server.R)

**Location:** In the `output$results` render function, after the mediation_analysis section (around line 1700)

**Required Code Structure:**

```r
} else if (input$sidebar_page == "survival_ni_equiv") {
  # Time-to-Event Equivalence/Non-Inferiority
  tab9_inputs <- tab9_vals$inputs()
  test_type <- tab9_inputs$test_type
  calc_mode <- tab9_inputs$calc_mode
  power <- tab9_inputs$power / 100
  hr_expected <- tab9_inputs$hr_expected
  prop_exposed <- tab9_inputs$prop_exposed / 100
  event_rate <- tab9_inputs$event_rate / 100
  ratio <- tab9_inputs$allocation_ratio
  alpha <- tab9_inputs$alpha

  md_vals <- tab9_vals$missing_data_vals()
  clust_vals <- tab9_vals$clustering_vals()

  if (calc_mode == "calc_n") {
    # Calculate sample size
    if (test_type == "non-inferiority") {
      hr_margin <- tab9_inputs$hr_margin_ni

      # Base calculation
      n_base <- ssize_survival_ni(
        power = power,
        hr_expected = hr_expected,
        hr_margin = hr_margin,
        k = prop_exposed,
        pE = event_rate,
        alpha = alpha,
        ratio = ratio
      )

      # Apply missing data adjustment
      if (md_vals$adjust_missing) {
        missing_adj <- calc_missing_data_inflation(...)
        n_total <- missing_adj$n_inflated
      } else {
        n_total <- n_base
      }

      # Apply clustering adjustment
      if (clust_vals$adjust_clustering) {
        de <- calc_design_effect(clust_vals$cluster_size, clust_vals$icc)
        n_total <- ceiling(n_total * de)
      }

      # Calculate group sizes
      n_test <- ceiling(n_total / (1 + ratio))
      n_ref <- n_total - n_test

      # Calculate events
      d_events <- events_survival_ni(power, hr_expected, hr_margin, alpha)

      # Generate result text
      result_text <- create_survival_ni_samplesize_text(
        n_total, n_test, n_ref, d_events,
        hr_expected, hr_margin, power, alpha,
        prop_exposed, event_rate
      )

      # Add missing data text if applicable
      if (md_vals$adjust_missing) {
        missing_text <- format_missing_data_text(missing_adj, n_base)
        result_text <- tagList(result_text, missing_text)
      }

      # Add clustering text if applicable
      if (clust_vals$adjust_clustering) {
        clustering_text <- format_clustering_text(clust_vals, n_before_clustering)
        result_text <- tagList(result_text, clustering_text)
      }

      HTML(as.character(result_text))

    } else {
      # Equivalence calculation
      hr_margin <- tab9_inputs$hr_margin_equiv
      hr_lower <- 1 / hr_margin
      hr_upper <- hr_margin

      # Similar structure to NI but using ssize_survival_equiv()
      # [Code similar to above]
    }

  } else {
    # Calculate margin (calc_mode == "calc_margin")
    n_fixed <- tab9_inputs$n_fixed

    # Account for adjustments in reverse
    # [Code to calculate minimal detectable margin]

    margin_detectable <- mde_survival_ni(
      n = n_effective,
      hr_expected = hr_expected,
      power = power,
      k = prop_exposed,
      pE = event_rate,
      alpha = alpha,
      ratio = ratio
    )

    result_text <- create_survival_ni_margin_text(
      margin_detectable, n_fixed, hr_expected,
      power, alpha, event_rate
    )

    HTML(as.character(result_text))
  }
}
```

### ❌ 6. Validation Logic (app_server.R)

**Location:** In the input validation section (around line 400)

```r
} else if (input$sidebar_page == "survival_ni_equiv") {
  tab9_inputs <- tab9_vals$inputs()
  validate(
    need(tab9_inputs$hr_expected > 0, "Expected HR must be positive"),
    need(tab9_inputs$prop_exposed > 0 && tab9_inputs$prop_exposed < 100, "Proportion exposed must be 0-100%"),
    need(tab9_inputs$event_rate > 0 && tab9_inputs$event_rate < 100, "Event rate must be 0-100%"),
    need(tab9_inputs$allocation_ratio > 0, "Allocation ratio must be positive")
  )

  if (tab9_inputs$calc_mode == "calc_n") {
    if (tab9_inputs$test_type == "non-inferiority") {
      validate(
        need(tab9_inputs$hr_margin_ni > 1, "NI margin must be > 1.0 (e.g., 1.25 for 25% increase)"),
        need(tab9_inputs$hr_expected < tab9_inputs$hr_margin_ni, "Expected HR must be better than margin to demonstrate NI")
      )
    } else {
      validate(
        need(tab9_inputs$hr_margin_equiv > 1, "Equivalence margin must be > 1.0"),
        need(abs(log(tab9_inputs$hr_expected)) < abs(log(tab9_inputs$hr_margin_equiv)),
             "Expected HR must be within equivalence bounds")
      )
    }
  } else {
    validate(
      need(tab9_inputs$n_fixed >= 50, "Sample size must be at least 50")
    )
  }
}
```

### ❌ 7. Visualization Logic (app_server.R)

**Location:** In the `output$plot` render function (around line 2150)

```r
} else if (input$sidebar_page == "survival_ni_equiv") {
  tab9_inputs <- tab9_vals$inputs()
  test_type <- tab9_inputs$test_type
  calc_mode <- tab9_inputs$calc_mode

  if (calc_mode == "calc_n") {
    # Power curve: power vs. sample size
    current_power <- tab9_inputs$power / 100
    n_seq <- seq(from = 100, to = 2000, length.out = 50)

    if (test_type == "non-inferiority") {
      hr_margin <- tab9_inputs$hr_margin_ni
      power_vals <- vapply(n_seq, function(n) {
        power_survival_ni(
          n = n,
          hr_expected = tab9_inputs$hr_expected,
          hr_margin = hr_margin,
          k = tab9_inputs$prop_exposed / 100,
          pE = tab9_inputs$event_rate / 100,
          alpha = tab9_inputs$alpha,
          ratio = tab9_inputs$allocation_ratio
        )
      }, FUN.VALUE = numeric(1))
    } else {
      # Equivalence: use min of two power calculations
      # [Similar code for equivalence]
    }

    # Create plot
    create_power_curve_plot(
      n_seq = n_seq,
      power_vals = power_vals,
      n_current = NULL,  # No current N in this mode
      target_power = current_power,
      plot_title = paste("Power Curve:",
                         ifelse(test_type == "non-inferiority", "Non-Inferiority", "Equivalence"),
                         "Test"),
      xaxis_title = "Total Sample Size (N)",
      n_reference_label = "Target Power"
    )

  } else {
    # Margin calculation mode: show margin vs. sample size
    # [Code to create margin sensitivity plot]
  }
}
```

### ❌ 8. CSV Export Logic (app_server.R)

**Location:** In the `output$download_csv` handler (around line 2680)

```r
} else if (input$sidebar_page == "survival_ni_equiv") {
  tab9_inputs <- tab9_vals$inputs()
  # [Extract calculation results and create data frame]
  results <- data.frame(
    Analysis_Type = ifelse(tab9_inputs$test_type == "non-inferiority",
                          "Time-to-Event Non-Inferiority",
                          "Time-to-Event Equivalence"),
    Calculation_Mode = ifelse(tab9_inputs$calc_mode == "calc_n",
                              "Sample Size Calculation",
                              "Margin Calculation"),
    Expected_HR = tab9_inputs$hr_expected,
    # ... rest of parameters and results
    Date = Sys.Date()
  )
}
```

## Testing Checklist

### Manual Testing

- [ ] Test non-inferiority sample size calculation
  - [ ] With typical values (HR=0.95, margin=1.25)
  - [ ] With extreme values
  - [ ] With missing data adjustment
  - [ ] With clustering adjustment
- [ ] Test equivalence sample size calculation
  - [ ] With typical values (HR=1.0, margin=1.20)
  - [ ] With unequal allocation ratios
- [ ] Test margin calculation mode
  - [ ] Verify margins make clinical sense
  - [ ] Test with various sample sizes
- [ ] Test E-value integration
- [ ] Test example and reset buttons
- [ ] Test power curve visualization
- [ ] Test CSV export
- [ ] Test mobile responsiveness

### Validation Testing

- [ ] Compare against published examples
- [ ] Cross-check with PASS or nQuery if available
- [ ] Verify formulas match literature
- [ ] Test edge cases:
  - [ ] HR = margin (should warn/fail)
  - [ ] Very small sample sizes
  - [ ] Very high event rates
  - [ ] Extreme allocation ratios

### Integration Testing

- [ ] Verify sidebar navigation works
- [ ] Verify page transitions smooth
- [ ] Verify all modules render correctly
- [ ] Verify no console errors
- [ ] Verify keyboard shortcuts work

## Statistical Validation

Compare results against published examples:

**Example 1: Cardiovascular NI Trial**
- Expected HR: 0.95
- NI Margin: 1.25
- Power: 80%
- Alpha: 0.025
- Event rate: 30%
- Expected N: ~1000-1200 (verify exact calculation)

**Example 2: Equivalence Study**
- Expected HR: 1.0
- Margins: [0.8, 1.25]
- Power: 80%
- Alpha: 0.05 (TOST)
- Event rate: 40%
- Expected N: ~800-1000 (verify exact calculation)

## Documentation Updates

### Update comprehensive-feature-analysis-2025.md

Mark Feature #4 as COMPLETED:

```markdown
#### **NEW 4: Time-to-Event Equivalence/Non-Inferiority** ✅ **COMPLETED**

**Priority:** ⭐⭐⭐⭐ **SHOULD HAVE**

**Status:** ✅ **IMPLEMENTED (2025-10-26)**

**What:** Equivalence and non-inferiority testing for time-to-event data using hazard ratios

**Implementation Details:**
- Created `R/fct_survival_ni.R` - Statistical functions (380+ lines)
- Created `R/mod_09_survival_equivalence.R` - UI and server module (300+ lines)
- Added result text helpers in `R/utils_text.R`
- Integrated into app UI, server, and sidebar navigation
- Supports both NI and equivalence tests
- Includes missing data, clustering, and E-value modules
- Two calculation modes: sample size and minimal detectable margin

**Statistical Methods:**
- Schoenfeld (1983) adapted for NI testing
- Two one-sided tests (TOST) for equivalence
- HR-based margins (future: RMST option)

**Impact:** ⭐⭐⭐⭐⭐
- Fills critical gap for survival NI/equivalence studies
- Competitive advantage: Most free tools don't have this
- Regulatory relevant (FDA/EMA guidance compliant)
- Modern, interactive interface

**Actual Effort:** 10-12 hours (design + implementation + testing)
```

## Known Limitations

1. **HR-based only:** Currently implements HR-based NI/equivalence. RMST (Restricted Mean Survival Time) methods planned for future enhancement.

2. **Proportional hazards assumption:** Assumes proportional hazards. If violated, RMST methods (future) will be more appropriate.

3. **Single time point:** Does not support multiple interim analyses or adaptive designs.

## Future Enhancements

### Enhancement 1: RMST-Based Methods (Tier 3)

Add restricted mean survival time approach for robustness to non-proportional hazards:
- More complex calculations
- Requires tau (restriction time) parameter
- More robust than HR-based methods

### Enhancement 2: Sample Size by Events (Tier 3)

Allow users to specify required events directly rather than total N and event rate:
- Common in oncology trials
- More precise for survival studies
- Requires accrual modeling

### Enhancement 3: Graphical Display of Margins (Tier 3)

Visual representation of equivalence/NI regions:
- Forest plot style visualization
- Shows margin, expected effect, confidence intervals
- Educational value for presentations

## References

1. Schoenfeld, D. (1983). "Sample-Size Formula for the Proportional-Hazards Regression Model." *Biometrics* 39(2): 499-503.

2. Julious, S.A., Campbell, M.J. (2012). "Tutorial in biostatistics: Sample sizes for parallel group clinical trials with binary data." *Statistics in Medicine* 31(24): 2904-2936.

3. FDA (2016). *Non-Inferiority Clinical Trials to Establish Effectiveness: Guidance for Industry*.

4. Hasegawa, T. (2023). "Investigating non-inferiority or equivalence in time-to-event data under non-proportional hazards." *Lifetime Data Analysis* 29: 589-618.

---

**Last Updated:** 2025-10-26
**Implementation Status:** 80% complete - Core infrastructure done, calculation/visualization logic remaining
**Next Steps:** Implement calculation, validation, and visualization logic in app_server.R
