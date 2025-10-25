## ----setup, include = FALSE---------------------------------------------------
knitr::opts_chunk$set(
  collapse = TRUE,
  comment = "#>",
  fig.width = 7,
  fig.height = 5
)


## ----power-curve-anatomy, echo=FALSE, eval=FALSE------------------------------
# # Example power curve (conceptual)
# library(ggplot2)
# library(pwr)
# 
# # Generate power curve for two-sample t-test
# n <- 64  # per group
# effect_sizes <- seq(0, 1, by = 0.01)
# power_values <- sapply(effect_sizes, function(d) {
#   if (d == 0) return(0.05)  # Type I error rate at null
#   result <- pwr.t.test(n = n, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")
#   return(result$power)
# })
# 
# df <- data.frame(Effect_Size = effect_sizes, Power = power_values)
# 
# ggplot(df, aes(x = Effect_Size, y = Power)) +
#   geom_line(linewidth = 1.2, color = "#1f77b4") +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   geom_vline(xintercept = 0.50, linetype = "dashed", color = "darkgreen") +
#   annotate("text", x = 0.55, y = 0.82, label = "80% Power Threshold", color = "red", hjust = 0) +
#   annotate("text", x = 0.52, y = 0.15, label = "Target Effect\n(d = 0.50)", color = "darkgreen", hjust = 0) +
#   annotate("point", x = 0.50, y = 0.80, color = "purple", size = 3) +
#   labs(
#     title = "Power Curve: Two-Sample t-test (N = 64 per group)",
#     x = "Effect Size (Cohen's d)",
#     y = "Statistical Power",
#     caption = "Dashed red line = 80% power threshold; Dashed green line = Target effect size"
#   ) +
#   theme_minimal() +
#   theme(plot.title = element_text(hjust = 0.5, face = "bold"))


## ----two-sample-interpretation, echo=FALSE------------------------------------
interpretation <- data.frame(
  Effect_Size = c("d = 0.20", "d = 0.35", "d = 0.50", "d = 0.80"),
  Example = c("3 mmHg BP reduction",
              "5 mmHg BP reduction",
              "7.5 mmHg BP reduction",
              "12 mmHg BP reduction"),
  Power_N64 = c("20%", "50%", "80%", "99%"),
  Interpretation = c("Underpowered for small effects",
                     "Moderate power for small-to-medium effects",
                     "Well-powered for medium effects (target)",
                     "Overpowered for large effects"),
  stringsAsFactors = FALSE
)

library(knitr)
kable(interpretation, caption = "Power at Different Effect Sizes (N = 64 per group, α = 0.05)")


## ----binary-outcome, echo=FALSE-----------------------------------------------
binary_interp <- data.frame(
  Risk_Difference = c("5%", "10%", "15%", "20%"),
  Example = c("20% vs 25%", "20% vs 30%", "20% vs 35%", "20% vs 40%"),
  Relative_Risk = c("1.25", "1.50", "1.75", "2.00"),
  Power_N200 = c("25%", "55%", "80%", "95%"),
  Interpretation = c("Underpowered for small differences",
                     "Moderate power for moderate differences",
                     "Well-powered for large differences (target)",
                     "Overpowered for very large differences"),
  stringsAsFactors = FALSE
)

kable(binary_interp, caption = "Power at Different Risk Differences (N = 100 per group, α = 0.05)")


## ----survival-interpretation, echo=FALSE--------------------------------------
survival_interp <- data.frame(
  Hazard_Ratio = c("1.30", "1.50", "1.75", "2.00"),
  Interpretation = c("30% increased hazard",
                     "50% increased hazard",
                     "75% increased hazard",
                     "100% increased hazard (doubling)"),
  Power_180_Events = c("40%", "70%", "90%", "98%"),
  Clinical_Example = c("Modest treatment effect",
                       "Moderate treatment effect",
                       "Strong treatment effect",
                       "Very strong treatment effect"),
  stringsAsFactors = FALSE
)

kable(survival_interp, caption = "Power at Different Hazard Ratios (180 events, α = 0.05)")


## ----matched-cc, echo=FALSE---------------------------------------------------
matched_interp <- data.frame(
  Odds_Ratio = c("1.50", "2.00", "2.50", "3.00"),
  Interpretation = c("50% increased odds",
                     "100% increased odds (doubling)",
                     "150% increased odds",
                     "200% increased odds (tripling)"),
  Power_100_Pairs = c("30%", "60%", "80%", "92%"),
  stringsAsFactors = FALSE
)

kable(matched_interp, caption = "Power at Different Odds Ratios (100 matched pairs, α = 0.05)")


## ----sensitivity-n, eval=FALSE------------------------------------------------
# library(pwr)
# library(ggplot2)
# 
# # Generate power curves for N = 50, 75, 100, 125 per group
# effect_sizes <- seq(0.2, 0.8, by = 0.01)
# sample_sizes <- c(50, 75, 100, 125)
# 
# power_data <- data.frame()
# for (n in sample_sizes) {
#   for (d in effect_sizes) {
#     result <- pwr.t.test(n = n, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")
#     power_data <- rbind(power_data, data.frame(N = n, Effect_Size = d, Power = result$power))
#   }
# }
# 
# ggplot(power_data, aes(x = Effect_Size, y = Power, color = factor(N), group = N)) +
#   geom_line(linewidth = 1) +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   geom_vline(xintercept = 0.40, linetype = "dashed", color = "darkgreen") +
#   labs(
#     title = "Sensitivity Analysis: Power Across Sample Sizes",
#     x = "Effect Size (Cohen's d)",
#     y = "Statistical Power",
#     color = "N per group"
#   ) +
#   theme_minimal()


## ----budget-constraint, eval=FALSE--------------------------------------------
# n_fixed <- 100
# effect_sizes <- seq(0.2, 1.0, by = 0.01)
# 
# power_values <- sapply(effect_sizes, function(d) {
#   result <- pwr.t.test(n = n_fixed, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")
#   return(result$power)
# })
# 
# df <- data.frame(Effect_Size = effect_sizes, Power = power_values)
# 
# # Find MDE (effect size at 80% power)
# mde <- effect_sizes[which.min(abs(power_values - 0.80))]
# 
# ggplot(df, aes(x = Effect_Size, y = Power)) +
#   geom_line(linewidth = 1.2, color = "#1f77b4") +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   geom_vline(xintercept = mde, linetype = "dashed", color = "darkgreen") +
#   annotate("text", x = mde + 0.05, y = 0.15, label = paste0("MDE = ", round(mde, 2)), color = "darkgreen") +
#   labs(
#     title = "Power Curve for Fixed Budget (N = 100 per group)",
#     x = "Effect Size (Cohen's d)",
#     y = "Statistical Power"
#   ) +
#   theme_minimal()


## ----multiple-outcomes, eval=FALSE--------------------------------------------
# # Primary: Continuous outcome (d = 0.50 target)
# primary_power <- sapply(seq(0.2, 1.0, by = 0.01), function(d) {
#   pwr.t.test(n = 80, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")$power
# })
# 
# # Secondary: Binary outcome (p1 = 0.30, p2 = 0.20, target RD = 0.10)
# # Convert to Cohen's h for power calculation
# p1_vals <- seq(0.22, 0.40, by = 0.001)
# p2 <- 0.20
# h_vals <- 2 * (asin(sqrt(p1_vals)) - asin(sqrt(p2)))
# secondary_power <- sapply(h_vals, function(h) {
#   pwr.2p.test(n = 80, h = h, sig.level = 0.05, alternative = "two.sided")$power
# })
# 
# # Plot both curves
# df_primary <- data.frame(Effect_Size = seq(0.2, 1.0, by = 0.01), Power = primary_power, Outcome = "Primary (Continuous)")
# df_secondary <- data.frame(Effect_Size = p1_vals - p2, Power = secondary_power, Outcome = "Secondary (Binary)")
# 
# df_combined <- rbind(df_primary, df_secondary)
# 
# ggplot(df_combined, aes(x = Effect_Size, y = Power, color = Outcome)) +
#   geom_line(linewidth = 1.2) +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   labs(
#     title = "Power Curves: Primary vs Secondary Outcomes (N = 80 per group)",
#     x = "Effect Size (Primary: Cohen's d; Secondary: Risk Difference)",
#     y = "Statistical Power",
#     color = "Outcome"
#   ) +
#   theme_minimal()


## ----case1-plot, eval=FALSE---------------------------------------------------
# # Plot power curves for N = 60, 90, 120, 150 per group
# sample_sizes <- c(60, 90, 120, 150)
# effect_sizes <- seq(0.2, 0.8, by = 0.01)
# 
# power_data <- expand.grid(N = sample_sizes, Effect_Size = effect_sizes)
# power_data$Power <- mapply(function(n, d) {
#   pwr.t.test(n = n, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")$power
# }, power_data$N, power_data$Effect_Size)
# 
# ggplot(power_data, aes(x = Effect_Size, y = Power, color = factor(N))) +
#   geom_line(linewidth = 1) +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   geom_vline(xintercept = 0.30, linetype = "dashed", color = "darkgreen", alpha = 0.5) +
#   geom_vline(xintercept = 0.60, linetype = "dashed", color = "darkgreen", alpha = 0.5) +
#   annotate("rect", xmin = 0.30, xmax = 0.60, ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "green") +
#   annotate("text", x = 0.45, y = 0.95, label = "Target Range", color = "darkgreen") +
#   labs(
#     title = "Sensitivity Analysis: Physical Activity Intervention",
#     x = "Effect Size (Cohen's d)",
#     y = "Statistical Power",
#     color = "N per group"
#   ) +
#   theme_minimal()


## ----case2-plot, eval=FALSE---------------------------------------------------
# n_fixed <- 25
# effect_sizes <- seq(0.2, 1.5, by = 0.01)
# 
# power_values <- sapply(effect_sizes, function(d) {
#   pwr.t.test(n = n_fixed, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")$power
# })
# 
# df <- data.frame(Effect_Size = effect_sizes, Power = power_values)
# 
# # Find MDE
# mde <- effect_sizes[which.min(abs(power_values - 0.80))]
# 
# # Clinical threshold: 5-point reduction = 0.5 SD = d = 0.50
# clinical_threshold <- 0.50
# 
# ggplot(df, aes(x = Effect_Size, y = Power)) +
#   geom_line(linewidth = 1.2, color = "#1f77b4") +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   geom_vline(xintercept = mde, linetype = "dashed", color = "purple") +
#   geom_vline(xintercept = clinical_threshold, linetype = "dashed", color = "darkgreen") +
#   annotate("text", x = mde + 0.1, y = 0.85, label = paste0("MDE = ", round(mde, 2)), color = "purple") +
#   annotate("text", x = clinical_threshold + 0.1, y = 0.30, label = "Clinical Threshold\n(d = 0.50)", color = "darkgreen") +
#   annotate("rect", xmin = -Inf, xmax = mde, ymin = -Inf, ymax = Inf, alpha = 0.1, fill = "red") +
#   annotate("text", x = 0.50, y = 0.95, label = "Underpowered Region", color = "red") +
#   labs(
#     title = "Power Curve: Rare Disease Trial (N = 25 per group)",
#     x = "Effect Size (Cohen's d)",
#     y = "Statistical Power"
#   ) +
#   theme_minimal()


## ----case3-plot, eval=FALSE---------------------------------------------------
# # Scenario A: Individual randomization (no clustering)
# n_individual <- 100  # per group
# effect_sizes <- seq(0.2, 0.8, by = 0.01)
# power_individual <- sapply(effect_sizes, function(d) {
#   pwr.t.test(n = n_individual, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")$power
# })
# 
# # Scenario B: Cluster randomization
# # Design effect = 3.45, so effective N = 100 / 3.45 ≈ 29
# n_effective <- round(n_individual / 3.45)
# power_clustered <- sapply(effect_sizes, function(d) {
#   pwr.t.test(n = n_effective, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")$power
# })
# 
# df <- data.frame(
#   Effect_Size = rep(effect_sizes, 2),
#   Power = c(power_individual, power_clustered),
#   Design = rep(c("Individual Randomization", "Cluster Randomization (DE=3.45)"), each = length(effect_sizes))
# )
# 
# ggplot(df, aes(x = Effect_Size, y = Power, color = Design)) +
#   geom_line(linewidth = 1.2) +
#   geom_hline(yintercept = 0.80, linetype = "dashed", color = "red") +
#   labs(
#     title = "Impact of Clustering on Power Curve (N = 100 per group)",
#     x = "Effect Size (Cohen's d)",
#     y = "Statistical Power",
#     color = "Design Type"
#   ) +
#   theme_minimal()


## ----contour-plot, eval=FALSE-------------------------------------------------
# library(ggplot2)
# 
# # Generate grid
# n_values <- seq(30, 150, by = 5)
# d_values <- seq(0.2, 0.8, by = 0.02)
# power_grid <- expand.grid(N = n_values, Effect_Size = d_values)
# 
# power_grid$Power <- mapply(function(n, d) {
#   pwr.t.test(n = n, d = d, sig.level = 0.05, type = "two.sample", alternative = "two.sided")$power
# }, power_grid$N, power_grid$Effect_Size)
# 
# # Contour plot
# ggplot(power_grid, aes(x = N, y = Effect_Size, z = Power)) +
#   geom_contour_filled(breaks = seq(0, 1, by = 0.1)) +
#   geom_contour(color = "white", alpha = 0.3, breaks = c(0.80)) +  # Highlight 80% power
#   labs(
#     title = "Power Contour Plot: Sample Size vs Effect Size",
#     x = "Sample Size (N per group)",
#     y = "Effect Size (Cohen's d)",
#     fill = "Power"
#   ) +
#   theme_minimal()

