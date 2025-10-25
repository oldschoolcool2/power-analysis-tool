#' 09_non_inferiority UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_09_non_inferiority_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 09_non_inferiority Server Functions
#'
#' @noRd 
mod_09_non_inferiority_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_09_non_inferiority_ui("09_non_inferiority_1")
    
## To be copied in the server
# mod_09_non_inferiority_server("09_non_inferiority_1")
