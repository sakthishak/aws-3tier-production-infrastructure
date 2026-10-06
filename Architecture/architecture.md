# Production-Style AWS 3-Tier Infrastructure

## 1. Architecture Overview

This project implements a production-style, highly available AWS 3-tier architecture using Terraform.

The architecture is designed around:

* Multi-AZ deployment
* Public load-balancing layer
* Private application layer
* Private database layer
* Least-privilege security-group communication
* Auto Scaling and self-healing
* Infrastructure as Code
* Secure AWS service access
* Centralized monitoring and operational management
* Cost-conscious portfolio implementation

The environment is deployed in **AWS US East (N. Virginia) — `us-east-1`**.

---

## 2. High-Level Architecture

```text
                              INTERNET
                                  |
                                  |
                         AWS ALB DNS Name
                                  |
                                  v
                    +---------------------------+
                    |   Application Load        |
                    |       Balancer            |
                    |     Public Subnets        |
                    |       AZ-1 + AZ-2          |
                    +-------------+-------------+
                                  |
                     HTTP :8080 / App Traffic
                                  |
                 +----------------+----------------+
                 |                                 |
                 v                                 v
        +-------------------+             +-------------------+
        |  EC2 Application  |             |  EC2 Application  |
        |    Instance       |             |    Instance       |
        |     AZ-1          |             |      AZ-2         |
        |   Private Subnet  |             |   Private Subnet  |
        +---------+---------+             +---------+---------+
                  \                                  /
                   \                                /
                    \                              /
                     +------------+---------------+
                                  |
                           PostgreSQL :5432
                                  |
                                  v
                    +---------------------------+
                    |       Amazon RDS           |
                    |      PostgreSQL            |
                    |       Private Subnets      |
                    |        AZ-1 + AZ-2         |
                    +---------------------------+


              Supporting AWS Services
              -----------------------

        +----------------+     +-------------------+
        | IAM            |     | AWS Systems       |
        | Roles/Policies |     | Manager (SSM)     |
        +----------------+     +-------------------+

        +----------------+     +-------------------+
        | CloudWatch     |     | Secrets Manager   |
        | Monitoring     |     | DB/Application    |
        +----------------+     +-------------------+

        +----------------+
        | S3 VPC         |
        | Gateway        |
        | Endpoint       |
        +----------------+
```

---

## 3. Network Architecture

The VPC uses the CIDR:

```text
10.0.0.0/16
```

It is distributed across two Availability Zones for high availability.

### Public Subnets

```text
Public-A → 10.0.1.0/24 → us-east-1a
Public-B → 10.0.2.0/24 → us-east-1b
```

These subnets contain the internet-facing Application Load Balancer.

They have a default route:

```text
0.0.0.0/0 → Internet Gateway
```

### Private Application Subnets

```text
App-A → 10.0.11.0/24 → us-east-1a
App-B → 10.0.12.0/24 → us-east-1b
```

These contain the EC2 application instances managed by an Auto Scaling Group.

They do **not** receive public IP addresses.

### Private Database Subnets

```text
DB-A → 10.0.21.0/24 → us-east-1a
DB-B → 10.0.22.0/24 → us-east-1b
```

These are dedicated to the database tier.

The database is not directly accessible from the internet.

---

## 4. Traffic Flow

### Application Request

```text
User
  |
  v
Internet
  |
  v
Application Load Balancer
  |
  | TCP 8080
  v
Private EC2 Application Instance
  |
  | TCP 5432
  v
Private RDS PostgreSQL
```

The database never receives traffic directly from the internet.

Only the application tier is allowed to communicate with the database tier.

---

## 5. Load Balancer Design

The project uses an **Application Load Balancer (ALB)** because the application is HTTP/HTTPS based.

The ALB:

* Is internet-facing
* Runs across two public subnets
* Performs health checks
* Distributes traffic between application instances
* Provides a single entry point to the application
* Can terminate TLS/HTTPS in a real production deployment

### Production HTTPS Design

In a real production environment:

```text
User
  |
  | HTTPS :443
  v
ALB
  |
  | HTTP :8080
  v
Application
```

The ALB would use an **AWS Certificate Manager (ACM)** certificate.

HTTP traffic on port 80 would normally redirect to HTTPS on port 443.

---

## 6. Domain and Route 53 Decision

This portfolio environment does **not** require a purchased domain.

AWS provides an automatically generated DNS name for the ALB, which can be used to test the application.

Example:

```text
aws-3tier-alb-xxxxxxxx.us-east-1.elb.amazonaws.com
```

In a real production environment, the architecture would normally be:

```text
User
  |
  v
Route 53
  |
  v
ALB
  |
  v
Application
```

For HTTPS:

```text
Route 53
   |
   v
ALB :443
   |
   +--> ACM Certificate
   |
   v
Application
```

Therefore:

* Route 53 is **production knowledge/design**
* ACM is **production knowledge/design**
* HTTPS is **production design**
* A purchased domain is **not required for this portfolio deployment**

This avoids unnecessary project cost while still demonstrating knowledge of the production architecture.

---

## 7. Security Group Architecture

Security is implemented using tier-based Security Groups.

### ALB Security Group

Allows:

```text
Internet → TCP 80
Internet → TCP 443 (production HTTPS design)
```

The ALB can communicate with the application tier.

### Application Security Group

Allows:

```text
ALB Security Group → TCP 8080
```

The application servers do not accept application traffic directly from the internet.

### Database Security Group

Allows:

```text
Application Security Group → TCP 5432
```

The database is therefore isolated from both the internet and the ALB.

---

## 8. Application Tier

The application tier consists of EC2 instances running in private subnets.

The instances are managed by an **Auto Scaling Group (ASG)** across two Availability Zones.

```text
                 Auto Scaling Group
                         |
             +-----------+-----------+
             |                       |
             v                       v
        EC2 Instance            EC2 Instance
           AZ-1                     AZ-2
        Private                  Private
        Subnet                   Subnet
```

The ASG provides:

* Self-healing
* Horizontal scaling
* Multi-AZ availability
* Automatic replacement of unhealthy instances

The ALB target group performs application health checks.

Example:

```text
/health
```

---

## 9. Database Tier

The database tier uses **Amazon RDS PostgreSQL**.

The database is deployed using dedicated private database subnets across two Availability Zones.

The database:

* Has no public accessibility
* Accepts connections only from the application Security Group
* Stores application data separately from compute resources
* Uses managed database capabilities provided by AWS

For a production deployment, RDS Multi-AZ would provide database high availability.

---

## 10. Secrets Management

Database credentials should not be hardcoded in:

* Terraform source code
* GitHub
* EC2 user-data
* Application configuration committed to Git

The production design uses **AWS Secrets Manager** for sensitive credentials.

Conceptually:

```text
Secrets Manager
       |
       v
Application
       |
       v
RDS PostgreSQL
```

IAM permissions should allow only the required application components to retrieve the required secret.

---

## 11. EC2 Management

The application instances are private and should not require direct public SSH access.

The production-style management approach uses:

**AWS Systems Manager (SSM)**

This allows administrators to:

* Connect to instances
* Run commands
* Troubleshoot
* Manage instances without exposing SSH to the internet

The EC2 instances therefore do not need public IP addresses.

---

## 12. AWS Service Connectivity

The application tier already uses an **Amazon S3 Gateway VPC Endpoint**.

This allows private-subnet resources to access S3 without requiring traffic to leave through the public internet.

Current design:

```text
Private EC2
    |
    v
S3 Gateway VPC Endpoint
    |
    v
Amazon S3
```

This also demonstrates an important production networking concept:

> Private resources can access selected AWS services through VPC endpoints instead of requiring direct internet connectivity.

---

## 13. Monitoring and Operations

The production design includes:

### Amazon CloudWatch

Used for:

* EC2 metrics
* Application monitoring
* ALB metrics
* RDS metrics
* Logs
* Alarms

### Health Checks

The ALB monitors application health through:

```text
/health
```

If an application instance becomes unhealthy, the load balancer stops sending traffic to it and the Auto Scaling Group can replace it.

---

## 14. Web Application Firewall

For a real internet-facing production application, **AWS WAF** can be placed in front of the ALB.

Conceptually:

```text
Internet
   |
   v
AWS WAF
   |
   v
ALB
   |
   v
Application
```

WAF can provide protection against common web attacks and allow organizations to define application-layer rules.

WAF is treated as production architecture knowledge in this portfolio environment rather than adding unnecessary cost to the initial deployment.

---

## 15. Complete Production Traffic Architecture

```text
                         INTERNET
                            |
                            v
                    +---------------+
                    |    Route 53   |
                    | Production DNS|
                    +-------+-------+
                            |
                            v
                    +---------------+
                    |    AWS WAF    |
                    +-------+-------+
                            |
                            v
              +---------------------------+
              | Application Load Balancer |
              |       Public Subnets      |
              |       AZ-1 + AZ-2         |
              +-------------+-------------+
                            |
                    HTTP :8080
                            |
             +--------------+--------------+
             |                             |
             v                             v
      +--------------+              +--------------+
      | EC2 / ASG    |              | EC2 / ASG    |
      | Private AZ-1 |              | Private AZ-2 |
      +------+-------+              +------+-------+
             |                             |
             +--------------+--------------+
                            |
                       TCP :5432
                            |
                            v
                  +-------------------+
                  |   Amazon RDS      |
                  |    PostgreSQL     |
                  | Private Subnets  |
                  |     AZ-1 + AZ-2   |
                  +-------------------+


Supporting Services
────────────────────────────────────────

IAM
  └── EC2 / ASG permissions

Systems Manager
  └── Private EC2 administration

Secrets Manager
  └── Database/application secrets

CloudWatch
  └── Metrics, logs and alarms

S3 Gateway VPC Endpoint
  └── Private S3 access
```

---

## 16. Portfolio Implementation vs Production Design

This distinction is intentional.

| Component        | Portfolio Environment          | Production Knowledge |
| ---------------- | ------------------------------ | -------------------- |
| VPC              | Implemented                    | Production           |
| Multi-AZ subnets | Implemented                    | Production           |
| Internet Gateway | Implemented                    | Production           |
| ALB              | Implemented/planned            | Production           |
| EC2              | To be implemented              | Production           |
| Auto Scaling     | To be implemented              | Production           |
| RDS PostgreSQL   | To be implemented              | Production           |
| Security Groups  | Implemented                    | Production           |
| S3 VPC Endpoint  | Implemented                    | Production           |
| IAM              | To be implemented              | Production           |
| Systems Manager  | To be implemented              | Production           |
| Secrets Manager  | To be implemented              | Production           |
| CloudWatch       | To be implemented              | Production           |
| Route 53         | Not required                   | Production knowledge |
| ACM              | Not required without domain    | Production knowledge |
| HTTPS            | Production design              | Production           |
| WAF              | Production knowledge           | Production           |
| NAT Gateway      | Deliberately avoided initially | Production trade-off |

The project will **never claim that a service was deployed when it was only studied or designed**.

---

## 17. Engineering Principle

The goal of this project is not to deploy the maximum number of AWS services.

The goal is to demonstrate the ability to:

1. Design a production-style AWS architecture.
2. Understand why each component exists.
3. Implement the appropriate components using Terraform.
4. Make cost-conscious engineering decisions.
5. Understand production alternatives.
6. Document architecture decisions and trade-offs.
7. Troubleshoot failures systematically.
8. Explain the architecture confidently in an AWS DevOps interview.

Every significant engineering decision made during implementation will be documented in the repository.
