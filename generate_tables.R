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
 
cat("Generating JME-formatted HTML tables...\n")
 
# ── helpers ───────────────────────────────────────────────────────────────────
 
pct_fmt <- function(x, digits = 1) sprintf("%.*f%%", digits, x)
n_pct   <- function(n, total) sprintf("%d (%.1f%%)", n, 100 * n / total)
 
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
 
# Build a full <table>: table number + italic title + rules + note
make_table <- function(table_num, title, header, body_rows, note = NULL) {
  head_row <- tr(header)
  body_str <- paste(sapply(body_rows, tr), collapse = "\n")
  note_str <- if (!is.null(note)) {
    sprintf('<p class="tbl-note"><em>Note.</em> %s</p>', note)
  } else ""
  sprintf(
    '<div class="tbl-block">
  <p class="tbl-num">%s</p>
  <p class="tbl-title">%s</p>
  <div class="tbl-wrap">
    <table>
      <thead>%s</thead>
      <tbody>%s</tbody>
    </table>
  </div>
  %s
</div>',
    table_num, title, head_row, body_str, note_str
  )
}
 
# ── CSS ───────────────────────────────────────────────────────────────────────
 
CSS <- '
  /* ── Reset ── */
  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
 
  /* ── Base ── */
  body {
    font-family: "Times New Roman", Times, serif;
    font-size: 13px;
    line-height: 1.6;
    color: #000;
    background: #fff;
    max-width: 900px;
    margin: 48px auto;
    padding: 0 32px 80px;
  }
 
  /* ── Document header ── */
  .doc-header { text-align: center; margin-bottom: 48px; }
  .doc-header .journal {
    font-size: 0.72em;
    font-weight: bold;
    letter-spacing: 0.15em;
    text-transform: uppercase;
    color: #555;
    margin-bottom: 12px;
  }
  .doc-header h1 {
    font-size: 1.3em;
    font-weight: bold;
    margin-bottom: 4px;
  }
  .doc-header .subtitle {
    font-style: italic;
    font-size: 1em;
    color: #333;
  }
 
  /* ── Table block ── */
  .tbl-block { margin-bottom: 48px; }
 
  /* APA: bold table number on its own line */
  .tbl-num {
    font-weight: bold;
    font-size: 1em;
    margin-bottom: 2px;
  }
 
  /* APA: italic title on next line */
  .tbl-title {
    font-style: italic;
    font-size: 1em;
    margin-bottom: 6px;
  }
 
  .tbl-wrap { overflow-x: auto; }
 
  /* ── Table: APA three-rule format ── */
  table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12.5px;
  }
 
  /* Thick top border */
  thead tr:first-child th {
    border-top: 2.5px solid #000;
  }
 
  /* Header cells: no background, no vertical lines */
  thead th {
    background: transparent;
    color: #000;
    font-weight: bold;
    text-align: left;
    padding: 5px 10px;
    border-bottom: 1.5px solid #000;   /* thin rule under header */
    border-left: none;
    border-right: none;
  }
 
  /* Sub-header row (for spanner headers) */
  thead tr.subhead th {
    font-weight: normal;
    font-style: italic;
    font-size: 0.92em;
    border-bottom: 1px solid #888;
  }
 
  /* Body cells: no borders at all */
  tbody td {
    padding: 4px 10px;
    border: none;
    vertical-align: top;
  }
 
  /* Last body row: thick bottom border */
  tbody tr:last-child td {
    border-bottom: 2.5px solid #000;
  }
 
  /* Section/region header rows: italic bold, slight top spacing */
  tbody tr.section-head td {
    font-weight: bold;
    font-style: italic;
    padding-top: 10px;
  }
 
  /* Subtotal rows: italic */
  tbody tr.subtotal td {
    font-style: italic;
    color: #333;
    font-size: 0.92em;
  }
 
  /* Grand total rows */
  tbody tr.grand-total td {
    font-weight: bold;
    border-top: 1.5px solid #000;
  }
 
  /* Alignment helpers */
  td.c, th.c { text-align: center; }
  td.r, th.r { text-align: right;  }
  td.indent  { padding-left: 24px; }
 
  /* ── Table note ── */
  .tbl-note {
    font-size: 11.5px;
    color: #333;
    margin-top: 5px;
    line-height: 1.5;
  }
 
  /* ── Section rule (before Appendix) ── */
  hr.section {
    border: none;
    border-top: 1px solid #aaa;
    margin: 56px 0 48px;
  }
  .appendix-label {
    font-weight: bold;
    font-size: 0.85em;
    letter-spacing: 0.1em;
    text-transform: uppercase;
    color: #555;
    margin-bottom: 6px;
  }
'
 
# ── Page wrapper ──────────────────────────────────────────────────────────────
 
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
  <div class="doc-header">
    <p class="journal">Journal of Management Education &mdash; Supplementary Tables</p>
    <h1>From Volunteer to Vocation</h1>
    <p class="subtitle">The Career Impact of Skill and Network Development in a Global Tech Nonprofit</p>
  </div>
  %s
</body>
</html>', title, CSS, body_html)
}
 
# ════════════════════════════════════════════════════════════════════════════
# TABLE 1 – Geography Distribution
# ════════════════════════════════════════════════════════════════════════════
 
cat("  Building Table 1: Geography...\n")
 
df_raw <- read.csv("input/vector_survey_responses.csv", check.names = FALSE,
                   stringsAsFactors = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
 
country_col <- grep("countries of residence", colnames(df_raw), value = TRUE)
country_col <- country_col[length(country_col)]
 
consent_col <- grep("I agree", colnames(df_raw), value = TRUE)[1]
 
likert_raw  <- df_raw[, 8:18]
colnames(likert_raw) <- paste0("q", 1:11)
complete_idx <- complete.cases(suppressWarnings(lapply(likert_raw, as.numeric)))
df_valid <- df_raw[complete_idx, ]
N <- nrow(df_valid)
cat(sprintf("  Complete cases: %d\n", N))
 
region_map <- list(
  "North America"          = c("United States (USA)", "Canada"),
  "East Asia"              = c("Japan", "South Korea"),
  "Middle East"            = c("United Arab Emirates (UAE)"),
  "South &amp; Southeast Asia" = c("India", "Pakistan", "Indonesia", "Singapore", "Bangladesh"),
  "Latin America"          = c("Brazil", "Colombia", "Argentina", "Venezuela"),
  "Oceania"                = c("Australia")
)
 
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
  countries  <- region_map[[region]]
  region_added <- FALSE
  region_n   <- 0
 
  for (ctry in countries) {
    n_ctry <- as.integer(country_respondents[ctry])
    if (is.na(n_ctry)) n_ctry <- 0L
    if (n_ctry == 0) next
 
    if (!region_added) {
      t1_rows[[length(t1_rows) + 1]] <- list(
        cells = c(td(sprintf('<strong>%s</strong>', region), colspan = "3")),
        class = "section-head"
      )
      region_added <- TRUE
    }
    t1_rows[[length(t1_rows) + 1]] <- list(
      cells = c(
        td(ctry, class = "indent"),
        td(as.character(n_ctry), class = "c"),
        td(pct_fmt(100 * n_ctry / N), class = "c")
      ),
      class = NULL
    )
    region_n <- region_n + n_ctry
  }
 
  if (region_added) {
    t1_rows[[length(t1_rows) + 1]] <- list(
      cells = c(
        td(sprintf('&emsp;<em>%s subtotal</em>', region)),
        td(as.character(region_n), class = "c"),
        td(pct_fmt(100 * region_n / N), class = "c")
      ),
      class = "subtotal"
    )
  }
}
 
t1_rows[[length(t1_rows) + 1]] <- list(
  cells = c(
    td('Total country mentions <span style="font-weight:normal;font-size:11px">(multi-select permitted)</span>'),
    td(as.character(total_mentions), class = "c"),
    td("&mdash;", class = "c")
  ),
  class = "grand-total"
)
t1_rows[[length(t1_rows) + 1]] <- list(
  cells = c(
    td("<strong>Unique respondents</strong>"),
    td(as.character(N), class = "c"),
    td("100.0%", class = "c")
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
 
t1_body_rows <- build_custom_rows(t1_rows)
 
t1_note <- sprintf(
  "n = %d complete cases. Respondents were permitted to select multiple countries of residence
  to reflect global mobility; therefore the sum of country mentions (%d) exceeds the number of
  unique respondents. Percentages are based on unique respondents (N = %d).",
  N, total_mentions, N
)
 
# Build table manually to use custom rows
TABLE1_HTML <- sprintf(
  '<div class="tbl-block">
  <p class="tbl-num">Table 1</p>
  <p class="tbl-title">Geography Distribution of Survey Respondents (n = %d)</p>
  <div class="tbl-wrap">
    <table>
      <thead><tr>%s%s%s</tr></thead>
      <tbody>%s</tbody>
    </table>
  </div>
  <p class="tbl-note"><em>Note.</em> %s</p>
</div>',
  N,
  th("Region / Country"),
  th("Respondents (n)", class = "c"),
  th("% of Sample", class = "c"),
  paste(t1_body_rows, collapse = "\n"),
  t1_note
)
 
# ════════════════════════════════════════════════════════════════════════════
# TABLE 2 – LMG Relative Importance, Full Sample
# ════════════════════════════════════════════════════════════════════════════
 
cat("  Building Table 2: LMG full sample...\n")
 
lmg <- read.csv("output/relative_importance_results.csv", stringsAsFactors = FALSE)
lmg <- lmg[order(-lmg$lmg_pct), ]
 
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
 
t2_body <- lapply(seq_len(nrow(lmg)), function(i) {
  v     <- lmg$variable[i]
  pct   <- lmg$lmg_pct[i]
  ci_lo <- lmg$ci_lower[i]
  ci_hi <- lmg$ci_upper[i]
  c(
    td(as.character(i), class = "c"),
    td(var_labels[v]),
    td(interpretations[v]),
    td(pct_fmt(pct), class = "c"),
    td(sprintf("[%.1f%%, %.1f%%]", ci_lo, ci_hi), class = "c")
  )
})
 
r_sq <- 0.575
TABLE2_HTML <- make_table(
  table_num = "Table 2",
  title     = sprintf("Relative Importance of Predictors for Career Outcomes (N = %d, R&sup2; = .575)", N),
  header    = c(
    th("Rank", class = "c"),
    th("Predictor (Survey Item)"),
    th("Interpretation"),
    th("Contribution to R&sup2;", class = "c"),
    th("95% Bootstrap CI", class = "c")
  ),
  body_rows = t2_body,
  note = paste0(
    "LMG method (Lindeman et al., 1980) via the <em>relaimpo</em> package in R. ",
    "Bootstrap confidence intervals based on 1,000 resamples (seed = 42). ",
    "Outcome variable: q10 (securing a new job, promotion, or academic placement). ",
    "Predictors ranked from largest to smallest contribution to explained variance."
  )
)
 
# ════════════════════════════════════════════════════════════════════════════
# TABLE 3 – Primary Career Drivers by Subgroup
# ════════════════════════════════════════════════════════════════════════════
 
cat("  Building Table 3: Subgroup drivers...\n")
 
sub <- read.csv("output/subgroup_analysis_results.csv", stringsAsFactors = FALSE)
 
groups_order <- c("Role: Tech", "Role: Non-Tech", "Stage: Student", "Stage: Professional")
group_labels <- c(
  "Role: Tech"          = "Technical Volunteers",
  "Role: Non-Tech"      = "Non-Technical Volunteers\u2020",
  "Stage: Student"      = "Students",
  "Stage: Professional" = "Established Professionals"
)
 
t3_body <- lapply(groups_order, function(g) {
  rows <- sub[sub$group == g, ]
  rows <- rows[order(-rows$contribution_pct), ]
  top  <- rows[1, ]
  c(
    td(group_labels[g]),
    td(as.character(top$n), class = "c"),
    td(var_labels[top$variable]),
    td(pct_fmt(top$contribution_pct), class = "c"),
    td(pct_fmt(100 * top$r_squared), class = "c")
  )
})
 
TABLE3_HTML <- make_table(
  table_num = "Table 3",
  title     = "Primary Career Drivers by Subgroup",
  header    = c(
    th("Subgroup"),
    th("n", class = "c"),
    th("Primary Career Driver"),
    th("Contribution to R&sup2;", class = "c"),
    th("Subgroup R&sup2;", class = "c")
  ),
  body_rows = t3_body,
  note = paste0(
    "\u2020 Exploratory; n &lt; 30. Results should be interpreted with caution and replicated ",
    "in larger samples before drawing strong conclusions."
  )
)
 
# ════════════════════════════════════════════════════════════════════════════
# TABLE 4 – Thematic Analysis Summary
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
 
n_qual <- 47
 
t4_body <- lapply(seq_len(nrow(thematic)), function(i) {
  pct   <- thematic$freq_pct[i]
  n_rep <- round(pct * n_qual / 100)
  c(
    td(thematic$theme[i]),
    td(sprintf("%d%%", pct), class = "c"),
    td(as.character(n_rep), class = "c")
  )
})
 
TABLE4_HTML <- make_table(
  table_num = "Table 4",
  title     = sprintf("Summary of Thematic Analysis Results (n = %d)", n_qual),
  header    = c(
    th("Theme"),
    th("Relative Frequency", class = "c"),
    th("Approx. Respondents", class = "c")
  ),
  body_rows = t4_body,
  note = paste0(
    "Themes were retained if cited by \u226515% of respondents (n \u2265 7). ",
    "Because respondents frequently identified multiple growth areas within a single response, ",
    "total frequencies exceed 100%. Thematic analysis followed Braun &amp; Clarke (2006)."
  )
)
 
# ════════════════════════════════════════════════════════════════════════════
# TABLE 5 – Convergence
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
    "Career Outcomes Construct (q8&ndash;q11)",
    "Leadership Skills (q3)",
    "<em>No quantitative counterpart</em>"
  ),
  lmg_contribution = c(
    "16.1%",
    "14.4%; 21.7% (non-technical subgroup)",
    "15.7% + 12.7%",
    "&mdash;",
    "17.2%",
    "<em>Qualitative-only insight</em>"
  ),
  stringsAsFactors = FALSE
)
 
t5_body <- lapply(seq_len(nrow(conv)), function(i) {
  c(
    td(conv$qual_theme[i]),
    td(conv$prevalence[i], class = "c"),
    td(conv$quant_counterpart[i]),
    td(conv$lmg_contribution[i])
  )
})
 
TABLE5_HTML <- make_table(
  table_num = "Table 5",
  title     = "Convergence of Qualitative Themes and Quantitative Predictors",
  header    = c(
    th("Qualitative Theme"),
    th("Prevalence", class = "c"),
    th("Quantitative Counterpart"),
    th("LMG Contribution")
  ),
  body_rows = t5_body,
  note = paste0(
    "LMG contributions reflect the full sample (N = 78). ",
    "Career Identity Clarification has no corresponding Likert-scale item, ",
    "representing a dimension of career development captured exclusively through the qualitative strand."
  )
)
 
# ════════════════════════════════════════════════════════════════════════════
# APPENDIX – Demographic Overview
# ════════════════════════════════════════════════════════════════════════════
 
cat("  Building Appendix: Demographic overview...\n")
 
role_col  <- grep("What best describes your role", colnames(df_valid), value = TRUE)[1]
stage_col <- grep("career stage", colnames(df_valid), value = TRUE)[1]
 
classify_role <- function(x) {
  tech_kws <- c("App Dev", "Cloud", "ML", "Web Dev", "Data Sci",
                "Machine Learning", "Cybersecurity", "UX", "acoustic",
                "App Developer", "Web Developer")
  if (any(sapply(tech_kws, function(k) grepl(k, x, ignore.case = TRUE)))) "Technical" else "Non-Technical"
}
classify_stage <- function(x) {
  if (any(sapply(c("student", "high school", "middle school"),
                 function(k) grepl(k, x, ignore.case = TRUE)))) "Student" else "Professional"
}
 
df_valid$role_type  <- sapply(df_valid[[role_col]],  classify_role)
df_valid$stage_type <- sapply(df_valid[[stage_col]], classify_stage)
 
demo_tab  <- table(Role = df_valid$role_type, Stage = df_valid$stage_type)
demo_df   <- as.data.frame.matrix(demo_tab)
grand_col <- rowSums(demo_df)
grand_row <- colSums(demo_df)
 
demo_body <- lapply(rownames(demo_df), function(r) {
  row_n <- demo_df[r, ]
  c(
    td(r),
    sapply(names(row_n), function(s) td(n_pct(row_n[[s]], N), class = "c")),
    td(n_pct(grand_col[r], N), class = "c")
  )
})
demo_body[[length(demo_body) + 1]] <- c(
  td("<strong>Total</strong>"),
  sapply(names(grand_row), function(s) td(n_pct(grand_row[s], N), class = "c")),
  td(sprintf("<strong>%d (100.0%%)</strong>", N), class = "c")
)
 
APPENDIX_HTML <- paste0(
  '<p class="appendix-label">Appendix</p>',
  make_table(
    table_num = "Appendix Table",
    title     = sprintf("Demographic Overview of Survey Respondents (N = %d)", N),
    header    = c(th("Role Type"), th("Student", class="c"), th("Professional", class="c"), th("Total", class="c")),
    body_rows = demo_body,
    note = paste0(
      "Technical roles include App Development, Cloud Engineering, ML Engineering, Web Development, ",
      "Data Science, Cybersecurity, and UX Design. Non-Technical roles include Grant Writing/Research, ",
      "HR, Legal, Marketing, and Operations. ",
      "Student includes undergraduate, graduate, and doctoral students. ",
      "Professional includes all respondents with paid work experience."
    )
  )
)
 
# ════════════════════════════════════════════════════════════════════════════
# WRITE FILES
# ════════════════════════════════════════════════════════════════════════════
 
if (file.exists("output/tables.html")) file.remove("output/tables.html")
 
tables <- list(
  list(file = "output/table1_geography.html",      html = TABLE1_HTML),
  list(file = "output/table2_lmg_full.html",       html = TABLE2_HTML),
  list(file = "output/table3_subgroups.html",      html = TABLE3_HTML),
  list(file = "output/table4_thematic.html",       html = TABLE4_HTML),
  list(file = "output/table5_convergence.html",    html = TABLE5_HTML),
  list(file = "output/appendix_demographics.html", html = APPENDIX_HTML)
)
 
# Also write a single combined file for convenience
all_html <- paste(sapply(tables, `[[`, "html"), collapse = "\n<hr class='section'>\n")
writeLines(page_wrap(all_html, "All Tables — From Volunteer to Vocation"),
           "output/all_tables.html")
cat("  Written: output/all_tables.html\n")
 
for (t in tables) {
  writeLines(page_wrap(t$html), t$file)
  cat(sprintf("  Written: %s\n", t$file))
}
 
cat(sprintf("\nDone. %d files written to output/\n", length(tables) + 1L))
