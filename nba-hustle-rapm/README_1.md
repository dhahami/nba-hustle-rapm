# 🏀 Quantifying the Impact of NBA Hustle Plays on RAPM

**Dylan Hahami | St. John's University, Queens, NY**  
**Contact:** dhahami5@gmail.com

---

## Overview

This project investigates whether NBA "hustle" plays — deflections, contested shots, screen assists, loose balls recovered, and box outs — have a meaningful relationship with a player's overall on-court impact as measured by **Regularized Adjusted Plus-Minus (RAPM)**.

Starting in the 2015-16 season, the NBA began officially tracking hustle statistics. This research bridges the traditional eye-test with advanced analytics by constructing a composite **Hustle Index** and evaluating its predictive power using linear regression and Random Forest models.

---

## Key Findings

- The Hustle Index shows only a **weak linear correlation (r = 0.21)** with RAPM, with just a **4% coefficient of determination (R²)**.
- Random Forest modeling showed that adding the Hustle Index improved predictive accuracy only marginally (88% → 89%), a statistically insignificant improvement.
- **Offensive and defensive efficiency** remain the dominant predictors of RAPM.
- Hustle Index is most meaningful for **differentiating role players**, whose value often stems entirely from high-effort plays.
- The analysis is slightly skewed because front-court players disproportionately perform screen assists and box-outs.

---

## Case Studies

| Player | RAPM | Hustle Index | Profile |
|---|---|---|---|
| Kawhi Leonard | 8.20 | 0.36 | Elite RAPM via efficiency, not hustle |
| Alex Caruso | 4.49 | 0.83 | Impact driven directly by hustle stats |
| Gary Payton II | 0.82 | 1.81 | Highest hustle, modest RAPM |
| Nikola Jokić | 6.68 | 0.73 | Top RAPM with above-average hustle |

---

## Data Sources

| Dataset | Source |
|---|---|
| NBA Hustle Stats (2015–2024) | [NBA.com/stats](https://www.nba.com/stats/players/hustle) |
| 5-Year 6-Factor RAPM | [nbarapm.com](https://www.nbarapm.com/datasets/six_factor) |

---

## Methodology

### 1. Data Collection & Scraping
- **`HustleScrape.ipynb`** — Python notebook scraping hustle stats from NBA.com
- **`RAPMscrape.ipynb`** — Python notebook scraping 5-Year 6-Factor RAPM data

### 2. Pre-Processing (`Hustle.R`)
- Converted all hustle stats to **per-36 minutes** to normalize playing time
- Filtered fringe players with a **500 minute minimum per season**
- Computed **5-year averages (2019-20 through 2023-24)** to align with 5-Year RAPM
- Removed outliers using z-score threshold (|z| < 3)

### 3. Hustle Index Construction
- Ran a linear regression of each hustle stat against RAPM to extract **data-driven weights**
- Combined standardized hustle stats into a single composite score:

```
HI = 0.35·Deflections + 0.28·ContestedShots + 0.18·ScreenAssists 
      + 0.11·LooseBalls + 0.08·BoxOuts
```
*(weights derived from normalized linear regression coefficients)*

### 4. Machine Learning Models
- **Decision Tree** — Baseline model for RAPM prediction using 6-Factor stats + Hustle Index
- **Random Forest (n=500 trees)** — Evaluated feature importance; Hustle Index ranked below all 6-Factor components

---

## Repository Structure

```
nba-hustle-rapm/
│
├── README.md                  # This file
├── poster/
│   └── Hustle_and_RAPM.pdf    # Research poster (St. John's University)
│
├── notebooks/
│   ├── HustleScrape.ipynb     # NBA hustle stats scraper
│   └── RAPMscrape.ipynb       # RAPM data scraper
│
├── analysis/
│   └── Hustle.R               # Full R analysis: EDA, Hustle Index, ML models
│
└── data/                      # (not tracked — see Data Sources above to reproduce)
    ├── hustle_stats.csv
    └── rapm_5yr.csv
```

---

## Requirements

### Python (scraping)
```
requests
pandas
jupyter
```

### R (analysis)
```r
install.packages(c("ggplot2", "patchwork", "dplyr", "tidyverse",
                   "caret", "rpart", "rpart.plot", "randomForest"))
```

---

## How to Reproduce

1. **Scrape the data** — Run `HustleScrape.ipynb` and `RAPMscrape.ipynb` to pull raw data
2. **Run the analysis** — Open `Hustle.R` in RStudio; update file paths to point to your scraped CSVs
3. **View results** — Plots and model outputs will render in RStudio's Plots pane

---

## Results Summary

| Model | R² | RMSE |
|---|---|---|
| Decision Tree | ~0.85 | — |
| Random Forest (without HI) | ~0.88 | — |
| Random Forest (with HI) | ~0.89 | — |

The marginal improvement from including Hustle Index confirms it is a supplementary, not primary, predictor.

---

## Future Work

- Explore hustle's role specifically among **non-star / role players** where the signal may be stronger
- Investigate **positional adjustments** to correct for front-court bias in screen assists and box-outs
- Expand to **play-by-play** data to connect hustle events directly to possession outcomes

---

*Research conducted as part of academic coursework at St. John's University.*
