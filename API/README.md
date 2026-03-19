# Salary Prediction API

A FastAPI-based REST API for predicting employee salaries using machine learning models trained on salary data. It is designed with scalability, maintainability, and ease of deployment in mind.

## Features

- **Single Prediction**: Predict salary for one employee
- **Batch Prediction**: Predict salaries for up to 100 employees at once
- **CORS Support**: Full Cross-Origin Resource Sharing enabled
- **Interactive Documentation**: Swagger UI at `/docs`
- **Health Checks**: Monitor API and model status
- **Data Validation**: Pydantic-based validation with type enforcement and range constraints

## System Architecture

The following diagram illustrates the interaction between client applications, the API, and the underlying machine learning models.

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Applications                      │
│         (Web Browsers, Mobile Apps, Backend Services)        │
└────────────────────────┬────────────────────────────────────┘
                         │
                    HTTP/REST
                         │
           ┌─────────────┴─────────────┐
           │                           │
    ┌──────▼──────┐          ┌────────▼──────┐
    │ Swagger UI  │          │  REST Clients │
    │  (/docs)    │          │  (curl, SDK)  │
    └─────────────┘          └────────────────┘
                         │
        ┌────────────────┴────────────────┐
        │                                 │
    ┌───▼─────────────────────────────────┴────┐
    │      FastAPI Application (main.py)       │
    │                                          │
    │  ┌────────────────────────────────────┐  │
    │  │   CORS Middleware                  │  │
    │  │   (Handles cross-origin requests)  │  │
    │  └────────────────────────────────────┘  │
    │                                          │
    │  ┌────────────────────────────────────┐  │
    │  │   Route Handlers                   │  │
    │  │   - GET /health                    │  │
    │  │   - GET /model/info                │  │
    │  │   - POST /predict (single)         │  │
    │  │   - POST /predict/batch            │  │
    │  └────────────────────────────────────┘  │
    │                                          │
    │  ┌────────────────────────────────────┐  │
    │  │   Data Validation (schemas.py)     │  │
    │  │   - Pydantic models                │  │
    │  │   - Type enforcement               │  │
    │  │   - Range constraints              │  │
    │  └────────────────────────────────────┘  │
    └──────────────┬───────────────────────────┘
                   │
    ┌──────────────┴──────────────────┐
    │                                 │
┌───▼──────────────┐
│  Model Utils     │
│  (model_utils)   │
│                  │
│ • LoadModel()    │
│ • Predict()      │
│ • GetModelInfo() │
└──────────────────┘
         │
         │
    ┌────▼────────────────────┐
    │   Model Artifacts                    │
    │   ../../Linear_Regression/           │
    │   best_model_salary.pkl              │
    └──────────────────────────────────────┘
```

### Key Components

1.  **main.py** - FastAPI Application
    - Core application with lifecycle management.
    - Handles HTTP routes and error management.
    - Configures CORS middleware.

2.  **schemas.py** - Data Validation
    - Defines Pydantic models for request and response data.
    - Enforces type safety (e.g., age must be an int) and constraints (e.g., age 18-80).

3.  **model_utils.py** - Model Logic
    - Loads the trained model (`best_model_salary.pkl`).
    - Handles prediction logic and model metadata.

## Quick Start & Installation

### Prerequisites

-   Python 3.8+
-   Trained model file (`best_model_salary.pkl`) available in the `../Linear_Regression/` directory. (Run the training notebook `LinearRegression.ipynb` if missing).

### 5-Minute Local Setup

1.  **Navigate to the API folder**:
    ```bash
    cd API
    ```

2.  **Create a virtual environment**:
    ```bash
    # Windows
    python -m venv venv
    venv\Scripts\activate

    # macOS/Linux
    python -m venv venv
    source venv/bin/activate
    ```

3.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Run the API**:
    ```bash
    uvicorn main:app --reload --host 0.0.0.0 --port 8000
    ```

The API will be available at:

-   **Main URL**: `http://localhost:8000`
-   **Interactive Docs (Swagger UI)**: `http://localhost:8000/docs`
-   **ReDoc**: `http://localhost:8000/redoc`

## API Endpoints

### Health & Info

-   `GET /`: Welcome message.
-   `GET /health`: Checks API and model status.
-   `GET /model/info`: Returns information about the currently loaded model.

### Predictions

-   `POST /predict`: Single salary prediction.
-   `POST /predict/batch`: Predicted salaries for multiple employees (up to 100).

## Usage Examples

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

## Input Parameters

All input fields are validated. Below are the requirements:

| Parameter             | Type    | Range                                   | Description                      |
| --------------------- | ------- | --------------------------------------- | -------------------------------- |
| `age`                 | Integer | 18-80                                   | Age in years                     |
| `gender`              | String  | Male, Female                            | Gender                           |
| `education_level`     | String  | High School, Bachelor's, Master's, PhD  | Education level                  |
| `job_title`           | String  | 1-100 chars                             | Job title                        |
| `years_of_experience` | Float   | 0-60                                    | Years of professional experience |

## Deployment on Render

1.  **Push code to GitHub**: Ensure `requirements.txt` is in the `API/` folder.
2.  **Connect to Render**: Create a new "Web Service".
3.  **Configure Settings**:
    -   **Build Command**: `pip install -r API/requirements.txt`
    -   **Start Command**: `cd API && uvicorn main:app --host 0.0.0.0 --port 8000`
4.  **Deploy**: Render will build and deploy your service.

## Troubleshooting

-   **Model Not Found?**: Ensure `best_model_salary.pkl` exists in `../Linear_Regression/`.
-   **Port 8000 Busy?**: Run with `--port 8001`.
-   **Dependency Issues?**: Try `pip install --upgrade pip` and re-install requirements.
