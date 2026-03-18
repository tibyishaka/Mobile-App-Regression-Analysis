# Salary Prediction API

A FastAPI-based REST API for predicting employee salaries using machine learning models trained on salary data.

## Features

- **Single Prediction**: Predict salary for one employee
- **Batch Prediction**: Predict salaries for up to 100 employees at once
- **CORS Support**: Full Cross-Origin Resource Sharing enabled
- **Interactive Documentation**: Swagger UI at `/docs`
- **Health Checks**: Monitor API and model status
- **Data Validation**: Pydantic-based validation with type enforcement and range constraints

## Models

The API uses one of three trained models (best performing is automatically selected):
- **Linear Regression with SGD**: Fast, linear relationship learning
- **Decision Tree**: Interpretable non-linear relationships
- **Random Forest**: Ensemble method for robust predictions

## Installation

### Local Development

1. **Clone or navigate to the project**:
   ```bash
   cd Mobile-App-Regression-Analysis/API
   ```

2. **Create a virtual environment**:
   ```bash
   python -m venv venv
   ```

3. **Activate the virtual environment**:
   - Windows:
     ```bash
     venv\Scripts\activate
     ```
   - macOS/Linux:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

## Running Locally

### Using Uvicorn

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

The API will be available at:
- **Main URL**: http://localhost:8000
- **Interactive Docs (Swagger UI)**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## API Endpoints

### Health & Info
- `GET /` - Welcome message
- `GET /health` - Health check
- `GET /model/info` - Model information

### Predictions
- `POST /predict` - Single salary prediction
- `POST /predict/batch` - Batch salary predictions (up to 100)

## Request/Response Examples

### Single Prediction

**Request**:
```bash
curl -X POST "http://localhost:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 32,
    "gender": "Male",
    "education_level": "Master'\''s",
    "job_title": "Data Analyst",
    "years_of_experience": 7
  }'
```

**Response**:
```json
{
  "predicted_salary": 85450.50,
  "model_name": "RandomForest",
  "confidence_metric": "Unknown"
}
```

### Batch Prediction

**Request**:
```json
{
  "predictions": [
    {
      "age": 32,
      "gender": "Male",
      "education_level": "Master's",
      "job_title": "Data Analyst",
      "years_of_experience": 7
    },
    {
      "age": 25,
      "gender": "Female",
      "education_level": "Bachelor's",
      "job_title": "Software Engineer",
      "years_of_experience": 2
    }
  ]
}
```

**Response**:
```json
{
  "predictions": [
    {
      "predicted_salary": 85450.50,
      "model_name": "RandomForest",
      "confidence_metric": "Batch prediction"
    },
    {
      "predicted_salary": 78920.25,
      "model_name": "RandomForest",
      "confidence_metric": "Batch prediction"
    }
  ],
  "total_predictions": 2
}
```

## Input Validation

All input fields are validated with type enforcement and range constraints:

### Single Prediction Input Parameters

| Parameter | Type | Range | Description |
| --- | --- | --- | --- |
| `age` | Integer | 18-80 | Age in years |
| `gender` | String | Male, Female | Gender |
| `education_level` | String | High School, Bachelor's, Master's, PhD | Education level |
| `job_title` | String | 1-100 chars | Job title |
| `years_of_experience` | Float | 0-60 | Years of professional experience |

## Deployment on Render

### Prerequisites
- Render account (free tier available at https://render.com)
- GitHub repository with this code

### Deployment Steps

1. **Push code to GitHub**:
   ```bash
   git init
   git add .
   git commit -m "Initial commit"
   git branch -M main
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
   git push -u origin main
   ```

2. **Connect to Render**:
   - Go to https://render.com/dashboard
   - Click "New +" → "Web Service"
   - Connect your GitHub repository
   - Select the repository

3. **Configure Render Settings**:
   - **Name**: salary-prediction-api
   - **Environment**: Python 3
   - **Region**: Choose closest to your users
   - **Branch**: main
   - **Build Command**: `pip install -r API/requirements.txt`
   - **Start Command**: `cd API && uvicorn main:app --host 0.0.0.0 --port 8000`

4. **Set Environment Variables** (if needed):
   - Add any required environment variables in Render dashboard

5. **Deploy**:
   - Click "Create Web Service"
   - Wait for deployment to complete

6. **Access Your API**:
   - Your API will be available at: `https://salary-prediction-api.onrender.com`
   - Swagger UI: `https://salary-prediction-api.onrender.com/docs`

## Important Notes

### Model File Location
The API expects the trained model at: `../Linear_Regression/best_model_salary.pkl`

**Before deploying**, ensure you've run the `LinearRegression.ipynb` notebook to generate the model file.

### CORS
CORS is enabled for all origins (`*`). For production, modify the CORS settings in `main.py`:

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],  # Specific origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Performance
- Single predictions: ~100-500ms
- Batch predictions: ~200-1000ms depending on batch size

## Troubleshooting

### Model Not Found Error
- Ensure `LinearRegression.ipynb` has been run to create `best_model_salary.pkl`
- Check file path: should be at `../Linear_Regression/best_model_salary.pkl`

### CORS Errors
- Check that CORS middleware is properly configured
- Ensure your frontend domain is in the allowed origins list

### Validation Errors
- Check all required fields are provided
- Verify data types match the schema
- Ensure numeric values are within specified ranges

## Project Structure

```
API/
├── main.py                    # FastAPI application
├── schemas.py                 # Pydantic models for request/response
├── model_utils.py             # Model loading and prediction utilities
├── requirements.txt           # Python dependencies
└── README.md                  # This file
```

## Technologies Used

- **FastAPI**: Modern web framework for building APIs
- **Pydantic**: Data validation using Python type hints
- **Uvicorn**: ASGI server
- **scikit-learn**: Machine learning models
- **pandas/numpy**: Data processing

## License

This project is provided as-is for educational purposes.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review FastAPI documentation: https://fastapi.tiangolo.com
3. Check Render deployment docs: https://render.com/docs
