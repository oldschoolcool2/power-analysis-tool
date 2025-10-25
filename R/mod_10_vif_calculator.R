#' 10_vif_calculator UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_10_vif_calculator_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 10_vif_calculator Server Functions
#'
#' @noRd 
mod_10_vif_calculator_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_10_vif_calculator_ui("10_vif_calculator_1")
    
## To be copied in the server
# mod_10_vif_calculator_server("10_vif_calculator_1")
