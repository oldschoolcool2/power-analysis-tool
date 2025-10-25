#!/usr/bin/env Rscript
# Dependency checker for R projects
# Finds used vs declared dependencies (similar to ruff for Python)

# Function to extract library() calls
find_library_calls <- function(files) {
  libs <- character()
  for (file in files) {
    content <- readLines(file, warn = FALSE)
    # Match library(pkg) or library("pkg") or library('pkg')
    matches <- regmatches(content, gregexpr('library\\(["\']?([a-zA-Z0-9.]+)["\']?\\)', content))
    for (match_vec in matches) {
      for (match in match_vec) {
        pkg <- gsub('library\\(["\']?([a-zA-Z0-9.]+)["\']?\\)', '\\1', match)
        libs <- c(libs, pkg)
      }
    }
  }
  unique(libs)
}

# Function to extract package::function calls
find_namespace_calls <- function(files) {
  pkgs <- character()
  for (file in files) {
    content <- readLines(file, warn = FALSE)
    # Match pkg::func
    matches <- regmatches(content, gregexpr('[a-zA-Z0-9.]+::', content))
    for (match_vec in matches) {
      for (match in match_vec) {
        pkg <- gsub('::', '', match)
        pkgs <- c(pkgs, pkg)
      }
    }
  }
  unique(pkgs)
}

# Function to get packages from renv.lock
get_renv_packages <- function() {
  if (!requireNamespace("renv", quietly = TRUE)) {
    stop("renv package not available")
  }

  lock <- renv::lockfile_read()

  # Get main packages (not dependencies)
  # In a perfect world, we'd parse DESCRIPTION, but for Shiny apps we use renv.lock
  names(lock$Packages)
}

# Main analysis
main <- function() {
  cat("Analyzing R dependencies...\n\n")

  # Find all R files (excluding renv/)
  r_files <- list.files(
    pattern = "\\.R$",
    recursive = TRUE,
    full.names = TRUE
  )
  r_files <- r_files[!grepl("^renv/", r_files)]

  cat("Found", length(r_files), "R files\n\n")

  # Find used packages
  lib_calls <- find_library_calls(r_files)
  ns_calls <- find_namespace_calls(r_files)

  # Filter out base R packages and false positives
  base_packages <- c("base", "utils", "tools", "stats", "graphics", "grDevices", "methods", "datasets")
  false_positives <- c("pkg", "package")  # Common variable names

  lib_calls <- setdiff(lib_calls, c(base_packages, false_positives))
  ns_calls <- setdiff(ns_calls, c(base_packages, false_positives))

  used_packages <- unique(c(lib_calls, ns_calls))

  cat("Packages loaded via library():\n")
  cat(paste("  -", lib_calls), sep = "\n")
  cat("\n")

  cat("Packages used via namespace (::):\n")
  cat(paste("  -", ns_calls), sep = "\n")
  cat("\n")

  cat("Total unique packages used in code:", length(used_packages), "\n")
  cat(paste("  -", sort(used_packages)), sep = "\n")
  cat("\n")

  # Get packages from renv.lock
  renv_packages <- get_renv_packages()

  # Filter out infrastructure packages (test/dev tools that won't appear in app code)
  infrastructure <- c("renv", "testthat", "shinytest2", "chromote", "covr",
                      "lintr", "styler", "devtools", "here", "knitr",
                      "jsonlite", "curl", "magrittr", "R6")
  app_packages <- setdiff(renv_packages, infrastructure)

  cat("Packages in renv.lock (excluding test/infrastructure):", length(app_packages), "\n")
  cat(paste("  -", sort(app_packages)), sep = "\n")
  cat("\n")

  # Find potentially unused packages
  unused <- setdiff(app_packages, used_packages)

  if (length(unused) > 0) {
    cat("⚠️  POTENTIALLY UNUSED packages in renv.lock:\n")
    cat(paste("  -", sort(unused)), sep = "\n")
    cat("\n")
    cat("Note: These may be indirect dependencies or used in ways not detected.\n")
    cat("Review before removing!\n\n")
  } else {
    cat("✅ All application packages appear to be used!\n\n")
  }

  # Find missing packages
  missing <- setdiff(used_packages, renv_packages)

  if (length(missing) > 0) {
    cat("❌ MISSING packages (used in code but not in renv.lock):\n")
    cat(paste("  -", sort(missing)), sep = "\n")
    cat("\n")
    cat("Run: renv::snapshot() to add these packages\n\n")
    return(1)  # Exit with error
  } else {
    cat("✅ All used packages are in renv.lock!\n\n")
  }

  return(0)
}

# Run if called directly
if (!interactive()) {
  status <- main()
  quit(status = status)
}
