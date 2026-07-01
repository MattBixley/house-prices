# Kaggle Setup Guide (House Prices)

This guide gets you from zero to submitting predictions on the Kaggle
[Housing Prices Competition for Kaggle Learn Users](https://www.kaggle.com/competitions/home-data-for-ml-course)
leaderboard. Written for R / ggplot users who are new to Kaggle.

> **Note on data:** For offline development this project ships the Ames CSVs from
> a public GitHub mirror in `data/raw/` (`train.csv`, `test.csv`,
> `sample_submission.csv`, `data_description.txt`). Those are identical to the
> official Kaggle files. The **authoritative** source is Kaggle itself — use the
> `kaggle` CLI download below once you are authenticated.

---

## 1. Create a Kaggle account and accept the rules

1. Sign up at <https://www.kaggle.com> (free; Google sign-in works).
2. Go to the competition page:
   <https://www.kaggle.com/competitions/home-data-for-ml-course>.
3. Click **Join Competition** and accept the rules. **You must do this** — the
   API will refuse to download data or accept submissions until you have
   accepted the competition rules in the browser.

---

## 2. Generate your API token (`kaggle.json`)

1. Click your avatar (top right) → **Settings**.
2. Scroll to the **API** section → **Create New Token**.
3. Your browser downloads `kaggle.json` (username + secret key — treat it like a
   password, never commit it).
4. Move it into place and lock down the permissions:

   ```bash
   mkdir -p ~/.kaggle
   mv ~/Downloads/kaggle.json ~/.kaggle/
   chmod 600 ~/.kaggle/kaggle.json
   ```

The `chmod 600` step matters — the CLI warns (and on some systems refuses to
run) if the file is world-readable.

---

## 3. Verify the CLI

```bash
export PATH="$HOME/.local/bin:$PATH"   # add to ~/.bashrc to make it permanent
kaggle --version
```

---

## 4. Download the data the "real" way

Once authenticated, pull the official competition files:

```bash
kaggle competitions download -c home-data-for-ml-course -p data/raw
unzip data/raw/home-data-for-ml-course.zip -d data/raw
```

This gives you `data/raw/train.csv` (1460 rows, includes `SalePrice`),
`data/raw/test.csv` (1459 rows, no `SalePrice`), `sample_submission.csv`, and
`data_description.txt`. These overwrite the mirror copies — that is fine, they
are the same data.

---

## 5. Submit predictions to the leaderboard

The Quarto submission document generates one CSV per model into `models/`,
named `submission_<model>.csv` where `<model>` is one of `xgboost`, `rf`,
`nnet`, `elasticnet`, `svm`, `mars`, or `stack`. Each file has exactly two
columns — `Id,SalePrice` — one row per test house, with `SalePrice` in dollars.

General form:

```bash
kaggle competitions submit -c home-data-for-ml-course -f models/submission_<model>.csv -m "<message>"
```

Concrete examples:

```bash
kaggle competitions submit -c home-data-for-ml-course -f models/submission_xgboost.csv -m "xgboost baseline"
kaggle competitions submit -c home-data-for-ml-course -f models/submission_stack.csv  -m "stacked ensemble"
```

The `-m` message shows up next to your score so you can tell submissions apart.

---

## 6. Check your score and submission history

```bash
kaggle competitions submissions -c home-data-for-ml-course
kaggle competitions leaderboard  -c home-data-for-ml-course --show
```

The score is **RMSE on log(SalePrice)** — lower is better. A stacked tidymodels
ensemble on these features typically lands around **0.12–0.13**.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `403 Forbidden` on download/submit | You have not accepted the competition rules — do step 1.3 in the browser. |
| `kaggle: command not found` | Add `~/.local/bin` to your `PATH` (step 3). |
| `Could not find kaggle.json` | It must live at `~/.kaggle/kaggle.json` (step 2). |
| Warning about insecure permissions | `chmod 600 ~/.kaggle/kaggle.json`. |
