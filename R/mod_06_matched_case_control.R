#' 06_matched_case_control UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_06_matched_case_control_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 06_matched_case_control Server Functions
#'
#' @noRd 
mod_06_matched_case_control_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_06_matched_case_control_ui("06_matched_case_control_1")
    
## To be copied in the server
# mod_06_matched_case_control_server("06_matched_case_control_1")
