#' 02_power_two_group UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_02_power_two_group_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 02_power_two_group Server Functions
#'
#' @noRd 
mod_02_power_two_group_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
 
  })
}
    
## To be copied in the UI
# mod_02_power_two_group_ui("02_power_two_group_1")
    
## To be copied in the server
# mod_02_power_two_group_server("02_power_two_group_1")
