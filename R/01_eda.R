# 01_eda.R ------------------------------------------------------------------
# Exploratory data analysis on the Ames House Prices training set.
# Runnable script version of the EDA; the Quarto doc mirrors this.
# Reads from data/raw/, writes plots to figures/.

source(here::here("R", "00_setup.R"))

train_path <- file.path(path_data_raw, "train.csv")

if (!file.exists(train_path)) {
  message(
    "train.csv not found at ", train_path, ".\n",
    "Download the Kaggle House Prices data into data/raw/ before running EDA."
  )
  if (!interactive()) quit(save = "no", status = 0)
} else {
  train <- readr::read_csv(train_path, show_col_types = FALSE)

  glimpse(train)
  if (requireNamespace("skimr", quietly = TRUE)) print(skimr::skim(train))

  # 1. SalePrice distribution (raw vs log) -----------------------------------
  p_price <- ggplot(train, aes(x = SalePrice)) +
    geom_histogram(bins = 50, fill = house_pal[1]) +
    scale_x_continuous(labels = scales::dollar) +
    labs(title = "SalePrice is right-skewed", x = "SalePrice", y = "Count")

  p_logprice <- ggplot(train, aes(x = log(SalePrice))) +
    geom_histogram(bins = 50, fill = house_pal[2]) +
    labs(title = "log(SalePrice) is roughly normal",
         x = "log(SalePrice)", y = "Count")

  # 2. SalePrice vs OverallQual ----------------------------------------------
  p_qual <- train |>
    mutate(OverallQual = factor(OverallQual)) |>
    ggplot(aes(x = OverallQual, y = SalePrice, fill = OverallQual)) +
    geom_boxplot(show.legend = FALSE) +
    scale_y_continuous(labels = scales::dollar) +
    labs(title = "Price rises steeply with overall quality",
         x = "OverallQual (1-10)", y = "SalePrice")

  # 3. SalePrice vs living area ----------------------------------------------
  p_area <- ggplot(train, aes(x = GrLivArea, y = SalePrice)) +
    geom_point(alpha = 0.4, colour = house_pal[1]) +
    geom_smooth(method = "lm", colour = house_pal[3], se = FALSE) +
    scale_y_continuous(labels = scales::dollar) +
    labs(title = "Above-grade living area drives price",
         x = "GrLivArea (sq ft)", y = "SalePrice")

  ggsave(file.path(path_figures, "eda_saleprice.png"),     p_price,    width = 6, height = 4, dpi = 150)
  ggsave(file.path(path_figures, "eda_saleprice_log.png"), p_logprice, width = 6, height = 4, dpi = 150)
  ggsave(file.path(path_figures, "eda_qual.png"),          p_qual,     width = 6, height = 4, dpi = 150)
  ggsave(file.path(path_figures, "eda_area.png"),          p_area,     width = 6, height = 4, dpi = 150)

  message("EDA plots written to ", path_figures)
}
