# Project VECTOR: Career Impact Analysis Supplement

This repository contains a reproducible R pipeline for the paper:

"From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit."

The pipeline performs:
- data audit and complete-case accounting
- full-sample relative importance analysis (LMG)
- subgroup LMG analysis
- SEM fit estimation
- paper-claim verification against code outputs

## Requirements

- R 4.0+
- internet connection for initial package install

## Quick Start

```bash
# 1) Install dependencies once
Rscript --vanilla install_dependencies.R

# 2) Run full analysis
Rscript --vanilla run_all_analyses.R
```

All analysis artifacts are written to `output/`.

## Input Data Contract

- file: `vector_survey_responses.csv`
- expected minimum columns: 18
- core Likert items: columns 8-18, mapped to `q1` through `q11`
- primary outcome for LMG models: `q10` (Job/Promotion Success)

Rows with any missing value in `q1` to `q11` are excluded for primary analysis (complete-case strategy).

## Repository Layout

```text
paper-career-supplement/
  install_dependencies.R
  run_all_analyses.R
  vector_survey_responses.csv
  vector_survey_responses_example.csv
  output/
```

## Main Outputs

### Data quality and flow
- `output/data_audit_summary.csv`
- `output/core_item_missingness.csv`
- `output/participant_flow.csv`

### Full-sample analysis
- `output/descriptive_statistics.csv`
- `output/correlation_matrix.csv`
- `output/correlation_heatmap.png`
- `output/relative_importance_results.csv`
- `output/relative_importance_barplot.png`
- `output/full_model_diagnostics.csv`

### Subgroup analysis
- `output/subgroup_counts.csv`
- `output/subgroup_analysis_results.csv`
- `output/subgroup_top_predictors_comparison.png`

### SEM and claim checks
- `output/sem_fit_indices.csv`
- `output/paper_claim_check.csv`
- `output/session_info.txt`

## Statistical Methods

- LMG relative importance decomposition: `relaimpo`
- OLS diagnostics: VIF (`car`), Shapiro-Wilk, Breusch-Pagan (`lmtest`)
- Spearman correlation matrix
- SEM (WLSMV with ordered indicators): `lavaan`
- Bootstrap confidence intervals for LMG contributions: `boot`

## Reproducibility Notes

- The script records full session metadata in `output/session_info.txt`.
- All paper-claim checks are exported to `output/paper_claim_check.csv`.
- If manuscript values differ from current outputs, update manuscript tables from exported CSV files rather than manual transcription.

## Interpretation Caution

This repository is only as reproducible as the data included in `vector_survey_responses.csv`.
If manuscript claims were computed on a different private dataset version, those claims may not reproduce from this repository alone.

## Suggested Submission Workflow

1. Freeze the analysis dataset version used for submission.
2. Run `run_all_analyses.R` on that frozen dataset.
3. Populate manuscript numeric claims directly from output CSV files.
4. Include this repository plus output files as supplementary material.
