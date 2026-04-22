# ============================================================
# Hustle Plays & RAPM: NBA Analytics
# Author: Dylan Hahami | St. John's University
# Description: Constructs a Hustle Index from NBA hustle stats
#              and evaluates its relationship with 5-Year RAPM
#              using EDA, linear regression, and Random Forest.
# ============================================================

# ============================================================
# 0. INSTALL & LOAD PACKAGES
# ============================================================
# Uncomment the install lines on first run:
# install.packages(c("ggplot2", "patchwork", "dplyr", "tidyverse",
#                    "caret", "rpart", "rpart.plot", "randomForest"))

library(ggplot2)
library(patchwork)
library(dplyr)
library(tidyverse)
library(caret)
library(rpart)
library(rpart.plot)
library(randomForest)


# ============================================================
# 1. LOAD DATA
# ============================================================
# Load raw hustle stats and RAPM data.
# Replace file paths below with your own CSV paths if needed.

df   <- as.data.frame(nbahustlestats201525)   # hustle stats (all seasons)
rapm <- as.data.frame(nba2024RAPM)            # 5-Year 6-Factor RAPM

# Standardize the PLAYER_ID column name in RAPM for joining
names(rapm)[11] <- "PLAYER_ID"


# ============================================================
# 2. PRE-PROCESSING
# ============================================================

# --- Filter to 5-year window (2019-20 through 2023-24) ---
df5y <- df %>%
  filter(SEASON %in% c("2019-20", "2020-21", "2021-22", "2022-23", "2023-24"))

# --- Compute per-player 5-year averages ---
# All hustle stats are per-36 minutes (normalized for playing time).
df5Y_avg <- df5y %>%
  group_by(PLAYER_NAME, PLAYER_ID) %>%
  summarise(
    Deflections_5Y      = mean(DEFLECTIONS,          na.rm = TRUE),
    ContestedShots_5Y   = mean(CONTESTED_SHOTS,      na.rm = TRUE),
    LooseBalls_5Y       = mean(LOOSE_BALLS_RECOVERED, na.rm = TRUE),
    BoxOuts_5Y          = mean(BOX_OUTS,              na.rm = TRUE),
    ScreenAssists_5Y    = mean(SCREEN_ASSISTS,        na.rm = TRUE),
    Minutes_Total       = sum(MIN,                    na.rm = TRUE),
    Seasons_Played      = n_distinct(SEASON)
  ) %>%
  mutate(AVG_MinPerSeason = Minutes_Total / Seasons_Played) %>%
  ungroup()

# --- Merge with RAPM and apply 500-minute minimum filter ---
merged_5yr <- df5Y_avg %>%
  inner_join(rapm, by = "PLAYER_ID") %>%
  filter(AVG_MinPerSeason >= 500)

# --- Remove statistical outliers (|z-score| >= 3) ---
remove_outliers_z <- function(x, threshold = 3) {
  abs(scale(x)) < threshold
}

merged_5yr <- merged_5yr %>%
  filter(
    remove_outliers_z(Deflections_5Y),
    remove_outliers_z(ContestedShots_5Y),
    remove_outliers_z(ScreenAssists_5Y),
    remove_outliers_z(BoxOuts_5Y),
    remove_outliers_z(LooseBalls_5Y)
  )


# ============================================================
# 3. EXPLORATORY DATA ANALYSIS (EDA)
# ============================================================

# --- Distribution histograms for each hustle stat ---
p_hist1 <- ggplot(merged_5yr, aes(x = ContestedShots_5Y)) +
  geom_histogram(binwidth = 1, fill = "red", color = "black") +
  labs(title = "Contested Shots per 36 (5Y Avg)", x = "Contested Shots", y = "Frequency")

p_hist2 <- ggplot(merged_5yr, aes(x = LooseBalls_5Y)) +
  geom_histogram(binwidth = 1, fill = "skyblue", color = "black") +
  labs(title = "Loose Balls Recovered per 36 (5Y Avg)", x = "Loose Balls", y = "Frequency")

p_hist3 <- ggplot(merged_5yr, aes(x = BoxOuts_5Y)) +
  geom_histogram(binwidth = 1, fill = "green", color = "black") +
  labs(title = "Box Outs per 36 (5Y Avg)", x = "Box Outs", y = "Frequency")

p_hist4 <- ggplot(merged_5yr, aes(x = ScreenAssists_5Y)) +
  geom_histogram(binwidth = 1, fill = "gold", color = "black") +
  labs(title = "Screen Assists per 36 (5Y Avg)", x = "Screen Assists", y = "Frequency")

p_hist5 <- ggplot(merged_5yr, aes(x = Deflections_5Y)) +
  geom_histogram(binwidth = 1, fill = "navy", color = "black") +
  labs(title = "Deflections per 36 (5Y Avg)", x = "Deflections", y = "Frequency")

(p_hist1 | p_hist2) / (p_hist3 | p_hist4 | p_hist5)

# --- Season-level trends (using all post-2017 seasons) ---
df17 <- df[df$SEASON >= "2017-18", ]

df_season_avg <- df17 %>%
  group_by(SEASON) %>%
  summarise(across(c(CONTESTED_SHOTS, DEFLECTIONS,
                     SCREEN_ASSISTS, LOOSE_BALLS_RECOVERED, BOX_OUTS), mean))

ggplot(df_season_avg, aes(x = SEASON, y = CONTESTED_SHOTS, group = 1)) +
  geom_line(color = "red", size = 1) + geom_point() +
  labs(title = "Avg Contested Shots per 36 by Season", x = "Season", y = "Avg per 36")

ggplot(df_season_avg, aes(x = SEASON, y = DEFLECTIONS, group = 1)) +
  geom_line(color = "navy", size = 1) + geom_point() +
  labs(title = "Avg Deflections per 36 by Season", x = "Season", y = "Avg per 36")

# --- Correlation matrix among raw hustle stats ---
cat("\n--- Hustle Stats Correlation Matrix ---\n")
cor(df17[, c("CONTESTED_SHOTS", "DEFLECTIONS",
             "SCREEN_ASSISTS", "LOOSE_BALLS_RECOVERED", "BOX_OUTS")])

# --- Individual hustle stat vs RAPM scatter plots ---
p1 <- ggplot(merged_5yr, aes(x = Deflections_5Y,    y = OVR_RAPM)) +
  geom_point(alpha = 0.6, color = "blue") +
  labs(title = "Deflections vs RAPM", x = "Deflections per 36 (5Y AVG)", y = "RAPM")

p2 <- ggplot(merged_5yr, aes(x = ContestedShots_5Y, y = OVR_RAPM)) +
  geom_point(alpha = 0.6, color = "blue") +
  labs(title = "Contested Shots vs RAPM", x = "Contested Shots per 36 (5Y AVG)", y = "RAPM")

p3 <- ggplot(merged_5yr, aes(x = ScreenAssists_5Y,  y = OVR_RAPM)) +
  geom_point(alpha = 0.6, color = "blue") +
  labs(title = "Screen Assists vs RAPM", x = "Screen Assists per 36 (5Y AVG)", y = "RAPM")

p4 <- ggplot(merged_5yr, aes(x = LooseBalls_5Y,     y = OVR_RAPM)) +
  geom_point(alpha = 0.6, color = "blue") +
  labs(title = "Loose Balls vs RAPM", x = "Loose Balls per 36 (5Y AVG)", y = "RAPM")

p5 <- ggplot(merged_5yr, aes(x = BoxOuts_5Y,        y = OVR_RAPM)) +
  geom_point(alpha = 0.6, color = "blue") +
  labs(title = "Box Outs vs RAPM", x = "Box Outs per 36 (5Y AVG)", y = "RAPM")

(p1 | p2) / (p3 | p4 | p5)


# ============================================================
# 4. HUSTLE INDEX CONSTRUCTION
# ============================================================
# Use linear regression coefficients as data-driven weights
# to combine standardized hustle stats into one composite score.

linear <- lm(
  scale(OVR_RAPM) ~ scale(Deflections_5Y) + scale(ContestedShots_5Y) +
                    scale(ScreenAssists_5Y) + scale(LooseBalls_5Y) + scale(BoxOuts_5Y),
  data = merged_5yr
)
summary(linear)

# Extract and normalize weights (drop intercept)
coefs   <- coef(linear)[-1]
weights <- coefs / sum(abs(coefs))
print(round(weights, 4))

# Compute Hustle Index for each player
merged_5yr$HustleIndex <-
  scale(merged_5yr$Deflections_5Y)    * weights["scale(Deflections_5Y)"]    +
  scale(merged_5yr$ContestedShots_5Y) * weights["scale(ContestedShots_5Y)"] +
  scale(merged_5yr$ScreenAssists_5Y)  * weights["scale(ScreenAssists_5Y)"]  +
  scale(merged_5yr$LooseBalls_5Y)     * weights["scale(LooseBalls_5Y)"]     +
  scale(merged_5yr$BoxOuts_5Y)        * weights["scale(BoxOuts_5Y)"]

cat("Mean Hustle Index:", round(mean(merged_5yr$HustleIndex), 4), "\n")

# --- Hustle Index vs RAPM scatter with LOESS smoother ---
ggplot(merged_5yr, aes(x = HustleIndex, y = OVR_RAPM)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "loess", se = FALSE, color = "red") +
  labs(title = "Hustle Index vs RAPM", x = "Hustle Index", y = "RAPM")

# --- Pearson correlation: Hustle Index vs RAPM ---
cat("\n--- Hustle Index vs RAPM Pearson Correlation ---\n")
correlation <- cor(merged_5yr$OVR_RAPM, merged_5yr$HustleIndex,
                   use = "complete.obs", method = "pearson")
cat("r =", round(correlation, 4), "\n")

cor_test <- cor.test(merged_5yr$OVR_RAPM, merged_5yr$HustleIndex, method = "pearson")
print(cor_test)

# --- Simple linear regression: RAPM ~ Hustle Index ---
summary(lm(OVR_RAPM ~ HustleIndex, data = merged_5yr))


# ============================================================
# 5. MACHINE LEARNING MODELS
# ============================================================

# --- Prepare ML dataset ---
# Features: 6-Factor RAPM components + Hustle Index
# Target: OVR_RAPM
ml_data <- merged_5yr %>%
  select(OVR_RAPM, HustleIndex,
         sc_OFF_REB, sc_OFF_TS, sc_OFF_TOV,
         sc_DEF_TOV, sc_DEF_TS, sc_DEF_REB) %>%
  na.omit()

# --- Train/Test Split (70/30) ---
set.seed(123)
trainIndex <- createDataPartition(ml_data$OVR_RAPM, p = 0.7, list = FALSE)
train <- ml_data[ trainIndex, ]
test  <- ml_data[-trainIndex, ]

# ----------------
# Decision Tree
# ----------------
tree_model <- rpart(OVR_RAPM ~ ., data = train, method = "anova")
rpart.plot(tree_model, main = "Decision Tree for RAPM Prediction")

tree_preds <- predict(tree_model, newdata = test)
cat("\n--- Decision Tree ---\n")
cat("RMSE:", round(RMSE(tree_preds, test$OVR_RAPM), 4), "\n")
cat("R²:  ", round(R2(tree_preds,   test$OVR_RAPM), 4), "\n")

# ----------------
# Random Forest
# ----------------
set.seed(123)
rf_model <- randomForest(OVR_RAPM ~ ., data = train, importance = TRUE, ntree = 500)

rf_preds <- predict(rf_model, newdata = test)
cat("\n--- Random Forest ---\n")
cat("RMSE:", round(RMSE(rf_preds, test$OVR_RAPM), 4), "\n")
cat("R²:  ", round(R2(rf_preds,   test$OVR_RAPM), 4), "\n")

# --- Feature Importance Plot ---
varImpPlot(rf_model, main = "Random Forest Feature Importance")

# --- Partial Dependence Plot: Hustle Index ---
# Requires the 'pdp' package:
# install.packages("pdp")
# library(pdp)
#
# pdp_hustle <- partial(rf_model, pred.var = "HustleIndex",
#                       grid.resolution = 50, train = train)
#
# ggplot(pdp_hustle, aes(x = HustleIndex, y = yhat)) +
#   geom_line(color = "red", size = 1.2) +
#   theme_minimal(base_size = 14) +
#   labs(title = "Partial Dependence: Hustle Index on RAPM",
#        x = "Hustle Index", y = "Predicted RAPM")
