# PowerAnalysisTool 5.0.0

## Initial CRAN Release

This is the first CRAN submission of PowerAnalysisTool, a comprehensive Shiny application for statistical power analysis, sample size calculation, and minimal detectable effect estimation designed specifically for real-world evidence (RWE) and observational study design.

### Major Features

#### Core Analysis Types

* **Single Proportion Tests**
  - Sample size calculation for single proportions using Cohen's arcsine transformation
  - Power analysis for hypothesis testing of single proportions
  - Confidence interval calculations using exact methods (Clopper-Pearson)

* **Two-Group Comparisons**
  - Binary outcomes (two-proportion z-test)
  - Continuous outcomes (independent t-tests)
  - Support for equal and unequal sample sizes
  - Effect size calculations (Cohen's h, Cohen's d)

* **Survival Analysis**
  - Cox proportional hazards models
  - Time-to-event sample size calculations (Schoenfeld method)
  - Hazard ratio estimation
  - Event calculator for study planning

* **Matched Case-Control Studies**
  - Sample size for matched pairs (McNemar's test)
  - Discordant pairs calculations
  - Odds ratio-based designs

* **Continuous Outcomes**
  - Independent t-tests (equal and unequal variances)
  - Effect size interpretation (Cohen's d)
  - Mean difference calculations

#### Advanced Statistical Features

* **Survival Non-Inferiority and Equivalence Testing** (NEW)
  - Non-inferiority margin calculations for time-to-event outcomes
  - Equivalence testing for survival data
  - Sample size, power, and minimal detectable effect calculations
  - Hazard ratio margin interpretation

* **Propensity Score Adjustments** (NEW)
  - Sample size calculations incorporating propensity score methods
  - Implementation of Li et al. (2025) cutting-edge methodology
  - Bhattacharyya coefficient for covariate overlap assessment
  - Distribution parameter estimation for propensity scores
  - Sensitivity analysis for propensity score assumptions
  - Method comparison tools (matching, weighting, stratification)

* **Missing Data Adjustments**
  - Sample size inflation for anticipated missingness
  - Multiple imputation considerations
  - Guidance for MCAR, MAR, and MNAR mechanisms

* **Clustering and Design Effects**
  - Intraclass correlation coefficient (ICC) adjustments
  - Design effect calculations for clustered data
  - Sample size inflation for hierarchical designs
  - Domain-specific ICC reference values

* **Multiple Testing Corrections**
  - Family-wise error rate (FWER) control
  - Bonferroni and Šidák corrections
  - False discovery rate (FDR) control
  - Interactive comparison of correction methods

* **E-value Sensitivity Analysis** (NEW)
  - Unmeasured confounding assessment
  - E-value calculations for effect estimates
  - Sensitivity to unmeasured confounders
  - Interpretation guidance for observational studies

* **Mediation Analysis** (NEW)
  - Power calculations for mediation effects
  - Direct and indirect effect sample size
  - Multiple mediation pathways support

#### User Experience Features

* **Interactive Power Curves**
  - Dynamic visualization of power vs. sample size
  - Effect size exploration
  - Real-time parameter updates

* **Modern UI Design**
  - Built with bslib for contemporary appearance
  - Responsive layout for different screen sizes
  - Accessible color schemes and typography
  - Keyboard navigation support

* **Comprehensive Help System**
  - Contextual help for every analysis type
  - Statistical guidance and formulas
  - Real-world examples from observational studies
  - Interpretation assistance

* **Export Capabilities**
  - CSV export for all results
  - Copy-to-clipboard functionality
  - Reproducible analysis parameters

#### Technical Implementation

* **Package Architecture**
  - Built using the golem framework for robust Shiny apps
  - Modular design with separate modules for each analysis type
  - Comprehensive test suite using testthat and shinytest2
  - Extensive documentation with 5 vignettes

* **Statistical Foundations**
  - Leverages established R packages: pwr, binom, powerSurvEpi, epiR
  - Validated against published methods and commercial software
  - Implements cutting-edge 2025 research (Li et al. propensity score methods)

### Vignettes

Five comprehensive vignettes are included:

1. **Propensity Score Calculations** - Guide to PS-adjusted sample size
2. **Missing Data Adjustments** - Handling incomplete data in designs
3. **Design Effects and Clustering** - ICC and clustered study designs
4. **Minimal Detectable Effects** - Reverse power calculations for fixed N
5. **Interactive Power Curves** - Visualization and exploration

### Dependencies

* R (>= 4.2.0)
* shiny (>= 1.9.1)
* bslib (>= 0.8.0)
* golem (>= 0.4.1)
* Statistical packages: pwr, binom, powerSurvEpi, epiR
* Visualization: plotly (>= 4.10.4)

### Authors and Maintainer

* Michael Batech (author, maintainer) <michael.batech@gmail.com>

### License

MIT License

---

## Future Development Roadmap

Planned enhancements for future versions:

* Bayesian power analysis methods
* Adaptive and sequential trial designs
* Additional clustering methods (GEE, mixed models)
* Expanded mediation analysis frameworks
* Enhanced export formats (PDF reports, Word documents)
* Multi-language support

---

## Acknowledgments

This package implements methods from numerous statistical publications and benefits from the R community's open-source packages. Special recognition to:

* Li, Morgan, and Zaslavsky (2025) for propensity score methodology
* The developers of pwr, powerSurvEpi, epiR, and binom packages
* The Shiny and golem development teams
* The biostatistics community for rigorous methods development

---

**Note:** This is the initial CRAN release. The package has been in active development with version numbers tracking internal milestones. Version 5.0.0 represents the first public CRAN-ready release with comprehensive features, testing, and documentation.
