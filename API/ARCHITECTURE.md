# API Architecture & Design Documentation

## Overview

The Salary Prediction API is a FastAPI-based REST service that provides machine learning-powered salary predictions. It's designed with scalability, maintainability, and ease of deployment in mind.

## System Architecture

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
    │                                      │
    │   Contains:                          │
    │   - Trained model (RandomForest,     │
    │     DecisionTree, or LinearRegression)
    │   - Preprocessor pipeline            │
    │   - Feature columns metadata         │
    │   - Target column name               │
    └──────────────────────────────────────┘
```

## Component Description

### 1. **main.py** - FastAPI Application
The core application file containing:
- FastAPI instance with startup/shutdown lifecycle management
- CORS middleware for cross-origin requests
- HTTP route handlers for all endpoints
- Error handling and exception management
- Application documentation (title, description, version)

### 2. **schemas.py** - Data Validation
Pydantic models ensuring type safety and data validation:

**Request Models**:
- `SalaryPredictionRequest`: Single prediction input with constraints
- `BatchPredictionRequest`: Multiple predictions with batch validation

**Response Models**:
- `SalaryPredictionResponse`: Prediction output with metadata
- `BatchPredictionResponse`: Batch results aggregation

**Validation Features**:
- Type enforcement (int, float, string)
- Range constraints (age: 18-80, experience: 0-60)
- Enum validation (gender, education_level)
- Min/max length constraints (job_title)
- Custom validators for categorical fields

### 3. **model_utils.py** - Model Management
Singleton pattern implementation for efficient model loading:

**ModelLoader Class**:
- `load_model()`: Loads pickle artifact with singleton pattern
- `make_prediction()`: Executes predictions on new data
- `get_model_info()`: Returns model metadata

**Features**:
- Singleton pattern ensures single model instance in memory
- Support for both pipeline and separate preprocessor+model architectures
- Comprehensive error handling and logging

### 4. **config.py** - Configuration Management
Centralized configuration with environment variable support:
- API settings and metadata
- CORS configuration
- Prediction constraints
- Model paths and logging settings
- Valid categorical values

## Data Flow

### Prediction Request Flow

```
User Request
    ↓
HTTP POST /predict
    ↓
Pydantic Validation (schemas.py)
    ├─ Type check
    ├─ Range validation
    └─ Custom validators
    ↓
validate_input_data() (model_utils.py)
    ├─ Convert dict → DataFrame
    └─ Error handling
    ↓
ModelLoader.make_prediction()
    ├─ Load model (singleton)
    ├─ Execute prediction
    └─ Return results
    ↓
SalaryPredictionResponse
    ├─ Predicted salary
    ├─ Model name
    └─ Confidence metric
    ↓
HTTP 200 JSON Response
```

## API Endpoints

### Health & Information

| Endpoint | Method | Purpose |
| --- | --- | --- |
| `/` | GET | Welcome message |
| `/health` | GET | Health check (model status) |
| `/model/info` | GET | Model metadata |

### Predictions

| Endpoint | Method | Purpose | Input | Output |
| --- | --- | --- | --- | --- |
| `/predict` | POST | Single prediction | SalaryPredictionRequest | SalaryPredictionResponse |
| `/predict/batch` | POST | Batch predictions | BatchPredictionRequest | BatchPredictionResponse |

## Input Validation Rules

### SalaryPredictionRequest

```python
{
  "age": int,                          # 18 ≤ age ≤ 80
  "gender": str,                       # "Male" | "Female"
  "education_level": str,              # "High School" | "Bachelor's" | "Master's" | "PhD"
  "job_title": str,                    # 1-100 characters
  "years_of_experience": float         # 0 ≤ experience ≤ 60
}
```

**Validation Order**:
1. Type checking (Pydantic)
2. Range constraints (Pydantic Field validators)
3. Enum validation (Custom @field_validator)
4. Dataframe conversion for model

## Error Handling

### HTTP Status Codes

| Code | Scenario | Example |
| --- | --- | --- |
| 200 | Successful request | Prediction returned |
| 400 | Bad request/validation error | Invalid age (150) |
| 422 | Validation error | Missing required field |
| 500 | Server error | Model loading failed |
| 503 | Service unavailable | Model not loaded |

### Example Error Response

```json
{
  "detail": "Invalid input: Age must be between 18 and 80"
}
```

## Performance Characteristics

### Prediction Performance

| Scenario | Time | Notes |
| --- | --- | --- |
| Single prediction | 100-500ms | Model inference only |
| Batch (10 samples) | 200-600ms | ~50ms per sample |
| Batch (100 samples) | 1-3s | Efficient vectorized processing |
| Model loading (cold start) | 2-5s | One-time; then cached |

### Resource Usage

| Resource | Typical | Peak |
| --- | --- | --- |
| Memory (idle) | 200-300 MB | 400-500 MB (batch requests) |
| CPU (single prediction) | ~5% | ~20% (batch) |
| Model file size | ~5-10 MB | - |

## Deployment Targets

### Development
- Local machine with `uvicorn main:app --reload`
- Docker container with docker-compose

### Production
- **Render** (recommended for beginners) - Free/paid tiers
- **AWS** - EC2, ECS, Lambda
- **Google Cloud** - Cloud Run, App Engine
- **Azure** - App Service
- **DigitalOcean** - App Platform

## Security Considerations

### CORS
- Currently allows all origins (`*`)
- For production: specify allowed domains

### Input Validation
- All inputs validated by Pydantic
- Type enforcement prevents injection attacks
- Range constraints prevent data anomalies

### Model Access
- Model loaded from local filesystem
- No direct user access to model weights
- Only predictions exposed via API

### Data Privacy
- No data logging by default
- Predictions not stored
- CSV uploads processed in-memory

### Recommended Production Hardening
1. Limit CORS to specific domains
2. Add API key authentication
3. Implement rate limiting
4. Use HTTPS/TLS
5. Add request logging
6. Monitor error rates
7. Set up alerting

## Extensibility

### Adding New Models
1. Train new model in notebook
2. Save to existing `best_model_salary.pkl` structure
3. Redeploy API to use new model

### Adding New Endpoints
1. Define Pydantic schemas in `schemas.py`
2. Implement logic in appropriate module
3. Add route handler in `main.py`
4. Test with `test_api.py`

## Testing Strategy

### Unit Testing Locations
- `test_api.py`: Integration tests for all endpoints
- Schema validation: Automatic via Pydantic
- Model loading: Tested on startup

### Manual Testing
```bash
# Test single prediction
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"age": 32, "gender": "Male", ...}'

# Test batch
curl -X POST http://localhost:8000/predict/batch \
  -H "Content-Type: application/json" \
  -d '{"predictions": [...]}'

# Test with test script
python test_api.py
```

## Future Enhancements

1. **Async Processing**: Batch predictions in background tasks
2. **Database Integration**: Store prediction history
3. **Caching Layer**: Redis for frequent predictions
4. **Model Versioning**: Support multiple model versions
5. **Explainability**: Feature importance endpoints
6. **A/B Testing**: Route X% to new models
7. **Monitoring**: Prometheus metrics integration
8. **Rate Limiting**: Token bucket algorithm
9. **Authentication**: OAuth2 / API keys
10. **Documentation**: OpenAPI schema auto-generation

## References

- FastAPI: https://fastapi.tiangolo.com
- Pydantic: https://docs.pydantic.dev
- scikit-learn: https://scikit-learn.org
- Uvicorn: https://www.uvicorn.org
- Render Docs: https://render.com/docs
