# =============================================================================
# run_all.R — reproduce the full analysis from the repository root
# =============================================================================
scripts <- c(
  "R/01_data_cleaning.R",
  "R/02_eda.R",
  "R/03_chi_square.R",
  "R/04_logistic_regression.R",
  "R/05_lasso.R"
)
for (s in scripts) {
  message("\n==== Running ", s, " ====")
  source(s, echo = FALSE)
}
message("\nDone. See outputs/figures and outputs/tables.")
