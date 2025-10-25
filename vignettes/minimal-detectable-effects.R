## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)


## ----mde-single-prop, eval=FALSE----------------------------------------------
# # This calculation is performed via binary search in the tool
# # For a single proportion test:
# 
# library(pwr)
# 
# # Solve for effect size h given fixed n
# result <- pwr.p.test(
#   n = 150,
#   sig.level = 0.05,
#   power = 0.80,
#   alternative = "two.sided"
# )
# 
# h_mde <- result$h  # Cohen's h
# 
# # Convert h back to proportion
# # h = 2 * (arcsin(sqrt(p1)) - arcsin(sqrt(p0)))
# # For p0 = 0.30, solve for p1 using h_mde
# p0 <- 0.30
# p1_mde <- (sin(asin(sqrt(p0)) + h_mde / 2))^2
# 
# cat("With N =", 150, ", minimal detectable proportion is p1 =", round(p1_mde, 3), "\n")
# cat("Minimal detectable difference:", round(p1_mde - p0, 3), "\n")


## ----mde-two-prop, eval=FALSE-------------------------------------------------
# result <- pwr.2p.test(
#   n = 100,  # Per group
#   sig.level = 0.05,
#   power = 0.80,
#   alternative = "two.sided"
# )
# 
# h_mde <- result$h
# 
# # Convert h to proportions (p2 = 0.20 is fixed)
# p2 <- 0.20
# # h = 2 * (arcsin(sqrt(p1)) - arcsin(sqrt(p2)))
# # Solve for p1
# p1_mde <- (sin(asin(sqrt(p2)) + h_mde / 2))^2
# 
# cat("With N = 100 per group, minimal detectable p1 =", round(p1_mde, 3), "\n")
# cat("Minimal detectable difference:", round(p1_mde - p2, 3), "\n")
# 
# # Calculate effect measures
# rr_mde <- p1_mde / p2
# or_mde <- (p1_mde / (1 - p1_mde)) / (p2 / (1 - p2))
# rd_mde <- p1_mde - p2
# 
# cat("MDE in terms of:\n")
# cat("  Risk Difference (RD):", round(rd_mde, 3), "\n")
# cat("  Relative Risk (RR):", round(rr_mde, 2), "\n")
# cat("  Odds Ratio (OR):", round(or_mde, 2), "\n")


## ----mde-continuous, eval=FALSE-----------------------------------------------
# result <- pwr.t.test(
#   n = 60,  # Per group
#   sig.level = 0.05,
#   power = 0.80,
#   type = "two.sample",
#   alternative = "two.sided"
# )
# 
# d_mde <- result$d
# 
# cat("With N = 60 per group, minimal detectable Cohen's d =", round(d_mde, 3), "\n")
# 
# # Interpretation in terms of raw differences (if SD is known)
# # Example: If outcome is blood pressure with SD = 15 mmHg
# sd <- 15
# mean_diff_mde <- d_mde * sd
# 
# cat("If SD = 15 mmHg, minimal detectable mean difference:", round(mean_diff_mde, 1), "mmHg\n")


## ----mde-survival, eval=FALSE-------------------------------------------------
# # Approximate calculation using event-driven power
# # For a two-group comparison with equal allocation:
# 
# n_events <- 180
# z_alpha <- qnorm(1 - 0.05 / 2)  # 1.96
# z_beta <- qnorm(0.80)           # 0.84
# 
# # Formula: log(HR) ≈ (z_alpha + z_beta) / sqrt(n_events / 4)
# log_hr_mde <- (z_alpha + z_beta) / sqrt(n_events / 4)
# hr_mde <- exp(log_hr_mde)
# 
# cat("With", n_events, "events, minimal detectable HR =", round(hr_mde, 2), "\n")


## ----cohens-d-table, echo=FALSE-----------------------------------------------
cohens_table <- data.frame(
  Effect_Size = c("Small", "Medium", "Large"),
  Cohens_d = c("0.20", "0.50", "0.80"),
  Example = c("Small but noticeable (e.g., 3 mmHg BP)",
              "Moderate, clinically relevant (e.g., 7.5 mmHg BP)",
              "Large, clinically important (e.g., 12 mmHg BP)"),
  stringsAsFactors = FALSE
)

library(knitr)
kable(cohens_table, caption = "Cohen's d Benchmarks for Continuous Outcomes")


## ----rr-or-table, echo=FALSE--------------------------------------------------
effect_table <- data.frame(
  Effect_Size = c("Small", "Moderate", "Large", "Very Large"),
  Relative_Risk = c("1.1 - 1.3", "1.3 - 2.0", "2.0 - 3.0", "> 3.0"),
  Odds_Ratio = c("1.2 - 1.5", "1.5 - 2.5", "2.5 - 4.0", "> 4.0"),
  Example = c("Weak association (e.g., minor risk factor)",
              "Moderate association (e.g., typical treatment effect)",
              "Strong association (e.g., effective prevention)",
              "Very strong (e.g., smoking → lung cancer)"),
  stringsAsFactors = FALSE
)

kable(effect_table, caption = "Relative Effect Size Benchmarks for Binary Outcomes")


## ----step1-example, eval=FALSE------------------------------------------------
# # Example: Two-group comparison with constrained N = 200 (100 per group)
# library(pwr)
# 
# result <- pwr.2p.test(
#   n = 100,
#   sig.level = 0.05,
#   power = 0.80,
#   alternative = "two.sided"
# )
# 
# h_mde <- result$h
# # Convert to practical metrics (RD, RR, OR) based on your baseline p2


## ----option-a, eval=FALSE-----------------------------------------------------
# # Calculate required N to detect clinical threshold effect
# # Example: Need to detect RD = 0.10 (10 percentage points)
# 
# # Convert RD to Cohen's h
# p1 <- 0.30  # Clinical threshold
# p2 <- 0.20
# h_target <- 2 * (asin(sqrt(p1)) - asin(sqrt(p2)))
# 
# # Calculate required N
# result_needed <- pwr.2p.test(
#   h = h_target,
#   sig.level = 0.05,
#   power = 0.80,
#   alternative = "two.sided"
# )
# 
# n_per_group_needed <- ceiling(result_needed$n)
# cat("To detect RD = 0.10, need", n_per_group_needed, "per group\n")


## ----option-b, eval=FALSE-----------------------------------------------------
# # Calculate MDE with current N but for higher power (e.g., 90%)
# result_high_power <- pwr.2p.test(
#   n = 100,
#   sig.level = 0.05,
#   power = 0.90,  # Higher power
#   alternative = "two.sided"
# )
# 
# h_mde_90 <- result_high_power$h
# # Compare: with 90% power, MDE is slightly larger


## ----option-c, eval=FALSE-----------------------------------------------------
# # Calculate MDE with lower power (70%)
# result_low_power <- pwr.2p.test(
#   n = 100,
#   sig.level = 0.05,
#   power = 0.70,
#   alternative = "two.sided"
# )
# 
# h_mde_70 <- result_low_power$h
# # With lower power, MDE is smaller (but risk of missing true effects increases)


## ----case1-analysis, eval=FALSE-----------------------------------------------
# # Calculate MDE with N = 100 per group
# result <- pwr.2p.test(
#   n = 100,
#   sig.level = 0.05,
#   power = 0.80,
#   alternative = "two.sided"
# )
# 
# h_mde <- result$h
# p2 <- 0.15
# 
# # Solve for p1 given h_mde and p2
# p1_mde <- (sin(asin(sqrt(p2)) + h_mde / 2))^2
# rd_mde <- p1_mde - p2
# 
# cat("MDE (Risk Difference):", round(rd_mde, 3), "\n")
# cat("MDE (Cessation rate):", round(p1_mde, 3), "(", round(p1_mde * 100, 1), "%)\n")
# cat("Clinical threshold: 0.10 (10 percentage points)\n")
# 
# if (rd_mde <= 0.10) {
#   cat("✅ Study is feasible: MDE ≤ clinical threshold\n")
# } else {
#   cat("❌ Study is underpowered: MDE > clinical threshold\n")
# }


## ----case1-option1, eval=FALSE------------------------------------------------
# h_target <- 2 * (asin(sqrt(0.25)) - asin(sqrt(0.15)))
# result_target <- pwr.2p.test(h = h_target, sig.level = 0.05, power = 0.80, alternative = "two.sided")
# n_needed <- ceiling(result_target$n)
# cat("Need", n_needed, "per group (", n_needed * 2, "total)\n")
# # Output: Need 293 per group (586 total)


## ----case2-analysis, eval=FALSE-----------------------------------------------
# # Calculate MDE (Cohen's d) with N = 60 per group
# result <- pwr.t.test(
#   n = 60,
#   sig.level = 0.05,
#   power = 0.80,
#   type = "two.sample",
#   alternative = "two.sided"
# )
# 
# d_mde <- result$d
# 
# # Convert to mmHg
# sd <- 15
# mean_diff_mde <- d_mde * sd
# 
# cat("MDE (Cohen's d):", round(d_mde, 3), "\n")
# cat("MDE (mmHg):", round(mean_diff_mde, 2), "mmHg\n")
# cat("Clinical threshold: 5 mmHg\n")
# 
# if (mean_diff_mde <= 5) {
#   cat("✅ Study is feasible: MDE ≤ clinical threshold\n")
# } else {
#   cat("❌ Study is underpowered: MDE > clinical threshold\n")
# }


## ----case2-option1, eval=FALSE------------------------------------------------
# d_target <- 5 / 15  # 0.333
# result_target <- pwr.t.test(d = d_target, sig.level = 0.05, power = 0.80, type = "two.sample", alternative = "two.sided")
# n_needed <- ceiling(result_target$n)
# cat("Need", n_needed, "per group (", n_needed * 2, "total)\n")
# # Output: Need 143 per group (286 total)


## ----case3-analysis, eval=FALSE-----------------------------------------------
# result <- pwr.t.test(
#   n = 25,
#   sig.level = 0.05,
#   power = 0.80,
#   type = "two.sample",
#   alternative = "two.sided"
# )
# 
# d_mde <- result$d
# sd <- 10
# mean_diff_mde <- d_mde * sd
# 
# cat("MDE (Cohen's d):", round(d_mde, 3), "\n")
# cat("MDE (score points):", round(mean_diff_mde, 2), "\n")
# cat("Clinical threshold: 5 points\n")


## ----mde-adjusted, eval=FALSE-------------------------------------------------
# # Calculate MDE using effective N
# n_effective <- 200 / 2  # 100 per group
# 
# result <- pwr.2p.test(
#   n = n_effective,
#   sig.level = 0.05,
#   power = 0.80,
#   alternative = "two.sided"
# )
# 
# # MDE will be larger due to reduced effective N

