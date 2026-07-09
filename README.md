# AI Model Project - Automated Training & Self-Hosting

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB)](https://www.python.org/)
[![PyTorch](https://img.shields.io/badge/PyTorch-EE4C2C)](https://pytorch.org/)

Sentiment analysis pipeline with automated training, Docker deployment, and a Flask REST API.

## Features

- DistilBERT-based 3-class sentiment classifier (negative / neutral / positive)
- Training script with automatic sample data generation
- Model versioning with timestamped checkpoints plus `best_model.pt`
- GitHub Actions CI/CD (train, test, build; deploy on manual trigger)
- Docker and docker-compose for local or server hosting
- Protected `/reload` endpoint (requires `RELOAD_TOKEN`)

## Project Structure

```
ai-model-project/
├── model.py              # Model architecture and ModelManager
├── train.py              # Training script
├── app.py                # Flask API server
├── requirements.txt      # Python dependencies
├── Dockerfile
├── docker-compose.yml
├── .github/workflows/train-and-deploy.yml
├── scripts/              # Setup and deployment helpers
├── tests/                # Unit and API tests
├── models/               # Trained weights (gitignored)
├── data/                 # Training CSV (gitignored)
└── outputs/              # Metrics JSON (gitignored)
```

## Quick Start

### Local development

**Windows:**
```powershell
.\setup.ps1
```

**Linux/macOS:**
```bash
chmod +x setup.sh && ./setup.sh
```

**Manual setup:**
```bash
python -m venv venv
source venv/bin/activate          # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

Train and run:
```bash
python train.py --data_path data/train.csv --num_epochs 3
python app.py
# Or: gunicorn --bind 0.0.0.0:5000 --workers 4 app:app
```

Test the API:
```bash
curl http://localhost:5000/health
curl -X POST http://localhost:5000/predict \
  -H "Content-Type: application/json" \
  -d '{"text": "I love this product!"}'
```

### Docker

```bash
docker-compose up -d
docker-compose logs -f
docker-compose down
```

Set `RELOAD_TOKEN` in `docker-compose.yml` (or an `.env` file) before using `/reload` in production.

## API Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Service health and model load status |
| POST | `/predict` | Single prediction (`{"text": "..."}`) |
| POST | `/predict/batch` | Batch prediction (`{"texts": ["...", "..."]}`) |
| POST | `/reload` | Reload model (requires auth token) |

### Reload authentication

`/reload` is disabled unless `RELOAD_TOKEN` is set. When configured, send either:

- `Authorization: Bearer <RELOAD_TOKEN>`, or
- `X-Reload-Token: <RELOAD_TOKEN>`

Optional body: `{"model_path": "models/model_v20241128_015400.pt"}`

## Training Data

CSV format (`data/train.csv`):

```csv
text,label
"I love this product!",2
"This is okay",1
"Terrible experience",0
```

Labels: `0` = negative, `1` = neutral, `2` = positive.

If the file is missing, `train.py` creates a small sample dataset automatically.

## Model Versioning

On each validation improvement during training:

- Timestamped checkpoint: `models/model_vYYYYMMDD_HHMMSS.pt`
- Best weights symlinked copy: `models/best_model.pt` (loaded by default at API startup)
- Metrics: `outputs/metrics_YYYYMMDD_HHMMSS.json`

## GitHub Setup

### 1. Create and push the repository

1. Create a new repo on GitHub (do not add README, license, or .gitignore).
2. Connect and push:

```bash
git remote add origin https://github.com/YOUR_USERNAME/ai-model-project.git
git branch -M main
git push -u origin main
```

Or on Windows: `.\scripts\setup-git.ps1 -GitHubUsername YOUR_USERNAME`

Use a [Personal Access Token](https://github.com/settings/tokens) if password auth fails.

### 2. Configure Actions secrets

Repository → **Settings** → **Secrets and variables** → **Actions**:

| Secret | Purpose |
|--------|---------|
| `DOCKER_USERNAME` | Docker Hub username (optional, for image push) |
| `DOCKER_PASSWORD` | Docker Hub password or access token |
| `SSH_HOST` | Remote server hostname/IP (for remote deploy) |
| `SSH_USERNAME` | SSH user |
| `SSH_PRIVATE_KEY` | SSH private key (full PEM content) |

### 3. Self-hosted runner (optional, for local deploy)

1. Repo → **Settings** → **Actions** → **Runners** → **New self-hosted runner** → Windows.
2. Run `.\scripts\setup-self-hosted-runner.ps1` with the registration token.
3. Install as a service:
   ```powershell
   cd actions-runner
   .\svc.cmd install
   .\svc.cmd start
   ```

## CI/CD Workflow

File: `.github/workflows/train-and-deploy.yml`

| Trigger | Behavior |
|---------|----------|
| Push to `main` / `master` / `develop` | Train (non-PR), test, build image |
| Pull request | Test only |
| Schedule (daily 02:00 UTC) | Train and build (no Docker push) |
| `workflow_dispatch` | Full pipeline including deploy jobs |

Deploy jobs (`deploy-local`, `deploy-remote`) run **only** on manual `workflow_dispatch`, not on every push.

Test failures block the pipeline. Docker push and remote deploy are skipped when the corresponding secrets are unset.

## Self-Hosting

### Linux server

```bash
sudo apt update && sudo apt install -y docker.io docker-compose-plugin
cd /opt && sudo git clone https://github.com/YOUR_USERNAME/ai-model-project.git ai-model
cd ai-model
docker compose up -d
curl http://localhost:5000/health
```

Optional cron auto-update:
```bash
0 3 * * * cd /opt/ai-model && git pull && docker compose up -d --build
```

### Windows local deployment

```powershell
git pull
.\scripts\deploy-local.ps1
# Or: docker-compose down && docker-compose build && docker-compose up -d
```

## Running Tests

```bash
pip install pytest pytest-cov
python -m pytest tests/ -v
```

## Customization

- **Model architecture:** edit `model.py`
- **Training hyperparameters:** `python train.py --num_epochs 5 --batch_size 32 --learning_rate 3e-5`
- **API routes:** edit `app.py`
- **Workflow:** edit `.github/workflows/train-and-deploy.yml`

## Troubleshooting

| Issue | Fix |
|-------|-----|
| Model not found | Run `python train.py`; confirm `models/best_model.pt` exists |
| Docker healthcheck fails | `requests` is in `requirements.txt`; rebuild the image |
| `/reload` returns 401 | Set `RELOAD_TOKEN` and send the Bearer or `X-Reload-Token` header |
| `/reload` returns 503 | `RELOAD_TOKEN` is not configured |
| Training OOM | Lower `--batch_size` |
| Port 5000 in use | Change the host port in `docker-compose.yml` |
| GitHub Actions deploy skipped | Use **Actions → Train and Deploy AI Model → Run workflow** |
| Runner offline | `cd actions-runner; .\run.cmd` or restart the Windows service |

## License

MIT License
