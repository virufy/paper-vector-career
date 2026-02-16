################################################################################
# PROJECT VECTOR: MASTER ANALYSIS SCRIPT
# Purpose: Run all analyses in correct order
# Usage: Source this file to run complete analysis pipeline
################################################################################

# Ensure a CRAN mirror is set for non-interactive installs
options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("\n")
cat("================================================================================\n")
cat("               PROJECT VECTOR: COMPREHENSIVE ANALYSIS PIPELINE                 \n")
cat("================================================================================\n\n")

# Set working directory to where your CSV file is located
# IMPORTANT: Update this path to match your file location
# setwd("path/to/your/data/directory")

# Alternatively, if running from uploaded files directory: (do not change working dir by default)
# setwd("/path/to/your/data/directory")

# Check if data file exists
csv_file <- "vector_survey_responses.csv"

if(!file.exists(csv_file)) {
  cat("ERROR: Data file not found!\n")
  cat(sprintf("Looking for: %s\n", csv_file))
  cat(sprintf("Current directory: %s\n", getwd()))
  cat("\nPlease update the setwd() command in this script.\n")
  stop("Data file not found")
}

cat(sprintf("✓ Data file found: %s\n\n", csv_file))

# ==============================================================================
# STEP 1: MAIN COMPREHENSIVE ANALYSIS
# ==============================================================================

cat("STEP 1: Running comprehensive exploratory analysis...\n")
cat("----------------------------------------------------------------------\n\n")

tryCatch({
  source("vector_comprehensive_analysis.R")
  cat("\n✓ Step 1 completed successfully\n\n")
}, error = function(e) {
  cat(sprintf("\n✗ Error in Step 1: %s\n\n", e$message))
})

# ==============================================================================
# STEP 2: SUBGROUP ANALYSIS (Optional - comment out if not needed)
# ==============================================================================

cat("\nSTEP 2: Running demographic subgroup analysis...\n")
cat("----------------------------------------------------------------------\n\n")

tryCatch({
  source("vector_subgroup_analysis.R")
  cat("\n✓ Step 2 completed successfully\n\n")
}, error = function(e) {
  cat(sprintf("\n✗ Error in Step 2: %s\n\n", e$message))
  cat("Note: Subgroup analysis may fail if sample sizes are too small\n\n")
})

# ==============================================================================
# SUMMARY OF OUTPUTS
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("                            ANALYSIS COMPLETE                                   \n")
cat("================================================================================\n\n")

cat("Generated files (in output/ folder):\n")
cat("  📊 output/correlation_heatmap.png\n")
cat("  📊 output/relative_importance_barplot.png\n")
cat("  📊 output/subgroup_top_predictors_comparison.png (if applicable)\n")
cat("  📄 output/correlation_matrix.csv\n")
cat("  📄 output/relative_importance_results.csv\n")
cat("  📄 output/variable_labels.csv\n")
cat("  📄 output/subgroup_analysis_results.csv (if applicable)\n\n")

cat("Next steps for your dissertation:\n")
cat("  1. Review 'relative_importance_results.csv' for the ranking\n")
cat("  2. Check if Time Management (q4) is truly #1 (validates paradox)\n")
cat("  3. Examine correlation heatmap for multicollinearity issues\n")
cat("  4. Use subgroup analysis to explore demographic variations\n\n")

cat("================================================================================\n\n")
