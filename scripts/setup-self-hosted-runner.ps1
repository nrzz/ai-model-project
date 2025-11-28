# Setup script for GitHub Actions self-hosted runner on Windows

Write-Host "Setting up GitHub Actions Self-Hosted Runner" -ForegroundColor Green
Write-Host "This will allow GitHub Actions to deploy directly to this PC" -ForegroundColor Yellow

$repoUrl = Read-Host "Enter your GitHub repository URL (e.g., https://github.com/username/ai-model-project)"
$token = Read-Host "Enter the runner registration token (from GitHub: Settings > Actions > Runners > New self-hosted runner)"

if ([string]::IsNullOrWhiteSpace($repoUrl) -or [string]::IsNullOrWhiteSpace($token)) {
    Write-Host "Error: Repository URL and token are required" -ForegroundColor Red
    exit 1
}

# Create runner directory
$runnerDir = "actions-runner"
if (Test-Path $runnerDir) {
    Write-Host "Runner directory already exists. Removing..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $runnerDir
}

# Download runner
Write-Host "Downloading GitHub Actions runner..." -ForegroundColor Yellow
$runnerUrl = "https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip"
$zipFile = "actions-runner.zip"

Invoke-WebRequest -Uri $runnerUrl -OutFile $zipFile

# Extract
Write-Host "Extracting runner..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $runnerDir -Force
Remove-Item $zipFile

# Configure
Write-Host "Configuring runner..." -ForegroundColor Yellow
Set-Location $runnerDir
.\config.cmd --url $repoUrl --token $token --name "windows-self-hosted" --work "_work" --unattended

Write-Host "`nRunner setup complete!" -ForegroundColor Green
Write-Host "`nTo start the runner:" -ForegroundColor Cyan
Write-Host "  cd $runnerDir" -ForegroundColor White
Write-Host "  .\run.cmd" -ForegroundColor White
Write-Host "`nTo run as a service (recommended):" -ForegroundColor Cyan
Write-Host "  .\svc.cmd install" -ForegroundColor White
Write-Host "  .\svc.cmd start" -ForegroundColor White

Set-Location ..

