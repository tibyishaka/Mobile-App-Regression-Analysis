"""
Model Retraining Module

Handles dynamic model retraining with new data uploaded via API or streamed.
Supports retraining with three algorithms: Linear Regression (SGD), Decision Tree, and Random Forest.

Features:
- Data validation and preprocessing
- Model retraining with hyperparameter optimization
- Model comparison and selection
- Saves best model artifact
- Tracks retraining history and metrics
"""

import pickle
import pandas as pd
import numpy as np
from pathlib import Path
from typing import Dict, Any, Tuple, List
import logging
from datetime import datetime
from io import StringIO, BytesIO

from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.impute import SimpleImputer
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import SGDRegressor
from sklearn.tree import DecisionTreeRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, r2_score

logger = logging.getLogger(__name__)

# Model paths
MODEL_DIR = Path(__file__).parent.parent / "Linear_Regression"
BACKUP_MODEL_DIR = Path(__file__).parent / "model_backups"
BEST_MODEL_PATH = MODEL_DIR / "best_model_salary.pkl"

# Hyperparameters for training
HYPERPARAMS = {
    'sgd': {
        'alphas': [1e-4, 1e-3, 1e-2],
        'eta0_values': [0.001, 0.01, 0.05],
        'epochs': 150
    },
    'dt': {
        'max_depth': 8,
        'min_samples_split': 10
    },
    'rf': {
        'n_estimators': 300,
        'max_depth': None,
        'min_samples_split': 5
    }
}

# Expected columns and constraints
REQUIRED_COLUMNS = {'age', 'gender', 'education_level', 'job_title', 'years_of_experience', 'salary'}
VALID_GENDERS = ['Male', 'Female']
VALID_EDUCATION_LEVELS = ["High School", "Bachelor's", "Master's", "PhD"]

# Data constraints
CONSTRAINTS = {
    'age': (18, 80),
    'years_of_experience': (0, 60),
    'salary': (1, 1000000)  # Minimum meaningful salary and max realistic
}

RANDOM_STATE = 42


def validate_new_data(df: pd.DataFrame) -> Tuple[bool, str]:
    """
    Validate new data for retraining.
    
    Args:
        df: DataFrame to validate
        
    Returns:
        Tuple of (is_valid, error_message)
    """
    try:
        # Check minimum rows
        if len(df) < 10:
            return False, f"Dataset too small: {len(df)} rows. Need at least 10 rows."
        
        # Check required columns
        missing_cols = REQUIRED_COLUMNS - set(df.columns)
        if missing_cols:
            return False, f"Missing required columns: {missing_cols}"
        
        # Normalize column names
        df.columns = [c.strip().lower().replace(' ', '_') for c in df.columns]
        
        # Check numeric conversions
        for col in ['age', 'years_of_experience', 'salary']:
            if col in df.columns:
                try:
                    df[col] = pd.to_numeric(df[col], errors='coerce')
                except Exception as e:
                    return False, f"Failed to convert column '{col}' to numeric: {str(e)}"
        
        # Check for NaN in target
        if df['salary'].isna().sum() > len(df) * 0.1:  # Allow max 10% NaN
            return False, f"Too many missing values in salary: {df['salary'].isna().sum()}"
        
        # Check constraints on numeric columns
        for col, (min_val, max_val) in CONSTRAINTS.items():
            if col in df.columns and df[col].dtype in [np.int64, np.float64]:
                out_of_range = ((df[col] < min_val) | (df[col] > max_val)).sum()
                if out_of_range > 0:
                    logger.warning(
                        f"Column '{col}': {out_of_range} rows outside "
                        f"expected range [{min_val}, {max_val}]"
                    )
        
        # Check categorical values
        if 'gender' in df.columns:
            invalid_genders = set(df['gender'].dropna().unique()) - set(VALID_GENDERS)
            if invalid_genders:
                return False, f"Invalid gender values: {invalid_genders}"
        
        if 'education_level' in df.columns:
            invalid_edu = set(df['education_level'].dropna().unique()) - set(VALID_EDUCATION_LEVELS)
            if invalid_edu:
                return False, f"Invalid education levels: {invalid_edu}"
        
        return True, "Data validation passed"
    
    except Exception as e:
        return False, f"Validation error: {str(e)}"


def prepare_data(df: pd.DataFrame) -> Tuple[pd.DataFrame, pd.Series, List[str], List[str]]:
    """
    Prepare data for model training.
    
    Args:
        df: Raw dataframe
        
    Returns:
        Tuple of (X, y, numeric_features, categorical_features)
    """
    df = df.copy()
    
    # Normalize columns
    df.columns = [c.strip().lower().replace(' ', '_') for c in df.columns]
    
    # Convert numeric columns
    for col in ['age', 'years_of_experience', 'salary']:
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors='coerce')
    
    # Remove rows with missing target
    df = df.dropna(subset=['salary'])
    
    # Drop leakage columns
    drop_cols = [c for c in ['salary_classification', 'salary_range', 'high_low_salary'] 
                 if c in df.columns]
    
    # Prepare features and target
    feature_cols = [c for c in df.columns if c not in drop_cols + ['salary']]
    X = df[feature_cols].copy()
    y = df['salary'].copy()
    
    numeric_features = X.select_dtypes(include=np.number).columns.tolist()
    categorical_features = X.select_dtypes(exclude=np.number).columns.tolist()
    
    return X, y, numeric_features, categorical_features


def build_preprocessor(numeric_features: List[str], 
                       categorical_features: List[str]) -> ColumnTransformer:
    """
    Build preprocessing pipeline.
    
    Args:
        numeric_features: List of numeric column names
        categorical_features: List of categorical column names
        
    Returns:
        ColumnTransformer for preprocessing
    """
    numeric_transformer = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy='median')),
        ('scaler', StandardScaler())
    ])
    
    categorical_transformer = Pipeline(steps=[
        ('imputer', SimpleImputer(strategy='most_frequent')),
        ('onehot', OneHotEncoder(handle_unknown='ignore'))
    ])
    
    preprocessor = ColumnTransformer(
        transformers=[
            ('num', numeric_transformer, numeric_features),
            ('cat', categorical_transformer, categorical_features)
        ]
    )
    
    return preprocessor


def train_sgd_model(X_train_prep: np.ndarray, X_test_prep: np.ndarray,
                    y_train: pd.Series, y_test: pd.Series) -> Dict[str, Any]:
    """
    Train SGD Linear Regression model with hyperparameter optimization.
    
    Args:
        X_train_prep: Preprocessed training features
        X_test_prep: Preprocessed test features
        y_train: Training target
        y_test: Test target
        
    Returns:
        Dictionary with best model and metrics
    """
    alphas = HYPERPARAMS['sgd']['alphas']
    eta0_values = HYPERPARAMS['sgd']['eta0_values']
    epochs = HYPERPARAMS['sgd']['epochs']
    
    best_model = None
    best_rmse = np.inf
    best_r2 = None
    best_params = None
    best_train_curve = None
    best_test_curve = None
    
    for alpha in alphas:
        for eta0 in eta0_values:
            model = SGDRegressor(
                loss='squared_error',
                penalty='l2',
                alpha=alpha,
                learning_rate='constant',
                eta0=eta0,
                max_iter=1,
                tol=None,
                random_state=RANDOM_STATE
            )
            
            train_curve = []
            test_curve = []
            
            for _ in range(epochs):
                model.partial_fit(X_train_prep, y_train)
                train_pred = model.predict(X_train_prep)
                test_pred = model.predict(X_test_prep)
                train_curve.append(mean_squared_error(y_train, train_pred))
                test_curve.append(mean_squared_error(y_test, test_pred))
            
            final_test_pred = model.predict(X_test_prep)
            rmse = np.sqrt(mean_squared_error(y_test, final_test_pred))
            r2 = r2_score(y_test, final_test_pred)
            
            if rmse < best_rmse:
                best_rmse = rmse
                best_r2 = r2
                best_model = model
                best_params = {'alpha': alpha, 'eta0': eta0, 'epochs': epochs}
                best_train_curve = train_curve
                best_test_curve = test_curve
    
    return {
        'model': best_model,
        'params': best_params,
        'rmse': best_rmse,
        'r2': best_r2,
        'train_curve': best_train_curve,
        'test_curve': best_test_curve
    }


def train_decision_tree(X_train: pd.DataFrame, X_test: pd.DataFrame,
                        y_train: pd.Series, y_test: pd.Series,
                        preprocessor: ColumnTransformer) -> Dict[str, Any]:
    """Train Decision Tree model."""
    params = HYPERPARAMS['dt']
    
    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('model', DecisionTreeRegressor(
            max_depth=params['max_depth'],
            min_samples_split=params['min_samples_split'],
            random_state=RANDOM_STATE
        ))
    ])
    
    pipeline.fit(X_train, y_train)
    pred = pipeline.predict(X_test)
    rmse = np.sqrt(mean_squared_error(y_test, pred))
    r2 = r2_score(y_test, pred)
    
    return {
        'pipeline': pipeline,
        'rmse': rmse,
        'r2': r2
    }


def train_random_forest(X_train: pd.DataFrame, X_test: pd.DataFrame,
                        y_train: pd.Series, y_test: pd.Series,
                        preprocessor: ColumnTransformer) -> Dict[str, Any]:
    """Train Random Forest model."""
    params = HYPERPARAMS['rf']
    
    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('model', RandomForestRegressor(
            n_estimators=params['n_estimators'],
            max_depth=params['max_depth'],
            min_samples_split=params['min_samples_split'],
            random_state=RANDOM_STATE,
            n_jobs=-1
        ))
    ])
    
    pipeline.fit(X_train, y_train)
    pred = pipeline.predict(X_test)
    rmse = np.sqrt(mean_squared_error(y_test, pred))
    r2 = r2_score(y_test, pred)
    
    return {
        'pipeline': pipeline,
        'rmse': rmse,
        'r2': r2
    }


def retrain_model(new_data: pd.DataFrame) -> Dict[str, Any]:
    """
    Retrain all three models with new data and select the best one.
    
    Args:
        new_data: DataFrame with new training data
        
    Returns:
        Dictionary with retraining results and best model artifact
    """
    logger.info("Starting model retraining...")
    retraining_start = datetime.now()
    
    try:
        # Validate data
        is_valid, validation_msg = validate_new_data(new_data)
        if not is_valid:
            logger.error(f"Data validation failed: {validation_msg}")
            raise ValueError(f"Data validation failed: {validation_msg}")
        
        logger.info(f"Data validation passed: {len(new_data)} rows")
        
        # Prepare data
        X, y, numeric_features, categorical_features = prepare_data(new_data)
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=RANDOM_STATE
        )
        
        logger.info(f"Data prepared: {X_train.shape[0]} train, {X_test.shape[0]} test")
        
        # Build preprocessor
        preprocessor = build_preprocessor(numeric_features, categorical_features)
        X_train_prep = preprocessor.fit_transform(X_train)
        X_test_prep = preprocessor.transform(X_test)
        
        logger.info("Preprocessing completed")
        
        # Train models
        logger.info("Training SGD model...")
        sgd_result = train_sgd_model(X_train_prep, X_test_prep, y_train, y_test)
        
        logger.info("Training Decision Tree model...")
        dt_result = train_decision_tree(X_train, X_test, y_train, y_test, preprocessor)
        
        logger.info("Training Random Forest model...")
        rf_result = train_random_forest(X_train, X_test, y_train, y_test, preprocessor)
        
        # Compare models
        results_df = pd.DataFrame([
            {'Model': 'LinearRegression_SGD', 'RMSE': sgd_result['rmse'], 'R2': sgd_result['r2']},
            {'Model': 'DecisionTree', 'RMSE': dt_result['rmse'], 'R2': dt_result['r2']},
            {'Model': 'RandomForest', 'RMSE': rf_result['rmse'], 'R2': rf_result['r2']}
        ]).sort_values('RMSE')
        
        best_model_name = results_df.iloc[0]['Model']
        logger.info(f"Best model selected: {best_model_name} with RMSE: {results_df.iloc[0]['RMSE']:.4f}")
        
        # Prepare model artifact
        feature_cols = X.columns.tolist()
        
        if best_model_name == 'LinearRegression_SGD':
            artifact = {
                'model_name': best_model_name,
                'model_type': 'separate',
                'preprocessor': preprocessor,
                'model': sgd_result['model'],
                'feature_columns': feature_cols,
                'target_column': 'salary',
                'metrics': {'rmse': sgd_result['rmse'], 'r2': sgd_result['r2']},
                'hyperparameters': sgd_result['params']
            }
        elif best_model_name == 'DecisionTree':
            artifact = {
                'model_name': best_model_name,
                'model_type': 'pipeline',
                'pipeline': dt_result['pipeline'],
                'feature_columns': feature_cols,
                'target_column': 'salary',
                'metrics': {'rmse': dt_result['rmse'], 'r2': dt_result['r2']}
            }
        else:
            artifact = {
                'model_name': best_model_name,
                'model_type': 'pipeline',
                'pipeline': rf_result['pipeline'],
                'feature_columns': feature_cols,
                'target_column': 'salary',
                'metrics': {'rmse': rf_result['rmse'], 'r2': rf_result['r2']}
            }
        
        # Backup old model
        if BEST_MODEL_PATH.exists():
            BACKUP_MODEL_DIR.mkdir(parents=True, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            backup_path = BACKUP_MODEL_DIR / f"best_model_salary_backup_{timestamp}.pkl"
            with open(BEST_MODEL_PATH, 'rb') as src:
                backup_data = src.read()
            with open(backup_path, 'wb') as dst:
                dst.write(backup_data)
            logger.info(f"Old model backed up to: {backup_path}")
        
        # Save new model
        MODEL_DIR.mkdir(parents=True, exist_ok=True)
        with open(BEST_MODEL_PATH, 'wb') as f:
            pickle.dump(artifact, f)
        logger.info(f"New model saved to: {BEST_MODEL_PATH}")
        
        retraining_duration = (datetime.now() - retraining_start).total_seconds()
        
        return {
            'status': 'success',
            'message': f'Model retraining completed successfully',
            'best_model': best_model_name,
            'metrics': {
                'sgd_rmse': sgd_result['rmse'],
                'sgd_r2': sgd_result['r2'],
                'dt_rmse': dt_result['rmse'],
                'dt_r2': dt_result['r2'],
                'rf_rmse': rf_result['rmse'],
                'rf_r2': rf_result['r2'],
            },
            'comparison_table': results_df.to_dict('records'),
            'data_stats': {
                'total_rows': len(new_data),
                'train_rows': len(X_train),
                'test_rows': len(X_test),
                'features': len(feature_cols),
                'numeric_features': len(numeric_features),
                'categorical_features': len(categorical_features)
            },
            'training_time_seconds': retraining_duration,
            'timestamp': datetime.now().isoformat()
        }
    
    except Exception as e:
        logger.error(f"Retraining failed: {str(e)}", exc_info=True)
        return {
            'status': 'error',
            'message': f'Model retraining failed: {str(e)}',
            'timestamp': datetime.now().isoformat()
        }


def load_csv_data(csv_content: str) -> pd.DataFrame:
    """
    Load CSV data from string content.
    
    Args:
        csv_content: CSV data as string
        
    Returns:
        DataFrame
    """
    try:
        df = pd.read_csv(StringIO(csv_content))
        return df
    except Exception as e:
        logger.error(f"Failed to parse CSV: {str(e)}")
        raise ValueError(f"Failed to parse CSV: {str(e)}")


def load_csv_bytes(csv_bytes: bytes) -> pd.DataFrame:
    """
    Load CSV data from bytes.
    
    Args:
        csv_bytes: CSV data as bytes
        
    Returns:
        DataFrame
    """
    try:
        df = pd.read_csv(BytesIO(csv_bytes))
        return df
    except Exception as e:
        logger.error(f"Failed to parse CSV from bytes: {str(e)}")
        raise ValueError(f"Failed to parse CSV: {str(e)}")
