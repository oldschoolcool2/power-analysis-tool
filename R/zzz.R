#' Package Initialization and Logging Configuration
#'
#' These functions are called when the package is loaded and attached.
#' They configure the logging system for the Power Analysis Tool.

#' Configure Logging on Package Load
#'
#' Sets safe defaults when the package loads. Per R packaging best practice,
#' `.onLoad` does not touch the filesystem and does not emit log messages --
#' both can fail under R CMD check or in restricted execution contexts. The
#' file appender (when applicable) is configured later by `setup_app_logging()`,
#' which `run_app()` calls once the application is actually starting.
#'
#' Environment Variables:
#' - PAT_LOG_LEVEL: Log threshold (TRACE, DEBUG, INFO, WARN, ERROR, FATAL)
#' - PAT_LOG_FORMAT: Format (console or json, default: auto-detect)
#'
#' @param libname Library name
#' @param pkgname Package name
#' @noRd
.onLoad <- function(libname, pkgname) {
  log_level <- Sys.getenv("PAT_LOG_LEVEL", "INFO")
  valid_levels <- c("TRACE", "DEBUG", "INFO", "SUCCESS", "WARN", "ERROR", "FATAL")
  if (!toupper(log_level) %in% valid_levels) {
    log_level <- "INFO"
  }

  logger::log_threshold(log_level)

  log_format <- Sys.getenv("PAT_LOG_FORMAT", "auto")
  use_json <- if (log_format == "json") {
    TRUE
  } else if (log_format == "console") {
    FALSE
  } else {
    !interactive()
  }

  if (use_json) {
    logger::log_layout(logger::layout_json())
    logger::log_formatter(logger::formatter_json)
  } else {
    logger::log_layout(logger::layout_glue_colors)
    logger::log_formatter(logger::formatter_glue_or_sprintf)
  }

  logger::log_appender(logger::appender_console)
}

#' Configure File-Based Logging for an App Session
#'
#' Sets up the tee appender (file + console) used in production. Called from
#' `run_app()` so that file connections are only opened when the app actually
#' starts -- not during package load, R CMD check, or `library()` calls where
#' the working directory may be read-only or transient.
#'
#' Falls back to console-only logging if the log directory cannot be created
#' or the file cannot be opened.
#'
#' @return Invisibly returns TRUE if file appender was configured, FALSE if
#'   we fell back to console-only.
#' @keywords internal
#' @noRd
setup_app_logging <- function() {
  if (interactive()) {
    return(invisible(FALSE))
  }

  log_dir <- Sys.getenv("PAT_LOG_DIR", "./logs")

  dir_ok <- tryCatch(
    {
      if (!dir.exists(log_dir)) {
        dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
      }
      dir.exists(log_dir)
    },
    error = function(e) FALSE
  )

  if (!isTRUE(dir_ok)) {
    return(invisible(FALSE))
  }

  log_file <- file.path(log_dir, sprintf("app_%s.log", Sys.Date()))

  appender_ok <- tryCatch(
    {
      logger::log_appender(logger::appender_tee(
        logger::appender_file(log_file, append = TRUE),
        logger::appender_console
      ))
      TRUE
    },
    error = function(e) FALSE
  )

  invisible(appender_ok)
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
    pkg_version <- utils::packageVersion("PowerAnalysisTool")
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
