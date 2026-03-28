################################################################################
# generate_figures.R
# Generates standalone HTML figures (SVG embedded) for the paper:
#   output/fig1_correlation_matrix.html
#   output/fig2_career_roi_pathway.html
#   output/fig3_subgroup_comparison.html
################################################################################

user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))

for (pkg in c("ggplot2")) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE))
    stop(sprintf("Missing package '%s'. Run install_dependencies.R first.", pkg))
}

dir.create("output", showWarnings = FALSE)
cat("Generating HTML figures...\n")

# ── shared helpers ────────────────────────────────────────────────────────────

ACCENT   <- "#1a3a5c"
ACCENT_L <- "#4a7aac"
GREY_LT  <- "#f7f9fc"
BORDER   <- "#b0c4de"

BASE_CSS <- sprintf('
  :root { --accent: %s; --accent-light: #e8f0f8; --border: %s; }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body {
    font-family: "Helvetica Neue", Arial, sans-serif;
    font-size: 14px;
    color: #1c1c1e;
    background: #fff;
    max-width: 860px;
    margin: 40px auto;
    padding: 0 24px 60px;
  }
  h2 { font-size: 1em; font-weight: bold; color: var(--accent);
       border-bottom: 2px solid var(--accent); padding-bottom: 3px; margin-bottom: 12px; }
  .fig-note { font-size: 11.5px; color: #555; margin-top: 10px; line-height: 1.5; }
  .fig-wrap { margin: 10px 0; }
  svg { display: block; width: 100%%; height: auto; }
', ACCENT, BORDER)

svg_to_html <- function(title, fig_num, svg_string, note = "") {
  sprintf('<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Figure %d — %s</title>
  <style>%s</style>
</head>
<body>
  <h2>Figure %d. %s</h2>
  <div class="fig-wrap">%s</div>
  %s
</body>
</html>',
    fig_num, title, BASE_CSS,
    fig_num, title, svg_string,
    if (nchar(note) > 0) sprintf('<p class="fig-note"><em>Note.</em> %s</p>', note) else ""
  )
}

svg_string_from_plot <- function(plot_obj, width = 8, height = 5.5) {
  tmp <- tempfile(fileext = ".svg")
  svg(tmp, width = width, height = height, bg = "white")
  print(plot_obj)
  dev.off()
  svg_raw <- paste(readLines(tmp, warn = FALSE), collapse = "\n")
  # Strip XML declaration / doctype, keep just the <svg> element
  svg_raw <- sub("^.*?(<svg)", "\\1", svg_raw)
  svg_raw
}

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 1 – Spearman Correlation Matrix
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 1: Correlation matrix...\n")

cor_mat <- read.csv("output/correlation_matrix.csv", row.names = 1,
                    check.names = FALSE)

# Keep only predictor items q1-q7 plus outcomes q8-q11
items <- paste0("q", 1:11)
cor_mat <- cor_mat[items, items]

var_labels <- c(
  q1  = "q1: Technical Skills",
  q2  = "q2: Communication Skills",
  q3  = "q3: Leadership Skills",
  q4  = "q4: Time Management",
  q5  = "q5: Network Size",
  q6  = "q6: Network Quality",
  q7  = "q7: Network Access",
  q8  = "q8: Career Impact",
  q9  = "q9: Résumé Competitiveness",
  q10 = "q10: Job/Promotion Success",
  q11 = "q11: Leadership Advancement"
)

cor_long <- data.frame(
  x   = rep(items, each = length(items)),
  y   = rep(items, times = length(items)),
  val = as.vector(as.matrix(cor_mat)),
  stringsAsFactors = FALSE
)
cor_long$x <- factor(cor_long$x, levels = items)
cor_long$y <- factor(cor_long$y, levels = rev(items))
cor_long$label <- sprintf("%.2f", cor_long$val)
# Mask upper triangle (keep diagonal + lower)
cor_long$masked <- with(cor_long, as.integer(x) > as.integer(rev(levels(y))) - as.integer(y) + length(items))

fig1 <- ggplot(cor_long, aes(x = x, y = y, fill = val)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(
    data   = subset(cor_long, as.integer(x) <= (length(items) + 1 - as.integer(y))),
    aes(label = label),
    size   = 2.8, color = "white", fontface = "bold"
  ) +
  scale_fill_gradient2(
    low      = "#d73027",
    mid      = "#fee090",
    high     = ACCENT,
    midpoint = 0.7,
    limits   = c(0.5, 1),
    name     = "Spearman r",
    guide    = guide_colorbar(barwidth = 0.8, barheight = 8, title.vjust = 1)
  ) +
  scale_x_discrete(labels = var_labels, position = "top") +
  scale_y_discrete(labels = var_labels) +
  labs(x = NULL, y = NULL,
       caption = "n = 78. All correlations significant at p < 0.001.") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x      = element_text(angle = 40, hjust = 0, size = 8.5, color = "#333"),
    axis.text.y      = element_text(size = 8.5, color = "#333"),
    panel.grid       = element_blank(),
    legend.position  = "right",
    plot.caption     = element_text(size = 9, color = "#555", hjust = 0),
    plot.background  = element_rect(fill = "white", color = NA)
  )

svg1 <- svg_string_from_plot(fig1, width = 9, height = 7)
html1 <- svg_to_html(
  title   = "The Interconnectedness of Volunteer Competencies: Spearman Correlation Matrix",
  fig_num = 1,
  svg_string = svg1,
  note = paste0(
    "n = 78. All correlations are significant at the p &lt; 0.001 level. ",
    "Coefficients range from 0.54 to 0.84, indicating strong positive associations ",
    "across all competencies. Lower triangle displayed; diagonal = 1.00."
  )
)
writeLines(html1, "output/fig1_correlation_matrix.html")
cat("  Written: output/fig1_correlation_matrix.html\n")

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 2 – Career ROI Pathway (LMG horizontal bar chart)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 2: Career ROI pathway...\n")

lmg <- read.csv("output/relative_importance_results.csv",
                stringsAsFactors = FALSE)
lmg <- lmg[order(lmg$lmg_pct), ]   # ascending so top is at top in coord_flip

lmg$label_full <- c(
  q1 = "Technical Skills\n(Programming, Data Analysis)",
  q2 = "Communication Skills\n(Writing, Presentations)",
  q3 = "Leadership Skills\n(Guiding Cross-Functional Teams)",
  q4 = "Time Management\n(Async Coordination)",
  q5 = "Network Size\n(Volume of Connections)",
  q6 = "Network Insights\n(Quality of Professional Advice)",
  q7 = "Network Access\n(Professional Communities)"
)[lmg$variable]

lmg$category <- ifelse(lmg$variable %in% c("q5","q6","q7"),
                        "Social Capital (Network)", "Human Capital (Skills)")
lmg$variable  <- factor(lmg$variable, levels = lmg$variable)

cat_colors <- c(
  "Human Capital (Skills)"   = ACCENT,
  "Social Capital (Network)" = "#2e7d9c"
)

fig2 <- ggplot(lmg, aes(x = variable, y = lmg_pct, fill = category)) +
  geom_col(width = 0.65) +
  geom_errorbar(
    aes(ymin = ci_lower, ymax = ci_upper),
    width = 0.25, linewidth = 0.6, color = "#444"
  ) +
  geom_text(
    aes(label = sprintf("%.1f%%", lmg_pct)),
    hjust = -0.2, size = 3.4, fontface = "bold", color = "#222"
  ) +
  scale_x_discrete(labels = setNames(lmg$label_full, lmg$variable)) +
  scale_y_continuous(
    limits = c(0, 30),
    labels = function(x) paste0(x, "%"),
    expand = c(0, 0)
  ) +
  scale_fill_manual(values = cat_colors, name = "Capital Type") +
  coord_flip() +
  labs(
    x       = NULL,
    y       = "Contribution to R\u00b2 (LMG Method)",
    caption = sprintf("N = 78. Overall model R\u00b2 = 57.5%%. Error bars: 95%% bootstrap CI (1,000 resamples).")
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.y      = element_text(size = 9, lineheight = 1.1, color = "#222"),
    axis.text.x      = element_text(size = 9, color = "#555"),
    axis.title.x     = element_text(size = 10, color = "#333", margin = margin(t = 8)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position  = "bottom",
    legend.title     = element_text(size = 9, face = "bold"),
    legend.text      = element_text(size = 9),
    plot.caption     = element_text(size = 9, color = "#555", hjust = 0),
    plot.background  = element_rect(fill = "white", color = NA)
  )

svg2 <- svg_string_from_plot(fig2, width = 9, height = 5.5)
html2 <- svg_to_html(
  title   = "Career ROI Pathway Model via Skill-Based Volunteering",
  fig_num = 2,
  svg_string = svg2,
  note = paste0(
    "Relative importance weights reflect LMG decomposition (Lindeman et al., 1980; N = 78). ",
    "The overall model explains 57.5% of the variance in career advancement outcomes (R&#178; = 0.575). ",
    "Error bars represent 95% bootstrap confidence intervals (1,000 resamples, seed = 42). ",
    "Outcome variable: q10 (securing a new job, promotion, or academic placement)."
  )
)
writeLines(html2, "output/fig2_career_roi_pathway.html")
cat("  Written: output/fig2_career_roi_pathway.html\n")

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 3 – Subgroup Top Predictors Comparison
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 3: Subgroup comparison...\n")

sub <- read.csv("output/subgroup_analysis_results.csv",
                stringsAsFactors = FALSE)

# Keep only the 4 main subgroups (exclude geography)
groups_keep <- c("Role: Tech", "Role: Non-Tech", "Stage: Student", "Stage: Professional")
sub <- sub[sub$group %in% groups_keep, ]

group_labels <- c(
  "Role: Tech"          = "Technical\nVolunteers (n=51)",
  "Role: Non-Tech"      = "Non-Technical\nVolunteers\u2020 (n=27)",
  "Stage: Student"      = "Students\n(n=46)",
  "Stage: Professional" = "Professionals\n(n=32)"
)
sub$group_label <- group_labels[sub$group]
sub$group_label <- factor(sub$group_label, levels = group_labels)

item_labels <- c(
  q1 = "Technical Skills",
  q2 = "Communication Skills",
  q3 = "Leadership Skills",
  q4 = "Time Management",
  q5 = "Network Size",
  q6 = "Network Quality",
  q7 = "Network Access"
)
sub$item_label <- item_labels[sub$variable]

# Highlight the top predictor in each group
top_per_group <- do.call(rbind, lapply(unique(sub$group), function(g) {
  rows <- sub[sub$group == g, ]
  rows[which.max(rows$contribution_pct), ]
}))
sub$is_top <- paste(sub$group, sub$variable) %in%
              paste(top_per_group$group, top_per_group$variable)

item_colors <- c(
  "Technical Skills"    = "#2e7d9c",
  "Communication Skills"= "#1a5276",
  "Leadership Skills"   = ACCENT,
  "Time Management"     = "#5d6d7e",
  "Network Size"        = "#7f8c8d",
  "Network Quality"     = "#1e8449",
  "Network Access"      = "#2e86c1"
)

fig3 <- ggplot(sub, aes(x = group_label, y = contribution_pct, fill = item_label,
                         alpha = is_top)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(
    data = top_per_group,
    aes(x = group_labels[group], y = contribution_pct,
        label = sprintf("%.1f%%\n%s", contribution_pct, item_labels[variable])),
    position = position_dodge(width = 0.8),
    vjust    = -0.3,
    size     = 2.8,
    fontface = "bold",
    color    = "#111",
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = item_colors, name = "Competency") +
  scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.45), guide = "none") +
  scale_y_continuous(
    labels = function(x) paste0(x, "%"),
    limits = c(0, 32),
    expand = c(0, 0)
  ) +
  labs(
    x       = NULL,
    y       = "Contribution to R\u00b2 (LMG Method)",
    caption = "\u2020 Exploratory; n < 30. Top predictor per subgroup labelled and fully opaque."
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x      = element_text(size = 9, lineheight = 1.2, color = "#222"),
    axis.text.y      = element_text(size = 9, color = "#555"),
    axis.title.y     = element_text(size = 10, color = "#333", margin = margin(r = 8)),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position  = "right",
    legend.title     = element_text(size = 9, face = "bold"),
    legend.text      = element_text(size = 9),
    plot.caption     = element_text(size = 9, color = "#555", hjust = 0),
    plot.background  = element_rect(fill = "white", color = NA)
  )

svg3 <- svg_string_from_plot(fig3, width = 10, height = 6)
html3 <- svg_to_html(
  title   = "Career ROI by Volunteer Subgroup: The Cross-Training Effect",
  fig_num = 3,
  svg_string = svg3,
  note = paste0(
    "LMG decomposition within each subgroup. Top predictor per subgroup is ",
    "fully opaque and labelled; remaining predictors are shown at reduced opacity for context. ",
    "&#8224; Non-Technical subgroup (n = 27) is exploratory given the sample size below n = 30."
  )
)
writeLines(html3, "output/fig3_subgroup_comparison.html")
cat("  Written: output/fig3_subgroup_comparison.html\n")

cat(sprintf("\nDone. 3 figures written to output/\n"))
