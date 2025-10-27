# CRAN Submission Comments

## Submission Type

This is a NEW submission.

## Package Purpose

PowerAnalysisTool provides a comprehensive Shiny application for statistical power analysis, sample size calculation, and minimal detectable effect estimation. It supports various study designs including two-proportion tests, survival analysis (including non-inferiority and equivalence tests), matched case-control studies, and continuous outcomes. The package includes advanced features for propensity score adjustments, missing data handling, and multiple testing corrections.

## Test Environments

### Local Testing
* Ubuntu 22.04 LTS, R 4.3.0

### GitHub Actions (Continuous Integration)
* ubuntu-latest, R-release
* ubuntu-latest, R-devel
* windows-latest, R-release
* macOS-latest, R-release

### Remote Testing (Planned)
* Win-builder (R-devel and R-release)
* R-hub builder

## R CMD check Results

### Current Status

⚠️ **Pre-submission checklist in progress**

Outstanding items before submission:
- [ ] Add `@examples` to all 16 exported functions
- [ ] Run local R CMD check with `--as-cran` flag
- [ ] Test on win-builder (R-devel and R-release)
- [ ] Verify 0 errors, 0 warnings, 0 notes

Target: 0 errors | 0 warnings | 0 notes

## Expected Notes (if any)

*To be updated after running R CMD check*

Possible notes we may see:
* New submission note (standard for first-time packages)
* Package size note (if vignettes/data make package large)

## Downstream Dependencies

This is a new package with no reverse dependencies.

## CRAN Policy Compliance

- [x] Package does not write to user's home directory
- [x] Package does not modify global options without restoring
- [x] All examples are wrapped in `\dontrun{}` where appropriate (Shiny UI functions)
- [ ] All exported functions have runnable examples (IN PROGRESS)
- [x] License is standard and open source (MIT)
- [x] Maintainer email is valid and monitored
- [x] Package title is in title case
- [x] Description provides adequate detail (>2 sentences)

## Additional Notes for CRAN Reviewers

### Shiny Application Package

This package primarily provides a Shiny web application for power analysis. The main function `run_app()` launches the interactive application.

### Large Number of Imports

The package imports several statistical and Shiny-related packages:
- Statistical computation: `pwr`, `binom`, `powerSurvEpi`, `epiR`
- Shiny framework: `shiny`, `bslib`, `shinyBS`, `shinyjs`, `plotly`
- Infrastructure: `golem`, `config`, `rmarkdown`

All imports are actively used in the package functionality.

### Vignettes

The package includes 5 vignettes demonstrating:
1. Propensity score calculations
2. Missing data adjustments
3. Design effects and clustering
4. Minimal detectable effects
5. Interactive power curves

## Version History

* Version 5.0.0 - Initial CRAN submission

---

**Submission Date:** TBD
**Maintainer:** Michael Batech <michael.batech@gmail.com>
