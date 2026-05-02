#' Run the Shiny Application
#'
#' @param ... Arguments passed to shinyApp()
#'
#' @export
#' @importFrom shiny shinyApp checkboxInput eventReactive onStop selectInput sliderInput
#' @importFrom golem with_golem_options
#' @importFrom utils packageVersion
#' @importFrom magrittr %>%
run_app <- function(...) {
  # Configure file-based logging now that an app session is actually starting.
  # Done here (not in .onLoad) so package load stays free of filesystem I/O.
  setup_app_logging()

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
    version = as.character(utils::packageVersion("PowerAnalysisTool")),
    r_version = R.version.string,
    golem_version = as.character(utils::packageVersion("golem")),
    environment = env
  )

  # Create and return the Shiny app
  # Note: All R files are automatically loaded when the package is loaded
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
