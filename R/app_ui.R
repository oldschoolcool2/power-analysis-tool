#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`. DO NOT REMOVE.
#' @noRd
#' 
#' @importFrom shiny fluidPage tags
#' @importFrom bslib bs_theme font_google
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),
    
    # Your application UI logic
    
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
    tags$link(rel = "icon", type = "image/svg+xml", href = "www/favicon.svg"),
    # CSS - version constant for cache busting (update when CSS changes)
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/design-tokens.css?v=1.1.0"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/modern-theme.css?v=1.1.0"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/input-components.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/responsive.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/sidebar.css"),
    # JavaScript - Bootstrap 5 fix must load before other scripts
    tags$script(src = "www/js/bootstrap5-shinyBS-fix.js"),
    tags$script(src = "www/js/theme-switcher.js"),
    tags$script(src = "www/js/sidebar-navigation.js"),
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

          # ==============================================================================
          # TAB 1: SINGLE PROPORTION [MODULARIZED]
          # ==============================================================================
          mod_01_single_proportion_ui("tab1"),

          # PAGE 3: Two-Group - Power Analysis
          conditionalPanel(
            condition = "input.sidebar_page == 'power_twogrp'",
            h2(class = "page-title", "Two-Group Comparison: Power Analysis"),
            helpText("Calculate power for comparing two proportions (e.g., exposed vs. unexposed in cohort studies)"),
            hr(),
            create_numeric_input_with_tooltip(
              "twogrp_pow_n1",
              "Sample Size Group 1:",
              value = 200,
              min = 1,
              step = 1,
              tooltip = "Number of participants in exposed/treatment group"
            ),
            create_numeric_input_with_tooltip(
              "twogrp_pow_n2",
              "Sample Size Group 2:",
              value = 200,
              min = 1,
              step = 1,
              tooltip = "Number of participants in unexposed/control group"
            ),
            create_numeric_input_with_tooltip(
              "twogrp_pow_p1",
              "Event Rate Group 1 (%):",
              value = 10,
              min = 0,
              max = 100,
              step = 0.1,
              tooltip = "Expected event rate in exposed/treatment group (as percentage)"
            ),
            create_numeric_input_with_tooltip(
              "twogrp_pow_p2",
              "Event Rate Group 2 (%):",
              value = 5,
              min = 0,
              max = 100,
              step = 0.1,
              tooltip = "Expected event rate in unexposed/control group (as percentage)"
            ),
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
            helpText("Calculate required sample size OR minimal detectable effect size"),
            hr(),
            radioButtons_fixed("twogrp_ss_calc_mode",
              "Calculation Mode:",
              choices = c(
                "Calculate Sample Size (given effect size)" = "calc_n",
                "Calculate Effect Size (given sample size)" = "calc_effect"
              ),
              selected = "calc_n"
            ),
            bsTooltip("twogrp_ss_calc_mode",
              "Choose whether to calculate required sample size or minimal detectable effect size",
              "right"
            ),
            hr(),
            create_segmented_power("twogrp_ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            conditionalPanel(
              condition = "input.twogrp_ss_calc_mode == 'calc_n'",
              create_numeric_input_with_tooltip("twogrp_ss_p1", "Event Rate Group 1 (%):", 10,
                                               min = 0, max = 100, step = 0.1,
                                               tooltip = "Expected event rate in exposed/treatment group (as percentage)"),
              create_numeric_input_with_tooltip("twogrp_ss_p2", "Event Rate Group 2 (%):", 5,
                                               min = 0, max = 100, step = 0.1,
                                               tooltip = "Expected event rate in unexposed/control group (as percentage)")
            ),
            conditionalPanel(
              condition = "input.twogrp_ss_calc_mode == 'calc_effect'",
              create_numeric_input_with_tooltip("twogrp_ss_n1_fixed", "Available Sample Size (Group 1):", 500,
                                               min = 10, step = 1,
                                               tooltip = "Fixed sample size available for Group 1"),
              create_numeric_input_with_tooltip("twogrp_ss_p2_baseline", "Baseline Event Rate Group 2 (%):", 10,
                                               min = 0, max = 100, step = 0.1,
                                               tooltip = "Expected event rate in control/unexposed group (as percentage)")
            ),
            create_numeric_input_with_tooltip("twogrp_ss_ratio", "Allocation Ratio (n2/n1):", 1,
                                             min = 0.1, max = 10, step = 0.1,
                                             tooltip = "Ratio of Group 2 to Group 1 sample size. 1 = equal groups, 2 = twice as many in Group 2"),
            create_segmented_alpha("twogrp_ss_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("twogrp_ss_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
              selected = "two.sided"
            ),
            hr(),
            missing_data_ui("twogrp_ss-missing_data"),
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
            create_numeric_input_with_tooltip("surv_pow_n", "Total Sample Size:", 500,
                                             min = 10, step = 10,
                                             tooltip = "Total number of participants in the study"),
            create_numeric_input_with_tooltip("surv_pow_hr", "Hazard Ratio (HR):", 0.7,
                                             min = 0.01, max = 10, step = 0.05,
                                             tooltip = "Expected hazard ratio (HR < 1 indicates protective effect, HR > 1 indicates risk)"),
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
            helpText("Calculate required sample size OR minimal detectable hazard ratio"),
            hr(),
            radioButtons_fixed("surv_ss_calc_mode",
              "Calculation Mode:",
              choices = c(
                "Calculate Sample Size (given hazard ratio)" = "calc_n",
                "Calculate Hazard Ratio (given sample size)" = "calc_effect"
              ),
              selected = "calc_n"
            ),
            bsTooltip("surv_ss_calc_mode",
              "Choose whether to calculate required sample size or minimal detectable hazard ratio",
              "right"
            ),
            hr(),
            create_segmented_power("surv_ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            conditionalPanel(
              condition = "input.surv_ss_calc_mode == 'calc_n'",
              create_numeric_input_with_tooltip("surv_ss_hr", "Hazard Ratio (HR):", 0.7,
                                               min = 0.01, max = 10, step = 0.05,
                                               tooltip = "Expected hazard ratio to detect")
            ),
            conditionalPanel(
              condition = "input.surv_ss_calc_mode == 'calc_effect'",
              create_numeric_input_with_tooltip("surv_ss_n_fixed", "Available Sample Size:", 500,
                                               min = 10, step = 10,
                                               tooltip = "Fixed total sample size available for the study")
            ),
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
            missing_data_ui("surv_ss-missing_data"),
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
            helpText("Calculate sample size OR minimal detectable odds ratio"),
            hr(),
            radioButtons_fixed("match_calc_mode",
              "Calculation Mode:",
              choices = c(
                "Calculate Sample Size (given odds ratio)" = "calc_n",
                "Calculate Odds Ratio (given sample size)" = "calc_effect"
              ),
              selected = "calc_n"
            ),
            bsTooltip("match_calc_mode",
              "Choose whether to calculate required sample size or minimal detectable odds ratio",
              "right"
            ),
            hr(),
            create_segmented_power("match_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            conditionalPanel(
              condition = "input.match_calc_mode == 'calc_n'",
              create_numeric_input_with_tooltip("match_or", "Odds Ratio (OR):", 2.0,
                min = 0.01, max = 20, step = 0.1,
                tooltip = "Expected odds ratio to detect (OR < 1 protective, OR > 1 risk factor)")
            ),
            conditionalPanel(
              condition = "input.match_calc_mode == 'calc_effect'",
              create_numeric_input_with_tooltip("match_n_pairs_fixed", "Available Number of Matched Pairs:", 100,
                min = 10, step = 5,
                tooltip = "Fixed number of matched case-control pairs available")
            ),
            create_enhanced_slider("match_p0", "Exposure Probability in Controls (%):",
                                  min = 5, max = 95, value = 20, step = 5, post = "%",
                                  tooltip = "Expected proportion of controls exposed to the risk factor"),
            create_numeric_input_with_tooltip("match_ratio", "Controls per Case:", 1,
              min = 1, max = 5, step = 1,
              tooltip = "Number of matched controls per case (typically 1:1, 2:1, or 3:1)"),
            create_segmented_alpha("match_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("match_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
              selected = "two.sided"
            ),
            bsTooltip("match_sided", "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
            hr(),
            missing_data_ui("match-missing_data"),
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
            create_numeric_input_with_tooltip("cont_pow_n1", "Sample Size Group 1:", 100,
              min = 2, step = 1,
              tooltip = "Number of participants in treatment/exposed group"),
            create_numeric_input_with_tooltip("cont_pow_n2", "Sample Size Group 2:", 100,
              min = 2, step = 1,
              tooltip = "Number of participants in control/unexposed group"),
            create_numeric_input_with_tooltip("cont_pow_d", "Effect Size (Cohen's d):", 0.5,
              min = 0.01, max = 5, step = 0.1,
              tooltip = "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8"),
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
            helpText("Calculate required sample size OR minimal detectable effect size"),
            hr(),
            radioButtons_fixed("cont_ss_calc_mode",
              "Calculation Mode:",
              choices = c(
                "Calculate Sample Size (given effect size)" = "calc_n",
                "Calculate Effect Size (given sample size)" = "calc_effect"
              ),
              selected = "calc_n"
            ),
            bsTooltip("cont_ss_calc_mode",
              "Choose whether to calculate required sample size or minimal detectable effect size (Cohen's d)",
              "right"
            ),
            hr(),
            create_segmented_power("cont_ss_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of detecting the effect if it exists"),
            conditionalPanel(
              condition = "input.cont_ss_calc_mode == 'calc_n'",
              create_numeric_input_with_tooltip("cont_ss_d", "Effect Size (Cohen's d):", 0.5, min = 0.01, max = 5, step = 0.1,
                tooltip = "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8")
            ),
            conditionalPanel(
              condition = "input.cont_ss_calc_mode == 'calc_effect'",
              create_numeric_input_with_tooltip("cont_ss_n1_fixed", "Available Sample Size (Group 1):", 100, min = 2, step = 1,
                tooltip = "Fixed sample size available for Group 1")
            ),
            create_numeric_input_with_tooltip("cont_ss_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1,
              tooltip = "Ratio of Group 2 to Group 1 sample size. 1 = equal groups"),
            create_segmented_alpha("cont_ss_alpha", "Significance Level (α):",
                                  selected = 0.05,
                                  tooltip = "Type I error rate (typically 0.05)"),
            radioButtons_fixed("cont_ss_sided", "Test Type:",
              choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
              selected = "two.sided"
            ),
            hr(),
            missing_data_ui("cont_ss-missing_data"),
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
            helpText("Calculate sample size OR minimal detectable non-inferiority margin"),
            hr(),
            radioButtons_fixed("noninf_calc_mode",
              "Calculation Mode:",
              choices = c(
                "Calculate Sample Size (given margin)" = "calc_n",
                "Calculate Margin (given sample size)" = "calc_effect"
              ),
              selected = "calc_n"
            ),
            bsTooltip("noninf_calc_mode",
              "Choose whether to calculate required sample size or minimal detectable non-inferiority margin",
              "right"
            ),
            hr(),
            create_segmented_power("noninf_power", "Desired Power:",
                                  selected = 80,
                                  tooltip = "Probability of demonstrating non-inferiority if true"),
            create_numeric_input_with_tooltip("noninf_p1", "Event Rate Test Group (%):", 10,
              min = 0, max = 100, step = 0.1,
              tooltip = "Expected event rate in test/generic group (as percentage)"),
            create_numeric_input_with_tooltip("noninf_p2", "Event Rate Reference Group (%):", 10,
              min = 0, max = 100, step = 0.1,
              tooltip = "Expected event rate in reference/branded group (as percentage)"),
            conditionalPanel(
              condition = "input.noninf_calc_mode == 'calc_n'",
              create_numeric_input_with_tooltip("noninf_margin", "Non-Inferiority Margin (%):", 5,
                min = 0.1, max = 50, step = 0.5,
                tooltip = "Maximum clinically acceptable difference (percentage points). Test is non-inferior if difference < margin.")
            ),
            conditionalPanel(
              condition = "input.noninf_calc_mode == 'calc_effect'",
              create_numeric_input_with_tooltip("noninf_n1_fixed", "Available Sample Size (Test Group):", 500,
                min = 10, step = 10,
                tooltip = "Fixed sample size available for test/generic group")
            ),
            create_numeric_input_with_tooltip("noninf_ratio", "Allocation Ratio (n2/n1):", 1,
              min = 0.1, max = 10, step = 0.1,
              tooltip = "Ratio of Reference to Test group size. 1 = equal groups"),
            create_segmented_alpha("noninf_alpha", "Significance Level (α):",
                                  choices = c("0.01" = 0.01, "0.025" = 0.025, "0.05" = 0.05, "0.10" = 0.10),
                                  selected = 0.025,
                                  tooltip = "Type I error rate (typically 0.025 for one-sided non-inferiority test)"),
            hr(),
            missing_data_ui("noninf-missing_data"),
            hr(),
            div(class = "btn-group-custom",
              actionButton("example_noninf", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
              actionButton("reset_noninf", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
            )
          ),

          # PAGE 11: Propensity Score Calculator (Austin 2021 + Li et al. 2025)
          conditionalPanel(
            condition = "input.sidebar_page == 'vif_calculator'",
            h2(class = "page-title", "Propensity Score Methods: Sample Size Calculator"),
            helpText("Calculate required sample size for propensity score studies using Austin (2021) VIF or Li et al. (2025) methods"),
            hr(),

            # Method selection
            radioButtons_fixed("ps_calc_method",
              "Calculation Method:",
              choices = c(
                "Austin (2021) - VIF Method (Traditional)" = "austin",
                "Li et al. (2025) - Overlap + Confounding Method (NEW)" = "li_2025"
              ),
              selected = "austin"),
            bsTooltip("ps_calc_method",
              "Austin (2021): Uses c-statistic to estimate VIF. Li et al. (2025): More accurate, accounts for overlap AND confounder-outcome association",
              "right"),

            hr(),

            # RCT-based sample size input
            create_numeric_input_with_tooltip(
              "vif_n_rct",
              "Required Sample Size (RCT Calculation):",
              value = 500,
              min = 10,
              step = 10,
              tooltip = "Sample size calculated from standard power analysis (as if it were a randomized trial)"
            ),

            # Propensity score model characteristics
            hr(),
            h4("Propensity Score Model Assumptions"),

            create_enhanced_slider("vif_prevalence",
              "Treatment Prevalence (%):",
              min = 10, max = 90, value = 50, step = 5, post = "%",
              tooltip = "Percentage of participants in the treatment/exposed group"),

            # Austin method inputs
            conditionalPanel(
              condition = "input.ps_calc_method == 'austin'",
              create_enhanced_slider("vif_cstat",
                "Anticipated C-statistic of PS Model:",
                min = 0.55, max = 0.95, value = 0.70, step = 0.05, post = "",
                tooltip = "Discriminative ability of propensity score model. 0.5=no discrimination, 1.0=perfect. Typical: 0.65-0.75 for RWE data")
            ),

            # Li et al. (2025) method inputs
            conditionalPanel(
              condition = "input.ps_calc_method == 'li_2025'",
              create_enhanced_slider("vif_overlap_phi",
                "Overlap Coefficient (φ):",
                min = 0.2, max = 1.0, value = 0.75, step = 0.05, post = "",
                tooltip = "Bhattacharyya coefficient measuring propensity score overlap. 1.0=perfect overlap, 0=no overlap. Typical: 0.6-0.8 for moderate overlap"),

              create_enhanced_slider("vif_rho_squared",
                "Confounder-Outcome Association (R²):",
                min = 0, max = 0.5, value = 0.10, step = 0.05, post = "",
                tooltip = "R-squared from regression of outcome on confounders. Quantifies confounding strength. Weak: <0.02, Moderate: 0.02-0.13, Strong: 0.13-0.26, Very Strong: >0.26"),

              helpText(style = "color: #666; font-size: 0.9em; margin-top: 10px;",
                icon("info-circle"),
                " The overlap coefficient (φ) can be estimated from pilot data or assumed based on clinical equipoise. R² can be obtained from previous studies or literature.")
            ),

            # Weighting method selection (common to both methods)
            hr(),
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

  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @importFrom shiny tags addResourcePath
#' @noRd
golem_add_external_resources <- function() {
  # Add resource path for www directory
  # In development, www is in the root; in production, it's in inst/app/www
  www_path <- if (file.exists("www")) {
    "www"
  } else {
    app_sys("app", "www")
  }
  
  addResourcePath(
    prefix = "www",
    directoryPath = www_path
  )
  
  tags$head(
    # Placeholder for additional head content if needed
  )
}
