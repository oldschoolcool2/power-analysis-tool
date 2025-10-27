# Help Content Functions
# Contextual help panels for each analysis type

#' Create contextual help accordion for a specific analysis
#' @param analysis_type The type of analysis (e.g., "single_proportion", "two_group")
#' @return A bslib accordion component with contextual help
#' @importFrom bslib accordion accordion_panel
#' @importFrom shiny tags icon a p strong h5 HTML
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
        p("This analysis performs power and sample size calculations for single proportion hypothesis testing using Cohen's arcsine transformation method. This approach tests whether an observed proportion differs significantly from a reference value."),
        p(strong("Method:"), "Uses the arcsine transformation for proportions (Cohen, 1988), implemented via the pwr.p.test function in R. This is the standard statistical approach for single proportion hypothesis testing."),
        p(strong("Rare Event Detection (Reference = 0%):"), "Testing whether an adverse event rate of 0.2% can be detected with a sample of 1,500 participants at 80% power and α = 0.05."),
        p(strong("Benchmark Comparison (Reference > 0%):"), "Testing whether a new treatment's response rate (75%) exceeds a historical standard of care (65%) with 80% power.")
      ),
      accordion_panel(
        title = "Use Cases",
        icon = icon("lightbulb"),
        tags$ul(
          tags$li(strong("Rare event detection:"), "Post-marketing surveillance, safety monitoring (reference proportion = 0%)"),
          tags$li(strong("Quality improvement:"), "Testing if improvement exceeds current performance baseline"),
          tags$li(strong("Benchmark testing:"), "Comparing against historical controls or published standards"),
          tags$li(strong("Regulatory compliance:"), "Testing if rates meet or exceed specified thresholds")
        )
      ),
      create_clustering_help_panel(),
      create_multiple_testing_help_panel(),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(strong("Primary method:"), "Cohen J. Statistical Power Analysis for the Behavioral Sciences. 2nd ed. Routledge; 1988."),
          tags$li(strong("Implementation:"), "Champely S. pwr: Basic Functions for Power Analysis. R package. CRAN."),
          tags$li(strong("Additional context:"), a("Hanley JA, Lippman-Hand A. If nothing goes wrong, is everything all right? Interpreting zero numerators. JAMA. 1983;249(13):1743-1745.",
                    href = "Hanley-1983-1743.pdf", target = "_blank"), " (Note: The 'Rule of Three' from this paper is for confidence intervals when zero events occur, not for power analysis)")
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
      create_clustering_help_panel(),
      create_multiple_testing_help_panel(),
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
      create_clustering_help_panel(),
      create_multiple_testing_help_panel(),
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
      create_clustering_help_panel(),
      create_multiple_testing_help_panel(),
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
      create_clustering_help_panel(),
      create_multiple_testing_help_panel(),
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
      create_clustering_help_panel(),
      create_multiple_testing_help_panel(),
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
        title = "Comparison: Austin (2021) vs. Li et al. (2025)",
        icon = icon("balance-scale"),
        p(strong("This calculator now offers TWO methods:")),
        tags$dl(
          tags$dt(strong("Austin (2021) - VIF Method (Traditional)")),
          tags$dd(tags$ul(
            tags$li(strong("Inputs:"), "C-statistic + treatment prevalence"),
            tags$li(strong("Pros:"), "Simple, widely used, only requires PS model discrimination"),
            tags$li(strong("Cons:"), "Does NOT account for confounder-outcome association; may underestimate sample size"),
            tags$li(strong("When to use:"), "Quick estimates, when confounder-outcome strength unknown")
          )),

          tags$dt(strong("Li et al. (2025) - Overlap + Confounding Method (NEW)")),
          tags$dd(tags$ul(
            tags$li(strong("Inputs:"), "Overlap coefficient (φ) + confounder-outcome R² + treatment prevalence"),
            tags$li(strong("Pros:"), "Theoretically sound; accounts for BOTH overlap AND confounding strength; more accurate"),
            tags$li(strong("Cons:"), "Requires estimating two additional parameters (φ and R²)"),
            tags$li(strong("When to use:"), "Pilot data available; want accurate estimates; strong confounding expected")
          ))
        ),
        p(strong("Key Innovation of Li et al. (2025):"), "Explicitly models the confounder-outcome association (via R²), which VIF methods omit. This can prevent substantial underestimation of required sample size.")
      ),
      accordion_panel(
        title = "Understanding Li et al. (2025) Parameters",
        icon = icon("info-circle"),
        tags$dl(
          tags$dt(strong("Overlap Coefficient (φ) - Bhattacharyya Measure")),
          tags$dd(tags$ul(
            tags$li("Measures distributional overlap between treated/control propensity scores"),
            tags$li("Range: 0 (no overlap) to 1 (perfect overlap)"),
            tags$li(strong("Interpretation:"),
              tags$ul(
                tags$li("φ ≥ 0.9: Excellent overlap"),
                tags$li("φ = 0.75-0.89: Good overlap"),
                tags$li("φ = 0.5-0.74: Fair overlap"),
                tags$li("φ < 0.5: Poor overlap")
              )),
            tags$li(strong("How to estimate:"), "Pilot study PS distributions, clinical judgment of equipoise, or assume 0.7-0.8 for moderate overlap")
          )),

          tags$dt(strong("Confounder-Outcome R² (ρ²)")),
          tags$dd(tags$ul(
            tags$li("Proportion of outcome variance explained by confounders"),
            tags$li("Bounds the correlation between confounders and outcome"),
            tags$li(strong("Interpretation:"),
              tags$ul(
                tags$li("ρ² < 0.02: Weak confounding (minimal inflation)"),
                tags$li("ρ² = 0.02-0.13: Moderate confounding"),
                tags$li("ρ² = 0.13-0.26: Strong confounding"),
                tags$li("ρ² > 0.26: Very strong confounding (large sample needed)")
              )),
            tags$li(strong("How to estimate:"), "Literature on confounders' effects, regression models from prior studies, or domain knowledge")
          ))
        ),
        p(style = "margin-top: 10px; color: #666;", icon("lightbulb"), " ", strong("Tip:"), " Conduct sensitivity analysis across plausible ranges of φ and R² rather than relying on single values.")
      ),
      accordion_panel(
        title = "Important Cautions",
        icon = icon("exclamation-triangle"),
        tags$ul(
          tags$li(strong("Assumption (Both methods):"), "Propensity score model will be correctly specified and achieve anticipated performance."),
          tags$li(strong("Positivity:"), "Both methods assume positivity (overlap). If there are regions of no overlap, estimates may be inaccurate. Li et al. (2025) is more robust via explicit overlap modeling."),
          tags$li(strong("Pilot data:"), "When possible, use pilot data to inform parameter estimates (c-statistic, φ, R²)."),
          tags$li(strong("Austin method limitation:"), "VIF methods based solely on c-statistic may underestimate sample size when confounder-outcome associations are strong."),
          tags$li(strong("Li et al. recommendation:"), "Authors recommend sensitivity analysis across reasonable ranges of φ and R² based on domain knowledge."),
          tags$li(strong("Overlap weights (ATO):"), "Most efficient weighting method for both approaches; strongly recommended when overlap is limited.")
        )
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(strong("Li et al. (2025) - NEW:"), "Li F, Liu B (2025). Sample size and power calculations for causal inference of observational studies. arXiv 2501.11181. [", a("PDF", href = "https://arxiv.org/pdf/2501.11181", target = "_blank"), "]"),
          tags$li(strong("Austin (2021):"), "Austin PC (2021). Informing power and sample size calculations when using inverse probability of treatment weighting using the propensity score. Statistics in Medicine 40(27):6150-6163."),
          tags$li("Li F, Thomas LE, Li F (2019). Addressing extreme propensity scores via the overlap weights. American Journal of Epidemiology 188(1):250-257."),
          tags$li("Li F, Morgan KL, Zaslavsky AM (2018). Balancing covariates via propensity score weighting. Journal of the American Statistical Association 113(521):390-400."),
          tags$li("Zhou Y, et al. (2020). A comprehensive evaluation of methods for studying continuous exposures using propensity score weighting. Biometrics 76(2):557-569."),
          tags$li(a("PSweight R package documentation",
                    href = "https://cran.r-project.org/package=PSweight",
                    target = "_blank"))
        )
      )
    ),

    # ============================================================
    # MEDIATION ANALYSIS
    # ============================================================
    "mediation_analysis" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About Mediation Analysis",
        icon = icon("project-diagram"),
        p("Mediation analysis examines how an independent variable (X) affects an outcome (Y) through an intermediary variable (M), called the mediator. This analysis quantifies both the ", strong("direct effect"), " (X → Y) and the ", strong("indirect effect"), " (X → M → Y)."),
        p(strong("Path Coefficients:")),
        tags$ul(
          tags$li(strong("Path a:"), "Effect of X on mediator M (X → M)"),
          tags$li(strong("Path b:"), "Effect of mediator M on outcome Y, controlling for X (M → Y|X)"),
          tags$li(strong("Path c':"), "Direct effect of X on Y, controlling for M (X → Y|M)"),
          tags$li(strong("Indirect effect:"), "a × b (the mediated effect)")
        ),
        p(strong("Method:"), "This calculator uses the ", em("Sobel test"), " approach for power calculations, which provides conservative estimates. Path coefficients should be standardized (like Cohen's d).")
      ),
      accordion_panel(
        title = "Use Cases in RWE",
        icon = icon("lightbulb"),
        tags$ul(
          tags$li(strong("Drug → Adherence → Clinical Outcome:"), "Does a drug work by improving medication adherence?"),
          tags$li(strong("Intervention → Biomarker → Disease:"), "Does a treatment affect disease by changing a biological marker?"),
          tags$li(strong("Policy → Access → Health:"), "Does a policy change health by improving healthcare access?"),
          tags$li(strong("Exposure → Pathway → Risk:"), "Does an exposure cause disease through a specific biological pathway?")
        ),
        p(style = "margin-top: 10px; color: #0066cc; background: #e6f2ff; padding: 10px; border-radius: 5px;",
          icon("info-circle"), " ",
          strong("Key Insight:"), " Mediation analysis helps answer ", em("\"how\""), " and ", em("\"why\""), " a treatment works, not just ", em("\"if\""), " it works.")
      ),
      accordion_panel(
        title = "Calculation Modes",
        icon = icon("calculator"),
        tags$dl(
          tags$dt(strong("1. Calculate Power")),
          tags$dd("Given your available sample size and expected path coefficients, what is the power to detect the indirect effect?"),
          tags$dt(strong("2. Calculate Sample Size")),
          tags$dd("Given your expected path coefficients and desired power (typically 80%), how many participants do you need?"),
          tags$dt(strong("3. Calculate Minimal Detectable Effect")),
          tags$dd("Given your available sample size and desired power, what is the smallest indirect effect (path b, given path a) you can reliably detect?")
        )
      ),
      accordion_panel(
        title = "Interpreting Path Coefficients",
        icon = icon("chart-line"),
        p("Path coefficients are typically standardized (like Cohen's d). Guidelines for interpretation:"),
        tags$div(
          style = "background-color: #f8f9fa; padding: 10px; border-left: 3px solid #007bff; margin: 10px 0;",
          tags$table(
            class = "table table-sm",
            tags$thead(
              tags$tr(
                tags$th("Effect Size"),
                tags$th("Interpretation"),
                tags$th("Example")
              )
            ),
            tags$tbody(
              tags$tr(
                tags$td(strong("< 0.1")),
                tags$td("Negligible"),
                tags$td("Minimal practical impact")
              ),
              tags$tr(
                tags$td(strong("0.1 - 0.3")),
                tags$td("Small"),
                tags$td("Detectable but modest effect")
              ),
              tags$tr(
                tags$td(strong("0.3 - 0.5")),
                tags$td("Medium"),
                tags$td("Substantial, meaningful effect")
              ),
              tags$tr(
                tags$td(strong("> 0.5")),
                tags$td("Large"),
                tags$td("Strong, important effect")
              )
            )
          )
        ),
        p(strong("Indirect Effect (a × b):"), " The product of paths a and b. Even with moderate individual paths (e.g., a=0.3, b=0.3), the indirect effect is small (0.3 × 0.3 = 0.09), requiring larger sample sizes.")
      ),
      accordion_panel(
        title = "Important Considerations",
        icon = icon("exclamation-triangle"),
        tags$ul(
          tags$li(strong("Temporal ordering:"), "The mediator (M) must occur after the exposure (X) and before the outcome (Y). Cross-sectional data cannot establish mediation."),
          tags$li(strong("Confounding:"), "Confounders can bias mediation analysis. Consider unmeasured confounding of M → Y relationship."),
          tags$li(strong("Sample size:"), "Mediation analysis typically requires larger samples than testing direct effects because the indirect effect (a × b) is often small."),
          tags$li(strong("Sobel test limitations:"), "The Sobel test assumes normality and may be conservative. Bootstrap methods provide more accurate power but require simulation."),
          tags$li(strong("Effect size estimation:"), "Base path coefficients on pilot data, literature, or domain expertise. Overestimating effect sizes leads to underpowered studies."),
          tags$li(strong("Multiple mediators:"), "This calculator handles single mediator models. Multiple mediators require more complex approaches.")
        )
      ),
      accordion_panel(
        title = "Sample Size Guidelines",
        icon = icon("users"),
        p("Rule of thumb for detecting indirect effects at 80% power (α = 0.05, two-sided):"),
        tags$ul(
          tags$li(strong("Small indirect effect (a × b = 0.01 - 0.09):"), "N ≥ 500 - 1,500"),
          tags$li(strong("Medium indirect effect (a × b = 0.09 - 0.25):"), "N ≥ 200 - 500"),
          tags$li(strong("Large indirect effect (a × b > 0.25):"), "N ≥ 100 - 200")
        ),
        p(style = "margin-top: 10px; color: #856404; background: #fff3cd; padding: 10px; border-radius: 5px;",
          icon("exclamation-triangle"), " ",
          strong("Warning:"), " Many mediation studies in the literature are underpowered. Always conduct a prospective power analysis!")
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li("Preacher KJ, Hayes AF (2008). Asymptotic and resampling strategies for assessing and comparing indirect effects in multiple mediator models. Behavior Research Methods 40(3):879-891."),
          tags$li("Fritz MS, MacKinnon DP (2007). Required sample size to detect the mediated effect. Psychological Science 18(3):233-239."),
          tags$li("Schoemann AM, et al. (2017). Determining power and sample size for simple and complex mediation models. Social Psychological and Personality Science 8(4):379-386."),
          tags$li("VanderWeele TJ (2015). Explanation in Causal Inference: Methods for Mediation and Interaction. Oxford University Press."),
          tags$li(a("powerMediation R package documentation",
                    href = "https://cran.r-project.org/package=powerMediation",
                    target = "_blank"))
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
          href = "https://www.ema.europa.eu/en/about-us/how-we-work/data-regulation-big-data-other-sources/real-world-evidence",
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
    ),

    # ============================================================
    # SENSITIVITY ANALYSES - E-VALUE
    # ============================================================
    "sensitivity_evalue" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About E-values",
        icon = icon("shield-alt"),
        p("E-values quantify the minimum strength of association that an unmeasured confounder would need to have with both the treatment and outcome to fully explain away an observed association. Higher E-values indicate greater robustness to unmeasured confounding."),
        p(strong("When to use:"), "E-values are calculated in the ", strong("report phase"), " after completing your analysis. They are ", em("not"), " used during protocol design or sample size planning."),
        p(strong("Example:"), "If your study found RR = 2.5 with E-value = 4.0, an unmeasured confounder would need to be associated with both treatment and outcome by a risk ratio of 4.0-fold each to completely explain away your finding.")
      ),
      accordion_panel(
        title = "When to Use E-values",
        icon = icon("calendar-check"),
        tags$ul(
          tags$li(strong("Report phase:"), "After data analysis is complete and effect estimates are obtained"),
          tags$li(strong("Observational studies:"), "Particularly important when randomization is not feasible"),
          tags$li(strong("Sensitivity analysis:"), "To assess robustness of findings to unmeasured confounding"),
          tags$li(strong("Publication:"), "Many journals now request E-values for observational research"),
          tags$li(strong("Regulatory submissions:"), "Increasingly expected for real-world evidence studies")
        ),
        p(style = "margin-top: 10px; color: #dc3545; background: #f8d7da; padding: 10px; border-radius: 5px;",
          icon("exclamation-triangle"), " ",
          strong("Important:"), " E-values do NOT replace good study design, randomization, or careful confounder control. They help quantify robustness of results but cannot prove causation.")
      ),
      accordion_panel(
        title = "Interpreting E-values",
        icon = icon("chart-line"),
        p("E-value magnitude provides insight into how robust your findings are to unmeasured confounding:"),
        tags$div(
          style = "background-color: #f8f9fa; padding: 10px; border-left: 3px solid #007bff; margin: 10px 0;",
          tags$table(
            class = "table table-sm",
            tags$thead(
              tags$tr(
                tags$th("E-value Range"),
                tags$th("Robustness"),
                tags$th("Interpretation")
              )
            ),
            tags$tbody(
              tags$tr(
                tags$td(strong("< 1.5")),
                tags$td(style = "color: #dc3545;", "Weak"),
                tags$td("Minor unmeasured confounding could explain away the effect")
              ),
              tags$tr(
                tags$td(strong("1.5 - 2.0")),
                tags$td(style = "color: #fd7e14;", "Moderate"),
                tags$td("Requires moderate confounding to explain away the effect")
              ),
              tags$tr(
                tags$td(strong("2.0 - 3.0")),
                tags$td(style = "color: #28a745;", "Strong"),
                tags$td("Requires strong confounding to explain away the effect")
              ),
              tags$tr(
                tags$td(strong("> 3.0")),
                tags$td(style = "color: #007bff;", "Very Strong"),
                tags$td("Effect is highly robust to unmeasured confounding")
              )
            )
          )
        ),
        p(strong("Practical consideration:"), "Ask yourself: 'Is an unmeasured confounder of this magnitude plausible in my study?' Consider known confounders and compare their effect sizes to the E-value.")
      ),
      accordion_panel(
        title = "Effect Measure Types",
        icon = icon("calculator"),
        tags$dl(
          tags$dt(strong("Relative Risk (RR)")),
          tags$dd("Used for cohort studies and RCTs. Most intuitive measure. RR > 1 indicates increased risk."),

          tags$dt(strong("Odds Ratio (OR)")),
          tags$dd("Used for case-control studies and logistic regression. For rare outcomes (<15%), OR approximates RR. For common outcomes, OR is converted to RR before calculating E-values."),

          tags$dt(strong("Hazard Ratio (HR)")),
          tags$dd("Used for survival analysis and Cox regression. Represents instantaneous risk over time."),

          tags$dt(strong("Mean Difference (MD)")),
          tags$dd("Used for continuous outcomes. The tool converts MD to risk ratio scale for E-value calculation.")
        )
      ),
      accordion_panel(
        title = "Confidence Interval E-values",
        icon = icon("chart-area"),
        p("You can optionally calculate E-values for the confidence interval bounds:"),
        tags$ul(
          tags$li(strong("Point estimate E-value:"), "Confounding needed to shift point estimate to null"),
          tags$li(strong("CI limit E-value:"), "Confounding needed to shift confidence interval to include null"),
          tags$li(strong("Conservative interpretation:"), "Use the CI E-value for most conservative assessment")
        ),
        p(style = "margin-top: 10px;",
          strong("Recommendation:"), " Always report both point estimate and CI E-values. The CI E-value is more conservative and accounts for statistical uncertainty.")
      ),
      accordion_panel(
        title = "Limitations & Important Notes",
        icon = icon("exclamation-circle"),
        tags$ul(
          tags$li(strong("Single unmeasured confounder:"), "E-values assume a single unmeasured confounder. Multiple weak confounders could jointly explain away findings."),
          tags$li(strong("Not a hypothesis test:"), "E-values do not provide p-values or formal tests. They are descriptive sensitivity measures."),
          tags$li(strong("Assumes no measurement error:"), "E-values assume measured confounders are correctly measured. Measurement error in covariates can bias results."),
          tags$li(strong("Binary exposure assumption:"), "Standard E-values assume binary exposure/treatment. Extensions exist for continuous exposures."),
          tags$li(strong("Does not prove causation:"), "A high E-value suggests robustness but does not prove causal relationship."),
          tags$li(strong("Subject matter knowledge required:"), "Interpretation requires domain expertise to assess plausibility of unmeasured confounders.")
        ),
        p(style = "margin-top: 10px; background: #fff3cd; padding: 10px; border-radius: 5px;",
          icon("lightbulb"), " ",
          strong("Best Practice:"), " Use E-values as one component of a comprehensive sensitivity analysis strategy. Combine with negative controls, dose-response analyses, and triangulation across study designs.")
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(strong("Original E-value paper:"), "VanderWeele TJ, Ding P. Sensitivity Analysis in Observational Research: Introducing the E-Value. Annals of Internal Medicine. 2017;167(4):268-274. [",
            a("doi:10.7326/M16-2607", href = "https://doi.org/10.7326/M16-2607", target = "_blank"), "]"),
          tags$li(strong("Technical details:"), "Ding P, VanderWeele TJ. Sensitivity Analysis Without Assumptions. Epidemiology. 2016;27(3):368-377."),
          tags$li(strong("Applied examples:"), "VanderWeele TJ, Ding P, Mathur M. Technical Considerations in the Use of the E-Value. Journal of Causal Inference. 2019;7(2):20180007."),
          tags$li(strong("E-value calculator website:"), a("www.evalue-calculator.com", href = "https://www.evalue-calculator.com", target = "_blank")),
          tags$li(strong("EValue R package:"), a("CRAN - EValue package", href = "https://cran.r-project.org/package=EValue", target = "_blank"))
        )
      )
    ),

    # ============================================================
    # SENSITIVITY ANALYSES - MULTIPLE-BIAS
    # ============================================================
    "sensitivity_multi_bias" = accordion(
      id = paste0("help_", analysis_type),
      open = FALSE,
      accordion_panel(
        title = "About Multiple-Bias Analysis",
        icon = icon("layer-group"),
        p("Multiple-bias sensitivity analysis allows you to assess the joint impact of unmeasured confounding, selection bias, and differential misclassification acting together. This approach recognizes that real studies are typically affected by multiple biases simultaneously, not just one in isolation."),
        p(strong("When to use:"), "Multiple-bias analysis is performed in the ", strong("report phase"), " after completing your analysis. It provides a more comprehensive and realistic assessment than single-bias sensitivity analysis."),
        p(strong("Example:"), "If your study found RR = 3.0 and the multi-bias E-value = 2.0, all bias parameters (confounding, selection, misclassification) would need to simultaneously reach a magnitude of at least 2.0 to fully explain away your finding.")
      ),
      accordion_panel(
        title = "Types of Biases Included",
        icon = icon("list-check"),
        tags$dl(
          tags$dt(strong("Unmeasured Confounding")),
          tags$dd("Represents confounders not adjusted for in your study. Characterized by two parameters: the confounder-exposure association and confounder-outcome association."),

          tags$dt(strong("Selection Bias")),
          tags$dd("Occurs when the study sample differs systematically from the target population. Can be specified as 'general' (inference about total population) or 'selected' (inference about selected population only)."),

          tags$dt(strong("Differential Misclassification")),
          tags$dd("Measurement error that differs between exposure groups. Can affect either outcome or exposure measurements. Requires specification of sensitivity and specificity parameters.")
        ),
        p(style = "margin-top: 10px; background: #e7f3ff; padding: 10px; border-radius: 5px;",
          icon("lightbulb"), " ",
          strong("Tip:"), " Start by including biases most plausible in your study context. You can always add more bias types to see how results change.")
      ),
      accordion_panel(
        title = "Two Analysis Modes",
        icon = icon("calculator"),
        tags$div(
          style = "background-color: #f8f9fa; padding: 10px; border-left: 3px solid #007bff; margin: 10px 0;",
          tags$p(strong("1. Multi-Bias E-value"), style = "margin-top: 0;"),
          tags$p("Calculates the minimum value that ", em("all"), " bias parameters must take on simultaneously to explain away your observed effect. This is the most common use case."),
          tags$p(strong("Example:"), "Multi-bias E-value = 1.8 means each bias parameter (RRAUc, RRUcY, RRSUsA1, etc.) must be at least 1.8 to jointly explain away the effect.")
        ),
        tags$div(
          style = "background-color: #f8f9fa; padding: 10px; border-left: 3px solid #28a745; margin: 10px 0;",
          tags$p(strong("2. Bias-Adjusted Bound"), style = "margin-top: 0;"),
          tags$p("Calculates what your effect estimate would be ", em("after"), " adjusting for biases of specific magnitudes you specify. Useful for 'what-if' scenarios."),
          tags$p(strong("Example:"), "If you suspect RRAUc = 2.0 and RRUcY = 1.5, the bound shows your adjusted RR accounting for these specific biases.")
        )
      ),
      accordion_panel(
        title = "Interpreting Multi-Bias E-values",
        icon = icon("chart-line"),
        p("Multi-bias E-value magnitude indicates robustness to combined biases:"),
        tags$table(
          class = "table table-sm",
          style = "margin-top: 10px;",
          tags$thead(
            tags$tr(
              tags$th("E-value Range"),
              tags$th("Interpretation"),
              tags$th("Robustness")
            )
          ),
          tags$tbody(
            tags$tr(
              tags$td(strong("< 1.5")),
              tags$td("Minor bias combinations could explain effect"),
              tags$td(tags$span(style = "color: #dc3545;", "Weak"))
            ),
            tags$tr(
              tags$td(strong("1.5 - 2.0")),
              tags$td("Requires moderate bias combinations"),
              tags$td(tags$span(style = "color: #fd7e14;", "Moderate"))
            ),
            tags$tr(
              tags$td(strong("2.0 - 3.0")),
              tags$td("Requires strong bias combinations"),
              tags$td(tags$span(style = "color: #28a745;", "Strong"))
            ),
            tags$tr(
              tags$td(strong("> 3.0")),
              tags$td("Highly robust to multiple biases"),
              tags$td(tags$span(style = "color: #0d6efd;", "Very Strong"))
            )
          )
        ),
        p(style = "margin-top: 10px;",
          strong("Key insight:"), " Multi-bias E-values are often lower than single-bias E-values because multiple biases can work together to explain away an effect, even if each individual bias is modest.")
      ),
      accordion_panel(
        title = "Advantages Over Single-Bias Analysis",
        icon = icon("trophy"),
        tags$ul(
          tags$li(strong("More realistic:"), "Real studies face multiple biases, not just one in isolation"),
          tags$li(strong("More conservative:"), "Accounts for biases working in concert to explain findings"),
          tags$li(strong("More comprehensive:"), "Provides a fuller picture of study vulnerability"),
          tags$li(strong("More informative:"), "Shows how different bias combinations could affect results"),
          tags$li(strong("Better decision-making:"), "Helps prioritize which biases to address in study design or analysis")
        )
      ),
      accordion_panel(
        title = "Limitations & Important Notes",
        icon = icon("exclamation-circle"),
        tags$ul(
          tags$li(strong("Assumes independence:"), "Multi-bias analysis assumes biases act independently. In reality, some biases may be correlated."),
          tags$li(strong("Complexity:"), "More bias types mean more parameters to specify, which can be challenging without prior knowledge."),
          tags$li(strong("Not a hypothesis test:"), "Like single-bias E-values, multi-bias E-values are descriptive sensitivity measures, not formal tests."),
          tags$li(strong("Subject matter expertise required:"), "Interpretation requires domain knowledge to assess plausibility of bias combinations."),
          tags$li(strong("Ordering matters:"), "The sequence of biases (e.g., selection before measurement) affects parameter interpretation.")
        ),
        p(style = "margin-top: 10px; background: #fff3cd; padding: 10px; border-radius: 5px;",
          icon("lightbulb"), " ",
          strong("Best Practice:"), " Start with the biases most likely in your study. Compare multi-bias E-values to single-bias E-values to understand how biases interact.")
      ),
      accordion_panel(
        title = "References",
        icon = icon("book"),
        tags$ul(
          tags$li(strong("Selection bias bounds:"), "Smith LH, VanderWeele TJ. Bounding Bias Due to Selection. Epidemiology. 2019;30(4):509-516."),
          tags$li(strong("Multiple-bias methods:"), "Mathur MB, VanderWeele TJ. Sensitivity Analysis for Unmeasured Confounding in Meta-Analyses. Journal of the American Statistical Association. 2020;115(529):163-172."),
          tags$li(strong("EValue package vignette:"), a("Multiple-bias sensitivity analysis", href = "https://cran.r-project.org/web/packages/EValue/vignettes/multiple-bias.html", target = "_blank")),
          tags$li(strong("EValue R package:"), a("CRAN - EValue package", href = "https://cran.r-project.org/package=EValue", target = "_blank"))
        )
      )
    )
  )
}

#' Create clustering/design effect help accordion panel
#' @return accordion_panel for clustering adjustment
#' @noRd
create_clustering_help_panel <- function() {
  accordion_panel(
    title = "Clustered Data & Design Effect",
    icon = icon("sitemap"),
    p(strong("What is clustered data?"),
      "In many real-world studies, participants are grouped within clusters (hospitals, clinics, geographic regions, practices). Observations within the same cluster tend to be more similar than those from different clusters, violating the independence assumption."),

    h5("When to Use Clustering Adjustment"),
    tags$ul(
      tags$li(strong("Multi-site studies:"), "Patients recruited from multiple hospitals or clinics"),
      tags$li(strong("Geographic clustering:"), "Participants grouped by region, city, or county"),
      tags$li(strong("Provider-level clustering:"), "Patients treated by the same physician or practice"),
      tags$li(strong("EHR/Claims data:"), "Patients naturally clustered within health systems")
    ),

    h5("Design Effect (DE)"),
    p("The design effect quantifies the loss of statistical efficiency due to clustering:"),
    tags$div(
      style = "background-color: #f8f9fa; padding: 10px; border-left: 3px solid #007bff; margin: 10px 0;",
      tags$strong("DE = 1 + (m - 1) × ICC"),
      tags$br(),
      tags$small("Where m = average cluster size, ICC = intraclass correlation coefficient")
    ),
    p("The required sample size is then: ", tags$strong("N_required = N_unclustered × DE")),

    h5("Intraclass Correlation (ICC)"),
    p("ICC measures the proportion of total variance attributable to clustering. Typical values from meta-analyses:"),
    tags$ul(
      tags$li(strong("Behavioral outcomes:"), "0.01 - 0.05 (e.g., smoking, adherence)"),
      tags$li(strong("Clinical/physiological outcomes:"), "0.01 - 0.10 (e.g., blood pressure, cholesterol)"),
      tags$li(strong("Process measures:"), "0.10 - 0.30 (e.g., quality metrics, provider practices)"),
      tags$li(strong("General practice level:"), "~0.017 (average across primary care studies)")
    ),

    h5("Impact on Sample Size"),
    tags$div(
      style = "background-color: #fff3cd; padding: 10px; border-left: 3px solid #ffc107; margin: 10px 0;",
      tags$strong("Example:"),
      tags$br(),
      "With 25 patients per hospital (m = 25) and ICC = 0.05:",
      tags$br(),
      "DE = 1 + (25-1) × 0.05 = 2.2",
      tags$br(),
      "This means you need ", tags$strong("2.2× more participants"), " than an unclustered study!"
    ),

    h5("Recommendations"),
    tags$ul(
      tags$li(strong("Minimum clusters:"), "At least 10-15 clusters for reliable inference"),
      tags$li(strong("Estimate ICC:"), "Use literature values from similar outcomes/settings"),
      tags$li(strong("Report design effect:"), "Always report DE and ICC in protocols and publications"),
      tags$li(strong("Analysis:"), "Use mixed-effects models or GEE to account for clustering in analysis")
    ),

    h5("References"),
    tags$ul(
      tags$li("Donner A, Klar N. Design and Analysis of Cluster Randomization Trials in Health Research. Arnold, 2000."),
      tags$li("Campbell MK, et al. Sample size calculator for cluster randomized trials. Computers in Biology and Medicine. 2004;34(2):113-125."),
      tags$li("Adams G, et al. Patterns of intra-cluster correlation from primary care research. Statistics in Medicine. 2004;23(12):1655-1665.")
    )
  )
}

#' Create Multiple Testing Corrections Help Panel
#' @return accordion_panel for multiple testing corrections
#' @noRd
create_multiple_testing_help_panel <- function() {
  accordion_panel(
    title = "Multiple Testing Corrections",
    icon = icon("tasks"),
    p(strong("Why adjust for multiple testing?"),
      "When conducting multiple statistical tests (e.g., multiple outcomes, endpoints, or subgroups), the probability of finding at least one statistically significant result by chance alone (Type I error) increases dramatically. Multiple testing corrections adjust for this inflation."),

    h5("The Multiple Comparisons Problem"),
    tags$div(
      style = "background-color: #fff3cd; padding: 10px; border-left: 3px solid #ffc107; margin: 10px 0;",
      tags$strong("Example without correction:"),
      tags$br(),
      "At α = 0.05, conducting 5 independent tests:",
      tags$br(),
      "P(≥1 false positive) = 1 - (1 - 0.05)⁵ = ", tags$strong("23%"),
      tags$br(),
      "Not 5% as intended!"
    ),

    h5("Common Correction Methods"),
    tags$dl(
      tags$dt(strong("Bonferroni Correction")),
      tags$dd(tags$ul(
        tags$li(strong("Formula:"), "α_adjusted = α / k (k = number of tests)"),
        tags$li(strong("Controls:"), "Family-Wise Error Rate (FWER)"),
        tags$li(strong("Pros:"), "Simple, guarantees strong Type I error control"),
        tags$li(strong("Cons:"), "Very conservative, substantial power loss with many tests"),
        tags$li(strong("When to use:"), "Few tests (k ≤ 5), confirmatory analyses")
      )),

      tags$dt(strong("Holm-Bonferroni (Recommended)")),
      tags$dd(tags$ul(
        tags$li(strong("Type:"), "Sequential step-down procedure"),
        tags$li(strong("Controls:"), "FWER"),
        tags$li(strong("Pros:"), "Uniformly more powerful than Bonferroni"),
        tags$li(strong("Cons:"), "Still conservative with many tests"),
        tags$li(strong("When to use:"), "Preferred over Bonferroni in most cases")
      )),

      tags$dt(strong("Benjamini-Hochberg (FDR)")),
      tags$dd(tags$ul(
        tags$li(strong("Controls:"), "False Discovery Rate (FDR) instead of FWER"),
        tags$li(strong("Pros:"), "Much better power, allows some false positives"),
        tags$li(strong("Cons:"), "Less stringent control than FWER methods"),
        tags$li(strong("When to use:"), "Exploratory analyses, many tests (k > 10), hypothesis generation")
      ))
    ),

    h5("FWER vs. FDR: Which to Choose?"),
    tags$div(
      style = "background-color: #f8f9fa; padding: 10px; border-left: 3px solid #007bff; margin: 10px 0;",
      tags$strong("Family-Wise Error Rate (FWER):"),
      tags$br(),
      "Probability of making ≥1 Type I error across ALL tests",
      tags$br(),
      tags$em("Choose for: Confirmatory studies, regulatory submissions"),
      tags$br(),
      tags$br(),
      tags$strong("False Discovery Rate (FDR):"),
      tags$br(),
      "Expected proportion of false positives among rejected hypotheses",
      tags$br(),
      tags$em("Choose for: Exploratory studies, large-scale screening, hypothesis generation")
    ),

    h5("Impact on Sample Size"),
    p("Adjusting alpha typically requires increasing sample size to maintain power:"),
    tags$ul(
      tags$li("With Bonferroni (k=5): α_adjusted = 0.01 → requires ~1.6× more participants"),
      tags$li("With Holm (k=5): Similar to Bonferroni for sample size planning"),
      tags$li("With Benjamini-Hochberg: Minimal sample size increase (controls FDR, not FWER)")
    ),

    h5("When to Use Multiple Testing Corrections"),
    tags$ul(
      tags$li(strong("Multiple primary outcomes:"), "Testing efficacy on 3+ different endpoints"),
      tags$li(strong("Subgroup analyses:"), "Testing treatment effects in multiple subgroups"),
      tags$li(strong("Interim analyses:"), "Multiple looks at data during trial (use group sequential methods)"),
      tags$li(strong("Secondary endpoints:"), "Testing multiple secondary outcomes"),
      tags$li(strong("NOT needed for:"), "Single pre-specified primary endpoint")
    ),

    h5("Recommendations"),
    tags$ul(
      tags$li(strong("Pre-specify:"), "Declare all planned tests and correction method in protocol"),
      tags$li(strong("Hierarchy:"), "Use hierarchical testing to avoid corrections (test sequentially, stop if non-significant)"),
      tags$li(strong("Choice of method:"), "Holm for confirmatory (k ≤ 10), Benjamini-Hochberg for exploratory (k > 10)"),
      tags$li(strong("Reporting:"), "Always report both unadjusted and adjusted p-values"),
      tags$li(strong("Pilot studies:"), "No correction needed for exploratory pilot analyses")
    ),

    h5("References"),
    tags$ul(
      tags$li("Bonferroni CE. Teoria statistica delle classi e calcolo delle probabilita. Pubblicazioni del R Istituto Superiore di Scienze Economiche e Commerciali di Firenze. 1936;8:3-62."),
      tags$li("Holm S. A simple sequentially rejective multiple test procedure. Scandinavian Journal of Statistics. 1979;6(2):65-70."),
      tags$li("Benjamini Y, Hochberg Y. Controlling the false discovery rate: a practical and powerful approach to multiple testing. Journal of the Royal Statistical Society: Series B. 1995;57(1):289-300."),
      tags$li("Dmitrienko A, D'Agostino RB Sr. Multiplicity considerations in clinical trials. New England Journal of Medicine. 2018;378(22):2115-2122."),
      tags$li("Noble WS. How does multiple testing correction work? Nature Biotechnology. 2009;27(12):1135-1137.")
    )
  )
}

