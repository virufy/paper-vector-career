################################################################################
# PROJECT VECTOR: Comprehensive Exploratory Analysis
# Purpose: Validate "Remote Work Paradox" and identify true drivers of career success
# Author: Generated for Doctoral Research
# Date: February 2026
################################################################################

# Ensure a CRAN mirror is set for non-interactive installs
options(repos = c(CRAN = "https://cloud.r-project.org"))

# ==============================================================================
# 1. ENVIRONMENT SETUP
# ==============================================================================

# Install required packages if not already installed
# NOTE: Order matters! Some packages depend on others.
packages <- c("lme4", "pbkrtest", "car", "lavaan", "dplyr", "ggplot2", 
              "corrplot", "relaimpo", "tidyr", "psych", "reshape2", 
              "gridExtra", "ppcor")

install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("  Installing %s...\n", pkg))
    install.packages(pkg, dependencies = TRUE, quiet = TRUE)
    library(pkg, character.only = TRUE, quietly = TRUE)
  }
}

cat("Checking and installing required packages...\n")
invisible(sapply(packages, install_if_missing))
cat("✓ All packages ready\n\n")

# Set working directory (adjust as needed)
# setwd("your/working/directory")

# ==============================================================================
# 2. DATA LOADING AND PREPARATION
# ==============================================================================

# Load the raw data
cat("Loading survey data...\n")
# Use the canonical project CSV file
df <- read.csv("vector_survey_responses.csv", check.names = FALSE)

# Fix duplicate column names (critical for avoiding errors)
colnames(df) <- make.unique(colnames(df))

# ROBUST APPROACH: Identify Likert columns by checking structure
# Expecting 11 numeric columns in positions 8-18
if(ncol(df) < 18) {
  stop("ERROR: Data structure unexpected. Expected at least 18 columns, found ", ncol(df))
}

target_cols <- 8:18
if(length(target_cols) != 11) {
  stop("ERROR: Expected 11 Likert scale columns (q1-q11)")
}

colnames(df)[target_cols] <- paste0("q", 1:11)

# Validate that columns contain numeric/Likert-scale data
df[target_cols] <- lapply(df[target_cols], function(x) as.numeric(as.character(x)))

# Check that values are reasonable (1-5 Likert scale)
for(col in paste0("q", 1:11)) {
  valid_range <- all(df[[col]] >= 1 & df[[col]] <= 5, na.rm = TRUE)
  if(!valid_range) {
    warning(sprintf("WARNING: %s contains values outside 1-5 range", col))
  }
}

# ==============================================================================
# 2.5 MISSING DATA ANALYSIS
# ==============================================================================

cat("\n=== MISSING DATA ANALYSIS ===\n")
missing_counts <- colSums(is.na(df[target_cols]))
missing_pct <- (missing_counts / nrow(df)) * 100

if(any(missing_counts > 0)) {
  cat("Missing data detected:\n")
  for(i in seq_along(missing_counts)) {
    if(missing_counts[i] > 0) {
      cat(sprintf("  %s: %d (%.1f%%)\n", names(missing_counts)[i], 
                  missing_counts[i], missing_pct[i]))
    }
  }
  cat("\nAction: Using listwise deletion (complete cases only)\n")
}

# Report sample loss
n_before <- nrow(df)
df_clean <- df[complete.cases(df[target_cols]), ]
n_after <- nrow(df_clean)
data_loss_pct <- ((n_before - n_after) / n_before) * 100

cat(sprintf("\nSample size: %d → %d complete responses\n", n_before, n_after))
if(data_loss_pct > 10) {
  cat(sprintf("⚠ WARNING: %.1f%% data loss due to missing values\n", data_loss_pct))
}

if(n_after < 30) {
  warning(sprintf("SAMPLE SIZE WARNING: n=%d is below recommended minimum of 30", n_after))
}

cat(sprintf("Variables: q1-q11 representing skills, networking, and outcomes\n\n"))

# ==============================================================================
# 3. VARIABLE MAPPING (For Reference)
# ==============================================================================

var_labels <- data.frame(
  Variable = paste0("q", 1:11),
  Category = c(rep("Skills", 4), rep("Network", 3), rep("Outcomes", 4)),
  Description = c(
    "Technical Skills (Programming, Data Analysis)",
    "Communication Skills (Writing, Presentation)",
    "Leadership Skills (Guiding teams)",
    "Time Management (Organization, Deadlines)",
    "Network Size (Quantity of connections)",
    "Network Quality (Insights/Advice)",
    "Network Access (Professional circles)",
    "Overall Career Impact",
    "Resume Competitiveness",
    "Job/Promotion Success (PRIMARY OUTCOME)",
    "Leadership Role Advancement"
  )
)

print(var_labels)
cat("\n")

# ==============================================================================
# 4. DESCRIPTIVE STATISTICS
# ==============================================================================

cat("=== DESCRIPTIVE STATISTICS ===\n")
desc_stats <- describe(df_clean[, paste0("q", 1:11)])
print(round(desc_stats[, c("mean", "sd", "median", "min", "max")], 2))
cat("\n")

# ==============================================================================
# 5. FULL CORRELATION MATRIX WITH HEATMAP
# ==============================================================================

cat("=== CORRELATION ANALYSIS ===\n")

# Calculate correlation matrix
cor_matrix <- cor(df_clean[, paste0("q", 1:11)], use = "complete.obs", method = "spearman")

# Print correlation with q10 (Job Success - our primary outcome)
cat("\nCorrelations with Job Success (q10):\n")
q10_cors <- cor_matrix[, "q10"]
q10_cors_sorted <- sort(q10_cors, decreasing = TRUE)
for(i in 1:length(q10_cors_sorted)) {
  var_name <- names(q10_cors_sorted)[i]
  var_desc <- var_labels$Description[var_labels$Variable == var_name]
  cat(sprintf("  %s (%s): %.3f\n", var_name, var_desc, q10_cors_sorted[i]))
}
cat("\n")

# Create correlation heatmap
dir.create("output", showWarnings = FALSE)
png("output/correlation_heatmap.png", width = 1200, height = 1000, res = 120)
corrplot(cor_matrix, 
         method = "color",
         type = "full",
         order = "hclust",
         addCoef.col = "black",
         number.cex = 0.7,
         tl.col = "black",
         tl.srt = 45,
         col = colorRampPalette(c("#6D9EC1", "white", "#E46726"))(200),
         title = "Project VECTOR: Full Correlation Matrix (Spearman)",
         mar = c(0,0,2,0))
dev.off()
cat("Correlation heatmap saved: output/correlation_heatmap.png\n\n")

# ==============================================================================
# 6. THE ROYAL RUMBLE: RELATIVE IMPORTANCE ANALYSIS
# ==============================================================================

cat("=== THE ROYAL RUMBLE: RELATIVE IMPORTANCE ANALYSIS ===\n")
cat("Testing ALL predictors (q1-q7) against Job Success (q10)\n\n")

# Prepare predictor matrix (all skills and network variables)
predictors <- df_clean[, paste0("q", 1:7)]
outcome <- df_clean$q10

# Standardize for fair comparison
predictors_scaled <- as.data.frame(scale(predictors))
outcome_scaled <- scale(outcome)

# Run full regression model
full_model <- lm(outcome_scaled ~ ., data = predictors_scaled)

cat("--- Full Regression Model Summary ---\n")
summary_full <- summary(full_model)
print(summary_full)
cat("\n")

# Calculate VIF (Variance Inflation Factors) to check multicollinearity
cat("--- Multicollinearity Check (VIF) ---\n")
vif_values <- vif(full_model)
print(round(vif_values, 2))

# Enhanced VIF interpretation
max_vif <- max(vif_values)
if(max_vif > 10) {
  cat("\n🔴 CRITICAL: VIF > 10 detected - severe multicollinearity\n")
  cat("   Consider: Removing highly correlated predictors or using ridge regression\n")
} else if(max_vif > 5) {
  cat("\n⚠ CAUTION: Some VIF > 5 - moderate multicollinearity detected\n")
  cat("   Standard errors may be inflated but results interpretable\n")
} else {
  cat("\n✓ No multicollinearity concerns (all VIF < 5)\n")
}
cat("\n")

# ==============================================================================
# 6.5 REGRESSION DIAGNOSTICS (Assumption Testing)
# ==============================================================================

cat("\n=== REGRESSION ASSUMPTION CHECKS ===\n")

# 1. Normality of residuals (Shapiro-Wilk test)
shapiro_test <- shapiro.test(residuals(full_model))
cat(sprintf("✓ Shapiro-Wilk normality test: W=%.4f, p=%.4f\n", 
            shapiro_test$statistic, shapiro_test$p.value))

if(shapiro_test$p.value < 0.05) {
  cat("  ⚠ WARNING: Residuals not normally distributed (p < 0.05)\n")
  cat("     Consider: Robust regression, bootstrap CI, or data transformation\n")
} else {
  cat("  ✓ Residuals appear normally distributed\n")
}

# 2. Homoscedasticity (Breusch-Pagan test)
if(require("lmtest", quietly = TRUE)) {
  bp_test <- lmtest::bptest(full_model)
  cat(sprintf("\n✓ Breusch-Pagan heteroscedasticity test: BP=%.4f, p=%.4f\n",
              bp_test$statistic, bp_test$p.value))
  
  if(bp_test$p.value < 0.05) {
    cat("  ⚠ WARNING: Heteroscedasticity detected (p < 0.05)\n")
    cat("     Consider: Weighted least squares or robust standard errors\n")
  } else {
    cat("  ✓ Homoscedasticity assumption appears satisfied\n")
  }
}

# 3. Influential outliers (Cook's Distance)
cooks_d <- cooks.distance(full_model)
influential_threshold <- 4 / nrow(df_clean)
influential <- which(cooks_d > influential_threshold)

cat(sprintf("\n✓ Cook's Distance analysis (threshold=%.4f):\n", influential_threshold))
if(length(influential) > 0) {
  cat(sprintf("  ⚠ WARNING: %d influential observations detected\n", length(influential)))
  cat(sprintf("     Values: %s\n", paste(head(influential, 10), collapse=", ")))
  cat("     Consider: Sensitivity analysis removing these points\n")
} else {
  cat("  ✓ No influential outliers detected\n")
}

# Save diagnostic plots
cat("\nGenerating diagnostic plots...\n")
png("output/regression_diagnostics.png", width=1400, height=1000, res=120)
par(mfrow=c(2,2))
plot(full_model)
dev.off()
cat("✓ Diagnostic plots saved: output/regression_diagnostics.png\n\n")

# ==============================================================================
# 7. RELATIVE IMPORTANCE METRICS (LMG)
# ==============================================================================

cat("--- Relative Importance (LMG Metric) ---\n")
cat("This shows what % of R² each predictor contributes\n\n")

# Calculate relative importance
rel_imp <- calc.relimp(full_model, type = "lmg", rela = TRUE)

# Extract results
importance_results <- data.frame(
  Variable = names(rel_imp$lmg),
  LMG_Contribution = rel_imp$lmg * 100,  # Convert to percentage
  Description = var_labels$Description[1:7],
  SE_Bootstrap = NA,
  CI_Lower = NA,
  CI_Upper = NA
)

# ==============================================================================
# 7.5 BOOTSTRAP CONFIDENCE INTERVALS FOR RELATIVE IMPORTANCE
# ==============================================================================

cat("Calculating bootstrap confidence intervals (1000 iterations)...\n")
set.seed(42)  # For reproducibility

boot_lmg <- function(data, indices) {
  d <- data[indices, ]
  model <- lm(q10_scaled ~ ., data = d)
  rel_imp_boot <- calc.relimp(model, type="lmg", rela=TRUE)
  return(rel_imp_boot$lmg * 100)
}

# Prepare data for bootstrap
boot_data <- cbind(
  predictors_scaled,
  q10_scaled = outcome_scaled
)

if(require("boot", quietly = TRUE)) {
  boot_results <- boot::boot(data = boot_data, 
                             statistic = boot_lmg, 
                             R = 1000,
                             parallel = "multicore",
                             ncpus = 4)
  
  # Extract confidence intervals
  for(i in 1:7) {
    ci <- quantile(boot_results$t[,i], c(0.025, 0.975), na.rm=TRUE)
    se <- sd(boot_results$t[,i], na.rm=TRUE)
    importance_results$SE_Bootstrap[i] <- se
    importance_results$CI_Lower[i] <- ci[1]
    importance_results$CI_Upper[i] <- ci[2]
  }
  cat("✓ Bootstrap confidence intervals calculated\n\n")
} else {
  cat("⚠ Boot package not available - skipping bootstrap CI\n\n")
}

# Sort by importance
importance_results <- importance_results[order(-importance_results$LMG_Contribution), ]

cat("\nRANKED PREDICTORS (by contribution to R²):\n")
for(i in 1:nrow(importance_results)) {
  lmg <- importance_results$LMG_Contribution[i]
  ci_lower <- importance_results$CI_Lower[i]
  ci_upper <- importance_results$CI_Upper[i]
  
  if(!is.na(ci_lower)) {
    cat(sprintf("%d. %s (%s): %.1f%% [95%% CI: %.1f%% - %.1f%%]\n", 
                i,
                importance_results$Variable[i],
                importance_results$Description[i],
                lmg, ci_lower, ci_upper))
  } else {
    cat(sprintf("%d. %s (%s): %.1f%%\n", 
                i,
                importance_results$Variable[i],
                importance_results$Description[i],
                lmg))
  }
}
cat("\n")

# Create visualization
png("output/relative_importance_barplot.png", width = 1400, height = 800, res = 120)
par(mar = c(8, 5, 4, 2))
barplot(importance_results$LMG_Contribution,
        names.arg = paste0(importance_results$Variable, "\n", 
                          substr(importance_results$Description, 1, 20)),
        las = 2,
        col = colorRampPalette(c("#E46726", "#F4A261", "#6D9EC1"))(7),
        main = "The Royal Rumble: Which Skill REALLY Gets You The Job?",
        ylab = "Contribution to R² (%)",
        cex.names = 0.8,
        ylim = c(0, max(importance_results$LMG_Contribution) * 1.2))

# Add percentage labels on bars
text(x = seq_along(importance_results$LMG_Contribution) * 1.2 - 0.5,
     y = importance_results$LMG_Contribution + 1,
     labels = sprintf("%.1f%%", importance_results$LMG_Contribution),
     cex = 0.9,
     font = 2)
dev.off()
cat("Relative importance plot saved: output/relative_importance_barplot.png\n\n")

# ==============================================================================
# 8. HEAD-TO-HEAD COMPARISONS
# ==============================================================================

cat("=== HEAD-TO-HEAD COMPARISONS ===\n")

# Compare the top contenders directly
head_to_head_pairs <- list(
  c("q1", "q4"),  # Technical vs Time Management (Original finding)
  c("q2", "q4"),  # Communication vs Time Management
  c("q3", "q4"),  # Leadership vs Time Management
  c("q1", "q3")   # Technical vs Leadership
)

cat("\nStandardized Beta Coefficients (Direct Comparisons):\n")
for(pair in head_to_head_pairs) {
  model_pair <- lm(scale(df_clean$q10) ~ scale(df_clean[[pair[1]]]) + scale(df_clean[[pair[2]]]))
  coefs <- summary(model_pair)$coefficients
  
  var1_label <- var_labels$Description[var_labels$Variable == pair[1]]
  var2_label <- var_labels$Description[var_labels$Variable == pair[2]]
  
  cat(sprintf("\n%s vs %s:\n", pair[1], pair[2]))
  cat(sprintf("  %s: β=%.3f (p=%.4f)\n", 
              substr(var1_label, 1, 30), 
              coefs[2, 1], 
              coefs[2, 4]))
  cat(sprintf("  %s: β=%.3f (p=%.4f)\n", 
              substr(var2_label, 1, 30), 
              coefs[3, 1], 
              coefs[3, 4]))
  
  if(coefs[2, 1] > coefs[3, 1]) {
    cat(sprintf("  → %s is STRONGER\n", pair[1]))
  } else {
    cat(sprintf("  → %s is STRONGER\n", pair[2]))
  }
}
cat("\n")

# ==============================================================================
# 9. VALIDATION: PARTIAL CORRELATIONS
# ==============================================================================

cat("=== PARTIAL CORRELATION ANALYSIS ===\n")
cat("Controlling for other variables to isolate true effects\n\n")

# Calculate partial correlations (controlling for all other predictors)
library(ppcor)
if(!require("ppcor")) {
  install.packages("ppcor")
  library(ppcor)
}

partial_data <- df_clean[, paste0("q", 1:7)]
partial_data$outcome <- df_clean$q10

partial_results <- pcor(partial_data)

cat("Partial correlations with q10 (controlling for q1-q7):\n")
partial_cors <- partial_results$estimate[1:7, 8]
names(partial_cors) <- paste0("q", 1:7)
partial_cors_sorted <- sort(partial_cors, decreasing = TRUE)

for(i in 1:length(partial_cors_sorted)) {
  var_name <- names(partial_cors_sorted)[i]
  var_desc <- var_labels$Description[var_labels$Variable == var_name]
  cat(sprintf("  %s (%s): %.3f\n", var_name, var_desc, partial_cors_sorted[i]))
}
cat("\n")

# ==============================================================================
# 10. THE VERDICT: SUMMARY REPORT
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("                         FINAL VERDICT: THE ROYAL RUMBLE                        \n")
cat("================================================================================\n\n")

top_3 <- importance_results[1:3, ]

cat("TOP 3 PREDICTORS OF JOB SUCCESS (q10):\n\n")
cat(sprintf("🥇 GOLD:   %s - %.1f%% contribution\n", 
            top_3$Description[1], top_3$LMG_Contribution[1]))
cat(sprintf("🥈 SILVER: %s - %.1f%% contribution\n", 
            top_3$Description[2], top_3$LMG_Contribution[2]))
cat(sprintf("🥉 BRONZE: %s - %.1f%% contribution\n", 
            top_3$Description[3], top_3$LMG_Contribution[3]))

cat("\n")
cat(sprintf("Model R²: %.3f (explains %.1f%% of variance in job success)\n", 
            summary_full$r.squared, 
            summary_full$r.squared * 100))

cat("\n")
cat("INTERPRETATION:\n")
if(top_3$Variable[1] == "q4") {
  cat("✓ The 'Remote Work Paradox' is CONFIRMED\n")
  cat("  Time Management beats Technical Skills for remote career success\n")
} else if(top_3$Variable[1] == "q1") {
  cat("✗ The 'Remote Work Paradox' is REJECTED\n")
  cat("  Technical Skills are actually the strongest driver\n")
} else {
  cat("⚠ UNEXPECTED FINDING:\n")
  cat(sprintf("  %s is the strongest predictor (not Time Mgmt or Technical)\n", 
              top_3$Description[1]))
}

cat("\n================================================================================\n")

# ==============================================================================
# 11. EXPORT RESULTS
# ==============================================================================

# Save all results to CSV
write.csv(importance_results, "output/relative_importance_results.csv", row.names = FALSE)
write.csv(cor_matrix, "output/correlation_matrix.csv")
write.csv(var_labels, "output/variable_labels.csv", row.names = FALSE)

cat("\nAll results exported to CSV files.\n")
cat("Analysis complete!\n")
