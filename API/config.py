"""
Configuration settings for the Salary Prediction API.
"""

import os
from pathlib import Path

# Application settings
APP_NAME = "Salary Prediction API"
APP_VERSION = "1.0.0"
DEBUG = os.getenv("DEBUG", "False") == "True"

# Model settings
MODEL_DIR = Path(__file__).parent.parent / "Linear_Regression"
MODEL_FILE = MODEL_DIR / "best_model_salary.pkl"

# API settings
API_TITLE = "Salary Prediction API"
API_DESCRIPTION = "API for predicting employee salaries using machine learning models"
API_VERSION = "1.0.0"

# CORS settings
CORS_ORIGINS = ["*"]
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_METHODS = ["*"]
CORS_ALLOW_HEADERS = ["*"]

# Request/Response settings
MAX_BATCH_SIZE = 100
REQUEST_TIMEOUT = 300  # seconds

# Logging settings
LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO")

# Server settings
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 8000))

# Prediction constraints
AGE_MIN = 18
AGE_MAX = 80
EXPERIENCE_MIN = 0
EXPERIENCE_MAX = 60
JOB_TITLE_MIN_LENGTH = 1
JOB_TITLE_MAX_LENGTH = 100

# Valid categorical values
VALID_GENDERS = ["Male", "Female"]
VALID_EDUCATION_LEVELS = ["High School", "Bachelor's", "Master's", "PhD"]
