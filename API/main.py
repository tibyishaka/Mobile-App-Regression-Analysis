from fastapi import FastAPI, HTTPException, File, UploadFile, status, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import pandas as pd
import logging
from contextlib import asynccontextmanager
from pathlib import Path
import threading

from schemas import (
    SalaryPredictionRequest,
    SalaryPredictionResponse,
    BatchPredictionRequest,
    BatchPredictionResponse,
    RetrainingResponse,
    StreamingRetrainingRequest
)
from model_utils import ModelLoader, validate_input_data
from model_retraining import (
    retrain_model,
    load_csv_bytes,
    load_csv_data,
    validate_new_data
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global retraining status tracker
retraining_status = {
    'is_retraining': False,
    'last_retrain_time': None,
    'last_status_message': None,
    'model_reload_count': 0
}


# Startup and shutdown events
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Load model on startup."""
    logger.info("Starting application...")
    try:
        ModelLoader.load_model()
        model_info = ModelLoader.get_model_info()
        logger.info(f"Model loaded successfully: {model_info['model_name']}")
    except Exception as e:
        logger.error(f"Failed to load model during startup: {str(e)}")
    
    yield
    
    logger.info("Shutting down application...")


# Create FastAPI app
app = FastAPI(
    title="Salary Prediction API",
    description="API for predicting employee salaries using machine learning models",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allow all origins. In production, specify allowed origins
    allow_credentials=True,
    allow_methods=["*"],  # Allow all HTTP methods
    allow_headers=["*"],  # Allow all headers
)


# Root endpoint
@app.get("/", tags=["Root"])
async def root():
    """Root endpoint providing API information."""
    return {
        "message": "Welcome to Salary Prediction API",
        "version": "1.0.0",
        "docs_url": "/docs",
        "health_check": "/health"
    }


# Health check endpoint
@app.get("/health", tags=["Health"])
async def health_check():
    """Health check endpoint."""
    try:
        ModelLoader.load_model()
        return {
            "status": "healthy",
            "message": "API is running and model is loaded"
        }
    except Exception as e:
        return JSONResponse(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            content={
                "status": "unhealthy",
                "message": f"Model loading failed: {str(e)}"
            }
        )


# Model info endpoint
@app.get("/model/info", tags=["Model"])
async def get_model_info():
    """Get information about the loaded model."""
    try:
        info = ModelLoader.get_model_info()
        return {
            "status": "success",
            "data": info
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to retrieve model info: {str(e)}"
        )


# Single prediction endpoint
@app.post(
    "/predict",
    response_model=SalaryPredictionResponse,
    tags=["Predictions"],
    summary="Single Salary Prediction",
    description="Predict salary for a single employee based on demographic and job features"
)
async def predict_salary(request: SalaryPredictionRequest) -> SalaryPredictionResponse:
    """
    Predict salary for a single employee.
    
    Request body example:
    {
        "age": 32,
        "gender": "Male",
        "education_level": "Master's",
        "job_title": "Data Analyst",
        "years_of_experience": 7
    }
    """
    try:
        # Validate and prepare input
        input_dict = request.model_dump()
        input_df = validate_input_data(input_dict)
        
        # Make prediction
        predictions, model_name = ModelLoader.make_prediction(input_df)
        
        # Get model R² score for confidence metric
        model_info = ModelLoader.get_model_info()
        model = ModelLoader.load_model()
        
        # Extract R² score from model metadata
        r2_score = "Unknown"
        if model['model_type'] == 'pipeline':
            if hasattr(model['pipeline'], 'score'):
                r2_score = "Available in model"
        
        return SalaryPredictionResponse(
            predicted_salary=float(predictions[0]),
            model_name=model_name,
            confidence_metric=r2_score
        )
    
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid input: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Prediction error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Prediction failed: {str(e)}"
        )


# Batch prediction endpoint
@app.post(
    "/predict/batch",
    response_model=BatchPredictionResponse,
    tags=["Predictions"],
    summary="Batch Salary Predictions",
    description="Predict salaries for multiple employees at once (up to 100)"
)
async def predict_batch(request: BatchPredictionRequest) -> BatchPredictionResponse:
    """
    Predict salaries for multiple employees in a single request.
    
    Maximum 100 predictions per batch.
    """
    try:
        predictions_list = []
        
        for pred_request in request.predictions:
            input_dict = pred_request.model_dump()
            input_df = validate_input_data(input_dict)
            
            predictions, model_name = ModelLoader.make_prediction(input_df)
            
            predictions_list.append(
                SalaryPredictionResponse(
                    predicted_salary=float(predictions[0]),
                    model_name=model_name,
                    confidence_metric="Batch prediction"
                )
            )
        
        return BatchPredictionResponse(
            predictions=predictions_list,
            total_predictions=len(predictions_list)
        )
    
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid input: {str(e)}"
        )
    except Exception as e:
        logger.error(f"Batch prediction error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Batch prediction failed: {str(e)}"
        )


# ============================================================================
# RETRAINING ENDPOINTS
# ============================================================================

def _background_retrain(data: pd.DataFrame):
    """Background task to retrain model."""
    global retraining_status
    try:
        retraining_status['is_retraining'] = True
        logger.info("Background retraining started...")
        
        result = retrain_model(data)
        
        retraining_status['is_retraining'] = False
        retraining_status['last_retrain_time'] = result.get('timestamp')
        retraining_status['last_status_message'] = result.get('message')
        retraining_status['model_reload_count'] += 1
        
        # Reload model into cache
        ModelLoader._model = None
        ModelLoader.load_model()
        
        logger.info(f"Background retraining completed: {result.get('message')}")
    except Exception as e:
        retraining_status['is_retraining'] = False
        retraining_status['last_status_message'] = f"Error: {str(e)}"
        logger.error(f"Background retraining failed: {str(e)}", exc_info=True)


@app.post(
    "/retrain/upload",
    response_model=RetrainingResponse,
    tags=["Retraining"],
    summary="Upload CSV and Retrain Model",
    description="Upload a CSV file with training data to retrain the model"
)
async def retrain_upload(
    file: UploadFile = File(...),
    background_tasks: BackgroundTasks = None
) -> RetrainingResponse:
    """
    Upload a CSV file to retrain the model.
    
    CSV file must contain columns: age, gender, education_level, job_title, years_of_experience, salary
    
    Minimum 10 rows required for valid retraining.
    """
    try:
        if not file.filename.endswith('.csv'):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="File must be a CSV file (*.csv)"
            )
        
        # Read file content
        content = await file.read()
        logger.info(f"Received file: {file.filename} ({len(content)} bytes)")
        
        # Load CSV data
        df = load_csv_bytes(content)
        logger.info(f"CSV loaded: {df.shape[0]} rows, {df.shape[1]} columns")
        
        # Validate data
        is_valid, validation_msg = validate_new_data(df)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Data validation failed: {validation_msg}"
            )
        
        # If retraining is already in progress
        if retraining_status['is_retraining']:
            return RetrainingResponse(
                status='error',
                message='Retraining is already in progress. Please wait for completion.',
                timestamp=pd.Timestamp.now().isoformat()
            )
        
        # Run retraining in background
        background_tasks.add_task(_background_retrain, df)
        
        logger.info("Retraining task added to background queue")
        
        return RetrainingResponse(
            status='success',
            message='Retraining started in background. Check /retrain/status for progress.',
            timestamp=pd.Timestamp.now().isoformat()
        )
    
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"File upload error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"File upload failed: {str(e)}"
        )


@app.post(
    "/retrain/stream",
    response_model=RetrainingResponse,
    tags=["Retraining"],
    summary="Stream Data and Retrain Model",
    description="Stream data points to retrain the model with new data"
)
async def retrain_stream(
    request: StreamingRetrainingRequest,
    background_tasks: BackgroundTasks = None
) -> RetrainingResponse:
    """
    Stream salary data for model retraining.
    
    Accepts up to 1000 data points per request. Set trigger_retrain=true to start retraining.
    """
    try:
        data_points = request.data_points
        logger.info(f"Received {len(data_points)} data points for streaming")
        
        # Convert to DataFrame
        df = pd.DataFrame([dp.model_dump() for dp in data_points])
        logger.info(f"DataFrame created: {df.shape[0]} rows, {df.shape[1]} columns")
        
        # Validate data
        is_valid, validation_msg = validate_new_data(df)
        if not is_valid:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Data validation failed: {validation_msg}"
            )
        
        # Check if retraining already in progress
        if retraining_status['is_retraining']:
            return RetrainingResponse(
                status='error',
                message='Retraining is already in progress. Please wait for completion.',
                timestamp=pd.Timestamp.now().isoformat()
            )
        
        # Trigger retraining if requested
        if request.trigger_retrain:
            background_tasks.add_task(_background_retrain, df)
            logger.info("Streaming retraining task added to background queue")
            
            return RetrainingResponse(
                status='success',
                message=f'Streaming retraining started with {len(data_points)} data points. Check /retrain/status for progress.',
                timestamp=pd.Timestamp.now().isoformat()
            )
        else:
            return RetrainingResponse(
                status='success',
                message=f'Received {len(data_points)} data points. Set trigger_retrain=true to start retraining.',
                timestamp=pd.Timestamp.now().isoformat()
            )
    
    except HTTPException as e:
        raise e
    except Exception as e:
        logger.error(f"Streaming error: {str(e)}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Streaming request failed: {str(e)}"
        )


@app.get(
    "/retrain/status",
    tags=["Retraining"],
    summary="Check Retraining Status",
    description="Check the status of ongoing or last completed model retraining"
)
async def get_retrain_status():
    """Get current retraining status."""
    try:
        return {
            "is_retraining": retraining_status['is_retraining'],
            "last_retrain_time": retraining_status['last_retrain_time'],
            "last_status_message": retraining_status['last_status_message'],
            "model_reload_count": retraining_status['model_reload_count'],
            "current_model": ModelLoader.get_model_info()
        }
    except Exception as e:
        logger.error(f"Status check error: {str(e)}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get retraining status: {str(e)}"
        )


# Exception handler for validation errors
@app.exception_handler(ValueError)
async def value_error_handler(request, exc):
    """Handle value errors."""
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={"detail": str(exc)}
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=8000,
        log_level="info"
    )
