#' 11_propensity_score UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_11_propensity_score_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 11_propensity_score Server Functions
#'
#' @noRd 
mod_11_propensity_score_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_11_propensity_score_ui("11_propensity_score_1")
    
## To be copied in the server
# mod_11_propensity_score_server("11_propensity_score_1")
