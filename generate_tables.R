################################################################################
# generate_tables.R
# Generates output/tables.html containing all paper tables:
#   Table 1 – Geography Distribution (computed from raw data)
#   Table 2 – LMG Relative Importance, Full Sample (from output CSVs)
#   Table 3 – Primary Career Drivers by Subgroup
#   Table 4 – Thematic Analysis Summary (hardcoded qualitative data)
#   Table 5 – Convergence of Qualitative Themes and Quantitative Predictors
#   Appendix – Demographic Overview (role type × career stage)
################################################################################

user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))

dir.create("output", showWarnings = FALSE)

cat("Generating HTML tables...\n")

# ── helpers ──────────────────────────────────────────────────────────────────

pct_fmt  <- function(x, digits = 1) sprintf("%.*f%%", digits, x)
n_pct    <- function(n, total) sprintf("%d (%.1f%%)", n, 100 * n / total)

html_tag <- function(tag, content, ...) {
  attrs <- list(...)
  attr_str <- if (length(attrs)) {
    paste(sprintf(' %s="%s"', names(attrs), unlist(attrs)), collapse = "")
  } else ""
  sprintf("<%s%s>%s</%s>", tag, attr_str, content, tag)
}

th <- function(x, ...) html_tag("th", x, ...)
td <- function(x, ...) html_tag("td", x, ...)
tr <- function(cells) html_tag("tr", paste(cells, collapse = ""))

# Build a full <table> from a list of row vectors (first row = header)
make_table <- function(header, body_rows, note = NULL, id = NULL) {
  id_attr  <- if (!is.null(id)) sprintf(' id="%s"', id) else ""
  head_row <- tr(sapply(header, th))
  body_str <- paste(sapply(body_rows, tr), collapse = "\n")
  note_str <- if (!is.null(note)) {
    sprintf('<p class="table-note"><em>Note.</em> %s</p>', note)
  } else ""
  sprintf(
    '<div class="table-wrap"%s><table>\n<thead>%s</thead>\n<tbody>\n%s\n</tbody>\n</table>%s</div>',
    id_attr, head_row, body_str, note_str
  )
}

# ── CSS & page template ───────────────────────────────────────────────────────

CSS <- '
  :root {
    --accent: #1a3a5c;
    --accent-light: #e8f0f8;
    --border: #b0c4de;
    --text: #1c1c1e;
    --subtext: #555;
    --row-alt: #f7f9fc;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: "Georgia", "Times New Roman", serif;
    font-size: 14px;
    line-height: 1.6;
    color: var(--text);
    background: #fff;
    max-width: 960px;
    margin: 40px auto;
    padding: 0 24px 60px;
  }
  h1 {
    font-size: 1.3em;
    font-weight: bold;
    text-align: center;
    margin-bottom: 6px;
    color: var(--accent);
  }
  .subtitle {
    text-align: center;
    font-size: 0.9em;
    color: var(--subtext);
    margin-bottom: 40px;
  }
  h2 {
    font-size: 1em;
    font-weight: bold;
    margin: 36px 0 6px;
    color: var(--accent);
    border-bottom: 2px solid var(--accent);
    padding-bottom: 3px;
  }
  .table-wrap {
    overflow-x: auto;
    margin: 10px 0 4px;
  }
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 13px;
  }
  thead th {
    background: var(--accent);
    color: #fff;
    text-align: left;
    padding: 8px 10px;
    font-weight: bold;
    border: 1px solid var(--border);
  }
  tbody td {
    padding: 6px 10px;
    border: 1px solid var(--border);
    vertical-align: top;
  }
  tbody tr:nth-child(even) td { background: var(--row-alt); }
  tbody tr.subtotal td {
    background: var(--accent-light);
    font-weight: bold;
    border-top: 2px solid var(--border);
  }
  tbody tr.region-header td {
    background: #d0dff0;
    font-weight: bold;
    font-style: italic;
    color: var(--accent);
  }
  tbody tr.grand-total td {
    background: #c8d8ec;
    font-weight: bold;
    border-top: 3px double var(--accent);
  }
  td.rank, td.pct, td.n { text-align: center; }
  td.bar-cell { min-width: 120px; }
  .bar-bg {
    background: #d9e8f5;
    border-radius: 3px;
    height: 14px;
    width: 100%;
    display: inline-block;
    vertical-align: middle;
  }
  .bar-fill {
    background: var(--accent);
    border-radius: 3px;
    height: 14px;
    display: inline-block;
    vertical-align: top;
  }
  td.ci { font-size: 11px; color: var(--subtext); }
  .table-note {
    font-size: 11.5px;
    color: var(--subtext);
    margin-top: 6px;
    line-height: 1.5;
  }
  .dagger { vertical-align: super; font-size: 0.8em; }
  hr.section { border: none; border-top: 1px solid var(--border); margin: 48px 0 0; }
'

page_wrap <- function(body_html, title = "Tables — From Volunteer to Vocation") {
  sprintf('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>%s</title>
  <style>%s</style>
</head>
<body>
  <h1>From Volunteer to Vocation</h1>
  <p class="subtitle">The Career Impact of Skill and Network Development in a Global Tech Nonprofit</p>
  %s
</body>
</html>', title, CSS, body_html)
}

# ════════════════════════════════════════════════════════════════════════════
# TABLE 1 – Geography Distribution (computed from raw data)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Table 1: Geography...\n")

df_raw <- read.csv("vector_survey_responses.csv", check.names = FALSE,
                   stringsAsFactors = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))

# Country column is index 24 (0-based) → column 25 in R (1-based)
country_col <- grep("countries of residence", colnames(df_raw), value = TRUE)
country_col <- country_col[length(country_col)]   # take the later duplicate

consent_col <- grep("I agree", colnames(df_raw), value = TRUE)[1]
df_valid <- df_raw[
  !is.na(df_raw[[consent_col]]) & trimws(df_raw[[consent_col]]) == "I agree and wish to participate",
]

# Also filter to complete cases on core Likert items (cols 8-18 in raw = q1-q11)
likert_raw <- df_raw[, 8:18]
colnames(likert_raw) <- paste0("q", 1:11)
complete_idx <- complete.cases(suppressWarnings(lapply(likert_raw, as.numeric)))

df_valid <- df_raw[complete_idx, ]
N <- nrow(df_valid)
cat(sprintf("  Complete cases: %d\n", N))

# Parse country column
raw_countries <- df_valid[[country_col]]
country_list  <- strsplit(as.character(raw_countries), ",|;")
country_vec   <- trimws(unlist(country_list))
country_vec   <- country_vec[country_vec != "" & !is.na(country_vec)]

# Normalise name variants
country_vec <- gsub("^United States$", "United States (USA)", country_vec)
country_vec <- gsub("^United Arab Emirates$", "United Arab Emirates (UAE)", country_vec)

# Region mapping
region_map <- list(
  "North America"          = c("United States (USA)", "Canada"),
  "East Asia"              = c("Japan", "South Korea"),
  "Middle East"            = c("United Arab Emirates (UAE)"),
  "South & Southeast Asia" = c("India", "Pakistan", "Indonesia",
                                "Singapore", "Bangladesh"),
  "Latin America"          = c("Brazil", "Colombia", "Argentina", "Venezuela"),
  "Oceania"                = c("Australia")
)

# Count unique respondents per country (not per mention)
respondent_countries <- lapply(
  strsplit(as.character(df_valid[[country_col]]), ",|;"),
  function(x) {
    x <- trimws(x)
    x <- gsub("^United States$", "United States (USA)", x)
    x <- gsub("^United Arab Emirates$", "United Arab Emirates (UAE)", x)
    x[x != ""]
  }
)

country_respondents <- table(unlist(respondent_countries))
total_mentions <- sum(country_respondents)

t1_rows <- list()

for (region in names(region_map)) {
  countries <- region_map[[region]]
  region_added <- FALSE
  region_n <- 0

  for (ctry in countries) {
    n_ctry <- as.integer(country_respondents[ctry])
    if (is.na(n_ctry)) n_ctry <- 0L
    if (n_ctry == 0) next

    # First country in this region → add region header row
    if (!region_added) {
      t1_rows[[length(t1_rows) + 1]] <- list(
        cells = c(
          sprintf('<strong>%s</strong>', region), "", ""
        ),
        class = "region-header"
      )
      region_added <- TRUE
    }
    t1_rows[[length(t1_rows) + 1]] <- list(
      cells = c(
        sprintf('&emsp;%s', ctry),
        td(as.character(n_ctry), class = "n"),
        td(pct_fmt(100 * n_ctry / N), class = "pct")
      ),
      class = NULL
    )
    region_n <- region_n + n_ctry
  }

  if (region_added) {
    t1_rows[[length(t1_rows) + 1]] <- list(
      cells = c(
        sprintf('&emsp;<em>%s subtotal</em>', region),
        td(as.character(region_n), class = "n"),
        td(pct_fmt(100 * region_n / N), class = "pct")
      ),
      class = "subtotal"
    )
  }
}

# Grand total row (mentions, not unique respondents)
t1_rows[[length(t1_rows) + 1]] <- list(
  cells = c(
    sprintf('<strong>Total country mentions</strong> <span style="font-weight:normal;font-size:11px">(multi-select permitted)</span>'),
    td(as.character(total_mentions), class = "n"),
    td("&mdash;", class = "pct")
  ),
  class = "grand-total"
)
t1_rows[[length(t1_rows) + 1]] <- list(
  cells = c(
    "<strong>Unique respondents</strong>",
    td(as.character(N), class = "n"),
    td("100.0%", class = "pct")
  ),
  class = "grand-total"
)

build_custom_rows <- function(row_list) {
  sapply(row_list, function(r) {
    cells_html <- paste(r$cells, collapse = "")
    cls <- if (!is.null(r$class)) sprintf(' class="%s"', r$class) else ""
    sprintf("<tr%s>%s</tr>", cls, cells_html)
  })
}

t1_header  <- c("Region / Country", "Respondents (n)", "% of Sample")
t1_body    <- build_custom_rows(t1_rows)

t1_note <- sprintf(
  "n = %d complete cases. Respondents were permitted to select multiple countries
  of residence to reflect global mobility; therefore the sum of country mentions
  (%d) exceeds the number of unique respondents. Percentages are based on
  unique respondents (N = %d).", N, total_mentions, N
)

TABLE1_HTML <- paste0(
  "<h2>Table 1. Geography Distribution of Survey Respondents (n = ", N, ")</h2>",
  '<div class="table-wrap">',
  '<table><thead>', tr(sapply(t1_header, th)), '</thead>',
  '<tbody>', paste(t1_body, collapse = "\n"), '</tbody>',
  '</table>',
  sprintf('<p class="table-note"><em>Note.</em> %s</p>', t1_note),
  '</div>'
)

# ════════════════════════════════════════════════════════════════════════════
# TABLE 2 – LMG Relative Importance, Full Sample
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Table 2: LMG full sample...\n")

lmg <- read.csv("output/relative_importance_results.csv",
                stringsAsFactors = FALSE)
lmg <- lmg[order(-lmg$lmg_pct), ]

# Friendly labels
var_labels <- c(
  q1 = "Technical Skills (q1)",
  q2 = "Communication Skills (q2)",
  q3 = "Leadership Skills (q3)",
  q4 = "Time Management (q4)",
  q5 = "Network Size (q5)",
  q6 = "Network Insights (q6)",
  q7 = "Network Access (q7)"
)
interpretations <- c(
  q1 = "Programming, data analysis, cloud infrastructure",
  q2 = "Writing, presentations, and verbal clarity",
  q3 = "Guiding cross-functional teams across time zones",
  q4 = "Asynchronous coordination and self-regulation",
  q5 = "Volume of new professional connections",
  q6 = "Quality of professional advice from global peers",
  q7 = "Entry into new professional communities"
)

max_lmg <- max(lmg$lmg_pct)

t2_body <- lapply(seq_len(nrow(lmg)), function(i) {
  v   <- lmg$variable[i]
  pct <- lmg$lmg_pct[i]
  ci_lo <- lmg$ci_lower[i]
  ci_hi <- lmg$ci_upper[i]
  bar_w <- round(100 * pct / max_lmg)

  bar_html <- sprintf(
    '<span class="bar-bg"><span class="bar-fill" style="width:%d%%"></span></span> %s',
    bar_w, pct_fmt(pct)
  )

  c(
    td(as.character(i), class = "rank"),
    td(var_labels[v]),
    td(interpretations[v]),
    td(bar_html, class = "bar-cell"),
    td(sprintf("[%.1f%%, %.1f%%]", ci_lo, ci_hi), class = "ci")
  )
})

r_sq <- 0.575   # from full_model_diagnostics
TABLE2_HTML <- paste0(
  sprintf("<h2>Table 2. Relative Importance of Predictors for Career Outcomes (N = %d, R&#178; = %.3f)</h2>", N, r_sq),
  make_table(
    header    = c("Rank", "Predictor (Survey Item)", "Interpretation",
                  "Contribution to R\u00b2", "95% Bootstrap CI"),
    body_rows = t2_body,
    note = paste0(
      "LMG method (Lindeman et al., 1980) via the <em>relaimpo</em> package in R. ",
      "Bootstrap confidence intervals based on 1,000 resamples (seed = 42). ",
      "Outcome variable: q10 (securing a new job, promotion, or academic placement)."
    )
  )
)

# ════════════════════════════════════════════════════════════════════════════
# TABLE 3 – Primary Career Drivers by Subgroup
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Table 3: Subgroup drivers...\n")

sub <- read.csv("output/subgroup_analysis_results.csv",
                stringsAsFactors = FALSE)

# For each group, pull the top predictor
groups_order <- c("Role: Tech", "Role: Non-Tech", "Stage: Student", "Stage: Professional")
group_labels <- c(
  "Role: Tech"            = "Technical Volunteers",
  "Role: Non-Tech"        = "Non-Technical Volunteers\u2020",
  "Stage: Student"        = "Students",
  "Stage: Professional"   = "Established Professionals"
)

t3_body <- lapply(groups_order, function(g) {
  rows <- sub[sub$group == g, ]
  rows <- rows[order(-rows$contribution_pct), ]
  top  <- rows[1, ]
  n_g  <- top$n
  r2_g <- top$r_squared
  var  <- top$variable
  pct  <- top$contribution_pct

  c(
    td(group_labels[g]),
    td(as.character(n_g), class = "n"),
    td(var_labels[var]),
    td(pct_fmt(pct), class = "pct"),
    td(pct_fmt(100 * r2_g), class = "pct")
  )
})

TABLE3_HTML <- paste0(
  "<h2>Table 3. Primary Career Drivers by Subgroup</h2>",
  make_table(
    header    = c("Subgroup", "n", "Primary Career Driver",
                  "Contribution to R\u00b2", "Subgroup R\u00b2"),
    body_rows = t3_body,
    note = paste0(
      "\u2020 Exploratory; n &lt; 30. Results should be interpreted with caution and replicated ",
      "in larger samples before drawing strong conclusions."
    )
  )
)

# ════════════════════════════════════════════════════════════════════════════
# TABLE 4 – Thematic Analysis Summary  (qualitative — hardcoded)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Table 4: Thematic analysis...\n")

thematic <- data.frame(
  theme = c(
    "Interpersonal &amp; Communication Development",
    "Technical Skill Acquisition",
    "Professional Network Expansion",
    "Career Signaling &amp; Marketability",
    "Leadership &amp; Ownership Development",
    "Career Identity Clarification"
  ),
  freq_pct = c(64, 57, 55, 45, 36, 21),
  stringsAsFactors = FALSE
)

n_qual <- 47   # respondents who submitted open-text responses
max_freq <- max(thematic$freq_pct)

t4_body <- lapply(seq_len(nrow(thematic)), function(i) {
  pct   <- thematic$freq_pct[i]
  n_rep <- round(pct * n_qual / 100)
  bar_w <- round(100 * pct / max_freq)
  bar_html <- sprintf(
    '<span class="bar-bg"><span class="bar-fill" style="width:%d%%"></span></span> %d%%',
    bar_w, pct
  )
  c(
    td(thematic$theme[i]),
    td(bar_html, class = "bar-cell"),
    td(as.character(n_rep), class = "n")
  )
})

TABLE4_HTML <- paste0(
  sprintf("<h2>Table 4. Summary of Thematic Analysis Results (n = %d)</h2>", n_qual),
  make_table(
    header    = c("Theme", "Relative Frequency", "Approx. Respondents"),
    body_rows = t4_body,
    note = paste0(
      "Themes were retained if cited by \u226515% of respondents (n \u2265 7). ",
      "Because respondents frequently identified multiple growth areas within a single response, ",
      "total frequencies exceed 100%. Thematic analysis followed Braun &amp; Clarke (2006)."
    )
  )
)

# ════════════════════════════════════════════════════════════════════════════
# TABLE 5 – Convergence of Qualitative Themes and Quantitative Predictors
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Table 5: Convergence table...\n")

conv <- data.frame(
  qual_theme = c(
    "Interpersonal &amp; Communication Development",
    "Technical Skill Acquisition",
    "Professional Network Expansion",
    "Career Signaling &amp; Marketability",
    "Leadership &amp; Ownership Development",
    "Career Identity Clarification"
  ),
  prevalence = c("64%", "57%", "55%", "45%", "36%", "21%"),
  quant_counterpart = c(
    "Communication Skills (q2)",
    "Technical Skills (q1)",
    "Network Insights (q6) + Network Access (q7)",
    "Career Outcomes Construct (q8–q11)",
    "Leadership Skills (q3)",
    "<em>No quantitative counterpart</em>"
  ),
  lmg_contribution = c(
    "16.1%",
    "14.4%&thinsp;;&thinsp;21.7% (non-technical subgroup)",
    "15.7% + 12.7%",
    "&#8212;",
    "17.2%",
    "<em>Qualitative-only insight</em>"
  ),
  stringsAsFactors = FALSE
)

t5_body <- lapply(seq_len(nrow(conv)), function(i) {
  c(
    td(conv$qual_theme[i]),
    td(conv$prevalence[i], class = "pct"),
    td(conv$quant_counterpart[i]),
    td(conv$lmg_contribution[i])
  )
})

TABLE5_HTML <- paste0(
  "<h2>Table 5. Convergence of Qualitative Themes and Quantitative Predictors</h2>",
  make_table(
    header    = c("Qualitative Theme", "Prevalence",
                  "Quantitative Counterpart", "LMG Contribution"),
    body_rows = t5_body,
    note = paste0(
      "LMG contributions reflect the full sample (N = 78). ",
      "Career Identity Clarification has no corresponding Likert-scale item, ",
      "representing a dimension of career development captured exclusively through the qualitative strand."
    )
  )
)

# ════════════════════════════════════════════════════════════════════════════
# APPENDIX TABLE – Demographic Overview (role type × career stage)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Appendix: Demographic overview...\n")

role_col  <- grep("What best describes your role", colnames(df_valid), value = TRUE)[1]
stage_col <- grep("career stage", colnames(df_valid), value = TRUE)[1]

classify_role <- function(x) {
  tech_kws <- c("App Dev", "Cloud", "ML", "Web Dev", "Data Sci",
                "Machine Learning", "Cybersecurity", "UX", "acoustic",
                "App Developer", "Web Developer")
  is_tech  <- any(sapply(tech_kws, function(k) grepl(k, x, ignore.case = TRUE)))
  if (is_tech) "Technical" else "Non-Technical"
}

classify_stage <- function(x) {
  student_kws <- c("student", "high school", "middle school")
  is_student  <- any(sapply(student_kws, function(k) grepl(k, x, ignore.case = TRUE)))
  if (is_student) "Student" else "Professional"
}

df_valid$role_type  <- sapply(df_valid[[role_col]],  classify_role)
df_valid$stage_type <- sapply(df_valid[[stage_col]], classify_stage)

demo_tab <- table(Role = df_valid$role_type, Stage = df_valid$stage_type)
demo_df  <- as.data.frame.matrix(demo_tab)
grand_col <- rowSums(demo_df)
grand_row <- colSums(demo_df)
total     <- sum(demo_df)

demo_body <- lapply(rownames(demo_df), function(r) {
  row_n <- demo_df[r, ]
  c(
    td(r),
    sapply(names(row_n), function(s)
      td(n_pct(row_n[[s]], N), class = "n")),
    td(n_pct(grand_col[r], N), class = "n")
  )
})
# Totals row
total_row <- c(
  td("<strong>Total</strong>"),
  sapply(names(grand_row), function(s) td(n_pct(grand_row[s], N), class = "n")),
  td(sprintf("<strong>%d (100.0%%)</strong>", N), class = "n")
)
demo_body[[length(demo_body) + 1]] <- total_row

APPENDIX_HTML <- paste0(
  "<hr class='section'>",
  "<h2>Appendix Table. Demographic Overview of Survey Respondents (N = ", N, ")</h2>",
  make_table(
    header    = c("Role Type", "Student", "Professional", "Total"),
    body_rows = demo_body,
    note = paste0(
      "Classification: Technical roles include App Development, Cloud Engineering, ",
      "ML Engineering, Web Development, Data Science, and related. Non-Technical roles include ",
      "Grant Writing/Research, HR, Legal, Marketing, Operations, and related. ",
      "Career stage: Student includes undergraduate, graduate, and doctoral students. ",
      "Professional includes all respondents with paid work experience."
    )
  )
)

# ════════════════════════════════════════════════════════════════════════════
# WRITE INDIVIDUAL HTML FILES
# ════════════════════════════════════════════════════════════════════════════

# Remove the old combined file if it exists
if (file.exists("output/tables.html")) file.remove("output/tables.html")

tables <- list(
  list(file = "output/table1_geography.html",    html = TABLE1_HTML),
  list(file = "output/table2_lmg_full.html",     html = TABLE2_HTML),
  list(file = "output/table3_subgroups.html",    html = TABLE3_HTML),
  list(file = "output/table4_thematic.html",     html = TABLE4_HTML),
  list(file = "output/table5_convergence.html",  html = TABLE5_HTML),
  list(file = "output/appendix_demographics.html", html = sub("^<hr[^>]*>", "", APPENDIX_HTML))
)

for (t in tables) {
  writeLines(page_wrap(t$html), t$file)
  cat(sprintf("  Written: %s\n", t$file))
}

cat(sprintf("\nDone. %d files written to output/\n", length(tables)))
