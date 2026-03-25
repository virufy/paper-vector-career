# Statistical Appendix: Quick Reproducible Example

This folder contains a lightweight, fast reproducible example of the core analysis from the paper.

## Quick Start

If you just want to see the main results quickly:

```bash
cd stats_appendix
Rscript reproduce_analysis.R
```

This runs the **LMG relative importance analysis** on example data in ~30 seconds.

## What This Contains

- **`reproduce_analysis.R`** — Fast LMG analysis (core results only, no subgroups/SEM)
- **`vector_survey_responses_example.csv`** — Example dataset (N=30)
- **`README.md`** — This file

## When to Use This

### Use this script if:
- You want to **quickly verify** the core analysis
- You're **submitting to a journal** and want minimal but complete reproduction
- You want to **test the pipeline** before running the full analysis
- You need **fast runtime** (~30 seconds vs. 2-5 minutes for full analysis)

### Use the main script if:
- You have **real survey data** and want full results
- You need **subgroup analysis** (by role, career stage, geography)
- You need **SEM validation** of latent constructs
- You want **all 17 outputs** with visualizations

## Output

Running the script produces:
- Console output showing LMG rankings with 95% confidence intervals
- R² and model diagnostics
- No files written (purely demonstration)

## Full Analysis

For the complete analysis with all outputs:

```bash
cd ..
Rscript --vanilla run_analysis.R
```

See [../README.md](../README.md) for complete documentation.
