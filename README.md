# Project VECTOR: Volunteer Career Outcomes Analysis

An R analysis pipeline for the paper *"From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit."*

Quantifies the career ROI of skill-based volunteering using Relative Importance Analysis (LMG), Structural Equation Modeling (SEM), and demographic subgroup analysis across 78 Virufy volunteers.

## Quick Start

### Prerequisites
- R 4.0+
- Internet connection (for package installation)

### Run in 2 Steps

```bash
# Step 1: Install dependencies (~5-10 min first time)
Rscript --vanilla install_dependencies.R

# Step 2: Run all analyses
Rscript --vanilla run_all_analyses.R
```

Outputs go to `output/` folder.

### Test with Example Data
```bash
cp vector_survey_responses_example.csv vector_survey_responses.csv
Rscript --vanilla run_all_analyses.R
```

---

## What the Pipeline Does

`run_all_analyses.R` runs four steps in order:

| Step | Script | Purpose |
|---|---|---|
| 1 | `vector_comprehensive_analysis.R` | Descriptive stats, LMG relative importance, correlation heatmap, head-to-head comparisons |
| 2 | `vector_subgroup_analysis.R` | LMG by role type (Tech/Non-Tech) and career stage (Student/Professional) |
| 3 | `vector_sem_analysis.R` | SEM with WLSMV estimator; reports CFI, RMSEA, SRMR |
| 4 | *(inline in run_all_analyses.R)* | Verifies code output against paper's reported figures |

---

## Project Structure

```
paper-career-supplement/
├── README.md
├── vector_survey_responses.csv            # Your survey data (replace with real data)
├── vector_survey_responses_example.csv    # 10-row test dataset
├── .gitignore
├── install_dependencies.R                 # One-time package install
├── run_all_analyses.R                     # Master script (runs all 4 steps)
├── vector_comprehensive_analysis.R        # Step 1: LMG + correlations
├── vector_subgroup_analysis.R             # Step 2: Demographic subgroups
├── vector_sem_analysis.R                  # Step 3: SEM construct validity
└── output/                                # Generated outputs (git-ignored)
    ├── correlation_heatmap.png
    ├── relative_importance_barplot.png
    ├── subgroup_top_predictors_comparison.png
    ├── correlation_matrix.csv
    ├── relative_importance_results.csv
    ├── variable_labels.csv
    ├── subgroup_analysis_results.csv
    └── sem_fit_indices.csv
```

---

## Input Data Format

- **File:** `vector_survey_responses.csv`
- **Columns 8–18:** Likert-scale responses (1–5), automatically renamed q1–q11
- **Minimum n:** 30; n ≥ 50 recommended for subgroup analysis

### Variable Definitions

| Variable | Category | Description |
|---|---|---|
| q1 | Skills | Technical Skills (Programming, Data Analysis) |
| q2 | Skills | Communication Skills (Writing, Presentation) |
| q3 | Skills | Leadership Skills (Guiding teams) |
| q4 | Skills | Time Management (Organization, Deadlines) |
| q5 | Network | Network Size (Quantity of connections) |
| q6 | Network | Network Quality (Insights/Advice) |
| q7 | Network | Network Access (Professional circles) |
| q8 | Outcomes | Overall Career Impact |
| q9 | Outcomes | Resume Competitiveness |
| **q10** | **Outcomes** | **Job/Promotion Success ← PRIMARY OUTCOME** |
| q11 | Outcomes | Leadership Role Advancement |

---

## Key Findings (N = 78)

**Full-sample relative importance (Table 2, R² = 0.575):**

| Rank | Predictor | LMG Contribution |
|---|---|---|
| 1 | Leadership Skills (q3) | 17.2% |
| 2 | Communication Skills (q2) | 16.1% |
| 3 | Network Quality (q6) | 15.7% |
| 4 | Technical Skills (q1) | 14.4% |
| 5 | Time Management (q4) | 13.4% |
| 6 | Network Access (q7) | 12.7% |
| 7 | Network Size (q5) | 10.6% |

**Subgroup findings:**
- Tech volunteers (n=51): Leadership is the top predictor (18.4%)
- Non-Tech volunteers (n=27): Technical literacy is the top predictor (21.7%) — exploratory
- Students (n=46): Leadership is the top predictor (23.3%)

**SEM model fit** (Skill_Development + Networking → Career_Outcomes):
CFI = 0.975, RMSEA = 0.039 — run on full private dataset by Muskaan.

---

## Interpreting Results

**`output/relative_importance_results.csv`** — primary output; predictor ranking by LMG contribution
**`output/sem_fit_indices.csv`** — CFI, RMSEA, SRMR for construct validity
**`output/subgroup_analysis_results.csv`** — LMG rankings by demographic group

Step 4 of the pipeline prints a verification table comparing code output to the figures in the paper. Mismatches are flagged as `MISMATCH` and should be investigated before submission.

---

## Troubleshooting

**"Data file not found"** — Check `getwd()` in R; place `vector_survey_responses.csv` in the repo root.

**"Package installation failed"** — Re-run `install_dependencies.R`; on Linux you may need `apt install build-essential r-base-dev`.

**"Sample size too small"** — Subgroup analysis requires n ≥ 15 per group. Check that demographic columns are being parsed correctly (column 4 = career stage, column 6 = role type).

**SEM returns CFI = 1.000, RMSEA = 0.000** — This happens when running on the anonymized local dataset (which has sparse data). The published SEM results (CFI = 0.975, RMSEA = 0.039) were produced on the full private dataset.

---

## Statistical Methods

| Method | Package | Purpose |
|---|---|---|
| LMG Relative Importance | `relaimpo` | Decomposes R² across predictors under multicollinearity |
| Structural Equation Modeling | `lavaan` (WLSMV) | Validates latent construct structure |
| Spearman Correlation | base R | Non-parametric association between ordinal items |
| VIF | `car` | Multicollinearity check |
| Partial Correlation | `ppcor` | Per-predictor effect controlling for others |

---

## References

- Lindeman, Merenda, & Gold (1980). LMG method for relative importance
- Grömping (2006). *relaimpo* package
- Hu & Bentler (1999). SEM fit thresholds (CFI > 0.95, RMSEA < 0.06)

---

**Project VECTOR** | Virufy Volunteer Career Outcomes Survey
**Last Updated:** March 2026
