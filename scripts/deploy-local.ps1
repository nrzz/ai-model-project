# Local deployment script for Windows

Write-Host "Deploying AI Model Service Locally..." -ForegroundColor Green

# Check if Docker is running
try {
    docker ps | Out-Null
    Write-Host "Docker is running" -ForegroundColor Green
} catch {
    Write-Host "Error: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Pull latest changes if in git repo
if (Test-Path ".git") {
    Write-Host "Pulling latest changes..." -ForegroundColor Yellow
    git pull origin main 2>$null
    git pull origin master 2>$null
}

# Stop existing containers
Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down

# Build and start
Write-Host "Building and starting containers..." -ForegroundColor Yellow
docker-compose build
docker-compose up -d

# Wait for service to be ready
Write-Host "Waiting for service to be ready..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

# Check health
$maxRetries = 10
$retryCount = 0
$healthy = $false

while ($retryCount -lt $maxRetries -and -not $healthy) {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5000/health" -UseBasicParsing -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            $healthy = $true
            Write-Host "Service is healthy!" -ForegroundColor Green
        }
    } catch {
        $retryCount++
        Write-Host "Waiting for service... ($retryCount/$maxRetries)" -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }
}

if (-not $healthy) {
    Write-Host "Warning: Service health check failed. Check logs:" -ForegroundColor Yellow
    docker-compose logs --tail=50
} else {
    Write-Host "`nDeployment successful!" -ForegroundColor Green
    Write-Host "Service is running at: http://localhost:5000" -ForegroundColor Cyan
    Write-Host "`nContainer status:" -ForegroundColor Yellow
    docker-compose ps
    Write-Host "`nTo view logs: docker-compose logs -f" -ForegroundColor Gray
    Write-Host "To stop: docker-compose down" -ForegroundColor Gray
}

