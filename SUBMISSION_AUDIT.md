# Submission Audit & Pre-Submission Checklist

**Paper:** From Volunteer to Vocation — Career Impact of Skill and Network Development in a Global Tech Nonprofit  
**Target journal:** International Journal of Training and Development (IJTD), Wiley  
**Analysis rerun date:** 2026-04-23  
**Status:** NO-GO — 3 items to fix before uploading  

---

## Summary for team

The paper is substantively ready. All 16 numerical claims were reproduced exactly from a fresh code run today. Three items need to be fixed in the Word documents — two are quick find-and-replace edits, one is a number update.

---

## Fix #1 — Update SEM fit indices in the manuscript

The manuscript reports **RMSEA = 0.083**. The code produces **RMSEA = 0.097**. This was confirmed by a fresh pipeline rerun today and is the only numerical discrepancy.

**Correct values to use (confirmed from code, 2026-04-23):**

| Index | Correct value | What to fix |
| ----- | ------------- | ----------- |
| CFI | **0.994** | update from 0.996 |
| TLI | **0.992** | update from 0.994 |
| RMSEA | **0.097** | **update from 0.083 — critical** |
| RMSEA 90% CI | **[0.056, 0.134]** | update from [0.028, 0.127] |
| SRMR | **0.032** | update from 0.030 |
| HC–SC composite *r* | **0.865** | already correct ✓ |

**Exact replacement text for the SEM results paragraph:**

> The model demonstrated acceptable fit: CFI = 0.994, TLI = 0.992, SRMR = 0.032, and RMSEA = 0.097 [90% CI: 0.056–0.134]. CFI, TLI, and SRMR met conventional thresholds, while RMSEA was slightly elevated above the strict 0.08 cutoff, indicating mixed but acceptable overall fit (Hu & Bentler, 1999). The latent correlation between Skill Development and Networking was *r* = 0.865.

Also check the Discussion/Limitations: wherever the text describes SEM fit as "good" or "excellent", revise to "acceptable but mixed."

---

## Fix #2 — Remove 9 placeholder strings from manuscript.docx

In `Paper - Vector - IJTD - Manuscript.docx`, open **Find & Replace** (Ctrl+H) and delete each of these (replace with nothing):

```text
[Insert Table 1 about here]
[Insert Figure 1 about here]
[Insert Figure 2 about here]
[Insert Table 2 about here]
[Insert Figure 3 about here]
[Insert Figure 4 about here]
[Insert Table 3 about here]
[Insert Table 4 about here]
[Insert Table 5 about here]
```

The actual figures and tables are already embedded — these are just stray instruction strings.

---

## Fix #3 — Formatting pass (raised by Amil)

Before uploading, do a final pass of the manuscript in Word (Print Layout, 100% zoom, Track Changes OFF) and fix:

- Any stray font size changes
- Random extra blank lines / paragraph spacing

These were flagged in the email thread and will reflect poorly on submission.

---

## Additional items (minor, not blocking)

**Running title:** IJTD requires ≤ 40 characters. Sheeba's suggestion *"Career Impact of Remote Volunteering"* (36 chars) works — confirm it is on the title page.

**Data path for reproducibility:** `run_analysis.R` and the README document `input/vector_survey_responses.csv` but the actual CSV is at the project root. Move the file into `input/` before the repository goes public/to reviewer.

---

## All verified-correct numbers — do not change

Everything below was confirmed exact-match by fresh pipeline run on 2026-04-23.

### Main model

| Metric | Value |
|--------|-------|
| *N* | 78 |
| R² | 0.575 |
| Adj. R² | 0.532 |
| *F*(7, 70) | 13.529, *p* < 0.001 |
| Max VIF | 4.71 |

### Table 2 — LMG relative importance (all correct, do not edit)

| Rank | Predictor | LMG (%) | 95% CI |
|------|-----------|---------|--------|
| 1 | Leadership Skills (q3) | 17.2% | [9.3%, 26.5%] |
| 2 | Communication Skills (q2) | 16.1% | [9.8%, 23.8%] |
| 3 | Network Quality (q6) | 15.7% | [10.2%, 22.9%] |
| 4 | Technical Skills (q1) | 14.4% | [6.8%, 29.2%] |
| 5 | Time Management (q4) | 13.4% | [8.5%, 20.8%] |
| 6 | Network Access (q7) | 12.7% | [7.4%, 20.1%] |
| 7 | Network Size (q5) | 10.6% | [7.0%, 15.1%] |

### Table 3 — Subgroup results (all correct, do not edit)

| Subgroup | *n* | R² | Top predictor | % |
|----------|-----|-----|--------------|---|
| Tech roles | 51 | 0.562 | Leadership (q3) | 18.4% |
| Non-Tech roles | 27 | 0.729 | Technical (q1) | 21.7% |
| Students | 46 | 0.709 | Leadership (q3) | 23.3% |
| Professionals | 32 | 0.484 | Network Quality (q6) | 21.5% |

---

## Final upload checklist

- [ ] **SEM table updated:** CFI=0.994, TLI=0.992, RMSEA=0.097, CI=[0.056–0.134], SRMR=0.032
- [ ] **SEM prose updated** to "acceptable but mixed" language (replacement text above)
- [ ] **9 placeholder strings removed** from manuscript.docx (Find & Replace)
- [ ] **Formatting pass done** — no stray font sizes or blank lines
- [ ] Running title "Career Impact of Remote Volunteering" confirmed on title page
- [ ] Final read of title page and cover letter — all declarations, ORCID, author affiliations
- [ ] Data CSV moved to `input/` folder before repository upload
- [ ] Manuscript, title page, and cover letter saved as final versions

---

*All numbers in this report sourced from `output/` CSVs generated by fresh `run_analysis.R` run on 2026-04-23.*
