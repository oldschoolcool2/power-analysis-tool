# Power Analysis Tool - Feature Matrix

**Last Updated:** 2025-10-27
**Purpose:** Track feature completeness and export functionality across all modules

---

## Quick Reference

| Status | Meaning |
|--------|---------|
| ✅ | Fully implemented and tested |
| ⚠️ | Partially implemented or has limitations |
| ❌ | Not implemented |
| 🚧 | Work in progress |

---

## Module Feature Matrix

```
┌─────────────────────────────────────────────┬────────────┬────────────┬──────────┬──────────┬─────────────────────────────┐
│ Module                                      │ Power Calc │ Sample Sz  │ CSV      │ PDF      │ Statistical Method          │
├─────────────────────────────────────────────┼────────────┼────────────┼──────────┼──────────┼─────────────────────────────┤
│ 1. Single Proportion Test                  │     ✅     │     ✅     │    ✅    │    ✅    │ Cohen's h (arcsine)         │
│ 2. Two-Group Comparisons                   │     ✅     │     ✅     │    ✅    │    ❌    │ Cohen's h (2-sample)        │
│ 3. Survival Analysis (Cox)                 │     ✅     │     ✅     │    ✅    │    ❌    │ Schoenfeld (1983)           │
│ 4. Matched Case-Control                    │     ❌     │     ✅     │    ✅    │    ❌    │ McNemar's test (epiR)       │
│ 5. Continuous Outcomes (t-tests)           │     ✅     │     ✅     │    ✅    │    ❌    │ Cohen's d (t-test)          │
│ 6. Non-Inferiority Testing                 │     ❌     │     ✅     │    ✅    │    ❌    │ Cohen's h (margin adjusted) │
│ 7. Propensity Score VIF Calculator         │     N/A    │     N/A    │    ✅    │    ❌    │ VIF calculation             │
│ 8. Mediation Analysis                      │     N/A    │     ✅     │    ✅    │    ❌    │ Product of coefficients     │
│ 9. Time-to-Event Equivalence/NI           │     ❌     │     ✅     │    ✅    │    ❌    │ Schoenfeld (equivalence)    │
│ 10. Multiple-Bias Sensitivity Analysis     │     N/A    │     N/A    │    ✅    │    ❌    │ Bias factor quantification  │
└─────────────────────────────────────────────┴────────────┴────────────┴──────────┴──────────┴─────────────────────────────┘
```

---

## Detailed Module Documentation

### 1. Single Proportion Test ✅ COMPLETE

**Status:** Fully implemented with generalized functionality
**Module File:** `R/mod_01_single_proportion.R`

#### Features
- ✅ Power calculation (given sample size, effect size)
- ✅ Sample size calculation (given power, effect size)
- ✅ Minimal detectable effect calculation (given sample size, power)
- ✅ Adjustments: discontinuation, missing data, clustering, multiple testing
- ✅ Dynamic PDF report with context-aware content
- ✅ CSV export with all parameters

#### Statistical Method
- **Primary:** Cohen's arcsine transformation via `pwr.p.test()`
- **Effect Size:** h = 2 * (arcsin(√p₁) - arcsin(√p₀))
- **Use Cases:**
  - Rare event detection (p₀ = 0%)
  - Benchmark comparison (p₀ > 0%)
  - Quality improvement studies
  - Regulatory compliance testing

#### Export Formats
- **CSV:** ✅ Includes expected proportion, reference proportion, power, sample size
- **PDF:** ✅ Dynamic title and content based on p₀ value
  - p₀ = 0: "Single Proportion Analysis: Rare Event Detection"
  - p₀ > 0: "Single Proportion Power Analysis"

#### Recent Updates
- **2025-10-27:** Generalized to support any reference proportion (p₀)
- Changed from "Rule of 3" branding to "Single Proportion Test"
- Added Reference Proportion (%) input parameter
- Changed input format from "1 in x" to percentage for clarity

---

### 2. Two-Group Comparisons ⚠️ EXPORT INCOMPLETE

**Status:** Core functionality complete, PDF export missing
**Module File:** `R/mod_02_two_group.R`

#### Features
- ✅ Power calculation (2-sample proportions)
- ✅ Sample size calculation with allocation ratios
- ✅ Effect measures: Risk Difference, Relative Risk, Odds Ratio
- ✅ One-sided and two-sided tests
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** Cohen's h for two proportions via `pwr.2p2n.test()`
- **Effect Size:** h = 2 * (arcsin(√p₁) - arcsin(√p₂))
- **Use Cases:** RCTs, cohort studies, comparative effectiveness

#### Export Formats
- **CSV:** ✅ Includes both groups, effect measures, power/sample size
- **PDF:** ❌ Not implemented (shows warning notification)

#### Gaps
1. No PDF report template
2. Missing comprehensive results summary document

---

### 3. Survival Analysis (Cox) ⚠️ EXPORT INCOMPLETE

**Status:** Core functionality complete, PDF export missing
**Module File:** `R/mod_03_survival.R`

#### Features
- ✅ Power calculation for Cox regression
- ✅ Sample size calculation
- ✅ Hazard ratio estimation
- ✅ Event rate and exposure proportion adjustments
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** Schoenfeld (1983) method via `powerSurvEpi` package
- **Effect Measure:** Hazard Ratio (HR)
- **Parameters:** Sample size, HR, proportion exposed, overall event rate
- **Use Cases:** Time-to-event outcomes, cohort studies

#### Export Formats
- **CSV:** ✅ Includes HR, sample size, event rate, power
- **PDF:** ❌ Not implemented

#### Gaps
1. No PDF report template for survival analyses
2. Missing Kaplan-Meier curve examples in documentation

---

### 4. Matched Case-Control ⚠️ LIMITED SCOPE

**Status:** Sample size only, no power calculation
**Module File:** `R/mod_04_matched_case_control.R`

#### Features
- ❌ Power calculation (not available in underlying epiR package)
- ✅ Sample size calculation
- ✅ Matching ratio (controls per case)
- ✅ Odds ratio specification
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** McNemar's test via `epiR::epi.sscc()`
- **Effect Measure:** Odds Ratio (OR)
- **Design:** Matched case-control with variable matching ratio
- **Use Cases:** Case-control studies with matching

#### Export Formats
- **CSV:** ✅ Includes OR, matching ratio, required cases/controls
- **PDF:** ❌ Not implemented

#### Gaps
1. No power calculation (limitation of epiR package)
2. No PDF export
3. Could add approximate power calculation using conditional logistic regression

---

### 5. Continuous Outcomes (t-tests) ⚠️ EXPORT INCOMPLETE

**Status:** Core functionality complete, PDF export missing
**Module File:** `R/mod_05_continuous.R`

#### Features
- ✅ Power calculation (two-sample t-tests)
- ✅ Sample size calculation with unequal groups
- ✅ Cohen's d effect size
- ✅ One-sided and two-sided tests
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** t-test via `pwr.t2n.test()` and `pwr.t.test()`
- **Effect Size:** Cohen's d = (μ₁ - μ₂) / σ
- **Use Cases:** Comparing means between two groups
- **Assumptions:** Normality, equal variances (or Welch correction)

#### Export Formats
- **CSV:** ✅ Includes effect size, sample sizes, power
- **PDF:** ❌ Not implemented

#### Gaps
1. No PDF report template
2. Missing guidance on Cohen's d interpretation (small = 0.2, medium = 0.5, large = 0.8)

---

### 6. Non-Inferiority Testing ⚠️ LIMITED SCOPE

**Status:** Sample size only, no power calculation
**Module File:** `R/mod_06_non_inferiority.R`

#### Features
- ❌ Power calculation
- ✅ Sample size calculation
- ✅ Non-inferiority margin specification
- ✅ Allocation ratios
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** Cohen's h with margin adjustment via `pwr.2p.test()`
- **Effect Size:** h = 2 * |arcsin(√p₁) - arcsin(√(p₂ + δ))|
- **Margin (δ):** Maximum clinically acceptable difference
- **Use Cases:** Demonstrating new treatment is "not worse" than standard

#### Export Formats
- **CSV:** ✅ Includes margin, proportions, sample sizes
- **PDF:** ❌ Not implemented

#### Gaps
1. No power calculation for given sample size
2. No PDF export
3. Missing guidance on selecting appropriate non-inferiority margins

---

### 7. Propensity Score VIF Calculator ⚠️ EXPORT INCOMPLETE

**Status:** Interactive calculator with CSV export
**Module File:** `R/mod_07_vif_ps.R`

#### Features
- ✅ VIF calculation for propensity score models
- ✅ Interactive UI with real-time calculations
- ✅ C-statistic estimation (Austin 2021 method)
- ✅ Overlap coefficient calculation (Li et al. 2025 method)
- ✅ CSV export with all parameters
- ❌ PDF export

#### Statistical Method
- **Primary:** Variance Inflation Factor (VIF) calculation
- **Methods:**
  - Austin (2021): VIF based on c-statistic
  - Li et al. (2025): VIF based on overlap coefficient and confounder-outcome R²
- **Purpose:** Assess confounding strength and propensity score quality
- **Metrics:** VIF, adjusted sample size, effective sample size
- **Use Cases:** Observational studies with propensity score adjustment

#### Export Formats
- **CSV:** ✅ Includes calculation method, weighting method, RCT sample size, VIF, adjusted sample size
  - Austin method: C-statistic included
  - Li method: Overlap coefficient and R² included
- **PDF:** ❌ Not implemented

#### Gaps
1. No PDF export
2. Could add scenario comparison table for different weighting methods

---

### 8. Mediation Analysis ⚠️ EXPORT INCOMPLETE

**Status:** Sample size calculation complete, CSV export added
**Module File:** `R/mod_08_mediation.R`

#### Features
- ✅ Power calculation (given sample size)
- ✅ Sample size calculation (given power)
- ✅ Minimal detectable effect calculation (given N and power)
- ✅ Effect size specification for direct and indirect paths
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** Product of coefficients method
- **Paths:** X → M (a), M → Y (b), X → Y (c')
- **Indirect Effect:** ab
- **Use Cases:** Testing mediation hypotheses

#### Export Formats
- **CSV:** ✅ Includes all three calculation modes (power, sample size, MDE)
  - Path coefficients (a, b, c')
  - Indirect effect (a × b)
  - Standard errors (estimated or user-provided)
  - Statistical parameters (α, test type)
- **PDF:** ❌ Not implemented

#### Gaps
1. No PDF export
2. No bootstrapping confidence interval guidance
3. Missing documentation on appropriate effect size magnitudes

---

### 9. Time-to-Event Equivalence/NI ⚠️ EXPORT INCOMPLETE

**Status:** Sample size calculation complete, exports incomplete
**Module File:** `R/mod_09_survival_equivalence.R`

#### Features
- ❌ Power calculation
- ✅ Sample size calculation for non-inferiority
- ✅ Sample size calculation for equivalence
- ✅ Hazard ratio margin specification
- ✅ CSV export
- ❌ PDF export

#### Statistical Method
- **Primary:** Schoenfeld method with equivalence/NI margins
- **Effect Measure:** Hazard Ratio (HR)
- **Margins:**
  - Non-inferiority: Upper bound only
  - Equivalence: Two-sided bounds
- **Use Cases:** Survival equivalence/non-inferiority trials

#### Export Formats
- **CSV:** ✅ Includes margins, HR, required events, sample sizes
- **PDF:** ❌ Not implemented

#### Gaps
1. No power calculation
2. No PDF report template
3. Missing guidance on selecting HR margins

---

### 10. Multiple-Bias Sensitivity Analysis ⚠️ EXPORT PARTIALLY COMPLETE

**Status:** CSV export implemented, PDF pending
**Module File:** `R/mod_10_sensitivity_analyses.R` (wrapper)
**Sub-module:** `R/mod_multi_bias.R`

#### Features
- ✅ Multiple bias factor analysis
- ✅ Joint impact of confounding, selection bias, misclassification
- ✅ Interactive bias parameter specification
- ✅ CSV export (E-value and Bias-adjusted bound)
- ❌ PDF export

#### Statistical Method
- **Primary:** Bias factor quantification
- **Bias Types:**
  - Unmeasured confounding
  - Selection bias
  - Differential misclassification
- **Use Cases:** Report-phase sensitivity analysis
- **Analysis Modes:**
  - E-value: Minimum bias strength to explain away effect
  - Bias-adjusted bound: Effect estimate given specific bias values

#### Export Formats
- **CSV:** ✅ Implemented with support for both analysis types
  - E-value export: Includes observed RR, CI, multi-bias E-value, robustness level
  - Bound export: Includes bias parameters, bias factor, adjusted RR, adjusted CI
- **PDF:** ❌ Not implemented

#### Gaps
1. No PDF export
2. Missing scenario comparison table for multiple scenarios

---

## Export Functionality Summary

### CSV Export Coverage

```
Modules with CSV Export:  10/10 (100%) ✅
Modules without CSV:       0/10  (0%)
```

**✅ CSV Implemented:**
1. Single Proportion
2. Two-Group Comparisons
3. Survival Analysis (Cox)
4. Matched Case-Control
5. Continuous Outcomes
6. Non-Inferiority Testing
7. Propensity Score VIF Calculator
8. Mediation Analysis
9. Time-to-Event Equivalence/NI
10. Multiple-Bias Sensitivity Analysis ⭐ NEW

**❌ CSV Missing:**
None - 100% CSV coverage achieved! 🎉

### PDF Export Coverage

```
Modules with PDF Export:  1/10  (10%)
Modules without PDF:      9/10  (90%)
```

**✅ PDF Implemented:**
1. Single Proportion (fully dynamic, context-aware)

**❌ PDF Missing:**
- All other modules (2-10)

---

## Recommended Priorities for Feature Parity

### Priority 1: CRITICAL (Export Gaps) - ✅ ALL COMPLETED
1. ~~**Add CSV export to VIF Calculator**~~ ✅ COMPLETED (2025-10-27)
2. ~~**Add CSV export to Mediation Analysis**~~ ✅ COMPLETED (2025-10-27)
3. ~~**Add CSV export to Multi-Bias Sensitivity**~~ ✅ COMPLETED (2025-10-27)

### Priority 2: HIGH (PDF Reports for Common Analyses)
4. **Two-Group Comparisons PDF** - Very common analysis type
5. **Survival Analysis PDF** - Complex results benefit from formatted report
6. **Continuous Outcomes PDF** - Widely used, should have full export

### Priority 3: MEDIUM (Power Calculations)
7. **Matched Case-Control Power** - Currently sample size only
8. **Non-Inferiority Power** - Currently sample size only
9. **Time-to-Event Power** - Currently sample size only

### Priority 4: LOW (Enhancement)
10. **PDF reports for remaining modules** (Matched, NI, Mediation, etc.)
11. **Interactive scenario comparison tables** across all modules
12. **Unified export format** with consistent column naming

---

## Technical Debt & Consistency Issues

### Inconsistent Naming Conventions
- Some modules use `power_p` (single proportion)
- Others use `twogrp_pow_p1` (two-group)
- Should standardize input naming across modules

### Export Handler Location
- All exports currently in `R/app_server.R` (lines 3793-4180)
- Consider moving to module-specific export functions
- Would improve maintainability and testability

### PDF Template Architecture
- Only one template exists: `inst/reports/analysis-report.Rmd`
- Should create module-specific templates
- Could use template inheritance for common sections

### Missing Module Documentation
- VIF Calculator has no vignette
- Mediation Analysis has no vignette
- Multi-Bias Sensitivity has no vignette

---

## Testing Coverage Gaps

### Export Testing
- No automated tests for CSV exports
- No tests for PDF generation
- Should add tests verifying:
  - CSV column names match expected format
  - PDF renders without errors
  - All parameters properly passed to exports

### Module Integration Testing
- Test each module's full workflow
- Test export functionality end-to-end
- Test error handling for edge cases

---

## Statistical Methods Reference

| Method | R Package | Function | Used In Modules |
|--------|-----------|----------|-----------------|
| Cohen's h (1-sample) | `pwr` | `pwr.p.test()` | Single Proportion |
| Cohen's h (2-sample) | `pwr` | `pwr.2p2n.test()` | Two-Group, Non-Inferiority |
| Cohen's d | `pwr` | `pwr.t2n.test()`, `pwr.t.test()` | Continuous Outcomes |
| Schoenfeld (survival) | `powerSurvEpi` | `powerEpi.default()`, `ssizeEpi.default()` | Survival Analysis, Time-to-Event |
| McNemar's test | `epiR` | `epi.sscc()` | Matched Case-Control |
| VIF calculation | Custom | N/A | Propensity Score VIF |
| Mediation | Custom | N/A | Mediation Analysis |
| Bias factors | Custom | N/A | Multiple-Bias Sensitivity |

---

## Change Log

### 2025-10-27
- **ADDED:** Features.md documentation
- **COMPLETED:** Single Proportion generalization (now supports any p₀)
- **RENAMED:** "Rule of 3" → "Single Proportion Test"
- **ADDED:** Dynamic PDF reports for Single Proportion module
- **COMPLETED:** CSV export for VIF Calculator module ✅
  - Supports both Austin (2021) and Li et al. (2025) methods
  - Includes all relevant parameters and calculations
- **COMPLETED:** CSV export for Mediation Analysis module ✅
  - Supports all three calculation modes (power, sample size, MDE)
  - Includes path coefficients, indirect effects, and standard errors
- **COMPLETED:** CSV export for Multi-Bias Sensitivity Analysis module ✅
  - Supports both E-value and bias-adjusted bound analyses
  - Includes bias types, observed RR, CI, multi-bias E-value, robustness level
  - Includes bias parameters, bias factor, adjusted estimates for bound analysis
  - **🎉 CSV coverage: 100% (10/10 modules) - ALL PRIORITY 1 ITEMS COMPLETE!**
- **IDENTIFIED:** 9 modules still missing PDF export

---

## Next Steps

1. ~~**Immediate:** Add CSV export to Multi-Bias Sensitivity module~~ ✅ COMPLETED
2. **Priority 2 (HIGH):** Create PDF templates for Two-Group and Survival modules
3. **Priority 3 (MEDIUM):** Add power calculations to modules with sample size only
4. **Sprint 1:** Standardize export formats across all modules
5. **Sprint 2:** Add comprehensive testing for all export functionality

---

**Maintained By:** Development Team
**Review Frequency:** After each module update
**Last Reviewed:** 2025-10-27
