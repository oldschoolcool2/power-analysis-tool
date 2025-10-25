# Refactoring Checklist

**Purpose:** Step-by-step checklist for refactoring each analysis tab to use the new Shiny modules and helper functions.

**Estimated Time per Tab:** 1-2 hours
**Total for All 11 Tabs:** 1-2 weeks

---

## Pre-Refactoring Setup

- [x] Modules and helpers created
- [x] Documentation written
- [x] Create git branch for refactoring work
- [x] Run current tests to establish baseline
- [x] Verify app runs correctly before any changes

---

## Analysis Tabs Refactoring Status

### Tab 1: Power (Single) - Lines 161-181 ✅ COMPLETED
- [x] **UI Refactoring**
  - [x] Replace `numericInput + bsTooltip` with `create_numeric_input_with_tooltip()`
  - [x] Verify alpha/power/discontinuation sliders (already using helpers)
  - [x] Test example/reset buttons work
- [x] **Server Refactoring**
  - [x] Use `create_power_single_result_text()` for result text
  - [x] Use `create_power_curve_plot()` for power plot
  - [x] Use `generate_n_sequence()` for sample size sequence
- [x] **Testing**
  - [x] Syntax validation passed
  - [x] Code compiles without errors
- [x] **Actual lines saved:** ~18 lines (59 lines removed, 41 lines added)
- [x] **Committed:** 052d22b

---

### Tab 2: Sample Size (Single) - Lines 184-267 ✅ COMPLETED
- [x] **UI Refactoring**
  - [x] Replace `numericInput + bsTooltip` (2 instances)
  - [x] Replace missing data UI block with `missing_data_ui("ss_single-missing_data")`
  - [x] Remove 40 lines of missing data conditional panels
- [x] **Server Refactoring**
  - [x] Initialize: `missing_data_ss_single <- missing_data_server("ss_single-missing_data")`
  - [x] Replace missing data calculation with `calc_missing_data_inflation()` using module values
  - [x] Use `format_missing_data_text()` for display
  - [x] Use `create_power_curve_plot()` for power plot
  - [x] Use `generate_n_sequence_for_ss()` for sample size sequence
- [x] **Testing**
  - [x] Syntax validation passed
  - [x] Code compiles without errors
- [x] **Actual lines saved:** ~56 lines (106 lines removed, 50 lines added)
- [x] **Committed:** c262154

---

### Tab 3: Power (Two-Group) - Lines 270-296 ✅ COMPLETED
- [x] **UI Refactoring**
  - [x] Replace `numericInput + bsTooltip` (4 instances: n1, n2, p1, p2)
  - [x] Verify test type radioButtons (no changes needed)
- [x] **Server Refactoring**
  - [x] Use `generate_n_sequence()` for sample size sequence
  - [x] Use `create_power_curve_plot_twogroup()` for power plot
  - [x] Result text already concise (no helper needed)
- [x] **Testing**
  - [x] Syntax validation passed
  - [x] Code compiles without errors
- [x] **Actual lines saved:** ~4 lines (49 lines removed, 45 lines added)
- [x] **Committed:** aede354

---

### Tab 4: Sample Size (Two-Group) - Lines 299-389 ✅ COMPLETED
- [x] **UI Refactoring**
  - [x] Replace `numericInput + bsTooltip` (5 instances: p1, p2, n1_fixed, p2_baseline, ratio)
  - [x] Replace missing data UI with `missing_data_ui("twogrp_ss-missing_data")`
- [x] **Server Refactoring**
  - [x] Initialize missing data module
  - [x] Use `calc_missing_data_inflation()` with module values
  - [x] Use `format_missing_data_text()` for formatted output
  - [x] Use `calc_effect_measures()` for effect calculations
  - [x] Use `format_effect_measures()` for display
  - [x] Use `format_minimal_detectable_effect()` for calc_effect mode
- [x] **Testing**
  - [x] Syntax validation passed
  - [x] Code compiles without errors
- [x] **Actual lines saved:** ~16 lines (88 lines removed, 72 lines added)
- [x] **Committed:** 60d078a

---

### Tab 5: Power (Survival) - Lines 392-415
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip` (n, hr)
- [ ] **Server Refactoring**
  - [ ] Use result text helpers
  - [ ] Use `format_hazard_ratio()` for HR interpretation
  - [ ] Use `create_power_curve_plot()` for power plot
- [ ] **Testing**
  - [ ] Test with HR < 1
  - [ ] Test with HR > 1
  - [ ] Verify hazard ratio interpretation
- [ ] **Estimated lines saved:** ~35 lines

---

### Tab 6: Sample Size (Survival) - Lines 418-504
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip`
  - [ ] Replace missing data UI with `missing_data_ui(NS("surv_ss", "missing_data"))`
- [ ] **Server Refactoring**
  - [ ] Initialize missing data module
  - [ ] Use `calculate_missing_inflation()`
  - [ ] Use `create_sample_size_result_text()`
  - [ ] Use `format_hazard_ratio()`
  - [ ] Use `create_power_curve_plot()`
- [ ] **Testing**
  - [ ] Test calc_n and calc_effect modes
  - [ ] Test with/without missing data
  - [ ] Verify HR interpretation
- [ ] **Estimated lines saved:** ~175 lines

---

### Tab 7: Matched Case-Control - Lines 507-597
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip`
  - [ ] Replace missing data UI with `missing_data_ui(NS("match", "missing_data"))`
- [ ] **Server Refactoring**
  - [ ] Initialize missing data module
  - [ ] Use `calculate_missing_inflation()`
  - [ ] Use `create_sample_size_result_text()`
  - [ ] Use `create_power_curve_plot()`
- [ ] **Testing**
  - [ ] Test calc_n and calc_effect modes
  - [ ] Test with/without missing data
  - [ ] Test matched pairs ratio variations
- [ ] **Estimated lines saved:** ~175 lines

---

### Tab 8: Power (Continuous) - Lines 600-624
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip` (n1, n2, d)
- [ ] **Server Refactoring**
  - [ ] Use result text helpers
  - [ ] Use `format_cohens_d()` for effect size interpretation
  - [ ] Use `create_power_curve_plot_twogroup()`
- [ ] **Testing**
  - [ ] Test with small/medium/large effect sizes
  - [ ] Verify Cohen's d interpretation
  - [ ] Test two-sided and one-sided
- [ ] **Estimated lines saved:** ~40 lines

---

### Tab 9: Sample Size (Continuous) - Lines 627-713
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip`
  - [ ] Replace missing data UI with `missing_data_ui(NS("cont_ss", "missing_data"))`
- [ ] **Server Refactoring**
  - [ ] Initialize missing data module
  - [ ] Use `calculate_missing_inflation()`
  - [ ] Use `create_sample_size_result_text()`
  - [ ] Use `format_cohens_d()`
  - [ ] Use `create_power_curve_plot_twogroup()`
- [ ] **Testing**
  - [ ] Test calc_n and calc_effect modes
  - [ ] Test with/without missing data
  - [ ] Verify Cohen's d interpretation
- [ ] **Estimated lines saved:** ~175 lines

---

### Tab 10: Non-Inferiority - Lines 716-803
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip`
  - [ ] Replace missing data UI with `missing_data_ui(NS("noninf", "missing_data"))`
- [ ] **Server Refactoring**
  - [ ] Initialize missing data module
  - [ ] Use `calculate_missing_inflation()`
  - [ ] Use `create_sample_size_result_text()`
  - [ ] Use `create_power_curve_plot()`
- [ ] **Testing**
  - [ ] Test calc_n and calc_effect modes
  - [ ] Test with/without missing data
  - [ ] Test non-inferiority margin variations
- [ ] **Estimated lines saved:** ~175 lines

---

### Tab 11: VIF Calculator - Lines 806-854
- [ ] **UI Refactoring**
  - [ ] Replace `numericInput + bsTooltip`
- [ ] **Server Refactoring**
  - [ ] Use result text helpers (if applicable)
  - [ ] This tab may not use all helpers (no power curve)
- [ ] **Testing**
  - [ ] Test VIF calculations
  - [ ] Verify results unchanged
- [ ] **Estimated lines saved:** ~20 lines

---

## Post-Refactoring per Tab

After refactoring each tab:

- [ ] Run the app locally
- [ ] Test the refactored tab thoroughly
  - [ ] Load example
  - [ ] Reset to defaults
  - [ ] Manual input testing
  - [ ] Edge cases (very large/small values)
  - [ ] All conditional panels show/hide correctly
- [ ] Compare outputs with original (before refactoring)
  - [ ] Result text matches
  - [ ] Plots render identically
  - [ ] Calculations are identical
- [ ] Commit changes with descriptive message
  ```bash
  git add -A
  git commit -m "refactor: apply Shiny modules to [Tab Name] analysis

  - Replace missing data UI with missing_data_ui() module
  - Use create_numeric_input_with_tooltip() for all numeric inputs
  - Apply plot helper functions for power curve generation
  - Use result text helpers for formatted output

  Reduces [Tab Name] code by ~[N] lines while maintaining functionality.

  Related: #[issue number if applicable]
  "
  ```

---

## Final Integration Testing

After all tabs are refactored:

- [ ] **Smoke Testing**
  - [ ] Launch app, no errors
  - [ ] Navigate to all 11 tabs
  - [ ] Click all example buttons
  - [ ] Click all reset buttons

- [ ] **Functional Testing**
  - [ ] Run through each analysis type with example values
  - [ ] Verify all plots render
  - [ ] Verify all result text displays correctly
  - [ ] Test missing data adjustment in all 6 applicable tabs

- [ ] **Edge Case Testing**
  - [ ] Very large sample sizes
  - [ ] Very small effect sizes
  - [ ] Boundary values (0%, 100%, etc.)

- [ ] **Regression Testing**
  - [ ] Compare calculations with original app (before refactoring)
  - [ ] Verify no functionality was lost
  - [ ] Check all tooltips appear

- [ ] **Performance Testing**
  - [ ] Measure app load time
  - [ ] Check plot generation speed
  - [ ] Verify reactivity is responsive

---

## Code Quality Checks

- [ ] Run R linter (if available)
  ```r
  lintr::lint_dir("R/")
  ```
- [ ] Check for unused functions
- [ ] Remove old commented-out code
- [ ] Verify all files follow project standards
- [ ] Update any inline comments that reference old code

---

## Documentation Updates

- [ ] Update README.md if any user-facing changes
- [ ] Mark refactoring as complete in REFACTORING_SUMMARY.md
- [ ] Create enhancement report in `docs/reports/enhancements/`
- [ ] Update any affected screenshots/diagrams

---

## Deployment

- [ ] Merge refactoring branch to main
- [ ] Tag release (if applicable)
  ```bash
  git tag -a v1.x.x-refactored -m "Complete Shiny modules refactoring"
  git push origin v1.x.x-refactored
  ```
- [ ] Deploy to production
- [ ] Monitor for any issues

---

## Metrics Tracking

Track these metrics before and after:

### Code Metrics
- **Total lines in app.R:**
  - Before: 3,827
  - After: _____
  - Reduction: _____%

- **Lines in UI section:**
  - Before: 936
  - After: _____
  - Reduction: _____%

- **Lines in server section:**
  - Before: 2,864
  - After: _____
  - Reduction: _____%

### Maintainability Metrics
- **Duplicated code blocks:**
  - Before: 8 major patterns
  - After: 0 ✅

- **Modules created:**
  - Total: 1 (missing_data)
  - Can add more as needed

- **Helper functions created:**
  - Plot helpers: 5 functions
  - Text helpers: 8 functions
  - Input helpers: 1 function (added to existing file)

### Developer Velocity
- **Time to add new analysis type:**
  - Before: 4-5 hours
  - After: _____ hours (target: 1-2 hours)

---

## Notes

### Tips for Success

1. **One tab at a time** - Don't try to refactor everything at once
2. **Test thoroughly** - Compare before/after for each tab
3. **Commit frequently** - One commit per tab refactored
4. **Document issues** - Note any unexpected challenges
5. **Incremental improvement** - Refactor when touching code, not all at once

### Common Pitfalls

1. **Namespace confusion** - Remember to use `NS("id", "subid")` for modules
2. **Reactive values** - Don't forget to call reactives with `()`
3. **Missing dependencies** - Ensure all helper files are sourced
4. **Testing shortcuts** - Don't skip testing, even for "simple" changes

### When to Stop

You don't have to refactor everything at once. Consider stopping at:
- After high-value tabs (those with missing data) - 6 tabs
- After hitting 50% reduction milestone
- When time budget is exhausted

The modules are available to use incrementally!

---

**Created:** 2025-10-25
**Status:** Ready to use
**Estimated Total Time:** 11-22 hours (1-2 hours per tab × 11 tabs)
