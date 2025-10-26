# Development mode startup script
# Loads all R functions without requiring package installation

# Load all functions from R/ directory
pkgload::load_all(".", export_all = FALSE, helpers = FALSE)

# Set development mode
options("golem.app.prod" = FALSE)

# Launch the application on port 3838
PowerAnalysisTool::run_app(port = 3838, host = "0.0.0.0")

