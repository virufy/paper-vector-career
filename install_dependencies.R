################################################################################
# Project VECTOR: Dependency Installer
# Usage: Rscript --vanilla install_dependencies.R
################################################################################

options(repos = c(CRAN = "https://cloud.r-project.org"))

required_packages <- c(
  "boot",
  "car",
  "corrplot",
  "dplyr",
  "ggplot2",
  "lavaan",
  "lmtest",
  "ppcor",
  "psych",
  "relaimpo"
)

cat("\nInstalling Project VECTOR dependencies...\n\n")

ok <- character(0)
failed <- character(0)

for (pkg in required_packages) {
  cat(sprintf("- %s: ", pkg))
  tryCatch({
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
    }
    library(pkg, character.only = TRUE, quietly = TRUE)
    ok <- c(ok, pkg)
    cat("OK\n")
  }, error = function(e) {
    failed <<- c(failed, pkg)
    cat(sprintf("FAILED (%s)\n", conditionMessage(e)))
  })
}

cat("\nSummary\n")
cat(sprintf("  Installed: %d/%d\n", length(ok), length(required_packages)))

if (length(failed) == 0) {
  cat("  Status: READY\n")
  cat("\nRun next:\n")
  cat("  Rscript --vanilla run_all_analyses.R\n")
} else {
  cat("  Status: INCOMPLETE\n")
  cat("  Failed packages:\n")
  for (pkg in failed) cat(sprintf("    - %s\n", pkg))
  cat("\nIf needed on Linux:\n")
  cat("  sudo apt install build-essential r-base-dev libcurl4-openssl-dev libxml2-dev libssl-dev\n")
}
cat("\n")
