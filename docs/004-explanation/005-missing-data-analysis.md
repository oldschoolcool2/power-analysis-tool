# Current Missing Data Adjustment Implementation Analysis
## Power Analysis Tool - Deep Dive Study

---

## EXECUTIVE SUMMARY

The Power Analysis Tool currently has a **modular, reusable missing data adjustment system** that supports:

1. **Two analysis approaches**: Complete Case Analysis (CCA) and Multiple Imputation (MI)
2. **Three missing data mechanisms**: MCAR, MAR, MNAR
3. **Six analysis tabs** where the feature is integrated
4. **Smart inflation factor calculations** based on analysis type

**Current Status:**
- ✅ Missing data module created and working on 6 tabs
- ✅ Calculation formulas implemented for both CCA and MI
- ⚠️ MI-specific enhancements needed for sample size calculations
- ⏳ Not yet available on all tabs (e.g., no missing data UI for power analysis tabs)

---

## 1. CURRENT MISSING DATA IMPLEMENTATION

### 1.1 Architecture Overview

```
R/modules/001-missing-data-module.R (163 lines)
├── missing_data_ui()      → Renders UI with controls
├── missing_data_server()  → Manages reactive values
└── calculate_missing_inflation() → Helper for parent app

app.R (3,000+ lines context)
├── calc_missing_data_inflation() [Lines 965-1036]
│   ├── Complete Case Analysis (CCA) branch
│   └── Multiple Imputation (MI) branch
└── format_missing_data_text() [R/helpers/002-result-text-helpers.R]
```

### 1.2 UI Component Structure (missing_data_ui)

**Conditional Rendering:**
```
┌─ Adjust Missing Data? [Toggle]
│  ├─ Expected Missingness Slider (5%-50%, default 20%)
│  ├─ Missing Data Mechanism Radio Buttons
│  │  ├─ MCAR (Missing Completely At Random)
│  │  ├─ MAR (Missing At Random) [DEFAULT]
│  │  └─ MNAR (Missing Not At Random)
│  ├─ Planned Analysis Approach Radio Buttons
│  │  ├─ Complete Case Analysis [DEFAULT]
│  │  └─ Multiple Imputation
│  │     [Shows ONLY when "Multiple Imputation" selected]
│  │     ├─ Number of Imputations (m): 3-100 [DEFAULT: 5]
│  │     └─ Imputation Model R²: 0.1-0.9 [DEFAULT: 0.5]
│  └─ Tooltips for each parameter
```

---

## 2. MISSING DATA MECHANISMS & IMPLEMENTATION

### 2.1 Supported Mechanisms

| Mechanism | Implementation | Interpretation |
|-----------|---|---|
| **MCAR** | Missingness independent of all variables | Minimal bias with either analysis approach |
| **MAR** | Missingness depends on observed variables | Can be handled with proper imputation or covariate adjustment |
| **MNAR** | Missingness depends on unobserved variables | Potential for substantial bias; sensitivity analysis recommended |

**Current Handling:**
- All three mechanisms supported in UI
- Different interpretive text provided based on mechanism + analysis type
- No mathematical adjustment for mechanism type (both CCA and MI use same inflation regardless of mechanism)

---

## 3. ANALYSIS APPROACHES: COMPLETE CASE vs. MULTIPLE IMPUTATION

### 3.1 Complete Case Analysis (CCA) Formula

**Current Implementation (Lines 979-999):**

```r
inflation_factor <- 1 / (1 - p_missing)
n_inflated <- ceiling(n_required * inflation_factor)
```

**Example:**
- Required N = 500
- Expected missingness = 20%
- Inflation factor = 1 / (1 - 0.20) = 1.25
- Inflated N = 500 × 1.25 = **625 participants**

**Why This Works:**
If 20% have missing data, only 80% of your N contribute to analysis.
To maintain the original effective sample size, multiply by 1.25.

**Mechanism-Specific Interpretation:**
```
"Assuming 20% missingness (MAR) with complete-case analysis, 
inflate sample size by 25% (add 125 participants) to ensure 
adequate complete-case sample."
```

### 3.2 Multiple Imputation (MI) Formula

**Current Implementation (Lines 1000-1027):**

```r
# Relative efficiency of MI vs complete case
re_mi <- 1 / ((1 + 1/m) * (1 - R²_imp))

# Total inflation accounts for both missing data and MI efficiency
inflation_factor <- (1 / (1 - p_missing)) * (1 / re_mi)
```

**Where:**
- `m` = number of imputations (user input, default 5)
- `R²_imp` = imputation model R² (user input, default 0.5)

**Example:**
- Required N = 500
- Expected missingness = 20%
- m = 5 imputations
- R² = 0.5 (moderate imputation model quality)

```
Step 1: Calculate RE (relative efficiency)
RE = 1 / [(1 + 1/5) × (1 - 0.5)]
   = 1 / [1.2 × 0.5]
   = 1 / 0.6
   = 1.667

Step 2: Total inflation
inflation = (1 / 0.8) × (1 / 1.667)
          = 1.25 × 0.6
          = 0.75

Wait, this gives compression (< 1), which is wrong!
```

**⚠️ POTENTIAL BUG IN CURRENT IMPLEMENTATION:**

Looking at lines 1006-1011:
```r
# Formula is: (1 / (1 - p_missing)) * (1 / re_mi)
inflation_factor <- (1 / (1 - p_missing)) * (1 / re_mi)
```

This appears to be dividing by relative efficiency, which would **reduce** the sample size below the missing-data-only inflation. This may be incorrect.

**Correct MI Inflation Should Be:**
```r
# Multiple imputation recovers some information lost to missingness
# Inflation should account for both missingness AND recovery
inflation_factor <- (1 / (1 - p_missing)) * sqrt(re_mi)
# OR (more conservative)
inflation_factor <- (1 / (1 - p_missing))  # Same as CCA, MI recovers info
```

### 3.3 Current Interpretation Text for MI

From lines 1023-1026:
```
"Assuming 20% missingness (MAR) with multiple imputation 
(m=5 imputations, R²=0.5), inflate sample size by [%] 
(add [N] participants). MI is more efficient than 
complete-case analysis."
```

**Note:** The current formula claims MI is more efficient, but the implementation may have an error.

---

## 4. INTEGRATION INTO ANALYSIS TABS

### 4.1 Where Missing Data Adjustment is Currently Available

**YES - Missing Data UI Present:**

1. **Tab 3: Single Proportion (Sample Size)** ✅
   - `missing_data_ui("ss_single-missing_data")`
   - Module: `missing_data_ss_single <- missing_data_server("ss_single-missing_data")`
   - Usage: Lines 1474-1489

2. **Tab 5: Two-Group (Sample Size)** ✅
   - `missing_data_ui("twogrp_ss-missing_data")`
   - Module: `missing_data_twogrp_ss <- missing_data_server("twogrp_ss-missing_data")`
   - Usage: Lines 1614-1639

3. **Tab 7: Survival (Sample Size)** ✅
   - `missing_data_ui("surv_ss-missing_data")`
   - Module: `missing_data_surv_ss <- missing_data_server("surv_ss-missing_data")`
   - Usage: Lines 1745-1776

4. **Tab 9: Matched Case-Control (Sample Size)** ✅
   - `missing_data_ui("match-missing_data")`
   - Module: `missing_data_match <- missing_data_server("match-missing_data")`
   - Usage: Lines 1901-1926

5. **Tab 11: Continuous Outcomes (Sample Size)** ✅
   - `missing_data_ui("cont_ss-missing_data")`
   - Module: `missing_data_cont_ss <- missing_data_server("cont_ss-missing_data")`
   - Usage: Lines 2103-2128

6. **Tab 12: Non-Inferiority (Sample Size)** ✅
   - `missing_data_ui("noninf-missing_data")`
   - Module: `missing_data_noninf <- missing_data_server("noninf-missing_data")`
   - Usage: Lines 2254-2279

**NO - Missing Data UI NOT Present:**

- Tab 1: Single Proportion (Power Analysis)
- Tab 2: Two-Group (Power Analysis)
- Tab 4: Survival (Power Analysis)
- Tab 6: Matched Case-Control (Power Analysis)
- Tab 8: Continuous Outcomes (Power Analysis)
- Tab 10: VIF Calculator
- (Any other tabs)

---

## 5. CALCULATION DETAILS & FORMULAS

### 5.1 calc_missing_data_inflation() Function

**Signature (Line 965):**
```r
calc_missing_data_inflation <- function(
  n_required,           # Base sample size
  missing_pct,          # Percentage missing (5-50)
  mechanism = "mar",    # "mcar", "mar", or "mnar"
  analysis_type = "complete_case",  # "complete_case" or "multiple_imputation"
  mi_imputations = 5,   # Number of imputations (m)
  mi_r_squared = 0.5    # Imputation model R²
)
```

**Returns:**
```r
list(
  n_inflated = ceiling(...),     # Final sample size
  inflation_factor = round(..., 3),  # Multiplier (e.g., 1.25)
  n_increase = n_inflated - n_required,  # Additional participants
  pct_increase = round(..., 1),   # Percentage increase
  interpretation = "..."         # Human-readable text
)
```

### 5.2 Complete Case Analysis Branch (Lines 979-999)

```r
if (analysis_type == "complete_case") {
  inflation_factor <- 1 / (1 - p_missing)  # p_missing = missing_pct/100
  n_inflated <- ceiling(n_required * inflation_factor)
  n_increase <- n_inflated - n_required
  pct_increase <- round((inflation_factor - 1) * 100, 1)
  
  mechanism_text <- switch(mechanism,
    "mcar" = "MCAR (minimal bias expected)",
    "mar" = "MAR (bias controllable with observed covariates)",
    "mnar" = "MNAR (potential for substantial bias; sensitivity analysis recommended)",
    "MAR"  # default
  )
  
  interpretation <- sprintf(
    "Assuming %s%% missingness (%s) with complete-case analysis, 
    inflate sample size by %s%% (add %s participants) to ensure 
    adequate complete-case sample.",
    missing_pct, mechanism_text, pct_increase, n_increase
  )
}
```

### 5.3 Multiple Imputation Branch (Lines 1000-1027)

```r
else if (analysis_type == "multiple_imputation") {
  # Relative efficiency of MI vs complete case
  # Based on: Var(MI estimate) / Var(Complete case estimate)
  # Formula: (1 + 1/m) × (1 - R²)
  re_mi <- 1 / ((1 + 1/mi_imputations) * (1 - mi_r_squared))
  
  # Total inflation accounts for both missing data and MI efficiency
  inflation_factor <- (1 / (1 - p_missing)) * (1 / re_mi)
  
  n_inflated <- ceiling(n_required * inflation_factor)
  n_increase <- n_inflated - n_required
  pct_increase <- round((inflation_factor - 1) * 100, 1)
  
  mechanism_text <- switch(mechanism,
    "mcar" = "MCAR (minimal bias, MI highly efficient)",
    "mar" = "MAR (MI can provide unbiased estimates with good imputation model)",
    "mnar" = "MNAR (MI may reduce but not eliminate bias; sensitivity analysis required)",
    "MAR"  # default
  )
  
  interpretation <- sprintf(
    "Assuming %s%% missingness (%s) with multiple imputation 
    (m=%s imputations, R²=%s), inflate sample size by %s%% 
    (add %s participants). MI is more efficient than 
    complete-case analysis.",
    missing_pct, mechanism_text, mi_imputations, mi_r_squared, 
    pct_increase, n_increase
  )
}
```

---

## 6. RESULT TEXT FORMATTING

### 6.1 format_missing_data_text() Function

**Location:** R/helpers/002-result-text-helpers.R, lines 21-44

**Purpose:** Wraps inflation results in styled HTML callout box

**Example Output:**
```
┌─────────────────────────────────────────────────────────┐
│ Missing Data Adjustment (Tier 1 Enhancement):           │
│                                                         │
│ Assuming 20% missingness (MAR) with complete-case       │
│ analysis, inflate sample size by 25% (add 125           │
│ participants) to ensure adequate complete-case sample.  │
│                                                         │
│ Sample size before missing data adjustment: 500         │
│ Inflation factor: 1.25                                  │
│ Additional participants needed: 125                     │
└─────────────────────────────────────────────────────────┘
```

**HTML Styling:**
- Background: Light yellow (#fff3cd)
- Border: Left border in orange (#f39c12)
- Padding: 10px
- Font: Strong (bold) for labels

---

## 7. MODULE PATTERN & REUSABILITY

### 7.1 Why This Was Modularized

**Problem Solved:**
- Missing data UI was duplicated across 6 tabs
- Each tab had 35-40 lines of identical UI code
- Server logic for reactive values repeated 6 times

**Solution: Shiny Module Pattern**
- `missing_data_ui(id)` - UI function (namespace-aware)
- `missing_data_server(id)` - Server function (namespace-aware)
- Returns reactive list that parent can access

### 7.2 Module Usage Pattern

**In UI (app.R, example for Tab 3):**
```r
missing_data_ui("ss_single-missing_data")
```

**In Server (app.R, line 854):**
```r
missing_data_ss_single <- missing_data_server("ss_single-missing_data")
```

**In Calculation (app.R, line 1474):**
```r
md_vals <- missing_data_ss_single()  # Get reactive values
if (md_vals$adjust_missing) {
  missing_adj <- calc_missing_data_inflation(
    n_calculated,
    md_vals$missing_pct,
    md_vals$missing_mechanism,
    md_vals$missing_analysis,
    md_vals$mi_imputations,
    md_vals$mi_r_squared
  )
  n_final <- missing_adj$n_inflated
}
```

**Benefits:**
- 85% code reduction (210 lines → 35 lines per tab)
- Single source of truth for UI/logic
- Easy to update all instances simultaneously
- DRY principle adherence

---

## 8. MISSING DATA PARAMETER DETAILS

### 8.1 Missing Percentage (missing_pct)

**UI Control:** `create_enhanced_slider()`
- Range: 5% - 50%
- Default: 20%
- Step: 5%
- Tooltip: "Percentage of participants with missing exposure, outcome, or covariate data"

**Interpretation:**
- Low (5-10%): Realistic for well-run studies
- Moderate (15-25%): Conservative assumption for typical studies
- High (30-50%): Pessimistic scenario planning

### 8.2 Missing Mechanism (missing_mechanism)

**UI Control:** `radioButtons_fixed()`
- Default: "mar" (MAR)
- Options:
  1. "mcar" → "MCAR (Missing Completely At Random)"
  2. "mar" → "MAR (Missing At Random)"
  3. "mnar" → "MNAR (Missing Not At Random)"

**User Guidance (from tooltip):**
> "MCAR: minimal bias. MAR: controllable with observed data. 
> MNAR: potential substantial bias"

### 8.3 Missing Analysis Approach (missing_analysis)

**UI Control:** `radioButtons_fixed()`
- Default: "complete_case"
- Options:
  1. "complete_case" → "Complete Case Analysis"
  2. "multiple_imputation" → "Multiple Imputation (MI)"

**User Guidance (from tooltip):**
> "Complete case: only use observations with no missing data (more conservative). 
> MI: impute missing values (more efficient)"

### 8.4 Number of Imputations (mi_imputations)

**UI Control:** `numericInput()`
- Range: 3 - 100
- Default: 5
- Step: 1
- Conditional: Shows ONLY when multiple_imputation selected

**User Guidance (from tooltip):**
> "Typical values: 5-20. More imputations increase precision but require more computation"

**Recommendation by Literature:**
- 5: Minimum for most applications
- 5-10: Common in practice (balance efficiency vs. diminishing returns)
- 20-30: When precision is critical
- 100: Rarely needed; computational cost increases

### 8.5 Imputation Model R² (mi_r_squared)

**UI Control:** `create_enhanced_slider()`
- Range: 0.1 - 0.9
- Default: 0.5
- Step: 0.1

**User Guidance (from tooltip):**
> "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). 
> Higher R² means better imputation quality and less inflation needed"

**Interpretation Scale:**
| R² Range | Interpretation |
|----------|---|
| 0.1 - 0.3 | Weak imputation model; high inflation needed |
| 0.3 - 0.5 | Moderate model; can explain ~30-50% of missingness |
| 0.5 - 0.7 | Strong model; good predictors available |
| 0.7 - 0.9 | Very strong model; excellent imputation quality |

**Statistical Basis:**
The R² represents how much variance in the missing variable is explained by
other variables in the imputation model (predictors).

---

## 9. CURRENT ISSUES & LIMITATIONS

### 9.1 Formula Issues

**⚠️ ISSUE 1: MI Inflation Factor Calculation (Line 1011)**

**Current Code:**
```r
inflation_factor <- (1 / (1 - p_missing)) * (1 / re_mi)
```

**Problem:**
- If re_mi > 1 (MI is efficient), then (1/re_mi) < 1
- This reduces the inflation factor below the CCA value
- But the code says "MI is more efficient" (more negative inflation)
- Mathematically, dividing by relative efficiency doesn't make sense

**What It Should Be:**
The relative efficiency formula `(1 + 1/m) × (1 - R²)` represents the
**variance increase** from using MI vs. complete data. To get the net effect:

```r
# Option A: MI reduces variance by factor of (1/re_mi)
# So inflation is: (missing data inflation) × sqrt(mi_recovery)
inflation_factor <- (1 / (1 - p_missing)) * sqrt(re_mi)

# Option B: MI recovers information, effectively increasing N
# Net effect is just the missing data inflation
inflation_factor <- 1 / (1 - p_missing)  # Same as CCA

# Option C (Literature-based - conservative):
# No inflation recovery - MI still requires adjusting for missingness
inflation_factor <- 1 / (1 - p_missing)
```

**Recommendation:** Verify formula against Rubin (1987), Little & Rubin (2002),
or van Buuren (2018) references.

### 9.2 Mechanism Handling

**Current:** Mechanism (MCAR/MAR/MNAR) affects only **interpretation text**, not calculations

**Expected:** Mechanism should affect **inflation factor**:
- MCAR: Minimum inflation (no bias)
- MAR: Moderate inflation (bias controllable)
- MNAR: Maximum inflation (bias uncontrollable)

**Current Workaround:** User is expected to choose more pessimistic assumptions
(higher missing %, lower R² for imputation) when MNAR is selected.

### 9.3 Missing from Power Analysis Tabs

**Gap:** Missing data adjustment available only for **sample size** tabs,
not for **power analysis** tabs.

**Users Cannot:**
- Calculate power when they have fixed N and expect missing data
- Determine minimum effect sizes detectable with missing data

### 9.4 Limited Mechanism-Specific Guidance

**Current:** Generic tooltips, no differentiation for mechanism choice

**Needed:**
- When MNAR selected: "Recommend conducting sensitivity analysis"
- When MAR selected: "Ensure important confounders are measured"
- When MCAR selected: "Least concerning scenario"

### 9.5 No Sensitivity Analysis

**Current:** Single-point estimates only

**Needed:**
- Scenario analysis tables (optimistic/base/pessimistic)
- What-if exploration: "If R² is actually 0.3, how much N?"
- Interactive sliders showing real-time N changes

---

## 10. WHAT NEEDS TO BE ADDED FOR MI-SPECIFIC CALCULATIONS

Based on the comprehensive feature analysis document (003-comprehensive-feature-analysis-2025.md),
this is the **NEW 2 feature** requiring implementation:

### 10.1 Feature: "Sample Size for Multiple Imputation" (NEW 2)

**Priority:** ⭐⭐⭐⭐ **SHOULD HAVE**

**Status:** Partially Implemented (basic MI option exists, needs enhancement)

**What's Needed:**

1. **MI-Specific Inflation Formulas**
   - Correct relative efficiency calculation
   - Power accounting for variance increase from MI
   - Effective sample size after imputation

2. **Additional MI Parameters**
   - Number of imputations m: 3-100 (current: ✅ exists)
   - Imputation model quality R²: (current: ✅ exists)
   - **NEW:** Fraction of information lost (λ = FMI - Fraction Missing Information)
   - **NEW:** Compliance with recommended m (m should be ≥ %missing)

3. **MI-Specific Output**
   ```
   Recommended sample size: N = 625
   - Base sample size: 500
   - Adjusted for 20% missingness + MI: × 1.15
   - Effective N after weighting: ~540
   
   Imputation efficiency gains:
   - Complete case would need: 625 (× 1.25)
   - With MI (m=5, R²=0.5): 606 (× 1.21)
   - Savings: 19 participants vs. CCA
   
   MI Recommendations:
   - Imputations m: Minimum of 5, ideally 10-20
   - m should be ≥ % missing (at least 20 imputations for 20% missingness)
   - Current m=5 is below recommended minimum
   ```

4. **Comparison to Complete-Case**
   - Side-by-side table: MI vs. CCA inflation
   - Cost-benefit analysis: Efficiency gains vs. computation cost

5. **Better Imputation Model Guidance**
   - How to estimate R² from pilot data
   - Typical R² values by outcome type and confounder sets
   - Literature values for common scenarios

### 10.2 Implementation Approach

**Suggested Structure:**

```r
# New helper function for MI-specific calculations
calculate_mi_sample_size <- function(
  n_complete,        # N for complete data
  missing_pct,       # Expected missing percentage
  m_imputations,     # Number of imputations
  r_squared,         # Imputation model R²
  outcome_type = "binary"  # binary, continuous, survival
) {
  
  # Fraction of missing information
  p_m <- missing_pct / 100
  
  # Relative efficiency of MI vs. complete case
  # Based on Rubin's variance formula
  relative_efficiency <- 1 / ((1 + 1/m_imputations) * (1 - r_squared))
  
  # Effective sample size recovery
  n_recovery <- n_complete * (1 - (1 / relative_efficiency))
  
  # Net inflation (less than CCA)
  cca_inflation <- 1 / (1 - p_m)
  mi_inflation <- cca_inflation * sqrt(relative_efficiency)  # ???
  
  # Check: Is m adequate?
  m_adequate <- m_imputations >= ceiling(missing_pct)
  
  # Recommendations
  recommendations <- list(
    n_needed = ceiling(n_complete * mi_inflation),
    compare_to_cca = ceiling(n_complete * cca_inflation),
    efficiency_gain = ceiling(n_complete * cca_inflation) - ceiling(n_complete * mi_inflation),
    m_adequate = m_adequate,
    m_recommended = max(m_imputations, ceiling(missing_pct))
  )
  
  return(recommendations)
}
```

### 10.3 Where to Integrate

**Option A: Extend Existing Missing Data Module**
- Keep current module structure
- Add MI-specific calculation path
- Expand output to show MI vs. CCA comparison

**Option B: Create Separate MI Sample Size Tab**
- New Tab 13: "Multiple Imputation Sample Size"
- Dedicated UI for MI parameters
- Focus on MI-specific guidance

**Recommended:** Option A (extend existing)
- Reuses existing module structure
- Less code duplication
- Leverages existing UX patterns

---

## 11. REFERENCE: MISSING DATA ADJUSTMENT WORKFLOW

### 11.1 User Workflow (Current)

```
User opens sample size calculator (e.g., Tab 3)
    ↓
Sees checkbox "Adjust for Missing Data"
    ↓
Checks checkbox
    ↓
UI expands to show:
    - Missing % slider
    - Mechanism: MCAR/MAR/MNAR radio
    - Analysis: Complete Case or MI radio
    ↓
If MI selected:
    - Number of imputations input
    - Imputation model R² slider
    ↓
Fills in other analysis parameters
    ↓
Clicks "Calculate"
    ↓
Results show:
    - Base sample size (no adjustment)
    - Sample size after discontinuation (if applicable)
    - Sample size after missing data adjustment
    - Interpretation box with details
```

### 11.2 Missing Data Calculation Workflow (Current)

```
calc_missing_data_inflation()
    ↓
if (analysis_type == "complete_case") {
    inflation = 1 / (1 - p_missing)
} else if (analysis_type == "multiple_imputation") {
    relative_efficiency = 1 / ((1 + 1/m) * (1 - R²))
    inflation = (1 / (1 - p_missing)) * (1 / relative_efficiency)
}
    ↓
n_inflated = ceiling(n_required * inflation)
    ↓
interpretation = switch(mechanism) { ... }
    ↓
return: list(n_inflated, inflation_factor, interpretation, ...)
```

---

## 12. CONFIGURATION & DEFAULT VALUES

### 12.1 Current Defaults (Hard-Coded)

**In missing_data_ui():**
```r
missing_pct: value = 20       # Default 20% missingness
missing_mechanism: selected = "mar"  # Default to MAR
missing_analysis: selected = "complete_case"  # Default CCA, not MI
mi_imputations: 5             # Default 5 imputations
mi_r_squared: value = 0.5     # Default 0.5 R²
```

**In calc_missing_data_inflation():**
```r
mechanism = "mar"             # Function default
analysis_type = "complete_case"  # Function default
mi_imputations = 5            # Function default
mi_r_squared = 0.5            # Function default
```

### 12.2 Recommended Defaults by Context

| Parameter | Current | Recommended | Rationale |
|-----------|---------|---|---|
| Adjust missing data | OFF | OFF | Users should decide |
| Missing % | 20% | 10% | More realistic for typical studies |
| Mechanism | MAR | MAR | Reasonable middle ground |
| Analysis | Complete case | Complete case | More conservative |
| m (imputations) | 5 | 10 | Better for realistic scenarios |
| R² | 0.5 | 0.4 | More conservative |

---

## 13. HELP & DOCUMENTATION

### 13.1 Current Help Content

**Location:** R/help_content.R

**VIF Calculator Help (lines 268-424)** includes:
- Section 6.2: "Understanding Li et al. (2025) Parameters"
- Multiple accordion panels explaining:
  - Overlap coefficient (φ)
  - Confounder-outcome R²
  - Important cautions about propensity score methods

**Missing Data Help:** NOT YET CREATED in help_content.R

### 13.2 What's Documented

**In UI Tooltips:**
- Each parameter has `bsTooltip()` with contextual help
- Appears on hover or click

**In Interactive Help (pending):**
- No dedicated accordion section for missing data in help_content.R
- Should be added alongside VIF guidance

---

## 14. VALIDATION STATUS

### 14.1 Against Formulas

**Complete Case Analysis:**
- Formula: N_adjusted = N / (1 - p_missing)
- Source: Standard epidemiology textbooks
- Status: ✅ Correct

**Multiple Imputation (RE formula):**
- Formula: RE = 1 / [(1 + 1/m) × (1 - R²)]
- Source: Rubin (1987), Little & Rubin (2002)
- Status: ⚠️ Formula correct, but application questionable

**Overall Inflation:**
- Current: inflate = (1 / (1 - p_missing)) × (1 / re_mi)
- Status: ❌ Needs verification against literature

### 14.2 Against Commercial Software

- Not yet cross-validated against PASS, nQuery, or G*Power
- Missing data adjustment not available in all commercial tools
- Recommend validation when feature is finalized

### 14.3 Against Real Studies

- No published protocols found using this tool's missing data module yet
- Module is new (created 2025-10-25)
- First production use expected within 3-6 months

---

## 15. KEY TAKEAWAYS FOR MI EXTENSION

### What Exists
✅ Modular, reusable UI and calculation framework
✅ Both CCA and MI options available
✅ Support for MCAR, MAR, MNAR mechanisms
✅ Integrated into 6 sample size calculation tabs
✅ Helper functions for formatting results
✅ Default reasonable values for common scenarios

### What Needs Improvement for MI
⚠️ Verify/correct MI inflation formula (potential bug)
⚠️ Add MI-specific output comparisons
⚠️ Better guidance on selecting m and R²
⚠️ Add to power analysis tabs (not just sample size)
⚠️ Create sensitivity analysis tables
⚠️ Enhance mechanism-specific guidance
⚠️ Build dedicated help content
⚠️ Cross-validate formulas against literature

### Where to Start
1. **First:** Verify the MI inflation formula (line 1011)
   - Consult Little & Rubin (2002), Rubin (1987), van Buuren (2018)
   - Create unit tests to validate formula

2. **Second:** Create MI-specific comparison output
   - Add table: CCA vs. MI sample size needs
   - Show efficiency gains from MI

3. **Third:** Extend to power analysis tabs
   - Add missing_data_ui() to power tabs
   - Implement power degradation with missing data

4. **Fourth:** Build sensitivity analysis
   - Grid of values: m (3-20) vs. R² (0.2-0.8)
   - Show how N varies with assumptions

5. **Fifth:** Create documentation
   - Help accordion section for missing data
   - Tutorial on selecting MI parameters
   - Examples showing MI benefits

