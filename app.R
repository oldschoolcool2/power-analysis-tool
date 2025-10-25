# Launch the Shiny Application (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue Publish button on top of this file in RStudio

# Load the package
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)

# Set production mode
options("golem.app.prod" = TRUE)

# Launch the application
PowerAnalysisTool::run_app()
