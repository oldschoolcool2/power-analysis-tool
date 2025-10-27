# How to Migrate an Existing Tab to a Shiny Module

**Type:** How-To Guide
**Audience:** Developers
**Last Updated:** 2025-10-25

## Overview

This guide shows how to incrementally refactor an existing analysis tab from the monolithic app.R into a self-contained Shiny module. This is the bridge between your current structure and the full golem package migration.

**When to use this guide:**
- You want to start refactoring before the full golem migration
- You need to improve a specific tab's maintainability now
- You're learning module patterns on a real example
- You want to test the module approach before committing to full migration

**Prerequisites:**
- Familiar with current app.R structure
- Read [How to use Shiny modules and helper functions](/docs/002-how-to-guides/005-using-shiny-modules-and-helpers.md)
- Understand Shiny reactivity

---

## Table of Contents

1. [Why Migrate to Modules?](#why-migrate-to-modules)
2. [Quick Reference Checklist](#quick-reference-checklist)
3. [Choose a Tab to Refactor](#step-1-choose-a-tab-to-refactor)
4. [Extract UI Code](#step-2-extract-ui-code)
5. [Extract Server Code](#step-3-extract-server-code)
6. [Create the Module File](#step-4-create-the-module-file)
7. [Update app.R](#step-5-update-appr)
8. [Test the Module](#step-6-test-the-module)
9. [Clean Up](#step-7-clean-up)
10. [Real Example: Power (Two-Group)](#real-example-power-two-group)

---

## Why Migrate to Modules?

### Current Problem

Your app.R currently has **4,044 lines**. Finding and editing code for a specific tab requires:
1. Scrolling through thousands of lines
2. Tracking down related code scattered across sections
3. Risk of accidentally breaking other tabs
4. Difficult code reviews
5. Impossible to test in isolation

### After Migration to Modules

Each tab becomes a self-contained ~150-line file:
- **Easy to find**: `R/modules/mod_02_power_two_group.R`
- **Easy to test**: Test just this module
- **Easy to review**: Small, focused pull requests
- **Easy to maintain**: All related code in one place
- **Easy to reuse**: Module can be used in other apps

### Benefits You'll See Immediately

- ✅ Reduce cognitive load (150 lines vs 4000 lines)
- ✅ Faster development (no scrolling)
- ✅ Better git diffs (isolated changes)
- ✅ Easier onboarding (modules are self-documenting)
- ✅ Foundation for golem migration later

---

## Quick Reference Checklist

- [ ] Choose a tab to refactor (start simple!)
- [ ] Create backup branch
- [ ] Extract UI code to module function
- [ ] Extract server code to module function
- [ ] Create module file in `R/modules/`
- [ ] Update app.R to use module
- [ ] Test thoroughly
- [ ] Verify no regressions
- [ ] Commit changes
- [ ] Repeat for next tab!

---

## Step 1: Choose a Tab to Refactor

### Selection Criteria

**Start with the simplest tab first** to learn the pattern.

**Good first choices:**
1. **Tab 1 (Single Proportion)** - Simple, well-understood
2. **Tab 11 (VIF Calculator)** - Recently refactored, uses helpers
3. **Tab 10 (Non-Inferiority)** - Medium complexity

**Avoid for now:**
1. Tabs with complex cross-tab dependencies
2. Tabs with shared state management
3. Your most critical production tab (save for later)

**Example: Let's refactor Tab 2 (Power Two-Group)**

Why this is a good choice:
- Medium complexity (not too simple, not too complex)
- Self-contained (no cross-tab dependencies)
- Uses existing helpers
- Good learning example

---

## Step 2: Extract UI Code

### Locate the UI Code

In app.R, find your tab's UI section. For Tab 2, it's around lines 300-450.

Look for the pattern:
```r
conditionalPanel(
  condition = "input.sidebar_page == 'power_two_group'",
  # ... UI content ...
)
```

### Copy the UI Content

Create a temporary file to work in: `R/modules/mod_02_power_two_group.R`

```r
#' Power (Two-Group) UI
#'
#' @param id Module namespace ID
#'
#' @importFrom shiny NS tagList conditionalPanel h2 helpText hr
mod_02_power_two_group_ui <- function(id) {
  ns <- NS(id)

  tagList(
    # PASTE YOUR UI CONTENT HERE
    # For now, just copy everything inside conditionalPanel
  )
}
```

### Wrap Input IDs with ns()

**Critical step:** All input/output IDs must be wrapped with `ns()`.

**Before (in app.R):**
```r
create_numeric_input_with_tooltip(
  "twogroup_n1",
  "Sample Size Group 1:",
  value = 100,
  ...
)
```

**After (in module):**
```r
create_numeric_input_with_tooltip(
  ns("twogroup_n1"),  # ← Wrapped with ns()!
  "Sample Size Group 1:",
  value = 100,
  ...
)
```

### Update ALL IDs

Go through your UI code and wrap every ID:

**Inputs to wrap:**
- `numericInput(ns("id"), ...)`
- `sliderInput(ns("id"), ...)`
- `actionButton(ns("id"), ...)`
- `radioButtons(ns("id"), ...)`
- All helper functions: `create_numeric_input_with_tooltip(ns("id"), ...)`

**Outputs to wrap:**
- `plotOutput(ns("plot_id"))`
- `verbatimTextOutput(ns("results_id"))`
- `tableOutput(ns("table_id"))`

**Nested modules to wrap:**
- `missing_data_ui(ns("missing_data"))`

### Example: UI Function Complete

```r
#' Power (Two-Group) Analysis - UI
#'
#' @param id Module namespace ID
#'
#' @importFrom shiny NS tagList h2 helpText hr div
mod_02_power_two_group_ui <- function(id) {
  ns <- NS(id)

  tagList(
    h2(class = "page-title", "Power Analysis: Two-Group Comparison"),
    helpText("Calculate statistical power for comparing two proportions"),
    hr(),

    # Sample sizes
    create_numeric_input_with_tooltip(
      ns("twogroup_n1"),
      "Sample Size Group 1:",
      value = 100,
      min = 2,
      step = 10,
      tooltip = "Number of participants in group 1"
    ),

    create_numeric_input_with_tooltip(
      ns("twogroup_n2"),
      "Sample Size Group 2:",
      value = 100,
      min = 2,
      step = 10,
      tooltip = "Number of participants in group 2"
    ),

    # Proportions
    create_enhanced_slider(
      ns("twogroup_p1"),
      "Proportion Group 1 (%):",
      min = 1,
      max = 99,
      value = 30,
      step = 1,
      post = "%",
      tooltip = "Expected proportion in group 1"
    ),

    create_enhanced_slider(
      ns("twogroup_p2"),
      "Proportion Group 2 (%):",
      min = 1,
      max = 99,
      value = 20,
      step = 1,
      post = "%",
      tooltip = "Expected proportion in group 2"
    ),

    # Alpha
    create_segmented_alpha(
      ns("twogroup_alpha"),
      "Significance Level (α):",
      selected = 0.05
    ),

    # Missing data module
    hr(),
    h4("Missing Data Adjustment"),
    missing_data_ui(ns("missing_data")),

    # Action buttons
    hr(),
    div(class = "btn-group-custom",
      actionButton(ns("calculate"), "Calculate",
                   icon = icon("calculator"), class = "btn-primary"),
      actionButton(ns("example"), "Load Example",
                   icon = icon("lightbulb"), class = "btn-info btn-sm"),
      actionButton(ns("reset"), "Reset",
                   icon = icon("refresh"), class = "btn-secondary btn-sm")
    )
  )
}
```

---

## Step 3: Extract Server Code

### Locate the Server Code

In app.R, find your tab's server logic. For Tab 2, it's around lines 1600-1850.

Look for the pattern:
```r
} else if (input$sidebar_page == "power_two_group") {
  # ... server logic ...
}
```

### Create Server Function Template

In your module file:

```r
#' Power (Two-Group) Analysis - Server
#'
#' @param id Module namespace ID
mod_02_power_two_group_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # PASTE YOUR SERVER LOGIC HERE
  })
}
```

### Copy Server Logic

Copy everything inside the `else if` block for your tab.

**Important changes:**
1. **Remove the condition check** - module is already isolated
2. **Don't wrap input/output IDs** - modules handle this automatically
3. **Initialize nested modules** at the top

### Handle Input References

**Before (in app.R):**
```r
n1 <- input$twogroup_n1
n2 <- input$twogroup_n2
```

**After (in module):**
```r
# Same! No changes needed
n1 <- input$twogroup_n1
n2 <- input$twogroup_n2
```

The module's `input` object is already namespaced, so you access inputs normally.

### Initialize Nested Modules

If your tab uses the missing data module:

**Add at the top of moduleServer:**
```r
moduleServer(id, function(input, output, session) {
  ns <- session$ns

  # Initialize missing data module
  missing_data_vals <- missing_data_server("missing_data")

  # ... rest of server logic ...
})
```

### Example: Server Function Complete

```r
#' Power (Two-Group) Analysis - Server
#'
#' @param id Module namespace ID
mod_02_power_two_group_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

    # Initialize missing data module
    missing_data_vals <- missing_data_server("missing_data")

    # Example button
    observeEvent(input$example, {
      updateNumericInput(session, "twogroup_n1", value = 150)
      updateNumericInput(session, "twogroup_n2", value = 150)
      updateSliderInput(session, "twogroup_p1", value = 35)
      updateSliderInput(session, "twogroup_p2", value = 25)
    })

    # Reset button
    observeEvent(input$reset, {
      updateNumericInput(session, "twogroup_n1", value = 100)
      updateNumericInput(session, "twogroup_n2", value = 100)
      updateSliderInput(session, "twogroup_p1", value = 30)
      updateSliderInput(session, "twogroup_p2", value = 20)
    })

    # Calculate button
    observeEvent(input$calculate, {
      # Get inputs
      n1 <- input$twogroup_n1
      n2 <- input$twogroup_n2
      p1 <- input$twogroup_p1 / 100
      p2 <- input$twogroup_p2 / 100
      alpha <- input$twogroup_alpha
      md_vals <- missing_data_vals()

      # Validation
      req(n1, n2, p1, p2, alpha)

      # Adjust for missing data
      if (md_vals$adjust_missing) {
        p_missing <- md_vals$missing_pct / 100
        n1_eff <- ceiling(n1 * (1 - p_missing))
        n2_eff <- ceiling(n2 * (1 - p_missing))
      } else {
        n1_eff <- n1
        n2_eff <- n2
      }

      # Calculate power (using existing helper or pwr package)
      power_result <- pwr::pwr.2p.test(
        h = ES.h(p1, p2),
        n = min(n1_eff, n2_eff),
        sig.level = alpha
      )$power

      # Generate output
      output$results <- renderText({
        create_two_group_power_result_text(
          n1 = n1,
          n2 = n2,
          n1_eff = n1_eff,
          n2_eff = n2_eff,
          p1 = p1,
          p2 = p2,
          power = power_result,
          alpha = alpha,
          md_vals = md_vals
        )
      })

      output$power_curve <- renderPlot({
        # Generate N sequence
        n_seq <- generate_n_sequence(min(n1, n2))

        # Calculate power for each N
        power_vals <- vapply(n_seq, function(n) {
          pwr::pwr.2p.test(
            h = ES.h(p1, p2),
            n = n,
            sig.level = alpha
          )$power
        }, FUN.VALUE = numeric(1))

        # Create plot
        create_power_curve_plot(
          n_seq = n_seq,
          power_vals = power_vals,
          n_current = min(n1, n2),
          target_power = 0.8,
          plot_title = "Power Curve: Two-Group Comparison",
          xaxis_title = "Sample Size per Group",
          n_reference_label = paste0("Current N = ", min(n1, n2))
        )
      })
    })
  })
}
```

---

## Step 4: Create the Module File

### File Structure

Your complete module file should look like:

```r
# R/modules/mod_02_power_two_group.R

#' Power (Two-Group) Analysis - UI
#'
#' @description UI for two-group proportion comparison power analysis
#'
#' @param id Module namespace ID
#'
#' @importFrom shiny NS tagList h2 helpText hr div
#' @importFrom shiny actionButton observeEvent updateNumericInput updateSliderInput
#' @importFrom shiny renderText renderPlot req
#'
#' @noRd
mod_02_power_two_group_ui <- function(id) {
  # ... UI code from Step 2 ...
}

#' Power (Two-Group) Analysis - Server
#'
#' @description Server logic for two-group proportion comparison
#'
#' @param id Module namespace ID
#'
#' @noRd
mod_02_power_two_group_server <- function(id) {
  # ... Server code from Step 3 ...
}
```

### Save the File

Save as `R/modules/mod_02_power_two_group.R`

**Naming convention:**
- `mod_` prefix (module)
- `##_` number (maintains order)
- `description` (what it does)

---

## Step 5: Update app.R

### Source the Module

At the top of app.R where other sources are:

```r
# Source Shiny modules
source("R/modules/001-missing-data-module.R")
source("R/modules/mod_02_power_two_group.R")  # ← Add this
```

### Replace UI in app.R

**Find the old UI section** (around lines 300-450):

```r
# BEFORE: Delete this entire block
conditionalPanel(
  condition = "input.sidebar_page == 'power_two_group'",
  h2(class = "page-title", "Power Analysis: Two-Group Comparison"),
  # ... 150 lines of UI code ...
)
```

**Replace with module call:**

```r
# AFTER: Just this one line!
conditionalPanel(
  condition = "input.sidebar_page == 'power_two_group'",
  mod_02_power_two_group_ui("power_two_group")
)
```

### Replace Server in app.R

**Find the old server section** (around lines 1600-1850):

```r
# BEFORE: Delete this entire block
} else if (input$sidebar_page == "power_two_group") {
  # Get inputs
  n1 <- input$twogroup_n1
  # ... 250 lines of server logic ...
}
```

**Replace with module call:**

```r
# AFTER: Just this one line!
mod_02_power_two_group_server("power_two_group")
```

**Important:** Call the module server at the **top level** of your server function, not inside reactive contexts:

```r
server <- function(input, output, session) {

  # Call modules at the top
  mod_02_power_two_group_server("power_two_group")

  # ... other server logic ...
}
```

### Verify ID Consistency

The ID must match in three places:

1. **Sidebar condition:** `input.sidebar_page == 'power_two_group'`
2. **Module UI call:** `mod_02_power_two_group_ui("power_two_group")`
3. **Module server call:** `mod_02_power_two_group_server("power_two_group")`

---

## Step 6: Test the Module

### Testing Checklist

- [ ] **App loads without errors**
  ```r
  source("app.R")
  # Check console for errors
  ```

- [ ] **Navigate to your tab**
  - Does UI render correctly?
  - All inputs visible?
  - No missing elements?

- [ ] **Test all inputs**
  - [ ] Numeric inputs work
  - [ ] Sliders work
  - [ ] Buttons respond
  - [ ] Missing data module works

- [ ] **Test calculations**
  - [ ] Click "Calculate" - does it work?
  - [ ] Results text displays?
  - [ ] Plot renders?
  - [ ] Values are correct?

- [ ] **Test example/reset buttons**
  - [ ] "Load Example" populates values
  - [ ] "Reset" returns to defaults

- [ ] **Test edge cases**
  - [ ] Very small N
  - [ ] Very large N
  - [ ] Extreme proportions
  - [ ] Invalid inputs (should show errors)

- [ ] **Test other tabs**
  - [ ] Navigate to other tabs
  - [ ] Verify they still work
  - [ ] No interference from your changes

### Common Issues and Fixes

#### Issue: "Object not found" error

**Cause:** Forgot to wrap ID with `ns()` in UI

**Fix:**
```r
# Wrong:
numericInput("my_input", ...)

# Correct:
numericInput(ns("my_input"), ...)
```

#### Issue: Inputs don't update with example/reset

**Cause:** Didn't pass `session` to `updateXxxInput()`

**Fix:**
```r
# Wrong:
updateNumericInput("my_input", value = 100)

# Correct:
updateNumericInput(session, "my_input", value = 100)
```

#### Issue: Missing data module doesn't work

**Cause:** Incorrect namespace

**Fix:**
```r
# UI:
missing_data_ui(ns("missing_data"))  # ← needs ns()

# Server:
missing_data_vals <- missing_data_server("missing_data")  # ← NO ns()
```

#### Issue: Plot/results don't update

**Cause:** Missing `req()` for inputs

**Fix:**
```r
observeEvent(input$calculate, {
  n1 <- input$twogroup_n1
  n2 <- input$twogroup_n2

  req(n1, n2)  # ← Add this!

  # ... calculations ...
})
```

---

## Step 7: Clean Up

### Remove Old Code

Once testing is successful:

1. **Delete the old UI block** from app.R (300-450 lines gone!)
2. **Delete the old server block** from app.R (250 lines gone!)
3. **Verify you kept the module calls** (should be 1 line UI, 1 line server)

### Check Line Count

```bash
wc -l app.R
```

**Before:** 4044 lines
**After:** ~3650 lines (reduced by ~400 lines!)

### Update Comments

In app.R, update section comments:

```r
# ==============================================================================
# UI: TAB 2 - POWER (TWO-GROUP) [MODULARIZED]
# ==============================================================================
conditionalPanel(
  condition = "input.sidebar_page == 'power_two_group'",
  mod_02_power_two_group_ui("power_two_group")
)
```

### Commit Your Changes

```bash
git add R/modules/mod_02_power_two_group.R
git add app.R
git commit -m "refactor(tab2): extract Power (Two-Group) into Shiny module

Extract Tab 2 (Power Two-Group) from monolithic app.R into self-contained module.

Benefits:
- Reduced app.R by ~400 lines (4044 → 3650)
- Improved maintainability (all Tab 2 code in one ~150-line file)
- Easier testing and debugging
- Foundation for future module migrations

Files:
- R/modules/mod_02_power_two_group.R (new, 178 lines)
- app.R (reduced by ~400 lines)

Testing:
- All Tab 2 functionality verified
- No regressions in other tabs
- Example/reset buttons work
- Missing data module integration works

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Real Example: Power (Two-Group)

Let me show you the actual before/after for Tab 2.

### Before: In app.R (Lines 300-450 for UI)

```r
conditionalPanel(
  condition = "input.sidebar_page == 'power_two_group'",
  h2(class = "page-title", "Power Analysis: Two-Group Comparison"),
  helpText("Calculate statistical power for comparing two proportions"),
  hr(),

  create_numeric_input_with_tooltip(
    "twogroup_n1",
    "Sample Size Group 1:",
    value = 100,
    min = 2,
    step = 10,
    tooltip = "Number of participants in group 1"
  ),

  create_numeric_input_with_tooltip(
    "twogroup_n2",
    "Sample Size Group 2:",
    value = 100,
    min = 2,
    step = 10,
    tooltip = "Number of participants in group 2"
  ),

  # ... 120 more lines ...
)
```

### Before: In app.R (Lines 1600-1850 for Server)

```r
} else if (input$sidebar_page == "power_two_group") {
  # Get inputs
  n1 <- input$twogroup_n1
  n2 <- input$twogroup_n2
  p1 <- input$twogroup_p1 / 100
  p2 <- input$twogroup_p2 / 100
  alpha <- input$twogroup_alpha
  md_vals <- missing_data_power_two_group()

  # Adjust for missing data
  if (md_vals$adjust_missing) {
    p_missing <- md_vals$missing_pct / 100
    n1_effective <- ceiling(n1 * (1 - p_missing))
    n2_effective <- ceiling(n2 * (1 - p_missing))
  } else {
    n1_effective <- n1
    n2_effective <- n2
  }

  # Calculate power
  power_result <- pwr::pwr.2p.test(
    h = ES.h(p1, p2),
    n = min(n1_effective, n2_effective),
    sig.level = alpha
  )$power

  # ... 200 more lines of result formatting and plotting ...
}
```

### After: In app.R (Lines 300-305 for UI)

```r
conditionalPanel(
  condition = "input.sidebar_page == 'power_two_group'",
  mod_02_power_two_group_ui("power_two_group")
)
```

### After: In app.R (Lines 1550-1552 for Server)

```r
# Initialize Power (Two-Group) module
mod_02_power_two_group_server("power_two_group")
```

### After: New File R/modules/mod_02_power_two_group.R

```r
# Complete module in one 178-line file
# All UI code
# All server code
# Self-contained and testable
```

### Impact

**Before:**
- UI: 150 lines scattered in app.R
- Server: 250 lines scattered in app.R
- Total: 400 lines mixed with other tabs
- Hard to find, hard to edit, hard to test

**After:**
- UI: 1 line in app.R (calls module)
- Server: 1 line in app.R (calls module)
- Module: 178 lines in dedicated file
- Easy to find, easy to edit, easy to test

**Savings:** 400 lines removed from app.R!

---

## Rinse and Repeat

Once you've successfully migrated one tab, repeat for the others:

### Suggested Order

1. ✅ **Tab 11 (VIF Calculator)** - Already complete
2. ✅ **Tab 2 (Power Two-Group)** - You just did this!
3. **Tab 3 (Sample Size Two-Group)** - Similar to Tab 2
4. **Tab 1 (Single Proportion)** - Simple, good practice
5. **Tab 4 (Power Survival)** - Medium complexity
6. **Tab 5 (Sample Size Survival)** - Similar to Tab 4
7. **Tab 7 (Power Continuous)** - Medium complexity
8. **Tab 8 (Sample Size Continuous)** - Similar to Tab 7
9. **Tab 6 (Matched Case-Control)** - More complex
10. **Tab 9 (Non-Inferiority)** - More complex
11. **Tab 10 (Propensity Score)** - Most complex

### Progress Tracking

After each tab migration, track your progress:

```bash
# Check line count reduction
wc -l app.R

# Expected progression:
# Start:  4044 lines
# Tab 2:  3650 lines (-400)
# Tab 3:  3250 lines (-400)
# Tab 1:  2900 lines (-350)
# ...
# End:    ~500 lines (UI calls + server calls + shared logic)
```

### Celebrate Milestones!

- 🎉 **After 3 tabs:** You've reduced app.R by ~1000 lines
- 🎉 **After 6 tabs:** You've cut app.R in half
- 🎉 **After 11 tabs:** You've reduced app.R by 85%+

---

## Tips for Success

### 1. **Test After Each Tab**

Don't migrate multiple tabs at once. Test thoroughly after each one.

### 2. **Commit After Each Tab**

Small, focused commits are easier to review and roll back if needed.

### 3. **Keep app.R Working**

The app should run successfully after every commit. Don't break production!

### 4. **Use Consistent IDs**

Module ID should match the sidebar value for clarity:
- Sidebar: `"power_two_group"`
- Module UI: `mod_02_power_two_group_ui("power_two_group")`
- Module Server: `mod_02_power_two_group_server("power_two_group")`

### 5. **Document as You Go**

Add comments to module files explaining the analysis type and any quirks.

### 6. **Create Helper Functions**

If you notice repeated code across modules, extract to `R/helpers/`.

### 7. **Ask for Code Reviews**

Have someone review each module before moving to the next.

---

## Troubleshooting

### Module doesn't appear

**Check:**
1. Did you source the module file in app.R?
2. Did you call `mod_XX_ui()` in the UI section?
3. Did you call `mod_XX_server()` in the server function?
4. Are the IDs consistent?

### Inputs don't work

**Check:**
1. Did you wrap all input IDs with `ns()` in the UI?
2. Are you accessing inputs correctly in server (no `ns()` needed)?

### Missing data module doesn't work

**Check:**
1. UI: `missing_data_ui(ns("missing_data"))`
2. Server: `missing_data_vals <- missing_data_server("missing_data")`
3. Usage: `md_vals <- missing_data_vals()` (call as function!)

### Example/reset buttons don't work

**Check:**
1. Did you pass `session` to `updateXxxInput()`?
2. Are you using the correct input IDs (without `ns()` in server)?

---

## Next Steps

After migrating all tabs to modules:

1. **Consider the golem migration** - You're 80% there!
   - See [How to reorganize as an R package with golem](/docs/002-how-to-guides/009-reorganize-as-r-package-with-golem.md)

2. **Extract business logic** - Move calculations to `R/helpers/`
   - Pure functions for power calculations
   - Result text generators
   - Plot creation functions

3. **Add comprehensive tests** - Now that code is modular, test it!
   - See [How to test Shiny modules](/docs/002-how-to-guides/011-testing-shiny-modules.md)

4. **Optimize performance** - Profile and improve
   - Identify slow reactive chains
   - Add caching where appropriate
   - Debounce expensive calculations

---

## Related Documentation

- [How to use Shiny modules and helper functions](/docs/002-how-to-guides/005-using-shiny-modules-and-helpers.md)
- [How to reorganize as an R package with golem](/docs/002-how-to-guides/009-reorganize-as-r-package-with-golem.md)
- [How to add a new analysis type](/docs/002-how-to-guides/008-add-new-analysis-type.md)

## External Resources

- [Shiny Modules](https://shiny.posit.co/r/articles/improve/modules/)
- [Mastering Shiny - Modules](https://mastering-shiny.org/scaling-modules.html)
- [Engineering Production-Grade Shiny Apps](https://engineering-shiny.org/)

---

**Last Updated:** 2025-10-25
**Maintained By:** Development Team
**Status:** Active - use this guide for incremental refactoring before golem migration
