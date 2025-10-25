# Help Content Functions
# Contextual help panels for each analysis type

#' Create contextual help accordion for a specific analysis
#' @param analysis_type The type of analysis (e.g., "single_proportion", "two_group")
#' @return A bslib accordion component with contextual help
create_contextual_help <- function(analysis_type) {
  
  help_content <- switch(analysis_type,
    
    # ============================================================
    # SINGLE PROPORTION
    # ============================================================
    "single_proportion" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("info-circle"),
        p("The 'Rule of Three' states that if a certain event did not occur in a sample with n participants, the interval from 0 to 3/n is a 95% confidence interval for the rate of occurrences in the population. When n is greater than 30, this is a good approximation."),
        p(strong("Example:"), "If a drug is tested on 1,500 participants and no adverse event is recorded, we can conclude with 95% confidence that fewer than 1 person in 500 (or 3/1500 = 0.2%) will experience an adverse event.")
      ),
      accordion_panel(
        title = "Use Cases",
        icon = icon("lightbulb"),
        tags$ul(
          tags$li("Post-marketing surveillance of pharmaceutical products"),
          tags$li("Rare adverse event detection in safety studies"),
          tags$li("Quality control and manufacturing safety"),
          tags$li("Clinical trial safety monitoring")
        )
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(a("Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745.", 
                    href = "Hanley-1983-1743.pdf", target = "_blank")),
          tags$li("Eypasch E, et al. Probability of adverse events that have not yet occurred: a statistical reminder. BMJ. 1995;311(7005):619-620.")
        )
      )
    ),
    
    # ============================================================
    # TWO-GROUP COMPARISONS
    # ============================================================
    "two_group" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("users"),
        p("Two-group comparison tests whether event rates differ between two independent groups (e.g., exposed vs. unexposed, treatment vs. control). This is fundamental for comparative effectiveness research and observational studies."),
        p(strong("Example:"), "Comparing hospitalization rates between patients prescribed Drug A vs. Drug B using claims data.")
      ),
      accordion_panel(
        title = "Study Designs & Use Cases",
        icon = icon("lightbulb"),
        tags$ul(
          tags$li(strong("Cohort studies:"), "Prospective or retrospective comparison of outcomes between exposure groups"),
          tags$li(strong("Comparative effectiveness studies:"), "Real-world comparison of treatment options"),
          tags$li(strong("RCTs:"), "Randomized controlled trials comparing interventions"),
          tags$li(strong("Database studies:"), "Claims, EHR, or registry-based comparisons")
        )
      ),
      accordion_panel(
        title = "Effect Measures",
        icon = icon("calculator"),
        p("The tool calculates three key effect measures:"),
        tags$ul(
          tags$li(strong("Risk Difference (RD):"), "Absolute difference in event rates (Group 1 - Group 2)"),
          tags$li(strong("Relative Risk (RR):"), "Risk ratio (P1/P2). RR > 1 indicates increased risk in Group 1"),
          tags$li(strong("Odds Ratio (OR):"), "Odds ratio. Approximates RR when events are rare (<10%)")
        )
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li("Fleiss JL, Levin B, Paik MC. Statistical Methods for Rates and Proportions. 3rd ed. Wiley; 2003."),
          tags$li("Schulz KF, Grimes DA. Sample size calculations in randomised trials: mandatory and mystical. Lancet. 2005;365(9467):1348-1353.")
        )
      )
    ),
    
    # ============================================================
    # SURVIVAL ANALYSIS
    # ============================================================
    "survival" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("chart-line"),
        p("Survival analysis is used for time-to-event outcomes, which are extremely common in pharmaceutical RWE studies (e.g., time to hospitalization, time to disease progression, time to death)."),
        p(strong("Method:"), "Uses the Schoenfeld (1983) method for Cox proportional hazards regression, implemented in the powerSurvEpi R package."),
        p(strong("Example:"), "Estimating sample size to detect a 30% reduction in risk of cardiovascular events (HR = 0.7) in a cohort study.")
      ),
      accordion_panel(
        title = "Key Inputs Explained",
        icon = icon("question-circle"),
        tags$ul(
          tags$li(strong("Hazard Ratio (HR):"), "Expected ratio of hazard rates between groups. HR < 1 indicates protective effect, HR > 1 indicates increased risk."),
          tags$li(strong("Proportion Exposed:"), "Proportion of the cohort in the exposed/treatment group."),
          tags$li(strong("Overall Event Rate:"), "Expected proportion experiencing the event during follow-up across all participants."),
          tags$li(strong("Significance Level (α):"), "Type I error rate, typically 0.05.")
        )
      ),
      accordion_panel(
        title = "Use Cases",
        icon = icon("lightbulb"),
        tags$ul(
          tags$li("Time to cardiovascular events (MI, stroke, death)"),
          tags$li("Time to disease progression or recurrence"),
          tags$li("Time to treatment discontinuation"),
          tags$li("Time to hospitalization or ER visit"),
          tags$li("Overall survival in oncology studies")
        )
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li("Schoenfeld DA. Sample-size formula for the proportional-hazards regression model. Biometrics. 1983;39(2):499-503."),
          tags$li("Collett D. Modelling Survival Data in Medical Research. 3rd ed. Chapman & Hall/CRC; 2014.")
        )
      )
    ),
    
    # ============================================================
    # MATCHED CASE-CONTROL
    # ============================================================
    "matched" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("link"),
        p("Matched case-control studies use matching strategies to control for confounding, such as propensity score matching or traditional matching on demographic and clinical characteristics."),
        p(strong("Example:"), "Matched case-control study examining association between statin use and liver injury, matching on age, sex, and diabetes status.")
      ),
      accordion_panel(
        title = "When to Use Matching",
        icon = icon("question-circle"),
        tags$ul(
          tags$li("When cases and controls need to be balanced on important confounders"),
          tags$li("When you have more potential controls than cases"),
          tags$li("When matching on factors like age, sex, comorbidities, enrollment date"),
          tags$li("When using propensity score matching in observational studies")
        )
      ),
      accordion_panel(
        title = "Matching Ratios",
        icon = icon("calculator"),
        p("This tool supports various matching ratios:"),
        tags$ul(
          tags$li(strong("1:1 matching:"), "One control per case (most common)"),
          tags$li(strong("2:1 matching:"), "Two controls per case (more efficient)"),
          tags$li(strong("3:1 matching:"), "Three controls per case"),
          tags$li(strong("Higher ratios:"), "Diminishing returns after 4:1")
        ),
        p("Higher matching ratios increase power but require more controls.")
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li("Dupont WD. Power calculations for matched case-control studies. Biometrics. 1988;44(4):1157-1168."),
          tags$li("Breslow NE, Day NE. Statistical Methods in Cancer Research, Volume 1: The Analysis of Case-Control Studies. IARC; 1980.")
        )
      )
    ),
    
    # ============================================================
    # CONTINUOUS OUTCOMES
    # ============================================================
    "continuous" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("calculator"),
        p("Power and sample size calculations for comparing continuous endpoints between two groups using two-sample t-tests. Assumes approximately normal distributions or large enough samples for Central Limit Theorem."),
        p(strong("Example:"), "Comparing mean HbA1c reduction between two diabetes medications in an RWE study using EHR data.")
      ),
      accordion_panel(
        title = "Use Cases",
        icon = icon("lightbulb"),
        tags$ul(
          tags$li(strong("Lab values:"), "HbA1c, cholesterol, blood pressure, biomarkers"),
          tags$li(strong("Physical measures:"), "BMI, weight change, bone density"),
          tags$li(strong("Patient-reported outcomes:"), "Quality of life scores, pain scales"),
          tags$li(strong("Cognitive tests:"), "Memory scores, functional assessments"),
          tags$li(strong("Healthcare utilization:"), "Number of visits, costs")
        )
      ),
      accordion_panel(
        title = "Understanding Effect Size (Cohen's d)",
        icon = icon("question-circle"),
        p("Effect size (Cohen's d) is the standardized mean difference:"),
        p(strong("Formula:"), "d = (Mean₁ - Mean₂) / Pooled SD"),
        p(strong("Conventional benchmarks:")),
        tags$ul(
          tags$li(strong("Small:"), "d = 0.2 (subtle difference)"),
          tags$li(strong("Medium:"), "d = 0.5 (moderate difference)"),
          tags$li(strong("Large:"), "d = 0.8 (substantial difference)")
        ),
        p("However, clinical significance should guide interpretation, not just statistical benchmarks.")
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li("Cohen J. Statistical Power Analysis for the Behavioral Sciences. 2nd ed. Routledge; 1988."),
          tags$li("Lakens D. Calculating and reporting effect sizes to facilitate cumulative science. Front Psychol. 2013;4:863.")
        )
      )
    ),
    
    # ============================================================
    # NON-INFERIORITY
    # ============================================================
    "noninferiority" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("balance-scale"),
        p("Non-inferiority trials aim to demonstrate that a new treatment is 'not worse' than a reference treatment by more than a pre-specified margin. This is common in generic drug approval, biosimilar studies, and situations where superiority is not expected or ethical."),
        p(strong("Example:"), "Demonstrating a generic formulation has adverse event rates no worse than branded drug +5 percentage points.")
      ),
      accordion_panel(
        title = "Non-Inferiority Margin",
        icon = icon("ruler"),
        p("The non-inferiority margin is the maximum clinically acceptable difference in outcomes."),
        tags$ul(
          tags$li(strong("Clinical judgment:"), "Should be based on what difference would be clinically meaningful"),
          tags$li(strong("Regulatory guidance:"), "FDA/EMA require pre-specification with justification"),
          tags$li(strong("Historical data:"), "Typically smaller than the expected treatment effect of the reference"),
          tags$li(strong("Common practice:"), "Margin should preserve a substantial portion of reference treatment's effect")
        )
      ),
      accordion_panel(
        title = "Regulatory Context",
        icon = icon("gavel"),
        tags$ul(
          tags$li(strong("FDA/EMA requirement:"), "Pre-specification of non-inferiority margin with clinical justification"),
          tags$li(strong("Statistical significance:"), "One-sided α = 0.025 (equivalent to two-sided α = 0.05) is standard"),
          tags$li(strong("Confidence interval:"), "Upper bound of 95% CI must fall below the margin"),
          tags$li(strong("ITT analysis:"), "Intent-to-treat is conservative for non-inferiority; per-protocol often also required")
        )
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(a("FDA Guidance: Non-Inferiority Clinical Trials to Establish Effectiveness",
                    href = "https://www.fda.gov/regulatory-information/search-fda-guidance-documents/non-inferiority-clinical-trials-establish-effectiveness",
                    target = "_blank")),
          tags$li("Piaggio G, et al. Reporting of noninferiority and equivalence randomized trials: extension of the CONSORT 2010 statement. JAMA. 2012;308(24):2594-2604.")
        )
      )
    ),

    # ============================================================
    # PROPENSITY SCORE VIF CALCULATOR
    # ============================================================
    "vif_propensity" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About this Analysis",
        icon = icon("chart-bar"),
        p("The Variance Inflation Factor (VIF) quantifies the efficiency loss when using propensity score weighting methods in observational studies. VIF describes how much larger your sample size needs to be compared to a randomized trial to achieve the same statistical power."),
        p(strong("Method:"), "Based on Austin (2021) methodology for estimating VIF from anticipated treatment prevalence and propensity score model c-statistic."),
        p(strong("Example:"), "If VIF = 2.0, you need 2× the sample size of an RCT (e.g., 1,000 instead of 500) to achieve the same power.")
      ),
      accordion_panel(
        title = "Weighting Methods Explained",
        icon = icon("balance-scale-right"),
        tags$dl(
          tags$dt(strong("ATE (Average Treatment Effect) - IPTW")),
          tags$dd("Inverse probability of treatment weighting. Creates a pseudo-population where treatment is independent of measured confounders. Generalizes to the entire population. Most common but can have high VIF."),

          tags$dt(strong("ATT (Average Treatment effect on Treated)")),
          tags$dd("Estimates the effect specifically in those who received treatment. Useful when interest is in the treated population only (e.g., comparative effectiveness in treated patients)."),

          tags$dt(strong("ATO (Overlap Weights)")),
          tags$dd("Focuses on patients with clinical equipoise (good propensity score overlap). Most efficient method—typically has lowest VIF. Recommended for RWE studies."),

          tags$dt(strong("ATM (Matching Weights)")),
          tags$dd("Mimics 1:1 matching but retains all subjects. Efficient and balances covariates well. Similar VIF to overlap weights."),

          tags$dt(strong("ATEN (Entropy Weights)")),
          tags$dd("Balances covariates while maximizing effective sample size. Similar efficiency to overlap and matching weights.")
        )
      ),
      accordion_panel(
        title = "C-statistic Guidelines",
        icon = icon("chart-line"),
        p("The c-statistic (area under the ROC curve) measures how well the propensity score model discriminates between treated and untreated groups."),
        tags$ul(
          tags$li(strong("0.5 - 0.6:"), "Poor discrimination. May indicate weak confounding or insufficient covariates."),
          tags$li(strong("0.6 - 0.7:"), "Fair discrimination. Typical for claims/EHR data with standard covariates."),
          tags$li(strong("0.7 - 0.8:"), "Good discrimination. Typical for rich registry or cohort data."),
          tags$li(strong("0.8 - 0.9:"), "Very good discrimination. Can lead to high VIF for ATE/ATT; use overlap weights."),
          tags$li(strong("> 0.9:"), "Excellent discrimination. High VIF expected. Consider alternative methods.")
        ),
        p(strong("Typical c-statistics by data source:")),
        tags$ul(
          tags$li("Claims data: 0.60 - 0.70"),
          tags$li("EHR data: 0.65 - 0.75"),
          tags$li("Registry data: 0.70 - 0.80"),
          tags$li("Rich cohort studies: 0.75 - 0.85")
        )
      ),
      accordion_panel(
        title = "VIF Interpretation",
        icon = icon("tachometer-alt"),
        tags$ul(
          tags$li(strong("VIF < 1.3:"), "✅ Minimal efficiency loss. Propensity score weighting is highly efficient."),
          tags$li(strong("VIF 1.3 - 2.0:"), "⚠️ Moderate efficiency loss. Acceptable for most studies. Consider overlap weights for better efficiency."),
          tags$li(strong("VIF 2.0 - 3.0:"), "⚠️ Substantial efficiency loss. Strongly recommend overlap/matching weights instead of ATE/ATT."),
          tags$li(strong("VIF > 3.0:"), "❌ Severe efficiency loss. Propensity score weighting may not be feasible. Consider matching, stratification, or regression adjustment.")
        )
      ),
      accordion_panel(
        title = "Sample Size Adjustment Workflow",
        icon = icon("project-diagram"),
        p("Follow these steps to adjust your sample size for propensity score methods:"),
        tags$ol(
          tags$li(strong("Step 1:"), "Calculate required sample size using standard power analysis (as if it were a randomized trial). Use the other tabs in this tool."),
          tags$li(strong("Step 2:"), "Estimate the c-statistic of your propensity score model based on pilot data, literature, or data source type."),
          tags$li(strong("Step 3:"), "Determine treatment prevalence in your data source."),
          tags$li(strong("Step 4:"), "Select your weighting method (ATE, ATT, ATO, ATM, or ATEN)."),
          tags$li(strong("Step 5:"), "Calculate VIF using this tool."),
          tags$li(strong("Step 6:"), "Multiply your RCT-based sample size by the VIF to get the adjusted sample size: N_adjusted = N_RCT × VIF"),
          tags$li(strong("Step 7:"), "Review the sensitivity analysis table to understand how VIF varies with different assumptions.")
        )
      ),
      accordion_panel(
        title = "Important Cautions",
        icon = icon("exclamation-triangle"),
        tags$ul(
          tags$li(strong("Assumption:"), "VIF estimation assumes the propensity score model will be correctly specified and achieve the anticipated c-statistic."),
          tags$li(strong("Positivity:"), "VIF methods assume positivity (overlap). If there are regions of no overlap, estimates may be inaccurate."),
          tags$li(strong("Pilot data:"), "When possible, use pilot data or similar studies to inform c-statistic estimates."),
          tags$li(strong("2025 update:"), "Recent research (Li & Liu 2025) suggests VIF methods may lack theoretical foundation and can be inaccurate with limited overlap. Use sensitivity analyses."),
          tags$li(strong("Alternative:"), "Consider using methods that focus on the overlap region (ATO, ATM) which are more robust.")
        )
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(strong("Key methodology:"), "Austin PC (2021). Informing power and sample size calculations when using inverse probability of treatment weighting using the propensity score. Statistics in Medicine 40(27):6150-6163."),
          tags$li("Li F, Thomas LE, Li F (2019). Addressing extreme propensity scores via the overlap weights. American Journal of Epidemiology 188(1):250-257."),
          tags$li("Li F, Morgan KL, Zaslavsky AM (2018). Balancing covariates via propensity score weighting. Journal of the American Statistical Association 113(521):390-400."),
          tags$li("Zhou Y, et al. (2020). A comprehensive evaluation of methods for studying continuous exposures using propensity score weighting. Biometrics 76(2):557-569."),
          tags$li(a("PSweight R package documentation",
                    href = "https://cran.r-project.org/package=PSweight",
                    target = "_blank")),
          tags$li("Recent 2025 developments: Li F, Liu L (2025). Sample size and power calculations for causal inference of observational studies. arXiv 2501.11181.")
        )
      )
    ),

    # Default fallback
    NULL
  )
  
  return(help_content)
}

#' Create global help content (Regulatory Guidance & Interpretation Guide)
#' To be used in a Help modal or separate page
create_global_help <- function() {
  accordion(
    id = "global_help_accordion",
    open = FALSE,
    accordion_panel(
      title = "Regulatory Guidance & References",
      icon = icon("book"),
      h5("FDA/EMA Guidance on RWE"),
      tags$ul(
        tags$li(a("FDA - Real-World Evidence Framework",
          href = "https://www.fda.gov/science-research/science-and-research-special-topics/real-world-evidence",
          target = "_blank"
        )),
        tags$li(a("FDA - Use of Real-World Evidence (2023)",
          href = "https://www.fda.gov/regulatory-information/search-fda-guidance-documents/real-world-data-assessing-electronic-health-records-and-medical-claims-data-support-regulatory",
          target = "_blank"
        )),
        tags$li(a("EMA - Real World Evidence Framework",
          href = "https://www.ema.europa.eu/en/about-us/how-we-work/big-data/real-world-evidence",
          target = "_blank"
        ))
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
  )
}

