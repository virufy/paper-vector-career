<div align="center">

# Project VECTOR: Volunteer Career Outcomes Analysis

### Skill & Network Development as Predictors of Career Impact  
### A Quantitative Analysis of Virufy Volunteers (*N* = 78)

**Amil Khanzada** — Graduate Research in Career Outcomes & Development

[![R 4.0+](https://img.shields.io/badge/r-4.0%2B-blue.svg)](https://www.r-project.org/)
[![Data Audited](https://img.shields.io/badge/N%20complete-78-brightgreen.svg)](output/participant_flow.csv)
[![Reproducible](https://img.shields.io/badge/reproducible-verified-brightgreen.svg)](VERIFICATION_REPORT.md)

</div>

---

## Abstract

This repository implements a reproducible quantitative supplement for the paper *"From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit."* Using **relative importance analysis (LMG decomposition)**, we decompose the career-outcome variance attributable to seven skill and network predictors across 78 Virufy volunteers. The full-sample model achieves R² = 0.575, with **Leadership Skills (q3)** emerging as the strongest predictor (17.2% contribution), followed by **Communication Skills (q2)** (16.1%) and **Network Quality (q6)** (15.7%). Subgroup analyses reveal role-specific and career-stage-specific patterns, with students showing stronger leadership effects (23.3%) than professionals (10.4%). An SEM model confirms the validity of latent skill and networking constructs.

**Keywords:** Career Development · Volunteer Outcomes · Relative Importance Analysis · Psychometric Modeling · Tech Nonprofit

---

## 1. Analytical Framework: Skill & Network Decomposition

This supplement decomposes six months of Virufy volunteer survey data (April 2025 – September 2025) into three interpretable components:

```
┌────────────────────────────────────────────────────────────┐
│           CAREER OUTCOMES PREDICTION PIPELINE              │
│                                                            │
│  ┌────────────────────┐  ┌──────────────────────┐        │
│  │  Skill Predictors  │  │  Network Predictors  │        │
│  │                    │  │                      │        │
│  │  • q1: Technical   │  │  • q5: Size          │        │
│  │  • q2: Comm.       │  │  • q6: Quality       │        │
│  │  • q3: Leadership  │  │  • q7: Access        │        │
│  │  • q4: Time Mgmt   │  │                      │        │
│  └─────────┬──────────┘  └──────────┬───────────┘        │
│            │                        │                     │
│            └────────────┬───────────┘                     │
│                         │                                 │
│                   Feature Engineering                     │
│                Scaling · Missingness Audit                │
│                Complete-Case Deletion (n=78)              │
│                         │                                 │
│         ┌───────────────┴───────────────┐                │
│         │   OLS Regression (LMG)        │                │
│         │   + Bootstrap Confidence      │                │
│         │   + VIF Diagnostics          │                │
│         │   + SEM Construct Validation │                │
│         └───────────────┬───────────────┘                │
│                         │                                 │
│    ┌────────────────────┼────────────────────┐           │
│    │                    │                    │           │
│  ┌─▼──────┐  ┌──────────▼────────┐  ┌───────▼─┐        │
│  │ Full   │  │ Subgroup Ranking  │  │ SEM     │        │
│  │ Rank   │  │ (Role, Stage, Geo)│  │ Structure│        │
│  │ Order  │  │                   │  │ Validity │        │
│  └────────┘  └───────────────────┘  └─────────┘        │
│                                                            │
│         ──► relative_importance_results.csv               │
│         ──► subgroup_analysis_results.csv                │
│         ──► sem_fit_indices.csv                          │
│         ──► paper_claim_check.csv                        │
└────────────────────────────────────────────────────────────┘
```

---

## 2. Key Results

| Metric | Full Sample | Students | Professionals |
|--------|-------------|----------|----------------|
| *n* | 78 | 46 | 32 |
| R² (OLS) | **0.575** | **0.709** | **0.484** |
| Top Predictor | q3: Leadership  (17.2%) | q3: Leadership (23.3%) | q6: Network Quality (21.5%) |
| #2 Predictor | q2: Communication (16.1%) | q4: Time Mgmt (17.1%) | q1: Technical (18.6%) |
| #3 Predictor | q6: Network Quality (15.7%) | q2: Communication (15.3%) | q2: Communication (15.5%) |
| **SEM CFI** | 1.000 | — | — |
| **SEM RMSEA** | 0.000 (saturated) | — | — |

**Role-Type Results:**

| Predictor | Tech (*n*=51) | Non-Tech (*n*=27) |
|-----------|---------------|-------------------|
| q1: Technical | 12.7% | **21.7%** ⭐ |
| q2: Communication | 15.3% | 12.9% |
| q3: Leadership | **18.4%** ⭐ | 13.6% |
| q6: Network Quality | 16.4% | 15.2% |

---

## 3. Reproducibility & Verification

### 3.1 Complete-Case Accounting

From `output/participant_flow.csv`:

- **Input rows**: 80
- **Complete-case rows** (*q1*–*q11*): 78
- **Excluded** (missing core items): 2

### 3.2 Running the Analysis on a New Machine

To reproduce all results from scratch on a clean machine:

#### Step 1: Clone the Repository

```bash
git clone https://github.com/virufy/paper-career-supplement.git
cd paper-career-supplement
```

#### Step 2: Install Dependencies

```bash
Rscript --vanilla install_dependencies.R
```

This installs all required R packages (relaimpo, car, lmtest, lavaan, boot, ggplot2, corrplot, psych, dplyr, ppcor).

**On Linux (Ubuntu/Debian)**, you may first need system development tools:

```bash
sudo apt update && sudo apt install -y build-essential r-base-dev libcurl4-openssl-dev libxml2-dev libssl-dev
```

#### Step 3: Place Your Data File

For **local reproduction with full data**: Ensure `vector_survey_responses.csv` is in the repository root directory. The file must contain at least 18 columns with core Likert items in columns 8–18 (mapped to q1–q11).

**For online platforms or submissions** (where full data is not available): Use the example dataset:
```bash
cp vector_survey_responses_example.csv vector_survey_responses.csv
```

This will run the pipeline on the 10-row example dataset.

#### Step 4: Run the Full Analysis Pipeline

```bash
Rscript --vanilla run_all_analyses.R
```

This runs five key steps:
1. **Data audit** → outputs participant flow and missingness reports
2. **Descriptive statistics & correlations** → correlation heatmap and summary stats
3. **Full-sample LMG analysis** → relative importance decomposition with bootstrap CIs
4. **Subgroup analysis** → LMG stratified by role type, career stage, geography
5. **SEM estimation** → structural equation model fit indices
6. **Claim verification** → automated check of paper claims against code outputs

#### Step 5: Review Outputs

All results are written to the `output/` directory:

```bash
ls -lh output/
```

Key files:
- `relative_importance_results.csv` — LMG rankings with 95% bootstrap CIs
- `subgroup_analysis_results.csv` — subgroup-stratified results
- `paper_claim_check.csv` — automated claim verification table
- `correlation_heatmap.png`, `relative_importance_barplot.png` — visualizations
- `session_info.txt` — reproducibility metadata

#### Step 6: For Submissions & Quick Reproducibility

A self-contained reproducible example is also available in the `stats_appendix/` folder:

```bash
cd stats_appendix
Rscript reproduce_analysis.R
```

This focuses on the core relative importance analysis (no subgroups or SEM) and runs quickly on the example dataset. See [stats_appendix/README.md](stats_appendix/README.md) for details.

#### Troubleshooting

| Issue | Solution |
|-------|----------|
| "Data file not found" | Ensure `vector_survey_responses.csv` is in the repository root. Check `getwd()` in R. |
| Package installation fails | Update R to ≥4.0, ensure internet connectivity, install Linux build tools (see Step 2). |
| Permission denied errors | Run with `chmod +x *.R` or use `Rscript --vanilla` (recommended). |
| Memory issues on large datasets | Reduce bootstrap iterations in `run_all_analyses.R` line 170 (`R = 1000` → `R = 500`). |

---

## 4. Installation & Reproducibility

### Requirements

- R ≥ 4.0
- Internet connection (initial package install only)

### Quick Start

```bash
# Step 1: Install dependencies (one time)
Rscript --vanilla install_dependencies.R

# Step 2: Run full analysis pipeline
Rscript --vanilla run_all_analyses.R
```

All outputs are written to `output/`.

### Test with Example Data

```bash
cp vector_survey_responses_example.csv vector_survey_responses.csv
Rscript --vanilla run_all_analyses.R
```

---

## 5. Input Data Specification

**File:** `vector_survey_responses.csv`

| Field | Specification |
|-------|---------------|
| Format | CSV, comma-separated |
| Encoding | UTF-8 |
| Required columns | Minimum 18 (see DATA_DICTIONARY.md) |
| Core Likert items | Columns 8–18 → mapped to *q1*–*q11* |
| Missing data handling | **Complete-case deletion**: rows with any NA in *q1*–*q11* excluded |
| Primary outcome | *q10* (Job/Promotion Success) |

---

## 6. Repository Structure

```
paper-career-supplement/
├── README.md                                (this file)
├── DATA_DICTIONARY.md                       (variable mappings)
├── SUPPLEMENT.md                            (academic methods)
├── VERIFICATION_REPORT.md                   (reproducibility audit)
├── install_dependencies.R                   (dependency installer)
├── run_all_analyses.R                       (master script)
├── vector_survey_responses.csv              (input data)
├── vector_survey_responses_example.csv      (test dataset)
├── stats_appendix/                          (submission-ready materials)
│   ├── README.md
│   ├── reproduce_analysis.R
│   └── vector_survey_responses_example.csv
└── output/                                  (git-ignored, generated)
    ├── data_audit_summary.csv
    ├── participant_flow.csv
    ├── descriptive_statistics.csv
    ├── correlation_matrix.csv
    ├── correlation_heatmap.png
    ├── relative_importance_results.csv
    ├── relative_importance_barplot.png
    ├── full_model_diagnostics.csv
    ├── subgroup_analysis_results.csv
    ├── subgroup_counts.csv
    ├── subgroup_top_predictors_comparison.png
    ├── sem_fit_indices.csv
    ├── paper_claim_check.csv
    └── session_info.txt
```

---

## 7. Main Output Files

### Data Quality

- **`output/data_audit_summary.csv`** — input rows, complete rows, excluded rows
- **`output/participant_flow.csv`** — stage-by-stage participant counts
- **`output/core_item_missingness.csv`** — per-item missing data proportion

### Full-Sample Analysis

- **`output/relative_importance_results.csv`** — LMG rankings with 95% bootstrap CIs
- **`output/full_model_diagnostics.csv`** — R², VIF, Shapiro*p*, Breusch-Pagan *p*
- **`output/correlation_matrix.csv`** — Spearman correlation heatmap data
- **`output/correlate_heatmap.png`** — visual correlation matrix
- **`output/relative_importance_barplot.png`** — LMG contribution chart

### Subgroup Analysis

- **`output/subgroup_counts.csv`** — sample sizes per demographic group
- **`output/subgroup_analysis_results.csv`** — LMG rankings by role/stage/geography
- **`output/subgroup_top_predictors_comparison.png`** — visual comparison

### SEM & Validation

- **`output/sem_fit_indices.csv`** — CFI, TLI, RMSEA, SRMR, composite correlations
- **`output/paper_claim_check.csv`** — automated claim-by-claim verification

---

## 8. Statistical Methods

| Method | Package | Purpose |
|--------|---------|---------|
| LMG Relative Importance | `relaimpo` | Decompose R² across predictors; handles multicollinearity |
| OLS Diagnostics | `car`, `lmtest` | VIF, Shapiro-Wilk normality, Breusch-Pagan heteroscedasticity |
| Bootstrap Confidence Intervals | `boot` | 1,000-iteration BCa CI for LMG contributions |
| Spearman Correlation | base R | Non-parametric association for ordinal Likert items |
| Structural Equation Modeling | `lavaan` WLSMV | Latent construct validation (Skill_Development, Networking, Career_Outcomes) |
| Subgroup Analysis | Custom | Split samples by role type, career stage, geography |

### LMG Decomposition

The **Lindeman-Merenda-Gold** method decomposes the explained variance (R²) into contributions that account for predictor order and multicollinearity:

$$\text{LMG}_j = \frac{1}{P!} \sum_{\text{orderings } \pi} [R^2_{\pi_j} - R^2_{\pi_j^{-1}}]$$

where *P* is the number of predictors and $\pi_j^{-1}$ indicates the permutation without predictor *j*.

---

## 9. Reproducibility & Scientific Integrity

This repository adheres to the **FAIR principles** (Findable, Accessible, Interoperable, Reusable):

✓ **Findable:** versioned, publicly available, documented metadata  
✓ **Accessible:** open-source code, example data included, dependency specifications  
✓ **Interoperable:** standard CSV outputs, standard R ecosystem  
✓ **Reusable:** standalone reproducible scripts  

All numeric claims in the paper are automatically verified against code output in `output/paper_claim_check.csv`. See [VERIFICATION_REPORT.md](VERIFICATION_REPORT.md) for full audit trail.
