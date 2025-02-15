from flask import Flask, render_template, jsonify, request
import pandas as pd
import joblib
import traceback
import os

app = Flask(__name__)

# Define file paths relative to the current directory
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, 'infrastructure_analysis_results.csv')
MODEL_PATH = os.path.join(BASE_DIR, 'train_model.joblib')
MLB_PATH = os.path.join(BASE_DIR, 'train_mlb.joblib')

# Global variables for data and models
df_infra = None
model = None
mlb = None

def initialize_data():
    global df_infra, model, mlb
    
    try:
        # Check if required files exist
        if not os.path.exists(CSV_PATH):
            print(f"Error: {CSV_PATH} not found. Please run the ML analysis first.")
            return False
            
        if not os.path.exists(MODEL_PATH) or not os.path.exists(MLB_PATH):
            print(f"Error: ML model files not found. Please run the training script first.")
            return False
            
        # Load the data and models
        df_infra = pd.read_csv(CSV_PATH)
        model = joblib.load(MODEL_PATH)
        mlb = joblib.load(MLB_PATH)
        
        print("=== DEBUG INFO ===")
        print("Columns in CSV:", df_infra.columns.tolist())
        print("\nFirst row of data:")
        print(df_infra.iloc[0].to_dict())
        print("=================")
        return True
        
    except Exception as e:
        print(f"Error initializing data: {str(e)}")
        print(traceback.format_exc())
        return False

@app.route('/')
def home():
    if df_infra is None:
        if not initialize_data():
            return "Error: Unable to load required data. Please check the server logs.", 500
            
    try:
        states = df_infra['Location'].unique().tolist()
        categories = df_infra['School Category'].unique().tolist()
        return render_template('index1.html', states=states, categories=categories)
    except Exception as e:
        print(f"Error in home route: {str(e)}")
        print(traceback.format_exc())
        return str(e), 500

@app.route('/get_recommendations', methods=['POST'])
def get_recommendations():
    try:
        selected_state = request.form['state']
        selected_category = request.form.get('category', None)  # Make category optional
        
        # Filter data based on state only if no category is selected
        if selected_category:
            state_data = df_infra[
                (df_infra['Location'] == selected_state) & 
                (df_infra['School Category'] == selected_category)
            ]
            if state_data.empty:
                return jsonify({
                    'success': True,
                    'no_data': True
                })
                
            total_schools = state_data.iloc[0]['Total No. of Schools']
        else:
            # If only state is selected, don't show any data
            return jsonify({
                'success': True,
                'waiting_for_category': True
            })
            
        state_data = state_data.iloc[0]
        
        print("Available data:")
        print(state_data.to_dict())
        
        try:
            # Prepare response data with error checking and default values
            column_name = "Functional Girl's Toilet Score"
            response = {
                'recommendations': str(state_data.get('ML_Recommendations', 'No recommendations available')),
                'metrics': {
                    "Girls' Toilets": f"{state_data.get(column_name, 0)}%",
                    'Internet': f"{state_data.get('Internet Score', 0)}%",
                    'Handwash': f"{state_data.get('Handwash Score', 0)}%",
                    'Playground': f"{state_data.get('Playground Score', 0)}%",
                    'Library': f"{state_data.get('Library or Reading Corner or Book Bank Score', 0)}%",
                    'Incinerator': f"{state_data.get('Incinerator Score', 0)}%",
                    'Drinking Water': f"{state_data.get('Functional Drinking Water Score', 0)}%"
                },
                'total_score': f"{state_data.get('Total Infrastructure Score', 0):.1f}%",
                'school_info': {
                    'category': selected_category,
                    'total_schools': int(total_schools),
                },
                'success': True
            }
            
            print("Prepared response:", response)
            return jsonify(response)
            
        except Exception as e:
            print(f"Error preparing response: {str(e)}")
            print(traceback.format_exc())
            return jsonify({
                'error': 'Error preparing response data',
                'details': str(e),
                'success': False
            }), 500
        
    except Exception as e:
        print(f"Error in get_recommendations: {str(e)}")
        print(traceback.format_exc())
        return jsonify({
            'error': str(e),
            'success': False
        }), 500

if __name__ == '__main__':
    if initialize_data():
        app.run(debug=True)
    else:
        print("Failed to initialize application data. Please check the requirements and try again.")
