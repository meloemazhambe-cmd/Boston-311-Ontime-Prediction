# =============================================================================
# 02_eda.R
# Exploratory data analysis: distributions, volumes and on-time rates
# Output: outputs/figures/*.png, outputs/tables/*.html
# =============================================================================

source("R/00_setup.R")
df_need  <- readRDS(file.path(paths$processed, "df_need.rds"))
df_model <- readRDS(file.path(paths$processed, "df_model.rds"))

save_plot <- function(p, name, w = 8, h = 5) {
  ggsave(file.path(paths$figures, name), p, width = w, height = h, dpi = 300)
}

# ---- Resolution time --------------------------------------------------------
p_time <- df_need %>%
  filter(!is.na(time), time >= 0, time <= 100) %>%
  ggplot(aes(x = time)) +
  geom_histogram(bins = 100, fill = "steelblue") +
  labs(title = "Resolution Time (cases closed within 100 hours)",
       x = "Hours", y = "Number of Cases")
save_plot(p_time, "fig00_resolution_time.png")

# ---- Figure 1: On-time vs overdue -------------------------------------------
p1 <- ggplot(df_need, aes(x = on_time)) +
  geom_bar(fill = "darkblue") +
  scale_y_continuous(labels = comma) +
  labs(title = "On-Time vs Overdue Cases", x = "Status", y = "Number of Cases")
save_plot(p1, "fig01_ontime_count.png")

# ---- Figure 2: Case volume by year ------------------------------------------
year_group <- df_model %>% count(year)
p2 <- ggplot(year_group, aes(x = year, y = n)) +
  geom_line(linewidth = 1.5, color = "steelblue") +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Number of Cases by Year", x = "Year", y = "Number of Cases")
save_plot(p2, "fig02_cases_by_year.png")

# ---- Table 1: On-time vs overdue by year ------------------------------------
tab_year <- df_need %>%
  filter(on_time %in% c("ONTIME", "OVERDUE")) %>%
  count(year, on_time) %>%
  mutate(year = as.character(year)) %>%
  pivot_wider(names_from = on_time, values_from = n, values_fill = 0) %>%
  mutate(Total = ONTIME + OVERDUE) %>%
  bind_rows(summarise(., year = "Total", across(where(is.numeric), sum)))

tab_year %>%
  gt(rowname_col = "year") %>%
  fmt_number(columns = where(is.numeric), decimals = 0) %>%
  tab_stubhead(label = "Year") %>%
  apa_style() %>%
  gtsave(file.path(paths$tables, "table01_ontime_by_year.html"))

# ---- Figure 3: On-time rate by year -----------------------------------------
on_time_by_year <- df_model %>%
  group_by(year) %>%
  summarise(on_time_rate = mean(on_time_bin == 1), .groups = "drop")

p3 <- ggplot(on_time_by_year, aes(x = year, y = on_time_rate)) +
  geom_line(linewidth = 1.5, color = "steelblue") +
  geom_point(size = 2.5, color = "steelblue") +
  geom_text(aes(label = percent(on_time_rate, accuracy = 0.1)), vjust = 1.5) +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  scale_x_continuous(breaks = on_time_by_year$year) +
  labs(title = "On-Time Rate by Year", x = "Year", y = "On-Time Rate")
save_plot(p3, "fig03_ontime_rate_by_year.png")

# ---- Figure 4: On-time rate, top 10 neighborhoods ---------------------------
nei_summary <- df_model %>%
  group_by(neighborhood) %>%
  summarise(total_cases = n(), on_time_rate = mean(on_time_bin == 1),
            .groups = "drop") %>%
  arrange(desc(on_time_rate))

p4 <- ggplot(nei_summary,
             aes(x = reorder(neighborhood, on_time_rate), y = on_time_rate)) +
  geom_col(fill = "steelblue") +
  geom_text(aes(label = percent(on_time_rate, accuracy = 0.1)),
            hjust = 1.2, color = "white") +
  coord_flip() +
  scale_y_continuous(labels = percent_format(accuracy = 1)) +
  labs(title = "On-Time Rate — Top 10 Neighborhoods",
       x = "Neighborhood", y = "On-Time Rate")
save_plot(p4, "fig04_ontime_rate_neighborhood.png")

# ---- Figure 5: Top 5 departments --------------------------------------------
p5 <- df_model %>%
  count(department) %>%
  ggplot(aes(x = reorder(department, n), y = n)) +
  geom_col(fill = "darkblue") +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Top 5 Departments by Case Count",
       x = "Department", y = "Number of Cases")
save_plot(p5, "fig05_top_departments.png")

# ---- Figure 6: Top 5 reasons ------------------------------------------------
p6 <- df_model %>%
  count(reason_top5) %>%
  ggplot(aes(x = reorder(reason_top5, n), y = n)) +
  geom_col(fill = "steelblue") +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Top Reasons by Case Count", x = "Reason", y = "Number of Cases")
save_plot(p6, "fig06_top_reasons.png")

# ---- Figure 7: Sources ------------------------------------------------------
p7 <- df_need %>%
  filter(!source %in% c("Maximo Integration", "Twitter")) %>%
  count(source) %>%
  ggplot(aes(x = reorder(source, n), y = n)) +
  geom_col(fill = "darkblue") +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Sources by Case Count", x = "Source", y = "Number of Cases")
save_plot(p7, "fig07_sources.png")

# ---- Neighborhood volume table (all neighborhoods) --------------------------
df_need %>%
  filter(on_time %in% c("ONTIME", "OVERDUE")) %>%
  count(neighborhood, on_time) %>%
  pivot_wider(names_from = on_time, values_from = n, values_fill = 0) %>%
  mutate(Total = ONTIME + OVERDUE) %>%
  arrange(desc(Total)) %>%
  bind_rows(summarise(., neighborhood = "Total", across(where(is.numeric), sum))) %>%
  gt(rowname_col = "neighborhood") %>%
  fmt_number(columns = where(is.numeric), decimals = 0) %>%
  apa_style() %>%
  gtsave(file.path(paths$tables, "table02_neighborhood_counts.html"))

message("EDA figures and tables saved to outputs/")
