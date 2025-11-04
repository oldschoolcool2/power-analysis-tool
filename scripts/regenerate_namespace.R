#!/usr/bin/env Rscript

#' Regenerate NAMESPACE File
#'
#' This script regenerates the NAMESPACE file from roxygen2 documentation
#' comments in R source files. Run this whenever you:
#' - Add new @export tags
#' - Add new @importFrom declarations
#' - Modify function documentation
#'
#' Usage:
#'   Rscript scripts/regenerate_namespace.R
#'
#' Or from R console:
#'   source("scripts/regenerate_namespace.R")

cat("\n")
cat("==============================================\n")
cat("  NAMESPACE Regeneration Script\n")
cat("  Power Analysis Tool v5.0.0\n")
cat("==============================================\n\n")

# Check if we're in the right directory
if (!file.exists("DESCRIPTION")) {
  stop("Error: Must be run from package root directory (where DESCRIPTION file is located)")
}

# Check if devtools is installed
if (!requireNamespace("devtools", quietly = TRUE)) {
  cat("Installing devtools package...\n")
  install.packages("devtools", repos = "https://cloud.r-project.org")
}

# Check if roxygen2 is installed
if (!requireNamespace("roxygen2", quietly = TRUE)) {
  cat("Installing roxygen2 package...\n")
  install.packages("roxygen2", repos = "https://cloud.r-project.org")
}

cat("✓ Prerequisites installed\n\n")

# Backup existing NAMESPACE
if (file.exists("NAMESPACE")) {
  namespace_backup <- readLines("NAMESPACE")
  export_count_before <- sum(grepl("^export\\(", namespace_backup))
  import_count_before <- sum(grepl("^import", namespace_backup))

  backup_file <- sprintf("NAMESPACE.backup.%s", format(Sys.time(), "%Y%m%d-%H%M%S"))
  file.copy("NAMESPACE", backup_file)
  cat(sprintf("✓ Backed up existing NAMESPACE to: %s\n", backup_file))
  cat(sprintf("  - %d exports found\n", export_count_before))
  cat(sprintf("  - %d imports found\n\n", import_count_before))
} else {
  cat("! No existing NAMESPACE file found\n\n")
  export_count_before <- 0
  import_count_before <- 0
}

# Count @export tags in R files
cat("Scanning R source files for @export tags...\n")
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
export_tags <- 0
for (f in r_files) {
  content <- readLines(f, warn = FALSE)
  export_tags <- export_tags + sum(grepl("#'\\s*@export", content))
}
cat(sprintf("✓ Found %d @export tags in R source files\n\n", export_tags))

# Regenerate documentation
cat("Regenerating NAMESPACE and documentation...\n")
tryCatch({
  devtools::document()
  cat("✓ Documentation regenerated successfully\n\n")
}, error = function(e) {
  cat(sprintf("✗ Error during regeneration: %s\n", e$message))
  if (exists("backup_file")) {
    cat(sprintf("! Restoring backup from: %s\n", backup_file))
    file.copy(backup_file, "NAMESPACE", overwrite = TRUE)
  }
  stop("Documentation regeneration failed")
})

# Analyze new NAMESPACE
if (file.exists("NAMESPACE")) {
  namespace_new <- readLines("NAMESPACE")
  export_count_after <- sum(grepl("^export\\(", namespace_new))
  import_count_after <- sum(grepl("^import", namespace_new))

  cat("==============================================\n")
  cat("  RESULTS\n")
  cat("==============================================\n\n")

  cat("Before:\n")
  cat(sprintf("  - Exports: %d\n", export_count_before))
  cat(sprintf("  - Imports: %d\n\n", import_count_before))

  cat("After:\n")
  cat(sprintf("  - Exports: %d\n", export_count_after))
  cat(sprintf("  - Imports: %d\n\n", import_count_after))

  cat("Changes:\n")
  export_diff <- export_count_after - export_count_before
  import_diff <- import_count_after - import_count_before

  if (export_diff > 0) {
    cat(sprintf("  - Added %d exports ✓\n", export_diff))
  } else if (export_diff < 0) {
    cat(sprintf("  - Removed %d exports ⚠\n", abs(export_diff)))
  } else {
    cat("  - No change in exports\n")
  }

  if (import_diff != 0) {
    cat(sprintf("  - Import changes: %+d\n", import_diff))
  } else {
    cat("  - No change in imports\n")
  }

  cat("\n")

  # Check for discrepancies
  if (export_count_after < export_tags) {
    cat("⚠ WARNING: Fewer exports in NAMESPACE than @export tags found\n")
    cat(sprintf("  Expected: %d, Got: %d\n", export_tags, export_count_after))
    cat("  This may indicate malformed @export tags or roxygen2 issues\n\n")
  } else if (export_count_after == export_tags) {
    cat("✓ Export count matches @export tags\n\n")
  }

} else {
  cat("✗ Error: NAMESPACE file not created\n")
  stop("NAMESPACE regeneration failed")
}

cat("==============================================\n")
cat("  NEXT STEPS\n")
cat("==============================================\n\n")
cat("1. Review the changes:\n")
cat("   git diff NAMESPACE\n\n")
cat("2. If changes look good, commit them:\n")
cat("   git add NAMESPACE man/\n")
cat("   git commit -m 'chore: regenerate NAMESPACE and documentation'\n\n")
cat("3. If changes are wrong, restore backup:\n")
if (exists("backup_file")) {
  cat(sprintf("   cp %s NAMESPACE\n\n", backup_file))
}

cat("✓ Done!\n\n")
