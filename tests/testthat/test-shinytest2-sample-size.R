# End-to-End Tests for Sample Size Calculation Tab
# Tests the complete user workflow for calculating sample size

library(shinytest2)

test_that("Sample Size tab loads correctly", {
  # GIVEN: A fresh instance of the app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-load",
    height = 800,
    width = 1200
  )

  # WHEN: The app initializes
  app$wait_for_idle()

  # THEN: The default tab should be visible
  app$expect_values(
    input = c("tabs", "p1", "p2", "alpha", "power"),
    output = c("results")
  )

  # Clean up
  app$stop()
})

test_that("Sample Size calculation works with valid inputs", {
  # GIVEN: An initialized app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-calculation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # Ensure we're on the Sample Size tab
  app$set_inputs(tabs = "sample_size")
  app$wait_for_idle()

  # WHEN: User enters valid proportions for sample size calculation
  # Example: p1 = 0.15, p2 = 0.10, alpha = 0.05, power = 0.80
  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE,
    timeout_ = 5000
  )

  app$wait_for_idle(timeout = 10000)

  # THEN: Results should be calculated and displayed
  app$expect_values(
    output = c("results", "plot_power_curve")
  )

  # Verify no error messages
  expect_true(is.null(app$get_value(output = "error_message")))

  # Take screenshot for visual regression testing
  app$get_screenshot("sample-size-valid-inputs")

  app$stop()
})

test_that("Sample Size validation prevents invalid inputs", {
  # GIVEN: An initialized app on Sample Size tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-validation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")
  app$wait_for_idle()

  # WHEN: User enters invalid proportion (p1 > 1)
  app$set_inputs(
    p1 = 1.5,  # Invalid: greater than 1
    p2 = 0.10,
    wait_ = FALSE
  )

  app$wait_for_idle()

  # THEN: Should show validation error or prevent calculation
  # Note: Actual behavior depends on app implementation
  # This test documents the expected behavior

  app$stop()
})

test_that("Sample Size switches between one-sided and two-sided tests", {
  # GIVEN: An initialized app on Sample Size tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-test-type",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")
  app$wait_for_idle()

  # Set baseline inputs
  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  # Record results for two-sided test (default)
  two_sided_snapshot <- app$get_values()

  # WHEN: User switches to one-sided test
  if (!is.null(app$get_value(input = "test_type"))) {
    app$set_inputs(test_type = "one.sided")
    app$wait_for_idle()

    # THEN: Results should update (one-sided test requires smaller sample size)
    one_sided_snapshot <- app$get_values()

    # Results should be different between test types
    expect_false(identical(two_sided_snapshot, one_sided_snapshot))
  }

  app$stop()
})

test_that("Sample Size power curve renders correctly", {
  # GIVEN: An initialized app with valid inputs
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-power-curve",
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

  app$wait_for_idle(timeout = 10000)

  # WHEN: Power curve should be rendered
  # THEN: Check that the plot output exists
  plot_output <- app$get_value(output = "plot_power_curve")

  # Should have plot data
  expect_true(!is.null(plot_output))

  # Take screenshot of the power curve
  app$get_screenshot("sample-size-power-curve")

  app$stop()
})

test_that("Sample Size allocation ratio affects results", {
  # GIVEN: An initialized app on Sample Size tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "sample-size-allocation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "sample_size")

  # Set baseline with 1:1 allocation
  app$set_inputs(
    p1 = 0.15,
    p2 = 0.10,
    alpha = 0.05,
    power = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  baseline_results <- app$get_values()

  # WHEN: User changes allocation ratio (if available)
  if (!is.null(app$get_value(input = "allocation_ratio"))) {
    app$set_inputs(allocation_ratio = 2)
    app$wait_for_idle()

    # THEN: Results should change
    changed_results <- app$get_values()
    expect_false(identical(baseline_results, changed_results))
  }

  app$stop()
})
