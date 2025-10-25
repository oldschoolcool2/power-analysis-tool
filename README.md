# Power & Sample Size Calculator for Real-World Evidence Studies

A comprehensive R Shiny application for calculating statistical power and sample size requirements in pharmaceutical RWE research. Covers binary outcomes, continuous outcomes, survival analysis, matched designs, and non-inferiority trials.

## Core Features

### Study Design Types

1. **Single Proportion Analysis** (Rule of Three) - Rare event detection in post-marketing surveillance
2. **Two-Group Comparisons** - Cohort studies, case-control studies, comparative effectiveness
3. **Survival Analysis** (Cox Regression) - Time-to-event outcomes using Schoenfeld method
4. **Matched Case-Control** - Propensity score matching, traditional matching designs
5. **Continuous Outcomes** (t-tests) - Lab values, biomarkers, QoL scores
6. **Non-Inferiority Testing** - Generic approval, biosimilar studies

### Key Capabilities

- **Adjustable parameters**: Sample sizes, event rates, effect sizes, significance levels, power targets
- **Effect measures**: Risk Difference, Relative Risk, Odds Ratio, Hazard Ratio, Cohen's d
- **Export options**: CSV (all analyses), PDF (single proportion only)
- **Scenario comparison**: Save and compare multiple designs side-by-side
- **Input validation**: Comprehensive error checking with clear feedback
- **Help system**: Collapsible accordion panels with methodology and examples
- **Example buttons**: Pre-filled realistic pharmaceutical RWE scenarios
- **Reset functionality**: Quick restore to defaults

### Modern User Interface

This application features an enterprise-grade, accessible user interface:

- **Hierarchical Navigation**: Logical sidebar with 6 grouped analysis sections replacing traditional horizontal tabs
- **Responsive Design**: Fully optimized for desktop, tablet, and mobile devices (≥320px width)
- **Dark Mode**: Toggle between light and dark themes with keyboard shortcut (Ctrl/Cmd+Shift+D)
- **Accessibility**: WCAG 2.1 Level AA compliant with keyboard navigation and screen reader support
- **Professional Aesthetics**: Teal/slate color palette with Inter typography and semantic design tokens
- **Touch-Optimized**: All interactive elements ≥44px on mobile for comfortable tapping
- **Print Support**: Clean print layout with expanded accordions and optimized typography

**Design System**: Built on 363 CSS custom properties with 9-level color scales, 8px-based spacing system, and consistent shadows, borders, and transitions. See `www/css/design-tokens.css` for full variable reference.

---

## Quick Start

### Running with Docker (Recommended)

```bash
docker build -t power-analysis-tool .
docker-compose up
```

Access at `http://localhost:3838`

### Running Locally

**Prerequisites:** R ≥ 4.2.0 (recommended 4.4.0)

```r
install.packages(c("shiny", "bslib", "shinyBS", "pwr", "binom",
                   "kableExtra", "tinytex", "powerSurvEpi", "epiR"))
shiny::runApp("app.R")
```

---

## Usage Examples

### Example 1: Single Proportion Power
**Scenario:** 500 participants, 1 in 200 adverse event rate, 10% discontinuation

1. Navigate to **"Power (Single)"** tab
2. Enter: Sample Size = 500, Event Frequency = 200, Withdrawal = 10%
3. Click **Calculate**
4. Result: ~91.8% power to detect at least one event

### Example 2: Two-Group Sample Size
**Scenario:** Comparing 15% vs. 10% event rates, need 80% power

1. Navigate to **"Sample Size (Two-Group)"** tab
2. Enter: Power = 80%, Event Rate Group 1 = 15%, Event Rate Group 2 = 10%
3. Click **Calculate**
4. Result: n₁=303, n₂=303, Total N=606

### Example 3: Continuous Outcomes
**Scenario:** Comparing mean HbA1c between two drugs, Cohen's d=0.5

1. Navigate to **"Power (Continuous)"** tab
2. Enter: n₁=150, n₂=150, Cohen's d = 0.5
3. Click **Calculate**
4. Result: ~81.8% power to detect difference

### Example 4: Non-Inferiority
**Scenario:** Generic vs. branded drug, 5% non-inferiority margin

1. Navigate to **"Non-Inferiority"** tab
2. Enter: Test Rate = 12%, Reference Rate = 10%, Margin = 5%, Power = 80%
3. Click **Calculate**
4. Result: Required sample sizes to demonstrate non-inferiority

---

## Statistical Methods

| Analysis Type | Method | R Function | Use Case |
|--------------|--------|------------|----------|
| Single Proportion | Binomial test, Cohen's h | `pwr::pwr.p.test()` | Rare adverse events, safety |
| Two-Group Proportions | Two-proportion Z-test | `pwr::pwr.2p2n.test()` | Cohort studies, RCTs |
| Survival Analysis | Cox regression (Schoenfeld) | `powerSurvEpi::powerEpi()` | Time-to-event outcomes |
| Matched Case-Control | McNemar-based | `epiR::epi.sscc()` | Propensity score matching |
| Continuous Outcomes | Two-sample t-test | `pwr::pwr.t2n.test()` | Lab values, QoL scores |
| Non-Inferiority | One-sided proportion test | `pwr::pwr.2p.test()` | Generic approval |

### Effect Size Interpretations

- **Cohen's d** (Continuous): Small=0.2, Medium=0.5, Large=0.8
- **Hazard Ratio**: HR<1 protective, HR>1 increased risk
- **Odds Ratio**: OR<1 protective, OR>1 risk factor
- **Relative Risk**: Directly interpretable as fold-change in risk

---

## Version History

### Version 5.0 - Continuous Outcomes and Equivalence (Current)

**KEY FEATURES:**
1. ✅ **Continuous Outcomes (t-tests)** - Two new tabs
   - Power calculation for continuous endpoints
   - Sample size calculation with unequal allocation
   - Cohen's d effect sizes (BMI, blood pressure, lab values, QoL)
   - Examples: HbA1c comparison, cholesterol reduction

2. ✅ **Non-Inferiority Testing** - One new tab
   - Sample size for generic/biosimilar approval
   - Clinically acceptable margin specification
   - Regulatory-compliant (FDA/EMA 2024 guidance)
   - One-sided α=0.025 standard

3. ✅ **Enhanced Documentation**
   - Help panels for continuous outcomes and non-inferiority
   - Cohen's d interpretation guide
   - Regulatory context for non-inferiority margin selection
   - Real-world pharmaceutical examples

4. ✅ **Complete Integration**
   - Example and reset buttons for all new tabs
   - Input validation (n≥2, d>0, valid margins)
   - CSV export for all new analysis types
   - Professional copy-paste-ready results text

**IMPROVEMENTS:**
- Expanded coverage to continuous endpoints (previously binary only)
- Added non-inferiority designs for regulatory submissions
- Comprehensive help system for advanced methods
- All calculations use existing `pwr` package (no new dependencies)

### Version 4.0 - Professional Polish
- Modern bslib theme with Bootstrap 5
- Mobile-responsive design
- Example and reset buttons (all 7 tabs)
- Collapsible educational accordion panels
- FDA/EMA regulatory guidance links
- Infrastructure: R 4.4.0, renv support

### Version 3.0 - UI/UX Modernization
- Survival analysis (Cox regression)
- Matched case-control studies
- Extended CSV export
- Scenario comparison

### Version 2.0 - Advanced Statistical Features
- Two-group proportion comparisons
- Adjustable significance level (α)
- Input validation and tooltips
- CSV export
- Effect measure calculations (RR, OR, RD)

---

## Regulatory & Best Practices

### FDA/EMA Guidance (2024)
- [FDA Real-World Evidence Framework](https://www.fda.gov/science-research/science-and-research-special-topics/real-world-evidence)
- [FDA Guidance on RWD from EHRs and Claims](https://www.fda.gov/regulatory-information/search-fda-guidance-documents/real-world-data-assessing-electronic-health-records-and-medical-claims-data-support-regulatory)
- [EMA Real World Evidence Framework](https://www.ema.europa.eu/en/about-us/how-we-work/big-data/real-world-evidence)

### Power Targets
- **80% power:** Minimum acceptable for most studies
- **90% power:** Preferred for pivotal/confirmatory studies
- **<70% power:** Generally inadequate

### Significance Levels
- **α = 0.05:** Standard for most studies (two-sided)
- **α = 0.01:** Conservative, multiple testing
- **α = 0.025:** Standard for non-inferiority (one-sided)

---

## Limitations

This calculator does **NOT** handle:
- Clustering (use design effect adjustments separately)
- Multiple comparisons (apply Bonferroni/FDR corrections separately)
- Non-inferiority for continuous outcomes (use equivalence tests)
- Competing risks in survival analysis
- Repeated measures / longitudinal designs
- Complex stratification beyond matching

---

## Technical Stack

- **R:** 4.4.0
- **Framework:** Shiny with bslib (Bootstrap 5)
- **Packages:** pwr, powerSurvEpi, epiR, binom, shinyBS, kableExtra, tinytex
- **Deployment:** Docker + docker-compose
- **Version Control:** renv for reproducibility

### File Structure
```
.
├── app.R                   # Main application (1815 lines)
├── analysis-report.Rmd     # PDF export template
├── Dockerfile              # Container configuration (R 4.4.0)
├── docker-compose.yml      # Local development
├── README.md               # This file (user documentation)
├── tests/                  # Test suite
│   └── testthat/
│       └── test-power-analysis.R
├── renv/                   # Package management (renv)
│   └── renv.lock           # Package versions
└── docs/                   # All developer & project documentation
    ├── README.md           # Documentation index
    ├── development/        # Developer guides
    │   ├── CLAUDE.md       # Comprehensive dev guide (Diataxis)
    │   ├── CONTRIBUTING.md # Contribution guidelines
    │   └── CODE_QUALITY.md # Code quality standards
    └── reports/            # Historical reports
        ├── enhancements/   # Feature implementation reports
        └── quality/        # Code quality audits
```

---

## References

1. Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all right? Interpreting zero numerators. *JAMA*. 1983;249(13):1743-1745.
2. Cohen J. *Statistical Power Analysis for the Behavioral Sciences*. 2nd ed. Routledge; 1988.
3. Schoenfeld DA. Sample-size formula for the proportional-hazards regression model. *Biometrics*. 1983;39(2):499-503.
4. Lachin JM. Introduction to sample size determination and power analysis for clinical trials. *Control Clin Trials*. 1981;2(2):93-113.
5. FDA. Considerations for the Use of Real-World Data and Real-World Evidence to Support Regulatory Decision-Making. Draft Guidance. 2024.

---

## Documentation

### For End Users
This README provides all information needed to use the application.

### For Developers & Contributors
All developer documentation is organized in the `docs/` directory:

- **[Documentation Index](docs/README.md)** - Complete documentation map
- **[Developer Guide](docs/development/CLAUDE.md)** - Comprehensive guide (tutorials, how-tos, reference, architecture)
- **[Contributing Guidelines](docs/development/CONTRIBUTING.md)** - How to contribute
- **[Code Quality Standards](docs/development/CODE_QUALITY.md)** - Coding standards and tools

### Quick Links
- 📚 [Get started with development](docs/development/CLAUDE.md#getting-started-tutorials)
- 🛠️ [Submit a pull request](docs/development/CONTRIBUTING.md#pull-request-process)
- 📊 [View enhancement history](docs/reports/enhancements/)
- 🔍 [View quality reports](docs/reports/quality/)

---

## Support & Contributing

### Reporting Issues
- Include steps to reproduce
- Expected vs. actual behavior
- Screenshots if applicable
- R version and package versions

See [Contributing Guidelines](docs/development/CONTRIBUTING.md) for detailed instructions.

### Feature Requests
All major feature categories now implemented:
- ✅ Binary outcomes
- ✅ Continuous outcomes
- ✅ Survival analysis
- ✅ Matched designs
- ✅ Non-inferiority
- ✅ Modern UI/UX
- ✅ Documentation & help

Potential future enhancements:
- Equivalence testing (two-sided non-inferiority)
- Clustered/multilevel designs
- Multiple comparison adjustments
- Sample size re-estimation
- ANOVA power calculations

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

**Current Version:** 5.0 (Continuous Outcomes and Equivalence)
**Last Updated:** 2025
