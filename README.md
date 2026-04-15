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

This repository implements a reproducible quantitative supplement for the paper *"From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit."* Using **relative importance analysis (LMG decomposition)**, we decompose the career-outcome variance attributable to seven skill and network predictors across 78 Virufy volunteers. The full-sample model achieves R² = 0.575, with **Leadership Skills (q3)** emerging as the strongest predictor (17.2% contribution), followed by **Communication Skills (q2)** (16.1%) and **Network Quality (q6)** (15.7%). Subgroup analyses reveal role-specific and career-stage-specific patterns, with students showing stronger leadership effects (23.3%) than professionals (10.4%). SEM fit is mixed but generally acceptable (CFI = 0.996, TLI = 0.994, SRMR = 0.030, RMSEA = 0.083).

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
| **SEM CFI** | 0.996 | — | — |
| **SEM RMSEA** | 0.083 | — | — |

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

### 3.2 Quick Start: Run the Analysis in 3 Steps

To reproduce all results on your machine:

#### **Step 1:** Clone the Repository

```bash
git clone https://github.com/virufy/paper-career-supplement.git
cd paper-career-supplement
```

#### **Step 2:** Install R Dependencies (Once)

```bash
Rscript --vanilla install_dependencies.R
```

**On Linux (Ubuntu/Debian)**, you may first need system tools:

```bash
sudo apt update && sudo apt install -y build-essential r-base-dev libcurl4-openssl-dev libxml2-dev libssl-dev
```

#### **Step 3:** Run the Consolidated Analysis Pipeline

```bash
Rscript --vanilla run_analysis.R
```

This single script:
- **Auto-detects data source:** Uses `input/vector_survey_responses.csv` if available (real data), otherwise uses example data for demonstration
- **Executes full 6-step pipeline:** Data audit → Descriptive stats → LMG analysis → Subgroup analysis → SEM → Paper claim verification
- **Generates 29 output files:** CSV/HTML tables, PNG/SVG visualizations, and session metadata in the `output/` directory
- **Takes ~2-5 minutes** depending on your machine (bootstrap iterations: 1,000)

**Output files** are written to `output/` (git-ignored, generated freshly each run):

```
relative_importance_results.csv       ← Main LMG rankings (Table 2)
subgroup_analysis_results.csv        ← Stratified findings (role, stage, geography)
sem_fit_indices.csv                  ← SEM model validation
paper_claim_check.csv                ← Automated paper reproducibility audit
correlation_heatmap.png              ← Visual predictor correlations
relative_importance_barplot.png      ← Visual LMG rankings
subgroup_top_predictors_comparison.png ← Subgroup comparison
[11 additional CSV audit files]
```

#### **To Run with Your Own Data**

If you have collected your own survey data using the standardized instrument:

1. Ensure your CSV has the same structure: ≥18 columns with Likert items in columns 8–18
2. Save it as `input/vector_survey_responses.csv`
3. Run: `Rscript --vanilla run_analysis.R`
4. Script automatically detects: "✓ Using real data: input/vector_survey_responses.csv"

#### **Troubleshooting**

| Issue | Solution |
|-------|----------|
| "Missing package 'X'" | Run `install_dependencies.R` again or ensure internet connectivity |
| "Data file not found" | Verify your CSV is at `input/vector_survey_responses.csv` (or use example) |
| Permission errors on Linux | Try: `chmod +x *.R && Rscript --vanilla install_dependencies.R` |
| Very slow on large N | Edit `run_analysis.R` line ~220: change `R = 1000` to `R = 500` for bootstrap iterations |

---

## 5. Input Data Specification

**File:** `input/vector_survey_responses.csv`

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
paper-vector-career/
├── README.md                                (this file)
├── DATA_DICTIONARY.md                       (variable mappings)
├── SUPPLEMENT.md                            (academic methods supplement)
├── VERIFICATION_REPORT.md                   (reproducibility audit)
├── install_dependencies.R                   (install R packages)
├── run_analysis.R                           (main analysis pipeline)
├── generate_figures.R                       (publication figures 1–4)
├── generate_tables.R                        (publication tables 1–5)
├── input/
│   └── vector_survey_responses.csv          (survey data — not in git for privacy)
├── statistical_appendix/
│   ├── README.md
│   ├── reproduce_analysis.R
│   └── vector_survey_responses_example.csv  (anonymised example dataset, N=30)
└── output/                                  (generated — not in git)
    ├── fig1_correlation_matrix.png
    ├── fig2_sem_path.png
    ├── fig3_lmg_forest.png
    ├── fig4_subgroup_comparison.png
    ├── table1_geography.html  … table5_convergence.html
    ├── relative_importance_results.csv
    ├── subgroup_analysis_results.csv
    ├── sem_fit_indices.csv
    ├── paper_claim_check.csv
    └── [additional CSV diagnostics]
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
