# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an R Shiny web application for statistical power analysis and sample size calculations in pharmaceutical real-world evidence (RWE) research. The application provides five analysis types: single proportion (Rule of Three), two-group comparisons, survival analysis (Cox regression), and matched case-control studies.

**Target users:** Pharmaceutical epidemiologists and non-statisticians conducting RWE research and protocol development.

## Development Commands

### Running the Application Locally

```r
# In R console:
shiny::runApp("app.R")
```

The app will start on `http://localhost:` with a randomly assigned port (displayed in console).

### Running Tests

```r
# Run all tests
testthat::test_file("tests/testthat/test-power-analysis.R")

# Run specific test
testthat::test_file("tests/testthat/test-power-analysis.R",
                    filter = "calc_effect_measures")
```

Tests cover:
- Helper function correctness (`calc_effect_measures`, `solve_n1_for_ratio`)
- Server logic with `testServer()` (button interactions, reactive values)
- Statistical calculation accuracy
- Edge cases (rare events, identical proportions, division by zero)

### Running with Docker

```bash
# Build and run
docker-compose up

# Access at http://localhost:3838

# Rebuild after changes
docker-compose up --build
```

### Package Management with renv

This project uses **renv** for reproducible package management - the R equivalent of Python's `uv`. All package dependencies are locked in `renv.lock`.

#### Daily Workflow

```r
# When you first clone the repository:
renv::restore()  # Installs exact package versions from renv.lock

# After installing new packages:
install.packages("new_package")
renv::snapshot()  # Updates renv.lock with new package

# Check if packages are in sync:
renv::status()

# Update packages and lockfile:
renv::update()
renv::snapshot()
```

#### How renv Works

1. **Project Isolation**: Each project has its own package library in `renv/library/`
2. **Global Cache**: Packages are cached in `~/.cache/R/renv/` and linked to projects (saves disk space)
3. **Reproducibility**: `renv.lock` captures exact package versions, sources, and dependencies
4. **Auto-Activation**: `.Rprofile` automatically activates renv when you open the project

#### renv Files (DO commit these to Git)

- `renv.lock` - JSON lockfile with all package versions
- `renv/activate.R` - Activation script
- `renv/settings.json` - Project-specific renv configuration
- `.Rprofile` - Auto-loads renv on project start

#### renv Files (DO NOT commit - in .gitignore)

- `renv/library/` - Installed packages (linked from global cache)
- `renv/staging/` - Temporary installation directory
- `renv/sandbox/` - Sandbox for package builds

#### Troubleshooting

```r
# Clean and reinstall everything:
renv::restore(clean = TRUE)

# Force snapshot even if status is OK:
renv::snapshot(force = TRUE)

# Deactivate renv (restore global library):
renv::deactivate()

# Reactivate:
renv::activate()
```

## Code Architecture

### Monolithic Shiny Application

The entire application is in `app.R` (~1,500 lines) with:
- **UI definition** (lines 14-435): Bootstrap 5 sidebar layout with tabset panels
- **Server logic** (lines 435-1500+): Reactive programming with delayed evaluation pattern

### Recent Performance Enhancements

The application includes several modern Shiny performance optimizations:

1. **Reactive Logging** - Enabled with `options(shiny.reactlog = TRUE)` for debugging
   - Press Ctrl+F3 (Cmd+F3 on Mac) in browser to visualize reactive graph
   - Helps identify performance bottlenecks and reactive dependencies

2. **Caching with `bindCache()`** - Power plot outputs are cached to avoid recalculation
   - Plots are cached based on input parameters
   - Dramatically improves performance when switching between tabs

3. **Debounced Live Preview** - Shows parameter preview with 1-second debounce
   - Users get feedback while typing without triggering expensive calculations
   - Preview disappears once Calculate is clicked

4. **req() Validation Pattern** - Cleaner input validation alongside traditional `validate()`
   - Example in `output$result_text` for Power (Single) tab
   - Uses `req(..., cancelOutput = TRUE)` to silently stop execution on invalid inputs

5. **Download Progress Indicators** - All download handlers now show progress feedback
   - **CSV Export**: Uses `withProgress()` with incremental updates during data preparation and file writing
   - **PDF Export**: Uses `Progress$new()` object with detailed status messages for R Markdown rendering
   - **Scenario Comparison**: Shows progress during multi-scenario CSV export
   - Provides professional user experience for long-running operations

### Key Architectural Pattern: Delayed Evaluation

Results are calculated **only when the Calculate button is clicked**, not on input changes:

```r
# Reactive flag controls visibility
v <- reactiveValues(doAnalysis = FALSE)

# Button sets flag
observeEvent(input$go, { v$doAnalysis <- input$go })

# Outputs check flag
output$result_text <- renderText({
    if (v$doAnalysis == FALSE) return()  # Don't render until Calculate clicked
    isolate({ ... })  # Breaks reactive dependencies
})
```

This prevents excessive recalculations and improves performance. When working with outputs, always check `v$doAnalysis` first.

### Tab Organization

Each analysis type is a separate `tabPanel()` with unique input IDs:

1. **Power (Single)** - Calculate power for single proportion
2. **Sample Size (Single)** - Calculate sample size for single proportion
3. **Power (Two-Group)** - Calculate power for two-group comparison
4. **Sample Size (Two-Group)** - Calculate sample size for two-group comparison
5. **Power (Survival)** - Calculate power for survival analysis (Cox)
6. **Sample Size (Survival)** - Calculate sample size for survival analysis
7. **Sample Size (Matched)** - Calculate sample size for matched case-control

Input naming convention: `{analysistype}_{parameter}` (e.g., `power_n`, `twogrp_pow_n1`, `ss_power`)

### Statistical Methods & R Packages

| Package | Purpose | Key Functions |
|---------|---------|---------------|
| `pwr` | Proportion power tests | `pwr.p.test()`, `pwr.2p.test()`, `pwr.2p2n.test()`, `ES.h()` |
| `powerSurvEpi` | Survival analysis | `powerEpi()`, `ssizeEpi()` (Schoenfeld 1983 method) |
| `epiR` | Matched case-control | `epi.sscc()` (accounts for matching correlation) |
| `binom` | Confidence intervals | `binom.confint()` (Clopper-Pearson exact method) |
| `bslib` + `shinyBS` | UI components | Bootstrap 5 theming, tooltips |

### Helper Functions

- **`calc_effect_measures(p1, p2)`** (lines 338-354): Calculates RR, OR, RD with safe division-by-zero handling
- **`solve_n1_for_ratio(p1, p2, ratio, power, alpha, sided)`** (lines 357-370): Root-finding algorithm for unequal allocation ratios using `uniroot()`
- **`validate_inputs()`** (lines 529-579): Tab-specific input validation with user-friendly error messages

### Output Components

Each analysis tab produces multiple outputs:

1. **`output$result_text`** - Narrative description (protocol-ready text)
2. **`output$effect_measures`** - RR, OR, RD calculations (two-group/survival only)
3. **`output$power_plot`** - Power curve visualization
4. **`output$result_table`** - Confidence interval table (single proportion only)

### Data Export

Three export mechanisms:

1. **CSV Export** (`downloadHandler` lines 1021-1160): All analysis inputs/results with timestamp
2. **PDF Export** (`downloadHandler` lines 1164-1223): Uses `analysis-report.Rmd` template (single proportion only)
3. **Scenario Comparison CSV** (lines 1413-1420): Exports saved scenario dataframe

## Adding New Analysis Types

To add a new analysis type:

1. **Create new UI tab** in `tabsetPanel()` with unique input IDs
2. **Add validation logic** in server section using `validate()` and `need()`
3. **Add output renderers** following delayed evaluation pattern:
   ```r
   output$new_result <- renderText({
       if (v$doAnalysis == FALSE) return()
       isolate({ ... })
   })
   ```
4. **Create CSV export handler** with tab-specific data frame structure
5. **Add Example and Reset buttons** with `observeEvent()` handlers
6. **Add scenario comparison logic** to handle new column structure

## Important Implementation Notes

### Reactive Programming

- Always use `isolate()` around calculation blocks to prevent cascading reactive updates
- Use `v$doAnalysis` flag to control when results are displayed
- Reset `v$doAnalysis <- FALSE` when switching tabs to hide stale results
- Use `outputOptions(output, "show_results", suspendWhenHidden = FALSE)` to keep flags reactive even when hidden

### Input Validation

Validation must occur inside `isolate()` to prevent premature execution:

```r
isolate({
    validate(
        need(input$power_n > 0, "Sample size must be positive"),
        need(input$power_p >= 1, "Event frequency must be at least 1")
    )
    # ... calculations
})
```

### Power Curve Generation

Power curves are generated using `sapply()` over a sequence of sample sizes:

```r
n_seq <- seq(50, n_max, length.out = 100)
power_seq <- sapply(n_seq, function(n) {
    pwr.p.test(h = effect_size, n = n, sig.level = alpha)$power
})
plot(n_seq, power_seq, type = "l")
```

Keep sequences to 50-100 points for responsiveness.

### Effect Measure Edge Cases

RR and OR calculations can produce `Inf` or `NaN`:

- **When p2 = 0**: RR and OR are undefined (division by zero)
- **Handle with `if` checks**: Return `NA` or display "Not calculable" messages
- Example in `calc_effect_measures()` at lines 338-354

### Scenario Comparison State

Scenarios are stored in `v$scenarios` reactive value as a data frame. When adding scenarios with different column structures:

```r
# Use union to combine column sets
all_cols <- union(names(v$scenarios), names(new_data))
# Add missing columns with NA
v$scenarios <- rbind(v$scenarios, new_data)
```

## Testing Notes

### Manual Testing Checklist

When modifying the application, test:

1. **All seven tabs** - Ensure Calculate button works
2. **Input validation** - Test boundary values (0, negative, >100%)
3. **Example buttons** - Verify pre-filled values are realistic
4. **Reset buttons** - Confirm defaults are restored
5. **CSV/PDF export** - Check file generation and content
6. **Scenario comparison** - Save multiple scenarios, export comparison
7. **Tab switching** - Verify results hide when switching tabs
8. **Power curves** - Check plot displays correctly
9. **Mobile responsiveness** - Test on different screen sizes

### Common Edge Cases

- **Event rates of 0% or 100%** - May cause mathematical errors
- **Identical group proportions** (p1 = p2) - No effect to detect
- **Hazard ratio of 1.0** - Null effect in survival analysis
- **Very large sample sizes** (>100,000) - May cause slow power curve rendering
- **Discontinuation rate = 100%** - Results in zero effective sample size

## Deployment

### Docker Container with renv

The Dockerfile follows **2024 best practices** for production Shiny deployment with renv:

#### Optimized Layer Structure

1. **System dependencies** (rarely changes)
2. **renv installation** (rarely changes)
3. **renv.lock + restore** (changes when dependencies update) ← **Cached layer**
4. **Application code** (changes frequently) ← **Fast rebuilds**

This structure means:
- Changing your app code → Only rebuilds the last layer (~5 seconds)
- Adding a package → Rebuilds package layer + app layer (~2-5 minutes)
- Changing system deps → Full rebuild (~10-15 minutes)

#### Key Docker Features

**Base Image**: `rocker/shiny:4.4.0`
- R 4.4.0 (latest stable)
- Pre-configured Shiny Server
- Ubuntu-based with common system libraries

**renv Configuration**:
- `RENV_PATHS_LIBRARY=renv/library` - Project-local package library
- `RENV_PATHS_CACHE=/opt/renv/cache` - Container-wide package cache
- `renv::restore()` runs during build (not runtime)

**TinyTeX for PDF Export**:
- Installed after renv restore (to avoid conflicts)
- LaTeX packages: threeparttable, float, booktabs

#### Building the Image

```bash
# Build (leverages Docker cache)
docker build -t power-analysis-tool .

# Build with no cache (if having issues)
docker build --no-cache -t power-analysis-tool .

# Build with docker-compose
docker-compose build
```

#### Rebuilding After Changes

| Change Type | What Rebuilds | Time |
|-------------|---------------|------|
| Edit `app.R` | Last layer only | ~5 sec |
| Add package to `renv.lock` | Package + app layers | ~2-5 min |
| Update `Dockerfile` system deps | Everything | ~10-15 min |

### Port Configuration

- **Local R**: Random port (displayed in console)
- **Docker**: Port 3838 (mapped in docker-compose.yml)
- **Production**: Use reverse proxy (nginx/Caddy) for HTTPS

### Environment Variables

**Optional configurations**:

```bash
# Increase Shiny app timeout
SHINY_APP_TIMEOUT=60

# Enable detailed logging
R_LOG_LEVEL=DEBUG

# Custom renv cache location
RENV_PATHS_CACHE=/custom/cache/path
```

The application is self-contained and requires no environment variables for basic operation.

## Dependencies

### Required R Packages

```r
install.packages(c(
    "shiny",         # Web application framework
    "bslib",         # Bootstrap 5 theming
    "shinyBS",       # Tooltips and popovers
    "pwr",           # Power analysis for proportions
    "powerSurvEpi",  # Survival analysis (Schoenfeld method)
    "epiR",          # Matched case-control designs
    "binom",         # Exact binomial confidence intervals
    "kableExtra",    # Table formatting (PDF export)
    "tinytex",       # LaTeX support (PDF export)
    "rmarkdown",     # PDF report rendering
    "renv"           # Package version management
))
```

### System Requirements

- **R version**: ≥ 4.2.0 (recommended 4.4.0)
- **LaTeX**: Installed via `tinytex::install_tinytex()` for PDF export
- **Browser**: Modern browser with JavaScript enabled

## File Structure

```
power-analysis-tool/
├── app.R                          # Main Shiny application (all code)
├── analysis-report.Rmd            # R Markdown template for PDF export
├── Dockerfile                     # Container configuration (R 4.4.0)
├── docker-compose.yml             # Local development setup (port 3838)
├── README.md                      # User documentation
├── CLAUDE.md                      # This file
├── TIER3_ENHANCEMENTS.md          # Version 4.0 feature log
├── tests/                         # Test suite
│   ├── testthat.R                 # Test runner configuration
│   └── testthat/
│       └── test-power-analysis.R  # Main test file
└── renv/                          # Package management (if initialized)
    ├── renv.lock                  # Package versions
    └── ...
```

## Key Design Decisions

### Why Monolithic app.R?

The entire application is in a single file (~1,425 lines) rather than modular files. This design:
- Simplifies deployment (single file to copy)
- Reduces overhead for small-medium applications
- Makes navigation easier with section markers (`##...`)
- Standard practice for Shiny apps <2,000 lines

If the application grows beyond 2,000 lines, consider splitting into:
- `ui.R` - UI definition
- `server.R` - Server logic
- `modules/` - Reusable Shiny modules for each analysis type

### Why Delayed Evaluation Pattern?

Results are calculated only on button click rather than reactively because:
- Power calculations are computationally cheap but power curves are not
- Prevents user confusion from results updating mid-input
- Gives users explicit control over when calculations occur
- Standard pattern for "submit" workflows in Shiny

### Why No Unit Tests?

The application relies on well-tested statistical packages (`pwr`, `powerSurvEpi`, `epiR`). The UI/server integration is best tested manually through browser interaction rather than automated tests. Focus testing efforts on:
- Input validation logic
- Helper function correctness (`calc_effect_measures`, `solve_n1_for_ratio`)
- Edge case handling

## Common Modifications

### Changing Default Values

Default values are set in UI `numericInput()` and `sliderInput()`:

```r
numericInput("power_n", "Available Sample Size:",
             value = 230,  # <-- Change this
             min = 1, step = 1)
```

Also update the Reset button observer:

```r
observeEvent(input$reset_power_single, {
    updateNumericInput(session, "power_n", value = 230)  # <-- Change this
})
```

### Adding New Example Scenarios

Add new example button observer:

```r
observeEvent(input$example_new_scenario, {
    updateNumericInput(session, "power_n", value = 1000)
    updateNumericInput(session, "power_p", value = 500)
    showNotification("Loaded new example scenario", type = "info")
})
```

### Modifying Power Curve Appearance

Power curves are standard base R plots. Customize with plot parameters:

```r
plot(n_seq, power_seq,
     type = "l",           # Line plot
     col = "blue",         # Line color
     lwd = 2,              # Line width
     xlab = "Sample Size",
     ylab = "Power",
     main = "Power Curve",
     cex.lab = 1.2)        # Axis label size
```

### Adjusting Input Ranges

Modify `min`, `max`, `step` parameters in UI inputs:

```r
sliderInput("power_alpha", "Significance Level (α):",
            min = 0.01,   # Minimum value
            max = 0.10,   # Maximum value
            value = 0.05, # Default
            step = 0.01)  # Increment
```

## Future Enhancements

### Recommended: Migration to bs4Dash

The application currently uses the standard `bslib` theme with `fluidPage` layout. For a more professional pharmaceutical dashboard appearance, consider migrating to the **bs4Dash** package:

#### Why bs4Dash?

1. **Professional Enterprise UI**: Built on AdminLTE3, designed specifically for enterprise dashboards and pharmaceutical applications
2. **Enhanced Metrics Display**: `valueBox()` components perfect for displaying calculated power metrics prominently
3. **Rich Component Library**:
   - Collapsible/maximizable cards for complex visualizations
   - Built-in notification system with toasts and alerts
   - Professional sidebar menu with expandable sections
   - Dashboard theming with `freshTheme` for branding consistency
4. **Better Suited for Target Audience**: Pharmaceutical epidemiologists expect polished, professional tools aligned with regulatory submission aesthetics

#### Migration Path

**Current Structure:**
```r
fluidPage(
  sidebarLayout(
    sidebarPanel(tabsetPanel(...)),
    mainPanel(...)
  )
)
```

**bs4Dash Structure:**
```r
dashboardPage(
  header = dashboardHeader(
    title = dashboardBrand(title = "Power Analysis Tool", color = "primary")
  ),
  sidebar = dashboardSidebar(
    sidebarMenu(
      menuItem("Single Proportion", icon = icon("chart-line"),
        menuSubItem("Power", tabName = "power_single"),
        menuSubItem("Sample Size", tabName = "ss_single")
      )
    )
  ),
  body = dashboardBody(
    tabItems(
      tabItem(tabName = "power_single",
        fluidRow(
          box(title = "Inputs", status = "primary", ...),
          box(title = "Results", status = "success", ...)
        ),
        fluidRow(
          valueBox(value = textOutput("power"),
                   subtitle = "Statistical Power",
                   icon = icon("tachometer-alt"),
                   color = "info"),
          valueBox(value = textOutput("sample_size"),
                   subtitle = "Sample Size",
                   icon = icon("users"),
                   color = "success")
        )
      )
    )
  )
)
```

#### Implementation Considerations

- **Current app size**: ~1,500 lines (well-suited for current monolithic structure)
- **Migration effort**: 1-2 days for complete UI restructuring
- **Server logic**: No changes needed - all reactive logic remains identical
- **Input IDs**: Keep all IDs the same for compatibility
- **Breakage risk**: Low - bs4Dash is compatible with standard Shiny components

#### When to Migrate

Consider bs4Dash migration when:
- Preparing the tool for regulatory submission or external publication
- Adding new analysis types that benefit from prominent metric displays
- App exceeds 2,000 lines and needs better organization
- Users request more polished, enterprise-grade appearance

**Note**: The `bs4Dash` package has been added to `Dockerfile` dependencies for future use. The current `bslib` implementation is perfectly functional and appropriate for the app's current size and complexity.

### Other Future Enhancements

1. **Rhino Framework**: Consider for apps >2,000 lines requiring enterprise structure, built-in testing, and CI/CD templates
2. **Async Operations**: Implement `future` + `promises` if power calculations become noticeably slow for users
3. **Shiny Modules**: Break into reusable modules if app grows beyond 2,000 lines
4. **Enhanced Testing**: Expand `testServer()` coverage to all analysis types

## References

- **Hanley & Lippman-Hand (1983)**: Rule of Three for rare event detection
- **Schoenfeld (1983)**: Sample size formula for Cox proportional hazards
- **Cohen (1988)**: Effect size conventions for power analysis
- **FDA/EMA RWE Guidance (2024)**: Regulatory framework for real-world evidence

## Additional Notes

- The application uses **two-sided tests by default** for two-group comparisons (conservative approach)
- **Discontinuation rates** inflate sample sizes via simple multiplier: `n_adjusted = n / (1 - dropout_rate)`
- **Scenario comparison** does not perform statistical comparison, only displays side-by-side parameters
- **PDF export** is limited to single proportion analyses due to R Markdown template complexity
