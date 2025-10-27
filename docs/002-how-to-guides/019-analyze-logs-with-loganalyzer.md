# How to analyze logs with LogAnalyzer

**Type:** How-To
**Audience:** Developers, Operations
**Last Updated:** 2025-10-27

## Goal

Set up and use LogAnalyzer to monitor, analyze, and visualize application logs.

## Prerequisites

- Logging system configured (see 018-logging-best-practices.md)
- Log files being generated in `./logs/`
- R >= 4.2.0

---

## What is LogAnalyzer?

LogAnalyzer is an R package from Appsilon that provides:
- Real-time log monitoring
- Log parsing and analysis
- Interactive dashboards for log visualization
- Pattern detection and alerting

**GitHub:** https://github.com/Appsilon/LogAnalyzer

---

## Installation

### Option 1: Install from GitHub (Recommended)

```r
# Install remotes if needed
if (!require("remotes")) install.packages("remotes")

# Install LogAnalyzer
remotes::install_github("Appsilon/LogAnalyzer")
```

### Option 2: Add to DESCRIPTION (Optional)

For development teams, add to `Suggests`:

```r
Suggests:
    testthat (>= 3.2.1),
    LogAnalyzer
```

Then install with:

```r
devtools::install_dev_deps()
```

---

## Quick Start

### Step 1: Generate some logs

Run your app to generate log files:

```r
# Load and run the app
devtools::load_all()
run_app()

# Interact with the app to generate logs
# - Navigate between tabs
# - Perform calculations
# - Export data
```

### Step 2: Locate log files

Check your log directory:

```r
log_dir <- Sys.getenv("PAT_LOG_DIR", "./logs")
list.files(log_dir, pattern = "\\.log$", full.names = TRUE)
```

### Step 3: Parse logs with LogAnalyzer

```r
library(LogAnalyzer)

# Read log file
log_file <- file.path(log_dir, paste0("app_", Sys.Date(), ".log"))

# For JSON logs (production)
if (Sys.getenv("PAT_LOG_FORMAT") == "json") {
  logs_df <- jsonlite::stream_in(file(log_file))
} else {
  # For console-format logs (development)
  # LogAnalyzer has built-in parsers for common formats
  logs_df <- read_logs(log_file)
}

# View structure
str(logs_df)
head(logs_df)
```

---

## Analyzing Logs

### Count logs by level

```r
library(dplyr)

logs_df %>%
  count(level) %>%
  arrange(desc(n))
```

**Output:**
```
  level    n
  <chr> <int>
1 INFO    450
2 DEBUG   230
3 WARN     15
4 ERROR     3
```

### Find all errors

```r
errors <- logs_df %>%
  filter(level == "ERROR")

# View error messages
errors %>%
  select(time, msg, error_msg, module)
```

### Track user sessions

```r
# Group by session
logs_df %>%
  filter(!is.na(session_id)) %>%
  group_by(session_id) %>%
  summarise(
    events = n(),
    first_event = min(time),
    last_event = max(time),
    duration_min = as.numeric(difftime(max(time), min(time), units = "mins"))
  )
```

### Monitor module usage

```r
# Count events by module
logs_df %>%
  filter(!is.na(module)) %>%
  count(module, sort = TRUE)
```

---

## Visualizing Logs

### Timeline of log events

```r
library(ggplot2)

# Logs over time by level
logs_df %>%
  mutate(hour = lubridate::floor_date(time, "hour")) %>%
  count(hour, level) %>%
  ggplot(aes(x = hour, y = n, color = level)) +
  geom_line() +
  labs(
    title = "Log Events Over Time",
    x = "Time",
    y = "Count",
    color = "Log Level"
  ) +
  theme_minimal()
```

### Error frequency by module

```r
logs_df %>%
  filter(level == "ERROR") %>%
  count(module) %>%
  ggplot(aes(x = reorder(module, n), y = n)) +
  geom_col(fill = "red") +
  coord_flip() +
  labs(
    title = "Errors by Module",
    x = "Module",
    y = "Error Count"
  ) +
  theme_minimal()
```

---

## Real-Time Monitoring

### Watch logs in real-time

Create a monitoring script:

```r
# scripts/monitor_logs.R

library(LogAnalyzer)
library(dplyr)

log_file <- file.path(
  Sys.getenv("PAT_LOG_DIR", "./logs"),
  paste0("app_", Sys.Date(), ".log")
)

# Monitor for new log entries
monitor_logs <- function(file_path, interval_sec = 5) {
  last_pos <- 0

  while (TRUE) {
    # Read new lines
    con <- file(file_path, "r")
    seek(con, last_pos)
    new_lines <- readLines(con)
    last_pos <- seek(con)
    close(con)

    if (length(new_lines) > 0) {
      # Parse and display
      for (line in new_lines) {
        tryCatch({
          entry <- jsonlite::fromJSON(line)

          # Highlight errors
          if (entry$level == "ERROR") {
            cat("\n[ERROR]", entry$msg, "\n")
            cat("  Module:", entry$module, "\n")
            cat("  Error:", entry$error_msg, "\n\n")
          }
        }, error = function(e) {
          # Skip unparseable lines
        })
      }
    }

    Sys.sleep(interval_sec)
  }
}

# Run monitor
monitor_logs(log_file)
```

Run the script:

```bash
Rscript scripts/monitor_logs.R
```

---

## Alerting on Patterns

### Detect error spikes

```r
# Count errors per hour
error_counts <- logs_df %>%
  filter(level == "ERROR") %>%
  mutate(hour = lubridate::floor_date(time, "hour")) %>%
  count(hour)

# Alert if >10 errors in an hour
error_spikes <- error_counts %>%
  filter(n > 10)

if (nrow(error_spikes) > 0) {
  warning("Error spike detected!")
  print(error_spikes)
}
```

### Detect slow operations

```r
# If you log execution time
slow_ops <- logs_df %>%
  filter(!is.na(duration_ms)) %>%
  filter(duration_ms > 5000)  # >5 seconds

if (nrow(slow_ops) > 0) {
  message("Slow operations detected:")
  print(slow_ops %>% select(time, msg, duration_ms, module))
}
```

---

## Log Analysis Dashboard

Create an interactive Shiny dashboard for log analysis:

```r
# scripts/log_dashboard.R

library(shiny)
library(dplyr)
library(ggplot2)
library(jsonlite)

ui <- fluidPage(
  titlePanel("Power Analysis Tool - Log Dashboard"),

  sidebarLayout(
    sidebarPanel(
      dateInput("log_date", "Select Date:", value = Sys.Date()),
      selectInput("log_level", "Filter by Level:",
                 choices = c("All", "ERROR", "WARN", "INFO", "DEBUG")),
      actionButton("refresh", "Refresh Logs")
    ),

    mainPanel(
      tabsetPanel(
        tabPanel("Overview",
                plotOutput("timeline"),
                tableOutput("level_summary")),
        tabPanel("Errors",
                tableOutput("error_table")),
        tabPanel("Modules",
                plotOutput("module_usage"))
      )
    )
  )
)

server <- function(input, output, session) {
  logs_data <- reactive({
    # Read log file
    log_file <- file.path(
      Sys.getenv("PAT_LOG_DIR", "./logs"),
      paste0("app_", input$log_date, ".log")
    )

    if (!file.exists(log_file)) {
      return(data.frame())
    }

    # Parse JSON logs
    logs <- jsonlite::stream_in(file(log_file), verbose = FALSE)

    # Filter by level
    if (input$log_level != "All") {
      logs <- logs %>% filter(level == input$log_level)
    }

    logs
  })

  output$timeline <- renderPlot({
    req(nrow(logs_data()) > 0)

    logs_data() %>%
      mutate(hour = lubridate::floor_date(time, "hour")) %>%
      count(hour, level) %>%
      ggplot(aes(x = hour, y = n, color = level)) +
      geom_line() +
      theme_minimal()
  })

  output$level_summary <- renderTable({
    req(nrow(logs_data()) > 0)

    logs_data() %>%
      count(level) %>%
      arrange(desc(n))
  })

  output$error_table <- renderTable({
    req(nrow(logs_data()) > 0)

    logs_data() %>%
      filter(level == "ERROR") %>%
      select(time, msg, error_msg, module)
  })

  output$module_usage <- renderPlot({
    req(nrow(logs_data()) > 0)

    logs_data() %>%
      filter(!is.na(module)) %>%
      count(module) %>%
      ggplot(aes(x = reorder(module, n), y = n)) +
      geom_col() +
      coord_flip() +
      theme_minimal()
  })
}

shinyApp(ui, server)
```

Run the dashboard:

```r
shiny::runApp("scripts/log_dashboard.R")
```

---

## Production Monitoring

### Centralized Log Aggregation

For production deployments, consider:

1. **ELK Stack** (Elasticsearch, Logstash, Kibana)
2. **Splunk**
3. **Grafana Loki**
4. **AWS CloudWatch Logs**

### Ship logs to external service

```r
# Example: Send to Loggly
# Configure in R/zzz.R

if (!interactive()) {
  # Production mode - also send to Loggly
  logger::log_appender(logger::appender_tee(
    logger::appender_file(log_file),
    logger::appender_syslog(
      host = "logs-01.loggly.com",
      port = 514
    )
  ))
}
```

---

## Best Practices

1. **Rotate logs** to prevent disk space issues
2. **Archive old logs** after analysis
3. **Set up alerts** for critical errors
4. **Review logs weekly** for patterns
5. **Monitor performance** via log timings

---

## Troubleshooting

### Log file not found

```r
# Check expected path
log_file <- file.path(
  Sys.getenv("PAT_LOG_DIR", "./logs"),
  paste0("app_", Sys.Date(), ".log")
)

file.exists(log_file)  # Should be TRUE
```

### Logs not in JSON format

Check your `.Renviron`:

```bash
PAT_LOG_FORMAT=json
```

Restart R session after changing.

### Cannot parse log entries

Verify log format:

```r
# Read first few lines
readLines(log_file, n = 5)
```

Should be valid JSON if `PAT_LOG_FORMAT=json`.

---

**Related Documentation:**
- docs/003-reference/010-logging-reference.md
- docs/002-how-to-guides/018-logging-best-practices.md

**External Resources:**
- LogAnalyzer GitHub: https://github.com/Appsilon/LogAnalyzer
- Appsilon blog: https://www.appsilon.com/post/introducing-loganalyzer
