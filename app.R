# Launch the Shiny Application (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue Publish button on top of this file in RStudio

# Production approach: Load the installed package
# (For development, pkgload::load_all() can be used instead)
library(PowerAnalysisTool)

# Set production mode
options("golem.app.prod" = TRUE)

# Launch the application
PowerAnalysisTool::run_app()
