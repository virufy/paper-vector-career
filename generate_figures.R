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
# FIGURE 2 – SEM Path Diagram (Standard Academic Style)  (§4.1)
# ════════════════════════════════════════════════════════════════════════════

cat("  Building Figure 2: SEM path diagram...\n")

if (!require("psych", character.only = TRUE, quietly = TRUE))
  stop("Missing package 'psych'. Run install_dependencies.R first.")

csv_file <- if (file.exists("vector_survey_responses.csv")) {
  "vector_survey_responses.csv"
} else if (file.exists("vector_survey_responses_example.csv")) {
  "vector_survey_responses_example.csv"
} else {
  stop("Data file not found.")
}

df_raw <- read.csv(csv_file, check.names = FALSE)
colnames(df_raw) <- make.unique(colnames(df_raw))
if (ncol(df_raw) < 18) stop("Unexpected data structure.")
colnames(df_raw)[8:18] <- paste0("q", 1:11)
df_raw[8:18] <- lapply(df_raw[8:18], function(x) as.numeric(as.character(x)))
df_sem <- df_raw[complete.cases(df_raw[paste0("q", 1:11)]), ]

sem_model <- '
  Skill_Development =~ q1 + q2 + q3 + q4
  Networking        =~ q5 + q6 + q7
  Career_Outcomes   =~ q8 + q9 + q10 + q11
  Career_Outcomes   ~ Skill_Development + Networking
'
fit <- lavaan::sem(sem_model, data = df_sem,
  ordered = paste0("q", 1:11))

std  <- lavaan::standardizedSolution(fit)
load <- std[std$op == "=~", c("lhs", "rhs", "est.std")]
spth <- std[std$op == "~"  & std$lhs == "Career_Outcomes", c("rhs", "est.std")]

a_sk <- suppressWarnings(psych::alpha(df_sem[, c("q1","q2","q3","q4")])$total$raw_alpha)
a_nt <- suppressWarnings(psych::alpha(df_sem[, c("q5","q6","q7")])$total$raw_alpha)
a_co <- suppressWarnings(psych::alpha(df_sem[, c("q8","q9","q10","q11")])$total$raw_alpha)
r2   <- as.numeric(lavaan::inspect(fit, "r2")["Career_Outcomes"])

# ── geometry helpers ────────────────────────────────────────────────────────
# Point on ellipse boundary in direction (dx,dy) from center
ell_pt <- function(cx, cy, rx, ry, dx, dy) {
  th <- atan2(dy / ry, dx / rx)
  c(cx + rx * cos(th), cy + ry * sin(th))
}
# Point on rectangle boundary in direction (dx,dy) from center
box_pt <- function(cx, cy, hw, hh, dx, dy) {
  s <- min(if (dx != 0) hw / abs(dx) else Inf,
           if (dy != 0) hh / abs(dy) else Inf)
  c(cx + s * dx, cy + s * dy)
}
# Filled ellipse polygon
ell_poly <- function(cx, cy, rx, ry, n = 200) {
  t <- seq(0, 2 * pi, length.out = n + 1)
  data.frame(x = cx + rx * cos(t), y = cy + ry * sin(t))
}

# ── layout  (canvas: x in [0,10], y in [0,7]) ───────────────────────────────
# Oval sizes reduced and CO shifted left so no shape overlaps any box.
# Horizontal gaps: left ~0.70 units, right ~0.45 units.
SK  <- list(cx = 3.8, cy = 4.83, rx = 0.84, ry = 0.95)   # Skill Development
NT  <- list(cx = 3.8, cy = 1.72, rx = 0.84, ry = 0.78)   # Networking
CO  <- list(cx = 6.75, cy = 3.27, rx = 0.80, ry = 1.18)  # Career Outcomes

BHW <- 1.15; BHH <- 0.275   # indicator box half-width / half-height

# Left indicators (Skill + Network constructs)
ind_L <- data.frame(
  lhs = c(rep("Skill_Development", 4), rep("Networking", 3)),
  var = c("q1","q2","q3","q4","q5","q6","q7"),
  lab = c("Technical Skills", "Communication Skills",
          "Leadership Skills", "Time Management",
          "Network Size", "Network Quality", "Network Access"),
  cx  = 1.1,
  cy  = c(6.25, 5.38, 4.44, 3.40,  2.46, 1.72, 0.98)
)

# Right indicators (Career Outcomes construct)
ind_R <- data.frame(
  lhs = "Career_Outcomes",
  var = c("q8","q9","q10","q11"),
  lab = c("Career Impact", "Résumé\nCompetitiveness",
          "Job / Promotion\nSuccess", "Leadership\nAdvancement"),
  cx  = 9.15,
  cy  = c(4.88, 3.84, 2.78, 1.70)
)

# ── build arrow segments and coefficient labels ──────────────────────────────
seg_df <- data.frame()
lbl_df <- data.frame()

# Left indicators → Skill / Networking ovals
for (k in seq_len(nrow(ind_L))) {
  r   <- ind_L[k, ]
  lat <- if (r$lhs == "Skill_Development") SK else NT
  lam <- load[load$lhs == r$lhs & load$rhs == r$var, "est.std"]
  p1  <- box_pt(r$cx, r$cy, BHW, BHH, 1, 0)
  p2  <- ell_pt(lat$cx, lat$cy, lat$rx, lat$ry, p1[1] - lat$cx, p1[2] - lat$cy)
  seg_df <- rbind(seg_df,
    data.frame(x=p1[1], y=p1[2], xe=p2[1], ye=p2[2], type="meas"))
  # Label at 40% from box toward oval, nudged above
  lx <- p1[1] + 0.40 * (p2[1] - p1[1])
  ly <- p1[2] + 0.40 * (p2[2] - p1[2]) + 0.17
  lbl_df <- rbind(lbl_df,
    data.frame(x=lx, y=ly, lab=sprintf("%.2f", lam), sty="plain"))
}

# Career Outcomes oval → right indicators
for (k in seq_len(nrow(ind_R))) {
  r   <- ind_R[k, ]
  lam <- load[load$lhs == "Career_Outcomes" & load$rhs == r$var, "est.std"]
  p1  <- ell_pt(CO$cx, CO$cy, CO$rx, CO$ry, r$cx - CO$cx, r$cy - CO$cy)
  p2  <- box_pt(r$cx, r$cy, BHW, BHH, -1, 0)
  seg_df <- rbind(seg_df,
    data.frame(x=p1[1], y=p1[2], xe=p2[1], ye=p2[2], type="meas"))
  lx <- p1[1] + 0.40 * (p2[1] - p1[1])
  ly <- p1[2] + 0.40 * (p2[2] - p1[2]) + 0.17
  lbl_df <- rbind(lbl_df,
    data.frame(x=lx, y=ly, lab=sprintf("%.2f", lam), sty="plain"))
}

# Structural: Skill_Development → Career_Outcomes
b_sk <- spth[spth$rhs == "Skill_Development", "est.std"]
p1   <- ell_pt(SK$cx, SK$cy, SK$rx, SK$ry, CO$cx - SK$cx, CO$cy - SK$cy)
p2   <- ell_pt(CO$cx, CO$cy, CO$rx, CO$ry, SK$cx - CO$cx, SK$cy - CO$cy)
seg_df <- rbind(seg_df,
  data.frame(x=p1[1], y=p1[2], xe=p2[1], ye=p2[2], type="struct"))
lbl_df <- rbind(lbl_df, data.frame(
  x = (p1[1]+p2[1])/2 - 0.12,
  y = (p1[2]+p2[2])/2 + 0.30,
  lab = sprintf("\u03b2 = %.3f", b_sk), sty = "bold"))

# Structural: Networking → Career_Outcomes
b_nt <- spth[spth$rhs == "Networking", "est.std"]
p1   <- ell_pt(NT$cx, NT$cy, NT$rx, NT$ry, CO$cx - NT$cx, CO$cy - NT$cy)
p2   <- ell_pt(CO$cx, CO$cy, CO$rx, CO$ry, NT$cx - CO$cx, NT$cy - CO$cy)
seg_df <- rbind(seg_df,
  data.frame(x=p1[1], y=p1[2], xe=p2[1], ye=p2[2], type="struct"))
lbl_df <- rbind(lbl_df, data.frame(
  x = (p1[1]+p2[1])/2 - 0.12,
  y = (p1[2]+p2[2])/2 - 0.30,
  lab = sprintf("\u03b2 = %.3f", b_nt), sty = "bold"))

# ── polygons & labels ────────────────────────────────────────────────────────
ell_df <- rbind(
  cbind(ell_poly(SK$cx, SK$cy, SK$rx, SK$ry), grp = "SK"),
  cbind(ell_poly(NT$cx, NT$cy, NT$rx, NT$ry), grp = "NT"),
  cbind(ell_poly(CO$cx, CO$cy, CO$rx, CO$ry), grp = "CO")
)
ell_df$x <- as.numeric(ell_df$x); ell_df$y <- as.numeric(ell_df$y)

all_ind <- rbind(ind_L[, c("var","lab","cx","cy")],
                 ind_R[, c("var","lab","cx","cy")])

lat_lbl <- data.frame(
  x   = c(SK$cx, NT$cx, CO$cx),
  y   = c(SK$cy, NT$cy, CO$cy),
  lab = c(
    sprintf("Skill\nDevelopment\n\u03b1 = %.3f", a_sk),
    sprintf("Networking\n\u03b1 = %.3f",          a_nt),
    sprintf("Career\nOutcomes\nR\u00b2 = %.3f",   r2)
  )
)

# ── plot ────────────────────────────────────────────────────────────────────
fig4 <- ggplot() +
  # measurement arrows (drawn first; shapes overlap their tails cleanly)
  geom_segment(
    data  = subset(seg_df, type == "meas"),
    aes(x = x, y = y, xend = xe, yend = ye),
    arrow = arrow(length = unit(0.13, "cm"), type = "closed"),
    color = "#555555", linewidth = 0.55
  ) +
  # structural arrows (thicker, accent colour)
  geom_segment(
    data  = subset(seg_df, type == "struct"),
    aes(x = x, y = y, xend = xe, yend = ye),
    arrow = arrow(length = unit(0.18, "cm"), type = "closed"),
    color = ACCENT, linewidth = 1.1
  ) +
  # latent variable ovals (drawn over arrow tails for clean edges)
  geom_polygon(
    data  = ell_df,
    aes(x = x, y = y, group = grp),
    fill = "#dbeafe", color = "#1f2937", linewidth = 0.55
  ) +
  # indicator boxes (drawn over arrow endpoints for clean edges)
  geom_rect(
    data  = all_ind,
    aes(xmin = cx - BHW, xmax = cx + BHW, ymin = cy - BHH, ymax = cy + BHH),
    fill = "#ffffff", color = "#374151", linewidth = 0.45
  ) +
  # indicator text
  geom_text(
    data  = all_ind,
    aes(x = cx, y = cy, label = lab),
    size = 2.55, color = "#1f2937", lineheight = 0.92
  ) +
  # latent variable labels (bold)
  geom_text(
    data  = lat_lbl,
    aes(x = x, y = y, label = lab),
    size = 2.85, fontface = "bold", color = "#1f2937", lineheight = 1.1
  ) +
  # loading coefficients
  geom_text(
    data  = subset(lbl_df, sty == "plain"),
    aes(x = x, y = y, label = lab),
    size = 2.55, color = "#333333"
  ) +
  # structural β labels (bold, accent)
  geom_text(
    data  = subset(lbl_df, sty == "bold"),
    aes(x = x, y = y, label = lab),
    size = 2.9, fontface = "bold", color = ACCENT
  ) +
  coord_cartesian(xlim = c(-0.2, 10.5), ylim = c(0.52, 6.90), clip = "off") +
  theme_void() +
  theme(
    plot.margin     = margin(4, 4, 4, 4),
    plot.background = element_rect(fill = "white", color = NA)
  )

save_fig(fig4, "output/fig2_sem_path", width = 12, height = 7)

cat(sprintf("\nDone. 4 figures written to output/\n"))
