#!/usr/bin/env Rscript

#' Email Alert System for Application Logs
#'
#' Monitors application logs and sends email alerts when:
#' - Error count exceeds threshold
#' - Critical errors occur
#' - Application stops responding
#' - Custom conditions are met
#'
#' Usage:
#'   Rscript scripts/alert_email.R [check|summary] [options]
#'
#' Commands:
#'   check   - Check for errors and alert if threshold exceeded
#'   summary - Send daily/weekly summary report
#'
#' Setup:
#'   1. Configure email settings in .Renviron:
#'      ALERT_EMAIL_FROM=alerts@yourapp.com
#'      ALERT_EMAIL_TO=ops@yourcompany.com
#'      ALERT_EMAIL_CC=dev@yourcompany.com
#'      SMTP_SERVER=smtp.gmail.com
#'      SMTP_PORT=587
#'      SMTP_USER=your-email@gmail.com
#'      SMTP_PASSWORD=your-app-password
#'
#'   2. Add to crontab for automated checking:
#'      */15 * * * * Rscript /path/to/alert_email.R check
#'      0 8 * * 1 Rscript /path/to/alert_email.R summary

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
  library(lubridate)
})

# ============================================================================
# Configuration
# ============================================================================

LOG_DIR <- Sys.getenv("PAT_LOG_DIR", "./logs")

# Alert thresholds
ERROR_THRESHOLD_PER_HOUR <- 10
ERROR_THRESHOLD_CRITICAL <- 50  # Immediate alert

# Email configuration
EMAIL_FROM <- Sys.getenv("ALERT_EMAIL_FROM", "alerts@poweranalysis.com")
EMAIL_TO <- Sys.getenv("ALERT_EMAIL_TO", "ops@company.com")
EMAIL_CC <- Sys.getenv("ALERT_EMAIL_CC", "")
SMTP_SERVER <- Sys.getenv("SMTP_SERVER", "smtp.gmail.com")
SMTP_PORT <- as.integer(Sys.getenv("SMTP_PORT", "587"))
SMTP_USER <- Sys.getenv("SMTP_USER", "")
SMTP_PASSWORD <- Sys.getenv("SMTP_PASSWORD", "")

# Alert state file (prevents duplicate alerts)
STATE_FILE <- file.path(LOG_DIR, ".alert_state.rds")

# ============================================================================
# Helper Functions
# ============================================================================

#' Read logs from specified time range
#' @param hours Number of hours to look back
#' @return Data frame with parsed logs
read_recent_logs <- function(hours = 1) {
  log_files <- list.files(
    LOG_DIR,
    pattern = "^app_.*\\.log$",
    full.names = TRUE
  )

  cutoff_time <- Sys.time() - hours * 3600

  # Filter by modification time
  recent_files <- log_files[file.mtime(log_files) > cutoff_time - 86400]

  if (length(recent_files) == 0) {
    return(data.frame())
  }

  # Read and parse
  all_logs <- lapply(recent_files, function(file) {
    lines <- readLines(file, warn = FALSE)
    parsed <- lapply(lines, function(line) {
      tryCatch(fromJSON(line), error = function(e) NULL)
    })
    parsed <- Filter(Negate(is.null), parsed)

    if (length(parsed) > 0) {
      df <- bind_rows(parsed)
      if ("time" %in% names(df)) {
        df$timestamp <- as.POSIXct(df$time, format = "%Y-%m-%d %H:%M:%OS")
      }
      df
    } else {
      data.frame()
    }
  })

  logs <- if (length(all_logs) > 0) bind_rows(all_logs) else data.frame()

  # Filter by timestamp
  if (nrow(logs) > 0 && "timestamp" %in% names(logs)) {
    logs <- logs %>% filter(timestamp >= cutoff_time)
  }

  logs
}

#' Load alert state
#' @return List with state information
load_alert_state <- function() {
  if (file.exists(STATE_FILE)) {
    readRDS(STATE_FILE)
  } else {
    list(
      last_alert_time = NULL,
      last_error_count = 0,
      consecutive_alerts = 0
    )
  }
}

#' Save alert state
#' @param state State list to save
save_alert_state <- function(state) {
  saveRDS(state, STATE_FILE)
}

#' Send email using system mail command or mailR
#' @param subject Email subject
#' @param body Email body (HTML)
#' @param to Recipient email
#' @param from Sender email
#' @return Logical success
send_email <- function(subject, body, to = EMAIL_TO, from = EMAIL_FROM) {
  # Try to use mailR package if available
  if (requireNamespace("mailR", quietly = TRUE)) {
    tryCatch(
      {
        mailR::send.mail(
          from = from,
          to = to,
          subject = subject,
          body = body,
          html = TRUE,
          smtp = list(
            host.name = SMTP_SERVER,
            port = SMTP_PORT,
            user.name = SMTP_USER,
            passwd = SMTP_PASSWORD,
            ssl = TRUE
          ),
          authenticate = TRUE
        )
        return(TRUE)
      },
      error = function(e) {
        warning("mailR failed: ", conditionMessage(e))
        return(FALSE)
      }
    )
  }

  # Fallback: Use system mail command (Linux/Mac)
  if (Sys.which("mail") != "") {
    temp_file <- tempfile(fileext = ".html")
    writeLines(c(
      "MIME-Version: 1.0",
      "Content-Type: text/html; charset=utf-8",
      "",
      body
    ), temp_file)

    cmd <- sprintf(
      "mail -s '%s' -a 'Content-Type: text/html' %s < %s",
      subject, to, temp_file
    )

    result <- system(cmd, ignore.stdout = TRUE, ignore.stderr = TRUE)
    unlink(temp_file)

    return(result == 0)
  }

  # No email method available
  warning("No email method available. Install mailR package or configure system mail.")
  return(FALSE)
}

#' Create HTML email body for error alert
#' @param errors Error log entries
#' @param error_count Total error count
#' @return HTML string
create_error_alert_html <- function(errors, error_count) {
  html <- paste0(
    "<!DOCTYPE html><html><head>",
    "<style>",
    "body { font-family: Arial, sans-serif; }",
    "table { border-collapse: collapse; width: 100%; margin-top: 20px; }",
    "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }",
    "th { background-color: #f2f2f2; }",
    ".error { color: #d32f2f; font-weight: bold; }",
    ".warning { color: #f57c00; }",
    ".summary { background-color: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }",
    "</style></head><body>",
    "<h2 style='color: #d32f2f;'>⚠️ Error Alert - Power Analysis Tool</h2>",
    "<div class='summary'>",
    "<p><strong>Alert triggered at:</strong> ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "</p>",
    "<p><strong>Total errors in last hour:</strong> <span class='error'>", error_count, "</span></p>",
    "<p><strong>Threshold:</strong> ", ERROR_THRESHOLD_PER_HOUR, " errors/hour</p>",
    "</div>"
  )

  if (nrow(errors) > 0) {
    html <- paste0(
      html,
      "<h3>Recent Errors (Last 10):</h3>",
      "<table>",
      "<tr><th>Time</th><th>Level</th><th>Message</th><th>Module</th></tr>"
    )

    for (i in seq_len(min(nrow(errors), 10))) {
      err <- errors[i, ]
      html <- paste0(
        html,
        "<tr>",
        "<td>", format(err$timestamp, "%H:%M:%S"), "</td>",
        "<td><span class='", tolower(err$level), "'>", err$level, "</span></td>",
        "<td>", htmltools::htmlEscape(err$msg %||% ""), "</td>",
        "<td>", htmltools::htmlEscape(err$module %||% "N/A"), "</td>",
        "</tr>"
      )
    }

    html <- paste0(html, "</table>")
  }

  html <- paste0(
    html,
    "<hr>",
    "<p style='color: #666; font-size: 12px;'>",
    "This is an automated alert from the Power Analysis Tool monitoring system. ",
    "To view full logs, access the monitoring dashboard or check logs in: ", LOG_DIR,
    "</p>",
    "</body></html>"
  )

  html
}

#' Create HTML email body for summary report
#' @param logs All logs for the period
#' @param period Period description (e.g., "Daily", "Weekly")
#' @return HTML string
create_summary_html <- function(logs, period = "Daily") {
  if (nrow(logs) == 0) {
    return(paste0(
      "<!DOCTYPE html><html><body>",
      "<h2>", period, " Summary - Power Analysis Tool</h2>",
      "<p>No log activity in this period.</p>",
      "</body></html>"
    ))
  }

  # Calculate statistics
  error_count <- sum(toupper(logs$level) == "ERROR", na.rm = TRUE)
  warn_count <- sum(toupper(logs$level) == "WARN", na.rm = TRUE)
  info_count <- sum(toupper(logs$level) == "INFO", na.rm = TRUE)
  session_count <- n_distinct(logs$session_id, na.rm = TRUE)

  # Top modules
  top_modules <- logs %>%
    filter(!is.na(module), module != "") %>%
    count(module, sort = TRUE) %>%
    head(5)

  # Recent errors
  recent_errors <- logs %>%
    filter(toupper(level) %in% c("ERROR", "WARN")) %>%
    arrange(desc(timestamp)) %>%
    head(10)

  html <- paste0(
    "<!DOCTYPE html><html><head>",
    "<style>",
    "body { font-family: Arial, sans-serif; }",
    "table { border-collapse: collapse; width: 100%; margin-top: 20px; }",
    "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }",
    "th { background-color: #f2f2f2; }",
    ".stat-box { display: inline-block; margin: 10px; padding: 15px; border-radius: 5px; background-color: #f8f9fa; }",
    ".error { color: #d32f2f; }",
    ".success { color: #388e3c; }",
    "</style></head><body>",
    "<h2>", period, " Summary - Power Analysis Tool</h2>",
    "<p><strong>Report Period:</strong> ", format(min(logs$timestamp), "%Y-%m-%d %H:%M"), " to ",
    format(max(logs$timestamp), "%Y-%m-%d %H:%M"), "</p>",
    "<div>",
    "<div class='stat-box'><strong>Total Logs:</strong> ", nrow(logs), "</div>",
    "<div class='stat-box'><strong>Sessions:</strong> ", session_count, "</div>",
    "<div class='stat-box'><strong>Info:</strong> <span class='success'>", info_count, "</span></div>",
    "<div class='stat-box'><strong>Warnings:</strong> ", warn_count, "</div>",
    "<div class='stat-box'><strong>Errors:</strong> <span class='error'>", error_count, "</span></div>",
    "</div>"
  )

  # Add top modules
  if (nrow(top_modules) > 0) {
    html <- paste0(
      html,
      "<h3>Top Modules:</h3>",
      "<ol>"
    )
    for (i in seq_len(nrow(top_modules))) {
      html <- paste0(html, "<li>", top_modules$module[i], " (", top_modules$n[i], " events)</li>")
    }
    html <- paste0(html, "</ol>")
  }

  # Add recent errors
  if (nrow(recent_errors) > 0) {
    html <- paste0(
      html,
      "<h3>Recent Errors/Warnings:</h3>",
      "<table>",
      "<tr><th>Time</th><th>Level</th><th>Message</th></tr>"
    )

    for (i in seq_len(min(nrow(recent_errors), 10))) {
      err <- recent_errors[i, ]
      html <- paste0(
        html,
        "<tr>",
        "<td>", format(err$timestamp, "%Y-%m-%d %H:%M"), "</td>",
        "<td>", err$level, "</td>",
        "<td>", htmltools::htmlEscape(substr(err$msg %||% "", 1, 100)), "</td>",
        "</tr>"
      )
    }

    html <- paste0(html, "</table>")
  } else {
    html <- paste0(html, "<p class='success'><strong>✓ No errors or warnings in this period!</strong></p>")
  }

  html <- paste0(
    html,
    "<hr>",
    "<p style='color: #666; font-size: 12px;'>",
    "This is an automated summary from the Power Analysis Tool monitoring system.",
    "</p>",
    "</body></html>"
  )

  html
}

# ============================================================================
# Command: check - Check for errors and alert
# ============================================================================

cmd_check <- function() {
  cat("Checking for errors...\n")

  # Read last hour of logs
  logs <- read_recent_logs(hours = 1)

  if (nrow(logs) == 0) {
    cat("No logs found in the last hour.\n")
    return()
  }

  # Count errors
  errors <- logs %>%
    filter(toupper(level) == "ERROR") %>%
    arrange(desc(timestamp))

  error_count <- nrow(errors)

  cat("Found", error_count, "errors in the last hour.\n")

  # Load state to avoid duplicate alerts
  state <- load_alert_state()

  # Determine if alert should be sent
  should_alert <- FALSE
  alert_reason <- ""

  if (error_count >= ERROR_THRESHOLD_CRITICAL) {
    should_alert <- TRUE
    alert_reason <- "critical"
    cat("CRITICAL: Error count exceeds critical threshold (", ERROR_THRESHOLD_CRITICAL, ")\n")
  } else if (error_count >= ERROR_THRESHOLD_PER_HOUR) {
    # Check if we already alerted recently
    if (is.null(state$last_alert_time) ||
        difftime(Sys.time(), state$last_alert_time, units = "hours") >= 1) {
      should_alert <- TRUE
      alert_reason <- "threshold"
      cat("WARNING: Error count exceeds hourly threshold (", ERROR_THRESHOLD_PER_HOUR, ")\n")
    } else {
      cat("Threshold exceeded but alert suppressed (recently alerted)\n")
    }
  } else {
    cat("Error count within acceptable range.\n")
  }

  if (should_alert) {
    # Send alert
    subject <- sprintf(
      "[ALERT] Power Analysis Tool - %s errors detected",
      if (alert_reason == "critical") "CRITICAL" else "High error count"
    )

    body <- create_error_alert_html(errors, error_count)

    cat("Sending email alert to:", EMAIL_TO, "\n")

    success <- send_email(subject, body)

    if (success) {
      cat("Alert sent successfully.\n")

      # Update state
      state$last_alert_time <- Sys.time()
      state$last_error_count <- error_count
      state$consecutive_alerts <- (state$consecutive_alerts %||% 0) + 1
      save_alert_state(state)
    } else {
      cat("Failed to send alert email.\n")
    }
  } else {
    # Reset consecutive alerts if no errors
    if (error_count == 0 && !is.null(state$consecutive_alerts)) {
      state$consecutive_alerts <- 0
      save_alert_state(state)
    }
  }
}

# ============================================================================
# Command: summary - Send summary report
# ============================================================================

cmd_summary <- function(period = "daily") {
  cat("Generating summary report...\n")

  # Determine time range
  hours <- if (period == "daily") 24 else 168  # 7 days

  # Read logs
  logs <- read_recent_logs(hours = hours)

  if (nrow(logs) == 0) {
    cat("No logs found for summary period.\n")
    return()
  }

  # Create summary
  subject <- sprintf(
    "[Summary] Power Analysis Tool - %s Report",
    tools::toTitleCase(period)
  )

  body <- create_summary_html(logs, tools::toTitleCase(period))

  cat("Sending summary email to:", EMAIL_TO, "\n")

  success <- send_email(subject, body)

  if (success) {
    cat("Summary sent successfully.\n")
  } else {
    cat("Failed to send summary email.\n")
  }
}

# ============================================================================
# Main Entry Point
# ============================================================================

main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    cat("\nPower Analysis Tool - Email Alert System\n\n")
    cat("Usage: Rscript scripts/alert_email.R [command] [options]\n\n")
    cat("Commands:\n")
    cat("  check                 - Check for errors and send alerts\n")
    cat("  summary [daily|weekly] - Send summary report (default: daily)\n")
    cat("\nSetup:\n")
    cat("  Configure email settings in .Renviron:\n")
    cat("    ALERT_EMAIL_FROM, ALERT_EMAIL_TO, SMTP_SERVER, etc.\n")
    cat("\nExample crontab entries:\n")
    cat("  */15 * * * * Rscript /path/to/alert_email.R check\n")
    cat("  0 8 * * 1 Rscript /path/to/alert_email.R summary weekly\n\n")
    return()
  }

  command <- args[1]

  tryCatch(
    {
      if (command == "check") {
        cmd_check()
      } else if (command == "summary") {
        period <- if (length(args) >= 2) args[2] else "daily"
        cmd_summary(period)
      } else {
        cat("Unknown command:", command, "\n")
        cat("Run without arguments to see usage.\n")
      }
    },
    error = function(e) {
      cat("Error:", conditionMessage(e), "\n")
    }
  )
}

# Null-coalescing operator
`%||%` <- function(a, b) if (is.null(a)) b else a

# Run main if executed as script
if (!interactive()) {
  main()
}
