################################################################################
# STATS APPENDIX: Quick Reproducible Analysis
# 
# This script runs the core analysis on the example dataset.
# Usage: Rscript reproduce_analysis.R
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))
set.seed(42)

# Add user library to search path
user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) {
  .libPaths(c(user_lib, .libPaths()))
}

# Required packages
required_pkgs <- c("boot", "car", "relaimpo", "psych")
missing <- !sapply(required_pkgs, function(pkg) {
  suppressWarnings(require(pkg, character.only = TRUE, quietly = TRUE))
})
if (any(missing)) {
  cat("Installing missing:", paste(names(missing)[missing], collapse=", "), "\n")
  if (!dir.exists(user_lib)) {
    dir.create(user_lib, recursive = TRUE, showWarnings = FALSE)
  }
  install.packages(required_pkgs[missing], lib = user_lib, repos = "https://cloud.r-project.org", quiet = TRUE)
  invisible(sapply(required_pkgs, require, character.only = TRUE, quietly = TRUE))
}

# Load data
df_raw <- read.csv("vector_survey_responses_example.csv", check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
colnames(df_raw)[8:18] <- paste0("q", 1:11)
df_raw[8:18] <- lapply(df_raw[8:18], function(x) as.numeric(as.character(x)))

# Complete-case
df <- df_raw[complete.cases(df_raw[paste0("q", 1:11)]), ]

cat("\n=== DATA ===\n")
cat(sprintf("Input: %d rows\nComplete-case: %d rows\nExcluded: %d rows\n\n", 
            nrow(df_raw), nrow(df), nrow(df_raw) - nrow(df)))

# ANALYSIS: Relative Importance (LMG)
cat("=== RELATIVE IMPORTANCE ANALYSIS ===\n")
predictors <- paste0("q", 1:7)
outcome <- "q10"
formula_str <- sprintf("%s ~ %s", outcome, paste(predictors, collapse = " + "))
model <- lm(as.formula(formula_str), data = df)

# Try LMG with error handling
lmg_success <- FALSE
tryCatch({
  importance <- calc.relimp(model, type = "lmg", rela = TRUE)
  lmg_vals <- as.numeric(importance@lmg) * 100
  results_df <- data.frame(
    predictor = predictors,
    rel_importance_pct = round(lmg_vals, 2)
  )
  results_df <- results_df[order(-results_df$rel_importance_pct), ]
  results_df$rank <- 1:nrow(results_df)
  lmg_success <- TRUE
}, error = function(e) {
  NULL
})

# Fallback: standardized coefficients
if (!lmg_success) {
  cat("(LMG failed, using standardized coefficients)\n")
  df_scaled <- as.data.frame(scale(df[c(outcome, predictors)]))
  model_scaled <- lm(as.formula(formula_str), data = df_scaled)
  coefs <- abs(coef(model_scaled)[-1])
  results_df <- data.frame(
    predictor = predictors,
    standardized_coef_pct = round(100 * coefs / sum(coefs), 2)
  )
  results_df <- results_df[order(-results_df[[2]]), ]
  results_df$rank <- 1:nrow(results_df)
}

cat("\n")
print(results_df)

# Model stats
r2 <- summary(model)$r.squared
cat(sprintf("\nModel R² = %.3f  |  N = %d\n", r2, nrow(df)))

# Correlations
cat("\n=== CORRELATIONS (Spearman, first 5x5) ===\n")
corr <- cor(df[paste0("q", 1:11)], method = "spearman")
print(round(corr[1:5, 1:5], 2))

# Descriptives
cat("\n=== DESCRIPTIVE STATISTICS ===\n")
all_q <- paste0("q", 1:11)
desc <- data.frame(
  q = all_q,
  mean = round(colMeans(df[all_q], na.rm = TRUE), 2),
  sd = round(apply(df[all_q], 2, sd, na.rm = TRUE), 2),
  median = round(apply(df[all_q], 2, median, na.rm = TRUE), 1),
  min = apply(df[all_q], 2, min),
  max = apply(df[all_q], 2, max)
)
print(desc)

cat("\n=== DONE ===\n")
cat(sprintf("Top predictor: %s (%.1f%% importance)\n", 
            results_df$predictor[1], results_df[[2]][1]))
