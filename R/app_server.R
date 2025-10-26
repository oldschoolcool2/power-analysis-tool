#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}. DO NOT REMOVE.
#' @noRd
#'
#' @importFrom shiny moduleServer observeEvent reactive renderPlot renderPrint
#' @importFrom shiny observe reactiveValues outputOptions showNotification debounce
#' @importFrom shiny strong br em HTML h1 h4 h5 h6 p downloadButton downloadHandler
#' @importFrom shiny tableOutput renderTable bindCache renderDataTable
#' @importFrom shinyjs useShinyjs
#' @importFrom stats uniroot qnorm
#' @importFrom pwr pwr.p.test ES.h pwr.t2n.test pwr.t.test
#' @importFrom powerSurvEpi powerEpi ssizeEpi
#' @importFrom epiR epi.sscc
#' @importFrom plotly plot_ly add_trace layout config renderPlotly
#' @importFrom binom binom.confint
#' @importFrom utils write.csv
#' @importFrom magrittr %>%
#' @importFrom rmarkdown render
#' @importFrom shinyBS bsTooltip
app_server <- function(input, output, session) {
  
  # Your application server logic
  

  # ============================================================
  # Module Initialization
  # ============================================================

  # Tab 1: Single Proportion (includes missing data module)
  tab1_vals <- mod_01_single_proportion_server("tab1")

  # Tab 2: Two-Group Comparisons (includes missing data module)
  tab2_vals <- mod_02_two_group_server("tab2")

  # Tab 3: Survival Analysis (includes missing data module)
  tab3_vals <- mod_03_survival_server("tab3")

  # Tab 4: Matched Case-Control (includes missing data module)
  tab4_vals <- mod_04_matched_case_control_server("tab4")

  # Tab 5: Continuous Outcomes (includes missing data module)
  tab5_vals <- mod_05_continuous_server("tab5")

  # Tab 6: Non-Inferiority (includes missing data module)
  tab6_vals <- mod_06_non_inferiority_server("tab6")

  # Tab 7: VIF/Propensity Score
  tab7_vals <- mod_07_vif_ps_server("tab7")

  # Tab 8: Mediation Analysis
  tab8_vals <- mod_08_mediation_server("tab8")

  # Tab 9: Time-to-Event Equivalence/NI
  tab9_vals <- mod_09_survival_equivalence_server("tab9")

  # Tab 10: Sensitivity Analyses
  tab10_vals <- mod_10_sensitivity_analyses_server("tab10")

  # Missing data modules for tabs not yet fully migrated
  # missing_data_surv_ss <- missing_data_server("surv_ss-missing_data")  # Now in tab3 module
  # missing_data_match <- missing_data_server("match-missing_data")  # Now in tab4 module
  # missing_data_cont_ss <- missing_data_server("cont_ss-missing_data")  # Now in tab5 module
  # missing_data_noninf <- missing_data_server("noninf-missing_data")  # Now in tab6 module

  # ============================================================
  # Sidebar Navigation Initialization
  # ============================================================

  # Initialize sidebar page to default (power_single)
  observe({
    if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
      session$sendCustomMessage("set_active_page", "power_single")
    }
  })

  # ============================================================
  # Helper Functions
  # ============================================================

  # Get current sidebar page with default fallback
  get_current_page <- function() {
    if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0 || identical(input$sidebar_page, "")) {
      "power_single"
    } else {
      input$sidebar_page
    }
  }
  
  # Convert sidebar_page value to display name (for filenames, titles, etc.)
  get_page_display_name <- function(page) {
    switch(page,
      "power_single" = "Power (Single)",
      "ss_single" = "Sample Size (Single)",
      "power_twogrp" = "Power (Two-Group)",
      "ss_twogrp" = "Sample Size (Two-Group)",
      "power_survival" = "Power (Survival)",
      "ss_survival" = "Sample Size (Survival)",
      "match_casecontrol" = "Matched Case-Control",
      "power_continuous" = "Power (Continuous)",
      "ss_continuous" = "Sample Size (Continuous)",
      "noninf" = "Non-Inferiority",
      "survival_ni_equiv" = "Time-to-Event Equivalence/Non-Inferiority",
      "vif_calculator" = "Propensity Score VIF Calculator",
      "mediation_analysis" = "Mediation Analysis",
      "sensitivity_evalue" = "E-value Sensitivity Analysis",
      "documentation" = "Documentation",
      "Unknown"
    )
  }

  # ============================================================
  # Quick Preview Footer Updates
  # ============================================================

  observe({
    # Get current page
    page <- input$sidebar_page

    # Build preview text based on active page and inputs
    preview_text <- if (is.null(page) || page == "") {
      "Select an analysis type from the sidebar"
    } else if (page == "power_single") {
      paste0("Preview: Testing n=", input$power_n,
             " participants for event rate 1 in ", input$power_p)
    } else if (page == "ss_single") {
      paste0("Preview: Single proportion sample size for event rate 1 in ",
             input$ss_p, " with ",
             input$ss_power, "% power")
    } else if (page == "power_two") {
      paste0("Preview: Comparing p1=", input$twogrp_pow_p1,
             "% vs p2=", input$twogrp_pow_p2, "% with n1=",
             input$twogrp_pow_n1, " and n2=", input$twogrp_pow_n2)
    } else if (page == "ss_two") {
      paste0("Preview: Sample size needed for p1=", input$twogrp_ss_p1,
             "% vs p2=", input$twogrp_ss_p2, "% with ",
             input$twogrp_ss_power, "% power")
    } else if (page == "power_surv") {
      paste0("Preview: Survival analysis with HR=", input$surv_power_hr,
             ", ", input$surv_power_n, " total participants")
    } else if (page == "ss_surv") {
      paste0("Preview: Sample size for HR=", input$surv_ss_hr,
             " with ", input$surv_ss_power, "% power")
    } else if (page == "matched") {
      paste0("Preview: Matched case-control with ",
             input$match_n_pairs, " pairs, OR=", input$match_or)
    } else if (page == "ss_cont") {
      paste0("Preview: Continuous outcome sample size, effect size d=",
             input$cont_ss_d, ", ", input$cont_ss_power, "% power")
    } else if (page == "noninf") {
      paste0("Preview: Non-inferiority margin=", input$noninf_margin,
             "%, baseline rate=", input$noninf_p1, "%")
    } else if (page == "vif_calculator") {
      paste0("Preview: VIF for ", input$vif_method, " weights, c-stat=",
             input$vif_cstat, ", prevalence=", input$vif_prevalence, "%")
    } else if (page == "mediation_analysis") {
      paste0("Preview: Mediation with a=", input$`tab8-path_a`,
             ", b=", input$`tab8-path_b`,
             " (indirect effect=", round(input$`tab8-path_a` * input$`tab8-path_b`, 3), ")")
    } else if (page == "documentation") {
      "Browse comprehensive guides and documentation"
    } else {
      "Enter parameters above"
    }

    # Update footer text using shinyjs
    shinyjs::html("preview-text", preview_text)
  })

  # Note: calc_effect_measures now sourced from fct_effect_size.R

  # Helper function: solve for n1 given allocation ratio (for unequal groups)
  solve_n1_for_ratio <- function(h, ratio, sig.level, power, alternative) {
    f <- function(n1) {
      n2 <- n1 * ratio
      pwr.2p2n.test(
        h = h, n1 = n1, n2 = n2, sig.level = sig.level,
        alternative = alternative
      )$power - power
    }
    tryCatch(
      {
        uniroot(f, c(2, 1e6), extendInt = "yes")$root
      },
      error = function(e) {
        # Fallback to equal-n approximation if root-finding fails
        warning("Root-finding failed; using equal-n approximation")
        pwr.2p.test(h = h, sig.level = sig.level, power = power, alternative = alternative)$n
      }
    )
  }

  # Note: calc_missing_data_inflation now sourced from fct_missing_data.R

  # Note: estimate_vif_propensity_score and interpret_vif now sourced from fct_propensity_score.R

  # Configuration for example and reset buttons (DRY refactoring)
  button_configs <- list(
    power_single = list(
      example = list(power_n = 1500, power_p = 500, power_discon = 15, power_alpha = 0.05),
      reset = list(power_n = 230, power_p = 100, power_discon = 10, power_alpha = 0.05),
      example_msg = "Rare adverse event study with 1,500 participants"
    ),
    ss_single = list(
      example = list(ss_power = 90, ss_p = 200, ss_discon = 10, ss_alpha = 0.05),
      reset = list(ss_power = 80, ss_p = 100, ss_discon = 10, ss_alpha = 0.05),
      example_msg = "Sample size for rare event (1 in 200)"
    ),
    twogrp_pow = list(
      example = list(twogrp_pow_n1 = 500, twogrp_pow_n2 = 500, twogrp_pow_p1 = 15, twogrp_pow_p2 = 10, twogrp_pow_alpha = 0.05),
      reset = list(twogrp_pow_n1 = 200, twogrp_pow_n2 = 200, twogrp_pow_p1 = 10, twogrp_pow_p2 = 5, twogrp_pow_alpha = 0.05, twogrp_pow_sided = "two.sided"),
      example_msg = "Cohort study comparing 15% vs 10% event rates"
    ),
    twogrp_ss = list(
      example = list(twogrp_ss_power = 80, twogrp_ss_p1 = 20, twogrp_ss_p2 = 15, twogrp_ss_ratio = 1, twogrp_ss_alpha = 0.05),
      reset = list(twogrp_ss_power = 80, twogrp_ss_p1 = 10, twogrp_ss_p2 = 5, twogrp_ss_ratio = 1, twogrp_ss_alpha = 0.05, twogrp_ss_sided = "two.sided"),
      example_msg = "Sample size for 20% vs 15% comparison"
    ),
    surv_pow = list(
      example = list(surv_pow_n = 800, surv_pow_hr = 0.75, surv_pow_k = 50, surv_pow_pE = 40, surv_pow_alpha = 0.05),
      reset = list(surv_pow_n = 500, surv_pow_hr = 0.7, surv_pow_k = 50, surv_pow_pE = 30, surv_pow_alpha = 0.05),
      example_msg = "Survival study with HR=0.75 and 40% event rate"
    ),
    surv_ss = list(
      example = list(surv_ss_power = 85, surv_ss_hr = 0.70, surv_ss_k = 50, surv_ss_pE = 35, surv_ss_alpha = 0.05),
      reset = list(surv_ss_power = 80, surv_ss_hr = 0.7, surv_ss_k = 50, surv_ss_pE = 30, surv_ss_alpha = 0.05),
      example_msg = "Sample size for survival analysis (HR=0.70)"
    ),
    match = list(
      example = list(match_power = 80, match_or = 2.5, match_p0 = 25, match_ratio = 2, match_alpha = 0.05),
      reset = list(match_power = 80, match_or = 2.0, match_p0 = 20, match_ratio = 1, match_alpha = 0.05, match_sided = "two.sided"),
      example_msg = "2:1 matched case-control with OR=2.5"
    ),
    cont_pow = list(
      example = list(cont_pow_n1 = 150, cont_pow_n2 = 150, cont_pow_d = 0.5, cont_pow_alpha = 0.05, cont_pow_sided = "two.sided"),
      reset = list(cont_pow_n1 = 100, cont_pow_n2 = 100, cont_pow_d = 0.5, cont_pow_alpha = 0.05, cont_pow_sided = "two.sided"),
      example_msg = "Continuous outcome comparison (Cohen's d=0.5, n=150 per group)"
    ),
    cont_ss = list(
      example = list(cont_ss_power = 90, cont_ss_d = 0.4, cont_ss_ratio = 1, cont_ss_alpha = 0.05, cont_ss_sided = "two.sided"),
      reset = list(cont_ss_power = 80, cont_ss_d = 0.5, cont_ss_ratio = 1, cont_ss_alpha = 0.05, cont_ss_sided = "two.sided"),
      example_msg = "Sample size for moderate effect (d=0.4, 90% power)"
    ),
    noninf = list(
      example = list(noninf_power = 85, noninf_p1 = 12, noninf_p2 = 10, noninf_margin = 4, noninf_ratio = 1, noninf_alpha = 0.025),
      reset = list(noninf_power = 80, noninf_p1 = 10, noninf_p2 = 10, noninf_margin = 5, noninf_ratio = 1, noninf_alpha = 0.025),
      example_msg = "Non-inferiority test with 4% margin (generic vs. branded)"
    ),
    vif = list(
      example = list(
        ps_calc_method = "li_2025",
        vif_n_rct = 800,
        vif_prevalence = 30,
        vif_cstat = 0.75,
        vif_overlap_phi = 0.60,
        vif_rho_squared = 0.15,
        vif_method = "ATE"
      ),
      reset = list(
        ps_calc_method = "austin",
        vif_n_rct = 500,
        vif_prevalence = 50,
        vif_cstat = 0.70,
        vif_overlap_phi = 0.75,
        vif_rho_squared = 0.10,
        vif_method = "ATE"
      ),
      example_msg = "Li et al. (2025) method with moderate overlap and strong confounding"
    )
  )

  # Reactive values for tracking state
  v <- reactiveValues(
    doAnalysis = FALSE,
    scenarios = data.frame(),
    scenario_counter = 0
  )

  # Show results flag
  output$show_results <- reactive({
    v$doAnalysis
  })
  outputOptions(output, "show_results", suspendWhenHidden = FALSE)

  # Has scenarios flag
  output$has_scenarios <- reactive({
    nrow(v$scenarios) > 0
  })
  outputOptions(output, "has_scenarios", suspendWhenHidden = FALSE)

  # Trigger analysis
  observeEvent(input$go, {
    cat("\n=== CALCULATE BUTTON CLICKED ===\n")
    cat("Current page:", input$sidebar_page, "\n")
    cat("Button click count:", input$go, "\n")
    v$doAnalysis <- input$go
    cat("doAnalysis set to:", v$doAnalysis, "\n")
  })

  # Data-driven button handlers (DRY refactoring - replaces 183 lines of repetitive code)
  # Generate example and reset handlers dynamically from configuration
  lapply(names(button_configs), function(tab_key) {
    config <- button_configs[[tab_key]]

    # Example button handler
    observeEvent(input[[paste0("example_", tab_key)]], {
      for (param in names(config$example)) {
        value <- config$example[[param]]
        # Determine input type and update accordingly
        if (grepl("_sided$|_method$|ps_calc_method", param)) {
          updateRadioButtons(session, param, selected = value)
        } else if (grepl("power|alpha|discon|k|pE|p0|prevalence|cstat|overlap_phi|rho_squared", param)) {
          updateSliderInput(session, param, value = value)
        } else {
          updateNumericInput(session, param, value = value)
        }
      }
      showNotification(paste("Example loaded:", config$example_msg),
        type = "message", duration = 3
      )
    })

    # Reset button handler
    observeEvent(input[[paste0("reset_", tab_key)]], {
      for (param in names(config$reset)) {
        value <- config$reset[[param]]
        # Determine input type and update accordingly
        if (grepl("_sided$|_method$|ps_calc_method", param)) {
          updateRadioButtons(session, param, selected = value)
        } else if (grepl("power|alpha|discon|k|pE|p0|prevalence|cstat|overlap_phi|rho_squared", param)) {
          updateSliderInput(session, param, value = value)
        } else {
          updateNumericInput(session, param, value = value)
        }
      }
      showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })
  })

  # Validation function
  validate_inputs <- function() {
    # Get current page with default fallback
    page <- get_current_page()

    # Tab 1: Single Proportion (using sidebar_page)
    if (page == "power_single") {
      tab1_inputs <- tab1_vals$inputs()
      validate(
        need(tab1_inputs$power_n > 0, "Sample size must be positive"),
        need(tab1_inputs$power_p > 0, "Event frequency must be positive"),
        need(tab1_inputs$power_discon >= 0 && tab1_inputs$power_discon <= 100, "Discontinuation rate must be between 0 and 100%")
      )
    } else if (page == "ss_single") {
      tab1_inputs <- tab1_vals$inputs()
      validate(
        need(tab1_inputs$ss_p > 0, "Event frequency must be positive"),
        need(tab1_inputs$ss_discon >= 0 && tab1_inputs$ss_discon <= 100, "Discontinuation rate must be between 0 and 100%")
      )
    # Tab 2: Two-Group Comparison (using sidebar_page)
    } else if (page == "power_twogrp") {
      tab2_inputs <- tab2_vals$inputs()
      validate(
        need(tab2_inputs$twogrp_pow_n1 > 0, "Sample size Group 1 must be positive"),
        need(tab2_inputs$twogrp_pow_n2 > 0, "Sample size Group 2 must be positive"),
        need(tab2_inputs$twogrp_pow_p1 >= 0 && tab2_inputs$twogrp_pow_p1 <= 100, "Event rate Group 1 must be between 0 and 100%"),
        need(tab2_inputs$twogrp_pow_p2 >= 0 && tab2_inputs$twogrp_pow_p2 <= 100, "Event rate Group 2 must be between 0 and 100%"),
        need(tab2_inputs$twogrp_pow_p1 != tab2_inputs$twogrp_pow_p2, "Event rates must be different to calculate power")
      )
    } else if (page == "ss_twogrp") {
      tab2_inputs <- tab2_vals$inputs()
      validate(
        need(tab2_inputs$twogrp_ss_p1 >= 0 && tab2_inputs$twogrp_ss_p1 <= 100, "Event rate Group 1 must be between 0 and 100%"),
        need(tab2_inputs$twogrp_ss_p2 >= 0 && tab2_inputs$twogrp_ss_p2 <= 100, "Event rate Group 2 must be between 0 and 100%"),
        need(tab2_inputs$twogrp_ss_p1 != tab2_inputs$twogrp_ss_p2, "Event rates must be different to calculate sample size"),
        need(tab2_inputs$twogrp_ss_ratio > 0, "Allocation ratio must be positive")
      )
    # Tab 3: Survival Analysis
    } else if (page == "power_survival") {
      tab3_inputs <- tab3_vals$inputs()
      validate(
        need(tab3_inputs$surv_pow_n > 0, "Sample size must be positive"),
        need(tab3_inputs$surv_pow_hr > 0, "Hazard ratio must be positive"),
        need(tab3_inputs$surv_pow_k >= 0 && tab3_inputs$surv_pow_k <= 100, "Proportion exposed must be between 0 and 100%"),
        need(tab3_inputs$surv_pow_pE >= 0 && tab3_inputs$surv_pow_pE <= 100, "Event rate must be between 0 and 100%"),
        need(tab3_inputs$surv_pow_hr != 1, "Hazard ratio must be different from 1 to calculate power")
      )
    } else if (page == "ss_survival") {
      tab3_inputs <- tab3_vals$inputs()
      validate(
        need(tab3_inputs$surv_ss_hr > 0, "Hazard ratio must be positive"),
        need(tab3_inputs$surv_ss_k >= 0 && tab3_inputs$surv_ss_k <= 100, "Proportion exposed must be between 0 and 100%"),
        need(tab3_inputs$surv_ss_pE >= 0 && tab3_inputs$surv_ss_pE <= 100, "Event rate must be between 0 and 100%"),
        need(tab3_inputs$surv_ss_hr != 1, "Hazard ratio must be different from 1 to calculate sample size")
      )
    # Tab 4: Matched Case-Control
    } else if (page == "match_casecontrol") {
      tab4_inputs <- tab4_vals$inputs()
      validate(
        need(tab4_inputs$match_or > 0, "Odds ratio must be positive"),
        need(tab4_inputs$match_p0 >= 0 && tab4_inputs$match_p0 <= 100, "Exposure probability must be between 0 and 100%"),
        need(tab4_inputs$match_ratio >= 1, "Controls per case must be at least 1"),
        need(tab4_inputs$match_or != 1, "Odds ratio must be different from 1 to calculate sample size")
      )
    # Tab 5: Continuous Outcomes
    } else if (page == "power_continuous") {
      tab5_inputs <- tab5_vals$inputs()
      validate(
        need(tab5_inputs$cont_pow_n1 > 1, "Sample size Group 1 must be at least 2"),
        need(tab5_inputs$cont_pow_n2 > 1, "Sample size Group 2 must be at least 2"),
        need(tab5_inputs$cont_pow_d > 0, "Effect size (Cohen's d) must be positive"),
        need(tab5_inputs$cont_pow_d != 0, "Effect size cannot be zero")
      )
    } else if (page == "ss_continuous") {
      tab5_inputs <- tab5_vals$inputs()
      validate(
        need(tab5_inputs$cont_ss_d > 0, "Effect size (Cohen's d) must be positive"),
        need(tab5_inputs$cont_ss_d != 0, "Effect size cannot be zero"),
        need(tab5_inputs$cont_ss_ratio > 0, "Allocation ratio must be positive")
      )
    # Tab 6: Non-Inferiority
    } else if (page == "noninf") {
      tab6_inputs <- tab6_vals$inputs()
      validate(
        need(tab6_inputs$noninf_p1 >= 0 && tab6_inputs$noninf_p1 <= 100, "Event rate Test Group must be between 0 and 100%"),
        need(tab6_inputs$noninf_p2 >= 0 && tab6_inputs$noninf_p2 <= 100, "Event rate Reference Group must be between 0 and 100%"),
        need(tab6_inputs$noninf_margin > 0, "Non-inferiority margin must be positive"),
        need(tab6_inputs$noninf_margin < 100, "Non-inferiority margin must be less than 100%"),
        need(tab6_inputs$noninf_ratio > 0, "Allocation ratio must be positive")
      )

    # Tab 9: Time-to-Event Equivalence/Non-Inferiority
    } else if (page == "survival_ni_equiv") {
      tab9_inputs <- tab9_vals$inputs()
      validate(
        need(tab9_inputs$hr_expected > 0, "Expected HR must be positive"),
        need(tab9_inputs$prop_exposed > 0 && tab9_inputs$prop_exposed <= 100, "Proportion exposed must be 0-100%"),
        need(tab9_inputs$event_rate > 0 && tab9_inputs$event_rate <= 100, "Event rate must be 0-100%"),
        need(tab9_inputs$allocation_ratio > 0, "Allocation ratio must be positive")
      )

      if (tab9_inputs$calc_mode == "calc_n") {
        if (tab9_inputs$test_type == "non-inferiority") {
          validate(
            need(!is.null(tab9_inputs$hr_margin_ni) && tab9_inputs$hr_margin_ni > 1.0,
                 "NI margin must be > 1.0 (e.g., 1.25 for 25% increase)"),
            need(tab9_inputs$hr_expected < tab9_inputs$hr_margin_ni,
                 "Expected HR must be better than margin to demonstrate NI")
          )
        } else {
          validate(
            need(!is.null(tab9_inputs$hr_margin_equiv) && tab9_inputs$hr_margin_equiv > 1.0,
                 "Equivalence margin must be > 1.0"),
            need(abs(log(tab9_inputs$hr_expected)) < abs(log(tab9_inputs$hr_margin_equiv)),
                 "Expected HR must be within equivalence bounds")
          )
        }
      } else {
        validate(
          need(tab9_inputs$n_fixed >= 50, "Sample size must be at least 50")
        )
      }
    }
  }

  ################################################################################################## LIVE PREVIEW (DEBOUNCED)

  # Create debounced preview reactive for quick feedback
  preview_inputs <- reactive({
    # Guard against NULL or uninitialized sidebar_page
    if (is.null(page) || length(page) == 0) {
      return(NULL)
    }

    # Tab 1: Single Proportion (using sidebar_page and module values)
    if (page == "power_single") {
      tab1_inputs <- tab1_vals$inputs()
      list(
        tab = "Power (Single)",
        n = tab1_inputs$power_n,
        p = tab1_inputs$power_p,
        alpha = tab1_inputs$power_alpha,
        rate = 1 / tab1_inputs$power_p
      )
    } else if (page == "ss_single") {
      tab1_inputs <- tab1_vals$inputs()
      list(
        tab = "Sample Size (Single)",
        power = tab1_inputs$ss_power,
        p = tab1_inputs$ss_p,
        alpha = tab1_inputs$ss_alpha,
        rate = 1 / tab1_inputs$ss_p
      )
    } else {
      list(tab = "Unknown")
    }
  }) %>% debounce(1000) # Wait 1 second after last input change

  output$live_preview <- renderUI({
    # Only show preview before Calculate is pressed
    if (v$doAnalysis) {
      return()
    }

    prev <- preview_inputs()

    # Guard against NULL preview
    if (is.null(prev)) {
      return(NULL)
    }

    # Create a lightweight preview message
    preview_text <- if (prev$tab == "Power (Single)") {
      paste0(
        "Preview: Testing n=", prev$n, " participants for event rate 1 in ", prev$p,
        " (", round(prev$rate * 100, 2), "%) at α=", prev$alpha
      )
    } else if (prev$tab == "Sample Size (Single)") {
      paste0(
        "Preview: Calculating sample size for ", prev$power, "% power, ",
        "event rate 1 in ", prev$p, " (", round(prev$rate * 100, 2), "%) at α=", prev$alpha
      )
    } else if (prev$tab == "Power (Two-Group)") {
      paste0(
        "Preview: Comparing n1=", prev$n1, " vs n2=", prev$n2,
        " with rates ", prev$p1, "% vs ", prev$p2, "%"
      )
    } else {
      "Fill in parameters and click Calculate"
    }

    div(
      style = "background-color: #f0f8ff; border-left: 4px solid #3498db; padding: 10px; margin-bottom: 10px;",
      icon("info-circle"),
      strong(" Quick Preview: "),
      preview_text,
      br(),
      em("(Click Calculate to run full analysis)")
    )
  })

  ################################################################################################## RESULT TEXT

  output$result_text <- renderUI({
    cat("\n=== result_text RENDER TRIGGERED ===\n")
    cat("doAnalysis:", v$doAnalysis, "\n")

    if (!v$doAnalysis) {
      cat("Exiting: doAnalysis is FALSE\n")
      return()
    }

    isolate({
      # Get current page with default fallback
      page <- get_current_page()
      cat("Current page in result_text:", page, "\n")

      validate_inputs()

      # Tab 1: Single Proportion - Power Analysis (using sidebar_page)
      if (page == "power_single") {
        tab1_inputs <- tab1_vals$inputs()
        incidence_rate <- tab1_inputs$power_p
        sample_size <- tab1_inputs$power_n
        discon <- tab1_inputs$power_discon / 100

        # Get multiple testing adjustment
        mt_vals <- tab1_vals$multiple_testing_vals()
        alpha_to_use <- if (mt_vals$adjust_alpha) {
          mt_adj <- calc_adjusted_alpha(
            tab1_inputs$power_alpha,
            mt_vals$n_tests,
            mt_vals$correction_method
          )
          mt_adj$alpha_adjusted
        } else {
          tab1_inputs$power_alpha
        }

        # Get clustering adjustment - use effective sample size
        clust_vals <- tab1_vals$clustering_vals()
        n_to_use <- if (clust_vals$adjust_clustering) {
          de <- calc_design_effect(clust_vals$cluster_size, clust_vals$icc)
          calc_effective_n(sample_size, de)
        } else {
          sample_size
        }

        # Calculate power with adjustments
        power <- pwr.p.test(
          sig.level = alpha_to_use, power = NULL,
          h = ES.h(1 / tab1_inputs$power_p, 0), alt = "greater", n = n_to_use
        )$power

        # Build adjustment notes
        adjustment_notes <- ""
        if (mt_vals$adjust_alpha || clust_vals$adjust_clustering) {
          adjustment_notes <- "<div style='background-color: #e7f3ff; border-left: 4px solid #0066cc; padding: 15px; margin: 15px 0;'><h5 style='margin-top: 0;'>Adjustments Applied</h5>"

          if (mt_vals$adjust_alpha) {
            adjustment_notes <- paste0(adjustment_notes,
              "<p><strong>Multiple Testing:</strong> Using ", mt_vals$correction_method,
              " correction for ", mt_vals$n_tests, " tests. Adjusted α = ",
              format(alpha_to_use, digits = 4), " (original α = ", tab1_inputs$power_alpha, ").</p>")
          }

          if (clust_vals$adjust_clustering) {
            adjustment_notes <- paste0(adjustment_notes,
              "<p><strong>Clustering:</strong> With ", sample_size, " total participants, ICC = ",
              clust_vals$icc, ", cluster size = ", clust_vals$cluster_size,
              ", design effect = ", format(de, digits = 2),
              ", the effective sample size is ", n_to_use, " participants.</p>")
          }

          adjustment_notes <- paste0(adjustment_notes, "</div>")
        }

        # Create base result text
        base_result <- create_power_single_result_text(
          incidence_rate = incidence_rate,
          sample_size = sample_size,
          power = power,
          alpha = tab1_inputs$power_alpha,
          discon = discon
        )

        # Combine with adjustment notes
        HTML(paste0(base_result, adjustment_notes))
      # Tab 1: Single Proportion - Sample Size (using sidebar_page)
      } else if (page == "ss_single") {
        tab1_inputs <- tab1_vals$inputs()
        calc_mode <- tab1_inputs$ss_single_calc_mode
        power <- tab1_inputs$ss_power / 100
        discon <- tab1_inputs$ss_discon / 100

        if (calc_mode == "calc_n") {
          # Calculate Sample Size
          incidence_rate <- tab1_inputs$ss_p

          # Get multiple testing adjustment
          mt_vals <- tab1_vals$multiple_testing_vals()
          alpha_to_use <- if (mt_vals$adjust_alpha) {
            mt_adj <- calc_adjusted_alpha(
              tab1_inputs$ss_alpha,
              mt_vals$n_tests,
              mt_vals$correction_method
            )
            mt_adj$alpha_adjusted
          } else {
            tab1_inputs$ss_alpha
          }

          sample_size_base <- pwr.p.test(
            sig.level = alpha_to_use, power = power,
            h = ES.h(1 / tab1_inputs$ss_p, 0), alt = "greater", n = NULL
          )$n

          # Apply discontinuation adjustment
          sample_size_after_discon <- ceiling(sample_size_base * (1 + discon))

          # Apply missing data adjustment if enabled
          md_vals <- tab1_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            missing_adj <- calc_missing_data_inflation(
              sample_size_after_discon,
              md_vals$missing_pct,
              md_vals$missing_mechanism,
              md_vals$missing_analysis,
              md_vals$mi_imputations,
              md_vals$mi_r_squared
            )
            sample_size_final <- missing_adj$n_inflated
            missing_data_text <- format_missing_data_text(missing_adj, sample_size_after_discon)
          } else {
            sample_size_final <- sample_size_after_discon
            missing_data_text <- HTML("")
          }

          # Apply clustering adjustment if enabled
          clust_vals <- tab1_vals$clustering_vals()
          if (clust_vals$adjust_clustering) {
            de <- calc_design_effect(clust_vals$cluster_size, clust_vals$icc)
            sample_size_before_clustering <- sample_size_final
            sample_size_final <- ceiling(sample_size_final * de)
          }

          # Build multiple testing text
          mt_text <- if (mt_vals$adjust_alpha) {
            paste0(" <strong>Multiple testing correction:</strong> Using ",
                   mt_vals$correction_method, " correction for ", mt_vals$n_tests,
                   " tests, adjusted α = ", format(alpha_to_use, digits = 4), ".")
          } else {
            ""
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "Based on the Binomial distribution and a true event incidence rate of 1 in ",
            format(incidence_rate, digits = 1, nsmall = 0), " (or ",
            format(1 / incidence_rate * 100, digits = 2, nsmall = 2), "%), ",
            format(ceiling(sample_size_base), digits = 1, nsmall = 0),
            " participants would be needed to observe at least one event with ",
            format(power * 100, digits = 1, nsmall = 0), "% probability (α = ",
            tab1_inputs$ss_alpha, ").",
            mt_text,
            " Accounting for a possible withdrawal or discontinuation rate of ",
            format(discon * 100, digits = 1), "%, the target number of participants is set as ",
            format(sample_size_after_discon, digits = 1), ".",
            if (md_vals$adjust_missing) {
              before_clust_n <- if (clust_vals$adjust_clustering) sample_size_before_clustering else sample_size_final
              paste0(" <strong>After adjusting for ", md_vals$missing_pct,
                     "% missing data, the target sample size is ",
                     format(before_clust_n, digits = 1), ".</strong>")
            } else {
              ""
            },
            if (clust_vals$adjust_clustering) {
              paste0(" <strong>After adjusting for clustering</strong> (ICC = ", clust_vals$icc,
                     ", cluster size = ", clust_vals$cluster_size, ", design effect = ",
                     format(de, digits = 2), "), <strong>the final target sample size is ",
                     format(sample_size_final, digits = 1), ".</strong>")
            } else {
              ""
            }
          ))

          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Minimal Detectable Effect Size
          n_nominal <- tab1_inputs$ss_n_fixed
          n_after_discon <- ceiling(n_nominal * (1 - discon))

          md_vals <- tab1_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n_effective <- ceiling(n_after_discon * (1 - p_missing))
          } else {
            n_effective <- n_after_discon
          }

          # Solve for minimal detectable p
          minimal_p <- uniroot(function(p) {
            pwr.p.test(
              sig.level = tab1_inputs$ss_alpha, power = power,
              h = ES.h(p, 0), alt = "greater", n = n_effective
            )$power - power
          }, c(0.001, 0.999))$root

          minimal_rate <- 1 / minimal_p

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "With a sample size of ", format(n_nominal, digits = 1), " participants, ",
            "accounting for ", format(discon * 100, digits = 1), "% discontinuation",
            if (md_vals$adjust_missing) {
              paste0(" and ", md_vals$missing_pct, "% missing data")
            } else {
              ""
            },
            " (effective N = ", n_effective, "), ",
            "the study has ", format(power * 100, digits = 1), "% power (α = ",
            tab1_inputs$ss_alpha, ") to detect an event with incidence rate of 1 in ",
            format(ceiling(minimal_rate), digits = 1, nsmall = 0), " (or ",
            format(minimal_p * 100, digits = 2, nsmall = 2), "%) or higher."
          ))

          HTML(paste0(text0, text1, text2, text3))
        }

      # Tab 2: Two-Group Comparison - Power Analysis (using sidebar_page)
      } else if (page == "power_twogrp") {
        tab2_inputs <- tab2_vals$inputs()
        n1 <- tab2_inputs$twogrp_pow_n1
        n2 <- tab2_inputs$twogrp_pow_n2
        p1 <- tab2_inputs$twogrp_pow_p1 / 100
        p2 <- tab2_inputs$twogrp_pow_p2 / 100

        power <- pwr.2p2n.test(
          h = ES.h(p1, p2), n1 = n1, n2 = n2,
          sig.level = tab2_inputs$twogrp_pow_alpha,
          alternative = tab2_inputs$twogrp_pow_sided
        )$power

        text0 <- hr()
        text1 <- h1("Results of this analysis")
        text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
        text3 <- p(paste0(
          "For a two-group comparison with event rates of ",
          format(p1 * 100, digits = 2, nsmall = 1), "% in Group 1 and ",
          format(p2 * 100, digits = 2, nsmall = 1), "% in Group 2, with sample sizes of n1 = ",
          n1, " and n2 = ", n2, ", the study has ",
          format(power * 100, digits = 1, nsmall = 1), "% power to detect this difference at α = ",
          tab2_inputs$twogrp_pow_alpha, " (", tab2_inputs$twogrp_pow_sided, " test)."
        ))
        HTML(paste0(text0, text1, text2, text3))

      # Tab 2: Two-Group Comparison - Sample Size (using sidebar_page)
      } else if (page == "ss_twogrp") {
        tab2_inputs <- tab2_vals$inputs()
        calc_mode <- tab2_inputs$twogrp_ss_calc_mode
        power <- tab2_inputs$twogrp_ss_power / 100

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          p1 <- tab2_inputs$twogrp_ss_p1 / 100
          p2 <- tab2_inputs$twogrp_ss_p2 / 100

          # Calculate base sample size for group 1 (ratio-aware for unequal allocation)
          n1_base <- solve_n1_for_ratio(
            ES.h(p1, p2), tab2_inputs$twogrp_ss_ratio,
            tab2_inputs$twogrp_ss_alpha, power, tab2_inputs$twogrp_ss_sided
          )
          n2_base <- n1_base * tab2_inputs$twogrp_ss_ratio
          n_total_base <- ceiling(n1_base + n2_base)

          # Apply missing data adjustment if enabled
          md_vals <- tab2_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              md_vals$missing_pct,
              md_vals$missing_mechanism,
              md_vals$missing_analysis,
              md_vals$mi_imputations,
              md_vals$mi_r_squared
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain allocation ratio after adjustment
            n1_final <- ceiling(n_total_final / (1 + tab2_inputs$twogrp_ss_ratio))
            n2_final <- n_total_final - n1_final

            missing_data_text <- format_missing_data_text(missing_adj, n_total_base)
          } else {
            n1_final <- ceiling(n1_base)
            n2_final <- ceiling(n2_base)
            n_total_final <- n1_final + n2_final
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")

          # Calculate effect measures
          effect_measures <- calc_effect_measures(p1, p2)

          text3 <- p(paste0(
            "To detect a difference in event rates from ",
            format(p2 * 100, digits = 2, nsmall = 1), "% in Group 2 (control) to ",
            format(p1 * 100, digits = 2, nsmall = 1), "% in Group 1 (exposed/treatment) with ",
            format(power * 100, digits = 1, nsmall = 0), "% power at α = ",
            tab2_inputs$twogrp_ss_alpha, " (", tab2_inputs$twogrp_ss_sided, " test), the required sample sizes are: Group 1: n1 = ",
            format(n1_final, digits = 1, nsmall = 0), ", Group 2: n2 = ",
            format(n2_final, digits = 1, nsmall = 0), " (total N = ",
            format(n_total_final, digits = 1, nsmall = 0), ").",
            if (md_vals$adjust_missing) {
              paste0(" <strong>After adjusting for ", md_vals$missing_pct,
                     "% missing data, the final total sample size is ",
                     format(n_total_final, digits = 1), " participants (n1=", n1_final, ", n2=", n2_final, ").</strong>")
            } else {
              ""
            }
          ))

          effect_text <- format_effect_measures(effect_measures)

          HTML(paste0(text0, text1, text2, text3, effect_text, missing_data_text))

        } else {
          # Calculate Effect Size (Minimal Detectable Effect)
          n1_nominal <- tab2_inputs$twogrp_ss_n1_fixed
          n2_nominal <- n1_nominal * tab2_inputs$twogrp_ss_ratio
          p2 <- tab2_inputs$twogrp_ss_p2_baseline / 100

          # Account for missing data to get effective sample sizes
          md_vals <- tab2_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n1_effective <- ceiling(n1_nominal * (1 - p_missing))
            n2_effective <- ceiling(n2_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", md_vals$missing_pct,
              "% missing data (", tolower(substr(md_vals$missing_mechanism, 1, 4)),
              "), effective sample sizes are n1=", n1_effective, ", n2=", n2_effective, ".")
          } else {
            n1_effective <- n1_nominal
            n2_effective <- n2_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable h
          h_min <- pwr.2p2n.test(
            h = NULL, n1 = n1_effective, n2 = n2_effective,
            sig.level = tab2_inputs$twogrp_ss_alpha, power = power,
            alternative = tab2_inputs$twogrp_ss_sided
          )$h

          # Convert h to p1 given p2
          # h = 2*asin(sqrt(p1)) - 2*asin(sqrt(p2))
          # Therefore: p1 = sin²((h + 2*asin(sqrt(p2)))/2)
          p1_detectable <- sin((h_min + 2 * asin(sqrt(p2))) / 2)^2

          # Calculate effect measures
          effect_measures <- calc_effect_measures(p1_detectable, p2)

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis</strong><br>",
            "With available sample sizes of n1=", n1_nominal, " (Group 1) and n2=",
            round(n2_nominal), " (Group 2, ratio=", tab2_inputs$twogrp_ss_ratio, "),",
            missing_note,
            " With ", format(power * 100, digits = 1), "% power and α = ", tab2_inputs$twogrp_ss_alpha,
            " (", tab2_inputs$twogrp_ss_sided, " test), given a baseline event rate of ",
            format(p2 * 100, digits = 2), "% in Group 2, ",
            "the <strong>minimal detectable event rate in Group 1 is ",
            format(p1_detectable * 100, digits = 2), "%</strong> (risk difference: ",
            format(abs(effect_measures$risk_diff), digits = 2), " percentage points)."
          ))

          effect_size_box <- format_minimal_detectable_effect(
            p1_detectable, p2, effect_measures, h_min
          )

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }

      # Tab 3: Survival Analysis - Power Analysis (using sidebar_page)
      } else if (page == "power_survival") {
        tab3_inputs <- tab3_vals$inputs()
        n <- tab3_inputs$surv_pow_n
        hr <- tab3_inputs$surv_pow_hr
        k <- tab3_inputs$surv_pow_k / 100
        pE <- tab3_inputs$surv_pow_pE / 100

        # Calculate power using powerSurvEpi
        power <- powerEpi.default(
          n = n, theta = hr, p = k, psi = pE,
          rho2 = 0, alpha = tab3_inputs$surv_pow_alpha
        )

        # Use helper function for result text
        HTML(as.character(create_survival_power_result_text(n, hr, k, pE, power, tab3_inputs$surv_pow_alpha)))

      # Tab 3: Survival Analysis - Sample Size (using sidebar_page)
      } else if (page == "ss_survival") {
        tab3_inputs <- tab3_vals$inputs()
        calc_mode <- tab3_inputs$surv_ss_calc_mode
        power <- tab3_inputs$surv_ss_power / 100
        k <- tab3_inputs$surv_ss_k / 100
        pE <- tab3_inputs$surv_ss_pE / 100
        md_vals <- tab3_vals$missing_data_vals()

        if (calc_mode == "calc_n") {
          # Calculate Sample Size
          hr <- tab3_inputs$surv_ss_hr

          # Calculate base sample size using powerSurvEpi
          n_base <- ssizeEpi.default(
            power = power, theta = hr, p = k, psi = pE,
            rho2 = 0, alpha = tab3_inputs$surv_ss_alpha
          )

          # Apply missing data adjustment if enabled
          if (md_vals$adjust_missing) {
            missing_adj <- calc_missing_data_inflation(
              n_base,
              md_vals$missing_pct,
              md_vals$missing_mechanism,
              md_vals$missing_analysis,
              md_vals$mi_imputations,
              md_vals$mi_r_squared
            )
            n_final <- missing_adj$n_inflated
            missing_data_text <- format_missing_data_text(missing_adj, n_base)
          } else {
            n_final <- n_base
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "To detect a hazard ratio of ", format_numeric(hr, 2),
            " with ", format_numeric(power * 100, 0), "% power in a survival analysis using Cox regression, ",
            "with ", format_numeric(k * 100, 1), "% of participants exposed/treated and an overall event rate of ",
            format_numeric(pE * 100, 1), "%, the required total sample size is N = ",
            format_numeric(ceiling(n_final), 0), " participants (α = ",
            tab3_inputs$surv_ss_alpha, ", two-sided test).",
            if (md_vals$adjust_missing) {
              paste0(" <strong>This includes adjustment for ", md_vals$missing_pct,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Hazard Ratio (Minimal Detectable Effect)
          n_nominal <- tab3_inputs$surv_ss_n_fixed

          # Account for missing data to get effective sample size
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n_effective <- ceiling(n_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", md_vals$missing_pct,
              "% missing data (", tolower(substr(md_vals$missing_mechanism, 1, 4)),
              "), the effective sample size is ", n_effective, " participants.")
          } else {
            n_effective <- n_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable HR using binary search
          hr_lower <- 0.01
          hr_upper <- 10.0
          tolerance <- 0.001
          max_iter <- 100

          for (i in 1:max_iter) {
            hr_mid <- (hr_lower + hr_upper) / 2
            power_achieved <- powerEpi.default(
              n = n_effective, theta = hr_mid, p = k, psi = pE,
              rho2 = 0, alpha = tab3_inputs$surv_ss_alpha
            )

            if (abs(power_achieved - power) < 0.001) {
              break
            } else if (power_achieved > power) {
              # HR too far from 1, need to move closer to 1
              if (hr_mid < 1) {
                hr_lower <- hr_mid
              } else {
                hr_upper <- hr_mid
              }
            } else {
              # HR too close to 1, need to move farther from 1
              if (hr_mid < 1) {
                hr_upper <- hr_mid
              } else {
                hr_lower <- hr_mid
              }
            }
          }

          hr_detectable <- hr_mid
          hr_interpretation <- format_hazard_ratio(hr_detectable)

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis</strong><br>",
            "With an available sample size of N=", n_nominal, " participants,",
            missing_note,
            " With ", format_numeric(power * 100, 0), "% power, α = ", tab3_inputs$surv_ss_alpha,
            ", ", format_numeric(k * 100, 1), "% exposed/treated, and ",
            format_numeric(pE * 100, 1), "% overall event rate, ",
            "the <strong>minimal detectable hazard ratio is HR = ",
            format_numeric(hr_detectable, 3), "</strong>. ",
            "This is the smallest hazard ratio that can be reliably detected with this sample size using Cox regression. ",
            "This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect:</strong><br>",
            "<strong>Hazard Ratio (HR):</strong> ", format_numeric(hr_detectable, 3),
            " (", hr_interpretation, ")<br>",
            "<strong>Interpretation:</strong> ",
            ifelse(hr_detectable < 1,
              paste0("Can detect protective effects with HR ≤ ", format_numeric(hr_detectable, 3)),
              paste0("Can detect risk increases with HR ≥ ", format_numeric(hr_detectable, 3))),
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }

      # Tab 4: Matched Case-Control (using sidebar_page)
      } else if (page == "match_casecontrol") {
        tab4_inputs <- tab4_vals$inputs()
        calc_mode <- tab4_inputs$match_calc_mode
        p0 <- tab4_inputs$match_p0 / 100
        m <- tab4_inputs$match_ratio
        power <- tab4_inputs$match_power / 100
        sided_val <- ifelse(tab4_inputs$match_sided == "two.sided", 2, 1)

        if (calc_mode == "calc_n") {
          # Calculate Sample Size
          or <- tab4_inputs$match_or

          # Calculate base sample size for matched case-control using epiR
          result <- epi.sscc(
            OR = or, p0 = p0, n = NA, power = power,
            r = m, rho = 0, design = 1, sided.test = sided_val,
            conf.level = 1 - tab4_inputs$match_alpha
          )
          n_cases_base <- ceiling(result$n.total)
          n_controls_base <- n_cases_base * m
          n_total_base <- n_cases_base * (1 + m)

          # Apply missing data adjustment if enabled
          md_vals <- tab4_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              md_vals$missing_pct,
              md_vals$missing_mechanism,
              md_vals$missing_analysis,
              md_vals$mi_imputations,
              md_vals$mi_r_squared
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain matching ratio
            n_cases_final <- ceiling(n_total_final / (1 + m))
            n_controls_final <- n_cases_final * m

            missing_data_text <- format_missing_data_text(missing_adj, n_total_base)
          } else {
            n_cases_final <- n_cases_base
            n_controls_final <- n_controls_base
            n_total_final <- n_total_base
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "For a matched case-control study to detect an odds ratio of ",
            format_numeric(or), " with ", format_numeric(power * 100, 0),
            "% power, assuming ", format_numeric(p0 * 100, 1),
            "% exposure prevalence in controls, and a ", m, ":1 matching ratio (controls per case), ",
            "the required sample size is ", n_cases_final, " cases and ",
            format_numeric(n_controls_final, 0), " controls (total N = ",
            format_numeric(n_total_final, 0), " participants) at α = ",
            tab4_inputs$match_alpha, " (", tab4_inputs$match_sided, " test).",
            if (md_vals$adjust_missing) {
              paste0(" <strong>After adjusting for ", md_vals$missing_pct,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " This accounts for correlation between matched pairs."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Odds Ratio (Minimal Detectable Effect)
          n_cases_nominal <- tab4_inputs$match_n_pairs_fixed
          n_controls_nominal <- n_cases_nominal * m
          n_total_nominal <- n_cases_nominal * (1 + m)

          # Account for missing data to get effective sample sizes
          md_vals <- tab4_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n_cases_effective <- ceiling(n_cases_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", md_vals$missing_pct,
              "% missing data (", tolower(substr(md_vals$missing_mechanism, 1, 4)),
              "), the effective number of cases is ", n_cases_effective, ".")
          } else {
            n_cases_effective <- n_cases_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable OR using binary search
          or_lower <- 0.1
          or_upper <- 10.0
          tolerance <- 0.01
          max_iter <- 100

          for (i in 1:max_iter) {
            or_mid <- (or_lower + or_upper) / 2
            result <- tryCatch({
              epi.sscc(
                OR = or_mid, p0 = p0, n = n_cases_effective, power = NA,
                r = m, rho = 0, design = 1, sided.test = sided_val,
                conf.level = 1 - tab4_inputs$match_alpha
              )
            }, error = function(e) list(power = 0))

            power_achieved <- result$power
            if (is.null(power_achieved) || is.na(power_achieved)) power_achieved <- 0

            if (abs(power_achieved - power) < 0.01) {
              break
            } else if (power_achieved > power) {
              # OR too far from 1, need to move closer to 1
              if (or_mid < 1) {
                or_lower <- or_mid
              } else {
                or_upper <- or_mid
              }
            } else {
              # OR too close to 1, need to move farther from 1
              if (or_mid < 1) {
                or_upper <- or_mid
              } else {
                or_lower <- or_mid
              }
            }
          }

          or_detectable <- or_mid

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis</strong><br>",
            "With an available sample size of ", n_cases_nominal, " matched case-control pairs,",
            missing_note,
            " With ", format_numeric(power * 100, 0), "% power, α = ", tab4_inputs$match_alpha,
            ", assuming ", format_numeric(p0 * 100, 1),
            "% exposure prevalence in controls and a ", m, ":1 matching ratio, ",
            "the <strong>minimal detectable odds ratio is OR = ",
            format_numeric(or_detectable, 2), "</strong>. ",
            "This is the smallest odds ratio that can be reliably detected with this matched study design."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect:</strong><br>",
            "<strong>Odds Ratio (OR):</strong> ", format_numeric(or_detectable, 2),
            ifelse(or_detectable < 1,
              " (protective effect)",
              " (risk factor)"), "<br>",
            "<strong>Interpretation:</strong> ",
            ifelse(or_detectable < 1,
              paste0("Can detect protective effects with OR ≤ ", format_numeric(or_detectable, 2)),
              paste0("Can detect risk increases with OR ≥ ", format_numeric(or_detectable, 2))),
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }

      # Tab 5: Continuous Outcomes - Power Analysis (using sidebar_page)
      } else if (page == "power_continuous") {
        tab5_inputs <- tab5_vals$inputs()
        n1 <- tab5_inputs$cont_pow_n1
        n2 <- tab5_inputs$cont_pow_n2
        d <- tab5_inputs$cont_pow_d

        # Calculate power for t-test
        power <- pwr.t2n.test(
          n1 = n1, n2 = n2, d = d,
          sig.level = tab5_inputs$cont_pow_alpha,
          alternative = tab5_inputs$cont_pow_sided
        )$power

        create_continuous_power_result_text(
          n1 = n1,
          n2 = n2,
          d = d,
          power = power,
          alpha = tab5_inputs$cont_pow_alpha,
          sided = tab5_inputs$cont_pow_sided
        )

      # Tab 5: Continuous Outcomes - Sample Size (using sidebar_page)
      } else if (page == "ss_continuous") {
        tab5_inputs <- tab5_vals$inputs()
        calc_mode <- tab5_inputs$cont_ss_calc_mode
        power <- tab5_inputs$cont_ss_power / 100
        ratio <- tab5_inputs$cont_ss_ratio

        if (calc_mode == "calc_n") {
          # Calculate Sample Size
          d <- tab5_inputs$cont_ss_d

          # Calculate base sample size for t-test (solve for n1)
          if (ratio == 1) {
            n <- pwr.t.test(
              d = d, sig.level = tab5_inputs$cont_ss_alpha,
              power = power, type = "two.sample",
              alternative = tab5_inputs$cont_ss_sided
            )$n
            n1_base <- n
            n2_base <- n
          } else {
            # For unequal allocation, use iterative approach
            f <- function(n1) {
              n2 <- n1 * ratio
              pwr.t2n.test(
                n1 = n1, n2 = n2, d = d,
                sig.level = tab5_inputs$cont_ss_alpha,
                alternative = tab5_inputs$cont_ss_sided
              )$power - power
            }
            n1_base <- tryCatch(
              {
                uniroot(f, c(2, 1e6), extendInt = "yes")$root
              },
              error = function(e) {
                # Fallback
                pwr.t.test(
                  d = d, sig.level = tab5_inputs$cont_ss_alpha,
                  power = power, type = "two.sample",
                  alternative = tab5_inputs$cont_ss_sided
                )$n
              }
            )
            n2_base <- n1_base * ratio
          }
          n_total_base <- ceiling(n1_base + n2_base)

          # Apply missing data adjustment if enabled
          md_vals <- tab5_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              md_vals$missing_pct,
              md_vals$missing_mechanism,
              md_vals$missing_analysis,
              md_vals$mi_imputations,
              md_vals$mi_r_squared
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain allocation ratio
            n1_final <- ceiling(n_total_final / (1 + ratio))
            n2_final <- n_total_final - n1_final

            missing_data_text <- format_missing_data_text(missing_adj, n_total_base)
          } else {
            n1_final <- ceiling(n1_base)
            n2_final <- ceiling(n2_base)
            n_total_final <- n1_final + n2_final
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "To detect an effect size of ", format_cohens_d(d),
            " in a two-group comparison of continuous outcomes with ", format_numeric(power * 100, 0),
            "% power at α = ", tab5_inputs$cont_ss_alpha, " (", tab5_inputs$cont_ss_sided, " test), ",
            "the required sample sizes are: Group 1: n1 = ", format_numeric(n1_final, 0),
            ", Group 2: n2 = ", format_numeric(n2_final, 0), " (total N = ",
            format_numeric(n_total_final, 0), ").",
            if (md_vals$adjust_missing) {
              paste0(" <strong>After adjusting for ", md_vals$missing_pct,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " Cohen's d is the standardized mean difference (difference in means / pooled SD)."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Effect Size (Minimal Detectable Effect)
          n1_nominal <- tab5_inputs$cont_ss_n1_fixed
          n2_nominal <- n1_nominal * ratio

          # Account for missing data to get effective sample sizes
          md_vals <- tab5_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n1_effective <- ceiling(n1_nominal * (1 - p_missing))
            n2_effective <- ceiling(n2_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", md_vals$missing_pct,
              "% missing data (", tolower(substr(md_vals$missing_mechanism, 1, 4)),
              "), effective sample sizes are n1=", format_numeric(n1_effective, 0),
              ", n2=", format_numeric(n2_effective, 0), ".")
          } else {
            n1_effective <- n1_nominal
            n2_effective <- n2_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable d
          d_detectable <- pwr.t2n.test(
            n1 = n1_effective, n2 = n2_effective, d = NULL,
            sig.level = tab5_inputs$cont_ss_alpha, power = power,
            alternative = tab5_inputs$cont_ss_sided
          )$d

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis</strong><br>",
            "With available sample sizes of n1=", format_numeric(n1_nominal, 0), " (Group 1) and n2=",
            format_numeric(n2_nominal, 0), " (Group 2, ratio=", ratio, "),",
            missing_note,
            " With ", format_numeric(power * 100, 0), "% power and α = ", tab5_inputs$cont_ss_alpha,
            " (", tab5_inputs$cont_ss_sided, " test), ",
            "the <strong>minimal detectable effect size is Cohen's d = ",
            format_numeric(d_detectable, 3), "</strong> (", format_cohens_d(d_detectable), "). ",
            "This is the smallest standardized mean difference that can be reliably detected."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect:</strong><br>",
            "<strong>Cohen's d:</strong> ", format_numeric(d_detectable, 3),
            " (", format_cohens_d(d_detectable), ")<br>",
            "<strong>Interpretation:</strong> The study can detect ", format_cohens_d(d_detectable),
            " differences in means (standardized).",
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }

      # Tab 6: Non-Inferiority (using sidebar_page)
      } else if (page == "noninf") {
        tab6_inputs <- tab6_vals$inputs()
        calc_mode <- tab6_inputs$noninf_calc_mode
        p1 <- tab6_inputs$noninf_p1 / 100
        p2 <- tab6_inputs$noninf_p2 / 100
        power <- tab6_inputs$noninf_power / 100
        ratio <- tab6_inputs$noninf_ratio

        if (calc_mode == "calc_n") {
          # Calculate Sample Size
          margin <- tab6_inputs$noninf_margin / 100

          # Non-inferiority sample size calculation
          # H0: p1 - p2 >= margin (inferior), H1: p1 - p2 < margin (non-inferior)
          # Use one-sided test

          # Calculate effect size h for the margin test
          h <- ES.h(p1, p2 + margin)

          if (ratio == 1) {
            n <- pwr.2p.test(
              h = abs(h), sig.level = tab6_inputs$noninf_alpha,
              power = power, alternative = "less"
            )$n
            n1_base <- n
            n2_base <- n
          } else {
            f <- function(n1) {
              n2 <- n1 * ratio
              pwr.2p2n.test(
                h = abs(h), n1 = n1, n2 = n2,
                sig.level = tab6_inputs$noninf_alpha,
                alternative = "less"
              )$power - power
            }
            n1_base <- tryCatch(
              {
                uniroot(f, c(2, 1e6), extendInt = "yes")$root
              },
              error = function(e) {
                pwr.2p.test(
                  h = abs(h), sig.level = tab6_inputs$noninf_alpha,
                  power = power, alternative = "less"
                )$n
              }
            )
            n2_base <- n1_base * ratio
          }
          n_total_base <- ceiling(n1_base + n2_base)

          # Apply missing data adjustment if enabled
          md_vals <- tab6_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              md_vals$missing_pct,
              md_vals$missing_mechanism,
              md_vals$missing_analysis,
              md_vals$mi_imputations,
              md_vals$mi_r_squared
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain allocation ratio
            n1_final <- ceiling(n_total_final / (1 + ratio))
            n2_final <- n_total_final - n1_final

            missing_data_text <- format_missing_data_text(missing_adj, n_total_base)
          } else {
            n1_final <- ceiling(n1_base)
            n2_final <- ceiling(n2_base)
            n_total_final <- n1_final + n2_final
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "For a non-inferiority trial comparing a test treatment (expected event rate: ",
            format_numeric(p1 * 100, 2, 1), "%) to a reference treatment (expected event rate: ",
            format_numeric(p2 * 100, 2, 1), "%) with a non-inferiority margin of ",
            format_numeric(margin * 100, 2, 1), " percentage points, to demonstrate non-inferiority with ",
            format_numeric(power * 100, 0, 0), "% power at α = ", tab6_inputs$noninf_alpha,
            " (one-sided test), the required sample sizes are: Test Group: n1 = ",
            format_numeric(n1_final, 0, 0), ", Reference Group: n2 = ",
            format_numeric(n2_final, 0, 0), " (total N = ",
            format_numeric(n_total_final, 0, 0), ").",
            if (md_vals$adjust_missing) {
              paste0(" <strong>After adjusting for ", md_vals$missing_pct,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " Non-inferiority will be demonstrated if the upper bound of the confidence interval for the difference (Test - Reference) is less than the margin."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Margin (Minimal Detectable Effect)
          n1_nominal <- tab6_inputs$noninf_n1_fixed
          n2_nominal <- n1_nominal * ratio

          # Account for missing data to get effective sample sizes
          md_vals <- tab6_vals$missing_data_vals()
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n1_effective <- ceiling(n1_nominal * (1 - p_missing))
            n2_effective <- ceiling(n2_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", md_vals$missing_pct,
              "% missing data (", tolower(substr(md_vals$missing_mechanism, 1, 4)),
              "), effective sample sizes are n1=", format_numeric(n1_effective, 0, 0),
              ", n2=", format_numeric(n2_effective, 0, 0), ".")
          } else {
            n1_effective <- n1_nominal
            n2_effective <- n2_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable margin using binary search
          margin_lower <- 0.001
          margin_upper <- 0.5
          tolerance <- 0.001
          max_iter <- 100

          for (i in 1:max_iter) {
            margin_mid <- (margin_lower + margin_upper) / 2
            h <- ES.h(p1, p2 + margin_mid)

            power_achieved <- pwr.2p2n.test(
              h = abs(h), n1 = n1_effective, n2 = n2_effective,
              sig.level = tab6_inputs$noninf_alpha,
              alternative = "less"
            )$power

            if (abs(power_achieved - power) < 0.01) {
              break
            } else if (power_achieved > power) {
              # Margin too large, decrease it
              margin_upper <- margin_mid
            } else {
              # Margin too small, increase it
              margin_lower <- margin_mid
            }
          }

          margin_detectable <- margin_mid

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Margin Analysis</strong><br>",
            "With available sample sizes of n1=", format_numeric(n1_nominal, 0, 0), " (Test Group) and n2=",
            format_numeric(n2_nominal, 0, 0), " (Reference Group, ratio=", format_numeric(ratio, 1, 1), "),",
            missing_note,
            " With ", format_numeric(power * 100, 0, 0), "% power and α = ", tab6_inputs$noninf_alpha,
            " (one-sided test), for a non-inferiority trial comparing test treatment (expected event rate: ",
            format_numeric(p1 * 100, 2, 1), "%) to reference treatment (expected event rate: ",
            format_numeric(p2 * 100, 2, 1), "%), ",
            "the <strong>minimal detectable non-inferiority margin is ",
            format_numeric(margin_detectable * 100, 2, 2), " percentage points</strong>. ",
            "This is the largest margin that can be reliably tested for non-inferiority with this sample size. ",
            "Non-inferiority will be demonstrated if the upper bound of the confidence interval for the difference (Test - Reference) is less than this margin."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Margin:</strong><br>",
            "<strong>Non-Inferiority Margin:</strong> ", format_numeric(margin_detectable * 100, 2, 2), " percentage points<br>",
            "<strong>Interpretation:</strong> Can demonstrate non-inferiority if the true difference (Test - Reference) is less than ",
            format_numeric(margin_detectable * 100, 2, 2), " percentage points",
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }

      } else if (page == "vif_calculator") {
        # PAGE 11: Propensity Score Calculator (Austin 2021 + Li et al. 2025)

        # Get common inputs
        n_rct <- input$vif_n_rct
        prevalence_pct <- input$vif_prevalence
        weight_method <- input$vif_method
        ps_calc_method <- input$ps_calc_method

        # Calculate based on selected method
        if (ps_calc_method == "austin") {
          # ========== AUSTIN (2021) VIF METHOD ==========
          c_stat <- input$vif_cstat

          # Calculate VIF
          vif <- estimate_vif_propensity_score(c_stat, prevalence_pct, weight_method)

          # Calculate adjusted sample sizes
          n_adjusted <- ceiling(n_rct * vif)
          n_increase <- n_adjusted - n_rct
          pct_increase <- (vif - 1) * 100
          n_effective <- floor(n_rct / vif)

          # Interpret VIF
          vif_interp <- interpret_vif(vif)

          # C-statistic interpretation
          c_stat_interp <- if (c_stat < 0.6) {
            "Poor discrimination (may indicate weak confounding or insufficient covariates)"
          } else if (c_stat < 0.7) {
            "Fair discrimination (typical for claims/EHR data)"
          } else if (c_stat < 0.8) {
            "Good discrimination (typical for rich registry/cohort data)"
          } else if (c_stat < 0.9) {
            "Very good discrimination (may lead to high VIF for ATE/ATT)"
          } else {
            "Excellent discrimination (high VIF expected; consider alternative methods)"
          }

          method_source <- "Austin (2021)"
          method_inputs_html <- paste0(
            "<ul>",
            "<li><strong>Treatment prevalence:</strong> ", prevalence_pct, "%</li>",
            "<li><strong>Anticipated c-statistic:</strong> ", c_stat, " (", c_stat_interp, ")</li>",
            "</ul>"
          )

        } else {
          # ========== LI ET AL. (2025) METHOD ==========
          overlap_phi <- input$vif_overlap_phi
          rho_squared <- input$vif_rho_squared

          # Use Li et al. (2025) calculations
          treatment_prop <- prevalence_pct / 100
          effect_size <- 0.2  # Standardized effect size placeholder

          li_result <- calculate_n_li_2025(
            effect_size = effect_size,
            alpha = 0.05,
            power = 0.80,
            treatment_prop = treatment_prop,
            overlap_phi = overlap_phi,
            rho_squared = rho_squared,
            weight_type = weight_method,
            outcome_var = 1
          )

          # Extract results
          vif <- li_result$vif
          n_adjusted <- li_result$n_required
          n_increase <- n_adjusted - n_rct
          pct_increase <- (vif - 1) * 100
          n_effective <- li_result$n_effective

          # Interpret components
          vif_interp <- interpret_vif(vif)
          overlap_interp <- interpret_overlap_coefficient(overlap_phi)
          rho_interp <- interpret_rho_squared(rho_squared)

          method_source <- "Li et al. (2025)"
          method_inputs_html <- paste0(
            "<ul>",
            "<li><strong>Treatment prevalence:</strong> ", prevalence_pct, "%</li>",
            "<li><strong>Overlap coefficient (φ):</strong> ", format_numeric(overlap_phi, 2), " <span style='color: ", overlap_interp$color, ";'>(", overlap_interp$level, ")</span></li>",
            "<li><strong>Confounder-outcome R²:</strong> ", format_numeric(rho_squared, 2), " <span style='color: ", rho_interp$color, ";'>(", rho_interp$level, ")</span></li>",
            "</ul>"
          )
        }

        # Interpret VIF (common to both methods)
        vif_interp <- interpret_vif(vif)

        # Method descriptions
        method_desc <- switch(weight_method,
          "ATE" = list(
            name = "Average Treatment Effect (ATE) - IPTW",
            description = "Inverse Probability of Treatment Weighting creates a pseudo-population where treatment is independent of measured confounders. Generalizes to the full population.",
            target = "entire population"
          ),
          "ATT" = list(
            name = "Average Treatment Effect on Treated (ATT)",
            description = "Estimates the effect specifically in those who received treatment. Useful when interest is in the treated population only.",
            target = "treated patients only"
          ),
          "ATO" = list(
            name = "Overlap Weights (ATO)",
            description = "Focuses on patients with clinical equipoise (good propensity score overlap). Most efficient method with lowest VIF. Recommended for RWE studies.",
            target = "overlap population (equipoise region)"
          ),
          "ATM" = list(
            name = "Matching Weights (ATM)",
            description = "Mimics 1:1 matching but retains all subjects. Efficient and balances covariates well.",
            target = "matched population"
          ),
          "ATEN" = list(
            name = "Entropy Weights (ATEN)",
            description = "Balances covariates while maximizing effective sample size. Similar efficiency to overlap weights.",
            target = "population maximizing effective sample size"
          )
        )

        # Recommendations (common logic for both methods)
        recommendations <- c()

        if (ps_calc_method == "austin" && c_stat < 0.65) {
          recommendations <- c(recommendations,
            "⚠️ C-statistic is low. Consider including stronger confounders to improve propensity score model discrimination.")
        } else if (ps_calc_method == "li_2025" && overlap_phi < 0.5) {
          recommendations <- c(recommendations,
            "⚠️ Overlap coefficient is low. Propensity score distributions have poor overlap. Overlap weights (ATO) strongly recommended.")
        } else {
          recommendations <- c(recommendations,
            "✅ Propensity score model assumptions are adequate.")
        }

        if (ps_calc_method == "li_2025" && rho_squared > 0.2) {
          recommendations <- c(recommendations,
            "⚠️ Strong confounder-outcome association (R² > 0.2) requires substantial sample size inflation. Consider whether all important confounders can be measured.")
        }

        if (prevalence_pct < 20 || prevalence_pct > 80) {
          recommendations <- c(recommendations,
            sprintf("⚠️ Treatment prevalence (%s%%) is imbalanced. VIF will be higher. Consider restricting to overlap region (ATO weights).", prevalence_pct))
        } else {
          recommendations <- c(recommendations,
            "✅ Treatment prevalence is reasonably balanced.")
        }

        if (vif > 2.0) {
          recommendations <- c(recommendations,
            "⚠️ High VIF suggests substantial efficiency loss. Consider overlap weights (ATO) or matching weights (ATM) to improve efficiency.")
        } else {
          recommendations <- c(recommendations,
            "✅ VIF is acceptable. Propensity score weighting is feasible for this scenario.")
        }

        if (ps_calc_method == "austin") {
          recommendations <- c(recommendations,
            "💡 <strong>Try Li et al. (2025) method:</strong> Provides more accurate sample size by accounting for confounder-outcome association strength.")
        }

        recommendations_html <- paste0(
          "<ul>",
          paste0("<li>", recommendations, "</li>", collapse = "\n"),
          "</ul>"
        )

        # Generate result HTML
        text0 <- hr()
        text1 <- h1("Propensity Score Weighting: Sample Size Results")
        text2 <- h4("(This analysis can be included in your Statistical Analysis Plan)")

        # Method-specific reference
        method_reference <- if (ps_calc_method == "austin") {
          "<p style='font-size: 0.9em; color: #666;'><strong>Reference:</strong> Austin PC (2021). Informing power and sample size calculations when using inverse probability of treatment weighting using the propensity score. <em>Statistics in Medicine</em> 40(27):6150-6163.</p>"
        } else {
          "<p style='font-size: 0.9em; color: #666;'><strong>Reference:</strong> Li F, Liu B (2025). Sample size and power calculations for causal inference of observational studies. <em>arXiv</em> 2501.11181.</p>"
        }

        text3 <- HTML(paste0(
          "<div style='background-color: #f8f9fa; border-left: 4px solid #6c757d; padding: 15px; margin-bottom: 15px;'>",
          "<strong>Calculation Method:</strong> ", method_source,
          "</div>",

          "<h4>Weighting Method: ", method_desc$name, "</h4>",
          "<p>", method_desc$description, "</p>",
          "<p><strong>Target Population:</strong> ", method_desc$target, "</p>",

          "<hr>",
          "<h4>Propensity Score Model Assumptions</h4>",
          method_inputs_html,

          "<hr>",
          "<h4>Variance Inflation Factor (VIF)</h4>",
          "<p style='font-size: 1.2em;'><strong>VIF = ", format_numeric(vif, 3), "</strong> ",
          "<span style='color: ", vif_interp$color, "; font-weight: bold;'>", vif_interp$icon, " ", vif_interp$level, " Efficiency Loss</span></p>",
          "<p>", vif_interp$message, "</p>",

          "<hr>",
          "<h4>Sample Size Adjustment</h4>",
          "<div style='background-color: #e3f2fd; border-left: 4px solid #2196f3; padding: 15px; margin: 10px 0;'>",
          "<p><strong>RCT-based sample size:</strong> ", format_numeric(n_rct, 0), "</p>",
          "<p><strong>Inflation needed:</strong> +", format_numeric(pct_increase, 1), "% (+", format_numeric(n_increase, 0), " participants)</p>",
          "<p style='font-size: 1.3em; color: #d32f2f;'><strong>Adjusted sample size:</strong> ", format_numeric(n_adjusted, 0), " participants</p>",
          "<p><strong>Effective sample size after weighting:</strong> ≈", format_numeric(n_effective, 0), " (statistical information equivalent)</p>",
          "</div>",

          "<hr>",
          "<h4>Interpretation</h4>",
          "<p>To achieve the same statistical power as a randomized trial with N=", format_numeric(n_rct, 0),
          ", an observational study using <strong>", method_desc$name, "</strong> weighting requires approximately <strong>N=",
          format_numeric(n_adjusted, 0), " participants</strong>.</p>",

          "<p>The effective sample size after propensity score weighting will be approximately ",
          format_numeric(n_effective, 0),
          ", which provides statistical information equivalent to a randomized trial of that size.</p>",

          if (ps_calc_method == "li_2025") {
            paste0(
              "<p><strong>Key Insight (Li et al. 2025):</strong> This calculation accounts for both ",
              "<strong>overlap</strong> (via φ=", format_numeric(overlap_phi, 2), ") and ",
              "<strong>confounding strength</strong> (via R²=", format_numeric(rho_squared, 2), "), ",
              "providing a more theoretically sound sample size estimate than VIF methods based solely on c-statistic.</p>"
            )
          } else {
            ""
          },

          "<hr>",
          "<h4>Recommendations</h4>",
          recommendations_html,

          "<hr>",
          method_reference
        ))

        HTML(paste0(text0, text1, text2, text3))

      } else if (page == "mediation_analysis") {
        # ============================================================
        # MEDIATION ANALYSIS
        # ============================================================

        # Get module inputs
        med_inputs <- tab8_vals$inputs()

        # Extract values
        calc_mode <- med_inputs$calc_mode
        a <- med_inputs$path_a
        b <- med_inputs$path_b
        c_prime <- med_inputs$path_c_prime
        alpha <- med_inputs$med_alpha
        alternative <- med_inputs$med_sided

        # Handle standard errors (use input or estimate from N)
        se_a <- if (!is.na(med_inputs$se_a)) med_inputs$se_a else NULL
        se_b <- if (!is.na(med_inputs$se_b)) med_inputs$se_b else NULL

        # Calculate based on mode
        if (calc_mode == "calc_power") {
          # Calculate power given N
          n <- med_inputs$med_n
          power <- calc_mediation_power(n, a, b, se_a, se_b, alpha, alternative)

          # Build result text
          result_html <- HTML(paste0(
            "<h1>Mediation Analysis Results: Power Calculation</h1>",
            "<hr>",
            "<h4>(Copy/paste this text into your protocol)</h4>",
            "<p>With a sample size of <strong>N = ", format_numeric(n, 0), "</strong> participants, ",
            "the study has <strong>", format_numeric(power * 100, 1), "% power</strong> to detect ",
            "an indirect effect of <strong>a × b = ", format_numeric(a * b, 3), "</strong> ",
            "(α = ", alpha, ", ", ifelse(alternative == "two.sided", "two-sided test", "one-sided test"), ").</p>",
            "<p><strong>Path Coefficients:</strong></p>",
            "<ul>",
            "<li>Path a (X → M): ", format_numeric(a, 3), " <em>(", interpret_path_coefficient(a), ")</em></li>",
            "<li>Path b (M → Y|X): ", format_numeric(b, 3), " <em>(", interpret_path_coefficient(b), ")</em></li>",
            "<li>Indirect effect (a × b): ", format_numeric(a * b, 3), " <em>(", interpret_indirect_effect(a * b), ")</em></li>"
          ))

          if (!is.na(c_prime)) {
            result_html <- HTML(paste0(result_html,
              "<li>Direct effect c' (X → Y|M): ", format_numeric(c_prime, 3), " <em>(", interpret_path_coefficient(c_prime), ")</em></li>"
            ))
          }

          result_html <- HTML(paste0(result_html,
            "</ul>",
            "<p><strong>Interpretation:</strong> The indirect effect represents the amount by which the outcome (Y) ",
            "changes when the independent variable (X) is held constant and the mediator (M) changes by the amount it would have ",
            "changed had X increased by one unit.</p>"
          ))

        } else if (calc_mode == "calc_n") {
          # Calculate sample size given power
          power <- med_inputs$med_power / 100
          n_required <- calc_mediation_n(a, b, power, alpha, alternative)

          if (is.na(n_required)) {
            result_html <- HTML(paste0(
              "<h1>Mediation Analysis: Sample Size Calculation</h1>",
              "<hr>",
              "<p style='color: #dc3545;'><strong>Error:</strong> Unable to calculate required sample size. ",
              "The indirect effect may be too small or the power target may be unachievable. ",
              "Consider increasing effect sizes or reducing power target.</p>"
            ))
          } else {
            result_html <- HTML(paste0(
              "<h1>Mediation Analysis Results: Sample Size Calculation</h1>",
              "<hr>",
              "<h4>(Copy/paste this text into your protocol)</h4>",
              "<p>To achieve <strong>", format_numeric(power * 100, 0), "% power</strong> to detect ",
              "an indirect effect of <strong>a × b = ", format_numeric(a * b, 3), "</strong>, ",
              "a sample size of <strong>N = ", format_numeric(n_required, 0), " participants</strong> is required ",
              "(α = ", alpha, ", ", ifelse(alternative == "two.sided", "two-sided test", "one-sided test"), ").</p>",
              "<p><strong>Path Coefficients:</strong></p>",
              "<ul>",
              "<li>Path a (X → M): ", format_numeric(a, 3), " <em>(", interpret_path_coefficient(a), ")</em></li>",
              "<li>Path b (M → Y|X): ", format_numeric(b, 3), " <em>(", interpret_path_coefficient(b), ")</em></li>",
              "<li>Indirect effect (a × b): ", format_numeric(a * b, 3), " <em>(", interpret_indirect_effect(a * b), ")</em></li>",
              "</ul>"
            ))
          }

        } else if (calc_mode == "calc_mde") {
          # Calculate minimal detectable effect
          n <- med_inputs$med_n
          power <- med_inputs$med_power / 100
          b_min <- calc_mediation_mde(n, a, power, alpha, alternative)

          if (is.na(b_min)) {
            result_html <- HTML(paste0(
              "<h1>Mediation Analysis: Minimal Detectable Effect</h1>",
              "<hr>",
              "<p style='color: #dc3545;'><strong>Error:</strong> Unable to calculate minimal detectable effect. ",
              "The sample size may be too small or the path a coefficient may be too weak.</p>"
            ))
          } else {
            ab_min <- a * b_min
            result_html <- HTML(paste0(
              "<h1>Mediation Analysis Results: Minimal Detectable Effect</h1>",
              "<hr>",
              "<h4>(Copy/paste this text into your protocol)</h4>",
              "<p>With <strong>N = ", format_numeric(n, 0), " participants</strong> and ",
              "<strong>", format_numeric(power * 100, 0), "% power</strong>, ",
              "the smallest detectable indirect effect is <strong>a × b = ", format_numeric(ab_min, 3), "</strong> ",
              "(α = ", alpha, ", ", ifelse(alternative == "two.sided", "two-sided test", "one-sided test"), ").</p>",
              "<p><strong>Path Coefficients:</strong></p>",
              "<ul>",
              "<li>Path a (X → M): ", format_numeric(a, 3), " <em>(", interpret_path_coefficient(a), ")</em> [Given]</li>",
              "<li>Path b (M → Y|X): ", format_numeric(b_min, 3), " <em>(", interpret_path_coefficient(b_min), ")</em> [Minimal detectable]</li>",
              "<li>Indirect effect (a × b): ", format_numeric(ab_min, 3), " <em>(", interpret_indirect_effect(ab_min), ")</em></li>",
              "</ul>",
              "<p><strong>Interpretation:</strong> Given the available sample size and path a, the study can detect ",
              "indirect effects of magnitude ", format_numeric(ab_min, 3), " or larger with ", format_numeric(power * 100, 0), "% power.</p>"
            ))
          }
        }

        HTML(result_html)

      } else if (page == "survival_ni_equiv") {
        # ============================================================
        # TIME-TO-EVENT EQUIVALENCE/NON-INFERIORITY
        # ============================================================

        # Get module inputs
        tab9_inputs <- tab9_vals$inputs()
        md_vals <- tab9_vals$missing_data_vals()
        clust_vals <- tab9_vals$clustering_vals()

        # Extract values
        test_type <- tab9_inputs$test_type
        calc_mode <- tab9_inputs$calc_mode
        power <- tab9_inputs$power / 100
        hr_expected <- tab9_inputs$hr_expected
        prop_exposed <- tab9_inputs$prop_exposed / 100
        event_rate <- tab9_inputs$event_rate / 100
        ratio <- tab9_inputs$allocation_ratio
        alpha <- tab9_inputs$alpha

        if (calc_mode == "calc_n") {
          # Calculate sample size
          if (test_type == "non-inferiority") {
            hr_margin <- tab9_inputs$hr_margin_ni

            # Base calculation
            n_base <- ssize_survival_ni(
              power = power,
              hr_expected = hr_expected,
              hr_margin = hr_margin,
              k = prop_exposed,
              pE = event_rate,
              alpha = alpha,
              ratio = ratio
            )

            # Apply missing data adjustment
            if (md_vals$adjust_missing) {
              missing_adj <- calc_missing_data_inflation(
                n_base,
                md_vals$missing_pct,
                md_vals$missing_mechanism,
                md_vals$missing_analysis,
                md_vals$mi_imputations,
                md_vals$mi_r_squared
              )
              n_total <- missing_adj$n_inflated
            } else {
              n_total <- n_base
            }

            # Apply clustering adjustment
            if (clust_vals$adjust_clustering) {
              de <- calc_design_effect(clust_vals$cluster_size, clust_vals$icc)
              n_before_clustering <- n_total
              n_total <- ceiling(n_total * de)
            }

            # Calculate group sizes
            n_test <- ceiling(n_total / (1 + ratio))
            n_ref <- n_total - n_test

            # Calculate events
            d_events <- events_survival_ni(power, hr_expected, hr_margin, alpha)

            # Generate result text using helper
            result_text <- create_survival_ni_samplesize_text(
              n_total, n_test, n_ref, d_events,
              hr_expected, hr_margin, power, alpha,
              prop_exposed, event_rate
            )

            # Add missing data text if applicable
            if (md_vals$adjust_missing) {
              missing_text <- format_missing_data_text(missing_adj, n_base)
              result_text <- tagList(result_text, missing_text)
            }

            # Add clustering text if applicable
            if (clust_vals$adjust_clustering) {
              clustering_text <- format_clustering_text(clust_vals, n_before_clustering, n_total, de)
              result_text <- tagList(result_text, clustering_text)
            }

            HTML(as.character(result_text))

          } else {
            # Equivalence calculation
            hr_margin <- tab9_inputs$hr_margin_equiv
            hr_lower <- 1 / hr_margin
            hr_upper <- hr_margin

            # Base calculation
            n_base <- ssize_survival_equiv(
              power = power,
              hr_expected = hr_expected,
              hr_lower = hr_lower,
              hr_upper = hr_upper,
              k = prop_exposed,
              pE = event_rate,
              alpha = alpha,
              ratio = ratio
            )

            # Apply missing data adjustment
            if (md_vals$adjust_missing) {
              missing_adj <- calc_missing_data_inflation(
                n_base,
                md_vals$missing_pct,
                md_vals$missing_mechanism,
                md_vals$missing_analysis,
                md_vals$mi_imputations,
                md_vals$mi_r_squared
              )
              n_total <- missing_adj$n_inflated
            } else {
              n_total <- n_base
            }

            # Apply clustering adjustment
            if (clust_vals$adjust_clustering) {
              de <- calc_design_effect(clust_vals$cluster_size, clust_vals$icc)
              n_before_clustering <- n_total
              n_total <- ceiling(n_total * de)
            }

            # Calculate group sizes
            n_test <- ceiling(n_total / (1 + ratio))
            n_ref <- n_total - n_test

            # Calculate events (use upper margin for conservative estimate)
            d_events <- events_survival_ni(power, hr_expected, hr_upper, alpha / 2)

            # Generate result text using helper
            result_text <- create_survival_equiv_samplesize_text(
              n_total, n_test, n_ref, d_events,
              hr_expected, hr_lower, hr_upper, power, alpha,
              prop_exposed, event_rate
            )

            # Add missing data text if applicable
            if (md_vals$adjust_missing) {
              missing_text <- format_missing_data_text(missing_adj, n_base)
              result_text <- tagList(result_text, missing_text)
            }

            # Add clustering text if applicable
            if (clust_vals$adjust_clustering) {
              clustering_text <- format_clustering_text(clust_vals, n_before_clustering, n_total, de)
              result_text <- tagList(result_text, clustering_text)
            }

            HTML(as.character(result_text))
          }

        } else {
          # Calculate margin (calc_mode == "calc_margin")
          n_fixed <- tab9_inputs$n_fixed

          # Account for adjustments in reverse
          n_effective <- n_fixed
          if (md_vals$adjust_missing) {
            p_missing <- md_vals$missing_pct / 100
            n_effective <- ceiling(n_fixed * (1 - p_missing))
          }
          if (clust_vals$adjust_clustering) {
            de <- calc_design_effect(clust_vals$cluster_size, clust_vals$icc)
            n_effective <- ceiling(n_effective / de)
          }

          margin_detectable <- mde_survival_ni(
            n = n_effective,
            hr_expected = hr_expected,
            power = power,
            k = prop_exposed,
            pE = event_rate,
            alpha = alpha,
            ratio = ratio
          )

          result_text <- create_survival_ni_margin_text(
            margin_detectable, n_fixed, hr_expected,
            power, alpha, event_rate
          )

          HTML(as.character(result_text))
        }
      }
    })
  })

  ################################################################################################## EFFECT MEASURES (Two-Group and Survival)

  output$effect_measures <- renderUI({
    if (!v$doAnalysis) {
      return()
    }

    # Guard against NULL or uninitialized sidebar_page
    if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
      return(NULL)
    }

    if (!grepl("twogrp|survival", input$sidebar_page)) {
      return()
    }

    isolate({
      validate_inputs()

      if (grepl("twogrp", input$sidebar_page)) {
        if (identical(input$sidebar_page, "power_twogrp")) {
          p1 <- input$twogrp_pow_p1 / 100
          p2 <- input$twogrp_pow_p2 / 100
        } else {
          p1 <- input$twogrp_ss_p1 / 100
          p2 <- input$twogrp_ss_p2 / 100
        }

        # Calculate effect measures safely
        eff <- calc_effect_measures(p1, p2)

        text1 <- h4("Effect Measures")
        text2 <- p(paste0(
          "Risk Difference: ", format(eff$risk_diff, digits = 2, nsmall = 2), " percentage points", br(),
          "Relative Risk: ", if (is.na(eff$relative_risk)) "N/A (Group 2 rate = 0%)" else format(eff$relative_risk, digits = 3, nsmall = 3), br(),
          "Odds Ratio: ", if (is.na(eff$odds_ratio)) "N/A (rate = 0% or 100%)" else format(eff$odds_ratio, digits = 3, nsmall = 3)
        ))

        HTML(paste0(text1, text2))
      } else if (grepl("survival", input$sidebar_page)) {
        if (identical(input$sidebar_page, "power_survival")) {
          hr <- input$surv_pow_hr
        } else {
          hr <- input$surv_ss_hr
        }

        text1 <- h4("Effect Measure")
        interpretation <- if (hr < 1) {
          "protective effect (reduced hazard)"
        } else if (hr > 1) {
          "increased risk (elevated hazard)"
        } else {
          "no effect"
        }

        text2 <- p(paste0(
          "Hazard Ratio (HR): ", format(hr, digits = 3, nsmall = 3), br(),
          "Interpretation: HR = ", format(hr, digits = 3, nsmall = 3), " indicates a ", interpretation
        ))

        HTML(paste0(text1, text2))
      }
    })
  })

  ################################################################################################## PLOT TITLE

  output$figure_title <- renderUI({
    if (!v$doAnalysis) {
      return()
    }

    # Guard against NULL or uninitialized sidebar_page
    if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
      return(NULL)
    }

    if (identical(input$sidebar_page, "match_casecontrol")) {
      return()
    } # No plot for matched case-control

    isolate({
      text1 <- hr()
      if (grepl("twogrp", input$sidebar_page)) {
        if (identical(input$sidebar_page, "power_twogrp")) {
          tab2_inputs <- tab2_vals$inputs()
          ratio <- round(tab2_inputs$twogrp_pow_n2 / tab2_inputs$twogrp_pow_n1, 3)
        } else {
          tab2_inputs <- tab2_vals$inputs()
          ratio <- tab2_inputs$twogrp_ss_ratio
        }
        text2 <- h4(paste0("Estimated power vs. n1 (Group 1 sample size) with allocation ratio n2/n1 = ", ratio, "."))
      } else if (grepl("survival", input$sidebar_page)) {
        text2 <- h4("Power curve for survival analysis at different sample sizes.")
      } else {
        text2 <- h4("Estimated power for the given conditions at different sample sizes.")
      }
      HTML(paste0(text1, text2))
    })
  })

  ################################################################################################## POWER VS. SAMPLE SIZE PLOT

  output$power_plot <- renderPlotly(
    {
      if (!v$doAnalysis) {
        return()
      }
      isolate({
        # Guard against NULL or uninitialized sidebar_page
        if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
          return(NULL)
        }

        validate_inputs()

        # Tab 1: Single Proportion - Power Analysis (using sidebar_page)
        if (identical(input$sidebar_page, "power_single")) {
          tab1_inputs <- tab1_vals$inputs()
          # Generate power curve data
          n_current <- tab1_inputs$power_n
          n_seq <- generate_n_sequence(n_reference = n_current)

          pow <- vapply(n_seq, function(n) {
            pwr.p.test(
              sig.level = tab1_inputs$power_alpha, power = NULL,
              h = ES.h(1 / tab1_inputs$power_p, 0), alt = "greater", n = n
            )$power
          }, FUN.VALUE = numeric(1))

          # Create plot using helper function
          create_power_curve_plot(
            n_seq = n_seq,
            power_vals = pow,
            n_current = n_current,
            target_power = 0.8,
            plot_title = "Interactive Power Curve",
            n_reference_label = "Current N"
          )

        # Tab 1: Single Proportion - Sample Size (using sidebar_page)
        } else if (identical(input$sidebar_page, "ss_single")) {
          tab1_inputs <- tab1_vals$inputs()
          # Generate power curve data
          target_power <- tab1_inputs$ss_power / 100
          n_required <- pwr.p.test(
            sig.level = tab1_inputs$ss_alpha, power = target_power,
            h = ES.h(1 / tab1_inputs$ss_p, 0), alt = "greater", n = NULL
          )$n
          n_seq <- generate_n_sequence_for_ss(n_required = n_required)

          pow <- vapply(n_seq, function(n) {
            pwr.p.test(
              sig.level = tab1_inputs$ss_alpha, power = NULL,
              h = ES.h(1 / tab1_inputs$ss_p, 0), alt = "greater", n = n
            )$power
          }, FUN.VALUE = numeric(1))

          # Create plot using helper function
          create_power_curve_plot(
            n_seq = n_seq,
            power_vals = pow,
            n_current = n_required,
            target_power = target_power,
            plot_title = "Interactive Power Curve",
            n_reference_label = "Required N"
          )

        # Tab 2: Two-Group Comparison - Power Analysis (using sidebar_page)
        } else if (identical(input$sidebar_page, "power_twogrp")) {
          tab2_inputs <- tab2_vals$inputs()
          # Ratio-aware interactive plot for unequal allocation
          p1 <- tab2_inputs$twogrp_pow_p1 / 100
          p2 <- tab2_inputs$twogrp_pow_p2 / 100
          ratio <- tab2_inputs$twogrp_pow_n2 / tab2_inputs$twogrp_pow_n1
          n1_current <- tab2_inputs$twogrp_pow_n1

          # Generate power curve varying n1
          n1_seq <- generate_n_sequence(n_reference = n1_current, absolute_min = 5)

          pow <- vapply(n1_seq, function(n1) {
            pwr.2p2n.test(
              h = ES.h(p1, p2), n1 = n1, n2 = n1 * ratio,
              sig.level = tab2_inputs$twogrp_pow_alpha,
              alternative = tab2_inputs$twogrp_pow_sided
            )$power
          }, FUN.VALUE = numeric(1))

          # Create plot using helper function
          create_power_curve_plot_twogroup(
            n_seq = n1_seq,
            power_vals = pow,
            n_current = n1_current,
            target_power = 0.8,
            plot_title = paste0("Interactive Power Curve (n2/n1 = ", round(ratio, 3), ")"),
            per_group = TRUE
          )

        # Tab 2: Two-Group Comparison - Sample Size (using sidebar_page)
        } else if (identical(input$sidebar_page, "ss_twogrp")) {
          tab2_inputs <- tab2_vals$inputs()
          # Ratio-aware interactive plot for sample size calculation
          p1 <- tab2_inputs$twogrp_ss_p1 / 100
          p2 <- tab2_inputs$twogrp_ss_p2 / 100
          ratio <- tab2_inputs$twogrp_ss_ratio
          target <- tab2_inputs$twogrp_ss_power / 100

          # Calculate required n1
          n1_required <- solve_n1_for_ratio(
            ES.h(p1, p2), ratio,
            tab2_inputs$twogrp_ss_alpha, target, tab2_inputs$twogrp_ss_sided
          )

          # Generate power curve varying n1
          n1_seq <- seq(max(5, floor(n1_required * 0.25)), floor(n1_required * 3), length.out = 100)
          pow <- vapply(n1_seq, function(n1) {
            pwr.2p2n.test(
              h = ES.h(p1, p2), n1 = n1, n2 = n1 * ratio,
              sig.level = tab2_inputs$twogrp_ss_alpha,
              alternative = tab2_inputs$twogrp_ss_sided
            )$power
          }, FUN.VALUE = numeric(1))

          # Create interactive plotly
          plot_ly() %>%
            add_trace(
              x = n1_seq, y = pow, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3),
              name = "Power Curve",
              hovertemplate = paste0(
                "<b>n1 (Group 1):</b> %{x:.0f}<br>",
                "<b>n2 (Group 2):</b> ", round(n1_seq * ratio, 0), "<br>",
                "<b>Power:</b> %{y:.3f}<br>",
                "<extra></extra>"
              )
            ) %>%
            add_trace(
              x = range(n1_seq), y = c(target, target),
              type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"),
              name = paste0("Target Power (", round(target * 100), "%)"),
              hovertemplate = paste0("<b>Target Power:</b> ", round(target * 100), "%<extra></extra>")
            ) %>%
            add_trace(
              x = c(n1_required, n1_required), y = c(0, 1),
              type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"),
              name = "Required n1",
              hovertemplate = paste0("<b>Required n1:</b> ", round(n1_required), "<extra></extra>")
            ) %>%
            layout(
              title = list(text = paste0("Interactive Power Curve (n2/n1 = ", round(ratio, 3), ")"), font = list(size = 16)),
              xaxis = list(title = "Sample Size n1 (Group 1)", gridcolor = "#e0e0e0"),
              yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
              hovermode = "closest",
              plot_bgcolor = "#f8f9fa",
              paper_bgcolor = "white",
              legend = list(x = 0.7, y = 0.2)
            ) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)

        # Tab 3: Survival - Power Analysis (using sidebar_page)
        } else if (identical(input$sidebar_page, "power_survival")) {
          tab3_inputs <- tab3_vals$inputs()
          hr <- tab3_inputs$surv_pow_hr
          k <- tab3_inputs$surv_pow_k / 100
          pE <- tab3_inputs$surv_pow_pE / 100
          alpha <- tab3_inputs$surv_pow_alpha
          current_n <- tab3_inputs$surv_pow_n

          n_range <- seq(from = max(50, current_n * 0.5), to = current_n * 2, length.out = 50)
          power_vals <- vapply(n_range, function(n) {
            powerEpi.default(n = n, theta = hr, p = k, psi = pE, rho2 = 0, alpha = alpha)
          }, FUN.VALUE = numeric(1))

          plot_ly() %>%
            add_trace(
              x = n_range, y = power_vals, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3), name = "Power Curve",
              hovertemplate = paste0("<b>Sample Size (N):</b> %{x:.0f}<br><b>Power:</b> %{y:.3f}<br><b>HR:</b> ", round(hr, 3), "<br><extra></extra>")
            ) %>%
            add_trace(x = range(n_range), y = c(0.8, 0.8), type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"), name = "80% Power Target") %>%
            add_trace(x = c(current_n, current_n), y = c(0, 1), type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"), name = "Current N") %>%
            layout(title = list(text = "Interactive Power Curve - Survival Analysis", font = list(size = 16)),
              xaxis = list(title = "Total Sample Size (N)"), yaxis = list(title = "Power", range = c(0, 1))) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)

        # Tab 3: Survival - Sample Size (using sidebar_page)
        } else if (identical(input$sidebar_page, "ss_survival")) {
          tab3_inputs <- tab3_vals$inputs()
          hr <- tab3_inputs$surv_ss_hr
          k <- tab3_inputs$surv_ss_k / 100
          pE <- tab3_inputs$surv_ss_pE / 100
          alpha <- tab3_inputs$surv_ss_alpha
          current_n <- ssizeEpi.default(power = tab3_inputs$surv_ss_power / 100, theta = hr, p = k, psi = pE, rho2 = 0, alpha = alpha)

          n_range <- seq(from = max(50, current_n * 0.5), to = current_n * 2, length.out = 50)
          power_vals <- vapply(n_range, function(n) {
            powerEpi.default(n = n, theta = hr, p = k, psi = pE, rho2 = 0, alpha = alpha)
          }, FUN.VALUE = numeric(1))

          plot_ly() %>%
            add_trace(x = n_range, y = power_vals, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3), name = "Power Curve") %>%
            add_trace(x = range(n_range), y = c(0.8, 0.8), type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"), name = "80% Power Target") %>%
            add_trace(x = c(current_n, current_n), y = c(0, 1), type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"), name = "Required N") %>%
            layout(title = list(text = "Interactive Power Curve - Survival Analysis", font = list(size = 16)),
              xaxis = list(title = "Total Sample Size (N)"), yaxis = list(title = "Power", range = c(0, 1))) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)

        # Tab 5: Continuous - Power Analysis (using sidebar_page)
        } else if (identical(input$sidebar_page, "power_continuous")) {
          tab5_inputs <- tab5_vals$inputs()
          n1 <- tab5_inputs$cont_pow_n1
          n2 <- tab5_inputs$cont_pow_n2
          d <- tab5_inputs$cont_pow_d
          alpha <- tab5_inputs$cont_pow_alpha
          sided <- tab5_inputs$cont_pow_sided

          n1_range <- seq(from = max(5, floor(n1 * 0.25)), to = floor(n1 * 3), length.out = 100)
          power_vals <- vapply(n1_range, function(n1_val) {
            pwr.t2n.test(d = d, n1 = n1_val, n2 = n2, sig.level = alpha, alternative = sided)$power
          }, FUN.VALUE = numeric(1))

          plot_ly() %>%
            add_trace(x = n1_range, y = power_vals, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3), name = "Power Curve") %>%
            add_trace(x = range(n1_range), y = c(0.8, 0.8), type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"), name = "80% Power Target") %>%
            add_trace(x = c(n1, n1), y = c(0, 1), type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"), name = "Current n1") %>%
            layout(title = list(text = "Interactive Power Curve - Continuous Outcomes", font = list(size = 16)),
              xaxis = list(title = "Sample Size Group 1 (n1)"), yaxis = list(title = "Power", range = c(0, 1))) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)

        # Tab 5: Continuous - Sample Size (using sidebar_page)
        } else if (identical(input$sidebar_page, "ss_continuous")) {
          tab5_inputs <- tab5_vals$inputs()
          d <- tab5_inputs$cont_ss_d
          alpha <- tab5_inputs$cont_ss_alpha
          sided <- tab5_inputs$cont_ss_sided
          ratio <- tab5_inputs$cont_ss_ratio
          target_power <- tab5_inputs$cont_ss_power / 100

          n1_test <- pwr.t2n.test(d = d, n1 = NULL, n2 = NULL, sig.level = alpha, power = target_power, alternative = sided)$n1
          current_n1 <- ceiling(n1_test)

          n1_range <- seq(from = max(5, floor(current_n1 * 0.25)), to = floor(current_n1 * 3), length.out = 100)
          power_vals <- vapply(n1_range, function(n1_val) {
            pwr.t2n.test(d = d, n1 = n1_val, n2 = n1_val * ratio, sig.level = alpha, alternative = sided)$power
          }, FUN.VALUE = numeric(1))

          plot_ly() %>%
            add_trace(x = n1_range, y = power_vals, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3), name = "Power Curve") %>%
            add_trace(x = range(n1_range), y = c(0.8, 0.8), type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"), name = "80% Power Target") %>%
            add_trace(x = c(current_n1, current_n1), y = c(0, 1), type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"), name = "Required n1") %>%
            layout(title = list(text = "Interactive Power Curve - Continuous Outcomes", font = list(size = 16)),
              xaxis = list(title = "Sample Size Group 1 (n1)"), yaxis = list(title = "Power", range = c(0, 1))) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)

        } else if (identical(input$sidebar_page, "mediation_analysis")) {
          # Mediation Analysis Power Curve
          med_inputs <- tab8_vals$inputs()
          calc_mode <- med_inputs$calc_mode
          a <- med_inputs$path_a
          b <- med_inputs$path_b
          alpha <- med_inputs$med_alpha
          alternative <- med_inputs$med_sided

          if (calc_mode == "calc_power") {
            # Power curve varying N
            n_current <- med_inputs$med_n
            n_seq <- generate_mediation_n_sequence(n_current, n_points = 50)

            power_vals <- vapply(n_seq, function(n) {
              calc_mediation_power(n, a, b, alpha = alpha, alternative = alternative)
            }, FUN.VALUE = numeric(1))

            # Create power curve plot
            plot_ly() %>%
              add_trace(
                x = n_seq,
                y = power_vals * 100,
                type = "scatter",
                mode = "lines",
                line = list(color = "#2B5876", width = 3),
                name = "Power",
                hovertemplate = paste0(
                  "<b>Sample Size:</b> %{x:.0f}<br>",
                  "<b>Power:</b> %{y:.1f}%<br>",
                  "<extra></extra>"
                )
              ) %>%
              add_trace(
                x = c(n_current, n_current),
                y = c(0, 100),
                type = "scatter",
                mode = "lines",
                line = list(color = "#FF6B6B", width = 2, dash = "dash"),
                name = "Current N",
                hoverinfo = "skip",
                showlegend = TRUE
              ) %>%
              add_trace(
                x = c(min(n_seq), max(n_seq)),
                y = c(80, 80),
                type = "scatter",
                mode = "lines",
                line = list(color = "#4ECDC4", width = 2, dash = "dot"),
                name = "80% Power",
                hoverinfo = "skip",
                showlegend = TRUE
              ) %>%
              layout(
                title = paste0("Power Curve: Mediation Analysis (a=", format_numeric(a, 2), ", b=", format_numeric(b, 2), ")"),
                xaxis = list(title = "Sample Size (N)", gridcolor = "#E0E0E0"),
                yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
                hovermode = "closest",
                plot_bgcolor = "#FFFFFF",
                paper_bgcolor = "#FFFFFF"
              ) %>%
              config(displayModeBar = TRUE, displaylogo = FALSE)

          } else if (calc_mode == "calc_n") {
            # Power curve showing achieved power at different sample sizes
            power_target <- med_inputs$med_power / 100
            n_required <- calc_mediation_n(a, b, power_target, alpha, alternative)

            if (!is.na(n_required)) {
              n_seq <- seq(max(10, n_required * 0.5), n_required * 1.5, length.out = 50)

              power_vals <- vapply(n_seq, function(n) {
                calc_mediation_power(n, a, b, alpha = alpha, alternative = alternative)
              }, FUN.VALUE = numeric(1))

              plot_ly() %>%
                add_trace(
                  x = n_seq,
                  y = power_vals * 100,
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#2B5876", width = 3),
                  name = "Power",
                  hovertemplate = paste0(
                    "<b>Sample Size:</b> %{x:.0f}<br>",
                    "<b>Power:</b> %{y:.1f}%<br>",
                    "<extra></extra>"
                  )
                ) %>%
                add_trace(
                  x = c(n_required, n_required),
                  y = c(0, 100),
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#FF6B6B", width = 2, dash = "dash"),
                  name = paste0("Required N (", format_numeric(n_required, 0), ")"),
                  hoverinfo = "skip",
                  showlegend = TRUE
                ) %>%
                add_trace(
                  x = c(min(n_seq), max(n_seq)),
                  y = c(power_target * 100, power_target * 100),
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#4ECDC4", width = 2, dash = "dot"),
                  name = paste0("Target Power (", format_numeric(power_target * 100, 0), "%)"),
                  hoverinfo = "skip",
                  showlegend = TRUE
                ) %>%
                layout(
                  title = paste0("Power Curve: Required Sample Size (a=", format_numeric(a, 2), ", b=", format_numeric(b, 2), ")"),
                  xaxis = list(title = "Sample Size (N)", gridcolor = "#E0E0E0"),
                  yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
                  hovermode = "closest",
                  plot_bgcolor = "#FFFFFF",
                  paper_bgcolor = "#FFFFFF"
                ) %>%
                config(displayModeBar = TRUE, displaylogo = FALSE)
            }

          } else if (calc_mode == "calc_mde") {
            # Power curve showing power for different effect sizes
            n <- med_inputs$med_n
            power_target <- med_inputs$med_power / 100

            # Vary path b from small to large
            b_seq <- seq(0.05, 0.8, length.out = 50)

            power_vals <- vapply(b_seq, function(b_val) {
              calc_mediation_power(n, a, b_val, alpha = alpha, alternative = alternative)
            }, FUN.VALUE = numeric(1))

            b_min <- calc_mediation_mde(n, a, power_target, alpha, alternative)

            plot_ly() %>%
              add_trace(
                x = a * b_seq,  # Show indirect effect on x-axis
                y = power_vals * 100,
                type = "scatter",
                mode = "lines",
                line = list(color = "#2B5876", width = 3),
                name = "Power",
                hovertemplate = paste0(
                  "<b>Indirect Effect (a×b):</b> %{x:.3f}<br>",
                  "<b>Power:</b> %{y:.1f}%<br>",
                  "<extra></extra>"
                )
              ) %>%
              add_trace(
                x = c(a * b_min, a * b_min),
                y = c(0, 100),
                type = "scatter",
                mode = "lines",
                line = list(color = "#FF6B6B", width = 2, dash = "dash"),
                name = "Minimal Detectable",
                hoverinfo = "skip",
                showlegend = TRUE
              ) %>%
              add_trace(
                x = c(min(a * b_seq), max(a * b_seq)),
                y = c(power_target * 100, power_target * 100),
                type = "scatter",
                mode = "lines",
                line = list(color = "#4ECDC4", width = 2, dash = "dot"),
                name = paste0("Target Power (", format_numeric(power_target * 100, 0), "%)"),
                hoverinfo = "skip",
                showlegend = TRUE
              ) %>%
              layout(
                title = paste0("Power Curve: Detectable Indirect Effects (N=", format_numeric(n, 0), ")"),
                xaxis = list(title = "Indirect Effect (a × b)", gridcolor = "#E0E0E0"),
                yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
                hovermode = "closest",
                plot_bgcolor = "#FFFFFF",
                paper_bgcolor = "#FFFFFF"
              ) %>%
              config(displayModeBar = TRUE, displaylogo = FALSE)
          }

        } else if (identical(input$sidebar_page, "survival_ni_equiv")) {
          # Time-to-Event Equivalence/Non-Inferiority Power Curve
          tab9_inputs <- tab9_vals$inputs()
          test_type <- tab9_inputs$test_type
          calc_mode <- tab9_inputs$calc_mode

          if (calc_mode == "calc_n") {
            # Power curve: power vs. sample size
            power_target <- tab9_inputs$power / 100
            hr_expected <- tab9_inputs$hr_expected
            prop_exposed <- tab9_inputs$prop_exposed / 100
            event_rate <- tab9_inputs$event_rate / 100
            ratio <- tab9_inputs$allocation_ratio
            alpha <- tab9_inputs$alpha

            if (test_type == "non-inferiority") {
              hr_margin <- tab9_inputs$hr_margin_ni

              # Calculate required N for reference
              n_required <- ssize_survival_ni(
                power = power_target,
                hr_expected = hr_expected,
                hr_margin = hr_margin,
                k = prop_exposed,
                pE = event_rate,
                alpha = alpha,
                ratio = ratio
              )

              # Generate sample size sequence
              n_seq <- seq(max(50, n_required * 0.5), n_required * 1.5, length.out = 50)

              power_vals <- vapply(n_seq, function(n) {
                power_survival_ni(
                  n = n,
                  hr_expected = hr_expected,
                  hr_margin = hr_margin,
                  k = prop_exposed,
                  pE = event_rate,
                  alpha = alpha,
                  ratio = ratio
                )
              }, FUN.VALUE = numeric(1))

              plot_ly() %>%
                add_trace(
                  x = n_seq,
                  y = power_vals * 100,
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#2B5876", width = 3),
                  name = "Power",
                  hovertemplate = paste0(
                    "<b>Sample Size:</b> %{x:.0f}<br>",
                    "<b>Power:</b> %{y:.1f}%<br>",
                    "<extra></extra>"
                  )
                ) %>%
                add_trace(
                  x = c(n_required, n_required),
                  y = c(0, 100),
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#FF6B6B", width = 2, dash = "dash"),
                  name = paste0("Required N (", format_numeric(n_required, 0), ")"),
                  hoverinfo = "skip",
                  showlegend = TRUE
                ) %>%
                add_trace(
                  x = c(min(n_seq), max(n_seq)),
                  y = c(power_target * 100, power_target * 100),
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#4ECDC4", width = 2, dash = "dot"),
                  name = paste0("Target Power (", format_numeric(power_target * 100, 0), "%)"),
                  hoverinfo = "skip",
                  showlegend = TRUE
                ) %>%
                layout(
                  title = paste0("Power Curve: Non-Inferiority Test (HR=", format_numeric(hr_expected, 2), ", Margin=", format_numeric(hr_margin, 2), ")"),
                  xaxis = list(title = "Total Sample Size (N)", gridcolor = "#E0E0E0"),
                  yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
                  hovermode = "closest",
                  plot_bgcolor = "#FFFFFF",
                  paper_bgcolor = "#FFFFFF"
                ) %>%
                config(displayModeBar = TRUE, displaylogo = FALSE)

            } else {
              # Equivalence test
              hr_margin <- tab9_inputs$hr_margin_equiv
              hr_lower <- 1 / hr_margin
              hr_upper <- hr_margin

              # Calculate required N for reference
              n_required <- ssize_survival_equiv(
                power = power_target,
                hr_expected = hr_expected,
                hr_lower = hr_lower,
                hr_upper = hr_upper,
                k = prop_exposed,
                pE = event_rate,
                alpha = alpha,
                ratio = ratio
              )

              # Generate sample size sequence
              n_seq <- seq(max(50, n_required * 0.5), n_required * 1.5, length.out = 50)

              # For equivalence, calculate power as minimum of both tests
              power_vals <- vapply(n_seq, function(n) {
                p_upper <- power_survival_ni(n, hr_expected, hr_upper, prop_exposed, event_rate, alpha/2, ratio)
                p_lower <- power_survival_ni(n, 1/hr_expected, 1/hr_lower, prop_exposed, event_rate, alpha/2, ratio)
                min(p_upper, p_lower)
              }, FUN.VALUE = numeric(1))

              plot_ly() %>%
                add_trace(
                  x = n_seq,
                  y = power_vals * 100,
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#2B5876", width = 3),
                  name = "Power",
                  hovertemplate = paste0(
                    "<b>Sample Size:</b> %{x:.0f}<br>",
                    "<b>Power:</b> %{y:.1f}%<br>",
                    "<extra></extra>"
                  )
                ) %>%
                add_trace(
                  x = c(n_required, n_required),
                  y = c(0, 100),
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#FF6B6B", width = 2, dash = "dash"),
                  name = paste0("Required N (", format_numeric(n_required, 0), ")"),
                  hoverinfo = "skip",
                  showlegend = TRUE
                ) %>%
                add_trace(
                  x = c(min(n_seq), max(n_seq)),
                  y = c(power_target * 100, power_target * 100),
                  type = "scatter",
                  mode = "lines",
                  line = list(color = "#4ECDC4", width = 2, dash = "dot"),
                  name = paste0("Target Power (", format_numeric(power_target * 100, 0), "%)"),
                  hoverinfo = "skip",
                  showlegend = TRUE
                ) %>%
                layout(
                  title = paste0("Power Curve: Equivalence Test (HR=", format_numeric(hr_expected, 2), ", Margins=[", format_numeric(hr_lower, 2), ", ", format_numeric(hr_upper, 2), "])"),
                  xaxis = list(title = "Total Sample Size (N)", gridcolor = "#E0E0E0"),
                  yaxis = list(title = "Power (%)", gridcolor = "#E0E0E0", range = c(0, 100)),
                  hovermode = "closest",
                  plot_bgcolor = "#FFFFFF",
                  paper_bgcolor = "#FFFFFF"
                ) %>%
                config(displayModeBar = TRUE, displaylogo = FALSE)
            }

          } else {
            # Margin calculation mode: show margin vs. sample size
            n_fixed <- tab9_inputs$n_fixed
            hr_expected <- tab9_inputs$hr_expected
            power_target <- tab9_inputs$power / 100
            prop_exposed <- tab9_inputs$prop_exposed / 100
            event_rate <- tab9_inputs$event_rate / 100
            ratio <- tab9_inputs$allocation_ratio
            alpha <- tab9_inputs$alpha

            # Generate sample size sequence around fixed N
            n_seq <- seq(max(50, n_fixed * 0.5), n_fixed * 1.5, length.out = 50)

            margin_vals <- vapply(n_seq, function(n) {
              mde_survival_ni(n, hr_expected, power_target, prop_exposed, event_rate, alpha, ratio)
            }, FUN.VALUE = numeric(1))

            plot_ly() %>%
              add_trace(
                x = n_seq,
                y = margin_vals,
                type = "scatter",
                mode = "lines",
                line = list(color = "#2B5876", width = 3),
                name = "Detectable Margin",
                hovertemplate = paste0(
                  "<b>Sample Size:</b> %{x:.0f}<br>",
                  "<b>Margin (HR):</b> %{y:.3f}<br>",
                  "<extra></extra>"
                )
              ) %>%
              add_trace(
                x = c(n_fixed, n_fixed),
                y = c(min(margin_vals) * 0.95, max(margin_vals) * 1.05),
                type = "scatter",
                mode = "lines",
                line = list(color = "#FF6B6B", width = 2, dash = "dash"),
                name = paste0("Available N (", format_numeric(n_fixed, 0), ")"),
                hoverinfo = "skip",
                showlegend = TRUE
              ) %>%
              layout(
                title = paste0("Minimal Detectable Margin (N=", format_numeric(n_fixed, 0), ", Power=", format_numeric(power_target * 100, 0), "%)"),
                xaxis = list(title = "Total Sample Size (N)", gridcolor = "#E0E0E0"),
                yaxis = list(title = "Detectable NI Margin (HR)", gridcolor = "#E0E0E0"),
                hovermode = "closest",
                plot_bgcolor = "#FFFFFF",
                paper_bgcolor = "#FFFFFF"
              ) %>%
              config(displayModeBar = TRUE, displaylogo = FALSE)
          }
        }
      })
    }
  ) %>%
    bindCache(
      input$sidebar_page,
      # Single Proportion inputs
      input$power_n, input$power_p, input$power_alpha,
      input$ss_power, input$ss_p, input$ss_alpha,
      # Two-Group inputs
      input$twogrp_pow_n1, input$twogrp_pow_n2, input$twogrp_pow_p1, input$twogrp_pow_p2,
      input$twogrp_pow_alpha, input$twogrp_pow_sided,
      input$twogrp_ss_p1, input$twogrp_ss_p2, input$twogrp_ss_ratio,
      input$twogrp_ss_alpha, input$twogrp_ss_sided, input$twogrp_ss_power,
      # Survival inputs
      input$surv_pow_n, input$surv_pow_hr, input$surv_pow_k, input$surv_pow_pE, input$surv_pow_alpha,
      input$surv_ss_hr, input$surv_ss_k, input$surv_ss_pE, input$surv_ss_alpha, input$surv_ss_power,
      # Continuous Outcomes inputs
      input$cont_pow_n1, input$cont_pow_n2, input$cont_pow_d, input$cont_pow_alpha, input$cont_pow_sided,
      input$cont_ss_d, input$cont_ss_alpha, input$cont_ss_sided, input$cont_ss_ratio, input$cont_ss_power,
      # Matched Case-Control inputs
      input$match_calc_mode, input$match_or, input$match_n_pairs_fixed, input$match_p0,
      input$match_ratio, input$match_power, input$match_alpha, input$match_sided,
      # Non-Inferiority inputs
      input$noninf_calc_mode, input$noninf_p1, input$noninf_p2, input$noninf_margin,
      input$noninf_n1_fixed, input$noninf_ratio, input$noninf_power, input$noninf_alpha,
      # VIF Calculator inputs
      input$vif_n_rct, input$vif_prevalence, input$vif_cstat, input$vif_method,
      # Mediation Analysis inputs
      input$`tab8-calc_mode`, input$`tab8-path_a`, input$`tab8-path_b`, input$`tab8-path_c_prime`,
      input$`tab8-med_n`, input$`tab8-med_power`, input$`tab8-med_alpha`, input$`tab8-med_sided`,
      input$`tab8-se_a`, input$`tab8-se_b`,
      # Survival NI/Equivalence inputs
      input$`tab9-test_type`, input$`tab9-calc_mode`, input$`tab9-power`, input$`tab9-hr_expected`,
      input$`tab9-hr_margin_ni`, input$`tab9-hr_margin_equiv`, input$`tab9-n_fixed`,
      input$`tab9-prop_exposed`, input$`tab9-event_rate`, input$`tab9-allocation_ratio`, input$`tab9-alpha`,
      # Include doAnalysis flag to invalidate cache when Calculate is pressed
      v$doAnalysis
    )

  ################################################################################################## TABLE TITLE

  output$table_title <- renderUI({
    if (!v$doAnalysis) {
      return()
    }

    # Guard against NULL or uninitialized sidebar_page
    if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
      return(NULL)
    }

    if (grepl("twogrp", input$sidebar_page)) {
      return()
    } # Only show for single proportion

    isolate({
      validate_inputs()

      if (identical(input$sidebar_page, "power_single")) {
        tab1_inputs <- tab1_vals$inputs()
        sample_size <- tab1_inputs$power_n
      } else if (identical(input$sidebar_page, "ss_single")) {
        tab1_inputs <- tab1_vals$inputs()
        sample_size <- pwr.p.test(
          sig.level = tab1_inputs$ss_alpha, 
          power = tab1_inputs$ss_power / 100,
          h = ES.h(1 / tab1_inputs$ss_p, 0), 
          alt = "greater", 
          n = NULL
        )$n
      } else {
        return(NULL)
      }

      text1 <- hr()
      text2 <- h5("In addition, if ", ceiling(sample_size), " participants are included, the event rate would be estimated to an accuracy shown in the table below:")
      text3 <- h4(paste0(
        "95% Confidence Interval around expected event rate(s) with a sample size of ",
        ceiling(sample_size), " participants."
      ))
      HTML(paste0(text1, text2, text3))
    })
  })

  ################################################################################################## CONFIDENCE INTERVAL TABLE

  output$result_table <- renderDataTable(
    {
      if (!v$doAnalysis) {
        return()
      }

      # Guard against NULL or uninitialized sidebar_page
      if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
        return(NULL)
      }

      if (grepl("twogrp", input$sidebar_page)) {
        return()
      } # Only show for single proportion

      isolate({
        validate_inputs()

        if (identical(input$sidebar_page, "power_single")) {
          tab1_inputs <- tab1_vals$inputs()
          sample_size <- tab1_inputs$power_n
        } else if (identical(input$sidebar_page, "ss_single")) {
          tab1_inputs <- tab1_vals$inputs()
          sample_size <- pwr.p.test(
            sig.level = tab1_inputs$ss_alpha, 
            power = tab1_inputs$ss_power / 100,
            h = ES.h(1 / tab1_inputs$ss_p, 0), 
            alt = "greater", 
            n = NULL
          )$n
        } else {
          return(NULL)
        }

        sequence <- unique(c(
          seq(0, 5), seq(10, 25, by = 5), seq(50, min(round(sample_size, 0), 1000), by = 50),
          seq(min(round(sample_size, 0), 1000), min(round(sample_size, 0), 10000), by = 1000)
        ))
        bb <- lapply(sequence, function(n) {
          binom.confint(n, sample_size, conf.level = 0.95, methods = "exact")
        })

        table <- do.call(rbind, bb)
        table$length <- table$upper - table$lower
        var <- c("mean", "lower", "upper", "length")
        for (i in var) {
          table[, i] <- round(table[, i] * 100, 1)
        }
        table <- table[, c(2, 4:7)]
        table
      })
    },
    options = list(columns = list(
      list(title = "Number of Events Observed"),
      list(title = "Event Rate<sup>1</sup>"),
      list(title = "Lower Limit<sup>2</sup>"),
      list(title = "Upper Limit<sup>2</sup>"),
      list(title = "Length")
    ), paging = TRUE, searching = FALSE, processing = FALSE)
  )

  ################################################################################################## TABLE FOOTNOTES

  output$table_footnotes <- renderUI({
    if (!v$doAnalysis) {
      return()
    }

    # Guard against NULL or uninitialized sidebar_page
    if (is.null(input$sidebar_page) || length(input$sidebar_page) == 0) {
      return(NULL)
    }

    if (grepl("twogrp", input$sidebar_page)) {
      return()
    } # Only show for single proportion

    isolate({
      text1 <- h6("(1) Event rate (%) is estimated as a crude rate, defined as the number of participants exposed and experiencing the event of interest divided by the total number of participants.")
      text2 <- h6("(2) Confidence interval (%) based on exact Clopper-Pearson method for one proportion.")
      HTML(paste0(text1, text2))
    })
  })

  ################################################################################################## DOWNLOAD BUTTONS

  output$download_buttons <- renderUI({
    if (!v$doAnalysis) {
      return()
    }

    isolate({
      text1 <- hr()
      text2 <- downloadButton("report_pdf", "Download Analysis (PDF)")
      text3 <- downloadButton("report_csv", "Download Results (CSV)", class = "btn-info")
      text4 <- hr()
      HTML(paste0(text1, " ", text2, " ", text3, " ", text4))
    })
  })

  ################################################################################################## CSV DOWNLOAD

  output$report_csv <- downloadHandler(
    filename = function() {
      paste("Power-Analysis-", get_page_display_name(input$sidebar_page), "-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      if (identical(input$sidebar_page, "power_single")) {
        tab1_inputs <- tab1_vals$inputs()
        results <- data.frame(
          Analysis_Type = "Single Proportion - Power Calculation",
          Sample_Size = tab1_inputs$power_n,
          Event_Frequency_1_in = tab1_inputs$power_p,
          Event_Rate_Percent = 100 / tab1_inputs$power_p,
          Power_Percent = pwr.p.test(
            sig.level = tab1_inputs$power_alpha, power = NULL,
            h = ES.h(1 / tab1_inputs$power_p, 0), alt = "greater",
            n = tab1_inputs$power_n
          )$power * 100,
          Significance_Level = tab1_inputs$power_alpha,
          Discontinuation_Rate_Percent = tab1_inputs$power_discon,
          Adjusted_Sample_Size = ceiling(tab1_inputs$power_n * (1 + tab1_inputs$power_discon / 100)),
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "ss_single")) {
        tab1_inputs <- tab1_vals$inputs()
        sample_size <- pwr.p.test(
          sig.level = tab1_inputs$ss_alpha, power = tab1_inputs$ss_power / 100,
          h = ES.h(1 / tab1_inputs$ss_p, 0), alt = "greater", n = NULL
        )$n
        results <- data.frame(
          Analysis_Type = "Single Proportion - Sample Size Calculation",
          Desired_Power_Percent = tab1_inputs$ss_power,
          Event_Frequency_1_in = tab1_inputs$ss_p,
          Event_Rate_Percent = 100 / tab1_inputs$ss_p,
          Required_Sample_Size = ceiling(sample_size),
          Significance_Level = tab1_inputs$ss_alpha,
          Discontinuation_Rate_Percent = tab1_inputs$ss_discon,
          Adjusted_Sample_Size = ceiling(sample_size * (1 + tab1_inputs$ss_discon / 100)),
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "power_twogrp")) {
        p1 <- input$twogrp_pow_p1 / 100
        p2 <- input$twogrp_pow_p2 / 100
        power <- pwr.2p2n.test(
          h = ES.h(p1, p2), n1 = input$twogrp_pow_n1, n2 = input$twogrp_pow_n2,
          sig.level = input$twogrp_pow_alpha,
          alternative = input$twogrp_pow_sided
        )$power
        eff <- calc_effect_measures(p1, p2)
        results <- data.frame(
          Analysis_Type = "Two-Group Comparison - Power Calculation",
          Sample_Size_Group1 = input$twogrp_pow_n1,
          Sample_Size_Group2 = input$twogrp_pow_n2,
          Event_Rate_Group1_Percent = input$twogrp_pow_p1,
          Event_Rate_Group2_Percent = input$twogrp_pow_p2,
          Power_Percent = power * 100,
          Significance_Level = input$twogrp_pow_alpha,
          Test_Type = input$twogrp_pow_sided,
          Risk_Difference = eff$risk_diff,
          Relative_Risk = eff$relative_risk,
          Odds_Ratio = eff$odds_ratio,
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "ss_twogrp")) {
        p1 <- input$twogrp_ss_p1 / 100
        p2 <- input$twogrp_ss_p2 / 100
        n1 <- solve_n1_for_ratio(
          ES.h(p1, p2), input$twogrp_ss_ratio,
          input$twogrp_ss_alpha, input$twogrp_ss_power / 100,
          input$twogrp_ss_sided
        )
        n2 <- n1 * input$twogrp_ss_ratio
        eff <- calc_effect_measures(p1, p2)
        results <- data.frame(
          Analysis_Type = "Two-Group Comparison - Sample Size Calculation",
          Desired_Power_Percent = input$twogrp_ss_power,
          Event_Rate_Group1_Percent = input$twogrp_ss_p1,
          Event_Rate_Group2_Percent = input$twogrp_ss_p2,
          Required_Sample_Size_Group1 = ceiling(n1),
          Required_Sample_Size_Group2 = ceiling(n2),
          Total_Sample_Size = ceiling(n1 + n2),
          Allocation_Ratio = input$twogrp_ss_ratio,
          Significance_Level = input$twogrp_ss_alpha,
          Test_Type = input$twogrp_ss_sided,
          Risk_Difference = eff$risk_diff,
          Relative_Risk = eff$relative_risk,
          Odds_Ratio = eff$odds_ratio,
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "power_survival")) {
        n <- input$surv_pow_n
        hr <- input$surv_pow_hr
        k <- input$surv_pow_k / 100
        pE <- input$surv_pow_pE / 100
        power <- powerEpi.default(n = n, theta = hr, p = k, psi = pE, rho2 = 0, alpha = input$surv_pow_alpha)
        results <- data.frame(
          Analysis_Type = "Survival Analysis - Power Calculation",
          Total_Sample_Size = n,
          Hazard_Ratio = hr,
          Proportion_Exposed_Percent = input$surv_pow_k,
          Overall_Event_Rate_Percent = input$surv_pow_pE,
          Power_Percent = power * 100,
          Significance_Level = input$surv_pow_alpha,
          Method = "Schoenfeld (1983)",
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "ss_survival")) {
        hr <- input$surv_ss_hr
        k <- input$surv_ss_k / 100
        pE <- input$surv_ss_pE / 100
        power <- input$surv_ss_power / 100
        n_est <- ssizeEpi.default(power = power, theta = hr, p = k, psi = pE, rho2 = 0, alpha = input$surv_ss_alpha)
        results <- data.frame(
          Analysis_Type = "Survival Analysis - Sample Size Calculation",
          Desired_Power_Percent = input$surv_ss_power,
          Hazard_Ratio = hr,
          Proportion_Exposed_Percent = input$surv_ss_k,
          Overall_Event_Rate_Percent = input$surv_ss_pE,
          Required_Total_Sample_Size = ceiling(n_est),
          Significance_Level = input$surv_ss_alpha,
          Method = "Schoenfeld (1983)",
          Date = Sys.Date()
        )
        } else if (identical(input$sidebar_page, "match_casecontrol")) {
        or <- input$match_or
        p0 <- input$match_p0 / 100
        m <- input$match_ratio
        power <- input$match_power / 100
        sided_val <- ifelse(input$match_sided == "two.sided", 2, 1)
        result <- epi.sscc(
          OR = or, p0 = p0, n = NA, power = power,
          r = m, rho = 0, design = 1, sided.test = sided_val,
          conf.level = 1 - input$match_alpha
        )
        n_cases <- ceiling(result$n.total)
        results <- data.frame(
          Analysis_Type = "Matched Case-Control - Sample Size Calculation",
          Desired_Power_Percent = input$match_power * 100,
          Odds_Ratio = or,
          Exposure_Prob_Controls_Percent = input$match_p0,
          Controls_Per_Case = m,
          Required_Cases = n_cases,
          Required_Controls = n_cases * m,
          Total_Sample_Size = n_cases * (1 + m),
          Significance_Level = input$match_alpha,
          Test_Type = input$match_sided,
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "power_continuous")) {
        n1 <- input$cont_pow_n1
        n2 <- input$cont_pow_n2
        d <- input$cont_pow_d
        power <- pwr.t2n.test(
          n1 = n1, n2 = n2, d = d,
          sig.level = input$cont_pow_alpha,
          alternative = input$cont_pow_sided
        )$power
        results <- data.frame(
          Analysis_Type = "Continuous Outcomes - Power Calculation",
          Sample_Size_Group1 = n1,
          Sample_Size_Group2 = n2,
          Effect_Size_Cohens_d = d,
          Power_Percent = power * 100,
          Significance_Level = input$cont_pow_alpha,
          Test_Type = input$cont_pow_sided,
          Date = Sys.Date()
        )
      } else if (identical(input$sidebar_page, "ss_continuous")) {
        d <- input$cont_ss_d
        power <- input$cont_ss_power / 100
        ratio <- input$cont_ss_ratio
        if (ratio == 1) {
          n <- pwr.t.test(
            d = d, sig.level = input$cont_ss_alpha,
            power = power, type = "two.sample",
            alternative = input$cont_ss_sided
          )$n
          n1 <- n
          n2 <- n
        } else {
          f <- function(n1) {
            n2 <- n1 * ratio
            pwr.t2n.test(
              n1 = n1, n2 = n2, d = d,
              sig.level = input$cont_ss_alpha,
              alternative = input$cont_ss_sided
            )$power - power
          }
          n1 <- tryCatch(
            {
              uniroot(f, c(2, 1e6), extendInt = "yes")$root
            },
            error = function(e) {
              pwr.t.test(
                d = d, sig.level = input$cont_ss_alpha,
                power = power, type = "two.sample",
                alternative = input$cont_ss_sided
              )$n
            }
          )
          n2 <- n1 * ratio
        }
        results <- data.frame(
          Analysis_Type = "Continuous Outcomes - Sample Size Calculation",
          Desired_Power_Percent = input$cont_ss_power,
          Effect_Size_Cohens_d = d,
          Required_Sample_Size_Group1 = ceiling(n1),
          Required_Sample_Size_Group2 = ceiling(n2),
          Total_Sample_Size = ceiling(n1 + n2),
          Allocation_Ratio = ratio,
          Significance_Level = input$cont_ss_alpha,
          Test_Type = input$cont_ss_sided,
          Date = Sys.Date()
        )
        } else if (identical(input$sidebar_page, "noninf")) {
        p1 <- input$noninf_p1 / 100
        p2 <- input$noninf_p2 / 100
        margin <- input$noninf_margin / 100
        power <- input$noninf_power / 100
        ratio <- input$noninf_ratio
        h <- ES.h(p1, p2 + margin)
        if (ratio == 1) {
          n <- pwr.2p.test(
            h = abs(h), sig.level = input$noninf_alpha,
            power = power, alternative = "less"
          )$n
          n1 <- n
          n2 <- n
        } else {
          f <- function(n1) {
            n2 <- n1 * ratio
            pwr.2p2n.test(
              h = abs(h), n1 = n1, n2 = n2,
              sig.level = input$noninf_alpha,
              alternative = "less"
            )$power - power
          }
          n1 <- tryCatch(
            {
              uniroot(f, c(2, 1e6), extendInt = "yes")$root
            },
            error = function(e) {
              pwr.2p.test(
                h = abs(h), sig.level = input$noninf_alpha,
                power = power, alternative = "less"
              )$n
            }
          )
          n2 <- n1 * ratio
        }
        results <- data.frame(
          Analysis_Type = "Non-Inferiority - Sample Size Calculation",
          Desired_Power_Percent = input$noninf_power,
          Event_Rate_Test_Percent = input$noninf_p1,
          Event_Rate_Reference_Percent = input$noninf_p2,
          Non_Inferiority_Margin_Percent = input$noninf_margin,
          Required_Sample_Size_Test = ceiling(n1),
          Required_Sample_Size_Reference = ceiling(n2),
          Total_Sample_Size = ceiling(n1 + n2),
          Allocation_Ratio = ratio,
          Significance_Level = input$noninf_alpha,
          Date = Sys.Date()
        )

      } else if (identical(input$sidebar_page, "survival_ni_equiv")) {
        tab9_inputs <- tab9_vals$inputs()
        test_type <- tab9_inputs$test_type
        calc_mode <- tab9_inputs$calc_mode

        if (calc_mode == "calc_n") {
          power <- tab9_inputs$power / 100
          hr_expected <- tab9_inputs$hr_expected
          prop_exposed <- tab9_inputs$prop_exposed / 100
          event_rate <- tab9_inputs$event_rate / 100
          ratio <- tab9_inputs$allocation_ratio
          alpha <- tab9_inputs$alpha

          if (test_type == "non-inferiority") {
            hr_margin <- tab9_inputs$hr_margin_ni

            n_total <- ssize_survival_ni(
              power = power,
              hr_expected = hr_expected,
              hr_margin = hr_margin,
              k = prop_exposed,
              pE = event_rate,
              alpha = alpha,
              ratio = ratio
            )

            n_test <- ceiling(n_total / (1 + ratio))
            n_ref <- n_total - n_test
            d_events <- events_survival_ni(power, hr_expected, hr_margin, alpha)

            results <- data.frame(
              Analysis_Type = "Time-to-Event Non-Inferiority - Sample Size",
              Test_Type = "Non-Inferiority (one-sided)",
              Expected_HR = hr_expected,
              NI_Margin_HR = hr_margin,
              Desired_Power_Percent = tab9_inputs$power,
              Significance_Level = alpha,
              Prop_Exposed_Percent = tab9_inputs$prop_exposed,
              Event_Rate_Percent = tab9_inputs$event_rate,
              Allocation_Ratio = ratio,
              Total_Sample_Size = n_total,
              Sample_Size_Test = n_test,
              Sample_Size_Reference = n_ref,
              Required_Events = d_events,
              Date = Sys.Date()
            )

          } else {
            hr_margin <- tab9_inputs$hr_margin_equiv
            hr_lower <- 1 / hr_margin
            hr_upper <- hr_margin

            n_total <- ssize_survival_equiv(
              power = power,
              hr_expected = hr_expected,
              hr_lower = hr_lower,
              hr_upper = hr_upper,
              k = prop_exposed,
              pE = event_rate,
              alpha = alpha,
              ratio = ratio
            )

            n_test <- ceiling(n_total / (1 + ratio))
            n_ref <- n_total - n_test
            d_events <- events_survival_ni(power, hr_expected, hr_upper, alpha / 2)

            results <- data.frame(
              Analysis_Type = "Time-to-Event Equivalence - Sample Size",
              Test_Type = "Equivalence (TOST)",
              Expected_HR = hr_expected,
              Equiv_Margin_Lower_HR = hr_lower,
              Equiv_Margin_Upper_HR = hr_upper,
              Desired_Power_Percent = tab9_inputs$power,
              Significance_Level = alpha,
              Prop_Exposed_Percent = tab9_inputs$prop_exposed,
              Event_Rate_Percent = tab9_inputs$event_rate,
              Allocation_Ratio = ratio,
              Total_Sample_Size = n_total,
              Sample_Size_Test = n_test,
              Sample_Size_Reference = n_ref,
              Required_Events = d_events,
              Date = Sys.Date()
            )
          }

        } else {
          # Margin calculation
          n_fixed <- tab9_inputs$n_fixed
          hr_expected <- tab9_inputs$hr_expected
          power <- tab9_inputs$power / 100
          prop_exposed <- tab9_inputs$prop_exposed / 100
          event_rate <- tab9_inputs$event_rate / 100
          ratio <- tab9_inputs$allocation_ratio
          alpha <- tab9_inputs$alpha

          margin_detectable <- mde_survival_ni(
            n = n_fixed,
            hr_expected = hr_expected,
            power = power,
            k = prop_exposed,
            pE = event_rate,
            alpha = alpha,
            ratio = ratio
          )

          results <- data.frame(
            Analysis_Type = "Time-to-Event NI/Equivalence - Margin Calculation",
            Test_Type = tab9_inputs$test_type,
            Available_Sample_Size = n_fixed,
            Expected_HR = hr_expected,
            Detectable_Margin_HR = margin_detectable,
            Desired_Power_Percent = tab9_inputs$power,
            Significance_Level = alpha,
            Prop_Exposed_Percent = tab9_inputs$prop_exposed,
            Event_Rate_Percent = tab9_inputs$event_rate,
            Allocation_Ratio = ratio,
            Date = Sys.Date()
          )
        }
      }

      write.csv(results, file, row.names = FALSE)
    }
  )

  ################################################################################################## PDF DOWNLOAD (original)

  output$report_pdf <- downloadHandler(
    filename = paste("Rule-of-3-Analysis-", Sys.Date(), ".pdf", sep = ""),
    content = function(file) {
      tryCatch({
        # Only works for single proportion analyses
        if (grepl("twogrp", input$sidebar_page)) {
          showNotification("PDF export not yet available for two-group analyses. Please use CSV export.",
            type = "warning", duration = 5
          )
          return()
        }

        tab1_inputs <- tab1_vals$inputs()
        
        # Safe comparison using identical() to avoid comparison errors
        is_power_single <- identical(input$sidebar_page, "power_single")
        
        incidence_rate <- if (is_power_single) {
          tab1_inputs$power_p
        } else {
          tab1_inputs$ss_p
        }
        
        sample_size <- if (is_power_single) {
          tab1_inputs$power_n
        } else {
          pwr.p.test(
            sig.level = tab1_inputs$ss_alpha, power = tab1_inputs$ss_power / 100,
            h = ES.h(1 / tab1_inputs$ss_p, 0), alt = "greater", n = NULL
          )$n
        }

        power <- if (is_power_single) {
          pwr.p.test(
            sig.level = tab1_inputs$power_alpha, power = NULL,
            h = ES.h(1 / tab1_inputs$power_p, 0), alt = "greater", n = tab1_inputs$power_n
          )$power
        } else {
          tab1_inputs$ss_power / 100
        }

        discon <- if (is_power_single) {
          tab1_inputs$power_discon / 100
        } else {
          tab1_inputs$ss_discon / 100
        }

        # Copy the report file to a temporary directory
        tempReport <- file.path(tempdir(), "analysis-report.Rmd")
        file.copy("analysis-report.Rmd", tempReport, overwrite = TRUE)

        # Create a Progress object
        progress <- shiny::Progress$new(style = "notification")
        on.exit(progress$close())
        progress$set(message = "Creating Analysis Report File", value = 0)

        # Set up parameters to pass to Rmd document
        params <- list(
          tabset = get_page_display_name(input$sidebar_page),
          incidence_rate = incidence_rate,
          sample_size = sample_size,
          power = power,
          discon = discon,
          adj_n = 100,
          progress = progress
        )

        # Knit the document
        rmarkdown::render(tempReport,
          output_file = file,
          params = params,
          envir = new.env(parent = globalenv())
        )
        progress$inc(1 / 6, detail = "Done!")
        
      }, error = function(e) {
        cat("PDF generation error:", e$message, "\n")
        showNotification(paste("PDF generation failed:", e$message), 
                        type = "error", duration = 10)
      })
    }
  )

  ################################################################################################## SCENARIO COMPARISON

  # Save current scenario
  observeEvent(input$save_scenario, {
    isolate({
      if (!v$doAnalysis) {
        return()
      }

      v$scenario_counter <- v$scenario_counter + 1

      if (identical(input$sidebar_page, "power_single")) {
        tab1_inputs <- tab1_vals$inputs()
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Single Prop - Power",
          Sample_Size = tab1_inputs$power_n,
          Event_Freq = paste0("1 in ", tab1_inputs$power_p),
          Power_Pct = round(pwr.p.test(
            sig.level = tab1_inputs$power_alpha, power = NULL,
            h = ES.h(1 / tab1_inputs$power_p, 0), alt = "greater",
            n = tab1_inputs$power_n
          )$power * 100, 1),
          Alpha = tab1_inputs$power_alpha,
          Disc_Rate = paste0(tab1_inputs$power_discon, "%"),
          Adj_N = ceiling(tab1_inputs$power_n * (1 + tab1_inputs$power_discon / 100)),
          stringsAsFactors = FALSE
        )
      } else if (identical(input$sidebar_page, "ss_single")) {
        tab1_inputs <- tab1_vals$inputs()
        sample_size <- pwr.p.test(
          sig.level = tab1_inputs$ss_alpha, power = tab1_inputs$ss_power / 100,
          h = ES.h(1 / tab1_inputs$ss_p, 0), alt = "greater", n = NULL
        )$n
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Single Prop - SS",
          Sample_Size = ceiling(sample_size),
          Event_Freq = paste0("1 in ", tab1_inputs$ss_p),
          Power_Pct = tab1_inputs$ss_power,
          Alpha = tab1_inputs$ss_alpha,
          Disc_Rate = paste0(tab1_inputs$ss_discon, "%"),
          Adj_N = ceiling(sample_size * (1 + tab1_inputs$ss_discon / 100)),
          stringsAsFactors = FALSE
        )
      } else if (identical(input$sidebar_page, "power_twogrp")) {
        p1 <- input$twogrp_pow_p1 / 100
        p2 <- input$twogrp_pow_p2 / 100
        power <- pwr.2p2n.test(
          h = ES.h(p1, p2), n1 = input$twogrp_pow_n1, n2 = input$twogrp_pow_n2,
          sig.level = input$twogrp_pow_alpha,
          alternative = input$twogrp_pow_sided
        )$power
        eff <- calc_effect_measures(p1, p2)
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Two-Group - Power",
          n1 = input$twogrp_pow_n1,
          n2 = input$twogrp_pow_n2,
          p1_Pct = input$twogrp_pow_p1,
          p2_Pct = input$twogrp_pow_p2,
          Power_Pct = round(power * 100, 1),
          Alpha = input$twogrp_pow_alpha,
          Test = input$twogrp_pow_sided,
          RR = if (is.na(eff$relative_risk)) NA_real_ else round(eff$relative_risk, 3),
          OR = if (is.na(eff$odds_ratio)) NA_real_ else round(eff$odds_ratio, 3),
          stringsAsFactors = FALSE
        )
      } else if (identical(input$sidebar_page, "ss_twogrp")) {
        p1 <- input$twogrp_ss_p1 / 100
        p2 <- input$twogrp_ss_p2 / 100
        n1 <- solve_n1_for_ratio(
          ES.h(p1, p2), input$twogrp_ss_ratio,
          input$twogrp_ss_alpha, input$twogrp_ss_power / 100,
          input$twogrp_ss_sided
        )
        n2 <- n1 * input$twogrp_ss_ratio
        eff <- calc_effect_measures(p1, p2)
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Two-Group - SS",
          n1 = ceiling(n1),
          n2 = ceiling(n2),
          p1_Pct = input$twogrp_ss_p1,
          p2_Pct = input$twogrp_ss_p2,
          Power_Pct = input$twogrp_ss_power,
          Alpha = input$twogrp_ss_alpha,
          Test = input$twogrp_ss_sided,
          RR = if (is.na(eff$relative_risk)) NA_real_ else round(eff$relative_risk, 3),
          OR = if (is.na(eff$odds_ratio)) NA_real_ else round(eff$odds_ratio, 3),
          stringsAsFactors = FALSE
        )
      } else if (identical(input$sidebar_page, "power_survival")) {
        n <- input$surv_pow_n
        hr <- input$surv_pow_hr
        k <- input$surv_pow_k / 100
        pE <- input$surv_pow_pE / 100
        power <- powerEpi.default(n = n, theta = hr, p = k, psi = pE, rho2 = 0, alpha = input$surv_pow_alpha)
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Survival - Power",
          Total_N = n,
          HR = hr,
          Prop_Exposed_Pct = input$surv_pow_k,
          Event_Rate_Pct = input$surv_pow_pE,
          Power_Pct = round(power * 100, 1),
          Alpha = input$surv_pow_alpha,
          stringsAsFactors = FALSE
        )
      } else if (identical(input$sidebar_page, "ss_survival")) {
        hr <- input$surv_ss_hr
        k <- input$surv_ss_k / 100
        pE <- input$surv_ss_pE / 100
        power <- input$surv_ss_power / 100
        n_est <- ssizeEpi.default(power = power, theta = hr, p = k, psi = pE, rho2 = 0, alpha = input$surv_ss_alpha)
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Survival - SS",
          Total_N = ceiling(n_est),
          HR = hr,
          Prop_Exposed_Pct = input$surv_ss_k,
          Event_Rate_Pct = input$surv_ss_pE,
          Power_Pct = input$surv_ss_power,
          Alpha = input$surv_ss_alpha,
          stringsAsFactors = FALSE
        )
        } else if (identical(input$sidebar_page, "match_casecontrol")) {
        or <- input$match_or
        p0 <- input$match_p0 / 100
        m <- input$match_ratio
        power <- input$match_power / 100
        sided_val <- ifelse(input$match_sided == "two.sided", 2, 1)
        result <- epi.sscc(
          OR = or, p0 = p0, n = NA, power = power,
          r = m, rho = 0, design = 1, sided.test = sided_val,
          conf.level = 1 - input$match_alpha
        )
        n_cases <- ceiling(result$n.total)
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Matched CC",
          OR = or,
          Exposure_Pct = input$match_p0,
          Controls_Per_Case = m,
          Cases = n_cases,
          Controls = n_cases * m,
          Total_N = n_cases * (1 + m),
          Power_Pct = input$match_power,
          Alpha = input$match_alpha,
          stringsAsFactors = FALSE
        )
      }

      # Add to scenarios dataframe
      if (nrow(v$scenarios) == 0) {
        v$scenarios <- new_scenario
      } else {
        # Check if columns match, if not create new structure
        if (all(names(new_scenario) == names(v$scenarios))) {
          v$scenarios <- rbind(v$scenarios, new_scenario)
        } else {
          # Different analysis types - merge with common columns
          all_cols <- union(names(v$scenarios), names(new_scenario))
          for (col in all_cols) {
            if (!(col %in% names(v$scenarios))) v$scenarios[[col]] <- NA
            if (!(col %in% names(new_scenario))) new_scenario[[col]] <- NA
          }
          v$scenarios <- rbind(v$scenarios, new_scenario[names(v$scenarios)])
        }
      }

      showNotification("Scenario saved! You can now compare multiple scenarios.",
        type = "message", duration = 3
      )
    })
  })

  # Clear scenarios
  observeEvent(input$clear_scenarios, {
    v$scenarios <- data.frame()
    v$scenario_counter <- 0
    showNotification("All saved scenarios cleared.", type = "warning", duration = 3)
  })

  # Display scenario comparison
  output$scenario_comparison <- renderUI({
    if (nrow(v$scenarios) == 0) {
      return()
    }

    tagList(
      hr(),
      h2("Saved Scenario Comparison"),
      p("Below are the scenarios you have saved for comparison:"),
      tableOutput("scenario_table"),
      hr()
    )
  })

  # Render scenario table
  output$scenario_table <- renderTable({
    v$scenarios
  })

  # Download scenario comparison
  output$download_comparison <- downloadHandler(
    filename = function() {
      paste("Scenario-Comparison-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      write.csv(v$scenarios, file, row.names = FALSE)
    }
  )
}
