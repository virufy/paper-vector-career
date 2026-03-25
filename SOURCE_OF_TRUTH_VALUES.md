# SOURCE OF TRUTH: Code-Validated Values for Paper
## Generated from: `Rscript --vanilla run_all_analyses.R` (March 25, 2026)

**These are the ONLY values that should appear in the paper. Do not deviate.**

---

## MAIN RESULTS (Full Sample, N=78)

### Table 2: Relative Importance Decomposition (LMG % with 95% BCa CI)

| Rank | Variable | Exact Value | Rounded | 95% CI | Description |
|------|----------|-------------|---------|---------|----|
| 1 | q3 | 17.1665282854612 | 17.2% | [9.27%, 26.52%] | Leadership Skills |
| 2 | q2 | 16.0675828752614 | 16.1% | [9.76%, 23.76%] | Communication Skills |
| 3 | q6 | 15.7292452269887 | 15.7% | [10.15%, 22.91%] | Network Quality |
| 4 | q1 | 14.3878799544225 | 14.4% | [6.78%, 29.16%] | Technical Skills |
| 5 | q4 | 13.3942736156782 | 13.4% | [8.50%, 20.78%] | Time Management |
| 6 | q7 | 12.6719655106612 | 12.7% | [7.44%, 20.08%] | Network Access |
| 7 | q5 | 10.5825245315268 | 10.6% | [6.97%, 15.07%] | Network Size |

**Model R²:** 0.575

---

## SUBGROUP RESULTS

### By Career Stage

#### STUDENTS (N=46)

| Rank | Variable | Contribution % | Description |
|------|----------|-----|-------------|
| 1 | q3 | 23.327 | Leadership Skills |
| 2 | q4 | 17.145 | Time Management |
| 3 | q2 | 15.348 | Communication Skills |
| 4 | q6 | 12.304 | Network Quality |
| 5 | q1 | 10.959 | Technical Skills |
| 6 | q7 | 10.812 | Network Access |
| 7 | q5 | 10.105 | Network Size |

**R² = 0.709**

---

#### PROFESSIONALS (N=32)

| Rank | Variable | Contribution % | Description |
|------|----------|-----|-------------|
| 1 | q6 | 21.535 | Network Quality |
| 2 | q1 | 18.633 | Technical Skills |
| 3 | q2 | 15.529 | Communication Skills |
| 4 | q7 | 13.654 | Network Access |
| 5 | q5 | 10.646 | Network Size |
| 6 | q3 | 10.429 | Leadership Skills |
| 7 | q4 | 9.575 | Time Management |

**R² = 0.484**

---

### By Professional Role

#### TECH ROLES (N=51)

| Rank | Variable | Contribution % | Description |
|------|----------|-----|-------------|
| 1 | q3 | 18.359 | Leadership Skills |
| 2 | q6 | 16.381 | Network Quality |
| 3 | q2 | 15.329 | Communication Skills |
| 4 | q7 | 14.412 | Network Access |
| 5 | q1 | 12.666 | Technical Skills |
| 6 | q4 | 12.573 | Time Management |
| 7 | q5 | 10.280 | Network Size |

**R² = 0.562**

---

#### NON-TECH ROLES (N=27)

| Rank | Variable | Contribution % | Description |
|------|----------|-----|-------------|
| 1 | q1 | 21.697 | Technical Skills ⭐ |
| 2 | q6 | 15.226 | Network Quality |
| 3 | q3 | 13.637 | Leadership Skills |
| 4 | q7 | 13.252 | Network Access |
| 5 | q2 | 12.914 | Communication Skills |
| 6 | q4 | 12.136 | Time Management |
| 7 | q5 | 11.138 | Network Size |

**R² = 0.729**

---

## SEM MODEL FIT INDICES (N=78)

| Index | Value | Interpretation |
|-------|-------|-----------------|
| **CFI** | 0.996 | Excellent fit (>0.95) |
| **TLI** | 0.994 | Excellent fit (>0.95) |
| **RMSEA** | 0.083 | Acceptable fit (<0.10) |
| **RMSEA 90% CI** | [0.028, 0.127] | — |
| **SRMR** | 0.030 | Good fit (<0.05) |
| **Composite R (HC/SC)** | 0.865 | Good construct reliability |

---

## PUBLICATION-READY SENTENCES

Use these exact phrasings:

### Main Finding
"The full-sample model achieved R² = 0.575, explaining 57.5% of variance in career outcomes. Leadership skills (17.2%) emerged as the strongest single predictor, followed by communication skills (16.1%) and network quality (15.7%)."

### SEM Validation
"The structural equation model showed good overall fit: CFI = 0.996, TLI = 0.994, RMSEA = 0.083 [90% CI: 0.028–0.127], SRMR = 0.030, and composite reliability = 0.865."

### Career Stage Difference
"Student volunteers demonstrated stronger leadership effects (23.3%) compared to professionals (10.4%), whereas professionals showed stronger network-quality effects (21.5% vs. 12.3%)."

### Role Difference
"In non-tech roles, technical skills emerged as the primary predictor (21.7%), whereas in tech roles, leadership skills dominated (18.4%)."

---

## FILES TO REFERENCE

For any future questions, use these source files:

```
output/relative_importance_results.csv     — Main effect sizes
output/subgroup_analysis_results.csv       — Subgroup breakdowns
output/sem_fit_indices.csv                 — SEM model fit
output/paper_claim_check.csv              — Validation report
```

**Do NOT edit these files.** They are generated automatically by the code.

**Do NOT use any values not in this document.**

---

## Validation Status: ✅ VERIFIED

- Exact values extracted from `output/` directory
- Cross-checked against code outputs
- Ready for peer review publication

**Last Updated:** March 25, 2026
**Data:** N=78 (complete cases from 80 total), April–September 2025 survey window

