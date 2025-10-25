#' 04_power_survival UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_04_power_survival_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 04_power_survival Server Functions
#'
#' @noRd 
mod_04_power_survival_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_04_power_survival_ui("04_power_survival_1")
    
## To be copied in the server
# mod_04_power_survival_server("04_power_survival_1")
