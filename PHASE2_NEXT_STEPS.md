# Phase 2 Migration - Next Steps

**Current Status:** Tab 1 complete, Tab 2 UI migrated, scaffolds exist for Tabs 3-11

## What's Been Accomplished

### ✅ Completed Work

1. **Tab 1 (Single Proportion)** - 100% Complete
   - ✅ UI migrated to `R/mod_01_single_proportion.R`
   - ✅ Server logic integrated via reactive values
   - ✅ Calculations wired up in app_server.R
   - ✅ All functionality tested and working
   - ✅ Commits: a8111b6

2. **Tab 2 (Two-Group)** - UI Complete (80%)
   - ✅ UI migrated to `R/mod_02_two_group.R`
   - ✅ Module returns reactive values
   - ✅ Example/reset buttons functional
   - ⏳ Calculations not yet wired in app_server.R
   - ✅ Commits: c34d515

3. **Documentation**
   - ✅ MIGRATION_STATUS.md created
   - ✅ Pattern established and documented
   - ✅ Commits: 8af3a72

4. **Module Scaffolds** (from earlier Phase 2a)
   - ✅ All 11 module files created
   - ⏳ Tabs 3-11 are empty templates

### 📊 Impact Summary

| Metric | Value |
|--------|-------|
| Tabs fully migrated | 1 of 11 (9%) |
| Tabs with UI migrated | 2 of 11 (18%) |
| App UI reduction | 204 lines (-27%) |
| Module code created | 444 lines |
| Pattern established | ✅ Yes |

## What Remains

### 🔄 In Progress: Fill Module Scaffolds (3-11)

Each module needs UI and server code migrated. Following Tab 1 & 2 pattern:

**Survival Analysis** (Tabs 3-4)
- `mod_04_power_survival.R` - needs UI from lines 267-294 of app_ui.R
- `mod_05_sample_size_survival.R` - needs UI from lines 295-346 of app_ui.R

**Matched Case-Control** (Tab 5)
- `mod_06_matched_case_control.R` - needs UI from lines 347-403 of app_ui.R

**Continuous Outcomes** (Tabs 6-7)
- `mod_07_power_continuous.R` - needs UI from lines 404-433 of app_ui.R
- `mod_08_sample_size_continuous.R` - needs UI from lines 434-483 of app_ui.R

**Non-Inferiority** (Tab 8)
- `mod_09_non_inferiority.R` - needs UI from lines 484-539 of app_ui.R

**VIF Calculator** (Tab 9)
- `mod_10_vif_calculator.R` - needs UI from lines 540-627 of app_ui.R

**Propensity Score** (Tab 10)
- `mod_11_propensity_score.R` - needs UI (if separate from VIF)

### ⚡ Wire Up Calculations

For EACH tab, update `app_server.R`:

1. **Initialize module:**
   ```r
   tabX_vals <- mod_0X_name_server("tabX")
   ```

2. **Update validation function:**
   ```r
   if (input$sidebar_page == "page_id") {
     tabX_inputs <- tabX_vals$inputs()
     validate(
       need(tabX_inputs$param > 0, "...")
     )
   }
   ```

3. **Update preview_inputs reactive:**
   ```r
   if (input$sidebar_page == "page_id") {
     tabX_inputs <- tabX_vals$inputs()
     list(tab = "...", param1 = tabX_inputs$param1, ...)
   }
   ```

4. **Update result_text rendering:**
   ```r
   if (input$sidebar_page == "page_id") {
     tabX_inputs <- tabX_vals$inputs()
     # Use tabX_inputs$... for all calculations
   }
   ```

5. **Update power_plot rendering:**
   ```r
   if (input$sidebar_page == "page_id") {
     tabX_inputs <- tabX_vals$inputs()
     # Use tabX_inputs$... for plot data
   }
   ```

## Step-by-Step Guide

### For Each Remaining Tab:

1. **Extract UI from app_ui.R**
   - Find the conditionalPanel for the tab
   - Copy all UI elements
   - Note the input IDs

2. **Fill Module UI Function**
   - Open `R/mod_0X_name.R`
   - Paste UI into `mod_0X_name_ui()` function
   - Wrap ALL input IDs with `ns()`:
     - `"input_id"` → `ns("input_id")`
     - For nested conditionalPanels: `input['ns("id")']`
   - Include any sub-modules with ns():
     - `missing_data_ui(ns("missing_data"))`

3. **Fill Module Server Function**
   - Add example/reset button handlers
   - Initialize any sub-modules:
     ```r
     missing_data_vals <- missing_data_server("missing_data")
     ```
   - Return reactive values:
     ```r
     list(
       inputs = reactive({ list(input1 = input$input1, ...) }),
       missing_data_vals = missing_data_vals  # if applicable
     )
     ```

4. **Update app_ui.R**
   - Replace conditionalPanel block with:
     ```r
     mod_0X_name_ui("tabX")
     ```

5. **Update run_app.R**
   - Add to source list:
     ```r
     "R/mod_0X_name.R"
     ```

6. **Wire Up in app_server.R**
   - Initialize: `tabX_vals <- mod_0X_name_server("tabX")`
   - Update validation, preview, result_text, power_plot (see above)

7. **Test**
   - Load app
   - Navigate to tab
   - Test all functionality
   - Verify calculations correct

8. **Commit**
   ```bash
   git add R/mod_0X_name.R R/app_ui.R R/app_server.R R/run_app.R
   git commit -m "feat: migrate Tab X (Name) to module"
   ```

## Example: Tab 4 (Survival Power)

```bash
# 1. Fill mod_04_power_survival.R with UI and server code
# 2. Update app_ui.R:
# Replace lines 267-294 with:
mod_04_power_survival_ui("tab4_power")

# 3. Update run_app.R:
"R/mod_04_power_survival.R"

# 4. Update app_server.R:
tab4_power_vals <- mod_04_power_survival_server("tab4_power")

# 5. Wire up calculations (validation, preview, results, plot)
# 6. Test
# 7. Commit
```

## Recommended Order

1. ✅ Tab 1 (Single Proportion) - DONE
2. ✅ Tab 2 (Two-Group) - UI DONE
3. Tab 4 & 5 (Survival) - 2 pages, uses powerSurvEpi
4. Tab 7 & 8 (Continuous) - 2 pages, uses pwr.t.test
5. Tab 6 (Matched Case-Control) - uses epiR
6. Tab 9 (Non-Inferiority) - custom logic
7. Tab 10 (VIF) - custom calculation
8. Tab 11 (Propensity) - custom calculation

## Time Estimates

| Task | Estimate |
|------|----------|
| Fill one module UI | 15-20 min |
| Wire up calculations | 20-30 min |
| Test tab | 10-15 min |
| **Per tab total** | 45-65 min |
| **9 remaining tabs** | 7-10 hours |

## Quality Checklist

For each migrated tab:

- [ ] Module UI uses ns() for all IDs
- [ ] Nested conditionalPanels properly namespaced
- [ ] Example/reset buttons update all inputs
- [ ] Module returns reactive values
- [ ] app_server.R uses module values (not direct inputs)
- [ ] Validation checks sidebar_page
- [ ] Preview uses module values
- [ ] Results calculation uses module values
- [ ] Plot rendering uses module values
- [ ] All functionality tested
- [ ] Committed with descriptive message

## Reference Files

- **Pattern template:** `R/mod_01_single_proportion.R` (complete example)
- **UI template:** `R/mod_02_two_group.R` (UI migration pattern)
- **Integration:** `R/app_server.R` lines 506-814 (Tab 1 integration)
- **Guide:** `docs/002-how-to-guides/010-migrate-existing-tab-to-module.md`

## Potential Issues

1. **Missing ns() wrapper:** Inputs won't work
   - Fix: Wrap with ns("id")

2. **Nested conditionalPanel syntax:** JavaScript needs special syntax
   - Fix: Use `input['${ns("id")}']` not `input$id`

3. **Module not sourced:** Module function not found
   - Fix: Add to run_app.R source list

4. **Direct input access:** `input$id` instead of module values
   - Fix: Use `tabX_vals$inputs()$id`

5. **Missing data module:** Not properly initialized
   - Fix: Call `missing_data_server("missing_data")` in module

---

**Start here:** Pick Tab 4 (Survival Power), follow the guide above, and iterate through remaining tabs!

**Questions?** Refer to completed Tab 1 module as the reference implementation.
