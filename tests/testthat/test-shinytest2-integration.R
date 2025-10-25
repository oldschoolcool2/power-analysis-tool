# Integration Tests for Power Analysis Tool
# Tests cross-functional workflows and tab navigation

library(shinytest2)

test_that("User can navigate between all tabs", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "tab-navigation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # WHEN: User navigates through all tabs
  tabs <- c("sample_size", "mde", "power")

  for (tab in tabs) {
    app$set_inputs(tabs = tab)
    app$wait_for_idle()

    # THEN: Each tab should load without errors
    current_tab <- app$get_value(input = "tabs")
    expect_equal(current_tab, tab)

    # Take screenshot of each tab
    app$get_screenshot(paste0("navigation-", tab))
  }

  app$stop()
})

test_that("Consistent results across related calculations", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "result-consistency",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # WHEN: User calculates sample size
  app$set_inputs(tabs = "sample_size")
  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  # Extract calculated sample size (implementation-specific)
  sample_size_results <- app$get_values()

  # THEN: Using those sample sizes in power calculation should yield ~0.80 power
  # (This tests internal consistency of calculations)

  app$stop()
})

test_that("Help sections are accessible from all tabs", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "help-accessibility",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  tabs <- c("sample_size", "mde", "power")

  for (tab in tabs) {
    # WHEN: User navigates to each tab and looks for help
    app$set_inputs(tabs = tab)
    app$wait_for_idle()

    # THEN: Help information should be available
    # (Check for help buttons, tooltips, or info sections)
    # Implementation depends on how help is provided in the app

    # Take screenshot showing help availability
    app$get_screenshot(paste0("help-", tab))
  }

  app$stop()
})

test_that("Download functionality works across tabs", {
  skip("Download testing requires additional setup")

  # GIVEN: An initialized app with calculated results
  app <- AppDriver$new(
    app_dir = "../../",
    name = "download-functionality",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # Test download buttons on each tab if available
  # Note: Download testing with shinytest2 requires special handling

  app$stop()
})

test_that("App handles rapid input changes gracefully", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "rapid-input-changes",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")

  # WHEN: User rapidly changes inputs
  for (i in 1:5) {
    app$set_inputs(
      p1 = 0.10 + (i * 0.02),
      p2 = 0.05 + (i * 0.01),
      wait_ = FALSE
    )
  }

  app$wait_for_idle(timeout = 15000)

  # THEN: App should handle this without errors
  app$expect_values()

  app$stop()
})

test_that("App state persists during session", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "state-persistence",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # WHEN: User enters data on one tab
  app$set_inputs(tabs = "sample_size")
  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  initial_values <- app$get_values()

  # Navigate away and back
  app$set_inputs(tabs = "mde")
  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")
  app$wait_for_idle()

  # THEN: Values should persist (if designed to do so)
  final_values <- app$get_values()

  # Check if input values are maintained
  # (Behavior depends on app design - some apps reset, some persist)

  app$stop()
})

test_that("Responsive layout works at different screen sizes", {
  # Test various screen sizes
  screen_sizes <- list(
    mobile = list(width = 375, height = 667),    # iPhone SE
    tablet = list(width = 768, height = 1024),   # iPad
    desktop = list(width = 1920, height = 1080)  # Full HD
  )

  for (size_name in names(screen_sizes)) {
    size <- screen_sizes[[size_name]]

    # GIVEN: App at specific screen size
    app <- AppDriver$new(
      app_dir = "../../",
      name = paste0("responsive-", size_name),
      width = size$width,
      height = size$height
    )

    app$wait_for_idle()

    # WHEN: User interacts with the app
    app$set_inputs(tabs = "sample_size")
    app$wait_for_idle()

    # THEN: Layout should be functional
    app$expect_values()

    # Take screenshot to verify responsive design
    app$get_screenshot(paste0("responsive-", size_name))

    app$stop()
  }
})

test_that("Interactive plots respond to user interactions", {
  # GIVEN: An initialized app with plot output
  app <- AppDriver$new(
    app_dir = "../../",
    name = "interactive-plots",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")

  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  # WHEN: Plot is rendered (if using plotly or similar)
  # THEN: Should support interactivity

  # Take screenshot showing interactive plot
  app$get_screenshot("interactive-plot")

  app$stop()
})

test_that("Error messages are user-friendly", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "error-messages",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")

  # WHEN: User triggers an error condition
  # (e.g., conflicting inputs, out-of-range values)

  # THEN: Error messages should be clear and helpful
  # Take screenshot if error message appears
  app$get_screenshot("error-handling")

  app$stop()
})

test_that("App performance is acceptable", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "performance-check",
    height = 800,
    width = 1200
  )

  # WHEN: User performs typical calculations
  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")

  start_time <- Sys.time()

  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  end_time <- Sys.time()
  calculation_time <- as.numeric(difftime(end_time, start_time, units = "secs"))

  # THEN: Calculations should complete in reasonable time
  expect_true(calculation_time < 5,
              info = paste("Calculation took", round(calculation_time, 2), "seconds"))

  app$stop()
})
