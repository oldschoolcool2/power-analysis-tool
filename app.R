# https://blogs.bmj.com/bmjebmspotlight/2017/11/14/rare-adverse-events-clinical-trials-understanding-rule-three/

library(shiny)
library(shinythemes)
library(pwr)
library(binom)
library(kableExtra)
library(tinytex)

# Define UI for application that draws a histogram
ui <- fluidPage(
    # SHINY Theme
    theme = shinytheme("lumen"),
    #shinythemes::themeSelector(),
    
    # Application title
    titlePanel("Statistical Power Analysis Tool"),
    
    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            tabsetPanel(id = "tabset",
                        tabPanel("Power",
                                 numericInput("power_n", "Please specify the available Sample Size:", 230),
                                 # sliderInput("power_p", "Please specify frequency of the event of interest (1 in x):", min = 1, max = 10000, value = 100),
                                 numericInput("power_p", "Please specify frequency of the event of interest (1 in x):", min = 1, max = 10000, value = 100),
                                 sliderInput("power_discon", "Withdrawal or Discontinuation rate? (%):", min = 0, max = 20, value = 10)
                        ),
                        tabPanel("Sample Size",
                                 sliderInput("ss_power", "Please specify desired power(%):", min = 50, max = 100, value = 80),
                                 # sliderInput("ss_p", "Please specify frequency of the event of interest (1 in x):", min = 1, max = 10000, value = 100),
                                 numericInput("ss_p", "Please specify frequency of the event of interest (1 in x):", min = 1, max = 10000, value = 100),
                                 sliderInput("ss_discon", "Withdrawal or Discontinuation rate? (%):", min = 0, max = 20, value = 10)
                        )
            )
            ,actionButton("go", "Calculate")
        ),
        # Show a plot of the generated distribution
        mainPanel(
            h1("About this tool"),
            p("In statistical analysis, the 'Rule of Three' states that if a certain event did not occur in a sample with n participants, the interval from 0 to 3/n is a 95% confidence interval for the rate of occurrences in the population. When n is greater than 30, this is a good approximation of results from more sensitive tests. For example, a pain-relief drug is tested on 1500 human participants, and no adverse event is recorded. From the rule of three, it can be concluded with 95% confidence that fewer than 1 person in 500 (or 3/1500) will experience an adverse event."),
            p("This is one of the recommended methods of estimating sample size or power for studies examining safety-event data, such as post-marketing surveillance (PMS) studies. It is also very useful in the interpretation of clinical trials generally, particularly in phase II or III trials where often there are limitations in duration or statistical power for safety assessment."),
            h6(a("Reference: Hanley JA, and Lippman-Hand A. If nothing goes wrong, is everything all right? Interpreting zero numerators. JAMA, 1983.", target="_blank", href="Hanley-1983-1743.pdf")),
            
            uiOutput('result_text'),
            uiOutput('figure_title'),
            plotOutput('power_plot'),
            uiOutput('table_title'),
            dataTableOutput('result_table'),
            uiOutput('table_footnotes'),
            uiOutput('download_button')
            # actionButton("resources", "Tell Me More")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    v <- reactiveValues(doAnalysis = FALSE, doResources=FALSE)
    
    observeEvent(input$go, {
        # 0 will be coerced to FALSE
        # 1+ will be coerced to TRUE
        v$doAnalysis <- input$go
    })
    
    observeEvent(input$tabset, {
        v$doAnalysis <- FALSE
    })
    
    observeEvent(input$resources, {
        # 0 will be coerced to FALSE
        # 1+ will be coerced to TRUE
        v$doResources <- input$resources
    })
    
    ################################################################################################## RESULT TEXT
    
    output$result_text <- renderUI({
        if (v$doAnalysis == FALSE) return()
        
        isolate({
            incidence_rate <- ifelse(input$tabset == "Power", input$power_p, input$ss_p)
            sample_size <- if(input$tabset == "Power"){
                input$power_n
            }
            else {
                pwr.p.test(sig.level=0.05, power=input$ss_power/100, h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }
            
            power <- if(input$tabset == "Power"){
                pwr.p.test(sig.level=0.05, power=NULL, h = ES.h(1/input$power_p, 0), alt="greater", n = input$power_n)$power
            }
            else {
                input$ss_power/100
            }
            
            discon <- if(input$tabset == "Power"){
                input$power_discon/100
            }
            else {
                input$ss_discon/100
            }
            
            text0 <- hr()
            text1 <- h1("Results of this analysis")
            text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
            text3 <- p(paste0("Based on the Binominal distribution and a true event incidence rate of 1 in ", format(incidence_rate, digits=0, nsmall=0), " (or ", format(1/incidence_rate, digits=2, nsmall=2), "%), ", format(ceiling(sample_size), digits=0, nsmall=0), " participants would be needed to observe at least one event with ", format(power*100, digits=0, nsmall=0), "% probability. Accounting for a possible withdrawal or discontinuation rate of ", format(discon*100, digits=0), "%, the target number of participants is set as ",format(ceiling((sample_size * (1+discon))), digits=0),"."))
            HTML(paste0(text0, text1, text2, text3))
        })
    })
    
    ################################################################################################## PLOT TITLE
    
    output$figure_title <- renderUI({
        if (v$doAnalysis == FALSE) return()
        
        isolate({
            incidence_rate <- ifelse(input$tabset == "Power", input$power_p, input$ss_p)
            sample_size <- if(input$tabset == "Power"){
                input$power_n
            }
            else {
                pwr.p.test(sig.level=0.05, power=input$ss_power/100, h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }
            text1 <- hr()
            text2 <- h4(paste0("Estimated power for the given conditions at different sample sizes."))
            HTML(paste0(text1, text2))
        })
    })
    
    ################################################################################################## POWER VS. SAMPLE SIZE PLOT
    
    output$power_plot <- renderPlot({
        if (v$doAnalysis == FALSE) return()
        
        isolate({
            p.out <- if(input$tabset == "Power"){
                pwr.p.test(sig.level=0.05, power=NULL, h = ES.h(1/input$power_p, 0), alt="greater", n = input$power_n)
            }
            else {
                pwr.p.test(sig.level=0.05, power=input$ss_power/100, h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)
            }
            
            plot(p.out)
        })
    }, width=600, height=400, res=100)
    
    ################################################################################################## TABLE HELP TEXT + TITLE
    
    output$table_title <- renderUI({
        if (v$doAnalysis == FALSE) return()
        
        isolate({
            incidence_rate <- ifelse(input$tabset == "Power", input$power_p, input$ss_p)
            sample_size <- if(input$tabset == "Power"){
                input$power_n
            }
            else {
                pwr.p.test(sig.level=0.05, power=input$ss_power/100, h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }
            text1 <- hr()
            text2 <- h5("In addition, if ", ceiling(sample_size), " participants are included, the event rate would be estimated to an accuracy shown in the table below:")
            text3 <- h4(paste0("95% Confidence Interval around expected event rate(s) with a sample size of ", ceiling(sample_size), " participants."))
            HTML(paste0(text1, text2, text3))
        })
    })
    
    ################################################################################################## SAMPLE SIZE BY INCIDENCE RATE TABLE CONTENTS
    
    output$result_table <- renderDataTable({
        if (v$doAnalysis == FALSE) return()
        
        isolate({
            sample_size <- if(input$tabset == "Power"){
                input$power_n
            }
            else {
                pwr.p.test(sig.level=0.05, power=input$ss_power/100, h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }
            sequence <- unique(c(seq(0, 5), seq(10, 25, by=5), seq(50, min(round(sample_size, 0), 1000), by=50), seq(min(round(sample_size, 0), 1000), min(round(sample_size, 0), 10000), by=1000)))
            bb <- lapply(sequence, function(n) {
                binom.confint(n, sample_size, conf.level = 0.95, methods = "exact")
            })
            
            table <- do.call(rbind, bb)
            table$length <- table$upper - table$lower
            var <- c("mean", "lower", "upper", "length")
            for (i in var) {
                table[, i] <- round(table[, i]*100, 1)
            }
            table <- table[, c(2,4:7)]
            table
        })
    },
    options = list(columns = list(
        list(title = 'Number of Events Observed'),
        list(title = 'Event Rate<sup>1</sup>'),
        list(title = 'Lower Limit<sup>2</sup>'),
        list(title = 'Upper Limit<sup>2</sup>'),
        list(title = 'Length')
    ), paging=TRUE, searching=FALSE, processing=FALSE)
    )
    
    ################################################################################################## TABLE FOOTER
    
    output$table_footnotes <- renderUI({
        if (v$doAnalysis == FALSE) return()
        
        isolate({
            text1 <- h6("(1) Event rate (%) is estimated as a crude rate, defined as the number of participants exposed and experiencing the event of interest divided by the total number of participants.")
            text2 <- h6("(2) Confidence interval (%) based on exact Clopper-Pearson exact method for one proportion.")
            HTML(paste0(text1, text2))
        })
    })
    
    ################################################################################################## DOWNLOAD / SAVE ANALYSIS AS PDF
    
    output$download_button <- renderUI({
        if (v$doAnalysis == FALSE) return()
        isolate({
            text1 <- hr()
            text2 <- downloadButton('report', "Download Analysis [Experimental]")
            text3 <- hr()
            HTML(paste0(text1, " ", text2, " ", text3))
        })
    })
    
    output$report <- downloadHandler(
        filename = paste('Rule-of-3-Anlaysis-', Sys.Date(), '.pdf', sep=''),
        content = function(file) {
            incidence_rate <- ifelse(input$tabset == "Power", input$power_p, input$ss_p)
            sample_size <- if(input$tabset == "Power"){
                input$power_n
            }
            else {
                pwr.p.test(sig.level=0.05, power=input$ss_power/100, h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }
            
            power <- if(input$tabset == "Power"){
                pwr.p.test(sig.level=0.05, power=NULL, h = ES.h(1/input$power_p, 0), alt="greater", n = input$power_n)$power
            }
            else {
                input$ss_power/100
            }
            
            discon <- if(input$tabset == "Power"){
                input$power_discon/100
            }
            else {
                input$ss_discon/100
            }
            
            # Copy the report file to a temporary directory before processing it, in
            # case we don't have write permissions to the current working dir (which
            # can happen when deployed).
            tempReport <- file.path(tempdir(), "analysis-report.Rmd")
            file.copy("analysis-report.Rmd", tempReport, overwrite = TRUE)
            
            # Create a Progress object
            progress <- shiny::Progress$new(style = "notification")
            # Make sure it closes when we exit this reactive, even if there's an error
            on.exit(progress$close())
            progress$set(message = "Creating Analysis Report File", value = 0)
            
            # Set up parameters to pass to Rmd document
            params <- list(tabset         = input$tabset,
                           incidence_rate = incidence_rate,
                           sample_size    = sample_size,
                           power          = power,
                           discon         = discon,
                           adj_n          = 100,
                           progress       = progress)
            
            
            # Knit the document, passing in the `params` list, and eval it in a
            # child of the global environment (this isolates the code in the document
            # from the code in this app).
            rmarkdown::render(tempReport, output_file = file,
                              params = params,
                              envir = new.env(parent = globalenv())
            )
            # Increment the progress bar, and update the detail text.
            progress$inc(1/6, detail = "Done!")
        }
    )
}

# Run the application 
shinyApp(ui = ui, server = server)




# NOTES
# The function tells us we should flip the coin 22.55127 times, which we round up to 23. Always round sample size estimates up. If we’re correct that our coin lands heads 75% of the time, we need to flip it at least 23 times to have an 80% chance of correctly rejecting the null hypothesis at the 0.05 significance level.
# 
# Notice that since we wanted to determine sample size (n), we left it out of the function. Our effect size is entered in the h argument. The label h is due to Cohen (1988). The function ES.h is used to calculate a unitless effect size using the arcsine transformation. (More on effect size below.) sig.level is the argument for our desired significance level. This is also sometimes referred to as our tolerance for a Type I error (α). power is our desired power. It is sometimes referred to as 1 - β, where β is Type II error. The alternative argument says we think the alternative is “greater” than the null, not just different.
# 
# Type I error, α, is the probability of rejecting the null hypothesis when it is true. This is thinking we have found an effect where none exist. This is considered the more serious error. Our tolerance for Type I error is usually 0.05 or lower.
# 
# Type II error, β, is the probability of failing to reject the null hypothesis when it is false. This is thinking there is no effect when in fact there is. Our tolerance for Type II error is usually 0.20 or lower. Type II error is 1 - Power. If we desire a power of 0.90, then we implicitly specify a Type II error tolerance of 0.10.
# 
# The pwr package provides a generic plot function that allows us to see how power changes as we change our sample size. If you have the ggplot2 package installed, it will create a plot using ggplot. Otherwise base R graphics are used.