# Mobile App Regression Analysis & Salary Prediction System

## 🎯 Mission

To strengthen cybersecurity awareness and digital literacy through accessible, data-driven education by building intelligent tools and APIs that help learners understand risk patterns and make safer digital decisions.

## 📋 Project Overview

This project is a comprehensive machine learning system that combines a machine learning pipeline with a  REST API and a mobile application frontend. The system trains regression models to predict employee salaries based on demographic and professional features, exposes these predictions via a FastAPI service, and consumes them in a mobile interface.

### Key Components

*   **Machine Learning Pipeline**: Jupyter notebook workflow for data analysis, preprocessing, and training multiple regression models (Linear Regression, Decision Tree, Random Forest).
*   **REST API**: A robust FastAPI backend that serves the best-performing model, handling single and batch predictions with strict data validation.
*   **Mobile Application**: A Flutter-based mobile app (located in `prediction_app/`) that allows users to interact with the prediction model on the go.

---

## ✨ Features

### ✅ API & Backend (FastAPI)
*   **Optimized Model Serving**: Automatically loads the best-trained model (`best_model_salary.pkl`).
*   **Multiple Endpoints**:
    *   `/predict`: Single salary prediction with real-time inference.
    *   `/predict/batch`: High-performance batch processing for up to 100 records.
    *   `/health`: System status monitoring.
    *   `/model/info`: Metadata about the currently active model.
*   **Robust Validation**: Pydantic models ensure data integrity (e.g., Age 18-80, valid Education levels).
*   **Production Ready**: Includes CORS middleware, structured logging, and Docker containerization.
*   **Interactive Docs**: Automatic Swagger UI (`/docs`) and ReDoc (`/redoc`).

### ✅ Machine Learning
*   **Model Comparison**: Trains and compares Linear Regression (SGD), Decision Tree, and Random Forest.
*   **Pipeline**: Includes EDA (Exploratory Data Analysis), feature engineering, and model persistence.

---

## 🛠️ Tech Stack

**Backend & ML**:
*   **Language**: Python 3.8+
*   **Framework**: FastAPI, Uvicorn
*   **Machine Learning**: Scikit-Learn, Pandas, NumPy
*   **Serialization**: Pickle
*   **Environment**: Virtualenv / Docker

**Frontend (Mobile)**:
*   **Framework**: Flutter
*   **Language**: Dart
*   **Platforms**: Android, iOS

**Tools & DevOps**:
*   **Containerization**: Docker, Docker Compose
*   **Notebooks**: Jupyter

---

## 📁 Project Structure

```
Mobile-App-Regression-Analysis/
├── API/                          # FastAPI Backend Application
│   ├── main.py                   # Application entry point
│   ├── schemas.py                # Data validation models
│   ├── model_utils.py            # Model loading & inference logic
│   ├── config.py                 # App configuration
│   └── ...
├── Linear_Regression/            # DS/ML Environment
│   ├── LinearRegression.ipynb    # Training notebook
│   └── best_model_salary.pkl     # Serialized model artifact
├── prediction_app/               # Mobile Application (Flutter)
│   ├── lib/                      # Dart source code
│   ├── pubspec.yaml              # App dependencies
│   └── ...
├── Dockerfile                    # Container definition
├── docker-compose.yml            # Multi-container orchestration
├── requirements.txt              # Python dependencies
└── README.md                     # Project documentation
```

---

## 🚀 Getting Started

### Prerequisites

*   Python 3.8+
*   Docker (Optional, for containerized run)
*   Flutter SDK (For mobile app development)

### Option 1: Local Python Setup

1.  **Navigate to the API directory**:
    ```bash
    cd API
    ```

2.  **Create and activate a virtual environment**:
    ```bash
    # Windows
    python -m venv venv
    venv\Scripts\activate

    # macOS/Linux
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **Install dependencies**:
    ```bash
    pip install -r requirements.txt
    ```

4.  **Run the API**:
    ```bash
    uvicorn main:app --reload
    ```
    The API will be accessible at `http://localhost:8000`.

### Option 2: Docker Setup

Run the entire backend stack using Docker Compose:

```bash
docker-compose up --build
```

Access the API documentation at `http://localhost:8000/docs`.

---

## 📱 Mobile Application Setup

To run the Flutter application that consumes the API:

1.  **Ensure the API is running** (locally or on a server).
2.  **Navigate to the app directory**:
    ```bash
    cd prediction_app
    ```
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
4.  **Run the app**:
    ```bash
    flutter run
    ```

---

## 📊 Dataset & Model Insights

### Dataset
The model is trained on the **Salary Data** dataset (sourced from Kaggle), which contains information about employees' demographic and professional details.

**Key Features:**
*   **Age**: Employee age in years.
*   **Gender**: Male or Female.
*   **Education Level**: High School, Bachelor's, Master's, PhD.
*   **Job Title**: Professional designation (e.g., "Software Engineer", "Data Scientist").
*   **Years of Experience**: Number of years in the workforce.
*   **Target**: Salary (Continuous variable).

### Model Training
The `LinearRegression.ipynb` notebook performs the following:
1.  **Data Cleaning**: Handling missing values and encoding categorical variables.
2.  **Training**: Three models are trained and evaluated:
    *   **Linear Regression (SGD)**: Good baseline for linear relationships.
    *   **Decision Tree**: Captures non-linear patterns.
    *   **Random Forest**: Ensemble method that generally provides the highest accuracy.
3.  **Selection**: The model with the best R² score is automatically saved as `best_model_salary.pkl`.

---

## 🧪 Usage & Testing

### API Endpoints

| Method | Endpoint         | Description                          |
| ------ | ---------------- | ------------------------------------ |
| `GET`  | `/`              | API Welcome & Status                 |
| `GET`  | `/health`        | Health check                         |
| `GET`  | `/model/info`    | Details about the loaded model       |
| `POST` | `/predict`       | Predict salary for a single user     |
| `POST` | `/predict/batch` | Predict salaries for a batch of users|

#### Sample Prediction Request
**POST** `/predict`
```json
{
  "age": 32,
  "gender": "Male",
  "education_level": "Master's",
  "job_title": "Data Analyst",
  "years_of_experience": 7
}
```

### Running Tests
Run the automated test suite to ensure everything is working correctly:

```bash
cd API
python test_api.py
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:
1.  Fork the repository.
2.  Create a new feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

---

## 📜 License

This project is open-source and available under the [MIT License](LICENSE).
