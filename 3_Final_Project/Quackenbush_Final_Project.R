#####------------------------------------------------------------------------------------------------------#####
# Corey Quackenbush
# CS 522 - Data Mining
# Final Project
# 11/25/2020
#####------------------------------------------------------------------------------------------------------#####

library(ggplot2)
library(psych)
library(scales)
library(dbscan)
library(caret)
setwd("/Users/crquack/Documents/Hood/Current Classes/CS 522 - Data Mining/Homework/9 final project/")

#####----------------------------------------- Data Prep ------------------------------------------#####
insurance <- read.table("insurance.csv", header = T, sep = ",")

# Factor children, reorder smoker
insurance$smoker   <- factor(insurance$smoker, levels = c("yes", "no"))
insurance$children <- factor(insurance$children)

######### Discretize BMI ##########
#   Underweight: BMI less than 18.5
# Normal weight: BMI 18.5 to 24.9
#    Overweight: BMI 25 to 29.9
#         Obese: BMI 30 or more

insurance$bmi_category[insurance$bmi < 18.5]                       <- "Underweight"
insurance$bmi_category[insurance$bmi >= 18.5 & insurance$bmi < 25] <- "Normal"
insurance$bmi_category[insurance$bmi >= 25.0 & insurance$bmi < 30] <- "Overweight"
insurance$bmi_category[insurance$bmi >= 30.0]                      <- "Obese"

insurance$bmi_category <- factor(insurance$bmi_category, levels = c("Underweight", "Normal", "Overweight", "Obese"))

# Obese only
insurance$obese <- factor(ifelse(insurance$bmi >= 30, "yes", "no"), levels = c("yes", "no"))

# Look at summary of insurance data frame.
summary(insurance)

# We're interested in predicting total charges so look at distribution of charges.
ggplot(data = insurance, aes(x=charges)) +
  geom_histogram(breaks = seq(0, 65000, 5000), fill = "gray", color = "black") +
  scale_x_continuous(breaks = seq(0, 70000, 10000)) +
  labs(x="Charges", y="Count", title = "Charges Histogram")



#####----------------------------------------- Partition data ------------------------------------------#####
# Set seed to make sample reproducible.
# Split data into testing and training sets. Using ~10% (134) from testing.
set.seed(123)
sampleID <- sample(nrow(insurance), 134, replace = F)

test_set     <- insurance[sampleID, ]
training_set <- insurance[-sampleID, ]



#####----------------------------------------- Prediction model ------------------------------------------#####
# http://www.sthda.com/english/articles/40-regression-analysis/165-linear-regression-essentials-in-r/
#### Check correlation between variables and their distribution.
pairs.panels(training_set[c("age", "sex", "bmi", "children", "smoker", "region", "charges")], stars = T, hist.col = "#00AFBB")

# From above: age, sex, bmi, children, smoker are significant.
# Explore the effects of dropping variables from the model.
summary(lm(charges ~ age + sex + bmi + children + smoker + region, data = training_set))
summary(lm(charges ~ age + sex + bmi + children + smoker, data = training_set))
summary(lm(charges ~ age + bmi + children + smoker, data = training_set))

# Plot final variables
pairs.panels(training_set[c("age", "bmi", "children", "smoker", "charges")], stars = T, hist.col = "#00AFBB")

# Create model with choosen variables.
model_1 <- lm(charges ~ age + bmi + children + smoker, data = training_set)

# About 75% of variation explained by model.
summary(model_1)


###------ Test Model ------###
test_p <- cbind(test_set, predict = predict(model_1, test_set))
test_p <- cbind(test_p, diff = round(abs(test_p$charges-test_p$predict),2))

# RMSE: Compute the prediction error (root-mean-square error).
# Want this value to be low.
M1_RMSE <- round( RMSE(test_p$predict, test_p$charges), 2)
M1_RMSE <- paste("RMSE == ", M1_RMSE, sep = "")

# Compute R-square
# Want this value to be close to 1.
M1_R2 <- round( R2(test_p$predict, test_p$charges), 2)
M1_R2 <- paste("R^2 == ", M1_R2, sep = "")


ggplot(data = test_p, aes(x=predict, y=charges)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  scale_x_continuous(breaks = seq(0, 70000, 5000)) +
  scale_y_continuous(breaks = seq(0, 70000, 5000)) +
  labs(x="Predicted Medical Cost", y="Actual Medical Cost", title="Model 1: Predicted vs Actual Cost") +
  annotate("text", x = 0, y = c(48000, 45000), label = c(M1_RMSE, M1_R2), hjust = 0, parse = TRUE)



#####----------------------------------------- Exploration ------------------------------------------#####
# Focus on variable that were significant above.

# Charges - Sex - Smoker
ggplot(insurance, aes(x=sex, y=charges, fill=smoker)) +
  geom_violin() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  labs(x="", y="Changes", title="Charges by Sex and Smoker") +
  scale_fill_discrete(name = "Smoker")


# Charges - BMI - various
ggplot(insurance, aes(x=bmi, y=charges, color=bmi_category)) +
  geom_point() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  labs(x="BMI", y="Changes", title="Charges by BMI and Category") +
  scale_color_discrete(name = "BMI Category")

ggplot(insurance, aes(x=bmi, y=charges, color=smoker)) +
  geom_point() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  labs(x="BMI", y="Changes", title="Charges by BMI and Smoker") +
  scale_color_discrete(name = "Smoker")

ggplot(insurance, aes(x=bmi, y=charges, color=age)) +
  geom_point() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  labs(x="BMI", y="Changes", title="Charges by BMI and Age") +
  scale_color_continuous(name = "Age")


# Training vs test sets.
# Combine data to make plotting easier.
tt <- rbind(cbind(training_set[ , c("bmi", "charges")], Data = "train"), cbind(test_set[ , c("bmi", "charges")], Data = "test"))

ggplot(data = tt, aes(x=bmi, y=charges, color=Data)) +
  geom_point() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  labs(x="BMI", y="Changes", title="Training vs Test Sets") +
  scale_color_manual(values = c("black", "red"))


# Charges - children - smoker
ggplot(insurance, aes(x=children, y=charges, color = smoker)) +
  geom_jitter() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  labs(x="Number of Children", y="Changes", title="Charges by Number of Children and Smoker") +
  scale_color_discrete(name = "Smoker")


# Charges - age - smoker
ggplot(insurance, aes(x= age, y=charges, color = smoker)) +
  geom_jitter() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 80, 5)) +
  labs(x="Age", y="Changes", title="Charges by Age and Smoker") +
  scale_color_discrete(name = "Smoker")


# Charges - age - smoker - facet
ggplot(insurance, aes(x=age, y=charges, color = smoker)) +
  geom_jitter() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 80, 5)) +
  labs(x="Age", y="Changes") +
  scale_color_discrete(name = "Smoker") +
  facet_grid(.~bmi_category)


# Charges - smoker - obese
ggplot(insurance, aes(x= obese, y=charges, color = smoker)) +
  geom_jitter() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  labs(x="Obese", y="Changes", title="Charges by Obese and Smoker") +
  scale_color_discrete(name = "Smoker")


# Charges - region - smoker
ggplot(insurance, aes(x=region, y=charges, color = smoker)) +
  geom_jitter() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_color_discrete(name = "Smoker") +
  labs(x="Region", y="Changes", title="Charges by Region and Smoker") 



#####----------------------------------------- Adjust Model ------------------------------------------#####
# Change model to account for combined effect of being a smoker and obese.
# Note: smoker*obese is shorthand for "smoker + obese + somker*obese"
model_2 <- lm(charges ~ age + bmi + children + smoker*obese, data = training_set)

# About 86% of variation explained by model.
summary(model_2)


###------ Test Model ------###
test_p <- cbind(test_set, predict = predict(model_2, test_set))
test_p <- cbind(test_p, diff = round(abs(test_p$charges-test_p$predict),2))

# RMSE: Compute the prediction error (root-mean-square error).
# Want this value to be low.
M2_RMSE <- round( RMSE(test_p$predict, test_p$charges), 2)
M2_RMSE <- paste("RMSE == ", M2_RMSE, sep = "")

# Compute R-square
# Want this value to be close to 1.
M2_R2 <- round( R2(test_p$predict, test_p$charges), 2)
M2_R2 <- paste("R^2 == ", M2_R2, sep = "")


ggplot(data = test_p, aes(x=predict, y=charges)) +
  geom_point() +
  geom_abline(intercept = 0, slope = 1) +
  scale_x_continuous(breaks = seq(0, 70000, 5000)) +
  scale_y_continuous(breaks = seq(0, 70000, 5000)) +
  labs(x="Predicted Medical Cost", y="Actual Medical Cost", title="Model 2: Predicted vs Actual Cost") +
  annotate("text", x = 0, y = c(48000, 45000), label = c(M2_RMSE, M2_R2), hjust = 0, parse = TRUE)



#####----------------------------------------- Clustering  ------------------------------------------#####
# Re-scale the data so that the two ranges are between -1 and 1. Otherwise charges would drive the clustering.
rescaled_data <- data.frame( cbind(charges=rescale(insurance$charges, to = c(-1,1)), bmi=rescale(insurance$bmi, to = c(-1,1))) )

###------ k-means clustering ------###
charge_bmi_kmeans <- kmeans(rescaled_data, centers = 2)

# k-means scatter plot
ggplot(insurance, aes(x=bmi, y=charges, color=factor(charge_bmi_kmeans$cluster))) +
  geom_point() +
  scale_color_discrete(name = "Cluster") +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  labs(x = "BMI", y = "Charges", title = "K-means Clustering: k=2")



###------ DBSCAN clustering ------###
kNNdistplot(insurance[ , c("bmi", "charges")], k = 5)
title(main="Distance to 5th Nearest Neighbor - EPS=700", adj = 0)
abline(h = 700, lty = 2)

charge_bmi_DBSCAN <- dbscan(insurance[ , c("bmi", "charges")], eps = 700, minPts = 5)

charge_bmi_DBSCAN

ggplot(insurance, aes(x=bmi, y=charges, color=factor(charge_bmi_DBSCAN$cluster))) +
  geom_point() +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  scale_color_manual(values = c("black", "#00BFC4", "#F8766D"), name = "Cluster", label = c("noise", "1", "2")) +
  labs(x = "BMI", y = "Charges", title = "DBSCAN Clustering: eps=700, k=5")
  


###------ Hierarchical Clustering ------###
# distance matrix
# cut tree into 2 clusters
# display dendogram
# draw dendogram with red borders around the 2 clusters
d <- dist(rescaled_data, method = "euclidean")
fit <- hclust(d, method="ward.D")
groups <- cutree(fit, k=2)

plot(fit, labels = F, xlab = "", sub = "") 
par(mar=c(0,0,0,0))
rect.hclust(fit, k=2, border="red")

ggplot(insurance, aes(x=bmi, y=charges, color=factor(groups))) +
  geom_point() +
  scale_color_manual(values = c("#00BFC4", "#F8766D"), name = "Cluster") +
  scale_y_continuous(breaks = seq(0, 70000, 10000)) +
  scale_x_continuous(breaks = seq(0, 60, 5)) +
  labs(x = "BMI", y = "Charges", title = "Hierarchical Clustering: Ward's Method")
