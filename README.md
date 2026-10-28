# Predicting On-Time Performance of Boston 311 Service Requests

**A Logistic Regression and LASSO Approach**

## 📂 Project Deep Dive

### Project Overview

**Dataset:** [Analyze Boston – City of Boston Open Data](https://data.boston.gov/) (311 Service Requests, 2015–2019)

Boston's 311 system is the city's main channel for non-emergency service requests: potholes, street cleaning, abandoned vehicles, code enforcement and more. This project analyzes **1,199,430 service requests from 2015–2019** to predict whether a request will be resolved **on time or overdue** relative to its service-level agreement (SLA), and to identify which case characteristics drive delays.

### Research Questions

1. How accurately can we classify a request as on-time or overdue using information available when the case is opened?
2. Which predictors (year, neighborhood, department, request reason, source) are most influential?
3. Do patterns seen in exploratory analysis (differences across years and neighborhoods) remain statistically significant under formal testing?

## 🛠️ Tech Stack & Core Competencies

**Languages & Frameworks:** R (tidyverse, lubridate, stringr, scales, broom, glmnet, caret, pROC, gt, knitr)

**Analytics & Modeling:** Chi-Square Tests of Independence, Logistic Regression, LASSO (L1) Regularization, 10-Fold Cross-Validation, Classification Evaluation (Confusion Matrix, ROC/AUC, Kappa, RMSE)

**Domain Focus:** Public Sector & Municipal Service Analytics, Predictive Modeling, Imbalanced Classification

## Methods

| Step | Method | Purpose |
|------|--------|---------|
| 1 | **Chi-square tests of independence** | Test whether on-time status depends on year and neighborhood (run on train and test sets) |
| 2 | **Logistic regression** | Model P(on-time) from year, neighborhood, reason, department and source |
| 3 | **LASSO (L1) regularization** | Automatic variable selection; compare `lambda.min` vs `lambda.1se` via 10-fold CV |

**Feature engineering and data reduction**

- Resolution time computed in **hours** (many cases close the same day).
- Outcome recoded as binary: `ONTIME = 1`, `OVERDUE = 0`.
- Kept the **top 5 departments** (~90% of cases), **top 10 neighborhoods** (~80%) and **top 5 request reasons** to reduce sparsity and noise.
- Dropped `type` because it largely duplicates `reason`.

## Key Achievements & Objectives

- **Engineered a Modeling-Ready Dataset:** Combined five years of raw 311 records, cleaned blank and missing values, calculated resolution time in hours, and recoded on-time status as a binary outcome.
- **Reduced High-Dimensional Categories:** Focused on the highest-volume departments, neighborhoods and request reasons to improve model stability and interpretability.
- **Validated Patterns with Hypothesis Testing:** Used chi-square tests on both training and test sets to confirm that on-time status depends on year and neighborhood.
- **Built a Predictive Classification Model:** Fitted a logistic regression on a 70/30 train-test split and evaluated it with accuracy, sensitivity, specificity, balanced accuracy and Cohen's Kappa.
- **Applied Regularization for Variable Selection:** Used cross-validated LASSO to reduce the model from 25 to 18 predictors with no loss in predictive accuracy.

## 📈 Key Results

**Class balance:** 79.5% on-time vs 20.5% overdue.

**Chi-square:** Year (χ² = 11,108, df = 4) and neighborhood were both significantly associated with on-time status (p < 2.2e-16), consistently across train and test sets.

**Logistic regression (test set, cutoff = 0.8)**

| Metric | Value |
|--------|-------|
| Accuracy | 81.4% |
| Sensitivity (on-time) | 92.7% |
| Specificity (overdue) | 37.6% |
| Balanced accuracy | 65.1% |
| Cohen's Kappa | 0.35 |

The model identifies on-time cases well but struggles with overdue cases, a typical effect of class imbalance.

**LASSO**

| | lambda.min | lambda.1se (final) |
|---|---|---|
| λ | 0.000327 | 0.00231 |
| Non-zero coefficients | 25 | 18 |
| Test RMSE | 0.3625 | 0.3621 |

The more parsimonious `lambda.1se` model performs essentially the same with 7 fewer predictors.

**Strongest predictors (LASSO, lambda.1se)**

| Lower odds of on-time | Coef. | Higher odds of on-time | Coef. |
|---|---|---|---|
| Highway Maintenance | −2.23 | City Worker App (source) | +1.13 |
| Street Cleaning | −1.50 | Sanitation | +0.39 |
| Inspectional Services (ISD) | −1.40 | Public Works (PWDx) | +0.38 |
| Information Technology (INFO) | −1.25 | Parks (PARK) | +0.36 |

Neighborhood and year effects were smaller but persisted after controlling for request mix.

## 📊 Visual Highlights

| # | Visual | Chart Type | Purpose |
|---|--------|-----------|---------|
| 1 | On-Time Rate by Year | Line chart | Tracks how SLA performance changed from 2015 to 2019 |
| 2 | On-Time Rate by Neighborhood | Horizontal bar chart | Compares on-time rates across the top 10 neighborhoods |
| 3 | Top Request Reasons | Horizontal bar chart | Shows which request types drive the most case volume |
| 4 | LASSO Cross-Validation Curve | Deviance plot | Shows how the regularization parameter (λ) was selected |
| 5 | LASSO Coefficients | Coefficient output | Ranks the predictors that most increase or reduce on-time odds |

### On-Time Rate by Year
Performance jumped from 69.7% in 2015 to 83.0% in 2016, then declined gradually to 80.1% by 2019.

![On-time rate by year](images/ontime_rate_by_year.png)

### On-Time Rate by Neighborhood (Top 10)
On-time rates range from 84.1% in Back Bay to 89.1% in East Boston and Allston/Brighton, a difference confirmed by the chi-square test.

![On-time rate by neighborhood](images/ontime_rate_by_neighborhood.png)

### Top Request Reasons
Street Cleaning and Enforcement & Abandoned Vehicles are the most common request types, followed by Sanitation, Highway Maintenance and Code Enforcement.

![Top request reasons](images/top_request_reasons.png)

### LASSO Cross-Validation Curve
Binomial deviance drops sharply and then flattens. The dotted lines mark `lambda.1se` (18 predictors, the final model) and `lambda.min` (25 predictors).

![LASSO cross-validation curve](images/lasso_cv_curve.png)

### LASSO Coefficients (lambda.1se)
Highway Maintenance (−2.23) and Street Cleaning (−1.50) have the strongest negative effects on on-time completion; the City Worker App (+1.13) has the strongest positive effect.

![LASSO coefficients](images/lasso_coefficients.png)

## 💡 Selected Observations & Insights

- **On-Time Cases Dominate:** Of 1,199,430 requests, 953,219 (79.5%) were resolved on time and 246,211 (20.5%) became overdue. This roughly 4-to-1 imbalance shapes how the models should be evaluated.
- **2015 Was the Weakest Year:** The on-time rate rose from 69.7% in 2015 to 83.0% in 2016, held at 82.9% in 2017, then eased to 80.5% in 2018 and 80.1% in 2019.
- **Request Type Is the Strongest Driver:** Highway Maintenance and Street Cleaning had the largest negative coefficients, while Sanitation was associated with higher on-time odds.
- **Department Matters:** The Inspectional Services and Information Technology departments were linked to lower on-time odds, while Public Works and Parks were linked to higher odds.
- **Internal Reporting Speeds Resolution:** Requests submitted through the City Worker App had much higher on-time odds than other channels, possibly because of more accurate locations and direct routing.
- **The Model Misses Most Overdue Cases:** Despite 81.4% accuracy, specificity of 37.6% means the model identified only about a third of overdue cases. Balanced accuracy (65.1%) and Kappa (0.35) give a more realistic picture.

**Note:** These coefficients describe associations within the dataset. They do not establish that any request type, department or neighborhood directly causes delays.

## ✅ Recommendations

- Target root causes of delays in **highway maintenance** and **street cleaning**.
- Review processes in the **ISD** and **INFO** departments.
- Improve resident-submitted information quality to capture the advantage seen in **City Worker App** requests.
- Address persistent **neighborhood-level disparities** in on-time rates.
- For future modeling, handle imbalance (SMOTE, cost-sensitive learning, threshold tuning) and add seasonal, weather and day-of-week features.

## ⚙️ Repository Architecture & Usage

### Repository Structure

```
boston-311-ontime-prediction/
├── README.md
├── run_all.R                     # Runs the full pipeline in order
├── R/
│   ├── 00_setup.R                # Packages, paths, APA table style
│   ├── 01_data_cleaning.R        # Load, clean, feature engineering, category reduction
│   ├── 02_eda.R                  # Descriptive figures and tables
│   ├── 03_chi_square.R           # Chi-square tests (train & test)
│   ├── 04_logistic_regression.R  # Logistic model, odds ratios, confusion matrix, ROC
│   └── 05_lasso.R                # LASSO CV, lambda comparison, coefficients, ROC
├── data/
│   ├── README.md                 # How to download the data
│   ├── raw/                      # Place 2015.csv – 2019.csv here (not tracked)
│   └── processed/                # Cleaned .rds files (generated, not tracked)
├── images/                       # Figures shown in this README
├── outputs/
│   ├── figures/                  # Generated plots
│   └── tables/                   # Generated gt tables (HTML)
└── docs/
    ├── Final_Project_Report.docx
    ├── Final_Project_Presentation.pptx
    └── original_analysis_script.R  # Original single-file script, kept for reference
```

### How to Reproduce

1. Clone the repository:
   ```bash
   git clone https://github.com/<your-username>/boston-311-ontime-prediction.git
   ```
2. Download the 2015–2019 data from [Analyze Boston](https://data.boston.gov/) into `data/raw/` (see [`data/README.md`](data/README.md)).
3. Open R or RStudio **in the repository root** and run:
   ```r
   source("run_all.R")
   ```
   Missing packages are installed automatically by `R/00_setup.R`.

**R packages:** tidyverse, lubridate, stringr, scales, broom, glmnet, caret, pROC, gt, knitr

## 📋 Data Source & Technical Limitations

### Dataset Profile

This project uses the **311 Service Requests** dataset published by the City of Boston on its open data portal, Analyze Boston, covering 1,199,430 requests submitted between January 2015 and December 2019.

| Field | Description |
|-------|-------------|
| `open_dt` | Date and time the case was opened |
| `closed_dt` | Date and time the case was closed |
| `on_time` | SLA status: ONTIME or OVERDUE (outcome variable) |
| `case_status` | Open or Closed |
| `subject` | Department subject area |
| `neighborhood` | Boston neighborhood of the request |
| `type` | Detailed request type (dropped because it overlaps with `reason`) |
| `department` | Department assigned to the case |
| `source` | Submission channel (Constituent Call, Citizens Connect App, City Worker App, etc.) |
| `reason` | Broad request category |

**Source:** 311 Service Requests — City of Boston via [Analyze Boston](https://data.boston.gov/)

**Dataset License:** [License]

### Limitations

- Data ends in 2019; post-COVID operations may differ.
- Results apply to high-volume categories only.
- Cases are treated as independent (no spatial or temporal clustering).
- Weather, season and time-of-day predictors were not available.

## 🛡️ Academic & Data Integrity Notice

The materials in this public repository are an independent application of data analytics methods to publicly available municipal open data. They contain no proprietary corporate materials, protected institutional data or restricted commercial information.

## Author
**Takudzwa Melody Mazhambe** | [LinkedIn](https://www.linkedin.com/in/your-profile)
