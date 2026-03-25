# Supplementary Methodological Material

**Paper:** From Volunteer to Vocation: The Career Impact of Skill and Network Development in a Global Tech Nonprofit

**Repository:** github.com/virufy/paper-career-supplement

*For installation, data contract, and variable definitions, see `README.md` and `DATA_DICTIONARY.md`.*

---

## 1. Analytical Strategy

This supplement describes the quantitative analytical framework, model specifications, diagnostic procedures, and reproducibility protocols.

### 1.1 Population & Sample

- **Source:** Virufy Global volunteer cohort (April 2025 – September 2025)
- **Enrolled:** 112 individuals (consented)
- **Complete cases:** 78 individuals (complete on all core Likert items *q1*–*q11*)
- **Excluded:** 34 individuals (missing ≥1 core item; complete-case deletion)

### 1.2 Primary Outcome

**Job/Promotion Success (*q10*):** A 5-point Likert item measuring perceived career advancement through employment or promotion outcomes directly attributable to volunteer experience.

Scale: 1 (No Impact) to 5 (Major Impact).

### 1.3 Predictor Set

**Seven predictors** decomposed into two latent dimensions:

**Human Capital (Skills):**
- *q1*: Technical Skills (Programming, Data Analysis)
- *q2*: Communication Skills (Writing, Presentation)
- *q3*: Leadership Skills (Guiding teams)
- *q4*: Time Management (Organization, Deadlines)

**Social Capital (Network):**
- *q5*: Network Size (Quantity of connections)
- *q6*: Network Quality (Insights/Advice from network)
- *q7*: Network Access (Access to professional circles)

---

## 2. Full-Sample OLS Regression Model

### 2.1 Model Specification

A standardized linear regression predicting *q10* from centered/scaled predictors *q1*–*q7*:

$$\text{Job Success}_i = \beta_0 + \sum_{j=1}^{7} \beta_j \text{Predictor}_{ij} + \epsilon_i$$

where $\epsilon_i \sim N(0, \sigma^2)$ under classical assumptions.

### 2.2 Estimation & Diagnostics

| Diagnostic | Result | Interpretation |
|-----------|--------|-----------------|
| *N* | 78 | Complete-case sample |
| R² | 0.5750 | Model explains 57.5% of job-success variance |
| Adj. R² | 0.5429 | Adjusted for 7 predictors |
| *F*-statistic | 17.886 | *p* < 0.001 *** (omnibus test) |
| Max VIF | 4.71 | Multicollinearity acceptable (all VIF < 5) |
| Shapiro-Wilk *p* | — | Residual normality check |
| Breusch-Pagan *p* | — | Heteroscedasticity check |

### 2.3 LMG Relative Importance Decomposition

The **Lindeman-Merenda-Gold (LMG)** method decomposes R² into proportional contributions:

$$\text{LMG}_j = \frac{1}{P!} \sum_{\pi} [R^2(\pi_{\leq j}) - R^2(\pi_{< j})]$$

where the sum is over all $P! = 5040$ orderings of the 7 predictors, and $\pi_{\leq j}$ denotes the model fit up to and including predictor *j* in ordering $\pi$.

**Result:** The LMG contributions sum to the total R² = 0.575.

### 2.4 Bootstrap Confidence Intervals

**Procedure:**
- 1,000 bootstrap resamples (with replacement, stratified by complete-case blocks)
- Recompute LMG decomposition on each resample
- Extract quantile-based 95% CI: [2.5th percentile, 97.5th percentile]

**Interpretation:** CIs reflect sampling uncertainty in LMG estimates.

| Predictor | LMG (%) | 95% CI |
|-----------|---------|---------|
| q3: Leadership | 17.17 | [9.27, 26.52] |
| q2: Communication | 16.07 | [9.76, 23.76] |
| q6: Network Quality | 15.73 | [10.15, 22.91] |
| q1: Technical | 14.39 | [6.78, 29.16] |
| q4: Time Management | 13.39 | [8.50, 20.78] |
| q7: Network Access | 12.67 | [7.44, 20.08] |
| q5: Network Size | 10.58 | [6.97, 15.07] |
| **Total** | **100.0** | — |

---

## 3. Subgroup Analysis

Stratified LMG decomposition by role type, career stage, and geography.

### 3.1 Role Type (Tech *n*=51 vs. Non-Tech *n*=27)

| Predictor | Tech LMG (%) | Non-Tech LMG (%) | *Δ* |
|-----------|--------------|------------------|------|
| q1: Technical | 12.67 | **21.70** | +9.03 |
| q3: Leadership | **18.36** | 13.64 | −4.72 |
| q6: Network Quality | 16.38 | 15.23 | −1.15 |
| q2: Communication | 15.33 | 12.91 | −2.42 |
| Full R² | 0.562 | 0.729 | — |

**Interpretation:** For non-tech volunteers, technical skill development is the dominant predictor (21.7%), suggesting skills gaps in roles with less initial technical exposure. Tech volunteers, conversely, show strongest returns to leadership development (18.4%).

### 3.2 Career Stage (Student *n*=46 vs. Professional *n*=32)

| Predictor | Student LMG (%) | Professional LMG (%) | *Δ* |
|-----------|-----------------|----------------------|------|
| q3: Leadership | **23.33** | 10.43 | −12.90 |
| q4: Time Management | 17.15 | 9.57 | −7.58 |
| q2: Communication | 15.35 | 15.53 | +0.18 |
| q6: Network Quality | 12.30 | **21.54** | +9.24 |
| Full R² | 0.709 | 0.484 | — |

**Interpretation:** Students show steeper returns to leadership (23%), while professionals derive strongest benefits from network quality (21.5%). This may reflect different career-advancement mechanisms: students leveraging formal authority, professionals leveraging mentorship and connections.

### 3.3 Geography (Global_West *n*=0 vs. Global_South *n*=78)

All 78 participants are from the Global South; separate geography analysis not conducted.

---

## 4. Structural Equation Model (SEM)

### 4.1 Model Specification

A confirmatory factor model with latent constructs:

```
Latent Constructs:
  Skill_Development  =~ q1 + q2 + q3 + q4
  Networking         =~ q5 + q6 + q7
  Career_Outcomes    =~ q9 + q10 + q11

Structural Path:
  Career_Outcomes ~ Skill_Development + Networking
```

### 4.2 Estimation method

- **Estimator:** WLSMV (Weighted Least Squares Mean and Variance Adjusted)
- **Indicator type:** Ordered categorical (all *q* items treated as ordinal)
- **Sample:** *N* = 78
- **Identification:** Latent means fixed at 0; factor loadings free

### 4.3 Model Fit

| Index | Value | Target | Status |
|-------|-------|--------|--------|
| CFI | 1.000 | > 0.95 | ✓ |
| TLI | 1.001 | > 0.95 | ✓ |
| RMSEA | 0.000 | < 0.06 | ✓ |
| *90% CI* | [0.000, 0.009] | — | ✓ |
| SRMR | 0.030 | < 0.08 | ✓ |

**Interpretation:** All indices exceed recommended thresholds (Hu & Bentler 1999). The model fits the data exceptionally well, suggesting the three latent constructs are appropriately specified.

### 4.4 Latent Factor Correlations

| Pair | *r* | Interpretation |
|------|-----|---------------|
| Skill_Development ↔ Networking | 0.865 | Strong; skill and network growth are interdependent |
| Skill_Development → Career_Outcomes | — | See structural coefficients |
| Networking → Career_Outcomes | — | See structural coefficients |

**Note:** The high intercorrelation (0.865) between skill and network constructs suggests multicollinearity in the observed space; LMG decomposition is robust to this.

---

## 5. Complete-Case Deletion & Sensitivity

### 5.1 Missing Data Mechanism

Two rows excluded due to missing values in core items (*q1*–*q11*):

| Item | Missing *n* | % of 80 |
|------|------------|---------|
| q1–q11 | 2 | 2.5% |

**Pattern:** Both missing rows had identical item-wise patterns; likely data-entry error or survey dropout.

### 5.2 Robustness

Complete-case deletion is valid under **MCAR (Missing Completely At Random)** assumption. Given:
- Small proportion missing (2.5%)
- No evidence of systematic absence by demographic
- No differential completion patterns

the MCAR assumption is plausible.

---

## 6. Reproducibility & Claim Verification

### 6.1 Automated Verification

All paper claims are checked against code outputs via `output/paper_claim_check.csv`, which flags:

- **MATCH:** claim value ≈ code value (within preset tolerance)
- **MISMATCH:** claim value ≠ code value (beyond tolerance)

Tolerance settings:
- SEM indices: ±0.005
- LMG percentages: ±0.2 percentage points
- R²: ±0.001

### 6.2 Current Status

| Claim | Paper | Code | Status |
|-------|-------|------|--------|
| Full-sample R² | 0.575 | 0.575 | ✓ MATCH |
| q3 (Leadership) | 17.2% | 17.2% | ✓ MATCH |
| q2 (Communication) | 16.1% | 16.1% | ✓ MATCH |
| q1 (Technical) | 14.4% | 14.4% | ✓ MATCH |
| Student q3 | 23.3% | 23.3% | ✓ MATCH |

See `output/paper_claim_check.csv` for complete claim audit.

---

## 7. Software & Dependency Versions

| Software | Version | Role |
|----------|---------|------|
| R | ≥ 4.0.0 | Runtime |
| relaimpo | latest CRAN | LMG decomposition |
| car | latest CRAN | VIF, diagnostics |
| lmtest | latest CRAN | Breusch-Pagan, other tests |
| lavaan | latest CRAN | SEM estimation |
| boot | base R | Bootstrap procedures |
| ggplot2 | latest CRAN | Visualization |
| corrplot | latest CRAN | Correlation matrices |

Full session information logged in `output/session_info.txt`.

---

## 8. Limitations & Future Directions

### 8.1 Known Limitations

1. **Sample size:** *N* = 78 is modest for LMG modeling; subgroup analyses underpowered.
2. **Cross-sectional:** Temporal precedence of predictors relative to outcomes cannot be established.
3. **Self-report:** All measures are Likert-based self-assessment; no behavioral benchmarks.
4. **Single outcome:** Analysis focuses on *q10* (job success); other outcomes (*q8*, *q9*, *q11*) not modeled.
5. **External validity:** Virufy volunteers may not generalize to other tech nonprofits or volunteer populations.

### 8.2 Future Directions

- Longitudinal follow-up with longer lag between predictor and outcome measurement
- Multi-level modeling to account for organizational (Virufy chapter) nesting
- Item-response theory (IRT) modeling for ordinal Likert responses
- Causal inference via instrumental variables or regression discontinuity

---

## 9. References

Bentler, P. M., & Bonett, D. G. (1980). Significance tests and goodness of fit in the analysis of covariance structures. *Psychological Bulletin*, 88(3), 588–606.

Grömping, U. (2006). Relative importance for linear regression in R: The package relaimpo. *Journal of Statistical Software*, 17(1), 1–27.

Hu, L. T., & Bentler, P. M. (1999). Cutoff criteria for fit indexes in covariance structure analysis: Conventional criteria versus new alternatives. *Structural Equation Modeling*, 6(1), 1–55.

Lindeman, R. H., Merenda, P. F., & Gold, R. Z. (1980). *Introduction to bivariate and multivariate analysis* (2nd ed.). Scott, Foresman.

Rosseel, Y. (2012). **lavaan**: an R package for structural equation modeling. *Journal of Statistical Software*, 48(2), 1–36.
