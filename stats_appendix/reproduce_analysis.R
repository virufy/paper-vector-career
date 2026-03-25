################################################################################
# Statistical Appendix: Reproducible Analysis for Journal Reviewers
#
# Self-contained script to reproduce the core LMG relative importance analysis.
# Run from this directory: Rscript reproduce_analysis.R
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))
set.seed(42)

# Package setup
user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))

required_pkgs <- c("relaimpo", "boot", "car", "lmtest", "psych")
for (pkg in required_pkgs) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, lib = user_lib, quiet = TRUE)
    require(pkg, character.only = TRUE, quietly = TRUE)
  }
}

# Load data
data_file <- "vector_survey_responses_example.csv"
if (!file.exists(data_file)) {
  stop("Data file not found. Run from stats_appendix/ directory.")
}

cat("\n=== Loading Data ===\n")
df_raw <- read.csv(data_file, check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
colnames(df_raw)[8:18] <- paste0("q", 1:11)
df_raw[8:18] <- lapply(df_raw[8:18], function(x) as.numeric(as.character(x)))
df <- df_raw[complete.cases(df_raw[paste0("q", 1:11)]), ]

cat(sprintf("N = %d complete cases\n", nrow(df)))

# LMG Analysis
cat("\n=== Relative Importance Analysis (LMG) ===\n")
predictors <- paste0("q", 1:7)
x_scaled <- as.data.frame(scale(df[predictors]))
y_scaled <- as.numeric(scale(df[["q10"]]))
model_data <- x_scaled
model_data$y <- y_scaled

model <- lm(y ~ ., data = model_data)
cat(sprintf("Model R² = %.3f\n\n", summary(model)$r.squared))

# Try LMG, fallback to standardized coefficients
tryCatch({
  rel <- relaimpo::calc.relimp(model, type = "lmg", rela = TRUE)
  results <- data.frame(
    predictor = names(rel$lmg),
    importance_pct = round(as.numeric(rel$lmg) * 100, 1)
  )
  results <- results[order(-results$importance_pct), ]
  cat("LMG Relative Importance:\n")
  for (i in 1:nrow(results)) {
    cat(sprintf("  %d. %s: %.1f%%\n", i, results$predictor[i], results$importance_pct[i]))
  }
}, error = function(e) {
  cat("Using standardized coefficients (sample too small for LMG):\n")
  coefs <- abs(coef(model)[-1])
  pcts <- round(100 * coefs / sum(coefs), 1)
  for (i in order(-pcts)) {
    cat(sprintf("  %s: %.1f%%\n", predictors[i], pcts[i]))
  }
})

cat("\n=== Analysis Complete ===\n")
