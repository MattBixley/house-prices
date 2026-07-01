# 02_features.R -------------------------------------------------------------
# The tidymodels preprocessing recipe. Operates on the PROCESSED data produced
# by R/03_engineer.R (data/processed/{train,test}.csv), which already carries
# the "None"-recoded categoricals, zero-filled absent numerics, and the derived
# size/age features (TotalSF, TotalBath, HouseAge, ...). This recipe only does
# per-row, estimated-from-training steps: impute the genuinely-missing values,
# tame skew, encode, normalise, and append principal components.
#
# The recipe works for BOTH train (with SalePrice) and test (no SalePrice).
#
# IMPORTANT — the outcome is modelled on the LOG scale. Kaggle scores this
# competition as RMSE between log(predicted) and log(actual) SalePrice, so every
# model document logs the outcome (SalePrice = log(SalePrice)) BEFORE calling
# make_recipe(), and the submission document exponentiates predictions back to
# dollars. Training on log(SalePrice) with RMSE therefore optimises the exact
# leaderboard metric.

source(here::here("R", "00_setup.R"))

#' Build the House Prices preprocessing recipe.
#'
#' @param data A processed data frame (train, with a LOG-transformed SalePrice,
#'   or test with no SalePrice).
#' @param num_comp Number of principal components to append. Defaults to
#'   `tune()` so the model documents can tune it; pass an integer for a fixed
#'   recipe (e.g. quick experiments).
#' @return An unprepped tidymodels recipe.
make_recipe <- function(data, num_comp = tune()) {

  has_outcome <- "SalePrice" %in% names(data)

  rec <- if (has_outcome) {
    recipe(SalePrice ~ ., data = data)
  } else {
    recipe(~ ., data = data)
  }

  rec <- rec %>%
    # Id is an identifier, not a predictor.
    update_role(Id, new_role = "id") %>%

    # --- Drop near-constant categoricals FIRST ------------------------------
    # A handful of Ames nominals are >99% one value (Utilities, Street, Heating,
    # RoofMatl, Condition2, ...). They carry almost no signal AND they break
    # cross-validation: a rare level can be absent from a fold's analysis set but
    # present in its assessment set, which makes the character->factor coercion
    # fail ("loss of generality"). Removing them up front, while still character,
    # is both defensible (no signal) and the robust fix for that CV error.
    step_nzv(all_nominal_predictors()) %>%

    # --- Imputation ---------------------------------------------------------
    # LotFrontage is genuinely missing (~18%) -> KNN from the other predictors.
    # median/mode mop up the handful of stray one-off NAs that appear only in
    # the test set (MSZoning, KitchenQual, Functional, Electrical, ...).
    step_impute_knn(LotFrontage, neighbors = 5) %>%
    step_impute_median(all_numeric_predictors()) %>%
    step_impute_mode(all_nominal_predictors()) %>%

    # --- Skew ---------------------------------------------------------------
    # Ames areas/prices are heavily right-skewed (LotArea, TotalSF, ...).
    # Yeo-Johnson symmetrises them, which helps the scale-sensitive models
    # (elastic net, SVM, neural net) without hurting the trees.
    step_YeoJohnson(all_numeric_predictors()) %>%

    # --- Nominal handling ---------------------------------------------------
    # Reserve a "new" level for unseen categories (step_novel FIRST), then lump
    # rare levels (e.g. minority Neighborhoods / roof styles) so dummies stay
    # stable across CV folds, then dummy-encode.
    step_novel(all_nominal_predictors()) %>%
    step_other(all_nominal_predictors(), threshold = 0.01, other = "Rare") %>%
    step_dummy(all_nominal_predictors()) %>%

    # Remove zero-variance predictors (constants + dummies that never fire).
    step_zv(all_predictors()) %>%

    # --- Principal components -----------------------------------------------
    # Normalise then append the top `num_comp` PCs as EXTRA features
    # (keep_original_cols = TRUE). num_comp defaults to tune(); normalisation
    # also benefits the (non-scale-invariant) neural net, SVM and elastic net.
    step_normalize(all_numeric_predictors()) %>%
    step_pca(all_numeric_predictors(),
             num_comp           = num_comp,
             keep_original_cols = TRUE,
             prefix             = "PC")

  rec
}
