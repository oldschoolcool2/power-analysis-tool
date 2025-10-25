#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`. DO NOT REMOVE.
#' @noRd
#' 
#' @importFrom shiny fluidPage tags actionButton icon conditionalPanel uiOutput dataTableOutput tagList div p HTML
#' @importFrom bslib bs_theme font_google
#' @importFrom shinyBS bsModal
#' @importFrom shinyjs useShinyjs
#' @importFrom plotly plotlyOutput
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    # Your application UI logic
    fluidPage(
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
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/result-cards.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/validation.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/progressive-disclosure.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/loading-spinner.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/success-animations.css"),
    tags$link(rel = "stylesheet", type = "text/css", href = "www/css/documentation.css"),
    # JavaScript - Bootstrap 5 fix must load before other scripts
    tags$script(src = "www/js/bootstrap5-shinyBS-fix.js"),
    tags$script(src = "www/js/theme-switcher.js"),
    tags$script(src = "www/js/sidebar-navigation.js"),
    tags$script(src = "www/js/copy-to-clipboard.js"),
    tags$script(src = "www/js/input-validation.js"),
    tags$script(src = "www/js/loading-spinner.js"),
    tags$script(src = "www/js/keyboard-shortcuts.js"),
    tags$script(src = "www/js/mobile-sidebar-toggle.js"),
    tags$script(src = "www/js/session-restore.js"),
    tags$script(src = "www/js/example-scenarios.js"),
    tags$script(src = "www/js/initialize-popovers.js"),
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

  # App Container with Sidebar + Main Content
  div(class = "app-container",

    # Hierarchical Sidebar Navigation
    create_sidebar_nav(),

    # Main Content Wrapper
    div(class = "main-content-wrapper",
      div(class = "main-content",

        # ============================================================
        # DOCUMENTATION PAGE (Full page replacement)
        # ============================================================

        # NEW: Documentation Page
        conditionalPanel(
          condition = "input.sidebar_page == 'documentation'",
          div(class = "content-card",
            create_documentation_page()
          )
        ),

        # ============================================================
        # INPUT PANELS (Conditional based on sidebar selection)
        # ============================================================

        # Wrap all analysis content so it's hidden when documentation is shown
        conditionalPanel(
          condition = "input.sidebar_page != 'documentation'",

        div(class = "content-card",

          # ==============================================================================
          # TAB 1: SINGLE PROPORTION [MODULARIZED]
          # ==============================================================================
          mod_01_single_proportion_ui("tab1"),

          # ==============================================================================
          # TAB 2: TWO-GROUP COMPARISONS [MODULARIZED]
          # ==============================================================================
          mod_02_two_group_ui("tab2"),

          # ==============================================================================
          # TAB 3: SURVIVAL ANALYSIS [MODULARIZED]
          # ==============================================================================
          mod_03_survival_ui("tab3"),

          # ==============================================================================
          # TAB 4: MATCHED CASE-CONTROL [MODULARIZED]
          # ==============================================================================
          mod_04_matched_case_control_ui("tab4"),

          # ==============================================================================
          # TAB 5: CONTINUOUS OUTCOMES [MODULARIZED]
          # ==============================================================================
          mod_05_continuous_ui("tab5"),

          # ==============================================================================
          # TAB 6: NON-INFERIORITY [MODULARIZED]
          # ==============================================================================
          mod_06_non_inferiority_ui("tab6"),

          # ==============================================================================
          # TAB 7: VIF/PROPENSITY SCORE [MODULARIZED]
          # ==============================================================================
          mod_07_vif_ps_ui("tab7"),

          # ==============================================================================
          # TAB 8: MEDIATION ANALYSIS [MODULARIZED]
          # ==============================================================================
          mod_08_mediation_ui("tab8"),

          # ==============================================================================
          # TAB 9: TIME-TO-EVENT EQUIVALENCE/NON-INFERIORITY [MODULARIZED]
          # ==============================================================================
          mod_09_survival_equivalence_ui("tab9")

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

        # Contextual help for Mediation Analysis
        conditionalPanel(
          condition = "input.sidebar_page == 'mediation_analysis'",
          div(class = "content-card help-section",
            create_contextual_help("mediation_analysis")
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

        ) # End of conditionalPanel (analysis content)

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
  ) # End of fluidPage()
) # End of tagList()
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @importFrom shiny tags addResourcePath
#' @importFrom htmltools htmlDependency
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

  # Get shinyBS package path for resources
  shinyBS_path <- system.file(package = "shinyBS")

  # Add shinyBS resource path
  addResourcePath(
    prefix = "shinyBS",
    directoryPath = file.path(shinyBS_path, "www")
  )

  tags$head(
    # Attach shinyBS CSS and JS dependencies
    tags$link(
      rel = "stylesheet",
      type = "text/css",
      href = "shinyBS/shinyBS.css"
    ),
    tags$script(src = "shinyBS/shinyBS.js")
  )
}
