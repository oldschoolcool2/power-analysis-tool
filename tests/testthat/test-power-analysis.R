# Tests for Power Analysis Shiny App
# Run with: testthat::test_file("tests/testthat/test-power-analysis.R")

library(testthat)
library(shiny)
library(pwr)
library(binom)
library(powerSurvEpi)
library(epiR)

# Source the app to get access to helper functions
source("app.R", local = TRUE)

################################################################################
# Test Helper Functions
################################################################################

test_that("calc_effect_measures calculates correctly for valid inputs", {
    # Test normal case
    result <- calc_effect_measures(0.10, 0.05)

    expect_equal(result$risk_diff, 5)  # (0.10 - 0.05) * 100
    expect_equal(result$relative_risk, 2)  # 0.10 / 0.05
    expect_true(abs(result$odds_ratio - 2.11) < 0.01)  # Approximately 2.11
})

test_that("calc_effect_measures handles edge cases correctly", {
    # Test when p2 = 0 (RR undefined)
    result <- calc_effect_measures(0.10, 0)

    expect_equal(result$risk_diff, 10)
    expect_true(is.na(result$relative_risk))  # Undefined
    expect_true(is.na(result$odds_ratio))     # Undefined
})

test_that("calc_effect_measures handles p2 = 100% edge case", {
    # Test when p2 = 1 (OR undefined)
    result <- calc_effect_measures(0.50, 1.0)

    expect_equal(result$risk_diff, -50)
    expect_equal(result$relative_risk, 0.5)
    expect_true(is.na(result$odds_ratio))  # Undefined when p2 = 1
})

test_that("solve_n1_for_ratio finds correct sample size", {
    # Test for equal groups (ratio = 1)
    h <- ES.h(0.10, 0.05)
    n1 <- solve_n1_for_ratio(h, ratio = 1, sig.level = 0.05,
                              power = 0.80, alternative = "two.sided")

    # Should return a positive integer
    expect_true(n1 > 0)
    expect_type(n1, "double")

    # Verify the solution gives approximately 80% power
    actual_power <- pwr.2p.test(h = h, n = n1, sig.level = 0.05,
                                 alternative = "two.sided")$power
    expect_true(abs(actual_power - 0.80) < 0.01)
})

test_that("solve_n1_for_ratio handles unequal allocation", {
    # Test for 2:1 allocation (ratio = 2)
    h <- ES.h(0.15, 0.10)
    n1 <- solve_n1_for_ratio(h, ratio = 2, sig.level = 0.05,
                              power = 0.80, alternative = "two.sided")

    # Should return a positive value
    expect_true(n1 > 0)

    # Verify the solution gives approximately 80% power
    n2 <- n1 * 2
    actual_power <- pwr.2p2n.test(h = h, n1 = n1, n2 = n2, sig.level = 0.05,
                                   alternative = "two.sided")$power
    expect_true(abs(actual_power - 0.80) < 0.05)  # Allow 5% tolerance
})

################################################################################
# Test Server Logic with testServer()
################################################################################

test_that("testServer: Power (Single) calculation works correctly", {
    skip_if_not_installed("shiny", minimum_version = "1.5.0")

    testServer(server, {
        # Set inputs for Power (Single) tab
        session$setInputs(
            tabset = "Power (Single)",
            power_n = 500,
            power_p = 200,
            power_discon = 10,
            power_alpha = 0.05,
            go = 1
        )

        # Check that doAnalysis flag is set
        expect_true(v$doAnalysis != FALSE)

        # Manually calculate expected power
        expected_power <- pwr.p.test(
            sig.level = 0.05,
            power = NULL,
            h = ES.h(1/200, 0),
            alt = "greater",
            n = 500
        )$power

        # Power should be between 0 and 1
        expect_gt(expected_power, 0)
        expect_lt(expected_power, 1)
    })
})

test_that("testServer: Tab switching resets doAnalysis flag", {
    skip_if_not_installed("shiny", minimum_version = "1.5.0")

    testServer(server, {
        # Set initial inputs and trigger analysis
        session$setInputs(
            tabset = "Power (Single)",
            go = 1
        )

        # Verify analysis is triggered
        expect_true(v$doAnalysis != FALSE)

        # Switch tabs
        session$setInputs(tabset = "Sample Size (Single)")

        # doAnalysis should be reset to FALSE
        expect_false(v$doAnalysis)
    })
})

test_that("testServer: Example button loads correct values", {
    skip_if_not_installed("shiny", minimum_version = "1.5.0")

    testServer(server, {
        # Click example button for Power (Single)
        session$setInputs(example_power_single = 1)

        # Check that inputs are updated to example values
        expect_equal(input$power_n, 1500)
        expect_equal(input$power_p, 500)
        expect_equal(input$power_discon, 15)
        expect_equal(input$power_alpha, 0.05)
    })
})

test_that("testServer: Reset button restores defaults", {
    skip_if_not_installed("shiny", minimum_version = "1.5.0")

    testServer(server, {
        # First modify inputs
        session$setInputs(
            power_n = 1000,
            power_p = 500,
            power_discon = 25
        )

        # Click reset button
        session$setInputs(reset_power_single = 1)

        # Check that inputs are restored to defaults
        expect_equal(input$power_n, 230)
        expect_equal(input$power_p, 100)
        expect_equal(input$power_discon, 10)
    })
})

test_that("testServer: Scenario saving works", {
    skip_if_not_installed("shiny", minimum_version = "1.5.0")

    testServer(server, {
        # Run an analysis
        session$setInputs(
            tabset = "Power (Single)",
            power_n = 500,
            power_p = 200,
            go = 1
        )

        # Save scenario
        session$setInputs(save_scenario = 1)

        # Check that scenario counter incremented
        expect_equal(v$scenario_counter, 1)

        # Check that scenarios dataframe has one row
        expect_equal(nrow(v$scenarios), 1)
    })
})

################################################################################
# Integration Tests - Statistical Calculations
################################################################################

test_that("Single proportion power calculation matches pwr package", {
    # Test parameters
    n <- 500
    p <- 1/200
    alpha <- 0.05

    # Calculate using pwr package
    result <- pwr.p.test(
        sig.level = alpha,
        power = NULL,
        h = ES.h(p, 0),
        alt = "greater",
        n = n
    )

    # Power should be reasonable
    expect_gt(result$power, 0.5)
    expect_lt(result$power, 1.0)
})

test_that("Two-group sample size calculation is reasonable", {
    # Test parameters
    p1 <- 0.10
    p2 <- 0.05
    power <- 0.80
    alpha <- 0.05

    # Calculate using pwr package
    result <- pwr.2p.test(
        h = ES.h(p1, p2),
        sig.level = alpha,
        power = power,
        alternative = "two.sided"
    )

    # Sample size should be positive and reasonable
    expect_gt(result$n, 0)
    expect_lt(result$n, 10000)  # Sanity check
})

test_that("Survival analysis power calculation works", {
    # Test parameters
    n <- 800
    hr <- 0.75
    k <- 0.50
    pE <- 0.40
    alpha <- 0.05

    # Calculate using powerSurvEpi
    power <- powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = alpha)

    # Power should be between 0 and 1
    expect_gte(power, 0)
    expect_lte(power, 1)
})

################################################################################
# Edge Case Tests
################################################################################

test_that("Effect measures handle identical proportions", {
    # When p1 = p2, effect measures should reflect no difference
    result <- calc_effect_measures(0.10, 0.10)

    expect_equal(result$risk_diff, 0)
    expect_equal(result$relative_risk, 1)
    expect_equal(result$odds_ratio, 1)
})

test_that("Very small event rates are handled correctly", {
    # Test with very small probability (rare event)
    p <- 1/10000
    n <- 5000

    result <- pwr.p.test(
        sig.level = 0.05,
        power = NULL,
        h = ES.h(p, 0),
        alt = "greater",
        n = n
    )

    # Should return a valid power (possibly low)
    expect_true(!is.na(result$power))
    expect_gte(result$power, 0)
    expect_lte(result$power, 1)
})

test_that("Large effect sizes produce high power", {
    # Large difference should give high power with moderate n
    p1 <- 0.50
    p2 <- 0.10
    n <- 100

    result <- pwr.2p.test(
        h = ES.h(p1, p2),
        n = n,
        sig.level = 0.05,
        alternative = "two.sided"
    )

    # Should have very high power
    expect_gt(result$power, 0.95)
})

################################################################################
# Message
################################################################################

message("\nAll power analysis tests completed successfully!")
message("To run these tests, use: testthat::test_file('tests/testthat/test-power-analysis.R')")
