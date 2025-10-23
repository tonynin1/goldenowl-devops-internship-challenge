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

### 3. **AWS EC2 Setup** (Step-by-Step Guide)

#### Step 3.1: Launch EC2 Instance

1. **Log in to AWS Console** → Navigate to EC2 Dashboard
2. **Click "Launch Instance"**
3. **Configure your instance:**
   - **Name:** `golden-owl-app-server`
   - **AMI:** Ubuntu Server 22.04 LTS (Free tier eligible)
   - **Instance type:** `t2.micro` (Free tier eligible - 1 vCPU, 1 GB RAM)
   - **Key pair:**
     - Create new key pair: `golden-owl-key`
     - Type: RSA
     - Format: `.pem`
     - ⚠️ **SAVE THE .PEM FILE SECURELY** - You'll need it for GitHub Secrets
   - **Network settings:**
     - ✅ Allow SSH traffic from: Your IP (recommended) or 0.0.0.0/0
     - ✅ Allow HTTP traffic from: 0.0.0.0/0 (internet)
   - **Storage:** 8 GiB gp3 (default is sufficient)
4. **Click "Launch Instance"**
5. **Note your Public IPv4 address** (you'll need this for GitHub Secrets)

#### Step 3.2: Configure Security Group

Verify your EC2 Security Group has these inbound rules:

| Type | Protocol | Port Range | Source               |     Description    |
|------|----------|------------|----------------------|--------------------|
| SSH  |    TCP   |     22     | Your IP or 0.0.0.0/0 | SSH access         |
| HTTP |    TCP   |     80     | 0.0.0.0/0            | Application access |

#### Step 3.3: Setup Docker on EC2

```bash
# 1. Set correct permissions on your private key
chmod 400 golden-owl-key.pem

# 2. Connect to your EC2 instance (replace YOUR_EC2_IP)
ssh -i golden-owl-key.pem ubuntu@YOUR_EC2_IP

# 3. Once connected, download and run the setup script
wget https://raw.githubusercontent.com/tonynin1/goldenowl-devops-internship-challenge/feature/ec2-deployment/scripts/setup-ec2.sh

# Or manually copy from your local machine:
# exit
# scp -i golden-owl-key.pem scripts/setup-ec2.sh ubuntu@YOUR_EC2_IP:~/
# ssh -i golden-owl-key.pem ubuntu@YOUR_EC2_IP

# 4. Make script executable and run it
chmod +x setup-ec2.sh
./setup-ec2.sh

# 5. Verify Docker installation
docker --version

# You should see: Docker version 20.x.x or higher
```

#### Step 3.4: Get Your EC2 Public IP

```bash
# While connected to EC2, run:
curl http://169.254.169.254/latest/meta-data/public-ipv4

# Or check in AWS Console → EC2 → Instances → Your instance → Public IPv4 address
```

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

## 🔧 Complete Setup Instructions

### Step 1: Configure GitHub Secrets

**Navigate to:** Your Repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets one by one:

#### Required Secrets Checklist:

- [ ] **DOCKER_USERNAME**
  - Value: Your Docker Hub username
  - Example: `johndoe`

- [ ] **DOCKER_PASSWORD**
  - Value: Your Docker Hub password or access token
  - Recommendation: Use access token (more secure)
  - Get token: Docker Hub → Account Settings → Security → New Access Token

- [ ] **AWS_ACCESS_KEY_ID**
  - Value: Your AWS access key ID
  - Get it: AWS Console → IAM → Users → Your user → Security credentials → Create access key

- [ ] **AWS_SECRET_ACCESS_KEY**
  - Value: Your AWS secret access key
  - Note: This is shown only once when creating the access key

- [ ] **EC2_SSH_KEY**
  - Value: Contents of your `.pem` file
  - How to get:
    ```bash
    cat golden-owl-key.pem
    # Copy the ENTIRE output including:
    # -----BEGIN RSA PRIVATE KEY-----
    # ...
    # -----END RSA PRIVATE KEY-----
    ```

- [ ] **EC2_HOST**
  - Value: Your EC2 public IP address
  - Example: `54.123.45.67`
  - Get it: AWS Console → EC2 → Instances → Public IPv4 address

### Step 2: EC2 Deployment is Now Active

✅ The CD workflow has been configured for EC2 deployment!

The workflow will automatically:
1. Build and push Docker image to Docker Hub
2. SSH into your EC2 instance
3. Pull the latest image
4. Stop and remove old container
5. Start new container
6. Verify deployment

<!-- ### Step 3: Optional - ECS Deployment (Alternative Method) -->

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
