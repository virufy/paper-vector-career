# Verification Report

Generated from the refactored analysis pipeline in `run_all_analyses.R`.

## Environment

- Date: 2026-03-25
- Input file: `vector_survey_responses.csv`
- Script: `run_all_analyses.R`
- Session metadata: `output/session_info.txt`

## Data Audit

From `output/data_audit_summary.csv`:

- rows in input CSV: 80
- rows with complete core Likert items (`q1` to `q11`): 78
- rows excluded due to core missingness: 2

From `output/participant_flow.csv`:

- input rows: 80
- complete core Likert: 78
- excluded core missing: 2

Interpretation: this repository does not contain 112 consented responses. It contains 80 rows, of which 78 are complete on core items.

## Core Full-Sample Result

From `output/relative_importance_results.csv` and `output/full_model_diagnostics.csv`:

- Full-sample model R-squared: 0.575
- LMG ranking: q3 > q2 > q6 > q1 > q4 > q7 > q5

This reproduces the core rank order and full-sample R-squared reported in the paper.

## Subgroup Result Check

From `output/subgroup_analysis_results.csv`:

- Tech (n=51): q3 is top predictor (18.36%)
- Non-Tech (n=27): q1 is top predictor (21.70%)
- Student (n=46): q3 is top predictor (23.33%)
- Professional (n=32): q6 is top predictor (21.54%), q4 is 9.57%

Interpretation: the claim that q4 is the top professional predictor is not supported by the reproducible outputs in this repository.

## SEM Result Check

From `output/sem_fit_indices.csv`:

- CFI: 1.000
- TLI: 1.001
- RMSEA: 0.000
- SRMR: 0.030
- HC-SC composite r: 0.865

Interpretation: these do not match manuscript claims that cite CFI=0.975, RMSEA=0.039, and HC-SC r=0.94.

## Claim-by-Claim Status

`output/paper_claim_check.csv` provides a machine-readable claim audit.

Current mismatches include:

- SEM CFI
- SEM RMSEA
- HC-SC composite r
- Table 2 q5 and q7 percentages
- Tech q6 percentage
- Non-Tech q1 percentage
- Professional q4 percentage

## Publishability Assessment

Current repository status is improved and reproducible, but not fully publication-ready as a standalone supplement because:

1. Participant-flow claim (112 -> 78) is not reproducible from this dataset.
2. Multiple manuscript numeric claims do not match regenerated outputs.
3. SEM claims appear to come from a different dataset version than the one provided.

## Minimum Actions Before Submission

1. Freeze and archive the exact dataset used for manuscript numbers.
2. Regenerate all manuscript tables directly from `output/*.csv` artifacts.
3. Either:
   - provide reproducible SEM inputs/scripts for the manuscript SEM claims, or
   - clearly label SEM claims as derived from an external private dataset.
4. Correct subgroup text for professionals to reflect current output (or rerun with the exact manuscript dataset and report that version consistently).
