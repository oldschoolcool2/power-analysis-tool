#!/usr/bin/env Rscript

#' Grafana Loki Integration for Power Analysis Tool
#'
#' This script demonstrates how to send logs from the Power Analysis Tool
#' to Grafana Loki for log aggregation and analysis with Grafana.
#'
#' Setup:
#' 1. Install Grafana Loki (or use Grafana Cloud):
#'    https://grafana.com/docs/loki/latest/installation/
#'
#' 2. Add to .Renviron:
#'    LOKI_URL=http://localhost:3100
#'    LOKI_USERNAME=optional-basic-auth-user
#'    LOKI_PASSWORD=optional-basic-auth-password
#'    LOKI_TENANT_ID=optional-tenant-id
#'
#' 3. For Grafana Cloud, get your credentials from:
#'    https://grafana.com/profile/org/cloud
#'
#' Usage:
#'   # Send recent logs to Loki
#'   Rscript scripts/integrations/loki_integration.R send
#'
#'   # Send logs from last N hours
#'   Rscript scripts/integrations/loki_integration.R send --hours=24
#'
#'   # Test connection
#'   Rscript scripts/integrations/loki_integration.R test
#'
#' Cron Setup (send logs every 5 minutes):
#'   */5 * * * * Rscript /path/to/loki_integration.R send --hours=0.1

suppressPackageStartupMessages({
  library(httr)
  library(jsonlite)
  library(dplyr)
})

# Configuration
LOKI_URL <- Sys.getenv("LOKI_URL", "http://localhost:3100")
LOKI_USERNAME <- Sys.getenv("LOKI_USERNAME", "")
LOKI_PASSWORD <- Sys.getenv("LOKI_PASSWORD", "")
LOKI_TENANT_ID <- Sys.getenv("LOKI_TENANT_ID", "")

# Loki push API endpoint
LOKI_PUSH_ENDPOINT <- sprintf("%s/loki/api/v1/push", LOKI_URL)

LOG_DIR <- "logs"
STATE_FILE <- file.path(LOG_DIR, ".loki_state.rds")

# Maximum logs to send in single batch
BATCH_SIZE <- 100

#' Check Loki Configuration
check_loki_config <- function() {
  if (LOKI_URL == "") {
    stop("LOKI_URL not set in environment. Please add to .Renviron file.")
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

#' Convert Logs to Loki Format
#'
#' Loki uses a specific JSON format with streams and values.
#' Each stream has labels and an array of [timestamp, line] tuples.
#'
#' @param logs Data frame of log entries
#' @return List in Loki push API format
convert_to_loki_format <- function(logs) {
  # Group logs by level to create separate streams
  logs_by_level <- split(logs, logs$level)

  streams <- lapply(names(logs_by_level), function(level) {
    level_logs <- logs_by_level[[level]]

    # Create label set for this stream
    labels <- sprintf(
      '{app="power-analysis-tool",level="%s",environment="%s",hostname="%s"}',
      tolower(level),
      Sys.getenv("R_ENV", "production"),
      Sys.info()["nodename"]
    )

    # Create values array (timestamp in nanoseconds, log line)
    values <- lapply(1:nrow(level_logs), function(i) {
      log_entry <- level_logs[i, , drop = FALSE]

      # Timestamp in nanoseconds
      timestamp_ns <- if ("timestamp" %in% names(log_entry)) {
        sprintf("%.0f", as.numeric(log_entry$timestamp) * 1e9)
      } else {
        sprintf("%.0f", as.numeric(Sys.time()) * 1e9)
      }

      # Log line as JSON
      log_line <- toJSON(as.list(log_entry), auto_unbox = TRUE)

      list(timestamp_ns, as.character(log_line))
    })

    list(
      stream = jsonlite::parse_json(sprintf('{"labels": %s}', labels)),
      values = values
    )
  })

  list(streams = streams)
}

#' Send Logs to Loki
#'
#' @param logs Data frame of log entries
#' @return List with success status and response details
send_to_loki <- function(logs) {
  if (nrow(logs) == 0) {
    return(list(success = TRUE, sent = 0, message = "No logs to send"))
  }

  # Convert to Loki format
  loki_payload <- convert_to_loki_format(logs)

  # Prepare headers
  headers <- list(
    "Content-Type" = "application/json"
  )

  # Add tenant ID header if specified (for multi-tenant Loki)
  if (LOKI_TENANT_ID != "") {
    headers[["X-Scope-OrgID"]] <- LOKI_TENANT_ID
  }

  # Add authentication if specified
  auth <- if (LOKI_USERNAME != "" && LOKI_PASSWORD != "") {
    authenticate(LOKI_USERNAME, LOKI_PASSWORD, "basic")
  } else {
    NULL
  }

  # Send to Loki
  tryCatch(
    {
      request <- POST(
        LOKI_PUSH_ENDPOINT,
        body = toJSON(loki_payload, auto_unbox = TRUE),
        do.call(add_headers, headers),
        encode = "raw",
        timeout(30)
      )

      # Add authentication if needed
      if (!is.null(auth)) {
        request <- POST(
          LOKI_PUSH_ENDPOINT,
          body = toJSON(loki_payload, auto_unbox = TRUE),
          do.call(add_headers, headers),
          auth,
          encode = "raw",
          timeout(30)
        )
      } else {
        request <- POST(
          LOKI_PUSH_ENDPOINT,
          body = toJSON(loki_payload, auto_unbox = TRUE),
          do.call(add_headers, headers),
          encode = "raw",
          timeout(30)
        )
      }

      status <- status_code(request)

      if (status == 204) {
        # 204 No Content is success for Loki
        list(
          success = TRUE,
          sent = nrow(logs),
          message = sprintf("Successfully sent %d logs to Loki", nrow(logs))
        )
      } else {
        response_text <- tryCatch(
          content(request, "text", encoding = "UTF-8"),
          error = function(e) "Unable to parse response"
        )

        list(
          success = FALSE,
          sent = 0,
          message = sprintf("Loki API error: HTTP %d - %s", status, response_text)
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

#' Send Command - Send Recent Logs to Loki
cmd_send <- function(hours = 1) {
  check_loki_config()

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

    result <- send_to_loki(batch)

    if (result$success) {
      cat("✓", result$message, "\n")
      total_sent <- total_sent + result$sent
    } else {
      cat("✗", result$message, "\n")
      stop("Failed to send batch ", batch_num)
    }

    # Small delay between batches
    if (batch_num < num_batches) {
      Sys.sleep(0.3)
    }
  }

  # Save last sent timestamp
  if ("timestamp" %in% names(logs)) {
    last_timestamp <- max(logs$timestamp, na.rm = TRUE)
    save_last_sent_time(last_timestamp)
  }

  cat(sprintf("\n✓ Total: Successfully sent %d logs to Loki\n", total_sent))

  # Construct Grafana explore URL
  grafana_url <- gsub(":3100$", ":3000", LOKI_URL)  # Assume Grafana on 3000
  cat(sprintf("\nView logs in Grafana:\n%s/explore\n", grafana_url))

  invisible(list(success = TRUE, sent = total_sent))
}

#' Test Command - Test Loki Connection
cmd_test <- function() {
  check_loki_config()

  cat("Testing Loki connection...\n")
  cat("Loki URL:", LOKI_URL, "\n")
  cat("Push Endpoint:", LOKI_PUSH_ENDPOINT, "\n")
  if (LOKI_USERNAME != "") {
    cat("Authentication: Enabled (Basic Auth)\n")
  } else {
    cat("Authentication: None\n")
  }
  if (LOKI_TENANT_ID != "") {
    cat("Tenant ID:", LOKI_TENANT_ID, "\n")
  }
  cat("\n")

  # Send a test log entry
  test_log <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    level = "INFO",
    msg = "Test log entry from Power Analysis Tool",
    test = TRUE,
    timestamp = Sys.time(),
    stringsAsFactors = FALSE
  )

  result <- send_to_loki(test_log)

  if (result$success) {
    cat("✓ Connection successful!\n")
    cat("✓ Test log sent to Loki\n\n")

    grafana_url <- gsub(":3100$", ":3000", LOKI_URL)
    cat("View logs in Grafana Explore:\n")
    cat(sprintf("%s/explore\n", grafana_url))
    cat("\nExample LogQL query:\n")
    cat('{app="power-analysis-tool"} |= "test"\n')
  } else {
    cat("✗ Connection failed:\n")
    cat(result$message, "\n\n")
    cat("Troubleshooting:\n")
    cat("- Verify Loki is running: curl ", LOKI_URL, "/ready\n", sep = "")
    cat("- Check LOKI_URL is correct\n")
    cat("- If using authentication, verify credentials\n")
  }

  invisible(result)
}

#' Main CLI Entry Point
main <- function() {
  args <- commandArgs(trailingOnly = TRUE)

  if (length(args) == 0) {
    cat("Grafana Loki Integration for Power Analysis Tool\n\n")
    cat("Usage:\n")
    cat("  Rscript loki_integration.R send [--hours=N]\n")
    cat("  Rscript loki_integration.R test\n\n")
    cat("Commands:\n")
    cat("  send   Send recent logs to Loki\n")
    cat("  test   Test Loki connection\n\n")
    cat("Options:\n")
    cat("  --hours=N   Number of hours to look back (default: 1)\n\n")
    cat("Environment Variables:\n")
    cat("  LOKI_URL          Loki URL (default: http://localhost:3100)\n")
    cat("  LOKI_USERNAME     Optional: Basic auth username\n")
    cat("  LOKI_PASSWORD     Optional: Basic auth password\n")
    cat("  LOKI_TENANT_ID    Optional: Multi-tenant org ID\n")
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
