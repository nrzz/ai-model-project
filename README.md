# AI Model Project - Automated Training & Self-Hosting

This project provides a complete AI model pipeline with automated training, versioning, and self-hosting capabilities.

## Features

- 🤖 **Sentiment Analysis Model**: Pre-trained DistilBERT-based classifier
- 🔄 **Automated Training**: GitHub Actions workflow for continuous training
- 🐳 **Docker Support**: Containerized deployment for easy self-hosting
- 📊 **Model Versioning**: Automatic versioning and artifact management
- 🚀 **REST API**: Flask-based API for model inference
- 📈 **Metrics Tracking**: Training metrics and model performance tracking

## Project Structure

```
ai-model-project/
├── model.py              # Model architecture and manager
├── train.py              # Training script
├── app.py                # Flask API server
├── requirements.txt      # Python dependencies
├── Dockerfile            # Docker image configuration
├── docker-compose.yml    # Docker Compose setup
├── .github/
│   └── workflows/
│       └── train-and-deploy.yml  # CI/CD pipeline
├── models/               # Trained model files (gitignored)
├── data/                 # Training data (gitignored)
└── outputs/              # Training outputs and metrics (gitignored)
```

## Quick Start

### Local Development

1. **Clone and setup**:
```bash
cd ai-model-project
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. **Train the model**:
```bash
python train.py --data_path data/train.csv --num_epochs 3
```

3. **Run the API server**:
```bash
python app.py
# Or with gunicorn:
gunicorn --bind 0.0.0.0:5000 app:app
```

4. **Test the API**:
```bash
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product!"}'
```

### Docker Deployment

1. **Build and run**:
```bash
docker-compose up -d
```

2. **Check logs**:
```bash
docker-compose logs -f
```

3. **Stop**:
```bash
docker-compose down
```

## API Endpoints

### Health Check
```bash
GET /health
```

### Single Prediction
```bash
POST /predict
Content-Type: application/json

{
  "text": "This is a great product!"
}
```

### Batch Prediction
```bash
POST /predict/batch
Content-Type: application/json

{
  "texts": ["Great!", "Not bad", "Terrible"]
}
```

### Reload Model
```bash
POST /reload
Content-Type: application/json

{
  "model_path": "models/model_v20241128_015400.pt"  # Optional
}
```

## GitHub Actions Workflow

The workflow automatically:
1. **Trains** the model on push to main/develop or on schedule (daily at 2 AM)
2. **Tests** the code and model loading
3. **Builds** Docker image
4. **Deploys** to self-hosted server (if configured)

### Required Secrets

Add these secrets to your GitHub repository:

- `DOCKER_USERNAME`: Docker Hub username
- `DOCKER_PASSWORD`: Docker Hub password or access token
- `SSH_HOST`: Self-hosted server IP/hostname
- `SSH_USERNAME`: SSH username
- `SSH_PRIVATE_KEY`: SSH private key for deployment

### Setting up Secrets

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add each secret listed above

## Self-Hosting Setup

### On Your Server

1. **Install Docker and Docker Compose**:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install docker.io docker-compose
sudo systemctl enable docker
sudo systemctl start docker
```

2. **Clone repository**:
```bash
cd /opt
git clone <your-repo-url> ai-model
cd ai-model
```

3. **Configure deployment**:
```bash
# Update docker-compose.yml if needed
docker-compose up -d
```

4. **Set up auto-update** (optional):
```bash
# Create a cron job to pull latest changes
crontab -e
# Add: 0 3 * * * cd /opt/ai-model && git pull && docker-compose up -d --build
```

## Training Data Format

The training script expects a CSV file with the following format:

```csv
text,label
"I love this product!",2
"This is okay",1
"Terrible experience",0
```

Labels:
- `0`: Negative
- `1`: Neutral
- `2`: Positive

## Model Versioning

Models are automatically versioned with timestamps:
- Format: `model_vYYYYMMDD_HHMMSS.pt`
- Best model is saved as `best_model.pt`
- Metrics are saved in `outputs/metrics_*.json`

## Customization

### Change Model Architecture

Edit `model.py` to modify the model architecture.

### Adjust Training Parameters

Modify `train.py` or pass arguments:
```bash
python train.py --num_epochs 5 --batch_size 32 --learning_rate 3e-5
```

### Change API Behavior

Edit `app.py` to add new endpoints or modify existing ones.

## Monitoring

- Check API health: `curl http://localhost:5000/health`
- View Docker logs: `docker-compose logs -f ai-model`
- Check training metrics: `cat outputs/metrics_*.json`

## Troubleshooting

### Model not found error
- Train the model first: `python train.py`
- Ensure model files exist in `models/` directory

### Docker build fails
- Check Docker is running: `docker ps`
- Verify Dockerfile syntax
- Check disk space: `df -h`

### Training fails
- Verify data file exists and format is correct
- Check GPU availability: `nvidia-smi` (if using GPU)
- Reduce batch size if out of memory

## License

MIT License - feel free to use this project for your own purposes.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

