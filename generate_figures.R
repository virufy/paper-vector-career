################################################################################
# generate_figures.R
# Generates high-resolution PNG figures for the paper:
#   output/fig1_correlation_matrix.png
#   output/fig2_career_roi_pathway.png
#   output/fig3_subgroup_comparison.png
################################################################################

user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))

for (pkg in c("ggplot2")) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE))
    stop(sprintf("Missing package '%s'. Run install_dependencies.R first.", pkg))
}

dir.create("output", showWarnings = FALSE)
cat("Generating PNG figures...\n")

ACCENT <- "#1a3a5c"

save_fig <- function(plot_obj, base, width = 9, height = 6, dpi = 300) {
  png_path <- paste0(base, ".png")
  svg_path <- paste0(base, ".svg")
  ggsave(png_path, plot = plot_obj, width = width, height = height,
         dpi = dpi, bg = "white")
  svg(svg_path, width = width, height = height, bg = "white")
  print(plot_obj)
  dev.off()
  cat(sprintf("  Written: %s  +  %s\n", png_path, svg_path))
}

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 1 – Spearman Correlation Matrix
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 1: Correlation matrix...\n")

cor_mat <- read.csv("output/correlation_matrix.csv", row.names = 1,
                    check.names = FALSE)
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
  q9  = "q9: Resume Competitiveness",
  q10 = "q10: Job/Promotion Success",
  q11 = "q11: Leadership Advancement"
)

cor_long <- data.frame(
  x   = rep(items, each  = length(items)),
  y   = rep(items, times = length(items)),
  val = as.vector(as.matrix(cor_mat)),
  stringsAsFactors = FALSE
)
cor_long$x <- factor(cor_long$x, levels = items)
cor_long$y <- factor(cor_long$y, levels = rev(items))
cor_long$label <- sprintf("%.2f", cor_long$val)

# Lower triangle + diagonal only
cor_long$show <- as.integer(cor_long$x) <= (length(items) + 1L - as.integer(cor_long$y))

fig1 <- ggplot(cor_long, aes(x = x, y = y, fill = val)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(data = subset(cor_long, show),
            aes(label = label),
            size = 2.8, color = "white", fontface = "bold") +
  scale_fill_gradient2(
    low = "#d73027", mid = "#fee090", high = ACCENT,
    midpoint = 0.7, limits = c(0.5, 1),
    name = "Spearman r",
    guide = guide_colorbar(barwidth = 0.8, barheight = 8, title.vjust = 1)
  ) +
  scale_x_discrete(labels = var_labels, position = "top") +
  scale_y_discrete(labels = var_labels) +
  labs(x = NULL, y = NULL,
       caption = "n = 78. All correlations significant at p < 0.001. Lower triangle shown; diagonal = 1.00.") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x    = element_text(angle = 40, hjust = 0, size = 8.5, color = "#333"),
    axis.text.y    = element_text(size = 8.5, color = "#333"),
    panel.grid     = element_blank(),
    legend.position = "right",
    plot.caption   = element_text(size = 9, color = "#555", hjust = 0),
    plot.background = element_rect(fill = "white", color = NA)
  )

save_fig(fig1, "output/fig1_correlation_matrix", width = 9, height = 7)

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 2 – Career ROI Pathway (LMG horizontal bar chart)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 2: Career ROI pathway...\n")

lmg <- read.csv("output/relative_importance_results.csv", stringsAsFactors = FALSE)
lmg <- lmg[order(lmg$lmg_pct), ]   # ascending → top predictor at top after coord_flip

label_full <- c(
  q1 = "Technical Skills\n(Programming, Data Analysis)",
  q2 = "Communication Skills\n(Writing, Presentations)",
  q3 = "Leadership Skills\n(Guiding Cross-Functional Teams)",
  q4 = "Time Management\n(Async Coordination)",
  q5 = "Network Size\n(Volume of Connections)",
  q6 = "Network Insights\n(Quality of Professional Advice)",
  q7 = "Network Access\n(Professional Communities)"
)
lmg$label_full <- label_full[lmg$variable]
lmg$category   <- ifelse(lmg$variable %in% c("q5","q6","q7"),
                          "Social Capital (Network)", "Human Capital (Skills)")
lmg$variable   <- factor(lmg$variable, levels = lmg$variable)

cat_colors <- c("Human Capital (Skills)" = ACCENT, "Social Capital (Network)" = "#2e7d9c")

fig2 <- ggplot(lmg, aes(x = variable, y = lmg_pct, fill = category)) +
  geom_col(width = 0.65) +
  geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                width = 0.25, linewidth = 0.6, color = "#444") +
  geom_text(aes(label = sprintf("%.1f%%", lmg_pct)),
            hjust = -0.2, size = 3.4, fontface = "bold", color = "#222") +
  scale_x_discrete(labels = setNames(lmg$label_full, as.character(lmg$variable))) +
  scale_y_continuous(limits = c(0, 30),
                     labels = function(x) paste0(x, "%"),
                     expand = c(0, 0)) +
  scale_fill_manual(values = cat_colors, name = "Capital Type") +
  coord_flip() +
  labs(x = NULL,
       y = "Contribution to R\u00b2 (LMG Method)",
       caption = "N = 78. R\u00b2 = 57.5%. Error bars: 95% bootstrap CI (1,000 resamples).") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.y        = element_text(size = 9, lineheight = 1.1, color = "#222"),
    axis.text.x        = element_text(size = 9, color = "#555"),
    axis.title.x       = element_text(size = 10, color = "#333", margin = margin(t = 8)),
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "bottom",
    legend.title       = element_text(size = 9, face = "bold"),
    legend.text        = element_text(size = 9),
    plot.caption       = element_text(size = 9, color = "#555", hjust = 0),
    plot.background    = element_rect(fill = "white", color = NA)
  )

save_fig(fig2, "output/fig2_career_roi_pathway", width = 9, height = 5.5)

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 3 – Subgroup Top Predictors Comparison
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 3: Subgroup comparison...\n")

sub <- read.csv("output/subgroup_analysis_results.csv", stringsAsFactors = FALSE)
sub <- sub[sub$group %in% c("Role: Tech","Role: Non-Tech","Stage: Student","Stage: Professional"), ]

group_labels <- c(
  "Role: Tech"          = "Technical\nVolunteers (n=51)",
  "Role: Non-Tech"      = "Non-Technical\nVolunteers\u2020 (n=27)",
  "Stage: Student"      = "Students\n(n=46)",
  "Stage: Professional" = "Professionals\n(n=32)"
)
sub$group_label <- factor(group_labels[sub$group], levels = group_labels)

item_labels <- c(q1="Technical Skills", q2="Communication Skills", q3="Leadership Skills",
                 q4="Time Management",  q5="Network Size",         q6="Network Quality",
                 q7="Network Access")
sub$item_label <- item_labels[sub$variable]

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

fig3 <- ggplot(sub, aes(x = group_label, y = contribution_pct,
                         fill = item_label, alpha = is_top)) +
  geom_col(position = position_dodge(width = 0.8), width = 0.7) +
  geom_text(
    data = top_per_group,
    aes(x = group_labels[group], y = contribution_pct,
        label = sprintf("%.1f%%\n%s", contribution_pct, item_labels[variable])),
    position = position_dodge(width = 0.8),
    vjust = -0.3, size = 2.8, fontface = "bold", color = "#111",
    inherit.aes = FALSE
  ) +
  scale_fill_manual(values = item_colors, name = "Competency") +
  scale_alpha_manual(values = c(`TRUE` = 1, `FALSE` = 0.4), guide = "none") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, 32), expand = c(0, 0)) +
  labs(x = NULL,
       y = "Contribution to R\u00b2 (LMG Method)",
       caption = "\u2020 Exploratory; n < 30. Top predictor per subgroup labelled.") +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.x        = element_text(size = 9, lineheight = 1.2, color = "#222"),
    axis.text.y        = element_text(size = 9, color = "#555"),
    axis.title.y       = element_text(size = 10, color = "#333", margin = margin(r = 8)),
    panel.grid.major.x = element_blank(),
    panel.grid.minor   = element_blank(),
    legend.position    = "right",
    legend.title       = element_text(size = 9, face = "bold"),
    legend.text        = element_text(size = 9),
    plot.caption       = element_text(size = 9, color = "#555", hjust = 0),
    plot.background    = element_rect(fill = "white", color = NA)
  )

save_fig(fig3, "output/fig3_subgroup_comparison", width = 10, height = 6)

cat(sprintf("\nDone. 3 PNG figures written to output/\n"))
