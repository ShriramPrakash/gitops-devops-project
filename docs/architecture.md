
---

## `docs/architecture.md`

```md
# Project Architecture

## Overview

This project demonstrates a GitOps-based application deployment platform on AWS using:

- **Terraform** for infrastructure provisioning
- **GitHub Actions** for CI/CD automation
- **Amazon ECR** for container image storage
- **Amazon EKS** for Kubernetes orchestration
- **Helm** for packaging Kubernetes resources
- **Argo CD** for GitOps-based deployment
- **AWS Load Balancer Controller** for ALB ingress provisioning

The application is a lightweight Flask service used to validate the deployment flow.

---

## High-Level Flow

1. Developer pushes code to GitHub
2. GitHub Actions CI pipeline builds Docker image
3. Image is tagged with Git commit SHA
4. Image is pushed to Amazon ECR
5. CI updates Helm `values.yaml` with the new image tag
6. Argo CD detects the Git change
7. Argo CD syncs the Helm chart to EKS
8. Kubernetes performs a rolling update
9. ALB routes external traffic to the application

---

## Architecture Components

### 1. GitHub Repository

The repository contains:

- application source code
- Terraform infrastructure code
- Helm chart
- Argo CD application manifest
- GitHub Actions workflows
- documentation

The Git repository acts as the source of truth for infrastructure and application deployment configuration.

---

### 2. GitHub Actions Workflows

#### `infra.yaml`
Responsible for:

- provisioning infrastructure using Terraform
- creating EKS, ECR, VPC, subnets, IAM and networking resources
- installing Argo CD into the cluster

#### `ci.yaml`
Responsible for:

- building the Docker image from the Flask application
- tagging the image with Git commit SHA
- pushing the image to ECR
- updating Helm values with the new image tag

#### `deploy.yaml`
Responsible for:

- applying the Argo CD application manifest
- ensuring Argo CD tracks the Helm chart path

---

### 3. Terraform Infrastructure

Terraform provisions the AWS foundation required to run the application.

Resources include:

- VPC
- public and private subnets
- internet gateway
- NAT gateway
- route tables
- IAM roles and policies
- EKS cluster
- EKS managed node group
- ECR repository

Public subnets are used for internet-facing ALB resources.  
Private subnets are used for EKS worker nodes and application workloads.

---

### 4. Amazon EKS

Amazon EKS hosts:

- Argo CD components
- AWS Load Balancer Controller
- application pods
- Kubernetes service and ingress resources

The EKS control plane is AWS-managed, while worker nodes run in private subnets.

---

### 5. Helm Chart

The Helm chart packages the Kubernetes application resources into a reusable deployment unit.

Managed resources:

- Deployment
- Service
- Ingress

The chart uses `values.yaml` for configurable parameters such as:

- image repository
- image tag
- replica count
- service port
- ingress annotations and subnet values

---

### 6. Argo CD

Argo CD watches the Git repository and syncs the desired state into the Kubernetes cluster.

It tracks the Helm chart path:

```text
helm/gitops-app
