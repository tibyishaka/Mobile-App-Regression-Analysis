# Mobile App Regression Analysis

## Mission
To strengthen cybersecurity awareness through accessible, data-driven education by building intelligent tools that help learners understand risk patterns and make safer digital decisions.

## Project Overview
This project demonstrates a regression-based machine learning workflow in a mobile-app context. It includes data preparation, exploratory analysis, model training, model comparison, and model export for later prediction use.

The notebook currently compares three regression approaches:
- Linear Regression (SGD-based training)
- Decision Tree Regressor
- Random Forest Regressor

## Objectives
- Build and evaluate multiple regression models on the same dataset.
- Compare model quality using RMSE and R2.
- Save the best-performing model artifact for deployment.
- Run sample predictions with the saved model.

## Repository Structure
- `Linear_Regression/LinearRegression.ipynb`: Main notebook for preprocessing, training, evaluation, and prediction.
- `API/predict_best_model.py`: Script for loading and running predictions with the saved best model.
- `API/x_test.csv`: Example test input data.

## Quick Start
1. Create and activate a Python virtual environment.
2. Install required packages used in the notebook (for example: `numpy`, `pandas`, `matplotlib`, `seaborn`, `scikit-learn`, `kagglehub`).
3. Open and run `Linear_Regression/LinearRegression.ipynb` top-to-bottom.

## Notes
- The notebook is configured to download the dataset from Kaggle using `kagglehub`.
- Internet access is required for first-time dataset download.
