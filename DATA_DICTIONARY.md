# Data Dictionary

Comprehensive mapping of input data columns to analysis variables for Project VECTOR.

---

## Survey Response CSV (`vector_survey_responses.csv`)

Input format: CSV with participant consent, demographics, and Likert-scale responses.

| Column # | Field (if available) | Pipeline Variable | Type | Valid Range | Description |
|----------|---------------------|------------------|------|-------------|-------------|
| 1 | Consent | `consent` | String | "Yes"/"No" | Informed consent indicator |
| 2 | Timestamp | `response_date` | Datetime | ISO 8601 | Survey completion date/time |
| 3 | (Preserved as-is) | – | String | – | Participant consent verbatim |
| 4 | Career Stage | `career_stage` | String | "Student"/"Professional" | Derived from keywords: "student", "undergraduate", "master", "doctoral", "phd" → "Student"; else → "Professional" |
| 5 | Country | `geography` | String | "Global_West"/"Global_South" | Derived from keywords: "USA", "UK", "Canada", "Japan", "Australia", "Singapore" → "Global_West"; else → "Global_South" |
| 6 | Role/Title | `role_type` | String | "Tech"/"Non-Tech" | Derived from keywords: "Developer", "App Dev", "Web Dev", "ML Engineering", "Data Scientist", "Cloud", "IT", "Engineer" → "Tech"; else → "Non-Tech" |
| **7** | (Skip) | – | – | – | (Reserved/unused) |
| **8** | Likert 1 | `q1` | Integer | 1–5 | Technical Skills (Programming, Data Analysis) |
| **9** | Likert 2 | `q2` | Integer | 1–5 | Communication Skills (Writing, Presentation) |
| **10** | Likert 3 | `q3` | Integer | 1–5 | Leadership Skills (Guiding teams) |
| **11** | Likert 4 | `q4` | Integer | 1–5 | Time Management (Organization, Deadlines) |
| **12** | Likert 5 | `q5` | Integer | 1–5 | Network Size (Quantity of connections) |
| **13** | Likert 6 | `q6` | Integer | 1–5 | Network Quality (Insights/Advice from network) |
| **14** | Likert 7 | `q7` | Integer | 1–5 | Network Access (Access to professional circles) |
| **15** | Likert 8 | `q8` | Integer | 1–5 | Overall Career Impact |
| **16** | Likert 9 | `q9` | Integer | 1–5 | Resume Competitiveness |
| **17** | Likert 10 | `q10` | Integer | 1–5 | **Job/Promotion Success** (PRIMARY OUTCOME) |
| **18** | Likert 11 | `q11` | Integer | 1–5 | Leadership Role Advancement |

### Likert Scale Definition

All Likert items use a standard 5-point scale:

| Score | Interpretation |
|-------|-----------------|
| 1 | Strongly Disagree / No Impact |
| 2 | Disagree / Minimal Impact |
| 3 | Neutral / Moderate Impact |
| 4 | Agree / Significant Impact |
| 5 | Strongly Agree / Major Impact |

---

## Engineered Features

Features created during data preparation for analysis models.

### Scale & Standardization

| Feature | Source | Transform | Purpose |
|---------|--------|-----------|---------|
| `q1_scaled` | q1 | `scale(q1)` | Standardization for LMG regression (mean=0, sd=1) |
| `q2_scaled` | q2 | `scale(q2)` | — |
| ... `q11_scaled` | q11 | `scale(q11)` | — |

### Composite Measures

| Feature | Definition | Range | Description |
|---------|-----------|-------|-------------|
| `hc_composite` | `mean(c(q1,q2,q3,q4))` | 1–5 | Human Capital (Skills) composite score |
| `sc_composite` | `mean(c(q5,q6,q7))` | 1–5 | Social Capital (Network) composite score |

### Demographic Indicators

| Feature | Source | Type | Values | Description |
|---------|--------|------|--------|-------------|
| `role_type` | Column 6 | Factor | "Tech", "Non-Tech" | Job role classification |
| `career_stage` | Column 4 | Factor | "Student", "Professional" | Career phase |
| `geography` | Column 5 | Factor | "Global_West", "Global_South" | Geographic region |

---

## Missing Data & Handling

### Exclusion Logic

**Primary Analysis:** Complete-case deletion on columns 8–18 (*q1*–*q11*).

- Rows with ≥1 missing value in *q1*–*q11* → **Excluded**
- Rows with all *q1*–*q11* values present → **Included**

### Reporting

Missing data is tracked and reported in:
- `output/core_item_missingness.csv` — per-item missing count and %
- `output/participant_flow.csv` — excluded vs. included counts

---

## Output Data Files

### Analysis Results

All outputs are comma-separated CSV unless noted otherwise.

#### `relative_importance_results.csv`

Full-sample LMG importance decomposition.

| Column | Type | Description |
|--------|------|-------------|
| `variable` | String | Predictor name (q1–q7) |
| `lmg_pct` | Float | LMG contribution to R² (%) |
| `ci_lower` | Float | 95% bootstrap CI lower bound (%) |
| `ci_upper` | Float | 95% bootstrap CI upper bound (%) |
| `description` | String | Human-readable variable label |

#### `subgroup_analysis_results.csv`

LMG decomposition by demographic subgroup.

| Column | Type | Description |
|--------|------|-------------|
| `variable` | String | Predictor name (q1–q7) |
| `contribution_pct` | Float | LMG contribution (%) for this subgroup |
| `group` | String | Subgroup label (e.g., "Role: Tech", "Stage: Student") |
| `n` | Integer | Sample size for this subgroup |
| `r_squared` | Float | R² for this subgroup model |

#### `full_model_diagnostics.csv`

OLS model diagnostics for main effects.

| Column | Type | Description |
|--------|------|-------------|
| `metric` | String | Diagnostic name |
| `value` | Float | Diagnostic value |

Common metrics:
- `n`: sample size
- `r_squared`: Model R²
- `adj_r_squared`: Adjusted R²
- `f_statistic`: F-statistic
- `f_p_value`: F-test *p*-value
- `max_vif`: Maximum VIF across predictors
- `shapiro_p`: Shapiro-Wilk normality test *p*-value
- `breusch_pagan_p`: Breusch-Pagan heteroscedasticity test *p*-value

#### `sem_fit_indices.csv`

Structural Equation Model fit metrics.

| Column | Type | Description |
|--------|------|-------------|
| `index` | String | Fit index name |
| `value` | Float | Index value |

Standard indices:
- `CFI`: Comparative Fit Index (target > 0.95)
- `TLI`: Tucker-Lewis Index (target > 0.95)
- `RMSEA`: Root Mean Square Error of Approximation (target < 0.06)
- `SRMR`: Standardized Root Mean Square Residual (target < 0.08)
- `HC_SC_COMPOSITE_R`: Correlation between Human Capital and Social Capital composites
- `N`: Sample size

#### `correlation_matrix.csv`

Spearman correlation matrix all 11 Likert variables.

Row/column order: q1, q2, q3, q4, q5, q6, q7, q8, q9, q10, q11.

#### `paper_claim_check.csv`

Automated verification of paper claims against reproducible outputs.

| Column | Type | Description |
|--------|------|-------------|
| `claim` | String | Claim identifier (e.g., "TABLE2_Q3") |
| `paper_value` | Float | Value reported in paper |
| `code_value` | Float | Value reproduced from code |
| `tolerance` | Float | Acceptable absolute difference |
| `status` | String | "MATCH" if \|paper_value - code_value\| ≤ tolerance; else "MISMATCH" |

#### `participant_flow.csv`

Flowchart of participant inclusion/exclusion.

| Column | Type | Description |
|--------|------|-------------|
| `stage` | String | Stage label ("input_rows", "complete_core_likert", "excluded_core_missing") |
| `n` | Integer | Count at this stage |

#### `data_audit_summary.csv`

Summary metrics for data quality audit.

| Column | Type | Description |
|--------|------|-------------|
| `metric` | String | Audit metric name |
| `value` | Integer | Metric value |

Metrics:
- `rows_in_input_csv`: Total input rows
- `rows_with_complete_core_likert_items`: Rows passing complete-case filter
- `rows_excluded_due_to_core_missingness`: Excluded rows

---

## Variable Labels & Categories

### Skill Predictors (*q1–q4*)

| Variable | Category | Full Label |
|----------|----------|-----------|
| q1 | Skills | Technical Skills (Programming, Data Analysis) |
| q2 | Skills | Communication Skills (Writing, Presentation) |
| q3 | Skills | Leadership Skills (Guiding teams) |
| q4 | Skills | Time Management (Organization, Deadlines) |

### Network Predictors (*q5–q7*)

| Variable | Category | Full Label |
|----------|----------|-----------|
| q5 | Network | Network Size (Quantity of connections) |
| q6 | Network | Network Quality (Insights/Advice from network) |
| q7 | Network | Network Access (Access to professional circles) |

### Outcome Indicators (*q8–q11*)

| Variable | Category | Full Label | Primary? |
|----------|----------|-----------|-----------|
| q8 | Outcomes | Overall Career Impact | — |
| q9 | Outcomes | Resume Competitiveness | — |
| q10 | Outcomes | Job/Promotion Success | ⭐ YES |
| q11 | Outcomes | Leadership Role Advancement | — |

---

## Cohort Composition (*N* = 78)

### By Role Type

| Role | *n* | % |
|------|-----|-----|
| Tech | 51 | 65.4% |
| Non-Tech | 27 | 34.6% |

### By Career Stage

| Stage | *n* | % |
|-------|-----|-----|
| Student | 46 | 59.0% |
| Professional | 32 | 41.0% |

### By Geography

| Region | *n* | % |
|--------|-----|-----|
| Global_West | 0 | 0.0% |
| Global_South | 78 | 100.0% |

*Note: All participants are from the Global South region in this cohort.*

---

## References for Interpretation

### Variable Selection

- **Primary outcome** (*q10*) selected a priori as most relevant to career trajectory and employment outcomes.
- **Predictors** (*q1–q7*) selected as theoretically relevant skill and network constructs.
- **Outcomes control variables** (*q8, q9, q11*) included for robustness but not used in primary LMG models.

### LMG Methodology

Lindeman, R. H., Merenda, P. F., & Gold, R. Z. (1980). *Introduction to Bivariate and Multivariate Analysis*. 2nd ed. Scott, Foresman.

Grömping, U. (2006). Relative Importance for Linear Regression in R: The Package relaimpo. *Journal of Statistical Software*, 17(1), 1–27.

### SEM References

Bentler, P. M., & Bonett, D. G. (1980). Significance tests and goodness of fit in the analysis of covariance structures. *Psychological Bulletin*, 88(3), 588–606.

Hu, L. T., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis: Conventional criteria versus new alternatives. *Structural Equation Modeling*, 6(1), 1–55.

Rosseel, Y. (2012). lavaan: An R package for structural equation modeling. *Journal of Statistical Software*, 48(2), 1–36.
