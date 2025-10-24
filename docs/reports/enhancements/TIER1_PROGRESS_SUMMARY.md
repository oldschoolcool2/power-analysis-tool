# Tier 1 Implementation - Progress Summary

**Date:** 2025-10-24
**Time:** Current Session
**Feature:** Missing Data Adjustment (Feature 1 of 4)

---

## ✅ COMPLETED SO FAR

### 1. Package Dependencies ✅
- Added `plotly`, `ggplot2`, `PSweight` to `app.R` (lines 17-18)
- Added package entries to `renv.lock` (lines 84-101)

### 2. Helper Function ✅
- Added `calc_missing_data_inflation()` function (lines 461-501)
- Fully implemented and tested
- Handles MCAR, MAR, MNAR mechanisms
- Returns inflation factor, adjusted N, and interpretation text

### 3. UI Implementation ✅
Successfully added missing data adjustment UI to:
- ✅ **Tab 2:** Sample Size (Single) - lines 80-104
- ✅ **Tab 4:** Sample Size (Two-Group) - lines 157-181
- ✅ **Tab 6:** Sample Size (Survival) - lines 225-249
- ✅ **Tab 7:** Matched Case-Control - lines 277-301

### 4. Calculation Logic ✅
Successfully integrated calculations for:
- ✅ **Tab 2:** Sample Size (Single) - lines 843-887
- ✅ **Tab 4:** Sample Size (Two-Group) - lines 951-999

---

## 🔄 REMAINING WORK

### UI Still Needed (2 tabs):
**Tab 9: Sample Size (Continuous)** - Add before line 388:
```r
hr(),
checkboxInput("adjust_missing_cont_ss", "Adjust for Missing Data", value = FALSE),
conditionalPanel(
  condition = "input.adjust_missing_cont_ss",
  sliderInput("missing_pct_cont_ss",
    "Expected Missingness (%)",
    min = 5, max = 50, value = 20, step = 5
  ),
  bsTooltip("missing_pct_cont_ss",
    "Percentage of participants with missing exposure, outcome, or covariate data",
    "right"
  ),
  radioButtons("missing_mechanism_cont_ss",
    "Missing Data Mechanism:",
    choices = c(
      "MCAR (Missing Completely At Random)" = "mcar",
      "MAR (Missing At Random)" = "mar",
      "MNAR (Missing Not At Random)" = "mnar"
    ),
    selected = "mar"
  ),
  bsTooltip("missing_mechanism_cont_ss",
    "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
    "right"
  )
),
hr(),
```

**Tab 10: Non-Inferiority** - Add before line 411:
```r
hr(),
checkboxInput("adjust_missing_noninf", "Adjust for Missing Data", value = FALSE),
conditionalPanel(
  condition = "input.adjust_missing_noninf",
  sliderInput("missing_pct_noninf",
    "Expected Missingness (%)",
    min = 5, max = 50, value = 20, step = 5
  ),
  bsTooltip("missing_pct_noninf",
    "Percentage of participants with missing exposure, outcome, or covariate data",
    "right"
  ),
  radioButtons("missing_mechanism_noninf",
    "Missing Data Mechanism:",
    choices = c(
      "MCAR (Missing Completely At Random)" = "mcar",
      "MAR (Missing At Random)" = "mar",
      "MNAR (Missing Not At Random)" = "mnar"
    ),
    selected = "mar"
  ),
  bsTooltip("missing_mechanism_noninf",
    "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
    "right"
  )
),
hr(),
```

---

### Calculation Logic Still Needed (4 tabs):

#### Tab 6: Sample Size (Survival) - Around line 1000+
Find: `} else if (input$tabset == "Sample Size (Survival)") {`

**Replace the calculation block with:**
```r
} else if (input$tabset == "Sample Size (Survival)") {
  power <- input$surv_ss_power / 100
  hr <- input$surv_ss_hr
  k <- input$surv_ss_k / 100
  pE <- input$surv_ss_pE / 100

  # Calculate base sample size
  n_base <- ssizeEpi(
    power = power, theta = hr, k = k, pE = pE,
    RR = hr, alpha = input$surv_ss_alpha
  )

  # Apply missing data adjustment if enabled (Tier 1 Enhancement)
  if (input$adjust_missing_surv_ss) {
    missing_adj <- calc_missing_data_inflation(
      n_base,
      input$missing_pct_surv_ss,
      input$missing_mechanism_surv_ss
    )
    n_final <- missing_adj$n_inflated
    missing_data_text <- HTML(paste0(
      "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
      "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
      missing_adj$interpretation,
      "<br><strong>Sample size before adjustment:</strong> ", n_base,
      "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
      "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
      "</p>"
    ))
  } else {
    n_final <- n_base
    missing_data_text <- HTML("")
  }

  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
  text3 <- p(paste0(
    "For a survival analysis comparing treatment groups with an expected hazard ratio of ",
    format(hr, digits = 2, nsmall = 2), ", ",
    format(k * 100, digits = 1, nsmall = 0), "% exposed/treated, an overall event rate of ",
    format(pE * 100, digits = 1, nsmall = 0), "%, and ",
    format(power * 100, digits = 0, nsmall = 0), "% power at α = ",
    input$surv_ss_alpha, ", the required total sample size is ",
    format(n_final, digits = 0, nsmall = 0), " participants.",
    if (input$adjust_missing_surv_ss) {
      paste0(" <strong>This includes adjustment for ", input$missing_pct_surv_ss,
             "% missing data.</strong>")
    } else {
      ""
    }
  ))
  HTML(paste0(text0, text1, text2, text3, missing_data_text))
```

#### Tab 7: Matched Case-Control - Around line 1050+
Find: `} else if (input$tabset == "Matched Case-Control") {`

**Replace the calculation block with:**
```r
} else if (input$tabset == "Matched Case-Control") {
  power <- input$match_power / 100
  or <- input$match_or
  p0 <- input$match_p0 / 100
  m <- input$match_ratio
  alpha <- input$match_alpha
  sided <- input$match_sided

  # Calculate base sample size using epiR
  result <- epi.sscc(
    OR = or,
    p0 = p0,
    n = NA,
    power = power,
    r = m,
    rho = 0,
    design = 1,
    sided.test = if (sided == "two.sided") 2 else 1,
    conf.level = 1 - alpha
  )
  n_cases_base <- result$n.case
  n_controls_base <- result$n.control
  n_total_base <- n_cases_base + n_controls_base

  # Apply missing data adjustment if enabled (Tier 1 Enhancement)
  if (input$adjust_missing_match) {
    missing_adj <- calc_missing_data_inflation(
      n_total_base,
      input$missing_pct_match,
      input$missing_mechanism_match
    )
    n_total_final <- missing_adj$n_inflated
    # Maintain ratio of cases:controls
    n_cases_final <- ceiling(n_total_final / (1 + m))
    n_controls_final <- n_total_final - n_cases_final

    missing_data_text <- HTML(paste0(
      "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
      "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
      missing_adj$interpretation,
      "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
      "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
      "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
      "</p>"
    ))
  } else {
    n_cases_final <- n_cases_base
    n_controls_final <- n_controls_base
    n_total_final <- n_total_base
    missing_data_text <- HTML("")
  }

  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
  text3 <- p(paste0(
    "For a matched case-control study with ",
    m, " control(s) per case, to detect an odds ratio of ",
    format(or, digits = 2, nsmall = 2), " with ",
    format(power * 100, digits = 0, nsmall = 0), "% power at α = ",
    alpha, " (", sided, " test), assuming ",
    format(p0 * 100, digits = 1, nsmall = 0), "% exposure in controls, the required sample size is: ",
    format(n_cases_final, digits = 0, nsmall = 0), " cases and ",
    format(n_controls_final, digits = 0, nsmall = 0), " controls (total N = ",
    format(n_total_final, digits = 0, nsmall = 0), ").",
    if (input$adjust_missing_match) {
      paste0(" <strong>After adjusting for ", input$missing_pct_match,
             "% missing data.</strong>")
    } else {
      ""
    }
  ))
  HTML(paste0(text0, text1, text2, text3, missing_data_text))
```

#### Tab 9: Sample Size (Continuous) - Around line 1100+
Find: `} else if (input$tabset == "Sample Size (Continuous)") {`

**Replace the calculation block with:**
```r
} else if (input$tabset == "Sample Size (Continuous)") {
  power <- input$cont_ss_power / 100
  d <- input$cont_ss_d
  ratio <- input$cont_ss_ratio
  alpha <- input$cont_ss_alpha
  sided <- input$cont_ss_sided

  # Calculate base sample size
  if (ratio == 1) {
    result <- pwr.t.test(d = d, sig.level = alpha, power = power,
                         type = "two.sample", alternative = sided)
    n1_base <- ceiling(result$n)
    n2_base <- ceiling(result$n)
  } else {
    # Solve for n1 with unequal allocation
    f <- function(n1) {
      n2 <- n1 * ratio
      pwr.t2n.test(n1 = n1, n2 = n2, d = d, sig.level = alpha,
                   alternative = sided)$power - power
    }
    n1_base <- ceiling(uniroot(f, c(2, 1e6))$root)
    n2_base <- ceiling(n1_base * ratio)
  }
  n_total_base <- n1_base + n2_base

  # Apply missing data adjustment if enabled (Tier 1 Enhancement)
  if (input$adjust_missing_cont_ss) {
    missing_adj <- calc_missing_data_inflation(
      n_total_base,
      input$missing_pct_cont_ss,
      input$missing_mechanism_cont_ss
    )
    n_total_final <- missing_adj$n_inflated
    # Maintain allocation ratio
    n1_final <- ceiling(n_total_final / (1 + ratio))
    n2_final <- n_total_final - n1_final

    missing_data_text <- HTML(paste0(
      "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
      "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
      missing_adj$interpretation,
      "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
      "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
      "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
      "</p>"
    ))
  } else {
    n1_final <- n1_base
    n2_final <- n2_base
    n_total_final <- n_total_base
    missing_data_text <- HTML("")
  }

  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
  text3 <- p(paste0(
    "To detect a standardized mean difference of Cohen's d = ",
    format(d, digits = 2, nsmall = 2), " (",
    ifelse(d < 0.3, "small", ifelse(d < 0.7, "medium", "large")),
    " effect) with ",
    format(power * 100, digits = 0, nsmall = 0), "% power at α = ",
    alpha, " (", sided, " test), the required sample sizes are: Group 1: n1 = ",
    format(n1_final, digits = 0, nsmall = 0), ", Group 2: n2 = ",
    format(n2_final, digits = 0, nsmall = 0), " (total N = ",
    format(n_total_final, digits = 0, nsmall = 0), ").",
    if (input$adjust_missing_cont_ss) {
      paste0(" <strong>After adjusting for ", input$missing_pct_cont_ss,
             "% missing data.</strong>")
    } else {
      ""
    }
  ))
  HTML(paste0(text0, text1, text2, text3, missing_data_text))
```

#### Tab 10: Non-Inferiority - Around line 1150+
Find: `} else if (input$tabset == "Non-Inferiority") {`

**Replace the calculation block with:**
```r
} else if (input$tabset == "Non-Inferiority") {
  power <- input$noninf_power / 100
  p1 <- input$noninf_p1 / 100
  p2 <- input$noninf_p2 / 100
  margin <- input$noninf_margin / 100
  ratio <- input$noninf_ratio
  alpha <- input$noninf_alpha

  # Non-inferiority: test H0: p1 - p2 >= margin vs H1: p1 - p2 < margin
  # Using one-sided test with adjusted p2
  p2_adj <- p2 + margin
  h <- ES.h(p1, p2_adj)

  # Calculate base sample size
  if (ratio == 1) {
    result <- pwr.2p.test(h = h, sig.level = alpha, power = power,
                          alternative = "less")
    n1_base <- ceiling(result$n)
    n2_base <- ceiling(result$n)
  } else {
    f <- function(n1) {
      n2 <- n1 * ratio
      pwr.2p2n.test(h = h, n1 = n1, n2 = n2, sig.level = alpha,
                    alternative = "less")$power - power
    }
    n1_base <- ceiling(uniroot(f, c(2, 1e6))$root)
    n2_base <- ceiling(n1_base * ratio)
  }
  n_total_base <- n1_base + n2_base

  # Apply missing data adjustment if enabled (Tier 1 Enhancement)
  if (input$adjust_missing_noninf) {
    missing_adj <- calc_missing_data_inflation(
      n_total_base,
      input$missing_pct_noninf,
      input$missing_mechanism_noninf
    )
    n_total_final <- missing_adj$n_inflated
    # Maintain allocation ratio
    n1_final <- ceiling(n_total_final / (1 + ratio))
    n2_final <- n_total_final - n1_final

    missing_data_text <- HTML(paste0(
      "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
      "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
      missing_adj$interpretation,
      "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
      "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
      "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
      "</p>"
    ))
  } else {
    n1_final <- n1_base
    n2_final <- n2_base
    n_total_final <- n_total_base
    missing_data_text <- HTML("")
  }

  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
  text3 <- p(paste0(
    "For a non-inferiority trial with a margin of ",
    format(margin * 100, digits = 2, nsmall = 1), " percentage points, ",
    "expected event rates of ",
    format(p1 * 100, digits = 2, nsmall = 1), "% in the test group and ",
    format(p2 * 100, digits = 2, nsmall = 1), "% in the reference group, with ",
    format(power * 100, digits = 0, nsmall = 0), "% power at α = ",
    alpha, " (one-sided), the required sample sizes are: Test group: n1 = ",
    format(n1_final, digits = 0, nsmall = 0), ", Reference group: n2 = ",
    format(n2_final, digits = 0, nsmall = 0), " (total N = ",
    format(n_total_final, digits = 0, nsmall = 0), ").",
    if (input$adjust_missing_noninf) {
      paste0(" <strong>After adjusting for ", input$missing_pct_noninf,
             "% missing data.</strong>")
    } else {
      ""
    }
  ))
  HTML(paste0(text0, text1, text2, text3, missing_data_text))
```

---

## 📊 Progress Metrics

| Component | Total | Completed | Remaining | % Done |
|-----------|-------|-----------|-----------|---------|
| UI Implementation | 6 tabs | 4 | 2 | 67% |
| Calculation Logic | 6 tabs | 2 | 4 | 33% |
| Overall Feature 1 | | | | **50%** |

---

## 🧪 Testing Checklist

Once implementation is complete:

- [ ] Test Tab 2 with 0%, 20%, 50% missingness
- [ ] Test Tab 4 with unequal allocation + missing data
- [ ] Test Tab 6 with survival analysis + missing data
- [ ] Test Tab 7 with matched design + missing data
- [ ] Test Tab 9 with continuous outcomes + missing data
- [ ] Test Tab 10 with non-inferiority + missing data
- [ ] Verify backward compatibility (all tabs work without checkbox)
- [ ] Test in Docker container
- [ ] Verify CSV export (not yet updated)
- [ ] Visual inspection of formatting

---

## 📝 Next Steps

### Immediate (Complete Feature 1):
1. **Add remaining UI** (2 tabs): Copy-paste code above for Tab 9 and Tab 10
2. **Add remaining calculations** (4 tabs): Follow code snippets above
3. **Update CSV exports**: Add missing data fields to download handlers
4. **Test everything**: Run through all 6 tabs

### Then (Other Features):
5. **Feature 2**: Minimal Detectable Effect Size Calculator
6. **Feature 3**: Interactive Power Curves with plotly
7. **Feature 4**: VIF Calculator for propensity score methods

---

## 💾 Files Modified

- `app.R`: ~450 lines added/modified
- `renv.lock`: 3 packages added
- `docs/ideas/features.md`: Created (93 KB)
- `docs/ideas/tier1-implementation-guide.md`: Created (68 KB)
- `docs/ideas/IMPLEMENTATION_STATUS.md`: Created (15 KB)
- `docs/ideas/TIER1_PROGRESS_SUMMARY.md`: This file

---

## 🎯 Estimated Time Remaining

- Complete UI for 2 tabs: **15 minutes**
- Complete calculations for 4 tabs: **30-45 minutes**
- Test all features: **30 minutes**
- Update CSV exports: **20 minutes**
- **Total: ~2 hours to complete Feature 1**

---

**Last Updated:** 2025-10-24
**Status:** 50% Complete - UI mostly done, calculations partially done
