# Deployment Guide

This document explains the CI/CD pipeline setup for the Golden Owl DevOps challenge.

## 🏗️ Architecture Overview

```
┌─────────────┐      ┌──────────────┐      ┌─────────────┐      ┌──────────┐
│   Feature   │─────▶│  GitHub      │─────▶│  Docker     │─────▶│   AWS    │
│   Branch    │      │  Actions CI  │      │  Hub/ECR    │      │  EC2/ECS │
└─────────────┘      └──────────────┘      └─────────────┘      └──────────┘
                            │
                            ├─ Run Tests
                            ├─ Run Linter
                            ├─ Build Docker
                            └─ Push to Registry
```

## 📋 Prerequisites

Before deploying, you need to set up the following:

### 1. **Docker Hub Account**
- Create account at https://hub.docker.com
- Create a repository named `golden-owl-app`

### 2. **GitHub Secrets Configuration**

Go to your repository → Settings → Secrets and variables → Actions → New repository secret

Add the following secrets:

#### For Docker Hub:
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_PASSWORD` - Your Docker Hub password or access token

#### For AWS Deployment:
- `AWS_ACCESS_KEY_ID` - Your AWS access key
- `AWS_SECRET_ACCESS_KEY` - Your AWS secret key

#### For EC2 Deployment (if using):
- `EC2_SSH_KEY` - Your EC2 private key (PEM format)
- `EC2_HOST` - Your EC2 instance public IP or DNS

### 3. **AWS Setup** (Choose one method)

#### Option A: AWS EC2
1. Launch an EC2 instance (Ubuntu 22.04 LTS recommended)
2. Install Docker on the instance
3. Configure security group to allow:
   - Port 80 (HTTP)
   - Port 22 (SSH)
4. Create or use existing SSH key pair

#### Option B: AWS ECS
1. Create an ECS cluster
2. Create a task definition (see `ecs-task-definition.json` below)
3. Create an ECS service
4. Set up Application Load Balancer (optional but recommended)

## 🚀 CI/CD Workflows

### CI Workflow (`.github/workflows/ci.yml`)
**Triggers:** Push to `feature/**` branches, PRs to `master`

**Steps:**
1. ✅ Checkout code
2. 🔧 Setup Node.js 18
3. 📦 Install dependencies
4. 🧹 Run linter
5. 🧪 Run tests
6. 📝 Check code formatting
7. 🐳 Build Docker image
8. ✔️ Test Docker container

### CD Workflow (`.github/workflows/cd.yml`)
**Triggers:** Push to `master` branch

**Steps:**
1. 🐳 Build Docker image
2. 📤 Push to Docker Hub
3. ☁️ Deploy to AWS (EC2 or ECS)

## 🔧 Setup Instructions

### Step 1: Configure GitHub Secrets
```bash
# Add secrets via GitHub UI
Repository → Settings → Secrets and variables → Actions
```

### Step 2: Choose Deployment Method

Edit `.github/workflows/cd.yml` and uncomment either:
- **EC2 deployment** (lines 72-81)
- **ECS deployment** (lines 84-98)

### Step 3: For ECS Deployment

Create `ecs-task-definition.json`:
```json
{
  "family": "golden-owl-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "containerDefinitions": [
    {
      "name": "golden-owl-container",
      "image": "your-dockerhub-username/golden-owl-app:latest",
      "portMappings": [
        {
          "containerPort": 3000,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ]
}
```

### Step 4: Test the Pipeline

```bash
# Create a feature branch
git checkout -b feature/test-pipeline

# Make a change and commit
git add .
git commit -m "Test CI pipeline"
git push origin feature/test-pipeline

# CI workflow will run automatically!
```

### Step 5: Deploy to Production

```bash
# Merge to master
git checkout master
git merge feature/test-pipeline
git push origin master

# CD workflow will run and deploy!
```

## 🧪 Local Testing

### Test the application locally:
```bash
cd src
npm install
npm test
npm start
```

### Test with Docker:
```bash
cd src
docker build -t golden-owl-test .
docker run -p 3000:3000 golden-owl-test
curl http://localhost:3000
# Should return: {"message":"Welcome warriors to Golden Owl!"}
```

## 🔍 Monitoring & Verification

### Check GitHub Actions
- Go to Actions tab in your repository
- View workflow runs and logs

### Verify Docker Image
```bash
docker pull your-username/golden-owl-app:latest
docker run -p 3000:3000 your-username/golden-owl-app:latest
```

### Access Deployed Application
- **EC2**: http://your-ec2-ip
- **ECS**: http://your-load-balancer-dns

## 🎨 Optional Enhancements (Nice to Have)

### 1. Load Balancer
- AWS Application Load Balancer (ALB)
- Distribute traffic across multiple instances

### 2. Auto Scaling
- EC2 Auto Scaling Group
- ECS Service Auto Scaling
- Scale based on CPU/Memory/Request count

### 3. Infrastructure as Code
- Use Terraform or CloudFormation
- Version control your infrastructure

## 📊 Recommended Metrics

- Deployment frequency
- Lead time for changes
- Mean time to recovery (MTTR)
- Change failure rate

## 🆘 Troubleshooting

### CI Fails on Linter
```bash
npm run lint:fix
npm run format:write
```

### Docker Build Fails
- Check Dockerfile syntax
- Verify `src/` directory structure
- Check network/proxy settings

### Deployment Fails
- Verify AWS credentials
- Check security group rules
- Verify Docker Hub credentials

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Docker Documentation](https://docs.docker.com/)
- [AWS ECS Documentation](https://docs.aws.amazon.com/ecs/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
