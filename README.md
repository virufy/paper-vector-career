# Project VECTOR: Remote Work Paradox Analysis

A comprehensive R analysis pipeline to validate the "Remote Work Paradox" hypothesis and identify true drivers of career success in remote work environments.

## Quick Start

### Prerequisites
- **R 4.0+** installed on your system
- **Internet connection** (for downloading R packages)

### Reproduce Analysis in 3 Steps

#### Step 1: Install Dependencies (One Time Only)
```bash
Rscript --vanilla install_dependencies.R
```

This installs all required packages in the correct dependency order. Takes ~5-10 minutes on first run.

#### Step 2: Check Data Quality (Optional but Recommended)
```bash
Rscript --vanilla data_diagnostics.R
```

Validates your data and generates a diagnostic report in `output/data_diagnostic_report.txt`.

#### Step 3: Run Full Analysis
```bash
Rscript --vanilla run_all_analyses.R
```

This runs the complete analysis pipeline and generates all outputs to the `output/` folder.

---

## Project Overview

### Research Question
Does **Time Management** truly outperform **Technical Skills** in predicting career success in remote work environments? Or is this the "Remote Work Paradox"?

### Methodology

The analysis uses **relative importance analysis** (LMG metric) to decompose the variance explained in job success outcomes, comparing:

- **Skills Variables** (q1-q4): Technical, Communication, Leadership, Time Management
- **Network Variables** (q5-q7): Network Size, Quality, Access
- **Outcome** (q10): Job/Promotion Success

### Key Techniques

- **Correlation Analysis**: Full Spearman correlation matrix with heatmap
- **Relative Importance (LMG)**: Determines % of R² each predictor contributes
- **Subgroup Analysis**: Tests if the paradox holds across demographics (Role, Career Stage, Geography)
- **Interaction Testing**: Examines if demographic factors moderate skill-outcome relationships
- **Multicollinearity Checks**: VIF values to ensure independence of predictors

---

## Project Structure

```
vector_analysis/
├── README.md                              # This file
├── vector_survey_responses.csv            # Raw survey data
├── install_dependencies.R                 # Installs all R packages
├── data_diagnostics.R                     # Data quality validation
├── run_all_analyses.R                     # Master pipeline script
├── vector_comprehensive_analysis.R        # Main analysis (Skills vs Outcomes)
├── vector_subgroup_analysis.R             # Demographic subgroup testing
└── output/                                # All generated files
    ├── correlation_heatmap.png
    ├── relative_importance_barplot.png
    ├── subgroup_top_predictors_comparison.png
    ├── correlation_matrix.csv
    ├── relative_importance_results.csv
    ├── variable_labels.csv
    ├── subgroup_analysis_results.csv
    └── data_diagnostic_report.txt
```

---

## Generated Outputs

All outputs are saved to the `output/` folder:

### Visualizations
- **`correlation_heatmap.png`**: Full correlation matrix showing relationships between all variables
- **`relative_importance_barplot.png`**: Ranked predictors showing which skills matter most
- **`subgroup_top_predictors_comparison.png`**: How rankings change across demographic groups

### Data Files
- **`correlation_matrix.csv`**: Full Spearman correlation matrix
- **`relative_importance_results.csv`**: Ranked predictors with % contribution to model R²
- **`variable_labels.csv`**: Variable descriptions and categories
- **`subgroup_analysis_results.csv`**: Relative importance broken down by demographic subgroup
- **`data_diagnostic_report.txt`**: Data quality summary and recommendations

---

## Understanding the Results

### The Royal Rumble: Relative Importance Ranking

The core finding is a **ranked list** of predictors ordered by their contribution to explaining job success variance:

1. **Gold** 🥇: Strongest predictor (highest % contribution)
2. **Silver** 🥈: Second strongest
3. **Bronze** 🥉: Third strongest

**Example Interpretation:**
- If q4 (Time Management) is #1: Remote Work Paradox is **CONFIRMED**
- If q1 (Technical Skills) is #1: Remote Work Paradox is **REJECTED**
- If different: Unexpected finding (education level? Gender? Role type?)

### Key Metrics

- **LMG Contribution (%)**: Percentage of total R² explained by each predictor
- **Model R²**: Overall proportion of job success variance explained by all 7 predictors
- **VIF (Variance Inflation Factor)**: Multicollinearity check (VIF > 5 is concerning)
- **Interaction p-value**: If < 0.05, demographic factors moderate skill-outcome relationships

---

## Technical Details

### Data Requirements
- **Input**: `vector_survey_responses.csv` with columns 8-18 containing Likert-scale responses (1-5)
- **Minimum Sample**: n ≥ 30 for basic analysis, n ≥ 50 recommended
- **Missing Data**: Analyses use complete cases only

### Variables Mapping
```
q1  = Technical Skills (Programming, Data Analysis)
q2  = Communication Skills (Writing, Presentation)
q3  = Leadership Skills (Guiding teams)
q4  = Time Management (Organization, Deadlines)
q5  = Network Size (Quantity of connections)
q6  = Network Quality (Insights/Advice)
q7  = Network Access (Professional circles)
q10 = Job/Promotion Success (PRIMARY OUTCOME)
```

### Statistical Methods
- **Correlation**: Spearman rank correlation (non-parametric)
- **Relative Importance**: Lindeman, Merenda, Gold (LMG) decomposition
- **Standardization**: All predictors are z-scored before regression
- **Subgroup Analysis**: Stratified relative importance analysis
- **Interaction Tests**: Moderation analysis with binary demographic factors

---

## Troubleshooting

### "Data file not found"
- Ensure `vector_survey_responses.csv` is in the same directory as the R scripts
- Check current working directory: `getwd()` in R

### "Package X not found / Installation failed"
- Run `install_dependencies.R` again
- Check internet connection
- On Linux/Mac, you may need C++ compiler: `apt install build-essential` (Ubuntu/Debian)

### "CRAN mirror error"
- Already handled by the scripts (they use `https://cloud.r-project.org`)
- If issues persist: `options(repos = c(CRAN = "https://your-mirror.com/CRAN"))`

### Tiny sample size (n < 30)
- Analysis will run but results may not be statistically robust
- Data diagnostic report will warn you about this

### Low variance in some variables
- Suggests ceiling/floor effects or likert scale compression
- Check diagnostic report for flagged questions

---

## Extending the Analysis

### Add Custom Demographics
Edit `vector_subgroup_analysis.R` section 2 to create new demographic variables:
```r
# Example: Add age group
df_clean$Age_Group <- cut(df_clean$age_column, breaks=c(0, 25, 35, 50, 100))
```

### Try Different Correlation Methods
In `vector_comprehensive_analysis.R`, change:
```r
cor_matrix <- cor(..., method = "pearson")  # or "kendall"
```

### Adjust Relative Importance Method
```r
rel_imp <- calc.relimp(..., type = "car")  # or "betasq", "pratt"
```

### Filter to Subsets
Add rows to subgroup analysis or create custom script:
```r
df_subset <- df_clean[df_clean$role == "Tech", ]
```

---

## Packages Used

- `lavaan` - Structural equation modeling
- `dplyr` - Data manipulation
- `ggplot2` - Visualizations
- `corrplot` - Correlation heatmaps
- `relaimpo` - Relative importance metrics
- `tidyr` - Data reshaping
- `psych` - Descriptive statistics
- `reshape2` - Data reshaping
- `gridExtra` - Grid graphics
- `car` - Multicollinearity diagnostics (VIF)
- `pbkrtest` - Statistical testing
- `lme4` - Linear mixed effects models
- `ppcor` - Partial correlations

---

## Citation & Attribution

**Project VECTOR** - Doctoral Research on Remote Work Career Outcomes  
Analysis Scripts Generated: February 2026  
Data: Virufy Volunteer Career Outcomes Survey

---

## Contact & Questions

For questions about the analysis or results, check:
1. `output/data_diagnostic_report.txt` for data quality notes
2. `output/relative_importance_results.csv` for complete rankings
3. Console output from `run_all_analyses.R` for computational details

---

**Last Updated**: February 16, 2026
