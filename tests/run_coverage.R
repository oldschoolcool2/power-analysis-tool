#!/usr/bin/env Rscript

# run_coverage.R - Code Coverage Analysis for Power Analysis Tool
#
# This script runs comprehensive code coverage analysis for the Shiny app
# using the covr package. It produces both console output and HTML reports.
#
# Usage:
#   Rscript tests/run_coverage.R
#   OR from Docker:
#   docker-compose run --rm app Rscript tests/run_coverage.R
#
# Output:
#   - Console summary with overall coverage percentage
#   - Detailed file-by-file breakdown
#   - HTML report in tests/coverage_report/
#
# Requirements:
#   - covr package installed
#   - All test dependencies available

# Suppress package startup messages
suppressPackageStartupMessages({
  library(covr)
  library(testthat)
})

cat("\n")
cat("==============================================================================\n")
cat("  Power Analysis Tool - Code Coverage Analysis\n")
cat("==============================================================================\n\n")

# Set working directory to project root
setwd(here::here())

cat("Running code coverage analysis...\n")
cat("This may take a few minutes as all tests are executed.\n\n")

# Run coverage analysis
# By default, covr tracks coverage for all R files in the package/project
# and runs all tests in tests/testthat/
coverage <- tryCatch(
  {
    covr::package_coverage(
      type = "tests",           # Run test suite
      quiet = FALSE,            # Show progress
      clean = TRUE,             # Clean up after running
      install_path = tempdir()  # Use temp directory for installation
    )
  },
  error = function(e) {
    cat("\nERROR: Coverage analysis failed:\n")
    cat(conditionMessage(e), "\n")
    quit(status = 1)
  }
)

cat("\n")
cat("==============================================================================\n")
cat("  COVERAGE SUMMARY\n")
cat("==============================================================================\n\n")

# Print overall coverage percentage
coverage_percent <- covr::percent_coverage(coverage)
cat(sprintf("Overall Coverage: %.2f%%\n\n", coverage_percent))

# Determine coverage quality
if (coverage_percent >= 90) {
  cat("Status: EXCELLENT ✓ (Target: 90%+)\n")
} else if (coverage_percent >= 80) {
  cat("Status: GOOD ✓ (Target: 80%+)\n")
} else if (coverage_percent >= 70) {
  cat("Status: FAIR ⚠ (Improvement recommended)\n")
} else {
  cat("Status: NEEDS IMPROVEMENT ✗\n")
}

cat("\n")
cat("==============================================================================\n")
cat("  FILE-BY-FILE BREAKDOWN\n")
cat("==============================================================================\n\n")

# Get coverage by file
file_coverage <- covr::coverage_to_list(coverage)

# Create a data frame for better display
coverage_df <- data.frame(
  File = character(),
  Coverage = numeric(),
  Lines_Covered = integer(),
  Lines_Total = integer(),
  stringsAsFactors = FALSE
)

for (file in names(file_coverage)) {
  file_data <- file_coverage[[file]]
  total_lines <- length(file_data$coverage)
  covered_lines <- sum(file_data$coverage > 0, na.rm = TRUE)
  coverage_pct <- if (total_lines > 0) (covered_lines / total_lines) * 100 else 0

  coverage_df <- rbind(coverage_df, data.frame(
    File = basename(file),
    Coverage = coverage_pct,
    Lines_Covered = covered_lines,
    Lines_Total = total_lines,
    stringsAsFactors = FALSE
  ))
}

# Sort by coverage percentage (ascending) to highlight problem areas
coverage_df <- coverage_df[order(coverage_df$Coverage), ]

# Print file coverage table
if (nrow(coverage_df) > 0) {
  for (i in 1:nrow(coverage_df)) {
    row <- coverage_df[i, ]

    # Color coding for terminal output
    status_icon <- if (row$Coverage >= 80) {
      "✓"
    } else if (row$Coverage >= 60) {
      "⚠"
    } else {
      "✗"
    }

    cat(sprintf(
      "%s %-40s %6.2f%% (%3d/%3d lines)\n",
      status_icon,
      row$File,
      row$Coverage,
      row$Lines_Covered,
      row$Lines_Total
    ))
  }
} else {
  cat("No coverage data available.\n")
}

cat("\n")
cat("==============================================================================\n")
cat("  UNCOVERED LINES\n")
cat("==============================================================================\n\n")

# Show specific uncovered lines for each file
zero_coverage <- covr::zero_coverage(coverage)

if (length(zero_coverage) > 0) {
  cat("The following lines are NOT covered by tests:\n\n")

  for (file in names(zero_coverage)) {
    uncovered_lines <- zero_coverage[[file]]
    if (length(uncovered_lines) > 0) {
      cat(sprintf("File: %s\n", basename(file)))
      cat(sprintf("  Lines: %s\n\n", paste(uncovered_lines, collapse = ", ")))
    }
  }
} else {
  cat("All lines are covered! 🎉\n\n")
}

cat("==============================================================================\n")
cat("  GENERATING HTML REPORT\n")
cat("==============================================================================\n\n")

# Generate interactive HTML report
report_dir <- "tests/coverage_report"
dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)

report_file <- file.path(report_dir, "coverage_report.html")

tryCatch(
  {
    covr::report(
      coverage,
      file = report_file,
      browse = FALSE  # Don't auto-open browser in CI/Docker
    )
    cat(sprintf("HTML report generated: %s\n", report_file))
    cat("Open this file in a browser for interactive line-by-line coverage.\n\n")
  },
  error = function(e) {
    cat("Warning: Could not generate HTML report.\n")
    cat(conditionMessage(e), "\n\n")
  }
)

cat("==============================================================================\n")
cat("  COVERAGE THRESHOLDS\n")
cat("==============================================================================\n\n")

# Define coverage thresholds for CI/CD
THRESHOLD_ERROR <- 70    # Below this = fail
THRESHOLD_WARNING <- 80  # Below this = warning
THRESHOLD_TARGET <- 90   # Target for excellent coverage

if (coverage_percent < THRESHOLD_ERROR) {
  cat(sprintf("❌ FAIL: Coverage %.2f%% is below minimum threshold of %d%%\n",
              coverage_percent, THRESHOLD_ERROR))
  cat("Action Required: Add more tests to increase coverage.\n\n")
  quit(status = 1)  # Exit with error for CI/CD

} else if (coverage_percent < THRESHOLD_WARNING) {
  cat(sprintf("⚠️  WARNING: Coverage %.2f%% is below target of %d%%\n",
              coverage_percent, THRESHOLD_WARNING))
  cat("Recommendation: Consider adding more test coverage.\n\n")

} else if (coverage_percent < THRESHOLD_TARGET) {
  cat(sprintf("✓ PASS: Coverage %.2f%% meets minimum standards.\n",
              coverage_percent))
  cat(sprintf("Goal: Reach target of %d%% coverage.\n\n", THRESHOLD_TARGET))

} else {
  cat(sprintf("🎉 EXCELLENT: Coverage %.2f%% exceeds target of %d%%!\n",
              coverage_percent, THRESHOLD_TARGET))
  cat("Great work maintaining high test coverage!\n\n")
}

cat("==============================================================================\n")
cat("  RECOMMENDATIONS\n")
cat("==============================================================================\n\n")

# Provide actionable recommendations based on coverage
files_below_80 <- coverage_df[coverage_df$Coverage < 80, ]

if (nrow(files_below_80) > 0) {
  cat("Files needing more test coverage:\n\n")
  for (i in 1:nrow(files_below_80)) {
    row <- files_below_80[i, ]
    gap <- 80 - row$Coverage
    additional_lines <- ceiling((row$Lines_Total * gap) / 100)
    cat(sprintf("  • %s (%.1f%% coverage)\n", row$File, row$Coverage))
    cat(sprintf("    → Add ~%d more tested lines to reach 80%% coverage\n\n",
                additional_lines))
  }
} else {
  cat("All files have ≥80% coverage! 🎉\n")
  cat("Consider:\n")
  cat("  • Testing edge cases\n")
  cat("  • Adding integration tests\n")
  cat("  • Testing error handling paths\n\n")
}

cat("==============================================================================\n")
cat("  BEST PRACTICES REMINDER\n")
cat("==============================================================================\n\n")

cat("Coverage Tips:\n")
cat("  1. Focus on testing critical business logic\n")
cat("  2. Test error handling and edge cases\n")
cat("  3. Use testServer() for reactive Shiny logic\n")
cat("  4. Use shinytest2 for end-to-end UI testing\n")
cat("  5. Don't sacrifice test quality for 100% coverage\n\n")

cat("To update coverage:\n")
cat("  1. Write new tests in tests/testthat/\n")
cat("  2. Re-run: Rscript tests/run_coverage.R\n")
cat("  3. Review HTML report for line-by-line details\n\n")

cat("Coverage analysis complete! ✓\n\n")

# Return coverage object (useful if sourced)
invisible(coverage)
