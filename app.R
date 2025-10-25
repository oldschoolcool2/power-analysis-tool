# https://blogs.bmj.com/bmjebmspotlight/2017/11/14/rare-adverse-events-clinical-trials-understanding-rule-three/

# Enable reactive logging for debugging (press Ctrl+F3 or Cmd+F3 in browser)
if (interactive()) {
  options(shiny.reactlog = TRUE)
}

library(shiny)
library(bslib)
library(shinyBS)
library(shinyjs)
library(pwr)
library(binom)
library(kableExtra)
library(tinytex)
library(powerSurvEpi)
library(epiR)
library(plotly)
library(ggplot2)

# Source UI helper functions
source("R/sidebar_ui.R")
source("R/input_components.R")
source("R/header_ui.R")
source("R/help_content.R")

# Define UI
ui <- fluidPage(
  # Modern bslib theme for mobile responsiveness
  theme = bs_theme(
    version = 5,
    bootswatch = NULL,  # Remove Cosmo theme - it has grey background
    primary = "#2B5876",  # Updated to professional teal/slate
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    bg = "#FFFFFF",  # Force pure white background
    fg = "#1D2A39"   # Dark text on white
  ),

  # Link custom CSS files for modern design system
  tags$head(
    # Favicon
    tags$link(rel = "icon", type = "image/svg+xml", href = "favicon.svg"),
    # CSS - version constant for cache busting (update when CSS changes)
    tags$link(rel = "stylesheet", type = "text/css", href = "css/design-tokens.css?v=1.1.0"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/modern-theme.css?v=1.1.0"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/input-components.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/responsive.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "css/sidebar.css"),
    # JavaScript - Bootstrap 5 fix must load before other scripts
    tags$script(src = "js/bootstrap5-shinyBS-fix.js"),
    tags$script(src = "js/theme-switcher.js"),
    tags$script(src = "js/sidebar-navigation.js"),
    tags$style(HTML("
      /* Clean background color definitions */
      :root {
        --bs-body-bg: #FFFFFF;
        --bs-body-bg-rgb: 255, 255, 255;
      }
      
      body, html {
        background-color: #FFFFFF;
      }
      
      /* Ensure dark mode overrides work */
      [data-theme='dark'] {
        --bs-body-bg: #0F172A;
      }
      
      [data-theme='dark'] body,
      [data-theme='dark'] html {
        background-color: #0F172A;
      }
      
      /* FIX: Style the Shiny disconnected overlay to be less intrusive */
      #shiny-disconnected-overlay {
        background: rgba(220, 53, 69, 0.95) !important; /* Red, semi-transparent */
        opacity: 1 !important;
        top: auto !important;
        bottom: 0 !important;
        left: 0 !important;
        right: 0 !important;
        height: auto !important;
        padding: 12px 20px !important;
        text-align: center !important;
        font-size: 14px !important;
        font-weight: 600 !important;
        color: white !important;
        z-index: 10000 !important;
        box-shadow: 0 -2px 10px rgba(0,0,0,0.2) !important;
      }
      
      /* Hide overlay when not disconnected */
      body:not(.disconnected) #shiny-disconnected-overlay {
        display: none !important;
      }
      
      /* Additional inline styles */
      .content-card {
        background: var(--bg-card) !important;
      }

      .page-title {
        font-size: var(--font-size-2xl);
        font-weight: var(--font-weight-bold);
        color: var(--text-primary);
        margin-bottom: var(--space-6);
        padding-bottom: var(--space-4);
        border-bottom: var(--border-subtle);
      }
    "))
  ),

  # Enable shinyjs for JavaScript interactions
  useShinyjs(),

  # App Header
  create_app_header(),

  # Global Help Modal
  bsModal(
    id = "help_modal",
    title = tags$div(
      class = "modal-header-title",
      icon("book", class = "me-2"),
      "Help & Documentation"
    ),
    trigger = "show_help_modal",
    size = "large",
    
    # Introduction
    tags$div(
      class = "modal-intro",
      p("This tool provides power and sample size calculations for epidemiological studies, with a focus on real-world evidence (RWE) applications in pharmaceutical research."),
      p(strong("How to use:"), "Select your study design from the sidebar navigation, enter your parameters, and click Calculate. Contextual help for each analysis type is available below the results.")
    ),
    
    hr(),
    
    # Global help content (Regulatory Guidance & Interpretation)
    create_global_help()
  ),

  # App Container with Sidebar + Main Content
  div(class = "app-container",

    # Hierarchical Sidebar Navigation
    create_sidebar_nav(),

    # Main Content Wrapper
    div(class = "main-content-wrapper",
      div(class = "main-content",

        # ============================================================
        # INPUT PANELS (Conditional based on sidebar selection)
        # ============================================================

        div(class = "content-card",

          # PAGE 1: Single Proportion - Power Analysis
          conditionalPanel(
            condition = "input.sidebar_page == 'power_single' || input.sidebar_page == null",
            h2(class = "page-title", "Single Proportion: Power Analysis"),
            helpText("Calculate power for detecting a single event rate (e.g., post-marketing surveillance)"),
            hr(),
            numericInput("power_n", "Available Sample Size:", 230, min = 1, step = 1),
            bsTooltip("power_n", "Total number of participants available for the study", "right"),
            numericInput("power_p", "Event Frequency (1 in x):", 100, min = 1, step = 1),
            bsTooltip("power_p", "Expected frequency of the event. E.g., 100 means 1 event per 100 participants", "right"),
            create_enhanced_slider("power_discon", "Withdrawal/Discontinuation Rate (%):",
                                  min = 0, max = 50, value = 10, step = 1, post = "%",
                                  tooltip = "Expected percentage of participants who will withdraw or discontinue"),
            create_segmented_alpha("power_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05). Lower values are more conservative."),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_power_single", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_power_single", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 2: Single Proportion - Sample Size
          conditionalPanel(
            condition = "input.sidebar_page == 'ss_single'",
            h2(class = "page-title", "Single Proportion: Sample Size Calculation"),
            helpText("Calculate required sample size OR minimal detectable effect size"),
            hr(),
            radioButtons_fixed("ss_single_calc_mode",
              "Calculation Mode:",
              choices = c(
                "Calculate Sample Size (given effect size)" = "calc_n",
                "Calculate Effect Size (given sample size)" = "calc_effect"
              ),
              selected = "calc_n"
            ),
            bsTooltip("ss_single_calc_mode",
              "Choose whether to calculate required sample size or minimal detectable effect size",
              "right"
            ),
            hr(),
            create_segmented_power("ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists (typically 80% or 90%)"),
            conditionalPanel(
              condition = "input.ss_single_calc_mode == 'calc_n'",
              numericInput("ss_p", "Event Frequency (1 in x):", 100, min = 1, step = 1),
              bsTooltip("ss_p", "Expected frequency of the event. E.g., 100 means 1 event per 100 participants", "right")
            ),
            conditionalPanel(
              condition = "input.ss_single_calc_mode == 'calc_effect'",
              numericInput("ss_n_fixed", "Available Sample Size:", 500, min = 10, step = 1),
              bsTooltip("ss_n_fixed", "Fixed sample size available for the study", "right")
            ),
            create_enhanced_slider("ss_discon", "Withdrawal/Discontinuation Rate (%):",
                                  min = 0, max = 50, value = 10, step = 1, post = "%",
                                  tooltip = "Expected percentage of participants who will withdraw or discontinue"),
            create_segmented_alpha("ss_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05). Lower values are more conservative."),
            hr(),
            checkboxInput("adjust_missing_ss_single", "Adjust for Missing Data", value = FALSE),
            conditionalPanel(
              condition = "input.adjust_missing_ss_single",
              create_enhanced_slider("missing_pct_ss_single", "Expected Missingness (%):",
                                    min = 5, max = 50, value = 20, step = 5, post = "%",
                                    tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"),
              radioButtons_fixed("missing_mechanism_ss_single",
                "Missing Data Mechanism:",
                choices = c(
                  "MCAR (Missing Completely At Random)" = "mcar",
                  "MAR (Missing At Random)" = "mar",
                  "MNAR (Missing Not At Random)" = "mnar"
                ),
                selected = "mar"
              ),
              bsTooltip("missing_mechanism_ss_single",
                "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
                "right"
              ),
              radioButtons_fixed("missing_analysis_ss_single",
                "Planned Analysis Approach:",
                choices = c(
                  "Complete Case Analysis" = "complete_case",
                  "Multiple Imputation (MI)" = "multiple_imputation"
                ),
                selected = "complete_case"
              ),
              bsTooltip("missing_analysis_ss_single",
                "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
                "right"
              ),
              conditionalPanel(
                condition = "input.missing_analysis_ss_single == 'multiple_imputation'",
                numericInput("mi_imputations_ss_single", "Number of Imputations (m):", 5, min = 3, max = 100, step = 1),
                bsTooltip("mi_imputations_ss_single", "Typical values: 5-20. More imputations increase precision but require more computation", "right"),
                create_enhanced_slider("mi_r_squared_ss_single", "Expected Imputation Model R²:",
                                      min = 0.1, max = 0.9, value = 0.5, step = 0.1,
                                      tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed")
              )
            ),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_ss_single", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_ss_single", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 3: Two-Group - Power Analysis
          conditionalPanel(
            condition = "input.sidebar_page == 'power_twogrp'",
            h2(class = "page-title", "Two-Group Comparison: Power Analysis"),
            helpText("Calculate power for comparing two proportions (e.g., exposed vs. unexposed in cohort studies)"),
            hr(),
            numericInput("twogrp_pow_n1", "Sample Size Group 1:", 200, min = 1, step = 1),
            numericInput("twogrp_pow_n2", "Sample Size Group 2:", 200, min = 1, step = 1),
            bsTooltip("twogrp_pow_n1", "Number of participants in exposed/treatment group", "right"),
            bsTooltip("twogrp_pow_n2", "Number of participants in unexposed/control group", "right"),
            numericInput("twogrp_pow_p1", "Event Rate Group 1 (%):", 10, min = 0, max = 100, step = 0.1),
            numericInput("twogrp_pow_p2", "Event Rate Group 2 (%):", 5, min = 0, max = 100, step = 0.1),
            bsTooltip("twogrp_pow_p1", "Expected event rate in exposed/treatment group (as percentage)", "right"),
            bsTooltip("twogrp_pow_p2", "Expected event rate in unexposed/control group (as percentage)", "right"),
            create_segmented_alpha("twogrp_pow_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("twogrp_pow_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
              selected = "two.sided"
            ),
            bsTooltip("twogrp_pow_sided", "Two-sided: test if groups differ. One-sided: test if Group 1 > Group 2", "right"),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_twogrp_pow", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_twogrp_pow", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 4: Two-Group - Sample Size
          conditionalPanel(
            condition = "input.sidebar_page == 'ss_twogrp'",
            h2(class = "page-title", "Two-Group Comparison: Sample Size Calculation"),
            helpText("Calculate required sample size per group to achieve desired power"),
            hr(),
            create_segmented_power("twogrp_ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            numericInput("twogrp_ss_p1", "Event Rate Group 1 (%):", 10, min = 0, max = 100, step = 0.1),
            numericInput("twogrp_ss_p2", "Event Rate Group 2 (%):", 5, min = 0, max = 100, step = 0.1),
            bsTooltip("twogrp_ss_p1", "Expected event rate in exposed/treatment group (as percentage)", "right"),
            bsTooltip("twogrp_ss_p2", "Expected event rate in unexposed/control group (as percentage)", "right"),
            numericInput("twogrp_ss_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1),
            bsTooltip("twogrp_ss_ratio", "Ratio of Group 2 to Group 1 sample size. 1 = equal groups, 2 = twice as many in Group 2", "right"),
            create_segmented_alpha("twogrp_ss_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("twogrp_ss_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
              selected = "two.sided"
            ),
            hr(),
            checkboxInput("adjust_missing_twogrp_ss", "Adjust for Missing Data", value = FALSE),
            conditionalPanel(
              condition = "input.adjust_missing_twogrp_ss",
              create_enhanced_slider("missing_pct_twogrp_ss", "Expected Missingness (%):",
                                    min = 5, max = 50, value = 20, step = 5, post = "%",
                                    tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"),
              radioButtons_fixed("missing_mechanism_twogrp_ss",
                "Missing Data Mechanism:",
                choices = c(
                  "MCAR (Missing Completely At Random)" = "mcar",
                  "MAR (Missing At Random)" = "mar",
                  "MNAR (Missing Not At Random)" = "mnar"
                ),
                selected = "mar"
              ),
              bsTooltip("missing_mechanism_twogrp_ss",
                "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
                "right"
              ),
              radioButtons_fixed("missing_analysis_twogrp_ss",
                "Planned Analysis Approach:",
                choices = c(
                  "Complete Case Analysis" = "complete_case",
                  "Multiple Imputation (MI)" = "multiple_imputation"
                ),
                selected = "complete_case"
              ),
              bsTooltip("missing_analysis_twogrp_ss",
                "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
                "right"
              ),
              conditionalPanel(
                condition = "input.missing_analysis_twogrp_ss == 'multiple_imputation'",
                numericInput("mi_imputations_twogrp_ss", "Number of Imputations (m):", 5, min = 3, max = 100, step = 1),
                bsTooltip("mi_imputations_twogrp_ss", "Typical values: 5-20. More imputations increase precision but require more computation", "right"),
                create_enhanced_slider("mi_r_squared_twogrp_ss", "Expected Imputation Model R²:",
                                      min = 0.1, max = 0.9, value = 0.5, step = 0.1,
                                      tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed")
              )
            ),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_twogrp_ss", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_twogrp_ss", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 5: Survival Analysis - Power Analysis
          conditionalPanel(
            condition = "input.sidebar_page == 'power_survival'",
            h2(class = "page-title", "Survival Analysis (Cox): Power Analysis"),
            helpText("Calculate power for time-to-event outcomes using Cox regression (common in RWE studies)"),
            hr(),
            numericInput("surv_pow_n", "Total Sample Size:", 500, min = 10, step = 10),
            bsTooltip("surv_pow_n", "Total number of participants in the study", "right"),
            numericInput("surv_pow_hr", "Hazard Ratio (HR):", 0.7, min = 0.01, max = 10, step = 0.05),
            bsTooltip("surv_pow_hr", "Expected hazard ratio (HR < 1 indicates protective effect, HR > 1 indicates risk)", "right"),
            create_enhanced_slider("surv_pow_k", "Proportion Exposed (%):",
                                  min = 10, max = 90, value = 50, step = 5, post = "%",
                                  tooltip = "Proportion of participants in the exposed/treatment group"),
            create_enhanced_slider("surv_pow_pE", "Overall Event Rate (%):",
                                  min = 5, max = 95, value = 30, step = 5, post = "%",
                                  tooltip = "Expected proportion of participants experiencing the event during follow-up"),
            create_segmented_alpha("surv_pow_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_surv_pow", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_surv_pow", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 6: Survival Analysis - Sample Size
          conditionalPanel(
            condition = "input.sidebar_page == 'ss_survival'",
            h2(class = "page-title", "Survival Analysis (Cox): Sample Size Calculation"),
            helpText("Calculate required sample size for time-to-event analysis"),
            hr(),
            create_segmented_power("surv_ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            numericInput("surv_ss_hr", "Hazard Ratio (HR):", 0.7, min = 0.01, max = 10, step = 0.05),
            bsTooltip("surv_ss_hr", "Expected hazard ratio to detect", "right"),
            create_enhanced_slider("surv_ss_k", "Proportion Exposed (%):",
                                  min = 10, max = 90, value = 50, step = 5, post = "%",
                                  tooltip = "Proportion of participants in the exposed/treatment group"),
            create_enhanced_slider("surv_ss_pE", "Overall Event Rate (%):",
                                  min = 5, max = 95, value = 30, step = 5, post = "%",
                                  tooltip = "Expected proportion of participants experiencing the event during follow-up"),
            create_segmented_alpha("surv_ss_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            hr(),
            checkboxInput("adjust_missing_surv_ss", "Adjust for Missing Data", value = FALSE),
            conditionalPanel(
              condition = "input.adjust_missing_surv_ss",
              create_enhanced_slider("missing_pct_surv_ss", "Expected Missingness (%):",
                                    min = 5, max = 50, value = 20, step = 5, post = "%",
                                    tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"),
              radioButtons_fixed("missing_mechanism_surv_ss",
                "Missing Data Mechanism:",
                choices = c(
                  "MCAR (Missing Completely At Random)" = "mcar",
                  "MAR (Missing At Random)" = "mar",
                  "MNAR (Missing Not At Random)" = "mnar"
                ),
                selected = "mar"
              ),
              bsTooltip("missing_mechanism_surv_ss",
                "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
                "right"
              ),
              radioButtons_fixed("missing_analysis_surv_ss",
                "Planned Analysis Approach:",
                choices = c(
                  "Complete Case Analysis" = "complete_case",
                  "Multiple Imputation (MI)" = "multiple_imputation"
                ),
                selected = "complete_case"
              ),
              bsTooltip("missing_analysis_surv_ss",
                "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
                "right"
              ),
              conditionalPanel(
                condition = "input.missing_analysis_surv_ss == 'multiple_imputation'",
                numericInput("mi_imputations_surv_ss", "Number of Imputations (m):", 5, min = 3, max = 100, step = 1),
                bsTooltip("mi_imputations_surv_ss", "Typical values: 5-20. More imputations increase precision but require more computation", "right"),
                create_enhanced_slider("mi_r_squared_surv_ss", "Expected Imputation Model R²:",
                                      min = 0.1, max = 0.9, value = 0.5, step = 0.1,
                                      tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed")
              )
            ),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_surv_ss", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_surv_ss", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 7: Matched Case-Control
          conditionalPanel(
            condition = "input.sidebar_page == 'match_casecontrol'",
            h2(class = "page-title", "Matched Case-Control Study"),
            helpText("Calculate sample size for matched case-control studies (e.g., propensity score matching)"),
            hr(),
            create_segmented_power("match_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            numericInput("match_or", "Odds Ratio (OR):", 2.0, min = 0.01, max = 20, step = 0.1),
            bsTooltip("match_or", "Expected odds ratio to detect (OR < 1 protective, OR > 1 risk factor)", "right"),
            create_enhanced_slider("match_p0", "Exposure Probability in Controls (%):",
                                  min = 5, max = 95, value = 20, step = 5, post = "%",
                                  tooltip = "Expected proportion of controls exposed to the risk factor"),
            numericInput("match_ratio", "Controls per Case:", 1, min = 1, max = 5, step = 1),
            bsTooltip("match_ratio", "Number of matched controls per case (typically 1:1, 2:1, or 3:1)", "right"),
            create_segmented_alpha("match_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("match_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
              selected = "two.sided"
            ),
            bsTooltip("match_sided", "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
            hr(),
            checkboxInput("adjust_missing_match", "Adjust for Missing Data", value = FALSE),
            conditionalPanel(
              condition = "input.adjust_missing_match",
              create_enhanced_slider("missing_pct_match", "Expected Missingness (%):",
                                    min = 5, max = 50, value = 20, step = 5, post = "%",
                                    tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"),
              radioButtons_fixed("missing_mechanism_match",
                "Missing Data Mechanism:",
                choices = c(
                  "MCAR (Missing Completely At Random)" = "mcar",
                  "MAR (Missing At Random)" = "mar",
                  "MNAR (Missing Not At Random)" = "mnar"
                ),
                selected = "mar"
              ),
              bsTooltip("missing_mechanism_match",
                "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
                "right"
              ),
              radioButtons_fixed("missing_analysis_match",
                "Planned Analysis Approach:",
                choices = c(
                  "Complete Case Analysis" = "complete_case",
                  "Multiple Imputation (MI)" = "multiple_imputation"
                ),
                selected = "complete_case"
              ),
              bsTooltip("missing_analysis_match",
                "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
                "right"
              ),
              conditionalPanel(
                condition = "input.missing_analysis_match == 'multiple_imputation'",
                numericInput("mi_imputations_match", "Number of Imputations (m):", 5, min = 3, max = 100, step = 1),
                bsTooltip("mi_imputations_match", "Typical values: 5-20. More imputations increase precision but require more computation", "right"),
                create_enhanced_slider("mi_r_squared_match", "Expected Imputation Model R²:",
                                      min = 0.1, max = 0.9, value = 0.5, step = 0.1,
                                      tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed")
              )
            ),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_match", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_match", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 8: Continuous Outcomes - Power Analysis
          conditionalPanel(
            condition = "input.sidebar_page == 'power_continuous'",
            h2(class = "page-title", "Continuous Outcomes (t-test): Power Analysis"),
            helpText("Calculate power for comparing means between two groups (e.g., BMI, blood pressure, QoL scores)"),
            hr(),
            numericInput("cont_pow_n1", "Sample Size Group 1:", 100, min = 2, step = 1),
            numericInput("cont_pow_n2", "Sample Size Group 2:", 100, min = 2, step = 1),
            bsTooltip("cont_pow_n1", "Number of participants in treatment/exposed group", "right"),
            bsTooltip("cont_pow_n2", "Number of participants in control/unexposed group", "right"),
            numericInput("cont_pow_d", "Effect Size (Cohen's d):", 0.5, min = 0.01, max = 5, step = 0.1),
            bsTooltip("cont_pow_d", "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8", "right"),
            create_segmented_alpha("cont_pow_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("cont_pow_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
              selected = "two.sided"
            ),
            bsTooltip("cont_pow_sided", "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_cont_pow", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_cont_pow", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 9: Continuous Outcomes - Sample Size
          conditionalPanel(
            condition = "input.sidebar_page == 'ss_continuous'",
            h2(class = "page-title", "Continuous Outcomes (t-test): Sample Size Calculation"),
            helpText("Calculate required sample size to detect a difference in means"),
            hr(),
            create_segmented_power("cont_ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            numericInput("cont_ss_d", "Effect Size (Cohen's d):", 0.5, min = 0.01, max = 5, step = 0.1),
            bsTooltip("cont_ss_d", "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8", "right"),
            numericInput("cont_ss_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1),
            bsTooltip("cont_ss_ratio", "Ratio of Group 2 to Group 1 sample size. 1 = equal groups", "right"),
            create_segmented_alpha("cont_ss_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("cont_ss_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
              selected = "two.sided"
            ),
            hr(),
            checkboxInput("adjust_missing_cont_ss", "Adjust for Missing Data", value = FALSE),
            conditionalPanel(
              condition = "input.adjust_missing_cont_ss",
              create_enhanced_slider("missing_pct_cont_ss", "Expected Missingness (%):",
                                    min = 5, max = 50, value = 20, step = 5, post = "%",
                                    tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"),
              radioButtons_fixed("missing_mechanism_cont_ss",
                "Missing Data Mechanism:",
                choices = c(
                  "MCAR (Missing Completely At Random)" = "mcar",
                  "MAR (Missing At Random)" = "mar",
                  "MNAR (Missing Not At Random)" = "mnar"
                ),
                selected = "mar"
              ),
              bsTooltip("missing_mechanism_cont_ss",
                "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
                "right"
              ),
              radioButtons_fixed("missing_analysis_cont_ss",
                "Planned Analysis Approach:",
                choices = c(
                  "Complete Case Analysis" = "complete_case",
                  "Multiple Imputation (MI)" = "multiple_imputation"
                ),
                selected = "complete_case"
              ),
              bsTooltip("missing_analysis_cont_ss",
                "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
                "right"
              ),
              conditionalPanel(
                condition = "input.missing_analysis_cont_ss == 'multiple_imputation'",
                numericInput("mi_imputations_cont_ss", "Number of Imputations (m):", 5, min = 3, max = 100, step = 1),
                bsTooltip("mi_imputations_cont_ss", "Typical values: 5-20. More imputations increase precision but require more computation", "right"),
                create_enhanced_slider("mi_r_squared_cont_ss", "Expected Imputation Model R²:",
                                      min = 0.1, max = 0.9, value = 0.5, step = 0.1,
                                      tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed")
              )
            ),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_cont_ss", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_cont_ss", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 10: Non-Inferiority Testing
          conditionalPanel(
            condition = "input.sidebar_page == 'noninf'",
            h2(class = "page-title", "Non-Inferiority Testing"),
            helpText("Calculate sample size for non-inferiority trials (common in generic/biosimilar studies)"),
            hr(),
            create_segmented_power("noninf_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of demonstrating non-inferiority if true"),
            numericInput("noninf_p1", "Event Rate Test Group (%):", 10, min = 0, max = 100, step = 0.1),
            numericInput("noninf_p2", "Event Rate Reference Group (%):", 10, min = 0, max = 100, step = 0.1),
            bsTooltip("noninf_p1", "Expected event rate in test/generic group (as percentage)", "right"),
            bsTooltip("noninf_p2", "Expected event rate in reference/branded group (as percentage)", "right"),
            numericInput("noninf_margin", "Non-Inferiority Margin (%):", 5, min = 0.1, max = 50, step = 0.5),
            bsTooltip("noninf_margin", "Maximum clinically acceptable difference (percentage points). Test is non-inferior if difference < margin.", "right"),
            numericInput("noninf_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1),
            bsTooltip("noninf_ratio", "Ratio of Reference to Test group size. 1 = equal groups", "right"),
            create_segmented_alpha("noninf_alpha", "Significance Level (α):",
                                  choices = c("0.01" = 0.01, "0.025" = 0.025, "0.05" = 0.05, "0.10" = 0.10),
                                  selected = 0.025,
                                  tooltip = "Type I error rate (typically 0.025 for one-sided non-inferiority test)"),
            hr(),
            checkboxInput("adjust_missing_noninf", "Adjust for Missing Data", value = FALSE),
            conditionalPanel(
              condition = "input.adjust_missing_noninf",
              create_enhanced_slider("missing_pct_noninf", "Expected Missingness (%):",
                                    min = 5, max = 50, value = 20, step = 5, post = "%",
                                    tooltip = "Percentage of participants with missing exposure, outcome, or covariate data"),
              radioButtons_fixed("missing_mechanism_noninf",
                "Missing Data Mechanism:",
                choices = c(
                  "MCAR (Missing Completely At Random)" = "mcar",
                  "MAR (Missing At Random)" = "mar",
                  "MNAR (Missing Not At Random)" = "mnar"
                ),
                selected = "mar"
              ),
              bsTooltip("missing_mechanism_noninf",
                "MCAR: minimal bias. MAR: controllable with observed data. MNAR: potential substantial bias",
                "right"
              ),
              radioButtons_fixed("missing_analysis_noninf",
                "Planned Analysis Approach:",
                choices = c(
                  "Complete Case Analysis" = "complete_case",
                  "Multiple Imputation (MI)" = "multiple_imputation"
                ),
                selected = "complete_case"
              ),
              bsTooltip("missing_analysis_noninf",
                "Complete case: only use observations with no missing data (more conservative). MI: impute missing values (more efficient)",
                "right"
              ),
              conditionalPanel(
                condition = "input.missing_analysis_noninf == 'multiple_imputation'",
                numericInput("mi_imputations_noninf", "Number of Imputations (m):", 5, min = 3, max = 100, step = 1),
                bsTooltip("mi_imputations_noninf", "Typical values: 5-20. More imputations increase precision but require more computation", "right"),
                create_enhanced_slider("mi_r_squared_noninf", "Expected Imputation Model R²:",
                                      min = 0.1, max = 0.9, value = 0.5, step = 0.1,
                                      tooltip = "Predictive power of imputation model (0.3=weak, 0.5=moderate, 0.7=strong). Higher R² means better imputation quality and less inflation needed")
              )
            ),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_noninf", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_noninf", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 11: Propensity Score VIF Calculator
          conditionalPanel(
            condition = "input.sidebar_page == 'vif_calculator'",
            h2(class = "page-title", "Propensity Score Methods: VIF Calculator"),
            helpText("Adjust sample size for efficiency loss from propensity score weighting (IPTW, overlap, matching)"),
            hr(),

            # RCT-based sample size input
            numericInput("vif_n_rct",
              "Required Sample Size (RCT Calculation):",
              500, min = 10, step = 10),
            bsTooltip("vif_n_rct",
              "Sample size calculated from standard power analysis (as if it were a randomized trial)",
              "right"),

            # Propensity score model characteristics
            hr(),
            h4("Propensity Score Model Assumptions"),

            create_enhanced_slider("vif_prevalence",
              "Treatment Prevalence (%):",
              min = 10, max = 90, value = 50, step = 5, post = "%",
              tooltip = "Percentage of participants in the treatment/exposed group"),

            create_enhanced_slider("vif_cstat",
              "Anticipated C-statistic of PS Model:",
              min = 0.55, max = 0.95, value = 0.70, step = 0.05, post = "",
              tooltip = "Discriminative ability of propensity score model. 0.5=no discrimination, 1.0=perfect. Typical: 0.65-0.75 for RWE data"),

            # Weighting method selection
            radioButtons_fixed("vif_method",
              "Weighting Method:",
              choices = c(
                "ATE - Inverse Probability of Treatment Weighting" = "ATE",
                "ATT - Average Treatment Effect on Treated" = "ATT",
                "ATO - Overlap Weights (most efficient)" = "ATO",
                "ATM - Matching Weights" = "ATM",
                "ATEN - Entropy Weights" = "ATEN"
              ),
              selected = "ATE"),
            bsTooltip("vif_method",
              "ATE: generalizes to full population. ATT: effect in treated only. ATO/ATM/ATEN: focus on overlap region (more efficient)",
              "right"),

            hr(),
            div(class = "btn-group-custom",
              actionButton("example_vif", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_vif", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          )

        ), # End of input cards

        # ============================================================
        # CALCULATE BUTTON (always visible)
        # ============================================================

        actionButton("go", "Calculate", icon = icon("calculator"), class = "btn-primary btn-lg w-100"),

        # ============================================================
        # CONTEXTUAL HELP & RESULTS
        # ============================================================

        # Contextual help for Single Proportion
        conditionalPanel(
          condition = "input.sidebar_page == 'power_single' || input.sidebar_page == 'ss_single'",
          div(class = "content-card help-section",
            create_contextual_help("single_proportion")
          )
        ),

        # Contextual help for Two-Group Comparisons
        conditionalPanel(
          condition = "input.sidebar_page == 'power_twogrp' || input.sidebar_page == 'ss_twogrp'",
          div(class = "content-card help-section",
            create_contextual_help("two_group")
          )
        ),

        # Contextual help for Survival Analysis
        conditionalPanel(
          condition = "input.sidebar_page == 'power_survival' || input.sidebar_page == 'ss_survival'",
          div(class = "content-card help-section",
            create_contextual_help("survival")
          )
        ),

        # Contextual help for Matched Case-Control
        conditionalPanel(
          condition = "input.sidebar_page == 'match_casecontrol'",
          div(class = "content-card help-section",
            create_contextual_help("matched")
          )
        ),

        # Contextual help for Continuous Outcomes
        conditionalPanel(
          condition = "input.sidebar_page == 'power_continuous' || input.sidebar_page == 'ss_continuous'",
          div(class = "content-card help-section",
            create_contextual_help("continuous")
          )
        ),

        # Contextual help for Non-Inferiority
        conditionalPanel(
          condition = "input.sidebar_page == 'noninf'",
          div(class = "content-card help-section",
            create_contextual_help("noninferiority")
          )
        ),

        # Contextual help for VIF Calculator
        conditionalPanel(
          condition = "input.sidebar_page == 'vif_calculator'",
          div(class = "content-card help-section",
            create_contextual_help("vif_propensity")
          )
        ),

        # Live preview (debounced)
        uiOutput("live_preview"),

        # Results section
        uiOutput("result_text"),
        uiOutput("effect_measures"),
        uiOutput("figure_title"),
        plotlyOutput("power_plot", height = "500px"),
        uiOutput("table_title"),
        dataTableOutput("result_table"),
        uiOutput("table_footnotes"),
        uiOutput("download_buttons"),

        # Scenario comparison section
        uiOutput("scenario_comparison")
      ) # End of main-content
    ) # End of main-content-wrapper
  ), # End of app-container

  # Quick Preview Footer (Phase 3: Layout Simplification)
  tags$div(
    class = "quick-preview-footer",
    id = "quick-preview-footer",
    tags$div(
      class = "quick-preview-content",
      tags$span(class = "quick-preview-icon", icon("info-circle")),
      tags$span(
        class = "quick-preview-text",
        id = "preview-text",
        "Select an analysis type from the sidebar to begin"
      ),
      tags$span(
        class = "quick-preview-cta",
        "(Enter parameters and click Calculate to run analysis)"
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {

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
      paste0("Preview: Rule of Three for event rate 1 in ",
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
    } else {
      "Enter parameters above"
    }

    # Update footer text using shinyjs
    shinyjs::html("preview-text", preview_text)
  })

  # Helper function: safely calculate effect measures (avoid division by zero)
  calc_effect_measures <- function(p1, p2) {
    risk_diff <- (p1 - p2) * 100

    # Relative Risk: undefined when p2 = 0
    relative_risk <- if (p2 == 0) NA_real_ else p1 / p2

    # Odds Ratio: undefined when either rate is 0% or 100%
    odds1 <- if (p1 %in% c(0, 1)) NA_real_ else p1 / (1 - p1)
    odds2 <- if (p2 %in% c(0, 1)) NA_real_ else p2 / (1 - p2)
    odds_ratio <- if (is.na(odds1) || is.na(odds2)) NA_real_ else odds1 / odds2

    list(
      risk_diff = risk_diff,
      relative_risk = relative_risk,
      odds_ratio = odds_ratio
    )
  }

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

  # Helper function: inflate sample size for missing data (Tier 1 Enhancement)
  calc_missing_data_inflation <- function(n_required, missing_pct, mechanism = "mar", analysis_type = "complete_case", mi_imputations = 5, mi_r_squared = 0.5) {
    if (missing_pct == 0) {
      return(list(
        n_inflated = n_required,
        inflation_factor = 1.0,
        n_increase = 0,
        pct_increase = 0,
        interpretation = "No adjustment needed (0% missingness assumed)"
      ))
    }

    p_missing <- missing_pct / 100

    # Calculate inflation based on analysis type
    if (analysis_type == "complete_case") {
      # Complete case analysis: conservative inflation
      # N_inflated = N_required / (1 - p_missing)
      inflation_factor <- 1 / (1 - p_missing)
      n_inflated <- ceiling(n_required * inflation_factor)
      n_increase <- n_inflated - n_required
      pct_increase <- round((inflation_factor - 1) * 100, 1)

      # Interpretation text based on mechanism
      mechanism_text <- switch(mechanism,
        "mcar" = "MCAR (minimal bias expected)",
        "mar" = "MAR (bias controllable with observed covariates)",
        "mnar" = "MNAR (potential for substantial bias; sensitivity analysis recommended)",
        "MAR"  # default
      )

      interpretation <- sprintf(
        "Assuming %s%% missingness (%s) with complete-case analysis, inflate sample size by %s%% (add %s participants) to ensure adequate complete-case sample.",
        missing_pct, mechanism_text, pct_increase, n_increase
      )

    } else if (analysis_type == "multiple_imputation") {
      # Multiple Imputation: Less inflation needed due to increased efficiency
      # Formula based on variance inflation: VarMI / VarComplete ≈ (1 + 1/m) × (1 - R²)
      # Where m = number of imputations, R² = predictive power of imputation model

      # Relative efficiency of MI vs complete case
      # RE = 1 / [(1 + 1/m) × (1 - R²_imp)]
      re_mi <- 1 / ((1 + 1/mi_imputations) * (1 - mi_r_squared))

      # Inflation factor accounts for both missing data and MI efficiency
      # Less conservative than complete case because MI recovers information
      inflation_factor <- (1 / (1 - p_missing)) * (1 / re_mi)
      n_inflated <- ceiling(n_required * inflation_factor)
      n_increase <- n_inflated - n_required
      pct_increase <- round((inflation_factor - 1) * 100, 1)

      mechanism_text <- switch(mechanism,
        "mcar" = "MCAR (minimal bias, MI highly efficient)",
        "mar" = "MAR (MI can provide unbiased estimates with good imputation model)",
        "mnar" = "MNAR (MI may reduce but not eliminate bias; sensitivity analysis required)",
        "MAR"  # default
      )

      interpretation <- sprintf(
        "Assuming %s%% missingness (%s) with multiple imputation (m=%s imputations, R²=%s), inflate sample size by %s%% (add %s participants). MI is more efficient than complete-case analysis.",
        missing_pct, mechanism_text, mi_imputations, mi_r_squared, pct_increase, n_increase
      )
    }

    list(
      n_inflated = n_inflated,
      inflation_factor = round(inflation_factor, 3),
      n_increase = n_increase,
      pct_increase = pct_increase,
      interpretation = interpretation
    )
  }

  # Helper function: estimate Variance Inflation Factor for propensity score weighting
  # Based on Austin PC (2021). Statistics in Medicine 40(27):6150-6163.
  estimate_vif_propensity_score <- function(c_statistic, prevalence_pct, weight_type = "ATE") {
    # Convert inputs to proportions
    p <- prevalence_pct / 100  # treatment prevalence
    c <- c_statistic

    # Validate inputs
    if (c < 0.5 || c > 1.0) {
      stop("C-statistic must be between 0.5 and 1.0")
    }
    if (p <= 0 || p >= 1) {
      stop("Prevalence must be between 0 and 100%")
    }

    # Empirical approximation based on Austin (2021) findings
    # These formulas approximate the relationships shown in the paper

    # Separation measure (higher c-statistic = more separation = higher VIF)
    separation <- (c - 0.5) / 0.5  # Normalized to 0-1 scale

    # Imbalance factor (balanced groups have lower VIF)
    # Minimum at p=0.5, increases as p approaches 0 or 1
    imbalance <- abs(p - 0.5) * 2  # Normalized to 0-1 scale

    # Calculate VIF based on weighting method
    if (weight_type == "ATE") {
      # Average Treatment Effect (IPTW) - most sensitive to c-statistic
      # VIF increases substantially with high c-statistic and imbalanced groups
      base_vif <- 1.0 + (separation^2 * 2.5)  # Quadratic relationship
      imbalance_penalty <- 1.0 + (imbalance * separation * 1.5)
      vif <- base_vif * imbalance_penalty

    } else if (weight_type == "ATT") {
      # Average Treatment effect on Treated
      # Slightly lower VIF than ATE, less sensitive to imbalance
      base_vif <- 1.0 + (separation^2 * 2.0)
      imbalance_penalty <- 1.0 + (imbalance * separation * 1.2)
      vif <- base_vif * imbalance_penalty

    } else if (weight_type == "ATO") {
      # Overlap weights - most efficient, VIF typically < 2
      # Least sensitive to c-statistic and imbalance
      base_vif <- 1.0 + (separation^1.5 * 0.8)  # Gentler increase
      imbalance_penalty <- 1.0 + (imbalance * separation * 0.5)
      vif <- base_vif * imbalance_penalty
      # Cap at reasonable maximum for overlap weights
      vif <- min(vif, 2.0)

    } else if (weight_type == "ATM") {
      # Matching weights - similar to overlap weights
      base_vif <- 1.0 + (separation^1.5 * 0.9)
      imbalance_penalty <- 1.0 + (imbalance * separation * 0.6)
      vif <- base_vif * imbalance_penalty
      vif <- min(vif, 2.2)

    } else if (weight_type == "ATEN") {
      # Entropy weights - similar efficiency to overlap weights
      base_vif <- 1.0 + (separation^1.5 * 0.85)
      imbalance_penalty <- 1.0 + (imbalance * separation * 0.55)
      vif <- base_vif * imbalance_penalty
      vif <- min(vif, 2.1)

    } else {
      stop("Invalid weight_type. Must be one of: ATE, ATT, ATO, ATM, ATEN")
    }

    return(round(vif, 3))
  }

  # Helper function: interpret VIF value
  interpret_vif <- function(vif) {
    if (vif < 1.3) {
      list(
        level = "Low",
        color = "#28a745",
        icon = "✅",
        message = "Minimal efficiency loss. Propensity score weighting is highly efficient for this scenario."
      )
    } else if (vif < 2.0) {
      list(
        level = "Moderate",
        color = "#ffc107",
        icon = "⚠️",
        message = "Moderate efficiency loss. Propensity score weighting is acceptable but consider overlap or matching weights for better efficiency."
      )
    } else if (vif < 3.0) {
      list(
        level = "High",
        color = "#fd7e14",
        icon = "⚠️",
        message = "Substantial efficiency loss. Consider using overlap weights (ATO) or matching weights (ATM) instead of ATE/ATT weights."
      )
    } else {
      list(
        level = "Very High",
        color = "#dc3545",
        icon = "❌",
        message = "Severe efficiency loss. Propensity score weighting may not be feasible. Consider alternative methods (matching, stratification, or regression adjustment)."
      )
    }
  }

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
      example = list(vif_n_rct = 800, vif_prevalence = 30, vif_cstat = 0.75, vif_method = "ATE"),
      reset = list(vif_n_rct = 500, vif_prevalence = 50, vif_cstat = 0.70, vif_method = "ATE"),
      example_msg = "High c-statistic PS model with imbalanced treatment prevalence"
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
    v$doAnalysis <- input$go
  })

  # Reset analysis when switching tabs
  observeEvent(input$tabset, {
    v$doAnalysis <- FALSE
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
        if (grepl("_sided$", param)) {
          updateRadioButtons(session, param, selected = value)
        } else if (grepl("power|alpha|discon|k|pE|p0", param)) {
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
        if (grepl("_sided$", param)) {
          updateRadioButtons(session, param, selected = value)
        } else if (grepl("power|alpha|discon|k|pE|p0", param)) {
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
    if (input$tabset == "Power (Single)") {
      validate(
        need(input$power_n > 0, "Sample size must be positive"),
        need(input$power_p > 0, "Event frequency must be positive"),
        need(input$power_discon >= 0 && input$power_discon <= 100, "Discontinuation rate must be between 0 and 100%")
      )
    } else if (input$tabset == "Sample Size (Single)") {
      validate(
        need(input$ss_p > 0, "Event frequency must be positive"),
        need(input$ss_discon >= 0 && input$ss_discon <= 100, "Discontinuation rate must be between 0 and 100%")
      )
    } else if (input$tabset == "Power (Two-Group)") {
      validate(
        need(input$twogrp_pow_n1 > 0, "Sample size Group 1 must be positive"),
        need(input$twogrp_pow_n2 > 0, "Sample size Group 2 must be positive"),
        need(input$twogrp_pow_p1 >= 0 && input$twogrp_pow_p1 <= 100, "Event rate Group 1 must be between 0 and 100%"),
        need(input$twogrp_pow_p2 >= 0 && input$twogrp_pow_p2 <= 100, "Event rate Group 2 must be between 0 and 100%"),
        need(input$twogrp_pow_p1 != input$twogrp_pow_p2, "Event rates must be different to calculate power")
      )
    } else if (input$tabset == "Sample Size (Two-Group)") {
      validate(
        need(input$twogrp_ss_p1 >= 0 && input$twogrp_ss_p1 <= 100, "Event rate Group 1 must be between 0 and 100%"),
        need(input$twogrp_ss_p2 >= 0 && input$twogrp_ss_p2 <= 100, "Event rate Group 2 must be between 0 and 100%"),
        need(input$twogrp_ss_p1 != input$twogrp_ss_p2, "Event rates must be different to calculate sample size"),
        need(input$twogrp_ss_ratio > 0, "Allocation ratio must be positive")
      )
    } else if (input$tabset == "Power (Survival)") {
      validate(
        need(input$surv_pow_n > 0, "Sample size must be positive"),
        need(input$surv_pow_hr > 0, "Hazard ratio must be positive"),
        need(input$surv_pow_k >= 0 && input$surv_pow_k <= 100, "Proportion exposed must be between 0 and 100%"),
        need(input$surv_pow_pE >= 0 && input$surv_pow_pE <= 100, "Event rate must be between 0 and 100%"),
        need(input$surv_pow_hr != 1, "Hazard ratio must be different from 1 to calculate power")
      )
    } else if (input$tabset == "Sample Size (Survival)") {
      validate(
        need(input$surv_ss_hr > 0, "Hazard ratio must be positive"),
        need(input$surv_ss_k >= 0 && input$surv_ss_k <= 100, "Proportion exposed must be between 0 and 100%"),
        need(input$surv_ss_pE >= 0 && input$surv_ss_pE <= 100, "Event rate must be between 0 and 100%"),
        need(input$surv_ss_hr != 1, "Hazard ratio must be different from 1 to calculate sample size")
      )
    } else if (input$tabset == "Matched Case-Control") {
      validate(
        need(input$match_or > 0, "Odds ratio must be positive"),
        need(input$match_p0 >= 0 && input$match_p0 <= 100, "Exposure probability must be between 0 and 100%"),
        need(input$match_ratio >= 1, "Controls per case must be at least 1"),
        need(input$match_or != 1, "Odds ratio must be different from 1 to calculate sample size")
      )
    } else if (input$tabset == "Power (Continuous)") {
      validate(
        need(input$cont_pow_n1 > 1, "Sample size Group 1 must be at least 2"),
        need(input$cont_pow_n2 > 1, "Sample size Group 2 must be at least 2"),
        need(input$cont_pow_d > 0, "Effect size (Cohen's d) must be positive"),
        need(input$cont_pow_d != 0, "Effect size cannot be zero")
      )
    } else if (input$tabset == "Sample Size (Continuous)") {
      validate(
        need(input$cont_ss_d > 0, "Effect size (Cohen's d) must be positive"),
        need(input$cont_ss_d != 0, "Effect size cannot be zero"),
        need(input$cont_ss_ratio > 0, "Allocation ratio must be positive")
      )
    } else if (input$tabset == "Non-Inferiority") {
      validate(
        need(input$noninf_p1 >= 0 && input$noninf_p1 <= 100, "Event rate Test Group must be between 0 and 100%"),
        need(input$noninf_p2 >= 0 && input$noninf_p2 <= 100, "Event rate Reference Group must be between 0 and 100%"),
        need(input$noninf_margin > 0, "Non-inferiority margin must be positive"),
        need(input$noninf_margin < 100, "Non-inferiority margin must be less than 100%"),
        need(input$noninf_ratio > 0, "Allocation ratio must be positive")
      )
    }
  }

  ################################################################################################## LIVE PREVIEW (DEBOUNCED)

  # Create debounced preview reactive for quick feedback
  preview_inputs <- reactive({
    if (input$tabset == "Power (Single)") {
      list(
        tab = input$tabset,
        n = input$power_n,
        p = input$power_p,
        alpha = input$power_alpha,
        rate = 1 / input$power_p
      )
    } else if (input$tabset == "Sample Size (Single)") {
      list(
        tab = input$tabset,
        power = input$ss_power,
        p = input$ss_p,
        alpha = input$ss_alpha,
        rate = 1 / input$ss_p
      )
    } else if (input$tabset == "Power (Two-Group)") {
      list(
        tab = input$tabset,
        n1 = input$twogrp_pow_n1,
        n2 = input$twogrp_pow_n2,
        p1 = input$twogrp_pow_p1,
        p2 = input$twogrp_pow_p2
      )
    } else {
      list(tab = input$tabset)
    }
  }) %>% debounce(1000) # Wait 1 second after last input change

  output$live_preview <- renderUI({
    # Only show preview before Calculate is pressed
    if (v$doAnalysis) {
      return()
    }

    prev <- preview_inputs()

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
    if (!v$doAnalysis) {
      return()
    }

    isolate({
      validate_inputs()

      if (input$tabset == "Power (Single)") {
        incidence_rate <- input$power_p
        sample_size <- input$power_n
        power <- pwr.p.test(
          sig.level = input$power_alpha, power = NULL,
          h = ES.h(1 / input$power_p, 0), alt = "greater", n = input$power_n
        )$power
        discon <- input$power_discon / 100

        text0 <- hr()
        text1 <- h1("Results of this analysis")
        text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
        text3 <- p(paste0(
          "Based on the Binomial distribution and a true event incidence rate of 1 in ",
          format(incidence_rate, digits = 0, nsmall = 0), " (or ",
          format(1 / incidence_rate * 100, digits = 2, nsmall = 2), "%), with ",
          format(ceiling(sample_size), digits = 0, nsmall = 0),
          " participants, the probability of observing at least one event is ",
          format(power * 100, digits = 0, nsmall = 0), "% (α = ",
          input$power_alpha, "). Accounting for a possible withdrawal or discontinuation rate of ",
          format(discon * 100, digits = 0), "%, the adjusted sample size is ",
          format(ceiling((sample_size * (1 + discon))), digits = 0), " to maintain this power."
        ))
        HTML(paste0(text0, text1, text2, text3))
      } else if (input$tabset == "Sample Size (Single)") {
        # Feature 2: Minimal Detectable Effect Size Calculator
        calc_mode <- input$ss_single_calc_mode
        power <- input$ss_power / 100
        discon <- input$ss_discon / 100

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          incidence_rate <- input$ss_p
          sample_size_base <- pwr.p.test(
            sig.level = input$ss_alpha, power = power,
            h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
          )$n

          # Apply discontinuation adjustment
          sample_size_after_discon <- ceiling(sample_size_base * (1 + discon))

          # Apply missing data adjustment if enabled (Tier 1 Enhancement)
          if (input$adjust_missing_ss_single) {
            missing_adj <- calc_missing_data_inflation(
              sample_size_after_discon,
              input$missing_pct_ss_single,
              input$missing_mechanism_ss_single,
              input$missing_analysis_ss_single,
              ifelse(input$missing_analysis_ss_single == "multiple_imputation", input$mi_imputations_ss_single, 5),
              ifelse(input$missing_analysis_ss_single == "multiple_imputation", input$mi_r_squared_ss_single, 0.5)
            )
            sample_size_final <- missing_adj$n_inflated
            missing_data_text <- HTML(paste0(
              "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
              "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
              missing_adj$interpretation,
              "<br><strong>Sample size before missing data adjustment:</strong> ",
              sample_size_after_discon,
              "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
              "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
              "</p>"
            ))
          } else {
            sample_size_final <- sample_size_after_discon
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "Based on the Binomial distribution and a true event incidence rate of 1 in ",
            format(incidence_rate, digits = 0, nsmall = 0), " (or ",
            format(1 / incidence_rate * 100, digits = 2, nsmall = 2), "%), ",
            format(ceiling(sample_size_base), digits = 0, nsmall = 0),
            " participants would be needed to observe at least one event with ",
            format(power * 100, digits = 0, nsmall = 0), "% probability (α = ",
            input$ss_alpha, "). Accounting for a possible withdrawal or discontinuation rate of ",
            format(discon * 100, digits = 0), "%, the target number of participants is set as ",
            format(sample_size_after_discon, digits = 0), ".",
            if (input$adjust_missing_ss_single) {
              paste0(" <strong>After adjusting for ", input$missing_pct_ss_single,
                     "% missing data, the final target sample size is ",
                     format(sample_size_final, digits = 0), " participants.</strong>")
            } else {
              ""
            }
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Effect Size (Feature 2: Tier 1 Enhancement)
          # Account for discontinuation and missing data to get effective sample size
          n_nominal <- input$ss_n_fixed
          n_after_discon <- ceiling(n_nominal * (1 - discon))

          if (input$adjust_missing_ss_single) {
            p_missing <- input$missing_pct_ss_single / 100
            n_effective <- ceiling(n_after_discon * (1 - p_missing))
            missing_note <- paste0(" After accounting for ",
              input$missing_pct_ss_single, "% missing data (",
              tolower(substr(input$missing_mechanism_ss_single, 1, 4)), "), ",
              "the effective sample size is ", n_effective, " participants.")
          } else {
            n_effective <- n_after_discon
            missing_note <- ""
          }

          # Solve for minimal detectable h
          h_min <- pwr.p.test(
            sig.level = input$ss_alpha, power = power,
            h = NULL, alt = "greater", n = n_effective
          )$h

          # Convert h back to proportion: h = 2*asin(sqrt(p1)) - 2*asin(sqrt(0)) = 2*asin(sqrt(p1))
          # Therefore: p1 = sin²(h/2)
          p_detectable <- sin(h_min / 2)^2
          incidence_rate_detectable <- 1 / p_detectable

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis (Tier 1 Enhancement)</strong><br>",
            "With an available sample size of ", n_nominal, " participants, ",
            "accounting for a ", format(discon * 100, digits = 0), "% discontinuation rate, ",
            "the effective sample size is ", n_after_discon, " participants.",
            missing_note,
            " With ", format(power * 100, digits = 0), "% power and α = ", input$ss_alpha,
            ", the <strong>minimal detectable event incidence rate is 1 in ",
            format(round(incidence_rate_detectable), digits = 0), " (or ",
            format(p_detectable * 100, digits = 2, nsmall = 2), "%)</strong>. ",
            "This is the smallest event rate that can be reliably detected with this sample size."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect (Tier 1 Enhancement):</strong><br>",
            "<strong>Event Incidence Rate:</strong> 1 in ", format(round(incidence_rate_detectable), digits = 0),
            " (", format(p_detectable * 100, digits = 2, nsmall = 2), "%)<br>",
            "<strong>Cohen's h:</strong> ", format(h_min, digits = 3),
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }
      } else if (input$tabset == "Power (Two-Group)") {
        n1 <- input$twogrp_pow_n1
        n2 <- input$twogrp_pow_n2
        p1 <- input$twogrp_pow_p1 / 100
        p2 <- input$twogrp_pow_p2 / 100

        power <- pwr.2p2n.test(
          h = ES.h(p1, p2), n1 = n1, n2 = n2,
          sig.level = input$twogrp_pow_alpha,
          alternative = input$twogrp_pow_sided
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
          input$twogrp_pow_alpha, " (", input$twogrp_pow_sided, " test)."
        ))
        HTML(paste0(text0, text1, text2, text3))
      } else if (input$tabset == "Sample Size (Two-Group)") {
        # Feature 2: Minimal Detectable Effect Size Calculator
        calc_mode <- input$twogrp_ss_calc_mode
        power <- input$twogrp_ss_power / 100

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          p1 <- input$twogrp_ss_p1 / 100
          p2 <- input$twogrp_ss_p2 / 100

          # Calculate base sample size for group 1 (ratio-aware for unequal allocation)
          n1_base <- solve_n1_for_ratio(
            ES.h(p1, p2), input$twogrp_ss_ratio,
            input$twogrp_ss_alpha, power, input$twogrp_ss_sided
          )
          n2_base <- n1_base * input$twogrp_ss_ratio
          n_total_base <- ceiling(n1_base + n2_base)

          # Apply missing data adjustment if enabled (Tier 1 Enhancement)
          if (input$adjust_missing_twogrp_ss) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              input$missing_pct_twogrp_ss,
              input$missing_mechanism_twogrp_ss,
              input$missing_analysis_twogrp_ss,
              ifelse(input$missing_analysis_twogrp_ss == "multiple_imputation", input$mi_imputations_twogrp_ss, 5),
              ifelse(input$missing_analysis_twogrp_ss == "multiple_imputation", input$mi_r_squared_twogrp_ss, 0.5)
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain allocation ratio after adjustment
            n1_final <- ceiling(n_total_final / (1 + input$twogrp_ss_ratio))
            n2_final <- n_total_final - n1_final

            missing_data_text <- HTML(paste0(
              "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
              "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
              missing_adj$interpretation,
              "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
              "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
              "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
              "</p>"
            ))
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
            "To detect a difference in event rates from ",
            format(p2 * 100, digits = 2, nsmall = 1), "% in Group 2 (control) to ",
            format(p1 * 100, digits = 2, nsmall = 1), "% in Group 1 (exposed/treatment) with ",
            format(power * 100, digits = 0, nsmall = 0), "% power at α = ",
            input$twogrp_ss_alpha, " (", input$twogrp_ss_sided, " test), the required sample sizes are: Group 1: n1 = ",
            format(n1_final, digits = 0, nsmall = 0), ", Group 2: n2 = ",
            format(n2_final, digits = 0, nsmall = 0), " (total N = ",
            format(n_total_final, digits = 0, nsmall = 0), ").",
            if (input$adjust_missing_twogrp_ss) {
              paste0(" <strong>After adjusting for ", input$missing_pct_twogrp_ss,
                     "% missing data, the final total sample size is ",
                     format(n_total_final, digits = 0), " participants (n1=", n1_final, ", n2=", n2_final, ").</strong>")
            } else {
              ""
            }
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Effect Size (Feature 2: Tier 1 Enhancement)
          n1_nominal <- input$twogrp_ss_n1_fixed
          n2_nominal <- n1_nominal * input$twogrp_ss_ratio
          p2 <- input$twogrp_ss_p2_baseline / 100

          # Account for missing data to get effective sample sizes
          if (input$adjust_missing_twogrp_ss) {
            p_missing <- input$missing_pct_twogrp_ss / 100
            n1_effective <- ceiling(n1_nominal * (1 - p_missing))
            n2_effective <- ceiling(n2_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", input$missing_pct_twogrp_ss,
              "% missing data (", tolower(substr(input$missing_mechanism_twogrp_ss, 1, 4)),
              "), effective sample sizes are n1=", n1_effective, ", n2=", n2_effective, ".")
          } else {
            n1_effective <- n1_nominal
            n2_effective <- n2_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable h
          h_min <- pwr.2p2n.test(
            h = NULL, n1 = n1_effective, n2 = n2_effective,
            sig.level = input$twogrp_ss_alpha, power = power,
            alternative = input$twogrp_ss_sided
          )$h

          # Convert h to p1 given p2
          # h = 2*asin(sqrt(p1)) - 2*asin(sqrt(p2))
          # Therefore: p1 = sin²((h + 2*asin(sqrt(p2)))/2)
          p1_detectable <- sin((h_min + 2 * asin(sqrt(p2))) / 2)^2

          # Calculate effect sizes
          risk_diff <- (p1_detectable - p2) * 100
          relative_risk <- ifelse(p2 > 0, p1_detectable / p2, NA)
          odds_ratio <- ifelse(p2 < 1 && p1_detectable < 1,
            (p1_detectable / (1 - p1_detectable)) / (p2 / (1 - p2)), NA)

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis (Tier 1 Enhancement)</strong><br>",
            "With available sample sizes of n1=", n1_nominal, " (Group 1) and n2=",
            round(n2_nominal), " (Group 2, ratio=", input$twogrp_ss_ratio, "),",
            missing_note,
            " With ", format(power * 100, digits = 0), "% power and α = ", input$twogrp_ss_alpha,
            " (", input$twogrp_ss_sided, " test), given a baseline event rate of ",
            format(p2 * 100, digits = 2), "% in Group 2, ",
            "the <strong>minimal detectable event rate in Group 1 is ",
            format(p1_detectable * 100, digits = 2), "%</strong> (risk difference: ",
            format(abs(risk_diff), digits = 2), " percentage points)."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect (Tier 1 Enhancement):</strong><br>",
            "<strong>Group 1 Event Rate:</strong> ", format(p1_detectable * 100, digits = 2), "%<br>",
            "<strong>Group 2 Event Rate:</strong> ", format(p2 * 100, digits = 2), "%<br>",
            "<strong>Risk Difference:</strong> ", format(abs(risk_diff), digits = 2), " percentage points<br>",
            "<strong>Relative Risk:</strong> ", ifelse(is.na(relative_risk), "N/A", format(relative_risk, digits = 3)), "<br>",
            "<strong>Odds Ratio:</strong> ", ifelse(is.na(odds_ratio), "N/A", format(odds_ratio, digits = 3)), "<br>",
            "<strong>Cohen's h:</strong> ", format(h_min, digits = 3),
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }
      } else if (input$tabset == "Power (Survival)") {
        n <- input$surv_pow_n
        hr <- input$surv_pow_hr
        k <- input$surv_pow_k / 100
        pE <- input$surv_pow_pE / 100

        # Calculate power using powerSurvEpi
        power <- powerEpi(
          n = n, theta = hr, k = k, pE = pE,
          RR = hr, alpha = input$surv_pow_alpha
        )

        text0 <- hr()
        text1 <- h1("Results of this analysis")
        text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
        text3 <- p(paste0(
          "For a survival analysis with N = ", n, " total participants, ",
          format(k * 100, digits = 1, nsmall = 0), "% exposed/treated, an overall event rate of ",
          format(pE * 100, digits = 1, nsmall = 0), "%, and an expected hazard ratio of ",
          format(hr, digits = 2, nsmall = 2), ", the study has ",
          format(power * 100, digits = 1, nsmall = 1), "% power to detect this effect using Cox regression at α = ",
          input$surv_pow_alpha, " (two-sided test). This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
        ))
        HTML(paste0(text0, text1, text2, text3))
      } else if (input$tabset == "Sample Size (Survival)") {
        # Feature 2: Minimal Detectable Effect Size Calculator
        calc_mode <- input$surv_ss_calc_mode
        power <- input$surv_ss_power / 100
        k <- input$surv_ss_k / 100
        pE <- input$surv_ss_pE / 100

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          hr <- input$surv_ss_hr

          # Calculate base sample size using powerSurvEpi
          n_base <- ssizeEpi(
            power = power, theta = hr, k = k, pE = pE,
            RR = hr, alpha = input$surv_ss_alpha
          )

          # Apply missing data adjustment if enabled (Tier 1 Enhancement)
          if (input$adjust_missing_surv_ss) {
            missing_adj <- calc_missing_data_inflation(
              n_base,
              input$missing_pct_surv_ss,
              input$missing_mechanism_surv_ss,
              input$missing_analysis_surv_ss,
              ifelse(input$missing_analysis_surv_ss == "multiple_imputation", input$mi_imputations_surv_ss, 5),
              ifelse(input$missing_analysis_surv_ss == "multiple_imputation", input$mi_r_squared_surv_ss, 0.5)
            )
            n_final <- missing_adj$n_inflated
            missing_data_text <- HTML(paste0(
              "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
              "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
              missing_adj$interpretation,
              "<br><strong>Sample size before adjustment:</strong> ", ceiling(n_base),
              "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
              "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
              "</p>"
            ))
          } else {
            n_final <- n_base
            missing_data_text <- HTML("")
          }

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "To detect a hazard ratio of ", format(hr, digits = 2, nsmall = 2),
            " with ", format(power * 100, digits = 0, nsmall = 0), "% power in a survival analysis using Cox regression, ",
            "with ", format(k * 100, digits = 1, nsmall = 0), "% of participants exposed/treated and an overall event rate of ",
            format(pE * 100, digits = 1, nsmall = 0), "%, the required total sample size is N = ",
            format(ceiling(n_final), digits = 0, nsmall = 0), " participants (α = ",
            input$surv_ss_alpha, ", two-sided test).",
            if (input$adjust_missing_surv_ss) {
              paste0(" <strong>This includes adjustment for ", input$missing_pct_surv_ss,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Hazard Ratio (Feature 2: Tier 1 Enhancement)
          n_nominal <- input$surv_ss_n_fixed

          # Account for missing data to get effective sample size
          if (input$adjust_missing_surv_ss) {
            p_missing <- input$missing_pct_surv_ss / 100
            n_effective <- ceiling(n_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", input$missing_pct_surv_ss,
              "% missing data (", tolower(substr(input$missing_mechanism_surv_ss, 1, 4)),
              "), the effective sample size is ", n_effective, " participants.")
          } else {
            n_effective <- n_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable HR using binary search
          # Search range: HR from 0.01 to 10
          hr_lower <- 0.01
          hr_upper <- 10.0
          tolerance <- 0.001
          max_iter <- 100

          for (i in 1:max_iter) {
            hr_mid <- (hr_lower + hr_upper) / 2
            power_achieved <- powerEpi(
              n = n_effective, theta = hr_mid, k = k, pE = pE,
              RR = hr_mid, alpha = input$surv_ss_alpha
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

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis (Tier 1 Enhancement)</strong><br>",
            "With an available sample size of N=", n_nominal, " participants,",
            missing_note,
            " With ", format(power * 100, digits = 0), "% power, α = ", input$surv_ss_alpha,
            ", ", format(k * 100, digits = 1), "% exposed/treated, and ",
            format(pE * 100, digits = 1), "% overall event rate, ",
            "the <strong>minimal detectable hazard ratio is HR = ",
            format(hr_detectable, digits = 3), "</strong>. ",
            "This is the smallest hazard ratio that can be reliably detected with this sample size using Cox regression. ",
            "This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect (Tier 1 Enhancement):</strong><br>",
            "<strong>Hazard Ratio (HR):</strong> ", format(hr_detectable, digits = 3), "<br>",
            "<strong>Interpretation:</strong> ",
            ifelse(hr_detectable < 1,
              paste0("Can detect protective effects with HR ≤ ", format(hr_detectable, digits = 3)),
              paste0("Can detect risk increases with HR ≥ ", format(hr_detectable, digits = 3))),
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }
      } else if (input$tabset == "Matched Case-Control") {
        # Feature 2: Minimal Detectable Effect Size Calculator
        calc_mode <- input$match_calc_mode
        p0 <- input$match_p0 / 100
        m <- input$match_ratio
        power <- input$match_power / 100
        sided_val <- ifelse(input$match_sided == "two.sided", 2, 1)

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          or <- input$match_or

          # Calculate base sample size for matched case-control using epiR
          result <- epi.sscc(
            OR = or, p0 = p0, n = NA, power = power,
            r = m, rho = 0, design = 1, sided.test = sided_val,
            conf.level = 1 - input$match_alpha
          )
          n_cases_base <- ceiling(result$n.total)
          n_controls_base <- n_cases_base * m
          n_total_base <- n_cases_base * (1 + m)

          # Apply missing data adjustment if enabled (Tier 1 Enhancement)
          if (input$adjust_missing_match) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              input$missing_pct_match,
              input$missing_mechanism_match,
              input$missing_analysis_match,
              ifelse(input$missing_analysis_match == "multiple_imputation", input$mi_imputations_match, 5),
              ifelse(input$missing_analysis_match == "multiple_imputation", input$mi_r_squared_match, 0.5)
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain matching ratio
            n_cases_final <- ceiling(n_total_final / (1 + m))
            n_controls_final <- n_cases_final * m

            missing_data_text <- HTML(paste0(
              "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
              "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
              missing_adj$interpretation,
              "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
              "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
              "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
              "</p>"
            ))
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
            format(or, digits = 2, nsmall = 2), " with ", format(power * 100, digits = 0, nsmall = 0),
            "% power, assuming ", format(p0 * 100, digits = 1, nsmall = 0),
            "% exposure prevalence in controls, and a ", m, ":1 matching ratio (controls per case), ",
            "the required sample size is ", n_cases_final, " cases and ",
            format(n_controls_final, digits = 0, nsmall = 0), " controls (total N = ",
            format(n_total_final, digits = 0, nsmall = 0), " participants) at α = ",
            input$match_alpha, " (", input$match_sided, " test).",
            if (input$adjust_missing_match) {
              paste0(" <strong>After adjusting for ", input$missing_pct_match,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " This accounts for correlation between matched pairs."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Odds Ratio (Feature 2: Tier 1 Enhancement)
          n_cases_nominal <- input$match_n_cases_fixed
          n_controls_nominal <- n_cases_nominal * m
          n_total_nominal <- n_cases_nominal * (1 + m)

          # Account for missing data to get effective sample sizes
          if (input$adjust_missing_match) {
            p_missing <- input$missing_pct_match / 100
            n_cases_effective <- ceiling(n_cases_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", input$missing_pct_match,
              "% missing data (", tolower(substr(input$missing_mechanism_match, 1, 4)),
              "), the effective number of cases is ", n_cases_effective, ".")
          } else {
            n_cases_effective <- n_cases_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable OR using binary search
          # Search range: OR from 0.1 to 10
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
                conf.level = 1 - input$match_alpha
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
            "<strong>Minimal Detectable Effect Size Analysis (Tier 1 Enhancement)</strong><br>",
            "With ", n_cases_nominal, " available cases and a ", m, ":1 matching ratio (",
            format(n_controls_nominal, digits = 0), " controls),",
            missing_note,
            " With ", format(power * 100, digits = 0), "% power and α = ", input$match_alpha,
            " (", input$match_sided, " test), assuming ",
            format(p0 * 100, digits = 1), "% exposure prevalence in controls, ",
            "the <strong>minimal detectable odds ratio is OR = ",
            format(or_detectable, digits = 3), "</strong>. ",
            "This is the smallest odds ratio that can be reliably detected with this sample size. ",
            "This accounts for correlation between matched pairs."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect (Tier 1 Enhancement):</strong><br>",
            "<strong>Odds Ratio (OR):</strong> ", format(or_detectable, digits = 3), "<br>",
            "<strong>Interpretation:</strong> ",
            ifelse(or_detectable < 1,
              paste0("Can detect protective effects with OR ≤ ", format(or_detectable, digits = 3)),
              paste0("Can detect risk increases with OR ≥ ", format(or_detectable, digits = 3))),
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }
      } else if (input$tabset == "Power (Continuous)") {
        n1 <- input$cont_pow_n1
        n2 <- input$cont_pow_n2
        d <- input$cont_pow_d

        # Calculate power for t-test
        power <- pwr.t2n.test(
          n1 = n1, n2 = n2, d = d,
          sig.level = input$cont_pow_alpha,
          alternative = input$cont_pow_sided
        )$power

        text0 <- hr()
        text1 <- h1("Results of this analysis")
        text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
        text3 <- p(paste0(
          "For a two-group comparison of continuous outcomes with sample sizes of n1 = ",
          n1, " and n2 = ", n2, ", and an expected effect size of Cohen's d = ",
          format(d, digits = 2, nsmall = 2), " (standardized mean difference), the study has ",
          format(power * 100, digits = 1, nsmall = 1), "% power to detect this difference using a two-sample t-test at α = ",
          input$cont_pow_alpha, " (", input$cont_pow_sided, " test). ",
          "Cohen's d represents the difference in means divided by the pooled standard deviation."
        ))
        HTML(paste0(text0, text1, text2, text3))
      } else if (input$tabset == "Sample Size (Continuous)") {
        # Feature 2: Minimal Detectable Effect Size Calculator
        calc_mode <- input$cont_ss_calc_mode
        power <- input$cont_ss_power / 100
        ratio <- input$cont_ss_ratio

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          d <- input$cont_ss_d

          # Calculate base sample size for t-test (solve for n1)
          if (ratio == 1) {
            n <- pwr.t.test(
              d = d, sig.level = input$cont_ss_alpha,
              power = power, type = "two.sample",
              alternative = input$cont_ss_sided
            )$n
            n1_base <- n
            n2_base <- n
          } else {
            # For unequal allocation, use iterative approach
            f <- function(n1) {
              n2 <- n1 * ratio
              pwr.t2n.test(
                n1 = n1, n2 = n2, d = d,
                sig.level = input$cont_ss_alpha,
                alternative = input$cont_ss_sided
              )$power - power
            }
            n1_base <- tryCatch(
              {
                uniroot(f, c(2, 1e6), extendInt = "yes")$root
              },
              error = function(e) {
                # Fallback
                pwr.t.test(
                  d = d, sig.level = input$cont_ss_alpha,
                  power = power, type = "two.sample",
                  alternative = input$cont_ss_sided
                )$n
              }
            )
            n2_base <- n1_base * ratio
          }
          n_total_base <- ceiling(n1_base + n2_base)

          # Apply missing data adjustment if enabled (Tier 1 Enhancement)
          if (input$adjust_missing_cont_ss) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              input$missing_pct_cont_ss,
              input$missing_mechanism_cont_ss,
              input$missing_analysis_cont_ss,
              ifelse(input$missing_analysis_cont_ss == "multiple_imputation", input$mi_imputations_cont_ss, 5),
              ifelse(input$missing_analysis_cont_ss == "multiple_imputation", input$mi_r_squared_cont_ss, 0.5)
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain allocation ratio
            n1_final <- ceiling(n_total_final / (1 + ratio))
            n2_final <- n_total_final - n1_final

            missing_data_text <- HTML(paste0(
              "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
              "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
              missing_adj$interpretation,
              "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
              "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
              "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
              "</p>"
            ))
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
            "To detect an effect size of Cohen's d = ", format(d, digits = 2, nsmall = 2),
            " in a two-group comparison of continuous outcomes with ", format(power * 100, digits = 0, nsmall = 0),
            "% power at α = ", input$cont_ss_alpha, " (", input$cont_ss_sided, " test), ",
            "the required sample sizes are: Group 1: n1 = ", format(n1_final, digits = 0, nsmall = 0),
            ", Group 2: n2 = ", format(n2_final, digits = 0, nsmall = 0), " (total N = ",
            format(n_total_final, digits = 0, nsmall = 0), ").",
            if (input$adjust_missing_cont_ss) {
              paste0(" <strong>After adjusting for ", input$missing_pct_cont_ss,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " Cohen's d is the standardized mean difference (difference in means / pooled SD)."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Effect Size (Feature 2: Tier 1 Enhancement)
          n1_nominal <- input$cont_ss_n1_fixed
          n2_nominal <- n1_nominal * ratio

          # Account for missing data to get effective sample sizes
          if (input$adjust_missing_cont_ss) {
            p_missing <- input$missing_pct_cont_ss / 100
            n1_effective <- ceiling(n1_nominal * (1 - p_missing))
            n2_effective <- ceiling(n2_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", input$missing_pct_cont_ss,
              "% missing data (", tolower(substr(input$missing_mechanism_cont_ss, 1, 4)),
              "), effective sample sizes are n1=", n1_effective, ", n2=", n2_effective, ".")
          } else {
            n1_effective <- n1_nominal
            n2_effective <- n2_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable d
          d_detectable <- pwr.t2n.test(
            n1 = n1_effective, n2 = n2_effective, d = NULL,
            sig.level = input$cont_ss_alpha, power = power,
            alternative = input$cont_ss_sided
          )$d

          text0 <- hr()
          text1 <- h1("Results of this analysis")
          text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
          text3 <- p(paste0(
            "<strong>Minimal Detectable Effect Size Analysis (Tier 1 Enhancement)</strong><br>",
            "With available sample sizes of n1=", n1_nominal, " (Group 1) and n2=",
            round(n2_nominal), " (Group 2, ratio=", ratio, "),",
            missing_note,
            " With ", format(power * 100, digits = 0), "% power and α = ", input$cont_ss_alpha,
            " (", input$cont_ss_sided, " test), ",
            "the <strong>minimal detectable effect size is Cohen's d = ",
            format(d_detectable, digits = 3), "</strong>. ",
            "This is the smallest standardized mean difference that can be reliably detected with this sample size. ",
            "Cohen's d is the standardized mean difference (difference in means / pooled SD)."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Effect (Tier 1 Enhancement):</strong><br>",
            "<strong>Cohen's d:</strong> ", format(d_detectable, digits = 3), "<br>",
            "<strong>Interpretation:</strong> ",
            ifelse(d_detectable < 0.2, "Very small effect",
              ifelse(d_detectable < 0.5, "Small effect",
                ifelse(d_detectable < 0.8, "Medium effect", "Large effect"))),
            " (Cohen 1988 guidelines: 0.2=small, 0.5=medium, 0.8=large)",
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }
      } else if (input$tabset == "Non-Inferiority") {
        # Feature 2: Minimal Detectable Effect Size Calculator
        calc_mode <- input$noninf_calc_mode
        p1 <- input$noninf_p1 / 100
        p2 <- input$noninf_p2 / 100
        power <- input$noninf_power / 100
        ratio <- input$noninf_ratio

        if (calc_mode == "calc_n") {
          # Calculate Sample Size (original functionality)
          margin <- input$noninf_margin / 100

          # Non-inferiority sample size calculation
          # H0: p1 - p2 >= margin (inferior), H1: p1 - p2 < margin (non-inferior)
          # Use one-sided test

          # Calculate effect size h for the margin test
          h <- ES.h(p1, p2 + margin)

          if (ratio == 1) {
            n <- pwr.2p.test(
              h = abs(h), sig.level = input$noninf_alpha,
              power = power, alternative = "less"
            )$n
            n1_base <- n
            n2_base <- n
          } else {
            f <- function(n1) {
              n2 <- n1 * ratio
              pwr.2p2n.test(
                h = abs(h), n1 = n1, n2 = n2,
                sig.level = input$noninf_alpha,
                alternative = "less"
              )$power - power
            }
            n1_base <- tryCatch(
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
            n2_base <- n1_base * ratio
          }
          n_total_base <- ceiling(n1_base + n2_base)

          # Apply missing data adjustment if enabled (Tier 1 Enhancement)
          if (input$adjust_missing_noninf) {
            missing_adj <- calc_missing_data_inflation(
              n_total_base,
              input$missing_pct_noninf,
              input$missing_mechanism_noninf,
              input$missing_analysis_noninf,
              ifelse(input$missing_analysis_noninf == "multiple_imputation", input$mi_imputations_noninf, 5),
              ifelse(input$missing_analysis_noninf == "multiple_imputation", input$mi_r_squared_noninf, 0.5)
            )
            n_total_final <- missing_adj$n_inflated
            # Maintain allocation ratio
            n1_final <- ceiling(n_total_final / (1 + ratio))
            n2_final <- n_total_final - n1_final

            missing_data_text <- HTML(paste0(
              "<p style='background-color: #fff3cd; border-left: 4px solid #f39c12; padding: 10px; margin-top: 15px;'>",
              "<strong>Missing Data Adjustment (Tier 1 Enhancement):</strong> ",
              missing_adj$interpretation,
              "<br><strong>Total sample size before adjustment:</strong> ", n_total_base,
              "<br><strong>Inflation factor:</strong> ", missing_adj$inflation_factor,
              "<br><strong>Additional participants needed:</strong> ", missing_adj$n_increase,
              "</p>"
            ))
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
            format(p1 * 100, digits = 2, nsmall = 1), "%) to a reference treatment (expected event rate: ",
            format(p2 * 100, digits = 2, nsmall = 1), "%) with a non-inferiority margin of ",
            format(margin * 100, digits = 2, nsmall = 1), " percentage points, to demonstrate non-inferiority with ",
            format(power * 100, digits = 0, nsmall = 0), "% power at α = ", input$noninf_alpha,
            " (one-sided test), the required sample sizes are: Test Group: n1 = ",
            format(n1_final, digits = 0, nsmall = 0), ", Reference Group: n2 = ",
            format(n2_final, digits = 0, nsmall = 0), " (total N = ",
            format(n_total_final, digits = 0, nsmall = 0), ").",
            if (input$adjust_missing_noninf) {
              paste0(" <strong>After adjusting for ", input$missing_pct_noninf,
                     "% missing data.</strong>")
            } else {
              ""
            },
            " Non-inferiority will be demonstrated if the upper bound of the confidence interval for the difference (Test - Reference) is less than the margin."
          ))
          HTML(paste0(text0, text1, text2, text3, missing_data_text))

        } else {
          # Calculate Margin (Feature 2: Tier 1 Enhancement)
          n1_nominal <- input$noninf_n1_fixed
          n2_nominal <- n1_nominal * ratio

          # Account for missing data to get effective sample sizes
          if (input$adjust_missing_noninf) {
            p_missing <- input$missing_pct_noninf / 100
            n1_effective <- ceiling(n1_nominal * (1 - p_missing))
            n2_effective <- ceiling(n2_nominal * (1 - p_missing))
            missing_note <- paste0(" After accounting for ", input$missing_pct_noninf,
              "% missing data (", tolower(substr(input$missing_mechanism_noninf, 1, 4)),
              "), effective sample sizes are n1=", n1_effective, ", n2=", n2_effective, ".")
          } else {
            n1_effective <- n1_nominal
            n2_effective <- n2_nominal
            missing_note <- ""
          }

          # Solve for minimal detectable margin using binary search
          # Search range: margin from 0.001 to 0.5 (0.1% to 50%)
          margin_lower <- 0.001
          margin_upper <- 0.5
          tolerance <- 0.001
          max_iter <- 100

          for (i in 1:max_iter) {
            margin_mid <- (margin_lower + margin_upper) / 2
            h <- ES.h(p1, p2 + margin_mid)

            power_achieved <- pwr.2p2n.test(
              h = abs(h), n1 = n1_effective, n2 = n2_effective,
              sig.level = input$noninf_alpha,
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
            "<strong>Minimal Detectable Margin Analysis (Tier 1 Enhancement)</strong><br>",
            "With available sample sizes of n1=", n1_nominal, " (Test Group) and n2=",
            round(n2_nominal), " (Reference Group, ratio=", ratio, "),",
            missing_note,
            " With ", format(power * 100, digits = 0), "% power and α = ", input$noninf_alpha,
            " (one-sided test), for a non-inferiority trial comparing test treatment (expected event rate: ",
            format(p1 * 100, digits = 2), "%) to reference treatment (expected event rate: ",
            format(p2 * 100, digits = 2), "%), ",
            "the <strong>minimal detectable non-inferiority margin is ",
            format(margin_detectable * 100, digits = 2), " percentage points</strong>. ",
            "This is the largest margin that can be reliably tested for non-inferiority with this sample size. ",
            "Non-inferiority will be demonstrated if the upper bound of the confidence interval for the difference (Test - Reference) is less than this margin."
          ))

          effect_size_box <- HTML(paste0(
            "<p style='background-color: #d4edda; border-left: 4px solid #28a745; padding: 10px; margin-top: 15px;'>",
            "<strong>Minimal Detectable Margin (Tier 1 Enhancement):</strong><br>",
            "<strong>Non-Inferiority Margin:</strong> ", format(margin_detectable * 100, digits = 2), " percentage points<br>",
            "<strong>Interpretation:</strong> Can demonstrate non-inferiority if the true difference (Test - Reference) is less than ",
            format(margin_detectable * 100, digits = 2), " percentage points",
            "</p>"
          ))

          HTML(paste0(text0, text1, text2, text3, effect_size_box))
        }
      } else if (input$sidebar_page == "vif_calculator") {
        # PAGE 11: Propensity Score VIF Calculator (Tier 1 Feature 4)

        # Get inputs
        n_rct <- input$vif_n_rct
        prevalence_pct <- input$vif_prevalence
        c_stat <- input$vif_cstat
        weight_method <- input$vif_method

        # Calculate VIF
        vif <- estimate_vif_propensity_score(c_stat, prevalence_pct, weight_method)

        # Calculate adjusted sample sizes
        n_adjusted <- ceiling(n_rct * vif)
        n_increase <- n_adjusted - n_rct
        pct_increase <- round((vif - 1) * 100, 1)
        n_effective <- floor(n_rct / vif)

        # Interpret VIF
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

        # Recommendations
        recommendations <- c()

        if (c_stat < 0.65) {
          recommendations <- c(recommendations,
            "⚠️ C-statistic is low. Consider including stronger confounders to improve propensity score model discrimination.")
        } else {
          recommendations <- c(recommendations,
            "✅ C-statistic is adequate for propensity score methods.")
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

        recommendations_html <- paste0(
          "<ul>",
          paste0("<li>", recommendations, "</li>", collapse = "\n"),
          "</ul>"
        )

        # Generate result HTML
        text0 <- hr()
        text1 <- h1("Propensity Score Weighting: VIF Results")
        text2 <- h4("(This analysis can be included in your Statistical Analysis Plan)")

        text3 <- HTML(paste0(
          "<h4>Weighting Method: ", method_desc$name, "</h4>",
          "<p>", method_desc$description, "</p>",
          "<p><strong>Target Population:</strong> ", method_desc$target, "</p>",

          "<hr>",
          "<h4>Propensity Score Model Assumptions</h4>",
          "<ul>",
          "<li><strong>Treatment prevalence:</strong> ", prevalence_pct, "%</li>",
          "<li><strong>Anticipated c-statistic:</strong> ", c_stat, " (", c_stat_interp, ")</li>",
          "</ul>",

          "<hr>",
          "<h4>Variance Inflation Factor (VIF)</h4>",
          "<p style='font-size: 1.2em;'><strong>VIF = ", vif, "</strong> ",
          "<span style='color: ", vif_interp$color, "; font-weight: bold;'>", vif_interp$icon, " ", vif_interp$level, " Efficiency Loss</span></p>",
          "<p>", vif_interp$message, "</p>",

          "<hr>",
          "<h4>Sample Size Adjustment</h4>",
          "<div style='background-color: #e3f2fd; border-left: 4px solid #2196f3; padding: 15px; margin: 10px 0;'>",
          "<p><strong>RCT-based sample size:</strong> ", format(n_rct, big.mark = ","), "</p>",
          "<p><strong>Inflation needed:</strong> +", pct_increase, "% (+", format(n_increase, big.mark = ","), " participants)</p>",
          "<p style='font-size: 1.3em; color: #d32f2f;'><strong>Adjusted sample size:</strong> ", format(n_adjusted, big.mark = ","), " participants</p>",
          "<p><strong>Effective sample size after weighting:</strong> ≈", format(n_effective, big.mark = ","), " (statistical information equivalent)</p>",
          "</div>",

          "<hr>",
          "<h4>Interpretation</h4>",
          "<p>To achieve the same statistical power as a randomized trial with N=", format(n_rct, big.mark = ","),
          ", an observational study using <strong>", method_desc$name, "</strong> weighting requires approximately <strong>N=",
          format(n_adjusted, big.mark = ","), " participants</strong> (assuming c-statistic=", c_stat, ").</p>",

          "<p>The effective sample size after propensity score weighting will be approximately ",
          format(n_effective, big.mark = ","),
          ", which provides statistical information equivalent to a randomized trial of that size.</p>",

          "<hr>",
          "<h4>Recommendations</h4>",
          recommendations_html,

          "<hr>",
          "<p style='font-size: 0.9em; color: #666;'><strong>Reference:</strong> Austin PC (2021). Informing power and sample size calculations when using inverse probability of treatment weighting using the propensity score. <em>Statistics in Medicine</em> 40(27):6150-6163.</p>"
        ))

        HTML(paste0(text0, text1, text2, text3))
      }
    })
  })

  ################################################################################################## EFFECT MEASURES (Two-Group and Survival)

  output$effect_measures <- renderUI({
    if (!v$doAnalysis) {
      return()
    }
    if (!grepl("Two-Group|Survival", input$tabset)) {
      return()
    }

    isolate({
      validate_inputs()

      if (grepl("Two-Group", input$tabset)) {
        if (input$tabset == "Power (Two-Group)") {
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
      } else if (grepl("Survival", input$tabset)) {
        if (input$tabset == "Power (Survival)") {
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
    if (input$tabset == "Matched Case-Control") {
      return()
    } # No plot for matched case-control

    isolate({
      text1 <- hr()
      if (grepl("Two-Group", input$tabset)) {
        if (input$tabset == "Power (Two-Group)") {
          ratio <- round(input$twogrp_pow_n2 / input$twogrp_pow_n1, 3)
        } else {
          ratio <- input$twogrp_ss_ratio
        }
        text2 <- h4(paste0("Estimated power vs. n1 (Group 1 sample size) with allocation ratio n2/n1 = ", ratio, "."))
      } else if (grepl("Survival", input$tabset)) {
        text2 <- h4("Power curve for survival analysis at different sample sizes.")
      } else {
        text2 <- h4("Estimated power for the given conditions at different sample sizes.")
      }
      HTML(paste0(text1, text2))
    })
  })

  ################################################################################################## POWER VS. SAMPLE SIZE PLOT (Feature 3: Interactive Power Curves)

  output$power_plot <- renderPlotly(
    {
      if (!v$doAnalysis) {
        return()
      }
      if (input$tabset == "Matched Case-Control") {
        return()
      } # No plot for matched case-control

      isolate({
        validate_inputs()

        if (input$tabset == "Power (Single)") {
          # Generate power curve data
          n_current <- input$power_n
          n_seq <- seq(max(10, floor(n_current * 0.25)),
            floor(n_current * 4),
            length.out = 100
          )
          pow <- vapply(n_seq, function(n) {
            pwr.p.test(
              sig.level = input$power_alpha, power = NULL,
              h = ES.h(1 / input$power_p, 0), alt = "greater", n = n
            )$power
          }, FUN.VALUE = numeric(1))

          # Create interactive plotly
          plot_ly() %>%
            add_trace(
              x = n_seq, y = pow, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3),
              name = "Power Curve",
              hovertemplate = paste0(
                "<b>Sample Size:</b> %{x:.0f}<br>",
                "<b>Power:</b> %{y:.3f}<br>",
                "<extra></extra>"
              )
            ) %>%
            add_trace(
              x = range(n_seq), y = c(0.8, 0.8),
              type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"),
              name = "80% Power Target",
              hovertemplate = "<b>Target Power:</b> 80%<extra></extra>"
            ) %>%
            add_trace(
              x = c(n_current, n_current), y = c(0, 1),
              type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"),
              name = "Current N",
              hovertemplate = paste0("<b>Current N:</b> ", n_current, "<extra></extra>")
            ) %>%
            layout(
              title = list(text = "Interactive Power Curve (Tier 1 Enhancement)", font = list(size = 16)),
              xaxis = list(title = "Sample Size (N)", gridcolor = "#e0e0e0"),
              yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
              hovermode = "closest",
              plot_bgcolor = "#f8f9fa",
              paper_bgcolor = "white",
              legend = list(x = 0.7, y = 0.2)
            ) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)

        } else if (input$tabset == "Sample Size (Single)") {
          # Generate power curve data
          target_power <- input$ss_power / 100
          n_required <- pwr.p.test(
            sig.level = input$ss_alpha, power = target_power,
            h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
          )$n
          n_seq <- seq(max(10, floor(n_required * 0.25)),
            floor(n_required * 3),
            length.out = 100
          )
          pow <- vapply(n_seq, function(n) {
            pwr.p.test(
              sig.level = input$ss_alpha, power = NULL,
              h = ES.h(1 / input$ss_p, 0), alt = "greater", n = n
            )$power
          }, FUN.VALUE = numeric(1))

          # Create interactive plotly
          plot_ly() %>%
            add_trace(
              x = n_seq, y = pow, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3),
              name = "Power Curve",
              hovertemplate = paste0(
                "<b>Sample Size:</b> %{x:.0f}<br>",
                "<b>Power:</b> %{y:.3f}<br>",
                "<extra></extra>"
              )
            ) %>%
            add_trace(
              x = range(n_seq), y = c(target_power, target_power),
              type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"),
              name = paste0("Target Power (", round(target_power * 100), "%)"),
              hovertemplate = paste0("<b>Target Power:</b> ", round(target_power * 100), "%<extra></extra>")
            ) %>%
            add_trace(
              x = c(n_required, n_required), y = c(0, 1),
              type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"),
              name = "Required N",
              hovertemplate = paste0("<b>Required N:</b> ", round(n_required), "<extra></extra>")
            ) %>%
            layout(
              title = list(text = "Interactive Power Curve (Tier 1 Enhancement)", font = list(size = 16)),
              xaxis = list(title = "Sample Size (N)", gridcolor = "#e0e0e0"),
              yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
              hovermode = "closest",
              plot_bgcolor = "#f8f9fa",
              paper_bgcolor = "white",
              legend = list(x = 0.7, y = 0.2)
            ) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)
        } else if (input$tabset == "Power (Two-Group)") {
          # Ratio-aware interactive plot for unequal allocation
          p1 <- input$twogrp_pow_p1 / 100
          p2 <- input$twogrp_pow_p2 / 100
          ratio <- input$twogrp_pow_n2 / input$twogrp_pow_n1
          n1_current <- input$twogrp_pow_n1

          # Generate power curve varying n1
          n1_seq <- seq(max(5, floor(n1_current * 0.25)),
            floor(n1_current * 4),
            length.out = 100
          )
          pow <- vapply(n1_seq, function(n1) {
            pwr.2p2n.test(
              h = ES.h(p1, p2), n1 = n1, n2 = n1 * ratio,
              sig.level = input$twogrp_pow_alpha,
              alternative = input$twogrp_pow_sided
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
              x = range(n1_seq), y = c(0.8, 0.8),
              type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"),
              name = "80% Power Target",
              hovertemplate = "<b>Target Power:</b> 80%<extra></extra>"
            ) %>%
            add_trace(
              x = c(n1_current, n1_current), y = c(0, 1),
              type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"),
              name = "Current n1",
              hovertemplate = paste0("<b>Current n1:</b> ", n1_current, "<extra></extra>")
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

        } else if (input$tabset == "Sample Size (Two-Group)") {
          # Ratio-aware interactive plot for sample size calculation
          p1 <- input$twogrp_ss_p1 / 100
          p2 <- input$twogrp_ss_p2 / 100
          ratio <- input$twogrp_ss_ratio
          target <- input$twogrp_ss_power / 100

          # Calculate required n1
          n1_required <- solve_n1_for_ratio(
            ES.h(p1, p2), ratio,
            input$twogrp_ss_alpha, target, input$twogrp_ss_sided
          )

          # Generate power curve varying n1
          n1_seq <- seq(max(5, floor(n1_required * 0.25)), floor(n1_required * 3), length.out = 100)
          pow <- vapply(n1_seq, function(n1) {
            pwr.2p2n.test(
              h = ES.h(p1, p2), n1 = n1, n2 = n1 * ratio,
              sig.level = input$twogrp_ss_alpha,
              alternative = input$twogrp_ss_sided
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
        } else if (grepl("Survival", input$tabset)) {
          # Generate power curve for survival analysis
          if (input$tabset == "Power (Survival)") {
            hr <- input$surv_pow_hr
            k <- input$surv_pow_k / 100
            pE <- input$surv_pow_pE / 100
            alpha <- input$surv_pow_alpha
            current_n <- input$surv_pow_n
          } else {
            hr <- input$surv_ss_hr
            k <- input$surv_ss_k / 100
            pE <- input$surv_ss_pE / 100
            alpha <- input$surv_ss_alpha
            current_n <- ssizeEpi(
              power = input$surv_ss_power / 100, theta = hr, k = k,
              pE = pE, RR = hr, alpha = alpha
            )
          }

          # Generate sample size range
          n_range <- seq(from = max(50, current_n * 0.5), to = current_n * 2, length.out = 50)
          power_vals <- vapply(n_range, function(n) {
            powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = alpha)
          }, FUN.VALUE = numeric(1))

          # Create interactive plotly
          plot_ly() %>%
            add_trace(
              x = n_range, y = power_vals, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3),
              name = "Power Curve",
              hovertemplate = paste0(
                "<b>Sample Size (N):</b> %{x:.0f}<br>",
                "<b>Power:</b> %{y:.3f}<br>",
                "<b>HR:</b> ", round(hr, 3), "<br>",
                "<extra></extra>"
              )
            ) %>%
            add_trace(
              x = range(n_range), y = c(0.8, 0.8),
              type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"),
              name = "80% Power Target",
              hovertemplate = "<b>Target Power:</b> 80%<extra></extra>"
            ) %>%
            add_trace(
              x = c(current_n, current_n), y = c(0, 1),
              type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"),
              name = paste(if(input$tabset == "Power (Survival)") "Current N" else "Required N"),
              hovertemplate = paste0("<b>", if(input$tabset == "Power (Survival)") "Current N" else "Required N", ":</b> ", round(current_n), "<extra></extra>")
            ) %>%
            layout(
              title = list(text = "Interactive Power Curve - Survival Analysis (Tier 1 Enhancement)", font = list(size = 16)),
              xaxis = list(title = "Total Sample Size (N)", gridcolor = "#e0e0e0"),
              yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
              hovermode = "closest",
              plot_bgcolor = "#f8f9fa",
              paper_bgcolor = "white",
              legend = list(x = 0.7, y = 0.2)
            ) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)
        } else if (grepl("Continuous", input$tabset)) {
          # Generate power curve for continuous outcomes (t-test)
          if (input$tabset == "Power (Continuous)") {
            n1 <- input$cont_pow_n1
            n2 <- input$cont_pow_n2
            d <- input$cont_pow_d
            alpha <- input$cont_pow_alpha
            sided <- input$cont_pow_sided
            current_n1 <- n1
          } else {
            # Sample Size (Continuous)
            d <- input$cont_ss_d
            alpha <- input$cont_ss_alpha
            sided <- input$cont_ss_sided
            ratio <- input$cont_ss_ratio
            target_power <- input$cont_ss_power / 100

            # Calculate required n1
            n1_test <- pwr.t2n.test(
              d = d, n1 = NULL, n2 = NULL,
              sig.level = alpha, power = target_power,
              alternative = sided
            )$n1
            n1 <- n1_test
            n2 <- n1 * ratio
            current_n1 <- ceiling(n1)
          }

          # Generate sample size range for n1
          n1_range <- seq(from = max(5, floor(current_n1 * 0.25)), to = floor(current_n1 * 3), length.out = 100)
          power_vals <- vapply(n1_range, function(n1_val) {
            n2_val <- if(input$tabset == "Power (Continuous)") n2 else n1_val * ratio
            pwr.t2n.test(
              d = d, n1 = n1_val, n2 = n2_val,
              sig.level = alpha, alternative = sided
            )$power
          }, FUN.VALUE = numeric(1))

          # Create interactive plotly
          plot_ly() %>%
            add_trace(
              x = n1_range, y = power_vals, type = "scatter", mode = "lines",
              line = list(color = "#2B5876", width = 3),
              name = "Power Curve",
              hovertemplate = paste0(
                "<b>n1 (Group 1):</b> %{x:.0f}<br>",
                "<b>n2 (Group 2):</b> ",
                if(input$tabset == "Power (Continuous)") round(n2, 0) else "varies with ratio",
                "<br>",
                "<b>Power:</b> %{y:.3f}<br>",
                "<b>Cohen's d:</b> ", round(d, 3), "<br>",
                "<extra></extra>"
              )
            ) %>%
            add_trace(
              x = range(n1_range), y = c(0.8, 0.8),
              type = "scatter", mode = "lines",
              line = list(color = "red", width = 2, dash = "dash"),
              name = "80% Power Target",
              hovertemplate = "<b>Target Power:</b> 80%<extra></extra>"
            ) %>%
            add_trace(
              x = c(current_n1, current_n1), y = c(0, 1),
              type = "scatter", mode = "lines",
              line = list(color = "green", width = 2, dash = "dot"),
              name = paste(if(input$tabset == "Power (Continuous)") "Current n1" else "Required n1"),
              hovertemplate = paste0("<b>", if(input$tabset == "Power (Continuous)") "Current n1" else "Required n1", ":</b> ", round(current_n1), "<extra></extra>")
            ) %>%
            layout(
              title = list(text = "Interactive Power Curve - Continuous Outcomes (Tier 1 Enhancement)", font = list(size = 16)),
              xaxis = list(title = "Sample Size Group 1 (n1)", gridcolor = "#e0e0e0"),
              yaxis = list(title = "Power", range = c(0, 1), gridcolor = "#e0e0e0"),
              hovermode = "closest",
              plot_bgcolor = "#f8f9fa",
              paper_bgcolor = "white",
              legend = list(x = 0.7, y = 0.2)
            ) %>%
            config(displayModeBar = TRUE, displaylogo = FALSE)
        }
      })
    }
  ) %>%
    bindCache(
      input$tabset,
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
      # Include doAnalysis flag to invalidate cache when Calculate is pressed
      v$doAnalysis
    )

  ################################################################################################## TABLE TITLE

  output$table_title <- renderUI({
    if (!v$doAnalysis) {
      return()
    }
    if (grepl("Two-Group", input$tabset)) {
      return()
    } # Only show for single proportion

    isolate({
      validate_inputs()

      if (input$tabset == "Power (Single)") {
        sample_size <- input$power_n
      } else {
        sample_size <- pwr.p.test(
          sig.level = input$ss_alpha, power = input$ss_power / 100,
          h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
        )$n
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
      if (grepl("Two-Group", input$tabset)) {
        return()
      } # Only show for single proportion

      isolate({
        validate_inputs()

        if (input$tabset == "Power (Single)") {
          sample_size <- input$power_n
        } else {
          sample_size <- pwr.p.test(
            sig.level = input$ss_alpha, power = input$ss_power / 100,
            h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
          )$n
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
    if (grepl("Two-Group", input$tabset)) {
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
      text2 <- downloadButton("report_pdf", "Download Analysis (PDF) [Experimental]")
      text3 <- downloadButton("report_csv", "Download Results (CSV)", class = "btn-info")
      text4 <- hr()
      HTML(paste0(text1, " ", text2, " ", text3, " ", text4))
    })
  })

  ################################################################################################## CSV DOWNLOAD

  output$report_csv <- downloadHandler(
    filename = function() {
      paste("Power-Analysis-", input$tabset, "-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      if (input$tabset == "Power (Single)") {
        results <- data.frame(
          Analysis_Type = "Single Proportion - Power Calculation",
          Sample_Size = input$power_n,
          Event_Frequency_1_in = input$power_p,
          Event_Rate_Percent = 100 / input$power_p,
          Power_Percent = pwr.p.test(
            sig.level = input$power_alpha, power = NULL,
            h = ES.h(1 / input$power_p, 0), alt = "greater",
            n = input$power_n
          )$power * 100,
          Significance_Level = input$power_alpha,
          Discontinuation_Rate_Percent = input$power_discon,
          Adjusted_Sample_Size = ceiling(input$power_n * (1 + input$power_discon / 100)),
          Date = Sys.Date()
        )
      } else if (input$tabset == "Sample Size (Single)") {
        sample_size <- pwr.p.test(
          sig.level = input$ss_alpha, power = input$ss_power / 100,
          h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
        )$n
        results <- data.frame(
          Analysis_Type = "Single Proportion - Sample Size Calculation",
          Desired_Power_Percent = input$ss_power,
          Event_Frequency_1_in = input$ss_p,
          Event_Rate_Percent = 100 / input$ss_p,
          Required_Sample_Size = ceiling(sample_size),
          Significance_Level = input$ss_alpha,
          Discontinuation_Rate_Percent = input$ss_discon,
          Adjusted_Sample_Size = ceiling(sample_size * (1 + input$ss_discon / 100)),
          Date = Sys.Date()
        )
      } else if (input$tabset == "Power (Two-Group)") {
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
      } else if (input$tabset == "Sample Size (Two-Group)") {
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
      } else if (input$tabset == "Power (Survival)") {
        n <- input$surv_pow_n
        hr <- input$surv_pow_hr
        k <- input$surv_pow_k / 100
        pE <- input$surv_pow_pE / 100
        power <- powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_pow_alpha)
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
      } else if (input$tabset == "Sample Size (Survival)") {
        hr <- input$surv_ss_hr
        k <- input$surv_ss_k / 100
        pE <- input$surv_ss_pE / 100
        power <- input$surv_ss_power / 100
        n_est <- ssizeEpi(power = power, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_ss_alpha)
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
      } else if (input$tabset == "Matched Case-Control") {
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
      } else if (input$tabset == "Power (Continuous)") {
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
      } else if (input$tabset == "Sample Size (Continuous)") {
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
      } else if (input$tabset == "Non-Inferiority") {
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
      }

      write.csv(results, file, row.names = FALSE)
    }
  )

  ################################################################################################## PDF DOWNLOAD (original)

  output$report_pdf <- downloadHandler(
    filename = paste("Rule-of-3-Analysis-", Sys.Date(), ".pdf", sep = ""),
    content = function(file) {
      # Only works for single proportion analyses
      if (grepl("Two-Group", input$tabset)) {
        showNotification("PDF export not yet available for two-group analyses. Please use CSV export.",
          type = "warning", duration = 5
        )
        return()
      }

      incidence_rate <- ifelse(input$tabset == "Power (Single)", input$power_p, input$ss_p)
      sample_size <- if (input$tabset == "Power (Single)") {
        input$power_n
      } else {
        pwr.p.test(
          sig.level = input$ss_alpha, power = input$ss_power / 100,
          h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
        )$n
      }

      power <- if (input$tabset == "Power (Single)") {
        pwr.p.test(
          sig.level = input$power_alpha, power = NULL,
          h = ES.h(1 / input$power_p, 0), alt = "greater", n = input$power_n
        )$power
      } else {
        input$ss_power / 100
      }

      discon <- if (input$tabset == "Power (Single)") {
        input$power_discon / 100
      } else {
        input$ss_discon / 100
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
        tabset = input$tabset,
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

      if (input$tabset == "Power (Single)") {
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Single Prop - Power",
          Sample_Size = input$power_n,
          Event_Freq = paste0("1 in ", input$power_p),
          Power_Pct = round(pwr.p.test(
            sig.level = input$power_alpha, power = NULL,
            h = ES.h(1 / input$power_p, 0), alt = "greater",
            n = input$power_n
          )$power * 100, 1),
          Alpha = input$power_alpha,
          Disc_Rate = paste0(input$power_discon, "%"),
          Adj_N = ceiling(input$power_n * (1 + input$power_discon / 100)),
          stringsAsFactors = FALSE
        )
      } else if (input$tabset == "Sample Size (Single)") {
        sample_size <- pwr.p.test(
          sig.level = input$ss_alpha, power = input$ss_power / 100,
          h = ES.h(1 / input$ss_p, 0), alt = "greater", n = NULL
        )$n
        new_scenario <- data.frame(
          Scenario = v$scenario_counter,
          Type = "Single Prop - SS",
          Sample_Size = ceiling(sample_size),
          Event_Freq = paste0("1 in ", input$ss_p),
          Power_Pct = input$ss_power,
          Alpha = input$ss_alpha,
          Disc_Rate = paste0(input$ss_discon, "%"),
          Adj_N = ceiling(sample_size * (1 + input$ss_discon / 100)),
          stringsAsFactors = FALSE
        )
      } else if (input$tabset == "Power (Two-Group)") {
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
      } else if (input$tabset == "Sample Size (Two-Group)") {
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
      } else if (input$tabset == "Power (Survival)") {
        n <- input$surv_pow_n
        hr <- input$surv_pow_hr
        k <- input$surv_pow_k / 100
        pE <- input$surv_pow_pE / 100
        power <- powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_pow_alpha)
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
      } else if (input$tabset == "Sample Size (Survival)") {
        hr <- input$surv_ss_hr
        k <- input$surv_ss_k / 100
        pE <- input$surv_ss_pE / 100
        power <- input$surv_ss_power / 100
        n_est <- ssizeEpi(power = power, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_ss_alpha)
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
      } else if (input$tabset == "Matched Case-Control") {
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

# Run the application
shinyApp(ui = ui, server = server)
