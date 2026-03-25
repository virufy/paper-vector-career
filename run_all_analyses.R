################################################################################
# Project VECTOR: Reproducible Analysis Pipeline
# Usage: Rscript --vanilla run_all_analyses.R
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_pkgs <- c(
  "boot", "car", "corrplot", "dplyr", "ggplot2", "lavaan", "lmtest",
  "ppcor", "psych", "relaimpo"
)

for (pkg in required_pkgs) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    stop(sprintf("Missing package '%s'. Run install_dependencies.R first.", pkg))
  }
}

set.seed(42)
dir.create("output", showWarnings = FALSE)

log_section <- function(title) {
  cat("\n")
  cat(strrep("=", 80), "\n", sep = "")
  cat(title, "\n")
  cat(strrep("=", 80), "\n", sep = "")
}

log_section("STEP 1: DATA LOADING AND AUDIT")

csv_file <- "vector_survey_responses.csv"
if (!file.exists(csv_file)) {
  stop(sprintf("Data file not found: %s", csv_file))
}

df_raw <- read.csv(csv_file, check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))

if (ncol(df_raw) < 18) {
  stop("Unexpected data structure: expected at least 18 columns")
}

likert_cols <- 8:18
question_names <- paste0("q", 1:11)
colnames(df_raw)[likert_cols] <- question_names

# Preserve non-Likert fields while forcing Likert fields to numeric for analysis.
df_raw[likert_cols] <- lapply(df_raw[likert_cols], function(x) as.numeric(as.character(x)))

audit <- data.frame(
  metric = c(
    "rows_in_input_csv",
    "rows_with_complete_core_likert_items",
    "rows_excluded_due_to_core_missingness"
  ),
  value = c(
    nrow(df_raw),
    sum(complete.cases(df_raw[question_names])),
    nrow(df_raw) - sum(complete.cases(df_raw[question_names]))
  )
)

write.csv(audit, "output/data_audit_summary.csv", row.names = FALSE)

missing_per_item <- data.frame(
  variable = question_names,
  missing_n = colSums(is.na(df_raw[question_names])),
  missing_pct = round(100 * colSums(is.na(df_raw[question_names])) / nrow(df_raw), 2)
)
write.csv(missing_per_item, "output/core_item_missingness.csv", row.names = FALSE)

df <- df_raw[complete.cases(df_raw[question_names]), ]

participant_flow <- data.frame(
  stage = c("input_rows", "complete_core_likert", "excluded_core_missing"),
  n = c(nrow(df_raw), nrow(df), nrow(df_raw) - nrow(df))
)
write.csv(participant_flow, "output/participant_flow.csv", row.names = FALSE)

cat(sprintf("Input rows: %d\n", nrow(df_raw)))
cat(sprintf("Complete rows used in primary analysis: %d\n", nrow(df)))
cat(sprintf("Excluded due to core missingness: %d\n", nrow(df_raw) - nrow(df)))

var_labels <- data.frame(
  variable = question_names,
  category = c(rep("Skills", 4), rep("Network", 3), rep("Outcomes", 4)),
  description = c(
    "Technical Skills (Programming, Data Analysis)",
    "Communication Skills (Writing, Presentation)",
    "Leadership Skills (Guiding teams)",
    "Time Management (Organization, Deadlines)",
    "Network Size (Quantity of connections)",
    "Network Quality (Insights/Advice)",
    "Network Access (Professional circles)",
    "Overall Career Impact",
    "Resume Competitiveness",
    "Job/Promotion Success (Primary Outcome)",
    "Leadership Role Advancement"
  )
)
write.csv(var_labels, "output/variable_labels.csv", row.names = FALSE)

log_section("STEP 2: DESCRIPTIVE STATISTICS AND CORRELATIONS")

desc <- psych::describe(df[question_names])
desc_export <- cbind(variable = rownames(desc), desc[, c("n", "mean", "sd", "median", "min", "max")])
rownames(desc_export) <- NULL
write.csv(desc_export, "output/descriptive_statistics.csv", row.names = FALSE)

cor_matrix <- cor(df[question_names], method = "spearman")
write.csv(cor_matrix, "output/correlation_matrix.csv")

png("output/correlation_heatmap.png", width = 1200, height = 1000, res = 120)
corrplot::corrplot(
  cor_matrix,
  method = "color",
  type = "full",
  order = "hclust",
  addCoef.col = "black",
  number.cex = 0.7,
  tl.col = "black",
  tl.srt = 45,
  col = colorRampPalette(c("#6D9EC1", "white", "#E46726"))(200),
  title = "Project VECTOR: Spearman Correlation Matrix",
  mar = c(0, 0, 2, 0)
)
dev.off()

log_section("STEP 3: FULL SAMPLE LMG ANALYSIS")

predictor_names <- paste0("q", 1:7)
outcome_name <- "q10"

x_scaled <- as.data.frame(scale(df[predictor_names]))
y_scaled <- as.numeric(scale(df[[outcome_name]]))
model_data <- x_scaled
model_data$y <- y_scaled

full_model <- lm(y ~ ., data = model_data)
model_summary <- summary(full_model)

vif_values <- car::vif(full_model)
resid_sw <- shapiro.test(residuals(full_model))
resid_bp <- lmtest::bptest(full_model)

rel <- relaimpo::calc.relimp(full_model, type = "lmg", rela = TRUE)

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
importance$description <- var_labels$description[match(importance$variable, var_labels$variable)]
importance <- importance[order(-importance$lmg_pct), ]
write.csv(importance, "output/relative_importance_results.csv", row.names = FALSE)

diagnostics <- data.frame(
  metric = c("n", "r_squared", "adj_r_squared", "f_statistic", "f_p_value", "max_vif", "shapiro_p", "breusch_pagan_p"),
  value = c(
    nrow(df),
    model_summary$r.squared,
    model_summary$adj.r.squared,
    unname(model_summary$fstatistic[1]),
    pf(model_summary$fstatistic[1], model_summary$fstatistic[2], model_summary$fstatistic[3], lower.tail = FALSE),
    max(vif_values),
    resid_sw$p.value,
    resid_bp$p.value
  )
)
write.csv(diagnostics, "output/full_model_diagnostics.csv", row.names = FALSE)

png("output/relative_importance_barplot.png", width = 1400, height = 800, res = 120)
par(mar = c(8, 5, 4, 2))
barplot(
  importance$lmg_pct,
  names.arg = paste0(importance$variable, "\n", substr(importance$description, 1, 24)),
  las = 2,
  col = colorRampPalette(c("#E46726", "#F4A261", "#6D9EC1"))(nrow(importance)),
  main = "Relative Importance of Predictors for Job/Promotion Success",
  ylab = "Contribution to R-squared (%)",
  ylim = c(0, max(importance$lmg_pct) * 1.2)
)
text(
  x = seq_len(nrow(importance)) * 1.2 - 0.5,
  y = importance$lmg_pct + 0.5,
  labels = sprintf("%.1f%%", importance$lmg_pct),
  cex = 0.9,
  font = 2
)
dev.off()

log_section("STEP 4: DEMOGRAPHIC SUBGROUP ANALYSIS")

tech_kw <- "App Dev|Web Dev|ML Engineering|Data Scientist|Cloud|IT|Engineer|Developer"
west_kw <- "United States|USA|Canada|UK|United Kingdom|Japan|Australia|Singapore"

df$role_type <- ifelse(grepl(tech_kw, df[[6]], ignore.case = TRUE), "Tech", "Non-Tech")
df$career_stage <- ifelse(
  grepl("student|undergraduate|master|doctoral|phd|high school", df[[4]], ignore.case = TRUE),
  "Student",
  "Professional"
)
df$geography <- ifelse(grepl(west_kw, df[[5]], ignore.case = TRUE), "Global_West", "Global_South")

subgroup_counts <- data.frame(
  group = c("Role: Tech", "Role: Non-Tech", "Stage: Student", "Stage: Professional", "Geo: Global_West", "Geo: Global_South"),
  n = c(
    sum(df$role_type == "Tech"),
    sum(df$role_type == "Non-Tech"),
    sum(df$career_stage == "Student"),
    sum(df$career_stage == "Professional"),
    sum(df$geography == "Global_West"),
    sum(df$geography == "Global_South")
  )
)
write.csv(subgroup_counts, "output/subgroup_counts.csv", row.names = FALSE)

run_subgroup_lmg <- function(dat, group_name, min_n = 15) {
  if (nrow(dat) < min_n) {
    return(NULL)
  }

  subgroup_x <- as.data.frame(scale(dat[predictor_names]))
  subgroup_y <- as.numeric(scale(dat[[outcome_name]]))
  subgroup_data <- subgroup_x
  subgroup_data$y <- subgroup_y

  m <- lm(y ~ ., data = subgroup_data)
  ri <- relaimpo::calc.relimp(m, type = "lmg", rela = TRUE)

  out <- data.frame(
    variable = names(ri$lmg),
    contribution_pct = as.numeric(ri$lmg) * 100,
    group = group_name,
    n = nrow(dat),
    r_squared = summary(m)$r.squared
  )

  out[order(-out$contribution_pct), ]
}

subgroup_results <- list()
for (role in sort(unique(df$role_type))) {
  subgroup_results[[paste("Role", role)]] <- run_subgroup_lmg(df[df$role_type == role, ], paste("Role:", role))
}
for (stage in sort(unique(df$career_stage))) {
  subgroup_results[[paste("Stage", stage)]] <- run_subgroup_lmg(df[df$career_stage == stage, ], paste("Stage:", stage))
}
for (geo in sort(unique(df$geography))) {
  subgroup_results[[paste("Geo", geo)]] <- run_subgroup_lmg(df[df$geography == geo, ], paste("Geo:", geo))
}

subgroup_results <- subgroup_results[!vapply(subgroup_results, is.null, logical(1))]

if (length(subgroup_results) > 0) {
  subgroup_df <- do.call(rbind, subgroup_results)
  rownames(subgroup_df) <- NULL
  write.csv(subgroup_df, "output/subgroup_analysis_results.csv", row.names = FALSE)

  plot_df <- subgroup_df[subgroup_df$variable %in% c("q1", "q2", "q3", "q4"), ]
  png("output/subgroup_top_predictors_comparison.png", width = 1400, height = 800, res = 120)
  print(
    ggplot(plot_df, aes(x = group, y = contribution_pct, fill = variable)) +
      geom_col(position = "dodge") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      labs(
        title = "Predictor Contribution to Job Success by Subgroup",
        x = "Subgroup",
        y = "Contribution to R-squared (%)"
      )
  )
  dev.off()
}

log_section("STEP 5: SEM")

sem_model <- '
  Skill_Development =~ q1 + q2 + q3 + q4
  Networking        =~ q5 + q6 + q7
  Career_Outcomes   =~ q9 + q10 + q11
  Career_Outcomes   ~ Skill_Development + Networking
'

fit <- lavaan::sem(
  sem_model,
  data = df,
  ordered = c("q1", "q2", "q3", "q4", "q5", "q6", "q7", "q9", "q10", "q11")
)

fit_idx <- lavaan::fitMeasures(
  fit,
  c("cfi", "tli", "rmsea", "rmsea.ci.lower", "rmsea.ci.upper", "srmr")
)

df$hc_composite <- rowMeans(df[, c("q1", "q2", "q3", "q4")], na.rm = TRUE)
df$sc_composite <- rowMeans(df[, c("q5", "q6", "q7")], na.rm = TRUE)
comp_r <- cor(df$hc_composite, df$sc_composite)

sem_export <- data.frame(
  index = c("CFI", "TLI", "RMSEA", "RMSEA_CI_LOWER", "RMSEA_CI_UPPER", "SRMR", "HC_SC_COMPOSITE_R", "N"),
  value = c(
    round(fit_idx["cfi"], 3),
    round(fit_idx["tli"], 3),
    round(fit_idx["rmsea"], 3),
    round(fit_idx["rmsea.ci.lower"], 3),
    round(fit_idx["rmsea.ci.upper"], 3),
    round(fit_idx["srmr"], 3),
    round(comp_r, 3),
    nrow(df)
  )
)
write.csv(sem_export, "output/sem_fit_indices.csv", row.names = FALSE)

log_section("STEP 6: PAPER CLAIM CHECK")

claim_rows <- list()

add_claim <- function(claim, paper_value, code_value, tolerance) {
  status <- ifelse(abs(code_value - paper_value) <= tolerance, "MATCH", "MISMATCH")
  data.frame(
    claim = claim,
    paper_value = paper_value,
    code_value = round(code_value, 3),
    tolerance = tolerance,
    status = status
  )
}

paper_table2 <- c(q1 = 14.4, q2 = 16.1, q3 = 17.2, q4 = 13.4, q5 = 11.0, q6 = 15.7, q7 = 12.2)
code_table2 <- setNames(importance$lmg_pct, importance$variable)

claim_rows[[length(claim_rows) + 1]] <- add_claim("SEM_CFI", 0.975, fit_idx["cfi"], 0.005)
claim_rows[[length(claim_rows) + 1]] <- add_claim("SEM_RMSEA", 0.039, fit_idx["rmsea"], 0.005)
claim_rows[[length(claim_rows) + 1]] <- add_claim("HC_SC_COMPOSITE_R", 0.940, comp_r, 0.020)
claim_rows[[length(claim_rows) + 1]] <- add_claim("FULL_SAMPLE_R2", 0.575, model_summary$r.squared, 0.001)

for (v in names(paper_table2)) {
  claim_rows[[length(claim_rows) + 1]] <- add_claim(
    paste0("TABLE2_", v),
    paper_table2[[v]],
    code_table2[[v]],
    0.2
  )
}

if (exists("subgroup_df")) {
  subgroup_lookup <- function(group_name, var_name) {
    subset_row <- subgroup_df[subgroup_df$group == group_name & subgroup_df$variable == var_name, ]
    if (nrow(subset_row) == 0) {
      return(NA_real_)
    }
    subset_row$contribution_pct[1]
  }

  claim_rows[[length(claim_rows) + 1]] <- add_claim("TECH_Q3", 18.4, subgroup_lookup("Role: Tech", "q3"), 0.2)
  claim_rows[[length(claim_rows) + 1]] <- add_claim("TECH_Q6", 16.9, subgroup_lookup("Role: Tech", "q6"), 0.2)
  claim_rows[[length(claim_rows) + 1]] <- add_claim("NONTECH_Q1", 25.2, subgroup_lookup("Role: Non-Tech", "q1"), 0.2)
  claim_rows[[length(claim_rows) + 1]] <- add_claim("STUDENT_Q3", 23.3, subgroup_lookup("Stage: Student", "q3"), 0.2)
  claim_rows[[length(claim_rows) + 1]] <- add_claim("PROF_Q4", 17.8, subgroup_lookup("Stage: Professional", "q4"), 0.2)
}

claim_check <- do.call(rbind, claim_rows)
write.csv(claim_check, "output/paper_claim_check.csv", row.names = FALSE)

capture.output(sessionInfo(), file = "output/session_info.txt")

cat("\nAnalysis complete. Key outputs written to output/ directory.\n")
