import pandas as pd

gdata_df = pd.read_csv('/Users/srianirudh/Documents/Deloitte project/GData.csv')
delivery_schedule_lines_df = pd.read_excel('Delivery Schedule Lines of a Purchasing Document.xlsx')

merged_df = gdata_df.merge(delivery_schedule_lines_df, left_on=['EBELN', 'EBELP'], right_on=['Purchasing Document Number', 'Item Number of Purchasing Document'], how='left')
merged_df['expected_GR_days'] = (pd.to_datetime(merged_df['Delivery Date of Vendor Confirmation']) - pd.to_datetime(merged_df['createtime'])).dt.days
merged_df['GR_delay'] = merged_df['GDdays'] - merged_df['expected_GR_days']
merged_df['GR_delay_flag'] = merged_df['GR_delay'].apply(lambda x: 1 if x > 0 else 0)


import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.svm import SVC  # Import SVM classifier
from sklearn.metrics import accuracy_score  # Use accuracy score for classification
from sklearn.preprocessing import OneHotEncoder
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline

# Sample DataFrame loading (ensure your DataFrame is loaded as 'merged_df')
# merged_df = pd.read_csv('your_data_file.csv')


# Feature engineering: Convert categorical variables using OneHotEncoder with handle_unknown set to 'ignore'
categorical_features = ['BUKRS', 'MATKL', 'MATNR', 'PSTYP', 'WERKS', 'ERNAM', 'Client']
numeric_features = ['changeconfirmeddeliverydate', 'changecontract', 'changecurrency',
                    'changedeliveryindicator', 'changefinalinvoiceindicator', 
                    'changeoutwarddeliveryindicator', 'changeprice', 'changequantity',
                    'changerequesteddeliverydate', 'changestoragelocation', 'numdelivery', 'NETPR']

# Creating a transformer for preprocessing
preprocessor = ColumnTransformer(
    transformers=[
        ('num', 'passthrough', numeric_features),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_features)
    ])

# Define the model pipeline with SVM classifier
pipeline = Pipeline(steps=[
    ('preprocessor', preprocessor),
    ('classifier', SVC(kernel='rbf'))  # Using linear kernel for SVM
])

# Ensuring there are no missing values in the target column and that we only use unique rows
merged_df = merged_df.dropna(subset=['GR_delay_flag'])
merged_df = merged_df[numeric_features + categorical_features + ['GR_delay_flag']].drop_duplicates()

# Define feature matrix X and target vector y
X = merged_df[numeric_features + categorical_features]
y = merged_df['GR_delay_flag']

# Splitting the data into train and test sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Fitting the model
pipeline.fit(X_train, y_train)

# Predicting the test set results
y_pred = pipeline.predict(X_test)

# Calculating the accuracy
accuracy = accuracy_score(y_test, y_pred)
print(f'Accuracy: {accuracy}')

# Optionally, you might want to print the support vectors or other details from the SVM model
# Number of support vectors for each class
print(f'Number of support vectors for each class: {pipeline.named_steps["classifier"].n_support_}')


