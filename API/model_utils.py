import pickle
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Union, Dict, Any, Tuple
import logging

logger = logging.getLogger(__name__)

# Path to the best model artifact
MODEL_PATH = Path(__file__).parent.parent / "Linear_Regression" / "best_model_salary.pkl"


class ModelLoader:
    """Utility class for loading and using the trained model."""
    
    _instance = None
    _model = None
    _model_metadata = None

    def __new__(cls):
        """Singleton pattern to ensure only one model instance."""
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    @classmethod
    def load_model(cls) -> Dict[str, Any]:
        """
        Load the best model artifact from pickle file.
        
        Returns:
            Dictionary containing the model artifact with keys:
            - model_name: Name of the best performing model
            - model_type: 'pipeline' or 'separate'
            - pipeline/model: The trained model or pipeline
            - preprocessor: Feature preprocessor (if model_type is 'separate')
            - feature_columns: List of feature column names
            - target_column: Target column name
        
        Raises:
            FileNotFoundError: If model file doesn't exist
            Exception: If model loading fails
        """
        if cls._model is None:
            try:
                if not MODEL_PATH.exists():
                    raise FileNotFoundError(
                        f"Model file not found at {MODEL_PATH}. "
                        "Please run the Linear_Regression/LinearRegression.ipynb notebook first."
                    )
                
                with open(MODEL_PATH, 'rb') as f:
                    cls._model = pickle.load(f)
                
                logger.info(f"Model loaded successfully: {cls._model.get('model_name', 'Unknown')}")
            
            except Exception as e:
                logger.error(f"Failed to load model: {str(e)}")
                raise
        
        return cls._model

    @classmethod
    def make_prediction(
        cls, 
        input_data: pd.DataFrame
    ) -> Tuple[np.ndarray, str, float]:
        """
        Make predictions using the loaded model.
        
        Args:
            input_data: DataFrame with the same features as training data
        
        Returns:
            Tuple of (predictions array, model name, R² score)
        """
        model = cls.load_model()
        
        try:
            if model['model_type'] == 'pipeline':
                predictions = model['pipeline'].predict(input_data)
            else:
                # Separate preprocessor and model
                transformed_data = model['preprocessor'].transform(input_data)
                predictions = model['model'].predict(transformed_data)
            
            # Get model metadata for response
            model_name = model['model_name']
            
            return predictions, model_name
        
        except Exception as e:
            logger.error(f"Prediction failed: {str(e)}")
            raise

    @classmethod
    def get_model_info(cls) -> Dict[str, Any]:
        """Get metadata about the loaded model."""
        model = cls.load_model()
        return {
            'model_name': model.get('model_name', 'Unknown'),
            'model_type': model.get('model_type', 'Unknown'),
            'feature_columns': model.get('feature_columns', []),
            'target_column': model.get('target_column', 'salary')
        }


def validate_input_data(input_dict: Dict[str, Any]) -> pd.DataFrame:
    """
    Validate and convert input dictionary to DataFrame for model.
    
    Args:
        input_dict: Dictionary with prediction features
    
    Returns:
        DataFrame ready for model prediction
    """
    try:
        df = pd.DataFrame([input_dict])
        return df
    except Exception as e:
        logger.error(f"Input validation failed: {str(e)}")
        raise ValueError(f"Failed to validate input data: {str(e)}")
