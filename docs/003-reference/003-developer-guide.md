# CLAUDE.md - Power Analysis Tool Developer Documentation

This file provides comprehensive guidance to Claude Code (claude.ai/code) when working with this R Shiny application for statistical power analysis in pharmaceutical real-world evidence (RWE) research.

**Documentation Framework:** This file follows the [Diataxis documentation framework](https://diataxis.fr/), organizing content into four distinct types to serve different developer needs efficiently.

---

## Table of Contents

### 📚 [Getting Started (Tutorials)](#getting-started-tutorials)
Learning-oriented guides for first-time developers

### 🛠️ [How-To Guides](#how-to-guides)
Task-oriented instructions for specific development tasks

### 📖 [Reference](#reference)
Information-oriented technical specifications

### 💡 [Explanation](#explanation)
Understanding-oriented discussions of design decisions

---

# Getting Started (Tutorials)

*Learning-oriented: Practical lessons for developers new to this codebase*

## Tutorial 1: Your First Development Session

This tutorial walks you through setting up the development environment, running the application, and making your first modification.

### Prerequisites
- R ≥ 4.2.0 installed (recommended 4.4.0)
- Basic familiarity with R and Shiny
- Git installed

### Step 1: Clone and Set Up the Environment

```bash
cd /home/mike/Documents/sharedFolder/power-analysis-tool
```

You should see the following key files:
- `app.R` - The main application (~1,815 lines)
- `renv.lock` - Package dependencies
- `Dockerfile` - Container configuration

### Step 2: Initialize Package Dependencies

This project uses **renv** for reproducible package management (R's equivalent of Python's `uv`):

```r
# In R console, navigate to project directory
# renv will automatically activate (via .Rprofile)

# Install all dependencies from lockfile
renv::restore()
```

You'll see package installation progress. This may take 5-10 minutes the first time.

### Step 3: Run the Application

```r
# In R console
shiny::runApp("app.R")
```

You should see output like:
```
Listening on http://127.0.0.1:4567
```

Open that URL in your browser. You should see the power analysis interface with multiple tabs.

### Step 4: Understand the Delayed Evaluation Pattern

This application uses a **delayed evaluation pattern** - results only calculate when you click "Calculate", not when inputs change.

**Try this:**
1. Navigate to the "Power (Single)" tab
2. Change the "Available Sample Size" to 500
3. Notice: Nothing happens yet
4. Click the **Calculate** button
5. Now you see results appear

**Why it works this way:**
- Prevents expensive recalculations while typing
- Gives users explicit control
- Standard pattern for "submit" workflows

### Step 5: Find Where Calculations Happen

Open `app.R` and search for `output$result_text <- renderText({`

You'll find this pattern (around line 580):

```r
output$result_text <- renderText({
    if (v$doAnalysis == FALSE) return()  # Don't render until Calculate clicked
    isolate({
        # All calculations happen here
        # isolate() prevents reactive dependencies
    })
})
```

**Key concepts:**
- `v$doAnalysis` - Reactive flag controlled by Calculate button
- `isolate({...})` - Breaks reactive dependencies to prevent cascading updates
- Pattern repeats for every output across all tabs

### Step 6: Make Your First Modification

Let's change the default sample size from 230 to 300.

**Find the UI input** (around line 50):
```r
numericInput("power_n", "Available Sample Size:",
             value = 230,  # <-- Change this to 300
             min = 1, step = 1)
```

**Also update the Reset button** (search for `observeEvent(input$reset_power_single`):
```r
observeEvent(input$reset_power_single, {
    updateNumericInput(session, "power_n", value = 300)  # <-- Change here too
})
```

**Test your change:**
1. Save `app.R`
2. Refresh the browser (or restart the app)
3. Navigate to "Power (Single)" tab
4. Default should now be 300
5. Click "Reset" - should return to 300

Congratulations! You've completed your first development session.

---

## Tutorial 2: Understanding Reactive Programming in This App

This tutorial explains how reactivity works in this specific application.

### The Problem: Uncontrolled Reactivity

Standard Shiny apps recalculate outputs whenever inputs change. For power calculations with plots, this would mean:
- User types "1" → calculation fires
- User types "2" → calculation fires again
- User types "0" → calculation fires with "120" (half-typed)
- Confusing user experience

### The Solution: Controlled Reactivity with Flags

This app uses a **reactive flag pattern**:

```r
# Create reactive values object (appears early in server function)
v <- reactiveValues(doAnalysis = FALSE)

# Button sets flag to TRUE
observeEvent(input$go, {
    v$doAnalysis <- input$go
})

# Outputs check flag before rendering
output$result_text <- renderText({
    if (v$doAnalysis == FALSE) return()  # Early return
    isolate({ ... })  # Calculations in isolation
})
```

### How It Works Step-by-Step

1. **Initial state:** `v$doAnalysis = FALSE`
2. **User changes inputs:** Flag remains FALSE, outputs don't recalculate
3. **User clicks Calculate:** `observeEvent` fires, sets `v$doAnalysis = TRUE`
4. **Outputs detect change:** `v$doAnalysis` changed, so `renderText` fires
5. **Inside `isolate()`:** Inputs are read in isolation (no dependencies created)

### Why `isolate()` Is Critical

Without `isolate()`, this would happen:
```r
output$result_text <- renderText({
    if (v$doAnalysis == FALSE) return()
    # Reading input$power_n creates a reactive dependency
    n <- input$power_n
    # Now changing input$power_n triggers recalculation (defeats purpose!)
})
```

With `isolate()`:
```r
output$result_text <- renderText({
    if (v$doAnalysis == FALSE) return()
    isolate({
        # Reading inputs inside isolate() doesn't create dependencies
        n <- input$power_n
        # Changing input$power_n does NOT trigger recalculation
    })
})
```

### When Results Hide on Tab Switching

You'll see this pattern:
```r
observeEvent(input$tabs, {
    if (input$tabs == "power_single") {
        v$doAnalysis <- FALSE  # Reset flag
    }
})
```

This hides stale results when users switch tabs.

### Practice: Add Reactive Logging

To visualize the reactive graph:

```r
# Add this to the top of app.R (before ui definition)
options(shiny.reactlog = TRUE)

# Run the app, then press Ctrl+F3 in your browser
# You'll see a visual graph of all reactive dependencies
```

This shows exactly when each reactive expression fires.

---

## Tutorial 3: Adding Your First Test

This tutorial shows how to add a test for a helper function.

### Step 1: Understand Existing Tests

Open `tests/testthat/test-power-analysis.R` (around line 10):

```r
test_that("calc_effect_measures returns correct values", {
  result <- calc_effect_measures(0.15, 0.10)

  expect_equal(round(result$RR, 3), 1.500)
  expect_equal(round(result$OR, 3), 1.591)
  expect_equal(round(result$RD, 3), 0.050)
})
```

This tests the `calc_effect_measures()` helper function.

### Step 2: Find the Helper Function

In `app.R`, search for `calc_effect_measures <- function(p1, p2) {` (around line 338):

```r
calc_effect_measures <- function(p1, p2) {
  RR <- ifelse(p2 == 0, NA, p1 / p2)
  OR <- ifelse(p2 == 0 || p2 == 1, NA, (p1 / (1 - p1)) / (p2 / (1 - p2)))
  RD <- p1 - p2
  return(list(RR = RR, OR = OR, RD = RD))
}
```

### Step 3: Write a New Test for Edge Cases

Add this test to `test-power-analysis.R`:

```r
test_that("calc_effect_measures handles p2=0 edge case", {
  result <- calc_effect_measures(0.15, 0)

  # RR should be NA (division by zero)
  expect_true(is.na(result$RR))

  # OR should be NA (division by zero)
  expect_true(is.na(result$OR))

  # RD should still calculate
  expect_equal(result$RD, 0.15)
})
```

### Step 4: Run the Test

```r
# In R console
testthat::test_file("tests/testthat/test-power-analysis.R")
```

You should see:
```
✓ | F W S  OK | Context
✓ |        12 | power-analysis

══ Results ════════════════════════
Duration: 0.5 s

[ FAIL 0 | WARN 0 | SKIP 0 | PASS 12 ]
```

### Step 5: Run a Specific Test

```r
testthat::test_file(
  "tests/testthat/test-power-analysis.R",
  filter = "calc_effect_measures"
)
```

This runs only tests matching "calc_effect_measures" in their description.

### Why Focus on Helper Functions?

The statistical packages (`pwr`, `powerSurvEpi`, `epiR`) are already well-tested. Focus testing on:
- Helper function correctness
- Edge case handling (0%, 100%, NA values)
- Input validation logic
- UI/server integration (use `testServer()`)

---

# How-To Guides

*Task-oriented: Directions for accomplishing specific goals*

## Development Workflow

### How to Run the Application Locally

**Using R directly:**

```r
# Navigate to project directory in R
shiny::runApp("app.R")

# Specify custom port
shiny::runApp("app.R", port = 3838)

# Specify host (for external access)
shiny::runApp("app.R", host = "0.0.0.0", port = 3838)
```

The app will display the URL (e.g., `http://localhost:4567`). Port is randomly assigned unless specified.

**Using Docker:**

```bash
# Build and run with docker-compose
docker-compose up

# Access at http://localhost:3838

# Rebuild after code changes
docker-compose up --build

# Build without cache (if having issues)
docker build --no-cache -t power-analysis-tool .
```

### How to Run Tests

**Run all tests:**
```r
testthat::test_file("tests/testthat/test-power-analysis.R")
```

**Run specific test:**
```r
testthat::test_file(
  "tests/testthat/test-power-analysis.R",
  filter = "calc_effect_measures"
)
```

**Tests cover:**
- Helper function correctness
- Server logic with `testServer()`
- Statistical calculation accuracy
- Edge cases (rare events, division by zero)

### How to Manage Packages with renv

**Daily workflow:**

```r
# First time: Install exact versions from lockfile
renv::restore()

# After installing new packages
install.packages("new_package")
renv::snapshot()  # Updates renv.lock

# Check if packages are in sync
renv::status()

# Update packages and lockfile
renv::update()
renv::snapshot()
```

**Troubleshooting:**

```r
# Clean and reinstall everything
renv::restore(clean = TRUE)

# Force snapshot even if status is OK
renv::snapshot(force = TRUE)

# Deactivate renv (restore global library)
renv::deactivate()

# Reactivate
renv::activate()
```

**How renv works:**
- Project isolation: Each project has its own library in `renv/library/`
- Global cache: Packages cached in `~/.cache/R/renv/` and linked (saves disk space)
- Reproducibility: `renv.lock` captures exact versions
- Auto-activation: `.Rprofile` activates renv on project start

---

## Adding Features

### How to Add a New Analysis Type

To add a completely new analysis type (e.g., "ANOVA"):

**1. Create new UI tab in `tabsetPanel()`:**

```r
tabPanel("Power (ANOVA)",
  value = "power_anova",
  h4("Calculate Power for ANOVA"),

  # Inputs
  numericInput("anova_n", "Sample Size per Group:", value = 30),
  numericInput("anova_groups", "Number of Groups:", value = 3),
  numericInput("anova_effect", "Effect Size (f):", value = 0.25),

  # Action buttons
  fluidRow(
    column(6, actionButton("go_anova", "Calculate", class = "btn-primary")),
    column(6, actionButton("reset_anova", "Reset", class = "btn-secondary"))
  ),

  # Outputs
  hr(),
  htmlOutput("anova_result_text"),
  plotOutput("anova_power_plot")
)
```

**2. Add validation logic in server section:**

```r
# Inside the server function
observeEvent(input$go_anova, {
  validate(
    need(input$anova_n > 0, "Sample size must be positive"),
    need(input$anova_groups >= 2, "Need at least 2 groups"),
    need(input$anova_effect > 0, "Effect size must be positive")
  )
  v$doAnalysis <- input$go_anova
})
```

**3. Add output renderers using delayed evaluation pattern:**

```r
output$anova_result_text <- renderText({
  if (v$doAnalysis == FALSE) return()

  isolate({
    # Perform calculation
    library(pwr)
    result <- pwr.anova.test(
      k = input$anova_groups,
      n = input$anova_n,
      f = input$anova_effect,
      sig.level = 0.05
    )

    # Format output
    sprintf("<b>Statistical Power:</b> %.1f%%", result$power * 100)
  })
})
```

**4. Create CSV export handler:**

```r
output$download_csv_anova <- downloadHandler(
  filename = function() {
    paste0("power_anova_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
  },
  content = function(file) {
    withProgress(message = "Generating CSV", value = 0, {
      incProgress(0.3, detail = "Preparing data")

      data <- data.frame(
        Analysis = "ANOVA Power",
        SampleSize = input$anova_n,
        Groups = input$anova_groups,
        EffectSize = input$anova_effect,
        Power = result$power
      )

      incProgress(0.7, detail = "Writing file")
      write.csv(data, file, row.names = FALSE)
    })
  }
)
```

**5. Add Example and Reset buttons:**

```r
# Example button
observeEvent(input$example_anova, {
  updateNumericInput(session, "anova_n", value = 30)
  updateNumericInput(session, "anova_groups", value = 4)
  updateNumericInput(session, "anova_effect", value = 0.35)
  showNotification("Loaded ANOVA example", type = "info")
})

# Reset button
observeEvent(input$reset_anova, {
  updateNumericInput(session, "anova_n", value = 30)
  updateNumericInput(session, "anova_groups", value = 3)
  updateNumericInput(session, "anova_effect", value = 0.25)
  v$doAnalysis <- FALSE
})
```

**6. Add tab switching logic to hide stale results:**

```r
observeEvent(input$tabs, {
  if (input$tabs == "power_anova") {
    v$doAnalysis <- FALSE
  }
})
```

### How to Change Default Values

Default values appear in two places and must be updated in both.

**UI `numericInput()`:**
```r
numericInput("power_n", "Available Sample Size:",
             value = 230,  # <-- Change this
             min = 1, step = 1)
```

**Reset button observer:**
```r
observeEvent(input$reset_power_single, {
  updateNumericInput(session, "power_n", value = 230)  # <-- Change this too
})
```

### How to Add New Example Scenarios

Add a new example button and observer:

```r
# In UI (add button)
actionButton("example_high_power", "High Power Example", class = "btn-info btn-sm")

# In server (add observer)
observeEvent(input$example_high_power, {
  updateNumericInput(session, "power_n", value = 1000)
  updateNumericInput(session, "power_p", value = 100)
  updateSliderInput(session, "power_alpha", value = 0.01)
  showNotification("Loaded high power example (99%+ power)", type = "info")
})
```

### How to Modify Power Curve Appearance

Power curves use base R plotting. Customize with standard `plot()` parameters:

```r
output$power_plot <- renderPlot({
  if (v$doAnalysis == FALSE) return()

  isolate({
    # Generate power sequence (keep to 50-100 points for responsiveness)
    n_seq <- seq(50, n_max, length.out = 100)
    power_seq <- sapply(n_seq, function(n) {
      pwr.p.test(h = effect_size, n = n, sig.level = alpha)$power
    })

    # Customize plot appearance
    plot(n_seq, power_seq,
         type = "l",           # Line plot
         col = "steelblue",    # Line color
         lwd = 3,              # Line width (thicker)
         xlab = "Sample Size",
         ylab = "Statistical Power",
         main = "Power Curve Analysis",
         cex.lab = 1.2,        # Axis label size
         cex.main = 1.3,       # Title size
         las = 1)              # Horizontal axis labels

    # Add reference lines
    abline(h = 0.8, col = "darkgreen", lty = 2, lwd = 2)  # 80% power
    abline(h = 0.9, col = "darkred", lty = 2, lwd = 2)    # 90% power

    # Add legend
    legend("bottomright",
           legend = c("Power curve", "80% power", "90% power"),
           col = c("steelblue", "darkgreen", "darkred"),
           lty = c(1, 2, 2),
           lwd = c(3, 2, 2))
  })
})
```

### How to Adjust Input Ranges

Modify `min`, `max`, `step` parameters in UI inputs:

```r
# Numeric input
numericInput("power_n", "Available Sample Size:",
            value = 230,
            min = 10,      # Minimum value
            max = 100000,  # Maximum value
            step = 10)     # Increment

# Slider input
sliderInput("power_alpha", "Significance Level (α):",
            min = 0.001,   # Minimum
            max = 0.10,    # Maximum
            value = 0.05,  # Default
            step = 0.001)  # Increment
```

---

## Deployment

### How to Build Docker Images

**Basic build:**
```bash
docker build -t power-analysis-tool .
```

**Build with no cache (troubleshooting):**
```bash
docker build --no-cache -t power-analysis-tool .
```

**Build with docker-compose:**
```bash
docker-compose build
```

**Rebuild times:**
| Change Type | Rebuilt Layers | Typical Time |
|-------------|----------------|--------------|
| Edit `app.R` | Last layer only | ~5 seconds |
| Add package to `renv.lock` | Package + app layers | ~2-5 minutes |
| Update system dependencies | Everything | ~10-15 minutes |

**How it works:**
The Dockerfile uses optimized layer caching:
1. System dependencies (rarely changes)
2. renv installation (rarely changes)
3. renv.lock + restore (changes when dependencies update) ← Cached layer
4. Application code (changes frequently) ← Fast rebuilds

### How to Deploy to Production

**Using Docker on a server:**

```bash
# On your server
git clone <repo-url>
cd power-analysis-tool

# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

**Using Shiny Server (without Docker):**

```bash
# Install Shiny Server (Ubuntu/Debian)
sudo apt-get install gdebi-core
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.20.1002-amd64.deb
sudo gdebi shiny-server-1.5.20.1002-amd64.deb

# Copy app to Shiny Server directory
sudo cp -R /path/to/power-analysis-tool /srv/shiny-server/

# Access at http://your-server-ip:3838/power-analysis-tool/
```

**Port configuration:**
- Local R: Random port (shown in console)
- Docker: Port 3838 (mapped in docker-compose.yml)
- Production: Use reverse proxy (nginx/Caddy) for HTTPS

### How to Configure Environment Variables

**Optional configurations:**

```bash
# In docker-compose.yml or as environment variables

# Increase Shiny app timeout (seconds)
SHINY_APP_TIMEOUT=60

# Enable detailed logging
R_LOG_LEVEL=DEBUG

# Custom renv cache location
RENV_PATHS_CACHE=/custom/cache/path
```

The application is self-contained and requires no environment variables for basic operation.

---

## Testing & Quality

### How to Run Code Quality Checks

This project uses pre-commit hooks for code quality:

```bash
# Run all quality checks manually
pre-commit run --all-files

# Run specific hook
pre-commit run lintr --all-files
```

Quality checks include:
- **lintr**: R code style and syntax
- **trailing-whitespace**: Remove trailing spaces
- **end-of-file-fixer**: Ensure files end with newline
- **check-yaml**: Validate YAML syntax

### How to Test Edge Cases Manually

**Manual testing checklist:**

1. **All seven tabs** - Ensure Calculate button works
2. **Input validation** - Test boundary values:
   - Sample size = 0, -1, 1
   - Event rates = 0%, 100%, >100%
   - Identical group proportions (p1 = p2)
   - Hazard ratio = 1.0
3. **Example buttons** - Verify pre-filled values are realistic
4. **Reset buttons** - Confirm defaults are restored
5. **CSV/PDF export** - Check file generation and content
6. **Scenario comparison** - Save multiple scenarios, export comparison
7. **Tab switching** - Verify results hide when switching tabs
8. **Power curves** - Check plot displays correctly
9. **Mobile responsiveness** - Test on different screen sizes

**Common edge cases to test:**

- Event rates of 0% or 100% → May cause mathematical errors
- Identical group proportions (p1 = p2) → No effect to detect
- Hazard ratio of 1.0 → Null effect in survival analysis
- Very large sample sizes (>100,000) → May cause slow rendering
- Discontinuation rate = 100% → Results in zero effective sample size

---

# Reference

*Information-oriented: Technical specifications and API documentation*

## Project Overview

**Application Type:** R Shiny web application for statistical power analysis

**Target Users:** Pharmaceutical epidemiologists and non-statisticians conducting RWE research

**Analysis Types Supported:**
1. Single proportion (Rule of Three)
2. Two-group comparisons
3. Survival analysis (Cox regression)
4. Matched case-control studies
5. Continuous outcomes (t-tests)
6. Non-inferiority testing

**Technology Stack:**
- R 4.4.0
- Shiny with bslib (Bootstrap 5)
- Docker + docker-compose
- renv for package management

---

## File Structure Reference

```
power-analysis-tool/
├── app.R                          # Main Shiny application (~1,815 lines)
├── analysis-report.Rmd            # R Markdown template for PDF export
├── Dockerfile                     # Container configuration (R 4.4.0)
├── docker-compose.yml             # Local development setup (port 3838)
├── README.md                      # User documentation
├── CLAUDE.md                      # This file (developer documentation)
├── TIER3_ENHANCEMENTS.md          # Version 4.0 feature log
├── TIER4_ENHANCEMENTS.md          # Version 5.0 feature log
├── tests/                         # Test suite
│   ├── testthat.R                 # Test runner configuration
│   └── testthat/
│       └── test-power-analysis.R  # Main test file (~200 lines)
├── renv/                          # Package management
│   ├── renv.lock                  # Package versions (commit to Git)
│   ├── activate.R                 # Activation script (commit to Git)
│   ├── settings.json              # renv configuration (commit to Git)
│   └── library/                   # Installed packages (DO NOT commit)
├── .Rprofile                      # Auto-loads renv on project start
├── .pre-commit-config.yaml        # Code quality hooks
├── .lintr                         # Lintr configuration
└── .editorconfig                  # Editor configuration
```

---

## Application Architecture Reference

### Monolithic Structure

The entire application is in `app.R` (~1,815 lines):

- **Lines 1-13:** Package loading and reactive log setup
- **Lines 14-435:** UI definition (Bootstrap 5 sidebar layout)
- **Lines 435-1815+:** Server logic (reactive programming)

### UI Organization

```r
ui <- fluidPage(
  theme = bs_theme(version = 5, bootswatch = "flatly"),

  titlePanel("Power & Sample Size Calculator"),

  sidebarLayout(
    sidebarPanel(
      tabsetPanel(id = "tabs",
        # 9 total tabs:
        tabPanel("Power (Single)", value = "power_single", ...),
        tabPanel("Sample Size (Single)", value = "ss_single", ...),
        tabPanel("Power (Two-Group)", value = "twogrp_pow", ...),
        tabPanel("Sample Size (Two-Group)", value = "twogrp_ss", ...),
        tabPanel("Power (Survival)", value = "surv_pow", ...),
        tabPanel("Sample Size (Survival)", value = "surv_ss", ...),
        tabPanel("Sample Size (Matched)", value = "matched_ss", ...),
        tabPanel("Power (Continuous)", value = "cont_pow", ...),
        tabPanel("Non-Inferiority", value = "noninf_ss", ...)
      )
    ),

    mainPanel(
      # Outputs rendered based on active tab
    )
  )
)
```

### Server Organization

```r
server <- function(input, output, session) {
  # Reactive values for state management
  v <- reactiveValues(
    doAnalysis = FALSE,
    scenarios = data.frame()
  )

  # Calculate button observers (one per tab)
  observeEvent(input$go, { v$doAnalysis <- input$go })

  # Output renderers (follow delayed evaluation pattern)
  output$result_text <- renderText({ ... })
  output$power_plot <- renderPlot({ ... })

  # Download handlers
  output$download_csv <- downloadHandler(...)
  output$download_pdf <- downloadHandler(...)

  # Tab switching logic
  observeEvent(input$tabs, { ... })
}

shinyApp(ui = ui, server = server)
```

---

## Input Naming Conventions

All inputs follow the pattern: `{tab_identifier}_{parameter}`

**Examples:**
- `power_n` - Sample size in Power (Single) tab
- `twogrp_pow_n1` - Sample size group 1 in Two-Group Power tab
- `ss_power` - Target power in Sample Size (Single) tab
- `surv_pow_hr` - Hazard ratio in Survival Power tab
- `matched_ss_phi` - Correlation in Matched Case-Control tab
- `cont_pow_d` - Cohen's d in Continuous Power tab
- `noninf_ss_margin` - Non-inferiority margin

---

## Output Component Reference

Each analysis tab produces multiple outputs:

### Standard Outputs (All Tabs)

1. **`output$result_text`** - Narrative description (protocol-ready text)
   - Type: `renderText()` or `renderUI()`
   - Format: HTML with `<b>` tags for emphasis
   - Location: Main panel

2. **`output$power_plot`** - Power curve visualization
   - Type: `renderPlot()`
   - Format: Base R graphics
   - Cached: Yes (using `bindCache()`)

### Tab-Specific Outputs

**Single Proportion tabs only:**
- `output$result_table` - Confidence interval table
  - Type: `renderTable()`
  - Format: Data frame with CI methods

**Two-Group & Survival tabs:**
- `output$effect_measures` - RR, OR, RD calculations
  - Type: `renderText()`
  - Format: HTML formatted list

---

## Helper Functions API

### `calc_effect_measures(p1, p2)`

Calculates effect measures from two proportions with safe division-by-zero handling.

**Location:** `app.R` lines 338-354

**Parameters:**
- `p1` (numeric): Proportion in group 1 (exposed/treatment)
- `p2` (numeric): Proportion in group 2 (unexposed/control)

**Returns:** List with three elements:
- `RR` (numeric or NA): Relative Risk = p1/p2
- `OR` (numeric or NA): Odds Ratio = (p1/(1-p1)) / (p2/(1-p2))
- `RD` (numeric): Risk Difference = p1 - p2

**Edge case handling:**
- If `p2 = 0`: RR and OR return NA (division by zero)
- If `p2 = 1`: OR returns NA (division by zero in denominator)
- RD always calculates (simple subtraction)

**Example:**
```r
result <- calc_effect_measures(0.15, 0.10)
# result$RR = 1.5 (50% increased risk)
# result$OR = 1.591
# result$RD = 0.05 (5 percentage point increase)
```

### `solve_n1_for_ratio(p1, p2, ratio, power, alpha, sided)`

Root-finding algorithm for calculating sample size with unequal allocation ratios.

**Location:** `app.R` lines 357-370

**Parameters:**
- `p1` (numeric): Proportion in group 1
- `p2` (numeric): Proportion in group 2
- `ratio` (numeric): Allocation ratio (n2/n1)
- `power` (numeric): Target power (0-1)
- `alpha` (numeric): Significance level (0-1)
- `sided` (string): "two.sided" or "one.sided"

**Returns:** Numeric value for n1

**Method:** Uses `uniroot()` to solve for n1 where calculated power equals target power

**Example:**
```r
n1 <- solve_n1_for_ratio(
  p1 = 0.15,
  p2 = 0.10,
  ratio = 2,    # 2:1 allocation
  power = 0.80,
  alpha = 0.05,
  sided = "two.sided"
)
# Returns n1, then n2 = ratio * n1
```

---

## Statistical Methods Reference

### Package Functions Used

| R Package | Function | Purpose | Analysis Type |
|-----------|----------|---------|---------------|
| `pwr` | `pwr.p.test()` | Single proportion power/sample size | Single proportion |
| `pwr` | `pwr.2p.test()` | Two proportions (equal n) | Two-group comparisons |
| `pwr` | `pwr.2p2n.test()` | Two proportions (unequal n) | Two-group comparisons |
| `pwr` | `ES.h()` | Cohen's h effect size | Proportion tests |
| `pwr` | `pwr.t2n.test()` | Two-sample t-test (unequal n) | Continuous outcomes |
| `powerSurvEpi` | `powerEpi()` | Cox regression power | Survival analysis |
| `powerSurvEpi` | `ssizeEpi()` | Cox regression sample size | Survival analysis |
| `epiR` | `epi.sscc()` | Matched case-control | Matched designs |
| `binom` | `binom.confint()` | Exact confidence intervals | Single proportion |

### Statistical Methods by Analysis Type

**Single Proportion:**
- Method: Binomial test with Cohen's h effect size
- Null hypothesis: p = p0 (specified null proportion)
- Test statistic: Z-test based on arcsin transformation
- Reference: Cohen (1988), Hanley & Lippman-Hand (1983)

**Two-Group Proportions:**
- Method: Two-proportion Z-test
- Null hypothesis: p1 = p2
- Effect sizes: RR, OR, RD
- Sidedness: Two-sided (default)

**Survival Analysis:**
- Method: Cox proportional hazards (Schoenfeld 1983)
- Assumptions: Proportional hazards, exponential survival
- Key parameter: Hazard ratio (HR)
- Accounts for: Accrual period, follow-up period

**Matched Case-Control:**
- Method: McNemar-based with correlation
- Accounts for: Matching correlation (φ)
- Key parameter: Odds ratio

**Continuous Outcomes:**
- Method: Two-sample t-test (unequal variances)
- Effect size: Cohen's d (standardized mean difference)
- Assumptions: Normality, independence

**Non-Inferiority:**
- Method: One-sided two-proportion test
- Key parameter: Non-inferiority margin (Δ)
- Null hypothesis: p_test - p_ref ≥ Δ
- Standard: α = 0.025 (one-sided)

---

## Reactive Programming Patterns

### Delayed Evaluation Pattern

**Purpose:** Only calculate results when Calculate button is clicked

**Implementation:**
```r
# 1. Create reactive flag
v <- reactiveValues(doAnalysis = FALSE)

# 2. Button sets flag
observeEvent(input$go, { v$doAnalysis <- input$go })

# 3. Outputs check flag
output$result_text <- renderText({
  if (v$doAnalysis == FALSE) return()  # Early return
  isolate({
    # Calculations here
    # Reading inputs inside isolate() prevents reactive dependencies
  })
})
```

**Why this pattern:**
- Prevents calculations while user is typing
- Gives user explicit control
- Improves performance (no unnecessary recalculations)

### Performance Optimizations

1. **Reactive Logging** - Enabled with `options(shiny.reactlog = TRUE)`
   - Press Ctrl+F3 in browser to visualize reactive graph

2. **Cached Plots** - Power plots use `bindCache()`
   ```r
   output$power_plot <- renderPlot({ ... }) %>%
     bindCache(input$power_n, input$power_p, input$power_alpha)
   ```

3. **Debounced Live Preview** - Shows preview with 1-second delay
   ```r
   preview_debounced <- debounce(reactive({ input$power_n }), 1000)
   ```

4. **`req()` Validation** - Silent validation without verbose error messages
   ```r
   output$result_text <- renderText({
     req(v$doAnalysis == TRUE, cancelOutput = TRUE)
     # Continues only if condition is TRUE
   })
   ```

5. **Progress Indicators** - All download handlers show progress
   ```r
   downloadHandler(
     content = function(file) {
       withProgress(message = "Generating CSV", value = 0, {
         incProgress(0.3, detail = "Preparing data")
         # ... work ...
         incProgress(0.7, detail = "Writing file")
       })
     }
   )
   ```

---

## Export Mechanisms Reference

### CSV Export

**File naming:** `power_analysis_{timestamp}.csv`

**Structure (varies by tab):**
```csv
Analysis,Parameter,Value
"Power (Single)","Sample Size",230
"Power (Single)","Event Frequency (1 in X)",200
"Power (Single)","Power",91.8%
```

**Implementation:**
```r
output$download_csv <- downloadHandler(
  filename = function() {
    paste0("power_analysis_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".csv")
  },
  content = function(file) {
    withProgress(message = "Generating CSV", value = 0, {
      # Build data frame based on active tab
      data <- data.frame(...)
      write.csv(data, file, row.names = FALSE)
    })
  }
)
```

### PDF Export (Single Proportion Only)

**Template:** `analysis-report.Rmd` (R Markdown)

**LaTeX packages required:**
- threeparttable
- float
- booktabs

**Implementation:**
```r
output$download_pdf <- downloadHandler(
  filename = function() {
    paste0("power_report_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".pdf")
  },
  content = function(file) {
    progress <- Progress$new()
    progress$set(message = "Generating PDF", value = 0)

    # Render R Markdown
    rmarkdown::render(
      "analysis-report.Rmd",
      output_file = file,
      params = list(
        n = input$power_n,
        p = input$power_p,
        power = calculated_power
      )
    )

    progress$close()
  }
)
```

### Scenario Comparison CSV

**Purpose:** Compare multiple saved scenarios side-by-side

**Structure:** Each row is a saved scenario, columns are parameters

**Implementation:** Exports `v$scenarios` data frame directly

---

## Docker Configuration Reference

### Dockerfile Layer Structure

```dockerfile
# Layer 1: System dependencies (rarely changes)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev

# Layer 2: Install renv (rarely changes)
RUN R -e "install.packages('renv')"

# Layer 3: Restore packages (changes when renv.lock changes)
COPY renv.lock renv.lock
RUN R -e "renv::restore()"

# Layer 4: Copy application code (changes frequently)
COPY app.R /srv/shiny-server/
```

**Caching behavior:**
- Changing `app.R` → Only rebuilds layer 4 (~5 seconds)
- Adding package → Rebuilds layers 3-4 (~2-5 minutes)
- Changing system deps → Rebuilds everything (~10-15 minutes)

### docker-compose.yml Configuration

```yaml
version: '3.8'
services:
  shiny:
    build: .
    ports:
      - "3838:3838"
    volumes:
      - ./app.R:/srv/shiny-server/app.R
      - ./analysis-report.Rmd:/srv/shiny-server/analysis-report.Rmd
```

**Port mapping:** Host 3838 → Container 3838

---

## renv Configuration Reference

### Files to Commit to Git

✅ **Commit these:**
- `renv.lock` - Package versions (JSON)
- `renv/activate.R` - Activation script
- `renv/settings.json` - renv configuration
- `.Rprofile` - Auto-loads renv

❌ **Do NOT commit:**
- `renv/library/` - Installed packages (in `.gitignore`)
- `renv/staging/` - Temporary installation
- `renv/sandbox/` - Package build sandbox

### renv.lock Structure

```json
{
  "R": {
    "Version": "4.4.0",
    "Repositories": [...]
  },
  "Packages": {
    "shiny": {
      "Package": "shiny",
      "Version": "1.8.0",
      "Source": "Repository",
      "Repository": "CRAN"
    }
  }
}
```

### renv Settings

**Location:** `renv/settings.json`

```json
{
  "bioconductor.version": null,
  "external.libraries": [],
  "ignored.packages": [],
  "package.dependency.fields": ["Imports", "Depends", "LinkingTo"],
  "snapshot.type": "implicit",
  "use.cache": true,
  "vcs.ignore.library": true
}
```

---

## Dependencies Reference

### Required R Packages

```r
# Core Shiny
shiny          # 1.8.0+ - Web application framework
bslib          # Bootstrap 5 theming
shinyBS        # Tooltips and popovers

# Statistical Analysis
pwr            # Power analysis for proportions and t-tests
powerSurvEpi   # Survival analysis (Schoenfeld method)
epiR           # Matched case-control designs
binom          # Exact binomial confidence intervals

# Export & Reporting
kableExtra     # Table formatting (PDF export)
tinytex        # LaTeX support (PDF export)
rmarkdown      # PDF report rendering

# Package Management
renv           # Reproducible package management
```

### System Requirements

**R version:** ≥ 4.2.0 (recommended 4.4.0)

**LaTeX:** Installed via `tinytex::install_tinytex()` for PDF export

**Browser:** Modern browser with JavaScript enabled

**System libraries (for Docker):**
- libcurl4-openssl-dev
- libssl-dev
- libxml2-dev
- pandoc (for R Markdown)

---

# Explanation

*Understanding-oriented: Context and rationale for design decisions*

## Why Monolithic app.R Structure?

The entire application is in a single `app.R` file (~1,815 lines) rather than split into modular files.

### Historical Context

Early Shiny applications required separate `ui.R` and `server.R` files. In 2013, Shiny introduced the single-file `app.R` structure, which became the recommended approach for small-to-medium applications.

### Advantages of Monolithic Structure

1. **Simpler deployment** - Single file to copy, no module loading complexity
2. **Easier navigation** - All code in one place, searchable with Ctrl+F
3. **Reduced overhead** - No need to manage module namespaces for this scale
4. **Industry standard** - Common practice for Shiny apps <2,000 lines

### When to Split Into Modules

Consider modularization when:
- App exceeds **2,000 lines** (this app is 1,815 lines)
- Multiple developers working simultaneously (merge conflicts)
- Reusing components across multiple apps
- Need for independent testing of UI components

### Comparison to Other Frameworks

**Rhino framework** (for enterprise Shiny):
- Provides opinionated structure with separate directories
- Built-in testing infrastructure
- CI/CD templates
- Overkill for this application's current size

**Shiny Modules** (for component reuse):
- Useful when same component appears multiple times
- This app has 9 unique analysis tabs (little repetition)
- Each tab has different inputs/outputs (low reusability)

### The Tradeoff

Monolithic structure trades **long-term maintainability** for **short-term simplicity**. For this pharmaceutical RWE tool with stable requirements, the simplicity wins. If the app grows to 15+ analysis types, modularization would become beneficial.

---

## Why Delayed Evaluation Pattern?

Results calculate only when the Calculate button is clicked, not reactively on input changes.

### The Problem with Pure Reactivity

Standard Shiny uses **reactive programming** where outputs automatically recalculate when inputs change. For this power analysis application, pure reactivity would cause:

**Poor user experience:**
1. User starts typing sample size "500"
2. After typing "5" → Calculation fires with n=5 (invalid)
3. After typing "50" → Calculation fires with n=50
4. After typing "500" → Calculation fires with n=500 (finally correct)

**Performance issues:**
- Power curves involve 100 calculations each
- Recalculating 3 times while typing is wasteful
- Multiplied across 9 tabs with multiple inputs

### The Solution: Controlled Reactivity

```r
v <- reactiveValues(doAnalysis = FALSE)

observeEvent(input$go, { v$doAnalysis <- input$go })

output$result_text <- renderText({
  if (v$doAnalysis == FALSE) return()
  isolate({
    # Calculations in isolation (no reactive dependencies)
  })
})
```

**How it works:**
- Inputs changing does NOT trigger recalculation
- Only the Calculate button click triggers recalculation
- `isolate()` reads inputs without creating reactive dependencies

### Alternative Approaches Considered

**Debouncing (waiting for typing to stop):**
- Still calculates while user is adjusting sliders
- No visual feedback that calculation will happen
- Less predictable behavior

**Validation-only reactivity:**
- Show real-time validation errors
- But don't calculate results
- This app uses a hybrid: debounced preview + button for full results

### When This Pattern is Appropriate

✅ **Good for:**
- Expensive calculations (power curves, simulations)
- Forms with multiple interdependent inputs
- "Submit" workflows (surveys, data entry)

❌ **Not appropriate for:**
- Filtering/searching (users expect immediate response)
- Simple calculations (addition, formatting)
- Data dashboards (real-time updates expected)

### Historical Note

This pattern was more common in early Shiny apps (2012-2015) when server resources were limited. Modern Shiny encourages reactive programming, but the pattern remains valuable for specific use cases like this one.

---

## Why Focus Testing on Helper Functions?

The test suite primarily tests helper functions like `calc_effect_measures()` rather than the entire UI/server integration.

### Philosophy: Test What You Own

This application **delegates** statistical calculations to well-tested packages:
- `pwr` package: Tested by R community since 2013
- `powerSurvEpi`: Published package with validation studies
- `epiR`: Epidemiology package with academic backing

**What we own:**
- Helper functions for effect measures
- Input validation logic
- UI/server integration (button clicks, reactive flow)
- Edge case handling (division by zero, NA values)

**What we don't own:**
- Statistical formulas (trust the packages)
- Plot rendering (base R graphics)
- Shiny framework itself

### Practical Constraints

**UI testing is brittle:**
```r
# This test breaks if we change ANY UI element
test_that("Power tab displays correctly", {
  app <- shinyApp(ui = ui, server = server)
  # Simulating clicks, checking HTML output...
  # Breaks when we change button text, CSS classes, layout...
})
```

**Helper function testing is stable:**
```r
# This test is robust to UI changes
test_that("calc_effect_measures returns correct RR", {
  result <- calc_effect_measures(0.15, 0.10)
  expect_equal(round(result$RR, 3), 1.500)
})
```

### When to Add More Tests

**Add `testServer()` tests when:**
- Complex reactive logic (multiple interdependent reactives)
- State management bugs appear
- Button interactions become unreliable

**Add end-to-end tests when:**
- Deploying to production with SLA requirements
- Multiple developers causing regressions
- Regulatory validation required (FDA submission)

### The Pragmatic Approach

For a pharmaceutical **research tool** (not a medical device), focus on:
1. Correctness of calculations (helper functions)
2. Edge case handling (division by zero, NA, Inf)
3. Manual testing checklist (9 tabs × realistic scenarios)

For a **production medical device**, add:
1. Full UI/server integration tests
2. Cross-browser testing
3. Performance testing (stress testing with large n)
4. Regulatory validation (21 CFR Part 11)

---

## Effect Measure Edge Case Handling

Calculating Relative Risk (RR) and Odds Ratio (OR) can produce mathematical errors when denominators are zero.

### The Mathematical Problem

**Relative Risk:** RR = p1 / p2
- If p2 = 0 → Division by zero → `Inf` in R

**Odds Ratio:** OR = [p1/(1-p1)] / [p2/(1-p2)]
- If p2 = 0 → Division by zero → `Inf` in R
- If p2 = 1 → (1-p2) = 0 → Division by zero → `Inf` in R

### Real-World Scenarios

**Scenario 1: Zero events in control group**
- Treatment group: 15% adverse event rate
- Control group: 0% adverse event rate
- RR = 0.15 / 0 = `Inf` (undefined)

**Scenario 2: Perfect event rate in control**
- Treatment group: 95% response rate
- Control group: 100% response rate
- OR calculation involves (1-1) = 0 in denominator

### Implementation Strategy

**Option 1: Return `Inf` (R default behavior)**
```r
RR <- p1 / p2  # Returns Inf if p2 = 0
```
- **Pros:** Mathematically "correct" (limit as p2 → 0)
- **Cons:** Confusing for users, breaks downstream calculations

**Option 2: Return NA (missing value)**
```r
RR <- ifelse(p2 == 0, NA, p1 / p2)
```
- **Pros:** Clear signal that calculation is impossible
- **Cons:** NA can propagate and hide real data

**Option 3: Add continuity correction**
```r
RR <- (p1 + 0.5) / (p2 + 0.5)
```
- **Pros:** Always computable
- **Cons:** Arbitrary, not clinically interpretable

**This app chooses Option 2 (NA):**
```r
calc_effect_measures <- function(p1, p2) {
  RR <- ifelse(p2 == 0, NA, p1 / p2)
  OR <- ifelse(p2 == 0 || p2 == 1, NA, (p1/(1-p1)) / (p2/(1-p2)))
  RD <- p1 - p2  # Always computable
  return(list(RR = RR, OR = OR, RD = RD))
}
```

### Why NA is the Right Choice Here

**Philosophical reason:**
- RR and OR are **undefined** when p2 = 0 (not "infinite")
- In clinical trials, 0 events is evidence of absence, not absence of evidence
- NA signals to users: "This measure doesn't apply in this scenario"

**Practical reason:**
- Users see "Not calculable" message instead of "Inf"
- Risk Difference (RD) still displays, providing interpretable effect measure
- Prevents downstream errors in CSV export

### Alternative Interpretation

Some epidemiologists argue for `Inf`:
- "If control has 0 events and treatment has any events, the risk is infinitely higher"
- Used in meta-analysis with continuity corrections

This app prioritizes **user clarity** over mathematical formalism.

---

## Performance Optimization Philosophy

The application includes several modern Shiny performance features. Here's why and when to use each.

### Reactive Logging - Debugging Tool

```r
options(shiny.reactlog = TRUE)
```

**Purpose:** Visualize the reactive dependency graph

**When to use:**
- Debugging unexpected recalculations
- Understanding why outputs fire multiple times
- Optimizing reactive performance

**How it works:**
- Press Ctrl+F3 (Cmd+F3 on Mac) in browser
- Shows visual graph of all reactive expressions
- Highlights which reactives fired and in what order

**Why not always enabled:**
- Performance overhead (stores all reactive events)
- Security risk (exposes internal app structure)
- Enable during development, disable in production

### Cached Plots - Performance Optimization

```r
output$power_plot <- renderPlot({ ... }) %>%
  bindCache(input$power_n, input$power_p, input$power_alpha)
```

**Purpose:** Avoid recalculating identical plots

**How it works:**
- Caches plot based on input parameters
- If user returns to previous inputs → serves cached plot
- Dramatically faster for expensive plots

**When to use:**
- Expensive calculations (power curves with 100+ points)
- Plots that don't change often
- Users frequently switch between scenarios

**When NOT to use:**
- Real-time data (caching defeats purpose)
- Plots dependent on time or random values
- Simple plots (caching overhead exceeds calculation time)

### Debounced Live Preview - UX Enhancement

```r
preview_debounced <- debounce(reactive({ input$power_n }), 1000)
```

**Purpose:** Show preview while typing, wait for pause

**How it works:**
- User types → Timer starts
- If 1 second passes without new input → Preview displays
- If user keeps typing → Timer resets

**The UX trade-off:**
- **No debounce:** Flickering preview while typing (jarring)
- **Too long debounce (5s):** Feels unresponsive
- **1 second:** Sweet spot for most users

**This app's hybrid approach:**
- Debounced preview for quick feedback
- Calculate button for full results
- Preview disappears after Calculate (prevents confusion)

### `req()` Validation - Clean Error Handling

```r
output$result_text <- renderText({
  req(v$doAnalysis == TRUE, cancelOutput = TRUE)
  # Only executes if condition is TRUE
})
```

**Purpose:** Silent validation without error messages

**Comparison to `validate()`:**
```r
# Verbose approach (displays error message)
validate(need(v$doAnalysis == TRUE, "Click Calculate to see results"))

# Silent approach (just doesn't render)
req(v$doAnalysis == TRUE, cancelOutput = TRUE)
```

**When to use each:**
- `validate()`: User-facing validation (invalid inputs)
- `req()`: Control flow validation (internal state)

### Progress Indicators - User Feedback

```r
withProgress(message = "Generating CSV", value = 0, {
  incProgress(0.3, detail = "Preparing data")
  # ... work ...
  incProgress(0.7, detail = "Writing file")
})
```

**Purpose:** Prevent "is it frozen?" anxiety

**Psychological impact:**
- **No progress bar:** User unsure if app is working (abandons after 10s)
- **Indeterminate progress bar:** Better, but still anxious
- **Determinate progress bar with details:** Confident, patient

**Implementation cost vs. benefit:**
- Cost: ~5 lines of code per download handler
- Benefit: Dramatically improved perceived performance
- Even fake progress is better than no progress

**This app's approach:**
- All download handlers show progress
- CSV export: Shows preparation + writing steps
- PDF export: Shows R Markdown rendering progress
- Details explain what's happening (not just "Please wait...")

---

## Scenario Comparison Architecture

The scenario comparison feature allows users to save multiple analysis configurations and export them side-by-side.

### Why This Feature Exists

**User workflow in protocol development:**
1. Run power analysis with planned sample size
2. Realize sample size is too expensive
3. Run again with lower sample size (lower power)
4. Need to compare options for protocol committee

**Without scenario comparison:**
- Manual copy-paste into spreadsheet
- Easy to mix up numbers
- No audit trail

**With scenario comparison:**
- Click "Save Scenario" button
- Automatic timestamping
- Side-by-side export to CSV

### Data Structure

Scenarios stored in reactive data frame:
```r
v <- reactiveValues(
  scenarios = data.frame()  # Empty initially
)

# When user clicks "Save Scenario"
new_scenario <- data.frame(
  Timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  Analysis = "Power (Single)",
  SampleSize = input$power_n,
  Power = calculated_power
)

v$scenarios <- rbind(v$scenarios, new_scenario)
```

### Challenge: Different Tab Structures

Each analysis type has different parameters:
- Power (Single): n, p, α, power
- Two-Group: n1, n2, p1, p2, power
- Survival: n, HR, events, power

**Problem:** Can't combine into single data frame (different columns)

**Solution 1 (current):** Separate data frames per tab
```r
v$scenarios_power_single <- data.frame()
v$scenarios_twogroup <- data.frame()
```

**Solution 2 (future):** Wide format with NA for missing columns
```r
# Union of all columns
all_cols <- union(names(v$scenarios), names(new_data))
v$scenarios <- rbind(v$scenarios, new_data)
# Fill missing columns with NA automatically
```

### Why the Current Approach Works

**Advantages:**
- Simple implementation
- Clear separation by analysis type
- Easy to export per-tab

**Disadvantages:**
- Can't compare across analysis types
- Duplication of structure

**Design decision:**
- Users rarely compare different analysis types side-by-side
- More common: Compare different sample sizes for same analysis
- Current approach optimizes for common case

### Future Enhancement Possibility

If users request cross-analysis comparison:
```r
v$scenarios <- data.frame(
  Timestamp = ...,
  Analysis = "Power (Single)" or "Two-Group",
  # Universal columns
  Power = ...,
  # Analysis-specific columns (NA if not applicable)
  SampleSize_Single = ...,
  SampleSize_Group1 = ...,
  SampleSize_Group2 = ...
)
```

This would allow filtering/sorting across all analyses.

---

## Future Directions

### Migration to bs4Dash - When and Why

The application currently uses `bslib` (Bootstrap 5) with standard `fluidPage` layout. **bs4Dash** is already in the Dockerfile as a future option.

**Current UI approach:**
```r
fluidPage(
  sidebarLayout(
    sidebarPanel(tabsetPanel(...)),
    mainPanel(...)
  )
)
```

**bs4Dash approach:**
```r
dashboardPage(
  header = dashboardHeader(...),
  sidebar = dashboardSidebar(sidebarMenu(...)),
  body = dashboardBody(
    valueBox(value = "91.8%", subtitle = "Power", icon = icon("tachometer")),
    box(title = "Results", ...)
  )
)
```

### When to Migrate

**Migrate when:**
1. Preparing for regulatory submission (polished appearance)
2. Adding 3+ more analysis types (better menu organization)
3. Users request dashboard-style metrics (value boxes)
4. App exceeds 2,000 lines (modularization time anyway)

**Don't migrate if:**
1. App stays at current size (~1,815 lines)
2. Users satisfied with current appearance
3. Limited development time (migration takes 1-2 days)

### Why bs4Dash Fits This Domain

**Pharmaceutical industry expectations:**
- Polished, professional appearance (AdminLTE3 theme)
- Prominent metrics display (power, sample size as value boxes)
- Collapsible sections (help panels, methodology)
- Regulatory submission aesthetics (serious, not playful)

**bs4Dash strengths:**
- Enterprise-focused design
- `valueBox()` for highlighting key metrics
- Sidebar menu with icons (better than tabs for 9+ analyses)
- `freshTheme()` for branding (company colors)

### Migration Effort Estimate

**Low risk (1-2 days):**
- UI restructuring only (server logic unchanged)
- Keep all input IDs identical (no server changes needed)
- bs4Dash compatible with standard Shiny components
- Gradual migration possible (one tab at a time)

**Breakage points:**
- Some `bslib` theming won't transfer (custom CSS)
- Bootstrap 5 vs. Bootstrap 4 differences (minor)
- Need to redesign layouts (from sidebar to boxes)

---

### Rhino Framework - Enterprise Structure

**What is Rhino:**
- Opinionated framework for enterprise Shiny apps
- Enforces structure: `app/`, `tests/`, `config/`
- Built-in testing infrastructure (box modules + testthat)
- CI/CD templates (GitHub Actions)
- Sass for styling, lintr for code quality

**When to adopt Rhino:**
1. App exceeds **2,000 lines** (this app: 1,815 lines)
2. Multiple developers (merge conflicts in monolithic file)
3. Need CI/CD (automated testing, deployment)
4. Corporate environment (standardized structure)

**When NOT to adopt Rhino:**
1. Solo developer projects
2. App under 2,000 lines
3. Rapid prototyping (Rhino adds overhead)
4. Simple apps (structure overkill)

**This app's position:**
- Currently 1,815 lines (close to threshold)
- Solo/small team development
- Stable requirements (not rapid prototyping)
- **Verdict:** Monitor size, adopt Rhino if exceeds 2,500 lines

---

### Modularization - When to Split app.R

**Current structure:** Monolithic `app.R` (1,815 lines)

**Signs you need modules:**
1. **File exceeds 2,000 lines**
2. **Repeated UI components** (same inputs across tabs)
3. **Multiple developers** (merge conflicts)
4. **Reuse across apps** (analysis module in multiple projects)

**How to modularize this app:**

**Step 1: Extract helper functions**
```
R/
  calc_effect_measures.R
  solve_n1_for_ratio.R
  validate_inputs.R
```

**Step 2: Create Shiny modules for repeated patterns**
```
R/
  mod_power_single.R      # Single proportion module
  mod_power_twogroup.R    # Two-group module
  mod_export.R            # CSV/PDF export module
```

**Step 3: Split UI and server**
```
ui.R              # UI definition
server.R          # Server logic
global.R          # Shared setup (library loading)
```

**Effort estimate:** 2-3 days for full modularization

**Benefit:** Better organization, easier testing, reusability

**Cost:** More files to navigate, module namespace management

---

## Summary: When to Use Each Approach

| App Size (lines) | Structure | Testing | Framework |
|-----------------|-----------|---------|-----------|
| <500 | Monolithic app.R | Manual | Base Shiny |
| 500-2,000 | Monolithic app.R | Helper function tests | Base Shiny + bslib |
| 2,000-5,000 | Modular (ui.R/server.R) | `testServer()` | Consider bs4Dash |
| 5,000+ | Rhino framework | Full suite | Rhino + bs4Dash |

**This app:** Currently at 1,815 lines, using appropriate structure for its size.

---

## References

### Statistical Methods
- Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all right? Interpreting zero numerators. *JAMA*. 1983;249(13):1743-1745.
- Cohen J. *Statistical Power Analysis for the Behavioral Sciences*. 2nd ed. Routledge; 1988.
- Schoenfeld DA. Sample-size formula for the proportional-hazards regression model. *Biometrics*. 1983;39(2):499-503.

### Regulatory Guidance
- FDA. Considerations for the Use of Real-World Data and Real-World Evidence to Support Regulatory Decision-Making. Draft Guidance. 2024.
- EMA. Real World Evidence Framework. 2024.

### R Shiny Best Practices
- Wickham H. *Mastering Shiny*. O'Reilly Media; 2021.
- RStudio. Shiny Articles. https://shiny.rstudio.com/articles/
- Appsilon. Rhino Framework. https://appsilon.github.io/rhino/

### Documentation Framework
- Procida D. *Diátaxis Documentation Framework*. https://diataxis.fr/
