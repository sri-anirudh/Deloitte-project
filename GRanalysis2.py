import pandas as pd
import numpy as np

gdata_df = pd.read_csv('/Users/srianirudh/Documents/Deloitte project/GData.csv')
activity_df = pd.read_excel('Activity_01012022_31032022.xlsx', sheet_name='Sheet1')


#joiing delivery schedule lines with gdata on EBELN and EBELP
# in gdata 76412, in deliv_Df 12394 common 12159 on PO number and item number
delivery_schedule_lines_df = pd.read_excel('Delivery Schedule Lines of a Purchasing Document.xlsx')
df= delivery_schedule_lines_df.groupby(['Purchasing Document Number', 'Item Number of Purchasing Document'])['Delivery Date of Vendor Confirmation'].max().reset_index()

merged_df = gdata_df.merge(df, left_on=['EBELN', 'EBELP'], right_on=['Purchasing Document Number', 'Item Number of Purchasing Document'], how='left')
#joining scheduling_agreement_schedule_lines_df with merged_df
scheduling_agreement_schedule_lines_df = pd.read_excel('Scheduling Agreement Schedule Lines.xlsx')
df=scheduling_agreement_schedule_lines_df.groupby(['Purchasing Document Number', 'Item Number of Purchasing Document'])['Item Delivery Date'].max()
df=pd.DataFrame(df).reset_index()

merged_df = merged_df.merge(df[['Purchasing Document Number', 'Item Number of Purchasing Document', 'Item Delivery Date']], 
                            left_on=['EBELN', 'EBELP'], 
                            right_on=['Purchasing Document Number', 'Item Number of Purchasing Document'], 
                            how='left')
# Create a new column 'expected_delivery_date' with default value as 'Item Delivery Date'
merged_df['expected_delivery_date'] = merged_df['Item Delivery Date']

# Replace the values with 'Delivery Date of Vendor Confirmation' where it is not null
merged_df.loc[merged_df['Delivery Date of Vendor Confirmation'].notnull(), 'expected_delivery_date'] = merged_df['Delivery Date of Vendor Confirmation']


#Adding expected_GR_days and delay_flag column to the merged_df
merged_df['expected_GR_days'] = (pd.to_datetime(merged_df['expected_delivery_date']) - pd.to_datetime(merged_df['createtime'])).dt.days
merged_df['GR_delay'] = merged_df['GDdays'] - merged_df['expected_GR_days']
merged_df['GR_delay_flag'] = merged_df['GR_delay'].apply(lambda x: 1 if x > 0 else 0)

#column_order = ['X_CASE_KEY', 'EBELN', 'EBELP', 'createtime', 'firstreceivetime', 'Delivery Date of Vendor Confirmation', 'GDdays', 'expected_GR_days', 'GR_delay', 'changeconfirmeddeliverydate', 'changecontract', 'changecurrency', 'changedeliveryindicator', 'changefinalinvoiceindicator', 'changeoutwarddeliveryindicator', 'changeprice', 'changequantity', 'changerequesteddeliverydate', 'changestoragelocation', 'numdelivery', 'BUKRS', 'MATKL', 'MATNR', 'NETPR', 'PSTYP', 'WERKS', 'ERNAM', 'GR_delay_flag']

#merged_df = merged_df.reindex(columns=column_order)

# Transform GDdays and GR_delay columns
merged_df['GDdays_log'] = np.log(merged_df['GDdays'] + 1)
merged_df['GR_delay_log'] = np.where(merged_df['GR_delay'] > 0, np.log(merged_df['GR_delay'] + 1), 0)
#join PR table to get PR to PO delay, and creation indicator
#gdata=76412 purchase_requisition_df=45179 commmon 37339 on POnumber and item number
#'Creation Indicator (Purchase Requisition/Schedule Lines)' and prtoPOdelay use in regression model
purchase_requisition_df = pd.read_excel('Purchase Requisition.xlsx')
order_delay = purchase_requisition_df.groupby(['Purchase Order Number', 'Item Number of Purchasing Document','Creation Indicator (Purchase Requisition/Schedule Lines)']).apply(lambda x: (x['Purchase Order Date'] - x['Requisition (Request) Date']).max()).reset_index()
order_delay.columns = ['Purchase Order Number', 'Item Number of Purchasing Document','Creation Indicator (Purchase Requisition/Schedule Lines)', 'PR_to_PO_delay']
merged_df = merged_df.merge(order_delay, left_on=['EBELN', 'EBELP'], right_on=['Purchase Order Number', 'Item Number of Purchasing Document'], how='left')
#join with purchasing document header to get Vendor and Currency information
purchasing_document_header_df = pd.read_excel('Purchasing Document Header.xlsx')
merged_df = merged_df.merge(purchasing_document_header_df[['Purchasing Document Number', 'Purchasing Group', 'Purchasing Organization', 'Vendor Account Number', 'Currency Key', 'Exchange Rate']], 
                            left_on='EBELN', right_on='Purchasing Document Number', how='left')
merged_df=merged_df[['X_CASE_KEY', 'EBELN', 'EBELP', 'createtime', 'firstreceivetime',
    'changeconfirmeddeliverydate', 'changecontract', 'changecurrency',
    'changedeliveryindicator', 'changefinalinvoiceindicator',
    'changeoutwarddeliveryindicator', 'changeprice', 'changequantity',
    'changerequesteddeliverydate', 'changestoragelocation', 'numdelivery',
    'GDdays', 'BUKRS', 'MATKL', 'MATNR', 'NETPR', 'PSTYP', 'WERKS', 'ERNAM',       
    'Delivery Date of Vendor Confirmation', 'Item Delivery Date',
    'expected_delivery_date', 'expected_GR_days', 'GR_delay',
    'GR_delay_flag', 'GDdays_log', 'GR_delay_log',
    'Creation Indicator (Purchase Requisition/Schedule Lines)',
    'PR_to_PO_delay', 'Purchasing Document Number', 'Purchasing Group',
    'Purchasing Organization', 'Vendor Account Number', 'Currency Key',
    'Exchange Rate']]
#total invoice value, and quantity
#purchasing_document_item_df 86402 gdata and merged 76412 
purchasing_document_item_df = pd.read_excel('Purchasing Document Item.xlsx')
selected_columns = ['Purchasing Document Number', 'Item Number of Purchasing Document', 'Storage Location', 'Price Unit', 'Purchase Order Unit of Measure', 'Net Price in Purchasing Document (in Document Currency)', 'Net Order Value in PO Currency']
purchasing_document_item_df['Quantity'] = purchasing_document_item_df['Net Order Value in PO Currency'] / purchasing_document_item_df['Net Price in Purchasing Document (in Document Currency)']
selected_df = purchasing_document_item_df[selected_columns + ['Quantity']]

# Perform left join without specifying suffixes
merged_df = merged_df.merge(selected_df, how='left', left_on=['EBELN', 'EBELP'], right_on=['Purchasing Document Number', 'Item Number of Purchasing Document'])
merged_df=merged_df[['EBELN', 'EBELP', 'createtime', 'firstreceivetime','expected_delivery_date','expected_GR_days', 'GR_delay',
       'GR_delay_flag', 'GDdays_log', 'GR_delay_log',
       'changeconfirmeddeliverydate', 'changecontract', 'changecurrency',
       'changedeliveryindicator', 'changefinalinvoiceindicator',
       'changeoutwarddeliveryindicator', 'changeprice', 'changequantity',
       'changerequesteddeliverydate', 'changestoragelocation', 'numdelivery',
       'GDdays', 'BUKRS', 'MATKL', 'MATNR', 'NETPR', 'PSTYP', 'WERKS', 'ERNAM',
       'Delivery Date of Vendor Confirmation', 'Item Delivery Date', 
       'Creation Indicator (Purchase Requisition/Schedule Lines)',
       'PR_to_PO_delay', 'Purchasing Group',
       'Purchasing Organization', 'Vendor Account Number', 'Currency Key',
       'Exchange Rate', 'Storage Location', 'Price Unit',
       'Purchase Order Unit of Measure',
       'Net Price in Purchasing Document (in Document Currency)',
       'Net Order Value in PO Currency', 'Quantity']]

merged_df.to_csv('merged_data.csv', index=False)

##Feature Engineering and Data Preprocessing
data=merged_df.copy()

# Create a new column for normalized values
data['NETPR_normalized'] = data['NETPR'] * data['Exchange Rate']

# Apply log transformation to the normalized values
data['NETPR_normalized_log'] = np.log(data['NETPR_normalized'])

# Apply scaling to the normalized values
from sklearn.preprocessing import MinMaxScaler
scaler = MinMaxScaler()
data['NETPR_normalized_scaled'] = scaler.fit_transform(data['NETPR_normalized'].values.reshape(-1, 1))

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import LabelEncoder, StandardScaler
import numpy as np
import pandas as pd

# Assume 'data' is your preprocessed DataFrame

# Encode categorical variables
label_encoders = {}
for column in ['Vendor Account Number', 'MATKL', 'Currency Key', 'WERKS']:
    le = LabelEncoder()
    data[column] = le.fit_transform(data[column].astype(str))
    label_encoders[column] = le

# Prepare the features and target variable
X = data[['expected_GR_days', 'Vendor Account Number', 'MATKL', 'NETPR_normalized_scaled', 
          'Currency Key', 'Quantity', 'WERKS'] + 
          ['changerequesteddeliverydate', 'changeprice', 'changequantity', 
          'changecurrency', 'changedeliveryindicator', 'changefinalinvoiceindicator', 
          'changestoragelocation', 'changeconfirmeddeliverydate', 
          'changecontract', 'changeoutwarddeliveryindicator']]
y = data['GR_delay_log']

# Split into training and testing sets
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# Initialize the Random Forest Regressor
rf = RandomForestRegressor(n_estimators=100, random_state=42)

# Train the model
rf.fit(X_train, y_train)

# Make predictions
y_pred = rf.predict(X_test)

# Calculate RMSE
rmse = np.sqrt(mean_squared_error(y_test, y_pred))

print(f'Root Mean Squared Error: {rmse}')

# Plotting
plt.figure(figsize=(10, 8))
plt.title("Feature Importances in Predicting GR_delay_log")
plt.bar(range(len(importances)), importances[indices], align="center")
plt.xticks(range(len(importances)), sorted_feature_names, rotation=90)
plt.ylabel('Importance')
plt.xlabel('Features')
plt.tight_layout()  # adjusts subplots to give some padding
plt.show()

#Evaluation throgh Visualization by predicting all values in data
import matplotlib.pyplot as plt

# Create new column
data['GR_delay_log_predicted'] = rf.predict(X)
data['GR_delay_predicted']=np.exp(data['GR_delay_log_predicted'])-1


# Sort the data by GR_delay_log
sorted_data = data.sort_values('GR_delay')
sorted_data = data[data['GR_delay'] >= 0]

# Plot line plot
plt.plot(sorted_data['GR_delay'], sorted_data['GR_delay_predicted'])
plt.xlabel('GR_delay')
plt.ylabel('GR_delay_predicted')
plt.title('GR_delay_predicted vs GR_delay')
plt.show()

from sklearn.metrics import mean_absolute_error
from sklearn.metrics import r2_score

mae = mean_absolute_error(sorted_data['GR_delay'], sorted_data['GR_delay_predicted'])
print("Mean Absolute Error:", mae)

# Assuming you have the predicted values in y_pred and the actual values in y_actual
r2_error = r2_score(sorted_data['GR_delay'], sorted_data['GR_delay_predicted'])
print(r2_error)