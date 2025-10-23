# CI/CD Workflow Diagram

This document provides visual representations of the complete CI/CD pipeline for the Golden Owl DevOps Challenge.

## 1. Complete CI/CD Pipeline Flow

```mermaid
flowchart TB
    Start([Developer pushes code]) --> Branch{Branch?}

    Branch -->|feature/**| CI[CI Workflow Triggered]
    Branch -->|master| CD[CD Workflow Triggered]

    CI --> Checkout1[Checkout Code]
    Checkout1 --> SetupNode[Setup Node.js 18]
    SetupNode --> Install[npm ci]
    Install --> Lint[Run ESLint]
    Lint --> Test[Run Jest Tests]
    Test --> Format[Prettier Check]
    Format --> DockerBuild[Build Docker Image]
    DockerBuild --> DockerTest[Test Container]
    DockerTest --> CIResult{CI Result}

    CIResult -->|Pass ✅| PRReady[Ready for PR]
    CIResult -->|Fail ❌| FixCode[Fix Code & Retry]

    PRReady --> CreatePR[Create Pull Request]
    CreatePR --> Merge[Merge to Master]
    Merge --> CD

    CD --> BuildJob[Job 1: Build & Push]

    BuildJob --> Checkout2[Checkout Code]
    Checkout2 --> SetupDocker[Setup Docker Buildx]
    SetupDocker --> DockerLogin[Login to Docker Hub]
    DockerLogin --> Metadata[Extract Metadata]
    Metadata --> BuildPush[Build & Push Image]
    BuildPush --> Registry[(Docker Hub Registry)]

    Registry --> DeployJob[Job 2: Deploy to EC2]

    DeployJob --> Checkout3[Checkout Code]
    Checkout3 --> AWSCreds[Configure AWS Credentials]
    AWSCreds --> SSHDeploy[SSH to EC2 & Deploy]
    SSHDeploy --> PullImage[Pull Latest Image]
    PullImage --> StopOld[Stop Old Container]
    StopOld --> RemoveOld[Remove Old Container]
    RemoveOld --> StartNew[Start New Container]
    StartNew --> Verify[Verify Deployment]

    Verify --> HealthCheck{Health Check}
    HealthCheck -->|200 OK ✅| Live[Application Live]
    HealthCheck -->|Error ⚠️| ManualCheck[Manual Verification Needed]

    Live --> End([Deployment Complete])
    ManualCheck --> End

    style Start fill:#90EE90
    style CI fill:#87CEEB
    style CD fill:#FFB6C1
    style Live fill:#90EE90
    style End fill:#90EE90
    style CIResult fill:#FFD700
    style HealthCheck fill:#FFD700
    style Registry fill:#DDA0DD
```

## 2. CI Pipeline (Feature Branch)

```mermaid
graph LR
    A[Push to feature/**] --> B[GitHub Actions CI]
    B --> C[Checkout Code]
    C --> D[Setup Node.js 18]
    D --> E[Install Dependencies]
    E --> F[ESLint Check]
    F --> G[Jest Tests]
    G --> H[Prettier Format Check]
    H --> I[Docker Build Test]
    I --> J[Container Smoke Test]
    J --> K{All Checks Pass?}
    K -->|Yes ✅| L[CI Success - Ready for PR]
    K -->|No ❌| M[CI Failed - Fix Issues]

    style A fill:#4CAF50,color:#fff
    style L fill:#4CAF50,color:#fff
    style M fill:#f44336,color:#fff
    style K fill:#FF9800,color:#fff
```

## 3. CD Pipeline (Master Branch)

```mermaid
graph TB
    subgraph "Job 1: Build and Push"
        A[Push to master] --> B[Checkout Code]
        B --> C[Setup Docker Buildx]
        C --> D[Login to Docker Hub]
        D --> E[Extract Tags & Labels]
        E --> F[Build Docker Image]
        F --> G[Push to Docker Hub]
        G --> H[(Docker Hub<br/>golden-owl-app:latest)]
    end

    subgraph "Job 2: Deploy to EC2"
        H --> I[Configure AWS Credentials]
        I --> J[SSH to EC2 Instance]
        J --> K[Pull Latest Image]
        K --> L[Stop Old Container]
        L --> M[Remove Old Container]
        M --> N[Run New Container<br/>Port 80:3000]
        N --> O[Wait 10 seconds]
        O --> P{Health Check<br/>HTTP 200?}
        P -->|Yes ✅| Q[Deployment Success]
        P -->|No ⚠️| R[Manual Verification]
    end

    style A fill:#2196F3,color:#fff
    style H fill:#9C27B0,color:#fff
    style Q fill:#4CAF50,color:#fff
    style R fill:#FF9800,color:#fff
```

## 4. Infrastructure Architecture

```mermaid
graph TB
    subgraph Internet
        User[End Users]
    end

    subgraph GitHub
        Code[Source Code Repository]
        Actions[GitHub Actions]
        Secrets[(GitHub Secrets)]
    end

    subgraph "Docker Hub"
        Registry[(Docker Registry<br/>golden-owl-app)]
    end

    subgraph AWS["AWS Cloud (ap-southeast-1)"]
        subgraph EC2["EC2 Instance (t2.micro)"]
            SG[Security Group<br/>Port 22, 80]
            Docker[Docker Engine]
            Container[Container<br/>golden-owl-app<br/>:80→:3000]
        end
    end

    User -->|HTTP Request| SG
    SG -->|Port 80| Container
    Container -->|Response| User

    Code -->|Trigger| Actions
    Actions -->|Build & Push| Registry
    Actions -->|Deploy via SSH| Docker
    Docker -->|Pull Image| Registry
    Docker -->|Run| Container
    Secrets -.->|Credentials| Actions

    style User fill:#4CAF50,color:#fff
    style Container fill:#2196F3,color:#fff
    style Registry fill:#9C27B0,color:#fff
    style Actions fill:#FF9800,color:#fff
```

## 5. Deployment Sequence Diagram

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GA as GitHub Actions
    participant DH as Docker Hub
    participant EC2 as AWS EC2
    participant App as Application

    Dev->>GH: 1. Push to master
    GH->>GA: 2. Trigger CD Workflow

    Note over GA: Job 1: Build & Push
    GA->>GA: 3. Build Docker Image
    GA->>DH: 4. Push image:latest
    DH-->>GA: 5. Push successful

    Note over GA: Job 2: Deploy
    GA->>EC2: 6. SSH Connect
    GA->>EC2: 7. docker pull image:latest
    EC2->>DH: 8. Pull image
    DH-->>EC2: 9. Image downloaded

    GA->>EC2: 10. docker stop old container
    GA->>EC2: 11. docker rm old container
    GA->>EC2: 12. docker run new container
    EC2->>App: 13. Start application

    GA->>App: 14. Health check (curl)
    App-->>GA: 15. HTTP 200 OK

    GA-->>Dev: 16. Deployment successful ✅
```

## 6. GitHub Secrets Configuration

```mermaid
graph LR
    subgraph "GitHub Repository Settings"
        A[Secrets and Variables] --> B[Actions]
        B --> C[Repository Secrets]
    end

    C --> D[DOCKER_USERNAME]
    C --> E[DOCKER_PASSWORD]
    C --> F[AWS_ACCESS_KEY_ID]
    C --> G[AWS_SECRET_ACCESS_KEY]
    C --> H[EC2_SSH_KEY]
    C --> I[EC2_HOST]

    D --> J[Docker Hub Login]
    E --> J
    F --> K[AWS Authentication]
    G --> K
    H --> L[EC2 SSH Access]
    I --> L

    J --> M[Push Docker Image]
    K --> N[AWS API Calls]
    L --> O[Deploy to EC2]

    style C fill:#2196F3,color:#fff
    style M fill:#9C27B0,color:#fff
    style O fill:#4CAF50,color:#fff
```

## 7. Optional: Load Balancer & Auto Scaling (Future Enhancement)

```mermaid
graph TB
    Users[Internet Users] --> ALB[Application Load Balancer]

    ALB --> TG[Target Group]

    TG --> ASG[Auto Scaling Group]

    ASG --> EC2-1[EC2 Instance 1<br/>golden-owl-app]
    ASG --> EC2-2[EC2 Instance 2<br/>golden-owl-app]
    ASG --> EC2-3[EC2 Instance 3<br/>golden-owl-app]

    CloudWatch[CloudWatch Metrics] -->|CPU > 70%| ScaleOut[Scale Out<br/>Add Instance]
    CloudWatch -->|CPU < 30%| ScaleIn[Scale In<br/>Remove Instance]

    ScaleOut --> ASG
    ScaleIn --> ASG

    EC2-1 -.->|Pull| DH[(Docker Hub)]
    EC2-2 -.->|Pull| DH
    EC2-3 -.->|Pull| DH

    style Users fill:#4CAF50,color:#fff
    style ALB fill:#FF9800,color:#fff
    style ASG fill:#2196F3,color:#fff
    style DH fill:#9C27B0,color:#fff
```

## 8. Deployment States

```mermaid
stateDiagram-v2
    [*] --> Idle: No deployment
    Idle --> Building: Push to master
    Building --> Testing: Build complete
    Testing --> Pushing: Tests pass
    Pushing --> Deploying: Push to Docker Hub
    Deploying --> Verifying: Container started
    Verifying --> Live: Health check pass
    Verifying --> Failed: Health check fail
    Live --> Idle: Monitoring
    Failed --> Rollback: Automatic/Manual
    Rollback --> Live: Previous version

    Live --> Building: New deployment
```

## Key Features Visualization

### CI/CD Benefits

```mermaid
mindmap
  root((CI/CD Pipeline))
    Continuous Integration
      Automated Testing
        Jest Unit Tests
        ESLint Code Quality
        Prettier Formatting
      Early Bug Detection
      Code Quality Gates
    Continuous Deployment
      Automated Deployment
        Docker Containerization
        Zero Downtime
        Automatic Rollout
      Fast Delivery
        2-3 min deployment
        Instant feedback
      Reliable Releases
        Consistent process
        Version control
    Infrastructure
      Docker
        Portable
        Consistent environment
        Easy scaling
      AWS EC2
        Cloud hosting
        Scalable
        Cost effective
      GitHub Actions
        Free for public repos
        Integrated with GitHub
        Easy configuration
```

---

## Technology Stack Summary

| Component | Technology | Purpose |
|-----------|-----------|---------|
| **Source Control** | GitHub | Code repository & version control |
| **CI/CD Platform** | GitHub Actions | Automated workflows |
| **Containerization** | Docker | Application packaging |
| **Container Registry** | Docker Hub | Image storage & distribution |
| **Cloud Provider** | AWS | Infrastructure hosting |
| **Compute** | EC2 (t2.micro) | Application server |
| **Runtime** | Node.js 18 | JavaScript runtime |
| **Framework** | Express.js | Web application framework |
| **Testing** | Jest | Unit testing |
| **Linting** | ESLint | Code quality |
| **Formatting** | Prettier | Code style consistency |

---

## Deployment Metrics

**Target Performance:**
- **Build Time:** ~30-60 seconds
- **Push Time:** ~20-30 seconds
- **Deploy Time:** ~30-60 seconds
- **Verification:** ~10 seconds
- **Total Time:** ~2-3 minutes from commit to production

**Reliability:**
- **Success Rate:** >95% (with passing tests)
- **Rollback Time:** <2 minutes
- **Uptime Target:** 99.9%

---

## How to View These Diagrams

These Mermaid diagrams can be viewed in:
1. **GitHub** - Native rendering in README and markdown files
2. **Visual Studio Code** - With Mermaid preview extension
3. **Mermaid Live Editor** - https://mermaid.live
4. **Documentation sites** - GitBook, MkDocs, etc.

Simply copy the mermaid code blocks into any of these tools for interactive viewing!
