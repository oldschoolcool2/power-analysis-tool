#' Calculate Design Effect for Clustered Data
#'
#' Business logic for calculating the design effect and sample size inflation
#' for clustered/hierarchical data (e.g., patients within hospitals, individuals
#' within geographic regions).
#'
#' @param cluster_size Average cluster size (m)
#' @param icc Intraclass correlation coefficient (0 to 1)
#'
#' @return Design effect value
#'
#' @details
#' The design effect quantifies the loss of statistical efficiency due to clustering.
#' Formula: DE = 1 + (m - 1) × ICC
#'
#' Where:
#'   - m = average cluster size
#'   - ICC = intraclass correlation coefficient
#'
#' Typical ICC values (from meta-analyses):
#'   - Behavioral outcomes: 0.01 - 0.05
#'   - Clinical outcomes: 0.01 - 0.10
#'   - Process measures: 0.10 - 0.30
#'   - GP practice-level: 0.017 (average)
#'
#' @references
#' Donner, A., & Klar, N. (2000). Design and Analysis of Cluster Randomization
#' Trials in Health Research. London: Arnold.
#'
#' @examples
#' # Example: 25 patients per hospital, ICC = 0.05
#' de <- calc_design_effect(cluster_size = 25, icc = 0.05)
#' # Returns: 2.2
#'
#' # Example: 100 patients per practice, ICC = 0.017
#' de <- calc_design_effect(cluster_size = 100, icc = 0.017)
#' # Returns: 2.683
#'
#' @noRd
calc_design_effect <- function(cluster_size, icc) {
  logger::log_debug("calc_design_effect called", cluster_size = cluster_size, icc = icc)

  tryCatch(
    {
      if (cluster_size < 1) {
        stop("Cluster size must be at least 1")
      }
      if (icc < 0 || icc > 1) {
        stop("ICC must be between 0 and 1")
      }

      # Design Effect formula
      de <- 1 + (cluster_size - 1) * icc

      logger::log_debug("calc_design_effect completed", design_effect = de)
      return(de)
    },
    error = function(e) {
      logger::log_error(
        "calc_design_effect failed",
        error_class = class(e)[1],
        error_msg = conditionMessage(e),
        cluster_size = cluster_size,
        icc = icc
      )
      stop(e)
    }
  )
}


#' Calculate Effective Sample Size Accounting for Clustering
#'
#' Convert total sample size to effective sample size after accounting for
#' design effect from clustering.
#'
#' @param n_total Total number of participants across all clusters
#' @param design_effect Design effect (DE) value
#'
#' @return Effective sample size (equivalent to unclustered study)
#'
#' @details
#' Formula: N_effective = N_total / DE
#'
#' The effective sample size represents the equivalent number of independent
#' observations, accounting for correlation within clusters.
#'
#' @examples
#' # 500 participants with DE = 2.0
#' n_eff <- calc_effective_n(n_total = 500, design_effect = 2.0)
#' # Returns: 250 (effective sample size is half of total)
#'
#' @noRd
calc_effective_n <- function(n_total, design_effect) {
  if (design_effect < 1) {
    stop("Design effect must be >= 1")
  }

  n_effective <- n_total / design_effect

  return(ceiling(n_effective))
}


#' Calculate Required Total Sample Size for Clustered Design
#'
#' Inflate unclustered sample size to account for design effect from clustering.
#'
#' @param n_unclustered Required sample size assuming independent observations
#' @param design_effect Design effect (DE) value
#'
#' @return Required total sample size for clustered design
#'
#' @details
#' Formula: N_total = N_unclustered × DE
#'
#' This function inflates the sample size calculated for an unclustered design
#' to maintain the same statistical power when data are clustered.
#'
#' @examples
#' # Need 200 for unclustered design, DE = 2.2
#' n_total <- calc_clustered_n(n_unclustered = 200, design_effect = 2.2)
#' # Returns: 440 total participants needed
#'
#' @noRd
calc_clustered_n <- function(n_unclustered, design_effect) {
  logger::log_debug("calc_clustered_n called", n_unclustered = n_unclustered, design_effect = design_effect)

  tryCatch(
    {
      if (design_effect < 1) {
        stop("Design effect must be >= 1")
      }

      n_total <- n_unclustered * design_effect
      result <- ceiling(n_total)

      logger::log_debug("calc_clustered_n completed", n_total = result)
      return(result)
    },
    error = function(e) {
      logger::log_error(
        "calc_clustered_n failed",
        error_class = class(e)[1],
        error_msg = conditionMessage(e),
        n_unclustered = n_unclustered,
        design_effect = design_effect
      )
      stop(e)
    }
  )
}


#' Calculate Required Number of Clusters
#'
#' Determine how many clusters are needed given total sample size and
#' average cluster size.
#'
#' @param n_total Total sample size required (accounting for design effect)
#' @param cluster_size Average cluster size
#'
#' @return Required number of clusters
#'
#' @details
#' Formula: K = N_total / m
#'
#' Where:
#'   - K = number of clusters
#'   - N_total = total sample size
#'   - m = average cluster size
#'
#' Result is always rounded up to ensure adequate sample size.
#'
#' @examples
#' # Need 440 total participants, clusters of 25
#' k <- calc_n_clusters(n_total = 440, cluster_size = 25)
#' # Returns: 18 clusters needed
#'
#' @noRd
calc_n_clusters <- function(n_total, cluster_size) {
  if (cluster_size < 1) {
    stop("Cluster size must be at least 1")
  }

  k <- n_total / cluster_size

  return(ceiling(k))
}


#' Get Typical ICC Value by Domain
#'
#' Retrieve typical ICC values from literature meta-analyses for common
#' clinical domains.
#'
#' @param domain One of: "behavioral", "clinical", "process", "gp"
#'
#' @return Numeric ICC value
#'
#' @details
#' Typical ICC values from meta-analyses (2024):
#'   - Behavioral outcomes: 0.025 (range: 0.01-0.05)
#'   - Clinical/physiological outcomes: 0.05 (range: 0.01-0.10)
#'   - Process measures (adherence, etc.): 0.20 (range: 0.10-0.30)
#'   - General practice level: 0.017 (meta-analysis average)
#'
#' @references
#' Source: Comprehensive Feature Analysis 2025, Section 2
#' (Clustered Data and Design Effects)
#'
#' @examples
#' icc <- get_typical_icc("clinical")
#' # Returns: 0.05
#'
#' @noRd
get_typical_icc <- function(domain = c("behavioral", "clinical", "process", "gp")) {
  domain <- match.arg(domain)

  icc_values <- list(
    behavioral = 0.025,
    clinical = 0.05,
    process = 0.20,
    gp = 0.017
  )

  return(icc_values[[domain]])
}


#' Format Design Effect Interpretation
#'
#' Generate human-readable interpretation of design effect impact.
#'
#' @param design_effect Calculated design effect value
#' @param n_unclustered Unclustered sample size
#' @param cluster_size Average cluster size
#' @param icc ICC value used
#'
#' @return Character string with interpretation
#'
#' @examples
#' interp <- format_design_effect_interpretation(
#'   design_effect = 2.2,
#'   n_unclustered = 200,
#'   cluster_size = 25,
#'   icc = 0.05
#' )
#'
#' @noRd
format_design_effect_interpretation <- function(design_effect, n_unclustered,
                                                cluster_size, icc) {
  n_total <- ceiling(n_unclustered * design_effect)
  n_increase <- n_total - n_unclustered
  pct_increase <- round((design_effect - 1) * 100, 1)
  n_clusters <- ceiling(n_total / cluster_size)

  # Categorize design effect magnitude
  if (design_effect < 1.5) {
    magnitude <- "low"
    color_class <- "success"
  } else if (design_effect < 2.5) {
    magnitude <- "moderate"
    color_class <- "warning"
  } else {
    magnitude <- "strong"
    color_class <- "danger"
  }

  interpretation <- sprintf(
    paste0(
      "The design effect of %.2f indicates a %s clustering impact. ",
      "Clustering inflates the required sample size by %.1f%% ",
      "(from %d to %d participants, an increase of %d). ",
      "With an average cluster size of %d and ICC of %.3f, ",
      "you will need approximately %d clusters."
    ),
    design_effect, magnitude, pct_increase,
    n_unclustered, n_total, n_increase,
    cluster_size, icc, n_clusters
  )

  return(interpretation)
}


#' Validate Clustering Parameters
#'
#' Check if clustering parameters are valid and provide warnings/errors.
#'
#' @param n_clusters Number of clusters
#' @param cluster_size Average cluster size
#' @param icc ICC value
#'
#' @return List with 'valid' (logical) and 'messages' (character vector)
#'
#' @details
#' Validation checks:
#'   - At least 2 clusters required
#'   - Cluster size must be >= 2
#'   - ICC must be between 0 and 1
#'   - Minimum 10-15 clusters recommended for reliable inference
#'   - Very high ICC (>0.3) is unusual and may indicate issues
#'
#' @examples
#' validation <- validate_clustering_params(
#'   n_clusters = 8,
#'   cluster_size = 25,
#'   icc = 0.05
#' )
#'
#' @noRd
validate_clustering_params <- function(n_clusters, cluster_size, icc) {
  logger::log_trace("validate_clustering_params called", n_clusters = n_clusters, cluster_size = cluster_size, icc = icc)

  valid <- TRUE
  messages <- character(0)

  # Error: minimum clusters
  if (n_clusters < 2) {
    valid <- FALSE
    messages <- c(messages, "ERROR: At least 2 clusters are required for clustered analysis.")
    logger::log_warn("Clustering validation: insufficient clusters", n_clusters = n_clusters)
  }

  # Warning: low cluster count
  if (n_clusters >= 2 && n_clusters < 10) {
    messages <- c(messages,
      sprintf("WARNING: Only %d clusters may provide unreliable variance estimates. Consider 10-15+ clusters.", n_clusters)
    )
  }

  # Error: cluster size
  if (cluster_size < 2) {
    valid <- FALSE
    messages <- c(messages, "ERROR: Cluster size must be at least 2.")
  }

  # Error: ICC range
  if (icc < 0 || icc > 1) {
    valid <- FALSE
    messages <- c(messages, "ERROR: ICC must be between 0 and 1.")
  }

  # Warning: very high ICC
  if (icc > 0.30 && icc <= 1) {
    messages <- c(messages,
      sprintf("WARNING: ICC of %.3f is unusually high (typical max is 0.30). Verify this value is correct.", icc)
    )
  }

  # Warning: large design effect
  de <- 1 + (cluster_size - 1) * icc
  if (de > 5) {
    messages <- c(messages,
      sprintf("WARNING: Design effect of %.2f is very high. Consider reducing cluster size or using individual randomization.", de)
    )
  }

  list(
    valid = valid,
    messages = messages
  )
}
