# AWS 3-Tier Production Infrastructure

Production-style AWS infrastructure built using **Terraform**, with a focus on network design, security boundaries, Infrastructure as Code, validation, troubleshooting, and engineering decisions.

The project is being built incrementally, with documentation updated alongside each implementation step.

---

## Project Objective

Build a production-style 3-tier AWS infrastructure where:

```text
Internet
   |
   v
Application Load Balancer
   |
   v
Private Application Tier
   |
   v
Private Database Tier
```

The infrastructure is designed to demonstrate practical AWS and DevOps concepts rather than simply creating individual AWS resources.

---

## Current Architecture

The project uses:

* One Amazon Virtual Private Cloud (VPC)
* Two Availability Zones
* Public subnets
* Private application subnets
* Private database subnets
* Internet Gateway
* Separate route tables for each tier
* S3 Gateway VPC Endpoint
* Separate security groups for each tier
* Terraform for Infrastructure as Code

### Network Layout

```text
                    VPC
                10.0.0.0/16
                     |
          +----------+----------+
          |                     |
      us-east-1a            us-east-1b
          |                     |
     +----+----+            +----+----+
     |         |            |         |
   Public     App         Public      App
  10.0.1.0   10.0.11.0   10.0.2.0   10.0.12.0
     |         |            |         |
     +---------+------------+---------+
               |
          Database Tier
        10.0.21.0 / 24
        10.0.22.0 / 24
```

The detailed architecture is documented in:

**[Architecture](Architecture/architecture.md)**

---

## Current Implementation

### Networking

Implemented and verified:

* VPC — `10.0.0.0/16`
* Two Availability Zones
* 2 public subnets
* 2 private application subnets
* 2 private database subnets
* Internet Gateway
* Public route table
* Private application route table
* Private database route table
* S3 Gateway VPC Endpoint

Detailed networking documentation:

**[Networking Infrastructure](Infrastructure/networking.md)**

---

### Security

Three security groups have been implemented:

```text
Internet
   |
   | TCP 80
   v
ALB Security Group
   |
   | TCP 8080
   v
Application Security Group
   |
   | TCP 5432
   v
Database Security Group
```

Detailed security documentation:

**[Security Groups](Infrastructure/security-groups.md)**

---

### Terraform

Infrastructure is managed using Terraform.

Current environment:

```text
Terraform:       1.14.8
AWS Provider:    6.66.0
AWS Region:      us-east-1
```

Terraform configuration is organized under:

```text
terraform/
```

Detailed Terraform documentation:

**[Terraform Infrastructure](Infrastructure/terraform.md)**

---

## Engineering Decisions

This project documents the reasoning behind infrastructure choices rather than only documenting the final configuration.

### Application Load Balancer vs Network Load Balancer

The target application is an HTTP/HTTPS web application, so an Application Load Balancer is being used as the load-balancing design.

**[Read the ALB vs NLB decision](Engineering-Decisions/alb-vs-nlb.md)**

Additional engineering decisions will be documented here as the project develops.

---

## Repository Structure

```text
aws-3tier-production-infrastructure/
│
├── README.md
│
├── Architecture/
│   └── architecture.md
│
├── Infrastructure/
│   ├── terraform.md
│   ├── networking.md
│   └── security-groups.md
│
├── Engineering-Decisions/
│   └── alb-vs-nlb.md
│
├── Operations/
│
├── Troubleshooting/
│
├── screenshots/
│
├── scripts/
│
└── terraform/
    ├── versions.tf
    ├── provider.tf
    ├── variables.tf
    ├── vpc.tf
    ├── availability-zones.tf
    ├── subnets.tf
    ├── internet_gateway.tf
    ├── public-route-table.tf
    ├── private-app-route-table.tf
    ├── private-db-route-table.tf
    ├── s3-vpc-endpoint.tf
    ├── security-groups.tf
    ├── ec2.tf
    └── outputs.tf
```

---

## Terraform Workflow

Infrastructure changes follow this workflow:

```text
Edit Terraform
      |
      v
terraform fmt
      |
      v
terraform validate
      |
      v
terraform plan
      |
      v
Review changes
      |
      v
terraform apply
      |
      v
Verify infrastructure
      |
      v
terraform plan
```

Terraform state files and generated directories are excluded from Git.

---

## Validation

The current infrastructure has been validated using Terraform.

```bash
terraform validate
terraform plan
```

Current plan result:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the deployed resources currently match the Terraform configuration.

---

## Cost Awareness

The project is being developed with AWS cost awareness.

For example, a NAT Gateway was not created during the initial networking implementation because the current application requirements do not require general outbound Internet access from the private application subnets.

An S3 Gateway VPC Endpoint is used for private S3 connectivity instead.

Infrastructure decisions are therefore evaluated based on:

```text
Requirement
    +
Security
    +
Architecture
    +
Cost
    +
Operational simplicity
```

---

## Documentation Approach

This repository documents the project as it is actually built.

The documentation focuses on:

```text
Requirement
    ↓
Architecture
    ↓
Engineering Decision
    ↓
Terraform Implementation
    ↓
Deployment
    ↓
Validation
    ↓
Troubleshooting
    ↓
Lessons Learned
```

Documentation is updated as each part of the infrastructure is implemented and verified.

---

## Project Status

### Completed

* Terraform project foundation
* AWS provider configuration
* VPC
* Availability Zones
* Public subnets
* Private application subnets
* Private database subnets
* Internet Gateway
* Public route table
* Private application route table
* Private database route table
* S3 Gateway VPC Endpoint
* ALB security group
* Application security group
* Database security group
* Terraform validation and plan verification
* Project documentation structure

The repository represents the infrastructure that has actually been implemented and verified at each stage.
