#' 01_single_proportion UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_01_single_proportion_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 01_single_proportion Server Functions
#'
#' @noRd 
mod_01_single_proportion_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session$ns
 
  })
}
    
## To be copied in the UI
# mod_01_single_proportion_ui("01_single_proportion_1")
    
## To be copied in the server
# mod_01_single_proportion_server("01_single_proportion_1")
