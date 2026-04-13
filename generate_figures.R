################################################################################
# generate_figures.R
# Generates high-resolution PNG figures for the paper.
#
# Figure order matches document order:
#   Fig 1 (§4.1) – Spearman Correlation Matrix
#   Fig 2 (§4.1) – SEM Path Diagram (Standardized)
#   Fig 3 (§4.2) – LMG Bootstrap CI Forest Plot
#   Fig 4 (§4.3) – Subgroup Comparison (Cross-Training Effect)
################################################################################

user_lib <- path.expand("~/R/library")
if (dir.exists(user_lib)) .libPaths(c(user_lib, .libPaths()))

for (pkg in c("ggplot2", "lavaan")) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE))
    stop(sprintf("Missing package '%s'. Run install_dependencies.R first.", pkg))
}

dir.create("output", showWarnings = FALSE)
cat("Generating figures...\n")

ACCENT <- "#1a3a5c"

save_fig <- function(plot_obj, base, width = 9, height = 6, dpi = 300) {
  ggsave(paste0(base, ".png"), plot = plot_obj,
         width = width, height = height, dpi = dpi, bg = "white")
  cat(sprintf("  Written: %s.png\n", base))
}

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 1 – Spearman Correlation Matrix  (§4.1)
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

# Build long-format data frame with integer row/column indices
ni <- length(items)
cor_long <- expand.grid(xi = seq_len(ni), yi = seq_len(ni),
                        KEEP.OUT.ATTRS = FALSE)
cor_long$val   <- as.vector(as.matrix(cor_mat))       # col-major matches xi/yi
cor_long$x     <- factor(items[cor_long$xi], levels = items)
cor_long$y     <- factor(items[cor_long$yi], levels = rev(items))
cor_long$label <- sprintf("%.2f", cor_long$val)
# Lower triangle + diagonal: row index (from bottom) >= col index
# y is reversed, so as.integer(y) gives position from top; row from bottom = ni+1 - as.integer(y)
cor_long$show  <- (ni + 1L - as.integer(cor_long$y)) >= cor_long$xi

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
    axis.text.x     = element_text(angle = 35, hjust = 0, vjust = 0,
                                   size = 8.5, color = "#333",
                                   margin = margin(b = 10)),
    axis.text.y     = element_text(size = 8.5, color = "#333",
                                   margin = margin(r = 4)),
    panel.grid      = element_blank(),
    legend.position = "right",
    plot.caption    = element_text(size = 9, color = "#555", hjust = 0),
    plot.background = element_rect(fill = "white", color = NA),
    plot.margin     = margin(t = 2, r = 2, b = 2, l = 2)
  )

save_fig(fig1, "output/fig1_correlation_matrix", width = 9, height = 7)

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 4 – Subgroup Comparison / Cross-Training Effect  (§4.3)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 4: Subgroup comparison...\n")

sub <- read.csv("output/subgroup_analysis_results.csv", stringsAsFactors = FALSE)
sub <- sub[sub$group %in% c("Role: Tech", "Role: Non-Tech",
                              "Stage: Student", "Stage: Professional"), ]

group_labels <- c(
  "Role: Tech"          = "Technical\nVolunteers (n=51)",
  "Role: Non-Tech"      = "Non-Technical\nVolunteers\u2020 (n=27)",
  "Stage: Student"      = "Students\n(n=46)",
  "Stage: Professional" = "Professionals\n(n=32)"
)
sub$group_label <- factor(group_labels[sub$group], levels = group_labels)

item_labels <- c(q1 = "Technical Skills",    q2 = "Communication Skills",
                 q3 = "Leadership Skills",   q4 = "Time Management",
                 q5 = "Network Size",        q6 = "Network Quality",
                 q7 = "Network Access")
sub$item_label <- factor(item_labels[sub$variable], levels = item_labels)

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

fig2 <- ggplot(sub, aes(x = group_label, y = contribution_pct,
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
       y = "Contribution to R\u00b2 (LMG Method)") +
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
    plot.background    = element_rect(fill = "white", color = NA)
  )

save_fig(fig2, "output/fig4_subgroup_comparison", width = 10, height = 6)

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 3 – LMG Bootstrap CI Forest Plot  (§4.2)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 3: LMG bootstrap CI forest plot...\n")

lmg <- read.csv("output/relative_importance_results.csv", stringsAsFactors = FALSE)
lmg$label <- paste0(lmg$variable, ": ", sub(" \\(.*", "", lmg$description))
lmg <- lmg[order(lmg$lmg_pct, decreasing = TRUE), ]
lmg$label <- factor(lmg$label, levels = rev(lmg$label))

fig3 <- ggplot(lmg, aes(y = label, x = lmg_pct)) +
  geom_segment(aes(x = ci_lower, xend = ci_upper, yend = label),
               color = "#888", linewidth = 1.1) +
  geom_point(size = 3.2, color = ACCENT) +
  geom_vline(xintercept = 100 / 7, linetype = "dashed", color = "#999") +
  geom_text(aes(label = sprintf("%.1f%%", lmg_pct)),
            hjust = -0.15, size = 3.3, color = "#222") +
  scale_x_continuous(
    limits = c(min(lmg$ci_lower) - 1, max(lmg$ci_upper) + 3),
    labels = function(x) paste0(x, "%")
  ) +
  labs(
    x = "Contribution to R\u00b2 (LMG %)",
    y = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(
    axis.text.y = element_text(size = 9, color = "#222"),
    axis.text.x = element_text(size = 9, color = "#555"),
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_blank(),
    plot.background = element_rect(fill = "white", color = NA)
  )

save_fig(fig3, "output/fig3_lmg_forest", width = 9, height = 5.6)

# ════════════════════════════════════════════════════════════════════════════
# FIGURE 2 – SEM Path Diagram (Standardized Coefficients)  (§4.1)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 2: SEM path diagram...\n")

# Rebuild the SEM model on the same mapped Likert items used by run_analysis.R
csv_file <- if (file.exists("vector_survey_responses.csv")) {
  "vector_survey_responses.csv"
} else if (file.exists("vector_survey_responses_example.csv")) {
  "vector_survey_responses_example.csv"
} else {
  stop("Data file not found. Expected vector_survey_responses.csv or vector_survey_responses_example.csv")
}

df_raw <- read.csv(csv_file, check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
if (ncol(df_raw) < 18) stop("Unexpected data structure: expected at least 18 columns")

likert_cols <- 8:18
question_names <- paste0("q", 1:11)
colnames(df_raw)[likert_cols] <- question_names
df_raw[likert_cols] <- lapply(df_raw[likert_cols], function(x) as.numeric(as.character(x)))
df_sem <- df_raw[complete.cases(df_raw[question_names]), ]

sem_model <- '
  Skill_Development =~ q1 + q2 + q3 + q4
  Networking        =~ q5 + q6 + q7
  Career_Outcomes   =~ q8 + q9 + q10 + q11
  Career_Outcomes   ~ Skill_Development + Networking
'

fit <- lavaan::sem(
  sem_model,
  data = df_sem,
  ordered = c("q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q11")
)

std <- lavaan::standardizedSolution(fit)
load <- std[std$op == "=~" & std$lhs %in% c("Skill_Development", "Networking", "Career_Outcomes"),
            c("lhs", "rhs", "est.std")]
path <- std[std$op == "~" & std$lhs == "Career_Outcomes" & std$rhs %in% c("Skill_Development", "Networking"),
            c("lhs", "rhs", "est.std")]

latent_nodes <- data.frame(
  node = c("Skill_Development", "Networking", "Career_Outcomes"),
  label = c("Skill Development", "Networking", "Career Outcomes"),
  x = c(0.22, 0.22, 0.22),
  y = c(0.78, 0.50, 0.22)
)

obs_nodes <- data.frame(
  node = c("q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q11"),
  label = c("q1", "q2", "q3", "q4", "q5", "q6", "q7", "q8", "q9", "q10", "q11"),
  x = c(rep(0.82, 11)),
  y = c(0.92, 0.84, 0.76, 0.68, 0.58, 0.50, 0.42, 0.32, 0.24, 0.16, 0.08)
)

edges_load <- merge(load, latent_nodes[, c("node", "x", "y")], by.x = "lhs", by.y = "node")
edges_load <- merge(edges_load, obs_nodes[, c("node", "x", "y")], by.x = "rhs", by.y = "node", suffixes = c("_from", "_to"))

edges_path <- merge(path, latent_nodes[, c("node", "x", "y")], by.x = "rhs", by.y = "node")
edges_path <- merge(edges_path, latent_nodes[latent_nodes$node == "Career_Outcomes", c("node", "x", "y")],
                    by.x = "lhs", by.y = "node", suffixes = c("_from", "_to"))

edges <- rbind(
  data.frame(x_from = edges_load$x_from, y_from = edges_load$y_from,
             x_to = edges_load$x_to, y_to = edges_load$y_to,
             est = edges_load$est.std, type = "loading"),
  data.frame(x_from = edges_path$x_from, y_from = edges_path$y_from,
             x_to = edges_path$x_to, y_to = edges_path$y_to,
             est = edges_path$est.std, type = "path")
)

edges$mx <- (edges$x_from + edges$x_to) / 2
edges$my <- (edges$y_from + edges$y_to) / 2
edges$lx <- edges$mx
edges$ly <- edges$my

# Nudge structural path labels so they do not overlap near the same destination node.
path_idx <- which(edges$type == "path")
if (length(path_idx) > 0) {
  if (length(path_idx) >= 1) {
    edges$lx[path_idx[1]] <- edges$mx[path_idx[1]] - 0.04
    edges$ly[path_idx[1]] <- edges$my[path_idx[1]] + 0.028
  }
  if (length(path_idx) >= 2) {
    edges$lx[path_idx[2]] <- edges$mx[path_idx[2]] - 0.04
    edges$ly[path_idx[2]] <- edges$my[path_idx[2]] - 0.028
  }
}

fig4 <- ggplot() +
  geom_curve(
    data = subset(edges, type == "loading"),
    aes(x = x_from, y = y_from, xend = x_to, yend = y_to, color = type),
    curvature = 0.08,
    arrow = grid::arrow(length = grid::unit(0.14, "cm")),
    linewidth = 0.8
  ) +
  geom_curve(
    data = subset(edges, type == "path"),
    aes(x = x_from, y = y_from, xend = x_to, yend = y_to, color = type),
    curvature = 0.18,
    arrow = grid::arrow(length = grid::unit(0.14, "cm")),
    linewidth = 0.8
  ) +
  geom_label(data = edges, aes(x = lx, y = ly, label = sprintf("%.2f", est)),
             size = 3, color = "#1f2937", fontface = "bold",
             fill = "white", linewidth = 0.15,
             label.padding = grid::unit(0.08, "lines")) +
  geom_label(data = latent_nodes, aes(x = x, y = y, label = label),
             fill = "#edf2f7", color = "#1f2937", size = 3.3, fontface = "bold", linewidth = 0.2) +
  geom_label(data = obs_nodes, aes(x = x, y = y, label = label),
             fill = "#ffffff", color = "#374151", size = 3, linewidth = 0.2) +
  scale_color_manual(values = c(loading = "#6b7280", path = ACCENT), guide = "none") +
  coord_cartesian(xlim = c(0.05, 0.98), ylim = c(0.08, 0.96), clip = "off") +
  theme_void() +
  theme(
    plot.margin = margin(2, 2, 2, 2),
    plot.background = element_rect(fill = "white", color = NA)
  )

save_fig(fig4, "output/fig2_sem_path", width = 10, height = 6)

cat(sprintf("\nDone. 4 figures written to output/\n"))
