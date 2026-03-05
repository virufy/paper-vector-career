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
# 2. CREATE DEMOGRAPHIC GROUPS
# ==============================================================================

cat("\n=== CREATING DEMOGRAPHIC SEGMENTS ===\n")

# Extract demographic columns (adjust indices based on your actual data structure)
# Column 3: Career stage
# Column 5: Country
# Column 6: Role

# A. TECH vs NON-TECH
tech_keywords <- "App Dev|Web Dev|ML Engineering|Data Scientist|Cloud|IT|Engineer|Developer"
df_clean$Role_Type <- ifelse(
  grepl(tech_keywords, df_clean[[6]], ignore.case = TRUE), 
  "Tech", 
  "Non-Tech"
)

# B. STUDENT vs PROFESSIONAL
df_clean$Career_Stage <- ifelse(
  grepl("student", df_clean[[3]], ignore.case = TRUE), 
  "Student", 
  "Professional"
)

# C. GEOGRAPHY (Global South vs West)
west_keywords <- "United States|USA|Canada|UK|United Kingdom|Japan|Australia|Singapore"
df_clean$Geography <- ifelse(
  grepl(west_keywords, df_clean[[5]], ignore.case = TRUE),
  "Global_West",
  "Global_South"
)

# Print segment sizes
cat(sprintf("\nTech: %d | Non-Tech: %d\n", 
            sum(df_clean$Role_Type == "Tech"), 
            sum(df_clean$Role_Type == "Non-Tech")))
cat(sprintf("Student: %d | Professional: %d\n", 
            sum(df_clean$Career_Stage == "Student"), 
            sum(df_clean$Career_Stage == "Professional")))
cat(sprintf("Global West: %d | Global South: %d\n\n", 
            sum(df_clean$Geography == "Global_West"), 
            sum(df_clean$Geography == "Global_South")))

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
  
  # Print top 3
  cat("\nTop 3 Predictors:\n")
  for(i in 1:min(3, nrow(results))) {
    cat(sprintf("  %d. %s: %.1f%%\n", i, results$Variable[i], results$Contribution[i]))
  }
  
  cat(sprintf("\nModel R²: %.3f\n", summary(model)$r.squared))
  cat("\n")
  
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
  write.csv(combined_results_export, "output/subgroup_analysis_results.csv", row.names = FALSE)
  cat("\nSubgroup results exported to: output/subgroup_analysis_results.csv\n")
}

cat("\nAdvanced subgroup analysis complete!\n")

#=============================UPDATED DEMOGRAPHIC SEGMENTS======================

# ────────────────────────────────────────────────────────────────
# 1. Install & load required packages (run once if needed)
# ────────────────────────────────────────────────────────────────
if (!require("janitor")) install.packages("janitor", quiet = TRUE)
if (!require("dplyr"))    install.packages("dplyr",    quiet = TRUE)
if (!require("stringr"))  install.packages("stringr",  quiet = TRUE)

library(janitor)
library(dplyr)
library(stringr)

# ────────────────────────────────────────────────────────────────
# 2. Fix column names (removes duplicates like "Confirmation")
# ────────────────────────────────────────────────────────────────
df_clean <- df_clean %>%
  clean_names()     # makes names snake_case + unique + safe

cat("Column names fixed. First 20 columns:\n")
print(head(colnames(df_clean), 20))

# ────────────────────────────────────────────────────────────────
# 3. Find key columns (robust name matching)
# ────────────────────────────────────────────────────────────────

# Career stage
career_col <- colnames(df_clean) %>%
  str_subset(regex("career_stage|stage_when_you_volunteered|best_describes_your_career_stage",
                   ignore_case = TRUE)) %>%
  first()

if (is.na(career_col)) stop("Career stage column not found")

# Role at Virufy
role_col <- colnames(df_clean) %>%
  str_subset(regex("role_at_virufy|best_describes_your_role",
                   ignore_case = TRUE)) %>%
  first()

if (is.na(role_col)) stop("Role column not found")

# Countries of residence
country_col <- colnames(df_clean) %>%
  str_subset(regex("countries_of_residence|country.*while_volunteering",
                   ignore_case = TRUE)) %>%
  first()

if (is.na(country_col)) stop("Country column not found")

# ────────────────────────────────────────────────────────────────
# 4. Create demographic variables
# ────────────────────────────────────────────────────────────────

df_clean <- df_clean %>%
  mutate(
    # ── Role Type (Tech vs Non-Tech) ───────────────────────────────
    role_text = str_to_lower(coalesce(.data[[role_col]], "")),

    Role_Type = case_when(
      str_detect(role_text, regex(
        "app (development|developer|dev)|web (development|developer|dev)|ml engineering|machine learning|data scientist|cloud engineering|cloud|it|cybersecurity|engineer|developer|aws|react|typescript|ai|\\bml\\b|\\bdata\\b|devops",
        ignore_case = TRUE
      )) ~ "Tech",

      role_text == "" ~ "Unknown / Not specified",
      TRUE ~ "Non-Tech"
    ),

    # ── Career Stage (handles multi-select) ────────────────────────
    career_text = str_to_lower(coalesce(.data[[career_col]], "")),

    has_student = str_detect(career_text, regex(
      "student|undergraduate|master|masters|doctoral|phd|high school",
      ignore_case = TRUE
    )),

    has_professional = str_detect(career_text, regex(
      "professional|\\d+-\\d+ years",
      ignore_case = TRUE
    )),

    has_prefer_not = str_detect(career_text, regex(
      "prefer not to answer",
      ignore_case = TRUE
    )),

    Career_Stage = case_when(
      has_student & has_professional              ~ "Hybrid (student + professional)",
      has_student                                 ~ "Student (current / recent)",
      has_professional                            ~ "Professional only",
      has_prefer_not                              ~ "Other / missing",
      TRUE                                        ~ "Other / missing"
    ),

    # ── Geography (approximate Global North/West vs South/Other) ───
    country_text = str_to_lower(coalesce(.data[[country_col]], "")),

    Geography = case_when(
      country_text == "" ~ "Unknown / Not specified",

      str_detect(country_text, regex(
        "united states|usa|canada|united kingdom|\\buk\\b|australia|new zealand|japan|singapore|south korea|germany|france|netherlands|sweden|switzerland|norway|denmark|finland|belgium|austria",
        ignore_case = TRUE
      )) ~ "Global North / West",

      TRUE ~ "Global South / Other"
    )
  )

# ────────────────────────────────────────────────────────────────
# 5. Print the requested distributions
# ────────────────────────────────────────────────────────────────

cat("\n=== Role Type Distribution ===\n")
df_clean %>%
  count(Role_Type, name = "Count") %>%
  arrange(desc(Count)) %>%
  mutate(Percentage = round(100 * Count / sum(Count), 1)) %>%
  print()

cat("\n=== Career Stage Distribution ===\n")
df_clean %>%
  count(Career_Stage, name = "Count") %>%
  arrange(desc(Count)) %>%
  mutate(Percentage = round(100 * Count / sum(Count), 1)) %>%
  print()



# Optional bonus: cross-tab
cat("\nCross-tab: Career Stage × Role Type\n")
table(df_clean$Career_Stage, df_clean$Role_Type) %>% print()


#==================GEOGRAPHY Distribution=======================================

# Use existing `country_col` and `Geography` classification computed earlier

# Print the Geography distribution
cat("\n=== Geography Distribution ===\n")
df_clean %>%
  count(Geography, name = "Count") %>%
  arrange(desc(Count)) %>%
  mutate(Percentage = round(100 * Count / sum(Count), 1)) %>%
  print()

# Bonus: show top 10 country combinations for reference
cat("\n=== Top 10 country combinations in data ===\n")
df_clean %>%
  count(.data[[country_col]], name = "Count", sort = TRUE) %>%
  head(10) %>%
  print()