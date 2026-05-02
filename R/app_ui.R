#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`. DO NOT REMOVE.
#' @noRd
#' 
#' @importFrom shiny fluidPage tags actionButton icon conditionalPanel uiOutput tagList div p HTML
#' @importFrom DT DTOutput
#' @importFrom bslib bs_theme font_google
#' @importFrom shinyjs useShinyjs
#' @importFrom plotly plotlyOutput
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    # Your application UI logic
    fluidPage(
  # Modern bslib theme for mobile responsiveness
  # Note: bslib color contrast warnings in dev mode are informational for auto-generated
  # color variations. Our custom CSS (design-tokens.css) uses WCAG AA compliant colors.
  theme = bs_theme(
    version = 5,
    bootswatch = NULL,
    # WCAG AA compliant primary color (7:1 contrast on white)
    primary = "#0F2A3F",  # Deep slate - matches design-tokens.css --color-primary-900
    base_font = font_google("Inter"),
    heading_font = font_google("Inter"),
    bg = "#FFFFFF",
    fg = "#1D2A39",
    # Disable problematic auto-generated color features
    "enable-shadows" = TRUE,
    "enable-gradients" = FALSE,
    # Explicitly set semantic colors to WCAG compliant values
    success = "#047857",   # --color-success-700 from design-tokens.css
    info = "#1D4ED8",      # --color-info-700 from design-tokens.css
    warning = "#B45309",   # --color-warning-700 from design-tokens.css
    danger = "#B91C1C"     # --color-error-700 from design-tokens.css
  ),

  # Bundled CSS/JS dependency. htmltools::htmlDependency dedupes across the
  # session, versions the assets (cache-busts on package version bump), and
  # injects exactly one <link>/<script> per file via Shiny's HTTP server.
  pat_assets(),

  tags$head(
    # Favicon (small enough to inline-link from head; not part of the bundle)
    tags$link(rel = "icon", type = "image/svg+xml", href = "www/favicon.svg"),
    tags$style(HTML("
      /* Clean background color definitions */
      :root {
        --bs-body-bg: #FFFFFF;
        --bs-body-bg-rgb: 255, 255, 255;
      }
      
      body, html {
        background-color: #FFFFFF;
      }
      
      /* Ensure dark mode overrides work - CRITICAL: Override Bootstrap inline styles */
      html[data-theme='dark'],
      [data-theme='dark'] {
        --bs-body-bg: #0F172A !important;
        --bs-body-color: #F8F9FA !important;
        --bs-body-color-rgb: 248, 249, 250 !important;
      }
      
      html[data-theme='dark'],
      [data-theme='dark'] body,
      [data-theme='dark'] html {
        background-color: #0F172A !important;
        color: #F8F9FA !important;
      }
      
      /* Force all text to be light in dark mode */
      html[data-theme='dark'] *:not(.btn):not(.badge),
      [data-theme='dark'] *:not(.btn):not(.badge) {
        color: inherit;
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
          mod_09_survival_equivalence_ui("tab9"),

          # ==============================================================================
          # TAB 10: SENSITIVITY ANALYSES [MODULARIZED]
          # ==============================================================================
          mod_10_sensitivity_analyses_ui("tab10")

        ), # End of input cards

        # ============================================================
        # CALCULATE BUTTON & RESULTS (hidden on sensitivity pages)
        # ============================================================

        conditionalPanel(
          condition = "input.sidebar_page != 'sensitivity_evalue' && input.sidebar_page != 'sensitivity_multi_bias'",

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

        # Contextual help for Sensitivity Analyses (Multiple-Bias)
        conditionalPanel(
          condition = "input.sidebar_page == 'sensitivity_multi_bias'",
          div(class = "content-card help-section",
            create_contextual_help("sensitivity_multi_bias")
          )
        ),

        # Contextual help for Sensitivity Analyses (E-value)
        conditionalPanel(
          condition = "input.sidebar_page == 'sensitivity_evalue'",
          div(class = "content-card help-section",
            create_contextual_help("sensitivity_evalue")
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
        DTOutput("result_table"),
        uiOutput("table_footnotes"),
        uiOutput("download_buttons"),

        # Scenario comparison section
        uiOutput("scenario_comparison")

        ) # End of conditionalPanel (exclude sensitivity pages)

        ) # End of conditionalPanel (analysis content)

      ) # End of main-content
    ) # End of main-content-wrapper
  ), # End of app-container

  # Quick Preview Footer
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
#' @importFrom htmltools htmlDependency attachDependencies tagList
#' @noRd
golem_add_external_resources <- function() {
  # Resolve www/ path. Inside the installed package the canonical location is
  # inst/app/www (resolved by app_sys). For pkgload::load_all() in dev, fall
  # back to the project-root inst/app/www tree.
  www_path <- app_sys("app", "www")
  if (!nzchar(www_path) || !dir.exists(www_path)) {
    www_path <- file.path("inst", "app", "www")
  }

  addResourcePath(
    prefix = "www",
    directoryPath = www_path
  )

  tags$head(
    # Placeholder for additional head content if needed
  )
}

#' Bundle all PAT static assets as a single HTML dependency
#'
#' Ships the project's CSS and JS as one versioned htmlDependency so Shiny can
#' dedupe duplicates, attach a cache-busting version string, and load scripts
#' with `defer` so they don't block first paint.
#'
#' Version string is derived from the installed package version, so any
#' release automatically invalidates browser caches.
#'
#' @importFrom htmltools htmlDependency
#' @importFrom utils packageVersion
#' @noRd
pat_assets <- function() {
  # Same path resolution as golem_add_external_resources()
  www_path <- app_sys("app", "www")
  if (!nzchar(www_path) || !dir.exists(www_path)) {
    www_path <- file.path("inst", "app", "www")
  }

  pkg_version <- tryCatch(
    as.character(packageVersion("PowerAnalysisTool")),
    error = function(e) "0.0.0"
  )

  htmlDependency(
    name = "pat-assets",
    version = pkg_version,
    src = c(file = www_path),
    stylesheet = c(
      "css/design-tokens.css",
      "css/modern-theme.css",
      "css/input-components.css",
      "css/responsive.css",
      "css/sidebar.css",
      "css/result-cards.css",
      "css/evalue-cards.css",
      "css/multi-bias-cards.css",
      "css/validation.css",
      "css/progressive-disclosure.css",
      "css/loading-spinner.css",
      "css/success-animations.css",
      "css/documentation.css"
    ),
    # `defer` so JS doesn't block parsing; none of these scripts produce
    # above-the-fold content, all attach handlers / read DOM after parse.
    script = lapply(
      c(
        "js/theme-switcher.js",
        "js/sidebar-navigation.js",
        "js/copy-to-clipboard.js",
        "js/input-validation.js",
        "js/loading-spinner.js",
        "js/keyboard-shortcuts.js",
        "js/mobile-sidebar-toggle.js",
        "js/session-restore.js",
        "js/example-scenarios.js",
        "js/initialize-popovers.js"
      ),
      function(s) list(src = s, defer = NA)
    )
  )
}
