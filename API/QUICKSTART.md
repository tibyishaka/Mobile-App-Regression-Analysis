# Quick Start Guide - Local Setup

## 5-Minute Setup

### 1. Navigate to API folder
```bash
cd API
```

### 2. Create virtual environment
```bash
python -m venv venv
```

### 3. Activate virtual environment

**Windows**:
```bash
venv\Scripts\activate
```

**macOS/Linux**:
```bash
source venv/bin/activate
```

### 4. Install dependencies
```bash
pip install -r requirements.txt
```

### 5. Run the API
```bash
uvicorn main:app --reload
```

The API is now running at: **http://localhost:8000**

## Access the API

### Interactive Documentation (Swagger UI)
Open in browser: **http://localhost:8000/docs**

### Try a Prediction
Click on the **POST `/predict`** endpoint and try this input:

```json
{
  "age": 32,
  "gender": "Male",
  "education_level": "Master's",
  "job_title": "Data Analyst",
  "years_of_experience": 7
}
```

## Troubleshooting

### Model Not Found?
1. Ensure you've run `LinearRegression.ipynb` to generate `best_model_salary.pkl`
2. The model should be at: `../Linear_Regression/best_model_salary.pkl`

### Port 8000 Already in Use?
```bash
uvicorn main:app --reload --port 8001
```

### Dependencies Installation Failed?
```bash
pip install --upgrade pip
pip install -r requirements.txt --no-cache-dir
```

## Next Steps

- Read [README.md](README.md) for full API documentation
- Check out the endpoints in Swagger UI for interactive testing
