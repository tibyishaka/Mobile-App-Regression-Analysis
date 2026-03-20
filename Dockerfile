# Multi-stage build for efficiency
FROM python:3.11-slim as builder

WORKDIR /tmp
COPY API/requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt && pip list

# Final stage
FROM python:3.11-slim

WORKDIR /app

# Copy Python dependencies from builder
COPY --from=builder /root/.local /root/.local

# Set environment variables
ENV PATH=/root/.local/bin:$PATH
ENV PYTHONUNBUFFERED=1

# Copy application code
COPY API/ /app/
COPY Linear_Regression/best_model_salary.pkl /app/../Linear_Regression/

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health')"

# Expose port
EXPOSE 8000

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
