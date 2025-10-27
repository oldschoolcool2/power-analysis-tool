#' Integration Tests for Logging System
#'
#' Tests the complete logging flow from module initialization through
#' calculation execution to cleanup. These tests verify that logging
#' works correctly in realistic usage scenarios.
#'
#' Test Coverage:
#' - Module lifecycle (init → calculate → cleanup)
#' - Business logic function logging
#' - Error handling and logging
#' - Performance measurement
#' - Session context tracking
#' - Multi-module scenarios

library(testthat)
library(shiny)
library(logger)

# ============================================================================
# Setup: Configure logger for testing
# ============================================================================

# Store original log level
original_log_level <- logger::log_threshold()

# Set to TRACE for comprehensive testing
logger::log_threshold(logger::TRACE)

# Create a temporary log appender that captures logs in memory
test_logs <- NULL
test_appender <- function(lines) {
  test_logs <<- c(test_logs, lines)
}

# Save original appender
original_appender <- logger::log_appender()

# Use test appender
logger::log_appender(test_appender)

# Cleanup function
teardown({
  logger::log_threshold(original_log_level)
  logger::log_appender(original_appender)
})

# ============================================================================
# Helper Functions
# ============================================================================

#' Create mock Shiny session for testing
create_mock_session <- function(session_id = "test_session_123") {
  list(
    token = session_id,
    user = "test_user",
    clientData = list(),
    request = list(
      REMOTE_ADDR = "127.0.0.1",
      HTTP_USER_AGENT = "Test Browser"
    )
  )
}

#' Extract log entries matching pattern
filter_logs <- function(pattern) {
  matching <- grep(pattern, test_logs, value = TRUE, ignore.case = TRUE)
  matching
}

#' Count log entries by level
count_logs_by_level <- function(level) {
  pattern <- paste0('"level":"', toupper(level), '"')
  length(grep(pattern, test_logs))
}

# ============================================================================
# Integration Test: Complete Module Lifecycle
# ============================================================================

test_that("complete module lifecycle generates expected logs", {
  test_logs <<- NULL

  # Simulate module lifecycle
  mock_session <- create_mock_session("integration_test_001")

  # 1. Module initialization
  log_module_event("two_group", "init", mock_session)

  # 2. User provides inputs (reactive execution)
  log_reactive_execution("power_reactive", mock_session,
                        p1 = 0.5, p2 = 0.6, n = 100)

  # 3. User clicks calculate button
  logger::log_info(
    "User clicked calculate button",
    session_id = mock_session$token,
    module = "two_group",
    action = "calculate"
  )

  # 4. Calculation with performance measurement
  calc_result <- measure_performance({
    # Simulate power calculation
    list(power = 0.82, n_required = 95)
  }, label = "power_calculation", log_result = TRUE)

  # 5. Module cleanup
  log_module_event("two_group", "cleanup", mock_session)

  # Verify all lifecycle stages were logged
  all_logs <- paste(test_logs, collapse = " ")

  expect_match(all_logs, "two_group")
  expect_match(all_logs, "init")
  expect_match(all_logs, "power_reactive")
  expect_match(all_logs, "calculate button")
  expect_match(all_logs, "power_calculation")
  expect_match(all_logs, "cleanup")
  expect_match(all_logs, "integration_test_001")

  # Verify log levels are appropriate
  expect_true(count_logs_by_level("INFO") >= 3)  # init, button, cleanup, performance
  expect_true(count_logs_by_level("TRACE") >= 1) # reactive execution
})

# ============================================================================
# Integration Test: Calculation with Error Handling
# ============================================================================

test_that("calculation errors are properly logged", {
  test_logs <<- NULL

  mock_session <- create_mock_session("error_test_002")

  # Start module
  log_module_event("continuous", "init", mock_session)

  # Simulate calculation that will fail
  expect_error({
    log_function_call(
      function(d) {
        if (d <= 0) stop("Effect size must be positive")
        list(n = 100)
      },
      "calculate_sample_size",
      d = -0.5,  # Invalid input
      log_level = logger::DEBUG
    )
  })

  # Verify error was logged
  error_logs <- filter_logs("failed")
  expect_true(length(error_logs) > 0)

  # Verify error includes context
  all_logs <- paste(test_logs, collapse = " ")
  expect_match(all_logs, "calculate_sample_size")
  expect_match(all_logs, "Effect size must be positive")

  # Verify ERROR level was used
  expect_true(count_logs_by_level("ERROR") >= 1)
})

# ============================================================================
# Integration Test: Multi-Module Session
# ============================================================================

test_that("multi-module session tracking works correctly", {
  test_logs <<- NULL

  mock_session <- create_mock_session("multi_module_003")

  # Simulate user working across multiple modules
  modules <- c("single_proportion", "two_group", "survival", "continuous")

  for (module_name in modules) {
    # Init module
    log_module_event(module_name, "init", mock_session)

    # Simulate some work
    log_reactive_execution(
      paste0(module_name, "_reactive"),
      mock_session
    )

    # Cleanup module
    log_module_event(module_name, "cleanup", mock_session)
  }

  # Verify all modules were logged
  all_logs <- paste(test_logs, collapse = " ")

  for (module_name in modules) {
    expect_match(all_logs, module_name)
  }

  # Verify session ID appears in all logs
  expect_true(length(grep("multi_module_003", test_logs)) >= length(modules) * 2)

  # Verify cleanup happened for all modules
  cleanup_logs <- filter_logs("cleanup")
  expect_true(length(cleanup_logs) >= length(modules))
})

# ============================================================================
# Integration Test: Performance Measurement
# ============================================================================

test_that("performance measurement captures timing correctly", {
  test_logs <<- NULL

  # Measure a simple operation
  result <- measure_performance({
    Sys.sleep(0.05)  # Sleep 50ms
    "completed"
  }, label = "sleep_test", log_result = TRUE)

  # Verify result is correct
  expect_equal(result$result, "completed")

  # Verify duration is reasonable (should be ~50ms, allow 10-100ms)
  expect_true(result$duration_ms >= 10)
  expect_true(result$duration_ms <= 200)

  # Verify performance was logged
  perf_logs <- filter_logs("sleep_test")
  expect_true(length(perf_logs) > 0)

  # Verify duration appears in logs
  all_logs <- paste(test_logs, collapse = " ")
  expect_match(all_logs, "duration_ms")
})

# ============================================================================
# Integration Test: Performance Threshold Filtering
# ============================================================================

test_that("performance threshold filters low-duration operations", {
  test_logs <<- NULL

  # Fast operation (should not log with threshold)
  result1 <- measure_performance({
    1 + 1
  }, label = "fast_op", log_result = TRUE, threshold_ms = 10)

  # Slow operation (should log)
  result2 <- measure_performance({
    Sys.sleep(0.02)  # 20ms
    2 + 2
  }, label = "slow_op", log_result = TRUE, threshold_ms = 10)

  # Fast operation should not appear in logs
  fast_logs <- filter_logs("fast_op")
  expect_true(length(fast_logs) == 0)

  # Slow operation should appear
  slow_logs <- filter_logs("slow_op")
  expect_true(length(slow_logs) > 0)
})

# ============================================================================
# Integration Test: Business Logic with Performance
# ============================================================================

test_that("business logic logging includes performance data", {
  test_logs <<- NULL

  # Simulate a real calculation function
  calculate_power_with_logging <- function(p1, p2, n, alpha = 0.05) {
    start_time <- Sys.time()

    tryCatch(
      {
        logger::log_debug("calculate_power called", p1 = p1, p2 = p2, n = n)

        # Simulate calculation
        result <- list(power = 0.82)

        duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

        logger::log_debug(
          "calculate_power completed",
          power = result$power,
          duration_ms = round(duration_ms, 2)
        )

        result
      },
      error = function(e) {
        duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

        logger::log_error(
          "calculate_power failed",
          error_msg = conditionMessage(e),
          duration_ms = round(duration_ms, 2)
        )

        stop(e)
      }
    )
  }

  # Execute function
  result <- calculate_power_with_logging(0.5, 0.6, 100)

  # Verify result
  expect_equal(result$power, 0.82)

  # Verify logging occurred
  all_logs <- paste(test_logs, collapse = " ")
  expect_match(all_logs, "calculate_power called")
  expect_match(all_logs, "calculate_power completed")
  expect_match(all_logs, "duration_ms")

  # Verify both entry and exit logs exist
  expect_true(count_logs_by_level("DEBUG") >= 2)
})

# ============================================================================
# Integration Test: Safe Logging During Errors
# ============================================================================

test_that("safe_log prevents logging failures from crashing app", {
  test_logs <<- NULL

  # Counter to track execution
  execution_count <- 0

  # Simulate operations with potentially failing logger
  for (i in 1:5) {
    execution_count <- execution_count + 1

    # Use safe_log which should never crash
    safe_log(logger::log_info, paste("Operation", i), value = i)

    # Simulate a failing logger on iteration 3
    if (i == 3) {
      bad_logger <- function(...) stop("Logger failure")
      safe_log(bad_logger, "This should not crash")
    }
  }

  # All iterations should complete
  expect_equal(execution_count, 5)

  # Some logs should still exist (the successful ones)
  expect_true(length(test_logs) >= 4)
})

# ============================================================================
# Integration Test: Log Calculation with Timing
# ============================================================================

test_that("log_calculation includes performance metrics", {
  test_logs <<- NULL

  # Simulate calculation with timing
  start_time <- Sys.time()

  inputs <- list(p1 = 0.5, p2 = 0.6, alpha = 0.05)
  result <- list(power = 0.82, n = 95)

  # Simulate some work
  Sys.sleep(0.01)

  duration_ms <- as.numeric(difftime(Sys.time(), start_time, units = "secs")) * 1000

  log_calculation("power_calc", inputs, result, success = TRUE, duration_ms = duration_ms)

  # Verify logging
  all_logs <- paste(test_logs, collapse = " ")
  expect_match(all_logs, "power_calc")
  expect_match(all_logs, "completed")
  expect_match(all_logs, "duration_ms")

  # Parse one of the JSON logs to verify structure
  json_log <- jsonlite::fromJSON(test_logs[1])
  expect_true(!is.null(json_log$duration_ms))
  expect_true(json_log$duration_ms > 0)
})

# ============================================================================
# Integration Test: Session Context Preservation
# ============================================================================

test_that("session context is preserved across multiple operations", {
  test_logs <<- NULL

  mock_session <- create_mock_session("context_test_004")

  # Extract context once
  context <- get_session_context(mock_session)

  # Simulate multiple operations using the same session
  for (i in 1:3) {
    log_module_event(paste0("module_", i), "init", mock_session)

    logger::log_info(
      paste("Operation", i),
      session_id = context$session_id,
      user = context$user,
      operation_num = i
    )
  }

  # Verify session ID appears consistently
  session_logs <- filter_logs("context_test_004")
  expect_true(length(session_logs) >= 6)  # 3 module inits + 3 operations

  # Verify user appears in logs
  user_logs <- filter_logs("test_user")
  expect_true(length(user_logs) >= 3)
})

# ============================================================================
# Integration Test: Reactive Execution Tracking
# ============================================================================

test_that("reactive execution is tracked with proper log level", {
  test_logs <<- NULL

  mock_session <- create_mock_session("reactive_test_005")

  # Simulate multiple reactive executions (common in Shiny)
  for (i in 1:10) {
    log_reactive_execution(
      "power_calc_reactive",
      mock_session,
      iteration = i,
      input_changed = TRUE
    )
  }

  # Verify all executions logged
  reactive_logs <- filter_logs("power_calc_reactive")
  expect_equal(length(reactive_logs), 10)

  # Verify TRACE level was used (shouldn't appear in production)
  expect_true(count_logs_by_level("TRACE") >= 10)

  # Verify INFO logs are still separate (shouldn't be cluttered with reactive logs)
  logger::log_info("Important user action")
  expect_true(count_logs_by_level("INFO") >= 1)
})

# ============================================================================
# Integration Test: Full User Journey
# ============================================================================

test_that("complete user journey is properly logged", {
  test_logs <<- NULL

  # Simulate a realistic user session
  mock_session <- create_mock_session("journey_test_006")

  # 1. User loads app
  logger::log_info("App started", session_id = mock_session$token)

  # 2. User navigates to two-group module
  log_module_event("two_group", "init", mock_session)

  # 3. User changes inputs (multiple reactive executions)
  for (param in c("p1", "p2", "n", "alpha")) {
    log_reactive_execution(
      "two_group_reactive",
      mock_session,
      changed_param = param
    )
  }

  # 4. User clicks calculate
  logger::log_info(
    "Calculate button clicked",
    session_id = mock_session$token,
    module = "two_group"
  )

  # 5. Calculation runs with performance tracking
  calc_result <- measure_performance({
    list(power = 0.82, n = 95)
  }, label = "two_group_power", log_result = TRUE)

  # 6. User downloads results
  logger::log_info(
    "Results exported",
    session_id = mock_session$token,
    module = "two_group",
    format = "csv"
  )

  # 7. User switches to different module
  log_module_event("two_group", "cleanup", mock_session)
  log_module_event("survival", "init", mock_session)

  # 8. User closes app
  logger::log_info("App closed", session_id = mock_session$token)

  # Verify complete journey is logged
  all_logs <- paste(test_logs, collapse = " ")

  expect_match(all_logs, "App started")
  expect_match(all_logs, "two_group")
  expect_match(all_logs, "Calculate button")
  expect_match(all_logs, "two_group_power")
  expect_match(all_logs, "Results exported")
  expect_match(all_logs, "survival")
  expect_match(all_logs, "App closed")

  # Verify session ID appears throughout
  expect_true(length(filter_logs("journey_test_006")) >= 10)

  # Verify appropriate log levels were used
  expect_true(count_logs_by_level("INFO") >= 5)   # Major events
  expect_true(count_logs_by_level("TRACE") >= 4)  # Reactive executions
})

# ============================================================================
# Integration Test: Error Recovery
# ============================================================================

test_that("application continues after logged errors", {
  test_logs <<- NULL

  mock_session <- create_mock_session("recovery_test_007")

  # Successful operation
  log_calculation("calc1", list(x = 1), list(y = 2), success = TRUE)

  # Failed operation (logged but caught)
  expect_error({
    log_function_call(
      function() stop("Expected error"),
      "failing_calc"
    )
  })

  # Application should continue
  log_calculation("calc2", list(x = 3), list(y = 4), success = TRUE)

  # Verify all operations were logged
  expect_true(length(filter_logs("calc1")) > 0)
  expect_true(length(filter_logs("failing_calc")) > 0)
  expect_true(length(filter_logs("calc2")) > 0)

  # Verify error was logged but didn't stop subsequent operations
  expect_true(count_logs_by_level("ERROR") >= 1)
  expect_true(count_logs_by_level("INFO") >= 2)
})

# ============================================================================
# Integration Test: Performance Profiling
# ============================================================================

test_that("performance profiling identifies slow operations", {
  test_logs <<- NULL

  # Simulate various operation durations
  operations <- list(
    list(name = "fast", duration = 0.001),   # 1ms
    list(name = "medium", duration = 0.05),  # 50ms
    list(name = "slow", duration = 0.15)     # 150ms
  )

  for (op in operations) {
    measure_performance({
      Sys.sleep(op$duration)
      "done"
    }, label = op$name, log_result = TRUE, threshold_ms = 100)
  }

  # Only slow operation should be logged (> 100ms threshold)
  fast_logs <- filter_logs("fast")
  medium_logs <- filter_logs("medium")
  slow_logs <- filter_logs("slow")

  expect_equal(length(fast_logs), 0)
  expect_equal(length(medium_logs), 0)
  expect_true(length(slow_logs) > 0)

  # Verify slow operation duration is in logs
  all_logs <- paste(test_logs, collapse = " ")
  expect_match(all_logs, "duration_ms")
})

# ============================================================================
# Summary Statistics Test
# ============================================================================

test_that("logging system performance is acceptable", {
  test_logs <<- NULL

  # Measure overhead of logging
  iterations <- 100

  # Without logging
  time_without <- system.time({
    for (i in 1:iterations) {
      x <- i * 2
    }
  })

  # With logging (suppressed - should be fast)
  logger::log_threshold(logger::ERROR)  # Suppress DEBUG logs
  time_with <- system.time({
    for (i in 1:iterations) {
      x <- i * 2
      logger::log_debug("Operation", i = i, result = x)
    }
  })
  logger::log_threshold(logger::TRACE)  # Restore

  # Logging overhead should be reasonable (< 5x slower)
  overhead_ratio <- time_with[["elapsed"]] / max(time_without[["elapsed"]], 0.001)
  expect_true(overhead_ratio < 5)

  # Report performance
  cat("\n")
  cat("Logging Performance:\n")
  cat("  Without logging:", time_without[["elapsed"]], "seconds\n")
  cat("  With logging:", time_with[["elapsed"]], "seconds\n")
  cat("  Overhead ratio:", round(overhead_ratio, 2), "x\n")
})
