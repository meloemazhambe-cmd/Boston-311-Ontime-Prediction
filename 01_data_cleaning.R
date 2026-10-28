# =============================================================================
# 01_data_cleaning.R
# Load 2015–2019 Boston 311 data, clean, engineer features, reduce categories
# Output: data/processed/df_need.rds  (all cleaned cases)
#         data/processed/df_model.rds (top categories, binary outcome)
# =============================================================================

source("R/00_setup.R")

# ---- 1. Load and combine yearly files ---------------------------------------
years <- 2015:2019
df <- map_dfr(years, ~ read.csv(file.path(paths$raw, paste0(.x, ".csv"))))

# ---- 2. Keep relevant variables ---------------------------------------------
df_need <- df %>%
  select(open_dt, closed_dt, on_time, case_status, subject,
         neighborhood, type, department, source, reason)

# ---- 3. Clean blanks -> NA and drop incomplete rows -------------------------
df_need <- df_need %>%
  mutate(across(c(on_time, neighborhood, department, reason, source),
                ~ na_if(str_squish(.x), ""))) %>%
  filter(!is.na(on_time), !is.na(neighborhood), !is.na(department),
         !is.na(reason), !is.na(source))

# ---- 4. Feature engineering -------------------------------------------------
# Resolution time in HOURS (many cases close the same day, so days lose precision)
df_need <- df_need %>%
  mutate(
    open_time  = as.POSIXct(open_dt,   format = "%Y-%m-%d %H:%M:%S"),
    close_time = as.POSIXct(closed_dt, format = "%Y-%m-%d %H:%M:%S"),
    time       = as.numeric(difftime(close_time, open_time, units = "hours")),
    year       = year(open_time)
  )

cat("Class balance (all cleaned cases):\n")
print(prop.table(table(df_need$on_time)))

# ---- 5. Category reduction --------------------------------------------------
# Top 5 reasons, top 10 neighborhoods, top 5 departments by volume
top_n_levels <- function(data, var, n) {
  data %>% count({{ var }}, sort = TRUE) %>% slice_head(n = n) %>% pull({{ var }})
}

top5_reason <- top_n_levels(df_need, reason, 5)
top10_nei   <- top_n_levels(df_need, neighborhood, 10)
top5_dep    <- top_n_levels(df_need, department, 5)

df_model <- df_need %>%
  filter(reason       %in% top5_reason,
         neighborhood %in% top10_nei,
         department   %in% top5_dep) %>%
  mutate(
    on_time_bin  = case_when(on_time == "ONTIME"  ~ 1L,
                             on_time == "OVERDUE" ~ 0L,
                             TRUE ~ NA_integer_),
    reason_top5  = factor(reason),
    nei_top10    = factor(neighborhood),
    dep_top5     = factor(department),
    source       = factor(source)
  ) %>%
  filter(!is.na(on_time_bin))

cat("\nModeling dataset rows:", nrow(df_model), "\n")

# ---- 6. Save ----------------------------------------------------------------
saveRDS(df_need,  file.path(paths$processed, "df_need.rds"))
saveRDS(df_model, file.path(paths$processed, "df_model.rds"))
