# Submission Audit Report
**Paper:** From Volunteer to Vocation — Career Impact of Skill and Network Development in a Global Tech Nonprofit  
**Target journal (current branch):** International Journal of Training and Development (IJTD)  
**Branch audited:** `submission-jme-2026` + `master`  
**Audit date:** 2026-04-23  

---

## Verdict: NO-GO — 3 Blocking Issues

The manuscript is substantively strong and methodologically rigorous, but three issues must be resolved before any submission.

---

## BLOCKING ISSUES

### 1. RMSEA mismatch — manuscript cites a better fit than code produces

**`paper_claim_check.csv` (master, run 2026-04-09):**

| Claim | Paper value | Code value | Tolerance | Status |
|-------|------------|-----------|-----------|--------|
| SEM_RMSEA | 0.083 | **0.097** | 0.005 | **MISMATCH** |
| SEM_CFI | 0.996 | 0.994 | 0.005 | MATCH (marginal) |

The manuscript currently reports RMSEA = 0.083. The code produces RMSEA = 0.097.  
RMSEA = 0.097 is above even borderline-acceptable thresholds (Hu & Bentler 1999 cutoff: < 0.06; common lenient threshold: < 0.10).

**Required fix:**
- Update manuscript SEM table to RMSEA = 0.097, CI [0.028, 0.127]
- Update CFI to match code output (0.994 or 0.996 — re-run and lock values)
- Revise fit interpretation: "CFI/TLI/SRMR indicate good fit; RMSEA is borderline/elevated (0.097) — overall fit is acceptable but mixed"
- Do **not** describe fit as "good" or "excellent" without qualification

---

### 2. Nine visible placeholder strings remain in manuscript

In `paper/Paper - Vector - IJTD - Manuscript.docx`, the following text strings are still present as visible body text:

- `[Insert Table 1 about here]` — Section 3.2
- `[Insert Figure 1 about here]` — Section 4.1
- `[Insert Figure 2 about here]` — Section 4.1
- `[Insert Table 2 about here]` — Section 4.2
- `[Insert Figure 3 about here]` — Section 4.2
- `[Insert Figure 4 about here]` — Section 4.3
- `[Insert Table 3 about here]` — Section 4.3
- `[Insert Table 4 about here]` — Section 4.4
- `[Insert Table 5 about here]` — Section 4.5

The figures/tables themselves **are** embedded in the .docx. These are stray instruction strings that must be deleted before upload.

**Required fix:** Open manuscript in Word, Find & Replace (or delete) each `[Insert … about here]` string.

---

### 3. Data file path inconsistency

`README.md`, `run_analysis.R`, and `SUPPLEMENT.md` all document the data path as `input/vector_survey_responses.csv`, but the actual file lives at the project root.

Reviewers running the reproducibility package will hit a "file not found" error.

**Required fix (pick one):**
- Move `vector_survey_responses.csv` → `input/vector_survey_responses.csv`, or
- Update the path in `run_analysis.R` line ~15 and both documentation files

---

## MINOR ISSUES (should address, not blocking)

### 4. Running title missing or over-length
IJTD requires a running title ≤ 40 characters. The current title is 81 characters. No running title field is set on the title page.  
**Suggested:** "Skill-Based Volunteering & Career Impact" (40 chars)

### 5. Acknowledgments section
IJTD style expects an Acknowledgments section in the manuscript body (before References), even if brief. Currently only the title page has declarations.

### 6. Author anonymity risk
The first author is identified as founder/president of the studied organization, and the paper names "Virufy" throughout. IJTD uses double-blind review. Consider whether this needs a separate anonymized submission copy.

---

## WHAT IS VERIFIED GOOD

### All 15 other claims: MATCH

| Claim | Paper | Code | Status |
|-------|-------|------|--------|
| Full-sample R² | 0.575 | 0.575 | ✓ |
| q3 Leadership | 17.2% | 17.167% | ✓ |
| q2 Communication | 16.1% | 16.068% | ✓ |
| q1 Technical | 14.4% | 14.388% | ✓ |
| q4 Time Mgmt | 13.4% | 13.394% | ✓ |
| q5 Network Size | 10.6% | 10.583% | ✓ |
| q6 Network Quality | 15.7% | 15.729% | ✓ |
| q7 Network Access | 12.7% | 12.672% | ✓ |
| Tech q3 | 18.4% | 18.359% | ✓ |
| Tech q6 | 16.4% | 16.381% | ✓ |
| Non-Tech q1 | 21.7% | 21.697% | ✓ |
| Student q3 | 23.3% | 23.327% | ✓ |
| Prof q6 | 21.5% | 21.535% | ✓ |
| HC-SC composite r | 0.865 | 0.865 | ✓ |

### Manuscript completeness: all present
- Abstract (191 words), 6 keywords
- Introduction, literature review, methodology, results, discussion, limitations (7), conclusion
- 30 complete, DOI-linked references
- Appendix A (survey instrument), Appendix B (thematic codebook)
- All figures (4 PNGs, 2048px) and tables (5) embedded in .docx
- All declarations on title page (IRB, consent, competing interests, AI use, ORCID, CRediT)
- Participant flow: 80 input → 78 complete-case (2 excluded)

### Reproducibility package: verified (with path fix)
- `run_analysis.R` produces all 18 outputs successfully
- Bootstrap CIs, SEM, LMG, subgroup analyses all reproducible
- Example dataset included in `statistical_appendix/`

---

## Fix checklist before next submission

- [ ] Re-run `run_analysis.R`, capture fresh `sem_fit_indices.csv`
- [ ] Update SEM table in manuscript with RMSEA = 0.097 (or confirmed value from fresh run)
- [ ] Update SEM fit narrative to "mixed/borderline" language
- [ ] Remove all 9 `[Insert … about here]` strings from manuscript .docx
- [ ] Fix data file path: move CSV to `input/` or update scripts
- [ ] Add running title ≤ 40 characters to title page
- [ ] Add brief Acknowledgments section before References
- [ ] Re-run `paper_claim_check.csv` — confirm 0 MISMATCHes before upload
