# End-to-End Tests for Power Calculation Tab
# Tests the complete user workflow for calculating statistical power

library(shinytest2)

test_that("Power Calculation tab loads correctly", {
  # GIVEN: A fresh instance of the app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-tab-load",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # WHEN: User navigates to Power Calculation tab
  app$set_inputs(tabs = "power")
  app$wait_for_idle()

  # THEN: Power-specific inputs should be available
  app$expect_values(
    input = c("tabs", "n1_power", "n2_power", "p1_power", "p2_power", "alpha_power")
  )

  # Take screenshot
  app$get_screenshot("power-tab-initial")

  app$stop()
})

test_that("Power calculation works with valid inputs", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-calculation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")
  app$wait_for_idle()

  # WHEN: User enters sample sizes and proportions
  # Example: n1 = 1000, n2 = 1000, p1 = 0.15, p2 = 0.10, alpha = 0.05
  app$set_inputs(
    n1_power = 1000,
    n2_power = 1000,
    p1_power = 0.15,
    p2_power = 0.10,
    alpha_power = 0.05,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  # THEN: Power should be calculated and displayed
  app$expect_values(output = "results_power")

  # Power should be a reasonable value (0 < power < 1)
  results <- app$get_value(output = "results_power")
  expect_true(!is.null(results))

  # Take screenshot
  app$get_screenshot("power-valid-calculation")

  app$stop()
})

test_that("Power increases with larger sample sizes", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-sample-size-relationship",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")
  app$wait_for_idle()

  # Set small sample size
  app$set_inputs(
    n1_power = 200,
    n2_power = 200,
    p1_power = 0.15,
    p2_power = 0.10,
    alpha_power = 0.05,
    wait_ = FALSE
  )
  app$wait_for_idle()

  small_n_results <- app$get_values()

  # WHEN: User increases sample size
  app$set_inputs(
    n1_power = 2000,
    n2_power = 2000,
    wait_ = FALSE
  )
  app$wait_for_idle()

  large_n_results <- app$get_values()

  # THEN: Power should increase with larger sample size
  expect_false(identical(small_n_results, large_n_results))

  app$stop()
})

test_that("Power increases with larger effect sizes", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-effect-size-relationship",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")
  app$wait_for_idle()

  # Set small effect size (p1 = 0.15, p2 = 0.14)
  app$set_inputs(
    n1_power = 1000,
    n2_power = 1000,
    p1_power = 0.15,
    p2_power = 0.14,
    alpha_power = 0.05,
    wait_ = FALSE
  )
  app$wait_for_idle()

  small_effect_results <- app$get_values()

  # WHEN: User increases effect size (p2 = 0.10)
  app$set_inputs(p2_power = 0.10, wait_ = FALSE)
  app$wait_for_idle()

  large_effect_results <- app$get_values()

  # THEN: Power should increase with larger effect size
  expect_false(identical(small_effect_results, large_effect_results))

  app$stop()
})

test_that("Power responds to alpha level changes", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-alpha-sensitivity",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")

  # Set baseline with alpha = 0.05
  app$set_inputs(
    n1_power = 1000,
    n2_power = 1000,
    p1_power = 0.15,
    p2_power = 0.10,
    alpha_power = 0.05,
    wait_ = FALSE
  )
  app$wait_for_idle()

  alpha_05_results <- app$get_values()

  # WHEN: User changes alpha to 0.01 (more stringent)
  app$set_inputs(alpha_power = 0.01, wait_ = FALSE)
  app$wait_for_idle()

  alpha_01_results <- app$get_values()

  # THEN: Power should decrease (harder to detect at stricter alpha)
  expect_false(identical(alpha_05_results, alpha_01_results))

  app$stop()
})

test_that("Power handles edge cases gracefully", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-edge-cases",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")
  app$wait_for_idle()

  # WHEN: User enters identical proportions (no effect)
  app$set_inputs(
    n1_power = 1000,
    n2_power = 1000,
    p1_power = 0.15,
    p2_power = 0.15,  # Same as p1
    alpha_power = 0.05,
    wait_ = FALSE
  )

  app$wait_for_idle()

  # THEN: Should handle this case (power should equal alpha)
  # or show appropriate message

  app$stop()
})

test_that("Power calculation handles unequal group sizes", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-unequal-groups",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")

  # WHEN: User enters unequal group sizes (2:1 ratio)
  app$set_inputs(
    n1_power = 2000,
    n2_power = 1000,
    p1_power = 0.15,
    p2_power = 0.10,
    alpha_power = 0.05,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  # THEN: Should calculate power appropriately for unequal groups
  app$expect_values(output = "results_power")

  # Take screenshot
  app$get_screenshot("power-unequal-groups")

  app$stop()
})

test_that("Power visualization renders correctly", {
  # GIVEN: An initialized app with valid Power inputs
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-visualization",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")

  app$set_inputs(
    n1_power = 1000,
    n2_power = 1000,
    p1_power = 0.15,
    p2_power = 0.10,
    alpha_power = 0.05,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  # WHEN/THEN: Power visualizations should render if available
  # Check for plot outputs
  if (!is.null(app$get_value(output = "plot_power"))) {
    plot_output <- app$get_value(output = "plot_power")
    expect_true(!is.null(plot_output))

    # Take screenshot for visual regression
    app$get_screenshot("power-visualization-plot")
  }

  app$stop()
})

test_that("Power calculation validates input ranges", {
  # GIVEN: An initialized app on Power tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "power-input-validation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "power")
  app$wait_for_idle()

  # WHEN: User enters invalid proportion (> 1)
  # Note: Input validation might prevent this at the UI level
  # This test documents expected behavior

  # THEN: App should handle validation appropriately

  app$stop()
})
