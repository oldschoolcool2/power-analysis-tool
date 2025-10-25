# Setup file for shinytest2 tests
# This file is run before all tests

# Load shinytest2
library(shinytest2)

# Set options for consistent testing behavior
options(shiny.snapshotsortc = TRUE)  # Consistent snapshot sorting across locales

# Configure test mode
options(shiny.testmode = TRUE)

# Helper function to create AppDriver for the main app
create_app_driver <- function(...) {
  AppDriver$new(
    app_dir = system.file(package = "power-analysis-tool"),
    name = "power-analysis-tool",
    variant = platform_variant(),
    ...
  )
}

# Helper function to wait for Shiny to be ready
wait_for_shiny_ready <- function(app, timeout = 30000) {
  app$wait_for_idle(timeout = timeout)
}

# Page Object Model helper class for better test organization
PowerAnalysisApp <- R6::R6Class(
  "PowerAnalysisApp",
  public = list(
    app = NULL,

    initialize = function(app_driver) {
      self$app <- app_driver
    },

    # Navigation methods
    switch_to_tab = function(tab_id) {
      self$app$set_inputs(tabs = tab_id)
      self$app$wait_for_idle()
      invisible(self)
    },

    # Input methods for Sample Size tab
    set_sample_size_inputs = function(p1 = NULL, p2 = NULL, alpha = NULL, power = NULL) {
      inputs <- list()
      if (!is.null(p1)) inputs$p1 <- p1
      if (!is.null(p2)) inputs$p2 <- p2
      if (!is.null(alpha)) inputs$alpha <- alpha
      if (!is.null(power)) inputs$power <- power

      if (length(inputs) > 0) {
        do.call(self$app$set_inputs, inputs)
        self$app$wait_for_idle()
      }
      invisible(self)
    },

    # Input methods for MDE tab
    set_mde_inputs = function(n1 = NULL, n2 = NULL, p1 = NULL, alpha = NULL, power = NULL) {
      inputs <- list()
      if (!is.null(n1)) inputs$n1_mde <- n1
      if (!is.null(n2)) inputs$n2_mde <- n2
      if (!is.null(p1)) inputs$p1_mde <- p1
      if (!is.null(alpha)) inputs$alpha_mde <- alpha
      if (!is.null(power)) inputs$power_mde <- power

      if (length(inputs) > 0) {
        do.call(self$app$set_inputs, inputs)
        self$app$wait_for_idle()
      }
      invisible(self)
    },

    # Input methods for Power Calculation tab
    set_power_inputs = function(n1 = NULL, n2 = NULL, p1 = NULL, p2 = NULL, alpha = NULL) {
      inputs <- list()
      if (!is.null(n1)) inputs$n1_power <- n1
      if (!is.null(n2)) inputs$n2_power <- n2
      if (!is.null(p1)) inputs$p1_power <- p1
      if (!is.null(p2)) inputs$p2_power <- p2
      if (!is.null(alpha)) inputs$alpha_power <- alpha

      if (length(inputs) > 0) {
        do.call(self$app$set_inputs, inputs)
        self$app$wait_for_idle()
      }
      invisible(self)
    },

    # Verification methods
    get_output_value = function(output_id) {
      self$app$get_value(output = output_id)
    },

    get_input_value = function(input_id) {
      self$app$get_value(input = input_id)
    },

    # Screenshot method
    take_screenshot = function(name = NULL) {
      if (is.null(name)) {
        self$app$get_screenshot()
      } else {
        self$app$get_screenshot(name)
      }
    },

    # Expect methods for assertions
    expect_output_contains = function(output_id, expected_text) {
      output <- self$get_output_value(output_id)
      testthat::expect_true(
        grepl(expected_text, output, fixed = TRUE),
        info = paste0("Output '", output_id, "' should contain '", expected_text, "'")
      )
      invisible(self)
    },

    expect_no_errors = function() {
      # Check that no error messages are displayed
      self$app$expect_values()
      invisible(self)
    }
  )
)
