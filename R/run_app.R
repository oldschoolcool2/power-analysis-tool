#' Run the Shiny Application
#'
#' @param ... Arguments passed to shinyApp()
#'
#' @export
#' @importFrom shiny shinyApp
run_app <- function(...) {
  # Source the existing app.R to get ui and server
  # We do this in a new environment to avoid polluting the global namespace
  app_env <- new.env()
  
  # Source app.R in the app environment
  source(
    system.file("app.R", package = "PowerAnalysisTool"),
    local = app_env
  )
  
  # If app.R is not found in inst/, try the project root
  # (for development mode before package is built)
  if (!exists("ui", envir = app_env) || !exists("server", envir = app_env)) {
    # During development, source from project root
    app_file <- file.path(getwd(), "app.R")
    if (file.exists(app_file)) {
      source(app_file, local = app_env)
    } else {
      stop("Cannot find app.R file")
    }
  }
  
  # Return the shiny app object
  shinyApp(ui = app_env$ui, server = app_env$server, ...)
}
