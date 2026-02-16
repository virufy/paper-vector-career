################################################################################
# PROJECT VECTOR: ADVANCED SUBGROUP ANALYSIS
# Purpose: Examine if the "Remote Work Paradox" varies by demographics
# Author: Generated for Doctoral Research
# Date: February 2026
################################################################################

# Ensure a CRAN mirror is set for non-interactive installs
options(repos = c(CRAN = "https://cloud.r-project.org"))

library(dplyr)
library(ggplot2)
library(relaimpo)

# Ensure other dependencies are installed
deps <- c("lme4", "pbkrtest", "car", "ppcor")
for (pkg in deps) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(sprintf("  Installing %s...\n", pkg))
    install.packages(pkg, dependencies = TRUE, quiet = TRUE)
    library(pkg, character.only = TRUE, quietly = TRUE)
  }
}

# ==============================================================================
# 1. LOAD PREPARED DATA (assumes main script has run)
# ==============================================================================

cat("Loading data for subgroup analysis...\n")

# If running standalone, uncomment and run data preparation:
df <- read.csv("vector_survey_responses.csv", check.names = FALSE)
colnames(df) <- make.unique(colnames(df))
target_cols <- 8:18
colnames(df)[target_cols] <- paste0("q", 1:11)
df[target_cols] <- lapply(df[target_cols], function(x) as.numeric(as.character(x)))
df_clean <- df[complete.cases(df[target_cols]), ]

# ==============================================================================
# 2. CREATE DEMOGRAPHIC GROUPS (WITH IMPROVED RESILIENT MAPPING)
# ==============================================================================

cat("\n=== CREATING DEMOGRAPHIC SEGMENTS ===\n")

# Improved mapping strategy: Use column names instead of indices for resilience
# After reading the CSV, the actual columns are:
# Column 4: Career stage when volunteered
# Column 6: Role at Virufy
# Column 25: Countries of residence (note: column 5 is empty, actual data is in 25)

# A. TECH vs NON-TECH (expanded keywords for better coverage)
tech_keywords <- "App Dev|Web Dev|Developer|ML Engineering|Data Scientist|Cloud|IT|Engineer|Programming|Technical|Data Analysis|Software|AI|Machine Learning"
nontech_keywords <- "HR|Marketing|Operations|Legal|Admin|Management|Communications|Design|Product|Business|Outreach|Research|Writing|Grant"

df_clean$Role_Type <- ifelse(
  grepl(tech_keywords, df_clean[[6]], ignore.case = TRUE), 
  "Tech",
  ifelse(grepl(nontech_keywords, df_clean[[6]], ignore.case = TRUE),
         "Non-Tech",
         NA)  # Unclassified roles as NA
)

# B. STUDENT vs PROFESSIONAL (expanded student keywords)
df_clean$Career_Stage <- ifelse(
  grepl("student|undergraduate|master|doctoral|phd|graduate", df_clean[[4]], ignore.case = TRUE), 
  "Student", 
  "Professional"
)

# C. GEOGRAPHY (Global West vs South) - Use column 25 which has the country data
# Countries data includes: Canada, Pakistan, Japan, United Arab Emirates, USA, etc.
west_keywords <- "United States|USA|Canada|UK|United Kingdom|Japan|Australia|Singapore|Germany|France|Switzerland|Netherlands|Belgium|Austria|South Korea|New Zealand|Sweden|Norway|Denmark"
df_clean$Geography <- ifelse(
  grepl(west_keywords, df_clean[[25]], ignore.case = TRUE),
  "Global_West",
  "Global_South"
)

# Print segment sizes with clarity
cat("\n--- Role Type Distribution ---\n")
tech_count <- sum(df_clean$Role_Type == "Tech", na.rm = TRUE)
nontech_count <- sum(df_clean$Role_Type == "Non-Tech", na.rm = TRUE)
unclassified_count <- sum(is.na(df_clean$Role_Type))
cat(sprintf("Tech: %d | Non-Tech: %d | Unclassified: %d\n\n", tech_count, nontech_count, unclassified_count))

cat("--- Career Stage Distribution ---\n")
student_count <- sum(df_clean$Career_Stage == "Student", na.rm = TRUE)
prof_count <- sum(df_clean$Career_Stage == "Professional", na.rm = TRUE)
cat(sprintf("Student: %d | Professional: %d\n\n", student_count, prof_count))

cat("--- Geography Distribution ---\n")
west_count <- sum(df_clean$Geography == "Global_West", na.rm = TRUE)
south_count <- sum(df_clean$Geography == "Global_South", na.rm = TRUE)
cat(sprintf("Global West: %d | Global South: %d\n\n", west_count, south_count))

# ==============================================================================
# 3. SUBGROUP RELATIVE IMPORTANCE ANALYSIS
# ==============================================================================

cat("=== SUBGROUP ANALYSIS: TOP PREDICTOR BY DEMOGRAPHIC ===\n\n")

# Function to analyze a subgroup
analyze_subgroup <- function(data, group_name) {
  
  if(nrow(data) < 15) {
    cat(sprintf("%s: Sample too small (n=%d) - skipping\n\n", group_name, nrow(data)))
    return(NULL)
  }
  
  cat(sprintf("--- %s (n=%d) ---\n", group_name, nrow(data)))
  
  # Prepare data
  predictors <- data[, paste0("q", 1:7)]
  outcome <- data$q10
  
  # Handle missing values
  complete_idx <- complete.cases(predictors, outcome)
  predictors <- predictors[complete_idx, ]
  outcome <- outcome[complete_idx]
  
  if(length(outcome) < 15) {
    cat("Insufficient complete cases - skipping\n\n")
    return(NULL)
  }
  
  # Standardize
  predictors_scaled <- as.data.frame(scale(predictors))
  outcome_scaled <- scale(outcome)
  
  # Run model
  model <- lm(outcome_scaled ~ ., data = predictors_scaled)
  
  # Calculate relative importance
  rel_imp <- calc.relimp(model, type = "lmg", rela = TRUE)
  
  # Create results dataframe
  results <- data.frame(
    Variable = names(rel_imp$lmg),
    Contribution = rel_imp$lmg * 100
  )
  results <- results[order(-results$Contribution), ]
  
  # Add Status column for scientific integrity labeling
  # Robust (n>=30): Confident findings
  # Exploratory/Preliminary (15<=n<30): Requires replication
  results$Status <- ifelse(nrow(data) >= 30, 
                           "Robust", 
                           "Exploratory/Preliminary")
  
  # Calculate statistical power
  n_subgroup <- length(outcome)
  n_predictors <- 7
  r_squared_subgroup <- summary(model)$r.squared
  effect_size_f2 <- ifelse(r_squared_subgroup < 1, 
                           r_squared_subgroup / (1 - r_squared_subgroup), 1.0)
  df_residual <- n_subgroup - n_predictors - 1
  f_crit <- qf(0.95, n_predictors, df_residual)
  lambda <- sqrt(n_subgroup * effect_size_f2)
  power <- max(0, min(1, 1 - pf(f_crit, n_predictors, df_residual, lambda)))
  
  # Print top 3
  cat("\nTop 3 Predictors:\n")
  for(i in 1:min(3, nrow(results))) {
    status_label <- results$Status[i]
    power_pct <- power * 100
    cat(sprintf("  %d. %s: %.1f%% (Status: %s, Power: %.0f%%)\n", 
                i, results$Variable[i], results$Contribution[i],
                status_label, power_pct))
  }
  
  cat(sprintf("\nModel R²: %.3f", summary(model)$r.squared))
  if(power < 0.80 && nrow(data) < 30) {
    cat(sprintf(" | WARNING: Power=%.0f%% (underpowered)", power*100))
  }
  cat("\n\n")
  
  # Return results for plotting
  results$Group <- group_name
  return(results)
}

# Run analysis for each demographic
all_subgroup_results <- list()

# By Role Type
if(length(unique(df_clean$Role_Type)) > 1) {
  for(role in unique(df_clean$Role_Type)) {
    subset_data <- df_clean[df_clean$Role_Type == role, ]
    result <- analyze_subgroup(subset_data, paste("Role:", role))
    if(!is.null(result)) all_subgroup_results[[paste("Role", role)]] <- result
  }
}

# By Career Stage
if(length(unique(df_clean$Career_Stage)) > 1) {
  for(stage in unique(df_clean$Career_Stage)) {
    subset_data <- df_clean[df_clean$Career_Stage == stage, ]
    result <- analyze_subgroup(subset_data, paste("Stage:", stage))
    if(!is.null(result)) all_subgroup_results[[paste("Stage", stage)]] <- result
  }
}

# By Geography
if(length(unique(df_clean$Geography)) > 1) {
  for(geo in unique(df_clean$Geography)) {
    subset_data <- df_clean[df_clean$Geography == geo, ]
    result <- analyze_subgroup(subset_data, paste("Geography:", geo))
    if(!is.null(result)) all_subgroup_results[[paste("Geo", geo)]] <- result
  }
}

# ==============================================================================
# 4. VISUALIZATION: HEATMAP OF TOP PREDICTORS BY GROUP
# ==============================================================================

if(length(all_subgroup_results) > 0) {
  
  cat("\n=== CREATING SUBGROUP COMPARISON HEATMAP ===\n")
  
  dir.create("output", showWarnings = FALSE)
  
  # Combine all results
  combined_results <- do.call(rbind, all_subgroup_results)
  
  # Reshape for heatmap (top variable per group)
  top_vars <- combined_results %>%
    group_by(Group) %>%
    slice_max(order_by = Contribution, n = 1)
  
  # Create visualization showing which variable is strongest in each group
  png("output/subgroup_top_predictors_comparison.png", width = 1400, height = 800, res = 120)
  
  ggplot(combined_results[combined_results$Variable %in% paste0("q", 1:4), ], 
         aes(x = Group, y = Contribution, fill = Variable)) +
    geom_bar(stat = "identity", position = "dodge") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 10),
          legend.position = "bottom") +
    labs(title = "Does the 'Remote Work Paradox' Hold Across Demographics?",
         subtitle = "Contribution of each skill to job success (q10) by demographic group",
         x = "Demographic Group",
         y = "Contribution to R² (%)") +
    scale_fill_brewer(palette = "Set2",
                      labels = c("q1: Technical", "q2: Communication", 
                                 "q3: Leadership", "q4: Time Mgmt"))
  
  dev.off()
  cat("Subgroup comparison plot saved: output/subgroup_top_predictors_comparison.png\n")
}

# ==============================================================================
# 5. STATISTICAL TEST: INTERACTION EFFECTS
# ==============================================================================

cat("\n=== INTERACTION EFFECT TESTS ===\n")
cat("Testing if demographic factors MODERATE the skill-outcome relationship\n\n")

# Test: Does Role Type moderate the relationship between q1 (Technical) and q10 (Job)?
if(length(unique(df_clean$Role_Type)) > 1) {
  cat("--- Test 1: Role Type × Technical Skills ---\n")
  
  df_clean$RoleType_numeric <- ifelse(df_clean$Role_Type == "Tech", 1, 0)
  
  interaction_model_1 <- lm(q10 ~ q1 * RoleType_numeric, data = df_clean)
  summary_int_1 <- summary(interaction_model_1)
  
  cat(sprintf("Interaction term (q1 × Role): β=%.3f, p=%.4f\n", 
              coef(interaction_model_1)[4],
              summary_int_1$coefficients[4, 4]))
  
  if(summary_int_1$coefficients[4, 4] < 0.05) {
    cat("→ SIGNIFICANT: Technical skills matter MORE/LESS depending on role type\n\n")
  } else {
    cat("→ Not significant: Effect is consistent across role types\n\n")
  }
}

# Test: Does Career Stage moderate q4 (Time Mgmt) → q10?
if(length(unique(df_clean$Career_Stage)) > 1) {
  cat("--- Test 2: Career Stage × Time Management ---\n")
  
  df_clean$CareerStage_numeric <- ifelse(df_clean$Career_Stage == "Student", 1, 0)
  
  interaction_model_2 <- lm(q10 ~ q4 * CareerStage_numeric, data = df_clean)
  summary_int_2 <- summary(interaction_model_2)
  
  cat(sprintf("Interaction term (q4 × Stage): β=%.3f, p=%.4f\n",
              coef(interaction_model_2)[4],
              summary_int_2$coefficients[4, 4]))
  
  if(summary_int_2$coefficients[4, 4] < 0.05) {
    cat("→ SIGNIFICANT: Time mgmt matters MORE/LESS for students vs professionals\n\n")
  } else {
    cat("→ Not significant: Effect is consistent across career stages\n\n")
  }
}

# ==============================================================================
# 6. EXPORT SUBGROUP RESULTS
# ==============================================================================

if(length(all_subgroup_results) > 0) {
  combined_results_export <- do.call(rbind, all_subgroup_results)
  rownames(combined_results_export) <- NULL  # Reset row names for clean export
  write.csv(combined_results_export, "output/subgroup_analysis_results.csv", row.names = FALSE)
  cat("\nSubgroup results exported to: output/subgroup_analysis_results.csv")
  cat("\nNote: Results marked 'Exploratory/Preliminary' require replication with larger sample.\n")
}

cat("\nAdvanced subgroup analysis complete!\n")
