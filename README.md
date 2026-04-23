# Reproducibility Package

**Paper:** From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit  
**Authors:** Amil Khanzada  
**Journal:** International Journal of Training and Development (submitted)

See [RESULTS.md](RESULTS.md) for pre-generated output showing all reproduced paper claims.

---

## Reproduce in 2 steps

```bash
Rscript install_dependencies.R
Rscript run_analysis.R
```

Generates `RESULTS.md` with full claim verification, LMG importance table, SEM fit indices, and model diagnostics.

**R 4.0+ required.** Runtime ~2–5 minutes (1,000 bootstrap iterations).

---

## Data

`vector_survey_responses_anonymized.csv` — N = 78 complete-case responses from Virufy volunteers. Organization and author names anonymized. All other data unchanged.

### Predictors (q1–q7, 5-point Likert)

| Variable | Label |
| -------- | ----- |
| q1 | Technical Skills (Programming, Data Analysis) |
| q2 | Communication Skills (Writing, Presentation) |
| q3 | Leadership Skills (Guiding teams) |
| q4 | Time Management (Organization, Deadlines) |
| q5 | Network Size (Quantity of connections) |
| q6 | Network Quality (Insights/Advice from network) |
| q7 | Network Access (Access to professional circles) |

### Outcome (q10)

**Job/Promotion Success** — 5-point Likert (1 = No Impact → 5 = Major Impact). Primary outcome variable for all models.

### Additional survey items

q8: Overall Career Impact · q9: Resume Competitiveness · q11: Leadership Role Advancement  
Used as SEM outcome indicators; not used in primary LMG regression.

### Demographics (derived from free-text)

| Column | Values | Derivation |
| ------ | ------ | ---------- |
| role_type | Tech / Non-Tech | Keywords: Developer, ML, Data Scientist, Engineer → Tech |
| career_stage | Student / Professional | Keywords: student, undergraduate, master, doctoral → Student |
| geography | Global_West / Global_South | USA, UK, Canada, Japan, Australia, Singapore → Global_West |

---

## Files

| File | Purpose |
| ---- | ------- |
| `run_analysis.R` | Full pipeline: LMG, SEM, subgroup analysis, claim verification |
| `install_dependencies.R` | Installs required R packages |
| `vector_survey_responses_anonymized.csv` | Survey data (N = 78) |
| `RESULTS.md` | Pre-generated reproducibility output |
| `SUPPLEMENT.md` | Detailed methods and analytical specifications |
