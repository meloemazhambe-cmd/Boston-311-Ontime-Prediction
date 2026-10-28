# =============================================================================
# 04_logistic_regression.R
# Logistic regression: P(on-time) ~ year + neighborhood + reason + department + source
# 70/30 train-test split, cutoff = 0.8
# =============================================================================

source("R/00_setup.R")
df_model <- readRDS(file.path(paths$processed, "df_model.rds"))

set.seed(123)
idx   <- createDataPartition(df_model$on_time_bin, p = 0.7, list = FALSE)
train <- df_model[idx, ]
test  <- df_model[-idx, ]

# ---- Fit --------------------------------------------------------------------
fit <- glm(
  on_time_bin ~ year + nei_top10 + reason_top5 + dep_top5 + source,
  data   = train,
  family = binomial()
)
summary(fit)

# ---- Odds ratio table -------------------------------------------------------
tab_or <- tidy(fit) %>%
  mutate(OR      = exp(estimate),
         CI_low  = exp(estimate - 1.96 * std.error),
         CI_high = exp(estimate + 1.96 * std.error)) %>%
  select(term, estimate, std.error, OR, CI_low, CI_high, p.value) %>%
  arrange(p.value)

tab_or %>%
  gt() %>%
  tab_header(title = "Logistic Regression Results (Odds Ratios)") %>%
  fmt_number(columns = c(estimate, std.error, OR, CI_low, CI_high), decimals = 3) %>%
  fmt_scientific(columns = p.value, decimals = 2) %>%
  apa_style() %>%
  gtsave(file.path(paths$tables, "table04_logistic_odds_ratios.html"))

# ---- Test-set evaluation ----------------------------------------------------
prob_test <- predict(fit, newdata = test, type = "response")
pred_test <- ifelse(prob_test >= CUTOFF, 1, 0)

cm_glm <- confusionMatrix(
  factor(pred_test, levels = c(0, 1)),
  factor(test$on_time_bin, levels = c(0, 1)),
  positive = "1"
)
print(cm_glm)

roc_glm <- roc(test$on_time_bin, prob_test)
cat("Test AUC:", round(auc(roc_glm), 3), "\n")

png(file.path(paths$figures, "fig08_roc_logistic.png"), width = 1800, height = 1500, res = 300)
plot(roc_glm, main = paste0("ROC Curve (Test) — AUC = ", round(auc(roc_glm), 3)))
dev.off()

saveRDS(fit, file.path(paths$processed, "logit_fit.rds"))
