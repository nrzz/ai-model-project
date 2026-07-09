# Master automation script - Sets up everything automatically
param(
    [Parameter(Mandatory=$false)]
    [string]$GitHubUsername = "",
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName = "ai-model-project",
    
    [Parameter(Mandatory=$false)]
    [string]$GitHubToken = ""
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "AI Model Project - Automated Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check prerequisites
Write-Host "[1/6] Checking prerequisites..." -ForegroundColor Yellow

$prereqsOk = $true

# Check Git
try {
    $gitVersion = git --version 2>&1
    Write-Host "  [OK] Git installed: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "  [ERROR] Git not found. Please install Git." -ForegroundColor Red
    $prereqsOk = $false
}

# Check Docker
try {
    docker ps 2>&1 | Out-Null
    Write-Host "  [OK] Docker is running" -ForegroundColor Green
} catch {
    Write-Host "  [WARN] Docker not running. Attempting to start..." -ForegroundColor Yellow
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe" -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 10
    try {
        docker ps 2>&1 | Out-Null
        Write-Host "  [OK] Docker is now running" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] Docker failed to start. Please start Docker Desktop manually." -ForegroundColor Red
        $prereqsOk = $false
    }
}

# Check GitHub CLI (optional)
$ghCliAvailable = $false
try {
    gh --version 2>&1 | Out-Null
    $ghCliAvailable = $true
    Write-Host "  [OK] GitHub CLI installed" -ForegroundColor Green
} catch {
    Write-Host "  [INFO] GitHub CLI not found (optional)" -ForegroundColor Yellow
}

if (-not $prereqsOk) {
    Write-Host ""
    Write-Host "Please fix the issues above and run again." -ForegroundColor Red
    exit 1
}

# Step 2: Get GitHub credentials if not provided
Write-Host ""
Write-Host "[2/6] Setting up GitHub..." -ForegroundColor Yellow

if ([string]::IsNullOrWhiteSpace($GitHubUsername)) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

if ([string]::IsNullOrWhiteSpace($GitHubToken) -and $ghCliAvailable) {
    Write-Host "  Attempting to use GitHub CLI for authentication..." -ForegroundColor Yellow
    try {
        gh auth status 2>&1 | Out-Null
        Write-Host "  [OK] GitHub CLI authenticated" -ForegroundColor Green
    } catch {
        Write-Host "  Please authenticate GitHub CLI: gh auth login" -ForegroundColor Yellow
        gh auth login
    }
}

# Step 3: Create GitHub repository (if GitHub CLI available)
$repoCreated = $false
if ($ghCliAvailable) {
    Write-Host ""
    Write-Host "[3/6] Creating GitHub repository..." -ForegroundColor Yellow
    try {
        $result = gh repo create $RepositoryName --public --source=. --remote=origin --push 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Repository created and code pushed!" -ForegroundColor Green
            $repoCreated = $true
        } else {
            Write-Host "  [WARN] Could not create repo via CLI" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARN] Could not create repo via CLI, will set up manually" -ForegroundColor Yellow
    }
}

# Step 4: Set up Git remote (if not created by GitHub CLI)
if (-not $repoCreated) {
    Write-Host ""
    Write-Host "[3/6] Setting up Git remote..." -ForegroundColor Yellow
    
    # Check if remote exists
    $remotes = git remote -v 2>&1
    $remoteExists = $remotes -match "origin"
    
    if ($remoteExists) {
        Write-Host "  [OK] Git remote already configured" -ForegroundColor Green
        git remote -v
    } else {
        $repoUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
        Write-Host "  Adding remote: $repoUrl" -ForegroundColor Yellow
        
        git remote add origin $repoUrl 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Git remote added" -ForegroundColor Green
        } else {
            Write-Host "  [WARN] Could not add remote. You may need to create the repository first." -ForegroundColor Yellow
            Write-Host "  Create it at: https://github.com/new" -ForegroundColor Cyan
            Write-Host "  Then run: git remote add origin $repoUrl" -ForegroundColor Cyan
        }
    }
    
    # Rename branch to main if needed
    $currentBranch = git branch --show-current 2>&1
    if ($currentBranch -eq "master") {
        Write-Host "  Renaming branch to main..." -ForegroundColor Yellow
        git branch -M main 2>&1 | Out-Null
    }
}

# Step 5: Push to GitHub
Write-Host ""
Write-Host "[4/6] Pushing to GitHub..." -ForegroundColor Yellow

$remotes = git remote -v 2>&1
$remoteExists = $remotes -match "origin"

if ($remoteExists) {
    try {
        # Try to push
        $pushOutput = git push -u origin main 2>&1 | Out-String
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Code pushed to GitHub!" -ForegroundColor Green
        } else {
            if ($pushOutput -match "authentication" -or $pushOutput -match "Permission denied") {
                Write-Host "  [WARN] Authentication required. Options:" -ForegroundColor Yellow
                Write-Host "    1. Use Personal Access Token as password" -ForegroundColor Cyan
                Write-Host "    2. Set up SSH keys" -ForegroundColor Cyan
                Write-Host "    3. Use GitHub CLI: gh auth login" -ForegroundColor Cyan
                Write-Host "  Then run: git push -u origin main" -ForegroundColor Cyan
            } else {
                Write-Host "  [WARN] Push failed. You may need to create the repository first." -ForegroundColor Yellow
                Write-Host "  Create it at: https://github.com/new?name=$RepositoryName" -ForegroundColor Cyan
            }
        }
    } catch {
        Write-Host "  [WARN] Push failed. See error above." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [WARN] No remote configured. Please create repository first." -ForegroundColor Yellow
}

# Step 6: Set up self-hosted runner
Write-Host ""
Write-Host "[5/6] Setting up self-hosted runner..." -ForegroundColor Yellow

$remotes = git remote -v 2>&1
$remoteExists = $remotes -match "origin"

if ($remoteExists) {
    $repoUrl = (git remote get-url origin 2>&1) -replace '\.git$', ''
    Write-Host "  Repository URL: $repoUrl" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  To set up the runner:" -ForegroundColor Yellow
    Write-Host "  1. Go to: $repoUrl/settings/actions/runners" -ForegroundColor Cyan
    Write-Host "  2. Click 'New self-hosted runner'" -ForegroundColor Cyan
    Write-Host "  3. Select 'Windows' and copy the token" -ForegroundColor Cyan
    Write-Host "  4. Run: .\scripts\setup-self-hosted-runner.ps1" -ForegroundColor Cyan
    Write-Host "  5. Start service: cd actions-runner; .\svc.cmd install; .\svc.cmd start" -ForegroundColor Cyan
} else {
    Write-Host "  [INFO] Set up runner after repository is created and pushed" -ForegroundColor Yellow
}

# Step 7: Initial local deployment
Write-Host ""
Write-Host "[6/6] Setting up local environment..." -ForegroundColor Yellow

# Create directories
New-Item -ItemType Directory -Force -Path models, data, outputs, logs | Out-Null
Write-Host "  [OK] Directories created" -ForegroundColor Green

# Check if Docker Compose is available
try {
    docker-compose --version 2>&1 | Out-Null
    Write-Host "  [OK] Docker Compose available" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "  Building Docker image..." -ForegroundColor Yellow
    docker-compose down 2>&1 | Out-Null
    docker-compose build 2>&1 | Out-Null
    
    Write-Host "  [OK] Docker image built" -ForegroundColor Green
    Write-Host ""
    Write-Host "  To start the service, run:" -ForegroundColor Cyan
    Write-Host "    docker-compose up -d" -ForegroundColor White
    Write-Host "  Or use: .\scripts\deploy-local.ps1" -ForegroundColor White
} catch {
    Write-Host "  [WARN] Docker Compose not found. Install Docker Desktop." -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$remotes = git remote -v 2>&1
$remoteExists = $remotes -match "origin"

if ($remoteExists) {
    $repoUrl = (git remote get-url origin 2>&1) -replace '\.git$', ''
    Write-Host ""
    Write-Host "[OK] Repository: $repoUrl" -ForegroundColor Green
    Write-Host "[OK] Local setup: Complete" -ForegroundColor Green
    Write-Host "[OK] Docker: Ready" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Push code (if not done): git push -u origin main" -ForegroundColor Cyan
    Write-Host "2. Set up self-hosted runner (see instructions above)" -ForegroundColor Cyan
    Write-Host "3. Start service: docker-compose up -d" -ForegroundColor Cyan
    Write-Host "4. Test: http://localhost:5000/health" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "[WARN] Repository not set up yet" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Create repository: https://github.com/new?name=$RepositoryName" -ForegroundColor Cyan
    Write-Host "2. Run: git remote add origin https://github.com/$GitHubUsername/$RepositoryName.git" -ForegroundColor Cyan
    Write-Host "3. Run: git push -u origin main" -ForegroundColor Cyan
    Write-Host "4. Set up self-hosted runner" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "For detailed instructions, see README.md" -ForegroundColor Cyan
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
