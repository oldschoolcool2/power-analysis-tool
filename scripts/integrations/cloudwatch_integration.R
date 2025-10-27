#!/usr/bin/env Rscript

#' AWS CloudWatch Integration for Power Analysis Tool
#'
#' This script demonstrates how to send logs from the Power Analysis Tool
#' to AWS CloudWatch Logs for centralized monitoring and analysis.
#'
#' Setup:
#' 1. Install AWS CLI and configure credentials:
#'    aws configure
#'
#' 2. Install required R packages:
#'    install.packages("paws.management")
#'
#' 3. Set environment variables in .Renviron:
#'    AWS_REGION=us-east-1
#'    CLOUDWATCH_LOG_GROUP=/power-analysis-tool/production
#'    CLOUDWATCH_LOG_STREAM=app-logs
#'
#' 4. Create log group in AWS:
#'    aws logs create-log-group --log-group-name /power-analysis-tool/production
#'
#' Usage:
#'   # Send recent logs to CloudWatch
#'   Rscript scripts/integrations/cloudwatch_integration.R send
#'
#'   # Send logs from last N hours
#'   Rscript scripts/integrations/cloudwatch_integration.R send --hours=24
#'
#'   # Test connection
#'   Rscript scripts/integrations/cloudwatch_integration.R test
#'
#'   # Create log group and stream
#'   Rscript scripts/integrations/cloudwatch_integration.R setup
#'
#' Cron Setup (send logs every 5 minutes):
#'   */5 * * * * Rscript /path/to/cloudwatch_integration.R send --hours=0.1

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
})

# Try to load paws.management, provide helpful error if missing
if (!requireNamespace("paws.management", quietly = TRUE)) {
  stop("Package 'paws.management' required but not installed.\n",
       "Install with: install.packages('paws.management')")
}
library(paws.management)

# Configuration
AWS_REGION <- Sys.getenv("AWS_REGION", "us-east-1")
LOG_GROUP <- Sys.getenv("CLOUDWATCH_LOG_GROUP", "/power-analysis-tool/production")
LOG_STREAM <- Sys.getenv("CLOUDWATCH_LOG_STREAM", "app-logs")

LOG_DIR <- "logs"
STATE_FILE <- file.path(LOG_DIR, ".cloudwatch_state.rds")

# Maximum events per batch (CloudWatch limit is 10,000)
BATCH_SIZE <- 100

#' Initialize CloudWatch Logs Client
init_cloudwatch <- function() {
  tryCatch(
    {
      client <- cloudwatchlogs(config = list(region = AWS_REGION))
      client
    },
    error = function(e) {
      stop("Failed to initialize CloudWatch client: ", conditionMessage(e), "\n",
           "Make sure AWS credentials are configured (run 'aws configure')")
    }
  )
}

#' Check CloudWatch Configuration
check_cloudwatch_config <- function() {
  if (!dir.exists(LOG_DIR)) {
    stop("Log directory '", LOG_DIR, "' not found.")
  }

  # Check AWS credentials
  if (Sys.getenv("AWS_ACCESS_KEY_ID") == "" && !file.exists("~/.aws/credentials")) {
    stop("AWS credentials not configured. Run 'aws configure' first.")
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

#' Save State (last sent time and sequence token)
save_state <- function(timestamp, sequence_token = NULL) {
  state <- list(
    last_sent_time = timestamp,
    sequence_token = sequence_token
  )
  saveRDS(state, STATE_FILE)
}

#' Get Sequence Token from State
get_sequence_token <- function() {
  if (!file.exists(STATE_FILE)) {
    return(NULL)
  }

  tryCatch(
    {
      state <- readRDS(STATE_FILE)
      state$sequence_token
    },
    error = function(e) NULL
  )
}

#' Ensure Log Group Exists
ensure_log_group <- function(client) {
  tryCatch(
    {
      client$describe_log_groups(logGroupNamePrefix = LOG_GROUP)
      TRUE
    },
    error = function(e) {
      if (grepl("ResourceNotFoundException", conditionMessage(e))) {
        cat("Creating log group:", LOG_GROUP, "\n")
        client$create_log_group(logGroupName = LOG_GROUP)
        TRUE
      } else {
        stop("Failed to check log group: ", conditionMessage(e))
      }
    }
  )
}

#' Ensure Log Stream Exists
ensure_log_stream <- function(client) {
  tryCatch(
    {
      client$describe_log_streams(
        logGroupName = LOG_GROUP,
        logStreamNamePrefix = LOG_STREAM
      )
      TRUE
    },
    error = function(e) {
      if (grepl("ResourceNotFoundException", conditionMessage(e))) {
        cat("Creating log stream:", LOG_STREAM, "\n")
        client$create_log_stream(
          logGroupName = LOG_GROUP,
          logStreamName = LOG_STREAM
        )
        TRUE
      } else {
        stop("Failed to check log stream: ", conditionMessage(e))
      }
    }
  )
}

#' Send Logs to CloudWatch
#'
#' @param client CloudWatch client
#' @param logs Data frame of log entries
#' @return List with success status and new sequence token
send_to_cloudwatch <- function(client, logs) {
  if (nrow(logs) == 0) {
    return(list(success = TRUE, sent = 0, message = "No logs to send"))
  }

  # Ensure resources exist
  ensure_log_group(client)
  ensure_log_stream(client)

  # Get sequence token for this stream
  sequence_token <- get_sequence_token()

  # Convert logs to CloudWatch format
  log_events <- lapply(1:nrow(logs), function(i) {
    log_entry <- logs[i, , drop = FALSE]

    # Calculate timestamp in milliseconds since epoch
    timestamp_ms <- if ("timestamp" %in% names(log_entry)) {
      as.numeric(log_entry$timestamp) * 1000
    } else {
      as.numeric(Sys.time()) * 1000
    }

    # Create message (JSON string)
    message <- toJSON(as.list(log_entry), auto_unbox = TRUE)

    list(
      timestamp = as.integer(timestamp_ms),
      message = as.character(message)
    )
  })

  # Sort by timestamp (CloudWatch requirement)
  log_events <- log_events[order(sapply(log_events, function(x) x$timestamp))]

  # Send to CloudWatch
  tryCatch(
    {
      params <- list(
        logGroupName = LOG_GROUP,
        logStreamName = LOG_STREAM,
        logEvents = log_events
      )

      if (!is.null(sequence_token)) {
        params$sequenceToken <- sequence_token
      }

      response <- do.call(client$put_log_events, params)

      # Save new sequence token
      new_token <- response$nextSequenceToken
      if ("timestamp" %in% names(logs)) {
        save_state(max(logs$timestamp, na.rm = TRUE), new_token)
      }

      list(
        success = TRUE,
        sent = nrow(logs),
        message = sprintf("Successfully sent %d logs to CloudWatch", nrow(logs)),
        sequence_token = new_token
      )
    },
    error = function(e) {
      list(
        success = FALSE,
        sent = 0,
        message = sprintf("CloudWatch API error: %s", conditionMessage(e))
      )
    }
  )
}

#' Send Command - Send Recent Logs to CloudWatch
cmd_send <- function(hours = 1) {
  check_cloudwatch_config()

  cat("Initializing CloudWatch client...\n")
  client <- init_cloudwatch()

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

  # Send in batches
  total_sent <- 0
  num_batches <- ceiling(nrow(logs) / BATCH_SIZE)

  for (batch_num in 1:num_batches) {
    start_idx <- (batch_num - 1) * BATCH_SIZE + 1
    end_idx <- min(batch_num * BATCH_SIZE, nrow(logs))
    batch <- logs[start_idx:end_idx, ]

    cat(sprintf("Sending batch %d/%d (%d logs)...\n",
               batch_num, num_batches, nrow(batch)))

    result <- send_to_cloudwatch(client, batch)

    if (result$success) {
      cat("✓", result$message, "\n")
      total_sent <- total_sent + result$sent
    } else {
      cat("✗", result$message, "\n")
      stop("Failed to send batch ", batch_num)
    }

    # Small delay between batches
    if (batch_num < num_batches) {
      Sys.sleep(0.2)
    }
  }

  cat(sprintf("\n✓ Total: Successfully sent %d logs to CloudWatch\n", total_sent))
  cat(sprintf("View logs at: https://console.aws.amazon.com/cloudwatch/home?region=%s#logsV2:log-groups/log-group/%s\n",
             AWS_REGION, URLencode(LOG_GROUP, reserved = TRUE)))

  invisible(list(success = TRUE, sent = total_sent))
}

#' Setup Command - Create CloudWatch Resources
cmd_setup <- function() {
  check_cloudwatch_config()

  cat("Setting up CloudWatch resources...\n")
  cat("Region:", AWS_REGION, "\n")
  cat("Log Group:", LOG_GROUP, "\n")
  cat("Log Stream:", LOG_STREAM, "\n\n")

  client <- init_cloudwatch()

  cat("Creating log group...\n")
  ensure_log_group(client)
  cat("✓ Log group ready\n\n")

  cat("Creating log stream...\n")
  ensure_log_stream(client)
  cat("✓ Log stream ready\n\n")

  cat("✓ Setup complete! You can now send logs to CloudWatch.\n")
  invisible(TRUE)
}

#' Test Command - Test CloudWatch Connection
cmd_test <- function() {
  check_cloudwatch_config()

  cat("Testing CloudWatch connection...\n")
  cat("Region:", AWS_REGION, "\n")
  cat("Log Group:", LOG_GROUP, "\n")
  cat("Log Stream:", LOG_STREAM, "\n\n")

  client <- init_cloudwatch()

  # Ensure resources exist
  ensure_log_group(client)
  ensure_log_stream(client)

  # Send a test log entry
  test_log <- data.frame(
    time = format(Sys.time(), "%Y-%m-%d %H:%M:%OS3"),
    level = "INFO",
    msg = "Test log entry from Power Analysis Tool",
    test = TRUE,
    timestamp = Sys.time(),
    stringsAsFactors = FALSE
  )

  result <- send_to_cloudwatch(client, test_log)

  if (result$success) {
    cat("✓ Connection successful!\n")
    cat("✓ Test log sent to CloudWatch\n\n")
    cat("View logs at:\n")
    cat(sprintf("https://console.aws.amazon.com/cloudwatch/home?region=%s#logsV2:log-groups/log-group/%s\n",
               AWS_REGION, URLencode(LOG_GROUP, reserved = TRUE)))
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
    cat("AWS CloudWatch Integration for Power Analysis Tool\n\n")
    cat("Usage:\n")
    cat("  Rscript cloudwatch_integration.R setup\n")
    cat("  Rscript cloudwatch_integration.R send [--hours=N]\n")
    cat("  Rscript cloudwatch_integration.R test\n\n")
    cat("Commands:\n")
    cat("  setup  Create log group and stream in CloudWatch\n")
    cat("  send   Send recent logs to CloudWatch\n")
    cat("  test   Test CloudWatch connection\n\n")
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
      if (command == "setup") {
        cmd_setup()
      } else if (command == "send") {
        cmd_send(hours = hours)
      } else if (command == "test") {
        cmd_test()
      } else {
        cat("Unknown command:", command, "\n")
        cat("Use 'setup', 'send', or 'test'\n")
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
