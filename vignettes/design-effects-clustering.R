## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)


## ----de-examples, echo=FALSE--------------------------------------------------
de_examples <- data.frame(
  Cluster_Size = c(10, 25, 50, 100, 10, 25, 50, 100, 10, 25, 50, 100),
  ICC = c(rep(0.01, 4), rep(0.05, 4), rep(0.10, 4)),
  Design_Effect = c(
    1 + (10-1)*0.01, 1 + (25-1)*0.01, 1 + (50-1)*0.01, 1 + (100-1)*0.01,
    1 + (10-1)*0.05, 1 + (25-1)*0.05, 1 + (50-1)*0.05, 1 + (100-1)*0.05,
    1 + (10-1)*0.10, 1 + (25-1)*0.10, 1 + (50-1)*0.10, 1 + (100-1)*0.10
  ),
  stringsAsFactors = FALSE
)

library(knitr)
kable(de_examples, caption = "Design Effect by Cluster Size and ICC", digits = 2)


## ----example-calc, eval=FALSE-------------------------------------------------
# library(PowerAnalysisTool)
# 
# # Step 1: Calculate design effect
# de <- calc_design_effect(cluster_size = 50, icc = 0.05)
# # Result: DE = 1 + (50 - 1) × 0.05 = 3.45
# 
# # Step 2: Inflate sample size
# n_clustered <- calc_clustered_n(n_unclustered = 400, design_effect = de)
# # Result: N = 400 × 3.45 = 1,380 participants
# 
# # Step 3: Calculate number of clusters needed
# k <- calc_n_clusters(n_total = 1380, cluster_size = 50)
# # Result: K = 1,380 / 50 = 28 hospitals
# 
# # Interpretation
# interp <- format_design_effect_interpretation(
#   design_effect = de,
#   n_unclustered = 400,
#   cluster_size = 50,
#   icc = 0.05
# )
# print(interp)


## ----icc-pilot, eval=FALSE----------------------------------------------------
# # Example in R using lme4
# library(lme4)
# 
# # Fit random intercept model: outcome ~ fixed effects + (1 | cluster)
# model <- lmer(blood_pressure ~ age + sex + treatment + (1 | hospital_id), data = pilot_data)
# 
# # Extract variance components
# vc <- as.data.frame(VarCorr(model))
# var_between <- vc$vcov[vc$grp == "hospital_id"]
# var_within <- vc$vcov[vc$grp == "Residual"]
# 
# # Calculate ICC
# icc_estimate <- var_between / (var_between + var_within)
# cat("Estimated ICC:", round(icc_estimate, 3))


## ----typical-icc, echo=FALSE--------------------------------------------------
icc_table <- data.frame(
  Domain = c("Behavioral outcomes",
             "Clinical/physiological outcomes",
             "Process measures",
             "General practice level",
             "Mortality outcomes",
             "Hospital characteristics",
             "Classroom-level education"),
  Typical_ICC = c("0.01 - 0.05",
                  "0.01 - 0.10",
                  "0.10 - 0.30",
                  "0.017 (median)",
                  "0.005 - 0.015",
                  "0.05 - 0.20",
                  "0.10 - 0.25"),
  Recommended = c("0.025",
                  "0.05",
                  "0.20",
                  "0.017",
                  "0.01",
                  "0.10",
                  "0.15"),
  Example = c("Smoking cessation, exercise adherence",
              "Blood pressure, HbA1c, weight",
              "Guideline adherence, prescribing patterns",
              "UK GP practices (various outcomes)",
              "30-day mortality, in-hospital death",
              "Length of stay, complications",
              "Test scores, attendance"),
  stringsAsFactors = FALSE
)

kable(icc_table, caption = "Typical ICC Values by Domain and Outcome Type")


## ----builtin-icc, eval=FALSE--------------------------------------------------
# # Get typical ICC for clinical outcomes
# icc_clinical <- get_typical_icc("clinical")
# # Returns: 0.05
# 
# # Get typical ICC for behavioral outcomes
# icc_behavioral <- get_typical_icc("behavioral")
# # Returns: 0.025
# 
# # Get typical ICC for process measures
# icc_process <- get_typical_icc("process")
# # Returns: 0.20
# 
# # Get typical ICC for GP practices
# icc_gp <- get_typical_icc("gp")
# # Returns: 0.017


## ----sensitivity-icc, eval=FALSE----------------------------------------------
# # Expected ICC: 0.05
# de_expected <- calc_design_effect(cluster_size = 40, icc = 0.05)
# n_expected <- calc_clustered_n(n_unclustered = 300, design_effect = de_expected)
# 
# # Best case (lower ICC): 0.02
# de_best <- calc_design_effect(cluster_size = 40, icc = 0.02)
# n_best <- calc_clustered_n(n_unclustered = 300, design_effect = de_best)
# 
# # Worst case (higher ICC): 0.10
# de_worst <- calc_design_effect(cluster_size = 40, icc = 0.10)
# n_worst <- calc_clustered_n(n_unclustered = 300, design_effect = de_worst)
# 
# cat("Best case (ICC=0.02):", n_best, "participants\n")
# cat("Expected (ICC=0.05):", n_expected, "participants\n")
# cat("Worst case (ICC=0.10):", n_worst, "participants\n")


## ----tradeoff, echo=FALSE-----------------------------------------------------
tradeoff_data <- data.frame(
  Scenario = c("A: Many small clusters", "B: Moderate", "C: Moderate", "D: Few large clusters"),
  N_Clusters = c(100, 50, 25, 10),
  Cluster_Size = c(10, 20, 40, 100),
  Design_Effect = c(
    1 + (10-1)*0.05,
    1 + (20-1)*0.05,
    1 + (40-1)*0.05,
    1 + (100-1)*0.05
  ),
  Effective_N = c(
    1000 / (1 + (10-1)*0.05),
    1000 / (1 + (20-1)*0.05),
    1000 / (1 + (40-1)*0.05),
    1000 / (1 + (100-1)*0.05)
  ),
  stringsAsFactors = FALSE
)

kable(tradeoff_data, caption = "Trade-off Between Cluster Size and Number of Clusters", digits = 1)


## ----validation-example, eval=FALSE-------------------------------------------
# # Validate clustering parameters
# validation <- validate_clustering_params(
#   n_clusters = 8,
#   cluster_size = 50,
#   icc = 0.05
# )
# 
# if (!validation$valid) {
#   cat("ERRORS detected:\n")
#   print(validation$messages[grepl("ERROR", validation$messages)])
# }
# 
# if (any(grepl("WARNING", validation$messages))) {
#   cat("\nWARNINGS:\n")
#   print(validation$messages[grepl("WARNING", validation$messages)])
# }


## ----case1-calc, eval=FALSE---------------------------------------------------
# # Step 1: Design effect
# de <- calc_design_effect(cluster_size = 30, icc = 0.017)
# # Result: DE = 1 + (30 - 1) × 0.017 = 1.493
# 
# # Step 2: Inflated sample size
# n_clustered <- calc_clustered_n(n_unclustered = 220, design_effect = de)
# # Result: N = 220 × 1.493 = 329 patients
# 
# # Step 3: Number of practices
# k <- calc_n_clusters(n_total = 329, cluster_size = 30)
# # Result: K = 329 / 30 = 11 practices
# 
# # Interpretation
# cat("Need:", n_clustered, "patients across", k, "practices\n")
# cat("Per arm:", ceiling(k / 2), "practices (assuming equal allocation)\n")


## ----case1-sens, eval=FALSE---------------------------------------------------
# # Worst case: ICC = 0.05 (clinical outcome, upper range)
# de_worst <- calc_design_effect(cluster_size = 30, icc = 0.05)
# n_worst <- calc_clustered_n(n_unclustered = 220, design_effect = de_worst)
# k_worst <- calc_n_clusters(n_total = n_worst, cluster_size = 30)
# 
# cat("Worst case (ICC=0.05):", n_worst, "patients across", k_worst, "practices\n")


## ----case2-problem, eval=FALSE------------------------------------------------
# de <- calc_design_effect(cluster_size = 100, icc = 0.05)
# # Result: DE = 1 + (100 - 1) × 0.05 = 5.95
# 
# n_clustered <- calc_clustered_n(n_unclustered = 500, design_effect = de)
# # Result: N = 500 × 5.95 = 2,975 patients
# 
# k <- calc_n_clusters(n_total = 2975, cluster_size = 100)
# # Result: K = 2,975 / 100 = 30 hospitals


## ----case2-solution, eval=FALSE-----------------------------------------------
# de_reduced <- calc_design_effect(cluster_size = 50, icc = 0.05)
# # Result: DE = 1 + (50 - 1) × 0.05 = 3.45
# 
# n_clustered_reduced <- calc_clustered_n(n_unclustered = 500, design_effect = de_reduced)
# # Result: N = 500 × 3.45 = 1,725 patients
# 
# k_reduced <- calc_n_clusters(n_total = 1725, cluster_size = 50)
# # Result: K = 1,725 / 50 = 35 hospitals


## ----case2-alternative, eval=FALSE--------------------------------------------
# # Even smaller: 25 patients per hospital
# de_small <- calc_design_effect(cluster_size = 25, icc = 0.05)
# n_small <- calc_clustered_n(n_unclustered = 500, design_effect = de_small)
# k_small <- calc_n_clusters(n_total = n_small, cluster_size = 25)
# 
# cat("Option C (25 per hospital):", n_small, "patients across", k_small, "hospitals\n")


## ----unequal-clusters, eval=FALSE---------------------------------------------
# # Use average cluster size
# de_avg <- calc_design_effect(cluster_size = 50, icc = 0.05)
# 
# # Or use maximum for conservative estimate
# de_max <- calc_design_effect(cluster_size = 70, icc = 0.05)


## ----workflow-step1, eval=FALSE-----------------------------------------------
# # Example: Two-sample t-test
# library(pwr)
# result <- pwr.t.test(d = 0.40, sig.level = 0.05, power = 0.80, type = "two.sample")
# n_unclustered <- ceiling(result$n * 2)  # Total for both groups


## ----workflow-step2, eval=FALSE-----------------------------------------------
# # Option A: Pilot data (fit mixed model, extract ICC)
# # Option B: Literature values
# icc <- get_typical_icc("clinical")  # Returns 0.05
# # Option C: Conservative assumption (e.g., upper bound from lit)


## ----workflow-step3, eval=FALSE-----------------------------------------------
# cluster_size <- 40  # Example: 40 patients per practice


## ----workflow-step4, eval=FALSE-----------------------------------------------
# de <- calc_design_effect(cluster_size = cluster_size, icc = icc)


## ----workflow-step5, eval=FALSE-----------------------------------------------
# n_clustered <- calc_clustered_n(n_unclustered = n_unclustered, design_effect = de)


## ----workflow-step6, eval=FALSE-----------------------------------------------
# k <- calc_n_clusters(n_total = n_clustered, cluster_size = cluster_size)
# 
# # Check if adequate (>=10 per arm for 2-arm trial)
# k_per_arm <- ceiling(k / 2)
# if (k_per_arm < 10) {
#   cat("WARNING: Only", k_per_arm, "clusters per arm. Aim for 10-15+ per arm.\n")
# }


## ----workflow-step7, eval=FALSE-----------------------------------------------
# validation <- validate_clustering_params(
#   n_clusters = k,
#   cluster_size = cluster_size,
#   icc = icc
# )
# 
# if (!validation$valid) {
#   stop("Clustering parameters are invalid. Review errors.")
# }
# 
# if (length(validation$messages) > 0) {
#   cat("Validation messages:\n")
#   print(validation$messages)
# }


## ----workflow-step8, eval=FALSE-----------------------------------------------
# # Test worst-case scenario
# icc_worst <- icc * 2  # Double the ICC
# de_worst <- calc_design_effect(cluster_size = cluster_size, icc = icc_worst)
# n_worst <- calc_clustered_n(n_unclustered = n_unclustered, design_effect = de_worst)
# k_worst <- calc_n_clusters(n_total = n_worst, cluster_size = cluster_size)
# 
# cat("Expected scenario:", k, "clusters,", n_clustered, "participants\n")
# cat("Worst case:", k_worst, "clusters,", n_worst, "participants\n")

