#' 07_power_continuous UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_07_power_continuous_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 07_power_continuous Server Functions
#'
#' @noRd 
mod_07_power_continuous_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_07_power_continuous_ui("07_power_continuous_1")
    
## To be copied in the server
# mod_07_power_continuous_server("07_power_continuous_1")
