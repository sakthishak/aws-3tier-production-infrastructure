# Architecture

## Project Architecture

This project is designed as a production-style AWS 3-tier application infrastructure.

The architecture separates the application into three logical tiers:

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

The design uses separate network subnets and security boundaries for each tier.

---

## AWS Region

The infrastructure is deployed in:

```text
us-east-1
```

---

## Network Architecture

The project uses one Amazon Virtual Private Cloud (VPC):

```text
VPC
CIDR: 10.0.0.0/16
```

The VPC is divided across two Availability Zones for better fault isolation.

### Availability Zones

```text
us-east-1a
us-east-1b
```

### Subnet Design

| Tier        | Availability Zone | CIDR         |
| ----------- | ----------------- | ------------ |
| Public      | us-east-1a        | 10.0.1.0/24  |
| Public      | us-east-1b        | 10.0.2.0/24  |
| Application | us-east-1a        | 10.0.11.0/24 |
| Application | us-east-1b        | 10.0.12.0/24 |
| Database    | us-east-1a        | 10.0.21.0/24 |
| Database    | us-east-1b        | 10.0.22.0/24 |

---

## Traffic Flow

The intended application traffic flow is:

```text
Internet
   |
   | HTTP : 80
   v
Application Load Balancer
   |
   | Application : 8080
   v
Private Application Tier
   |
   | PostgreSQL : 5432
   v
Private Database Tier
```

The ports represent the application communication design. Ports are not assigned to subnets; applications listen on ports, while security groups control which traffic is allowed to reach those ports.

---

## Network Connectivity

### Public Tier

The public subnets have a route to the Internet Gateway.

```text
Public Subnet
      |
      v
Public Route Table
      |
      v
Internet Gateway
      |
      v
Internet
```

The public route table contains:

```text
0.0.0.0/0 → Internet Gateway
```

### Application Tier

The application subnets are private.

They do not have a direct route to the Internet Gateway.

An Amazon Simple Storage Service (S3) Gateway VPC Endpoint has been configured for the application route table so that application resources can access S3 without requiring a NAT Gateway.

### Database Tier

The database subnets are private and currently have only the local VPC route.

They are intentionally isolated from direct Internet connectivity.

---

## Security Boundaries

Security groups provide the traffic controls between the tiers.

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

The current security rules are:

| Security Group | Allowed Traffic | Source                     |
| -------------- | --------------- | -------------------------- |
| ALB            | TCP 80          | Internet                   |
| Application    | TCP 8080        | ALB Security Group         |
| Database       | TCP 5432        | Application Security Group |

This creates a tier-to-tier security boundary instead of allowing each tier to communicate freely.

---

## Current Implementation

The following architecture components have been implemented and verified with Terraform:

* VPC
* Two Availability Zones
* Two public subnets
* Two private application subnets
* Two private database subnets
* Internet Gateway
* Public route table
* Private application route table
* Private database route table
* S3 Gateway VPC Endpoint
* Application Load Balancer security group
* Application security group
* Database security group

The load balancer, application compute resources, and database resources are represented as part of the target 3-tier architecture and will be documented here when they are implemented.

---

## Design Principles

The architecture follows these principles:

1. Separate public, application, and database network tiers.
2. Keep application and database resources in private subnets.
3. Control tier-to-tier communication using security groups.
4. Use route tables to control network paths.
5. Use multiple Availability Zones for fault isolation.
6. Avoid unnecessary billable infrastructure during the initial networking stage.
7. Keep infrastructure reproducible through Terraform.
8. Document implementation decisions and validation results as the project evolves.
