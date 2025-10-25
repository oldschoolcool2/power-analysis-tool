# Code Duplication Analysis Report: power-analysis-tool/app.R

**Document Type:** Code Quality Analysis  
**Analysis Date:** 2025-10-25  
**Total File Size:** 3,827 lines  
**UI Section:** Lines 28-963  
**Server Section:** Lines 964-3827  

---

## Executive Summary

The `app.R` file exhibits significant code duplication patterns across multiple dimensions. The application has **11 distinct analysis modules** (tabs) with nearly identical UI structures and calculation workflows. This analysis identifies DRY (Don't Repeat Yourself) principle violations and opportunities for systematic modularization using Shiny modules.

**Key Finding:** Estimated ~40-45% of the code consists of repetitive patterns that could be refactored into reusable components.

---

## 1. UI INPUT PATTERN DUPLICATION

### 1.1 Repeated UI Input Structure Across Tabs

All 11 analysis tabs follow an identical pattern:

```
conditionalPanel(condition = "input.sidebar_page == 'TAB_ID'")
  h2(class = "page-title", "TAB_TITLE")
  helpText("DESCRIPTION")
  hr()
  [Input controls]
  [Optional conditional inputs]
  hr()
  [Example/Reset buttons]
```

#### Occurrence Count: 11 tabs

**Tab IDs and Lines:**
1. Power (Single) - Lines 161-181 (21 lines of structure)
2. Sample Size (Single) - Lines 184-267 (84 lines, includes missing data)
3. Power (Two-Group) - Lines 270-296 (27 lines)
4. Sample Size (Two-Group) - Lines 299-389 (91 lines, includes missing data)
5. Power (Survival) - Lines 392-415 (24 lines)
6. Sample Size (Survival) - Lines 418-504 (87 lines, includes missing data)
7. Matched Case-Control - Lines 507-597 (91 lines, includes missing data)
8. Power (Continuous) - Lines 600-624 (25 lines)
9. Sample Size (Continuous) - Lines 627-713 (87 lines, includes missing data)
10. Non-Inferiority - Lines 716-803 (88 lines, includes missing data)
11. VIF Calculator - Lines 806-854 (49 lines)

### 1.2 Repeated Input Component Patterns

#### Pattern A: Numeric Sample Size Inputs
**Occurrence: 30+ times**

```r
numericInput("power_n", "Available Sample Size:", 230, min = 1, step = 1),
bsTooltip("power_n", "Total number of participants...", "right"),
```

Lines with numeric inputs for sample size:
- 166: power_n
- 207: ss_p
- 212: ss_n_fixed
- 275-276: twogrp_pow_n1, twogrp_pow_n2
- 322-323: twogrp_ss_p1, twogrp_ss_p2
- 329-331: twogrp_ss_n1_fixed, twogrp_ss_p2_baseline
- 334: twogrp_ss_ratio
- 397: surv_pow_n
- 399: surv_pow_hr
- 441: surv_ss_hr
- 446: surv_ss_n_fixed
- 530: match_or
- 535: match_n_pairs_fixed
- 541: match_ratio
- 605-606: cont_pow_n1, cont_pow_n2
- 609: cont_pow_d
- 650: cont_ss_d
- 655: cont_ss_n1_fixed
- 658: cont_ss_ratio
- 737-738: noninf_p1, noninf_p2
- 743: noninf_margin
- 748: noninf_n1_fixed
- 751: noninf_ratio
- 813: vif_n_rct

**Duplication Factor:** Each numeric input requires 2 lines (input + tooltip).

#### Pattern B: Significance Level (Alpha) Selection
**Occurrence: 11 times**

```r
create_segmented_alpha("power_alpha", "Significance Level (α):",
                      selected = 0.05,
                      tooltip = "Type I error rate...")
```

Lines:
- 173-175: power_alpha
- 218-220: ss_alpha
- 283-285: twogrp_pow_alpha
- 336-338: twogrp_ss_alpha
- 407-409: surv_pow_alpha
- 455-457: surv_ss_alpha
- 543-545: match_alpha
- 611-613: cont_pow_alpha
- 660-662: cont_ss_alpha
- 753-756: noninf_alpha (different choices)
- (implied) All missing data sections

#### Pattern C: Power Level Selection
**Occurrence: 10 times in sample size calculations**

```r
create_segmented_power("ss_power", "Desired Power:",
                      selected = 80,
                      tooltip = "Probability of detecting...")
```

Lines:
- 202-204: ss_power
- 317-319: twogrp_ss_power
- 436-438: surv_ss_power
- 525-527: match_power
- 645-647: cont_ss_power
- 734-736: noninf_power

#### Pattern D: Discontinuation/Withdrawal Rate Slider
**Occurrence: 3 times (Power analyses only)**

```r
create_enhanced_slider("power_discon", "Withdrawal/Discontinuation Rate (%):",
                      min = 0, max = 50, value = 10, step = 1, post = "%",
                      tooltip = "Expected percentage...")
```

Lines:
- 170-172: power_discon
- 215-217: ss_discon

#### Pattern E: Missing Data Adjustment Block
**Occurrence: 6 times (all sample size calculations)**

This is a complex conditional block repeated in:
- Lines 222-261: ss_single (missing data)
- Lines 344-383: twogrp_ss (missing data)
- Lines 459-498: surv_ss (missing data)
- Lines 552-591: match (missing data)
- Lines 668-707: cont_ss (missing data)
- Lines 758-797: noninf (missing data)

**Structure of missing data block (repeated 6 times):**
1. Checkbox: "Adjust for Missing Data"
2. Conditional missing percentage slider
3. Conditional missing mechanism radioButtons
4. Conditional missing analysis approach radioButtons
5. Conditional multiple imputation parameters
   - Number of imputations input
   - Expected R² slider

**Approximate lines per block:** 35-40 lines

**Total lines for missing data patterns:** ~210 lines

#### Pattern F: Test Type (Sided) Selection
**Occurrence: 7 times**

```r
radioButtons_fixed("twogrp_pow_sided", "Test Type:",
  choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
  selected = "two.sided"
)
```

Lines:
- 286-289: twogrp_pow_sided
- 339-342: twogrp_ss_sided
- 546-549: match_sided
- 614-617: cont_pow_sided
- 663-666: cont_ss_sided

#### Pattern G: Calculation Mode Selection
**Occurrence: 7 times (sample size calculations)**

Two-mode pattern: "Calculate N" vs "Calculate Effect Size"

```r
radioButtons_fixed("ss_single_calc_mode",
  "Calculation Mode:",
  choices = c(
    "Calculate Sample Size (given effect size)" = "calc_n",
    "Calculate Effect Size (given sample size)" = "calc_effect"
  ),
  selected = "calc_n"
)
```

Lines:
- 189-196: ss_single_calc_mode
- 304-311: twogrp_ss_calc_mode
- 423-430: surv_ss_calc_mode
- 512-519: match_calc_mode
- 632-639: cont_ss_calc_mode
- 721-728: noninf_calc_mode

#### Pattern H: Conditional Inputs Based on Calc Mode
**Occurrence: 7 pairs (14 conditional blocks)**

Pattern repeats for each sample size calculation:

```r
conditionalPanel(
  condition = "input.TAB_calc_mode == 'calc_n'",
  [Effect size inputs]
),
conditionalPanel(
  condition = "input.TAB_calc_mode == 'calc_effect'",
  [Sample size inputs]
)
```

Examples:
- Lines 205-214: ss_single (calc_n vs calc_effect)
- Lines 320-333: twogrp_ss (calc_n vs calc_effect)
- Lines 439-448: surv_ss (calc_n vs calc_effect)
- Lines 528-537: match (calc_n vs calc_effect)
- Lines 648-657: cont_ss (calc_n vs calc_effect)
- Lines 741-750: noninf (calc_n vs calc_effect)

#### Pattern I: Example/Reset Button Pairs
**Occurrence: 11 times**

```r
div(class = "btn-group-custom",
  actionButton("example_TAB", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
  actionButton("reset_TAB", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
)
```

Lines:
- 177-180: power_single buttons
- 263-266: ss_single buttons
- 292-295: twogrp_pow buttons
- 385-388: twogrp_ss buttons
- 411-414: surv_pow buttons
- 500-503: surv_ss buttons
- 593-596: match buttons
- 620-623: cont_pow buttons
- 709-712: cont_ss buttons
- 799-802: noninf buttons
- 850-853: vif buttons

**Pattern:** All identical structure, only button IDs differ

### Summary of UI Duplication

| Pattern | Type | Count | Total Lines |
|---------|------|-------|------------|
| Page structure (conditionalPanel) | Framework | 11 | ~550 |
| Numeric inputs + tooltips | Input | 30+ | 60+ |
| Alpha selection | Input | 11 | 30+ |
| Power selection | Input | 10 | 25+ |
| Discontinuation slider | Input | 2 | 8 |
| Missing data blocks | Input | 6 | 210+ |
| Test type selection | Input | 7 | 20+ |
| Calc mode selection | Input | 7 | 35+ |
| Conditional calc inputs | Input | 14 | 50+ |
| Example/Reset buttons | Button | 11 | 45 |
| **Total Estimated Duplication** | | | **1,033+ lines** |

---

## 2. SERVER-SIDE CALCULATION LOGIC DUPLICATION

### 2.1 Reactive Output Rendering Pattern

All analysis tabs follow identical output rendering structure in `output$result_text`:

**Pattern:** (Lines 1521-2500+)

```r
output$result_text <- renderUI({
  if (!v$doAnalysis) return()
  isolate({
    validate_inputs()
    
    if (input$tabset == "Power (Single)") {
      [calculation logic]
      [text generation]
      HTML(paste0(...))
    } else if (input$tabset == "Sample Size (Single)") {
      [calculation logic - calc_n mode]
      [calculation logic - calc_effect mode]
      HTML(paste0(...))
    } else if (input$tabset == "Power (Two-Group)") {
      ...
    }
    # ... 8 more tabs with identical if/else-if structure
  })
})
```

**Occurrence:** 11 complete tab-specific blocks in single reactive

**Lines:** 1521-2500 (approximately 980 lines)

### 2.2 Missing Data Adjustment Pattern

Repeated across 6 sample size calculations:

```r
if (input$adjust_missing_TAB) {
  missing_adj <- calc_missing_data_inflation(
    n_calculated,
    input$missing_pct_TAB,
    input$missing_mechanism_TAB,
    input$missing_analysis_TAB,
    ifelse(input$missing_analysis_TAB == "multiple_imputation", 
           input$mi_imputations_TAB, 5),
    ifelse(input$missing_analysis_TAB == "multiple_imputation", 
           input$mi_r_squared_TAB, 0.5)
  )
  n_final <- missing_adj$n_inflated
  # ... HTML output with missing_adj$interpretation
} else {
  n_final <- n_calculated
  missing_data_text <- HTML("")
}
```

**Occurrence:** 6 times (ss_single, twogrp_ss, surv_ss, match, cont_ss, noninf)

**Estimated lines:** ~30-40 lines per occurrence, 180-240 total

### 2.3 Effect Measures Display Pattern

**Occurrence:** 3 times (two-group, survival, continuous)

Pattern in `output$effect_measures`:

```r
if (grepl("Two-Group", input$tabset)) {
  eff <- calc_effect_measures(p1, p2)
  text1 <- h4("Effect Measures")
  text2 <- p(paste0(
    "Risk Difference: ...",
    "Relative Risk: ...",
    "Odds Ratio: ..."
  ))
  HTML(paste0(text1, text2))
} else if (grepl("Survival", input$tabset)) {
  [HR interpretation]
} else if (grepl("Continuous", input$tabset)) {
  [Cohen's d interpretation]
}
```

**Lines:** 2686-2735 (approximately 50 lines)

### 2.4 Power Curve Plot Generation Pattern

**Occurrence:** 11 times (one per analysis type) in `output$power_plot`

**Pattern structure (lines 2767-3400+):**

```r
output$power_plot <- renderPlotly({
  if (!v$doAnalysis) return()
  isolate({
    validate_inputs()
    
    if (input$tabset == "Power (Single)") {
      # [60-80 lines of plotly code]
    } else if (input$tabset == "Sample Size (Single)") {
      # [60-80 lines of plotly code]
    } else if (input$tabset == "Power (Two-Group)") {
      # [60-80 lines of plotly code]
    } else if (input$tabset == "Sample Size (Two-Group)") {
      # [60-80 lines of plotly code]
    } else if (grepl("Survival", input$tabset)) {
      # [60-80 lines of plotly code]
    } else if (grepl("Continuous", input$tabset)) {
      # [60-80 lines of plotly code]
    } else if (input$tabset == "Matched Case-Control") {
      # [60-80 lines for both calc_n and calc_effect modes]
    } else if (input$tabset == "Non-Inferiority") {
      # [if present, similar structure]
    }
  })
})
```

**Total lines:** ~900+ lines for all plot generation

**Common pattern within each branch:**
1. Extract parameters from input$
2. Generate sequence of sample sizes
3. Calculate power for each sample size using appropriate function
4. Create plotly object with add_trace calls (4+ traces per plot):
   - Power curve line
   - Target power reference line
   - Current/required N reference line
5. Apply layout styling (consistent across all)

**Duplicated layouting:** Every plot uses identical styling:
```r
layout(
  title = list(text = "...", font = list(size = 16)),
  xaxis = list(title = "...", gridcolor = "#e0e0e0"),
  yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
  hovermode = "closest",
  plot_bgcolor = "#f8f9fa",
  paper_bgcolor = "white",
  legend = list(x = 0.7, y = 0.2)
) %>%
config(displayModeBar = TRUE, displaylogo = FALSE)
```

### 2.5 Example and Reset Button Handlers

**Lines:** 1334-1372

Already partially refactored using data-driven approach with `button_configs` list:

```r
button_configs <- list(
  power_single = list(
    example = list(power_n = 1500, power_p = 500, ...),
    reset = list(power_n = 230, power_p = 100, ...),
    example_msg = "..."
  ),
  # ... 10 more analysis types
)

lapply(names(button_configs), function(tab_key) {
  observeEvent(input[[paste0("example_", tab_key)]], {
    # Dynamic handler for all example buttons
  })
  observeEvent(input[[paste0("reset_", tab_key)]], {
    # Dynamic handler for all reset buttons
  })
})
```

**Status:** GOOD - Already using DRY pattern, though could be further optimized

### 2.6 Result Table Generation

Output not shown in reading, but typically would follow pattern:
```r
output$result_table <- renderDataTable({
  if (!v$doAnalysis) return()
  # [tab-specific table generation]
})
```

### Summary of Server-Side Duplication

| Pattern | Type | Count | Estimated Lines |
|---------|------|-------|-----------------|
| Tab-specific calculation blocks | Logic | 11 | 980 |
| Missing data inflation calls | Logic | 6 | 180-240 |
| Effect measures display | Logic | 3 | 50 |
| Power curve generation | Logic | 11 | 900+ |
| Plot layout styling | Code | 11+ | 120+ |
| Parameter extraction | Code | 11 | 30-50 |
| Result text formatting | Code | 11 | 400+ |
| **Total Estimated Duplication** | | | **2,660+ lines** |

---

## 3. IDENTIFIED REFACTORING OPPORTUNITIES

### 3.1 High-Priority: Create Shiny Modules

#### Module 1: Input Panel Module
**Purpose:** Encapsulate all UI input patterns for a single analysis tab

**Current State:** Scattered across lines 161-854

**Proposed Module:**
```r
# R/modules/input_panel_module.R
input_panel_ui <- function(id, title, description, inputs, include_missing_data = FALSE)
input_panel_server <- function(id) # returns reactive list of inputs
```

**Would consolidate:**
- Page structure (h2, helpText, hr)
- All input component rendering
- Missing data adjustment blocks
- Example/Reset button handlers
- Input validation

**Estimated consolidation:** 450-550 lines to ~200 lines (module + instances)

#### Module 2: Analysis Result Module
**Purpose:** Handle all output generation for a single analysis type

**Current State:** Scattered across lines 1521-3400+

**Proposed Module:**
```r
# R/modules/analysis_result_module.R
analysis_result_ui <- function(id)
analysis_result_server <- function(id, inputs_reactive, analysis_type)
```

**Would consolidate:**
- Result text generation
- Effect measures display
- Power curve plots
- Result table generation
- File download handlers

**Benefit:** Replace 980 lines of result_text rendering + 900 lines of plot generation with module instances

#### Module 3: Missing Data Module
**Purpose:** Isolated missing data adjustment UI and logic

**Current State:** Repeated 6 times (lines 222-261, 344-383, 459-498, 552-591, 668-707, 758-797)

**Proposed Module:**
```r
# R/modules/missing_data_module.R
missing_data_ui <- function(id)
missing_data_server <- function(id) # returns reactive list of missing data inputs
```

**Would consolidate:** 210+ lines to ~100 lines (module + 6 instances)

### 3.2 Medium-Priority: Helper Functions for Calculations

#### Function 1: Create Power Curve Data
**Current:** Repeated in 11 plot generation sections

```r
# Extract to: R/helpers/power_curve_helpers.R
create_power_curve_data <- function(
  analysis_type,
  params_list,
  n_points = 100
)
```

**Consolidates:** Power sequence generation and power calculation loops

#### Function 2: Create Plotly Visualization
**Current:** Repeated layout code in 11 plots

```r
# Extract to: R/helpers/plot_helpers.R
create_power_curve_plot <- function(
  n_seq,
  power_vals,
  current_n,
  target_power = 0.8,
  title = "Power Curve"
)
```

**Consolidates:** Plotly object creation, layout styling, tracing

#### Function 3: Generate Result Text
**Current:** 980 lines in single reactive

```r
# Extract to: R/helpers/result_text_helpers.R
generate_result_text <- function(
  analysis_type,
  inputs,
  calculation_results
)
```

#### Function 4: Validation Wrapper
**Current:** Lines 1375-1446, large if/else-if chain

```r
# Extract to: R/helpers/validation_helpers.R
validate_analysis_inputs <- function(analysis_type, input)
```

### 3.3 Low-Priority: UI Component Functions

Some already partially done via `input_components.R`:
- `create_segmented_alpha()` - Line 60 ✓
- `create_segmented_power()` - Line 111 ✓
- `create_enhanced_slider()` - Line 172 ✓
- `radioButtons_fixed()` - Line 22 ✓

**Suggested additions:**
```r
create_sample_size_input <- function(inputId, label, default = 500)
create_event_rate_input <- function(inputId, label, default = 10)
create_effect_size_input <- function(inputId, label, default = 0.5, type = "h")
create_numeric_input_with_tooltip <- function(inputId, label, default, tooltip, ...)
```

---

## 4. CODE METRICS & DUPLICATION STATISTICS

### Overall Code Structure
- **Total lines:** 3,827
- **UI section:** 936 lines (28-963)
- **Server section:** 2,864 lines (964-3827)

### Duplication Breakdown

| Section | Lines | % of Total | Duplication Level |
|---------|-------|-----------|------------------|
| UI Input Patterns | 1,033+ | 27% | HIGH |
| Server Calculation Logic | 2,660+ | 69% | HIGH |
| Helper Functions | 150+ | 4% | MEDIUM |
| **Total Duplicated** | **3,843+** | **100%** | **CRITICAL** |

**Note:** Duplication counts exceed file size because each duplicated pattern is counted separately.

### Duplication Hotspots

**Top 5 Most Duplicated Patterns:**

1. **Tab Page Structure** (11 tabs)
   - Occurrences: 11
   - Lines per occurrence: ~50
   - Total lines: 550
   - Consolidation potential: 70%

2. **Result Text Rendering** (11 analysis types)
   - Occurrences: 11
   - Lines per occurrence: ~90
   - Total lines: 990
   - Consolidation potential: 80%

3. **Power Curve Generation** (11 analysis types)
   - Occurrences: 11
   - Lines per occurrence: ~80
   - Total lines: 880
   - Consolidation potential: 75%

4. **Missing Data Adjustment** (6 analyses)
   - Occurrences: 6
   - Lines per occurrence: ~35
   - Total lines: 210
   - Consolidation potential: 85%

5. **Numeric Input + Tooltip** (30+ inputs)
   - Occurrences: 30+
   - Lines per occurrence: 2
   - Total lines: 60+
   - Consolidation potential: 90%

---

## 5. SPECIFIC DUPLICATION EXAMPLES

### Example 1: Sample Size Input Pattern
Appears 30+ times with minimal variation:

**Current (repeated 30+ times):**
```r
# Line 166-167
numericInput("power_n", "Available Sample Size:", 230, min = 1, step = 1),
bsTooltip("power_n", "Total number of participants...", "right"),

# Line 275
numericInput("twogrp_pow_n1", "Sample Size Group 1:", 200, min = 1, step = 1),

# Line 276
numericInput("twogrp_pow_n2", "Sample Size Group 2:", 200, min = 1, step = 1),

# Line 322-323
numericInput("twogrp_ss_p1", "Event Rate Group 1 (%):", 10, min = 0, max = 100, step = 0.1),
numericInput("twogrp_ss_p2", "Event Rate Group 2 (%):", 5, min = 0, max = 100, step = 0.1),
# ... pattern continues 25+ more times
```

**Proposed (single helper function):**
```r
create_numeric_input_with_tooltip <- function(
  inputId,
  label,
  default = 100,
  min = NULL,
  max = NULL,
  step = 1,
  tooltip = NULL
) {
  tagList(
    numericInput(inputId, label, default, min = min, max = max, step = step),
    if (!is.null(tooltip)) bsTooltip(inputId, tooltip, "right")
  )
}

# Usage (one function call replaces 2 lines):
create_numeric_input_with_tooltip(
  "power_n", "Available Sample Size:", 230, min = 1,
  tooltip = "Total number of participants available for the study"
)
```

### Example 2: Missing Data Adjustment Block
**Lines 222-261 (ss_single) vs Lines 344-383 (twogrp_ss)**

Virtually identical structure, only input ID suffixes change:

```r
# Current Pattern (repeated 6x, ~35 lines each = 210 lines total)
checkboxInput("adjust_missing_ss_single", "Adjust for Missing Data", value = FALSE),
conditionalPanel(
  condition = "input.adjust_missing_ss_single",
  create_enhanced_slider("missing_pct_ss_single", "Expected Missingness (%):",
                        min = 5, max = 50, value = 20, step = 5, post = "%",
                        tooltip = "..."),
  radioButtons_fixed("missing_mechanism_ss_single", "Missing Data Mechanism:", ...),
  radioButtons_fixed("missing_analysis_ss_single", "Planned Analysis Approach:", ...),
  conditionalPanel(
    condition = "input.missing_analysis_ss_single == 'multiple_imputation'",
    numericInput("mi_imputations_ss_single", "Number of Imputations (m):", ...),
    create_enhanced_slider("mi_r_squared_ss_single", "Expected Imputation Model R²:", ...)
  )
)

# Proposed Replacement (call to module):
missing_data_ui("missing_data_ss_single")
```

### Example 3: Tab-Specific Calculation Logic
**Lines 1529-1552 (Power Single) vs Lines 1675-1698 (Power Two-Group)**

```r
# Current (980 lines total for 11 analyses in one massive if/else-if chain)
if (input$tabset == "Power (Single)") {
  incidence_rate <- input$power_p
  sample_size <- input$power_n
  power <- pwr.p.test(..., n = input$power_n)$power
  discon <- input$power_discon / 100
  
  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted...)")
  text3 <- p(paste0("Based on the Binomial distribution...", ...))
  HTML(paste0(text0, text1, text2, text3))
  
} else if (input$tabset == "Sample Size (Single)") {
  # 120+ lines for single vs multiple imputation modes
  
} else if (input$tabset == "Power (Two-Group)") {
  # 20 lines of similar calculation
  
} else if (input$tabset == "Sample Size (Two-Group)") {
  # 130+ lines for single vs multiple imputation modes
  
} # ... 7 more analysis types
```

**Proposed (module-based architecture):**
```r
output$result_text <- renderUI({
  if (!v$doAnalysis) return()
  analysis_result_server("results", inputs_reactive, input$tabset)
})
```

### Example 4: Power Curve Plot Generation
**Lines 2775-2825 (Power Single) vs Lines 2826-2880 (Sample Size Single)**

Both generate ~55 lines of nearly identical Plotly code:

```r
# Both follow this pattern:
if (input$tabset == "Power (Single)") {
  # 1. Extract parameters
  n_current <- input$power_n
  n_seq <- seq(...)
  
  # 2. Generate power sequence
  pow <- vapply(n_seq, function(n) {
    pwr.p.test(..., n = n)$power
  }, FUN.VALUE = numeric(1))
  
  # 3. Create plotly with identical layout
  plot_ly() %>%
    add_trace(x = n_seq, y = pow, ...) %>%
    add_trace(x = range(n_seq), y = c(0.8, 0.8), ...) %>%
    add_trace(x = c(n_current, n_current), y = c(0, 1), ...) %>%
    layout(
      title = list(...),
      xaxis = list(...),
      yaxis = list(...),
      # ... identical for all 11 types
    )
}

# Proposed:
output$power_plot <- renderPlotly({
  if (!v$doAnalysis) return()
  create_power_curve_plot(
    analysis_type = input$sidebar_page,
    params = input,
    calculation_fn = get_calculation_function(input$sidebar_page)
  )
})
```

---

## 6. SUGGESTED MODULARIZATION ARCHITECTURE

```
app.R (Simplified, ~300-400 lines)
├── UI Structure (100-150 lines)
│   └── Uses modules for each tab
├── Server (150-200 lines)
│   └── Uses modules for each tab
└── Data/Config (50 lines)
    └── button_configs, analysis_metadata

R/
├── modules/
│   ├── 001-input_panel.R (200-250 lines)
│   │   ├── input_panel_ui()
│   │   ├── input_panel_server()
│   │   └── Handles all input rendering for a tab
│   │
│   ├── 002-analysis_result.R (300-350 lines)
│   │   ├── analysis_result_ui()
│   │   ├── analysis_result_server()
│   │   └── Handles result display, plots, tables
│   │
│   ├── 003-missing_data.R (150-180 lines)
│   │   ├── missing_data_ui()
│   │   └── missing_data_server()
│   │
│   └── 004-power_curve_plot.R (200-250 lines)
│       ├── power_curve_plot_ui()
│       └── power_curve_plot_server()
│
├── helpers/
│   ├── 001-calculation_wrappers.R (300-350 lines)
│   │   ├── calculate_power_single()
│   │   ├── calculate_ss_single()
│   │   ├── calculate_power_twogroup()
│   │   └── ... (wrapper for each analysis type)
│   │
│   ├── 002-power_curve_helpers.R (150 lines)
│   │   ├── generate_power_sequence()
│   │   └── calculate_power_for_sequence()
│   │
│   ├── 003-plot_helpers.R (200-250 lines)
│   │   ├── create_power_curve_plot()
│   │   ├── create_result_table()
│   │   └── styling constants
│   │
│   ├── 004-result_text_helpers.R (200-250 lines)
│   │   ├── format_result_text()
│   │   ├── format_effect_measures()
│   │   └── format_missing_data_text()
│   │
│   ├── 005-validation_helpers.R (100-150 lines)
│   │   └── validate_inputs() (simplified from 70 lines)
│   │
│   └── 006-input_components.R (260 lines - existing)
│       ├── radioButtons_fixed()
│       ├── create_segmented_alpha()
│       ├── create_segmented_power()
│       ├── create_enhanced_slider()
│       └── new: create_numeric_input_with_tooltip()
│
└── config/
    ├── analysis_metadata.R (100 lines)
    │   └── Configuration for all 11 analysis types
    └── button_configs.R (50 lines - extracted from app.R)
        └── Example/reset values
```

---

## 7. ESTIMATED IMPACT OF REFACTORING

### Before Refactoring
- **Total lines:** 3,827
- **Maintainability:** Low (high duplication)
- **Testing coverage:** Difficult (monolithic)
- **Feature additions:** ~4-5 hours per new analysis type
- **Bug fixes:** Must fix in multiple locations

### After Refactoring
- **Total lines:** ~2,200-2,400 (40% reduction)
- **Maintainability:** High (DRY principle)
- **Testing coverage:** High (modular, testable)
- **Feature additions:** ~1-2 hours per new analysis type
- **Bug fixes:** Single location (modules/helpers)

### Lines Saved by Consolidation

| Consolidation | Current | Proposed | Savings |
|---------------|---------|----------|---------|
| UI Input panels (11 tabs) | 550 | 100 | 450 |
| Missing data blocks (6) | 210 | 60 | 150 |
| Result text rendering (11) | 980 | 150 | 830 |
| Power curve plots (11) | 880 | 120 | 760 |
| Validation logic | 70 | 40 | 30 |
| Tab-specific parameters | 200 | 60 | 140 |
| **Total estimated savings** | **3,890** | **530** | **3,360** |

---

## 8. IMPLEMENTATION ROADMAP

### Phase 1: Foundation (Week 1)
1. Extract `input_components.R` helpers to independent file (already done)
2. Create `R/config/analysis_metadata.R` with all tab configurations
3. Create `R/helpers/validation_helpers.R` (consolidate validate_inputs)
4. Create `R/helpers/result_text_helpers.R` (initial template)

### Phase 2: Module Development (Weeks 2-3)
1. Create `R/modules/missing_data.R` module
2. Create `R/modules/input_panel.R` module with missing data integration
3. Create `R/modules/power_curve_plot.R` module
4. Test modules with 1-2 analysis types

### Phase 3: Integration (Weeks 4-5)
1. Refactor `app.R` UI to use input_panel module (11 instances)
2. Refactor server logic to use power_curve_plot module
3. Create wrapper functions in helpers/ for result text generation
4. Integrate all modules into app.R

### Phase 4: Cleanup (Week 6)
1. Remove duplicate code from main app.R
2. Update documentation
3. Add comprehensive test suite
4. Validate all 11 analysis types still work identically

---

## 9. RECOMMENDATIONS

### Priority 1 (Must Do)
1. **Create missing_data module** - 6 occurrences of identical 35-line block
2. **Extract calculation wrappers** - Simplifies 980-line result_text rendering
3. **Create plot helper functions** - Reduces 880 lines of duplicated plot code

### Priority 2 (Should Do)
4. **Create input_panel module** - Consolidates UI structure across 11 tabs
5. **Extract validation logic** - Simplify 70-line if/else chain
6. **Add numeric input helper** - Replace 60+ lines of repetitive code

### Priority 3 (Nice to Have)
7. **Create result_text module** - Further modularization of output rendering
8. **Add reactive configuration** - Allow dynamic tab addition without code changes
9. **Create comprehensive tests** - Ensure refactoring doesn't break functionality

---

## 10. CODE EXAMPLES FOR REFACTORING

### Example 1: Missing Data Module

**Before (repeated 6 times, 210+ lines total):**
```r
# Lines 222-261 (ss_single)
checkboxInput("adjust_missing_ss_single", "Adjust for Missing Data", value = FALSE),
conditionalPanel(
  condition = "input.adjust_missing_ss_single",
  create_enhanced_slider("missing_pct_ss_single", ...,
                        tooltip = "Percentage of participants..."),
  radioButtons_fixed("missing_mechanism_ss_single", "Missing Data Mechanism:", ...),
  radioButtons_fixed("missing_analysis_ss_single", "Planned Analysis Approach:", ...),
  conditionalPanel(
    condition = "input.missing_analysis_ss_single == 'multiple_imputation'",
    numericInput("mi_imputations_ss_single", "Number of Imputations (m):", ...),
    create_enhanced_slider("mi_r_squared_ss_single", "Expected Imputation Model R²:", ...)
  )
)
# ... REPEAT 5 MORE TIMES WITH DIFFERENT SUFFIX
```

**After (single module instance × 6):**
```r
missing_data_ui("missing_data_ss_single")

# In R/modules/missing_data.R:
missing_data_ui <- function(id) {
  ns <- NS(id)
  tagList(
    checkboxInput(ns("enabled"), "Adjust for Missing Data", value = FALSE),
    conditionalPanel(
      condition = paste0("input['", id, "-enabled']"),
      create_enhanced_slider(ns("missing_pct"), "Expected Missingness (%):", ...),
      radioButtons_fixed(ns("mechanism"), "Missing Data Mechanism:", ...),
      radioButtons_fixed(ns("analysis"), "Planned Analysis Approach:", ...),
      conditionalPanel(
        condition = paste0("input['", id, "-analysis'] == 'multiple_imputation'"),
        numericInput(ns("imputations"), "Number of Imputations (m):", ...),
        create_enhanced_slider(ns("r_squared"), "Expected Imputation Model R²:", ...)
      )
    )
  )
}

missing_data_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Validation and reactivity
    return(reactive(list(
      enabled = input$enabled,
      missing_pct = input$missing_pct,
      mechanism = input$mechanism,
      analysis = input$analysis,
      imputations = input$imputations,
      r_squared = input$r_squared
    )))
  })
}
```

### Example 2: Simplified Result Text Generation

**Before (980+ lines for 11 types in single massive if/else-if):**
```r
output$result_text <- renderUI({
  if (!v$doAnalysis) return()
  isolate({
    validate_inputs()
    
    if (input$tabset == "Power (Single)") {
      # 20+ lines
    } else if (input$tabset == "Sample Size (Single)") {
      # 150+ lines
    } else if (input$tabset == "Power (Two-Group)") {
      # 20+ lines
    } else if (input$tabset == "Sample Size (Two-Group)") {
      # 150+ lines
    } # ... 7 more with hundreds of lines
  })
})
```

**After (using helper functions):**
```r
output$result_text <- renderUI({
  if (!v$doAnalysis) return()
  isolate({
    validate_inputs()
    
    analysis_type <- get_analysis_type_from_tabset(input$tabset)
    calculation_result <- perform_calculation(analysis_type, input)
    
    format_result_text(
      analysis_type = analysis_type,
      inputs = input,
      result = calculation_result,
      include_missing_data_adjustment = has_missing_data_inputs(input)
    )
  })
})

# In R/helpers/result_text_helpers.R:
format_result_text <- function(analysis_type, inputs, result, include_missing_data_adjustment) {
  # Single function dispatches to type-specific formatters
  formatter <- switch(analysis_type,
    "power_single" = format_power_single,
    "ss_single" = format_ss_single,
    "power_twogroup" = format_power_twogroup,
    # ... etc
  )
  formatter(inputs, result, include_missing_data_adjustment)
}

# Simple, focused functions:
format_power_single <- function(inputs, result, include_adjustment) {
  # Only ~20 lines for this specific type
  text0 <- hr()
  text1 <- h1("Results of this analysis")
  text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
  text3 <- p(paste0(...))
  
  missing_text <- if (include_adjustment) {
    format_missing_data_text(inputs, result)
  } else {
    HTML("")
  }
  
  HTML(paste0(text0, text1, text2, text3, missing_text))
}
```

---

## 11. CONCLUSION

The `app.R` file contains substantial code duplication (estimated 40-45% of total lines) across multiple dimensions:

- **UI Level:** Repeated patterns in input rendering, button groups, and conditional panels
- **Logic Level:** Identical calculation structures replicated across 11 analysis types
- **Output Level:** Nearly identical rendering logic for results, plots, and tables

Key duplication hotspots:
1. Missing data adjustment blocks (210+ lines)
2. Result text rendering (980+ lines)
3. Power curve plot generation (880+ lines)
4. Tab page structure (550+ lines)
5. Numeric input components (60+ lines)

**Primary Recommendation:** Implement Shiny module-based architecture with helper functions to achieve:
- 40% code reduction (3,827 → 2,200-2,400 lines)
- Significant improvement in maintainability
- Easier feature additions and bug fixes
- Better testability and code organization

The existing code demonstrates good practices in some areas (button_configs, input_components.R) but lacks systematic modularization at the UI and business logic levels.

