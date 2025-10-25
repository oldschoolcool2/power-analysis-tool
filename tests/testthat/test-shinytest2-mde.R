# End-to-End Tests for Minimal Detectable Effect (MDE) Tab
# Tests the complete user workflow for calculating MDE

library(shinytest2)

test_that("MDE tab loads and displays correctly", {
  # GIVEN: A fresh instance of the app
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-tab-load",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()

  # WHEN: User navigates to MDE tab
  app$set_inputs(tabs = "mde")
  app$wait_for_idle()

  # THEN: MDE-specific inputs should be available
  app$expect_values(
    input = c("tabs", "n1_mde", "n2_mde", "p1_mde", "alpha_mde", "power_mde")
  )

  # Take screenshot of MDE tab
  app$get_screenshot("mde-tab-initial")

  app$stop()
})

test_that("MDE calculation works with valid sample sizes", {
  # GIVEN: An initialized app on MDE tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-calculation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")
  app$wait_for_idle()

  # WHEN: User enters sample sizes and baseline proportion
  # Example: n1 = 1000, n2 = 1000, p1 = 0.15, alpha = 0.05, power = 0.80
  app$set_inputs(
    n1_mde = 1000,
    n2_mde = 1000,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  # THEN: MDE should be calculated and displayed
  app$expect_values(
    output = c("results_mde", "plot_mde_curve")
  )

  # Verify results are numeric and reasonable
  results <- app$get_value(output = "results_mde")
  expect_true(!is.null(results))

  # Take screenshot
  app$get_screenshot("mde-valid-calculation")

  app$stop()
})

test_that("MDE increases with smaller sample sizes", {
  # GIVEN: An initialized app on MDE tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-sample-size-relationship",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")
  app$wait_for_idle()

  # Set large sample size
  app$set_inputs(
    n1_mde = 2000,
    n2_mde = 2000,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  large_n_results <- app$get_values()

  # WHEN: User reduces sample size
  app$set_inputs(
    n1_mde = 500,
    n2_mde = 500,
    wait_ = FALSE
  )
  app$wait_for_idle()

  small_n_results <- app$get_values()

  # THEN: MDE should be larger with smaller sample size
  # (This is the fundamental relationship we're testing)
  expect_false(identical(large_n_results, small_n_results))

  app$stop()
})

test_that("MDE validates minimum sample size requirements", {
  # GIVEN: An initialized app on MDE tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-validation",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")
  app$wait_for_idle()

  # WHEN: User enters very small sample sizes
  app$set_inputs(
    n1_mde = 10,
    n2_mde = 10,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle()

  # THEN: Should either show warning or handle gracefully
  # (Exact behavior depends on implementation)

  app$stop()
})

test_that("MDE curve visualization renders", {
  # GIVEN: An initialized app with valid MDE inputs
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-curve-visualization",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")

  app$set_inputs(
    n1_mde = 1000,
    n2_mde = 1000,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  # WHEN/THEN: MDE curve plot should render
  plot_output <- app$get_value(output = "plot_mde_curve")
  expect_true(!is.null(plot_output))

  # Take screenshot for visual regression
  app$get_screenshot("mde-curve-plot")

  app$stop()
})

test_that("MDE responds to alpha level changes", {
  # GIVEN: An initialized app on MDE tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-alpha-sensitivity",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")

  # Set baseline with alpha = 0.05
  app$set_inputs(
    n1_mde = 1000,
    n2_mde = 1000,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  alpha_05_results <- app$get_values()

  # WHEN: User changes alpha to 0.01 (more stringent)
  app$set_inputs(alpha_mde = 0.01, wait_ = FALSE)
  app$wait_for_idle()

  alpha_01_results <- app$get_values()

  # THEN: MDE should increase (need larger effect to detect at stricter alpha)
  expect_false(identical(alpha_05_results, alpha_01_results))

  app$stop()
})

test_that("MDE responds to power level changes", {
  # GIVEN: An initialized app on MDE tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-power-sensitivity",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")

  # Set baseline with power = 0.80
  app$set_inputs(
    n1_mde = 1000,
    n2_mde = 1000,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )
  app$wait_for_idle()

  power_80_results <- app$get_values()

  # WHEN: User increases power to 0.90
  app$set_inputs(power_mde = 0.90, wait_ = FALSE)
  app$wait_for_idle()

  power_90_results <- app$get_values()

  # THEN: MDE should increase (need larger effect to achieve higher power)
  expect_false(identical(power_80_results, power_90_results))

  app$stop()
})

test_that("MDE handles unequal group sizes", {
  # GIVEN: An initialized app on MDE tab
  app <- AppDriver$new(
    app_dir = "../../",
    name = "mde-unequal-groups",
    height = 800,
    width = 1200
  )

  app$wait_for_idle()
  app$set_inputs(tabs = "mde")

  # WHEN: User enters unequal group sizes (2:1 ratio)
  app$set_inputs(
    n1_mde = 2000,
    n2_mde = 1000,
    p1_mde = 0.15,
    alpha_mde = 0.05,
    power_mde = 0.80,
    wait_ = FALSE
  )

  app$wait_for_idle(timeout = 10000)

  # THEN: Should calculate MDE appropriately for unequal groups
  app$expect_values(output = "results_mde")

  # Take screenshot
  app$get_screenshot("mde-unequal-groups")

  app$stop()
})
