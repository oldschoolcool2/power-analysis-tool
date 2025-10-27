#!/usr/bin/env Rscript

#' Loggly Integration for Power Analysis Tool
#'
#' This script demonstrates how to send logs from the Power Analysis Tool
#' to Loggly cloud logging service using their HTTP Event API.
#'
#' Setup:
#' 1. Sign up for Loggly account at https://www.loggly.com/
#' 2. Get your customer token from Loggly dashboard
#' 3. Add to .Renviron:
#'    LOGGLY_TOKEN=your-customer-token-here
#'    LOGGLY_TAG=power-analysis-tool
#'
#' Usage:
#'   # Send recent logs to Loggly
#'   Rscript scripts/integrations/loggly_integration.R send
#'
#'   # Send logs from last N hours
#'   Rscript scripts/integrations/loggly_integration.R send --hours=24
#'
#'   # Test connection
#'   Rscript scripts/integrations/loggly_integration.R test
#'
#' Cron Setup (send logs every 5 minutes):
#'   */5 * * * * Rscript /path/to/loggly_integration.R send --hours=0.1

suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(logger)
})

# Configuration
LOGGLY_TOKEN <- Sys.getenv("LOGGLY_TOKEN", "")
LOGGLY_TAG <- Sys.getenv("LOGGLY_TAG", "power-analysis-tool")
LOGGLY_BULK_ENDPOINT <- sprintf(
  "https://logs-01.loggly.com/bulk/%s/tag/%s/",
  LOGGLY_TOKEN,
  LOGGLY_TAG
)

LOG_DIR <- "logs"
STATE_FILE <- file.path(LOG_DIR, ".loggly_state.rds")

# Maximum logs to send in single batch
BATCH_SIZE <- 100

#' Check Loggly Configuration
check_loggly_config <- function() {
  if (LOGGLY_TOKEN == "") {
    stop("LOGGLY_TOKEN not set in environment. Please add to .Renviron file.")
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
#'
#' @return POSIXct timestamp or NULL
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
#'
#' @param timestamp POSIXct timestamp
save_last_sent_time <- function(timestamp) {
  state <- list(last_sent_time = timestamp)
  saveRDS(state, STATE_FILE)
}

#' Send Logs to Loggly in Bulk
#'
#' @param logs Data frame of log entries
#' @return List with success status and response details
send_to_loggly <- function(logs) {
  if (nrow(logs) == 0) {
    return(list(success = TRUE, sent = 0, message = "No logs to send"))
  }

  # Convert logs to newline-delimited JSON (Loggly bulk format)
  log_json_lines <- sapply(1:nrow(logs), function(i) {
    log_entry <- as.list(logs[i, , drop = FALSE])
    # Add metadata
    log_entry$app <- "power-analysis-tool"
    log_entry$environment <- Sys.getenv("R_ENV", "production")
    log_entry$hostname <- Sys.info()["nodename"]

    toJSON(log_entry, auto_unbox = TRUE)
  })

  # Join with newlines for bulk API
  bulk_payload <- paste(log_json_lines, collapse = "\n")

  # Send to Loggly
  tryCatch(
    {
      response <- POST(
        LOGGLY_BULK_ENDPOINT,
        body = bulk_payload,
        content_type("application/json"),
        timeout(30)
      )

      if (status_code(response) == 200) {
        list(
          success = TRUE,
          sent = nrow(logs),
          message = sprintf("Successfully sent %d logs to Loggly", nrow(logs))
        )
      } else {
        list(
          success = FALSE,
          sent = 0,
          message = sprintf("Loggly API error: HTTP %d - %s",
                          status_code(response),
                          content(response, "text"))
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

#' Send Command - Send Recent Logs to Loggly
#'
#' @param hours Number of hours to look back (default: 1)
cmd_send <- function(hours = 1) {
  check_loggly_config()

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

    result <- send_to_loggly(batch)

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

  cat(sprintf("\n✓ Total: Successfully sent %d logs to Loggly\n", total_sent))
  invisible(list(success = TRUE, sent = total_sent))
}

#' Test Command - Test Loggly Connection
cmd_test <- function() {
  check_loggly_config()

  cat("Testing Loggly connection...\n")
  cat("Endpoint:", LOGGLY_BULK_ENDPOINT, "\n\n")

  # Send a test log entry
  test_log <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    level = "INFO",
    msg = "Test log entry from Power Analysis Tool",
    test = TRUE,
    stringsAsFactors = FALSE
  )

  result <- send_to_loggly(test_log)

  if (result$success) {
    cat("✓ Connection successful!\n")
    cat("✓ Test log sent to Loggly\n")
    cat("\nCheck your Loggly dashboard to verify the log arrived.\n")
    cat("It may take 1-2 minutes to appear.\n")
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
    cat("Loggly Integration for Power Analysis Tool\n\n")
    cat("Usage:\n")
    cat("  Rscript loggly_integration.R send [--hours=N]\n")
    cat("  Rscript loggly_integration.R test\n\n")
    cat("Commands:\n")
    cat("  send   Send recent logs to Loggly\n")
    cat("  test   Test Loggly connection\n\n")
    cat("Options:\n")
    cat("  --hours=N   Number of hours to look back (default: 1)\n")
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
