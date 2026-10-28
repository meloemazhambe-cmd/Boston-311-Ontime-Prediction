# =============================================================================
# 00_setup.R
# Boston 311 On-Time Prediction — package loading and project paths
# ALY6015 Intermediate Analytics, Northeastern University
# =============================================================================

required_pkgs <- c(
  "tidyverse", "lubridate", "stringr", "scales", "broom",
  "glmnet", "caret", "pROC", "gt", "knitr"
)

missing <- required_pkgs[!required_pkgs %in% installed.packages()[, "Package"]]
if (length(missing) > 0) install.packages(missing)

suppressPackageStartupMessages({
  library(tidyverse)   # dplyr, ggplot2, tidyr, readr ...
  library(lubridate)
  library(stringr)
  library(scales)
  library(broom)
  library(glmnet)
  library(caret)
  library(pROC)
  library(gt)
  library(knitr)
})

# Relative paths — run scripts from the repository root
# (or open the folder as an RStudio project)
paths <- list(
  raw       = "data/raw",
  processed = "data/processed",
  figures   = "outputs/figures",
  tables    = "outputs/tables"
)
invisible(lapply(paths, dir.create, recursive = TRUE, showWarnings = FALSE))

# Classification cutoff used throughout the project
CUTOFF <- 0.8

# Reusable APA-style formatting for gt tables
apa_style <- function(gt_tbl) {
  gt_tbl %>%
    tab_options(
      table.font.names                  = "Times New Roman",
      table.font.size                   = px(12),
      table.border.top.width            = px(2),
      table.border.top.color            = "black",
      table.border.bottom.width         = px(2),
      table.border.bottom.color         = "black",
      column_labels.border.bottom.width = px(1),
      column_labels.border.bottom.color = "black",
      table_body.hlines.width           = px(0),
      table_body.vlines.width           = px(0),
      column_labels.vlines.width        = px(0),
      table.border.left.width           = px(0),
      table.border.right.width          = px(0)
    ) %>%
    tab_style(
      style     = cell_text(weight = "bold"),
      locations = cells_column_labels(everything())
    )
}
