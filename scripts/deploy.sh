#!/bin/bash

# Deployment script for self-hosted server

set -e

echo "Deploying AI Model Service..."

# Pull latest changes
git pull origin main

# Rebuild and restart containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# Wait for service to be healthy
echo "Waiting for service to be ready..."
sleep 10

# Check health
curl -f http://localhost:5000/health || {
    echo "Service health check failed!"
    docker-compose logs --tail=50
    exit 1
}

echo "Deployment successful!"
docker-compose ps


