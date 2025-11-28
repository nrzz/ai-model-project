# PowerShell setup script for Windows

Write-Host "Setting up AI Model Project..." -ForegroundColor Green

# Create virtual environment
if (-not (Test-Path "venv")) {
    Write-Host "Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

# Activate virtual environment
Write-Host "Activating virtual environment..." -ForegroundColor Yellow
& .\venv\Scripts\Activate.ps1

# Install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Yellow
python -m pip install --upgrade pip
pip install -r requirements.txt

# Create necessary directories
Write-Host "Creating directories..." -ForegroundColor Yellow
New-Item -ItemType Directory -Force -Path models, data, outputs, logs | Out-Null

# Create sample data if it doesn't exist
if (-not (Test-Path "data\train.csv")) {
    Write-Host "Creating sample training data..." -ForegroundColor Yellow
    python train.py --data_path data/train.csv
}

Write-Host "Setup complete!" -ForegroundColor Green
Write-Host "To activate the virtual environment, run: .\venv\Scripts\Activate.ps1" -ForegroundColor Cyan
Write-Host "To train the model, run: python train.py" -ForegroundColor Cyan
Write-Host "To start the API server, run: python app.py" -ForegroundColor Cyan


