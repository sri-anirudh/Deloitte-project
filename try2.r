# Load necessary libraries
library(caret)
library(ROCR)

# Load your data
# classification_data <- read.csv("path_to_your_data.csv")
classification_data <- read.csv("final_data_classification.csv")

# Convert the target variable to a factor if it's not already
classification_data$GR_delay_flag <- as.factor(classification_data$GR_delay_flag)

classification_data <- na.omit(classification_data)

# Check if there are still any missing values
sum(is.na(classification_data))

# Set up cross-validation
train_control <- trainControl(
  method = "cv",           # Use cross-validation
  number = 10,             # Number of folds in the cross-validation
  savePredictions = "final",
  classProbs = TRUE,       # Save class probabilities for ROC analysis
  summaryFunction = twoClassSummary  # Use ROC summary
)

# Train the GLM model
glm_model <- train(
  GR_delay_flag ~ .,       # Formula: predict GR_delay_flag using all other variables
  data = classification_data,
  method = "glm",
  family = "binomial",     # Specify binomial for classification
  trControl = train_control,
  metric = "ROC"           # Optimize for ROC (requires classProbs = TRUE)
)

# Print the model summary
print(glm_model)

# Evaluation using confusion matrix
confusionMatrix(glm_model)

# Calculate and plot ROC curve
prob_predictions <- predict(glm_model, classification_data, type = "prob")
roc_pred <- prediction(prob_predictions[, "positive_class"], classification_data$GR_delay_flag)
roc_perf <- performance(roc_pred, "tpr", "fpr")
plot(roc_perf, colorize = TRUE)
abline(a = 0, b = 1, col = "gray", lwd = 2, lty = 2)
