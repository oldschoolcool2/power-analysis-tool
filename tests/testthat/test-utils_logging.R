#' Unit Tests for Logging Utility Functions
#'
#' Tests for R/utils_logging.R - Helper functions for structured logging
#'
#' Test Coverage:
#' - log_function_call: Entry/exit/error logging wrapper
#' - get_session_context: Session metadata extraction
#' - log_reactive_execution: Reactive logging helper
#' - log_module_event: Module lifecycle event logging
#' - log_calculation: Calculation logging with inputs/outputs
#' - safe_log: Error-safe logging wrapper
#' - %||%: Null-coalescing operator

library(testthat)
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
# log_function_call Tests
# ============================================================================

test_that("log_function_call logs successful function execution", {
  test_logs <<- NULL

  # Simple test function
  test_fn <- function(a, b) {
    a + b
  }

  result <- log_function_call(test_fn, "test_fn", a = 5, b = 3)

  # Check result
  expect_equal(result, 8)

  # Check that logs were created
  expect_true(length(test_logs) > 0)

  # Check for entry log
  entry_log <- paste(test_logs, collapse = " ")
  expect_match(entry_log, "test_fn called")

  # Check for exit log
  expect_match(entry_log, "test_fn completed successfully")
})

test_that("log_function_call logs errors with full context", {
  test_logs <<- NULL

  # Function that throws an error
  error_fn <- function(x) {
    stop("Test error")
  }

  # Should throw error
  expect_error(
    log_function_call(error_fn, "error_fn", x = 42),
    "Test error"
  )

  # Check that error was logged
  error_log <- paste(test_logs, collapse = " ")
  expect_match(error_log, "error_fn failed")
  expect_match(error_log, "Test error")
})

test_that("log_function_call handles functions with no arguments", {
  test_logs <<- NULL

  no_arg_fn <- function() {
    return(TRUE)
  }

  result <- log_function_call(no_arg_fn, "no_arg_fn")

  expect_true(result)
  expect_true(length(test_logs) > 0)
})

test_that("log_function_call respects custom log levels", {
  test_logs <<- NULL

  test_fn <- function(x) x * 2

  # Use INFO level instead of DEBUG
  result <- log_function_call(test_fn, "test_fn", x = 10, log_level = logger::INFO)

  expect_equal(result, 20)

  # Logs should still be created (TRACE threshold is lower than INFO)
  expect_true(length(test_logs) > 0)
})

# ============================================================================
# get_session_context Tests
# ============================================================================

test_that("get_session_context handles NULL session gracefully", {
  context <- get_session_context(NULL)

  expect_type(context, "list")
  expect_equal(context$session_id, "unknown")
  expect_equal(context$user, "unknown")
})

test_that("get_session_context extracts session metadata", {
  # Mock session object
  mock_session <- list(
    token = "test_session_123",
    user = "test_user",
    clientData = list(),
    request = list(
      REMOTE_ADDR = "192.168.1.1",
      HTTP_USER_AGENT = "Mozilla/5.0 Test Browser"
    )
  )

  context <- get_session_context(mock_session)

  expect_equal(context$session_id, "test_session_123")
  expect_equal(context$user, "test_user")
  expect_equal(context$client_ip, "192.168.1.1")
  expect_equal(context$user_agent, "Mozilla/5.0 Test Browser")
})

test_that("get_session_context handles missing client data", {
  # Session without clientData
  mock_session <- list(
    token = "test_session_456",
    user = "test_user_2"
  )

  context <- get_session_context(mock_session)

  expect_equal(context$session_id, "test_session_456")
  expect_equal(context$user, "test_user_2")
  # Should not have client_ip or user_agent
  expect_null(context$client_ip)
  expect_null(context$user_agent)
})

test_that("get_session_context uses default values for missing fields", {
  # Session with some missing fields
  mock_session <- list(
    token = "test_session_789"
    # user is missing
  )

  context <- get_session_context(mock_session)

  expect_equal(context$session_id, "test_session_789")
  expect_equal(context$user, "unknown")
})

# ============================================================================
# log_reactive_execution Tests
# ============================================================================

test_that("log_reactive_execution logs with reactive name", {
  test_logs <<- NULL

  log_reactive_execution("test_reactive")

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "test_reactive")
  expect_match(log_output, "executing")
})

test_that("log_reactive_execution includes session context", {
  test_logs <<- NULL

  mock_session <- list(token = "session_abc")

  log_reactive_execution("test_reactive", mock_session, input_val = 42)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "session_abc")
})

test_that("log_reactive_execution handles additional context", {
  test_logs <<- NULL

  log_reactive_execution(
    "power_calculation",
    session = NULL,
    p1 = 0.5,
    p2 = 0.6,
    n = 100
  )

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "power_calculation")
})

# ============================================================================
# log_module_event Tests
# ============================================================================

test_that("log_module_event logs initialization events", {
  test_logs <<- NULL

  log_module_event("two_group", "init")

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "two_group")
  expect_match(log_output, "init")
})

test_that("log_module_event logs cleanup events", {
  test_logs <<- NULL

  log_module_event("single_proportion", "cleanup")

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "single_proportion")
  expect_match(log_output, "cleanup")
})

test_that("log_module_event includes session context", {
  test_logs <<- NULL

  mock_session <- list(
    token = "session_xyz",
    user = "test_user"
  )

  log_module_event("survival", "init", mock_session)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "session_xyz")
})

test_that("log_module_event handles custom context", {
  test_logs <<- NULL

  log_module_event(
    "mediation",
    "calculation",
    session = NULL,
    n = 250,
    power = 0.8
  )

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "mediation")
  expect_match(log_output, "calculation")
})

test_that("log_module_event uses appropriate log levels", {
  test_logs <<- NULL

  # Init should use INFO
  log_module_event("test_module", "init")
  init_log <- paste(test_logs, collapse = " ")

  test_logs <<- NULL

  # Cleanup should use INFO
  log_module_event("test_module", "cleanup")
  cleanup_log <- paste(test_logs, collapse = " ")

  test_logs <<- NULL

  # Error should use ERROR
  log_module_event("test_module", "error")
  error_log <- paste(test_logs, collapse = " ")

  # All should have created logs
  expect_true(nchar(init_log) > 0)
  expect_true(nchar(cleanup_log) > 0)
  expect_true(nchar(error_log) > 0)
})

# ============================================================================
# log_calculation Tests
# ============================================================================

test_that("log_calculation logs successful calculations", {
  test_logs <<- NULL

  inputs <- list(p1 = 0.5, p2 = 0.6, alpha = 0.05)
  result <- list(power = 0.8, n = 200)

  log_calculation("power_calc", inputs, result, success = TRUE)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "power_calc")
  expect_match(log_output, "completed")
})

test_that("log_calculation logs failed calculations", {
  test_logs <<- NULL

  inputs <- list(p1 = 0.5, p2 = 0.6)
  error <- simpleError("Invalid input")

  log_calculation("power_calc", inputs, NULL, success = FALSE, error = error)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "power_calc")
  expect_match(log_output, "failed")
  expect_match(log_output, "Invalid input")
})

test_that("log_calculation handles NULL result for failures", {
  test_logs <<- NULL

  inputs <- list(x = 5)

  log_calculation("test_calc", inputs, NULL, success = FALSE, error = NULL)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "failed")
  expect_match(log_output, "unknown")
})

test_that("log_calculation captures result metadata", {
  test_logs <<- NULL

  inputs <- list(n = 100)
  result <- data.frame(x = 1:10, y = 11:20)

  log_calculation("data_gen", inputs, result, success = TRUE)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "data_gen")
  expect_match(log_output, "completed")
})

# ============================================================================
# safe_log Tests
# ============================================================================

test_that("safe_log executes logging successfully", {
  test_logs <<- NULL

  safe_log(logger::log_info, "Test message", value = 42)

  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "Test message")
})

test_that("safe_log prevents crashes on logging errors", {
  # Create a logger function that will fail
  bad_logger <- function(...) {
    stop("Logging system failure")
  }

  # Should not throw error - safe_log should catch it
  expect_silent(safe_log(bad_logger, "This should not crash"))
})

test_that("safe_log returns NULL invisibly", {
  result <- safe_log(logger::log_debug, "Test")

  expect_null(result)
})

test_that("safe_log writes to stderr on failure", {
  # Capture stderr
  stderr_output <- capture.output(
    {
      bad_logger <- function(...) stop("Test error")
      safe_log(bad_logger, "Test message")
    },
    type = "message"
  )

  # Should contain the error message
  expect_true(any(grepl("LOGGING ERROR", stderr_output)))
})

# ============================================================================
# %||% Operator Tests
# ============================================================================

test_that("%||% returns left value when not NULL", {
  result <- "left_value" %||% "right_value"
  expect_equal(result, "left_value")
})

test_that("%||% returns right value when left is NULL", {
  result <- NULL %||% "right_value"
  expect_equal(result, "right_value")
})

test_that("%||% works with numeric values", {
  result <- NULL %||% 42
  expect_equal(result, 42)

  result <- 10 %||% 42
  expect_equal(result, 10)
})

test_that("%||% works with complex objects", {
  obj1 <- list(a = 1, b = 2)
  obj2 <- list(x = 10, y = 20)

  result <- NULL %||% obj2
  expect_equal(result, obj2)

  result <- obj1 %||% obj2
  expect_equal(result, obj1)
})

test_that("%||% handles NA differently from NULL", {
  # NA is not NULL, so it should be returned
  result <- NA %||% "default"
  expect_true(is.na(result))

  # But NULL should return the default
  result <- NULL %||% "default"
  expect_equal(result, "default")
})

test_that("%||% can chain multiple operations", {
  result <- NULL %||% NULL %||% "final_default"
  expect_equal(result, "final_default")

  result <- NULL %||% "first_value" %||% "second_value"
  expect_equal(result, "first_value")
})

# ============================================================================
# Integration Tests
# ============================================================================

test_that("logging utilities work together in realistic scenario", {
  test_logs <<- NULL

  # Simulate a module lifecycle with calculation
  mock_session <- list(token = "integration_test_session", user = "test_user")

  # 1. Module initialization
  log_module_event("test_module", "init", mock_session)

  # 2. Reactive execution
  log_reactive_execution("power_reactive", mock_session, p1 = 0.5, p2 = 0.6)

  # 3. Function call with calculation
  calc_fn <- function(p1, p2) {
    inputs <- list(p1 = p1, p2 = p2)
    result <- list(power = 0.8)
    log_calculation("power_calc", inputs, result, success = TRUE)
    result
  }

  result <- log_function_call(calc_fn, "calc_fn", p1 = 0.5, p2 = 0.6)

  # 4. Module cleanup
  log_module_event("test_module", "cleanup", mock_session)

  # Check that all events were logged
  log_output <- paste(test_logs, collapse = " ")
  expect_match(log_output, "test_module")
  expect_match(log_output, "init")
  expect_match(log_output, "power_reactive")
  expect_match(log_output, "power_calc")
  expect_match(log_output, "cleanup")
  expect_match(log_output, "integration_test_session")
})

test_that("safe_log allows continuation when logging system fails", {
  test_logs <<- NULL

  # Simulate normal operations with safe_log even if logger fails
  counter <- 0

  # First operation with safe_log
  safe_log(logger::log_info, "Operation 1")
  counter <- counter + 1

  # Second operation with failing logger
  bad_logger <- function(...) stop("Simulated failure")
  safe_log(bad_logger, "This should not crash")
  counter <- counter + 1

  # Third operation continues normally
  safe_log(logger::log_info, "Operation 3")
  counter <- counter + 1

  # All operations should have completed
  expect_equal(counter, 3)
})

# ============================================================================
# Edge Cases and Error Handling
# ============================================================================

test_that("logging utilities handle empty inputs gracefully", {
  test_logs <<- NULL

  # Empty function name
  test_fn <- function() TRUE
  expect_error(log_function_call(test_fn, "", log_level = logger::DEBUG), NA)

  # Empty module ID
  expect_error(log_module_event("", "init"), NA)

  # Empty reactive name
  expect_error(log_reactive_execution(""), NA)

  # Empty calculation name
  expect_error(log_calculation("", list(), NULL), NA)
})

test_that("logging utilities handle special characters in strings", {
  test_logs <<- NULL

  # Module with special characters
  log_module_event("test-module_v2.0", "init")

  # Reactive with unicode
  log_reactive_execution("reactive_αβγ")

  # Calculation with quotes
  log_calculation("calc'with\"quotes", list(val = "test"), NULL)

  # Should not crash
  expect_true(length(test_logs) > 0)
})

test_that("logging utilities handle very large objects", {
  test_logs <<- NULL

  # Large list as input
  large_input <- list(
    data = matrix(rnorm(1000), ncol = 10),
    params = list(a = 1:100, b = letters)
  )

  # Should still log without crashing
  expect_error(
    log_calculation("large_calc", large_input, NULL, success = TRUE),
    NA
  )
})

# ============================================================================
# Performance Tests
# ============================================================================

test_that("logging has minimal performance impact", {
  test_logs <<- NULL

  # Time without logging
  time_without <- system.time({
    for (i in 1:100) {
      x <- i * 2
    }
  })

  # Time with logging (using safe_log for each iteration)
  time_with <- system.time({
    for (i in 1:100) {
      x <- i * 2
      safe_log(logger::log_trace, "Operation", i = i)
    }
  })

  # Logging overhead should be reasonable (< 10x slower)
  # This is a loose bound to avoid flakiness
  expect_true(time_with[["elapsed"]] < time_without[["elapsed"]] * 10)
})
