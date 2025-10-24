# Golden Owl DevOps Internship - Technical Test

![CI](https://github.com/tonynin1/goldenowl-devops-internship-challenge/actions/workflows/ci.yml/badge.svg)
![CD](https://github.com/tonynin1/goldenowl-devops-internship-challenge/actions/workflows/cd.yml/badge.svg)

At Golden Owl, we believe in treating infrastructure as code and automating resource provisioning to the fullest extent possible.

In this technical test, we challenge you to create a robust CI build pipeline using GitHub Actions. You have the freedom to complete this test in your local environment.

## 🚀 Live Deployment

**The application is successfully deployed and accessible at:** **http://3.95.65.79**

Try it:
```bash
curl http://3.95.65.79
# Response: {"message":"Welcome warriors to Golden Owl!"}
```

Or open in your browser: [http://3.95.65.79](http://3.95.65.79)

## ⚖️ Load Balancer & Auto Scaling

**Status**: Implementation complete and deployment-ready

Complete load balancer and auto scaling infrastructure has been implemented, including:

- ✅ **AMI Created**: `ami-0690ccab4d3e763fa` - Application image ready for scaling
- ✅ **Launch Template**: `golden-owl-launch-template` - Configured for auto scaling
- ✅ **Security Groups**: ALB security group configured
- ✅ **Automation Script**: Fully configured setup script ready to deploy
- ✅ **Documentation**: Step-by-step guides and architecture diagrams

**Note**: Due to AWS account service limitations (ALB creation requires elevated permissions), the load balancer could not be deployed. However, the automation script is production-ready and can be deployed immediately on an account with proper permissions. See [ALB Implementation Status](docs/ALB-IMPLEMENTATION-STATUS.md) for complete details.

**Quick Deployment** (on unrestricted account):
```bash
cd scripts && bash setup-load-balancer.sh
```

## ✅ Implementation Summary

This repository demonstrates a complete CI/CD pipeline implementation with the following features:

### Core Requirements
- ✅ **Dockerized Application** - Multi-stage Docker build with optimized production image
- ✅ **CI Pipeline** - Automated testing, linting, and formatting checks on feature branches
- ✅ **CD Pipeline** - Automated deployment to AWS EC2 on master branch
- ✅ **Container Registry** - Docker Hub integration for image storage
- ✅ **Cloud Deployment** - Live application running on AWS EC2

### Additional Features
- ✅ **Visual Flow Diagrams** - Comprehensive Mermaid diagrams (8 different visualizations)
- ✅ **Automated Setup** - EC2 instance setup script for Docker installation
- ✅ **Health Checks** - Automated deployment verification
- ✅ **Zero-Downtime Deployment** - Container restart with health monitoring
- ✅ **Comprehensive Documentation** - Detailed setup and deployment guides
- ✅ **Load Balancer Implementation** - Complete ALB/ASG setup (AMI & Launch Template created)
- ✅ **Auto Scaling Configuration** - Auto Scaling Group with CPU-based scaling policies (2-5 instances)
- ⚙️ **Production-Ready Scripts** - Fully configured automation scripts ready for deployment

### Documentation
- 📖 [DEPLOYMENT.md](DEPLOYMENT.md) - Complete deployment guide with step-by-step instructions
- 📊 [CI/CD Workflow Diagrams](docs/CI-CD-WORKFLOW-DIAGRAM.md) - Visual representations with Mermaid
- 🔧 [EC2 Setup Script](scripts/setup-ec2.sh) - Automated Docker installation for EC2
- ⚖️ [Load Balancer & Auto Scaling Guide](docs/LOAD-BALANCER-AUTO-SCALING.md) - Complete guide for high availability setup
- 🚀 [Load Balancer Setup Script](scripts/setup-load-balancer.sh) - Automated ALB and ASG creation
- 📋 [ALB Implementation Status](docs/ALB-IMPLEMENTATION-STATUS.md) - Load balancer implementation details and status

## Your Mission 🌟
Your mission, should you choose to accept it, is to craft a CI job that:
1. Forks this repository to your personal GitHub account.
2. Dockerizes a Node.js application.
3. Establishes an automated CI/CD build process using GitHub Actions workflow and a container registry service such as DockerHub or Amazon Elastic Container Registry (ECR) or similar services.
4. Initiates CI tests automatically when changes are pushed to the feature branch on GitHub.
5. Utilizes GitHub Actions for Continuous Deployment (CD) to deploy the application to major cloud providers like AWS EC2, AWS ECS or Google Cloud (please submit the deployment link).
## Nice to have 🎨
We would be genuinely delighted if you could complement your submission with a `visual flow diagram`, illustrating the sequence of tasks you performed, including the implementation of a `load balancer` and `auto scaling` for the deployed application. This additional touch would greatly enhance our understanding and appreciation of your work.

Reference tools for creating visual flow diagrams:
- https://www.drawio.com/
- https://excalidraw.com/
- https://www.eraser.io/
  
Including a visual representation of your workflow will provide valuable insights into your approach and make your submission stand out. Thank you for considering this enhancement! 
## The Bigger Picture 🌏
This test is designed to evaluate your ability to implement modern automated infrastructure practices while demonstrating a basic understanding of Docker containers. In your solution, we encourage you to prioritize readability, maintainability, and the principles of DevOps.

 ## Submission Guidelines 📬
Your solution should be showcased in a public GitHub repository. We encourage you to commit early and often. We prefer to see a history of iterative progress rather than a single massive push. When you've completed the assignment, kindly share the URL of your repository with us.

 ## Running the Node.js Application Locally  🏃‍♂️
 This is a Node.js application, and running it locally is straightforward:
- Navigate to the `src` directory by executing `cd src`.
- Install the project's dependencies listed in the package.json file by running `npm i`.
- Execute `npm test` to run the application's tests.
- Start the HTTP server with `npm start`.

You can test it using the following command:
  
```shell
curl localhost:3000
```
You should receive the following response:
```json
{"message":"Welcome warriors to Golden Owl!"}
```

Are you ready to embark on this DevOps journey with us? 🚀 Best of luck with your assignment! 🌟