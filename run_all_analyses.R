################################################################################
# PROJECT VECTOR: COMPLETE ANALYSIS PIPELINE
# Usage: Rscript --vanilla run_all_analyses.R
#
# Sections:
#   1. Setup & Data Loading
#   2. Descriptive Statistics & Correlations
#   3. Relative Importance Analysis (LMG)
#   4. Demographic Subgroup Analysis
#   5. Structural Equation Modeling (SEM)
#   6. Paper Claim Verification
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))

pkgs <- c("lme4", "pbkrtest", "car", "lavaan", "dplyr", "ggplot2",
          "corrplot", "relaimpo", "tidyr", "psych", "reshape2",
          "gridExtra", "ppcor", "janitor", "stringr")
for (p in pkgs) {
  if (!require(p, character.only = TRUE, quietly = TRUE)) {
    install.packages(p, dependencies = TRUE, quiet = TRUE)
    library(p, character.only = TRUE, quietly = TRUE)
  }
}

cat("\n")
cat("================================================================================\n")
cat("               PROJECT VECTOR: COMPREHENSIVE ANALYSIS PIPELINE                 \n")
cat("================================================================================\n\n")

# ==============================================================================
# 1. SETUP & DATA LOADING
# ==============================================================================

csv_file <- "vector_survey_responses.csv"
if (!file.exists(csv_file)) {
  cat(sprintf("ERROR: Data file not found: %s\nCurrent directory: %s\n", csv_file, getwd()))
  stop("Data file not found")
}

df <- read.csv(csv_file, check.names = FALSE)
colnames(df) <- make.unique(colnames(df))

if (ncol(df) < 18) stop("Unexpected data structure: expected at least 18 columns")

target_cols <- 8:18
colnames(df)[target_cols] <- paste0("q", 1:11)
df[target_cols] <- lapply(df[target_cols], function(x) as.numeric(as.character(x)))

# Missing data report
missing_counts <- colSums(is.na(df[target_cols]))
if (any(missing_counts > 0)) {
  cat("Missing data (listwise deletion applied):\n")
  for (i in seq_along(missing_counts)) {
    if (missing_counts[i] > 0)
      cat(sprintf("  %s: %d (%.1f%%)\n", names(missing_counts)[i],
                  missing_counts[i], 100 * missing_counts[i] / nrow(df)))
  }
}

n_before  <- nrow(df)
df_clean  <- df[complete.cases(df[target_cols]), ]
n_after   <- nrow(df_clean)
cat(sprintf("\nData loaded: %d → %d complete responses\n", n_before, n_after))
cat("Variables: q1-q11 (skills q1-q4, network q5-q7, outcomes q8-q11)\n\n")

dir.create("output", showWarnings = FALSE)

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

# ==============================================================================
# 2. DESCRIPTIVE STATISTICS & CORRELATIONS
# ==============================================================================

cat("=== DESCRIPTIVE STATISTICS ===\n")
desc_stats <- describe(df_clean[, paste0("q", 1:11)])
print(round(desc_stats[, c("mean", "sd", "median", "min", "max")], 2))
cat("\n")

cat("=== CORRELATION ANALYSIS ===\n")
cor_matrix <- cor(df_clean[, paste0("q", 1:11)], use = "complete.obs", method = "spearman")

cat("\nCorrelations with Job Success (q10):\n")
q10_cors <- sort(cor_matrix[, "q10"], decreasing = TRUE)
for (i in seq_along(q10_cors)) {
  v <- names(q10_cors)[i]
  cat(sprintf("  %s (%s): %.3f\n", v,
              var_labels$Description[var_labels$Variable == v], q10_cors[i]))
}
cat("\n")

png("output/correlation_heatmap.png", width = 1200, height = 1000, res = 120)
corrplot(cor_matrix, method = "color", type = "full", order = "hclust",
         addCoef.col = "black", number.cex = 0.7, tl.col = "black", tl.srt = 45,
         col = colorRampPalette(c("#6D9EC1", "white", "#E46726"))(200),
         title = "Project VECTOR: Full Correlation Matrix (Spearman)", mar = c(0,0,2,0))
dev.off()
cat("Correlation heatmap saved: output/correlation_heatmap.png\n\n")

# ==============================================================================
# 3. RELATIVE IMPORTANCE ANALYSIS (LMG)
# ==============================================================================

cat("=== RELATIVE IMPORTANCE ANALYSIS (LMG) ===\n")
cat("Predictors: q1-q7  |  Outcome: q10 (Job/Promotion Success)\n\n")

predictors_scaled <- as.data.frame(scale(df_clean[, paste0("q", 1:7)]))
outcome_scaled    <- scale(df_clean$q10)
full_model        <- lm(outcome_scaled ~ ., data = predictors_scaled)

cat("--- Regression Model Summary ---\n")
print(summary(full_model))

cat("--- Multicollinearity (VIF) ---\n")
vif_vals <- vif(full_model)
print(round(vif_vals, 2))
cat(sprintf("\nMax VIF = %.2f  (%s)\n\n", max(vif_vals),
            ifelse(max(vif_vals) > 10, "CRITICAL: severe multicollinearity",
                   ifelse(max(vif_vals) > 5, "CAUTION: moderate multicollinearity",
                          "No multicollinearity concerns"))))

# Regression diagnostics
sw <- shapiro.test(residuals(full_model))
cat(sprintf("Shapiro-Wilk: W=%.4f, p=%.4f  (%s)\n", sw$statistic, sw$p.value,
            ifelse(sw$p.value < 0.05, "non-normal residuals", "residuals OK")))
if (require("lmtest", quietly = TRUE)) {
  bp <- lmtest::bptest(full_model)
  cat(sprintf("Breusch-Pagan: BP=%.4f, p=%.4f  (%s)\n", bp$statistic, bp$p.value,
              ifelse(bp$p.value < 0.05, "heteroscedasticity detected", "homoscedasticity OK")))
}
cooks_d   <- cooks.distance(full_model)
threshold <- 4 / nrow(df_clean)
n_inf     <- sum(cooks_d > threshold)
cat(sprintf("Cook's D: %d influential observations (threshold=%.4f)\n\n", n_inf, threshold))

png("output/regression_diagnostics.png", width = 1400, height = 1000, res = 120)
par(mfrow = c(2, 2)); plot(full_model); dev.off()

# LMG decomposition
rel_imp <- calc.relimp(full_model, type = "lmg", rela = TRUE)
importance_results <- data.frame(
  Variable    = names(rel_imp$lmg),
  LMG_Contribution = rel_imp$lmg * 100,
  Description = var_labels$Description[1:7]
)

# Bootstrap CIs
set.seed(42)
boot_data <- cbind(predictors_scaled, q10_scaled = outcome_scaled)
boot_fn   <- function(data, idx) {
  m  <- lm(q10_scaled ~ ., data = data[idx, ])
  calc.relimp(m, type = "lmg", rela = TRUE)$lmg * 100
}
boot_res <- boot::boot(boot_data, boot_fn, R = 1000)
importance_results$CI_Lower <- apply(boot_res$t, 2, quantile, 0.025, na.rm = TRUE)
importance_results$CI_Upper <- apply(boot_res$t, 2, quantile, 0.975, na.rm = TRUE)
importance_results <- importance_results[order(-importance_results$LMG_Contribution), ]

cat("RANKED PREDICTORS (by contribution to R²):\n")
for (i in seq_len(nrow(importance_results))) {
  cat(sprintf("%d. %s (%s): %.1f%% [95%% CI: %.1f%% - %.1f%%]\n", i,
              importance_results$Variable[i], importance_results$Description[i],
              importance_results$LMG_Contribution[i],
              importance_results$CI_Lower[i], importance_results$CI_Upper[i]))
}
cat(sprintf("\nModel R² = %.3f (explains %.1f%% of variance in job success)\n\n",
            summary(full_model)$r.squared, summary(full_model)$r.squared * 100))

# Barplot
png("output/relative_importance_barplot.png", width = 1400, height = 800, res = 120)
par(mar = c(8, 5, 4, 2))
barplot(importance_results$LMG_Contribution,
        names.arg = paste0(importance_results$Variable, "\n",
                           substr(importance_results$Description, 1, 20)),
        las = 2, col = colorRampPalette(c("#E46726", "#F4A261", "#6D9EC1"))(7),
        main = "Relative Importance of Predictors for Career Success (LMG)",
        ylab = "Contribution to R² (%)",
        ylim = c(0, max(importance_results$LMG_Contribution) * 1.2))
text(x = seq_len(nrow(importance_results)) * 1.2 - 0.5,
     y = importance_results$LMG_Contribution + 0.5,
     labels = sprintf("%.1f%%", importance_results$LMG_Contribution), cex = 0.9, font = 2)
dev.off()
cat("Relative importance barplot saved: output/relative_importance_barplot.png\n\n")

# Head-to-head comparisons
cat("=== HEAD-TO-HEAD COMPARISONS ===\n")
for (pair in list(c("q1","q4"), c("q2","q4"), c("q3","q4"), c("q1","q3"))) {
  m    <- lm(scale(df_clean$q10) ~ scale(df_clean[[pair[1]]]) + scale(df_clean[[pair[2]]]))
  coef <- summary(m)$coefficients
  l1   <- var_labels$Description[var_labels$Variable == pair[1]]
  l2   <- var_labels$Description[var_labels$Variable == pair[2]]
  cat(sprintf("\n%s vs %s:\n  %s: b=%.3f (p=%.4f)\n  %s: b=%.3f (p=%.4f)\n  -> %s is STRONGER\n",
              pair[1], pair[2],
              substr(l1, 1, 35), coef[2,1], coef[2,4],
              substr(l2, 1, 35), coef[3,1], coef[3,4],
              ifelse(coef[2,1] > coef[3,1], pair[1], pair[2])))
}

# Partial correlations
cat("\n=== PARTIAL CORRELATION ANALYSIS ===\n")
pcor_data <- df_clean[, paste0("q", 1:7)]
pcor_data$outcome <- df_clean$q10
pcor_res  <- pcor(pcor_data)
pcors     <- sort(pcor_res$estimate[1:7, 8], decreasing = TRUE)
names(pcors) <- paste0("q", 1:7)[order(pcor_res$estimate[1:7, 8], decreasing = TRUE)]
for (i in seq_along(pcors)) {
  v <- names(pcors)[i]
  cat(sprintf("  %s (%s): %.3f\n", v,
              var_labels$Description[var_labels$Variable == v], pcors[i]))
}
cat("\n")

# Export
write.csv(importance_results, "output/relative_importance_results.csv", row.names = FALSE)
write.csv(cor_matrix,         "output/correlation_matrix.csv")
write.csv(var_labels,         "output/variable_labels.csv", row.names = FALSE)
cat("Main analysis results exported to output/\n\n")

# ==============================================================================
# 4. DEMOGRAPHIC SUBGROUP ANALYSIS
# ==============================================================================

cat("================================================================================\n")
cat("  STEP 4: DEMOGRAPHIC SUBGROUP ANALYSIS\n")
cat("================================================================================\n\n")

# Demographic classification
# Column 4 = career stage  |  Column 5 = country  |  Column 6 = role
tech_kw  <- "App Dev|Web Dev|ML Engineering|Data Scientist|Cloud|IT|Engineer|Developer"
west_kw  <- "United States|USA|Canada|UK|United Kingdom|Japan|Australia|Singapore"

df_clean$Role_Type    <- ifelse(grepl(tech_kw,  df_clean[[6]], ignore.case = TRUE), "Tech", "Non-Tech")
df_clean$Career_Stage <- ifelse(grepl("student|undergraduate|master|doctoral|phd|high school",
                                      df_clean[[4]], ignore.case = TRUE), "Student", "Professional")
df_clean$Geography    <- ifelse(grepl(west_kw,  df_clean[[5]], ignore.case = TRUE), "Global_West", "Global_South")

cat(sprintf("Role:    Tech=%d | Non-Tech=%d\n",
            sum(df_clean$Role_Type == "Tech"), sum(df_clean$Role_Type == "Non-Tech")))
cat(sprintf("Stage:   Student=%d | Professional=%d\n",
            sum(df_clean$Career_Stage == "Student"), sum(df_clean$Career_Stage == "Professional")))
cat(sprintf("Geo:     Global_West=%d | Global_South=%d\n\n",
            sum(df_clean$Geography == "Global_West"), sum(df_clean$Geography == "Global_South")))

# Subgroup LMG function
analyze_subgroup <- function(data, group_name) {
  if (nrow(data) < 15) {
    cat(sprintf("%s: Sample too small (n=%d) - skipping\n\n", group_name, nrow(data)))
    return(NULL)
  }
  preds <- data[, paste0("q", 1:7)]
  out   <- data$q10
  cc    <- complete.cases(preds, out); preds <- preds[cc,]; out <- out[cc]
  if (length(out) < 15) { cat("Insufficient complete cases\n\n"); return(NULL) }

  m   <- lm(scale(out) ~ ., data = as.data.frame(scale(preds)))
  ri  <- calc.relimp(m, type = "lmg", rela = TRUE)
  res <- data.frame(Variable = names(ri$lmg), Contribution = ri$lmg * 100)
  res <- res[order(-res$Contribution), ]

  cat(sprintf("--- %s (n=%d, R²=%.3f) ---\n", group_name, length(out), summary(m)$r.squared))
  cat("Top 3 Predictors:\n")
  for (i in 1:min(3, nrow(res))) cat(sprintf("  %d. %s: %.1f%%\n", i, res$Variable[i], res$Contribution[i]))
  cat("\n")

  res$Group <- group_name
  res
}

all_subgroup_results <- list()

for (role in unique(df_clean$Role_Type)) {
  r <- analyze_subgroup(df_clean[df_clean$Role_Type == role, ], paste("Role:", role))
  if (!is.null(r)) all_subgroup_results[[paste("Role", role)]] <- r
}
for (stage in unique(df_clean$Career_Stage)) {
  r <- analyze_subgroup(df_clean[df_clean$Career_Stage == stage, ], paste("Stage:", stage))
  if (!is.null(r)) all_subgroup_results[[paste("Stage", stage)]] <- r
}
for (geo in unique(df_clean$Geography)) {
  r <- analyze_subgroup(df_clean[df_clean$Geography == geo, ], paste("Geo:", geo))
  if (!is.null(r)) all_subgroup_results[[paste("Geo", geo)]] <- r
}

# Subgroup comparison plot
if (length(all_subgroup_results) > 0) {
  combined <- do.call(rbind, all_subgroup_results)

  png("output/subgroup_top_predictors_comparison.png", width = 1400, height = 800, res = 120)
  print(
    ggplot(combined[combined$Variable %in% paste0("q", 1:4), ],
           aes(x = Group, y = Contribution, fill = Variable)) +
      geom_bar(stat = "identity", position = "dodge") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      labs(title = "Predictor Contribution to Career Success by Demographic Group",
           x = "Group", y = "Contribution to R² (%)") +
      scale_fill_brewer(palette = "Set2",
                        labels = c("q1: Technical", "q2: Communication",
                                   "q3: Leadership", "q4: Time Mgmt"))
  )
  dev.off()
  cat("Subgroup comparison plot saved: output/subgroup_top_predictors_comparison.png\n")

  write.csv(combined, "output/subgroup_analysis_results.csv", row.names = FALSE)
  cat("Subgroup results exported to: output/subgroup_analysis_results.csv\n\n")
}

# Interaction tests
cat("=== INTERACTION EFFECT TESTS ===\n")
df_clean$Role_num  <- ifelse(df_clean$Role_Type == "Tech", 1, 0)
df_clean$Stage_num <- ifelse(df_clean$Career_Stage == "Student", 1, 0)

int1 <- lm(q10 ~ q1 * Role_num,  data = df_clean); s1 <- summary(int1)$coefficients
int2 <- lm(q10 ~ q4 * Stage_num, data = df_clean); s2 <- summary(int2)$coefficients
cat(sprintf("Role x Technical:       b=%.3f, p=%.4f  -> %s\n",
            s1[4,1], s1[4,4], ifelse(s1[4,4] < 0.05, "SIGNIFICANT", "Not significant")))
cat(sprintf("Career Stage x TimeMgmt: b=%.3f, p=%.4f  -> %s\n\n",
            s2[4,1], s2[4,4], ifelse(s2[4,4] < 0.05, "SIGNIFICANT", "Not significant")))

# ==============================================================================
# 5. STRUCTURAL EQUATION MODELING (SEM)
# ==============================================================================

cat("================================================================================\n")
cat("  STEP 5: STRUCTURAL EQUATION MODELING (SEM)\n")
cat("================================================================================\n\n")

sem_model <- '
  Skill_Development =~ q1 + q2 + q3 + q4
  Networking        =~ q5 + q6 + q7
  Career_Outcomes   =~ q9 + q10 + q11
  Career_Outcomes   ~  Skill_Development + Networking
'
fit <- sem(sem_model, data = df_clean,
           ordered = c("q1","q2","q3","q4","q5","q6","q7","q9","q10","q11"))

cat("--- SEM Results ---\n")
summary(fit, standardized = TRUE, fit.measures = TRUE, rsquare = TRUE)

idx <- fitMeasures(fit, c("cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"))
cat("\n=== MODEL FIT INDICES ===\n")
cat(sprintf("  CFI   = %.3f  (>0.95 required)   %s\n", idx["cfi"],  ifelse(idx["cfi"]  >= 0.95, "PASS", "FAIL")))
cat(sprintf("  TLI   = %.3f  (>0.95 required)   %s\n", idx["tli"],  ifelse(idx["tli"]  >= 0.95, "PASS", "FAIL")))
cat(sprintf("  RMSEA = %.3f  (<0.06 required)   %s\n", idx["rmsea"],ifelse(idx["rmsea"] <= 0.06, "PASS", "FAIL")))
cat(sprintf("  SRMR  = %.3f  (<0.08 required)   %s\n\n", idx["srmr"],ifelse(idx["srmr"] <= 0.08, "PASS", "FAIL")))

df_clean$HC <- rowMeans(df_clean[, c("q1","q2","q3","q4")], na.rm = TRUE)
df_clean$SC <- rowMeans(df_clean[, c("q5","q6","q7")],      na.rm = TRUE)
r_comp <- cor(df_clean$HC, df_clean$SC)
cat(sprintf("Composite r (Human Capital vs Social Capital): %.3f\n\n", r_comp))

fit_df <- data.frame(
  Index = c("CFI","TLI","RMSEA","RMSEA_CI_lower","RMSEA_CI_upper","SRMR","HC_SC_composite_r","N"),
  Value = c(round(idx["cfi"],3), round(idx["tli"],3), round(idx["rmsea"],3),
            round(idx["rmsea.ci.lower"],3), round(idx["rmsea.ci.upper"],3),
            round(idx["srmr"],3), round(r_comp,3), nrow(df_clean))
)
write.csv(fit_df, "output/sem_fit_indices.csv", row.names = FALSE)
cat("SEM fit indices saved: output/sem_fit_indices.csv\n\n")

# ==============================================================================
# 6. PAPER CLAIM VERIFICATION
# ==============================================================================

cat("================================================================================\n")
cat("  STEP 6: PAPER CLAIM VERIFICATION\n")
cat("================================================================================\n\n")

chk <- function(got, expected, tol = 0.02) ifelse(abs(got - expected) <= tol, "MATCH", "MISMATCH")

lmg_v <- round(rel_imp$lmg * 100, 1)
paper_t2 <- c(q1=14.4, q2=16.1, q3=17.2, q4=13.4, q5=11.0, q6=15.7, q7=12.2)
r2_v <- round(summary(full_model)$r.squared, 3)

run_lmg_sub <- function(data) {
  p <- as.data.frame(scale(data[, paste0("q", 1:7)]))
  o <- scale(data$q10); cc <- complete.cases(p, o); p <- p[cc,]; o <- o[cc]
  if (length(o) < 15) return(NULL)
  m  <- lm(o ~ ., data = p)
  ri <- calc.relimp(m, type = "lmg", rela = TRUE)
  sort(ri$lmg * 100, decreasing = TRUE)
}

tech_res    <- run_lmg_sub(df_clean[df_clean$Role_Type    == "Tech",        ])
nontech_res <- run_lmg_sub(df_clean[df_clean$Role_Type    == "Non-Tech",    ])
student_res <- run_lmg_sub(df_clean[df_clean$Career_Stage == "Student",     ])
prof_res    <- run_lmg_sub(df_clean[df_clean$Career_Stage == "Professional",])

cat("  Claim                              | Paper   | Code    | Status\n")
cat("  -----------------------------------|---------|---------|----------\n")
cat(sprintf("  SEM CFI                            | 0.975   | %.3f   | %s\n", idx["cfi"],   chk(idx["cfi"],   0.975, 0.005)))
cat(sprintf("  SEM RMSEA                          | 0.039   | %.3f   | %s\n", idx["rmsea"], chk(idx["rmsea"], 0.039, 0.005)))
cat(sprintf("  Composite r (HC vs SC)             | 0.940   | %.3f   | %s\n", r_comp,       chk(r_comp, 0.94, 0.02)))
cat(sprintf("  Full-sample R2                     | 0.575   | %.3f   | %s\n", r2_v,         chk(r2_v, 0.575, 0.001)))
for (v in paste0("q", 1:7))
  cat(sprintf("  Table 2 %-5s                      | %5.1f%%  | %5.1f%%  | %s\n",
              v, paper_t2[v], lmg_v[v], chk(lmg_v[v], paper_t2[v], 0.2)))
if (!is.null(tech_res)) {
  cat(sprintf("  Tech subgroup q3 (Leadership)      | 18.4%%   | %.1f%%   | %s\n", tech_res["q3"],    chk(tech_res["q3"],    18.4, 0.2)))
  cat(sprintf("  Tech subgroup q6 (Net Quality)     | 16.9%%   | %.1f%%   | %s\n", tech_res["q6"],    chk(tech_res["q6"],    16.9, 0.2)))
}
if (!is.null(nontech_res))
  cat(sprintf("  Non-Tech subgroup q1 (Technical)   | 25.2%%   | %.1f%%   | %s\n", nontech_res["q1"], chk(nontech_res["q1"], 25.2, 0.2)))
if (!is.null(student_res))
  cat(sprintf("  Student subgroup q3 (Leadership)   | 23.3%%   | %.1f%%   | %s\n", student_res["q3"], chk(student_res["q3"], 23.3, 0.2)))
if (!is.null(prof_res))
  cat(sprintf("  Prof subgroup q4 (Time Mgmt)       | 17.8%%   | %.1f%%   | %s\n", prof_res["q4"],    chk(prof_res["q4"],    17.8, 0.2)))

cat("\n  Note: SEM/composite r mismatches are expected on the anonymized local dataset.\n")
cat("  Published SEM results (CFI=0.975, RMSEA=0.039) were run on the full dataset.\n\n")

# ==============================================================================
# DONE
# ==============================================================================

cat("================================================================================\n")
cat("  ANALYSIS COMPLETE\n")
cat("================================================================================\n\n")
cat("Output files:\n")
cat("  output/correlation_heatmap.png\n")
cat("  output/regression_diagnostics.png\n")
cat("  output/relative_importance_barplot.png\n")
cat("  output/subgroup_top_predictors_comparison.png\n")
cat("  output/correlation_matrix.csv\n")
cat("  output/relative_importance_results.csv\n")
cat("  output/variable_labels.csv\n")
cat("  output/subgroup_analysis_results.csv\n")
cat("  output/sem_fit_indices.csv\n\n")
