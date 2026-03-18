"""
Test script for the Salary Prediction API.

Run this script to test all endpoints locally:
    python test_api.py
"""

import requests
import json
from typing import Dict, Any

# Configuration
BASE_URL = "http://localhost:8000"
TIMEOUT = 10


def print_response(title: str, response: requests.Response):
    """Pretty print API response."""
    print(f"\n{'='*60}")
    print(f"🧪 {title}")
    print(f"{'='*60}")
    print(f"Status Code: {response.status_code}")
    try:
        print(json.dumps(response.json(), indent=2))
    except:
        print(response.text)


def test_health_check():
    """Test health check endpoint."""
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=TIMEOUT)
        print_response("Health Check", response)
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Health check failed: {str(e)}")
        return False


def test_model_info():
    """Test model info endpoint."""
    try:
        response = requests.get(f"{BASE_URL}/model/info", timeout=TIMEOUT)
        print_response("Model Info", response)
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Model info failed: {str(e)}")
        return False


def test_single_prediction():
    """Test single prediction endpoint."""
    try:
        payload = {
            "age": 32,
            "gender": "Male",
            "education_level": "Master's",
            "job_title": "Data Analyst",
            "years_of_experience": 7
        }
        response = requests.post(
            f"{BASE_URL}/predict",
            json=payload,
            timeout=TIMEOUT
        )
        print_response("Single Prediction", response)
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Single prediction failed: {str(e)}")
        return False


def test_batch_prediction():
    """Test batch prediction endpoint."""
    try:
        payload = {
            "predictions": [
                {
                    "age": 32,
                    "gender": "Male",
                    "education_level": "Master's",
                    "job_title": "Data Analyst",
                    "years_of_experience": 7
                },
                {
                    "age": 25,
                    "gender": "Female",
                    "education_level": "Bachelor's",
                    "job_title": "Software Engineer",
                    "years_of_experience": 2
                },
                {
                    "age": 45,
                    "gender": "Male",
                    "education_level": "PhD",
                    "job_title": "Research Director",
                    "years_of_experience": 20
                }
            ]
        }
        response = requests.post(
            f"{BASE_URL}/predict/batch",
            json=payload,
            timeout=TIMEOUT
        )
        print_response("Batch Prediction (3 samples)", response)
        return response.status_code == 200
    except Exception as e:
        print(f"❌ Batch prediction failed: {str(e)}")
        return False


def test_invalid_input():
    """Test error handling with invalid input."""
    try:
        payload = {
            "age": 150,  # Invalid: exceeds max age of 80
            "gender": "Male",
            "education_level": "Master's",
            "job_title": "Data Analyst",
            "years_of_experience": 7
        }
        response = requests.post(
            f"{BASE_URL}/predict",
            json=payload,
            timeout=TIMEOUT
        )
        print_response("Invalid Input Handling (age > 80)", response)
        return response.status_code == 422  # Validation error
    except Exception as e:
        print(f"❌ Invalid input test failed: {str(e)}")
        return False


def test_cors_headers():
    """Test CORS headers."""
    try:
        response = requests.options(
            f"{BASE_URL}/predict",
            timeout=TIMEOUT
        )
        
        print(f"\n{'='*60}")
        print(f"🧪 CORS Headers Test")
        print(f"{'='*60}")
        
        cors_headers = {
            'Access-Control-Allow-Origin': response.headers.get('access-control-allow-origin'),
            'Access-Control-Allow-Methods': response.headers.get('access-control-allow-methods'),
            'Access-Control-Allow-Headers': response.headers.get('access-control-allow-headers'),
        }
        
        print(json.dumps(cors_headers, indent=2))
        
        has_cors = response.headers.get('access-control-allow-origin') is not None
        print(f"CORS Enabled: {'✅ Yes' if has_cors else '❌ No'}")
        
        return has_cors
    except Exception as e:
        print(f"❌ CORS test failed: {str(e)}")
        return False


def main():
    """Run all tests."""
    print("\n" + "="*60)
    print("🚀 Salary Prediction API - Test Suite")
    print("="*60)
    print(f"\nBase URL: {BASE_URL}")
    print(f"Timeout: {TIMEOUT}s")
    
    results = {
        "Health Check": test_health_check(),
        "Model Info": test_model_info(),
        "Single Prediction": test_single_prediction(),
        "Batch Prediction": test_batch_prediction(),
        "Invalid Input Handling": test_invalid_input(),
        "CORS Headers": test_cors_headers(),
    }
    
    # Summary
    print(f"\n{'='*60}")
    print("📊 Test Summary")
    print(f"{'='*60}")
    
    passed = sum(1 for v in results.values() if v)
    total = len(results)
    
    for test_name, result in results.items():
        status = "✅ PASSED" if result else "❌ FAILED"
        print(f"{test_name}: {status}")
    
    print(f"\n{'='*60}")
    print(f"Result: {passed}/{total} tests passed")
    print(f"{'='*60}\n")
    
    return passed == total


if __name__ == "__main__":
    import sys
    import time
    
    print("\n⏳ Waiting 2 seconds before starting tests...\n")
    time.sleep(2)
    
    success = main()
    sys.exit(0 if success else 1)
