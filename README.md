# Mobile App Regression Analysis

## 🎯 Mission
To strengthen cybersecurity awareness and digital literacy through accessible, data-driven education by building intelligent tools and APIs that help learners understand risk patterns and make safer digital decisions.

## 📋 Project Overview

**Mobile App Regression Analysis** is a full-stack machine learning project that combines Jupyter-based model development with a production-ready REST API for salary prediction. The system trains multiple regression models on demographic and job feature data, compares their performance, and exposes the best model through a scalable FastAPI service.

### Key Components:
- **Model Training**: Jupyter notebook implementing salary prediction pipeline
- **REST API**: Production-ready FastAPI service for predictions
- **Deployment**: Docker & Render.com support for cloud deployment
- **Model Management**: Dynamic model retraining via API
- **Batch Processing**: Support for single and batch predictions (up to 100 items)

---

## 🏗️ Project Architecture

```
Mobile-App-Regression-Analysis/
├── API/                                    # FastAPI REST API (main application)
│   ├── main.py                             # FastAPI app with endpoints
│   ├── schemas.py                          # Pydantic models for validation
│   ├── model_utils.py                      # Model loading & prediction logic
│   ├── model_retraining.py                 # Model retraining functionality
│   ├── config.py                           # Configuration settings
│   ├── requirements.txt                    # Python dependencies
│   ├── test_api.py                         # API test suite
│   ├── README.md                           # API-specific documentation
│   ├── QUICKSTART.md                       # 5-minute setup guide
│   ├── ARCHITECTURE.md                     # System architecture details
│   └── __init__.py                         # Package initialization
│
├── Linear_Regression/                      # Model training artifacts
│   ├── LinearRegression.ipynb              # Model training notebook
│   └── best_model_salary.pkl               # Trained model artifact
│
├── API_SUMMARY.md                          # Comprehensive API overview
├── GETTING_STARTED.md                      # Implementation guide
├── Dockerfile                              # Docker container specification
├── docker-compose.yml                      # Local Docker development
├── Procfile                                # Render deployment configuration
└── README.md                               # This file
```

---

## ✨ Features

### 1. **REST API Endpoints**

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/` | GET | Welcome message & API status |
| `/health` | GET | Health check endpoint |
| `/model/info` | GET | Model metadata (name, R² score, training info) |
| `/predict` | POST | Single salary prediction |
| `/predict/batch` | POST | Batch predictions (1-100 samples) |

### 2. **Machine Learning Models**

The notebook trains and compares three regression models:
- **Linear Regression** (SGD-based)
- **Decision Tree Regressor**
- **Random Forest Regressor**

Best-performing model is automatically selected and deployed.

### 3. **Data Validation & Constraints**

All API inputs validated with Pydantic:
- **Age**: 18-80 years
- **Years of Experience**: 0-60 years
- **Gender**: 'Male' or 'Female'
- **Education Level**: 'High School', 'Bachelor\'s', 'Master\'s', or 'PhD'
- **Job Title**: 1-100 characters

### 4. **Production Features**

- ✅ **CORS Middleware**: Enabled for cross-origin requests
- ✅ **Interactive Documentation**: Swagger UI at `/docs`, ReDoc at `/redoc`
- ✅ **Error Handling**: Comprehensive validation and error responses
- ✅ **Logging**: Structured logging for debugging and monitoring
- ✅ **Batch Processing**: Process multiple predictions efficiently

---

## 🚀 Quick Start

### Local Development (5 minutes)

#### Step 1: Navigate to API Directory
```bash
cd API
```

#### Step 2: Create Virtual Environment
```bash
python -m venv venv
```

#### Step 3: Activate Virtual Environment
```bash
# Windows
venv\Scripts\activate

# macOS/Linux
source venv/bin/activate
```

#### Step 4: Install Dependencies
```bash
pip install -r requirements.txt
```

#### Step 5: Run API Server
```bash
uvicorn main:app --reload
```

#### Step 6: Access the API
- **Main URL**: http://localhost:8000
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **Health Check**: http://localhost:8000/health

### Test Single Prediction
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

---

## 🐳 Docker Deployment

### Using Docker Compose (Recommended)
```bash
docker-compose up
```
Access API at: http://localhost:8000/docs

### Manual Docker Build
```bash
docker build -t salary-api .
docker run -p 8000:8000 salary-api
```

---

## 📊 Model Training Workflow

### Running the Notebook

1. **Ensure best model exists**: Run [Linear_Regression/LinearRegression.ipynb](Linear_Regression/LinearRegression.ipynb) to train models
2. **Output**: Generates `best_model_salary.pkl` in the notebook directory
3. **API Usage**: API automatically loads and uses the saved model

---

## 📦 Dependencies

**Core Framework**:
- `fastapi==0.104.1` - Modern web framework
- `uvicorn==0.24.0` - ASGI server

**Data & ML**:
- `pandas==2.1.3` - Data manipulation
- `numpy==1.26.2` - Numerical computing
- `scikit-learn==1.3.2` - Machine learning

**Validation & Config**:
- `pydantic==2.5.0` - Data validation
- `python-multipart==0.0.6` - File uploads
- `python-dotenv==1.0.0` - Environment variables

See [API/requirements.txt](API/requirements.txt) for complete list.

---

## 📚 Documentation

- **[API_SUMMARY.md](API_SUMMARY.md)**: Complete API feature overview
- **[API/README.md](API/README.md)**: API-specific documentation
- **[API/QUICKSTART.md](API/QUICKSTART.md)**: Quick setup guide
- **[API/ARCHITECTURE.md](API/ARCHITECTURE.md)**: System architecture & design
- **[GETTING_STARTED.md](GETTING_STARTED.md)**: Implementation details
- **[RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md)**: Cloud deployment guide

---

## 🚢 Deployment

### Render.com (Production)
Follow instructions in [RENDER_DEPLOYMENT.md](RENDER_DEPLOYMENT.md) for automated deployment.

### Local Docker
```bash
docker-compose up
```

### Manual Uvicorn
```bash
cd API
uvicorn main:app --host 0.0.0.0 --port 8000
```

---

## 🔧 Configuration

Environment variables (see `.env.example` in API folder):
```
KAGGLE_USERNAME=your_username
KAGGLE_KEY=your_api_key
MODEL_PATH=./Linear_Regression/best_model_salary.pkl
```

---

## 📝 Notes

- **Dataset**: Downloaded from Kaggle using `kagglehub` (internet access required for first-time download)
- **Model Artifacts**: Training notebook generates `best_model_salary.pkl` 
- **CORS**: Enabled for all origins (configure in `config.py` for production)
- **Logging**: Structured logs with timestamps and severity levels

---

## 🤝 Contributing

This project is maintained as part of ALU coursework and educational initiatives. Updates reflect current implementation state.

---

## 📄 License

Educational project for ALU (African Leadership University)
