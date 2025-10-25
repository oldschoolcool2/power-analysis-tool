#!/usr/bin/env Rscript

# coverage_summary.R - Quick Coverage Summary Script
#
# This is a lightweight script that provides a quick coverage summary
# without generating the full HTML report. Useful for CI/CD pipelines.
#
# Usage:
#   Rscript tests/coverage_summary.R
#
# Exit codes:
#   0 = Coverage meets threshold (≥70%)
#   1 = Coverage below threshold (<70%)

suppressPackageStartupMessages({
  library(covr)
})

# Set working directory to project root
setwd(here::here())

# Run coverage (silent mode)
cat("Calculating code coverage...\n")
coverage <- covr::package_coverage(
  type = "tests",
  quiet = TRUE,
  clean = TRUE,
  install_path = tempdir()
)

# Get percentage
coverage_percent <- covr::percent_coverage(coverage)

# Print summary
cat(sprintf("\nCode Coverage: %.2f%%\n", coverage_percent))

# Check threshold
THRESHOLD <- 70

if (coverage_percent >= THRESHOLD) {
  cat(sprintf("✓ Coverage meets threshold (≥%d%%)\n", THRESHOLD))
  quit(status = 0)
} else {
  cat(sprintf("✗ Coverage below threshold (<%d%%)\n", THRESHOLD))
  quit(status = 1)
}
