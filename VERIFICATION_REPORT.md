# Reproducibility Verification Report

**Study:** From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit

**Repository:** github.com/virufy/paper-career-supplement  
**Date Generated:** 2026-04-23 (updated from 2026-04-09)  
**Reproducible Script:** `run_analysis.R`

---

## Executive Summary

This report documents a fresh rerun of the full analysis pipeline and compares claims in the submitted manuscript PDF against generated outputs in `output/`.

- Pipeline rerun status: **PASS** (exit code 0)
- Output regeneration: **PASS** (all expected CSV/plot files regenerated)
- Main full-sample OLS and LMG findings: **REPRODUCED**
- SEM headline values in manuscript: **NEEDS UPDATE** — RMSEA in manuscript (0.083) does not match code output (0.097)
- Participant-flow narrative alignment: **VERIFIED** — 78 complete cases (anonymized dataset pre-excludes 2 incomplete rows)

---

## 1. Data Audit & Participant Flow

### 1.1 Input Data Characteristics

| Metric | Value |
|--------|-------|
| Input file | `input/vector_survey_responses.csv` |
| Total rows | 80 |
| Core-complete rows | 78 |
| Excluded rows (core missing) | 2 |

### 1.2 Participant Flow

From `output/participant_flow.csv`:

```
input_rows            80
complete_core_likert  78
excluded_core_missing 2
```

**Verification note:** The repository supports 80 -> 78 -> 2 accounting. If manuscript text also reports broader recruitment totals (e.g., invitation counts), that should be explicitly labeled as external to this public CSV.

---

## 2. Full-Sample Main Findings: Verification

### 2.1 OLS Diagnostics

From `output/full_model_diagnostics.csv`:

| Metric | Code Value |
|--------|------------|
| *N* | 78 |
| R² | 0.574992 |
| Adj. R² | 0.532492 |
| *F* | 13.528985 |
| *p* (*F*) | 6.41e-11 |
| Max VIF | 4.706841 |
| Shapiro-Wilk *p* | 3.56e-05 |
| Breusch-Pagan *p* | 0.972628 |

**Status:** Full-sample R² = 0.575 claim is reproduced after rounding.

### 2.2 Relative Importance (LMG)

From `output/relative_importance_results.csv`:

| Rank | Variable | Code LMG (%) | Rounded |
|------|----------|--------------|---------|
| 1 | q3 Leadership | 17.1665 | 17.2 |
| 2 | q2 Communication | 16.0676 | 16.1 |
| 3 | q6 Network Quality | 15.7292 | 15.7 |
| 4 | q1 Technical | 14.3879 | 14.4 |
| 5 | q4 Time Management | 13.3943 | 13.4 |
| 6 | q7 Network Access | 12.6720 | 12.7 |
| 7 | q5 Network Size | 10.5825 | 10.6 |

**Status:** Rank order and rounded percentages are reproduced.

---

## 3. Subgroup Findings: Verification

From `output/subgroup_analysis_results.csv`:

### 3.1 Role Type

- Tech (*n* = 51): top predictor q3 = 18.359% (18.4%)
- Non-Tech (*n* = 27): top predictor q1 = 21.697% (21.7%)

### 3.2 Career Stage

- Student (*n* = 46): top predictor q3 = 23.327% (23.3%)
- Professional (*n* = 32): top predictor q6 = 21.535% (21.5%)

**Status:** Subgroup headline claims in the current PDF are reproduced.

---

## 4. SEM Fit Verification

From `output/sem_fit_indices.csv`:

| Index               | Code Value     | Manuscript says | Status                       |
| ------------------- | -------------- | --------------- | ---------------------------- |
| CFI                 | 0.994          | 0.996           | update needed                |
| TLI                 | 0.992          | 0.994           | update needed                |
| RMSEA               | **0.097**      | 0.083           | **update needed — critical** |
| RMSEA 90% CI        | [0.056, 0.134] | [0.028, 0.127]  | update needed                |
| SRMR                | 0.032          | 0.030           | update needed                |
| HC-SC composite *r* | 0.865          | 0.865           | ✓ correct                    |

**Status:** RMSEA mismatch confirmed. Manuscript must be updated to report RMSEA = 0.097 before submission. See SUBMISSION_AUDIT.md for exact replacement text.

**Interpretation:** RMSEA = 0.097 is above the strict 0.08 cutoff; CFI/TLI/SRMR are strong. Describe fit as mixed but acceptable (Hu & Bentler, 1999).

---

## 5. Automated Claim Check Snapshot

From `output/paper_claim_check.csv` (rerun 2026-04-23):

- MATCH: 16/16 claims
- MISMATCH: 0

All LMG, subgroup, R², and composite-*r* claims reproduce exactly. The one outstanding issue is the SEM RMSEA value in the manuscript body text (see Section 4 above) — that is a manuscript edit, not a code discrepancy.

---

## 6. Submission-Readiness Recommendations

1. Clarify participant-flow language in the manuscript so 80-row repository accounting and broader invitation totals are not conflated.
2. Keep SEM interpretation cautious: report mixed fit (strong CFI/TLI/SRMR, elevated RMSEA).
3. Update `output/paper_claim_check.csv` paper values to match the final manuscript version.
4. Continue sourcing all reported percentages directly from generated CSV outputs to avoid transcription drift.

---

## 7. Session Note

Fresh rerun completed successfully on 2026-04-09 and regenerated analysis outputs in `output/`.
