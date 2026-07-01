# 03_engineer.R --------------------------------------------------------------
# Deterministic feature engineering that is clearer done up front than inside a
# parsnip recipe: (1) recode the many "NA means None" categorical columns of the
# Ames data, (2) zero-fill numeric columns whose NA means "feature absent"
# (no garage -> GarageArea = 0), and (3) derive a handful of combined size / age
# features. We do this for train AND test and write data/processed/{train,test}.csv.
#
# What we DON'T do here (left to the recipe in R/02_features.R): impute the few
# genuinely-missing values (LotFrontage, and the stray one-off test NAs like
# MSZoning/KitchenQual), dummy-encode, normalise, Yeo-Johnson, PCA. Those are
# per-row, estimated-from-training steps that belong in the recipe so they are
# refit inside every CV fold (no leakage).
#
# Unlike the Titanic build, there is no group/outcome leakage to control here —
# every step below is a per-row, outcome-free transform.
#
# Run standalone:  Rscript R/03_engineer.R   (also used as a Quarto pre-render)

suppressMessages({
  library(tidyverse)
  library(here)
})

# Categorical columns where NA is meaningful: the feature is simply ABSENT
# (no alley, no pool, no basement, ...). Per data_description.txt.
none_cols <- c(
  "Alley", "BsmtQual", "BsmtCond", "BsmtExposure", "BsmtFinType1",
  "BsmtFinType2", "FireplaceQu", "GarageType", "GarageFinish", "GarageQual",
  "GarageCond", "PoolQC", "Fence", "MiscFeature", "MasVnrType"
)

# Numeric columns where NA means "none of it" -> 0. GarageYrBlt NA = no garage.
zero_cols <- c(
  "MasVnrArea", "GarageYrBlt", "GarageCars", "GarageArea",
  "BsmtFinSF1", "BsmtFinSF2", "BsmtUnfSF", "TotalBsmtSF",
  "BsmtFullBath", "BsmtHalfBath"
)

recode_absent <- function(df) {
  df |>
    # MSSubClass is coded as integers but is really a nominal dwelling class.
    mutate(MSSubClass = as.character(MSSubClass)) |>
    mutate(across(any_of(none_cols),  ~ replace_na(.x, "None"))) |>
    mutate(across(any_of(zero_cols),  ~ replace_na(.x, 0)))
}

# Derived size / age / count features. Backticks on the digit-leading Ames
# column names (`1stFlrSF`, `2ndFlrSF`, `3SsnPorch`).
add_derived <- function(df) {
  df |>
    mutate(
      TotalSF      = TotalBsmtSF + `1stFlrSF` + `2ndFlrSF`,
      TotalBath    = FullBath + 0.5 * HalfBath +
                     BsmtFullBath + 0.5 * BsmtHalfBath,
      TotalPorchSF = OpenPorchSF + EnclosedPorch + `3SsnPorch` +
                     ScreenPorch + WoodDeckSF,
      HouseAge     = YrSold - YearBuilt,
      RemodAge     = YrSold - YearRemodAdd,
      IsNew        = if_else(YrSold == YearBuilt, "yes", "no"),
      IsRemodeled  = if_else(YearRemodAdd != YearBuilt, "yes", "no"),
      Has2ndFloor  = if_else(`2ndFlrSF`  > 0, "yes", "no"),
      HasBsmt      = if_else(TotalBsmtSF > 0, "yes", "no"),
      HasGarage    = if_else(GarageArea  > 0, "yes", "no"),
      HasPool      = if_else(PoolArea    > 0, "yes", "no"),
      HasFireplace = if_else(Fireplaces  > 0, "yes", "no"),
      OverallScore = OverallQual * OverallCond
    )
}

engineer <- function() {
  train <- readr::read_csv(here("data", "raw", "train.csv"), show_col_types = FALSE)
  test  <- readr::read_csv(here("data", "raw", "test.csv"),  show_col_types = FALSE)

  train <- train |> recode_absent() |> add_derived()
  test  <- test  |> recode_absent() |> add_derived()

  dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
  readr::write_csv(train, here("data", "processed", "train.csv"))
  readr::write_csv(test,  here("data", "processed", "test.csv"))
  message("Wrote processed data: ", nrow(train), " train / ", nrow(test),
          " test rows, ", ncol(train), " train cols.")
  invisible(list(train = train, test = test))
}

# Run when sourced/executed.
engineer()
