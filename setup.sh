#!/bin/bash

set -e

echo "Setting up AI Model Project..."

# Create virtual environment
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

# Install dependencies
echo "Installing dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Create necessary directories
echo "Creating directories..."
mkdir -p models data outputs logs

# Create sample data if it doesn't exist
if [ ! -f "data/train.csv" ]; then
    echo "Creating sample training data..."
    python train.py --data_path data/train.csv || true
fi

echo "Setup complete!"
echo "To activate the virtual environment, run: source venv/bin/activate"
echo "To train the model, run: python train.py"
echo "To start the API server, run: python app.py"


