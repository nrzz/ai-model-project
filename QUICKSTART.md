# Quick Start Guide

## 🚀 Get Started in 5 Minutes

### Step 1: Setup Local Environment

**Windows:**
```powershell
.\setup.ps1
```

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

### Step 2: Train Your First Model

```bash
python train.py
```

This will:
- Create sample training data if needed
- Train a sentiment analysis model
- Save the model to `models/` directory

### Step 3: Start the API Server

```bash
python app.py
```

Or with gunicorn (production):
```bash
gunicorn --bind 0.0.0.0:5000 --workers 4 app:app
```

### Step 4: Test the API

Open a new terminal and run:

```bash
# Health check
curl http://localhost:5000/health

# Make a prediction
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product!"}'
```

## 🐳 Docker Quick Start

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop
docker-compose down
```

## 📤 Push to GitHub

1. Create a new repository on GitHub
2. Add remote and push:

```bash
git remote add origin https://github.com/YOUR_USERNAME/ai-model-project.git
git branch -M main
git push -u origin main
```

3. Configure GitHub Secrets (see `GIT_SETUP.md`)
4. The workflow will automatically train and deploy!

## 🔄 Automated Workflow

Once pushed to GitHub, the workflow will:

- ✅ Train model on every push to main/develop
- ✅ Run tests automatically
- ✅ Build Docker image
- ✅ Deploy to self-hosted server (if configured)
- ✅ Train daily at 2 AM UTC (scheduled)

## 📝 Next Steps

- Read `README.md` for detailed documentation
- Check `GIT_SETUP.md` for GitHub configuration
- Customize the model in `model.py`
- Add your training data to `data/train.csv`

## 🆘 Need Help?

- Check `README.md` for troubleshooting
- Review GitHub Actions logs if workflow fails
- Verify Docker is running: `docker ps`

