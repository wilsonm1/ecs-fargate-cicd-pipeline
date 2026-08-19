# AWS ECS Fargate Deployment Pipeline

Dockerized React frontend and Express backend deployed to AWS ECS Fargate, provisioned with Terraform, and deployed through two independent CI/CD pipelines: Jenkins (main branch) and GitHub Actions (gitops branch).

## Live URLs

- **Frontend (public):** http://techchallenge1-alb-1549756790.us-east-2.elb.amazonaws.com
- **Backend (public):** http://techchallenge1-backend-alb-639916556.us-east-2.elb.amazonaws.com:8080
- **Jenkins server:** http://18.219.238.184:8080

When the frontend successfully connects to the backend, it displays a GUID returned by the backend API.

## Architecture Overview

- **Frontend:** React app, built with a multi-stage Docker build (Node 16 build stage, nginx:alpine serve stage), served on port 80.
- **Backend:** Express API, Docker container based on node:16-alpine, listening on port 8080.
- **Compute:** Both services run as AWS ECS Fargate tasks (0.5 vCPU / 1 GB memory each), in the `techchallenge1-cluster` ECS cluster.
- **Load balancing:** Two public Application Load Balancers, one for the frontend (port 80) and one for the backend (port 8080), each with its own target group and health checks.
- **Auto scaling:** Both ECS services scale between 1 and 4 tasks, triggered at 50% average CPU utilization.
- **Container registry:** Docker images for both services are stored in Amazon ECR (`techchallenge1-frontend`, `techchallenge1-backend`).
- **Networking:** Default VPC and subnets, with dedicated security groups so the ALBs are open to the internet and the ECS tasks only accept traffic from their respective ALB.
- **IAM:** ECS tasks run under a dedicated task execution role scoped to the `AmazonECSTaskExecutionRolePolicy`. CI/CD pipelines use a separate, least-privilege IAM user (`techchallenge1-jenkins-ci`) scoped only to push/pull on the two ECR repos and update the two ECS services.

All of the above (cluster, services, task definitions, ALBs, security groups, autoscaling, IAM roles) is provisioned via Terraform in the `terraform/` directory.

## CI/CD Pipelines

This repository has two independent, equivalent CI/CD pipelines, kept deliberately on separate branches to compare a self-hosted approach against a fully managed one:

### Jenkins (main branch)

A `Jenkinsfile` at the repo root defines a four-stage pipeline:

1. **Checkout** - pulls the latest code from the `main` branch.
2. **Build Images** - builds the frontend and backend Docker images.
3. **Push to ECR** - authenticates to Amazon ECR and pushes both images tagged `:latest`.
4. **Deploy to ECS** - forces a new deployment on both ECS services, which pulls the freshly pushed images.

The Jenkins server itself is intentionally provisioned outside of Terraform, keeping the CI/CD tooling decoupled from the application infrastructure it deploys - see the "Jenkins Server Infrastructure" section below for how it was set up manually.

### GitHub Actions (gitops branch)

A workflow file at `.github/workflows/deploy.yml` performs the same job using GitHub's hosted runners and official AWS GitHub Actions:

1. **Checkout** - `actions/checkout`
2. **Configure AWS credentials** - `aws-actions/configure-aws-credentials`, using repository secrets
3. **Log in to Amazon ECR** - `aws-actions/amazon-ecr-login`
4. **Build and push frontend/backend images** - Docker build and push for each service
5. **Deploy frontend/backend to ECS** - forces a new deployment on both ECS services

This workflow triggers automatically on every push to the `gitops` branch.

## Jenkins Server Infrastructure

The Jenkins server and its supporting infrastructure were provisioned manually rather than through Terraform. This section documents what was set up.

- **Compute:** A single EC2 instance (Ubuntu, t3.small) named `techchallenge1-jenkins`, running in `us-east-2`.
- **Jenkins itself:** Runs as a Docker container (`jenkins/jenkins:lts`) on the EC2 host, with its configuration and job data persisted in a named Docker volume (`jenkins_home`) so it survives container restarts.
- **Docker access:** The Jenkins container has the Docker CLI installed and the host's Docker socket (`/var/run/docker.sock`) mounted into it, so pipeline stages can build and push images using the host's Docker engine. The `jenkins` user inside the container was added to a `docker` group whose GID matches the host's socket ownership, so it can use the socket without running as root.
- **AWS CLI:** AWS CLI v2 is installed directly inside the Jenkins container so pipeline stages can authenticate to ECR and call the ECS API.
- **Security group:** Allows inbound SSH (port 22) and the Jenkins web UI (port 8080) from the internet, so the server is publicly reachable for both administration and pipeline access.
- **Credentials:** AWS credentials used by the pipeline (a dedicated, least-privilege IAM user scoped to ECR push/pull and ECS service updates) and a GitHub Personal Access Token (for cloning this private repository) are stored in Jenkins' built-in encrypted credential store, referenced by ID from the Jenkinsfile - never hardcoded in the repository.

## Repository Structure

```
.
├── frontend/              React app + Dockerfile
├── backend/               Express API + Dockerfile
├── terraform/             All Terraform-provisioned AWS infrastructure
├── Jenkinsfile             Jenkins pipeline definition (main branch)
├── .github/workflows/      GitHub Actions workflow (gitops branch)
└── README.md
```

## Local Setup

### Prerequisites

- Node.js (last tested with Node 16)
- Docker Desktop
- Terraform
- AWS CLI, configured with credentials that have access to the target AWS account

### Run the apps locally (without Docker)

Backend first:

```bash
cd backend
npm ci
npm start
```

The backend responds to a GET request on `localhost:8080`.

With the backend running, start the frontend:

```bash
cd frontend
npm ci
npm start
```

The frontend is accessible at `localhost:3000`. If it successfully connects to the backend, it displays "SUCCESS" followed by a GUID.

### Run the apps locally with Docker

```bash
docker build -t techchallenge1-backend ./backend
docker build -t techchallenge1-frontend ./frontend

docker run -d -p 8080:8080 techchallenge1-backend
docker run -d -p 80:80 techchallenge1-frontend
```

### Configuration

- `frontend/src/config.js` defines `API_URL`, the URL the frontend calls to reach the backend. When pointing at the deployed backend, this must include the port (`:8080`).
- `backend/config.js` defines the `CORS_ORIGIN` the backend allows requests from.

## Deploying the Infrastructure

The ECS infrastructure is provisioned with Terraform:

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

This provisions the ECS cluster, task definitions, services, autoscaling policies, ALBs, security groups, and IAM roles for both the frontend and backend.

After infrastructure is applied, images can be pushed to ECR and services deployed either manually or by triggering one of the two CI/CD pipelines described above.

## Notes

- The frontend and backend ALBs are HTTP-only (no ACM certificate or custom domain was provisioned for this challenge), so both live URLs above use `http://`.
- Both CI/CD pipelines deploy by forcing a new ECS deployment against the `:latest` image tag in ECR, matching the existing ECS task definitions.
