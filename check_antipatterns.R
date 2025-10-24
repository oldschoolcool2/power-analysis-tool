#!/usr/bin/env Rscript
# Antipattern Detection Script
# Checks for R and Shiny-specific antipatterns not caught by lintr
# Usage: Rscript check_antipatterns.R [--fix] [--file app.R]

suppressPackageStartupMessages({
  library(tools)  # For file_path_sans_ext
})

# Configuration
ARGS <- commandArgs(trailingOnly = TRUE)
FIX_MODE <- "--fix" %in% ARGS
TARGET_FILE <- if ("--file" %in% ARGS) {
  ARGS[which(ARGS == "--file") + 1]
} else {
  "app.R"
}

# Color output for terminal
red <- function(x) paste0("\033[31m", x, "\033[0m")
yellow <- function(x) paste0("\033[33m", x, "\033[0m")
green <- function(x) paste0("\033[32m", x, "\033[0m")
blue <- function(x) paste0("\033[34m", x, "\033[0m")

# Antipattern detection functions
check_shiny_antipatterns <- function(code_lines, filename) {
  issues <- list()

  # ANTIPATTERN 1: Excessive renderUI (performance killer)
  renderui_count <- sum(grepl("renderUI\\s*\\(", code_lines))
  if (renderui_count > 5) {
    issues[[length(issues) + 1]] <- list(
      severity = "MEDIUM",
      pattern = "Excessive renderUI",
      message = sprintf(
        "Found %d renderUI calls. Consider using update* functions instead for better performance.",
        renderui_count
      ),
      fix = "Replace renderUI with updateSelectInput, updateNumericInput, etc.",
      line = which(grepl("renderUI\\s*\\(", code_lines))[1]
    )
  }

  # ANTIPATTERN 2: Missing isolate() in reactive contexts
  # Look for observeEvent/reactive that reads inputs without isolate
  for (i in seq_along(code_lines)) {
    line <- code_lines[i]

    # Check if we're in a reactive context without isolate
    if (grepl("observeEvent\\s*\\(", line)) {
      # Look ahead for input$ usage without isolate
      context_end <- min(i + 20, length(code_lines))
      context <- code_lines[i:context_end]

      has_input_read <- any(grepl("input\\$", context))
      has_isolate <- any(grepl("isolate\\s*\\(", context))

      if (has_input_read && !has_isolate) {
        issues[[length(issues) + 1]] <- list(
          severity = "LOW",
          pattern = "Missing isolate()",
          message = "observeEvent may create unintended reactive dependencies. Consider using isolate().",
          fix = "Wrap input reads in isolate({ ... })",
          line = i
        )
      }
    }
  }

  # ANTIPATTERN 3: Blocking operations without async
  blocking_patterns <- c(
    "Sys\\.sleep\\(",
    "download\\.file\\(",
    "system\\(",
    "readLines\\(url\\("
  )

  for (pattern in blocking_patterns) {
    matches <- grep(pattern, code_lines)
    if (length(matches) > 0) {
      issues[[length(issues) + 1]] <- list(
        severity = "HIGH",
        pattern = "Blocking operation",
        message = sprintf(
          "Found potentially blocking operation: %s. Consider using async/promises.",
          sub("\\\\", "", pattern)
        ),
        fix = "Use future/promises for async execution",
        line = matches[1]
      )
    }
  }

  # ANTIPATTERN 4: Not using bindCache for expensive renders
  expensive_renders <- grep("renderPlot\\s*\\(|renderTable\\s*\\(", code_lines)
  for (line_num in expensive_renders) {
    # Check if bindCache is used within next 3 lines
    context <- code_lines[line_num:min(line_num + 3, length(code_lines))]
    if (!any(grepl("bindCache|%>%\\s*bindCache", context))) {
      issues[[length(issues) + 1]] <- list(
        severity = "MEDIUM",
        pattern = "Missing bindCache",
        message = "Expensive render without caching. Consider adding bindCache().",
        fix = "Add %>% bindCache(input$var1, input$var2)",
        line = line_num
      )
    }
  }

  # ANTIPATTERN 5: Global state modification in Shiny
  global_assign <- grep("<-\\s*\\w+\\s*$|^\\w+\\s*<<-", code_lines)
  for (line_num in global_assign) {
    if (grepl("<<-", code_lines[line_num])) {
      issues[[length(issues) + 1]] <- list(
        severity = "HIGH",
        pattern = "Global assignment (<<-)",
        message = "Using <<- can cause unexpected behavior in multi-user Shiny apps.",
        fix = "Use reactiveValues() instead",
        line = line_num
      )
    }
  }

  return(issues)
}

check_r_antipatterns <- function(code_lines, filename) {
  issues <- list()

  # ANTIPATTERN 6: Using sapply (type-unsafe)
  sapply_lines <- grep("sapply\\s*\\(", code_lines)
  if (length(sapply_lines) > 0) {
    issues[[length(issues) + 1]] <- list(
      severity = "MEDIUM",
      pattern = "sapply usage",
      message = "sapply returns inconsistent types. Use vapply for type safety.",
      fix = "Replace sapply(x, fun) with vapply(x, fun, FUN.VALUE = ...)",
      line = sapply_lines[1]
    )
  }

  # ANTIPATTERN 7: Using setwd() in scripts
  setwd_lines <- grep("setwd\\s*\\(", code_lines)
  if (length(setwd_lines) > 0) {
    issues[[length(issues) + 1]] <- list(
      severity = "HIGH",
      pattern = "setwd usage",
      message = "setwd() breaks reproducibility. Use here::here() or relative paths.",
      fix = "Remove setwd() and use relative paths or here::here()",
      line = setwd_lines[1]
    )
  }

  # ANTIPATTERN 8: Hardcoded absolute paths
  abs_path_patterns <- c(
    '"/home/',
    '"/Users/',
    '"C:/',
    '"D:/',
    '"/mnt/',
    '"/tmp/' # Less severe, but still antipattern
  )

  for (pattern in abs_path_patterns) {
    matches <- grep(pattern, code_lines, fixed = TRUE)
    if (length(matches) > 0) {
      issues[[length(issues) + 1]] <- list(
        severity = "HIGH",
        pattern = "Absolute path",
        message = sprintf("Hardcoded absolute path found: %s", pattern),
        fix = "Use relative paths or here::here()",
        line = matches[1]
      )
    }
  }

  # ANTIPATTERN 9: T/F instead of TRUE/FALSE
  tf_pattern <- "\\b[^'\"]\\s*[TF]\\s*(?=[,\\)\\s]|$)"
  tf_lines <- grep(tf_pattern, code_lines, perl = TRUE)
  if (length(tf_lines) > 0) {
    issues[[length(issues) + 1]] <- list(
      severity = "MEDIUM",
      pattern = "T/F shorthand",
      message = "Using T/F instead of TRUE/FALSE. T and F are variables, not constants.",
      fix = "Replace T with TRUE, F with FALSE",
      line = tf_lines[1]
    )
  }

  # ANTIPATTERN 10: attach() usage
  attach_lines <- grep("attach\\s*\\(", code_lines)
  if (length(attach_lines) > 0) {
    issues[[length(issues) + 1]] <- list(
      severity = "HIGH",
      pattern = "attach() usage",
      message = "attach() pollutes global namespace and can cause naming conflicts.",
      fix = "Use with() or explicit data$column references",
      line = attach_lines[1]
    )
  }

  return(issues)
}

check_code_quality <- function(code_lines, filename) {
  issues <- list()

  # ANTIPATTERN 11: Very long functions (>50 lines)
  in_function <- FALSE
  function_start <- 0
  brace_count <- 0

  for (i in seq_along(code_lines)) {
    line <- code_lines[i]

    if (grepl("function\\s*\\(", line) && !grepl("^\\s*#", line)) {
      in_function <- TRUE
      function_start <- i
      brace_count <- 0
    }

    if (in_function) {
      brace_count <- brace_count + lengths(regmatches(line, gregexpr("\\{", line)))
      brace_count <- brace_count - lengths(regmatches(line, gregexpr("\\}", line)))

      if (brace_count == 0 && function_start > 0) {
        function_length <- i - function_start
        if (function_length > 50) {
          issues[[length(issues) + 1]] <- list(
            severity = "LOW",
            pattern = "Long function",
            message = sprintf("Function is %d lines long. Consider breaking into smaller functions.", function_length),
            fix = "Refactor into smaller, focused functions",
            line = function_start
          )
        }
        in_function <- FALSE
        function_start <- 0
      }
    }
  }

  # ANTIPATTERN 12: Magic numbers (except common ones like 0, 1, 2)
  magic_number_lines <- grep("\\b[3-9]\\d{2,}\\b", code_lines)
  if (length(magic_number_lines) > 5) {
    issues[[length(issues) + 1]] <- list(
      severity = "LOW",
      pattern = "Magic numbers",
      message = "Multiple magic numbers found. Consider using named constants.",
      fix = "Define constants at top of file (e.g., MAX_ITERATIONS <- 1000)",
      line = magic_number_lines[1]
    )
  }

  return(issues)
}

# Main execution
main <- function() {
  cat(blue("╔════════════════════════════════════════════════════════════╗\n"))
  cat(blue("║"), yellow("  Antipattern Detection for R & Shiny Applications      "), blue("║\n"))
  cat(blue("╚════════════════════════════════════════════════════════════╝\n\n"))

  if (!file.exists(TARGET_FILE)) {
    cat(red(sprintf("Error: File '%s' not found.\n", TARGET_FILE)))
    quit(status = 1)
  }

  cat(sprintf("Analyzing: %s\n\n", TARGET_FILE))

  code_lines <- readLines(TARGET_FILE, warn = FALSE)

  # Run all checks
  all_issues <- c(
    check_shiny_antipatterns(code_lines, TARGET_FILE),
    check_r_antipatterns(code_lines, TARGET_FILE),
    check_code_quality(code_lines, TARGET_FILE)
  )

  if (length(all_issues) == 0) {
    cat(green("✓ No antipatterns detected! Code looks good.\n\n"))
    quit(status = 0)
  }

  # Group by severity
  high <- Filter(function(x) x$severity == "HIGH", all_issues)
  medium <- Filter(function(x) x$severity == "MEDIUM", all_issues)
  low <- Filter(function(x) x$severity == "LOW", all_issues)

  # Report
  cat(sprintf("Found %d antipatterns:\n", length(all_issues)))
  cat(sprintf("  %s %d HIGH severity\n", red("●"), length(high)))
  cat(sprintf("  %s %d MEDIUM severity\n", yellow("●"), length(medium)))
  cat(sprintf("  %s %d LOW severity\n", blue("●"), length(low)))
  cat("\n")

  print_issues <- function(issues, severity_color) {
    for (issue in issues) {
      cat(severity_color(sprintf(
        "[%s] %s (Line %d)\n",
        issue$severity,
        issue$pattern,
        issue$line
      )))
      cat(sprintf("  %s\n", issue$message))
      cat(green(sprintf("  Fix: %s\n", issue$fix)))
      cat(sprintf("  Code: %s\n", trimws(code_lines[issue$line])))
      cat("\n")
    }
  }

  if (length(high) > 0) {
    cat(red("\n━━━ HIGH PRIORITY ISSUES ━━━\n\n"))
    print_issues(high, red)
  }

  if (length(medium) > 0) {
    cat(yellow("\n━━━ MEDIUM PRIORITY ISSUES ━━━\n\n"))
    print_issues(medium, yellow)
  }

  if (length(low) > 0) {
    cat(blue("\n━━━ LOW PRIORITY ISSUES ━━━\n\n"))
    print_issues(low, blue)
  }

  # Exit with non-zero if HIGH severity issues found
  if (length(high) > 0) {
    quit(status = 1)
  } else {
    quit(status = 0)
  }
}

# Run if called as script
if (!interactive()) {
  main()
}
