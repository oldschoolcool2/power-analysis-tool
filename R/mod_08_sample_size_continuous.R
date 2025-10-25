#' 08_sample_size_continuous UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd 
#'
#' @importFrom shiny NS tagList 
mod_08_sample_size_continuous_ui <- function(id) {
  ns <- NS(id)
  tagList(
 
  )
}
    
#' 08_sample_size_continuous Server Functions
#'
#' @noRd 
mod_08_sample_size_continuous_server <- function(id){
  moduleServer(id, function(input, output, session){
    ns <- session
 
  })
}
    
## To be copied in the UI
# mod_08_sample_size_continuous_ui("08_sample_size_continuous_1")
    
## To be copied in the server
# mod_08_sample_size_continuous_server("08_sample_size_continuous_1")
