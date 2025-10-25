#' 05_sample_size_survival UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_05_sample_size_survival_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 05_sample_size_survival Server Functions
#'
#' @noRd 
mod_05_sample_size_survival_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_05_sample_size_survival_ui("05_sample_size_survival_1")
    
## To be copied in the server
# mod_05_sample_size_survival_server("05_sample_size_survival_1")
