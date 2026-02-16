################################################################################
# PROJECT VECTOR: DEPENDENCY INSTALLER
# Purpose: Install all required packages with proper dependency handling
# Run this ONCE before running analyses
################################################################################

# Set CRAN mirror for non-interactive installs
options(repos = c(CRAN = "https://cloud.r-project.org"))

cat("\n")
cat("================================================================================\n")
cat("                   Installing Project VECTOR Dependencies                      \n")
cat("================================================================================\n\n")

# List of all required packages (order matters for dependencies)
core_packages <- c(
  "lattice",      # Base dependency for many packages
  "Matrix",       # Base dependency
  "Rcpp",         # Compiler dependency
  "RcppEigen",    # Math library
  "minqa",        # Optimization
  "nloptr",       # Optimization
  "lme4",         # Linear mixed effects (CRITICAL: install early)
  "pbkrtest",     # Testing (depends on lme4)
  "car",          # Companion to applied regression (depends on pbkrtest)
  "effects",      # Effect displays (depends on car)
  "alr4",         # Applied linear regression (depends on car + effects)
  "lavaan",       # Structural equation modeling
  "dplyr",        # Data wrangling
  "ggplot2",      # Visualization
  "corrplot",     # Correlation heatmaps
  "relaimpo",     # Relative importance analysis (CRITICAL for analysis)
  "tidyr",        # Tidy data
  "psych",        # Psychological statistics
  "reshape2",     # Data reshaping
  "gridExtra",    # Grid graphics
  "ppcor"         # Partial and semi-partial correlations
)

installed_count <- 0
failed_packages <- character(0)

cat("Installing packages in dependency order...\n")
cat("This may take several minutes.\n\n")

for (pkg in core_packages) {
  cat(sprintf("Installing %s... ", pkg))
  
  tryCatch({
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
      library(pkg, character.only = TRUE, quietly = TRUE)
    }
    cat("✓\n")
    installed_count <- installed_count + 1
  }, error = function(e) {
    cat(sprintf("✗ (Error: %s)\n", substr(e$message, 1, 50)))
    failed_packages <<- c(failed_packages, pkg)
  })
}

cat("\n")
cat("================================================================================\n")
cat(sprintf("                    Installation Summary: %d/%d successful\n", 
            installed_count, length(core_packages)))
cat("================================================================================\n\n")

if (length(failed_packages) == 0) {
  cat("✓ All dependencies installed successfully!\n\n")
  cat("Next steps:\n")
  cat("  1. Run: Rscript --vanilla run_all_analyses.R\n")
  cat("  OR\n")
  cat("  2. Run diagnostics first: Rscript --vanilla data_diagnostics.R\n\n")
} else {
  cat(sprintf("✗ Failed to install %d package(s):\n", length(failed_packages)))
  for (pkg in failed_packages) {
    cat(sprintf("  - %s\n", pkg))
  }
  cat("\nTroubleshooting:\n")
  cat("  1. Check internet connection\n")
  cat("  2. Try installing individually: install.packages('package_name')\n")
  cat("  3. Check system dependencies (e.g., build tools for Linux)\n\n")
}

cat("================================================================================\n\n")
