# =============================================================================
# 05_lasso.R
# LASSO-regularized logistic regression with 10-fold CV
# Compares lambda.min vs lambda.1se (RMSE, Brier, AUC, confusion matrix)
# 80/20 train-test split, cutoff = 0.8
# =============================================================================

source("R/00_setup.R")
df_model <- readRDS(file.path(paths$processed, "df_model.rds"))

set.seed(123)
idx   <- createDataPartition(df_model$on_time_bin, p = 0.8, list = FALSE)

form  <- on_time_bin ~ year + nei_top10 + reason_top5 + dep_top5 + source

# Build one design matrix so train and test share identical dummy columns
X_all <- model.matrix(form, data = df_model)[, -1]
y_all <- df_model$on_time_bin

x_train <- X_all[idx, , drop = FALSE];  y_train <- y_all[idx]
x_test  <- X_all[-idx, , drop = FALSE]; y_test  <- y_all[-idx]

# ---- Cross-validated LASSO --------------------------------------------------
cv_fit <- cv.glmnet(x_train, y_train, family = "binomial", alpha = 1, nfolds = 10)
cat("lambda.min:", signif(cv_fit$lambda.min, 3),
    "| lambda.1se:", signif(cv_fit$lambda.1se, 3), "\n")

# plot.cv.glmnet already draws dashed lines at lambda.min and lambda.1se
png(file.path(paths$figures, "fig09_lasso_cv.png"), width = 2100, height = 1500, res = 300)
par(mar = c(5, 5, 6, 2))
plot(cv_fit, main = "LASSO Cross-Validation (Binomial Deviance)")
dev.off()

# ---- Helpers ----------------------------------------------------------------
predict_p <- function(x, s) as.numeric(predict(cv_fit, newx = x, s = s, type = "response"))
rmse      <- function(y, p) sqrt(mean((y - p)^2))
brier     <- function(y, p) mean((y - p)^2)

get_coef_table <- function(s) {
  co <- coef(cv_fit, s = s)
  tibble(term = rownames(co), estimate = as.numeric(co)) %>%
    filter(estimate != 0, term != "(Intercept)") %>%
    arrange(desc(abs(estimate)))
}

# ---- Compare lambda.min and lambda.1se --------------------------------------
results <- map_dfr(c("lambda.min", "lambda.1se"), function(s) {
  p_tr <- predict_p(x_train, s)
  p_te <- predict_p(x_test,  s)
  cm   <- confusionMatrix(factor(ifelse(p_te >= CUTOFF, 1, 0), levels = c(0, 1)),
                          factor(y_test, levels = c(0, 1)), positive = "1")
  tibble(
    Model          = s,
    Lambda         = cv_fit[[s]],
    Nonzero_Coefs  = nrow(get_coef_table(s)),
    RMSE_Train     = rmse(y_train, p_tr),
    RMSE_Test      = rmse(y_test,  p_te),
    Brier_Test     = brier(y_test, p_te),
    AUC_Test       = as.numeric(auc(roc(y_test, p_te, quiet = TRUE))),
    Accuracy       = cm$overall["Accuracy"],
    Sensitivity    = cm$byClass["Sensitivity"],
    Specificity    = cm$byClass["Specificity"],
    Balanced_Acc   = cm$byClass["Balanced Accuracy"],
    Kappa          = cm$overall["Kappa"]
  )
})
print(results)

results %>%
  gt() %>%
  fmt_number(columns = -c(Model, Lambda, Nonzero_Coefs), decimals = 4) %>%
  fmt_scientific(columns = Lambda, decimals = 2) %>%
  tab_header(title = "LASSO: lambda.min vs lambda.1se") %>%
  apa_style() %>%
  gtsave(file.path(paths$tables, "table05_lasso_comparison.html"))

# ---- Final model coefficients (lambda.1se) ----------------------------------
coef_1se <- get_coef_table("lambda.1se")
print(coef_1se)

coef_1se %>%
  gt() %>%
  fmt_number(columns = estimate, decimals = 3) %>%
  tab_header(title = "Non-zero LASSO Coefficients (lambda.1se)") %>%
  apa_style() %>%
  gtsave(file.path(paths$tables, "table06_lasso_coefficients.html"))

# Coefficient plot (visual version of the table above)
p_coef <- coef_1se %>%
  mutate(
    term      = str_remove(term, "^(nei_top10|reason_top5|dep_top5|source)"),
    direction = if_else(estimate > 0, "Higher odds of on-time", "Lower odds of on-time")
  ) %>%
  ggplot(aes(x = reorder(term, estimate), y = estimate, fill = direction)) +
  geom_col() +
  coord_flip() +
  scale_fill_manual(values = c("Higher odds of on-time" = "steelblue",
                               "Lower odds of on-time"  = "firebrick")) +
  labs(title = "LASSO Coefficients (lambda.1se)",
       x = NULL, y = "Coefficient (log-odds)", fill = NULL) +
  theme(legend.position = "bottom")
ggsave(file.path(paths$figures, "fig11_lasso_coefficients.png"),
       p_coef, width = 8, height = 6, dpi = 300)

# ---- ROC comparison ---------------------------------------------------------
roc_1se <- roc(y_test, predict_p(x_test, "lambda.1se"), quiet = TRUE)
roc_min <- roc(y_test, predict_p(x_test, "lambda.min"), quiet = TRUE)

png(file.path(paths$figures, "fig10_lasso_roc_comparison.png"), width = 1800, height = 1500, res = 300)
plot(roc_1se, col = "blue", main = "ROC: lambda.1se vs lambda.min")
plot(roc_min, add = TRUE, col = "red", lwd = 2)
legend("bottomright", bty = "n", lty = 1, col = c("blue", "red"),
       legend = c(paste0("lambda.1se AUC = ", round(auc(roc_1se), 3)),
                  paste0("lambda.min AUC = ", round(auc(roc_min), 3))))
dev.off()

saveRDS(cv_fit, file.path(paths$processed, "lasso_cv_fit.rds"))
