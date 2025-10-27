#' Logging Utility Functions
#'
#' Helper functions for consistent structured logging throughout the app.
#' These utilities make it easier to log function calls, errors, and
#' session context in a standardized way.

#' Log Function Call with Automatic Entry/Exit Tracking
#'
#' Wraps a function call with automatic logging of entry, exit, and errors.
#' Useful for adding comprehensive logging to business logic functions.
#'
#' @param fn Function to execute
#' @param fn_name Character string name of the function for logging
#' @param ... Named arguments to pass to the function
#' @param log_level Log level for entry/exit messages (default: DEBUG)
#'
#' @return Result of the function call
#'
#' @details
#' This wrapper:
#' - Logs function entry with all arguments at DEBUG level
#' - Executes the function
#' - Logs successful completion at DEBUG level
#' - Logs errors at ERROR level with full context
#' - Re-throws errors after logging
#'
#' @examples
#' \dontrun{
#' result <- log_function_call(
#'   calculate_power,
#'   "calculate_power",
#'   p1 = 0.5, p2 = 0.6, alpha = 0.05
#' )
#' }
#'
#' @noRd
log_function_call <- function(fn, fn_name, ..., log_level = logger::DEBUG) {
  args <- list(...)

  # Log function entry
  logger::log_level(
    log_level,
    paste0(fn_name, " called"),
    fn = fn_name,
    args = args,
    n_args = length(args)
  )

  # Execute with error handling
  result <- tryCatch(
    {
      res <- do.call(fn, args)

      # Log successful completion
      logger::log_level(
        log_level,
        paste0(fn_name, " completed successfully"),
        fn = fn_name
      )

      res
    },
    error = function(e) {
      # Log error with full context
      logger::log_error(
        paste0(fn_name, " failed"),
        fn = fn_name,
        error_class = class(e)[1],
        error_msg = conditionMessage(e),
        args = args
      )

      # Re-throw the error
      stop(e)
    }
  )

  result
}

#' Get Session Context for Structured Logging
#'
#' Extracts metadata from a Shiny session object for inclusion in logs.
#' Useful for tracking user actions and debugging session-specific issues.
#'
#' @param session Shiny session object
#'
#' @return Named list with session metadata
#'
#' @details
#' Extracted metadata includes:
#' - session_id: Unique session token
#' - user: Username (if authentication enabled)
#' - client_ip: Client IP address
#' - user_agent: Browser user agent string
#'
#' @examples
#' \dontrun{
#' logger::log_info(
#'   "User action",
#'   action = "download",
#'   session_context = get_session_context(session)
#' )
#' }
#'
#' @noRd
get_session_context <- function(session) {
  if (is.null(session)) {
    return(list(session_id = "unknown", user = "unknown"))
  }

  context <- list(
    session_id = session$token %||% "unknown",
    user = session$user %||% "unknown"
  )

  # Add client data if available
  if (!is.null(session$clientData)) {
    context$client_ip <- session$request$REMOTE_ADDR %||% "unknown"
    context$user_agent <- session$request$HTTP_USER_AGENT %||% "unknown"
  }

  context
}

#' Log Reactive Execution
#'
#' Helper for logging reactive expression execution in Shiny modules.
#' Logs when reactive is invalidated and when it completes.
#'
#' @param reactive_name Character name of the reactive
#' @param session Shiny session object
#' @param ... Additional context to include in logs
#'
#' @return Nothing (used for side effects)
#'
#' @examples
#' \dontrun{
#' observe({
#'   log_reactive_execution("power_calculation", session, p1 = input$p1)
#'   # ... reactive code
#' })
#' }
#'
#' @noRd
log_reactive_execution <- function(reactive_name, session = NULL, ...) {
  context <- list(...)

  if (!is.null(session)) {
    context$session_id <- session$token
  }

  logger::log_trace(
    paste0("Reactive '", reactive_name, "' executing"),
    reactive = reactive_name,
    context = context
  )
}

#' Log Module Lifecycle Event
#'
#' Standardized logging for Shiny module lifecycle events
#' (initialization, rendering, cleanup).
#'
#' @param module_id Character module identifier
#' @param event Character event type ("init", "render", "cleanup", etc.)
#' @param session Shiny session object (optional)
#' @param ... Additional context to log
#'
#' @return Nothing (used for side effects)
#'
#' @examples
#' \dontrun{
#' mod_server <- function(id) {
#'   moduleServer(id, function(input, output, session) {
#'     log_module_event("two_group", "init", session)
#'     # ... module code
#'   })
#' }
#' }
#'
#' @noRd
log_module_event <- function(module_id, event, session = NULL, ...) {
  context <- list(
    module = module_id,
    event = event,
    ...
  )

  if (!is.null(session)) {
    context <- c(context, get_session_context(session))
  }

  # Use appropriate log level based on event
  log_fn <- switch(event,
    "init" = logger::log_info,
    "cleanup" = logger::log_info,
    "error" = logger::log_error,
    logger::log_debug
  )

  log_fn(
    sprintf("Module '%s' %s", module_id, event),
    context = context
  )
}

#' Log Calculation with Input/Output Context
#'
#' Specialized logging for statistical calculations, capturing both
#' inputs and results for reproducibility and debugging.
#'
#' @param calc_name Character name of the calculation
#' @param inputs Named list of input parameters
#' @param result Calculation result (or NULL if not yet computed)
#' @param success Logical indicating success (default: TRUE)
#' @param error Error object if calculation failed (default: NULL)
#'
#' @return Nothing (used for side effects)
#'
#' @examples
#' \dontrun{
#' result <- tryCatch({
#'   res <- calculate_power(p1, p2, alpha)
#'   log_calculation("power", list(p1=p1, p2=p2, alpha=alpha), res)
#'   res
#' }, error = function(e) {
#'   log_calculation("power", list(p1=p1, p2=p2, alpha=alpha),
#'                  NULL, success=FALSE, error=e)
#' })
#' }
#'
#' @noRd
log_calculation <- function(calc_name, inputs, result = NULL,
                            success = TRUE, error = NULL) {
  if (success) {
    logger::log_info(
      paste0("Calculation '", calc_name, "' completed"),
      calculation = calc_name,
      inputs = inputs,
      result_class = class(result)[1],
      result_length = if (is.null(result)) 0 else length(result)
    )
  } else {
    logger::log_error(
      paste0("Calculation '", calc_name, "' failed"),
      calculation = calc_name,
      inputs = inputs,
      error_class = if (!is.null(error)) class(error)[1] else "unknown",
      error_msg = if (!is.null(error)) conditionMessage(error) else "unknown"
    )
  }
}

#' Safe Logging Helper (Prevents Logging Failures from Breaking Code)
#'
#' Wraps logger calls in tryCatch to ensure logging failures don't
#' crash the application. Use for non-critical logging.
#'
#' @param log_fn Logger function (e.g., logger::log_info)
#' @param ... Arguments to pass to log_fn
#'
#' @return NULL invisibly
#'
#' @examples
#' \dontrun{
#' safe_log(logger::log_debug, "This won't crash if logging fails",
#'          complex_obj = some_object)
#' }
#'
#' @noRd
safe_log <- function(log_fn, ...) {
  tryCatch(
    {
      log_fn(...)
    },
    error = function(e) {
      # Silently fail - don't let logging break the app
      # Optionally write to stderr as fallback
      message(sprintf("[LOGGING ERROR] %s", conditionMessage(e)))
    }
  )

  invisible(NULL)
}

#' Null-coalescing operator
#'
#' Returns left-hand side if not NULL, otherwise right-hand side
#' @param a Left value
#' @param b Right value
#' @return a if not NULL, otherwise b
#' @noRd
`%||%` <- function(a, b) {
  if (is.null(a)) b else a
}
