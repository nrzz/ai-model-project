# Git Repository Setup Guide

## Initial Setup

Your AI model project is ready to be pushed to GitHub. Follow these steps:

### 1. Create a GitHub Repository

1. Go to [GitHub](https://github.com) and create a new repository
2. Name it `ai-model-project` (or your preferred name)
3. **Do NOT** initialize with README, .gitignore, or license (we already have these)

### 2. Connect Local Repository to GitHub

Run these commands in the `ai-model-project` directory:

```bash
# Add remote repository (replace YOUR_USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR_USERNAME/ai-model-project.git

# Rename default branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main
```

### 3. Configure GitHub Secrets

For the automated workflow to work, you need to add secrets to your GitHub repository:

1. Go to your repository on GitHub
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** and add:

#### Required Secrets:

- **DOCKER_USERNAME**: Your Docker Hub username
- **DOCKER_PASSWORD**: Your Docker Hub password or access token
- **SSH_HOST**: Your self-hosted server IP or hostname (e.g., `192.168.1.100` or `myserver.com`)
- **SSH_USERNAME**: SSH username for your server
- **SSH_PRIVATE_KEY**: Your SSH private key content (the entire key, including `-----BEGIN OPENSSH PRIVATE KEY-----`)

#### Optional Secrets (if not using Docker Hub):

- **GHCR_TOKEN**: GitHub Container Registry token (if using GHCR instead)

### 4. Enable GitHub Actions

GitHub Actions should be enabled by default. If not:

1. Go to **Settings** → **Actions** → **General**
2. Ensure "Allow all actions and reusable workflows" is selected
3. Save changes

### 5. Verify Workflow

1. Make a small change to any file
2. Commit and push:
   ```bash
   git add .
   git commit -m "Test workflow"
   git push
   ```
3. Go to **Actions** tab in your GitHub repository
4. You should see the workflow running

## Workflow Triggers

The workflow will automatically run on:

- **Push to main/develop branches**: Trains model and deploys
- **Pull requests**: Runs tests only
- **Scheduled (daily at 2 AM UTC)**: Trains model automatically
- **Manual trigger**: Go to Actions → Train and Deploy AI Model → Run workflow

## Self-Hosting Setup

### On Your Server (Linux):

1. **Install Docker and Docker Compose**:
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

2. **Clone your repository**:
   ```bash
   cd /opt
   sudo git clone https://github.com/YOUR_USERNAME/ai-model-project.git
   cd ai-model-project
   ```

3. **Set up SSH key for GitHub Actions**:
   ```bash
   # Generate SSH key if you don't have one
   ssh-keygen -t ed25519 -C "github-actions" -f ~/.ssh/github_actions
   
   # Add public key to authorized_keys
   cat ~/.ssh/github_actions.pub >> ~/.ssh/authorized_keys
   
   # Copy private key content to add as GitHub secret
   cat ~/.ssh/github_actions
   ```

4. **Initial deployment**:
   ```bash
   docker-compose up -d
   ```

5. **Verify deployment**:
   ```bash
   curl http://localhost:5000/health
   ```

### Auto-Update Script (Optional)

Create a cron job to automatically pull and deploy updates:

```bash
# Edit crontab
crontab -e

# Add this line (runs daily at 3 AM)
0 3 * * * cd /opt/ai-model-project && git pull && docker-compose up -d --build
```

## Troubleshooting

### Workflow fails to deploy

- Check SSH secrets are correct
- Verify SSH key has proper permissions: `chmod 600 ~/.ssh/github_actions`
- Test SSH connection manually: `ssh -i ~/.ssh/github_actions user@your-server`

### Docker build fails

- Check Docker Hub credentials
- Verify Docker is running on server
- Check disk space: `df -h`

### Model training fails

- Ensure data file exists in repository or is generated during workflow
- Check GitHub Actions logs for specific errors
- Verify Python dependencies are correct

## Next Steps

1. ✅ Push code to GitHub
2. ✅ Configure secrets
3. ✅ Set up self-hosted server
4. ✅ Test the workflow
5. ✅ Monitor training and deployment

Your AI model will now train automatically and deploy without your intervention!


