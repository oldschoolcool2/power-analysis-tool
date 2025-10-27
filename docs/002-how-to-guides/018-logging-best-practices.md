# How to implement logging best practices

**Type:** How-To
**Audience:** Developers
**Last Updated:** 2025-10-27

## Goal

Learn how to add comprehensive, structured logging to your code following the project's logging standards.

## Prerequisites

- Familiarity with R and Shiny
- Understanding of the project structure
- `logger` package installed (included in DESCRIPTION)

---

## Quick Start

### Step 1: Configure your environment

Copy the example environment file:

```bash
cp .Renviron.example .Renviron
```

Edit `.Renviron` to set your log level:

```bash
PAT_LOG_LEVEL=DEBUG  # For development
PAT_LOG_DIR=./logs
PAT_LOG_FORMAT=auto
```

### Step 2: Test logging

In R console:

```r
# Load package
devtools::load_all()

# Test logging
logger::log_info("Testing logging system")
logger::log_debug("Debug message with data", value = 123)
```

You should see output in your console and a log file in `./logs/`.

---

## Adding Logging to Different Function Types

### Business Logic Functions (fct_*.R)

**Pattern:** Log entry, exit, and errors

```r
#' Calculate Statistical Power
#'
#' @param p1 Proportion in group 1
#' @param p2 Proportion in group 2
#' @param alpha Significance level
#' @return Power value
#' @noRd
calculate_power <- function(p1, p2, alpha) {
  # Log function entry with inputs
  logger::log_debug(
    "calculate_power called",
    p1 = p1,
    p2 = p2,
    alpha = alpha
  )

  result <- tryCatch(
    {
      # Perform calculation
      power <- pwr::pwr.2p.test(
        h = pwr::ES.h(p1, p2),
        sig.level = alpha,
        power = NULL,
        n = 100
      )$power

      # Log successful completion
      logger::log_debug(
        "calculate_power completed",
        power = power
      )

      power
    },
    error = function(e) {
      # Log error with full context
      logger::log_error(
        "calculate_power failed",
        error_class = class(e)[1],
        error_msg = conditionMessage(e),
        p1 = p1,
        p2 = p2,
        alpha = alpha
      )

      # Re-throw error
      stop(e)
    }
  )

  result
}
```

**When to use each level:**
- **DEBUG**: Function entry/exit, parameter values
- **ERROR**: Calculation failures, invalid inputs
- **WARN**: When using fallback methods

---

### Shiny Modules (mod_*.R)

**Pattern:** Log initialization, user actions, cleanup

```r
#' My Module Server
#'
#' @param id Module namespace ID
#' @noRd
mod_my_module_server <- function(id) {
  moduleServer(id, function(input, output, session) {

    # Log module initialization
    log_module_event("my_module", "init", session)

    # Log user button clicks
    observeEvent(input$calculate_btn, {
      logger::log_info(
        "User clicked calculate button",
        module = "my_module",
        session_id = session$token
      )

      # Perform calculation...
    })

    # Log when example data is loaded
    observeEvent(input$load_example, {
      logger::log_info(
        "Loading example data",
        module = "my_module",
        action = "load_example",
        session_id = session$token
      )
    })

    # Register cleanup handler
    onStop(function() {
      log_module_event("my_module", "cleanup", session)
    })

    # Return reactive values
    list(
      inputs = reactive({
        # Only log reactive execution at TRACE level
        log_reactive_execution("my_module_inputs", session)

        list(
          param1 = input$param1,
          param2 = input$param2
        )
      })
    )
  })
}
```

**Module logging checklist:**
- [ ] Log initialization (`log_module_event("module", "init", session)`)
- [ ] Log user actions (button clicks, input changes)
- [ ] Log cleanup (`onStop` with `log_module_event`)
- [ ] Optional: Log reactive execution (TRACE level only)

---

### Utility Functions (utils_*.R)

**Pattern:** Log errors only (utilities are called frequently)

```r
#' Format Numeric Result
#'
#' @param value Numeric value
#' @param digits Number of decimal places
#' @return Formatted string
#' @noRd
format_numeric <- function(value, digits = 2) {
  # Only log problematic values
  if (is.null(value) || is.na(value) || !is.finite(value)) {
    logger::log_warn(
      "Invalid value in format_numeric",
      value = value,
      value_class = class(value)[1]
    )
    return("N/A")
  }

  # Normal operation - no logging
  sprintf(paste0("%.", digits, "f"), value)
}
```

**Utility logging guidelines:**
- **Avoid** logging on every call (performance impact)
- **Do** log warnings for invalid/unexpected inputs
- **Do** log errors for failures

---

### Export/Download Functions (fct_export.R, utils_export.R)

**Pattern:** Log start, success, and failure with file details

```r
#' Export Data to CSV
#'
#' @param data Data frame to export
#' @param filename Output filename
#' @return TRUE on success
#' @noRd
export_to_csv <- function(data, filename) {
  logger::log_info(
    "Starting CSV export",
    filename = filename,
    rows = nrow(data),
    cols = ncol(data)
  )

  tryCatch(
    {
      write.csv(data, filename, row.names = FALSE)

      logger::log_success(
        "CSV export completed successfully",
        filename = filename,
        file_size_bytes = file.size(filename)
      )

      TRUE
    },
    error = function(e) {
      logger::log_error(
        "CSV export failed",
        filename = filename,
        error_class = class(e)[1],
        error_msg = conditionMessage(e)
      )

      FALSE
    }
  )
}
```

**Export logging checklist:**
- [ ] Log export start with file details
- [ ] Log successful completion with file size
- [ ] Log failures with error details
- [ ] Use SUCCESS level for successful exports

---

## Choosing the Right Log Level

### Decision Tree

```
Is this a critical failure that stops the app?
├─ Yes → FATAL
└─ No → Is this an error that affects functionality?
    ├─ Yes → ERROR
    └─ No → Is this a potential issue or fallback?
        ├─ Yes → WARN
        └─ No → Is this confirming success?
            ├─ Yes → SUCCESS or INFO
            └─ No → Is this general information?
                ├─ Yes → INFO
                └─ No → Is this detailed diagnostic info?
                    ├─ Yes → DEBUG
                    └─ No → Is this extremely detailed?
                        └─ Yes → TRACE
```

### Examples by Scenario

**Scenario: Power calculation**
```r
# Entry
logger::log_debug("calculate_power called", n = 100, alpha = 0.05)

# Success
logger::log_info("Power calculation completed", power = 0.85)

# Warning (using fallback)
logger::log_warn("Root-finding failed, using approximation")

# Error (invalid input)
logger::log_error("Invalid alpha value", alpha = -0.05)
```

**Scenario: User interaction**
```r
# Button click
logger::log_info("User clicked export button", format = "CSV")

# Download success
logger::log_success("File downloaded", filename = "results.csv")
```

**Scenario: Reactive execution**
```r
# Only at TRACE level (very verbose)
logger::log_trace("Reactive invalidated", reactive = "power_inputs")
```

---

## Structured Logging Best Practices

### Include Relevant Context

**Always include:**
- Session ID (for multi-user debugging)
- Module name (for module-specific logs)
- Input parameters (for reproducibility)
- Error details (class and message)

```r
# BAD: Minimal context
logger::log_error("Calculation failed")

# GOOD: Rich context
logger::log_error(
  "Power calculation failed",
  module = "two_group",
  function = "calculate_power",
  session_id = session$token,
  error_class = class(e)[1],
  error_msg = conditionMessage(e),
  inputs = list(
    n1 = 300,
    n2 = 300,
    p1 = 0.15,
    p2 = 0.10
  )
)
```

### Use Consistent Key Names

**Standardized keys:**
- `session_id`: Session token
- `module`: Module identifier
- `function`: Function name (use `fn` for brevity)
- `error_class`: Class of error object
- `error_msg`: Error message text
- `file`, `filename`: File paths
- `rows`, `cols`: Data dimensions

```r
# Consistent across codebase
logger::log_info("Export completed",
                module = "two_group",
                filename = "results.csv",
                rows = 10,
                cols = 5)
```

---

## Performance Optimization

### Avoid Expensive Operations in Logs

**Problem:**
```r
# BAD: Always computes summary(), even at INFO level
logger::log_debug("Data summary", summary = summary(large_data))
```

**Solution 1: Conditional logging**
```r
# GOOD: Only computes if DEBUG active
if (logger::log_threshold() <= logger::DEBUG) {
  logger::log_debug("Data summary", summary = summary(large_data))
}
```

**Solution 2: Lazy evaluation**
```r
# GOOD: Uses lazy evaluation
logger::log_debug("Data summary", summary = {
  if (logger::log_threshold() <= logger::DEBUG) {
    summary(large_data)
  } else {
    NULL
  }
})
```

### Log Sampling for High-Frequency Events

For events that fire hundreds of times:

```r
# Sample: only log 1% of reactive executions
reactive_counter <- 0

my_reactive <- reactive({
  reactive_counter <<- reactive_counter + 1

  # Only log every 100th execution
  if (reactive_counter %% 100 == 0) {
    logger::log_trace("Reactive executed", count = reactive_counter)
  }

  # ... reactive code
})
```

---

## Common Patterns

### Pattern 1: Try-Catch with Logging

```r
result <- tryCatch(
  {
    # Perform operation
    output <- risky_operation(param1, param2)

    # Log success
    logger::log_info("Operation succeeded", result_length = length(output))

    output
  },
  error = function(e) {
    # Log error
    logger::log_error(
      "Operation failed",
      error_class = class(e)[1],
      error_msg = conditionMessage(e),
      param1 = param1,
      param2 = param2
    )

    # Return safe default or re-throw
    NULL
  }
)
```

### Pattern 2: Module Lifecycle

```r
moduleServer(id, function(input, output, session) {
  # Initialization
  log_module_event("module_name", "init", session)

  # Cleanup
  onStop(function() {
    log_module_event("module_name", "cleanup", session)
  })

  # ... module code
})
```

### Pattern 3: User Action Tracking

```r
observeEvent(input$action_button, {
  logger::log_info(
    "User action",
    module = "module_name",
    action = "button_click",
    button = "action_button",
    session_id = session$token,
    session_context = get_session_context(session)
  )

  # ... handle action
})
```

---

## Verification

After adding logging, verify it works:

### Step 1: Check console output

```r
# Set to DEBUG level
Sys.setenv(PAT_LOG_LEVEL = "DEBUG")

# Reload package
devtools::load_all()

# Run your function
my_function(param1, param2)
```

You should see DEBUG messages in the console.

### Step 2: Check log file

```bash
# View recent logs
tail -f ./logs/app_$(date +%Y-%m-%d).log
```

### Step 3: Test error logging

```r
# Trigger an error intentionally
my_function(invalid_param)
```

Verify ERROR level log appears with full context.

---

## Troubleshooting

### Logs not appearing

**Check log level:**
```r
logger::log_threshold()  # Should be <= 500 for DEBUG
```

**Check environment:**
```r
Sys.getenv("PAT_LOG_LEVEL")  # Should return "DEBUG"
```

**Restart R session:**
```r
.rs.restartR()  # RStudio
```

### Too much output

**Reduce verbosity:**
```bash
# In .Renviron
PAT_LOG_LEVEL=INFO  # Less verbose
```

### Log file not created

**Check directory:**
```r
dir.exists(Sys.getenv("PAT_LOG_DIR"))  # Should be TRUE
```

**Create manually:**
```r
dir.create("./logs", recursive = TRUE)
```

---

## Examples from Codebase

See these files for logging examples:

- **Business logic:** `R/fct_power.R` (R/fct_power.R:25)
- **Export functions:** `R/fct_export.R` (R/fct_export.R:42)
- **Shiny modules:** `R/mod_02_two_group.R` (R/mod_02_two_group.R:150)
- **App server:** `R/app_server.R` (R/app_server.R:23)
- **Helper functions:** `R/utils_logging.R`

---

## Checklist: Adding Logging to New Code

When adding new functions or modules:

- [ ] Add `logger::log_debug()` at function entry with parameters
- [ ] Add `logger::log_info()` or `logger::log_success()` on success
- [ ] Add `logger::log_error()` in error handlers with full context
- [ ] Add `logger::log_warn()` when using fallback methods
- [ ] Use `log_module_event()` for module init/cleanup
- [ ] Use `get_session_context()` for user-facing actions
- [ ] Verify logs appear in console and file
- [ ] Check performance impact (use conditional logging if needed)

---

**Related Documentation:**
- docs/003-reference/010-logging-reference.md (complete API reference)
- R/utils_logging.R (helper function source code)
- .Renviron.example (configuration template)

**External Resources:**
- logger package docs: https://daroczig.github.io/logger/
- Shiny debugging: https://shiny.posit.co/r/articles/improve/debugging/
