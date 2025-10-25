# How to troubleshoot deployment issues

**Type:** How-To Guide
**Audience:** Developers, DevOps
**Last Updated:** 2025-10-25

## Overview

This guide helps you diagnose and fix common deployment issues when deploying your golem-based Shiny app to production environments.

You'll learn how to troubleshoot:
- shinyapps.io deployment failures
- Posit Connect deployment issues
- Docker container problems
- Dependency resolution errors
- Performance issues in production
- renv.lock synchronization problems

---

## Quick Diagnosis

### Is Your App Working Locally?

**Before troubleshooting deployment, verify locally:**

```r
# 1. Load all code
devtools::load_all()

# 2. Run the app
powerAnalysisTool::run_app()
```

**If it doesn't work locally:**
- Fix local issues first
- Check console for error messages
- Verify all dependencies are installed
- Run `devtools::check()` for package issues

**If it works locally but not in deployment:**
- Continue with this troubleshooting guide

---

## Part 1: shinyapps.io Deployment Issues

### Issue 1.1: "Unable to deploy - bundle too large"

**Symptoms:**
```
Error: The application could not be deployed because the bundle is too large.
Maximum size is 3GB, but bundle is 3.2GB.
```

**Causes:**
- Large data files included in deployment
- Many unused packages in renv.lock
- Build artifacts not ignored

**Solutions:**

**Step 1: Create/update .rscignore**

```bash
# .rscignore
.git
.Rproj.user
.Rhistory
.RData
docs/
tests/
vignettes/
data-raw/
*.Rmd
README.md
.DS_Store
.gitignore
dev/
inst/dev/
```

**Step 2: Remove large files from inst/**

```r
# Move large reference data out of package
# Instead, download on first run or use external data source

# Before (in inst/extdata/large_dataset.csv - 500MB)
data <- system.file("extdata", "large_dataset.csv", package = "powerAnalysisTool")

# After (download on demand)
data_url <- "https://example.com/large_dataset.csv"
cache_file <- "~/.powerAnalysisTool/large_dataset.csv"
if (!file.exists(cache_file)) {
  download.file(data_url, cache_file)
}
```

**Step 3: Clean up renv.lock**

```r
# Remove unused packages
renv::clean()

# Update renv.lock to only include used packages
renv::snapshot()

# Check the lock file size
file.size("renv.lock") / 1024^2  # Size in MB
```

**Verification:**

```r
# Check deployment bundle size before deploying
rsconnect::showLogs()

# If still too large, identify large files:
# In terminal:
du -sh * | sort -rh | head -20
```

---

### Issue 1.2: "Dependency installation failed"

**Symptoms:**
```
Error: Installation of package 'somepackage' failed
Installation of Rcpp (1.0.11) failed [error code: 1]
```

**Causes:**
- Package requires system libraries not available on shinyapps.io
- Package compilation fails
- Version conflicts

**Solutions:**

**Step 1: Check if package needs system libraries**

```r
# Common packages that need system libraries:
# - rJava (Java)
# - RMySQL (MySQL client)
# - RPostgres (PostgreSQL client)
# - sf (GDAL, GEOS, PROJ)
# - magick (ImageMagick)
# - xml2 (libxml2)
# - curl (libcurl)
```

**For packages needing system libraries:**

```r
# Option A: Use pure R alternatives
# Instead of: RMySQL
# Use: DBI + RMariaDB (pre-installed on shinyapps.io)

# Option B: Check if library is available
# https://docs.posit.co/shinyapps.io/applications.html#system-dependencies
```

**Step 2: Pin package versions in renv.lock**

```r
# If specific version fails, try different version
# Manually edit renv.lock:

{
  "Package": "Rcpp",
  "Version": "1.0.10",  # Try older version
  "Source": "Repository",
  "Repository": "CRAN"
}

# Then restore
renv::restore()
```

**Step 3: Use binary packages when possible**

```r
# In .Rprofile (create if doesn't exist)
options(
  repos = c(
    RSPM = "https://packagemanager.rstudio.com/cran/latest",
    CRAN = "https://cloud.r-project.org"
  ),
  HTTPUserAgent = sprintf(
    "R/%s R (%s)",
    getRversion(),
    paste(getRversion(), R.version$platform, R.version$arch, R.version$os)
  )
)

# This uses Posit Public Package Manager which provides pre-built binaries
```

**Verification:**

```r
# Test package installation in clean session
renv::restore()
library(problemPackage)  # Should load without error
```

---

### Issue 1.3: "Application failed to start"

**Symptoms:**
- App deploys successfully but shows error when loading
- Gray screen or "An error has occurred"
- Works locally but not on shinyapps.io

**Causes:**
- Missing app.R file
- Incorrect run_app() call
- Environment-specific paths
- Missing .onLoad initialization

**Solutions:**

**Step 1: Verify app.R structure**

```r
# app.R (must be in root directory)
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
powerAnalysisTool::run_app()
```

**Common mistakes:**

```r
# ❌ Wrong - using library()
library(powerAnalysisTool)
run_app()

# ❌ Wrong - wrong function name
powerAnalysisTool::runApp()

# ❌ Wrong - missing options
powerAnalysisTool::run_app()

# ✅ Correct
pkgload::load_all(export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)
options("golem.app.prod" = TRUE)
powerAnalysisTool::run_app()
```

**Step 2: Check for hard-coded paths**

```r
# ❌ Wrong - absolute path
data <- read.csv("/Users/mike/Documents/data.csv")

# ❌ Wrong - relative to working directory
data <- read.csv("../../data/file.csv")

# ✅ Correct - using system.file()
data_path <- system.file("extdata", "file.csv", package = "powerAnalysisTool")
data <- read.csv(data_path)

# ✅ Correct - app_sys() helper
data_path <- app_sys("extdata", "file.csv")
data <- read.csv(data_path)
```

**Step 3: Check logs on shinyapps.io**

```r
# View deployment logs
rsconnect::showLogs()

# Or in browser:
# 1. Go to shinyapps.io dashboard
# 2. Click your app
# 3. Click "Logs" tab
# 4. Look for ERROR messages
```

**Step 4: Add debug logging**

```r
# In R/run_app.R, add logging:
run_app <- function(...) {
  message("Starting app...")
  message("golem.app.prod = ", getOption("golem.app.prod"))
  message("Working directory: ", getwd())

  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      options = list(...)
    ),
    golem_opts = list(...)
  )
}

# Then check logs for these messages
```

---

### Issue 1.4: "Memory limit exceeded"

**Symptoms:**
```
Error: memory exhausted (limit reached)
Error: cannot allocate vector of size X MB
```

**Causes:**
- App uses too much memory
- Free tier has 1GB RAM limit
- Memory leak in reactive code
- Large datasets loaded into memory

**Solutions:**

**Step 1: Upgrade plan**

```
Free tier: 1GB RAM, 1 worker
Starter: 2GB RAM, 3 workers ($9/month)
Basic: 4GB RAM, 5 workers ($39/month)
```

**Step 2: Optimize memory usage**

```r
# ❌ Wrong - loading all data upfront
full_data <- read.csv("huge_file.csv")  # 800MB

server <- function(input, output, session) {
  filtered_data <- reactive({
    full_data[full_data$category == input$category, ]
  })
}

# ✅ Correct - load only what's needed
server <- function(input, output, session) {
  filtered_data <- reactive({
    # Read only needed columns and rows
    data.table::fread(
      "huge_file.csv",
      select = c("id", "value", "category"),
      filter = paste0("category=='", input$category, "'")
    )
  })
}

# ✅ Better - use database instead of CSV
server <- function(input, output, session) {
  filtered_data <- reactive({
    con <- dbConnect(RSQLite::SQLite(), "data.db")
    result <- dbGetQuery(
      con,
      "SELECT id, value FROM data WHERE category = ?",
      params = list(input$category)
    )
    dbDisconnect(con)
    result
  })
}
```

**Step 3: Fix memory leaks**

```r
# Common cause: Not cleaning up reactive values

# ❌ Memory leak - accumulating data
server <- function(input, output, session) {
  all_results <- reactiveVal(list())

  observeEvent(input$run, {
    new_result <- run_analysis()
    # This grows forever!
    all_results(c(all_results(), list(new_result)))
  })
}

# ✅ Fixed - keep only latest
server <- function(input, output, session) {
  latest_result <- reactiveVal(NULL)

  observeEvent(input$run, {
    new_result <- run_analysis()
    latest_result(new_result)  # Replaces old value
  })
}

# ✅ Fixed - keep limited history
server <- function(input, output, session) {
  results_history <- reactiveVal(list())

  observeEvent(input$run, {
    new_result <- run_analysis()
    history <- results_history()
    # Keep only last 10
    results_history(tail(c(history, list(new_result)), 10))
  })
}
```

**Step 4: Monitor memory usage**

```r
# Add memory monitoring to your app
server <- function(input, output, session) {
  output$memory_usage <- renderText({
    invalidateLater(5000)  # Update every 5 seconds
    mem <- pryr::mem_used()
    sprintf("Memory: %.1f MB", mem / 1024^2)
  })
}
```

---

## Part 2: Posit Connect Deployment Issues

### Issue 2.1: "Unauthorized - API key invalid"

**Symptoms:**
```
Error: Unauthorized (HTTP 401)
Unable to publish to server: Invalid API key
```

**Solutions:**

**Step 1: Generate new API key**

1. Log into Posit Connect
2. Go to Profile (top right) → API Keys
3. Click "New API Key"
4. Copy the key immediately (won't be shown again)

**Step 2: Set up credentials**

```r
# Option A: Interactive setup
rsconnect::addServer(
  url = "https://connect.example.com",
  name = "production"
)

rsconnect::connectApiUser(
  account = "your-username",
  server = "production",
  apiKey = "YOUR_API_KEY_HERE"
)

# Option B: Environment variables (recommended for CI/CD)
# In .Renviron:
CONNECT_SERVER=https://connect.example.com
CONNECT_API_KEY=your_api_key_here

# In deploy script:
rsconnect::addConnectServer(
  url = Sys.getenv("CONNECT_SERVER"),
  name = "production"
)

rsconnect::connectApiUser(
  server = "production",
  apiKey = Sys.getenv("CONNECT_API_KEY")
)
```

**Step 3: Deploy**

```r
rsconnect::deployApp(
  appDir = ".",
  appFiles = c("app.R", "DESCRIPTION", "NAMESPACE", "R/", "inst/"),
  server = "production",
  account = "your-username",
  appName = "power-analysis-tool"
)
```

---

### Issue 2.2: "R version mismatch"

**Symptoms:**
```
Error: This app was built with R version 4.3.0, but server has 4.2.0
Warning: Package versions may not match
```

**Solutions:**

**Step 1: Check server R version**

Contact your Posit Connect administrator or check documentation.

**Step 2: Match R version locally**

```r
# Check your R version
R.version.string

# If different from server, either:
# A) Install matching R version locally, or
# B) Ask admin to install your R version on server
```

**Step 3: Specify R version in deployment**

```r
rsconnect::deployApp(
  appDir = ".",
  appName = "power-analysis-tool",
  forceUpdate = TRUE,
  # Specify R version
  metadata = list(
    appMode = "shiny",
    rVersion = "4.2.0"
  )
)
```

**Step 4: Test with matching version**

```r
# Use Docker to test with target R version
# Create Dockerfile:
FROM rocker/shiny:4.2.0

COPY . /srv/shiny-server/app
WORKDIR /srv/shiny-server/app

RUN R -e "install.packages('renv')"
RUN R -e "renv::restore()"

CMD ["R", "-e", "powerAnalysisTool::run_app()"]
```

---

### Issue 2.3: "Permission denied accessing /opt/..."

**Symptoms:**
```
Error: cannot create directory '/opt/connect/...'
Permission denied
```

**Solutions:**

**Step 1: Don't write to system directories**

```r
# ❌ Wrong - writing to package directory
cache_dir <- system.file("cache", package = "powerAnalysisTool")
dir.create(cache_dir)

# ✅ Correct - use temp directory
cache_dir <- tempdir()
dir.create(file.path(cache_dir, "cache"), showWarnings = FALSE)

# ✅ Correct - use rappdirs for user directory
cache_dir <- rappdirs::user_cache_dir("powerAnalysisTool")
dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
```

**Step 2: Use environment variables for storage**

```r
# In Posit Connect settings, set environment variable:
# APP_CACHE_DIR=/mnt/app-cache/power-analysis-tool

# In your app:
get_cache_dir <- function() {
  cache_dir <- Sys.getenv("APP_CACHE_DIR", unset = tempdir())
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  cache_dir
}
```

---

## Part 3: Docker Deployment Issues

### Issue 3.1: "Package installation fails in Docker"

**Symptoms:**
```
ERROR: dependency 'systemlib' is not available
ERROR: compilation failed for package 'Rcpp'
```

**Solutions:**

**Step 1: Install system dependencies**

```dockerfile
FROM rocker/shiny:4.3.0

# Install system dependencies BEFORE R packages
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libpq-dev \
    libgit2-dev \
    && rm -rf /var/lib/apt/lists/*

# Now install R packages
COPY renv.lock renv.lock
RUN R -e "install.packages('renv')"
RUN R -e "renv::restore()"

COPY . /srv/shiny-server/app
WORKDIR /srv/shiny-server/app

CMD ["R", "-e", "powerAnalysisTool::run_app(options = list(host = '0.0.0.0', port = 3838))"]
```

**Common system dependencies:**

| R Package | System Dependency | Debian/Ubuntu Package |
|-----------|-------------------|----------------------|
| curl | libcurl | libcurl4-openssl-dev |
| xml2 | libxml2 | libxml2-dev |
| openssl | OpenSSL | libssl-dev |
| RPostgres | PostgreSQL | libpq-dev |
| sf | GDAL, GEOS, PROJ | libgdal-dev, libgeos-dev, libproj-dev |
| magick | ImageMagick | libmagick++-dev |
| rJava | Java | default-jdk |
| git2r | libgit2 | libgit2-dev |

**Step 2: Use multi-stage build for smaller images**

```dockerfile
# Stage 1: Build dependencies
FROM rocker/shiny:4.3.0 AS builder

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY renv.lock renv.lock
RUN R -e "install.packages('renv')"
RUN R -e "renv::restore()"

COPY . .
RUN R CMD INSTALL --build .

# Stage 2: Runtime
FROM rocker/shiny:4.3.0

RUN apt-get update && apt-get install -y \
    libcurl4 \
    libssl3 \
    libxml2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/lib/R/site-library /usr/local/lib/R/site-library
COPY --from=builder /build /srv/shiny-server/app

WORKDIR /srv/shiny-server/app

EXPOSE 3838

CMD ["R", "-e", "powerAnalysisTool::run_app(options = list(host = '0.0.0.0', port = 3838))"]
```

---

### Issue 3.2: "App not accessible from host"

**Symptoms:**
- Docker container running but can't access app in browser
- Connection refused on localhost:3838

**Solutions:**

**Step 1: Bind to 0.0.0.0, not localhost**

```r
# In R/run_app.R:
run_app <- function(options = list(), ...) {
  # In production/Docker, bind to all interfaces
  if (!interactive()) {
    options$host <- "0.0.0.0"
    options$port <- as.numeric(Sys.getenv("PORT", "3838"))
  }

  with_golem_options(
    app = shinyApp(ui = app_ui, server = app_server, options = options),
    golem_opts = list(...)
  )
}
```

**Step 2: Map ports correctly**

```bash
# Run Docker with port mapping
docker run -p 3838:3838 my-shiny-app

# Or with docker-compose:
# docker-compose.yml
version: '3'
services:
  app:
    build: .
    ports:
      - "3838:3838"
    environment:
      - PORT=3838
```

**Step 3: Check Docker logs**

```bash
# View logs
docker logs <container-id>

# Follow logs in real-time
docker logs -f <container-id>

# Check if app is listening
docker exec <container-id> netstat -tlnp | grep 3838
```

---

### Issue 3.3: "Container runs out of memory"

**Symptoms:**
```
Error: cannot allocate vector of size X MB
Container killed by OOM killer
```

**Solutions:**

**Step 1: Increase memory limit**

```bash
# Run with memory limit
docker run -m 2g my-shiny-app

# docker-compose.yml
services:
  app:
    build: .
    mem_limit: 2g
    memswap_limit: 2g
```

**Step 2: Optimize Dockerfile caching**

```dockerfile
# Put slow-changing layers first
FROM rocker/shiny:4.3.0

# System deps (rarely change)
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# R packages (change occasionally)
COPY renv.lock renv.lock
RUN R -e "install.packages('renv')"
RUN R -e "renv::restore()"

# App code (changes frequently)
COPY . /srv/shiny-server/app

# This way, changing app code doesn't reinstall packages
```

---

## Part 4: Dependency Issues

### Issue 4.1: "renv.lock out of sync"

**Symptoms:**
```
Warning: The following package(s) are installed but not recorded in renv.lock
Warning: Package versions do not match renv.lock
```

**Solutions:**

**Step 1: Update renv.lock**

```r
# Snapshot current packages
renv::snapshot()

# Review changes
git diff renv.lock

# Commit if correct
git add renv.lock
git commit -m "Update renv.lock"
```

**Step 2: Restore from renv.lock**

```r
# If renv.lock is correct but local install is wrong:
renv::restore()

# If conflicts, use clean restore:
renv::restore(clean = TRUE)
```

**Step 3: Check for development packages**

```r
# List all packages and their sources
renv::status()

# If you have packages from GitHub:
renv::record("username/repo@branch")

# Then snapshot
renv::snapshot()
```

---

### Issue 4.2: "Package version not available on CRAN"

**Symptoms:**
```
Error: package 'oldpackage' is not available for R version 4.3.0
Error: version '1.2.3' of package 'X' cannot be found
```

**Solutions:**

**Step 1: Check CRAN archive**

```r
# Find available versions
available.packages()[, "Version"]["packagename"]

# Update renv.lock to use available version
# Or install from archive:
renv::install("https://cran.r-project.org/src/contrib/Archive/packagename/packagename_1.2.3.tar.gz")
```

**Step 2: Use MRAN or Posit Package Manager**

```r
# In renv/settings.dcf, add:
snapshot.type: all
r.version: 4.3.0

# Or in .Rprofile:
options(repos = c(
  CRAN = "https://packagemanager.rstudio.com/cran/2023-10-15"  # Frozen CRAN snapshot
))

# Then restore
renv::restore()
```

**Step 3: Pin to specific date**

```r
# Create renv/settings.dcf:
snapshot.type: all
use.cache: TRUE
ppm.enabled: TRUE
ppm.url: https://packagemanager.rstudio.com/cran/2023-10-15

# This uses CRAN as it existed on 2023-10-15
```

---

## Part 5: Performance Issues

### Issue 5.1: "App is slow in production"

**Symptoms:**
- Fast locally but slow on server
- Long loading times
- Slow reactivity

**Solutions:**

**Step 1: Enable profiling**

```r
# In R/run_app.R
run_app <- function(...) {
  # Enable profiling in production
  if (getOption("golem.app.prod", FALSE)) {
    options(shiny.reactlog = TRUE)
  }

  with_golem_options(
    app = shinyApp(ui = app_ui, server = app_server, ...),
    golem_opts = list(...)
  )
}

# Then access: http://yourapp.com/?showreactlog=true
```

**Step 2: Cache expensive computations**

```r
# Before: Recalculates every time
output$plot <- renderPlot({
  expensive_data_processing(input$data)
  make_plot(data)
})

# After: Cache based on inputs
cache_key <- memoise::memoise(
  expensive_data_processing,
  cache = cachem::cache_disk("~/.cache/myapp")
)

output$plot <- renderPlot({
  data <- cache_key(input$data)
  make_plot(data)
})
```

**Step 3: Use async operations**

```r
library(promises)
library(future)
plan(multisession)

# Before: Blocks UI during computation
output$result <- renderText({
  slow_calculation(input$x)
})

# After: Non-blocking
output$result <- renderText({
  future({ slow_calculation(input$x) }) %...>%
    function(result) { result }
})
```

**Step 4: Optimize reactive dependencies**

```r
# Before: Triggers on ANY input change
server <- function(input, output, session) {
  data <- reactive({
    # Depends on ALL inputs implicitly
    expensive_operation(input$slider1, input$slider2, input$text, input$checkbox)
  })
}

# After: Explicit dependencies
server <- function(input, output, session) {
  data <- reactive({
    # Only re-runs when slider1 or slider2 change
    req(input$slider1, input$slider2)
    expensive_operation(input$slider1, input$slider2)
  }) %>% bindEvent(input$slider1, input$slider2)
}
```

---

### Issue 5.2: "Too many concurrent users"

**Symptoms:**
```
Error: Maximum number of connections reached
Users see "Application is busy" message
```

**Solutions:**

**Step 1: Increase worker count**

For shinyapps.io:
```r
rsconnect::configureApp(
  appName = "power-analysis-tool",
  account = "your-account",
  size = "large",  # More memory
  instances = 5     # More concurrent instances
)
```

For Posit Connect:
```
# In Connect dashboard:
1. Go to app settings
2. Runtime tab
3. Increase "Max Processes"
4. Increase "Max Connections Per Process"
```

For Docker with ShinyProxy:
```yaml
# application.yml
specs:
  - id: power-analysis
    container-image: myapp:latest
    container-memory: 2g
    container-network: shinyproxy-net
    instances:
      min: 2    # Always 2 running
      max: 10   # Scale up to 10
```

**Step 2: Optimize for multiple users**

```r
# ❌ Bad: Global data (shared across ALL users)
data <- read.csv("large_file.csv")

server <- function(input, output, session) {
  output$table <- renderTable({ data })
}

# ✅ Good: Reactive data (isolated per user)
server <- function(input, output, session) {
  user_data <- reactive({
    read.csv("large_file.csv")
  })
  output$table <- renderTable({ user_data() })
}

# ✅ Better: Shared data loaded once
# In global.R or above server function:
shared_data <- read.csv("large_file.csv")

server <- function(input, output, session) {
  # Each user gets view of shared data
  output$table <- renderTable({ shared_data })
}
```

---

## Part 6: Debugging Tools

### Tool 1: Application Logs

**shinyapps.io:**
```r
rsconnect::showLogs()
```

**Posit Connect:**
```r
# In browser:
# App → Logs tab
# Or use API:
library(connectapi)
client <- connect()
app <- get_content(client, "your-app-id")
get_content_logs(app)
```

**Docker:**
```bash
docker logs my-container
docker logs -f my-container  # Follow
docker logs --tail 100 my-container  # Last 100 lines
```

---

### Tool 2: Add Debug Messages

```r
# In your module or server code:
server <- function(input, output, session) {
  observeEvent(input$button, {
    message("Button clicked at ", Sys.time())
    message("Input values: ", paste(names(input), collapse = ", "))

    tryCatch({
      result <- risky_operation()
      message("Operation succeeded")
    }, error = function(e) {
      message("ERROR: ", e$message)
      message("Traceback: ", paste(sys.calls(), collapse = "\n"))
    })
  })
}
```

---

### Tool 3: Health Check Endpoint

```r
# In R/run_app.R
run_app <- function(...) {
  # Add health check
  health_check <- function(req) {
    list(
      status = "healthy",
      timestamp = Sys.time(),
      r_version = R.version.string,
      memory_mb = as.numeric(pryr::mem_used()) / 1024^2
    )
  }

  with_golem_options(
    app = shinyApp(
      ui = app_ui,
      server = app_server,
      options = list(...)
    ),
    golem_opts = list(...)
  )
}

# Access: http://yourapp.com/__health__
```

---

### Tool 4: Reactlog

```r
# Enable reactlog
options(shiny.reactlog = TRUE)

# Run app
run_app()

# In browser, press Ctrl+F3
# Or visit: http://localhost:3838/?showreactlog=true
```

---

## Quick Reference

### Deployment Checklist

Before deploying:

- [ ] App works locally: `devtools::load_all(); run_app()`
- [ ] Tests pass: `devtools::test()`
- [ ] Package check passes: `devtools::check()`
- [ ] renv.lock is up to date: `renv::status()`
- [ ] No hard-coded paths in code
- [ ] app.R exists and is correct
- [ ] .rscignore configured correctly
- [ ] Environment variables documented
- [ ] No secrets in code (use environment variables)

### Common Error Patterns

| Error Message | Likely Cause | Quick Fix |
|---------------|--------------|-----------|
| "Bundle too large" | Large files in deployment | Add to .rscignore |
| "Package installation failed" | Missing system library | Check package needs |
| "Cannot allocate vector" | Out of memory | Optimize or upgrade plan |
| "Application failed to start" | Incorrect app.R | Verify app.R structure |
| "Permission denied" | Writing to read-only location | Use tempdir() |
| "Unauthorized" | Invalid API key | Regenerate API key |
| "R version mismatch" | Different R versions | Match R versions |
| "Connection refused" | Wrong host binding | Use host="0.0.0.0" |

---

## Next Steps

After troubleshooting your deployment:

1. **Document environment-specific config**: Add deployment notes to README
2. **Set up CI/CD**: Automate testing and deployment
3. **Monitor in production**: Set up alerts for errors
4. **Plan for scaling**: Consider load balancing if needed
5. **Regular maintenance**: Update dependencies quarterly

**Related Documentation:**
- [How to reorganize as R package with golem](009-reorganize-as-r-package-with-golem.md) - See Phase 7 for deployment setup
- [Package structure reference](../003-reference/002-package-structure-reference.md) - File organization

**External References:**
- [shinyapps.io documentation](https://docs.posit.co/shinyapps.io/)
- [Posit Connect documentation](https://docs.posit.co/connect/)
- [Docker + Shiny guide](https://www.r-bloggers.com/2019/02/dockerizing-shiny-applications/)
- [ShinyProxy documentation](https://www.shinyproxy.io/)
- [rsconnect package](https://rstudio.github.io/rsconnect/)

---

**Last Updated:** 2025-10-25
**Version:** 1.0
**Status:** Complete
