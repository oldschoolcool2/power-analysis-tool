# Development mode startup script
# Loads all R functions without requiring package installation
#
# KNOWN ISSUES TO MONITOR:
# - Rare comparison error: "Error in ==: comparison (==) is possible only for atomic and list types"
#   Occurred once on 2025-10-27 in .dev.log (line 154)
#   Stack trace shows internal Shiny reactivity code, no clear application source
#   Action: Monitor logs for recurrence; if frequent, add defensive checks around reactive comparisons

# Load all functions from R/ directory
pkgload::load_all(".", export_all = FALSE, helpers = FALSE)

# Set development options
options(
  "golem.app.prod" = FALSE,
  shiny.port = 3838,
  shiny.host = "0.0.0.0",
  shiny.autoreload = TRUE,
  shiny.launch.browser = TRUE,
  # Suppress bslib color contrast warnings (WCAG accessibility checks from dependency)
  bslib.color_contrast_warnings = FALSE
)

# Enable developer mode for additional debugging
if (requireNamespace("shiny", quietly = TRUE)) {
  shiny::devmode(TRUE)
}

# Launch the application on port 3838
PowerAnalysisTool::run_app(
  options = list(
    host = "0.0.0.0",
    port = 3838,
    launch.browser = TRUE
  )
)

