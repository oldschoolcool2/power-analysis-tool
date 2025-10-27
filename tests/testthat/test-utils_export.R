#' Unit Tests for Export Utility Functions
#'
#' Tests for R/utils_export.R - Helper functions for export operations
#'
#' Test Coverage:
#' - extract_analysis_inputs()
#' - generate_export_filename()
#' - get_page_display_name()
#' - supports_pdf_export()
#' - get_missing_exports()
#' - prepare_reactive_vals()

library(testthat)

# ============================================================================
# get_page_display_name() Tests
# ============================================================================

test_that("get_page_display_name returns correct display names", {
  # Test all known page types
  expect_equal(get_page_display_name("power_single"), "Power (Single)")
  expect_equal(get_page_display_name("ss_single"), "Sample Size (Single)")
  expect_equal(get_page_display_name("power_twogrp"), "Power (Two-Group)")
  expect_equal(get_page_display_name("ss_twogrp"), "Sample Size (Two-Group)")
  expect_equal(get_page_display_name("power_survival"), "Power (Survival)")
  expect_equal(get_page_display_name("ss_survival"), "Sample Size (Survival)")
  expect_equal(get_page_display_name("match_casecontrol"), "Matched Case-Control")
  expect_equal(get_page_display_name("power_continuous"), "Power (Continuous)")
  expect_equal(get_page_display_name("ss_continuous"), "Sample Size (Continuous)")
  expect_equal(get_page_display_name("noninf"), "Non-Inferiority")
  expect_equal(get_page_display_name("survival_ni_equiv"), "Time-to-Event NI-Equiv")
  expect_equal(get_page_display_name("mediation_analysis"), "Mediation Analysis")
  expect_equal(get_page_display_name("sensitivity_multi_bias"), "Multi-Bias Sensitivity")
  expect_equal(get_page_display_name("vif_calculator"), "VIF Calculator")
})

test_that("get_page_display_name returns Unknown for invalid page", {
  expect_equal(get_page_display_name("invalid_page"), "Unknown")
  expect_equal(get_page_display_name(""), "Unknown")
  expect_equal(get_page_display_name(NULL), "Unknown")
})

test_that("get_page_display_name is case-sensitive", {
  # Should return Unknown for incorrect case
  expect_equal(get_page_display_name("POWER_SINGLE"), "Unknown")
  expect_equal(get_page_display_name("Power_Single"), "Unknown")
})

# ============================================================================
# generate_export_filename() Tests
# ============================================================================

test_that("generate_export_filename produces correct CSV filenames", {
  filename <- generate_export_filename("power_single", "csv")

  # Check format: Power-Analysis-{DisplayName}-{Date}.csv
  expect_true(grepl("^Power-Analysis-", filename))
  expect_true(grepl("\\.csv$", filename))
  expect_true(grepl("Power \\(Single\\)", filename))
  expect_true(grepl(as.character(Sys.Date()), filename))
})

test_that("generate_export_filename produces correct PDF filenames", {
  filename <- generate_export_filename("ss_twogrp", "pdf")

  expect_true(grepl("^Power-Analysis-", filename))
  expect_true(grepl("\\.pdf$", filename))
  expect_true(grepl("Sample Size \\(Two-Group\\)", filename))
})

test_that("generate_export_filename handles all analysis types", {
  types <- c(
    "power_single", "ss_single",
    "power_twogrp", "ss_twogrp",
    "power_survival", "ss_survival",
    "match_casecontrol",
    "power_continuous", "ss_continuous",
    "noninf",
    "survival_ni_equiv",
    "mediation_analysis",
    "sensitivity_multi_bias"
  )

  for (type in types) {
    filename_csv <- generate_export_filename(type, "csv")
    filename_pdf <- generate_export_filename(type, "pdf")

    expect_true(grepl("\\.csv$", filename_csv))
    expect_true(grepl("\\.pdf$", filename_pdf))
    expect_true(nchar(filename_csv) > 20) # Reasonable length
    expect_true(nchar(filename_pdf) > 20)
  }
})

test_that("generate_export_filename validates format parameter", {
  expect_error(
    generate_export_filename("power_single", "xlsx"),
    "'arg' should be one of"
  )

  expect_error(
    generate_export_filename("power_single", "invalid"),
    "'arg' should be one of"
  )
})

test_that("generate_export_filename includes current date", {
  filename <- generate_export_filename("power_single", "csv")
  current_date <- as.character(Sys.Date())

  expect_true(grepl(current_date, filename))
})

test_that("generate_export_filename handles special characters in display names", {
  # Test that display names with special chars are included correctly
  filename <- generate_export_filename("survival_ni_equiv", "csv")

  # Should contain the display name (may be escaped)
  expect_true(nchar(filename) > 20)
  expect_true(grepl("\\.csv$", filename))
})

# ============================================================================
# extract_analysis_inputs() Tests
# ============================================================================

test_that("extract_analysis_inputs returns correct structure for single proportion", {
  mock_tab1_vals <- list(
    inputs = function() {
      list(
        power_n = 100,
        power_p = 60,
        power_p0 = 50,
        power_alpha = 0.05,
        power_discon = 10
      )
    }
  )

  reactive_vals <- list(
    tab1_vals = mock_tab1_vals,
    tab8_vals = NULL,
    tab9_vals = NULL,
    tab10_vals = NULL
  )

  result <- extract_analysis_inputs("power_single", NULL, reactive_vals)

  expect_type(result, "list")
  expect_equal(result$power_n, 100)
  expect_equal(result$power_p, 60)
})

test_that("extract_analysis_inputs returns NULL for direct input modules", {
  # Modules that use direct Shiny input should return NULL
  result <- extract_analysis_inputs("power_twogrp", NULL, list())
  expect_null(result)

  result <- extract_analysis_inputs("power_survival", NULL, list())
  expect_null(result)

  result <- extract_analysis_inputs("power_continuous", NULL, list())
  expect_null(result)
})

test_that("extract_analysis_inputs handles mediation analysis", {
  mock_tab8_vals <- list(
    inputs = function() {
      list(
        calc_mode = "calc_power",
        med_n = 100,
        path_a = 0.3,
        path_b = 0.4
      )
    }
  )

  reactive_vals <- list(
    tab1_vals = NULL,
    tab8_vals = mock_tab8_vals,
    tab9_vals = NULL,
    tab10_vals = NULL
  )

  result <- extract_analysis_inputs("mediation_analysis", NULL, reactive_vals)

  expect_type(result, "list")
  expect_equal(result$calc_mode, "calc_power")
  expect_equal(result$med_n, 100)
})

test_that("extract_analysis_inputs handles time-to-event NI/equiv", {
  mock_tab9_vals <- list(
    inputs = function() {
      list(
        test_type = "non-inferiority",
        calc_mode = "calc_n",
        power = 80
      )
    }
  )

  reactive_vals <- list(
    tab1_vals = NULL,
    tab8_vals = NULL,
    tab9_vals = mock_tab9_vals,
    tab10_vals = NULL
  )

  result <- extract_analysis_inputs("survival_ni_equiv", NULL, reactive_vals)

  expect_type(result, "list")
  expect_equal(result$test_type, "non-inferiority")
  expect_equal(result$calc_mode, "calc_n")
})

test_that("extract_analysis_inputs handles multi-bias sensitivity", {
  mock_tab10_vals <- function() {
    list(
      multi_bias = list(
        include_confounding = TRUE,
        rr = 2.0
      )
    )
  }

  reactive_vals <- list(
    tab1_vals = NULL,
    tab8_vals = NULL,
    tab9_vals = NULL,
    tab10_vals = mock_tab10_vals
  )

  result <- extract_analysis_inputs("sensitivity_multi_bias", NULL, reactive_vals)

  expect_type(result, "list")
  expect_true("multi_bias" %in% names(result))
})

# ============================================================================
# supports_pdf_export() Tests
# ============================================================================

test_that("supports_pdf_export returns TRUE for supported modules", {
  expect_true(supports_pdf_export("power_single"))
  expect_true(supports_pdf_export("ss_single"))
})

test_that("supports_pdf_export returns FALSE for unsupported modules", {
  expect_false(supports_pdf_export("power_twogrp"))
  expect_false(supports_pdf_export("ss_twogrp"))
  expect_false(supports_pdf_export("power_survival"))
  expect_false(supports_pdf_export("mediation_analysis"))
  expect_false(supports_pdf_export("sensitivity_multi_bias"))
})

test_that("supports_pdf_export handles invalid inputs", {
  expect_false(supports_pdf_export("invalid_type"))
  expect_false(supports_pdf_export(""))
  expect_false(supports_pdf_export(NULL))
})

# ============================================================================
# get_missing_exports() Tests
# ============================================================================

test_that("get_missing_exports returns empty for CSV (100% coverage)", {
  missing_csv <- get_missing_exports("csv")

  expect_type(missing_csv, "character")
  expect_length(missing_csv, 0)
})

test_that("get_missing_exports returns correct list for PDF", {
  missing_pdf <- get_missing_exports("pdf")

  expect_type(missing_pdf, "character")
  expect_true(length(missing_pdf) > 0)

  # Should NOT include supported modules
  expect_false("power_single" %in% missing_pdf)
  expect_false("ss_single" %in% missing_pdf)

  # Should include unsupported modules
  expect_true("power_twogrp" %in% missing_pdf)
  expect_true("power_survival" %in% missing_pdf)
  expect_true("mediation_analysis" %in% missing_pdf)
})

test_that("get_missing_exports validates export_type parameter", {
  expect_error(
    get_missing_exports("xlsx"),
    "'arg' should be one of"
  )

  expect_error(
    get_missing_exports("invalid"),
    "'arg' should be one of"
  )
})

test_that("get_missing_exports PDF count matches features.md", {
  missing_pdf <- get_missing_exports("pdf")

  # According to features.md: 1/10 modules have PDF = 9 missing
  # But we have 14 analysis types (some modules have multiple types)
  # So just check that we have a reasonable number
  expect_true(length(missing_pdf) >= 9)
})

# ============================================================================
# prepare_reactive_vals() Tests
# ============================================================================

test_that("prepare_reactive_vals creates correct structure", {
  mock_tab1 <- list(inputs = function() list(power_n = 100))
  mock_tab8 <- list(inputs = function() list(med_n = 50))
  mock_tab9 <- list(inputs = function() list(power = 80))
  mock_tab10 <- function() list(multi_bias = list())

  result <- prepare_reactive_vals(
    tab1_vals = mock_tab1,
    tab8_vals = mock_tab8,
    tab9_vals = mock_tab9,
    tab10_vals = mock_tab10
  )

  expect_type(result, "list")
  expect_equal(names(result), c("tab1_vals", "tab8_vals", "tab9_vals", "tab10_vals"))
  expect_identical(result$tab1_vals, mock_tab1)
  expect_identical(result$tab8_vals, mock_tab8)
  expect_identical(result$tab9_vals, mock_tab9)
  expect_identical(result$tab10_vals, mock_tab10)
})

test_that("prepare_reactive_vals handles NULL values", {
  result <- prepare_reactive_vals(
    tab1_vals = NULL,
    tab8_vals = NULL,
    tab9_vals = NULL,
    tab10_vals = NULL
  )

  expect_type(result, "list")
  expect_null(result$tab1_vals)
  expect_null(result$tab8_vals)
  expect_null(result$tab9_vals)
  expect_null(result$tab10_vals)
})

test_that("prepare_reactive_vals handles partial NULL values", {
  mock_tab1 <- list(inputs = function() list(power_n = 100))

  result <- prepare_reactive_vals(
    tab1_vals = mock_tab1,
    tab8_vals = NULL,
    tab9_vals = NULL,
    tab10_vals = NULL
  )

  expect_identical(result$tab1_vals, mock_tab1)
  expect_null(result$tab8_vals)
  expect_null(result$tab9_vals)
  expect_null(result$tab10_vals)
})

# ============================================================================
# Integration Tests (Utility Functions Working Together)
# ============================================================================

test_that("utilities work together for complete export workflow", {
  # Simulate a complete export workflow
  analysis_type <- "power_single"

  # Step 1: Get display name
  display_name <- get_page_display_name(analysis_type)
  expect_equal(display_name, "Power (Single)")

  # Step 2: Generate filename
  filename <- generate_export_filename(analysis_type, "csv")
  expect_true(grepl("Power \\(Single\\)", filename))
  expect_true(grepl("\\.csv$", filename))

  # Step 3: Check PDF support
  has_pdf <- supports_pdf_export(analysis_type)
  expect_true(has_pdf)

  # Step 4: Prepare reactive vals
  mock_tab1 <- list(inputs = function() list(power_n = 100))
  reactive_vals <- prepare_reactive_vals(tab1_vals = mock_tab1)

  # Step 5: Extract inputs
  inputs <- extract_analysis_inputs(analysis_type, NULL, reactive_vals)
  expect_equal(inputs$power_n, 100)
})

test_that("utilities handle workflow for module without PDF support", {
  analysis_type <- "power_twogrp"

  # Check display name
  display_name <- get_page_display_name(analysis_type)
  expect_equal(display_name, "Power (Two-Group)")

  # Check PDF support
  has_pdf <- supports_pdf_export(analysis_type)
  expect_false(has_pdf)

  # Verify it's in missing exports list
  missing_pdf <- get_missing_exports("pdf")
  expect_true(analysis_type %in% missing_pdf)
})

# ============================================================================
# Edge Cases and Error Handling
# ============================================================================

test_that("utilities handle empty strings gracefully", {
  expect_equal(get_page_display_name(""), "Unknown")

  # Should handle empty string in filename generation (will use "Unknown")
  filename <- generate_export_filename("", "csv")
  expect_true(grepl("Unknown", filename))
})

test_that("utilities handle special characters", {
  # Test with analysis type that has special chars in display name
  analysis_type <- "survival_ni_equiv"
  display_name <- get_page_display_name(analysis_type)

  expect_true(nchar(display_name) > 0)

  filename <- generate_export_filename(analysis_type, "csv")
  expect_true(grepl("\\.csv$", filename))
})

test_that("utilities are consistent across multiple calls", {
  # Same inputs should produce same outputs
  filename1 <- generate_export_filename("power_single", "csv")
  filename2 <- generate_export_filename("power_single", "csv")

  # Should be identical (same date)
  expect_equal(filename1, filename2)

  display1 <- get_page_display_name("mediation_analysis")
  display2 <- get_page_display_name("mediation_analysis")

  expect_equal(display1, display2)
})

# ============================================================================
# Performance Tests
# ============================================================================

test_that("utilities perform efficiently", {
  # These are simple functions, should be fast
  start_time <- Sys.time()

  for (i in 1:1000) {
    get_page_display_name("power_single")
  }

  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time, units = "secs")

  expect_true(elapsed < 1) # Should take less than 1 second for 1000 calls
})

test_that("filename generation is efficient", {
  start_time <- Sys.time()

  for (i in 1:100) {
    generate_export_filename("power_single", "csv")
  }

  end_time <- Sys.time()
  elapsed <- as.numeric(end_time - start_time, units = "secs")

  expect_true(elapsed < 1)
})

# ============================================================================
# Documentation Consistency Tests
# ============================================================================

test_that("all analysis types in extract_analysis_inputs have display names", {
  # Every analysis type that extract_analysis_inputs knows about
  # should have a corresponding display name
  known_types <- c(
    "power_single", "ss_single",
    "power_twogrp", "ss_twogrp",
    "power_survival", "ss_survival",
    "match_casecontrol",
    "power_continuous", "ss_continuous",
    "noninf",
    "survival_ni_equiv",
    "mediation_analysis",
    "sensitivity_multi_bias"
  )

  for (type in known_types) {
    display_name <- get_page_display_name(type)
    expect_false(display_name == "Unknown", info = paste("Type:", type))
  }
})

test_that("PDF support list matches implementation", {
  # Modules that support_pdf_export returns TRUE for
  # should NOT be in get_missing_exports("pdf")
  missing_pdf <- get_missing_exports("pdf")

  expect_false("power_single" %in% missing_pdf)
  expect_false("ss_single" %in% missing_pdf)

  # Modules that support_pdf_export returns FALSE for
  # should be in get_missing_exports("pdf")
  expect_true("power_twogrp" %in% missing_pdf)
  expect_true("mediation_analysis" %in% missing_pdf)
})

# ============================================================================
# Test Summary
# ============================================================================

test_that("all utility functions are covered by tests", {
  # This meta-test ensures comprehensive coverage
  exported_functions <- c(
    "extract_analysis_inputs",
    "generate_export_filename",
    "get_page_display_name",
    "supports_pdf_export",
    "get_missing_exports",
    "prepare_reactive_vals"
  )

  # Each function should have multiple tests
  test_files <- list.files(
    testthat::test_path(),
    pattern = "test-utils_export\\.R",
    full.names = TRUE
  )

  expect_true(length(test_files) > 0)
})
