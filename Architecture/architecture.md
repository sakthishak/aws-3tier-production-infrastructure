# AWS 3-Tier Infrastructure Architecture

## Overview

This project provisions AWS infrastructure using Terraform, with segmented network tiers, controlled traffic flow, and a privately hosted application behind an Application Load Balancer (ALB).

**Region:** `us-east-1`
**Availability Zones:** `us-east-1a`, `us-east-1b`
**VPC CIDR:** `10.0.0.0/16`

## Architecture Diagram

```text
                         Internet
                            |
                            v
                Application Load Balancer
                      Public Subnets
                            |
                       HTTP : 80
                            |
                            v
                  Private Application Tier
                    EC2 | Port 8080
                            |
                            v
                   Private Database Tier
                   Subnets and Security Group
```

## Network Design

The VPC contains six subnets across two Availability Zones.

| Tier        | Subnet   | CIDR           | Availability Zone |
| ----------- | -------- | -------------- | ----------------- |
| Public      | public-a | `10.0.1.0/24`  | us-east-1a        |
| Public      | public-b | `10.0.2.0/24`  | us-east-1b        |
| Application | app-a    | `10.0.11.0/24` | us-east-1a        |
| Application | app-b    | `10.0.12.0/24` | us-east-1b        |
| Database    | db-a     | `10.0.21.0/24` | us-east-1a        |
| Database    | db-b     | `10.0.22.0/24` | us-east-1b        |

* An Internet Gateway provides internet connectivity for resources using the public route table.
* Separate route tables control routing for the public, application, and database tiers.
* An Amazon S3 Gateway VPC Endpoint provides private connectivity to S3 for supported traffic.
* The application EC2 instance runs in a private subnet without a public IP address.

## Application Traffic Flow

1. A user sends an HTTP request to the Application Load Balancer.
2. The ALB forwards the request to the application target on port `8080`.
3. The Python HTTP application processes the request.
4. The `/health` endpoint returns a health-check response for the ALB.

## Security Design

### Application Load Balancer Security Group

* Allows inbound HTTP traffic on port `80`.

### Application Security Group

* Allows inbound TCP traffic on port `8080` from the ALB security group.

### Database Security Group

* Allows inbound TCP traffic on port `5432` from the application security group.

These security-group references restrict application and database traffic to the intended source tiers.

## Terraform Implementation

Terraform configurations are separated by responsibility:

* VPC and Availability Zones
* Subnets and route tables
* Internet Gateway and S3 VPC Endpoint
* Security groups
* EC2 application instance
* Application Load Balancer, listener, target group, and target attachment
* Variables, outputs, provider configuration, and version constraints

## Verification

The application deployment was verified through:

* Successful HTTP responses from the application.
* Successful application access through the ALB.
* A healthy ALB target status.
* Successful Terraform formatting, validation, and plan checks.

Screenshots documenting these results are available in the [`screenshots/`](../screenshots/) directory.

## Implementation Scope

The public, application, and database network tiers are configured. The application tier includes one EC2 instance behind the ALB.

The database tier currently consists of subnets, routing, and a security group; a database instance has not been deployed. Auto Scaling and additional application instances are not part of the current implementation.
