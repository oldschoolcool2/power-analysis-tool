#' Log Monitoring Dashboard - Shiny Application
#'
#' Interactive web-based dashboard for monitoring application logs.
#' Provides real-time visualization, filtering, and analysis of log data.
#'
#' Features:
#' - Real-time log streaming
#' - Error/warning tracking
#' - Module usage analytics
#' - Session tracking
#' - Performance metrics
#' - Export capabilities
#'
#' Usage:
#'   shiny::runApp("inst/app_monitoring")
#'
#' Or from R console:
#'   source("inst/app_monitoring/app.R")
#'   shinyApp(ui, server)

library(shiny)
library(bslib)
library(dplyr)
library(ggplot2)
library(plotly)
library(DT)
library(jsonlite)
library(lubridate)

# ============================================================================
# Configuration
# ============================================================================

LOG_DIR <- Sys.getenv("PAT_LOG_DIR", "./logs")
REFRESH_INTERVAL <- 5000  # 5 seconds

# ============================================================================
# Helper Functions
# ============================================================================

#' Read and parse log files
#' @param days Number of days to look back
#' @return Data frame with parsed logs
read_logs <- function(days = 7) {
  log_files <- list.files(
    LOG_DIR,
    pattern = "^app_.*\\.log$",
    full.names = TRUE
  )

  # Filter by modification time
  recent_files <- log_files[file.mtime(log_files) > Sys.time() - days * 86400]

  if (length(recent_files) == 0) {
    return(data.frame())
  }

  # Read and parse each file
  all_logs <- lapply(recent_files, function(file) {
    lines <- readLines(file, warn = FALSE)
    parsed <- lapply(lines, function(line) {
      tryCatch(fromJSON(line), error = function(e) NULL)
    })
    parsed <- Filter(Negate(is.null), parsed)

    if (length(parsed) > 0) {
      df <- bind_rows(parsed)
      if ("time" %in% names(df)) {
        df$timestamp <- as.POSIXct(df$time, format = "%Y-%m-%d %H:%M:%OS")
      }
      df
    } else {
      data.frame()
    }
  })

  if (length(all_logs) > 0) {
    bind_rows(all_logs)
  } else {
    data.frame()
  }
}

#' Get log statistics
get_log_stats <- function(logs) {
  if (nrow(logs) == 0) {
    return(list(
      total = 0,
      errors = 0,
      warnings = 0,
      info = 0,
      sessions = 0,
      modules = 0
    ))
  }

  list(
    total = nrow(logs),
    errors = sum(toupper(logs$level) == "ERROR", na.rm = TRUE),
    warnings = sum(toupper(logs$level) == "WARN", na.rm = TRUE),
    info = sum(toupper(logs$level) == "INFO", na.rm = TRUE),
    sessions = n_distinct(logs$session_id, na.rm = TRUE),
    modules = n_distinct(logs$module, na.rm = TRUE)
  )
}

# ============================================================================
# UI
# ============================================================================

ui <- page_navbar(
  title = "Power Analysis Tool - Log Monitor",
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = "#2C3E50",
    success = "#18BC9C",
    danger = "#E74C3C",
    warning = "#F39C12"
  ),

  # Overview Tab
  nav_panel(
    "Overview",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 300,

        selectInput(
          "overview_days",
          "Time Range:",
          choices = c("Last Hour" = 0.042, "Last 6 Hours" = 0.25,
                     "Last 24 Hours" = 1, "Last 7 Days" = 7,
                     "Last 30 Days" = 30),
          selected = 1
        ),

        selectInput(
          "overview_level",
          "Log Level:",
          choices = c("All" = "ALL", "ERROR" = "ERROR", "WARN" = "WARN",
                     "INFO" = "INFO", "DEBUG" = "DEBUG", "TRACE" = "TRACE"),
          selected = "ALL"
        ),

        actionButton("refresh_overview", "Refresh", class = "btn-primary w-100")
      ),

      # Main content
      layout_column_wrap(
        width = 1/4,

        value_box(
          title = "Total Logs",
          value = textOutput("stat_total"),
          showcase = bsicons::bs_icon("file-text"),
          theme = "primary"
        ),

        value_box(
          title = "Errors",
          value = textOutput("stat_errors"),
          showcase = bsicons::bs_icon("x-circle"),
          theme = "danger"
        ),

        value_box(
          title = "Warnings",
          value = textOutput("stat_warnings"),
          showcase = bsicons::bs_icon("exclamation-triangle"),
          theme = "warning"
        ),

        value_box(
          title = "Active Sessions",
          value = textOutput("stat_sessions"),
          showcase = bsicons::bs_icon("people"),
          theme = "success"
        )
      ),

      card(
        card_header("Logs Over Time"),
        plotlyOutput("plot_logs_timeline", height = "300px")
      ),

      layout_columns(
        col_widths = c(6, 6),

        card(
          card_header("Log Level Distribution"),
          plotlyOutput("plot_level_dist", height = "300px")
        ),

        card(
          card_header("Top Modules"),
          plotlyOutput("plot_modules", height = "300px")
        )
      )
    )
  ),

  # Errors Tab
  nav_panel(
    "Errors & Warnings",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 300,

        selectInput(
          "errors_hours",
          "Show errors from:",
          choices = c("Last Hour" = 1, "Last 6 Hours" = 6,
                     "Last 24 Hours" = 24, "Last 7 Days" = 168),
          selected = 24
        ),

        checkboxGroupInput(
          "errors_levels",
          "Include:",
          choices = c("Errors" = "ERROR", "Warnings" = "WARN"),
          selected = c("ERROR", "WARN")
        ),

        actionButton("refresh_errors", "Refresh", class = "btn-primary w-100")
      ),

      card(
        card_header("Recent Errors and Warnings"),
        DTOutput("table_errors")
      )
    )
  ),

  # Sessions Tab
  nav_panel(
    "Sessions",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 300,

        selectInput(
          "sessions_days",
          "Time Range:",
          choices = c("Last Hour" = 0.042, "Last 6 Hours" = 0.25,
                     "Last 24 Hours" = 1, "Last 7 Days" = 7),
          selected = 1
        ),

        checkboxInput(
          "sessions_active_only",
          "Show active only (last 10 min)",
          value = FALSE
        ),

        actionButton("refresh_sessions", "Refresh", class = "btn-primary w-100")
      ),

      card(
        card_header("Session Summary"),
        DTOutput("table_sessions")
      )
    )
  ),

  # Performance Tab
  nav_panel(
    "Performance",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 300,

        selectInput(
          "perf_days",
          "Time Range:",
          choices = c("Last Hour" = 0.042, "Last 6 Hours" = 0.25,
                     "Last 24 Hours" = 1, "Last 7 Days" = 7),
          selected = 1
        ),

        numericInput(
          "perf_threshold",
          "Show operations slower than (ms):",
          value = 100,
          min = 0,
          step = 10
        ),

        actionButton("refresh_perf", "Refresh", class = "btn-primary w-100")
      ),

      card(
        card_header("Slow Operations"),
        plotlyOutput("plot_performance", height = "400px")
      ),

      card(
        card_header("Performance Details"),
        DTOutput("table_performance")
      )
    )
  ),

  # Raw Logs Tab
  nav_panel(
    "Raw Logs",
    layout_sidebar(
      sidebar = sidebar(
        title = "Filters",
        width = 300,

        selectInput(
          "raw_level",
          "Log Level:",
          choices = c("All" = "ALL", "ERROR" = "ERROR", "WARN" = "WARN",
                     "INFO" = "INFO", "DEBUG" = "DEBUG", "TRACE" = "TRACE"),
          selected = "ALL"
        ),

        textInput(
          "raw_search",
          "Search:",
          placeholder = "Filter by message..."
        ),

        numericInput(
          "raw_limit",
          "Show last N entries:",
          value = 100,
          min = 10,
          max = 1000,
          step = 10
        ),

        actionButton("refresh_raw", "Refresh", class = "btn-primary w-100"),

        hr(),

        downloadButton("download_logs", "Export All Logs", class = "btn-success w-100")
      ),

      card(
        card_header("Raw Log Entries"),
        DTOutput("table_raw_logs")
      )
    )
  ),

  # Settings Tab
  nav_panel(
    "Settings",
    layout_columns(
      col_widths = c(6, 6),

      card(
        card_header("Configuration"),
        card_body(
          p(strong("Log Directory:"), LOG_DIR),
          p(strong("Refresh Interval:"), paste0(REFRESH_INTERVAL / 1000, " seconds")),
          p(strong("Log Level:"), Sys.getenv("PAT_LOG_LEVEL", "INFO")),
          hr(),
          actionButton("clear_cache", "Clear Cache", class = "btn-warning"),
          p(class = "text-muted mt-2",
            "Clear cache forces reload of all log files on next refresh.")
        )
      ),

      card(
        card_header("About"),
        card_body(
          h5("Power Analysis Tool - Log Monitoring Dashboard"),
          p("Version 1.0.0"),
          p("Real-time monitoring and analysis of application logs."),
          hr(),
          h6("Features:"),
          tags$ul(
            tags$li("Real-time log streaming"),
            tags$li("Error and warning tracking"),
            tags$li("Session monitoring"),
            tags$li("Performance profiling"),
            tags$li("Module usage analytics")
          ),
          hr(),
          p(class = "text-muted",
            "Built with Shiny, bslib, and plotly.")
        )
      )
    )
  )
)

# ============================================================================
# Server
# ============================================================================

server <- function(input, output, session) {

  # Reactive values for caching
  cache <- reactiveValues(
    logs = NULL,
    last_update = NULL
  )

  # Read logs with caching
  get_logs <- reactive({
    # Force refresh on button click
    input$refresh_overview
    input$refresh_errors
    input$refresh_sessions
    input$refresh_perf
    input$refresh_raw

    # Check if cache is valid (< 5 seconds old)
    if (!is.null(cache$last_update) &&
        difftime(Sys.time(), cache$last_update, units = "secs") < 5) {
      return(cache$logs)
    }

    # Read fresh logs
    logs <- read_logs(days = 30)
    cache$logs <- logs
    cache$last_update <- Sys.time()

    logs
  })

  # Clear cache
  observeEvent(input$clear_cache, {
    cache$logs <- NULL
    cache$last_update <- NULL
    showNotification("Cache cleared", type = "message")
  })

  # ========================================================================
  # Overview Tab
  # ========================================================================

  overview_logs <- reactive({
    logs <- get_logs()
    if (nrow(logs) == 0) return(logs)

    days <- as.numeric(input$overview_days)
    cutoff <- Sys.time() - days * 86400

    filtered <- logs %>%
      filter(timestamp >= cutoff)

    if (input$overview_level != "ALL") {
      filtered <- filtered %>%
        filter(toupper(level) == input$overview_level)
    }

    filtered
  })

  # Statistics
  output$stat_total <- renderText({
    stats <- get_log_stats(overview_logs())
    format(stats$total, big.mark = ",")
  })

  output$stat_errors <- renderText({
    stats <- get_log_stats(overview_logs())
    format(stats$errors, big.mark = ",")
  })

  output$stat_warnings <- renderText({
    stats <- get_log_stats(overview_logs())
    format(stats$warnings, big.mark = ",")
  })

  output$stat_sessions <- renderText({
    stats <- get_log_stats(overview_logs())
    format(stats$sessions, big.mark = ",")
  })

  # Timeline plot
  output$plot_logs_timeline <- renderPlotly({
    logs <- overview_logs()

    if (nrow(logs) == 0) {
      return(plot_ly() %>%
        layout(title = "No data available",
               xaxis = list(title = "Time"),
               yaxis = list(title = "Log Count")))
    }

    # Aggregate by hour
    timeline_data <- logs %>%
      mutate(hour = floor_date(timestamp, "hour")) %>%
      count(hour, level = toupper(level))

    plot_ly(timeline_data, x = ~hour, y = ~n, color = ~level,
            type = "scatter", mode = "lines+markers") %>%
      layout(
        title = "Logs Over Time",
        xaxis = list(title = "Time"),
        yaxis = list(title = "Count"),
        hovermode = "x unified"
      )
  })

  # Level distribution
  output$plot_level_dist <- renderPlotly({
    logs <- overview_logs()

    if (nrow(logs) == 0) {
      return(plot_ly() %>% layout(title = "No data available"))
    }

    level_counts <- logs %>%
      count(level = toupper(level)) %>%
      arrange(desc(n))

    plot_ly(level_counts, x = ~level, y = ~n, type = "bar",
            marker = list(color = c("#E74C3C", "#F39C12", "#18BC9C", "#3498DB", "#95A5A6"))) %>%
      layout(
        title = "Log Levels",
        xaxis = list(title = "Level"),
        yaxis = list(title = "Count")
      )
  })

  # Module usage
  output$plot_modules <- renderPlotly({
    logs <- overview_logs()

    if (nrow(logs) == 0 || !"module" %in% names(logs)) {
      return(plot_ly() %>% layout(title = "No module data"))
    }

    module_counts <- logs %>%
      filter(!is.na(module), module != "") %>%
      count(module) %>%
      arrange(desc(n)) %>%
      head(10)

    if (nrow(module_counts) == 0) {
      return(plot_ly() %>% layout(title = "No module data"))
    }

    plot_ly(module_counts, y = ~reorder(module, n), x = ~n, type = "bar",
            orientation = "h", marker = list(color = "#2C3E50")) %>%
      layout(
        title = "Top Modules",
        xaxis = list(title = "Count"),
        yaxis = list(title = "")
      )
  })

  # ========================================================================
  # Errors Tab
  # ========================================================================

  output$table_errors <- renderDT({
    logs <- get_logs()

    if (nrow(logs) == 0) {
      return(data.frame(Message = "No errors found"))
    }

    hours <- as.numeric(input$errors_hours)
    cutoff <- Sys.time() - hours * 3600

    errors <- logs %>%
      filter(
        timestamp >= cutoff,
        toupper(level) %in% input$errors_levels
      ) %>%
      arrange(desc(timestamp)) %>%
      select(timestamp, level, msg, module, session_id, error_msg) %>%
      head(100)

    if (nrow(errors) == 0) {
      return(data.frame(Message = "No errors in selected time range"))
    }

    datatable(
      errors,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        order = list(list(0, "desc"))
      ),
      rownames = FALSE
    )
  })

  # ========================================================================
  # Sessions Tab
  # ========================================================================

  output$table_sessions <- renderDT({
    logs <- get_logs()

    if (nrow(logs) == 0 || !"session_id" %in% names(logs)) {
      return(data.frame(Message = "No session data"))
    }

    days <- as.numeric(input$sessions_days)
    cutoff <- Sys.time() - days * 86400

    sessions <- logs %>%
      filter(!is.na(session_id), session_id != "unknown") %>%
      filter(timestamp >= cutoff) %>%
      group_by(session_id) %>%
      summarise(
        user = first(user, default = "unknown"),
        first_seen = min(timestamp),
        last_seen = max(timestamp),
        event_count = n(),
        errors = sum(toupper(level) == "ERROR"),
        .groups = "drop"
      ) %>%
      arrange(desc(last_seen))

    if (input$sessions_active_only) {
      active_cutoff <- Sys.time() - 600  # 10 minutes
      sessions <- sessions %>% filter(last_seen >= active_cutoff)
    }

    if (nrow(sessions) == 0) {
      return(data.frame(Message = "No sessions found"))
    }

    datatable(
      sessions,
      options = list(
        pageLength = 25,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })

  # ========================================================================
  # Performance Tab
  # ========================================================================

  output$plot_performance <- renderPlotly({
    logs <- get_logs()

    if (nrow(logs) == 0 || !"duration_ms" %in% names(logs)) {
      return(plot_ly() %>% layout(title = "No performance data"))
    }

    days <- as.numeric(input$perf_days)
    cutoff <- Sys.time() - days * 86400

    perf_data <- logs %>%
      filter(!is.na(duration_ms), duration_ms >= input$perf_threshold) %>%
      filter(timestamp >= cutoff) %>%
      arrange(desc(duration_ms)) %>%
      head(50)

    if (nrow(perf_data) == 0) {
      return(plot_ly() %>% layout(title = "No slow operations"))
    }

    plot_ly(perf_data, x = ~timestamp, y = ~duration_ms,
            type = "scatter", mode = "markers",
            text = ~paste(msg, "<br>Duration:", round(duration_ms, 2), "ms"),
            marker = list(size = 10, color = "#E74C3C")) %>%
      layout(
        title = "Slow Operations",
        xaxis = list(title = "Time"),
        yaxis = list(title = "Duration (ms)")
      )
  })

  output$table_performance <- renderDT({
    logs <- get_logs()

    if (nrow(logs) == 0 || !"duration_ms" %in% names(logs)) {
      return(data.frame(Message = "No performance data"))
    }

    days <- as.numeric(input$perf_days)
    cutoff <- Sys.time() - days * 86400

    perf_data <- logs %>%
      filter(!is.na(duration_ms), duration_ms >= input$perf_threshold) %>%
      filter(timestamp >= cutoff) %>%
      select(timestamp, msg, duration_ms, module, session_id) %>%
      arrange(desc(duration_ms)) %>%
      head(100)

    if (nrow(perf_data) == 0) {
      return(data.frame(Message = "No slow operations"))
    }

    datatable(
      perf_data,
      options = list(
        pageLength = 25,
        scrollX = TRUE
      ),
      rownames = FALSE
    )
  })

  # ========================================================================
  # Raw Logs Tab
  # ========================================================================

  output$table_raw_logs <- renderDT({
    logs <- get_logs()

    if (nrow(logs) == 0) {
      return(data.frame(Message = "No logs available"))
    }

    filtered <- logs

    # Apply level filter
    if (input$raw_level != "ALL") {
      filtered <- filtered %>%
        filter(toupper(level) == input$raw_level)
    }

    # Apply search filter
    if (!is.null(input$raw_search) && input$raw_search != "") {
      filtered <- filtered %>%
        filter(grepl(input$raw_search, msg, ignore.case = TRUE))
    }

    # Limit results
    filtered <- filtered %>%
      arrange(desc(timestamp)) %>%
      head(input$raw_limit)

    if (nrow(filtered) == 0) {
      return(data.frame(Message = "No matching logs"))
    }

    datatable(
      filtered,
      options = list(
        pageLength = 50,
        scrollX = TRUE,
        order = list(list(0, "desc"))
      ),
      rownames = FALSE
    )
  })

  # Download logs
  output$download_logs <- downloadHandler(
    filename = function() {
      paste0("logs_export_", format(Sys.Date(), "%Y%m%d"), ".csv")
    },
    content = function(file) {
      logs <- get_logs()
      write.csv(logs, file, row.names = FALSE)
    }
  )
}

# ============================================================================
# Run App
# ============================================================================

shinyApp(ui, server)
