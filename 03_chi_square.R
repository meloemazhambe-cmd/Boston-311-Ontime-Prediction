# =============================================================================
# 03_chi_square.R
# Chi-square tests of independence: on-time status vs year and neighborhood
# Run on both train (70%) and test (30%) splits to check consistency
# =============================================================================

source("R/00_setup.R")
df_model <- readRDS(file.path(paths$processed, "df_model.rds"))

set.seed(123)
idx   <- createDataPartition(df_model$on_time_bin, p = 0.7, list = FALSE)
train <- df_model[idx, ]
test  <- df_model[-idx, ]

run_chisq <- function(data, var, split) {
  res <- chisq.test(table(data[[var]], data$on_time_bin))
  tibble(Variable = var, Split = split,
         Chi_Square = unname(res$statistic),
         df = unname(res$parameter),
         p_value = res$p.value)
}

chisq_results <- bind_rows(
  run_chisq(train, "year",         "Train"),
  run_chisq(test,  "year",         "Test"),
  run_chisq(train, "neighborhood", "Train"),
  run_chisq(test,  "neighborhood", "Test")
)
print(chisq_results)

chisq_results %>%
  gt() %>%
  fmt_number(columns = Chi_Square, decimals = 1) %>%
  fmt_scientific(columns = p_value, decimals = 2) %>%
  tab_header(title = "Chi-Square Tests of Independence") %>%
  apa_style() %>%
  gtsave(file.path(paths$tables, "table03_chi_square.html"))
