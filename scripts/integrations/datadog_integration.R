#!/usr/bin/env Rscript

#' Datadog Integration for Power Analysis Tool
#'
#' This script demonstrates how to send logs from the Power Analysis Tool
#' to Datadog for monitoring, alerting, and analytics.
#'
#' Setup:
#' 1. Sign up for Datadog at https://www.datadoghq.com/
#' 2. Get your API key from Datadog dashboard (Organization Settings > API Keys)
#' 3. Add to .Renviron:
#'    DATADOG_API_KEY=your-api-key-here
#'    DATADOG_SITE=datadoghq.com  # or datadoghq.eu for EU
#'    DATADOG_SERVICE=power-analysis-tool
#'    DATADOG_ENV=production
#'
#' Usage:
#'   # Send recent logs to Datadog
#'   Rscript scripts/integrations/datadog_integration.R send
#'
#'   # Send logs from last N hours
#'   Rscript scripts/integrations/datadog_integration.R send --hours=24
#'
#'   # Test connection
#'   Rscript scripts/integrations/datadog_integration.R test
#'
#' Cron Setup (send logs every 5 minutes):
#'   */5 * * * * Rscript /path/to/datadog_integration.R send --hours=0.1

suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
})

# Configuration
DATADOG_API_KEY <- Sys.getenv("DATADOG_API_KEY", "")
DATADOG_SITE <- Sys.getenv("DATADOG_SITE", "datadoghq.com")
DATADOG_SERVICE <- Sys.getenv("DATADOG_SERVICE", "power-analysis-tool")
DATADOG_ENV <- Sys.getenv("DATADOG_ENV", "production")

# Datadog Log API endpoint
DATADOG_API_ENDPOINT <- sprintf("https://http-intake.logs.%s/api/v2/logs", DATADOG_SITE)

LOG_DIR <- "logs"
STATE_FILE <- file.path(LOG_DIR, ".datadog_state.rds")

# Maximum logs to send in single batch (Datadog recommends < 5MB per request)
BATCH_SIZE <- 100

#' Check Datadog Configuration
check_datadog_config <- function() {
  if (DATADOG_API_KEY == "") {
    stop("DATADOG_API_KEY not set in environment. Please add to .Renviron file.")
  }

  if (!dir.exists(LOG_DIR)) {
    stop("Log directory '", LOG_DIR, "' not found.")
  }

  invisible(TRUE)
}

#' Read Recent Logs
#'
#' @param hours Number of hours to look back
#' @return Data frame of log entries
read_recent_logs <- function(hours = 1) {
  log_files <- list.files(LOG_DIR, pattern = "^app_.*\\.log$", full.names = TRUE)

  if (length(log_files) == 0) {
    return(data.frame())
  }

  cutoff_time <- Sys.time() - as.difftime(hours, units = "hours")
  recent_files <- log_files[file.mtime(log_files) > cutoff_time]

  if (length(recent_files) == 0) {
    return(data.frame())
  }

  all_logs <- lapply(recent_files, function(file) {
    lines <- readLines(file, warn = FALSE)
    parsed_logs <- lapply(lines, function(line) {
      tryCatch(
        fromJSON(line),
        error = function(e) NULL
      )
    })

    valid_logs <- Filter(Negate(is.null), parsed_logs)
    if (length(valid_logs) == 0) return(NULL)

    bind_rows(valid_logs)
  })

  logs <- bind_rows(Filter(Negate(is.null), all_logs))

  if (nrow(logs) > 0 && "time" %in% names(logs)) {
    logs <- logs %>%
      mutate(timestamp = as.POSIXct(time, format = "%Y-%m-%d %H:%M:%OS", tz = "UTC")) %>%
      filter(timestamp > cutoff_time)
  }

  logs
}

#' Get Last Sent Timestamp from State
get_last_sent_time <- function() {
  if (!file.exists(STATE_FILE)) {
    return(NULL)
  }

  tryCatch(
    {
      state <- readRDS(STATE_FILE)
      state$last_sent_time
    },
    error = function(e) NULL
  )
}

#' Save Last Sent Timestamp to State
save_last_sent_time <- function(timestamp) {
  state <- list(last_sent_time = timestamp)
  saveRDS(state, STATE_FILE)
}

#' Map Logger Level to Datadog Status
#'
#' @param level Logger level string
#' @return Datadog status string
map_log_level <- function(level) {
  level_upper <- toupper(as.character(level))

  switch(level_upper,
    "FATAL" = "emergency",
    "ERROR" = "error",
    "WARN" = "warn",
    "WARNING" = "warn",
    "SUCCESS" = "info",
    "INFO" = "info",
    "DEBUG" = "debug",
    "TRACE" = "debug",
    "info"  # default
  )
}

#' Convert Logs to Datadog Format
#'
#' @param logs Data frame of log entries
#' @return List of Datadog log objects
convert_to_datadog_format <- function(logs) {
  lapply(1:nrow(logs), function(i) {
    log_entry <- logs[i, , drop = FALSE]

    # Calculate timestamp in milliseconds
    timestamp_ms <- if ("timestamp" %in% names(log_entry)) {
      as.numeric(log_entry$timestamp) * 1000
    } else {
      as.numeric(Sys.time()) * 1000
    }

    # Extract level and map to Datadog status
    level <- if ("level" %in% names(log_entry)) {
      as.character(log_entry$level)
    } else {
      "INFO"
    }
    status <- map_log_level(level)

    # Extract message
    message <- if ("msg" %in% names(log_entry)) {
      as.character(log_entry$msg)
    } else {
      "Log entry"
    }

    # Build attributes from all other fields
    attributes <- as.list(log_entry)
    attributes$timestamp <- NULL  # Remove, will be top-level
    attributes$level <- level      # Keep original level in attributes
    attributes$msg <- NULL         # Remove, will be in message

    # Add service and environment tags
    attributes$service <- DATADOG_SERVICE
    attributes$env <- DATADOG_ENV
    attributes$hostname <- Sys.info()["nodename"]

    # Datadog log format
    list(
      ddsource = "r-shiny",
      ddtags = sprintf("env:%s,service:%s", DATADOG_ENV, DATADOG_SERVICE),
      hostname = Sys.info()["nodename"],
      message = message,
      status = status,
      timestamp = as.character(as.integer(timestamp_ms)),
      attributes = attributes
    )
  })
}

#' Send Logs to Datadog
#'
#' @param logs Data frame of log entries
#' @return List with success status and response details
send_to_datadog <- function(logs) {
  if (nrow(logs) == 0) {
    return(list(success = TRUE, sent = 0, message = "No logs to send"))
  }

  # Convert to Datadog format
  datadog_logs <- convert_to_datadog_format(logs)

  # Send to Datadog
  tryCatch(
    {
      response <- POST(
        DATADOG_API_ENDPOINT,
        add_headers(
          "DD-API-KEY" = DATADOG_API_KEY,
          "Content-Type" = "application/json"
        ),
        body = toJSON(datadog_logs, auto_unbox = TRUE),
        encode = "raw",
        timeout(30)
      )

      if (status_code(response) == 202) {
        # 202 Accepted is success for Datadog logs API
        list(
          success = TRUE,
          sent = nrow(logs),
          message = sprintf("Successfully sent %d logs to Datadog", nrow(logs))
        )
      } else {
        response_text <- tryCatch(
          content(response, "text", encoding = "UTF-8"),
          error = function(e) "Unable to parse response"
        )

        list(
          success = FALSE,
          sent = 0,
          message = sprintf("Datadog API error: HTTP %d - %s",
                          status_code(response),
                          response_text)
        )
      }
    },
    error = function(e) {
      list(
        success = FALSE,
        sent = 0,
        message = sprintf("Failed to send logs: %s", conditionMessage(e))
      )
    }
  )
}

#' Send Command - Send Recent Logs to Datadog
cmd_send <- function(hours = 1) {
  check_datadog_config()

  cat("Reading logs from last", hours, "hour(s)...\n")
  logs <- read_recent_logs(hours)

  if (nrow(logs) == 0) {
    cat("No logs found in specified time range.\n")
    return(invisible(NULL))
  }

  # Filter to only send logs newer than last sent time
  last_sent <- get_last_sent_time()
  if (!is.null(last_sent) && "timestamp" %in% names(logs)) {
    logs <- logs %>% filter(timestamp > last_sent)
  }

  if (nrow(logs) == 0) {
    cat("No new logs to send (already sent previously).\n")
    return(invisible(NULL))
  }

  cat("Found", nrow(logs), "log entries to send.\n")

  # Send in batches if needed
  total_sent <- 0
  num_batches <- ceiling(nrow(logs) / BATCH_SIZE)

  for (batch_num in 1:num_batches) {
    start_idx <- (batch_num - 1) * BATCH_SIZE + 1
    end_idx <- min(batch_num * BATCH_SIZE, nrow(logs))
    batch <- logs[start_idx:end_idx, ]

    cat(sprintf("Sending batch %d/%d (%d logs)...\n",
               batch_num, num_batches, nrow(batch)))

    result <- send_to_datadog(batch)

    if (result$success) {
      cat("✓", result$message, "\n")
      total_sent <- total_sent + result$sent
    } else {
      cat("✗", result$message, "\n")
      stop("Failed to send batch ", batch_num)
    }

    # Small delay between batches to avoid rate limits
    if (batch_num < num_batches) {
      Sys.sleep(0.5)
    }
  }

  # Save last sent timestamp
  if ("timestamp" %in% names(logs)) {
    last_timestamp <- max(logs$timestamp, na.rm = TRUE)
    save_last_sent_time(last_timestamp)
  }

  cat(sprintf("\n✓ Total: Successfully sent %d logs to Datadog\n", total_sent))
  cat(sprintf("\nView logs at: https://app.%s/logs?query=service:%s\n",
             DATADOG_SITE, DATADOG_SERVICE))

  invisible(list(success = TRUE, sent = total_sent))
}

#' Test Command - Test Datadog Connection
cmd_test <- function() {
  check_datadog_config()

  cat("Testing Datadog connection...\n")
  cat("API Endpoint:", DATADOG_API_ENDPOINT, "\n")
  cat("Service:", DATADOG_SERVICE, "\n")
  cat("Environment:", DATADOG_ENV, "\n\n")

  # Send a test log entry
  test_log <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    level = "INFO",
    msg = "Test log entry from Power Analysis Tool",
    test = TRUE,
    timestamp = Sys.time(),
    stringsAsFactors = FALSE
  )

  result <- send_to_datadog(test_log)

  if (result$success) {
    cat("✓ Connection successful!\n")
    cat("✓ Test log sent to Datadog\n\n")
    cat("View your logs at:\n")
    cat(sprintf("https://app.%s/logs?query=service:%s\n",
               DATADOG_SITE, DATADOG_SERVICE))
    cat("\nNote: It may take 1-2 minutes for logs to appear in Datadog.\n")
  } else {
    cat("✗ Connection failed:\n")
    cat(result$message, "\n")
  }

  invisible(result)
}

#' Main CLI Entry Point
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    cat("Datadog Integration for Power Analysis Tool\n\n")
    cat("Usage:\n")
    cat("  Rscript datadog_integration.R send [--hours=N]\n")
    cat("  Rscript datadog_integration.R test\n\n")
    cat("Commands:\n")
    cat("  send   Send recent logs to Datadog\n")
    cat("  test   Test Datadog connection\n\n")
    cat("Options:\n")
    cat("  --hours=N   Number of hours to look back (default: 1)\n\n")
    cat("Environment Variables Required:\n")
    cat("  DATADOG_API_KEY     Your Datadog API key\n")
    cat("  DATADOG_SITE        datadoghq.com (US) or datadoghq.eu (EU)\n")
    cat("  DATADOG_SERVICE     Service name (default: power-analysis-tool)\n")
    cat("  DATADOG_ENV         Environment (default: production)\n")
    quit(status = 1)
  }

  command <- args[1]

  # Parse options
  hours <- 1
  for (arg in args[-1]) {
    if (grepl("^--hours=", arg)) {
      hours <- as.numeric(sub("^--hours=", "", arg))
    }
  }

  tryCatch(
    {
      if (command == "send") {
        cmd_send(hours = hours)
      } else if (command == "test") {
        cmd_test()
      } else {
        cat("Unknown command:", command, "\n")
        cat("Use 'send' or 'test'\n")
        quit(status = 1)
      }
    },
    error = function(e) {
      cat("Error:", conditionMessage(e), "\n")
      quit(status = 1)
    }
  )
}

# Run if called as script
if (!interactive()) {
  main()
}
