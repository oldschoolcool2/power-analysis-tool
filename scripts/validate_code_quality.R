#!/usr/bin/env Rscript
# Code Quality Validation Script
# Runs comprehensive checks using the new .lintr configuration
# Usage: Rscript validate_code_quality.R

cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║  Code Quality Validation - Power Analysis Tool            ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

# Check if required packages are installed
check_package <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("❌ Package '%s' not installed. Install with: install.packages('%s')\n", pkg, pkg))
    return(FALSE)
  }
  return(TRUE)
}

packages_ok <- TRUE
packages_ok <- check_package("lintr") && packages_ok
packages_ok <- check_package("styler") && packages_ok

if (!packages_ok) {
  cat("\n⚠️  Install missing packages and re-run this script.\n")
  quit(status = 1)
}

library(lintr)
library(styler)

cat("1. Running lintr with enhanced configuration...\n")
cat("   (Using .lintr config with antipattern detection)\n\n")

# Lint the main application file
lints <- lint_dir(".", exclusions = list("renv/", "tests/testthat.R", "renv.lock"))

if (length(lints) == 0) {
  cat("✅ No linting issues found!\n\n")
} else {
  cat(sprintf("⚠️  Found %d linting issues:\n\n", length(lints)))

  # Group by linter type
  linter_counts <- table(sapply(lints, function(x) class(x)[1]))

  cat("Issues by type:\n")
  for (linter_name in names(linter_counts)) {
    cat(sprintf("  • %s: %d\n", linter_name, linter_counts[linter_name]))
  }
  cat("\n")

  # Show first 10 issues
  cat("First 10 issues:\n")
  cat("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")
  print(head(lints, 10))
  cat("\n")

  if (length(lints) > 10) {
    cat(sprintf("... and %d more issues.\n\n", length(lints) - 10))
  }
}

cat("2. Checking code style with styler...\n\n")

# Check if code needs styling
style_results <- style_dir(".", dry = "on", exclude_dirs = c("renv"))

changed_files <- style_results[style_results$changed, ]

if (nrow(changed_files) == 0) {
  cat("✅ All code follows tidyverse style!\n\n")
} else {
  cat(sprintf("⚠️  %d files need styling:\n", nrow(changed_files)))
  for (f in changed_files$file) {
    cat(sprintf("  • %s\n", f))
  }
  cat("\nRun 'styler::style_dir()' to auto-format.\n\n")
}

cat("3. Running custom antipattern checks...\n\n")

if (file.exists("check_antipatterns.R")) {
  system("Rscript check_antipatterns.R --file app.R", ignore.stdout = FALSE)
} else {
  cat("⚠️  check_antipatterns.R not found. Skipping custom checks.\n")
}

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║  Validation Complete                                       ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

cat("Summary:\n")
cat(sprintf("  • Lintr issues: %d\n", length(lints)))
cat(sprintf("  • Files needing style: %d\n", nrow(changed_files)))
cat("\n")

if (length(lints) > 0) {
  cat("Next steps:\n")
  cat("  1. Review lintr issues above\n")
  cat("  2. Fix HIGH priority issues first\n")
  cat("  3. Run 'styler::style_dir()' to format code\n")
  cat("  4. Re-run this script to verify fixes\n")
} else {
  cat("🎉 Code quality is excellent! No issues found.\n")
}

cat("\nFor detailed guidance, see:\n")
cat("  • docs/development/ANTIPATTERNS.md\n")
cat("  • docs/development/CODE_QUALITY.md\n\n")

# Exit with status based on issues found
if (length(lints) > 0) {
  quit(status = 1)
} else {
  quit(status = 0)
}
