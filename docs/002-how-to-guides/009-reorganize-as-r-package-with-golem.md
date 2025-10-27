# How to Reorganize as an R Package with Golem

**Type:** How-To Guide
**Audience:** Developers, Contributors
**Last Updated:** 2025-10-25

## Overview

This guide explains how to systematically reorganize the Power Analysis Tool codebase to follow the golem framework, transforming it into a production-grade R package. This restructuring will improve maintainability, enable robust testing, and simplify deployment—all while preserving existing functionality and deployment workflows.

**Key Question Answered:** Will this still allow us to deploy the Shiny app easily?

**Answer:** Yes! The package structure actually **simplifies** deployment. You won't need a secondary codebase. The golem framework generates small wrapper files (`app.R`) that load your package and launch the app. Deployment to shinyapps.io, Posit Connect, or Docker works seamlessly with one-click publishing.

---

## Table of Contents

1. [Why Reorganize as an R Package?](#why-reorganize-as-an-r-package)
2. [Understanding the Golem Framework](#understanding-the-golem-framework)
3. [Deployment Story: No Secondary Codebase Needed](#deployment-story-no-secondary-codebase-needed)
4. [Current vs. Target Structure](#current-vs-target-structure)
5. [Step-by-Step Migration Plan](#step-by-step-migration-plan)
6. [Detailed Implementation Steps](#detailed-implementation-steps)
7. [Testing Strategy](#testing-strategy)
8. [Deployment Workflow](#deployment-workflow)
9. [Rollback Plan](#rollback-plan)
10. [FAQ](#faq)

---

## Why Reorganize as an R Package?

### Current Challenges (4,044 lines in app.R)

- **Difficult navigation:** Scrolling through thousands of lines to find specific code
- **Merge conflicts:** Multiple developers editing the same massive file
- **Testing complexity:** Hard to test individual components in isolation
- **Dependency confusion:** No formal declaration of required packages
- **Version management:** No structured way to track application versions
- **Code duplication:** Despite recent helper functions, still significant repetition

### Benefits of Package Structure

| Benefit | How It Helps |
|---------|--------------|
| **Metadata** | `DESCRIPTION` file declares all dependencies, versions, and authors |
| **Namespace** | Clear boundaries between internal/exported functions |
| **Documentation** | Roxygen2 comments generate help pages automatically |
| **Testing** | `testthat` framework integrates natively with package structure |
| **Versioning** | Semantic versioning (1.0.0, 1.1.0, etc.) built into package system |
| **Installation** | Users can install with `install.packages()` or `remotes::install_github()` |
| **Deployment** | Single-click deploy to shinyapps.io, Posit Connect, Docker |
| **CI/CD** | Standard R package checks (`R CMD check`) ensure quality |

### Real-World Impact

From "Engineering Production-Grade Shiny Apps":
> "There is nothing harder to maintain than a Shiny app made of a unique 1000-line long app.R file. Package structure transforms chaos into order."

Your recent refactoring (65% code reduction per tab) demonstrates the power of modularization. Package structure is the logical next step.

---

## Understanding the Golem Framework

### What is Golem?

Golem is an opinionated framework for building production-grade Shiny applications as R packages. It provides:

- **Project scaffolding:** Pre-configured directory structure
- **Development helpers:** Functions for adding modules, functions, tests
- **Deployment scripts:** One-command setup for shinyapps.io, Posit Connect, Docker
- **Best practices:** Enforces separation of concerns, testing, documentation

### Golem Philosophy

1. **Shiny app = R package:** Every production Shiny app should be a package
2. **Module-first:** Break large apps into Shiny modules from the start
3. **Reproducibility:** `renv` for dependency management
4. **Documentation:** roxygen2 for all functions
5. **Testing:** testthat for unit and integration tests

### Golem File Naming Conventions

| Prefix | Purpose | Example |
|--------|---------|---------|
| `app_*.R` | Top-level UI and server | `app_ui.R`, `app_server.R` |
| `mod_*.R` | Shiny modules | `mod_01_single_proportion.R` |
| `fct_*.R` | Business logic (no reactivity) | `fct_effect_size.R` |
| `utils_*.R` | Helper utilities | `utils_ui.R` |
| `run_*.R` | App launchers | `run_app.R` |

---

## Deployment Story: No Secondary Codebase Needed

### The Deployment Question

**Common Concern:** "If I build my app as a package, do I need a separate codebase for deployment?"

**Answer:** **No!** The package IS your deployment artifact.

### How Deployment Works

#### Traditional app.R Approach (Current)
```
power-analysis-tool/
├── app.R (4,044 lines)
├── R/
│   └── helpers...
└── Deploy: Upload entire directory to shinyapps.io
```

#### Package Approach (Target)
```
power-analysis-tool/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── run_app.R (launches app)
│   ├── app_ui.R (50 lines)
│   ├── app_server.R (100 lines)
│   ├── mod_*.R (modules)
│   └── fct_*.R (functions)
├── inst/
│   └── app/www/ (static files)
├── app.R (5 lines - auto-generated wrapper)
└── Deploy: golem creates app.R automatically
```

### The Magic: app.R Wrapper

When you run `golem::add_shinyappsio_file()`, it creates a **5-line app.R**:

```r
# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
powerAnalysisTool::run_app() # Assuming package name is powerAnalysisTool
```

**That's it!** This tiny file:
1. Loads your package
2. Sets production mode
3. Launches your app

### Deployment Platforms

| Platform | Setup Command | Result |
|----------|---------------|--------|
| **shinyapps.io** | `golem::add_shinyappsio_file()` | Creates `app.R` + `.rscignore` |
| **Posit Connect** | `golem::add_positconnect_file()` | Creates `app.R` + config files |
| **Shiny Server** | `golem::add_shinyserver_file()` | Creates `app.R` |
| **Docker** | `golem::add_dockerfile_with_renv()` | Creates `deploy/` folder with Dockerfile |

### One-Click Deployment

After setup:
1. Open the generated `app.R`
2. Click the blue "Publish" button in RStudio
3. Select shinyapps.io or Posit Connect
4. Click "Publish"

**No secondary codebase. No manual configuration. It just works.**

---

## Current vs. Target Structure

### Current Structure (Before Golem)

```
power-analysis-tool/
├── app.R (4,044 lines)
│   ├── Library imports (20 lines)
│   ├── Source statements (15 lines)
│   ├── UI definition (800+ lines)
│   ├── Server function (3,200+ lines)
│   └── shinyApp(ui, server)
├── R/
│   ├── sidebar_ui.R
│   ├── input_components.R
│   ├── header_ui.R
│   ├── help_content.R
│   ├── modules/
│   │   └── 001-missing-data-module.R
│   └── helpers/
│       ├── 001-plot-helpers.R
│       ├── 002-result-text-helpers.R
│       └── 003-propensity-score-helpers.R
├── www/ (CSS, JS, images)
├── data/
├── docs/
├── tests/ (minimal)
├── renv.lock
├── README.md
└── CLAUDE.md
```

**Issues:**
- ❌ No DESCRIPTION file (dependencies undeclared)
- ❌ No NAMESPACE (function exports unclear)
- ❌ Massive app.R (hard to navigate)
- ❌ Inconsistent file naming
- ❌ Minimal test infrastructure

### Target Structure (After Golem)

```
power-analysis-tool/
├── DESCRIPTION (package metadata)
├── NAMESPACE (auto-generated)
├── R/
│   ├── run_app.R (app launcher)
│   ├── app_ui.R (main UI, 50-100 lines)
│   ├── app_server.R (main server, 100-200 lines)
│   ├── app_config.R (configuration)
│   ├── mod_01_single_proportion.R (module)
│   ├── mod_02_power_two_group.R
│   ├── mod_03_sample_size_two_group.R
│   ├── mod_04_power_survival.R
│   ├── mod_05_sample_size_survival.R
│   ├── mod_06_matched_case_control.R
│   ├── mod_07_power_continuous.R
│   ├── mod_08_sample_size_continuous.R
│   ├── mod_09_non_inferiority.R
│   ├── mod_10_vif_calculator.R
│   ├── mod_11_propensity_score.R
│   ├── mod_missing_data.R (cross-cutting module)
│   ├── fct_effect_size.R (business logic)
│   ├── fct_power_calculations.R
│   ├── fct_sample_size.R
│   ├── fct_propensity_score.R
│   ├── utils_plot.R (plot helpers)
│   ├── utils_text.R (result text helpers)
│   └── utils_ui.R (UI helpers)
├── inst/
│   └── app/
│       └── www/ (CSS, JS, images)
├── man/ (auto-generated documentation)
├── tests/
│   └── testthat/
│       ├── test-fct_effect_size.R
│       ├── test-fct_power_calculations.R
│       └── test-mod_single_proportion.R
├── dev/ (development scripts)
│   ├── 01_start.R
│   ├── 02_dev.R
│   └── 03_deploy.R
├── data-raw/ (raw data processing scripts)
├── vignettes/ (long-form documentation)
├── docs/ (existing Diataxis docs - unchanged)
├── renv.lock
├── app.R (5 lines - auto-generated)
├── DESCRIPTION
├── NAMESPACE
├── README.md
├── CLAUDE.md
└── NEWS.md (version changelog)
```

**Benefits:**
- ✅ DESCRIPTION declares all dependencies
- ✅ NAMESPACE makes exports explicit
- ✅ app.R shrinks from 4,044 → ~5 lines
- ✅ Consistent golem naming conventions
- ✅ Comprehensive test suite
- ✅ Auto-generated documentation

---

## Step-by-Step Migration Plan

### Migration Strategy: Incremental, Not Big Bang

**Principle:** Transform the codebase incrementally while maintaining a working application at every step.

### Phase Overview

| Phase | Duration | Goal | Deliverable |
|-------|----------|------|-------------|
| **0: Preparation** | 1 day | Setup golem, preserve current app | Working app + golem scaffold |
| **1: Core Structure** | 2-3 days | Create package skeleton | DESCRIPTION, NAMESPACE, run_app.R |
| **2: Module Migration** | 2-3 weeks | Convert tabs to modules | 11 mod_*.R files |
| **3: Function Extraction** | 1 week | Extract business logic | fct_*.R and utils_*.R files |
| **4: Testing** | 1-2 weeks | Add comprehensive tests | 80%+ test coverage |
| **5: Documentation** | 3-4 days | Document all functions | man/ files via roxygen2 |
| **6: Deployment** | 1 day | Configure deployment | app.R for shinyapps.io |
| **7: Validation** | 2-3 days | End-to-end testing | Production-ready package |

**Total Estimated Time:** 5-7 weeks (1 developer, part-time)

### Risk Mitigation

1. **Keep current app.R working** throughout migration
2. **Create feature branch** for all golem work
3. **Test after each phase** to catch issues early
4. **Parallel development possible** via branch isolation
5. **Easy rollback** if needed (git revert)

---

## Detailed Implementation Steps

### Phase 0: Preparation (1 day)

**Goal:** Set up golem infrastructure without breaking existing app.

#### Step 0.1: Install Golem

```r
install.packages("golem")
```

#### Step 0.2: Create Backup Branch

```bash
git checkout -b backup/pre-golem-migration
git push origin backup/pre-golem-migration
git checkout master
git checkout -b feature/golem-migration
```

#### Step 0.3: Initialize Golem (In a Separate Directory)

**Important:** Don't run `golem::create_golem()` in your existing directory. It creates a new project.

Instead, we'll manually create the golem structure:

```bash
# Create branch for golem work
git checkout -b feature/golem-migration

# We'll manually add files one-by-one
```

#### Step 0.4: Create DESCRIPTION File

Create `DESCRIPTION` at project root:

```r
Package: powerAnalysisTool
Title: Power and Sample Size Calculator for Real-World Evidence Studies
Version: 1.0.0
Authors@R:
    person("Your", "Name", , "your.email@example.com", role = c("cre", "aut"))
Description: A comprehensive Shiny application for power and sample size
    calculations in observational studies and real-world evidence research.
    Features include propensity score adjustments, survival analysis,
    non-inferiority testing, and 11 analysis types.
License: MIT + file LICENSE
Imports:
    shiny (>= 1.7.0),
    bslib (>= 0.5.0),
    shinyBS (>= 0.61),
    shinyjs (>= 2.1.0),
    pwr (>= 1.3.0),
    binom (>= 1.1.1),
    kableExtra (>= 1.3.4),
    tinytex (>= 0.45),
    powerSurvEpi (>= 0.1.3),
    epiR (>= 2.0.52),
    plotly (>= 4.10.0),
    ggplot2 (>= 3.4.0),
    config (>= 0.3.1),
    golem (>= 0.4.1),
    pkgload (>= 1.3.0)
Suggests:
    testthat (>= 3.0.0),
    shinytest2 (>= 0.3.0),
    spelling
Encoding: UTF-8
LazyData: true
RoxygenNote: 7.2.3
Language: en-US
```

**Commit:**
```bash
git add DESCRIPTION
git commit -m "feat: add DESCRIPTION file for package structure"
```

#### Step 0.5: Create NAMESPACE (Initial)

Create `NAMESPACE` at project root:

```r
# Generated by roxygen2: do not edit by hand

export(run_app)
```

**Commit:**
```bash
git add NAMESPACE
git commit -m "feat: add initial NAMESPACE file"
```

#### Step 0.6: Create R/run_app.R

Create `R/run_app.R`:

```r
#' Run the Shiny Application
#'
#' @param ... Arguments passed to shinyApp()
#'
#' @export
#' @importFrom shiny shinyApp
run_app <- function(...) {
  # For now, source the existing app.R
  source("app.R", local = new.env())

  # Return the shiny app object
  shinyApp(ui = ui, server = server, ...)
}
```

This creates a package function that wraps your existing app.R.

**Commit:**
```bash
git add R/run_app.R
git commit -m "feat: add run_app() function to launch application"
```

#### Step 0.7: Test Package Installation

```r
# Install your package locally
devtools::install()

# Test it
library(powerAnalysisTool)
run_app()
```

**Expected Result:** Your app launches exactly as before.

**Commit:**
```bash
git commit -m "test: verify package installs and run_app() works"
```

---

### Phase 1: Core Structure (2-3 days)

**Goal:** Create the essential package infrastructure files.

#### Step 1.1: Create R/app_ui.R

Extract UI definition from `app.R` (lines 36-845) into a function:

```r
#' The application User-Interface
#'
#' @param request Internal parameter for `{shiny}`. DO NOT REMOVE.
#' @noRd
app_ui <- function(request) {
  tagList(
    # Leave this function for adding external resources
    golem_add_external_resources(),

    # Your application UI logic
    fluidPage(
      theme = bs_theme(
        version = 5,
        bootswatch = NULL,
        primary = "#2B5876",
        base_font = font_google("Inter"),
        heading_font = font_google("Inter"),
        bg = "#FFFFFF",
        fg = "#1D2A39"
      ),

      tags$head(
        tags$link(rel = "icon", type = "image/svg+xml", href = "www/favicon.svg"),
        tags$link(rel = "stylesheet", type = "text/css", href = "www/css/design-tokens.css?v=1.1.0"),
        tags$link(rel = "stylesheet", type = "text/css", href = "www/css/modern-theme.css?v=1.1.0"),
        tags$link(rel = "stylesheet", type = "text/css", href = "www/css/input-components.css"),
        tags$link(rel = "stylesheet", type = "text/css", href = "www/css/responsive.css"),
        tags$link(rel = "stylesheet", type = "text/css", href = "www/css/sidebar.css"),
        tags$script(src = "www/js/bootstrap5-shinyBS-fix.js"),
        tags$script(src = "www/js/theme-switcher.js"),
        tags$script(src = "www/js/sidebar-navigation.js"),
        # ... rest of tags$head content
      ),

      # Copy all your existing UI content from app.R here
      # For now, keep the inline tab definitions
      # We'll extract them to modules in Phase 2

      navbarPage(
        title = create_app_header(),
        id = "tabs",
        # ... all your tabPanel() definitions
      )
    )
  )
}

#' Add external Resources to the Application
#'
#' This function is internally used to add external
#' resources inside the Shiny application.
#'
#' @noRd
golem_add_external_resources <- function() {
  add_resource_path(
    "www",
    app_sys("app/www")
  )
}
```

**Note:** For now, copy all the tab UI code inline. We'll extract to modules in Phase 2.

#### Step 1.2: Create R/app_server.R

Extract server function from `app.R` (lines 847-4043) into a function:

```r
#' The application server-side
#'
#' @param input,output,session Internal parameters for {shiny}. DO NOT REMOVE.
#' @noRd
app_server <- function(input, output, session) {

  # Copy all your existing server logic from app.R here
  # For now, keep all the inline reactive logic
  # We'll extract to modules in Phase 2

  # Example structure (fill in with your actual code):

  # Tab 1: Single Proportion
  # ... all your existing observers, reactives, outputs

  # Tab 2: Power (Two-Group)
  # ... all your existing observers, reactives, outputs

  # ... etc for all 11 tabs
}
```

#### Step 1.3: Update R/run_app.R

Now update `run_app.R` to use the new structure:

```r
#' Run the Shiny Application
#'
#' @param ... Arguments passed to shinyApp()
#'
#' @export
#' @importFrom shiny shinyApp
#' @importFrom golem with_golem_options
run_app <- function(...) {
  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      options = list(...)
    ),
    golem_opts = list(...)
  )
}
```

#### Step 1.4: Create R/app_config.R

```r
#' Access files in the current app
#'
#' @param ... Character vector specifying directory and or file to
#'     point to inside the current package.
#'
#' @noRd
app_sys <- function(...) {
  system.file(..., package = "powerAnalysisTool")
}

#' Read App Config
#'
#' @param value Value to retrieve from the config file.
#' @param config GOLEM_CONFIG_ACTIVE value. If unset, R_CONFIG_ACTIVE.
#'     If unset, "default".
#' @param use_parent Logical, scan the parent directory for config file.
#'
#' @noRd
get_golem_config <- function(value, config = Sys.getenv("GOLEM_CONFIG_ACTIVE", "default"), use_parent = TRUE) {
  config::get(value = value, config = config, file = app_sys("golem-config.yml"), use_parent = use_parent)
}
```

#### Step 1.5: Move www/ to inst/app/www/

Golem expects static files in `inst/app/www/`:

```bash
mkdir -p inst/app
git mv www inst/app/
git commit -m "refactor: move www/ to inst/app/www/ for golem structure"
```

Update all references in `app_ui.R`:
- Change `href = "css/...` to `href = "www/css/..."`
- Change `src = "js/..."` to `src = "www/js/..."`

#### Step 1.6: Create dev/ Scripts

Create `dev/01_start.R`:

```r
# Development workflow script
# This file guides you through the golem development process

# 1. Load package during development
pkgload::load_all()

# 2. Run the dev version of the app
run_app()

# 3. If you want to test the production version
options("golem.app.prod" = TRUE)
run_app()
options("golem.app.prod" = FALSE)
```

Create `dev/02_dev.R`:

```r
# Development helpers for adding components

# Add modules
golem::add_module(name = "single_proportion", module_template = golem_module_template_file("simple"))

# Add functions
golem::add_fct("effect_size")
golem::add_utils("plot")

# Add tests
usethis::use_test("effect_size")

# Dependencies
usethis::use_package("dplyr")
usethis::use_package("ggplot2")
```

Create `dev/03_deploy.R`:

```r
# Deployment setup

# Check package before deployment
devtools::check()
rhub::check_for_cran()

# Deploy to shinyapps.io
golem::add_shinyappsio_file()
# rsconnect::deployApp()

# Deploy to Posit Connect
golem::add_positconnect_file()

# Create Docker image
golem::add_dockerfile_with_renv(output_dir = "deploy")
```

#### Step 1.7: Test Package Build

```r
# Load package
devtools::load_all()

# Test run
run_app()

# Build package
devtools::build()

# Check package
devtools::check()
```

**Expected Result:** App runs identically to before, but now as a package.

**Commit:**
```bash
git add R/app_ui.R R/app_server.R R/run_app.R R/app_config.R dev/
git commit -m "refactor: create core package structure with app_ui and app_server"
```

---

### Phase 2: Module Migration (2-3 weeks)

**Goal:** Extract each tab into a Shiny module following golem conventions.

#### Strategy

Migrate tabs one at a time:
1. Create `mod_XX_name.R` file
2. Extract UI code into `mod_XX_name_ui()`
3. Extract server code into `mod_XX_name_server()`
4. Update `app_ui.R` to use module UI
5. Update `app_server.R` to call module server
6. Test thoroughly
7. Commit before moving to next module

#### Step 2.1: Create Module Template

Use golem to create module scaffolds:

```r
# In R console
golem::add_module(name = "01_single_proportion")
golem::add_module(name = "02_power_two_group")
golem::add_module(name = "03_sample_size_two_group")
golem::add_module(name = "04_power_survival")
golem::add_module(name = "05_sample_size_survival")
golem::add_module(name = "06_matched_case_control")
golem::add_module(name = "07_power_continuous")
golem::add_module(name = "08_sample_size_continuous")
golem::add_module(name = "09_non_inferiority")
golem::add_module(name = "10_vif_calculator")
golem::add_module(name = "11_propensity_score")
```

This creates files like:
- `R/mod_01_single_proportion.R`
- `R/mod_02_power_two_group.R`
- etc.

Each file has this template:

```r
#' 01_single_proportion UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_01_single_proportion_ui <- function(id){
  ns <- NS(id)
  tagList(
    # Module UI here
  )
}

#' 01_single_proportion Server Functions
#'
#' @noRd
mod_01_single_proportion_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    # Module server logic here

  })
}
```

#### Step 2.2: Migrate Tab 1 (Single Proportion)

**UI Migration:**

In `R/mod_01_single_proportion.R`, replace the UI function:

```r
#' Single Proportion Power Analysis UI
#'
#' @description Shiny module for single proportion (Rule of 3) power calculations.
#'
#' @param id Module ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList sidebarLayout sidebarPanel mainPanel
#' @importFrom shiny numericInput actionButton plotOutput verbatimTextOutput
mod_01_single_proportion_ui <- function(id){
  ns <- NS(id)

  tagList(
    tags$div(class = "analysis-container",
      sidebarLayout(
        # Copy the sidebarPanel content from your current Tab 1
        sidebarPanel(
          width = 4,
          class = "sidebar-panel",

          # Use ns() to wrap all input IDs
          numericInput(ns("sp_events"),
                      label = "Number of events observed:",
                      value = 0,
                      min = 0,
                      step = 1),

          numericInput(ns("sp_n"),
                      label = "Total sample size (N):",
                      value = 100,
                      min = 1),

          actionButton(ns("sp_calculate"),
                      "Calculate",
                      class = "btn-primary btn-lg"),

          # ... rest of your inputs, wrapped with ns()
        ),

        # Copy the mainPanel content
        mainPanel(
          width = 8,

          # Wrap output IDs with ns()
          plotOutput(ns("sp_power_curve")),
          verbatimTextOutput(ns("sp_results")),

          # ... rest of your outputs, wrapped with ns()
        )
      )
    )
  )
}
```

**Server Migration:**

```r
#' Single Proportion Power Analysis Server
#'
#' @description Server logic for single proportion module.
#'
#' @param id Module ID
#'
#' @noRd
mod_01_single_proportion_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns

    # Copy all your reactive logic from app_server.R Tab 1 section
    # No need to wrap input/output IDs - module handles namespacing

    observeEvent(input$sp_calculate, {
      # Your calculation logic

      output$sp_results <- renderPrint({
        # Your results rendering
      })

      output$sp_power_curve <- renderPlot({
        # Your plot rendering
      })
    })

    # ... all other reactive logic for Tab 1
  })
}
```

**Update app_ui.R:**

In `R/app_ui.R`, replace the Tab 1 tabPanel:

```r
# Before:
tabPanel("Single Proportion",
  value = "single_proportion",
  # ... 200 lines of UI code
)

# After:
tabPanel("Single Proportion",
  value = "single_proportion",
  mod_01_single_proportion_ui("tab1")
)
```

**Update app_server.R:**

In `R/app_server.R`, replace Tab 1 server logic:

```r
# Before:
# ... 300 lines of Tab 1 server logic

# After:
mod_01_single_proportion_server("tab1")
```

**Test:**

```r
devtools::load_all()
run_app()

# Test Tab 1 thoroughly:
# - All inputs work
# - Calculations correct
# - Plots render
# - Downloads work
```

**Commit:**

```bash
git add R/mod_01_single_proportion.R R/app_ui.R R/app_server.R
git commit -m "refactor: extract Tab 1 (Single Proportion) into Shiny module"
```

#### Step 2.3: Repeat for Remaining Tabs

Follow the same pattern for tabs 2-11:

**Week 1:**
- Tab 2: Power (Two-Group)
- Tab 3: Sample Size (Two-Group)
- Tab 4: Power (Survival)

**Week 2:**
- Tab 5: Sample Size (Survival)
- Tab 6: Matched Case-Control
- Tab 7: Power (Continuous)
- Tab 8: Sample Size (Continuous)

**Week 3:**
- Tab 9: Non-Inferiority
- Tab 10: VIF Calculator
- Tab 11: Propensity Score

After each tab:
1. Test thoroughly
2. Commit with descriptive message
3. Update documentation

#### Step 2.4: Migrate Cross-Cutting Modules

Your existing modules need light refactoring:

**Missing Data Module:**

Rename `R/modules/001-missing-data-module.R` → `R/mod_missing_data.R`

Update to golem conventions:

```r
#' Missing Data Adjustment UI
#'
#' @param id Module ID
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_missing_data_ui <- function(id){
  ns <- NS(id)

  tagList(
    # Your existing missing data UI
    # Already uses ns() - just verify
  )
}

#' Missing Data Adjustment Server
#'
#' @param id Module ID
#'
#' @noRd
mod_missing_data_server <- function(id){
  moduleServer(id, function(input, output, session){
    # Your existing logic
    # Return reactive values for other modules to use
  })
}
```

**Commit:**

```bash
git mv R/modules/001-missing-data-module.R R/mod_missing_data.R
git commit -m "refactor: rename missing data module to golem convention"
```

#### Step 2.5: Final app.R Size Check

After all modules extracted:

```bash
wc -l R/app_ui.R R/app_server.R R/run_app.R
```

**Expected:**
- `app_ui.R`: 50-100 lines (just module calls)
- `app_server.R`: 100-200 lines (just module calls + shared state)
- `run_app.R`: 20-30 lines

**Total: ~200-300 lines vs. original 4,044 lines**

---

### Phase 3: Function Extraction (1 week)

**Goal:** Extract business logic (non-reactive functions) into `fct_*.R` and utilities into `utils_*.R`.

#### Step 3.1: Identify Business Logic

Business logic = functions that work without Shiny reactivity:
- Power calculations
- Sample size calculations
- Effect size conversions
- Statistical tests
- Plot generation (base functions)

#### Step 3.2: Create fct_*.R Files

**Example: Extract effect size functions**

Create `R/fct_effect_size.R`:

```r
#' Calculate Effect Measures from Two Proportions
#'
#' Calculates Relative Risk (RR), Odds Ratio (OR), and Risk Difference (RD)
#' from two proportions.
#'
#' @param p1 Proportion in group 1 (numeric, 0-1)
#' @param p2 Proportion in group 2 (numeric, 0-1)
#'
#' @return List with three elements: RR, OR, RD
#'
#' @examples
#' calc_effect_measures(0.15, 0.10)
#'
#' @noRd
calc_effect_measures <- function(p1, p2) {
  # Input validation
  if (!is.numeric(p1) || !is.numeric(p2)) {
    stop("p1 and p2 must be numeric")
  }
  if (p1 < 0 || p1 > 1 || p2 < 0 || p2 > 1) {
    stop("Proportions must be between 0 and 1")
  }

  # Calculate RR
  RR <- if (p2 > 0) p1 / p2 else NA

  # Calculate OR
  if (p1 == 0 || p1 == 1 || p2 == 0 || p2 == 1) {
    OR <- NA
  } else {
    OR <- (p1 / (1 - p1)) / (p2 / (1 - p2))
  }

  # Calculate RD
  RD <- p1 - p2

  list(RR = RR, OR = OR, RD = RD)
}

#' Convert Cohen's d to Correlation
#'
#' @param d Cohen's d effect size
#'
#' @return Correlation coefficient (r)
#'
#' @noRd
cohens_d_to_r <- function(d) {
  d / sqrt(d^2 + 4)
}

# ... more effect size functions
```

Use golem helper:

```r
golem::add_fct("effect_size")
# Creates R/fct_effect_size.R with roxygen template
```

#### Step 3.3: Create Additional fct_*.R Files

```r
golem::add_fct("power_calculations")    # R/fct_power_calculations.R
golem::add_fct("sample_size")           # R/fct_sample_size.R
golem::add_fct("propensity_score")      # R/fct_propensity_score.R
golem::add_fct("survival_analysis")     # R/fct_survival_analysis.R
```

Move appropriate functions from helpers to these files.

#### Step 3.4: Reorganize Helpers into utils_*.R

Rename and reorganize your existing helpers:

```bash
# Rename to golem conventions
git mv R/helpers/001-plot-helpers.R R/utils_plot.R
git mv R/helpers/002-result-text-helpers.R R/utils_text.R
git mv R/helpers/003-propensity-score-helpers.R R/fct_propensity_score.R
```

Move pure business logic from utils to fct files:
- `utils_*.R`: UI helpers, formatters, small utilities
- `fct_*.R`: Core statistical calculations, business logic

#### Step 3.5: Reorganize UI Helpers

```bash
git mv R/sidebar_ui.R R/utils_ui_sidebar.R
git mv R/header_ui.R R/utils_ui_header.R
git mv R/input_components.R R/utils_ui_inputs.R
git mv R/help_content.R R/utils_ui_help.R
```

#### Step 3.6: Update Documentation

Add roxygen2 comments to ALL functions:

```r
#' Calculate Two-Group Power
#'
#' @param n1 Sample size group 1
#' @param n2 Sample size group 2
#' @param p1 Proportion group 1
#' @param p2 Proportion group 2
#' @param alpha Significance level (default 0.05)
#' @param alternative "two.sided", "less", or "greater"
#'
#' @return Numeric power (0-1)
#'
#' @examples
#' calc_two_group_power(100, 100, 0.3, 0.2)
#'
#' @noRd
calc_two_group_power <- function(n1, n2, p1, p2, alpha = 0.05, alternative = "two.sided") {
  # Implementation
}
```

Generate documentation:

```r
devtools::document()
```

**Commit:**

```bash
git add R/fct_*.R R/utils_*.R man/
git commit -m "refactor: extract business logic to fct_* and utils_* files"
```

---

### Phase 4: Testing (1-2 weeks)

**Goal:** Achieve 80%+ test coverage with unit and integration tests.

#### Step 4.1: Setup Testing Infrastructure

```r
usethis::use_testthat()
```

This creates:
- `tests/testthat/` directory
- `tests/testthat.R` file

#### Step 4.2: Test Business Logic (fct_*.R)

Create `tests/testthat/test-fct_effect_size.R`:

```r
test_that("calc_effect_measures works correctly", {
  result <- calc_effect_measures(0.15, 0.10)

  expect_type(result, "list")
  expect_named(result, c("RR", "OR", "RD"))

  expect_equal(result$RR, 1.5)
  expect_equal(result$RD, 0.05)
  expect_gt(result$OR, 1.0)
})

test_that("calc_effect_measures handles edge cases", {
  # Test p2 = 0
  result <- calc_effect_measures(0.1, 0)
  expect_true(is.na(result$RR))

  # Test p1 = 0
  result <- calc_effect_measures(0, 0.1)
  expect_equal(result$RR, 0)

  # Test invalid inputs
  expect_error(calc_effect_measures(-0.1, 0.5))
  expect_error(calc_effect_measures(0.5, 1.5))
})

test_that("cohens_d_to_r converts correctly", {
  expect_equal(cohens_d_to_r(0), 0)
  expect_gt(cohens_d_to_r(0.5), 0)
  expect_lt(cohens_d_to_r(0.5), 1)
})
```

#### Step 4.3: Test Utilities (utils_*.R)

Create `tests/testthat/test-utils_plot.R`:

```r
test_that("create_power_curve_data generates correct structure", {
  data <- create_power_curve_data(
    sample_sizes = c(50, 100, 150),
    effect_size = 0.3,
    alpha = 0.05
  )

  expect_s3_class(data, "data.frame")
  expect_named(data, c("n", "power"))
  expect_equal(nrow(data), 3)
  expect_true(all(data$power >= 0 & data$power <= 1))
})
```

#### Step 4.4: Test Modules (Integration Tests)

Create `tests/testthat/test-mod_01_single_proportion.R`:

```r
library(shinytest2)

test_that("Single Proportion module UI renders", {
  # Test UI function returns valid HTML
  ui <- mod_01_single_proportion_ui("test")
  expect_s3_class(ui, "shiny.tag.list")
})

test_that("Single Proportion module server works", {
  testServer(mod_01_single_proportion_server, {
    # Simulate user input
    session$setInputs(sp_events = 0, sp_n = 100)
    session$setInputs(sp_calculate = 1)

    # Check outputs exist
    expect_true(!is.null(output$sp_results))
  })
})
```

#### Step 4.5: Add End-to-End Tests

Create `tests/testthat/test-app.R`:

```r
library(shinytest2)

test_that("App launches successfully", {
  app <- AppDriver$new(run_app())

  # Check that app loads
  expect_true(app$is_alive())

  # Check tab navigation
  app$set_inputs(tabs = "single_proportion")
  app$wait_for_idle()

  # Check calculation works
  app$set_inputs(`tab1-sp_events` = 0)
  app$set_inputs(`tab1-sp_n` = 100)
  app$click("tab1-sp_calculate")
  app$wait_for_idle()

  # Verify output appears
  expect_true(app$get_value(output = "tab1-sp_results") != "")

  app$stop()
})
```

#### Step 4.6: Run Tests

```r
# Run all tests
devtools::test()

# Check test coverage
covr::package_coverage()

# View coverage report
covr::report()
```

**Target:** 80%+ coverage

**Commit:**

```bash
git add tests/
git commit -m "test: add comprehensive test suite with 80%+ coverage"
```

---

### Phase 5: Documentation (3-4 days)

**Goal:** Generate complete package documentation.

#### Step 5.1: Document All Functions

Ensure every function has roxygen2 comments:

```r
#' Function Title
#'
#' Detailed description of what the function does.
#'
#' @param param1 Description of parameter 1
#' @param param2 Description of parameter 2
#'
#' @return Description of return value
#'
#' @examples
#' example_function(1, 2)
#'
#' @export  # Only for user-facing functions
```

For internal functions, use `@noRd` instead of `@export`.

#### Step 5.2: Generate Documentation

```r
devtools::document()
```

This creates/updates:
- `man/*.Rd` files (help pages)
- `NAMESPACE` file (exports)

#### Step 5.3: Create Package Vignettes

Create long-form documentation:

```r
usethis::use_vignette("getting-started")
usethis::use_vignette("power-calculations")
usethis::use_vignette("sample-size-calculations")
usethis::use_vignette("propensity-score-methods")
```

Edit `vignettes/getting-started.Rmd`:

```rmd
---
title: "Getting Started with powerAnalysisTool"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteIndexEntry{Getting Started with powerAnalysisTool}
  %\VignetteEngine{knitr::rmarkdown}
  %\VignetteEncoding{UTF-8}
---

## Installation

```{r, eval = FALSE}
# Install from GitHub
remotes::install_github("yourusername/power-analysis-tool")
```

## Basic Usage

```{r}
library(powerAnalysisTool)

# Launch the application
run_app()
```

## Features

- 11 analysis types
- Propensity score adjustments
- Interactive visualizations
- ...
```

#### Step 5.4: Update README.md

Enhance README with installation instructions:

```markdown
# Power Analysis Tool

[![R-CMD-check](https://github.com/yourusername/power-analysis-tool/workflows/R-CMD-check/badge.svg)](https://github.com/yourusername/power-analysis-tool/actions)
[![codecov](https://codecov.io/gh/yourusername/power-analysis-tool/branch/master/graph/badge.svg)](https://codecov.io/gh/yourusername/power-analysis-tool)

Comprehensive power and sample size calculator for real-world evidence studies.

## Installation

### From GitHub

```r
# Install from GitHub
remotes::install_github("yourusername/power-analysis-tool")
```

### From Source

```r
# Clone repository
git clone https://github.com/yourusername/power-analysis-tool.git
cd power-analysis-tool

# Install
devtools::install()
```

## Usage

```r
library(powerAnalysisTool)
run_app()
```

## Development

```r
# Load package during development
devtools::load_all()

# Run tests
devtools::test()

# Check package
devtools::check()
```

## Documentation

See vignettes for detailed guides:
- `vignette("getting-started")`
- `vignette("power-calculations")`
- `vignette("sample-size-calculations")`
```

#### Step 5.5: Create NEWS.md

Document version history:

```markdown
# powerAnalysisTool 1.0.0

## Major Changes

* Reorganized as R package following golem framework
* Extracted 11 analysis tabs into Shiny modules
* Added comprehensive test suite (80%+ coverage)
* Generated complete function documentation

## New Features

* Propensity score calculator (Li et al. 2025 methods)
* Interactive power curves for all analysis types
* Enhanced missing data adjustments

## Bug Fixes

* Fixed VIF calculation edge cases
* Corrected survival power calculations for small samples

## Breaking Changes

* None - application interface unchanged
```

**Commit:**

```bash
git add man/ vignettes/ README.md NEWS.md
git commit -m "docs: generate complete package documentation"
```

---

### Phase 6: Deployment Setup (1 day)

**Goal:** Configure deployment for shinyapps.io, Posit Connect, and Docker.

#### Step 6.1: Setup for shinyapps.io

```r
# Generate deployment file
golem::add_shinyappsio_file()
```

This creates `app.R` in the project root:

```r
# Launch the ShinyApp (Do not remove this comment)
# To deploy, run: rsconnect::deployApp()
# Or use the blue button on top of this file

pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
powerAnalysisTool::run_app()
```

**Test locally:**

```r
# Simulate production mode
options("golem.app.prod" = TRUE)
source("app.R")
```

#### Step 6.2: Configure rsconnect

```r
# Set up account (first time only)
rsconnect::setAccountInfo(
  name = "your-account",
  token = "your-token",
  secret = "your-secret"
)
```

Get credentials from: https://www.shinyapps.io/admin/#/tokens

#### Step 6.3: Deploy to shinyapps.io

**Option 1: RStudio IDE**
1. Open `app.R`
2. Click blue "Publish" button
3. Select shinyapps.io account
4. Click "Publish"

**Option 2: Command line**

```r
rsconnect::deployApp(
  appName = "power-analysis-tool",
  appTitle = "Power Analysis Tool for RWE Studies",
  account = "your-account"
)
```

**First deployment takes 5-10 minutes** (installs all dependencies).

Subsequent deployments take 1-2 minutes.

#### Step 6.4: Setup for Posit Connect

```r
golem::add_positconnect_file()
```

Creates similar `app.R` with Posit Connect-specific settings.

Deploy via RStudio Connect button or:

```r
rsconnect::deployApp(
  server = "your-connect-server.com",
  account = "your-account"
)
```

#### Step 6.5: Setup for Docker

```r
golem::add_dockerfile_with_renv(
  output_dir = "deploy",
  from = "rocker/r-ver:4.3.2"  # Match your R version
)
```

This creates:
- `deploy/Dockerfile`
- `deploy/README.md`
- `deploy/renv.lock`
- `deploy/powerAnalysisTool_*.tar.gz` (packaged app)

**Build Docker image:**

```bash
cd deploy
docker build -t power-analysis-tool:1.0.0 .
```

**Run container:**

```bash
docker run -p 3838:3838 power-analysis-tool:1.0.0
```

Access at: http://localhost:3838

**Push to registry:**

```bash
docker tag power-analysis-tool:1.0.0 your-registry.com/power-analysis-tool:1.0.0
docker push your-registry.com/power-analysis-tool:1.0.0
```

#### Step 6.6: Update .Rbuildignore

Ensure deployment files aren't included in package builds:

```
^.*\.Rproj$
^\.Rproj\.user$
^app\.R$
^rsconnect$
^deploy$
^\.github$
^docs/002-how-to-guides$
^docs/004-explanation$
```

**Commit:**

```bash
git add app.R deploy/ .Rbuildignore
git commit -m "deploy: configure deployment for shinyapps.io, Connect, and Docker"
```

---

### Phase 7: Validation (2-3 days)

**Goal:** Comprehensive end-to-end testing before production release.

#### Step 7.1: R CMD Check

Run official R package checks:

```r
devtools::check()
```

**Target:** 0 errors, 0 warnings, 0 notes

Common issues:
- Undeclared dependencies → Add to DESCRIPTION
- Non-ASCII characters → Use `\uXXXX` encoding
- Missing Rd files → Run `devtools::document()`

#### Step 7.2: CRAN Checks (Optional)

If planning CRAN submission:

```r
# Check on multiple platforms
devtools::check_rhub()

# Check on Windows
devtools::check_win_devel()

# Check with strict settings
rcmdcheck::rcmdcheck(args = c("--as-cran"))
```

#### Step 7.3: User Acceptance Testing

Create test protocol:

**Checklist:**
- [ ] App launches from package (`run_app()`)
- [ ] All 11 tabs load correctly
- [ ] Navigation between tabs works
- [ ] All calculations produce correct results
- [ ] All plots render properly
- [ ] Download buttons work (CSV, PDF)
- [ ] Help accordions open/close
- [ ] Theme switcher works (light/dark mode)
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] No console errors in browser
- [ ] No R warnings/errors in console

Test on:
- Chrome
- Firefox
- Safari
- Edge

#### Step 7.4: Performance Testing

```r
# Profile app performance
profvis::profvis({
  shiny::runApp(run_app())
})
```

Check for:
- Slow reactive expressions
- Unnecessary re-renders
- Memory leaks

#### Step 7.5: Deployment Testing

**Test shinyapps.io deployment:**
1. Deploy to staging: `rsconnect::deployApp(appName = "power-tool-staging")`
2. Test all features on deployed app
3. Check logs for errors: `rsconnect::showLogs(appName = "power-tool-staging")`

**Test Docker deployment:**
1. Build image
2. Run container
3. Test in isolated environment
4. Check resource usage

#### Step 7.6: Documentation Review

- [ ] All functions documented
- [ ] Vignettes render correctly: `devtools::build_vignettes()`
- [ ] README accurate
- [ ] NEWS.md up-to-date
- [ ] DESCRIPTION metadata complete

#### Step 7.7: Final Package Build

```r
# Build source package
devtools::build()

# Build binary package (optional)
devtools::build(binary = TRUE)

# Install from built package
install.packages("../powerAnalysisTool_1.0.0.tar.gz", repos = NULL, type = "source")

# Test installation
library(powerAnalysisTool)
run_app()
```

**Commit:**

```bash
git add .
git commit -m "chore: finalize package for v1.0.0 release"
git tag -a v1.0.0 -m "Version 1.0.0: Golem-based package structure"
git push origin feature/golem-migration
git push origin v1.0.0
```

---

## Testing Strategy

### Test Pyramid

```
       /\
      /  \  E2E (10%)        - Full app tests
     /____\
    /      \ Integration (30%) - Module tests
   /________\
  /          \ Unit (60%)      - Function tests
 /____________\
```

### Test Coverage Targets

| Component | Target Coverage | Priority |
|-----------|----------------|----------|
| `fct_*.R` | 95%+ | Critical |
| `utils_*.R` | 80%+ | High |
| `mod_*.R` | 70%+ | Medium |
| `app_*.R` | 50%+ | Low |

### Continuous Integration

Create `.github/workflows/R-CMD-check.yaml`:

```yaml
name: R-CMD-check

on:
  push:
    branches: [ main, master, feature/* ]
  pull_request:
    branches: [ main, master ]

jobs:
  R-CMD-check:
    runs-on: ${{ matrix.os }}

    strategy:
      matrix:
        os: [ubuntu-latest, windows-latest, macos-latest]
        r-version: ['4.2', '4.3']

    steps:
      - uses: actions/checkout@v3

      - uses: r-lib/actions/setup-r@v2
        with:
          r-version: ${{ matrix.r-version }}

      - uses: r-lib/actions/setup-pandoc@v2

      - uses: r-lib/actions/setup-r-dependencies@v2
        with:
          extra-packages: any::rcmdcheck

      - uses: r-lib/actions/check-r-package@v2
```

---

## Deployment Workflow

### Development Workflow

```r
# 1. Load package
devtools::load_all()

# 2. Make changes to code

# 3. Test changes
devtools::test()

# 4. Check package
devtools::check()

# 5. Run app
run_app()

# 6. Commit
git add .
git commit -m "feat: add new feature"
```

### Release Workflow

```r
# 1. Update version in DESCRIPTION
# 1.0.0 → 1.1.0

# 2. Update NEWS.md

# 3. Build and check
devtools::check()

# 4. Build package
devtools::build()

# 5. Deploy to shinyapps.io
rsconnect::deployApp()

# 6. Tag release
git tag -a v1.1.0 -m "Version 1.1.0"
git push origin v1.1.0

# 7. Create GitHub release (optional)
usethis::use_github_release()
```

### Deployment Comparison

| Method | Setup Time | Deploy Time | Cost | Best For |
|--------|-----------|-------------|------|----------|
| **shinyapps.io** | 5 min | 1-2 min | Free tier available | Quick demos, sharing |
| **Posit Connect** | 10 min | 1-2 min | Enterprise license | Internal enterprise apps |
| **Shiny Server** | 30 min | 5 min | Free (open source) | Self-hosted, on-premise |
| **Docker** | 1 hour | 10 min | Infrastructure cost | Cloud (AWS, GCP, Azure) |

---

## Rollback Plan

If issues arise during migration:

### Emergency Rollback (< 5 minutes)

```bash
# Revert to pre-golem state
git checkout master
git checkout backup/pre-golem-migration

# Or tag-based:
git checkout v0.9.0  # Last pre-golem version
```

### Gradual Rollback

If only some modules are problematic:

```r
# In app_server.R, replace module call with inline code
# Instead of:
mod_01_single_proportion_server("tab1")

# Temporarily use:
source("backup/tab1_server_logic.R", local = TRUE)
```

### Deployment Rollback

**shinyapps.io:**
```r
# List deployments
rsconnect::deployments()

# Restore previous version
rsconnect::restoreDeployment(
  appName = "power-analysis-tool",
  bundleId = "1234567"  # Previous bundle ID
)
```

**Docker:**
```bash
# Revert to previous image
docker pull power-analysis-tool:0.9.0
docker run -p 3838:3838 power-analysis-tool:0.9.0
```

---

## FAQ

### Q1: Will this break my existing deployment?

**A:** No. The package structure is additive. Your current `app.R` continues working during migration. Only after Phase 7 do you switch to the new deployment method.

### Q2: Can I still develop without understanding packages?

**A:** Yes. After initial setup, daily development is the same:
1. Edit code in `R/`
2. Run `devtools::load_all()`
3. Test with `run_app()`

The package machinery runs in the background.

### Q3: How do I add a new dependency?

**Before (current):**
```r
# Add library(newpackage) to app.R
```

**After (package):**
```r
usethis::use_package("newpackage")
# Automatically updates DESCRIPTION
```

### Q4: Do I need to rebuild the package every time I make a change?

**A:** No. Use `devtools::load_all()` for instant reloading during development. Only build (`devtools::build()`) when releasing.

### Q5: Can I still use my existing CLAUDE.md and docs/?

**A:** Yes! Keep all existing documentation. The package structure adds to it, doesn't replace it.

Your Diataxis docs (`docs/001-tutorials/`, etc.) remain unchanged.

### Q6: What if I don't want to use golem?

**A:** You can create a package manually without golem. Golem just provides:
- Pre-configured structure
- Helper functions
- Deployment scripts

The underlying package structure is standard R.

### Q7: How do collaborators work with the package?

**Collaborators clone and install:**
```r
git clone https://github.com/yourusername/power-analysis-tool.git
cd power-analysis-tool
devtools::install_deps()  # Install dependencies
devtools::load_all()      # Load for development
run_app()                 # Launch app
```

Same as before, just one extra command (`install_deps()`).

### Q8: Can I deploy to multiple platforms simultaneously?

**A:** Yes. Create all deployment files:

```r
golem::add_shinyappsio_file()      # app.R
golem::add_positconnect_file()     # app.R (overwrites)
golem::add_dockerfile_with_renv()  # deploy/Dockerfile
```

Keep separate branches:
- `deploy/shinyapps` - for shinyapps.io
- `deploy/connect` - for Posit Connect
- `deploy/docker` - for Docker

Or use different deployment scripts.

### Q9: What about renv? Do I still need it?

**A:** Yes! `renv` manages package versions. Golem + renv work together:
- `DESCRIPTION`: Declares what packages are needed
- `renv.lock`: Locks specific versions for reproducibility

Keep using `renv::snapshot()` after package updates.

### Q10: How do I handle data files in the package?

**Raw data (not for users):**
```r
# Put in data-raw/
usethis::use_data_raw("my_data")
# Creates data-raw/my_data.R for processing
```

**Processed data (for users):**
```r
# Save processed data
usethis::use_data(my_processed_data)
# Creates data/my_processed_data.rda
```

**External files (CSV, images):**
```
inst/extdata/
```

Access with:
```r
system.file("extdata", "file.csv", package = "powerAnalysisTool")
```

---

## Summary: Your Questions Answered

### Main Question: Do I need a secondary codebase for deployment?

**Answer: Absolutely not.**

The package structure IS your deployment artifact. Here's why:

1. **shinyapps.io**: Golem generates a 5-line `app.R` that loads your package and runs it. You upload this + package files. No separate codebase.

2. **Posit Connect**: Same as shinyapps.io. One-click publish from RStudio.

3. **Docker**: Golem creates a `deploy/` folder with Dockerfile. It packages your app as a `.tar.gz` and installs it in the container. No separate code.

4. **Shiny Server**: Place the generated `app.R` + package in the app directory. Shiny Server installs and runs it.

### What Changes for Deployment?

**Before (current):**
```
1. Open app.R
2. Click "Publish"
3. Wait for upload
```

**After (package):**
```
1. Run golem::add_shinyappsio_file()  (one-time setup)
2. Open app.R
3. Click "Publish"
4. Wait for upload
```

**Difference:** One extra step (one-time), then identical.

### Benefits of Package Deployment

| Benefit | Why It Matters |
|---------|----------------|
| **Dependency Management** | DESCRIPTION declares all packages; deployment auto-installs them |
| **Version Control** | Semantic versioning (1.0.0 → 1.1.0); easy rollbacks |
| **Smaller Uploads** | Only changed files upload; first deploy slow, subsequent fast |
| **Environment Isolation** | Package namespace prevents conflicts with other apps |
| **Professional Image** | "Install our package" sounds better than "run this script" |

---

## Next Steps

After reading this guide:

1. **Review with team:** Discuss timeline, resource allocation
2. **Create feature branch:** `git checkout -b feature/golem-migration`
3. **Start Phase 0:** Setup golem infrastructure (1 day)
4. **Incremental progress:** One phase at a time, test thoroughly
5. **Regular commits:** Commit after each module migration
6. **Celebrate milestones:** Phase completion = progress update

**Estimated Timeline:** 5-7 weeks part-time, or 2-3 weeks full-time

---

## Resources

### Official Documentation

- **Golem:** https://thinkr-open.github.io/golem/
- **Engineering Shiny:** https://engineering-shiny.org/
- **R Packages (2nd ed):** https://r-pkgs.org/
- **Shiny Modules:** https://shiny.posit.co/r/articles/improve/modules/

### Community Resources

- **RStudio Community:** https://forum.posit.co/c/shiny/8
- **Golem GitHub:** https://github.com/ThinkR-open/golem
- **Shiny App-Packages Book:** https://mjfrigaard.github.io/shiny-app-pkgs/

### Example Projects

- **Golem Demo:** https://github.com/ThinkR-open/golem-demo
- **Production Shiny Apps:** https://github.com/topics/golem

---

**Document Version:** 1.0.0
**Last Updated:** 2025-10-25
**Maintained By:** Development Team
**Questions?** Open an issue or discussion in the project repository.

---

**Remember:** Package structure is an investment. Upfront effort = long-term maintainability. Your recent refactoring work (modules, helpers) proves you're ready for this next step. The golem framework just formalizes what you've already started doing.

Good luck with the migration! 🚀
