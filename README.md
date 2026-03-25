<div align="center">

# Project VECTOR: Volunteer Career Outcomes Analysis

### Skill & Network Development as Predictors of Career Impact  
### A Quantitative Analysis of Virufy Volunteers (*N* = 78)

**Amil Khanzada** — Graduate Research in Career Outcomes & Development

[![R 4.0+](https://img.shields.io/badge/r-4.0%2B-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
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
┌──────────────────────────────────────────────────────────┐
│          CAREER OUTCOMES PREDICTION PIPELINE             │
│                                                          │
│  ┌────────────────────┐  ┌──────────────────────┐       │
│  │  Skill Predictors  │  │  Network Predictors  │       │
│  │                    │  │                      │       │
│  │  • q1: Technical   │  │  • q5: Size          │       │
│  │  • q2: Comm.       │  │  • q6: Quality       │       │
│  │  • q3: Leadership  │  │  • q7: Access        │       │
│  │  • q4: Time Mgmt   │  │                      │       │
│  └─────────┬──────────┘  └──────────┬───────────┘       │
│            │                        │                    │
│            └────────────┬───────────┘                    │
│                         │                                │
│                   Feature Engineering                    │
│                Scaling · Missingness Audit               │
│                Complete-Case Deletion (n=78)             │
│                         │                                │
│         ┌───────────────┴───────────────┐               │
│         │   OLS Regression (LMG)        │               │
│         │   + Bootstrap Confidence      │               │
│         │   + VIF Diagnostics          │               │
│         │   + SEM Construct Validation │               │
│         └───────────────┬───────────────┘               │
│                         │                                │
│    ┌────────────────────┼────────────────────┐          │
│    │                    │                    │          │
│  ┌─▼──────┐  ┌──────────▼────────┐  ┌───────▼─┐       │
│  │ Full   │  │ Subgroup Ranking  │  │ SEM     │       │
│  │ Rank   │  │ (Role, Stage, Geo)│  │ Structure │       │
│  │ Order  │  │                   │  │ Validity │       │
│  └────────┘  └───────────────────┘  └─────────┘       │
│                                                          │
│         ──► relative_importance_results.csv              │
│         ──► subgroup_analysis_results.csv               │
│         ──► sem_fit_indices.csv                         │
│         ──► paper_claim_check.csv                       │
└──────────────────────────────────────────────────────────┘
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

### 3.2 Claim Verification

All paper claims are automatically checked against reproducible code outputs in `output/paper_claim_check.csv`. Current status:

| Claim | Paper | Code | Status |
|-------|-------|------|--------|
| Full-sample R² | 0.575 | 0.575 | ✓ MATCH |
| q3 (Leadership) | 17.2% | 17.2% | ✓ MATCH |
| q2 (Communication) | 16.1% | 16.1% | ✓ MATCH |
| q6 (Network Quality) | 15.7% | 15.7% | ✓ MATCH |
| Student q3 | 23.3% | 23.3% | ✓ MATCH |
| SEM CFI | 0.975* | 1.000 | — (external dataset) |

*SEM fit indices were computed on the full private dataset by co-author Muskaan.*

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
├── LICENSE
├── install_dependencies.R                   (dependency installer)
├── run_all_analyses.R                       (master script)
├── vector_survey_responses.csv              (input data)
├── vector_survey_responses_example.csv      (test dataset)
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

## 9. How to Cite

```bibtex
@software{khanzada2026vector,
  author = {Khanzada, Amil},
  title = {Project VECTOR: Reproducible Analysis Supplement},
  year = {2026},
  month = {March},
  note = {GitHub repository for paper "From Volunteer to Vocation"},
  url = {https://github.com/virufy/paper-career-supplement}
}
```

---

## 10. Reproducibility & Scientific Integrity

This repository adheres to the **FAIR principles** (Findable, Accessible, Interoperable, Reusable):

✓ **Findable:** versioned, publicly available, documented metadata  
✓ **Accessible:** open-source code, example data included, dependency specifications  
✓ **Interoperable:** standard CSV outputs, standard R ecosystem  
✓ **Reusable:** MIT License, standalone reproducible scripts  

All numeric claims in the paper are automatically verified against code output in `output/paper_claim_check.csv`. See [VERIFICATION_REPORT.md](VERIFICATION_REPORT.md) for full audit trail.
