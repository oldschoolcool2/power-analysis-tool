# Power & Sample Size Calculator for Real-World Evidence Studies

A comprehensive R Shiny application for calculating statistical power and sample size requirements in epidemiological and pharmaceutical research, with enhanced support for real-world evidence (RWE) applications.

## Overview

This tool provides power and sample size calculations for:
- **Single proportion analyses** (Rule of Three) - for rare event detection in post-marketing surveillance
- **Two-group comparisons** - for cohort studies, case-control studies, and comparative effectiveness research
- **Survival analysis** - for time-to-event outcomes using Cox regression
- **Matched case-control studies** - accounting for matched pairs and correlation

Developed for epidemiologists and non-statisticians conducting pharmaceutical RWE research and protocol development.

---

## Features

### Core Functionality

#### 1. Single Proportion Analysis (Rule of Three)
Based on Hanley & Lippman-Hand (1983), calculates power or sample size for detecting rare adverse events.

**Use cases:**
- Post-marketing surveillance (PMS) studies
- Safety signal detection
- Phase II/III trial safety assessment

**Tabs:**
- **Power (Single)**: Calculate statistical power given available sample size
- **Sample Size (Single)**: Calculate required sample size to achieve desired power

#### 2. Two-Group Comparisons (NEW!)
Compare event rates between two independent groups (e.g., exposed vs. unexposed, treatment vs. control).

**Use cases:**
- Cohort studies (exposed vs. unexposed)
- Case-control studies
- Comparative effectiveness research
- Observational RWE studies

**Tabs:**
- **Power (Two-Group)**: Calculate power given sample sizes for both groups
- **Sample Size (Two-Group)**: Calculate required sample sizes to achieve desired power

**Automatically calculates effect measures:**
- Risk Difference (RD)
- Relative Risk (RR)
- Odds Ratio (OR)

#### 3. Survival Analysis (TIER 2 - NEW!)
Calculate power and sample size for time-to-event outcomes using Cox proportional hazards regression.

**Use cases:**
- Time to hospitalization
- Time to disease progression
- Time to treatment discontinuation
- Overall survival analysis
- Any time-to-event endpoint in RWE

**Tabs:**
- **Power (Survival)**: Calculate power given total sample size and hazard ratio
- **Sample Size (Survival)**: Calculate required sample size for detecting a hazard ratio

**Method**: Schoenfeld (1983) formula implemented via powerSurvEpi package

**Inputs:**
- Hazard ratio (HR)
- Proportion exposed/treated
- Overall event rate during follow-up
- Significance level

#### 4. Matched Case-Control Studies (TIER 2 - NEW!)
Sample size calculations for matched study designs including propensity score matching.

**Use cases:**
- Propensity score matched cohorts
- Traditional case-control matching (e.g., age, sex)
- Matched retrospective studies
- Nested case-control designs

**Features:**
- Accounts for correlation between matched pairs
- Supports 1:1, 1:2, 1:3, etc. matching ratios
- Calculates required cases and controls

**Method**: epiR package implementation for matched designs

### Enhanced Features (TIER 1)

#### Adjustable Significance Level (α)
- Previously fixed at 0.05
- Now adjustable from 0.01 to 0.10
- Allows for more conservative tests or specific regulatory requirements

#### Input Validation & Help System
- **Tooltips**: Hover over any input to see explanations
- **Error checking**: Validates all inputs before calculation
- **User-friendly messages**: Clear feedback when invalid inputs are provided

#### Export Capabilities
- **CSV Export**: Download results in machine-readable format
  - All input parameters
  - Calculated results
  - Effect measures (for two-group analyses)
  - Timestamped for record-keeping
- **PDF Export**: Original experimental PDF report (single proportion only)

#### Scenario Comparison
- **Save multiple scenarios** for side-by-side comparison
- Compare different:
  - Sample sizes
  - Event rates
  - Power levels
  - Study designs
- **Export comparison table** as CSV for documentation

---

## Quick Start

### Running Locally

#### Prerequisites
- R (≥ 3.6.1)
- Required packages: `shiny`, `shinythemes`, `shinyBS`, `pwr`, `binom`, `kableExtra`, `tinytex`, `powerSurvEpi`, `epiR`

#### Installation
```r
# Install required packages
install.packages(c("shiny", "shinythemes", "shinyBS", "pwr", "binom",
                   "kableExtra", "tinytex", "powerSurvEpi", "epiR"))

# Run the app
shiny::runApp("path/to/app.R")
```

### Running with Docker

```bash
# Build the image
docker build -t power-analysis-tool .

# Run the container
docker-compose up
```

Access at `http://localhost:3838`

---

## Usage Guide

### Example 1: Single Proportion Power Calculation

**Scenario:** You have 500 participants available and expect an adverse event rate of 1 in 200. What power do you have to detect at least one event?

**Steps:**
1. Navigate to **"Power (Single)"** tab
2. Enter:
   - Available Sample Size: `500`
   - Event Frequency: `200` (means 1 in 200)
   - Withdrawal Rate: `10%` (optional)
   - Significance Level: `0.05`
3. Click **Calculate**
4. Review results and download CSV/PDF

**Result interpretation:** The app will show your statistical power (e.g., 91.8%) and provide copy-paste-ready text for your protocol.

---

### Example 2: Two-Group Sample Size Calculation

**Scenario:** You're designing a cohort study comparing cardiovascular event rates in exposed (10%) vs. unexposed (5%) groups. You want 80% power to detect this difference.

**Steps:**
1. Navigate to **"Sample Size (Two-Group)"** tab
2. Enter:
   - Desired Power: `80%`
   - Event Rate Group 1 (exposed): `10%`
   - Event Rate Group 2 (control): `5%`
   - Allocation Ratio: `1` (equal groups)
   - Significance Level: `0.05`
   - Test Type: `Two-sided`
3. Click **Calculate**
4. Review required sample sizes (e.g., n1=385, n2=385, total=770)
5. Download results as CSV

**Effect measures shown:**
- Risk Difference: 5 percentage points
- Relative Risk: 2.0
- Odds Ratio: 2.11

---

### Example 3: Scenario Comparison

**Scenario:** You want to compare power under different sample size assumptions.

**Steps:**
1. Run first analysis (e.g., n=500, event rate 1 in 200)
2. Click **"Save Current Scenario"**
3. Modify inputs (e.g., change n=750)
4. Click **Calculate** again
5. Click **"Save Current Scenario"** again
6. View comparison table at bottom of page
7. Click **"Download Scenario Comparison (CSV)"** to export

---

## Statistical Methods

### Single Proportion Tests
- **Method**: One-proportion Z-test using binomial distribution
- **Effect size**: Cohen's h via arcsine transformation: `ES.h(p1, p0)` where p0=0
- **Confidence intervals**: Exact Clopper-Pearson binomial method
- **R function**: `pwr::pwr.p.test()`
- **Reference**: Hanley & Lippman-Hand (1983)

### Two-Group Proportion Tests
- **Method**: Two-proportion Z-test
- **Effect size**: Cohen's h: `ES.h(p1, p2)`
- **R functions**:
  - `pwr::pwr.2p.test()` for equal n
  - `pwr::pwr.2p2n.test()` for unequal n
- **Test types**: Two-sided or one-sided (greater)

### Assumptions
- Binary outcomes (event yes/no)
- Independent observations
- Fixed sample sizes
- Known or assumed event rates

---

## Best Practices for Real-World Evidence

### Study Design Considerations

1. **Event Rate Estimation**
   - Use published literature or pilot data
   - Consider variation across subpopulations
   - Plan sensitivity analyses for uncertainty

2. **Sample Size Inflation**
   - Account for:
     - Withdrawal/discontinuation (built into app)
     - Incomplete data/missing outcomes
     - Exclusion criteria applied during analysis
     - Propensity score matching (reduces effective sample size)

3. **Significance Level Selection**
   - α = 0.05: Standard for most epidemiological studies
   - α = 0.01: More conservative, reduces Type I error
   - α = 0.10: Exploratory analyses or hypothesis generation

4. **Power Target**
   - 80%: Minimum acceptable for most studies
   - 90%: Preferred for confirmatory studies
   - Higher power: Needed when detecting small effects or rare events

### Regulatory Considerations

- **FDA/EMA RWE Guidance (2024)**: Emphasizes proper sample size justification
- **STROBE Guidelines**: Recommend reporting sample size rationale for observational studies
- **Documentation**: Use CSV/PDF export for regulatory submissions

### Limitations

This calculator does NOT account for:
- Clustering (use mixed models or design effect adjustments)
- Multiple comparisons (requires Bonferroni or FDR correction)
- Continuous outcomes (use t-test or ANOVA power calculators)
- Non-inferiority/equivalence designs
- Competing risks in survival analysis
- Complex stratification beyond matching

---

## Technical Details

### Dependencies
- **R**: ≥ 3.6.1
- **Shiny**: Web application framework
- **pwr**: Power analysis functions for proportion tests
- **powerSurvEpi**: Survival analysis power calculations (Schoenfeld method)
- **epiR**: Epidemiological statistics including matched case-control designs
- **binom**: Exact binomial confidence intervals
- **shinyBS**: Bootstrap tooltips and popovers
- **kableExtra**: Table formatting (PDF export)
- **tinytex**: LaTeX support (PDF export)

### File Structure
```text
.
├── app.R                 # Main Shiny application
├── analysis-report.Rmd   # R Markdown template for PDF export
├── Dockerfile            # Container configuration
├── docker-compose.yml    # Local development setup
├── ci.config.yml         # AWS ECS deployment configuration
└── README.md             # This file
```

### Performance
- Calculations: Instantaneous (<100ms)
- PDF generation: 2-5 seconds (depends on LaTeX installation)
- Concurrent users: Supports 50+ simultaneous users (Docker deployment)

---

## Changes in This Release

### Version 3.0 - Tier 2 Enhancements (Current)

**NEW TIER 2 FEATURES:**
1. ✅ **Survival Analysis** - Cox regression power/sample size calculations
   - Power calculation given sample size and hazard ratio
   - Sample size calculation for target power
   - Schoenfeld (1983) method via powerSurvEpi
   - Interactive power curves
2. ✅ **Matched Case-Control Studies** - Sample size for matched designs
   - Accounts for correlation in matched pairs
   - Flexible matching ratios (1:1, 1:2, 1:3, etc.)
   - Propensity score matching support
3. ✅ **Extended CSV Export** - All analysis types now export to CSV
4. ✅ **Extended Scenario Comparison** - Supports all new analysis types

**TIER 1 FEATURES (Version 2.0):**
1. ✅ Two-group proportion comparisons (cohort/case-control studies)
2. ✅ Adjustable significance level (α)
3. ✅ Input validation with helpful error messages
4. ✅ Tooltips explaining every input
5. ✅ CSV export for all analyses
6. ✅ Scenario comparison feature
7. ✅ Effect measure calculations (RR, OR, RD)
8. ✅ One-sided vs two-sided test options
9. ✅ Unequal allocation ratio support

**IMPROVEMENTS:**
- Comprehensive RWE study design support
- Enhanced statistical methods for modern epidemiology
- FDA/EMA 2024 RWE guidance alignment
- Expanded documentation with survival analysis examples
- Updated package dependencies (powerSurvEpi, epiR)

**BACKWARD COMPATIBILITY:**
- All original single-proportion features preserved
- All Version 2.0 two-group features preserved
- Existing workflows unchanged
- PDF export still available (single-proportion only)

---

## References

1. **Hanley JA, Lippman-Hand A.** (1983). If nothing goes wrong, is everything all right? Interpreting zero numerators. *JAMA*, 249(13), 1743-1745.

2. **Cohen J.** (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Routledge.

3. **Schoenfeld DA.** (1983). Sample-size formula for the proportional-hazards regression model. *Biometrics*, 39(2), 499-503.

4. **FDA.** (2024). Considerations for the Use of Real-World Data and Real-World Evidence to Support Regulatory Decision-Making for Drug and Biological Products. Draft Guidance.

5. **von Elm E, et al.** (2007). The Strengthening the Reporting of Observational Studies in Epidemiology (STROBE) statement. *The Lancet*, 370(9596), 1453-1457.

---

## Support & Contributing

### Reporting Issues
- GitHub Issues: [Create an issue](../../issues)
- Include:
  - Steps to reproduce
  - Expected vs. actual behavior
  - Screenshots if applicable
  - R version and package versions

### Feature Requests
Suggestions for future enhancements (Tier 3):
- ✅ ~~Survival analysis (Cox regression)~~ - COMPLETED in v3.0
- ✅ ~~Matched study designs~~ - COMPLETED in v3.0
- Stratified analyses
- Multiple comparison adjustments
- Sample size re-estimation (adaptive designs)
- Non-inferiority/equivalence designs
- Propensity score weighting (IPTW) adjustments

---

## License

Open source for pharmaceutical RWE research

---

## Acknowledgments

Enhanced for real-world evidence applications based on:
- 2024 FDA/EMA guidance on RWE
- STROBE reporting guidelines for observational studies
- Contemporary epidemiological research best practices
- User feedback from pharmaceutical epidemiologists
