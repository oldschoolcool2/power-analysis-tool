#' Package Initialization and Logging Configuration
#'
#' These functions are called when the package is loaded and attached.
#' They configure the logging system for the Power Analysis Tool.

#' Configure Logging on Package Load
#'
#' Sets up logging configuration when package loads. This includes:
#' - Setting log level from environment variables
#' - Configuring structured logging format
#' - Setting up appropriate appenders for dev vs production
#'
#' Environment Variables:
#' - PAT_LOG_LEVEL: Log threshold (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
#' - PAT_LOG_DIR: Directory for log files (default: ./logs)
#' - PAT_LOG_FORMAT: Format (console or json, default: auto-detect)
#'
#' @param libname Library name
#' @param pkgname Package name
#' @noRd
.onLoad <- function(libname, pkgname) {
  # Determine log level from environment (defaults to INFO in production)
  log_level <- Sys.getenv("PAT_LOG_LEVEL", "INFO")

  # Validate and set log level
  valid_levels <- c("TRACE", "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR", "FATAL")
  if (!toupper(log_level) %in% valid_levels) {
    warning(sprintf("Invalid PAT_LOG_LEVEL '%s'. Using 'INFO'", log_level))
    log_level <- "INFO"
  }

  # Set the default log level
  logger::log_threshold(log_level)

  # Determine output format
  log_format <- Sys.getenv("PAT_LOG_FORMAT", "auto")
  use_json <- if (log_format == "json") {
    TRUE
  } else if (log_format == "console") {
    FALSE
  } else {
    # Auto-detect: use JSON in non-interactive mode (production)
    !interactive()
  }

  # Configure log layout and formatter
  if (use_json) {
    # Production: structured JSON logging
    logger::log_layout(logger::layout_json())
    logger::log_formatter(logger::formatter_json)
  } else {
    # Development: human-readable colorful logging
    logger::log_layout(logger::layout_glue_colors)
    logger::log_formatter(logger::formatter_glue_or_sprintf)
  }

  # Configure appenders based on environment
  if (interactive()) {
    # Development: console logging only
    logger::log_appender(logger::appender_console)
  } else {
    # Production: both file and console logging
    log_dir <- Sys.getenv("PAT_LOG_DIR", "./logs")

    # Create log directory if it doesn't exist
    if (!dir.exists(log_dir)) {
      dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
    }

    # Create log file path with date
    log_file <- file.path(log_dir, sprintf("app_%s.log", Sys.Date()))

    # Use tee appender to write to both file and console
    logger::log_appender(logger::appender_tee(
      logger::appender_file(log_file, append = TRUE),
      logger::appender_console
    ))
  }

  # Set up custom log namespace for this package
  logger::log_info(
    "PowerAnalysisTool package loaded",
    version = as.character(packageVersion("PowerAnalysisTool")),
    r_version = R.version.string,
    log_level = log_level,
    interactive = interactive()
  )
}

#' Display Startup Message on Package Attach
#'
#' Shows a friendly message when package is attached (library() call)
#'
#' @param libname Library name
#' @param pkgname Package name
#' @noRd
.onAttach <- function(libname, pkgname) {
  # Only show startup message in interactive sessions
  if (interactive()) {
    pkg_version <- packageVersion("PowerAnalysisTool")
    log_level <- Sys.getenv("PAT_LOG_LEVEL", "INFO")

    msg <- sprintf(
      "PowerAnalysisTool v%s loaded with logging enabled (level: %s)",
      pkg_version,
      log_level
    )

    packageStartupMessage(msg)
    packageStartupMessage("Set PAT_LOG_LEVEL environment variable to change log verbosity")
  }
}

#' Clean Up on Package Unload
#'
#' Performs cleanup when package is unloaded
#'
#' @param libpath Library path
#' @noRd
.onUnload <- function(libpath) {
  logger::log_info("PowerAnalysisTool package unloading")
}
