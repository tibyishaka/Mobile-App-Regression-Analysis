from pydantic import BaseModel, Field, field_validator
from typing import List, Optional


class SalaryPredictionRequest(BaseModel):
    """
    Request model for salary prediction endpoint.
    
    Constraints:
    - age: 18 to 80 years
    - years_of_experience: 0 to 60 years
    - gender: 'Male' or 'Female'
    - education_level: 'High School', "Bachelor's", "Master's", or "PhD"
    - job_title: string (1-100 characters)
    """
    age: int = Field(
        ...,
        ge=18,
        le=80,
        description="Age of the person (18-80 years)"
    )
    gender: str = Field(
        ...,
        description="Gender: 'Male' or 'Female'"
    )
    education_level: str = Field(
        ...,
        description="Education level: 'High School', 'Bachelor\\'s', 'Master\\'s', or 'PhD'"
    )
    job_title: str = Field(
        ...,
        min_length=1,
        max_length=100,
        description="Job title (1-100 characters)"
    )
    years_of_experience: float = Field(
        ...,
        ge=0,
        le=60,
        description="Years of professional experience (0-60 years)"
    )

    @field_validator('gender')
    @classmethod
    def validate_gender(cls, v):
        valid_genders = ['Male', 'Female']
        if v not in valid_genders:
            raise ValueError(f'Gender must be one of {valid_genders}')
        return v

    @field_validator('education_level')
    @classmethod
    def validate_education(cls, v):
        valid_education = ["High School", "Bachelor's", "Master's", "PhD"]
        if v not in valid_education:
            raise ValueError(f'Education level must be one of {valid_education}')
        return v


class SalaryPredictionResponse(BaseModel):
    """Response model for salary prediction."""
    predicted_salary: float = Field(..., description="Predicted annual salary in USD")
    model_name: str = Field(..., description="Name of the model used for prediction")
    confidence_metric: str = Field(..., description="Model R² score as a confidence metric")


class BatchPredictionRequest(BaseModel):
    """Request model for batch predictions."""
    predictions: List[SalaryPredictionRequest] = Field(
        ...,
        min_items=1,
        max_items=100,
        description="List of prediction requests (1-100 items)"
    )


class BatchPredictionResponse(BaseModel):
    """Response model for batch predictions."""
    predictions: List[SalaryPredictionResponse]
    total_predictions: int


class ModelMetrics(BaseModel):
    """Model performance metrics."""
    rmse: float = Field(..., description="Root Mean Squared Error")
    r2: float = Field(..., description="R² Score")


class RetrainingMetrics(BaseModel):
    """Comprehensive metrics from retraining."""
    sgd_rmse: float = Field(..., description="SGD Linear Regression RMSE")
    sgd_r2: float = Field(..., description="SGD Linear Regression R² Score")
    dt_rmse: float = Field(..., description="Decision Tree RMSE")
    dt_r2: float = Field(..., description="Decision Tree R² Score")
    rf_rmse: float = Field(..., description="Random Forest RMSE")
    rf_r2: float = Field(..., description="Random Forest R² Score")


class DataStatistics(BaseModel):
    """Statistics about the training data."""
    total_rows: int = Field(..., description="Total number of rows in dataset")
    train_rows: int = Field(..., description="Number of training rows")
    test_rows: int = Field(..., description="Number of testing rows")
    features: int = Field(..., description="Number of features")
    numeric_features: int = Field(..., description="Number of numeric features")
    categorical_features: int = Field(..., description="Number of categorical features")


class RetrainingResponse(BaseModel):
    """Response model for model retraining endpoint."""
    status: str = Field(..., description="Status of retraining: 'success' or 'error'")
    message: str = Field(..., description="Human-readable status message")
    best_model: Optional[str] = Field(None, description="Name of the best performing model")
    metrics: Optional[RetrainingMetrics] = Field(None, description="Performance metrics for all models")
    data_stats: Optional[DataStatistics] = Field(None, description="Statistics about the training data")
    training_time_seconds: Optional[float] = Field(None, description="Time taken to retrain in seconds")
    timestamp: str = Field(..., description="ISO format timestamp of retraining")


class StreamingDataPoint(BaseModel):
    """Single data point for streaming retraining."""
    age: int = Field(..., ge=18, le=80, description="Age of the person")
    gender: str = Field(..., description="Gender: 'Male' or 'Female'")
    education_level: str = Field(..., description="Education level")
    job_title: str = Field(..., description="Job title")
    years_of_experience: float = Field(..., ge=0, le=60, description="Years of experience")
    salary: float = Field(..., gt=0, description="Annual salary in USD")

    @field_validator('gender')
    @classmethod
    def validate_gender(cls, v):
        valid_genders = ['Male', 'Female']
        if v not in valid_genders:
            raise ValueError(f'Gender must be one of {valid_genders}')
        return v

    @field_validator('education_level')
    @classmethod
    def validate_education(cls, v):
        valid_education = ["High School", "Bachelor's", "Master's", "PhD"]
        if v not in valid_education:
            raise ValueError(f'Education level must be one of {valid_education}')
        return v


class StreamingRetrainingRequest(BaseModel):
    """Request model for streaming data retraining."""
    data_points: List[StreamingDataPoint] = Field(
        ...,
        min_items=1,
        max_items=1000,
        description="List of data points for retraining (1-1000 items)"
    )
    trigger_retrain: bool = Field(
        default=False,
        description="Whether to trigger retraining after adding data"
    )
