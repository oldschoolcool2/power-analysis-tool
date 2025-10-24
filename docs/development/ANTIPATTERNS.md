# R & Shiny Antipatterns Guide

## Overview

This guide documents common antipatterns in R and Shiny development, why they're problematic, and how to avoid them. Our codebase uses automated tools to detect and prevent these issues.

**Last Updated:** 2025-10-24

---

## Table of Contents

1. [R General Antipatterns](#r-general-antipatterns)
2. [Shiny-Specific Antipatterns](#shiny-specific-antipatterns)
3. [Code Quality Antipatterns](#code-quality-antipatterns)
4. [Detection & Prevention](#detection--prevention)
5. [How to Fix Common Issues](#how-to-fix-common-issues)

---

## R General Antipatterns

### 1. Using `sapply()` Instead of `vapply()`

**❌ Antipattern:**
```r
results <- sapply(data_list, mean)
```

**Why it's bad:**
- `sapply()` returns inconsistent types (sometimes vector, sometimes list)
- Type instability causes bugs that only appear at runtime
- Makes code harder to reason about

**✅ Best Practice:**
```r
# Explicitly specify return type
results <- vapply(data_list, mean, FUN.VALUE = numeric(1))
```

**Detection:** `undesirable_function_linter` in lintr

---

### 2. Using `T` and `F` Instead of `TRUE` and `FALSE`

**❌ Antipattern:**
```r
if (x > 0 && debug == T) {
  message("Debugging")
}
```

**Why it's bad:**
- `T` and `F` are **variables**, not constants
- Can be overwritten: `T <- FALSE` (valid R code!)
- Causes subtle bugs

**✅ Best Practice:**
```r
if (x > 0 && debug == TRUE) {
  message("Debugging")
}
```

**Detection:** `T_and_F_symbol_linter` in lintr

---

### 3. Using `setwd()` in Scripts

**❌ Antipattern:**
```r
setwd("/home/user/my-project")
source("analysis.R")
```

**Why it's bad:**
- Breaks reproducibility (path doesn't exist on other machines)
- Changes global state (side effects)
- Doesn't work in containers/CI/CD

**✅ Best Practice:**
```r
# Option 1: Use relative paths
source("analysis.R")

# Option 2: Use here package
library(here)
source(here("scripts", "analysis.R"))

# Option 3: For temporary changes
withr::with_dir("./data", {
  # Code that needs to run in ./data
})
```

**Detection:** `undesirable_function_linter` in lintr, custom check in `check_antipatterns.R`

---

### 4. Hardcoded Absolute Paths

**❌ Antipattern:**
```r
data <- read.csv("/home/mike/Documents/data.csv")
output_path <- "C:/Users/John/results/plot.png"
```

**Why it's bad:**
- Won't work on other machines
- Breaks Docker containers
- Not portable across OS (Windows vs Unix)

**✅ Best Practice:**
```r
# Use relative paths
data <- read.csv("data/data.csv")

# Use file.path() for cross-platform compatibility
output_path <- file.path("results", "plot.png")

# For temporary files
temp_file <- tempfile(fileext = ".csv")
```

**Detection:** `absolute_path_linter` and `nonportable_path_linter` in lintr

---

### 5. Using `attach()`

**❌ Antipattern:**
```r
attach(mtcars)
mean_mpg <- mean(mpg)  # Where does 'mpg' come from? Unclear!
```

**Why it's bad:**
- Pollutes global namespace
- Name collisions (if mtcars has column named `mean`, conflicts with `mean()`)
- Makes code harder to understand

**✅ Best Practice:**
```r
# Option 1: Explicit references
mean_mpg <- mean(mtcars$mpg)

# Option 2: Use with() for temporary scope
mean_mpg <- with(mtcars, mean(mpg))

# Option 3: Use dplyr
library(dplyr)
mtcars %>%
  summarize(mean_mpg = mean(mpg))
```

**Detection:** `undesirable_function_linter` in lintr

---

### 6. Shadowing Base R Functions

**❌ Antipattern:**
```r
# 'data' is a base R function
data <- read.csv("study_data.csv")

# 'plot' is a base R function
plot <- ggplot(data, aes(x, y)) + geom_point()
```

**Why it's bad:**
- Overwrites base R functions
- Causes confusion when trying to use the original function
- Can break code that depends on those functions

**✅ Best Practice:**
```r
# Use descriptive names
study_data <- read.csv("study_data.csv")
mpg_plot <- ggplot(study_data, aes(x, y)) + geom_point()
```

**Common variables to avoid:**
- `data`, `plot`, `summary`, `mean`, `sum`, `df`, `c`, `t`, `matrix`, `list`

**Detection:** `object_overwrite_linter` in lintr

---

### 7. Using Class Comparison with `==`

**❌ Antipattern:**
```r
if (class(obj) == "data.frame") {
  # Process data frame
}
```

**Why it's bad:**
- Breaks with S3/S4 classes (which can have multiple classes)
- `class(tibble)` returns `c("tbl_df", "tbl", "data.frame")`
- `class(tibble) == "data.frame"` returns `FALSE`!

**✅ Best Practice:**
```r
# Use inherits()
if (inherits(obj, "data.frame")) {
  # Process data frame
}

# Or is.*() functions
if (is.data.frame(obj)) {
  # Process data frame
}
```

**Detection:** `class_equals_linter` in lintr

---

## Shiny-Specific Antipatterns

### 8. Excessive Use of `renderUI()`

**❌ Antipattern:**
```r
output$dynamic_controls <- renderUI({
  selectInput("var", "Variable", choices = names(data))
})

output$another_control <- renderUI({
  numericInput("n", "Sample size", value = 100)
})

# ... 10 more renderUI calls
```

**Why it's bad:**
- **Performance killer** - Rebuilds entire UI on every change
- Causes flickering
- Loses input state (user selections reset)
- Blocks UI thread

**✅ Best Practice:**
```r
# Define UI statically
ui <- fluidPage(
  selectInput("var", "Variable", choices = NULL),
  numericInput("n", "Sample size", value = 100)
)

# Update choices dynamically
server <- function(input, output, session) {
  observe({
    updateSelectInput(session, "var", choices = names(data))
  })
}
```

**When `renderUI()` is acceptable:**
- Truly dynamic UI (number of controls changes based on user input)
- Complex conditional rendering that can't be done with `conditionalPanel`

**Detection:** Custom check in `check_antipatterns.R` (warns if >5 uses)

---

### 9. Missing `isolate()` in Reactive Contexts

**❌ Antipattern:**
```r
observeEvent(input$calculate, {
  # Reading input$n creates unwanted reactive dependency
  result <- expensive_calculation(input$n, input$alpha)
  output$result <- renderText(result)
})
```

**Why it's bad:**
- Creates unintended reactive dependencies
- Calculation re-runs when `input$n` OR `input$alpha` change
- Defeats purpose of having a Calculate button

**✅ Best Practice:**
```r
observeEvent(input$calculate, {
  # isolate() prevents reactive dependencies
  isolate({
    result <- expensive_calculation(input$n, input$alpha)
    output$result <- renderText(result)
  })
})
```

**Detection:** Custom check in `check_antipatterns.R`

---

### 10. Not Using `bindCache()` for Expensive Renders

**❌ Antipattern:**
```r
output$power_plot <- renderPlot({
  # Expensive calculation: 100 power calculations
  n_seq <- seq(10, 1000, length.out = 100)
  power_seq <- sapply(n_seq, function(n) {
    pwr::pwr.p.test(n = n, h = 0.5, sig.level = 0.05)$power
  })
  plot(n_seq, power_seq, type = "l")
})
```

**Why it's bad:**
- Recalculates identical plots (if user changes tab and comes back)
- Wastes CPU
- Slow user experience

**✅ Best Practice:**
```r
output$power_plot <- renderPlot({
  n_seq <- seq(10, 1000, length.out = 100)
  power_seq <- sapply(n_seq, function(n) {
    pwr::pwr.p.test(n = n, h = 0.5, sig.level = 0.05)$power
  })
  plot(n_seq, power_seq, type = "l")
}) %>%
  bindCache(input$n_max, input$effect_size, input$alpha)
```

**How it works:**
- Caches plot based on cache keys (`input$n_max`, etc.)
- If user returns to same inputs → serves cached plot instantly
- Dramatically faster for expensive renders

**Detection:** Custom check in `check_antipatterns.R`

---

### 11. Blocking Operations in Reactive Contexts

**❌ Antipattern:**
```r
output$data <- renderTable({
  # Blocking operation - freezes entire app!
  Sys.sleep(10)
  data.frame(result = "Done")
})

output$download_file <- downloadHandler(
  content = function(file) {
    # Blocks all users in shared R process
    download.file("https://example.com/large.csv", file)
  }
)
```

**Why it's bad:**
- Shiny is **single-threaded** - one user blocks all users
- UI becomes unresponsive
- Poor user experience (no progress indicator)

**✅ Best Practice:**
```r
# Option 1: Use promises for async
library(promises)
library(future)
plan(multisession)

output$data <- renderTable({
  future({
    Sys.sleep(10)
    data.frame(result = "Done")
  }) %...>% {
    # This code runs when future completes
    .
  }
})

# Option 2: Show progress indicators
output$download_file <- downloadHandler(
  content = function(file) {
    withProgress(message = "Downloading", {
      download.file("https://example.com/large.csv", file)
    })
  }
)
```

**Detection:** Custom check in `check_antipatterns.R` (detects `Sys.sleep`, `download.file`, etc.)

---

### 12. Using `<<-` for Global Assignment

**❌ Antipattern:**
```r
# Global variable modified in server
results_cache <<- list()

server <- function(input, output, session) {
  observeEvent(input$calculate, {
    # Modifies global state - breaks with multiple users!
    results_cache[[input$scenario]] <<- calculate_results()
  })
}
```

**Why it's bad:**
- Breaks in multi-user scenarios (users interfere with each other)
- Hard to debug
- Not thread-safe
- State persists across sessions (memory leak)

**✅ Best Practice:**
```r
server <- function(input, output, session) {
  # Session-specific reactive values
  results <- reactiveValues(
    cache = list()
  )

  observeEvent(input$calculate, {
    results$cache[[input$scenario]] <- calculate_results()
  })
}
```

**Detection:** Custom check in `check_antipatterns.R`

---

## Code Quality Antipatterns

### 13. Very Long Functions (>50 lines)

**❌ Antipattern:**
```r
calculate_everything <- function(data) {
  # 150 lines of code
  # Data cleaning
  # Validation
  # Calculations
  # Formatting
  # Plotting
  # Export
}
```

**Why it's bad:**
- Hard to understand
- Hard to test
- Hard to reuse
- Violates Single Responsibility Principle

**✅ Best Practice:**
```r
# Break into focused functions
clean_data <- function(data) { ... }
validate_inputs <- function(data) { ... }
calculate_results <- function(data) { ... }
format_output <- function(results) { ... }

# Main function orchestrates
process_analysis <- function(data) {
  data <- clean_data(data)
  validate_inputs(data)
  results <- calculate_results(data)
  format_output(results)
}
```

**Rule of thumb:**
- Functions should be <50 lines
- If >50 lines, consider breaking up
- Each function should do ONE thing well

**Detection:** Custom check in `check_antipatterns.R`

---

### 14. Magic Numbers

**❌ Antipattern:**
```r
# What do these numbers mean?
if (sample_size < 384) {
  warning("Sample size below recommended minimum")
}

power_threshold <- 0.8
alpha_level <- 0.05
```

**Why it's bad:**
- Unclear what numbers represent
- Hard to maintain (if you need to change, must find all occurrences)
- No context

**✅ Best Practice:**
```r
# Named constants at top of file
MIN_SAMPLE_SIZE_RCT <- 384  # Cochran's formula for 95% CI, 5% margin
STANDARD_POWER <- 0.80      # Conventional 80% power
STANDARD_ALPHA <- 0.05      # Two-sided α = 0.05

if (sample_size < MIN_SAMPLE_SIZE_RCT) {
  warning("Sample size below recommended minimum")
}
```

**When numbers are OK without constants:**
- 0, 1, 2 (obvious values)
- 100 (for percentages)
- Math constants (2 in `x/2`)

**Detection:** Custom check in `check_antipatterns.R`

---

## Detection & Prevention

### Automated Tools

Our codebase uses multiple layers of antipattern detection:

#### 1. **lintr** - Static Code Analysis

**Configuration:** `.lintr` file

**What it checks:**
- All R general antipatterns (#1-7)
- Style consistency
- Common mistakes

**Run manually:**
```r
lintr::lint_dir(".")
```

**Runs automatically:**
- Pre-commit hook (warning mode)
- GitHub Actions (blocking mode)

---

#### 2. **check_antipatterns.R** - Custom Checks

**What it checks:**
- All Shiny antipatterns (#8-12)
- Code quality issues (#13-14)
- Project-specific patterns

**Run manually:**
```bash
Rscript check_antipatterns.R --file app.R
```

**Runs automatically:**
- GitHub Actions (warning mode)
- Can be added to pre-commit hooks

---

#### 3. **GitHub Actions** - CI/CD

**Workflow:** `.github/workflows/antipattern-check.yml`

**What it does:**
- Runs lintr (blocking - fails PR if issues found)
- Runs custom antipattern checks (warning only)
- Checks code style with styler
- Posts summary to PR

---

#### 4. **Pre-commit Hooks**

**Configuration:** `.pre-commit-config.yaml`

**What it does:**
- Runs styler (auto-formats code)
- Runs lintr (warning mode)
- Checks for debug statements

**Enable:**
```bash
pip install pre-commit
pre-commit install
```

---

## How to Fix Common Issues

### Workflow for Addressing Antipatterns

1. **Run detection tools:**
```bash
# Check for antipatterns
Rscript check_antipatterns.R

# Check linting
R -e "lintr::lint_dir('.')"
```

2. **Prioritize by severity:**
- **HIGH:** Fix immediately (breaks functionality/security)
- **MEDIUM:** Fix before next release
- **LOW:** Fix when refactoring that area

3. **Fix one category at a time:**
```bash
# Example: Fix all object_overwrite issues
# 1. Review lintr output for object_overwrite_linter
# 2. Rename conflicting variables
# 3. Commit: "refactor: resolve object_overwrite antipatterns"
```

4. **Test after fixes:**
```r
# Run tests
testthat::test_dir("tests")

# Run app locally
shiny::runApp()
```

5. **Commit with clear messages:**
```bash
git commit -m "refactor: replace sapply with vapply for type safety"
```

---

### Common Fix Patterns

#### Fix: Replace sapply with vapply
```r
# Before
results <- sapply(data_list, mean)

# After
results <- vapply(data_list, mean, FUN.VALUE = numeric(1))
#                                  ^^^^^^^^^^^^^^^^^^^
#                                  Specify return type
```

#### Fix: Remove absolute paths
```r
# Before
source("/home/user/project/utils.R")

# After
source("utils.R")  # Relative to project root
# OR
source(here::here("R", "utils.R"))
```

#### Fix: Add bindCache to expensive renders
```r
# Before
output$plot <- renderPlot({ expensive_plot() })

# After
output$plot <- renderPlot({
  expensive_plot()
}) %>% bindCache(input$var1, input$var2)
```

---

## Summary: Antipattern Checklist

Before committing code, verify:

- [ ] No `sapply()` - Use `vapply()` instead
- [ ] No `T`/`F` - Use `TRUE`/`FALSE` instead
- [ ] No `setwd()` - Use relative paths or `here::here()`
- [ ] No absolute paths - Use relative paths or `file.path()`
- [ ] No `attach()` - Use explicit `$` or `with()`
- [ ] No shadowing base R functions - Check with `object_overwrite_linter`
- [ ] No class comparison with `==` - Use `inherits()` or `is.*()`
- [ ] Limited `renderUI()` - Use `update*` functions instead
- [ ] Proper use of `isolate()` - Prevent unwanted reactive dependencies
- [ ] Expensive renders use `bindCache()` - Cache when possible
- [ ] No blocking operations - Use async or progress indicators
- [ ] No `<<-` for global state - Use `reactiveValues()` instead
- [ ] Functions <50 lines - Break up long functions
- [ ] No magic numbers - Use named constants

---

## References

### Best Practice Guides
- [Tidyverse Style Guide](https://style.tidyverse.org/)
- [Google R Style Guide](https://google.github.io/styleguide/Rguide.html)
- [Mastering Shiny (Hadley Wickham)](https://mastering-shiny.org/)

### Performance Optimization
- [Shiny Performance Tips (Appsilon)](https://www.appsilon.com/post/optimize-shiny-app-performance)
- [R-Craft Shiny Best Practices](https://r-craft.org/best-practices-for-building-blazing-fast-shiny-apps/)

### Reactive Programming
- [Shiny Reactivity (Datanovia)](https://www.datanovia.com/learn/tools/shiny-apps/fundamentals/reactive-programming.html)
- [Advanced Reactivity (RStudio)](https://shiny.rstudio.com/articles/reactivity-overview.html)

### Code Quality
- [lintr documentation](https://lintr.r-lib.org/)
- [R Packages (Hadley Wickham)](https://r-pkgs.org/)

---

**Last Updated:** 2025-10-24
**Maintainer:** Development Team
**Related Docs:** `CODE_QUALITY.md`, `CLAUDE.md`
