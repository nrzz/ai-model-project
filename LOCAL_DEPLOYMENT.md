# Local Self-Hosting Setup Guide

This guide will help you set up the AI model to run on your current PC with automated deployment from GitHub Actions.

## Option 1: Self-Hosted GitHub Actions Runner (Recommended)

This allows GitHub Actions to automatically deploy to your PC when code is pushed.

### Step 1: Set Up Self-Hosted Runner

1. **Get Runner Token**:
   - Go to your GitHub repository
   - Navigate to: **Settings** → **Actions** → **Runners**
   - Click **New self-hosted runner**
   - Select **Windows** and copy the token

2. **Run Setup Script**:
   ```powershell
   .\scripts\setup-self-hosted-runner.ps1
   ```
   - Enter your repository URL
   - Enter the registration token

3. **Start Runner as Service** (Recommended):
   ```powershell
   cd actions-runner
   .\svc.cmd install
   .\svc.cmd start
   ```

4. **Verify Runner**:
   - Go to GitHub: **Settings** → **Actions** → **Runners**
   - You should see your runner listed as "online"

### Step 2: Update Workflow

The workflow is already configured to use self-hosted runners. The `deploy-local` job will run on your PC.

### Step 3: Test Deployment

1. Make a small change and push:
   ```powershell
   git add .
   git commit -m "Test deployment"
   git push
   ```

2. Check GitHub Actions:
   - Go to **Actions** tab
   - Watch the workflow run
   - The `deploy-local` job should run on your PC

## Option 2: Manual Local Deployment

If you prefer manual deployment without GitHub Actions runner:

### Step 1: Set Up Git Remote

```powershell
# Run the setup script
.\scripts\setup-git.ps1 -GitHubUsername YOUR_USERNAME

# Or manually:
git remote add origin https://github.com/YOUR_USERNAME/ai-model-project.git
git branch -M main
```

### Step 2: Push to GitHub

```powershell
git add .
git commit -m "Initial commit"
git push -u origin main
```

### Step 3: Deploy Locally

```powershell
# Pull latest changes
git pull

# Deploy using script
.\scripts\deploy-local.ps1

# Or manually:
docker-compose down
docker-compose build
docker-compose up -d
```

### Step 4: Set Up Auto-Pull (Optional)

Create a scheduled task to automatically pull and deploy:

```powershell
# Create a PowerShell script: auto-deploy.ps1
cd D:\ai-model-project
git pull
.\scripts\deploy-local.ps1

# Schedule it with Task Scheduler to run daily
```

## Option 3: GitHub Actions with Local Pull Script

Use GitHub Actions to train and build, then pull locally:

### Step 1: Configure GitHub Secrets (Optional)

Only needed if you want Docker Hub integration:
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

### Step 2: Create Local Pull Script

```powershell
# pull-and-deploy.ps1
cd D:\ai-model-project
git pull origin main
.\scripts\deploy-local.ps1
```

### Step 3: Schedule Local Script

Use Windows Task Scheduler to run `pull-and-deploy.ps1` periodically.

## Verification

After deployment, verify the service:

```powershell
# Check health
curl http://localhost:5000/health

# Or in PowerShell:
Invoke-WebRequest -Uri http://localhost:5000/health

# Test prediction
$body = @{text="I love this product!"} | ConvertTo-Json
Invoke-RestMethod -Uri http://localhost:5000/predict -Method POST -Body $body -ContentType "application/json"
```

## Troubleshooting

### Docker Not Running
```powershell
# Start Docker Desktop
# Or check status:
docker ps
```

### Port Already in Use
```powershell
# Change port in docker-compose.yml
ports:
  - "5001:5000"  # Use 5001 instead of 5000
```

### Runner Not Connecting
- Check runner is running: `cd actions-runner; .\run.cmd`
- Verify token is correct
- Check firewall settings
- Ensure runner has necessary permissions

### Service Not Starting
```powershell
# Check logs
docker-compose logs

# Rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

## Workflow Behavior

With self-hosted runner configured:

1. **On Push to main/master**:
   - ✅ Train model (on GitHub Actions)
   - ✅ Run tests (on GitHub Actions)
   - ✅ Build Docker image (on GitHub Actions)
   - ✅ Deploy to your PC (on self-hosted runner)

2. **Daily at 2 AM UTC**:
   - ✅ Train model automatically
   - ✅ Create release with new model

3. **Manual Trigger**:
   - Go to **Actions** → **Train and Deploy AI Model** → **Run workflow**

## Next Steps

1. ✅ Set up self-hosted runner (Option 1) OR use manual deployment (Option 2)
2. ✅ Push code to GitHub
3. ✅ Verify deployment works
4. ✅ Monitor GitHub Actions for automated training

Your AI model will now train and deploy automatically! 🚀

