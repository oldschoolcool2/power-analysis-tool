# https://blogs.bmj.com/bmjebmspotlight/2017/11/14/rare-adverse-events-clinical-trials-understanding-rule-three/

# Enable reactive logging for debugging (press Ctrl+F3 or Cmd+F3 in browser)
if (interactive()) {
    options(shiny.reactlog = TRUE)
}

library(shiny)
library(bslib)
library(shinyBS)
library(pwr)
library(binom)
library(kableExtra)
library(tinytex)
library(powerSurvEpi)
library(epiR)

# Define UI
ui <- fluidPage(
    # Modern bslib theme for mobile responsiveness
    theme = bs_theme(
        version = 5,
        bootswatch = "cosmo",
        primary = "#3498db",
        base_font = font_google("Open Sans"),
        heading_font = font_google("Montserrat")
    ),

    # Application title
    titlePanel("Statistical Power Analysis Tool for Real-World Evidence"),

    # Sidebar with inputs
    sidebarLayout(
        sidebarPanel(
            tabsetPanel(id = "tabset",
                        # TAB 1: Single Proportion Power
                        tabPanel("Power (Single)",
                                 h4("Single Proportion Analysis"),
                                 helpText("Calculate power for detecting a single event rate (e.g., post-marketing surveillance)"),
                                 hr(),
                                 numericInput("power_n", "Available Sample Size:", 230, min = 1, step = 1),
                                 bsTooltip("power_n", "Total number of participants available for the study", "right"),

                                 numericInput("power_p", "Event Frequency (1 in x):", 100, min = 1, step = 1),
                                 bsTooltip("power_p", "Expected frequency of the event. E.g., 100 means 1 event per 100 participants", "right"),

                                 sliderInput("power_discon", "Withdrawal/Discontinuation Rate (%):", min = 0, max = 50, value = 10, step = 1),
                                 bsTooltip("power_discon", "Expected percentage of participants who will withdraw or discontinue", "right"),

                                 sliderInput("power_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("power_alpha", "Type I error rate (typically 0.05). Lower values are more conservative.", "right"),
                                 hr(),
                                 actionButton("example_power_single", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_power_single", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 2: Single Proportion Sample Size
                        tabPanel("Sample Size (Single)",
                                 h4("Single Proportion Analysis"),
                                 helpText("Calculate required sample size to achieve desired power"),
                                 hr(),
                                 sliderInput("ss_power", "Desired Power (%):", min = 50, max = 99, value = 80, step = 1),
                                 bsTooltip("ss_power", "Probability of detecting the effect if it exists (typically 80% or 90%)", "right"),

                                 numericInput("ss_p", "Event Frequency (1 in x):", 100, min = 1, step = 1),
                                 bsTooltip("ss_p", "Expected frequency of the event. E.g., 100 means 1 event per 100 participants", "right"),

                                 sliderInput("ss_discon", "Withdrawal/Discontinuation Rate (%):", min = 0, max = 50, value = 10, step = 1),
                                 bsTooltip("ss_discon", "Expected percentage of participants who will withdraw or discontinue", "right"),

                                 sliderInput("ss_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("ss_alpha", "Type I error rate (typically 0.05). Lower values are more conservative.", "right"),
                                 hr(),
                                 actionButton("example_ss_single", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_ss_single", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 3: Two-Group Power
                        tabPanel("Power (Two-Group)",
                                 h4("Two-Group Comparison"),
                                 helpText("Calculate power for comparing two proportions (e.g., exposed vs. unexposed in cohort studies)"),
                                 hr(),
                                 numericInput("twogrp_pow_n1", "Sample Size Group 1:", 200, min = 1, step = 1),
                                 numericInput("twogrp_pow_n2", "Sample Size Group 2:", 200, min = 1, step = 1),
                                 bsTooltip("twogrp_pow_n1", "Number of participants in exposed/treatment group", "right"),
                                 bsTooltip("twogrp_pow_n2", "Number of participants in unexposed/control group", "right"),

                                 numericInput("twogrp_pow_p1", "Event Rate Group 1 (%):", 10, min = 0, max = 100, step = 0.1),
                                 numericInput("twogrp_pow_p2", "Event Rate Group 2 (%):", 5, min = 0, max = 100, step = 0.1),
                                 bsTooltip("twogrp_pow_p1", "Expected event rate in exposed/treatment group (as percentage)", "right"),
                                 bsTooltip("twogrp_pow_p2", "Expected event rate in unexposed/control group (as percentage)", "right"),

                                 sliderInput("twogrp_pow_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("twogrp_pow_alpha", "Type I error rate (typically 0.05)", "right"),

                                 radioButtons("twogrp_pow_sided", "Test Type:",
                                             choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
                                             selected = "two.sided"),
                                 bsTooltip("twogrp_pow_sided", "Two-sided: test if groups differ. One-sided: test if Group 1 > Group 2", "right"),
                                 hr(),
                                 actionButton("example_twogrp_pow", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_twogrp_pow", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 4: Two-Group Sample Size
                        tabPanel("Sample Size (Two-Group)",
                                 h4("Two-Group Comparison"),
                                 helpText("Calculate required sample size per group to achieve desired power"),
                                 hr(),
                                 sliderInput("twogrp_ss_power", "Desired Power (%):", min = 50, max = 99, value = 80, step = 1),
                                 bsTooltip("twogrp_ss_power", "Probability of detecting the effect if it exists", "right"),

                                 numericInput("twogrp_ss_p1", "Event Rate Group 1 (%):", 10, min = 0, max = 100, step = 0.1),
                                 numericInput("twogrp_ss_p2", "Event Rate Group 2 (%):", 5, min = 0, max = 100, step = 0.1),
                                 bsTooltip("twogrp_ss_p1", "Expected event rate in exposed/treatment group (as percentage)", "right"),
                                 bsTooltip("twogrp_ss_p2", "Expected event rate in unexposed/control group (as percentage)", "right"),

                                 numericInput("twogrp_ss_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1),
                                 bsTooltip("twogrp_ss_ratio", "Ratio of Group 2 to Group 1 sample size. 1 = equal groups, 2 = twice as many in Group 2", "right"),

                                 sliderInput("twogrp_ss_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("twogrp_ss_alpha", "Type I error rate (typically 0.05)", "right"),

                                 radioButtons("twogrp_ss_sided", "Test Type:",
                                             choices = c("Two-sided" = "two.sided", "One-sided" = "greater"),
                                             selected = "two.sided"),
                                 hr(),
                                 actionButton("example_twogrp_ss", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_twogrp_ss", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 5: Survival Analysis Power
                        tabPanel("Power (Survival)",
                                 h4("Survival Analysis (Cox Regression)"),
                                 helpText("Calculate power for time-to-event outcomes using Cox regression (common in RWE studies)"),
                                 hr(),
                                 numericInput("surv_pow_n", "Total Sample Size:", 500, min = 10, step = 10),
                                 bsTooltip("surv_pow_n", "Total number of participants in the study", "right"),

                                 numericInput("surv_pow_hr", "Hazard Ratio (HR):", 0.7, min = 0.01, max = 10, step = 0.05),
                                 bsTooltip("surv_pow_hr", "Expected hazard ratio (HR < 1 indicates protective effect, HR > 1 indicates risk)", "right"),

                                 sliderInput("surv_pow_k", "Proportion Exposed (%):", min = 10, max = 90, value = 50, step = 5),
                                 bsTooltip("surv_pow_k", "Proportion of participants in the exposed/treatment group", "right"),

                                 sliderInput("surv_pow_pE", "Overall Event Rate (%):", min = 5, max = 95, value = 30, step = 5),
                                 bsTooltip("surv_pow_pE", "Expected proportion of participants experiencing the event during follow-up", "right"),

                                 sliderInput("surv_pow_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("surv_pow_alpha", "Type I error rate (typically 0.05)", "right"),
                                 hr(),
                                 actionButton("example_surv_pow", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_surv_pow", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 6: Survival Analysis Sample Size
                        tabPanel("Sample Size (Survival)",
                                 h4("Survival Analysis (Cox Regression)"),
                                 helpText("Calculate required sample size for time-to-event analysis"),
                                 hr(),
                                 sliderInput("surv_ss_power", "Desired Power (%):", min = 50, max = 99, value = 80, step = 1),
                                 bsTooltip("surv_ss_power", "Probability of detecting the effect if it exists", "right"),

                                 numericInput("surv_ss_hr", "Hazard Ratio (HR):", 0.7, min = 0.01, max = 10, step = 0.05),
                                 bsTooltip("surv_ss_hr", "Expected hazard ratio to detect", "right"),

                                 sliderInput("surv_ss_k", "Proportion Exposed (%):", min = 10, max = 90, value = 50, step = 5),
                                 bsTooltip("surv_ss_k", "Proportion of participants in the exposed/treatment group", "right"),

                                 sliderInput("surv_ss_pE", "Overall Event Rate (%):", min = 5, max = 95, value = 30, step = 5),
                                 bsTooltip("surv_ss_pE", "Expected proportion of participants experiencing the event during follow-up", "right"),

                                 sliderInput("surv_ss_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("surv_ss_alpha", "Type I error rate (typically 0.05)", "right"),
                                 hr(),
                                 actionButton("example_surv_ss", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_surv_ss", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 7: Matched Case-Control
                        tabPanel("Matched Case-Control",
                                 h4("Matched Case-Control Study"),
                                 helpText("Calculate sample size for matched case-control studies (e.g., propensity score matching)"),
                                 hr(),
                                 sliderInput("match_power", "Desired Power (%):", min = 50, max = 99, value = 80, step = 1),
                                 bsTooltip("match_power", "Probability of detecting the effect if it exists", "right"),

                                 numericInput("match_or", "Odds Ratio (OR):", 2.0, min = 0.01, max = 20, step = 0.1),
                                 bsTooltip("match_or", "Expected odds ratio to detect (OR < 1 protective, OR > 1 risk factor)", "right"),

                                 sliderInput("match_p0", "Exposure Probability in Controls (%):", min = 5, max = 95, value = 20, step = 5),
                                 bsTooltip("match_p0", "Expected proportion of controls exposed to the risk factor", "right"),

                                 numericInput("match_ratio", "Controls per Case:", 1, min = 1, max = 5, step = 1),
                                 bsTooltip("match_ratio", "Number of matched controls per case (typically 1:1, 2:1, or 3:1)", "right"),

                                 sliderInput("match_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("match_alpha", "Type I error rate (typically 0.05)", "right"),

                                 radioButtons("match_sided", "Test Type:",
                                             choices = c("Two-sided" = "two.sided", "One-sided" = "one.sided"),
                                             selected = "two.sided"),
                                 bsTooltip("match_sided", "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
                                 hr(),
                                 actionButton("example_match", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_match", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 8: Continuous Outcomes - Power (TIER 4)
                        tabPanel("Power (Continuous)",
                                 h4("Continuous Outcomes (t-test)"),
                                 helpText("Calculate power for comparing means between two groups (e.g., BMI, blood pressure, QoL scores)"),
                                 hr(),
                                 numericInput("cont_pow_n1", "Sample Size Group 1:", 100, min = 2, step = 1),
                                 numericInput("cont_pow_n2", "Sample Size Group 2:", 100, min = 2, step = 1),
                                 bsTooltip("cont_pow_n1", "Number of participants in treatment/exposed group", "right"),
                                 bsTooltip("cont_pow_n2", "Number of participants in control/unexposed group", "right"),

                                 numericInput("cont_pow_d", "Effect Size (Cohen's d):", 0.5, min = 0.01, max = 5, step = 0.1),
                                 bsTooltip("cont_pow_d", "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8", "right"),

                                 sliderInput("cont_pow_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("cont_pow_alpha", "Type I error rate (typically 0.05)", "right"),

                                 radioButtons("cont_pow_sided", "Test Type:",
                                             choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
                                             selected = "two.sided"),
                                 bsTooltip("cont_pow_sided", "Two-sided: test if groups differ. One-sided: test directional hypothesis", "right"),
                                 hr(),
                                 actionButton("example_cont_pow", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_cont_pow", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 9: Continuous Outcomes - Sample Size (TIER 4)
                        tabPanel("Sample Size (Continuous)",
                                 h4("Continuous Outcomes (t-test)"),
                                 helpText("Calculate required sample size to detect a difference in means"),
                                 hr(),
                                 sliderInput("cont_ss_power", "Desired Power (%):", min = 50, max = 99, value = 80, step = 1),
                                 bsTooltip("cont_ss_power", "Probability of detecting the effect if it exists", "right"),

                                 numericInput("cont_ss_d", "Effect Size (Cohen's d):", 0.5, min = 0.01, max = 5, step = 0.1),
                                 bsTooltip("cont_ss_d", "Standardized mean difference: Small=0.2, Medium=0.5, Large=0.8", "right"),

                                 numericInput("cont_ss_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1),
                                 bsTooltip("cont_ss_ratio", "Ratio of Group 2 to Group 1 sample size. 1 = equal groups", "right"),

                                 sliderInput("cont_ss_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.05, step = 0.01),
                                 bsTooltip("cont_ss_alpha", "Type I error rate (typically 0.05)", "right"),

                                 radioButtons("cont_ss_sided", "Test Type:",
                                             choices = c("Two-sided" = "two.sided", "One-sided (greater)" = "greater", "One-sided (less)" = "less"),
                                             selected = "two.sided"),
                                 hr(),
                                 actionButton("example_cont_ss", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_cont_ss", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        ),

                        # TAB 10: Non-Inferiority Testing (TIER 4)
                        tabPanel("Non-Inferiority",
                                 h4("Non-Inferiority Testing"),
                                 helpText("Calculate sample size for non-inferiority trials (common in generic/biosimilar studies)"),
                                 hr(),
                                 sliderInput("noninf_power", "Desired Power (%):", min = 50, max = 99, value = 80, step = 1),
                                 bsTooltip("noninf_power", "Probability of demonstrating non-inferiority if true", "right"),

                                 numericInput("noninf_p1", "Event Rate Test Group (%):", 10, min = 0, max = 100, step = 0.1),
                                 numericInput("noninf_p2", "Event Rate Reference Group (%):", 10, min = 0, max = 100, step = 0.1),
                                 bsTooltip("noninf_p1", "Expected event rate in test/generic group (as percentage)", "right"),
                                 bsTooltip("noninf_p2", "Expected event rate in reference/branded group (as percentage)", "right"),

                                 numericInput("noninf_margin", "Non-Inferiority Margin (%):", 5, min = 0.1, max = 50, step = 0.5),
                                 bsTooltip("noninf_margin", "Maximum clinically acceptable difference (percentage points). Test is non-inferior if difference < margin.", "right"),

                                 numericInput("noninf_ratio", "Allocation Ratio (n2/n1):", 1, min = 0.1, max = 10, step = 0.1),
                                 bsTooltip("noninf_ratio", "Ratio of Reference to Test group size. 1 = equal groups", "right"),

                                 sliderInput("noninf_alpha", "Significance Level (α):", min = 0.01, max = 0.10, value = 0.025, step = 0.005),
                                 bsTooltip("noninf_alpha", "Type I error rate (typically 0.025 for one-sided non-inferiority test)", "right"),
                                 hr(),
                                 actionButton("example_noninf", "Load Example", icon = icon("lightbulb"), class = "btn-info btn-sm"),
                                 actionButton("reset_noninf", "Reset", icon = icon("refresh"), class = "btn-secondary btn-sm")
                        )
            ),
            hr(),
            actionButton("go", "Calculate", class = "btn-primary btn-lg"),
            hr(),
            # Scenario comparison buttons
            conditionalPanel(
                condition = "output.show_results",
                actionButton("save_scenario", "Save Current Scenario", class = "btn-success"),
                bsTooltip("save_scenario", "Save this analysis to compare with other scenarios", "right"),
                br(), br(),
                actionButton("clear_scenarios", "Clear Saved Scenarios", class = "btn-warning"),
                conditionalPanel(
                    condition = "output.has_scenarios",
                    br(), br(),
                    downloadButton("download_comparison", "Download Scenario Comparison (CSV)")
                )
            )
        ),

        # Main panel with results
        mainPanel(
            h1("About this tool"),
            p("This tool provides power and sample size calculations for epidemiological studies, with a focus on real-world evidence (RWE) applications in pharmaceutical research. Use the sidebar tabs to select your study design and fill in the parameters."),

            # Collapsible help sections using accordion
            accordion(
                id = "help_accordion",
                multiple = TRUE,
                accordion_panel(
                    title = "Single Proportion Analysis (Rule of Three)",
                    icon = icon("info-circle"),
                    p("The 'Rule of Three' states that if a certain event did not occur in a sample with n participants, the interval from 0 to 3/n is a 95% confidence interval for the rate of occurrences in the population. When n is greater than 30, this is a good approximation."),
                    p(strong("Example:"), "If a drug is tested on 1,500 participants and no adverse event is recorded, we can conclude with 95% confidence that fewer than 1 person in 500 (or 3/1500 = 0.2%) will experience an adverse event."),
                    p(strong("Use cases:"), "Post-marketing surveillance, rare adverse event detection, safety studies."),
                    p(a("Learn more in Hanley & Lippman-Hand (1983)", href = "Hanley-1983-1743.pdf", target = "_blank"))
                ),

                accordion_panel(
                    title = "Two-Group Comparisons",
                    icon = icon("users"),
                    p("For comparative effectiveness research and observational studies, use the Two-Group tabs to compare event rates between exposed/unexposed groups or treatment/control groups."),
                    p(strong("Study designs:"), "Cohort studies (prospective or retrospective), comparative effectiveness studies, RCTs."),
                    p(strong("Effect measures:"), "The tool calculates Risk Difference, Relative Risk (RR), and Odds Ratio (OR) to help interpret clinical significance."),
                    p(strong("Example:"), "Comparing hospitalization rates between patients prescribed Drug A vs. Drug B using claims data.")
                ),

                accordion_panel(
                    title = "Survival Analysis (Cox Regression)",
                    icon = icon("chart-line"),
                    p("Survival analysis is used for time-to-event outcomes, which are extremely common in pharmaceutical RWE studies (e.g., time to hospitalization, time to disease progression, time to death)."),
                    p(strong("Method:"), "Uses the Schoenfeld (1983) method for Cox proportional hazards regression, implemented in the powerSurvEpi R package."),
                    p(strong("Key inputs:"), "Hazard Ratio (HR), proportion exposed, overall event rate during follow-up."),
                    p(strong("Example:"), "Estimating sample size to detect a 30% reduction in risk of cardiovascular events (HR = 0.7) in a cohort study.")
                ),

                accordion_panel(
                    title = "Matched Case-Control Studies",
                    icon = icon("link"),
                    p("The Matched Case-Control tab provides sample size calculations for studies using matching strategies, such as propensity score matching or traditional case-control matching."),
                    p(strong("When to use:"), "When cases and controls are matched on confounding variables (age, sex, comorbidities, etc.)."),
                    p(strong("Matching ratios:"), "Supports 1:1, 2:1, 3:1, or higher matching ratios (controls per case)."),
                    p(strong("Example:"), "Matched case-control study examining association between statin use and liver injury, matching on age, sex, and diabetes status.")
                ),

                accordion_panel(
                    title = "Continuous Outcomes (TIER 4 - NEW!)",
                    icon = icon("calculator"),
                    p("The Continuous Outcomes tabs handle power and sample size calculations for comparing continuous endpoints between two groups using two-sample t-tests."),
                    p(strong("Use cases:"), "Comparisons involving continuous measures such as BMI, blood pressure, lab values (HbA1c, cholesterol), quality of life scores, cognitive function tests, and biomarker levels."),
                    p(strong("Effect size (Cohen's d):"), "Standardized mean difference. Conventionally: Small = 0.2, Medium = 0.5, Large = 0.8. Calculate as (mean1 - mean2) / pooled_SD."),
                    p(strong("Example:"), "Comparing mean HbA1c reduction between two diabetes medications in an RWE study using EHR data.")
                ),

                accordion_panel(
                    title = "Non-Inferiority Testing (TIER 4 - NEW!)",
                    icon = icon("balance-scale"),
                    p("Non-inferiority trials aim to demonstrate that a new treatment is 'not worse' than a reference treatment by more than a pre-specified margin. This is common in generic drug approval, biosimilar studies, and situations where superiority is not expected or ethical."),
                    p(strong("Non-inferiority margin:"), "The maximum clinically acceptable difference in outcomes. Should be based on clinical judgment and regulatory guidance. Typically smaller than expected treatment effect of reference."),
                    p(strong("Regulatory context:"), "FDA/EMA require pre-specification of non-inferiority margin with clinical justification. One-sided α=0.025 (equivalent to two-sided α=0.05) is standard."),
                    p(strong("Example:"), "Demonstrating a generic formulation has adverse event rates no worse than branded drug +5 percentage points.")
                ),

                accordion_panel(
                    title = "Regulatory Guidance & References",
                    icon = icon("book"),
                    h5("FDA/EMA Guidance on RWE"),
                    tags$ul(
                        tags$li(a("FDA - Real-World Evidence Framework",
                                href = "https://www.fda.gov/science-research/science-and-research-special-topics/real-world-evidence",
                                target = "_blank")),
                        tags$li(a("FDA - Use of Real-World Evidence (2023)",
                                href = "https://www.fda.gov/regulatory-information/search-fda-guidance-documents/real-world-data-assessing-electronic-health-records-and-medical-claims-data-support-regulatory",
                                target = "_blank")),
                        tags$li(a("EMA - Real World Evidence Framework",
                                href = "https://www.ema.europa.eu/en/about-us/how-we-work/big-data/real-world-evidence",
                                target = "_blank"))
                    ),
                    h5("Key Statistical References"),
                    tags$ul(
                        tags$li("Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745."),
                        tags$li("Schoenfeld DA. Sample-size formula for the proportional-hazards regression model. Biometrics. 1983;39(2):499-503."),
                        tags$li("Cohen J. Statistical Power Analysis for the Behavioral Sciences. 2nd ed. Routledge; 1988."),
                        tags$li("Lachin JM. Introduction to sample size determination and power analysis for clinical trials. Control Clin Trials. 1981;2(2):93-113.")
                    )
                ),

                accordion_panel(
                    title = "Interpretation Guide",
                    icon = icon("question-circle"),
                    h5("Understanding Power"),
                    p("Power is the probability of detecting a true effect when it exists. Conventionally:"),
                    tags$ul(
                        tags$li(strong("80% power:"), "Standard for most studies"),
                        tags$li(strong("90% power:"), "Preferred for pivotal or confirmatory studies"),
                        tags$li(strong("<70% power:"), "Generally considered inadequate")
                    ),
                    h5("Understanding Significance Level (α)"),
                    tags$ul(
                        tags$li(strong("α = 0.05:"), "Standard for most studies (5% false positive rate)"),
                        tags$li(strong("α = 0.01:"), "More conservative, used for multiple testing or critical decisions"),
                        tags$li(strong("α = 0.10:"), "Sometimes used in exploratory studies")
                    ),
                    h5("Effect Sizes"),
                    tags$ul(
                        tags$li(strong("Hazard Ratio (HR):"), "HR < 1 = protective, HR > 1 = increased risk, HR = 1 = no effect"),
                        tags$li(strong("Odds Ratio (OR):"), "Similar interpretation to HR for rare outcomes"),
                        tags$li(strong("Relative Risk (RR):"), "More intuitive than OR; directly interpretable as relative increase/decrease in risk")
                    )
                )
            ),

            hr(),

            # Live preview (debounced)
            uiOutput('live_preview'),

            # Results section
            uiOutput('result_text'),
            uiOutput('effect_measures'),
            uiOutput('figure_title'),
            plotOutput('power_plot'),
            uiOutput('table_title'),
            dataTableOutput('result_table'),
            uiOutput('table_footnotes'),
            uiOutput('download_buttons'),

            # Scenario comparison section
            uiOutput('scenario_comparison')
        )
    )
)

# Define server logic
server <- function(input, output, session) {

    # Helper function: safely calculate effect measures (avoid division by zero)
    calc_effect_measures <- function(p1, p2) {
        risk_diff <- (p1 - p2) * 100

        # Relative Risk: undefined when p2 = 0
        relative_risk <- if (p2 == 0) NA_real_ else p1 / p2

        # Odds Ratio: undefined when either rate is 0% or 100%
        odds1 <- if (p1 %in% c(0, 1)) NA_real_ else p1 / (1 - p1)
        odds2 <- if (p2 %in% c(0, 1)) NA_real_ else p2 / (1 - p2)
        odds_ratio <- if (is.na(odds1) || is.na(odds2)) NA_real_ else odds1 / odds2

        list(
            risk_diff = risk_diff,
            relative_risk = relative_risk,
            odds_ratio = odds_ratio
        )
    }

    # Helper function: solve for n1 given allocation ratio (for unequal groups)
    solve_n1_for_ratio <- function(h, ratio, sig.level, power, alternative) {
        f <- function(n1) {
            n2 <- n1 * ratio
            pwr.2p2n.test(h = h, n1 = n1, n2 = n2, sig.level = sig.level,
                         alternative = alternative)$power - power
        }
        tryCatch({
            uniroot(f, c(2, 1e6), extendInt = "yes")$root
        }, error = function(e) {
            # Fallback to equal-n approximation if root-finding fails
            warning("Root-finding failed; using equal-n approximation")
            pwr.2p.test(h = h, sig.level = sig.level, power = power, alternative = alternative)$n
        })
    }

    # Reactive values for tracking state
    v <- reactiveValues(
        doAnalysis = FALSE,
        scenarios = data.frame(),
        scenario_counter = 0
    )

    # Show results flag
    output$show_results <- reactive({
        v$doAnalysis != FALSE
    })
    outputOptions(output, "show_results", suspendWhenHidden = FALSE)

    # Has scenarios flag
    output$has_scenarios <- reactive({
        nrow(v$scenarios) > 0
    })
    outputOptions(output, "has_scenarios", suspendWhenHidden = FALSE)

    # Trigger analysis
    observeEvent(input$go, {
        v$doAnalysis <- input$go
    })

    # Reset analysis when switching tabs
    observeEvent(input$tabset, {
        v$doAnalysis <- FALSE
    })

    # Example button handlers - load common scenarios
    observeEvent(input$example_power_single, {
        updateNumericInput(session, "power_n", value = 1500)
        updateNumericInput(session, "power_p", value = 500)
        updateSliderInput(session, "power_discon", value = 15)
        updateSliderInput(session, "power_alpha", value = 0.05)
        showNotification("Example loaded: Rare adverse event study with 1,500 participants", type = "message", duration = 3)
    })

    observeEvent(input$example_ss_single, {
        updateSliderInput(session, "ss_power", value = 90)
        updateNumericInput(session, "ss_p", value = 200)
        updateSliderInput(session, "ss_discon", value = 10)
        updateSliderInput(session, "ss_alpha", value = 0.05)
        showNotification("Example loaded: Sample size for rare event (1 in 200)", type = "message", duration = 3)
    })

    observeEvent(input$example_twogrp_pow, {
        updateNumericInput(session, "twogrp_pow_n1", value = 500)
        updateNumericInput(session, "twogrp_pow_n2", value = 500)
        updateNumericInput(session, "twogrp_pow_p1", value = 15)
        updateNumericInput(session, "twogrp_pow_p2", value = 10)
        updateSliderInput(session, "twogrp_pow_alpha", value = 0.05)
        showNotification("Example loaded: Cohort study comparing 15% vs 10% event rates", type = "message", duration = 3)
    })

    observeEvent(input$example_twogrp_ss, {
        updateSliderInput(session, "twogrp_ss_power", value = 80)
        updateNumericInput(session, "twogrp_ss_p1", value = 20)
        updateNumericInput(session, "twogrp_ss_p2", value = 15)
        updateNumericInput(session, "twogrp_ss_ratio", value = 1)
        updateSliderInput(session, "twogrp_ss_alpha", value = 0.05)
        showNotification("Example loaded: Sample size for 20% vs 15% comparison", type = "message", duration = 3)
    })

    observeEvent(input$example_surv_pow, {
        updateNumericInput(session, "surv_pow_n", value = 800)
        updateNumericInput(session, "surv_pow_hr", value = 0.75)
        updateSliderInput(session, "surv_pow_k", value = 50)
        updateSliderInput(session, "surv_pow_pE", value = 40)
        updateSliderInput(session, "surv_pow_alpha", value = 0.05)
        showNotification("Example loaded: Survival study with HR=0.75 and 40% event rate", type = "message", duration = 3)
    })

    observeEvent(input$example_surv_ss, {
        updateSliderInput(session, "surv_ss_power", value = 85)
        updateNumericInput(session, "surv_ss_hr", value = 0.70)
        updateSliderInput(session, "surv_ss_k", value = 50)
        updateSliderInput(session, "surv_ss_pE", value = 35)
        updateSliderInput(session, "surv_ss_alpha", value = 0.05)
        showNotification("Example loaded: Sample size for survival analysis (HR=0.70)", type = "message", duration = 3)
    })

    observeEvent(input$example_match, {
        updateSliderInput(session, "match_power", value = 80)
        updateNumericInput(session, "match_or", value = 2.5)
        updateSliderInput(session, "match_p0", value = 25)
        updateNumericInput(session, "match_ratio", value = 2)
        updateSliderInput(session, "match_alpha", value = 0.05)
        showNotification("Example loaded: 2:1 matched case-control with OR=2.5", type = "message", duration = 3)
    })

    # Reset button handlers - restore defaults
    observeEvent(input$reset_power_single, {
        updateNumericInput(session, "power_n", value = 230)
        updateNumericInput(session, "power_p", value = 100)
        updateSliderInput(session, "power_discon", value = 10)
        updateSliderInput(session, "power_alpha", value = 0.05)
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    observeEvent(input$reset_ss_single, {
        updateSliderInput(session, "ss_power", value = 80)
        updateNumericInput(session, "ss_p", value = 100)
        updateSliderInput(session, "ss_discon", value = 10)
        updateSliderInput(session, "ss_alpha", value = 0.05)
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    observeEvent(input$reset_twogrp_pow, {
        updateNumericInput(session, "twogrp_pow_n1", value = 200)
        updateNumericInput(session, "twogrp_pow_n2", value = 200)
        updateNumericInput(session, "twogrp_pow_p1", value = 10)
        updateNumericInput(session, "twogrp_pow_p2", value = 5)
        updateSliderInput(session, "twogrp_pow_alpha", value = 0.05)
        updateRadioButtons(session, "twogrp_pow_sided", selected = "two.sided")
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    observeEvent(input$reset_twogrp_ss, {
        updateSliderInput(session, "twogrp_ss_power", value = 80)
        updateNumericInput(session, "twogrp_ss_p1", value = 10)
        updateNumericInput(session, "twogrp_ss_p2", value = 5)
        updateNumericInput(session, "twogrp_ss_ratio", value = 1)
        updateSliderInput(session, "twogrp_ss_alpha", value = 0.05)
        updateRadioButtons(session, "twogrp_ss_sided", selected = "two.sided")
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    observeEvent(input$reset_surv_pow, {
        updateNumericInput(session, "surv_pow_n", value = 500)
        updateNumericInput(session, "surv_pow_hr", value = 0.7)
        updateSliderInput(session, "surv_pow_k", value = 50)
        updateSliderInput(session, "surv_pow_pE", value = 30)
        updateSliderInput(session, "surv_pow_alpha", value = 0.05)
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    observeEvent(input$reset_surv_ss, {
        updateSliderInput(session, "surv_ss_power", value = 80)
        updateNumericInput(session, "surv_ss_hr", value = 0.7)
        updateSliderInput(session, "surv_ss_k", value = 50)
        updateSliderInput(session, "surv_ss_pE", value = 30)
        updateSliderInput(session, "surv_ss_alpha", value = 0.05)
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    observeEvent(input$reset_match, {
        updateSliderInput(session, "match_power", value = 80)
        updateNumericInput(session, "match_or", value = 2.0)
        updateSliderInput(session, "match_p0", value = 20)
        updateNumericInput(session, "match_ratio", value = 1)
        updateSliderInput(session, "match_alpha", value = 0.05)
        updateRadioButtons(session, "match_sided", selected = "two.sided")
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    # Example/Reset for Continuous Outcomes Power (TIER 4)
    observeEvent(input$example_cont_pow, {
        updateNumericInput(session, "cont_pow_n1", value = 150)
        updateNumericInput(session, "cont_pow_n2", value = 150)
        updateNumericInput(session, "cont_pow_d", value = 0.5)
        updateSliderInput(session, "cont_pow_alpha", value = 0.05)
        updateRadioButtons(session, "cont_pow_sided", selected = "two.sided")
        showNotification("Example loaded: Continuous outcome comparison (Cohen's d=0.5, n=150 per group)", type = "message", duration = 3)
    })

    observeEvent(input$reset_cont_pow, {
        updateNumericInput(session, "cont_pow_n1", value = 100)
        updateNumericInput(session, "cont_pow_n2", value = 100)
        updateNumericInput(session, "cont_pow_d", value = 0.5)
        updateSliderInput(session, "cont_pow_alpha", value = 0.05)
        updateRadioButtons(session, "cont_pow_sided", selected = "two.sided")
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    # Example/Reset for Continuous Outcomes Sample Size (TIER 4)
    observeEvent(input$example_cont_ss, {
        updateSliderInput(session, "cont_ss_power", value = 90)
        updateNumericInput(session, "cont_ss_d", value = 0.4)
        updateNumericInput(session, "cont_ss_ratio", value = 1)
        updateSliderInput(session, "cont_ss_alpha", value = 0.05)
        updateRadioButtons(session, "cont_ss_sided", selected = "two.sided")
        showNotification("Example loaded: Sample size for moderate effect (d=0.4, 90% power)", type = "message", duration = 3)
    })

    observeEvent(input$reset_cont_ss, {
        updateSliderInput(session, "cont_ss_power", value = 80)
        updateNumericInput(session, "cont_ss_d", value = 0.5)
        updateNumericInput(session, "cont_ss_ratio", value = 1)
        updateSliderInput(session, "cont_ss_alpha", value = 0.05)
        updateRadioButtons(session, "cont_ss_sided", selected = "two.sided")
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    # Example/Reset for Non-Inferiority (TIER 4)
    observeEvent(input$example_noninf, {
        updateSliderInput(session, "noninf_power", value = 85)
        updateNumericInput(session, "noninf_p1", value = 12)
        updateNumericInput(session, "noninf_p2", value = 10)
        updateNumericInput(session, "noninf_margin", value = 4)
        updateNumericInput(session, "noninf_ratio", value = 1)
        updateSliderInput(session, "noninf_alpha", value = 0.025)
        showNotification("Example loaded: Non-inferiority test with 4% margin (generic vs. branded)", type = "message", duration = 3)
    })

    observeEvent(input$reset_noninf, {
        updateSliderInput(session, "noninf_power", value = 80)
        updateNumericInput(session, "noninf_p1", value = 10)
        updateNumericInput(session, "noninf_p2", value = 10)
        updateNumericInput(session, "noninf_margin", value = 5)
        updateNumericInput(session, "noninf_ratio", value = 1)
        updateSliderInput(session, "noninf_alpha", value = 0.025)
        showNotification("Inputs reset to defaults", type = "warning", duration = 2)
    })

    # Validation function
    validate_inputs <- function() {
        if (input$tabset == "Power (Single)") {
            validate(
                need(input$power_n > 0, "Sample size must be positive"),
                need(input$power_p > 0, "Event frequency must be positive"),
                need(input$power_discon >= 0 && input$power_discon <= 100, "Discontinuation rate must be between 0 and 100%")
            )
        } else if (input$tabset == "Sample Size (Single)") {
            validate(
                need(input$ss_p > 0, "Event frequency must be positive"),
                need(input$ss_discon >= 0 && input$ss_discon <= 100, "Discontinuation rate must be between 0 and 100%")
            )
        } else if (input$tabset == "Power (Two-Group)") {
            validate(
                need(input$twogrp_pow_n1 > 0, "Sample size Group 1 must be positive"),
                need(input$twogrp_pow_n2 > 0, "Sample size Group 2 must be positive"),
                need(input$twogrp_pow_p1 >= 0 && input$twogrp_pow_p1 <= 100, "Event rate Group 1 must be between 0 and 100%"),
                need(input$twogrp_pow_p2 >= 0 && input$twogrp_pow_p2 <= 100, "Event rate Group 2 must be between 0 and 100%"),
                need(input$twogrp_pow_p1 != input$twogrp_pow_p2, "Event rates must be different to calculate power")
            )
        } else if (input$tabset == "Sample Size (Two-Group)") {
            validate(
                need(input$twogrp_ss_p1 >= 0 && input$twogrp_ss_p1 <= 100, "Event rate Group 1 must be between 0 and 100%"),
                need(input$twogrp_ss_p2 >= 0 && input$twogrp_ss_p2 <= 100, "Event rate Group 2 must be between 0 and 100%"),
                need(input$twogrp_ss_p1 != input$twogrp_ss_p2, "Event rates must be different to calculate sample size"),
                need(input$twogrp_ss_ratio > 0, "Allocation ratio must be positive")
            )
        } else if (input$tabset == "Power (Survival)") {
            validate(
                need(input$surv_pow_n > 0, "Sample size must be positive"),
                need(input$surv_pow_hr > 0, "Hazard ratio must be positive"),
                need(input$surv_pow_k >= 0 && input$surv_pow_k <= 100, "Proportion exposed must be between 0 and 100%"),
                need(input$surv_pow_pE >= 0 && input$surv_pow_pE <= 100, "Event rate must be between 0 and 100%"),
                need(input$surv_pow_hr != 1, "Hazard ratio must be different from 1 to calculate power")
            )
        } else if (input$tabset == "Sample Size (Survival)") {
            validate(
                need(input$surv_ss_hr > 0, "Hazard ratio must be positive"),
                need(input$surv_ss_k >= 0 && input$surv_ss_k <= 100, "Proportion exposed must be between 0 and 100%"),
                need(input$surv_ss_pE >= 0 && input$surv_ss_pE <= 100, "Event rate must be between 0 and 100%"),
                need(input$surv_ss_hr != 1, "Hazard ratio must be different from 1 to calculate sample size")
            )
        } else if (input$tabset == "Matched Case-Control") {
            validate(
                need(input$match_or > 0, "Odds ratio must be positive"),
                need(input$match_p0 >= 0 && input$match_p0 <= 100, "Exposure probability must be between 0 and 100%"),
                need(input$match_ratio >= 1, "Controls per case must be at least 1"),
                need(input$match_or != 1, "Odds ratio must be different from 1 to calculate sample size")
            )
        } else if (input$tabset == "Power (Continuous)") {
            validate(
                need(input$cont_pow_n1 > 1, "Sample size Group 1 must be at least 2"),
                need(input$cont_pow_n2 > 1, "Sample size Group 2 must be at least 2"),
                need(input$cont_pow_d > 0, "Effect size (Cohen's d) must be positive"),
                need(input$cont_pow_d != 0, "Effect size cannot be zero")
            )
        } else if (input$tabset == "Sample Size (Continuous)") {
            validate(
                need(input$cont_ss_d > 0, "Effect size (Cohen's d) must be positive"),
                need(input$cont_ss_d != 0, "Effect size cannot be zero"),
                need(input$cont_ss_ratio > 0, "Allocation ratio must be positive")
            )
        } else if (input$tabset == "Non-Inferiority") {
            validate(
                need(input$noninf_p1 >= 0 && input$noninf_p1 <= 100, "Event rate Test Group must be between 0 and 100%"),
                need(input$noninf_p2 >= 0 && input$noninf_p2 <= 100, "Event rate Reference Group must be between 0 and 100%"),
                need(input$noninf_margin > 0, "Non-inferiority margin must be positive"),
                need(input$noninf_margin < 100, "Non-inferiority margin must be less than 100%"),
                need(input$noninf_ratio > 0, "Allocation ratio must be positive")
            )
        }
    }

    ################################################################################################## LIVE PREVIEW (DEBOUNCED)

    # Create debounced preview reactive for quick feedback
    preview_inputs <- reactive({
        if (input$tabset == "Power (Single)") {
            list(
                tab = input$tabset,
                n = input$power_n,
                p = input$power_p,
                alpha = input$power_alpha,
                rate = 1/input$power_p
            )
        } else if (input$tabset == "Sample Size (Single)") {
            list(
                tab = input$tabset,
                power = input$ss_power,
                p = input$ss_p,
                alpha = input$ss_alpha,
                rate = 1/input$ss_p
            )
        } else if (input$tabset == "Power (Two-Group)") {
            list(
                tab = input$tabset,
                n1 = input$twogrp_pow_n1,
                n2 = input$twogrp_pow_n2,
                p1 = input$twogrp_pow_p1,
                p2 = input$twogrp_pow_p2
            )
        } else {
            list(tab = input$tabset)
        }
    }) %>% debounce(1000)  # Wait 1 second after last input change

    output$live_preview <- renderUI({
        # Only show preview before Calculate is pressed
        if (v$doAnalysis != FALSE) return()

        prev <- preview_inputs()

        # Create a lightweight preview message
        preview_text <- if (prev$tab == "Power (Single)") {
            paste0("Preview: Testing n=", prev$n, " participants for event rate 1 in ", prev$p,
                   " (", round(prev$rate * 100, 2), "%) at α=", prev$alpha)
        } else if (prev$tab == "Sample Size (Single)") {
            paste0("Preview: Calculating sample size for ", prev$power, "% power, ",
                   "event rate 1 in ", prev$p, " (", round(prev$rate * 100, 2), "%) at α=", prev$alpha)
        } else if (prev$tab == "Power (Two-Group)") {
            paste0("Preview: Comparing n1=", prev$n1, " vs n2=", prev$n2,
                   " with rates ", prev$p1, "% vs ", prev$p2, "%")
        } else {
            "Fill in parameters and click Calculate"
        }

        div(
            style = "background-color: #f0f8ff; border-left: 4px solid #3498db; padding: 10px; margin-bottom: 10px;",
            icon("info-circle"),
            strong(" Quick Preview: "),
            preview_text,
            br(),
            em("(Click Calculate to run full analysis)")
        )
    })

    ################################################################################################## RESULT TEXT

    output$result_text <- renderUI({
        if (v$doAnalysis == FALSE) return()

        isolate({
            # Use req() for cleaner validation (demonstrated for Power (Single) tab)
            if (input$tabset == "Power (Single)") {
                req(input$power_n > 0, cancelOutput = TRUE)
                req(input$power_p > 0, cancelOutput = TRUE)
                req(input$power_discon >= 0 && input$power_discon <= 100, cancelOutput = TRUE)
            }

            validate_inputs()

            if (input$tabset == "Power (Single)") {
                incidence_rate <- input$power_p
                sample_size <- input$power_n
                power <- pwr.p.test(sig.level=input$power_alpha, power=NULL,
                                  h = ES.h(1/input$power_p, 0), alt="greater", n = input$power_n)$power
                discon <- input$power_discon/100

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("Based on the Binomial distribution and a true event incidence rate of 1 in ",
                                format(incidence_rate, digits=0, nsmall=0), " (or ",
                                format(1/incidence_rate * 100, digits=2, nsmall=2), "%), with ",
                                format(ceiling(sample_size), digits=0, nsmall=0),
                                " participants, the probability of observing at least one event is ",
                                format(power*100, digits=0, nsmall=0), "% (α = ",
                                input$power_alpha, "). Accounting for a possible withdrawal or discontinuation rate of ",
                                format(discon*100, digits=0), "%, the adjusted sample size is ",
                                format(ceiling((sample_size * (1+discon))), digits=0)," to maintain this power."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Sample Size (Single)") {
                incidence_rate <- input$ss_p
                sample_size <- pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                                         h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
                power <- input$ss_power/100
                discon <- input$ss_discon/100

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("Based on the Binomial distribution and a true event incidence rate of 1 in ",
                                format(incidence_rate, digits=0, nsmall=0), " (or ",
                                format(1/incidence_rate * 100, digits=2, nsmall=2), "%), ",
                                format(ceiling(sample_size), digits=0, nsmall=0),
                                " participants would be needed to observe at least one event with ",
                                format(power*100, digits=0, nsmall=0), "% probability (α = ",
                                input$ss_alpha, "). Accounting for a possible withdrawal or discontinuation rate of ",
                                format(discon*100, digits=0), "%, the target number of participants is set as ",
                                format(ceiling((sample_size * (1+discon))), digits=0),"."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Power (Two-Group)") {
                n1 <- input$twogrp_pow_n1
                n2 <- input$twogrp_pow_n2
                p1 <- input$twogrp_pow_p1/100
                p2 <- input$twogrp_pow_p2/100

                power <- pwr.2p2n.test(h = ES.h(p1, p2), n1 = n1, n2 = n2,
                                       sig.level = input$twogrp_pow_alpha,
                                       alternative = input$twogrp_pow_sided)$power

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("For a two-group comparison with event rates of ",
                                format(p1*100, digits=2, nsmall=1), "% in Group 1 and ",
                                format(p2*100, digits=2, nsmall=1), "% in Group 2, with sample sizes of n1 = ",
                                n1, " and n2 = ", n2, ", the study has ",
                                format(power*100, digits=1, nsmall=1), "% power to detect this difference at α = ",
                                input$twogrp_pow_alpha, " (", input$twogrp_pow_sided, " test)."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Sample Size (Two-Group)") {
                p1 <- input$twogrp_ss_p1/100
                p2 <- input$twogrp_ss_p2/100
                power <- input$twogrp_ss_power/100

                # Calculate sample size for group 1 (ratio-aware for unequal allocation)
                n1 <- solve_n1_for_ratio(ES.h(p1, p2), input$twogrp_ss_ratio,
                                        input$twogrp_ss_alpha, power, input$twogrp_ss_sided)
                n2 <- n1 * input$twogrp_ss_ratio

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("To detect a difference in event rates from ",
                                format(p2*100, digits=2, nsmall=1), "% in Group 2 (control) to ",
                                format(p1*100, digits=2, nsmall=1), "% in Group 1 (exposed/treatment) with ",
                                format(power*100, digits=0, nsmall=0), "% power at α = ",
                                input$twogrp_ss_alpha, " (", input$twogrp_ss_sided, " test), the required sample sizes are: Group 1: n1 = ",
                                format(ceiling(n1), digits=0, nsmall=0), ", Group 2: n2 = ",
                                format(ceiling(n2), digits=0, nsmall=0), " (total N = ",
                                format(ceiling(n1 + n2), digits=0, nsmall=0), ")."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Power (Survival)") {
                n <- input$surv_pow_n
                hr <- input$surv_pow_hr
                k <- input$surv_pow_k/100
                pE <- input$surv_pow_pE/100

                # Calculate power using powerSurvEpi
                power <- powerEpi(n = n, theta = hr, k = k, pE = pE,
                                 RR = hr, alpha = input$surv_pow_alpha)

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("For a survival analysis with N = ", n, " total participants, ",
                                format(k*100, digits=1, nsmall=0), "% exposed/treated, an overall event rate of ",
                                format(pE*100, digits=1, nsmall=0), "%, and an expected hazard ratio of ",
                                format(hr, digits=2, nsmall=2), ", the study has ",
                                format(power*100, digits=1, nsmall=1), "% power to detect this effect using Cox regression at α = ",
                                input$surv_pow_alpha, " (two-sided test). This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Sample Size (Survival)") {
                power <- input$surv_ss_power/100
                hr <- input$surv_ss_hr
                k <- input$surv_ss_k/100
                pE <- input$surv_ss_pE/100

                # Calculate sample size using powerSurvEpi
                # We need to iterate to find the right sample size
                n_est <- ssizeEpi(power = power, theta = hr, k = k, pE = pE,
                                 RR = hr, alpha = input$surv_ss_alpha)

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("To detect a hazard ratio of ", format(hr, digits=2, nsmall=2),
                                " with ", format(power*100, digits=0, nsmall=0), "% power in a survival analysis using Cox regression, ",
                                "with ", format(k*100, digits=1, nsmall=0), "% of participants exposed/treated and an overall event rate of ",
                                format(pE*100, digits=1, nsmall=0), "%, the required total sample size is N = ",
                                format(ceiling(n_est), digits=0, nsmall=0), " participants (α = ",
                                input$surv_ss_alpha, ", two-sided test). This calculation uses the Schoenfeld (1983) method for Cox proportional hazards models."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Matched Case-Control") {
                or <- input$match_or
                p0 <- input$match_p0/100
                m <- input$match_ratio
                power <- input$match_power/100

                # Calculate sample size for matched case-control using epiR
                sided_val <- ifelse(input$match_sided == "two.sided", 2, 1)

                # Use epi.sscc for matched case-control
                result <- epi.sscc(OR = or, p0 = p0, n = NA, power = power,
                                  r = m, rho = 0, design = 1, sided.test = sided_val,
                                  conf.level = 1 - input$match_alpha)
                n_cases <- ceiling(result$n.total)

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("For a matched case-control study to detect an odds ratio of ",
                                format(or, digits=2, nsmall=2), " with ", format(power*100, digits=0, nsmall=0),
                                "% power, assuming ", format(p0*100, digits=1, nsmall=0),
                                "% exposure prevalence in controls, and a ", m, ":1 matching ratio (controls per case), ",
                                "the required sample size is ", n_cases, " cases and ",
                                format(n_cases * m, digits=0, nsmall=0), " controls (total N = ",
                                format(n_cases * (1 + m), digits=0, nsmall=0), " participants) at α = ",
                                input$match_alpha, " (", input$match_sided, " test). This accounts for correlation between matched pairs."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Power (Continuous)") {
                n1 <- input$cont_pow_n1
                n2 <- input$cont_pow_n2
                d <- input$cont_pow_d

                # Calculate power for t-test
                power <- pwr.t2n.test(n1 = n1, n2 = n2, d = d,
                                     sig.level = input$cont_pow_alpha,
                                     alternative = input$cont_pow_sided)$power

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("For a two-group comparison of continuous outcomes with sample sizes of n1 = ",
                                n1, " and n2 = ", n2, ", and an expected effect size of Cohen's d = ",
                                format(d, digits=2, nsmall=2), " (standardized mean difference), the study has ",
                                format(power*100, digits=1, nsmall=1), "% power to detect this difference using a two-sample t-test at α = ",
                                input$cont_pow_alpha, " (", input$cont_pow_sided, " test). ",
                                "Cohen's d represents the difference in means divided by the pooled standard deviation."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Sample Size (Continuous)") {
                d <- input$cont_ss_d
                power <- input$cont_ss_power/100
                ratio <- input$cont_ss_ratio

                # Calculate sample size for t-test (solve for n1)
                # Using pwr.t.test for equal n, then adjust for ratio
                if (ratio == 1) {
                    n <- pwr.t.test(d = d, sig.level = input$cont_ss_alpha,
                                   power = power, type = "two.sample",
                                   alternative = input$cont_ss_sided)$n
                    n1 <- n
                    n2 <- n
                } else {
                    # For unequal allocation, use iterative approach
                    f <- function(n1) {
                        n2 <- n1 * ratio
                        pwr.t2n.test(n1 = n1, n2 = n2, d = d,
                                    sig.level = input$cont_ss_alpha,
                                    alternative = input$cont_ss_sided)$power - power
                    }
                    n1 <- tryCatch({
                        uniroot(f, c(2, 1e6), extendInt = "yes")$root
                    }, error = function(e) {
                        # Fallback
                        pwr.t.test(d = d, sig.level = input$cont_ss_alpha,
                                  power = power, type = "two.sample",
                                  alternative = input$cont_ss_sided)$n
                    })
                    n2 <- n1 * ratio
                }

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("To detect an effect size of Cohen's d = ", format(d, digits=2, nsmall=2),
                                " in a two-group comparison of continuous outcomes with ", format(power*100, digits=0, nsmall=0),
                                "% power at α = ", input$cont_ss_alpha, " (", input$cont_ss_sided, " test), ",
                                "the required sample sizes are: Group 1: n1 = ", format(ceiling(n1), digits=0, nsmall=0),
                                ", Group 2: n2 = ", format(ceiling(n2), digits=0, nsmall=0), " (total N = ",
                                format(ceiling(n1 + n2), digits=0, nsmall=0), "). ",
                                "Cohen's d is the standardized mean difference (difference in means / pooled SD)."))
                HTML(paste0(text0, text1, text2, text3))

            } else if (input$tabset == "Non-Inferiority") {
                p1 <- input$noninf_p1/100
                p2 <- input$noninf_p2/100
                margin <- input$noninf_margin/100
                power <- input$noninf_power/100
                ratio <- input$noninf_ratio

                # Non-inferiority sample size calculation
                # Based on difference in proportions with non-inferiority margin
                # H0: p1 - p2 >= margin (inferior), H1: p1 - p2 < margin (non-inferior)
                # Use one-sided test

                # Calculate using pwr package with adjusted effect size
                # For non-inferiority, we test against the margin, not zero
                # Effective difference = true_diff - margin (must be < 0 for non-inferiority)
                true_diff <- p1 - p2
                effect_diff <- true_diff - margin  # This should be negative for non-inferiority

                # Calculate effect size h for the margin test
                h <- ES.h(p1, p2 + margin)

                if (ratio == 1) {
                    n <- pwr.2p.test(h = abs(h), sig.level = input$noninf_alpha,
                                    power = power, alternative = "less")$n
                    n1 <- n
                    n2 <- n
                } else {
                    f <- function(n1) {
                        n2 <- n1 * ratio
                        pwr.2p2n.test(h = abs(h), n1 = n1, n2 = n2,
                                     sig.level = input$noninf_alpha,
                                     alternative = "less")$power - power
                    }
                    n1 <- tryCatch({
                        uniroot(f, c(2, 1e6), extendInt = "yes")$root
                    }, error = function(e) {
                        pwr.2p.test(h = abs(h), sig.level = input$noninf_alpha,
                                   power = power, alternative = "less")$n
                    })
                    n2 <- n1 * ratio
                }

                text0 <- hr()
                text1 <- h1("Results of this analysis")
                text2 <- h4("(This text can be copy/pasted into your synopsis or protocol)")
                text3 <- p(paste0("For a non-inferiority trial comparing a test treatment (expected event rate: ",
                                format(p1*100, digits=2, nsmall=1), "%) to a reference treatment (expected event rate: ",
                                format(p2*100, digits=2, nsmall=1), "%) with a non-inferiority margin of ",
                                format(margin*100, digits=2, nsmall=1), " percentage points, to demonstrate non-inferiority with ",
                                format(power*100, digits=0, nsmall=0), "% power at α = ", input$noninf_alpha,
                                " (one-sided test), the required sample sizes are: Test Group: n1 = ",
                                format(ceiling(n1), digits=0, nsmall=0), ", Reference Group: n2 = ",
                                format(ceiling(n2), digits=0, nsmall=0), " (total N = ",
                                format(ceiling(n1 + n2), digits=0, nsmall=0), "). ",
                                "Non-inferiority will be demonstrated if the upper bound of the confidence interval for the difference (Test - Reference) is less than the margin."))
                HTML(paste0(text0, text1, text2, text3))
            }
        })
    })

    ################################################################################################## EFFECT MEASURES (Two-Group and Survival)

    output$effect_measures <- renderUI({
        if (v$doAnalysis == FALSE) return()
        if (!grepl("Two-Group|Survival", input$tabset)) return()

        isolate({
            validate_inputs()

            if (grepl("Two-Group", input$tabset)) {
                if (input$tabset == "Power (Two-Group)") {
                    p1 <- input$twogrp_pow_p1/100
                    p2 <- input$twogrp_pow_p2/100
                } else {
                    p1 <- input$twogrp_ss_p1/100
                    p2 <- input$twogrp_ss_p2/100
                }

                # Calculate effect measures safely
                eff <- calc_effect_measures(p1, p2)

                text1 <- h4("Effect Measures")
                text2 <- p(paste0(
                    "Risk Difference: ", format(eff$risk_diff, digits=2, nsmall=2), " percentage points", br(),
                    "Relative Risk: ", if (is.na(eff$relative_risk)) "N/A (Group 2 rate = 0%)" else format(eff$relative_risk, digits=3, nsmall=3), br(),
                    "Odds Ratio: ", if (is.na(eff$odds_ratio)) "N/A (rate = 0% or 100%)" else format(eff$odds_ratio, digits=3, nsmall=3)
                ))

                HTML(paste0(text1, text2))
            } else if (grepl("Survival", input$tabset)) {
                if (input$tabset == "Power (Survival)") {
                    hr <- input$surv_pow_hr
                } else {
                    hr <- input$surv_ss_hr
                }

                text1 <- h4("Effect Measure")
                interpretation <- if (hr < 1) {
                    "protective effect (reduced hazard)"
                } else if (hr > 1) {
                    "increased risk (elevated hazard)"
                } else {
                    "no effect"
                }

                text2 <- p(paste0(
                    "Hazard Ratio (HR): ", format(hr, digits=3, nsmall=3), br(),
                    "Interpretation: HR = ", format(hr, digits=3, nsmall=3), " indicates a ", interpretation
                ))

                HTML(paste0(text1, text2))
            }
        })
    })

    ################################################################################################## PLOT TITLE

    output$figure_title <- renderUI({
        if (v$doAnalysis == FALSE) return()
        if (input$tabset == "Matched Case-Control") return()  # No plot for matched case-control

        isolate({
            text1 <- hr()
            if (grepl("Two-Group", input$tabset)) {
                if (input$tabset == "Power (Two-Group)") {
                    ratio <- round(input$twogrp_pow_n2 / input$twogrp_pow_n1, 3)
                } else {
                    ratio <- input$twogrp_ss_ratio
                }
                text2 <- h4(paste0("Estimated power vs. n1 (Group 1 sample size) with allocation ratio n2/n1 = ", ratio, "."))
            } else if (grepl("Survival", input$tabset)) {
                text2 <- h4("Power curve for survival analysis at different sample sizes.")
            } else {
                text2 <- h4("Estimated power for the given conditions at different sample sizes.")
            }
            HTML(paste0(text1, text2))
        })
    })

    ################################################################################################## POWER VS. SAMPLE SIZE PLOT

    output$power_plot <- renderPlot({
        if (v$doAnalysis == FALSE) return()
        if (input$tabset == "Matched Case-Control") return()  # No plot for matched case-control

        isolate({
            validate_inputs()

            if (input$tabset == "Power (Single)") {
                p.out <- pwr.p.test(sig.level=input$power_alpha, power=NULL,
                                   h = ES.h(1/input$power_p, 0), alt="greater", n = input$power_n)
                plot(p.out)
            } else if (input$tabset == "Sample Size (Single)") {
                p.out <- pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                                   h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)
                plot(p.out)
            } else if (input$tabset == "Power (Two-Group)") {
                # Ratio-aware plot for unequal allocation
                p1 <- input$twogrp_pow_p1/100
                p2 <- input$twogrp_pow_p2/100
                ratio <- input$twogrp_pow_n2 / input$twogrp_pow_n1

                # Generate power curve varying n1
                n1_seq <- seq(max(5, floor(input$twogrp_pow_n1*0.25)),
                             floor(input$twogrp_pow_n1*4), length.out = 100)
                pow <- sapply(n1_seq, function(n1) {
                    pwr.2p2n.test(h = ES.h(p1, p2), n1 = n1, n2 = n1*ratio,
                                 sig.level = input$twogrp_pow_alpha,
                                 alternative = input$twogrp_pow_sided)$power
                })

                plot(n1_seq, pow, type="l", lwd=2, col="darkblue",
                     xlab="Sample Size n1 (Group 1)", ylab="Power",
                     main=paste0("Power Analysis (n2/n1 = ", round(ratio, 3), ")"),
                     ylim=c(0,1), las=1)
                abline(h=0.8, col="red", lty=2)
                abline(v=input$twogrp_pow_n1, col="darkgreen", lty=2)
                grid()

            } else if (input$tabset == "Sample Size (Two-Group)") {
                # Ratio-aware plot for sample size calculation
                p1 <- input$twogrp_ss_p1/100
                p2 <- input$twogrp_ss_p2/100
                ratio <- input$twogrp_ss_ratio
                target <- input$twogrp_ss_power/100

                # Generate power curve varying n1
                n1_seq <- seq(5, 2000, length.out = 100)
                pow <- sapply(n1_seq, function(n1) {
                    pwr.2p2n.test(h = ES.h(p1, p2), n1 = n1, n2 = n1*ratio,
                                 sig.level = input$twogrp_ss_alpha,
                                 alternative = input$twogrp_ss_sided)$power
                })

                plot(n1_seq, pow, type="l", lwd=2, col="darkblue",
                     xlab="Sample Size n1 (Group 1)", ylab="Power",
                     main=paste0("Power Analysis (n2/n1 = ", round(ratio, 3), ")"),
                     ylim=c(0,1), las=1)
                abline(h=target, col="red", lty=2, lwd=2)
                grid()

            } else if (grepl("Survival", input$tabset)) {
                # Generate power curve for survival analysis
                if (input$tabset == "Power (Survival)") {
                    hr <- input$surv_pow_hr
                    k <- input$surv_pow_k/100
                    pE <- input$surv_pow_pE/100
                    alpha <- input$surv_pow_alpha
                    current_n <- input$surv_pow_n
                } else {
                    hr <- input$surv_ss_hr
                    k <- input$surv_ss_k/100
                    pE <- input$surv_ss_pE/100
                    alpha <- input$surv_ss_alpha
                    current_n <- ssizeEpi(power = input$surv_ss_power/100, theta = hr, k = k,
                                         pE = pE, RR = hr, alpha = alpha)
                }

                # Generate sample size range
                n_range <- seq(from = max(50, current_n * 0.5), to = current_n * 2, length.out = 50)
                power_vals <- sapply(n_range, function(n) {
                    powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = alpha)
                })

                # Create plot
                plot(n_range, power_vals, type = "l", lwd = 2, col = "blue",
                     xlab = "Total Sample Size (N)", ylab = "Power",
                     main = "Power vs. Sample Size for Survival Analysis",
                     ylim = c(0, 1), las = 1)
                abline(h = 0.80, lty = 2, col = "red")
                abline(v = current_n, lty = 2, col = "green")
                grid()
                legend("bottomright", legend = c("Power curve", "80% Power", "Current N"),
                      col = c("blue", "red", "green"), lty = c(1, 2, 2), lwd = c(2, 1, 1))
            }
        })
    }, width=600, height=400, res=100) %>%
        bindCache(
            input$tabset,
            # Single Proportion inputs
            input$power_n, input$power_p, input$power_alpha,
            input$ss_power, input$ss_p, input$ss_alpha,
            # Two-Group inputs
            input$twogrp_pow_n1, input$twogrp_pow_n2, input$twogrp_pow_p1, input$twogrp_pow_p2,
            input$twogrp_pow_alpha, input$twogrp_pow_sided,
            input$twogrp_ss_p1, input$twogrp_ss_p2, input$twogrp_ss_ratio,
            input$twogrp_ss_alpha, input$twogrp_ss_sided, input$twogrp_ss_power,
            # Survival inputs
            input$surv_pow_n, input$surv_pow_hr, input$surv_pow_k, input$surv_pow_pE, input$surv_pow_alpha,
            input$surv_ss_hr, input$surv_ss_k, input$surv_ss_pE, input$surv_ss_alpha, input$surv_ss_power,
            # Include doAnalysis flag to invalidate cache when Calculate is pressed
            v$doAnalysis
        )

    ################################################################################################## TABLE TITLE

    output$table_title <- renderUI({
        if (v$doAnalysis == FALSE) return()
        if (grepl("Two-Group", input$tabset)) return()  # Only show for single proportion

        isolate({
            validate_inputs()

            if (input$tabset == "Power (Single)") {
                sample_size <- input$power_n
            } else {
                sample_size <- pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                                         h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }

            text1 <- hr()
            text2 <- h5("In addition, if ", ceiling(sample_size), " participants are included, the event rate would be estimated to an accuracy shown in the table below:")
            text3 <- h4(paste0("95% Confidence Interval around expected event rate(s) with a sample size of ",
                              ceiling(sample_size), " participants."))
            HTML(paste0(text1, text2, text3))
        })
    })

    ################################################################################################## CONFIDENCE INTERVAL TABLE

    output$result_table <- renderDataTable({
        if (v$doAnalysis == FALSE) return()
        if (grepl("Two-Group", input$tabset)) return()  # Only show for single proportion

        isolate({
            validate_inputs()

            if (input$tabset == "Power (Single)") {
                sample_size <- input$power_n
            } else {
                sample_size <- pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                                         h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }

            sequence <- unique(c(seq(0, 5), seq(10, 25, by=5), seq(50, min(round(sample_size, 0), 1000), by=50),
                               seq(min(round(sample_size, 0), 1000), min(round(sample_size, 0), 10000), by=1000)))
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

    ################################################################################################## TABLE FOOTNOTES

    output$table_footnotes <- renderUI({
        if (v$doAnalysis == FALSE) return()
        if (grepl("Two-Group", input$tabset)) return()  # Only show for single proportion

        isolate({
            text1 <- h6("(1) Event rate (%) is estimated as a crude rate, defined as the number of participants exposed and experiencing the event of interest divided by the total number of participants.")
            text2 <- h6("(2) Confidence interval (%) based on exact Clopper-Pearson method for one proportion.")
            HTML(paste0(text1, text2))
        })
    })

    ################################################################################################## DOWNLOAD BUTTONS

    output$download_buttons <- renderUI({
        if (v$doAnalysis == FALSE) return()

        isolate({
            text1 <- hr()
            text2 <- downloadButton('report_pdf', "Download Analysis (PDF) [Experimental]")
            text3 <- downloadButton('report_csv', "Download Results (CSV)", class = "btn-info")
            text4 <- hr()
            HTML(paste0(text1, " ", text2, " ", text3, " ", text4))
        })
    })

    ################################################################################################## CSV DOWNLOAD

    output$report_csv <- downloadHandler(
        filename = function() {
            paste('Power-Analysis-', input$tabset, '-', Sys.Date(), '.csv', sep='')
        },
        content = function(file) {
            if (input$tabset == "Power (Single)") {
                results <- data.frame(
                    Analysis_Type = "Single Proportion - Power Calculation",
                    Sample_Size = input$power_n,
                    Event_Frequency_1_in = input$power_p,
                    Event_Rate_Percent = 100/input$power_p,
                    Power_Percent = pwr.p.test(sig.level=input$power_alpha, power=NULL,
                                              h = ES.h(1/input$power_p, 0), alt="greater",
                                              n = input$power_n)$power * 100,
                    Significance_Level = input$power_alpha,
                    Discontinuation_Rate_Percent = input$power_discon,
                    Adjusted_Sample_Size = ceiling(input$power_n * (1 + input$power_discon/100)),
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Sample Size (Single)") {
                sample_size <- pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                                         h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
                results <- data.frame(
                    Analysis_Type = "Single Proportion - Sample Size Calculation",
                    Desired_Power_Percent = input$ss_power,
                    Event_Frequency_1_in = input$ss_p,
                    Event_Rate_Percent = 100/input$ss_p,
                    Required_Sample_Size = ceiling(sample_size),
                    Significance_Level = input$ss_alpha,
                    Discontinuation_Rate_Percent = input$ss_discon,
                    Adjusted_Sample_Size = ceiling(sample_size * (1 + input$ss_discon/100)),
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Power (Two-Group)") {
                p1 <- input$twogrp_pow_p1/100
                p2 <- input$twogrp_pow_p2/100
                power <- pwr.2p2n.test(h = ES.h(p1, p2), n1 = input$twogrp_pow_n1, n2 = input$twogrp_pow_n2,
                                       sig.level = input$twogrp_pow_alpha,
                                       alternative = input$twogrp_pow_sided)$power
                eff <- calc_effect_measures(p1, p2)
                results <- data.frame(
                    Analysis_Type = "Two-Group Comparison - Power Calculation",
                    Sample_Size_Group1 = input$twogrp_pow_n1,
                    Sample_Size_Group2 = input$twogrp_pow_n2,
                    Event_Rate_Group1_Percent = input$twogrp_pow_p1,
                    Event_Rate_Group2_Percent = input$twogrp_pow_p2,
                    Power_Percent = power * 100,
                    Significance_Level = input$twogrp_pow_alpha,
                    Test_Type = input$twogrp_pow_sided,
                    Risk_Difference = eff$risk_diff,
                    Relative_Risk = eff$relative_risk,
                    Odds_Ratio = eff$odds_ratio,
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Sample Size (Two-Group)") {
                p1 <- input$twogrp_ss_p1/100
                p2 <- input$twogrp_ss_p2/100
                n1 <- solve_n1_for_ratio(ES.h(p1, p2), input$twogrp_ss_ratio,
                                        input$twogrp_ss_alpha, input$twogrp_ss_power/100,
                                        input$twogrp_ss_sided)
                n2 <- n1 * input$twogrp_ss_ratio
                eff <- calc_effect_measures(p1, p2)
                results <- data.frame(
                    Analysis_Type = "Two-Group Comparison - Sample Size Calculation",
                    Desired_Power_Percent = input$twogrp_ss_power,
                    Event_Rate_Group1_Percent = input$twogrp_ss_p1,
                    Event_Rate_Group2_Percent = input$twogrp_ss_p2,
                    Required_Sample_Size_Group1 = ceiling(n1),
                    Required_Sample_Size_Group2 = ceiling(n2),
                    Total_Sample_Size = ceiling(n1 + n2),
                    Allocation_Ratio = input$twogrp_ss_ratio,
                    Significance_Level = input$twogrp_ss_alpha,
                    Test_Type = input$twogrp_ss_sided,
                    Risk_Difference = eff$risk_diff,
                    Relative_Risk = eff$relative_risk,
                    Odds_Ratio = eff$odds_ratio,
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Power (Survival)") {
                n <- input$surv_pow_n
                hr <- input$surv_pow_hr
                k <- input$surv_pow_k/100
                pE <- input$surv_pow_pE/100
                power <- powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_pow_alpha)
                results <- data.frame(
                    Analysis_Type = "Survival Analysis - Power Calculation",
                    Total_Sample_Size = n,
                    Hazard_Ratio = hr,
                    Proportion_Exposed_Percent = input$surv_pow_k,
                    Overall_Event_Rate_Percent = input$surv_pow_pE,
                    Power_Percent = power * 100,
                    Significance_Level = input$surv_pow_alpha,
                    Method = "Schoenfeld (1983)",
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Sample Size (Survival)") {
                hr <- input$surv_ss_hr
                k <- input$surv_ss_k/100
                pE <- input$surv_ss_pE/100
                power <- input$surv_ss_power/100
                n_est <- ssizeEpi(power = power, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_ss_alpha)
                results <- data.frame(
                    Analysis_Type = "Survival Analysis - Sample Size Calculation",
                    Desired_Power_Percent = input$surv_ss_power,
                    Hazard_Ratio = hr,
                    Proportion_Exposed_Percent = input$surv_ss_k,
                    Overall_Event_Rate_Percent = input$surv_ss_pE,
                    Required_Total_Sample_Size = ceiling(n_est),
                    Significance_Level = input$surv_ss_alpha,
                    Method = "Schoenfeld (1983)",
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Matched Case-Control") {
                or <- input$match_or
                p0 <- input$match_p0/100
                m <- input$match_ratio
                power <- input$match_power/100
                sided_val <- ifelse(input$match_sided == "two.sided", 2, 1)
                result <- epi.sscc(OR = or, p0 = p0, n = NA, power = power,
                                  r = m, rho = 0, design = 1, sided.test = sided_val,
                                  conf.level = 1 - input$match_alpha)
                n_cases <- ceiling(result$n.total)
                results <- data.frame(
                    Analysis_Type = "Matched Case-Control - Sample Size Calculation",
                    Desired_Power_Percent = input$match_power * 100,
                    Odds_Ratio = or,
                    Exposure_Prob_Controls_Percent = input$match_p0,
                    Controls_Per_Case = m,
                    Required_Cases = n_cases,
                    Required_Controls = n_cases * m,
                    Total_Sample_Size = n_cases * (1 + m),
                    Significance_Level = input$match_alpha,
                    Test_Type = input$match_sided,
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Power (Continuous)") {
                n1 <- input$cont_pow_n1
                n2 <- input$cont_pow_n2
                d <- input$cont_pow_d
                power <- pwr.t2n.test(n1 = n1, n2 = n2, d = d,
                                     sig.level = input$cont_pow_alpha,
                                     alternative = input$cont_pow_sided)$power
                results <- data.frame(
                    Analysis_Type = "Continuous Outcomes - Power Calculation",
                    Sample_Size_Group1 = n1,
                    Sample_Size_Group2 = n2,
                    Effect_Size_Cohens_d = d,
                    Power_Percent = power * 100,
                    Significance_Level = input$cont_pow_alpha,
                    Test_Type = input$cont_pow_sided,
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Sample Size (Continuous)") {
                d <- input$cont_ss_d
                power <- input$cont_ss_power/100
                ratio <- input$cont_ss_ratio
                if (ratio == 1) {
                    n <- pwr.t.test(d = d, sig.level = input$cont_ss_alpha,
                                   power = power, type = "two.sample",
                                   alternative = input$cont_ss_sided)$n
                    n1 <- n
                    n2 <- n
                } else {
                    f <- function(n1) {
                        n2 <- n1 * ratio
                        pwr.t2n.test(n1 = n1, n2 = n2, d = d,
                                    sig.level = input$cont_ss_alpha,
                                    alternative = input$cont_ss_sided)$power - power
                    }
                    n1 <- tryCatch({
                        uniroot(f, c(2, 1e6), extendInt = "yes")$root
                    }, error = function(e) {
                        pwr.t.test(d = d, sig.level = input$cont_ss_alpha,
                                  power = power, type = "two.sample",
                                  alternative = input$cont_ss_sided)$n
                    })
                    n2 <- n1 * ratio
                }
                results <- data.frame(
                    Analysis_Type = "Continuous Outcomes - Sample Size Calculation",
                    Desired_Power_Percent = input$cont_ss_power,
                    Effect_Size_Cohens_d = d,
                    Required_Sample_Size_Group1 = ceiling(n1),
                    Required_Sample_Size_Group2 = ceiling(n2),
                    Total_Sample_Size = ceiling(n1 + n2),
                    Allocation_Ratio = ratio,
                    Significance_Level = input$cont_ss_alpha,
                    Test_Type = input$cont_ss_sided,
                    Date = Sys.Date()
                )
            } else if (input$tabset == "Non-Inferiority") {
                p1 <- input$noninf_p1/100
                p2 <- input$noninf_p2/100
                margin <- input$noninf_margin/100
                power <- input$noninf_power/100
                ratio <- input$noninf_ratio
                h <- ES.h(p1, p2 + margin)
                if (ratio == 1) {
                    n <- pwr.2p.test(h = abs(h), sig.level = input$noninf_alpha,
                                    power = power, alternative = "less")$n
                    n1 <- n
                    n2 <- n
                } else {
                    f <- function(n1) {
                        n2 <- n1 * ratio
                        pwr.2p2n.test(h = abs(h), n1 = n1, n2 = n2,
                                     sig.level = input$noninf_alpha,
                                     alternative = "less")$power - power
                    }
                    n1 <- tryCatch({
                        uniroot(f, c(2, 1e6), extendInt = "yes")$root
                    }, error = function(e) {
                        pwr.2p.test(h = abs(h), sig.level = input$noninf_alpha,
                                   power = power, alternative = "less")$n
                    })
                    n2 <- n1 * ratio
                }
                results <- data.frame(
                    Analysis_Type = "Non-Inferiority - Sample Size Calculation",
                    Desired_Power_Percent = input$noninf_power,
                    Event_Rate_Test_Percent = input$noninf_p1,
                    Event_Rate_Reference_Percent = input$noninf_p2,
                    Non_Inferiority_Margin_Percent = input$noninf_margin,
                    Required_Sample_Size_Test = ceiling(n1),
                    Required_Sample_Size_Reference = ceiling(n2),
                    Total_Sample_Size = ceiling(n1 + n2),
                    Allocation_Ratio = ratio,
                    Significance_Level = input$noninf_alpha,
                    Date = Sys.Date()
                )
            }

            write.csv(results, file, row.names = FALSE)
        }
    )

    ################################################################################################## PDF DOWNLOAD (original)

    output$report_pdf <- downloadHandler(
        filename = paste('Rule-of-3-Analysis-', Sys.Date(), '.pdf', sep=''),
        content = function(file) {
            # Only works for single proportion analyses
            if (grepl("Two-Group", input$tabset)) {
                showNotification("PDF export not yet available for two-group analyses. Please use CSV export.",
                               type = "warning", duration = 5)
                return()
            }

            incidence_rate <- ifelse(input$tabset == "Power (Single)", input$power_p, input$ss_p)
            sample_size <- if(input$tabset == "Power (Single)"){
                input$power_n
            }
            else {
                pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                          h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
            }

            power <- if(input$tabset == "Power (Single)"){
                pwr.p.test(sig.level=input$power_alpha, power=NULL,
                          h = ES.h(1/input$power_p, 0), alt="greater", n = input$power_n)$power
            }
            else {
                input$ss_power/100
            }

            discon <- if(input$tabset == "Power (Single)"){
                input$power_discon/100
            }
            else {
                input$ss_discon/100
            }

            # Copy the report file to a temporary directory
            tempReport <- file.path(tempdir(), "analysis-report.Rmd")
            file.copy("analysis-report.Rmd", tempReport, overwrite = TRUE)

            # Create a Progress object
            progress <- shiny::Progress$new(style = "notification")
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

            # Knit the document
            rmarkdown::render(tempReport, output_file = file,
                              params = params,
                              envir = new.env(parent = globalenv())
            )
            progress$inc(1/6, detail = "Done!")
        }
    )

    ################################################################################################## SCENARIO COMPARISON

    # Save current scenario
    observeEvent(input$save_scenario, {
        isolate({
            if (v$doAnalysis == FALSE) return()

            v$scenario_counter <- v$scenario_counter + 1

            if (input$tabset == "Power (Single)") {
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Single Prop - Power",
                    Sample_Size = input$power_n,
                    Event_Freq = paste0("1 in ", input$power_p),
                    Power_Pct = round(pwr.p.test(sig.level=input$power_alpha, power=NULL,
                                                 h = ES.h(1/input$power_p, 0), alt="greater",
                                                 n = input$power_n)$power * 100, 1),
                    Alpha = input$power_alpha,
                    Disc_Rate = paste0(input$power_discon, "%"),
                    Adj_N = ceiling(input$power_n * (1 + input$power_discon/100)),
                    stringsAsFactors = FALSE
                )
            } else if (input$tabset == "Sample Size (Single)") {
                sample_size <- pwr.p.test(sig.level=input$ss_alpha, power=input$ss_power/100,
                                         h = ES.h(1/input$ss_p, 0), alt="greater", n = NULL)$n
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Single Prop - SS",
                    Sample_Size = ceiling(sample_size),
                    Event_Freq = paste0("1 in ", input$ss_p),
                    Power_Pct = input$ss_power,
                    Alpha = input$ss_alpha,
                    Disc_Rate = paste0(input$ss_discon, "%"),
                    Adj_N = ceiling(sample_size * (1 + input$ss_discon/100)),
                    stringsAsFactors = FALSE
                )
            } else if (input$tabset == "Power (Two-Group)") {
                p1 <- input$twogrp_pow_p1/100
                p2 <- input$twogrp_pow_p2/100
                power <- pwr.2p2n.test(h = ES.h(p1, p2), n1 = input$twogrp_pow_n1, n2 = input$twogrp_pow_n2,
                                       sig.level = input$twogrp_pow_alpha,
                                       alternative = input$twogrp_pow_sided)$power
                eff <- calc_effect_measures(p1, p2)
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Two-Group - Power",
                    n1 = input$twogrp_pow_n1,
                    n2 = input$twogrp_pow_n2,
                    p1_Pct = input$twogrp_pow_p1,
                    p2_Pct = input$twogrp_pow_p2,
                    Power_Pct = round(power * 100, 1),
                    Alpha = input$twogrp_pow_alpha,
                    Test = input$twogrp_pow_sided,
                    RR = if (is.na(eff$relative_risk)) NA_real_ else round(eff$relative_risk, 3),
                    OR = if (is.na(eff$odds_ratio)) NA_real_ else round(eff$odds_ratio, 3),
                    stringsAsFactors = FALSE
                )
            } else if (input$tabset == "Sample Size (Two-Group)") {
                p1 <- input$twogrp_ss_p1/100
                p2 <- input$twogrp_ss_p2/100
                n1 <- solve_n1_for_ratio(ES.h(p1, p2), input$twogrp_ss_ratio,
                                        input$twogrp_ss_alpha, input$twogrp_ss_power/100,
                                        input$twogrp_ss_sided)
                n2 <- n1 * input$twogrp_ss_ratio
                eff <- calc_effect_measures(p1, p2)
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Two-Group - SS",
                    n1 = ceiling(n1),
                    n2 = ceiling(n2),
                    p1_Pct = input$twogrp_ss_p1,
                    p2_Pct = input$twogrp_ss_p2,
                    Power_Pct = input$twogrp_ss_power,
                    Alpha = input$twogrp_ss_alpha,
                    Test = input$twogrp_ss_sided,
                    RR = if (is.na(eff$relative_risk)) NA_real_ else round(eff$relative_risk, 3),
                    OR = if (is.na(eff$odds_ratio)) NA_real_ else round(eff$odds_ratio, 3),
                    stringsAsFactors = FALSE
                )
            } else if (input$tabset == "Power (Survival)") {
                n <- input$surv_pow_n
                hr <- input$surv_pow_hr
                k <- input$surv_pow_k/100
                pE <- input$surv_pow_pE/100
                power <- powerEpi(n = n, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_pow_alpha)
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Survival - Power",
                    Total_N = n,
                    HR = hr,
                    Prop_Exposed_Pct = input$surv_pow_k,
                    Event_Rate_Pct = input$surv_pow_pE,
                    Power_Pct = round(power * 100, 1),
                    Alpha = input$surv_pow_alpha,
                    stringsAsFactors = FALSE
                )
            } else if (input$tabset == "Sample Size (Survival)") {
                hr <- input$surv_ss_hr
                k <- input$surv_ss_k/100
                pE <- input$surv_ss_pE/100
                power <- input$surv_ss_power/100
                n_est <- ssizeEpi(power = power, theta = hr, k = k, pE = pE, RR = hr, alpha = input$surv_ss_alpha)
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Survival - SS",
                    Total_N = ceiling(n_est),
                    HR = hr,
                    Prop_Exposed_Pct = input$surv_ss_k,
                    Event_Rate_Pct = input$surv_ss_pE,
                    Power_Pct = input$surv_ss_power,
                    Alpha = input$surv_ss_alpha,
                    stringsAsFactors = FALSE
                )
            } else if (input$tabset == "Matched Case-Control") {
                or <- input$match_or
                p0 <- input$match_p0/100
                m <- input$match_ratio
                power <- input$match_power/100
                sided_val <- ifelse(input$match_sided == "two.sided", 2, 1)
                result <- epi.sscc(OR = or, p0 = p0, n = NA, power = power,
                                  r = m, rho = 0, design = 1, sided.test = sided_val,
                                  conf.level = 1 - input$match_alpha)
                n_cases <- ceiling(result$n.total)
                new_scenario <- data.frame(
                    Scenario = v$scenario_counter,
                    Type = "Matched CC",
                    OR = or,
                    Exposure_Pct = input$match_p0,
                    Controls_Per_Case = m,
                    Cases = n_cases,
                    Controls = n_cases * m,
                    Total_N = n_cases * (1 + m),
                    Power_Pct = input$match_power,
                    Alpha = input$match_alpha,
                    stringsAsFactors = FALSE
                )
            }

            # Add to scenarios dataframe
            if (nrow(v$scenarios) == 0) {
                v$scenarios <- new_scenario
            } else {
                # Check if columns match, if not create new structure
                if (all(names(new_scenario) == names(v$scenarios))) {
                    v$scenarios <- rbind(v$scenarios, new_scenario)
                } else {
                    # Different analysis types - merge with common columns
                    all_cols <- union(names(v$scenarios), names(new_scenario))
                    for (col in all_cols) {
                        if (!(col %in% names(v$scenarios))) v$scenarios[[col]] <- NA
                        if (!(col %in% names(new_scenario))) new_scenario[[col]] <- NA
                    }
                    v$scenarios <- rbind(v$scenarios, new_scenario[names(v$scenarios)])
                }
            }

            showNotification("Scenario saved! You can now compare multiple scenarios.",
                           type = "message", duration = 3)
        })
    })

    # Clear scenarios
    observeEvent(input$clear_scenarios, {
        v$scenarios <- data.frame()
        v$scenario_counter <- 0
        showNotification("All saved scenarios cleared.", type = "warning", duration = 3)
    })

    # Display scenario comparison
    output$scenario_comparison <- renderUI({
        if (nrow(v$scenarios) == 0) return()

        tagList(
            hr(),
            h2("Saved Scenario Comparison"),
            p("Below are the scenarios you have saved for comparison:"),
            tableOutput("scenario_table"),
            hr()
        )
    })

    # Render scenario table
    output$scenario_table <- renderTable({
        v$scenarios
    })

    # Download scenario comparison
    output$download_comparison <- downloadHandler(
        filename = function() {
            paste('Scenario-Comparison-', Sys.Date(), '.csv', sep='')
        },
        content = function(file) {
            write.csv(v$scenarios, file, row.names = FALSE)
        }
    )
}

# Run the application
shinyApp(ui = ui, server = server)
