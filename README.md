# Project VECTOR: Remote Work Paradox Analysis

A comprehensive R analysis pipeline to validate the "Remote Work Paradox" hypothesis and identify true drivers of career success in remote work environments.

## Quick Start

### Prerequisites
- **R 4.0+** installed on your system
- **Internet connection** (for downloading R packages)

### Run in 2 Steps

#### Step 1: Install Dependencies
```bash
Rscript --vanilla install_dependencies.R
```
Takes ~5-10 minutes on first run. Installs all packages with proper dependency order.

#### Step 2: Run Analysis
```bash
Rscript --vanilla run_all_analyses.R
```
Outputs generated in `output/` folder.

### Test with Example Data
Before using your own data, test the pipeline:
```bash
cp vector_survey_responses_example.csv vector_survey_responses.csv
Rscript --vanilla run_all_analyses.R
```

---

## About This Analysis

**Research Question:** Does Time Management outperform Technical Skills in predicting remote work career success?

**Method:** Relative importance analysis (LMG metric) decomposes explained variance in job success across 7 predictors:
- q1-q4: Technical, Communication, Leadership, Time Management skills
- q5-q7: Network Size, Quality, Access

**Outputs:**
- Ranked predictors (which factor matters most?)
- Correlation matrix and heatmap
- Subgroup analysis (do rankings vary by role/seniority/geography?)
- Statistical checks (multicollinearity via VIF, partial correlations)

If q4 (Time Management) ranks #1 → Remote Work Paradox is confirmed.  
If q1 (Technical) ranks #1 → Paradox is rejected.

---

## Project Structure

```
vector_analysis/
├── README.md                              # This file
├── vector_survey_responses.csv            # Your survey data (replace with your own)
├── vector_survey_responses_example.csv    # Example test data
├── .gitignore                             # Git ignore rules
├── install_dependencies.R                 # Install all packages
├── run_all_analyses.R                     # Main analysis script
├── vector_comprehensive_analysis.R        # Relative importance + correlations
├── vector_subgroup_analysis.R             # Demographic breakdowns
└── output/                                # Generated files (not tracked)
    ├── correlation_heatmap.png
    ├── relative_importance_barplot.png
    ├── correlation_matrix.csv
    ├── relative_importance_results.csv
    ├── variable_labels.csv
    └── subgroup_analysis_results.csv
```

---

## How to Use Your Data

### Input Format
- **File:** `vector_survey_responses.csv` (replace the example file with your data)
- **Structure:** Columns 8-18 contain Likert-scale responses (1-5 scale)
- **Sample Size:** n ≥ 30 minimum, n ≥ 50 recommended
- **Missing Data:** Analyses use complete cases only

### Variable Definitions
All questions use 1-5 Likert scale:
```
q1  = Technical Skills (Programming, Data Analysis)
q2  = Communication Skills (Writing, Presentation)
q3  = Leadership Skills (Guiding teams)
q4  = Time Management (Organization, Deadlines)
q5  = Network Size (Quantity of connections)
q6  = Network Quality (Insights/Advice)
q7  = Network Access (Professional circles)
q10 = Job/Promotion Success ← PRIMARY OUTCOME
```

### Test with Example Data
The repo includes `vector_survey_responses_example.csv` (10 rows of realistic data).  
Copy it to test the pipeline before using real data:
```bash
cp vector_survey_responses_example.csv vector_survey_responses.csv
Rscript --vanilla run_all_analyses.R
```

---

## Interpreting Results

All outputs go to `output/` folder:

**Key File:** `output/relative_importance_results.csv`  
Shows predictors ranked by their % contribution to explaining job success variance.

**Reading the Results:**
- **LMG_Contribution (%):** How much of the R² does this predictor explain?
- **Model R²:** Total variance explained (aim for > 0.40 for meaningful model)
- **VIF values:** Check for multicollinearity (should be < 5)

**Example Output:**
```
Variable | LMG_Contribution | Description
---------|------------------|-------------------
q4       | 28.5%           | Time Management
q1       | 22.3%           | Technical Skills
q3       | 18.7%           | Leadership
```

**If Time Management (q4) is #1:** Remote Work Paradox is confirmed.  
**If Technical Skills (q1) is #1:** Paradox is rejected.

**Visualizations:**
- `correlation_heatmap.png` - Shows which variables correlate together
- `relative_importance_barplot.png` - Ranked predictors at a glance
- `subgroup_top_predictors_comparison.png` - Rankings by demographic group

---

## Statistical Robustness

This analysis uses rigorous statistical methods to ensure findings are reliable:

### Why This Matters
- **Relative Importance (LMG):** Accounts for predictor intercorrelations, avoiding bias toward correlated variables
- **Spearman Correlation:** Non-parametric method, doesn't assume normal distribution
- **VIF Checks:** Detects multicollinearity that could distort results
- **Partial Correlations:** Isolates each predictor's effect while controlling for others
- **Subgroup Analysis:** Tests if findings hold across different demographics

### Quality Checks Built In
- Complete cases only (no imputation)
- z-scored predictors (standardized comparison)
- Interaction tests for moderation effects
- Hierarchical correlation clustering

If results are questionable, the main script will warn you (e.g., "VIF > 5 indicates multicollinearity").

---

## Troubleshooting

### "Data file not found"
Check current directory: `getwd()` in R, or place `vector_survey_responses.csv` in repo folder.

### "Package installation failed"
Run `install_dependencies.R` again, or check internet connection.  
On Linux/Mac, you may need: `apt install build-essential`

### "CRAN mirror error"
Already configured in scripts (using `https://cloud.r-project.org`). Shouldn't appear.

### "Sample size too small"
Script will skip subgroup analysis if n < 15. Results need n ≥ 50 to be robust.

### "VIF > 5"
Multicollinearity detected (predictors are too correlated). Check correlation heatmap for problem variables.

---

## Customization

### Change correlation method
In `vector_comprehensive_analysis.R`, line with `cor()`:
```r
cor_matrix <- cor(..., method = "pearson")  # or "kendall"
```

### Try different relative importance metrics
```r
rel_imp <- calc.relimp(..., type = "car")  # or "betasq", "pratt"
```

### Add new demographics
In `vector_subgroup_analysis.R`, section 2:
```r
df_clean$Age_Group <- cut(df_clean$age_column, breaks=c(0, 25, 35, 50, 100))
```

### Filter to specific subset
```r
df_subset <- df_clean[df_clean$role == "Tech", ]
```

---

## Next Steps

1. **Test:** `cp vector_survey_responses_example.csv vector_survey_responses.csv` and run the pipeline
2. **Replace:** Swap in your real `vector_survey_responses.csv` when ready
3. **Analyze:** Check `output/relative_importance_results.csv` for key findings
4. **Interpret:** Compare rankings to your hypothesis

---

## References

- **LMG Method:** Lindeman, Merenda, & Gold (1980). *Introduction to Bivariate and Multivariate Analysis*
- **relaimpo Package:** Grömping (2006). Relative Importance for Linear Regression in R
- **VIF:** O'Brien (2007). A Caution Regarding Rules of Thumb for VIF

---

**Project VECTOR** — Remote Work Career Paradox Analysis  
**Generated:** February 2026  
**Data Source:** Virufy Volunteer Career Outcomes Survey  
**Last Updated:** February 16, 2026
