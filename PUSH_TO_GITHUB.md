# Push to GitHub - Quick Guide

## Step 1: Create GitHub Repository

1. Go to https://github.com/new
2. Repository name: `ai-model-project` (or your preferred name)
3. **Important**: Do NOT check "Add a README file", "Add .gitignore", or "Choose a license"
4. Click "Create repository"

## Step 2: Set Up Git Remote

### Option A: Use the Setup Script

```powershell
.\scripts\setup-git.ps1 -GitHubUsername YOUR_GITHUB_USERNAME
```

### Option B: Manual Setup

```powershell
# Replace YOUR_USERNAME with your GitHub username
git remote add origin https://github.com/YOUR_USERNAME/ai-model-project.git
git branch -M main
```

## Step 3: Push to GitHub

```powershell
git push -u origin main
```

If you get an error about authentication, you may need to:
- Use a Personal Access Token instead of password
- Or set up SSH keys

## Step 4: Verify

1. Go to your repository on GitHub
2. You should see all your files
3. Check the **Actions** tab - workflows should be available

## Step 5: Set Up Self-Hosted Runner (For Auto-Deployment)

After pushing, set up the self-hosted runner so GitHub Actions can deploy to your PC:

1. Go to your repository on GitHub
2. Navigate to: **Settings** → **Actions** → **Runners**
3. Click **New self-hosted runner**
4. Select **Windows**
5. Copy the registration token
6. Run on your PC:
   ```powershell
   .\scripts\setup-self-hosted-runner.ps1
   ```
7. Start the runner:
   ```powershell
   cd actions-runner
   .\svc.cmd install
   .\svc.cmd start
   ```

## Troubleshooting

### Authentication Error
If you get authentication errors, use a Personal Access Token:
1. Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Generate new token with `repo` scope
3. Use token as password when pushing

### Branch Name Mismatch
If your default branch is `master` instead of `main`:
```powershell
git branch -M master
git push -u origin master
```

### Remote Already Exists
```powershell
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/ai-model-project.git
```

