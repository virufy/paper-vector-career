################################################################################
# PROJECT VECTOR: MASTER ANALYSIS SCRIPT
# Usage: Rscript --vanilla run_all_analyses.R
#
# Steps:
#   1. Comprehensive exploratory analysis (descriptives, LMG, correlations)
#   2. Demographic subgroup analysis (role type, career stage)
#   3. Structural Equation Modeling (SEM) — construct validity + model fit
#   4. Paper claim verification — checks code output against paper figures
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("\n")
cat("================================================================================\n")
cat("               PROJECT VECTOR: COMPREHENSIVE ANALYSIS PIPELINE                 \n")
cat("================================================================================\n\n")

csv_file <- "vector_survey_responses.csv"
if (!file.exists(csv_file)) {
  cat(sprintf("ERROR: Data file not found: %s\nCurrent directory: %s\n", csv_file, getwd()))
  stop("Data file not found")
}
cat(sprintf("Data file found: %s\n\n", csv_file))

# ==============================================================================
# STEP 1: COMPREHENSIVE EXPLORATORY ANALYSIS
# Outputs: correlation_heatmap.png, relative_importance_barplot.png, CSVs
# ==============================================================================

cat("STEP 1: Running comprehensive exploratory analysis...\n")
cat("----------------------------------------------------------------------\n\n")
tryCatch({
  source("vector_comprehensive_analysis.R")
  cat("\nStep 1 completed successfully\n\n")
}, error = function(e) cat(sprintf("\nError in Step 1: %s\n\n", e$message)))

# ==============================================================================
# STEP 2: DEMOGRAPHIC SUBGROUP ANALYSIS
# Outputs: subgroup_top_predictors_comparison.png, subgroup_analysis_results.csv
# Note: Career Stage uses column 4 (career question), not column 3 (consent text)
# ==============================================================================

cat("\nSTEP 2: Running demographic subgroup analysis...\n")
cat("----------------------------------------------------------------------\n\n")
tryCatch({
  source("vector_subgroup_analysis.R")
  cat("\nStep 2 completed successfully\n\n")
}, error = function(e) {
  cat(sprintf("\nError in Step 2: %s\n\n", e$message))
  cat("Note: Subgroup analysis may fail if sample sizes are too small\n\n")
})

# ==============================================================================
# STEP 3: STRUCTURAL EQUATION MODELING (SEM)
# Output: output/sem_fit_indices.csv
# Model: Skill_Development(q1-q4) + Networking(q5-q7) -> Career_Outcomes(q9-q11)
# Estimator: WLSMV (appropriate for ordinal Likert data)
# ==============================================================================

cat("\nSTEP 3: Running Structural Equation Model (SEM)...\n")
cat("----------------------------------------------------------------------\n\n")
tryCatch({
  source("vector_sem_analysis.R")
  cat("\nStep 3 completed successfully\n\n")
}, error = function(e) cat(sprintf("\nError in Step 3: %s\n\n", e$message)))

# ==============================================================================
# STEP 4: PAPER CLAIM VERIFICATION
# Checks key quantitative claims from the paper against code output.
# Flags mismatches so they can be corrected before submission.
# ==============================================================================

cat("\nSTEP 4: Verifying paper claims against code output...\n")
cat("----------------------------------------------------------------------\n\n")

tryCatch({

  pkgs <- c("lavaan", "relaimpo", "dplyr", "janitor", "stringr")
  for (p in pkgs) if (!require(p, character.only = TRUE, quietly = TRUE)) {
    install.packages(p, quiet = TRUE); library(p, character.only = TRUE, quietly = TRUE)
  }

  chk <- function(got, expected, tol = 0.02) ifelse(abs(got - expected) <= tol, "MATCH", "MISMATCH")

  # -- Data load --
  df_v <- read.csv("vector_survey_responses.csv", check.names = FALSE)
  colnames(df_v) <- make.unique(colnames(df_v))
  tc <- 8:18
  colnames(df_v)[tc] <- paste0("q", 1:11)
  df_v[tc] <- lapply(df_v[tc], function(x) as.numeric(as.character(x)))
  df_v <- df_v[complete.cases(df_v[tc]), ]

  # -- Full-sample LMG (Table 2) --
  psc <- as.data.frame(scale(df_v[, paste0("q", 1:7)]))
  osc <- scale(df_v$q10)
  fm  <- lm(osc ~ ., data = psc)
  ri  <- calc.relimp(fm, type = "lmg", rela = TRUE)
  lmg <- round(ri$lmg * 100, 1)
  r2  <- round(summary(fm)$r.squared, 3)

  paper_t2 <- c(q1=14.4, q2=16.1, q3=17.2, q4=13.4, q5=11.0, q6=15.7, q7=12.2)

  # -- Role subgroups --
  tech_kw <- "App Dev|Web Dev|ML Engineering|Data Scientist|Cloud|IT|Engineer|Developer"
  df_v$Role <- ifelse(grepl(tech_kw, df_v[[6]], ignore.case = TRUE), "Tech", "Non-Tech")

  run_lmg <- function(data) {
    p <- as.data.frame(scale(data[, paste0("q", 1:7)]))
    o <- scale(data$q10)
    cc <- complete.cases(p, o); p <- p[cc,]; o <- o[cc]
    if (length(o) < 15) return(NULL)
    m  <- lm(o ~ ., data = p)
    ri <- calc.relimp(m, type = "lmg", rela = TRUE)
    sort(ri$lmg * 100, decreasing = TRUE)
  }

  tech_res    <- run_lmg(df_v[df_v$Role == "Tech",    ])
  nontech_res <- run_lmg(df_v[df_v$Role == "Non-Tech",])

  # -- Career stage subgroups --
  df_v$Stage <- ifelse(
    grepl("student|undergraduate|master|doctoral|phd|high school", df_v[[4]], ignore.case = TRUE),
    "Student", "Professional"
  )
  student_res <- run_lmg(df_v[df_v$Stage == "Student",     ])
  prof_res    <- run_lmg(df_v[df_v$Stage == "Professional",])

  # -- SEM --
  sem_model <- '
    Skill_Development =~ q1 + q2 + q3 + q4
    Networking        =~ q5 + q6 + q7
    Career_Outcomes   =~ q9 + q10 + q11
    Career_Outcomes   ~  Skill_Development + Networking
  '
  fit <- sem(sem_model, data = df_v,
             ordered = c("q1","q2","q3","q4","q5","q6","q7","q9","q10","q11"))
  idx <- fitMeasures(fit, c("cfi", "rmsea"))

  # -- Composite correlation --
  df_v$HC <- rowMeans(df_v[, c("q1","q2","q3","q4")], na.rm = TRUE)
  df_v$SC <- rowMeans(df_v[, c("q5","q6","q7")],      na.rm = TRUE)
  r_comp <- cor(df_v$HC, df_v$SC)

  # -- Print summary table --
  cat("  Claim                              | Paper   | Code    | Status\n")
  cat("  -----------------------------------|---------|---------|----------\n")
  cat(sprintf("  SEM CFI                            | 0.975   | %.3f   | %s\n", idx["cfi"],   chk(idx["cfi"],   0.975, 0.005)))
  cat(sprintf("  SEM RMSEA                          | 0.039   | %.3f   | %s\n", idx["rmsea"], chk(idx["rmsea"], 0.039, 0.005)))
  cat(sprintf("  Composite r (HC vs SC)             | 0.940   | %.3f   | %s\n", r_comp,       chk(r_comp, 0.94, 0.02)))
  cat(sprintf("  Full-sample R2                     | 0.575   | %.3f   | %s\n", r2,           chk(r2, 0.575, 0.001)))
  for (v in paste0("q", 1:7)) {
    cat(sprintf("  Table 2 %-5s                      | %5.1f%%  | %5.1f%%  | %s\n",
                v, paper_t2[v], lmg[v], chk(lmg[v], paper_t2[v], 0.2)))
  }
  if (!is.null(tech_res)) {
    cat(sprintf("  Tech subgroup q3 (Leadership)      | 18.4%%   | %.1f%%   | %s\n",
                tech_res["q3"], chk(tech_res["q3"], 18.4, 0.2)))
    cat(sprintf("  Tech subgroup q6 (Net Quality)     | 16.9%%   | %.1f%%   | %s\n",
                tech_res["q6"], chk(tech_res["q6"], 16.9, 0.2)))
  }
  if (!is.null(nontech_res)) {
    cat(sprintf("  Non-Tech subgroup q1 (Technical)   | 25.2%%   | %.1f%%   | %s\n",
                nontech_res["q1"], chk(nontech_res["q1"], 25.2, 0.2)))
  }
  if (!is.null(student_res)) {
    cat(sprintf("  Student subgroup q3 (Leadership)   | 23.3%%   | %.1f%%   | %s\n",
                student_res["q3"], chk(student_res["q3"], 23.3, 0.2)))
  }
  if (!is.null(prof_res)) {
    cat(sprintf("  Prof subgroup q4 (Time Mgmt)       | 17.8%%   | %.1f%%   | %s\n",
                prof_res["q4"], chk(prof_res["q4"], 17.8, 0.2)))
  }
  cat("\n  Note: SEM/composite r mismatches are expected when running on the\n")
  cat("  anonymized local dataset. Full results require the private dataset.\n")

  cat("\nStep 4 completed successfully\n\n")

}, error = function(e) cat(sprintf("\nError in Step 4: %s\n\n", e$message)))

# ==============================================================================
# SUMMARY
# ==============================================================================

cat("\n")
cat("================================================================================\n")
cat("                            ANALYSIS COMPLETE                                   \n")
cat("================================================================================\n\n")
cat("Generated files (in output/ folder):\n")
cat("  output/correlation_heatmap.png\n")
cat("  output/relative_importance_barplot.png\n")
cat("  output/subgroup_top_predictors_comparison.png\n")
cat("  output/correlation_matrix.csv\n")
cat("  output/relative_importance_results.csv\n")
cat("  output/variable_labels.csv\n")
cat("  output/subgroup_analysis_results.csv\n")
cat("  output/sem_fit_indices.csv\n\n")
cat("================================================================================\n\n")
