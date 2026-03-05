################################################################################
# PROJECT VECTOR: STRUCTURAL EQUATION MODELING (SEM)
# Purpose: Validate the measurement model and confirm construct validity
# Model: Skill_Development + Networking -> Career_Outcomes (WLSMV, ordinal)
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))

if (!require("lavaan", quietly = TRUE)) {
  install.packages("lavaan", quiet = TRUE)
  library(lavaan, quietly = TRUE)
}

cat("Loading data for SEM analysis...\n")
df_raw <- read.csv("vector_survey_responses.csv", check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
target_cols <- 8:18
colnames(df_raw)[target_cols] <- paste0("q", 1:11)
df_raw[target_cols] <- lapply(df_raw[target_cols], function(x) as.numeric(as.character(x)))
df_clean <- df_raw[complete.cases(df_raw[target_cols]), ]
cat(sprintf("N = %d complete responses\n\n", nrow(df_clean)))

# ==============================================================================
# MODEL SPECIFICATION
# q1-q4:  Skill_Development (Human Capital)
# q5-q7:  Networking (Social Capital)
# q9-q11: Career_Outcomes (q8 = overall impact, excluded from outcome construct
#          as it is too broad; q9-q11 capture specific career outcomes)
# ==============================================================================

sem_model <- '
  # Measurement model
  Skill_Development =~ q1 + q2 + q3 + q4
  Networking        =~ q5 + q6 + q7
  Career_Outcomes   =~ q9 + q10 + q11

  # Structural model
  Career_Outcomes   ~  Skill_Development + Networking
'

cat("=== STRUCTURAL EQUATION MODEL (WLSMV, Ordinal) ===\n\n")
fit <- sem(sem_model, data = df_clean,
           ordered = c("q1","q2","q3","q4","q5","q6","q7","q9","q10","q11"))

cat("--- Full Model Summary ---\n")
summary(fit, standardized = TRUE, fit.measures = TRUE, rsquare = TRUE)

# ==============================================================================
# FIT INDICES
# ==============================================================================
cat("\n=== MODEL FIT INDICES ===\n")
idx <- fitMeasures(fit, c("cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr"))
cat(sprintf("  CFI   = %.3f  (threshold: > 0.95)\n", idx["cfi"]))
cat(sprintf("  TLI   = %.3f  (threshold: > 0.95)\n", idx["tli"]))
cat(sprintf("  RMSEA = %.3f  [90%% CI: %.3f - %.3f]  (threshold: < 0.06)\n",
            idx["rmsea"], idx["rmsea.ci.lower"], idx["rmsea.ci.upper"]))
cat(sprintf("  SRMR  = %.3f  (threshold: < 0.08)\n\n", idx["srmr"]))

if (idx["cfi"] >= 0.95 && idx["rmsea"] <= 0.06) {
  cat("VERDICT: Model fit meets academic thresholds (CFI >= 0.95, RMSEA <= 0.06)\n\n")
} else {
  cat("WARNING: Model fit does not meet one or more thresholds.\n")
  cat(sprintf("  CFI threshold (>= 0.95): %s\n",  ifelse(idx["cfi"] >= 0.95, "PASS", "FAIL")))
  cat(sprintf("  RMSEA threshold (<= 0.06): %s\n\n", ifelse(idx["rmsea"] <= 0.06, "PASS", "FAIL")))
}

# ==============================================================================
# COMPOSITE CORRELATION (HC vs SC)
# ==============================================================================
cat("=== COMPOSITE CORRELATION: Human Capital vs Social Capital ===\n")
df_clean$HC <- rowMeans(df_clean[, c("q1","q2","q3","q4")], na.rm = TRUE)
df_clean$SC <- rowMeans(df_clean[, c("q5","q6","q7")],      na.rm = TRUE)
r_comp <- cor(df_clean$HC, df_clean$SC)
cat(sprintf("  r = %.3f between Human Capital and Social Capital composites\n\n", r_comp))

# ==============================================================================
# EXPORT
# ==============================================================================
dir.create("output", showWarnings = FALSE)
fit_df <- data.frame(
  Index = c("CFI", "TLI", "RMSEA", "RMSEA_CI_lower", "RMSEA_CI_upper", "SRMR",
            "HC_SC_composite_r", "N"),
  Value = c(round(idx["cfi"], 3), round(idx["tli"], 3),
            round(idx["rmsea"], 3), round(idx["rmsea.ci.lower"], 3),
            round(idx["rmsea.ci.upper"], 3), round(idx["srmr"], 3),
            round(r_comp, 3), nrow(df_clean))
)
write.csv(fit_df, "output/sem_fit_indices.csv", row.names = FALSE)
cat("SEM fit indices saved: output/sem_fit_indices.csv\n")
cat("SEM analysis complete!\n")
