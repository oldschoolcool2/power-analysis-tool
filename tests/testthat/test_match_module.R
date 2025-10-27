library(shiny)
library(bslib)

# Source the module
devtools::load_all()

# Minimal UI
ui <- fluidPage(
  mod_04_matched_case_control_ui("test"),
  hr(),
  verbatimTextOutput("debug")
)

# Server
server <- function(input, output, session) {
  vals <- mod_04_matched_case_control_server("test")

  output$debug <- renderPrint({
    cat("Module inputs:\n")
    print(vals$inputs())
  })
}

shinyApp(ui, server)
