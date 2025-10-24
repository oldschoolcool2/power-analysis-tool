# Feature Enhancement Ideas for RWE Power Analysis Tool

**Document Version:** 1.0
**Date:** 2025-10-24
**Purpose:** Enhancement recommendations based on best practices for power and sample size calculations in Real-World Evidence (RWE) and observational studies

---

## Executive Summary

This document outlines evidence-based enhancements to make the Power Analysis Tool more robust and powerful for biostatisticians working with real-world data (RWD), generating real-world evidence (RWE), and conducting observational studies.

### Key Research Findings

Recent research (2024-2025) shows that observational study sample size calculations require additional considerations beyond traditional RCT calculations:

- **Propensity Score Methods**: Variance Inflation Factor (VIF) accounts for reduced effective sample size when using IPTW
- **Confounding Adjustment**: Two additional parameters needed beyond RCT inputs: confounder-treatment and confounder-outcome association strength
- **Regulatory Context**: FDA/EMA emphasize "fit-for-use" RWD with attention to data quality, missing data, and bias mitigation
- **Fixed Sample Sizes**: In secondary data use, sample size is often predetermined by available database

### Current Application Strengths

✅ Matched case-control designs (accounting for correlation)
✅ Multiple allocation ratios
✅ Discontinuation/withdrawal adjustments
✅ Non-inferiority testing
✅ Comprehensive effect measures (RR, OR, HR)
✅ 10 analysis types covering binary, continuous, and survival outcomes

---

## TIER 1: Critical Additions for Propensity Score Methods

### 1. Variance Inflation Factor (VIF) Calculator

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE

**Purpose:** Adjust sample size for propensity score weighting methods

**Inputs:**
- Anticipated treatment prevalence (%)
- Anticipated c-statistic of propensity score model (0.5-1.0)
- Weighting method:
  - ATE (Average Treatment Effect - inverse probability weights)
  - ATT (Average Treatment effect on Treated)
  - ATO (Average Treatment effect in Overlap population)
  - ATM (Average Treatment effect in Matched population)
  - ATEN (Entropy weights)

**Outputs:**
- Design effect/VIF multiplier
- Adjusted sample size = N_RCT × VIF
- Effective sample size after weighting
- Interpretation text for protocols

**Statistical Method:**
- Austin (2021) methods for VIF estimation based on treatment prevalence and c-statistic
- Formula: VIF depends on weighting scheme and propensity score distribution

**R Package:** `PSweight` (comprehensive platform for various balancing weights)

**UI Location:** New tab "Propensity Score Methods" or integrate into existing two-group tabs

**Rationale:** This addresses the #1 methodological gap in current RWE sample size guidance. Essential for observational comparative effectiveness studies using propensity score methods.

**References:**
- Austin PC (2021). "Informing power and sample size calculations when using inverse probability of treatment weighting using the propensity score." Statistics in Medicine 40(27):6150-6163.
- Recent arXiv preprint (2501.11181): "Sample size and power calculations for causal inference of observational studies"

---

### 2. Expected Events Calculator for Cox Regression

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE

**Purpose:** Calculate required EVENTS, not just sample size, for time-to-event analyses

**Current Limitation:** Power (Survival) tab inputs overall event rate but doesn't explicitly show required number of events

**Inputs:**
- Desired power (%)
- Hazard ratio (HR)
- α level
- Proportion in treatment group (%)
- Anticipated follow-up duration (years/months)
- Expected event probability or rate
- Anticipated censoring pattern (administrative, loss to follow-up)

**Outputs:**
- Required number of EVENTS (Schoenfeld formula)
- Required sample size to observe those events given follow-up duration
- Expected calendar time to accrue events
- Tabular display: Sample size scenarios by follow-up duration
- Accrual period considerations

**Enhancement to Existing Tab:**
Modify "Power (Survival)" and "Sample Size (Survival)" tabs to show:
1. Primary result: Required EVENTS
2. Secondary result: Required N given expected event probability
3. Tertiary result: Expected accrual/follow-up time

**Statistical Method:**
- Schoenfeld (1983) formula: E = [(Z_α/2 + Z_β)² × (1 + 1/r)] / [p₁(1-p₁) × ln(HR)²]
  - Where E = required events, r = allocation ratio, p₁ = proportion in group 1

**Rationale:** In RWE studies, event-driven analyses are common (e.g., hospitalization, mortality, disease progression). Sample size alone is insufficient without knowing how many events will be observed.

---

### 3. Minimal Detectable Effect Size Calculator

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE

**Purpose:** Reverse calculator - given fixed sample size, what effect can we detect?

**Critical for RWE:** In secondary data use (EHR, claims), sample size is often FIXED by what exists in the database. Biostatisticians need to assess feasibility.

**Inputs:**
- Available sample size (fixed, cannot change)
- Baseline rate/mean (control group)
- Allocation ratio (if applicable)
- Desired power (%)
- α level

**Outputs:**
- Minimal detectable difference (absolute)
- Minimal detectable effect size:
  - Binary: Minimal detectable RR, OR, risk difference
  - Continuous: Minimal detectable Cohen's d, mean difference
  - Survival: Minimal detectable HR
- Practical interpretation: "Can detect RR ≥ 1.25 with 80% power"
- Feasibility assessment: "This sample can detect small/medium/large effects"
- Power curve showing power for range of effect sizes

**Available For:**
- All existing test types (modify each tab)
- Add toggle: "Calculate sample size" vs. "Calculate detectable effect"

**UI Implementation:**
Add radio button to each tab:
```
○ Calculate required sample size (given effect size)
● Calculate detectable effect (given sample size)
```

**Rationale:** Most critical for RWE where N is fixed. Helps determine study feasibility before investing resources in data extraction and analysis.

---

## TIER 2: Missing Data & Bias Adjustments

### 4. Missing Data Inflation Factor

**Priority:** ⭐⭐⭐⭐ SHOULD HAVE

**Purpose:** Adjust sample size to account for missing data in key variables

**Current Limitation:** Discontinuation adjustment only applies to single proportion tab

**Inputs:**
- Calculated sample size from primary analysis
- Expected missingness rate for exposure variable (%)
- Expected missingness rate for outcome variable (%)
- Expected missingness rate for key covariates (%)
- Missing data mechanism assumption:
  - MCAR (Missing Completely At Random) - minimal bias
  - MAR (Missing At Random) - bias controllable with observed data
  - MNAR (Missing Not At Random) - potential for substantial bias
- Planned analysis approach:
  - Complete case analysis
  - Multiple imputation (MI)
  - Inverse probability weighting (IPW)
  - Full information maximum likelihood (FIML)

**Outputs:**
- Inflated sample size to account for missing data
- Effective analysis sample size (completers)
- Multiple scenarios table:
  - Optimistic (10% missing)
  - Expected (user input)
  - Pessimistic (user input + 10%)
- Interpretation: "If 20% of outcome data are missing, need to recruit N=XXX to have YYY complete cases"
- Assumptions and limitations text

**Statistical Method:**
- Complete case: N_inflated = N_required / (1 - p_missing)
- MI: Less inflation needed, depends on imputation model strength
- IPW: May further inflate if weights are variable

**UI Location:**
- Option 1: Expandable "Advanced Options" section in each tab
- Option 2: Separate "Data Quality Adjustments" tab
- Option 3: Integrated into each calculation with checkbox "Account for missing data"

**Rationale:** RWE studies routinely have 10-30% missing data for key variables. Ignoring this leads to underpowered studies.

---

### 5. Sensitivity Analysis for Unmeasured Confounding

**Priority:** ⭐⭐⭐⭐ SHOULD HAVE

**Purpose:** E-value calculator for assessing robustness to unmeasured confounding

**Inputs:**
- Observed effect measure (RR, OR, HR) from study or pilot data
- Confidence interval bounds (lower, upper)
- Outcome type: binary, continuous, survival

**Outputs:**
- **E-value** for point estimate: minimum strength of unmeasured confounding (on RR scale) needed to explain away the observed effect
- **E-value** for CI bound: minimum strength to shift CI to include null
- Interpretation text:
  - "An unmeasured confounder would need to be associated with both treatment and outcome by a RR of X-fold each to explain away the effect"
  - "This is stronger/weaker than observed confounders [list examples]"
- Contextualization: Compare to known confounders' effects
- Protocol text for SAP sensitivity analysis section

**Statistical Method:**
- E-value formula (VanderWeele & Ding 2017):
  - For RR: E = RR + sqrt[RR × (RR - 1)]
  - For OR, HR: Convert to RR approximation first
- Bias plot showing required confounder associations

**R Package:** `EValue` package (VanderWeele)

**UI Location:**
- New tab "Sensitivity Analysis"
- Or add to existing tabs as expandable section
- Could be part of "Results interpretation" output

**Rationale:** FDA/EMA increasingly require sensitivity analyses for unmeasured confounding in RWE submissions. E-values are becoming standard in epidemiology and pharmacoepidemiology publications.

**References:**
- VanderWeele TJ, Ding P (2017). "Sensitivity Analysis in Observational Research: Introducing the E-Value." Annals of Internal Medicine 167(4):268-274.

---

## TIER 3: Advanced RWE Study Designs

### 6. Difference-in-Differences (DiD) Power Analysis

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Quasi-experimental designs with pre/post periods and control groups

**Use Cases:**
- Policy changes (e.g., drug approval, formulary changes)
- Natural experiments (e.g., state-level policy variations)
- Interrupted time series with comparison group

**Inputs:**
- Pre-intervention trend (slope)
- Expected policy/intervention effect (difference in slopes or levels)
- Number of pre-intervention time periods
- Number of post-intervention time periods
- Number of treated units/clusters
- Number of control units/clusters
- Within-cluster correlation (if clustered)
- Parallel trends assumption confidence

**Outputs:**
- Required number of clusters (if applicable)
- Power to detect interaction (group × time)
- Power curves by number of time periods
- Minimum detectable effect size
- Recommendations for pre-periods needed

**Statistical Method:**
- Two-way fixed effects model power
- Clustering adjustments if applicable
- Autocorrelation structure in time series

**R Packages:**
- `did` package (Callaway & Sant'Anna)
- `DIDmultiplegt` for multiple time periods
- Simulation-based power

**UI Location:** New tab "Quasi-Experimental Designs" > DiD sub-tab

**Rationale:** DiD is increasingly common in health policy RWE studies (drug approval impacts, coverage policy changes, Medicare Part D studies).

---

### 7. Interrupted Time Series (ITS) Power Analysis

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Single-group pre/post designs with multiple time points

**Use Cases:**
- Implementation studies
- Guideline changes
- Single-arm policy interventions
- Before-after studies with temporal controls

**Inputs:**
- Baseline trend slope
- Expected level change (immediate effect)
- Expected slope change (sustained effect)
- Number of pre-intervention observations
- Number of post-intervention observations
- Autocorrelation structure (AR1 coefficient)
- Seasonality considerations (if monthly/quarterly data)

**Outputs:**
- Power to detect level change
- Power to detect slope change
- Minimum detectable effect for both
- Recommendations on number of time points needed
- Sensitivity to autocorrelation assumptions

**Statistical Method:**
- Segmented regression power analysis
- Time series ARIMA adjustments
- Newey-West standard errors considerations

**R Package:**
- `rits` (randomization inference for ITS)
- Simulation-based approaches

**UI Location:** New tab "Quasi-Experimental Designs" > ITS sub-tab

**Rationale:** ITS is a strong quasi-experimental design for RWE when randomization is not feasible. Common in implementation science and policy evaluation.

---

### 8. Regression Discontinuity Design (RDD) Power Analysis

**Priority:** ⭐⭐ FUTURE

**Purpose:** Eligibility threshold studies (quasi-randomization at cutoff)

**Use Cases:**
- Age-based eligibility (e.g., Medicare at 65)
- Clinical threshold-based treatment (e.g., HbA1c ≥ 6.5%)
- Score-based interventions

**Inputs:**
- Bandwidth around threshold (range to include)
- Expected jump at cutoff (discontinuity size)
- Available sample near threshold
- Polynomial order for fitting (linear, quadratic)
- Fuzzy vs. sharp RDD

**Outputs:**
- Power to detect discontinuity
- Optimal bandwidth recommendations
- Required sample in bandwidth
- Sensitivity to bandwidth choice

**Statistical Method:**
- Local linear regression at discontinuity
- Robust standard errors
- Simulation-based power

**R Packages:**
- `rddtools`
- `rdrobust`

**UI Location:** New tab "Quasi-Experimental Designs" > RDD sub-tab

**Rationale:** RDD provides credible causal inference in absence of randomization, but less common than DiD/ITS. Lower priority but valuable for specialized use cases.

---

## TIER 4: Clustering & Hierarchical Data

### 9. Design Effect for Clustered Data

**Priority:** ⭐⭐⭐⭐ SHOULD HAVE

**Purpose:** Adjust sample size for clustering (patients within providers/hospitals/sites)

**Current Limitation:** App explicitly states clustering is not handled

**Inputs:**
- Unclustered sample size (from standard calculation)
- Average cluster size (m) - patients per provider
- Intraclass correlation coefficient (ICC)
  - Typical values table provided:
    - Behavioral outcomes: 0.01-0.05
    - Clinical outcomes: 0.01-0.10
    - Process measures: 0.10-0.30
- Number of clusters available (if fixed)
- Cluster size variation (equal vs. variable)

**Outputs:**
- **Design Effect (DE)** = 1 + (m - 1) × ICC
- Adjusted sample size = N_unclustered × DE
- Required number of clusters = Adjusted N / m
- Effective sample size (accounts for correlation)
- Sensitivity analysis:
  - Table showing DE for range of ICC values
  - Impact of cluster size on efficiency
- Practical interpretation: "Clustering within providers reduces effective sample by X%"

**Statistical Method:**
- Standard design effect formula (Donner & Klar)
- Coefficient of variation (CV) adjustment if cluster sizes vary
- Enhanced DE = 1 + [(m² × CV² + m) × ICC]

**Extensions:**
- Two-level clustering (patients in providers in hospitals)
- Varying ICCs by outcome type

**R Packages:**
- `clusterPower` - comprehensive clustering power functions
- `CRTSize` - cluster randomized trial sample size
- `iccCounts` - ICC for count outcomes

**UI Location:**
- Option 1: Checkbox on each tab "Data are clustered" → expands fields
- Option 2: Separate "Clustered Data Adjustment" tab
- Option 3: Post-calculation multiplier shown in results

**Rationale:** RWE data from EHRs/claims are inherently clustered (patients within providers within hospitals within regions). Ignoring clustering leads to overly optimistic sample sizes and inflated Type I error.

**Pedagogical Feature:**
- ICC slider with real-time DE calculation
- Visual: show how clustering "throws away" information
- Examples from literature by outcome type

---

### 10. Hierarchical/Multilevel Model Power Analysis

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Power for mixed models with random effects at multiple levels

**Use Cases:**
- Longitudinal studies (repeated measures nested in patients)
- Multi-site studies (patients in providers in sites)
- Cross-level interactions (site-level predictor × patient-level outcome)

**Inputs:**
- Level 1 variance (within-patient, σ²_within)
- Level 2 variance (between-patient, τ²_between)
- ICC = τ² / (τ² + σ²)
- Number of level 2 units (patients, clusters)
- Number of level 1 observations per level 2 unit (repeated measures)
- Fixed effect size of interest
- Random slopes (yes/no)
- Cross-level interaction effect size (if applicable)

**Outputs:**
- Power for fixed effects at level 1
- Power for fixed effects at level 2
- Power for cross-level interactions
- Required number of clusters and observations per cluster
- Trade-off curves: more clusters vs. more obs/cluster
- Optimal allocation recommendations

**Statistical Method:**
- Analytical formulas for balanced designs (Raudenbush & Liu 2000)
- Simulation-based for complex designs

**R Packages:**
- `powerlmm` - longitudinal mixed models
- `simr` - simulation-based power for mixed models (very flexible)
- `mlpwr` - multilevel power analysis

**UI Location:** New tab "Hierarchical Models"

**Complexity:** HIGH - requires understanding of variance partitioning

**Rationale:** Appropriate for longitudinal RWE studies and multi-level analyses. More complex than simple design effect but provides more nuanced power estimates.

---

## TIER 5: Multiple Comparisons & Subgroups

### 11. Multiple Testing Correction Calculator

**Priority:** ⭐⭐⭐⭐ SHOULD HAVE

**Purpose:** Adjust α or sample size for multiple comparisons

**Current Limitation:** App states multiple comparisons not handled

**Inputs:**
- Number of planned comparisons/endpoints (k)
  - Examples:
    - Multiple outcomes (primary + secondary)
    - Multiple subgroups
    - Multiple time points
    - Multiple treatment comparisons
- Correction method:
  - **Bonferroni**: α_adj = α / k (most conservative)
  - **Šidák**: α_adj = 1 - (1 - α)^(1/k)
  - **Holm**: Step-down procedure (less conservative)
  - **Hochberg**: Step-up procedure
  - **FDR - Benjamini-Hochberg**: Control false discovery rate (exploratory)
  - **Hommel**: More powerful than Holm
- Family-wise error rate (FWER) desired - typically 0.05
- Test correlation structure (if known):
  - Independent tests
  - Correlated tests (requires correlation matrix)

**Outputs:**
- Adjusted α levels for each test
- Adjusted sample size to maintain original power at adjusted α
- Sample size inflation factor
- Comparison table showing:
  - Unadjusted: α = 0.05, N = X
  - Bonferroni: α = 0.05/k, N = Y (% increase)
  - FDR: α_FDR = 0.05, N = Z (% increase)
- Decision tree: "For k tests, use method X"
- Interpretation text for protocols

**Educational Feature:**
- Slider for number of comparisons showing real-time impact
- Visual comparison of methods (plot of critical values)
- Recommendations based on study phase:
  - Confirmatory: Bonferroni, Holm
  - Exploratory: FDR

**Statistical Method:**
- Exact formulas for Bonferroni, Šidák
- Iterative calculation for Holm, Hochberg
- Sample size: re-run power calculation with adjusted α

**R Packages:**
- Base R: `p.adjust()` function
- `multcomp` for simultaneous inference

**UI Location:**
- Option 1: Post-calculation module (apply to existing result)
- Option 2: Checkbox "Adjust for multiple comparisons" on each tab
- Option 3: Separate "Multiple Testing" tab

**Rationale:** RWE studies often examine multiple subgroups, outcomes, or time points. Proper multiplicity adjustment is essential for controlling Type I error and is required by regulatory agencies.

---

### 12. Subgroup Analysis Power Calculator

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Power to detect heterogeneous treatment effects (HTE) and subgroup differences

**Use Cases:**
- Age subgroups (pediatric, adult, geriatric)
- Sex/gender differences
- Race/ethnicity subgroups
- Disease severity subgroups
- Prior medication use subgroups

**Inputs:**
- Overall sample size (total N)
- Number of subgroups (k)
- Subgroup prevalence (%) for each
  - Or equal allocation assumed
- Expected effect in subgroup 1 (e.g., RR = 1.5)
- Expected effect in subgroup 2 (e.g., RR = 1.0)
- Effect modification magnitude (difference or ratio of effects)
- α level for interaction test
- Multiple testing adjustment (yes/no)

**Outputs:**
- Power within each subgroup (stratified analysis power)
- Power for interaction test (subgroup × treatment)
- Minimum sample size in smallest subgroup
- Recommendations:
  - Adequate power for within-subgroup analysis? (yes/no)
  - Adequate power for interaction test? (yes/no)
- Warning if small subgroups: "Subgroup X has only N=YY, powered for large effects only"
- Effect size detectable in each subgroup

**Statistical Method:**
- Within-subgroup: standard power calculation with reduced N
- Interaction test: regression with product term (Brookes et al. 2004)
  - Power_interaction = f(N, p_subgroup, effect_difference, variance)
- Often requires 4× larger sample for interaction vs. main effect

**Visual Output:**
- Forest plot showing hypothetical effects by subgroup
- Power curves by subgroup size

**R Packages:**
- Standard `pwr` functions applied to subgroups
- `powerMediation` for complex interactions

**UI Location:** New tab "Subgroup Analysis"

**Rationale:** Subgroup analyses are common in RWE but often underpowered. Helps set realistic expectations and avoid spurious findings.

**Warning Message:**
"Caution: Subgroup analyses are exploratory and prone to false positives. Pre-specify subgroups and adjust for multiple comparisons. Interaction tests typically require 4× larger sample than main effect tests."

---

## TIER 6: Enhanced Visualization & Reporting

### 13. Interactive Power Curves

**Priority:** ⭐⭐⭐⭐⭐ MUST HAVE

**Purpose:** Visual exploration of design space and sensitivity analysis

**Current Limitation:** Static text output only, no visualizations

**Plots to Add:**

#### A. Power vs. Sample Size Curve
- X-axis: Sample size (range around calculated value)
- Y-axis: Power (0-100%)
- Vertical line at calculated N
- Horizontal line at target power
- Shaded region: acceptable power (80-90%)
- Interactive hover: "At N=500, power = 85%"

#### B. Power vs. Effect Size Curve
- X-axis: Effect size (RR, OR, HR, Cohen's d)
- Y-axis: Power
- Shows what effects are detectable with current N
- Reference lines for small/medium/large effects

#### C. Sample Size vs. Effect Size Curve
- X-axis: Effect size
- Y-axis: Required sample size
- Shows trade-off: smaller effects need larger N
- Target power line

#### D. Multi-Parameter Sensitivity Surface
- 3D plot or contour plot
- Axes: N, effect size, power
- Shows feasible design space

**Interactive Features:**
- Plotly interactive plots (zoom, pan, hover)
- Click on curve to update calculations
- Export plots as PNG/SVG
- Toggle log scale for large N ranges
- Multiple curves on same plot (sensitivity scenarios)

**Inputs:**
- Use current calculation as baseline
- Automatic range generation (50% to 200% of calculated value)
- User can adjust plot ranges

**R Packages:**
- `plotly` for interactivity
- `ggplot2` for static high-quality plots
- `ggiraph` for interactive ggplot

**UI Location:**
- New tab in main panel: "Visualizations"
- Appears after calculation
- Tabbed sub-panels for different plot types

**Export Options:**
- Download plot as PNG (for presentations)
- Download plot as SVG (for publications)
- Download underlying data as CSV

**Rationale:** Major UX improvement. Visual exploration helps understand sensitivity and communicate results to stakeholders. Industry-standard power analysis software (G*Power, PASS, nQuery) all provide interactive curves.

---

### 14. Sample Size Trade-off Dashboard

**Priority:** ⭐⭐⭐⭐ SHOULD HAVE

**Purpose:** Real-time multi-parameter exploration of design decisions

**Interactive Dashboard Components:**

#### Sliders (Real-time reactive updates):
1. **Power slider** (50-99%): Shows required N in real-time
2. **α slider** (0.01-0.10): Shows impact on required N
3. **Effect size slider**: Shows feasible detection with fixed N
4. **Allocation ratio slider** (1:1 to 1:5): Shows N1 and N2
5. **ICC slider** (if clustered): Shows design effect
6. **Missing data slider** (0-50%): Shows inflation

#### Dynamic Display:
- Gauge chart showing current power
- Number boxes showing required N (updates live)
- Cost calculator: N × cost_per_participant
- Timeline estimator: N / enrollment_rate = months
- Feasibility indicator: Green (achievable) / Yellow (challenging) / Red (infeasible)

#### Scenario Comparison Table:
| Scenario | Power | α | Effect | N Required | Cost | Timeline |
|----------|-------|---|--------|------------|------|----------|
| Conservative | 90% | 0.01 | RR=1.2 | 5000 | $500K | 24 mo |
| Standard | 80% | 0.05 | RR=1.3 | 2000 | $200K | 10 mo |
| Optimistic | 80% | 0.05 | RR=1.5 | 800 | $80K | 4 mo |

**Workflow:**
1. User performs initial calculation
2. Clicks "Explore Trade-offs" button
3. Dashboard opens with sliders initialized to calculated values
4. User adjusts sliders to see real-time impact
5. Can save multiple scenarios
6. Export comparison table

**R Packages:**
- `shiny` reactive programming
- `shinydashboard` or `bs4Dash` for dashboard layout
- `shinyWidgets` for enhanced sliders and gauges

**UI Location:**
- Option 1: New tab "Trade-off Explorer"
- Option 2: Modal dialog that pops up after calculation
- Option 3: Collapsible panel below results

**Rationale:** Helps users understand design flexibility and make informed decisions when constraints exist (budget, timeline, available database size). Facilitates stakeholder discussions about feasibility.

---

### 15. SAP/Protocol Text Generator (Enhanced)

**Priority:** ⭐⭐⭐⭐ SHOULD HAVE

**Purpose:** Generate publication-ready and regulatory-compliant methods text

**Current Feature:** Basic narrative text output

**Enhancements:**

#### A. Comprehensive Methods Section Template
```markdown
## Sample Size Justification

### Study Design
[Auto-populated based on selected tab]
- Design: [Two-group cohort comparison / Matched case-control / Single-arm / Survival analysis]
- Outcome: [Binary / Continuous / Time-to-event]
- Comparison: [Treatment vs. Control / Exposed vs. Unexposed]

### Statistical Hypotheses
- Null hypothesis (H₀): [Auto-generated based on test type]
- Alternative hypothesis (H₁): [Auto-generated]
- Test type: [Two-sided / One-sided]

### Assumptions
- Primary outcome: [User input]
- Expected rate/mean in control group: XX% [User input]
- Expected rate/mean in treatment group: YY% [Calculated or user input]
- Effect size: [RR = Z / OR = Z / HR = Z / Cohen's d = Z]
- Allocation ratio: [1:1 / 1:2 / etc.]
- Significance level (α): 0.05
- Target power (1-β): 80%

### Sample Size Calculation
Using [statistical test name] with the assumptions above, a total of N=[calculated]
participants (n₁=[X] in treatment group, n₂=[Y] in control group) will provide
[power]% power to detect a [effect description] at a two-sided significance level
of [α].

The calculation was performed using the [method citation] implemented in the
[R package] package in R version [X.X.X].

### Adjustments
[If applicable - auto-included based on user selections]
- Discontinuation/withdrawal: Assuming [X]% dropout, sample size inflated to N=[adjusted]
- Missing data: Assuming [X]% missingness in key variables, sample size inflated to N=[adjusted]
- Clustering: Design effect = [DE], accounting for ICC=[X], sample size inflated to N=[adjusted]
- Multiple comparisons: Using [Bonferroni/Holm/FDR], adjusted α=[X], sample size adjusted to N=[X]

### Sensitivity Analyses
[Optional - user can select]
- Power will range from X% to Y% if the true effect is [range]
- Minimum detectable effect with this sample is [effect]
- Sensitivity to unmeasured confounding (E-value): [calculated]

### References
[Auto-generated citations for methods used]
- Cohen J (1988). Statistical Power Analysis for the Behavioral Sciences.
- Schoenfeld DA (1983). Sample-size formula for the proportional-hazards regression model. Biometrics 39(2):499-503.
- [Additional citations based on methods selected]
```

#### B. Regulatory Language Templates

**FDA Submission:**
```
The sample size for this real-world evidence study was determined to ensure adequate
statistical power while accounting for the observational nature of the data. We used
[method] to calculate the required sample size, incorporating adjustments for [list
adjustments]. The sample size calculation assumptions were informed by [pilot data /
published literature / clinical expert input].
```

**EMA Submission:**
```
Sample size justification for this non-interventional post-authorization safety study
follows EMA guidance on registry-based studies. We calculated the minimum sample size
required to detect a relative risk of [X] with [Y]% power and [Z]% significance level...
```

#### C. Publication-Ready Abstract/Methods Text

Pre-formatted for journal submission:
- Word count optimized
- Standard statistical reporting format
- APA/ICMJE style
- Effect sizes with 95% CIs

#### D. Protocol Text for Different Audiences

Toggle between:
- **Technical** (for statisticians): Full formulas, assumptions, citations
- **Clinical** (for clinicians): Plain language, clinical interpretation
- **Regulatory** (for agencies): Compliance language, validation statements
- **Stakeholder** (for non-experts): Simplified explanations

**Export Formats:**
- Copy to clipboard (formatted)
- Download as .docx (with formatting)
- Download as .txt (plain text)
- Download as LaTeX (for academic papers)

**R Packages:**
- `officer` - create Word documents
- `flextable` - formatted tables for Word/HTML
- `kableExtra` - tables for PDF

**UI Location:**
- Expandable section in results: "Generate Protocol Text"
- Select template type
- Customize sections
- Preview before download

**Rationale:** Saves substantial time in protocol/SAP writing. Ensures consistent, accurate reporting. Reduces transcription errors. Provides proper citations and methodological rigor.

---

### 16. Comparison Table Enhancements

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Current Feature:** Save scenarios, download comparison CSV

**Enhancements:**

#### A. Side-by-Side Visualization Table

Instead of plain CSV, display interactive comparison table in app:

| Parameter | Scenario 1 | Scenario 2 | Scenario 3 | Difference |
|-----------|------------|------------|------------|------------|
| Power | 80% | 85% | 90% | ↑10% |
| N Required | 500 | 650 | 850 | ↑70% |
| Effect Size | RR=1.5 | RR=1.3 | RR=1.2 | ↓0.3 |
| Cost | $50K | $65K | $85K | ↑$35K |

**Features:**
- Highlight differences (color coding: green = better, red = worse)
- Sortable columns
- Add notes/labels to scenarios ("Conservative", "Standard", "Optimistic")
- Star "preferred" scenario

#### B. What-If Scenario Builder

Pre-populated sensitivity scenarios:
- "What if power increased to 90%?"
- "What if effect size is smaller (RR=1.2)?"
- "What if allocation ratio is 2:1?"
- "What if 20% data are missing?"

User clicks button → new scenario auto-calculated and added to table

#### C. Interpretation Assistant

Automated interpretation text:
```
Scenario Comparison Insights:
- Increasing power from 80% to 90% requires 170 additional participants (34% increase)
- If the true effect is RR=1.3 instead of RR=1.5, need 150 more participants
- Optimal scenario depends on budget constraints and feasibility
- Recommendation: Scenario 2 (Standard) balances power and resources
```

#### D. Visual Comparison Charts

- Bar chart: Sample size by scenario
- Line chart: Power vs. N across scenarios
- Radar chart: Multi-dimensional comparison (power, cost, timeline, feasibility)

**Export Options:**
- Download comparison as Excel (formatted, with charts)
- Download as PowerPoint slide (for presentations)
- Download as PDF report (formal comparison document)

**R Packages:**
- `DT` - interactive DataTables
- `reactable` - modern React-based tables
- `openxlsx` - Excel export with formatting

**UI Location:**
- Enhanced "Scenario Comparison" section in main panel
- Opens in modal or dedicated tab

**Rationale:** Facilitates sensitivity analysis and stakeholder decision-making. Helps answer "what-if" questions efficiently. Professional presentation for study planning meetings.

---

## TIER 7: Specialized Clinical Contexts

### 17. Rare Disease Power Calculator (Enhanced)

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Enhanced beyond current rare event detection for orphan drug development

**Current Feature:** Single proportion rare event analysis (Power tab 1)

**Enhancements:**

#### A. External Control Arms
- Historical control data integration
- Bayesian borrowing from external sources
- Power gain from incorporating external data
- Discounting factor for historical data quality

**Inputs:**
- Historical control sample size (N_historical)
- Historical control event rate
- Similarity assessment (0-1 scale)
- Borrowing strength (full, partial, none)
- Current trial sample size

**Outputs:**
- Effective sample size = N_current + (discount factor × N_historical)
- Power with vs. without borrowing
- Sensitivity to discounting assumptions

#### B. Adaptive Enrichment
- Sample size re-estimation for rare events
- Sequential monitoring plans
- Conditional power calculations
- Futility stopping rules

#### C. Registry-Based Studies
- Power for registry studies with varying follow-up
- Left-truncated enrollment considerations
- Prevalent vs. incident cohort designs

**R Packages:**
- `RBesT` - Bayesian historical borrowing
- `rpact` - adaptive designs

**Rationale:** Rare disease studies face unique challenges (small populations, ethical constraints, need for external data). Enhanced capabilities support orphan drug development.

---

### 18. Non-Inferiority Margin Justification

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Evidence-based selection of non-inferiority margins

**Current Feature:** User manually inputs margin

**Enhancement:** Guidance on margin selection

**Margin Selection Methods:**

#### A. Preservation of Effect (M1/M2 Method)
**FDA 2016 guidance standard approach**

Inputs:
- Historical effect of active control vs. placebo (from prior RCTs)
  - Point estimate (e.g., RR = 0.70 for control vs. placebo)
  - 95% CI for historical effect
- Fraction of effect to preserve (typically 50% of lower CI bound)
  - M1: Conservative margin (preserve 95% CI lower bound)
  - M2: Less conservative (preserve 50% of effect)

Outputs:
- Calculated M1 margin
- Calculated M2 margin (recommended)
- Interpretation: "Active control showed 30% risk reduction vs. placebo. Preserving 50% of lower CI bound (20%) yields M2 margin of 10%."
- Fixed margin on difference scale or relative scale

#### B. Clinical Significance Threshold
- Minimum clinically important difference (MCID)
- Survey of clinical experts
- Patient-centered outcomes research input

#### C. Regulatory Precedent
- Database of approved NI margins by indication
- Examples:
  - Anticoagulants: typically 2% absolute difference
  - Antibiotics: 10-15% cure rate difference
  - Antihypertensives: 5 mmHg SBP difference

**Visual Aid:**
- Diagram showing M1/M2 calculation
- Forest plot of historical control effect
- Margin relative to effect size

**Educational Content:**
- FDA guidance interpretation
- EMA guidance differences
- Common mistakes in margin selection

**References:**
- FDA (2016). Non-Inferiority Clinical Trials to Establish Effectiveness.
- ICH E10 guideline

**UI Location:**
- Enhanced "Non-Inferiority Testing" tab
- Expandable section "Margin Justification Tool"

**Rationale:** Margin selection is critical and often done incorrectly. Providing evidence-based guidance improves study quality and regulatory acceptance.

---

### 19. Equivalence Testing

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Two-sided equivalence tests (vs. one-sided non-inferiority)

**Use Cases:**
- Biosimilar development
- Generic drug approval (PK/PD studies)
- Comparability studies (formulation changes)
- Bridge studies (different populations)

**Equivalence vs. Non-Inferiority:**
- Non-inferiority: Test ≥ Reference (one-sided)
- Equivalence: Test ≈ Reference (two-sided)

**Inputs:**
- Lower equivalence margin (Δ_L) - typically negative
- Upper equivalence margin (Δ_U) - typically positive
  - Often symmetric: ±Δ
  - Asymmetric allowed for ratios
- Expected true difference (often 0)
- Reference value/rate
- Desired power
- α level (typically 0.05 for two one-sided tests = TOST)

**Outputs:**
- Required sample size for equivalence
- Sample size for each of the two one-sided tests (TOST)
- Power for both tails
- Comparison to non-inferiority sample size

**Statistical Method:**
- TOST: Two One-Sided Tests procedure
  - Test 1: H0: μT - μR ≤ Δ_L (lower bound)
  - Test 2: H0: μT - μR ≥ Δ_U (upper bound)
- Reject both nulls to conclude equivalence
- Sample size: maximum of two one-sided tests

**Applications by Outcome Type:**

A. **Binary Outcomes** (e.g., cure rate)
- Difference scale: ±5% equivalence margin
- Two-proportion TOST

B. **Continuous Outcomes** (e.g., bioequivalence)
- Ratio scale: 80-125% (0.80-1.25 on log scale)
- Crossover design considerations
- Two one-sided t-tests (TOST)

C. **Time-to-Event** (e.g., survival)
- HR equivalence margin: 0.75-1.33
- Log-rank TOST

**R Packages:**
- `TrialSize` - equivalence tests
- `PowerTOST` - bioequivalence (crossover designs)
- `equivalence` - various equivalence tests

**UI Location:**
- New tab "Equivalence Testing" (separate from Non-Inferiority tab)
- Or expand current Non-Inferiority tab to include both

**Visual Output:**
- Equivalence plot showing margins and expected difference
- Decision regions (equivalent, non-equivalent, inconclusive)

**Rationale:** Equivalence testing is standard for biosimilars and generic approval. Current app only handles one-sided non-inferiority.

---

## TIER 8: Data Quality Assessments

### 20. Precision-Based Sample Size

**Priority:** ⭐⭐⭐ NICE TO HAVE

**Purpose:** Alternative to hypothesis testing when goal is precise estimation

**Use Cases:**
- Descriptive studies (no comparison)
- Incidence/prevalence estimation
- Safety signal detection (no hypothesis)
- Real-world effectiveness (descriptive)
- Confidence interval width specification

**Philosophy:**
Many RWE studies are not hypothesis-testing but aim for precise effect estimation. Traditional power analysis doesn't apply—instead, focus on confidence interval width.

**Inputs:**
- Desired confidence interval width (w)
  - Example: "Want to estimate prevalence within ±2%"
- Confidence level (typically 95%)
- Expected parameter value (proportion, mean)
- Standard deviation (for continuous)

**Outputs:**
- Required sample size for desired precision
- Achieved confidence interval width for given N
- Table: N vs. CI width trade-off
- Comparison to power-based sample size (if applicable)

**Statistical Methods:**

#### A. Binary Outcomes (Proportion)
- Exact (Clopper-Pearson): Solve for N such that CI width = w
- Normal approximation: N = 4 × Z²_(α/2) × p(1-p) / w²
- Wilson score interval

#### B. Continuous Outcomes (Mean)
- N = 4 × Z²_(α/2) × σ² / w²
- Requires estimate of standard deviation

#### C. Rate Ratios
- Precision for RR, OR, HR estimation
- Log scale precision

**Visual Output:**
- Precision curve: CI width vs. N
- Demonstrates diminishing returns (large N → small precision gain)

**R Packages:**
- `presize` - precision-based sample size
- `MKmisc` - sample size for precision

**UI Location:** New tab "Precision-Based Design"

**Rationale:** Not all RWE studies test hypotheses. Many are descriptive or exploratory. Precision-based sample size is more appropriate for these designs and is increasingly recognized in methodology literature.

**Interpretation:**
"This study will estimate the incidence rate with 95% confidence interval of ±2 percentage points, allowing precise characterization of the rate in this population."

---

### 21. Measurement Error Impact Analysis

**Priority:** ⭐⭐ FUTURE

**Purpose:** Sensitivity analysis for misclassification in exposure or outcome

**Use Cases:**
- Exposure misclassification (e.g., medication use from claims may miss OTC)
- Outcome misclassification (e.g., diagnosis codes may miss true cases)
- Covariate measurement error
- Recall bias in self-reported data

**Inputs:**
- Expected true effect (RR, OR)
- Exposure misclassification:
  - Sensitivity (true positive rate) of exposure measurement
  - Specificity (true negative rate)
- Outcome misclassification:
  - Sensitivity of outcome measurement
  - Specificity
- Direction: Differential (worse in one group) vs. Non-differential
- Correlation between misclassification and truth

**Outputs:**
- Bias-adjusted effect estimate
- Expected observed effect given misclassification
- Required sample size inflation to overcome bias
- Quantitative bias analysis results
- Interpretation: "Observed RR of 1.3 may reflect true RR of 1.5 if exposure sensitivity is 80%"

**Statistical Methods:**
- Bias formulas for misclassification (Copeland et al. 1977)
- Quantitative bias analysis (Lash et al. 2009)
- Probabilistic bias analysis (Monte Carlo)

**R Packages:**
- `episensr` - Quantitative bias analysis for epidemiologic data
- `riskCommunicator` - misclassification functions

**UI Location:** New tab "Bias Analysis" or "Measurement Error"

**Complexity:** HIGH - requires deep understanding of bias mechanisms

**Rationale:** RWE data often have measurement error (claims diagnoses, medication use, lab values). Understanding impact on effect estimates and sample size is valuable for sensitivity analysis.

---

## Implementation Priority Recommendations

### MUST HAVE (Next Release - Q1 2026)
**Timeline:** 3-4 months development

1. ✅ **Variance Inflation Factor (VIF) Calculator** (#1)
   - Effort: Medium (2-3 weeks)
   - Impact: Very High
   - Complexity: Medium
   - Dependencies: Add `PSweight` package

2. ✅ **Minimal Detectable Effect Size Calculator** (#3)
   - Effort: Medium (2-3 weeks)
   - Impact: Very High
   - Complexity: Low
   - Dependencies: None (use existing functions in reverse)

3. ✅ **Interactive Power Curves** (#13)
   - Effort: Medium (2-3 weeks)
   - Impact: Very High (UX improvement)
   - Complexity: Medium
   - Dependencies: Add `plotly`, `ggplot2`

4. ✅ **Missing Data Adjustment** (#4)
   - Effort: Low (1-2 weeks)
   - Impact: High
   - Complexity: Low
   - Dependencies: None (simple inflation formulas)

**Total Estimated Effort:** 8-10 weeks (2.5 months)

---

### SHOULD HAVE (Within 6 months - Q2 2026)
**Timeline:** Add to subsequent releases

5. **Design Effect for Clustered Data** (#9)
   - Effort: Medium (2-3 weeks)
   - Impact: High
   - Complexity: Medium
   - Dependencies: Add `clusterPower`

6. **E-value Sensitivity Analysis** (#5)
   - Effort: Low (1 week)
   - Impact: High (regulatory value)
   - Complexity: Low
   - Dependencies: Add `EValue` package

7. **Multiple Testing Corrections** (#11)
   - Effort: Medium (2 weeks)
   - Impact: High
   - Complexity: Medium
   - Dependencies: Base R functions

8. **Enhanced Protocol Text Generator** (#15)
   - Effort: Medium (3-4 weeks)
   - Impact: High (user satisfaction)
   - Complexity: Medium
   - Dependencies: Add `officer`, `flextable`

9. **Sample Size Trade-off Dashboard** (#14)
   - Effort: High (4-5 weeks)
   - Impact: High (interactive exploration)
   - Complexity: High
   - Dependencies: Advanced Shiny reactivity

**Total Estimated Effort:** 12-15 weeks (3.5 months)

---

### NICE TO HAVE (Future Roadmap - Q3-Q4 2026)
**Timeline:** Consider for version 2.0

10. Enhanced Events Calculator for Survival (#2)
11. DiD Power Analysis (#6)
12. ITS Power Analysis (#7)
13. Subgroup Analysis Power (#12)
14. Rare Disease Enhancements (#17)
15. Non-Inferiority Margin Justification (#18)
16. Equivalence Testing (#19)
17. Precision-Based Sample Size (#20)
18. Comparison Table Enhancements (#16)
19. Hierarchical Model Power (#10)

---

### ADVANCED/SPECIALIZED (Version 3.0 - 2027)
**Timeline:** Requires significant research & development

20. Regression Discontinuity (#8)
21. Measurement Error Impact (#21)

---

## Technical Implementation Considerations

### Architecture Recommendations

**Current State:** Monolithic app.R (1,815 lines)

**Recommended Refactoring:**

```
power-analysis-tool/
├── app.R (main entry point, ~200 lines)
├── global.R (packages, constants, ~100 lines)
├── R/
│   ├── mod_basic_power.R (existing tabs 1-9)
│   ├── mod_propensity_score.R (NEW - VIF calculator)
│   ├── mod_minimal_detectable.R (NEW - reverse calculator)
│   ├── mod_missing_data.R (NEW - adjustments)
│   ├── mod_clustered_data.R (NEW - design effect)
│   ├── mod_visualizations.R (NEW - power curves)
│   ├── mod_trade_offs.R (NEW - dashboard)
│   ├── mod_sensitivity.R (NEW - E-values, bias analysis)
│   ├── mod_advanced_designs.R (FUTURE - DiD, ITS, RDD)
│   ├── utils_statistics.R (statistical functions)
│   ├── utils_helpers.R (UI helpers, formatting)
│   └── utils_export.R (CSV, PDF, Word generation)
├── tests/
│   ├── testthat/
│   │   ├── test-mod-propensity-score.R
│   │   ├── test-mod-minimal-detectable.R
│   │   ├── test-utils-statistics.R
│   │   └── ... (expand test coverage)
├── docs/
│   ├── ideas/
│   │   └── features.md (this document)
│   ├── vignettes/
│   │   ├── rwe-workflows.Rmd (NEW - use case examples)
│   │   ├── propensity-score-methods.Rmd (NEW)
│   │   └── clustered-data.Rmd (NEW)
│   └── ...
├── inst/
│   └── templates/
│       ├── protocol-text-templates/ (NEW)
│       ├── sap-text-templates/ (NEW)
│       └── regulatory-templates/ (NEW)
└── ...
```

### Package Dependencies to Add

**Tier 1 (MUST HAVE):**
```r
install.packages(c(
  "PSweight",      # Propensity score weighting VIF
  "plotly",        # Interactive visualizations
  "ggplot2",       # Static high-quality plots
  "ggiraph"        # Interactive ggplot
))
```

**Tier 2 (SHOULD HAVE):**
```r
install.packages(c(
  "EValue",        # Sensitivity to unmeasured confounding
  "clusterPower",  # Clustered designs
  "officer",       # Word document generation
  "flextable",     # Formatted tables
  "reactable"      # Modern interactive tables
))
```

**Tier 3 (NICE TO HAVE):**
```r
install.packages(c(
  "CRTSize",       # Cluster randomized trials
  "simr",          # Simulation-based power (mixed models)
  "presize",       # Precision-based sample size
  "TrialSize",     # Equivalence tests
  "PowerTOST"      # Bioequivalence
))
```

### Testing Strategy

**Current:** Basic unit tests for helper functions

**Recommended Expansion:**

1. **Statistical Accuracy Tests**
   - Validate against published examples from papers
   - Cross-check with commercial software (G*Power, PASS, nQuery)
   - Edge case handling (p=0, p=1, HR=1, etc.)

2. **Module Tests**
   - Test each new module independently
   - Test integration between modules
   - Snapshot tests for UI components

3. **Performance Tests**
   - Ensure calculations complete within 1 second
   - Test with extreme values (N=1,000,000)
   - Memory usage monitoring

4. **Regression Tests**
   - Lock current calculation results
   - Ensure updates don't change existing functionality

### Documentation Enhancements

1. **Vignettes** (R Markdown articles)
   - "Power Analysis for Real-World Evidence Studies"
   - "Propensity Score Methods and Sample Size"
   - "Handling Clustered Data in Observational Studies"
   - "Multiple Comparisons in RWE"

2. **Interactive Help**
   - Expand tooltip text for new features
   - Add "Learn More" links to methodology papers
   - Video tutorials (screen recordings)

3. **Example Gallery**
   - Case studies from published RWE studies
   - Step-by-step walkthroughs
   - Industry-specific examples (cardiovascular, oncology, rare disease)

### Deployment Considerations

**Current:** Docker container, port 3838

**Scalability:**
- Consider Shiny Server Pro or RStudio Connect for production
- Load balancing if high traffic expected
- Caching for computationally intensive calculations
- Database backend for saving user scenarios (optional)

---

## User Experience Enhancements

### Guided Workflows

Add "wizard" mode for beginners:

1. Study type selection: Descriptive / Comparative / Survival / Matched
2. Data source: RCT / Observational / Registry / Claims/EHR
3. Outcome type: Binary / Continuous / Time-to-event
4. Special considerations: Clustering? Missing data? Multiple comparisons?
5. → Directs to appropriate tab with pre-populated examples

### Help System Improvements

- Context-sensitive help (?) icons next to each input
- "Why does this matter?" explanations
- Link to methodology references
- Video demonstrations
- Live chat support (optional)

### Accessibility

- Screen reader compatible (WCAG 2.1 AA)
- Keyboard navigation
- Color-blind friendly palettes
- High contrast mode option

### Mobile Responsiveness

- Ensure all features work on tablets
- Simplified mobile view (may hide advanced features)
- Touch-friendly sliders and buttons

---

## Regulatory & Compliance Features

### Audit Trail

For validated environments:
- Log all calculations with timestamps
- User authentication (if deployed in corporate environment)
- Version tracking of app and package versions
- Export audit log

### Validation Documentation

- Software validation plan (IQ/OQ/PQ)
- Test cases mapped to requirements
- Traceability matrix
- Change control documentation

### Citations & References Manager

- Built-in reference list for methods used
- Auto-generate bibliography for methods section
- Export as BibTeX, RIS, EndNote

---

## Educational Features

### Learning Center

- Glossary of terms (ICC, VIF, design effect, etc.)
- Statistical concept explanations
- When to use which test
- Interpretation guidelines

### Warning System

Implement intelligent warnings:
- "Warning: Small sample size (N<30) may violate normality assumptions"
- "Caution: Very large effect size (RR>3) - consider if realistic"
- "Note: Unequal allocation reduces efficiency"
- "Recommendation: Consider clustering adjustment for EHR data"

### Best Practices Checker

Before finalizing design, run checklist:
- [ ] Power ≥ 80%?
- [ ] Effect size clinically meaningful?
- [ ] Adjusted for clustering?
- [ ] Adjusted for missing data?
- [ ] Multiple comparisons considered?
- [ ] Sensitivity analyses planned?

---

## Performance Optimization

### Computational Efficiency

- Cache repeated calculations
- Parallelize simulations (if added)
- Optimize iterative root-finding (current solve_n1_for_ratio)
- Debounce all reactive inputs (already implemented for preview)

### Load Time

- Lazy load large packages
- Minimize startup calculations
- Async loading for visualizations

---

## Community & Open Source

### GitHub Repository Enhancements

- Public issue tracker for feature requests
- Contribution guidelines
- Code of conduct
- Public roadmap (link to this document)

### User Community

- Discussion forum (GitHub Discussions)
- Share example analyses
- User-contributed templates
- Monthly newsletter with tips

### Academic Collaboration

- Collaborate with biostatistics departments
- Validation studies (compare to commercial software)
- Publish methodology paper describing tool
- Present at JSM, ENAR, PSI conferences

---

## Cost-Benefit Analysis

### Benefits of Implementation

**For Users:**
- Reduced protocol preparation time (save 5-10 hours per study)
- Increased methodological rigor
- Regulatory compliance
- Reduced risk of underpowered studies
- Better stakeholder communication

**For Organization:**
- Competitive differentiation
- Industry recognition
- Academic citations
- Attracting top biostatistics talent

### Development Costs

**Must Have Features (Tier 1):**
- Developer time: 8-10 weeks
- Testing/QA: 2-3 weeks
- Documentation: 1-2 weeks
- **Total: ~3 months, 1 developer**

**Should Have Features (Tier 2):**
- Developer time: 12-15 weeks
- Testing/QA: 3-4 weeks
- Documentation: 2 weeks
- **Total: ~5 months, 1 developer**

**ROI Calculation:**
- If tool saves 5 hours per analysis
- 20 analyses per year
- 100 hours saved per year per user
- At $150/hr biostatistician rate = $15,000 saved per user per year

---

## Risk Assessment

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Package dependency conflicts | Medium | High | Use renv, test thoroughly |
| Performance degradation | Low | Medium | Profile code, optimize |
| Breaking changes in updates | Medium | Medium | Pin package versions |
| Statistical errors in new methods | Low | Very High | Extensive validation, peer review |

### User Experience Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Too complex (feature bloat) | Medium | High | Progressive disclosure, wizard mode |
| Confusing new features | Medium | Medium | Comprehensive help, tutorials |
| Resistance to change | Low | Low | Maintain backward compatibility |

### Regulatory Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Calculation errors in submissions | Low | Very High | Validation testing, audit trail |
| Non-compliance with guidance | Low | High | Regular guidance review |
| Validation burden for users | Medium | Medium | Provide validation docs |

---

## Success Metrics

### Adoption Metrics
- Number of active users
- Number of calculations performed
- Feature usage frequency
- User retention rate

### Quality Metrics
- Test coverage (target: >90%)
- Bug report rate
- User satisfaction (NPS score)
- Time to complete analysis (target: <10 min)

### Impact Metrics
- Citations in protocols/SAPs
- Regulatory submissions using tool
- Publications citing tool
- Community contributions (GitHub stars, forks)

---

## Competitive Landscape

### Commercial Software Comparison

| Feature | Our Tool | G*Power | PASS | nQuery | SAS |
|---------|----------|---------|------|--------|-----|
| Cost | Free | Free | $$$ | $$$$ | $$$$ |
| RWE-specific | ✅ Yes | ❌ No | Partial | Partial | Yes |
| Propensity score | 🔜 Planned | ❌ No | ✅ Yes | ✅ Yes | ✅ Yes |
| Interactive viz | 🔜 Planned | ✅ Yes | ✅ Yes | ✅ Yes | ✅ Yes |
| Open source | ✅ Yes | Partial | ❌ No | ❌ No | ❌ No |
| Protocol text | ✅ Yes | ❌ No | ✅ Yes | ✅ Yes | Partial |

**Competitive Advantages:**
- Free and open source
- RWE-focused features
- Modern web interface
- Reproducible (R code)
- Extensible

**Gaps to Close:**
- Interactive visualizations (planned)
- Propensity score methods (planned)
- Hierarchical models (future)

---

## Conclusion

This feature enhancement roadmap provides a comprehensive path to making the Power Analysis Tool the premier solution for biostatisticians working with real-world evidence.

**Recommended Next Steps:**

1. **Prioritize Must Have features** (#1, 3, 4, 13) for next release
2. **Create detailed technical specifications** for each feature
3. **Develop implementation timeline** with milestones
4. **Allocate development resources** (1 developer, 3-4 months)
5. **Establish testing and validation plan**
6. **Plan user communication** (release notes, tutorials)
7. **Gather user feedback** throughout development

**Key Success Factors:**
- ✅ Focus on RWE-specific needs (our unique value proposition)
- ✅ Maintain simplicity despite added complexity (progressive disclosure)
- ✅ Ensure statistical rigor (validation, peer review)
- ✅ Provide excellent documentation (vignettes, examples)
- ✅ Build community (open source, collaboration)

**Vision Statement:**

*"To be the industry-standard power analysis tool for real-world evidence studies, providing biostatisticians with methodologically rigorous, user-friendly, and regulatory-compliant sample size calculations."*

---

## Document Control

**Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-24 | Claude Code | Initial comprehensive feature enhancement document based on RWE best practices research |

**Review and Approval:**

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead Biostatistician | | | |
| Software Architect | | | |
| Product Owner | | | |

**Next Review Date:** 2025-Q2

---

## References

### Key Methodology Papers

1. Austin PC (2021). "Informing power and sample size calculations when using inverse probability of treatment weighting using the propensity score." *Statistics in Medicine* 40(27):6150-6163.

2. Li F, Morgan KL, Zaslavsky AM (2025). "Sample size and power calculations for causal inference of observational studies." *arXiv* 2501.11181.

3. VanderWeele TJ, Ding P (2017). "Sensitivity Analysis in Observational Research: Introducing the E-Value." *Annals of Internal Medicine* 167(4):268-274.

4. Schoenfeld DA (1983). "Sample-size formula for the proportional-hazards regression model." *Biometrics* 39(2):499-503.

5. Donner A, Klar N (2000). *Design and Analysis of Cluster Randomization Trials in Health Research*. London: Arnold.

6. FDA (2016). *Non-Inferiority Clinical Trials to Establish Effectiveness: Guidance for Industry*.

7. FDA (2021). *Real-World Data: Assessing Electronic Health Records and Medical Claims Data To Support Regulatory Decision-Making for Drug and Biological Products*.

8. EMA (2021). *Guideline on registry-based studies*.

### R Package Documentation

- `pwr`: https://cran.r-project.org/package=pwr
- `PSweight`: https://cran.r-project.org/package=PSweight
- `EValue`: https://cran.r-project.org/package=EValue
- `clusterPower`: https://cran.r-project.org/package=clusterPower
- `powerSurvEpi`: https://cran.r-project.org/package=powerSurvEpi
- `epiR`: https://cran.r-project.org/package=epiR

### Additional Resources

- CIOMS Working Group XIII (2025). "Real-World Data and Real-World Evidence in Regulatory Decision Making."
- STROBE Statement: https://www.strobe-statement.org/
- CONSORT Statement: http://www.consort-statement.org/

---

**END OF DOCUMENT**
