# Two-Tier Navigation System Refactoring

**Type:** Enhancement Report
**Category:** UI/UX Modernization
**Status:** Implementation Planning
**Last Updated:** 2025-10-27
**Priority:** Medium
**Effort:** Large (Multi-phase implementation)

## Executive Summary

This document outlines a comprehensive refactoring plan to modernize the application's navigation system by implementing a two-tier header design inspired by modern dashboard applications. The refactoring will improve visual hierarchy, reduce UI clutter, remove grey containerization, and create a more spacious, professional interface.

### Key Changes

1. **Two-tier header system** - Separate module title bar and tab navigation bar
2. **Collapsible sidebar** - Icons-only mode with hover-to-reveal labels
3. **About this Analysis tab** - Move contextual help from bottom to dedicated tab
4. **Full-width content layout** - Remove grey content-card containers
5. **Dynamic tab configuration** - Configuration-driven tab system per module

### Visual References

All screenshots referenced in this document are located in:
```
docs/screenshots/ui-modernization/
```

---

## Table of Contents

1. [Current State Analysis](#current-state-analysis)
2. [Desired State Design](#desired-state-design)
3. [React Reference Pattern Analysis](#react-reference-pattern-analysis)
4. [Implementation Architecture](#implementation-architecture)
5. [Detailed Implementation Plan](#detailed-implementation-plan)
6. [File-by-File Changes](#file-by-file-changes)
7. [Testing Strategy](#testing-strategy)
8. [Migration Path](#migration-path)

---

## Current State Analysis

### Navigation Structure

**Reference:** `01-current-state-tabbed-navigation.png`

The current implementation uses:

```
Left Sidebar (fixed)
└── Module selection

Main Content Area
└── conditionalPanel (per module)
    ├── h2 (module title)
    ├── helpText (subtitle)
    ├── hr()
    ├── tabsetPanel (type = "pills")
    │   ├── tabPanel (Sample Size)
    │   ├── tabPanel (Power Analysis)
    │   └── tabPanel (Detectable Effect)
    ├── Common Parameters section
    └── Contextual Help (bottom of page)
```

**Key Issues:**

1. **Title/subtitle consumes vertical space** - Appears above tabs
2. **Grey container background** - Creates visual boxes around content
3. **Tabs float in content area** - No clear visual separation from content
4. **Contextual help at bottom** - Users must scroll to find "About this Analysis"
5. **No sidebar collapse** - Left sidebar always takes full width
6. **Limited visual hierarchy** - All content appears at same level

### Current Code Structure

**Module UI Pattern (mod_04_matched_case_control.R:10-210):**

```r
mod_04_matched_case_control_ui <- function(id) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = "input.sidebar_page == 'match_casecontrol'",

      h2(class = "page-title", "Matched Case-Control Study"),  # LINE 17
      helpText("Comprehensive power, sample size..."),           # LINE 18
      hr(),                                                      # LINE 19

      tabsetPanel(                                               # LINE 22
        id = ns("match_analysis_type"),
        type = "pills",

        tabPanel("Sample Size", ...),
        tabPanel("Power Analysis", ...),
        tabPanel("Detectable Effect", ...)
      ),

      # Common parameters
      hr(),
      h4("Common Parameters"),
      # ... common inputs ...
    )
  )
}
```

**App UI Structure (app_ui.R:136-217):**

```r
div(class = "app-container",
  create_sidebar_nav(),

  div(class = "main-content-wrapper",
    div(class = "main-content",

      div(class = "content-card",  # LINE 165 - GREY WRAPPER
        mod_01_single_proportion_ui("tab1"),
        mod_04_matched_case_control_ui("tab4"),
        # ... other modules
      )
    )
  )
)
```

**Contextual Help Location (app_ui.R:256-262):**

```r
# Contextual help for Matched Case-Control
conditionalPanel(
  condition = "input.sidebar_page == 'match_casecontrol'",
  div(class = "content-card help-section",
    create_contextual_help("matched")  # AT BOTTOM OF PAGE
  )
)
```

---

## Desired State Design

### Design Evolution

**Initial Concept:** `02-desired-cleaner-layout-v1.png`
- Shows tabs integrated into top navigation
- Cleaner content area without grey boxes
- No visible title/subtitle

**Revised Concept:** `03-desired-layout-with-title-subtitle.png`
- **This is the target design**
- Module title/subtitle visible in header area
- Tabs in separate navigation bar
- Four tabs including "About this Analysis"
- Content area uses full width without containers

### Desired Structure

```
App Header (existing - stays unchanged)

Collapsible Sidebar
├── Icon-only mode (see 04-collapsed-sidebar-icons-only.png)
└── Full mode with labels

Two-Tier Module Header
├── Tier 1: Module Title Bar
│   ├── [←] Sidebar toggle button (left)
│   ├── Module Title + Subtitle (center)
│   └── [⋮] Menu button → Documentation link (right)
│
└── Tier 2: Tab Navigation Bar
    ├── Sample Size (active shows white background)
    ├── Power Analysis
    ├── Detectable Effect
    └── About this Analysis (NEW)

Main Content Area (full width, white background)
└── Tab content (conditional)
    ├── Sample Size content
    ├── Power Analysis content
    ├── Detectable Effect content
    └── About this Analysis content (moved from bottom)
```

### Key Design Requirements

1. **No grey containers** - Pure white content background
2. **No title/subtitle in content** - Moved to Tier 1 header
3. **No tabsetPanel wrapper** - Use conditionalPanel per tab
4. **Common parameters inline** - Within each tab's content
5. **Calculate button hidden on About tab** - Conditional rendering

---

## React Reference Pattern Analysis

### Reference Application

**Screenshots:**
- `06-react-reference-two-tier-header.png` - Two-tier header with Overview tab active
- `07-react-reference-collapsed-sidebar.png` - Demographics tab with collapsed sidebar

This React-based dashboard application ("Atrial Fibrillation Registry") demonstrates the exact pattern we want to implement.

### Design Pattern Breakdown

#### Tier 1: Module Title Bar

**Visual characteristics:**
- Dark blue background (#2B5876 or similar)
- White text
- Left: Sidebar toggle (chevron icon)
- Center: Module title only ("Atrial Fibrillation Registry")
- Right: Settings icon + user avatar
- Height: ~60px
- Position: sticky top

#### Tier 2: Tab Navigation Bar

**Visual characteristics:**
- Light grey background (#E8EDF2)
- Tabs span full width
- Active tab: white background + colored bottom border
- Inactive tabs: transparent background + grey text
- Simple text labels (no icons)
- Height: ~48px
- Position: sticky below Tier 1

**Tab styling:**
```css
/* Active tab */
background: white;
color: #24292F;
border-bottom: 3px solid #2B5876;
padding: 16px 32px;

/* Inactive tab */
background: transparent;
color: #57606A;
border-bottom: 3px solid transparent;
padding: 16px 32px;
```

#### Content Area

**Visual characteristics:**
- Pure white background (no containers)
- Card-based layout for dashboard elements
- Generous padding: ~32-40px
- Max-width for readability: ~1600px
- Centered content

#### Sidebar Collapse Behavior

**Reference:** `07-react-reference-collapsed-sidebar.png`

When collapsed:
- Width: ~60px
- Icons only (no text)
- Chevron changes to right-facing (→)
- Likely shows labels on hover (not visible in screenshot)

**Advantages of This Pattern:**

1. ✅ **Simpler to implement** - Two divs instead of complex navbar
2. ✅ **Better visual hierarchy** - Clear separation of title and tabs
3. ✅ **Cleaner design** - No clutter, focused content
4. ✅ **Familiar UX** - Users recognize this from many web apps
5. ✅ **Mobile responsive** - Tabs can scroll horizontally
6. ✅ **Configuration-driven** - Easy to add/remove tabs per module

---

## Implementation Architecture

### Component Structure

```
New Components (to create):
├── R/fct_module_configs.R
│   └── MODULE_CONFIGS list (maps sidebar_page → title + tabs)
│
├── R/fct_module_header.R
│   └── create_module_header() → Two-tier header HTML
│
├── inst/app/www/css/two-tier-header.css
│   └── Styling for Tier 1 + Tier 2 navigation
│
├── inst/app/www/css/sidebar-collapsible.css
│   └── Collapsed/expanded sidebar states
│
└── inst/app/www/js/sidebar-collapse.js
    └── Toggle sidebar + persist state

Modified Components:
├── R/app_ui.R
│   ├── Remove content-card wrapper (line 165)
│   ├── Add module_header_ui output
│   └── Update conditionalPanel structure
│
├── R/app_server.R
│   ├── Add current_module() reactive
│   ├── Render module_header_ui
│   ├── Render dynamic tabs
│   └── Handle tab state initialization
│
└── R/mod_04_matched_case_control.R (and other modules)
    ├── Remove h2/helpText/hr (lines 17-19)
    ├── Remove tabsetPanel wrapper (line 22)
    ├── Replace with conditionalPanel per tab
    └── Add "About this Analysis" tab content
```

### Data Flow

```
User Action: Select module from sidebar
↓
input$sidebar_page changes
↓
current_module() reactive fires
↓
output$module_header_ui renders → Tier 1 + Tier 2
↓
output$module_tabs_dynamic renders → Tab buttons
↓
User Action: Click tab button
↓
JavaScript: Shiny.setInputValue('match_tab', 'sample_size')
↓
conditionalPanel(condition = "input.match_tab == 'sample_size'") shows
↓
Tab content displayed
```

### State Management

**Session State:**
```r
# Sidebar collapsed state
input$sidebar_collapsed  # Boolean, persisted in sessionStorage

# Current module
input$sidebar_page  # String, e.g., "match_casecontrol"

# Current tab per module
input$match_tab           # String, e.g., "sample_size"
input$power_single_tab    # String, e.g., "power"
# ... one per module
```

**Reactive Chain:**
```r
current_module()
  → module_header_ui()
    → module_tabs_dynamic()
      → tab conditionalPanels
```

---

## Detailed Implementation Plan

### Phase 1: Foundation (Configuration System)

**Goal:** Create module configuration system

**Files to create:**

#### `R/fct_module_configs.R`

```r
#' Module Configuration Registry
#'
#' Defines title and tabs for each module
#'
#' @format List of lists, keyed by sidebar_page value
#' @export
MODULE_CONFIGS <- list(

  # Matched Case-Control Study
  match_casecontrol = list(
    title = "Matched Case-Control Study",
    subtitle = "Comprehensive power, sample size, and effect size analysis for matched designs",
    tabs = list(
      list(id = "sample_size", label = "Sample Size"),
      list(id = "power", label = "Power Analysis"),
      list(id = "mde", label = "Detectable Effect"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Single Proportion
  power_single = list(
    title = "Single Proportion",
    subtitle = "Power and sample size for single proportion tests",
    tabs = list(
      list(id = "power", label = "Power Analysis"),
      list(id = "sample_size", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Two-Group Comparisons
  power_twogrp = list(
    title = "Two-Group Comparisons",
    subtitle = "Power and sample size for comparing two groups",
    tabs = list(
      list(id = "power", label = "Power Analysis"),
      list(id = "sample_size", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Survival Analysis (Cox)
  power_survival = list(
    title = "Survival Analysis (Cox)",
    subtitle = "Power and sample size for Cox proportional hazards models",
    tabs = list(
      list(id = "power", label = "Power Analysis"),
      list(id = "sample_size", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Continuous Outcomes
  power_continuous = list(
    title = "Continuous Outcomes",
    subtitle = "Power and sample size for continuous outcome comparisons",
    tabs = list(
      list(id = "power", label = "Power Analysis"),
      list(id = "sample_size", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Non-Inferiority Testing
  noninf = list(
    title = "Non-Inferiority Testing",
    subtitle = "Sample size for non-inferiority trials",
    tabs = list(
      list(id = "main", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # VIF Calculator
  vif_calculator = list(
    title = "VIF Calculator",
    subtitle = "Variance Inflation Factor and propensity score analysis",
    tabs = list(
      list(id = "main", label = "Calculator"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Mediation Analysis
  mediation_analysis = list(
    title = "Mediation Analysis",
    subtitle = "Sample size for mediation models",
    tabs = list(
      list(id = "main", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Time-to-Event Equivalence/NI
  survival_equivalence = list(
    title = "Time-to-Event Equivalence/Non-Inferiority",
    subtitle = "Sample size for time-to-event equivalence trials",
    tabs = list(
      list(id = "main", label = "Sample Size"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Sensitivity Analyses - E-value
  sensitivity_evalue = list(
    title = "E-value Sensitivity Analysis",
    subtitle = "Assess robustness to unmeasured confounding",
    tabs = list(
      list(id = "main", label = "Calculate E-value"),
      list(id = "about", label = "About this Analysis")
    )
  ),

  # Sensitivity Analyses - Multi-Bias
  sensitivity_multi_bias = list(
    title = "Multiple-Bias Sensitivity Analysis",
    subtitle = "Quantify impact of multiple bias sources",
    tabs = list(
      list(id = "main", label = "Bias Analysis"),
      list(id = "about", label = "About this Analysis")
    )
  )
)

#' Get Module Configuration
#'
#' @param sidebar_page String, current sidebar page ID
#' @return List with title, subtitle, tabs, or NULL if not found
#' @export
get_module_config <- function(sidebar_page) {
  MODULE_CONFIGS[[sidebar_page]] %||% NULL
}
```

**Testing:**
```r
# Test configuration access
config <- get_module_config("match_casecontrol")
expect_equal(config$title, "Matched Case-Control Study")
expect_length(config$tabs, 4)
```

---

### Phase 2: Two-Tier Header Component

**Goal:** Create reusable header component

#### `R/fct_module_header.R`

```r
#' Create Two-Tier Module Header
#'
#' Generates a two-tier navigation header:
#' - Tier 1: Module title bar with sidebar toggle and menu
#' - Tier 2: Tab navigation bar
#'
#' @param module_config List with title, subtitle, tabs from MODULE_CONFIGS
#' @param sidebar_collapsed Boolean, current sidebar state
#'
#' @return tagList with header HTML
#'
#' @importFrom shiny tagList tags actionButton icon uiOutput
#' @export
create_module_header <- function(module_config = NULL, sidebar_collapsed = FALSE) {

  if (is.null(module_config)) {
    return(NULL)
  }

  tagList(
    # TIER 1: Module Title Bar
    tags$div(
      class = "module-title-bar",

      # Left: Sidebar toggle button
      actionButton(
        "sidebar_toggle",
        icon = icon(if(sidebar_collapsed) "chevron-right" else "chevron-left"),
        class = "sidebar-toggle-btn",
        title = "Toggle sidebar"
      ),

      # Center: Module title and subtitle
      tags$div(
        class = "module-header-content",
        tags$h1(class = "module-title", module_config$title),
        if (!is.null(module_config$subtitle)) {
          tags$p(class = "module-subtitle", module_config$subtitle)
        }
      ),

      # Right: Menu button with dropdown
      tags$div(
        class = "header-actions",
        actionButton(
          "header_menu",
          icon = icon("ellipsis-v"),
          class = "header-menu-btn",
          title = "More options"
        ),

        # Dropdown menu (hidden by default)
        tags$div(
          id = "header-menu-dropdown",
          class = "header-dropdown hidden",
          tags$a(
            href = "#",
            onclick = "Shiny.setInputValue('sidebar_page', 'documentation', {priority: 'event'}); return false;",
            icon("book"),
            "Documentation"
          )
        )
      )
    ),

    # TIER 2: Tab Navigation Bar (rendered dynamically)
    tags$div(
      class = "module-tab-bar",
      uiOutput("module_tabs_dynamic")
    )
  )
}
```

**Usage in app_ui.R:**
```r
# Render header when not on documentation page
conditionalPanel(
  condition = "input.sidebar_page != 'documentation'",
  uiOutput("module_header_ui")
)
```

---

### Phase 3: CSS Styling

**Goal:** Style the two-tier header to match React reference

#### `inst/app/www/css/two-tier-header.css`

```css
/* ============================================================
   TIER 1: MODULE TITLE BAR
   ============================================================ */

.module-title-bar {
  display: flex;
  align-items: center;
  background: var(--primary-blue, #2B5876);
  color: white;
  padding: 0;
  min-height: 60px;
  position: sticky;
  top: 0;
  z-index: 100;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.sidebar-toggle-btn {
  background: transparent;
  border: none;
  color: white;
  padding: 20px;
  font-size: 18px;
  cursor: pointer;
  transition: background 0.2s;
  min-width: 60px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.sidebar-toggle-btn:hover {
  background: rgba(255,255,255,0.1);
}

.sidebar-toggle-btn:focus {
  outline: 2px solid rgba(255,255,255,0.5);
  outline-offset: -2px;
}

.module-header-content {
  flex: 1;
  padding: 0 20px;
}

.module-title {
  font-size: 20px;
  font-weight: 600;
  margin: 0 0 4px 0;
  color: white;
  line-height: 1.2;
}

.module-subtitle {
  font-size: 13px;
  color: rgba(255,255,255,0.85);
  margin: 0;
  line-height: 1.3;
}

.header-actions {
  position: relative;
  padding: 0 20px;
}

.header-menu-btn {
  background: transparent;
  border: none;
  color: white;
  font-size: 18px;
  cursor: pointer;
  padding: 10px;
  border-radius: 4px;
  transition: background 0.2s;
}

.header-menu-btn:hover {
  background: rgba(255,255,255,0.1);
}

.header-dropdown {
  position: absolute;
  right: 0;
  top: 100%;
  margin-top: 8px;
  background: white;
  border-radius: 6px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  min-width: 200px;
  z-index: 1000;
  overflow: hidden;
}

.header-dropdown.hidden {
  display: none;
}

.header-dropdown a {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 16px;
  color: var(--text-primary, #24292F);
  text-decoration: none;
  transition: background 0.2s;
}

.header-dropdown a:hover {
  background: var(--bg-hover, #F6F8FA);
}

/* ============================================================
   TIER 2: TAB NAVIGATION BAR
   ============================================================ */

.module-tab-bar {
  display: flex;
  background: #E8EDF2;
  border-bottom: 1px solid #D0D7DE;
  position: sticky;
  top: 60px;
  z-index: 99;
  overflow-x: auto;
  overflow-y: hidden;
  scrollbar-width: none; /* Firefox */
  -webkit-overflow-scrolling: touch; /* iOS smooth scrolling */
}

.module-tab-bar::-webkit-scrollbar {
  display: none; /* Chrome, Safari */
}

.module-tab {
  flex: 0 0 auto;
  padding: 16px 32px;
  background: transparent;
  border: none;
  color: #57606A;
  font-size: 15px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s ease;
  border-bottom: 3px solid transparent;
  white-space: nowrap;
  position: relative;
}

.module-tab:hover {
  color: #24292F;
  background: rgba(255,255,255,0.5);
}

.module-tab.active {
  background: white;
  color: #24292F;
  border-bottom: 3px solid var(--primary-blue, #2B5876);
}

.module-tab:focus {
  outline: 2px solid var(--primary-blue, #2B5876);
  outline-offset: -2px;
}

/* ============================================================
   CONTENT AREA
   ============================================================ */

.main-content {
  background: white;
  padding: 0;
  min-height: calc(100vh - 120px); /* Account for header heights */
}

.tab-content-wrapper {
  padding: 32px 40px;
  max-width: 1600px;
  margin: 0 auto;
  animation: fadeIn 0.2s ease-in;
}

@keyframes fadeIn {
  from {
    opacity: 0;
    transform: translateY(8px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Input sections within tabs */
.input-section {
  margin-bottom: 24px;
}

.input-section h4 {
  font-size: 18px;
  font-weight: 600;
  margin-bottom: 16px;
  color: var(--text-primary, #24292F);
}

/* About tab styling */
.about-content {
  max-width: 1200px;
}

/* ============================================================
   DARK MODE
   ============================================================ */

[data-theme='dark'] .module-title-bar {
  background: #1C2938;
}

[data-theme='dark'] .module-tab-bar {
  background: #0D1B2A;
  border-bottom-color: #2D3A4A;
}

[data-theme='dark'] .module-tab {
  color: #8B949E;
}

[data-theme='dark'] .module-tab:hover {
  color: #C9D1D9;
  background: rgba(255,255,255,0.05);
}

[data-theme='dark'] .module-tab.active {
  background: #0F172A;
  color: #F0F6FC;
  border-bottom-color: var(--accent-primary, #4A9EFF);
}

[data-theme='dark'] .main-content {
  background: #0F172A;
}

[data-theme='dark'] .header-dropdown {
  background: #1C2938;
  border: 1px solid #2D3A4A;
}

[data-theme='dark'] .header-dropdown a {
  color: #C9D1D9;
}

[data-theme='dark'] .header-dropdown a:hover {
  background: rgba(255,255,255,0.05);
}

/* ============================================================
   RESPONSIVE
   ============================================================ */

@media (max-width: 768px) {
  .module-title-bar {
    min-height: 56px;
  }

  .sidebar-toggle-btn {
    padding: 16px;
    min-width: 50px;
  }

  .module-title {
    font-size: 18px;
  }

  .module-subtitle {
    font-size: 12px;
  }

  .module-tab {
    padding: 14px 24px;
    font-size: 14px;
  }

  .tab-content-wrapper {
    padding: 24px 20px;
  }
}

@media (max-width: 480px) {
  .module-subtitle {
    display: none; /* Hide subtitle on very small screens */
  }

  .module-tab {
    padding: 12px 20px;
  }
}
```

**Add to app_ui.R (line 34):**
```r
tags$link(rel = "stylesheet", type = "text/css", href = "www/css/two-tier-header.css"),
```

---

### Phase 4: Collapsible Sidebar

**Goal:** Enable sidebar collapse to icon-only mode

#### `inst/app/www/css/sidebar-collapsible.css`

```css
/* ============================================================
   COLLAPSIBLE SIDEBAR
   ============================================================ */

.sidebar {
  width: 250px;
  transition: width 0.3s ease;
  overflow-x: hidden;
}

.sidebar.collapsed {
  width: 60px;
}

/* Hide text when collapsed */
.sidebar.collapsed .nav-text {
  display: none;
}

/* Center icons when collapsed */
.sidebar.collapsed .nav-icon {
  margin: 0 auto;
  font-size: 24px;
}

.sidebar.collapsed .nav-item {
  padding: 12px 0;
  justify-content: center;
}

/* Show label on hover when collapsed */
.sidebar.collapsed .nav-item:hover .nav-text {
  display: block;
  position: absolute;
  left: 60px;
  top: 50%;
  transform: translateY(-50%);
  background: var(--bg-elevated, #1C2938);
  color: white;
  padding: 8px 16px;
  border-radius: 4px;
  white-space: nowrap;
  z-index: 1000;
  box-shadow: 0 2px 8px rgba(0,0,0,0.15);
  pointer-events: none;
  animation: slideIn 0.2s ease;
}

@keyframes slideIn {
  from {
    opacity: 0;
    transform: translateY(-50%) translateX(-8px);
  }
  to {
    opacity: 1;
    transform: translateY(-50%) translateX(0);
  }
}

/* Adjust main content when sidebar collapsed */
.main-content-wrapper {
  margin-left: 250px;
  transition: margin-left 0.3s ease;
}

.main-content-wrapper.sidebar-collapsed {
  margin-left: 60px;
}

/* Dark mode */
[data-theme='dark'] .sidebar.collapsed .nav-item:hover .nav-text {
  background: #2D3A4A;
  box-shadow: 0 2px 8px rgba(0,0,0,0.3);
}

/* Mobile: Always show full sidebar when visible */
@media (max-width: 768px) {
  .sidebar {
    width: 250px;
  }

  .sidebar.collapsed {
    width: 0;
  }

  .main-content-wrapper {
    margin-left: 0;
  }
}
```

**Add to app_ui.R (line 38):**
```r
tags$link(rel = "stylesheet", type = "text/css", href = "www/css/sidebar-collapsible.css"),
```

#### `inst/app/www/js/sidebar-collapse.js`

```javascript
/**
 * Sidebar Collapse Toggle
 *
 * Handles sidebar expansion/collapse with state persistence
 */

$(document).ready(function() {

  // Restore sidebar state from sessionStorage
  const isCollapsed = sessionStorage.getItem('sidebarCollapsed') === 'true';
  if (isCollapsed) {
    $('.sidebar').addClass('collapsed');
    $('.main-content-wrapper').addClass('sidebar-collapsed');
    updateToggleIcon(true);
  }

  // Toggle sidebar on button click
  $(document).on('click', '#sidebar_toggle', function(e) {
    e.preventDefault();

    const sidebar = $('.sidebar');
    const isNowCollapsed = !sidebar.hasClass('collapsed');

    // Toggle classes
    sidebar.toggleClass('collapsed');
    $('.main-content-wrapper').toggleClass('sidebar-collapsed', isNowCollapsed);

    // Update button icon
    updateToggleIcon(isNowCollapsed);

    // Persist state
    sessionStorage.setItem('sidebarCollapsed', isNowCollapsed);

    // Notify Shiny (optional, for reactive tracking)
    Shiny.setInputValue('sidebar_collapsed', isNowCollapsed, {priority: 'event'});
  });

  // Update toggle button icon
  function updateToggleIcon(collapsed) {
    const icon = $('#sidebar_toggle i');
    icon.removeClass('fa-chevron-left fa-chevron-right');
    icon.addClass(collapsed ? 'fa-chevron-right' : 'fa-chevron-left');
  }

  // Toggle dropdown menu
  $(document).on('click', '#header_menu', function(e) {
    e.preventDefault();
    e.stopPropagation();
    $('#header-menu-dropdown').toggleClass('hidden');
  });

  // Close dropdown when clicking outside
  $(document).on('click', function(e) {
    if (!$(e.target).closest('.header-actions').length) {
      $('#header-menu-dropdown').addClass('hidden');
    }
  });
});
```

**Add to app_ui.R (line 54):**
```r
tags$script(src = "www/js/sidebar-collapse.js"),
```

---

### Phase 5: Server Logic

**Goal:** Wire up reactive rendering of headers and tabs

#### Update `R/app_server.R`

**Add after existing observes (around line 50):**

```r
# ============================================================
# TWO-TIER HEADER SYSTEM
# ============================================================

# Reactive: Get current module configuration
current_module <- reactive({
  req(input$sidebar_page)

  # Skip if on documentation page
  if (input$sidebar_page == "documentation") {
    return(NULL)
  }

  get_module_config(input$sidebar_page)
})

# Render module header (Tier 1 + Tier 2 container)
output$module_header_ui <- renderUI({
  config <- current_module()
  if (is.null(config)) return(NULL)

  create_module_header(
    module_config = config,
    sidebar_collapsed = input$sidebar_collapsed %||% FALSE
  )
})

# Render dynamic tabs (Tier 2 content)
output$module_tabs_dynamic <- renderUI({
  config <- current_module()
  if (is.null(config) || length(config$tabs) == 0) return(NULL)

  # Get current tab ID for this module
  tab_input_id <- paste0(input$sidebar_page, "_tab")
  current_tab <- input[[tab_input_id]] %||% config$tabs[[1]]$id

  # Generate tab buttons
  tabs <- lapply(config$tabs, function(tab) {
    tags$button(
      class = paste0("module-tab", if(current_tab == tab$id) " active" else ""),
      onclick = sprintf(
        "Shiny.setInputValue('%s_tab', '%s', {priority: 'event'})",
        input$sidebar_page,
        tab$id
      ),
      tab$label
    )
  })

  tagList(tabs)
})

# Initialize tab state when module changes
observe({
  req(input$sidebar_page)

  config <- get_module_config(input$sidebar_page)
  if (!is.null(config) && length(config$tabs) > 0) {
    # Set default tab to first tab
    default_tab <- config$tabs[[1]]$id
    tab_input_id <- paste0(input$sidebar_page, "_tab")

    # Only update if not already set
    if (is.null(input[[tab_input_id]])) {
      updateTextInput(session, tab_input_id, value = default_tab)
    }
  }
})

# Hide Calculate button on "About" tabs
observe({
  req(input$sidebar_page)

  # Get current tab
  tab_input_id <- paste0(input$sidebar_page, "_tab")
  current_tab <- input[[tab_input_id]]

  # Hide if on "about" tab
  if (!is.null(current_tab) && current_tab == "about") {
    shinyjs::hide("go")
  } else {
    shinyjs::show("go")
  }
})
```

---

### Phase 6: Module Refactoring

**Goal:** Refactor modules to use new structure

#### Module Refactoring Pattern

**BEFORE (old structure):**
```r
mod_04_matched_case_control_ui <- function(id) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = "input.sidebar_page == 'match_casecontrol'",

      h2("Matched Case-Control Study"),    # REMOVE
      helpText("Comprehensive power..."),   # REMOVE
      hr(),                                 # REMOVE

      tabsetPanel(                          # REMOVE WRAPPER
        id = ns("match_analysis_type"),
        type = "pills",

        tabPanel("Sample Size", ...),
        tabPanel("Power Analysis", ...),
        tabPanel("Detectable Effect", ...)
      ),

      # Common parameters
      hr(),
      h4("Common Parameters"),
      # ...
    )
  )
}
```

**AFTER (new structure):**
```r
mod_04_matched_case_control_ui <- function(id) {
  ns <- NS(id)

  tagList(
    conditionalPanel(
      condition = "input.sidebar_page == 'match_casecontrol'",

      # NO title, subtitle, tabsetPanel wrapper

      # TAB 1: Sample Size
      conditionalPanel(
        condition = "input.match_tab == 'sample_size'",
        div(class = "tab-content-wrapper",
          h3("Calculate Required Sample Size"),
          p(class = "lead-text",
            "Determine the number of matched pairs needed to detect a specified odds ratio with desired power"
          ),

          # Inputs
          div(class = "input-section",
            create_segmented_power(
              ns("match_power_ss"),
              "Desired Power:",
              selected = 80,
              tooltip = "Probability of detecting the effect if it exists"
            ),

            create_numeric_input_with_tooltip(
              ns("match_or_ss"),
              "Target Odds Ratio (OR):",
              value = 2.0,
              min = 0.01,
              max = 20,
              step = 0.1,
              tooltip = "Expected odds ratio to detect",
              validation_type = "odds_ratio",
              help_content = HTML("...")
            ),

            create_enhanced_slider(
              ns("match_p0_ss"),
              "Exposure Probability in Controls (%):",
              min = 5, max = 95, value = 20, step = 5, post = "%",
              tooltip = "Expected proportion of controls exposed"
            )
          ),

          # Common parameters (inline, not separate section)
          hr(),
          h4("Additional Parameters"),
          div(class = "input-section",
            create_numeric_input_with_tooltip(
              ns("match_ratio"),
              "Controls per Case:",
              value = 1, min = 1, max = 5, step = 1,
              tooltip = "Number of matched controls per case"
            ),

            create_segmented_alpha(
              ns("match_alpha"),
              "Significance Level (α):",
              selected = 0.05,
              tooltip = "Type I error rate"
            ),

            bslib::tooltip(
              radioButtons_fixed(
                ns("match_sided"),
                "Test Type:",
                choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
                selected = "two.sided"
              ),
              "Two-sided: test if groups differ"
            )
          ),

          # Advanced options
          hr(),
          missing_data_ui(ns("missing_data")),
          hr(),
          h4("Clustering Adjustment"),
          clustering_ui(ns("clustering")),
          hr(),
          h4("Multiple Testing Corrections"),
          multiple_testing_ui(ns("multiple_testing")),
          hr(),
          div(class = "btn-group-custom",
            actionButton(ns("example_match"), "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
            actionButton(ns("reset_match"), "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
          )
        )
      ),

      # TAB 2: Power Analysis
      conditionalPanel(
        condition = "input.match_tab == 'power'",
        div(class = "tab-content-wrapper",
          h3("Calculate Statistical Power"),
          p(class = "lead-text",
            "Determine the power given available sample size and expected effect size"
          ),

          # Similar structure to Sample Size tab
          div(class = "input-section",
            # ... inputs ...
          ),

          hr(),
          h4("Additional Parameters"),
          div(class = "input-section",
            # ... common parameters ...
          ),

          # ... rest of inputs ...
        )
      ),

      # TAB 3: Detectable Effect
      conditionalPanel(
        condition = "input.match_tab == 'mde'",
        div(class = "tab-content-wrapper",
          h3("Calculate Minimal Detectable Odds Ratio"),
          p(class = "lead-text",
            "Determine the smallest effect size detectable with available sample and desired power"
          ),

          # Similar structure
          # ...
        )
      ),

      # TAB 4: About this Analysis (NEW)
      conditionalPanel(
        condition = "input.match_tab == 'about'",
        div(class = "tab-content-wrapper about-content",
          # Move contextual help here from bottom of app_ui.R
          create_contextual_help("matched")
        )
      )
    )
  )
}
```

**Key Changes:**

1. ✅ Remove `h2()`, `helpText()`, `hr()` at top
2. ✅ Remove `tabsetPanel()` wrapper
3. ✅ Replace with `conditionalPanel()` per tab
4. ✅ Use `input.match_tab` instead of `input.match_analysis_type`
5. ✅ Wrap content in `.tab-content-wrapper` div
6. ✅ Move common parameters inline within each tab
7. ✅ Add "About this Analysis" tab with `create_contextual_help()`

**Server Changes:**

Update all references from `input$match_analysis_type` to `input$match_tab`:

```r
# BEFORE
observeEvent(input$example_match, {
  req(input$match_analysis_type)
  if (isTRUE(input$match_analysis_type == "sample_size")) {
    # ...
  }
})

# AFTER
observeEvent(input$example_match, {
  req(input$match_tab)
  if (isTRUE(input$match_tab == "sample_size")) {
    # ...
  }
})
```

---

### Phase 7: Update app_ui.R

**Goal:** Remove grey containers and integrate new header

#### Changes to `app_ui.R`

**1. Add module header output (after line 142):**

```r
div(class = "main-content-wrapper",

  # Two-tier module header (shown for all modules except documentation)
  conditionalPanel(
    condition = "input.sidebar_page != 'documentation'",
    uiOutput("module_header_ui")
  ),

  div(class = "main-content",
    # ...
```

**2. Remove content-card wrapper (line 165):**

**BEFORE:**
```r
conditionalPanel(
  condition = "input.sidebar_page != 'documentation'",

  div(class = "content-card",  # REMOVE THIS LINE
    mod_01_single_proportion_ui("tab1"),
    mod_02_two_group_ui("tab2"),
    # ...
  ), # REMOVE THIS LINE

  # Calculate button
  actionButton("go", "Calculate", ...)
```

**AFTER:**
```r
conditionalPanel(
  condition = "input.sidebar_page != 'documentation'",

  # Direct module rendering - no wrapper
  mod_01_single_proportion_ui("tab1"),
  mod_02_two_group_ui("tab2"),
  mod_03_survival_ui("tab3"),
  mod_04_matched_case_control_ui("tab4"),
  mod_05_continuous_ui("tab5"),
  mod_06_non_inferiority_ui("tab6"),
  mod_07_vif_ps_ui("tab7"),
  mod_08_mediation_ui("tab8"),
  mod_09_survival_equivalence_ui("tab9"),
  mod_10_sensitivity_analyses_ui("tab10"),

  # Calculate button (already conditionally hidden by server logic)
  actionButton("go", "Calculate", icon = icon("calculator"), class = "btn-primary btn-lg w-100"),

  # Results
  uiOutput("live_preview"),
  uiOutput("result_text"),
  # ...
```

**3. Remove contextual help panels (lines 232-310):**

These sections are **DELETED** because contextual help moves to "About" tab:

```r
# DELETE THIS ENTIRE SECTION
# Contextual help for Single Proportion
conditionalPanel(
  condition = "input.sidebar_page == 'power_single' || input.sidebar_page == 'ss_single'",
  div(class = "content-card help-section",
    create_contextual_help("single_proportion")
  )
),

# DELETE: Contextual help for Two-Group Comparisons
# DELETE: Contextual help for Survival Analysis
# DELETE: Contextual help for Matched Case-Control
# DELETE: All other contextual help panels
# ... (lines 232-310)
```

---

## File-by-File Changes

### Summary Table

| File | Action | Lines | Description |
|------|--------|-------|-------------|
| `R/fct_module_configs.R` | **CREATE** | - | Module configuration registry |
| `R/fct_module_header.R` | **CREATE** | - | Two-tier header component |
| `inst/app/www/css/two-tier-header.css` | **CREATE** | - | Header styling |
| `inst/app/www/css/sidebar-collapsible.css` | **CREATE** | - | Sidebar collapse styles |
| `inst/app/www/js/sidebar-collapse.js` | **CREATE** | - | Sidebar toggle logic |
| `R/app_ui.R` | **MODIFY** | 34 | Add CSS link |
| `R/app_ui.R` | **MODIFY** | 38 | Add CSS link |
| `R/app_ui.R` | **MODIFY** | 54 | Add JS script |
| `R/app_ui.R` | **MODIFY** | 142 | Add header output |
| `R/app_ui.R` | **DELETE** | 165 | Remove content-card wrapper |
| `R/app_ui.R` | **DELETE** | 232-310 | Remove contextual help panels |
| `R/app_server.R` | **ADD** | ~50 | Add header reactive logic |
| `R/mod_04_matched_case_control.R` | **REFACTOR** | 10-210 | Remove tabsetPanel, add conditionalPanel per tab |
| `R/mod_04_matched_case_control.R` | **MODIFY** | 228-275 | Update server input references |
| `R/mod_01_single_proportion.R` | **REFACTOR** | - | Apply same pattern |
| `R/mod_02_two_group.R` | **REFACTOR** | - | Apply same pattern |
| `R/mod_03_survival.R` | **REFACTOR** | - | Apply same pattern |
| `R/mod_05_continuous.R` | **REFACTOR** | - | Apply same pattern |
| All other modules | **REFACTOR** | - | Apply same pattern |

---

## Testing Strategy

### Unit Tests

**Test module configuration:**
```r
# tests/testthat/test-module-configs.R
test_that("MODULE_CONFIGS has correct structure", {
  expect_type(MODULE_CONFIGS, "list")
  expect_true("match_casecontrol" %in% names(MODULE_CONFIGS))

  config <- MODULE_CONFIGS$match_casecontrol
  expect_true("title" %in% names(config))
  expect_true("tabs" %in% names(config))
  expect_length(config$tabs, 4)
})

test_that("get_module_config returns correct config", {
  config <- get_module_config("match_casecontrol")
  expect_equal(config$title, "Matched Case-Control Study")

  no_config <- get_module_config("nonexistent")
  expect_null(no_config)
})
```

**Test header component:**
```r
# tests/testthat/test-module-header.R
test_that("create_module_header returns NULL for NULL config", {
  result <- create_module_header(NULL)
  expect_null(result)
})

test_that("create_module_header generates correct HTML", {
  config <- list(
    title = "Test Module",
    subtitle = "Test subtitle",
    tabs = list(
      list(id = "tab1", label = "Tab 1")
    )
  )

  result <- create_module_header(config)
  expect_s3_class(result, "shiny.tag.list")

  html <- as.character(result)
  expect_true(grepl("module-title-bar", html))
  expect_true(grepl("Test Module", html))
})
```

### Integration Tests

**Manual testing checklist:**

- [ ] Sidebar toggle works (collapse/expand)
- [ ] Sidebar state persists across page reloads
- [ ] Hover over collapsed sidebar shows labels
- [ ] Module header shows correct title for each module
- [ ] Tabs render dynamically based on module
- [ ] Active tab highlights correctly
- [ ] Tab clicks change content
- [ ] Content animates smoothly on tab change
- [ ] "About" tab shows contextual help
- [ ] Calculate button hidden on "About" tab
- [ ] Calculate button visible on other tabs
- [ ] Header menu dropdown opens/closes
- [ ] Documentation link navigates correctly
- [ ] Dark mode styling works
- [ ] Responsive layout works on mobile
- [ ] No grey containers visible
- [ ] Full-width layout renders correctly

### Browser Testing

Test in:
- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

### Accessibility Testing

- [ ] Keyboard navigation works (Tab, Enter, Space)
- [ ] Focus indicators visible
- [ ] ARIA labels present on buttons
- [ ] Screen reader announces tab changes
- [ ] Color contrast meets WCAG AA standards

---

## Migration Path

### Recommended Phased Approach

**Phase 1: Foundation (Week 1)**
- Create `R/fct_module_configs.R`
- Create `R/fct_module_header.R`
- Create CSS files
- Create JS file
- Add to `app_ui.R` (links/scripts)
- Test configuration system

**Phase 2: Infrastructure (Week 1-2)**
- Add server logic to `app_server.R`
- Update `app_ui.R` to add header output
- Remove content-card wrapper
- Test header rendering without module changes

**Phase 3: Pilot Module (Week 2)**
- Refactor `mod_04_matched_case_control.R` completely
- Test thoroughly
- Document any issues
- Adjust configuration/server logic as needed

**Phase 4: Remaining Modules (Week 3-4)**
- Apply pattern to all other modules
- Update each module's server logic
- Remove old contextual help panels from `app_ui.R`
- Test each module after refactoring

**Phase 5: Polish & Testing (Week 5)**
- Final CSS adjustments
- Responsive testing
- Accessibility testing
- Browser compatibility testing
- Documentation updates

### Rollback Strategy

If issues arise:
1. Keep old code in comments during refactoring
2. Use feature flags to toggle between old/new UI
3. Git branch strategy: `feature/two-tier-nav`
4. Can rollback individual modules without affecting others

---

## Potential Issues & Solutions

### Issue 1: Tab State Lost on Module Switch

**Problem:** When user switches modules, tab state resets

**Solution:** Store tab state per module in session:
```r
observe({
  req(input$sidebar_page, input[[paste0(input$sidebar_page, "_tab")]])
  # Store in reactiveValues
  module_tab_states[[input$sidebar_page]] <- input[[paste0(input$sidebar_page, "_tab")]]
})
```

### Issue 2: Calculate Button Timing

**Problem:** Button visibility flickers during tab changes

**Solution:** Use `shinyjs::delay()`:
```r
observe({
  current_tab <- input[[paste0(input$sidebar_page, "_tab")]]
  shinyjs::delay(100, {
    if (current_tab == "about") {
      shinyjs::hide("go")
    } else {
      shinyjs::show("go")
    }
  })
})
```

### Issue 3: Mobile Sidebar Overlap

**Problem:** Collapsed sidebar doesn't work well on mobile

**Solution:** Use media query to hide sidebar completely on mobile:
```css
@media (max-width: 768px) {
  .sidebar.collapsed {
    width: 0;
    visibility: hidden;
  }
}
```

### Issue 4: Tab Scrolling on Small Screens

**Problem:** Too many tabs don't fit on narrow screens

**Solution:** Already implemented - `.module-tab-bar` has `overflow-x: auto` and hidden scrollbars for smooth horizontal scrolling

---

## Success Criteria

### Visual Criteria

✅ Header matches React reference design
✅ No grey containers visible
✅ Full-width content layout
✅ Clean visual hierarchy (title → tabs → content)
✅ Smooth animations and transitions
✅ Dark mode styling works correctly

### Functional Criteria

✅ All modules have "About this Analysis" tab
✅ Sidebar collapses to icons-only mode
✅ Tab state persists within session
✅ Calculate button hides on About tab
✅ All existing functionality preserved
✅ No console errors

### Performance Criteria

✅ Tab switching < 100ms
✅ Sidebar toggle < 300ms
✅ No layout shift on page load
✅ Smooth 60fps animations

---

## Future Enhancements

After successful implementation, consider:

1. **Tab badges** - Show validation status or result counts
2. **Tab icons** - Add optional icons (currently text-only)
3. **Sticky Calculate button** - Button follows scroll on long forms
4. **Tab history** - Browser back/forward navigation between tabs
5. **Keyboard shortcuts** - Ctrl+1-9 to jump to tabs
6. **Tab tooltips** - Show descriptions on hover

---

## Related Documentation

- **Current navigation implementation:** `R/fct_sidebar.R`
- **Module structure:** `R/mod_*.R`
- **App layout:** `R/app_ui.R`
- **Contextual help:** `R/fct_contextual_help.R`
- **CSS system:** `inst/app/www/css/`

---

## Questions for Implementation Agent

When implementing this plan, consider:

1. **Should all modules have the same tab structure?**
   - Some modules may only need 2 tabs (main + about)
   - Current plan is flexible via MODULE_CONFIGS

2. **Should sidebar remember collapse state per user?**
   - Currently using sessionStorage (per session)
   - Could upgrade to localStorage (persistent) or user preferences

3. **Should tabs support icons?**
   - React reference uses text-only
   - Current Shiny version uses icons
   - Recommendation: Start text-only, add icons later if needed

4. **Should Calculate button position change?**
   - Currently at top of results
   - Could make sticky or move to header

5. **Should we support URL routing for tabs?**
   - Would enable shareable URLs like `?module=match&tab=power`
   - Requires additional implementation

---

## Conclusion

This refactoring represents a significant UX improvement that will:

- Modernize the application's appearance
- Improve navigation clarity
- Reduce visual clutter
- Create a more professional, dashboard-like experience
- Make contextual help more discoverable via dedicated "About" tabs
- Improve mobile responsiveness
- Align with modern web application patterns

The phased implementation approach allows for incremental progress with minimal risk. Start with the matched case-control module as a pilot, validate the approach, then systematically apply to remaining modules.

**Estimated Total Effort:** 3-5 weeks (depending on testing depth)

**Risk Level:** Medium (requires careful testing of module interactions)

**User Impact:** High (visible change to all users, significant UX improvement)

---

**Next Steps:**

1. Review this document with stakeholders
2. Create implementation branch: `git checkout -b feature/two-tier-nav`
3. Begin Phase 1 (Foundation) implementation
4. Create tracking issue in project management system
5. Schedule weekly progress reviews

**Document Version:** 1.0
**Last Updated:** 2025-10-27
**Author:** Claude Code
**Status:** Ready for Implementation
