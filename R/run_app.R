#' Run the Shiny Application
#'
#' @param ... Arguments passed to shinyApp()
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(...) {
  # Configure error sanitization based on environment
  # In production, sanitize errors to prevent information leakage
  # In development, show full error messages for debugging
  env <- Sys.getenv("R_CONFIG_ACTIVE", "default")

  if (env == "production") {
    options(shiny.sanitize.errors = TRUE)
    logger::log_info("Error sanitization ENABLED (production mode)")
  } else {
    options(shiny.sanitize.errors = FALSE)
    logger::log_info("Error sanitization DISABLED (development mode)")
  }

  # Log application startup
  logger::log_info(
    "Application starting",
    version = as.character(packageVersion("PowerAnalysisTool")),
    r_version = R.version.string,
    golem_version = as.character(packageVersion("golem")),
    environment = env
  )

  # Source helper files needed by the app
  # These are loaded when the package is loaded
  tryCatch(
    {
      source_helpers()
      logger::log_info("Helper files sourced successfully")
    },
    error = function(e) {
      logger::log_error(
        "Failed to source helper files",
        error_class = class(e)[1],
        error_msg = conditionMessage(e)
      )
      stop(e)
    }
  )

  # Create and return the Shiny app
  logger::log_info("Creating Shiny app object")

  app <- with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      options = list(...)
    ),
    golem_opts = list(...)
  )

  logger::log_info("Shiny app created successfully")

  app
}

#' Source helper files
#'
#' Internal function to source all helper files needed by the app
#' @noRd
source_helpers <- function() {
  # Get the package directory
  pkg_dir <- system.file(package = "PowerAnalysisTool")

  # If in development mode (package not installed), use current directory
  if (pkg_dir == "") {
    pkg_dir <- getwd()
    logger::log_debug("Running in development mode", pkg_dir = pkg_dir)
  } else {
    logger::log_debug("Running in installed mode", pkg_dir = pkg_dir)
  }

  # Define helper files to source
  helper_files <- c(
    "R/sidebar_ui.R",
    "R/input_components.R",
    "R/header_ui.R",
    "R/help_content.R",
    "R/modules/001-missing-data-module.R",
    "R/mod_01_single_proportion.R",
    "R/mod_02_two_group.R",
    "R/helpers/001-plot-helpers.R",
    "R/helpers/002-result-text-helpers.R",
    "R/helpers/003-propensity-score-helpers.R"
  )

  logger::log_debug(
    "Sourcing helper files",
    pkg_dir = pkg_dir,
    file_count = length(helper_files)
  )

  # Track sourcing statistics
  sourced_count <- 0
  skipped_count <- 0

  # Source each helper file
  for (file in helper_files) {
    file_path <- file.path(pkg_dir, file)
    if (file.exists(file_path)) {
      logger::log_trace("Sourcing file", file = file)
      tryCatch(
        {
          source(file_path, local = parent.frame())
          sourced_count <- sourced_count + 1
        },
        error = function(e) {
          logger::log_error(
            "Failed to source file",
            file = file,
            error_msg = conditionMessage(e)
          )
          stop(e)
        }
      )
    } else {
      logger::log_warn("Helper file not found", file = file_path)
      skipped_count <- skipped_count + 1
    }
  }

  logger::log_debug(
    "Helper files sourcing complete",
    sourced = sourced_count,
    skipped = skipped_count,
    total = length(helper_files)
  )
}
