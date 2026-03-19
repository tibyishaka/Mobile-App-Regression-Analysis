# Render Deployment Guide

## Prerequisites

1. **Render Account**: Create a free account at https://render.com
2. **GitHub Repository**: Push your code to GitHub
3. **Model File**: Ensure `best_model_salary.pkl` is generated and committed to the repository

## Step-by-Step Deployment

### 1. Prepare Your Repository

Ensure your repository structure looks like this:

```
your-repo/
├── API/
│   ├── main.py
│   ├── schemas.py
│   ├── model_utils.py
│   ├── model_retraining.py
│   ├── requirements.txt
│   ├── config.py
│   ├── __init__.py
│   └── README.md
├── Linear_Regression/
│   ├── LinearRegression.ipynb
│   └── best_model_salary.pkl  # IMPORTANT: Must exist
├── Procfile
└── README.md
```

**CRITICAL**: Before pushing to GitHub, run the `LinearRegression.ipynb` notebook locally to generate `best_model_salary.pkl`. Then commit and push it to your repository.

### 2. Push Code to GitHub

```bash
git init
git add .
git commit -m "Initial commit with model"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO.git
git push -u origin main
```

### 3. Create New Web Service on Render

1. Go to https://render.com/dashboard
2. Click **"New +" button** in the top right
3. Select **"Web Service"**
4. Click **"Connect" next to your GitHub repository**
5. Select the repository name

### 4. Configure Web Service

Fill in the configuration form:

| Setting | Value |
| --- | --- |
| **Name** | `salary-prediction-api` (or your preference) |
| **Environment** | `Python 3` |
| **Region** | Choose the closest to your users |
| **Branch** | `main` |
| **Build Command** | `pip install -r requirements.txt --no-cache-dir` |
| **Start Command** | `uvicorn API.main:app --host 0.0.0.0 --port 8000` |
| **Instance Type** | `Free` (for testing) or `Starter` (for production) |

### 5. Environment Variables (Optional)

Under "Environment" section, you can add:

```
DEBUG=False
LOG_LEVEL=INFO
```

### 6. Deploy

1. Click the **"Create Web Service"** button
2. Render will automatically:
   - Clone your repository
   - Install dependencies from `requirements.txt`
   - Run the start command
   - Assign you a public URL

3. Wait for deployment to complete (may take 2-5 minutes)

### 7. Access Your API

Once deployment is complete, your API will be available at:

**Main URL**: `https://salary-prediction-api.onrender.com`

**Interactive Documentation**: 
- Swagger UI: `https://salary-prediction-api.onrender.com/docs`
- ReDoc: `https://salary-prediction-api.onrender.com/redoc`

**Health Check**: 
```bash
curl https://salary-prediction-api.onrender.com/health
```

## Testing Your Deployed API

### Make a Prediction

```bash
curl -X POST "https://salary-prediction-api.onrender.com/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "age": 32,
    "gender": "Male",
    "education_level": "Master'\''s",
    "job_title": "Data Analyst",
    "years_of_experience": 7
  }'
```

### Check Health

```bash
curl https://salary-prediction-api.onrender.com/health
```

## Troubleshooting

### Build Fails: "ModuleNotFoundError"

**Cause**: Dependencies not installed correctly

**Solution**:
1. Ensure all dependencies are in `requirements.txt`
2. Check the build log for specific missing modules
3. Update `requirements.txt` and push again

### Build Fails: "Model File Not Found"

**Cause**: `best_model_salary.pkl` is not in the repository

**Solution**:
1. Run `LinearRegression.ipynb` locally to generate the model
2. Ensure you're tracking `.pkl` files in git (not in `.gitignore`)
3. Commit and push the model file:
   ```bash
   git add Linear_Regression/best_model_salary.pkl
   git commit -m "Add trained model"
   git push
   ```

### Deployment Hangs

**Solution**:
1. Check if the model file is being loaded (check logs)
2. The model loading might be slow - patience needed
3. Check Render logs for errors

### API Returns 503 Unhealthy

**Cause**: Model failed to load during startup

**Solution**:
1. Check the API logs in Render dashboard
2. Verify the model file path: should be `../Linear_Regression/best_model_salary.pkl`
3. Regenerate the model if corrupted

## Performance Tips

### For Free Tier

- Free tier instances have limited resources
- Cold starts may take 30-60 seconds
- Consider upgrading to Starter ($10/month) for production use

### Database/Data Management

- The API doesn't use a database by default
- CSV uploads for retraining are processed in-memory
- For large files (>100MB), consider implementing storage integration

### Monitoring

Render provides:
- Live logs in the dashboard
- Metrics (CPU, memory usage)
- Deploy history
- Error tracking

## Scaling

If your API receives high traffic:

1. **Upgrade Instance Type**: From Free → Starter → Professional
2. **Enable Auto-Scaling**: Available on higher tiers
3. **Implement Caching**: Cache frequent predictions
4. **Database Integration**: Store prediction history

## Custom Domain

To use a custom domain:

1. In Render dashboard, go to Settings
2. Add your custom domain
3. Update DNS settings at your domain provider
4. Point to Render's nameservers or CNAME

## Continuous Deployment

Your Render service will automatically redeploy when:
- You push to the main branch
- You manually trigger a deploy in Render dashboard

To disable auto-deploy:
- Go to Service Settings → Auto-Deploy → set to "No"

## Important Notes

### Model Updates

If you retrain the model locally:
1. Replace `best_model_salary.pkl`
2. Commit and push to GitHub
3. Render will automatically redeploy

Or use the `/model/retrain/upload` endpoint to retrain dynamically.

### Security in Production

For production deployment:

1. **Limit CORS Origins**: Update `main.py` to allow only your domain
2. **Add Authentication**: Consider adding API key authentication
3. **Rate Limiting**: Implement rate limiting for the `/predict` endpoint
4. **Input Validation**: Already implemented via Pydantic
5. **Use Environment Variables**: Store sensitive data in Render environment variables

Example CORS update:
```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://yourdomain.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)
```

## Monitoring and Logs

### View Logs
1. Go to your service in Render dashboard
2. Click "Logs" tab
3. View real-time logs and deploy history

### Common Log Patterns

- `Uvicorn running on 0.0.0.0:8000` - Server started successfully
- `Model loaded successfully` - Model loaded in startup
- `POST /predict` - API prediction request
- `Predicted salary:` - Successful prediction (in app logs)

## Free vs Paid Tiers

| Feature | Free | Starter ($10/mo) | Professional ($100/mo) |
| --- | --- | --- | --- |
| Auto-scaling | ❌ | ✅ | ✅ |
| Concurrent requests | Limited | ~50 | ~500 |
| Cold start time | ~30-60s | ~5-10s | <1s |
| Memory | 512 MB | 1 GB | 4+ GB |
| Uptime SLA | 99.5% | 99.9% | 99.99% |

## Support

For Render-specific issues:
- Render Documentation: https://render.com/docs
- Render Status: https://status.render.com

For API code issues:
- FastAPI Docs: https://fastapi.tiangolo.com
- Check logs in Render dashboard

---

**Your Deployed API URL**: `https://salary-prediction-api.onrender.com`
**Documentation**: `https://salary-prediction-api.onrender.com/docs`
