# Logging System Reference

**Type:** Reference
**Audience:** Developers
**Last Updated:** 2025-10-27

## Overview

The Power Analysis Tool uses the `logger` package for comprehensive structured logging. This document provides complete technical reference for the logging infrastructure, including configuration, functions, log levels, and output formats.

---

## Configuration

### Environment Variables

Logging behavior is controlled via environment variables set in `.Renviron`:

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `PAT_LOG_LEVEL` | TRACE, DEBUG, INFO, SUCCESS, WARN, ERROR, FATAL | INFO | Minimum log level to output |
| `PAT_LOG_DIR` | Path string | ./logs | Directory for log files |
| `PAT_LOG_FORMAT` | auto, console, json | auto | Log output format |

**Example `.Renviron`:**
```bash
PAT_LOG_LEVEL=DEBUG
PAT_LOG_DIR=./logs
PAT_LOG_FORMAT=auto
```

### Initialization

Logging is automatically configured when the package loads via `.onLoad()` in `R/zzz.R`:

```r
.onLoad <- function(libname, pkgname) {
  # Set log level from environment
  log_level <- Sys.getenv("PAT_LOG_LEVEL", "INFO")
  logger::log_threshold(log_level)

  # Configure format (JSON in production, console in dev)
  # Configure appenders (file + console in production, console only in dev)
  # ...
}
```

---

## Log Levels

### Level Hierarchy

From most verbose (TRACE) to least verbose (FATAL):

| Level | Numeric | When to Use | Example |
|-------|---------|-------------|---------|
| **TRACE** | 600 | Extremely detailed debugging | Reactive dependency tracking, loop iterations |
| **DEBUG** | 500 | Detailed diagnostic information | Function entry/exit, parameter values |
| **INFO** | 400 | General informational events | Module initialization, successful calculations |
| **SUCCESS** | 350 | Positive confirmations | Successful exports, API calls |
| **WARN** | 300 | Potentially harmful situations | Fallback methods used, deprecated features |
| **ERROR** | 200 | Error events (app continues) | Calculation failures, invalid inputs |
| **FATAL** | 100 | Critical errors (app terminates) | Database connection lost, critical config missing |

### Setting Log Level

**Via environment variable:**
```bash
PAT_LOG_LEVEL=DEBUG
```

**Via R code (not recommended in production):**
```r
logger::log_threshold(logger::DEBUG)
```

**Check current level:**
```r
logger::log_threshold()
```

---

## Logging Functions

### Core Logger Functions

#### Direct Logging

```r
logger::log_trace("Message", key1 = value1, key2 = value2)
logger::log_debug("Message", key1 = value1, key2 = value2)
logger::log_info("Message", key1 = value1, key2 = value2)
logger::log_success("Message", key1 = value1, key2 = value2)
logger::log_warn("Message", key1 = value1, key2 = value2)
logger::log_error("Message", key1 = value1, key2 = value2)
logger::log_fatal("Message", key1 = value1, key2 = value2)
```

**Parameters:**
- `...`: Message and named key-value pairs for structured logging
- All additional parameters are captured as structured data

**Example:**
```r
logger::log_info(
  "Power calculation completed",
  module = "two_group",
  n1 = 300,
  n2 = 300,
  power = 0.85,
  session_id = session$token
)
```

### Helper Functions

All helper functions are defined in `R/utils_logging.R`.

#### `log_function_call()`

Automatically logs function entry, exit, and errors.

```r
log_function_call(fn, fn_name, ..., log_level = logger::DEBUG)
```

**Parameters:**
- `fn`: Function to execute
- `fn_name`: String name for logging
- `...`: Named arguments to pass to function
- `log_level`: Log level for entry/exit (default: DEBUG)

**Returns:** Function result

**Example:**
```r
result <- log_function_call(
  calculate_power,
  "calculate_power",
  p1 = 0.5,
  p2 = 0.6,
  alpha = 0.05
)
```

**Logs Generated:**
- Entry: `calculate_power called` (DEBUG)
- Exit: `calculate_power completed successfully` (DEBUG)
- Error: `calculate_power failed` (ERROR) with stack trace

---

#### `get_session_context()`

Extracts session metadata for structured logging.

```r
get_session_context(session)
```

**Parameters:**
- `session`: Shiny session object

**Returns:** Named list with:
- `session_id`: Unique session token
- `user`: Username (if auth enabled)
- `client_ip`: Client IP address
- `user_agent`: Browser user agent

**Example:**
```r
logger::log_info(
  "User exported data",
  action = "csv_export",
  session_context = get_session_context(session)
)
```

---

#### `log_module_event()`

Standardized logging for Shiny module lifecycle.

```r
log_module_event(module_id, event, session = NULL, ...)
```

**Parameters:**
- `module_id`: String module identifier
- `event`: Event type ("init", "render", "cleanup", "error")
- `session`: Shiny session object (optional)
- `...`: Additional context

**Example:**
```r
# In module server function
log_module_event("two_group", "init", session)

# On cleanup
onStop(function() {
  log_module_event("two_group", "cleanup", session)
})
```

---

#### `log_reactive_execution()`

Logs reactive expression execution (TRACE level).

```r
log_reactive_execution(reactive_name, session = NULL, ...)
```

**Parameters:**
- `reactive_name`: String name of reactive
- `session`: Shiny session object (optional)
- `...`: Additional context

**Example:**
```r
inputs <- reactive({
  log_reactive_execution("two_group_inputs", session)
  # ... reactive code
})
```

---

#### `log_calculation()`

Specialized logging for statistical calculations.

```r
log_calculation(calc_name, inputs, result = NULL,
                success = TRUE, error = NULL)
```

**Parameters:**
- `calc_name`: String calculation name
- `inputs`: Named list of input parameters
- `result`: Calculation result (or NULL)
- `success`: Logical success indicator
- `error`: Error object if failed

**Example:**
```r
tryCatch({
  result <- calculate_power(p1, p2, alpha)
  log_calculation("power", list(p1=p1, p2=p2, alpha=alpha), result)
}, error = function(e) {
  log_calculation("power", list(p1=p1, p2=p2, alpha=alpha),
                 NULL, success=FALSE, error=e)
})
```

---

#### `safe_log()`

Wraps logging in tryCatch to prevent failures.

```r
safe_log(log_fn, ...)
```

**Parameters:**
- `log_fn`: Logger function (e.g., logger::log_info)
- `...`: Arguments to pass to log function

**Returns:** NULL invisibly

**Example:**
```r
# Won't crash if complex_obj can't be logged
safe_log(logger::log_debug, "Complex data", obj = complex_obj)
```

---

## Log Output Formats

### Console Format (Development)

Human-readable colored output:

```
INFO [2025-10-27 12:34:56] Power calculation completed
  module: two_group
  n1: 300
  n2: 300
  power: 0.85
```

### JSON Format (Production)

Machine-readable structured logs:

```json
{
  "time": "2025-10-27T12:34:56Z",
  "level": "INFO",
  "msg": "Power calculation completed",
  "module": "two_group",
  "n1": 300,
  "n2": 300,
  "power": 0.85,
  "session_id": "abc123"
}
```

---

## File Locations

### Log Files

**Development:**
```
./logs/app_2025-10-27.log
```

**Production:**
```
/var/log/power-analysis-tool/app_2025-10-27.log
```

Files are created daily with date suffix.

### Configuration Files

- `.Renviron`: User-specific configuration (git-ignored)
- `.Renviron.example`: Template configuration (committed to repo)
- `R/zzz.R`: Logging initialization code
- `R/utils_logging.R`: Helper functions

---

## Appenders

### Console Appender (Development)

Writes to stdout/stderr with colors:

```r
logger::log_appender(logger::appender_console)
```

### File Appender (Production)

Writes to rotating daily log files:

```r
logger::log_appender(logger::appender_file(
  file.path(log_dir, sprintf("app_%s.log", Sys.Date()))
))
```

### Tee Appender (Production)

Writes to both file and console:

```r
logger::log_appender(logger::appender_tee(
  logger::appender_file(log_file),
  logger::appender_console
))
```

---

## Performance Considerations

### Conditional Logging

Avoid expensive computations in log statements:

```r
# BAD: Always computes expensive_fn()
logger::log_debug("Data", data = expensive_fn())

# GOOD: Only computes if DEBUG level active
if (logger::log_threshold() <= logger::DEBUG) {
  logger::log_debug("Data", data = expensive_fn())
}
```

### Lazy Evaluation

Use expressions for expensive logging:

```r
logger::log_debug("Data", data = {
  if (logger::log_threshold() <= logger::DEBUG) {
    expensive_fn()
  } else {
    NULL
  }
})
```

---

## Testing with Logging

### Suppress Logs in Tests

In `tests/testthat/helper.R`:

```r
# Suppress all but FATAL during tests
logger::log_threshold(logger::FATAL)
```

### Capture Logs for Testing

```r
capture_logs <- function(expr) {
  tmp <- tempfile()
  logger::log_appender(logger::appender_file(tmp))
  on.exit(logger::log_appender(logger::appender_console))

  result <- force(expr)
  logs <- readLines(tmp)

  list(result = result, logs = logs)
}

# Usage
test_that("calculation logs correctly", {
  output <- capture_logs({
    calculate_power(0.5, 0.6, 0.05)
  })

  expect_true(any(grepl("calculate_power", output$logs)))
})
```

---

## Troubleshooting

### Logs Not Appearing

**Check log level:**
```r
logger::log_threshold()  # Should return numeric (400 = INFO)
```

**Verify environment variable:**
```r
Sys.getenv("PAT_LOG_LEVEL")  # Should return "INFO", "DEBUG", etc.
```

### Log Directory Not Found

**Check directory:**
```r
Sys.getenv("PAT_LOG_DIR")
dir.exists(Sys.getenv("PAT_LOG_DIR"))
```

**Create manually:**
```r
dir.create(Sys.getenv("PAT_LOG_DIR"), recursive = TRUE)
```

### Logs Too Verbose

**Reduce verbosity:**
```bash
# In .Renviron
PAT_LOG_LEVEL=WARN  # Only warnings and errors
```

---

## API Quick Reference

### Log Levels (Most to Least Verbose)
```r
logger::TRACE    # 600
logger::DEBUG    # 500
logger::INFO     # 400
logger::SUCCESS  # 350
logger::WARN     # 300
logger::ERROR    # 200
logger::FATAL    # 100
```

### Common Patterns

**Module initialization:**
```r
log_module_event("module_name", "init", session)
```

**Function logging:**
```r
logger::log_debug("function_name called", param1 = val1, param2 = val2)
```

**Error logging:**
```r
logger::log_error("Operation failed",
                 error_class = class(e)[1],
                 error_msg = conditionMessage(e))
```

**Success logging:**
```r
logger::log_info("Operation completed", result_count = n)
```

---

**Related Documentation:**
- docs/002-how-to-guides/018-logging-best-practices.md
- R/zzz.R (initialization code)
- R/utils_logging.R (helper functions)
- .Renviron.example (configuration template)

**External References:**
- logger package: https://daroczig.github.io/logger/
- Structured logging: https://www.thoughtworks.com/insights/blog/infrastructure/structured-logging
