#!/bin/bash

# EC2 Setup Script for Golden Owl DevOps Challenge
# This script prepares an Ubuntu EC2 instance to run Docker containers
# Run this script on your EC2 instance after launching it

set -e  # Exit on any error

echo "🚀 Starting EC2 instance setup for Golden Owl App..."

# Update package lists
echo "📦 Updating package lists..."
sudo apt-get update

# Install required packages
echo "📦 Installing required packages..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "🔑 Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
echo "📚 Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
echo "🐳 Installing Docker Engine..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add current user to docker group (to run docker without sudo)
echo "👤 Adding user to docker group..."
sudo usermod -aG docker $USER

# Enable Docker to start on boot
echo "🔧 Enabling Docker to start on boot..."
sudo systemctl enable docker
sudo systemctl start docker

# Verify Docker installation
echo "✅ Verifying Docker installation..."
sudo docker --version

# Pull the Docker image (optional - commented out as it will be pulled during deployment)
# echo "📥 Pre-pulling Docker image..."
# sudo docker pull YOUR_DOCKERHUB_USERNAME/golden-owl-app:latest

echo ""
echo "✅ Setup complete!"
echo ""
echo "⚠️  IMPORTANT: You need to log out and log back in for group changes to take effect"
echo "    Or run: newgrp docker"
echo ""
echo "Next steps:"
echo "1. Configure GitHub Secrets in your repository:"
echo "   - EC2_HOST: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "   - EC2_SSH_KEY: Your private key content"
echo "   - DOCKER_USERNAME: Your Docker Hub username"
echo "   - DOCKER_PASSWORD: Your Docker Hub password/token"
echo "   - AWS_ACCESS_KEY_ID: Your AWS access key"
echo "   - AWS_SECRET_ACCESS_KEY: Your AWS secret key"
echo ""
echo "2. Ensure Security Group allows:"
echo "   - Port 80 (HTTP) from 0.0.0.0/0"
echo "   - Port 22 (SSH) from your IP"
echo ""
echo "3. Push changes to master branch to trigger deployment"
echo ""
echo "Your EC2 instance is ready! 🎉"
