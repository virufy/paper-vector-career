# Muskaan's Paper Discrepancies Report
## Code Validation vs. Paper Claims - March 25, 2026

**Analysis Date:** March 25, 2026
**Validation Run:** GitHub repository `paper-career-supplement` (master branch)
**Sample:** N = 78 (complete cases)

---

## Executive Summary

**CRITICAL ISSUES: 7 out of 17 claims are INCORRECT in the paper**

- ❌ **3 CRITICAL ERRORS** - SEM model fit indices (CFI, RMSEA, Composite R)
- ❌ **2 MAJOR ERRORS** - Subgroup effect sizes (Non-Tech q1, Tech q6)
- ❌ **2 MINOR ERRORS** - Main effect sizes (q5, q7) — out of tolerance

---

## Issue #1: SEM Model Fit Indices (CRITICAL)

### The Error

Muskaan reported **incorrect SEM fit statistics** in the paper:

| Index | Paper Value (WRONG) | Code Value (CORRECT) | Error Magnitude | Issue |
|-------|-------------------|-------------------|-----------------|-------|
| **CFI** | 0.976 | 0.996 | +0.020 | Wrong by 2% |
| **RMSEA** | 0.038 | 0.083 | +0.045 | Wrong by 45%! |
| **Composite R** | 0.94 | 0.865 | -0.075 | Wrong by 8.7% |

### Impact

These are **foundational validity claims**. Peer reviewers will immediately catch that:
- **CFI**: You claimed 0.976 (good fit) but actual is 0.996 (excellent)
- **RMSEA**: You claimed 0.038 (excellent) but actual is 0.083 (acceptable)
- **Composite R**: You claimed 0.94 but actual is 0.865

The RMSEA error is especially problematic — you reported a value that's **half the actual magnitude**.

### Root Cause

Muskaan likely:
1. Ran SEM in a **different tool/package** (e.g., Python lavaan port)
2. **Didn't validate outputs** against the authoritative R script
3. Used **old cached results** from earlier analysis attempts

### What Needs Fixing

```
Line X, Table Y: SEM Fit Indices
BEFORE (WRONG):
  CFI = 0.976, RMSEA = 0.038, Composite R = 0.94

AFTER (CORRECT):
  CFI = 0.996, RMSEA = 0.083, Composite R = 0.865
```

---

## Issue #2: Main Effect Size — Network Size (q5) [MINOR]

### The Error

| Predictor | Paper Value | Code Value | Difference | Status |
|-----------|-------------|-----------|-----------|--------|
| q5 (Network Size) | 11.0% | 10.583% | -0.417% | OUT OF TOLERANCE |

### Impact

- **Tolerance:** ±0.2%
- **Mismatch:** 0.417% exceeds tolerance
- This is the 7th-ranked predictor; minor but noticeable

### Root Cause

Muskaan likely **hand-rounded** the value instead of using exact code output.

### What Needs Fixing

Table 2 or results section:
```
BEFORE: q5 Network Size = 11.0%
AFTER:  q5 Network Size = 10.6% (or 10.583% with precision)
```

---

## Issue #3: Main Effect Size — Network Access (q7) [MINOR]

### The Error

| Predictor | Paper Value | Code Value | Difference | Status |
|-----------|-------------|-----------|-----------|--------|
| q7 (Network Access) | 12.2% | 12.672% | +0.472% | OUT OF TOLERANCE |

### Impact

- **Tolerance:** ±0.2%
- **Mismatch:** 0.472% exceeds tolerance by 136%
- 6th-ranked predictor; should match code exactly

### Root Cause

**Hand-rounding error.** The value 12.672% was rounded DOWN to 12.2%, losing precision.

### What Needs Fixing

Table 2:
```
BEFORE: q7 Network Access = 12.2%
AFTER:  q7 Network Access = 12.7% (rounded to 1 decimal)
```

---

## Issue #4: Subgroup Effect — Non-Tech q1 (MAJOR)

### The Error

| Group | Variable | Paper Value | Code Value | Difference | Severity |
|-------|----------|------------|-----------|-----------|----------|
| Non-Tech Roles | q1 (Technical Skills) | **25.2%** | **21.697%** | -3.5% | **MAJOR** |
| Sample | N=27 | — | Confirmed N=27 | — | — |

### Impact

- **This is a 13.8% underestimation** of the actual code value
- You **overstated** the importance of technical skills in non-tech roles
- This is the **#1 predictor in the Non-Tech subgroup** — high visibility error
- Peer reviewers will question your claim

### Root Cause

Muskaan likely:
1. **Used the wrong subgroup filtering logic** (e.g., filtered by a different categorical variable)
2. **Ran analysis on a subset with deleted/missing rows** (affecting sample composition)
3. **Used cached results from an older analysis** that had different data

### What Needs Fixing

Table X (Subgroup Results - Non-Tech):
```
BEFORE: Technical Skills (q1) = 25.2%
AFTER:  Technical Skills (q1) = 21.7%
```

---

## Issue #5: Subgroup Effect — Tech q6 (MAJOR)

### The Error

| Group | Variable | Paper Value | Code Value | Difference | Severity |
|-------|----------|------------|-----------|-----------|----------|
| Tech Roles | q6 (Network Quality) | **16.9%** | **16.381%** | -0.519% | Marginal but out of tolerance |
| Sample | N=51 | — | Confirmed N=51 | — | — |

### Impact

- Out of tolerance by 159%
- This is the #2 predictor in the Tech subgroup
- Smaller error magnitude than Issue #4, but still problematic

### Root Cause

Same as Issue #4: likely **subgroup filtering logic error** or **wrong data subset**.

### What Needs Fixing

Table X (Subgroup Results - Tech):
```
BEFORE: Network Quality (q6) = 16.9%
AFTER:  Network Quality (q6) = 16.4% (or 16.381% with precision)
```

---

## Issue #6: Student Subgroup — q3 [MINOR - NOW CORRECT ✓]

### Status: FIXED

| Group | Variable | Paper Value | Code Value | Status |
|-------|----------|------------|-----------|--------|
| Student | q3 (Leadership) | 23.3% | 23.327% | **MATCH** ✓ |

**No action needed** — This was corrected and now matches the code.

---

## Issue #7: Professional Subgroup — q6 [CORRECT ✓]

### Status: FIXED

| Group | Variable | Paper Value | Code Value | Status |
|-------|----------|------------|-----------|--------|
| Professional | q6 (Network Quality) | 21.5% | 21.535% | **MATCH** ✓ |

**No action needed** — This matches the code output.

---

## Summary of Required Corrections

### CRITICAL (Fix immediately):
1. ❌ **SEM CFI:** 0.976 → 0.996
2. ❌ **SEM RMSEA:** 0.038 → 0.083
3. ❌ **SEM Composite R:** 0.94 → 0.865
4. ❌ **Non-Tech q1:** 25.2% → 21.7%
5. ❌ **Tech q6:** 16.9% → 16.4%

### MINOR (Fix for precision):
6. ⚠️ **q5 (Main):** 11.0% → 10.6%
7. ⚠️ **q7 (Main):** 12.2% → 12.7%

---

## Validation Summary

| Category | Result | Count |
|----------|--------|-------|
| **Correct Claims** | ✓ MATCH | 10/17 |
| **Incorrect Claims** | ❌ MISMATCH | 7/17 |
| **Accuracy Rate** | — | **58.8%** |

### Correct Claims (Do NOT change):
- Full sample R² = 0.575 ✓
- q1 (Main) = 14.4% ✓
- q2 (Main) = 16.1% ✓
- q3 (Main) = 17.2% ✓
- q4 (Main) = 13.4% ✓
- q6 (Main) = 15.7% ✓
- Tech q3 = 18.4% ✓
- Student q3 = 23.3% ✓
- Professional q6 = 21.5% ✓
- All Main Results (Top 3) ✓

---

## How This Happened

Based on the email thread and Muskaan's workflow:

1. **Muskaan ran analysis in Google Colab** (not in the GitHub repo environment)
2. **She may have used an older/different data file** or filtering logic
3. **SEM results were pulled from a Python implementation** (not the authoritative R code)
4. **No cross-validation** against `paper_claim_check.csv` automated validation
5. **Rounding inconsistencies** introduced when transcribing results to paper

---

## How to Prevent This

1. **Always run `paper_claim_check.csv`** after any analysis update
2. **Use the GitHub repo as source of truth** — not Colab notebooks
3. **Never hand-transcribe results** — use automated export scripts
4. **Validate against code outputs** before submitting to paper

---

## Recommendations

### Immediate Actions:
1. ✅ Correct all 7 discrepancies in the paper
2. ✅ Re-run `run_all_analyses.R` to generate fresh outputs
3. ✅ Cross-check `output/paper_claim_check.csv` for 100% match
4. ✅ Update paper with corrected values
5. ✅ Commit corrected paper to repo

### Before Submission:
- Run validation suite one final time
- Have peer reviewer compare paper claims to `paper_claim_check.csv`
- Ensure all outputs are reproducible in repo

---

**Report Generated:** March 25, 2026
**Status:** REQUIRES IMMEDIATE CORRECTION
**Estimated Fix Time:** 30-45 minutes

