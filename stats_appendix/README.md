# Statistical Appendix

This folder contains the minimal reproducible example for the analysis presented in "From Volunteer to Vocation."

## Contents

- **`vector_survey_responses_example.csv`** — Example dataset (10 respondents) with the same structure as the full survey data
- **`reproduce_analysis.R`** — Self-contained R script to reproduce core analysis outputs

## Quick Start

### Prerequisites

R 4.0+ with the following packages:
```
boot, car, corrplot, dplyr, ggplot2, lavaan, lmtest, ppcor, psych, relaimpo
```

To install missing packages:
```R
install.packages(c("boot", "car", "corrplot", "dplyr", "ggplot2", "lavaan", "lmtest", "ppcor", "psych", "relaimpo"))
```

### Run the Analysis

From the command line:
```bash
Rscript reproduce_analysis.R
```

Or from R:
```R
source("reproduce_analysis.R")
```

The script will:
1. Load the example dataset
2. Perform complete-case analysis (n = 10)
3. Compute relative importance decomposition (LMG) with 95% bootstrap confidence intervals
4. Generate correlation matrix and descriptive statistics
5. Report model fit and key findings

## Expected Output

```
Input rows: 10
Complete-case rows: 10
Excluded: 0

Top predictor of Job/Promotion Success: q3 (23.45% relative importance)
```

## Data Structure

The CSV file contains 18 columns:
- **Cols 1–7:** Metadata (Timestamp, Email, Career Stage, Academic Background, Country, Current Role, Years Experience)
- **Cols 8–18:** Likert scale items (Q1–Q11, scale 1–5)
  - **Q1–Q4:** Skills (Technical, Communication, Leadership, Time Management)
  - **Q5–Q7:** Network (Size, Quality, Access)
  - **Q8–Q11:** Outcomes (Overall Impact, Resume Competitiveness, Job/Promotion Success [primary], Leadership Advancement)

## For Full Analysis

For the complete analysis on the full dataset (n = 78) with subgroup stratification and structural equation modeling, see the parent directory and run:
```bash
Rscript run_all_analyses.R
```

## References

- Lindeman, R. H., Merenda, P. F., & Gold, R. Z. (1980). Introduction to bivariate and multivariate analysis. Glenview, IL: Scott, Foresman.
- Grömping, U. (2006). Relative importance for linear regression in R: The package relaimpo. Journal of Statistical Software, 17(1), 1–27.
