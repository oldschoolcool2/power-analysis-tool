#!/usr/bin/env Rscript

#' Log Monitoring Dashboard Script
#'
#' Real-time monitoring and analysis of application logs for the Power Analysis Tool.
#' This script provides command-line tools for log analysis, error detection, and
#' performance monitoring.
#'
#' Usage:
#'   Rscript scripts/monitor_logs.R [command] [options]
#'
#' Commands:
#'   tail       - Follow logs in real-time
#'   errors     - Show recent errors
#'   stats      - Display log statistics
#'   users      - Show active users and sessions
#'   modules    - Analyze module usage
#'   dashboard  - Launch interactive dashboard
#'   export     - Export logs to various formats
#'
#' Examples:
#'   Rscript scripts/monitor_logs.R tail
#'   Rscript scripts/monitor_logs.R errors --last 24h
#'   Rscript scripts/monitor_logs.R stats --date 2025-10-27
#'   Rscript scripts/monitor_logs.R dashboard

# ============================================================================
# Dependencies
# ============================================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(lubridate)
  library(ggplot2)
  library(glue)
})

# ============================================================================
# Configuration
# ============================================================================

# Default log directory
LOG_DIR <- Sys.getenv("PAT_LOG_DIR", "./logs")

# Colors for terminal output
COLOR_RED <- "\033[31m"
COLOR_YELLOW <- "\033[33m"
COLOR_GREEN <- "\033[32m"
COLOR_BLUE <- "\033[34m"
COLOR_CYAN <- "\033[36m"
COLOR_RESET <- "\033[0m"
COLOR_BOLD <- "\033[1m"

# ============================================================================
# Helper Functions
# ============================================================================

#' Print colored message to console
#' @param msg Message to print
#' @param color Color code
print_colored <- function(msg, color = COLOR_RESET) {
  cat(paste0(color, msg, COLOR_RESET, "\n"))
}

#' Get today's log file
#' @return Path to today's log file
get_todays_log <- function() {
  log_date <- format(Sys.Date(), "%Y-%m-%d")
  log_file <- file.path(LOG_DIR, paste0("app_", log_date, ".log"))

  if (!file.exists(log_file)) {
    print_colored(paste("No log file found for today:", log_file), COLOR_YELLOW)
    return(NULL)
  }

  log_file
}

#' Get all log files in directory
#' @param days Number of days to look back (default: 7)
#' @return Vector of log file paths
get_log_files <- function(days = 7) {
  all_files <- list.files(LOG_DIR, pattern = "^app_.*\\.log$", full.names = TRUE)

  # Filter by modification time
  recent_files <- all_files[file.mtime(all_files) > Sys.time() - days * 86400]

  sort(recent_files, decreasing = TRUE)
}

#' Parse JSON log line
#' @param line Log line string
#' @return List with parsed log data, or NULL if parsing fails
parse_log_line <- function(line) {
  tryCatch(
    fromJSON(line),
    error = function(e) NULL
  )
}

#' Read and parse log file
#' @param log_file Path to log file
#' @param max_lines Maximum lines to read (default: NULL = all)
#' @return Data frame with parsed logs
read_log_file <- function(log_file, max_lines = NULL) {
  if (!file.exists(log_file)) {
    return(data.frame())
  }

  # Read lines
  lines <- readLines(log_file, warn = FALSE)

  if (!is.null(max_lines)) {
    lines <- tail(lines, max_lines)
  }

  # Parse each line
  parsed <- lapply(lines, parse_log_line)
  parsed <- Filter(Negate(is.null), parsed)

  if (length(parsed) == 0) {
    return(data.frame())
  }

  # Convert to data frame
  df <- bind_rows(parsed)

  # Ensure timestamp column
  if ("time" %in% names(df)) {
    df$timestamp <- as.POSIXct(df$time, format = "%Y-%m-%d %H:%M:%OS")
  } else if ("timestamp" %in% names(df)) {
    df$timestamp <- as.POSIXct(df$timestamp)
  } else {
    df$timestamp <- Sys.time()
  }

  df
}

#' Format log entry for display
#' @param entry Single log entry (row from parsed log df)
#' @return Formatted string
format_log_entry <- function(entry) {
  # Determine color by level
  level_color <- switch(
    toupper(entry$level %||% "INFO"),
    "ERROR" = COLOR_RED,
    "WARN" = COLOR_YELLOW,
    "INFO" = COLOR_GREEN,
    "DEBUG" = COLOR_CYAN,
    COLOR_RESET
  )

  # Format timestamp
  ts <- format(entry$timestamp, "%Y-%m-%d %H:%M:%S")

  # Build output
  output <- paste0(
    COLOR_BOLD, ts, COLOR_RESET, " ",
    level_color, "[", toupper(entry$level %||% "INFO"), "]", COLOR_RESET, " ",
    entry$msg %||% "No message"
  )

  # Add context if available
  if (!is.null(entry$session_id) && entry$session_id != "unknown") {
    output <- paste0(output, " ", COLOR_BLUE, "(session: ", entry$session_id, ")", COLOR_RESET)
  }

  if (!is.null(entry$module)) {
    output <- paste0(output, " ", COLOR_CYAN, "[", entry$module, "]", COLOR_RESET)
  }

  output
}

# ============================================================================
# Command: tail - Follow logs in real-time
# ============================================================================

cmd_tail <- function() {
  log_file <- get_todays_log()
  if (is.null(log_file)) return()

  print_colored("\n=== Following logs (Ctrl+C to stop) ===\n", COLOR_BOLD)
  print_colored(paste("Log file:", log_file), COLOR_CYAN)
  print_colored("", COLOR_RESET)

  # Get current size
  last_size <- file.info(log_file)$size

  # Print last 20 lines
  initial_logs <- read_log_file(log_file, max_lines = 20)
  if (nrow(initial_logs) > 0) {
    for (i in seq_len(nrow(initial_logs))) {
      cat(format_log_entry(initial_logs[i, ]), "\n")
    }
  }

  # Follow new entries
  while (TRUE) {
    Sys.sleep(1)

    current_size <- file.info(log_file)$size

    if (current_size > last_size) {
      # Read new lines
      all_lines <- readLines(log_file, warn = FALSE)

      # Calculate how many lines are new
      new_line_count <- length(all_lines) - floor(last_size / 100)  # Rough estimate
      new_lines <- tail(all_lines, max(new_line_count, 1))

      # Parse and display
      for (line in new_lines) {
        entry <- parse_log_line(line)
        if (!is.null(entry)) {
          if (!is.null(entry$time)) {
            entry$timestamp <- as.POSIXct(entry$time, format = "%Y-%m-%d %H:%M:%OS")
          }
          cat(format_log_entry(entry), "\n")
        }
      }

      last_size <- current_size
    }
  }
}

# ============================================================================
# Command: errors - Show recent errors
# ============================================================================

cmd_errors <- function(last = "24h") {
  print_colored("\n=== Recent Errors ===\n", COLOR_BOLD)

  # Parse time window
  hours <- as.numeric(gsub("h$", "", last))
  cutoff_time <- Sys.time() - hours * 3600

  # Read recent log files
  log_files <- get_log_files(days = ceiling(hours / 24))

  all_errors <- list()

  for (log_file in log_files) {
    logs <- read_log_file(log_file)

    if (nrow(logs) > 0) {
      errors <- logs %>%
        filter(
          toupper(level) %in% c("ERROR", "WARN"),
          timestamp >= cutoff_time
        ) %>%
        arrange(desc(timestamp))

      if (nrow(errors) > 0) {
        all_errors[[length(all_errors) + 1]] <- errors
      }
    }
  }

  if (length(all_errors) == 0) {
    print_colored("No errors found in the specified time window.", COLOR_GREEN)
    return()
  }

  all_errors_df <- bind_rows(all_errors)

  print_colored(paste("Found", nrow(all_errors_df), "errors/warnings:\n"), COLOR_YELLOW)

  for (i in seq_len(min(nrow(all_errors_df), 50))) {
    cat(format_log_entry(all_errors_df[i, ]), "\n")

    # Print error details if available
    if (!is.null(all_errors_df[i, ]$error_msg)) {
      cat(COLOR_RED, "  Error:", all_errors_df[i, ]$error_msg, COLOR_RESET, "\n")
    }

    if (!is.null(all_errors_df[i, ]$error_class)) {
      cat(COLOR_RED, "  Class:", all_errors_df[i, ]$error_class, COLOR_RESET, "\n")
    }

    cat("\n")
  }

  if (nrow(all_errors_df) > 50) {
    print_colored(paste("... and", nrow(all_errors_df) - 50, "more"), COLOR_YELLOW)
  }
}

# ============================================================================
# Command: stats - Display log statistics
# ============================================================================

cmd_stats <- function(date = NULL) {
  print_colored("\n=== Log Statistics ===\n", COLOR_BOLD)

  # Determine which log files to analyze
  if (!is.null(date)) {
    log_file <- file.path(LOG_DIR, paste0("app_", date, ".log"))
    log_files <- if (file.exists(log_file)) log_file else character(0)
    print_colored(paste("Analyzing:", date), COLOR_CYAN)
  } else {
    log_files <- get_log_files(days = 1)
    print_colored("Analyzing: Last 24 hours", COLOR_CYAN)
  }

  if (length(log_files) == 0) {
    print_colored("No log files found.", COLOR_YELLOW)
    return()
  }

  # Read and aggregate
  all_logs <- lapply(log_files, read_log_file) %>% bind_rows()

  if (nrow(all_logs) == 0) {
    print_colored("No log entries found.", COLOR_YELLOW)
    return()
  }

  # Overall statistics
  cat("\n")
  print_colored("Overall Statistics:", COLOR_BOLD)
  cat("  Total log entries:", nrow(all_logs), "\n")
  cat("  Time range:", format(min(all_logs$timestamp, na.rm = TRUE), "%Y-%m-%d %H:%M"), "to",
      format(max(all_logs$timestamp, na.rm = TRUE), "%Y-%m-%d %H:%M"), "\n")
  cat("  Duration:", round(as.numeric(difftime(max(all_logs$timestamp, na.rm = TRUE),
                                                min(all_logs$timestamp, na.rm = TRUE),
                                                units = "hours")), 2), "hours\n")

  # By log level
  cat("\n")
  print_colored("By Log Level:", COLOR_BOLD)
  level_counts <- all_logs %>%
    count(level = toupper(level)) %>%
    arrange(desc(n))

  for (i in seq_len(nrow(level_counts))) {
    level_color <- switch(
      level_counts$level[i],
      "ERROR" = COLOR_RED,
      "WARN" = COLOR_YELLOW,
      "INFO" = COLOR_GREEN,
      "DEBUG" = COLOR_CYAN,
      "TRACE" = COLOR_BLUE,
      COLOR_RESET
    )
    cat("  ", level_color, sprintf("%-10s", level_counts$level[i]), COLOR_RESET,
        ": ", level_counts$n[i], "\n", sep = "")
  }

  # By module
  if ("module" %in% names(all_logs)) {
    cat("\n")
    print_colored("By Module:", COLOR_BOLD)
    module_counts <- all_logs %>%
      filter(!is.na(module), module != "") %>%
      count(module) %>%
      arrange(desc(n)) %>%
      head(10)

    if (nrow(module_counts) > 0) {
      for (i in seq_len(nrow(module_counts))) {
        cat("  ", sprintf("%-30s", module_counts$module[i]), ": ",
            module_counts$n[i], "\n", sep = "")
      }
    }
  }

  # Error summary
  error_count <- sum(toupper(all_logs$level) == "ERROR", na.rm = TRUE)
  warn_count <- sum(toupper(all_logs$level) == "WARN", na.rm = TRUE)

  cat("\n")
  if (error_count > 0) {
    print_colored(paste("⚠️  ERRORS:", error_count), COLOR_RED)
  } else {
    print_colored("✓ No errors", COLOR_GREEN)
  }

  if (warn_count > 0) {
    print_colored(paste("⚠  WARNINGS:", warn_count), COLOR_YELLOW)
  }

  cat("\n")
}

# ============================================================================
# Command: users - Show active users and sessions
# ============================================================================

cmd_users <- function() {
  print_colored("\n=== Active Users and Sessions ===\n", COLOR_BOLD)

  log_files <- get_log_files(days = 1)

  if (length(log_files) == 0) {
    print_colored("No log files found.", COLOR_YELLOW)
    return()
  }

  all_logs <- lapply(log_files, read_log_file) %>% bind_rows()

  if (nrow(all_logs) == 0) {
    print_colored("No log entries found.", COLOR_YELLOW)
    return()
  }

  # Filter for logs with session information
  session_logs <- all_logs %>%
    filter(!is.na(session_id), session_id != "unknown")

  if (nrow(session_logs) == 0) {
    print_colored("No session information found in logs.", COLOR_YELLOW)
    return()
  }

  # Aggregate by session
  session_summary <- session_logs %>%
    group_by(session_id) %>%
    summarise(
      user = first(user, default = "unknown"),
      first_seen = min(timestamp, na.rm = TRUE),
      last_seen = max(timestamp, na.rm = TRUE),
      event_count = n(),
      modules_used = n_distinct(module, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(last_seen))

  cat("Total sessions:", nrow(session_summary), "\n\n")

  for (i in seq_len(min(nrow(session_summary), 20))) {
    session <- session_summary[i, ]

    # Determine if session is recent (active in last 10 minutes)
    is_active <- difftime(Sys.time(), session$last_seen, units = "mins") < 10

    status_color <- if (is_active) COLOR_GREEN else COLOR_RESET

    cat(status_color, "Session:", session$session_id, COLOR_RESET, "\n", sep = "")
    cat("  User:", session$user, "\n")
    cat("  First seen:", format(session$first_seen, "%Y-%m-%d %H:%M:%S"), "\n")
    cat("  Last seen:", format(session$last_seen, "%Y-%m-%d %H:%M:%S"), "\n")
    cat("  Events:", session$event_count, "\n")
    cat("  Modules:", session$modules_used, "\n")

    if (is_active) {
      cat(COLOR_GREEN, "  Status: ACTIVE", COLOR_RESET, "\n")
    }

    cat("\n")
  }

  if (nrow(session_summary) > 20) {
    print_colored(paste("... and", nrow(session_summary) - 20, "more sessions"), COLOR_CYAN)
  }
}

# ============================================================================
# Command: modules - Analyze module usage
# ============================================================================

cmd_modules <- function() {
  print_colored("\n=== Module Usage Analysis ===\n", COLOR_BOLD)

  log_files <- get_log_files(days = 7)

  if (length(log_files) == 0) {
    print_colored("No log files found.", COLOR_YELLOW)
    return()
  }

  all_logs <- lapply(log_files, read_log_file) %>% bind_rows()

  if (nrow(all_logs) == 0) {
    print_colored("No log entries found.", COLOR_YELLOW)
    return()
  }

  # Filter for module events
  module_logs <- all_logs %>%
    filter(!is.na(module), module != "")

  if (nrow(module_logs) == 0) {
    print_colored("No module events found in logs.", COLOR_YELLOW)
    return()
  }

  # Module initialization counts
  cat("\n")
  print_colored("Module Initialization Counts (Last 7 Days):", COLOR_BOLD)

  init_counts <- module_logs %>%
    filter(grepl("init", msg, ignore.case = TRUE)) %>%
    count(module) %>%
    arrange(desc(n))

  if (nrow(init_counts) > 0) {
    max_count <- max(init_counts$n)

    for (i in seq_len(nrow(init_counts))) {
      # Create a simple bar chart
      bar_length <- round(20 * init_counts$n[i] / max_count)
      bar <- paste(rep("█", bar_length), collapse = "")

      cat("  ", sprintf("%-30s", init_counts$module[i]), " ",
          COLOR_CYAN, bar, COLOR_RESET, " ",
          init_counts$n[i], "\n", sep = "")
    }
  }

  # Module errors
  cat("\n")
  print_colored("Module Errors:", COLOR_BOLD)

  module_errors <- module_logs %>%
    filter(toupper(level) == "ERROR") %>%
    count(module) %>%
    arrange(desc(n))

  if (nrow(module_errors) > 0) {
    for (i in seq_len(nrow(module_errors))) {
      cat("  ", COLOR_RED, sprintf("%-30s", module_errors$module[i]), COLOR_RESET,
          ": ", module_errors$n[i], " errors\n", sep = "")
    }
  } else {
    print_colored("  No module errors found", COLOR_GREEN)
  }

  cat("\n")
}

# ============================================================================
# Command: export - Export logs to various formats
# ============================================================================

cmd_export <- function(format = "csv", output = NULL, days = 7) {
  print_colored("\n=== Exporting Logs ===\n", COLOR_BOLD)

  log_files <- get_log_files(days = days)

  if (length(log_files) == 0) {
    print_colored("No log files found.", COLOR_YELLOW)
    return()
  }

  all_logs <- lapply(log_files, read_log_file) %>% bind_rows()

  if (nrow(all_logs) == 0) {
    print_colored("No log entries found.", COLOR_YELLOW)
    return()
  }

  # Generate default output filename if not provided
  if (is.null(output)) {
    output <- paste0("logs_export_", format(Sys.Date(), "%Y%m%d"), ".", format)
  }

  # Export based on format
  if (format == "csv") {
    write.csv(all_logs, output, row.names = FALSE)
    print_colored(paste("Exported", nrow(all_logs), "log entries to:", output), COLOR_GREEN)
  } else if (format == "json") {
    write(toJSON(all_logs, pretty = TRUE), output)
    print_colored(paste("Exported", nrow(all_logs), "log entries to:", output), COLOR_GREEN)
  } else if (format == "rds") {
    saveRDS(all_logs, output)
    print_colored(paste("Exported", nrow(all_logs), "log entries to:", output), COLOR_GREEN)
  } else {
    print_colored(paste("Unknown format:", format), COLOR_RED)
    print_colored("Supported formats: csv, json, rds", COLOR_YELLOW)
  }
}

# ============================================================================
# Command: dashboard - Launch interactive dashboard
# ============================================================================

cmd_dashboard <- function() {
  print_colored("\n=== Log Dashboard ===\n", COLOR_BOLD)
  print_colored("Feature coming soon: Interactive Shiny dashboard for log analysis", COLOR_CYAN)
  print_colored("\nFor now, use the other commands for log analysis:", COLOR_YELLOW)
  cat("  - tail: Follow logs in real-time\n")
  cat("  - errors: View recent errors\n")
  cat("  - stats: Display statistics\n")
  cat("  - users: Show active sessions\n")
  cat("  - modules: Analyze module usage\n")
  cat("\n")
}

# ============================================================================
# Main Entry Point
# ============================================================================

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    cat("\n")
    print_colored("Power Analysis Tool - Log Monitor", COLOR_BOLD)
    cat("\n")
    cat("Usage: Rscript scripts/monitor_logs.R [command] [options]\n")
    cat("\n")
    cat("Commands:\n")
    cat("  tail       - Follow logs in real-time\n")
    cat("  errors     - Show recent errors (--last 24h)\n")
    cat("  stats      - Display log statistics (--date YYYY-MM-DD)\n")
    cat("  users      - Show active users and sessions\n")
    cat("  modules    - Analyze module usage\n")
    cat("  export     - Export logs (--format csv|json|rds --days 7)\n")
    cat("  dashboard  - Launch interactive dashboard\n")
    cat("\n")
    cat("Examples:\n")
    cat("  Rscript scripts/monitor_logs.R tail\n")
    cat("  Rscript scripts/monitor_logs.R errors --last 48h\n")
    cat("  Rscript scripts/monitor_logs.R stats --date 2025-10-27\n")
    cat("  Rscript scripts/monitor_logs.R export --format csv --days 7\n")
    cat("\n")
    return()
  }

  command <- args[1]

  # Parse additional options
  opts <- list()
  if (length(args) > 1) {
    for (i in seq(2, length(args), by = 2)) {
      if (i <= length(args)) {
        key <- gsub("^--", "", args[i])
        value <- if (i + 1 <= length(args)) args[i + 1] else TRUE
        opts[[key]] <- value
      }
    }
  }

  # Execute command
  tryCatch(
    {
      if (command == "tail") {
        cmd_tail()
      } else if (command == "errors") {
        cmd_errors(last = opts$last %||% "24h")
      } else if (command == "stats") {
        cmd_stats(date = opts$date)
      } else if (command == "users") {
        cmd_users()
      } else if (command == "modules") {
        cmd_modules()
      } else if (command == "export") {
        cmd_export(
          format = opts$format %||% "csv",
          output = opts$output,
          days = as.numeric(opts$days %||% 7)
        )
      } else if (command == "dashboard") {
        cmd_dashboard()
      } else {
        print_colored(paste("Unknown command:", command), COLOR_RED)
        print_colored("Run without arguments to see usage.", COLOR_YELLOW)
      }
    },
    error = function(e) {
      print_colored(paste("Error:", conditionMessage(e)), COLOR_RED)
    }
  )
}

# Run main if executed as script
if (!interactive()) {
  main()
}
