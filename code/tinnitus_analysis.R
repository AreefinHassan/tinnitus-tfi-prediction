# Predicting Tinnitus Functional Index (TFI) Reduction
# MATH 6333 Statistical Learning — Fall 2022, University of Texas Rio Grande Valley
# Author: Areefin-Ul-Hassan Chowdhury
#
# Goal: predict how much a tinnitus patient's TFI score drops after treatment,
# and find which patient factors drive that reduction.
#
# Results (test set, n = 27):
#   Best linear model (PHQ + ISI + SWLS) ..... test MSE 534.7406
#   KNN regression (k = 10) .................. test MSE 302.9401
#   PHQ (depression score) is the most influential predictor (lowest p-value).
#   KNN wins on MSE, but unlike linear regression it cannot show each
#   variable's separate influence on TFI reduction.
#
# NOTE: the dataset (CaseStudy1.csv) is not committed to this repo.
# Place it in data/ before running this script.

# ------------------------------------------------------------------
# 1. Setup
# ------------------------------------------------------------------
library(Hmisc)
library(lessR)
library(tidyverse)
library(caret)
library(leaps)   # best-subsets regression
library(car)     # VIF

# ------------------------------------------------------------------
# 2. Load and explore the data
# ------------------------------------------------------------------
mydata <- read.csv("data/CaseStudy1.csv")
head(mydata)
dim(mydata)
class(mydata)
summary(mydata)

# Clean a trailing space in the Group labels
mydata$Group[mydata$Group == "Control "] <- "Control"

# ------------------------------------------------------------------
# 3. Descriptive analysis: pie charts and histograms
# ------------------------------------------------------------------
# Gender: 56% male / 44% female; Group: 51% control / 49% treatment
Gender1 <- mydata$Gender
Gender1 <- gsub(1, "Male", Gender1)
Gender1 <- gsub(2, "Female", Gender1)

PieChart(Gender1, hole = 0, values = "%", data = mydata,
         fill = c("brown2", "darkcyan"), main = "Gender")

PieChart(Group, hole = 0, values = "%", data = mydata,
         fill = c("chartreuse3", "cadetblue4"), main = "Group")

# Histograms of the quantitative variables:
# HHI_Score, GAD, PHQ, ISI, SWLS, Hyperacusis, CFQ
hist.data.frame(mydata[, c(3:9)])

# ------------------------------------------------------------------
# 4. Correlation analysis
# ------------------------------------------------------------------
# Highest: GAD vs PHQ (0.76). Lowest: PHQ vs SWLS (-0.36).
CoM1 <- cor(mydata[, c(3:9)])
round(CoM1, 2)

# ------------------------------------------------------------------
# 5. Missing values and the response variable
# ------------------------------------------------------------------
# Post TFI scores have missing values: fill them with the column mean
# (mean imputation), then define the response as the TFI reduction.
is.na(mydata$Post_TFI_Score)
which(is.na(mydata$Post_TFI_Score))
mean(mydata$Post_TFI_Score, na.rm = TRUE)
mydata$Post_TFI_Score[is.na(mydata$Post_TFI_Score)] <-
  mean(mydata$Post_TFI_Score, na.rm = TRUE)

mydata$TFI_Reduction <- (mydata$Pre_TFI_Score - mydata$Post_TFI_Score)
head(mydata)

# ------------------------------------------------------------------
# 6. Train / test split (80 / 20)
# ------------------------------------------------------------------
set.seed(1)
trainIndex <- createDataPartition(y = mydata$TFI_Reduction, p = 0.8, list = FALSE)

head(trainIndex)
mydataTrain <- mydata[trainIndex, ]
mydataTest  <- mydata[-trainIndex, ]
dim(mydataTrain)
dim(mydataTest)

# Predictors used in the models: columns 3:9 (HHI_Score, GAD, PHQ, ISI,
# SWLS, Hyperacusis, CFQ) plus column 15 (TFI_Reduction, the response).

# ------------------------------------------------------------------
# 7. Backward selection (10-fold CV)
# ------------------------------------------------------------------
train.control <- trainControl(method = "cv", number = 10, savePredictions = TRUE)

step.modelbackward <- train(TFI_Reduction ~ ., data = mydataTrain[, c(3:9, 15)],
                            method = "leapBackward",
                            tuneGrid = data.frame(nvmax = 1:7),
                            trControl = train.control)
step.modelbackward$results
step.modelbackward$bestTune
summary(step.modelbackward$finalModel)
# 4-variable model (GAD, PHQ, ISI, SWLS): lowest RMSE, close to 16.5
coef(step.modelbackward$finalModel, 4)
plot(step.modelbackward)

# ------------------------------------------------------------------
# 8. Forward selection (10-fold CV)
# ------------------------------------------------------------------
train_control <- trainControl(method = "cv", number = 10, savePredictions = TRUE)

step.modelforward <- train(TFI_Reduction ~ ., data = mydataTrain[, c(3:9, 15)],
                           method = "leapForward",
                           tuneGrid = data.frame(nvmax = 1:7),
                           trControl = train_control)
plot(step.modelforward)
step.modelforward$results
step.modelforward$bestTune
summary(step.modelforward$finalModel)
# 3-variable model (PHQ, ISI, SWLS): lowest RMSE, below 16.5
coef(step.modelforward$finalModel, 3)

# ------------------------------------------------------------------
# 9. Best-subset selection (RSS, adjusted R^2, Cp, BIC)
# ------------------------------------------------------------------
regfit.full <- regsubsets(TFI_Reduction ~ ., data = mydataTrain[, c(3:9, 15)])
summary(regfit.full)

regfit.full <- regsubsets(TFI_Reduction ~ ., data = mydataTrain[, c(3:9, 15)], nvmax = 7)
reg.summary <- summary(regfit.full)
names(reg.summary)
reg.summary$rsq

par(mfrow = c(2, 2))
plot(reg.summary$rss, xlab = "Number of Variables", ylab = "RSS", type = "l")

plot(reg.summary$adjr2, xlab = "Number of Variables", ylab = "Adjusted RSq", type = "l")
which.max(reg.summary$adjr2)
points(3, reg.summary$adjr2[3], col = "red", cex = 2, pch = 20)

plot(reg.summary$cp, xlab = "Number of Variables", ylab = "Cp", type = "l")
which.min(reg.summary$cp)
points(3, reg.summary$cp[3], col = "red", cex = 2, pch = 20)

plot(reg.summary$bic, xlab = "Number of Variables", ylab = "BIC", type = "l")
which.min(reg.summary$bic)
points(3, reg.summary$bic[3], col = "red", cex = 2, pch = 20)

# RSS, adjusted R^2, Cp and BIC all point to the same 3-variable solution.
plot(regfit.full, scale = "r2")
plot(regfit.full, scale = "adjr2")
plot(regfit.full, scale = "Cp")
plot(regfit.full, scale = "bic")
coef(regfit.full, 3)

# ------------------------------------------------------------------
# 10. Best model and diagnostics
# ------------------------------------------------------------------
# PHQ, ISI, SWLS: coefficients 0.772, 0.726, -0.552; intercept 19.486.
Best_model <- lm(TFI_Reduction ~ PHQ + ISI + SWLS, data = mydataTrain[, c(3:9, 15)])
summary(Best_model)
anova(Best_model)

car::vif(Best_model)

# Diagnostic plots: residuals vs fitted, normal Q-Q, scale-location,
# residuals vs leverage. No outliers beyond 3 SD; points above the
# leverage threshold 2(p+1)/n = 2(3+1)/115 = 0.069 have somewhat
# higher leverage (#57, #62, #3 are the most extreme).
par(mfrow = c(2, 2))
plot(Best_model)

# ------------------------------------------------------------------
# 11. Predictions and test MSE (linear model)
# ------------------------------------------------------------------
model.pred <- predict(Best_model, mydataTest)
par(mfrow = c(1, 1))
plot(model.pred)
summary(model.pred)

pre_T <- data.frame(actual = mydataTest$TFI_Reduction, predicted = model.pred)

# Test MSE of the best linear model: 534.7406
MSE <- mean((mydataTest$TFI_Reduction - model.pred)^2)
MSE

names(mydataTrain)

# ------------------------------------------------------------------
# 12. KNN regression (k = 2, 4, 6, 8, 10; 10-fold CV)
# ------------------------------------------------------------------
model_knns <- train(TFI_Reduction ~ ., data = mydataTrain[, c(3:9, 15)],
                    method = "knn",
                    tuneGrid = expand.grid(k = c(2, 4, 6, 8, 10)),
                    trControl = trainControl(method = "cv", number = 10,
                                             verboseIter = TRUE))
summary(model_knns)
model_knns

# Predictions on the test data
model_predict <- predict(model_knns, mydataTest)

# Test MSE of the KNN model (k = 10): 302.9401 — better than the linear
# model, but KNN cannot show each variable's separate influence.
output_predict <- data.frame(actual = mydataTest$TFI_Reduction,
                             predicted = model_predict)
mean((output_predict$actual - output_predict$predicted)^2)
