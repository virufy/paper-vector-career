################################################################################
# Statistical Appendix: Quick Reproducible Analysis
#
# This script provides a fast, submission-ready reproducible example
# using the core LMG relative importance analysis.
#
# Usage: Rscript reproduce_analysis.R
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))
set.seed(42)

# Package setup
user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) {
  .libPaths(c(user_lib, .libPaths()))
}

required_pkgs <- c("boot", "car", "relaimpo", "psych", "dplyr")
for (pkg in required_pkgs) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, lib = user_lib, quiet = TRUE)
    require(pkg, character.only = TRUE, quietly = TRUE)
  }
}

# Load data (from local stats_appendix folder)
cat("\n=== LOADING DATA ===\n")
data_file <- "vector_survey_responses_example.csv"
if (!file.exists(data_file)) {
  stop(sprintf("Data file not found: %s\nMake sure you're running from the stats_appendix/ directory", data_file))
}
df_raw <- read.csv(data_file, check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
colnames(df_raw)[8:18] <- paste0("q", 1:11)
df_raw[8:18] <- lapply(df_raw[8:18], function(x) as.numeric(as.character(x)))

# Complete-case deletion
df <- df_raw[complete.cases(df_raw[paste0("q", 1:11)]), ]

cat(sprintf("Input: %d rows\n", nrow(df_raw)))
cat(sprintf("Complete-case: %d rows\n", nrow(df)))
cat(sprintf("Excluded: %d rows\n", nrow(df_raw) - nrow(df)))

# Setup
cat("\n=== RELATIVE IMPORTANCE ANALYSIS (LMG) ===\n")

predictor_names <- paste0("q", 1:7)
outcome_name <- "q10"

# Scaling
x_scaled <- as.data.frame(scale(df[predictor_names]))
y_scaled <- as.numeric(scale(df[[outcome_name]]))
model_data <- x_scaled
model_data$y <- y_scaled

# Fit model
full_model <- lm(y ~ ., data = model_data)
model_summary <- summary(full_model)

cat(sprintf("Model R² = %.3f\n", model_summary$r.squared))

# LMG analysis with error handling
lmg_success <- FALSE
tryCatch({
  rel <- relaimpo::calc.relimp(full_model, type = "lmg", rela = TRUE)

  # Bootstrap CIs (1000 iterations)
  boot_fn <- function(data, idx) {
    m <- lm(y ~ ., data = data[idx, ])
    relaimpo::calc.relimp(m, type = "lmg", rela = TRUE)$lmg * 100
  }
  boot_res <- boot::boot(model_data, boot_fn, R = 1000)

  importance <- data.frame(
    variable = names(rel$lmg),
    lmg_pct = as.numeric(rel$lmg) * 100,
    ci_lower = apply(boot_res$t, 2, quantile, probs = 0.025, na.rm = TRUE),
    ci_upper = apply(boot_res$t, 2, quantile, probs = 0.975, na.rm = TRUE)
  )
  importance <- importance[order(-importance$lmg_pct), ]
  lmg_success <- TRUE

  cat("\nRelative Importance (LMG %):\n")
  for (i in 1:nrow(importance)) {
    cat(sprintf("  %d. %s: %.1f%% [95%% CI: %.1f%%-%.1f%%]\n",
                i, importance$variable[i], importance$lmg_pct[i],
                importance$ci_lower[i], importance$ci_upper[i]))
  }

}, error = function(e) {
  cat("⚠️  LMG analysis failed on small sample. Using standardized coefficients.\n")
})

# Fallback: standardized coefficients
if (!lmg_success) {
  coef_std <- coef(full_model)[-1]
  importance <- data.frame(
    variable = predictor_names,
    standardized_coef = abs(coef_std),
    pct_contribution = 100 * abs(coef_std) / sum(abs(coef_std))
  )
  importance <- importance[order(-importance$pct_contribution), ]

  cat("\nStandardized Coefficients (Fallback):\n")
  for (i in 1:nrow(importance)) {
    cat(sprintf("  %d. %s: %.1f%%\n",
                i, importance$variable[i], importance$pct_contribution[i]))
  }
}

# Diagnostics
cat("\n=== MODEL DIAGNOSTICS ===\n")
cat(sprintf("N = %d\n", nrow(df)))
cat(sprintf("R² = %.3f\n", model_summary$r.squared))
cat(sprintf("Adjusted R² = %.3f\n", model_summary$adj.r.squared))
cat(sprintf("F-statistic p-value: %.4f\n",
            pf(model_summary$fstatistic[1], model_summary$fstatistic[2],
               model_summary$fstatistic[3], lower.tail = FALSE)))

vif_values <- car::vif(full_model)
cat(sprintf("Max VIF = %.2f\n", max(vif_values)))

resid_sw <- shapiro.test(residuals(full_model))
cat(sprintf("Shapiro-Wilk p-value: %.4f\n", resid_sw$p.value))

resid_bp <- lmtest::bptest(full_model)
cat(sprintf("Breusch-Pagan p-value: %.4f\n", resid_bp$p.value))

cat("\n=== ANALYSIS COMPLETE ===\n")
cat("For full analysis with subgroups and SEM, see: Rscript run_analysis.R\n\n")
