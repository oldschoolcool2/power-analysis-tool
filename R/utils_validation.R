#' Input Validation Utilities
#'
#' Server-side input validation and sanitization functions following
#' golem framework and Shiny best practices for production-grade applications.
#'
#' @section Philosophy:
#' - Always validate on the server (client-side can be bypassed)
#' - Use allowlisting over denylisting
#' - Fail fast with clear error messages
#' - Log validation failures in production
#'
#' @name utils_validation
NULL

#' Validate and Sanitize Numeric Input
#'
#' Validates that an input is numeric, within range, and handles type coercion
#' with proper error handling. This prevents invalid values from reaching
#' calculation functions.
#'
#' @param value Input value to validate
#' @param name Parameter name for error messages
#' @param min Minimum allowed value (optional)
#' @param max Maximum allowed value (optional)
#' @param allow_null Whether NULL is acceptable (default: FALSE)
#' @param allow_na Whether NA is acceptable (default: FALSE)
#'
#' @return Validated numeric value
#' @export
#'
#' @examples
#' \dontrun{
#' # Validate sample size
#' n <- validate_numeric_input(input$sample_size, "Sample size", min = 1)
#'
#' # Validate proportion with range
#' p <- validate_numeric_input(input$proportion, "Proportion", min = 0, max = 100)
#'
#' # Allow NULL for optional parameters
#' alpha <- validate_numeric_input(input$alpha, "Alpha", min = 0, max = 1, allow_null = TRUE)
#' }
validate_numeric_input <- function(value, name, min = NULL, max = NULL,
                                   allow_null = FALSE, allow_na = FALSE) {

  # Handle NULL
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    logger::log_warn("validate_numeric_input: NULL value not allowed", param_name = name)
    stop(sprintf("%s cannot be NULL", name), call. = FALSE)
  }

  # Check if already numeric
  if (!is.numeric(value)) {
    # Attempt coercion
    converted <- suppressWarnings(as.numeric(value))
    if (is.na(converted) && !is.na(value)) {
      logger::log_warn(
        "validate_numeric_input: non-numeric value",
        param_name = name,
        value_type = class(value)[1],
        value = as.character(value)
      )
      stop(sprintf(
        "%s must be numeric, got: %s (value: %s)",
        name,
        class(value)[1],
        as.character(value)
      ), call. = FALSE)
    }
    value <- converted
  }

  # Handle NA
  if (is.na(value)) {
    if (allow_na) {
      return(NA_real_)
    }
    logger::log_warn("validate_numeric_input: NA value not allowed", param_name = name)
    stop(sprintf("%s cannot be NA", name), call. = FALSE)
  }

  # Check for infinite values
  if (is.infinite(value)) {
    logger::log_warn("validate_numeric_input: infinite value not allowed", param_name = name, value = value)
    stop(sprintf("%s cannot be infinite", name), call. = FALSE)
  }

  # Check minimum
  if (!is.null(min) && value < min) {
    stop(sprintf(
      "%s must be >= %s, got: %s",
      name,
      format(min, scientific = FALSE),
      format(value, scientific = FALSE)
    ), call. = FALSE)
  }

  # Check maximum
  if (!is.null(max) && value > max) {
    stop(sprintf(
      "%s must be <= %s, got: %s",
      name,
      format(max, scientific = FALSE),
      format(value, scientific = FALSE)
    ), call. = FALSE)
  }

  return(value)
}


#' Validate Choice Input Against Allowlist
#'
#' Validates that a selected value is in the allowed set of choices.
#' This prevents manipulation of radio buttons, select inputs, etc.
#' Uses allowlisting (explicit allowed values) rather than denylisting.
#'
#' @param value Selected value from input
#' @param choices Vector of valid choices (the allowlist)
#' @param name Parameter name for error messages
#' @param allow_null Whether NULL is acceptable (default: FALSE)
#'
#' @return Validated value (unchanged if valid)
#' @export
#'
#' @examples
#' \dontrun{
#' VALID_ALPHA <- c("0.001", "0.01", "0.05", "0.10")
#' alpha <- validate_choice_input(input$alpha, VALID_ALPHA, "Alpha level")
#'
#' VALID_TEST_TYPES <- c("one_sided", "two_sided")
#' test_type <- validate_choice_input(input$test_type, VALID_TEST_TYPES, "Test type")
#' }
validate_choice_input <- function(value, choices, name, allow_null = FALSE) {

  # Handle NULL
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    stop(sprintf("%s cannot be NULL", name), call. = FALSE)
  }

  # Validate against allowlist
  if (!value %in% choices) {
    stop(sprintf(
      "%s must be one of: %s. Got: %s",
      name,
      paste(shQuote(choices), collapse = ", "),
      shQuote(value)
    ), call. = FALSE)
  }

  return(value)
}


#' Validate Proportion Input
#'
#' Convenience wrapper for validating proportion/percentage inputs.
#' Ensures value is between 0-100 and handles common edge cases.
#'
#' @param value Input value to validate
#' @param name Parameter name for error messages
#' @param allow_zero Whether 0\% is acceptable (default: TRUE)
#' @param allow_hundred Whether 100\% is acceptable (default: TRUE)
#' @param allow_null Whether NULL is acceptable (default: FALSE)
#'
#' @return Validated proportion value
#' @export
#'
#' @examples
#' \dontrun{
#' event_rate <- validate_proportion_input(input$event_rate, "Event rate")
#' discontinuation <- validate_proportion_input(input$discon, "Discontinuation rate")
#' }
validate_proportion_input <- function(value, name, allow_zero = TRUE,
                                     allow_hundred = TRUE, allow_null = FALSE) {

  # Handle NULL
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    stop(sprintf("%s cannot be NULL", name), call. = FALSE)
  }

  # Use numeric validator with 0-100 range
  min_val <- if (allow_zero) 0 else .Machine$double.eps
  max_val <- if (allow_hundred) 100 else 100 - .Machine$double.eps

  value <- validate_numeric_input(value, name, min = min_val, max = max_val)

  return(value)
}


#' Validate Integer Input
#'
#' Validates and coerces to integer. Useful for count variables
#' like number of tests, number of clusters, etc.
#'
#' @param value Input value to validate
#' @param name Parameter name for error messages
#' @param min Minimum allowed value (optional)
#' @param max Maximum allowed value (optional)
#' @param allow_null Whether NULL is acceptable (default: FALSE)
#'
#' @return Validated integer value
#' @export
#'
#' @examples
#' \dontrun{
#' n_tests <- validate_integer_input(input$n_tests, "Number of tests", min = 1)
#' n_clusters <- validate_integer_input(input$n_clusters, "Number of clusters", min = 2)
#' }
validate_integer_input <- function(value, name, min = NULL, max = NULL, allow_null = FALSE) {

  # Handle NULL
  if (is.null(value)) {
    if (allow_null) {
      return(NULL)
    }
    stop(sprintf("%s cannot be NULL", name), call. = FALSE)
  }

  # First validate as numeric
  value <- validate_numeric_input(value, name, min = min, max = max)

  # Check if it's a whole number
  if (abs(value - round(value)) > .Machine$double.eps) {
    stop(sprintf(
      "%s must be a whole number, got: %s",
      name,
      format(value, scientific = FALSE)
    ), call. = FALSE)
  }

  # Convert to integer
  return(as.integer(round(value)))
}


#' Create Validation Result Object
#'
#' Standardized structure for validation results with status and messages.
#' Used by module-specific validators that return validation feedback.
#'
#' @param valid Logical - whether validation passed
#' @param messages Character vector of error/warning/info messages
#'
#' @return List with components:
#'   \describe{
#'     \item{valid}{Logical - TRUE if all validations passed}
#'     \item{messages}{Character vector of messages}
#'     \item{errors}{Character vector of error messages only}
#'     \item{warnings}{Character vector of warning messages only}
#'     \item{notes}{Character vector of informational messages only}
#'   }
#' @export
#'
#' @examples
#' \dontrun{
#' messages <- character(0)
#' valid <- TRUE
#'
#' if (n < 1) {
#'   messages <- c(messages, "ERROR: Sample size must be positive")
#'   valid <- FALSE
#' }
#'
#' if (effect_size < 0.1) {
#'   messages <- c(messages, "WARNING: Small effect size detected")
#' }
#'
#' validation_result(valid, messages)
#' }
validation_result <- function(valid, messages = character(0)) {

  # Extract message types
  errors <- grep("^ERROR:", messages, value = TRUE)
  warnings <- grep("^WARNING:", messages, value = TRUE)
  notes <- grep("^NOTE:", messages, value = TRUE)

  list(
    valid = valid,
    messages = messages,
    errors = errors,
    warnings = warnings,
    notes = notes
  )
}


#' Validate Cross-Field Logic
#'
#' Helper for validating logical relationships between multiple inputs.
#'
#' @param condition Logical condition to check
#' @param message Error message if condition is FALSE
#' @param type Message type: "ERROR", "WARNING", or "NOTE" (default: "ERROR")
#'
#' @return NULL if condition is TRUE, otherwise stops with error or returns message
#' @export
#'
#' @examples
#' \dontrun{
#' # Error if proportions are identical
#' validate_cross_field(
#'   p1 != p2,
#'   "Proportions must differ for power calculation"
#' )
#'
#' # Warning if effect size is small
#' validate_cross_field(
#'   abs(p1 - p2) >= 5,
#'   "Small effect size may require very large sample",
#'   type = "WARNING"
#' )
#' }
validate_cross_field <- function(condition, message, type = "ERROR") {

  if (!condition) {
    formatted_msg <- sprintf("%s: %s", type, message)

    if (type == "ERROR") {
      stop(formatted_msg, call. = FALSE)
    } else {
      return(formatted_msg)
    }
  }

  return(NULL)
}


#' Safe Numeric Coercion with Default
#'
#' Attempts to coerce a value to numeric, returning a default if coercion fails.
#' Useful for handling potentially invalid input with graceful degradation.
#'
#' @param value Value to coerce
#' @param default Default value if coercion fails
#'
#' @return Coerced numeric value or default
#' @export
#'
#' @examples
#' \dontrun{
#' # Returns 100 if input is invalid
#' n <- safe_numeric(input$sample_size, default = 100)
#'
#' # Returns NA if input is invalid
#' alpha <- safe_numeric(input$alpha, default = NA)
#' }
safe_numeric <- function(value, default) {

  if (is.null(value)) {
    return(default)
  }

  if (is.numeric(value) && !is.na(value)) {
    return(value)
  }

  converted <- suppressWarnings(as.numeric(value))

  if (is.na(converted)) {
    return(default)
  }

  return(converted)
}
