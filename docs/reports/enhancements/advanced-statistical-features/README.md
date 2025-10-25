# Advanced Statistical Features - Implementation Reports

This directory contains documentation for advanced statistical enhancement features focused on advanced capabilities for real-world evidence studies.

## Files

- **progress-summary.md** - Current implementation progress tracker (most recent and authoritative)
  - Feature 1: Missing Data Adjustment ✅ 100% Complete
  - Feature 2: Minimal Detectable Effect Size Calculator ✅ 100% Complete
  - Feature 3: Interactive Power Curves with Plotly 🔄 60% Complete
  - Feature 4: VIF Calculator ⏳ Pending
  - **Overall: 84% Complete (16/19 components)**

- **implementation-status.md** - Earlier status document (older, may be outdated)
  - Use `progress-summary.md` as the primary reference

## Features Overview

### Feature 1: Missing Data Adjustment
Inflate sample sizes to account for expected missingness (MCAR, MAR, MNAR mechanisms). Implemented across all 6 sample size calculation tabs.

### Feature 2: Minimal Detectable Effect Size Calculator
Reverse power analysis - calculate what effects can be detected given a fixed sample size. Critical for RWE studies with predetermined database sizes.

### Feature 3: Interactive Power Curves
Replace static base R plots with interactive Plotly visualizations showing power vs. sample size with hover tooltips, zoom, and pan capabilities.

### Feature 4: Variance Inflation Factor Calculator
PSWeight-based VIF calculations for propensity score methods (ATE, ATT, ATO, ATM).

## Related Documentation

- Implementation guide: `docs/002-how-to-guides/002-advanced-statistical-features-implementation.md`
- Feature proposals: `docs/004-explanation/001-feature-proposals.md`

## Status

**Overall Progress:** 84% (16/19 components complete)
**Time Remaining:** ~9 hours to complete all advanced statistical features
