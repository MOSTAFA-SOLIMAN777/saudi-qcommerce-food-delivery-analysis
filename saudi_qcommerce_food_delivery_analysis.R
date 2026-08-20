# ============================================================
# Saudi Q-Commerce & Food Delivery Market Analysis
# ============================================================
#
# Purpose:
#   Clean and reproducible version of the original R analysis.
#
# Expected input:
#   saudi_food_delivery.csv
#
# Main analyses:
#   1. Data import and validation
#   2. Data cleaning and type conversion
#   3. Basic exploratory analysis
#   4. Revenue analysis by restaurant type
#   5. Multiple regression models for customer ratings
#   6. Export of model results
#
# ------------------------------------------------------------


# ------------------------------------------------------------
# 1. Packages
# ------------------------------------------------------------

library(readr)
library(dplyr)
library(broom)
library(knitr)


# ------------------------------------------------------------
# 2. Reproducibility and output folders
# ------------------------------------------------------------

dir.create("outputs", showWarnings = FALSE)


# ------------------------------------------------------------
# 3. Import data
# ------------------------------------------------------------

df <- read_csv("saudi_food_delivery.csv")

# Inspect the dataset
glimpse(df)
summary(df)
colnames(df)


# ------------------------------------------------------------
# 4. Validate required columns
# ------------------------------------------------------------

required_columns <- c(
  "Total Bill (in Saudi Riyals)",
  "Delivery Duration (in minutes)",
  "Customer Rating (from 1 to 5 stars)",
  "Restaurant Type",
  "Rush Time",
  "hour"
)

missing_columns <- setdiff(required_columns, names(df))

if (length(missing_columns) > 0) {
  stop(
    paste(
      "Missing required columns:",
      paste(missing_columns, collapse = ", ")
    )
  )
}


# ------------------------------------------------------------
# 5. Rename variables for easier analysis
# ------------------------------------------------------------

df <- df %>%
  rename(
    total_bill = `Total Bill (in Saudi Riyals)`,
    delivery_duration = `Delivery Duration (in minutes)`,
    customer_rating = `Customer Rating (from 1 to 5 stars)`,
    restaurant_type = `Restaurant Type`,
    rush_time = `Rush Time`
  )


# ------------------------------------------------------------
# 6. Data cleaning and type conversion
# ------------------------------------------------------------

df <- df %>%
  mutate(
    total_bill = as.numeric(total_bill),
    delivery_duration = as.numeric(delivery_duration),
    customer_rating = as.numeric(customer_rating),
    restaurant_type = as.factor(restaurant_type),
    rush_time = as.factor(rush_time),
    hour = as.numeric(hour)
  )


# ------------------------------------------------------------
# 7. Missing-value check
# ------------------------------------------------------------

missing_summary <- data.frame(
  variable = names(df),
  missing_count = colSums(is.na(df)),
  missing_percent = round(colMeans(is.na(df)) * 100, 2)
)

print(missing_summary)

write.csv(
  missing_summary,
  "outputs/missing_values_summary.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 8. Exploratory analysis
# ------------------------------------------------------------

# Orders by rush-time category
orders_by_rush_time <- df %>%
  count(rush_time, name = "orders") %>%
  arrange(desc(orders))

print(orders_by_rush_time)

write.csv(
  orders_by_rush_time,
  "outputs/orders_by_rush_time.csv",
  row.names = FALSE
)


# Orders by hour
orders_by_hour <- df %>%
  count(hour, name = "orders") %>%
  arrange(hour)

print(orders_by_hour)

write.csv(
  orders_by_hour,
  "outputs/orders_by_hour.csv",
  row.names = FALSE
)


# Revenue by restaurant type
revenue_by_restaurant <- df %>%
  group_by(restaurant_type) %>%
  summarise(
    total_revenue = sum(total_bill, na.rm = TRUE),
    average_bill = mean(total_bill, na.rm = TRUE),
    orders = n(),
    .groups = "drop"
  ) %>%
  arrange(desc(total_revenue))

print(revenue_by_restaurant)

write.csv(
  revenue_by_restaurant,
  "outputs/revenue_by_restaurant_type.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 9. Model 1
# ------------------------------------------------------------
#
# Customer Rating explained by:
#   - Total Bill
#   - Delivery Duration
#   - Restaurant Type

model_1 <- lm(
  customer_rating ~
    total_bill +
    delivery_duration +
    restaurant_type,
  data = df
)

summary(model_1)

capture.output(
  summary(model_1),
  file = "outputs/model_1_summary.txt"
)


# ------------------------------------------------------------
# 10. Model 2
# ------------------------------------------------------------
#
# Extended model adding:
#   - Rush Time
#   - Hour of Order

model_2 <- lm(
  customer_rating ~
    total_bill +
    delivery_duration +
    restaurant_type +
    rush_time +
    hour,
  data = df
)

summary(model_2)

capture.output(
  summary(model_2),
  file = "outputs/model_2_summary.txt"
)


# ------------------------------------------------------------
# 11. Clean regression tables
# ------------------------------------------------------------

model_1_results <- tidy(
  model_1,
  conf.int = TRUE
)

model_2_results <- tidy(
  model_2,
  conf.int = TRUE
)

print(
  kable(
    model_1_results,
    digits = 3,
    caption = "Regression Results: Model 1"
  )
)

print(
  kable(
    model_2_results,
    digits = 3,
    caption = "Regression Results: Model 2"
  )
)

write.csv(
  model_1_results,
  "outputs/model_1_coefficients.csv",
  row.names = FALSE
)

write.csv(
  model_2_results,
  "outputs/model_2_coefficients.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 12. Model-level statistics
# ------------------------------------------------------------

model_comparison <- bind_rows(
  glance(model_1) %>% mutate(model = "Model 1"),
  glance(model_2) %>% mutate(model = "Model 2")
) %>%
  select(
    model,
    r.squared,
    adj.r.squared,
    sigma,
    statistic,
    p.value,
    AIC,
    BIC,
    df.residual,
    nobs
  )

print(model_comparison)

write.csv(
  model_comparison,
  "outputs/model_comparison.csv",
  row.names = FALSE
)


# ------------------------------------------------------------
# 13. Final console summary
# ------------------------------------------------------------

cat("\n============================================\n")
cat("ANALYSIS COMPLETE\n")
cat("============================================\n")

cat(
  "\nNumber of observations:",
  nrow(df),
  "\n"
)

cat(
  "Model 1 R-squared:",
  round(summary(model_1)$r.squared, 4),
  "\n"
)

cat(
  "Model 2 R-squared:",
  round(summary(model_2)$r.squared, 4),
  "\n"
)

cat(
  "Model 2 adjusted R-squared:",
  round(summary(model_2)$adj.r.squared, 4),
  "\n"
)

cat(
  "\nOutputs saved to the /outputs folder.\n"
)
