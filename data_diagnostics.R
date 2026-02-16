################################################################################
# PROJECT VECTOR: DATA DIAGNOSTIC SCRIPT
# Purpose: Quick data quality check before running main analysis
# Run this FIRST to verify data structure
################################################################################

# Ensure a CRAN mirror is set for non-interactive installs
options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("\n")
cat("================================================================================\n")
cat("                    PROJECT VECTOR: DATA DIAGNOSTICS                           \n")
cat("================================================================================\n\n")

# Load required library
if(!require(dplyr)) {
  install.packages("dplyr")
  library(dplyr)
}

# ==============================================================================
# 1. LOCATE AND LOAD DATA
# ==============================================================================

cat("STEP 1: Locating data file...\n")
cat("----------------------------------------------------------------------\n")

# Try to find the CSV file
possible_paths <- c(
  "vector_survey_responses.csv",
  file.path(getwd(), "vector_survey_responses.csv")
)

csv_file <- NULL
for(path in possible_paths) {
  if(file.exists(path)) {
    csv_file <- path
    break
  }
}

if(is.null(csv_file)) {
  cat("✗ ERROR: Data file not found in any of these locations:\n")
  for(p in possible_paths) {
    cat(sprintf("  - %s\n", p))
  }
  cat("\nCurrent working directory: ", getwd(), "\n")
  cat("\nPlease either:\n")
  cat("  1. Set working directory: setwd('path/to/your/data')\n")
  cat("  2. Provide full path to CSV file\n")
  stop("Data file not found")
} else {
  cat(sprintf("✓ Found data file: %s\n\n", csv_file))
}

# Load data
df <- read.csv(csv_file, check.names = FALSE)
cat(sprintf("✓ Data loaded: %d rows × %d columns\n\n", nrow(df), ncol(df)))

# ==============================================================================
# 2. EXAMINE STRUCTURE
# ==============================================================================

cat("STEP 2: Examining data structure...\n")
cat("----------------------------------------------------------------------\n")

# Show first few column names
cat("\nFirst 10 column names:\n")
for(i in 1:min(10, ncol(df))) {
  cat(sprintf("  Column %d: %s\n", i, colnames(df)[i]))
}

# Check for duplicate column names
dupe_check <- duplicated(colnames(df))
if(any(dupe_check)) {
  cat("\n⚠ WARNING: Duplicate column names detected!\n")
  cat("  Will be fixed automatically in main analysis script.\n\n")
} else {
  cat("\n✓ No duplicate column names\n\n")
}

# ==============================================================================
# 3. IDENTIFY NUMERIC QUESTION COLUMNS
# ==============================================================================

cat("STEP 3: Identifying Likert scale questions...\n")
cat("----------------------------------------------------------------------\n")

# Based on your survey structure, questions should be in columns 8-18
target_cols <- 8:18

cat("\nAssuming Likert questions are in columns 8-18:\n")
for(i in target_cols) {
  sample_values <- head(unique(df[[i]]), 10)
  cat(sprintf("  Column %d: %s\n", i, paste(sample_values, collapse=", ")))
}

# Fix column names
colnames(df)[target_cols] <- paste0("q", 1:11)

# Convert to numeric
df[target_cols] <- lapply(df[target_cols], function(x) {
  as.numeric(as.character(x))
})

cat("\n✓ Columns renamed to q1-q11 and converted to numeric\n\n")

# ==============================================================================
# 4. DATA QUALITY CHECKS
# ==============================================================================

cat("STEP 4: Data quality assessment...\n")
cat("----------------------------------------------------------------------\n\n")

# Check sample size
complete_cases <- complete.cases(df[target_cols])
n_complete <- sum(complete_cases)
n_incomplete <- sum(!complete_cases)

cat(sprintf("Total responses: %d\n", nrow(df)))
cat(sprintf("Complete cases: %d (%.1f%%)\n", n_complete, n_complete/nrow(df)*100))
cat(sprintf("Incomplete cases: %d (%.1f%%)\n\n", n_incomplete, n_incomplete/nrow(df)*100))

if(n_complete < 30) {
  cat("⚠ WARNING: Sample size is small (n < 30)\n")
  cat("  - Results may not be statistically robust\n")
  cat("  - Consider collecting more data if possible\n\n")
} else if(n_complete < 50) {
  cat("✓ Sample size is acceptable (30 ≤ n < 50)\n")
  cat("  - Basic analyses will work\n")
  cat("  - Subgroup analyses may be limited\n\n")
} else {
  cat("✓ Sample size is good (n ≥ 50)\n")
  cat("  - All analyses should work well\n\n")
}

# Check value ranges
cat("Value range check (should be 1-5 for Likert scale):\n")
for(q in paste0("q", 1:11)) {
  values <- df[[q]][!is.na(df[[q]])]
  min_val <- min(values, na.rm = TRUE)
  max_val <- max(values, na.rm = TRUE)
  n_na <- sum(is.na(df[[q]]))
  
  status <- if(min_val >= 1 && max_val <= 5) "✓" else "⚠"
  
  cat(sprintf("  %s %s: range [%.1f, %.1f], %d NAs\n", 
              status, q, min_val, max_val, n_na))
}

cat("\n")

# Missing data pattern
missing_counts <- colSums(is.na(df[target_cols]))
if(any(missing_counts > nrow(df) * 0.1)) {
  cat("⚠ WARNING: Some questions have >10% missing data:\n")
  high_missing <- names(missing_counts[missing_counts > nrow(df) * 0.1])
  for(q in high_missing) {
    pct <- missing_counts[q] / nrow(df) * 100
    cat(sprintf("  - %s: %.1f%% missing\n", q, pct))
  }
  cat("\n")
} else {
  cat("✓ Missing data is acceptable (<10% per question)\n\n")
}

# ==============================================================================
# 5. DESCRIPTIVE STATISTICS
# ==============================================================================

cat("STEP 5: Descriptive statistics for each question...\n")
cat("----------------------------------------------------------------------\n\n")

df_clean <- df[complete_cases, ]

for(q in paste0("q", 1:11)) {
  values <- df_clean[[q]]
  
  cat(sprintf("%s: Mean=%.2f, SD=%.2f, Median=%.0f, Range=[%.0f-%.0f]\n",
              q,
              mean(values, na.rm = TRUE),
              sd(values, na.rm = TRUE),
              median(values, na.rm = TRUE),
              min(values, na.rm = TRUE),
              max(values, na.rm = TRUE)))
}

cat("\n")

# Check for variables with no variance
low_variance <- sapply(df_clean[paste0("q", 1:11)], function(x) {
  sd(x, na.rm = TRUE) < 0.5
})

if(any(low_variance)) {
  cat("⚠ WARNING: Some questions have very low variance (SD < 0.5):\n")
  cat("  This suggests ceiling effects or lack of discrimination\n")
  for(q in names(low_variance[low_variance])) {
    cat(sprintf("  - %s: SD = %.2f\n", q, sd(df_clean[[q]], na.rm=TRUE)))
  }
  cat("\n")
} else {
  cat("✓ All questions show adequate variance\n\n")
}

# ==============================================================================
# 6. DEMOGRAPHIC VARIABLES CHECK
# ==============================================================================

cat("STEP 6: Checking demographic variables...\n")
cat("----------------------------------------------------------------------\n\n")

# Check career stage column (column 3)
if(ncol(df) >= 3) {
  cat("Career Stage distribution:\n")
  stage_table <- table(df[[3]])
  print(stage_table)
  cat("\n")
}

# Check country column (column 5)
if(ncol(df) >= 5) {
  cat("Top 5 countries:\n")
  country_table <- sort(table(df[[5]]), decreasing = TRUE)
  print(head(country_table, 5))
  cat("\n")
}

# Check role column (column 6)  
if(ncol(df) >= 6) {
  cat("Top 5 roles:\n")
  role_table <- sort(table(df[[6]]), decreasing = TRUE)
  print(head(role_table, 5))
  cat("\n")
}

# ==============================================================================
# 7. FINAL RECOMMENDATIONS
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("                              RECOMMENDATIONS                                   \n")
cat("================================================================================\n\n")

# Generate recommendations based on diagnostics
recommendations <- character(0)

if(n_complete < 30) {
  recommendations <- c(recommendations, 
                      "⚠ CRITICAL: Increase sample size before publication (target: n ≥ 50)")
}

if(any(missing_counts > nrow(df) * 0.2)) {
  recommendations <- c(recommendations,
                      "⚠ Address high missing data rates (>20%) in some questions")
}

if(any(low_variance)) {
  recommendations <- c(recommendations,
                      "⚠ Review questions with low variance - may have ceiling effects")
}

if(n_complete >= 50 && max(missing_counts) < nrow(df) * 0.1 && !any(low_variance)) {
  recommendations <- c(recommendations,
                      "✓ Data quality is EXCELLENT - proceed with full analysis")
}

if(length(recommendations) == 0) {
  recommendations <- "✓ Data quality is GOOD - ready for analysis"
}

for(rec in recommendations) {
  cat(sprintf("%s\n", rec))
}

cat("\n")
cat("Ready to run main analysis?\n")
cat("  → Next step: source('run_all_analyses.R')\n\n")

cat("================================================================================\n\n")

# Save diagnostic report
dir.create("output", showWarnings = FALSE)
sink("output/data_diagnostic_report.txt")
cat("PROJECT VECTOR - DATA DIAGNOSTIC REPORT\n")
cat("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")
cat("Sample size:", n_complete, "complete cases\n")
cat("Missing data rate:", round(mean(missing_counts > 0) * 100, 1), "%\n")
cat("\nRecommendations:\n")
for(rec in recommendations) {
  cat(rec, "\n")
}
sink()

cat("Diagnostic report saved to: output/data_diagnostic_report.txt\n")
