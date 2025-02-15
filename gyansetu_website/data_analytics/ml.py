import pandas as pd
import numpy as np

dataset = pd.read_csv('data.csv')


def generate_recommendations_extended(df):
    recommendations = []

    for _, row in df.iterrows():
        state = row['Location']
        total_schools = row['Total No. of Schools']
        functional_girls_toilets = row["Functional Girl's Toilet"]
        internet = row['Internet']
        handwash = row['Handwash']
        playground = row['Playground']
        library = row['Library or Reading Corner or Book Bank']
        incinerators = row['Incinerator']
        drinking_water = row['Functional Drinking Water']

        state_recommendations = []

        # Girls' toilets recommendation
        if functional_girls_toilets / total_schools < 0.5:
            state_recommendations.append(
                f"Increase the number of functional girls' toilets."
            )

        # Internet recommendation
        if internet / total_schools < 0.25:
            state_recommendations.append(
                f"Enhance internet connectivity in schools."
            )

        # Handwash recommendation
        if handwash / total_schools < 0.75:
            state_recommendations.append(
                f"Ensure handwash facilities are available in all schools."
            )

        # Playgrounds recommendation
        if playground / total_schools < 0.6:
            state_recommendations.append(
                f"Increase the number of schools with playgrounds to encourage physical activity."
            )

        # Libraries recommendation
        if library / total_schools < 0.5:
            state_recommendations.append(
                f"Establish libraries or reading corners in more schools to promote a reading culture."
            )

        # Incinerators recommendation
        if incinerators / total_schools < 0.3:
            state_recommendations.append(
                f"Install incinerators in schools to ensure safe waste disposal."
            )

        # Drinking water recommendation
        if drinking_water / total_schools < 0.8:
            state_recommendations.append(
                f"Ensure access to clean and functional drinking water in all schools."
            )

        # If no recommendations are generated
        if not state_recommendations:
            state_recommendations.append(
                f"No immediate actions needed as all infrastructure indicators are adequate."
            )

        recommendations.append("; ".join(state_recommendations))

    df['Recommendations'] = recommendations
    return df

# Load the dataset
file_path = 'data.csv'  # Replace with the actual file path
data = pd.read_csv(file_path)

# Generate extended recommendations
updated_data_extended = generate_recommendations_extended(data)

# Save the updated dataset
output_file_path_extended = 'updated_data_with_extended_recommendations.csv'
updated_data_extended.to_csv(output_file_path_extended, index=False)

print(f"Updated dataset saved to {output_file_path_extended}")



import skmultilearn
import os

# Get the file path for the skmultilearn library
file = skmultilearn.__file__

# Define the path to the specific file to modify (mlknn.py)
file_path = os.path.join(os.path.dirname(file), "adapt", "mlknn.py")

# Read the file's contents
with open(file_path, 'r') as file:
    file_contents = file.read()

# Modify the specific code: Replace 'NearestNeighbors(self.k)' with 'NearestNeighbors(n_neighbors=self.k)'
modified_contents = file_contents.replace('NearestNeighbors(self.k)', 'NearestNeighbors(n_neighbors=self.k)')

# Write the modified contents back to the file
with open(file_path, 'w') as file:
    file.write(modified_contents)

print("File modified and saved successfully.")


import pandas as pd
import numpy as np
from skmultilearn.adapt import MLkNN
from sklearn.preprocessing import MultiLabelBinarizer
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

# Load the dataset
# Replace 'Train_Dataset_Path' with the actual file path of your dataset
df = pd.read_csv("updated_data_with_extended_recommendations.csv")

# Define features and labels
# Replace 'Assessments' with the actual column names representing your features
X = df[['Total No. of Schools',
        "Functional Girl's Toilet",
        'Internet',
        'Handwash',
        'Playground',
        'Library or Reading Corner or Book Bank',
        'Incinerator',
        'Functional Drinking Water']]

# Preprocess the 'Recommendation' column to convert into multiple binary labels
# Assuming each recommendation is a unique string separated by "; "
df['Recommendations'] = df['Recommendations'].fillna("")
df['Recommendations'] = df['Recommendations'].apply(lambda x: x.split("; ") if x else [])

# Use MultiLabelBinarizer to encode string labels into a binary format
mlb = MultiLabelBinarizer()
Y = mlb.fit_transform(df['Recommendations'])

# Split data into training and testing sets
X_train, X_test, Y_train, Y_test = train_test_split(X, Y, test_size=0.2, random_state=42)

# Initialize variables to track the best k value and accuracy
best_k = None
best_accuracy = 0.0

# Loop through a range of k values to find the optimal one
for k in range(5,10):  # Testing k values from 22 to 25
    print(f"Training MLkNN with k={k}...")
    mlknn = MLkNN(k=k)

    # Fit the model
    mlknn.fit(X_train, Y_train)

    # Predict on the test data
    Y_pred = mlknn.predict(X_test)

    # Evaluate the model's accuracy
    accuracy = accuracy_score(Y_test, Y_pred.toarray())
    print(f"k={k}, Accuracy: {accuracy * 100:.2f}%")

    # Update the best k and accuracy if the current one is better
    if accuracy >= best_accuracy:
        best_k = k
        best_accuracy = accuracy

# Print the final result
print(f"\nBest k value: {best_k} with Accuracy: {best_accuracy * 100:.2f}%")


import joblib

model_file_path = 'train_model.joblib'
joblib.dump(mlknn, model_file_path)
mlb_file_path = 'train_mlb.joblib'
joblib.dump(mlb, mlb_file_path)  # Save the MultiLabelBinarizer

print(f"Model saved as {model_file_path}")
print(f"MLB saved as {mlb_file_path}")


# ... existing code until the model saving ...

def process_infrastructure_data(csv_file_path):
    df_infra = pd.read_csv(csv_file_path)
    
    # Define the infrastructure metrics we want to track
    infrastructure_metrics = [
        'Total No. of Schools',
        "Functional Girl's Toilet",
        'Internet',
        'Handwash',
        'Playground',
        'Library or Reading Corner or Book Bank',
        'Incinerator',
        'Functional Drinking Water'
    ]
    
    # Handle missing values
    for metric in infrastructure_metrics:
        df_infra[metric].fillna(0, inplace=True)
        df_infra[metric] = df_infra[metric].astype(int)
    
    return df_infra, infrastructure_metrics

def calculate_infrastructure_scores(df_infra, infrastructure_metrics):
    # Create normalized scores (0-100) for each infrastructure metric
    for metric in infrastructure_metrics[1:]:  # Skip 'Total No. of Schools'
        score_column = f'{metric} Score'
        df_infra[score_column] = round((df_infra[metric] / df_infra['Total No. of Schools']) * 100)
        df_infra[score_column] = df_infra[score_column].astype(int)
    
    # Calculate total infrastructure score
    score_columns = [f'{metric} Score' for metric in infrastructure_metrics[1:]]
    df_infra['Total Infrastructure Score'] = df_infra[score_columns].mean(axis=1)
    
    return df_infra

# Usage example:
csv_file_path = 'data.csv'  # Your input CSV file

# Process the data
df_infra, metrics = process_infrastructure_data(csv_file_path)
df_infra = calculate_infrastructure_scores(df_infra, metrics)

# Generate recommendations using the ML model
def predict_recommendations(df_infra, model, mlb):
    # Prepare features
    X_pred = df_infra[metrics]
    
    # Get predictions
    Y_pred = model.predict(X_pred)
    
    # Convert predictions back to readable recommendations
    recommendations = mlb.inverse_transform(Y_pred)
    
    # Add recommendations to dataframe
    df_infra['ML_Recommendations'] = ['; '.join(rec) for rec in recommendations]
    
    return df_infra

# Load the trained model and MLB
loaded_model = joblib.load('train_model.joblib')
loaded_mlb = joblib.load('train_mlb.joblib')

# Generate recommendations
df_infra = predict_recommendations(df_infra, loaded_model, loaded_mlb)

# Save the updated dataset
output_path = 'infrastructure_analysis_results.csv'
df_infra.to_csv(output_path, index=False)

print(f"Analysis complete. Results saved to {output_path}")


import pandas as pd
import joblib

# Load the trained MLkNN model and MultiLabelBinarizer
model_file_path = 'train_model.joblib'
mlb_file_path = 'train_mlb.joblib'
loaded_model = joblib.load(model_file_path)
mlb = joblib.load(mlb_file_path)

# Load infrastructure data
df_infra = pd.read_csv('data.csv')

# Define infrastructure metrics
infrastructure_metrics = [
    'Total No. of Schools',
    "Functional Girl's Toilet",
    'Internet',
    'Handwash',
    'Playground',
    'Library or Reading Corner or Book Bank',
    'Incinerator',
    'Functional Drinking Water'
]

# Calculate scores and prepare recommendations
recommendations_list = []

for index, row in df_infra.iterrows():
    # Create a test dataframe for this row
    test_data = {metric: [row[metric]] for metric in infrastructure_metrics}
    test_df = pd.DataFrame(test_data)
    
    # Get predictions
    predictions = loaded_model.predict(test_df)
    predicted_labels = mlb.inverse_transform(predictions.toarray())
    
    # Format recommendations
    recommendation = ""
    for i, labels in enumerate(predicted_labels):
        if labels:
            recommendation += f"{'; '.join(labels)}"
        else:
            recommendation += "No immediate actions needed as all infrastructure indicators are adequate"
    recommendations_list.append(recommendation)

# Add recommendations to the dataframe
df_infra['ML_Recommendations'] = recommendations_list

# Calculate infrastructure scores
for metric in infrastructure_metrics[1:]:  # Skip 'Total No. of Schools'
    score_column = f'{metric} Score'
    df_infra[score_column] = round((df_infra[metric] / df_infra['Total No. of Schools']) * 100)
    df_infra[score_column] = df_infra[score_column].astype(int)

# Calculate total infrastructure score
score_columns = [f'{metric} Score' for metric in infrastructure_metrics[1:]]
df_infra['Total Infrastructure Score'] = df_infra[score_columns].mean(axis=1)

# Save the updated dataset
df_infra.to_csv('infrastructure_analysis_results.csv', index=False)

print("Recommendations and analysis complete")



from sklearn.metrics import multilabel_confusion_matrix
import seaborn as sns
import matplotlib.pyplot as plt

# Calculate multi-label confusion matrices
ml_confusion_matrices = multilabel_confusion_matrix(Y_test, Y_pred.toarray())

# Create a figure with subplots for each recommendation type
n_labels = len(mlb.classes_)
fig_rows = (n_labels + 2) // 3  # Calculate number of rows needed (3 plots per row)
fig = plt.figure(figsize=(15, 5 * fig_rows))

# Iterate through each label and plot the confusion matrix
for idx, cm in enumerate(ml_confusion_matrices):
    plt.subplot(fig_rows, 3, idx + 1)
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues')
    plt.title(f'Confusion Matrix for:\n{mlb.classes_[idx][:50]}...')  # Show first 50 chars
    plt.ylabel('True Labels')
    plt.xlabel('Predicted Labels')

plt.tight_layout()
plt.show()

# Print classification metrics for each recommendation
from sklearn.metrics import classification_report

# Generate and print classification report
y_test_array = Y_test
y_pred_array = Y_pred.toarray()

print("\nClassification Report:")
print(classification_report(y_test_array, y_pred_array, 
                          target_names=[rec[:50] + "..." for rec in mlb.classes_]))

# Calculate and print accuracy for each recommendation type
print("\nAccuracy for each recommendation type:")
for idx, label in enumerate(mlb.classes_):
    accuracy = (y_test_array[:, idx] == y_pred_array[:, idx]).mean()
    print(f"{label[:50]}...: {accuracy:.2%}")