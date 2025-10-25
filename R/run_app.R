#' Run the Shiny Application
#'
#' @param ... Arguments passed to shinyApp()
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(...) {
  # Source helper files needed by the app
  # These are loaded when the package is loaded
  source_helpers()

  # Create and return the Shiny app
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      options = list(...)
    ),
    golem_opts = list(...)
  )
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
  }

  # Define helper files to source
  helper_files <- c(
    "R/sidebar_ui.R",
    "R/input_components.R",
    "R/header_ui.R",
    "R/help_content.R",
    "R/modules/001-missing-data-module.R",
    "R/helpers/001-plot-helpers.R",
    "R/helpers/002-result-text-helpers.R",
    "R/helpers/003-propensity-score-helpers.R"
  )

  # Source each helper file
  for (file in helper_files) {
    file_path <- file.path(pkg_dir, file)
    if (file.exists(file_path)) {
      source(file_path, local = parent.frame())
    }
  }
}
