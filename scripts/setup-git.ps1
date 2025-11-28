# PowerShell script to set up Git remote and push

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName = "ai-model-project"
)

Write-Host "Setting up Git repository..." -ForegroundColor Green

# Check if git is initialized
if (-not (Test-Path ".git")) {
    Write-Host "Initializing git repository..." -ForegroundColor Yellow
    git init
    git branch -M main
}

# Check if remote already exists
$remoteExists = git remote -v | Select-String "origin"
if ($remoteExists) {
    Write-Host "Remote 'origin' already exists. Removing..." -ForegroundColor Yellow
    git remote remove origin
}

# Add remote
$remoteUrl = "https://github.com/$GitHubUsername/$RepositoryName.git"
Write-Host "Adding remote: $remoteUrl" -ForegroundColor Yellow
git remote add origin $remoteUrl

# Verify remote
Write-Host "`nVerifying remote configuration..." -ForegroundColor Yellow
git remote -v

Write-Host "`nGit setup complete!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Create the repository on GitHub: https://github.com/new" -ForegroundColor White
Write-Host "   Repository name: $RepositoryName" -ForegroundColor White
Write-Host "   Do NOT initialize with README, .gitignore, or license" -ForegroundColor White
Write-Host "`n2. Push your code:" -ForegroundColor White
Write-Host "   git add ." -ForegroundColor Gray
Write-Host "   git commit -m 'Initial commit'" -ForegroundColor Gray
Write-Host "   git push -u origin main" -ForegroundColor Gray

