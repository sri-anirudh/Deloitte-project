# Set the file path
file_path <- "/Users/srianirudh/Documents/Deloitte project/final_data.csv"

# Read the CSV file
data <- read.csv("final_data.csv")

# Print the data
print(data)

# Load the required library
library(GGally)

# Plot correlation matrix
ggcorr(data)

# Plot scatter plot matrix
ggpairs(data)


# Read the classification CSV file
classification_data <- read.csv("final_data_classification.csv")
# Print the classification data
print(classification_data)

# Fit a generalized linear model (GLM) to predict 'GR_delay_log' using all other fields
model <- glm(GR_delay_log ~ ., data = classification_data)


# Read the Excel file
merged_data <- read.xlsx("/Users/srianirudh/Documents/Deloitte project/merged_data.xlsx", sheetIndex = 1)

# Continue with the rest of your code...
# Fit a generalized linear model (GLM) to predict 'GR_delay_log' using all other fields
model <- glm(GR_delay_log ~ ., data = merged_data)
classification_data <- read.csv("final_data_classification.csv")
regression_data <- read.csv("final_data_regression.csv")


# Convert nominal variables to factors
regression_data$MATKL <- as.factor(regression_data$MATKL)
regression_data$Vendor.Account.Number <- as.factor(regression_data$Vendor.Account.Number)
regression_data$Currency.Key <- as.factor(regression_data$Currency.Key)

# Fit linear regression model
model <- lm(GR_delay_log ~ ., data = regression_data)



install.packages("tidyverse")  # Comprehensive set of packages for data science
install.packages("ggplot2")     # Data visualization
install.packages("dplyr")       # Data manipulation
install.packages("readr")       # Data import
install.packages("caret")       # Machine learning toolkit
install.packages("lubridate")   # Date and time handling
install.packages("tidyr")       # Data tidying
install.packages("stringr")     # String manipulation
install.packages("rpart")       # Recursive partitioning for decision trees
install.packages("randomForest")# Random Forest algorithm
install.packages("readxl")        # For reading Excel files
install.packages("readr")         # For reading CSV files
install.packages("ggplot2")       # Data visualization
install.packages("caret")         # Machine learning toolkit
install.packages("corrplot")      # Visualization of correlation matrices
install.packages("pROC")          # Tools for ROC curve analysis
install.packages("e1071")         # Functions for evaluating accuracy, including confusion matrices
