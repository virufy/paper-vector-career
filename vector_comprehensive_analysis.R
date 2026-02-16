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

# Identify the numeric Likert scale columns (questions 1-11 in the survey)
# Based on your structure, these should be columns 8-18
target_cols <- 8:18
colnames(df)[target_cols] <- paste0("q", 1:11)

# Convert to numeric
df[target_cols] <- lapply(df[target_cols], function(x) {
  as.numeric(as.character(x))
})

# Create clean dataset (complete cases only)
df_clean <- df[complete.cases(df[target_cols]), ]

cat(sprintf("Data loaded successfully: %d complete responses\n", nrow(df_clean)))
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
cat("\nNote: VIF > 5 indicates potential multicollinearity issues\n\n")

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
  Description = var_labels$Description[1:7]
)

# Sort by importance
importance_results <- importance_results[order(-importance_results$LMG_Contribution), ]

cat("\nRANKED PREDICTORS (by contribution to R²):\n")
for(i in 1:nrow(importance_results)) {
  cat(sprintf("%d. %s (%s): %.1f%%\n", 
              i,
              importance_results$Variable[i],
              importance_results$Description[i],
              importance_results$LMG_Contribution[i]))
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
