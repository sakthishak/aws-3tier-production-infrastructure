# AWS Security Groups

## Overview

The Terraform configuration defines three security groups for the three-tier architecture:

* Application Load Balancer (ALB)
* Application server
* Database tier

Security groups control inbound and outbound traffic associated with AWS resources. The configured inbound rules restrict communication between tiers.

## Inbound Rules

| Security Group | Protocol | Port | Allowed Source             | Purpose                                             |
| -------------- | -------- | ---: | -------------------------- | --------------------------------------------------- |
| ALB            | TCP      |   80 | `0.0.0.0/0`                | Accept HTTP requests                                |
| Application    | TCP      | 8080 | ALB security group         | Receive application traffic from the ALB            |
| Database       | TCP      | 5432 | Application security group | Permit PostgreSQL traffic from the application tier |

These rules are defined in `terraform/security-groups.tf`.

## 1. ALB Security Group

**Terraform resource:** `aws_security_group.alb`

### Inbound

* Protocol: TCP
* Port: 80
* Source: `0.0.0.0/0`

This permits HTTP traffic from IPv4 internet addresses to reach the ALB, subject to the remaining network configuration.

### Outbound

* Protocol: All
* Destination: `0.0.0.0/0`

The current configuration allows all outbound traffic.

**Security consideration:** HTTPS is not configured in the current implementation. For a production deployment, configure HTTPS with a valid certificate and consider restricting access according to the application's requirements.

## 2. Application Security Group

**Terraform resource:** `aws_security_group.app`

### Inbound

* Protocol: TCP
* Port: 8080
* Source: ALB security group

The application security group references the ALB security group rather than allowing direct inbound connections from the internet.

This supports the intended traffic flow:

```text
Internet
   |
   | HTTP : 80
   v
Application Load Balancer
   |
   | HTTP : 8080
   v
Private EC2 Application Instance
```

The application instance does not need a public IP address for the ALB to forward traffic to its private IP address.

### Outbound

* Protocol: All
* Destination: `0.0.0.0/0`

The current configuration allows all outbound traffic. Actual connectivity depends on the available routes, endpoints, and applicable network controls.

## 3. Database Security Group

**Terraform resource:** `aws_security_group.db`

### Inbound

* Protocol: TCP
* Port: 5432
* Source: Application security group

Port 5432 is the default PostgreSQL port.

The rule allows PostgreSQL traffic originating from resources associated with the application security group. It does not expose the database port directly to the internet.

**Current scope:** The database security group is defined in Terraform, but no database instance is deployed. This rule documents the intended future application-to-database access pattern; it does not mean that a working database connection exists.

### Outbound

* Protocol: All
* Destination: `0.0.0.0/0`

The current configuration allows all outbound traffic.

## Why Reference Other Security Groups?

The application security group references the ALB security group, and the database security group references the application security group.

This approach defines access by security-group membership rather than relying on fixed private IP addresses.

For example:

```text
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

The diagram represents the intended three-tier access model. The application-to-database path is configured as a security-group rule, but the database workload itself is not deployed.

## Security Groups and Route Tables

These AWS networking components have different responsibilities.

| Component      | Responsibility                                                           |
| -------------- | ------------------------------------------------------------------------ |
| Route table    | Determines the network path for traffic                                  |
| Security group | Controls permitted inbound and outbound traffic for associated resources |

A valid route does not override a security-group restriction. Likewise, a security-group rule does not create a network route.

Successful communication requires an appropriate network path and rules that permit the traffic.

## Security Groups Are Stateful

AWS security groups are stateful.

When traffic is permitted in one direction and a connection is established, response traffic for that connection is automatically permitted. A separate inbound rule is not needed solely to allow the response.

## Outbound Access and Least Privilege

All three security groups currently allow all outbound traffic to `0.0.0.0/0`.

This is a broad outbound rule rather than a strict least-privilege design.

For a production deployment, review outbound requirements and restrict traffic where practical. Changes should account for application dependencies, health checks, AWS service access, and operational requirements.

## Validation

Terraform configuration can be checked using:

```bash
terraform fmt
terraform validate
terraform plan
```

These commands format the configuration, validate its structure, and preview proposed infrastructure changes.

They do not independently prove that live network traffic works.

For runtime verification, check the relevant AWS security-group rules and resource associations. For the implemented application path, verify that:

* The ALB accepts HTTP traffic on port 80.
* The application security group permits TCP port 8080 from the ALB security group.
* The application is listening on port 8080.
* The ALB target health check succeeds.

The database rule can be reviewed in Terraform and AWS, but database connectivity cannot be tested until a database instance is implemented.

## Current Configuration Summary

| Component                  | Configuration                                     |
| -------------------------- | ------------------------------------------------- |
| ALB security group         | Inbound TCP 80 from `0.0.0.0/0`                   |
| Application security group | Inbound TCP 8080 from ALB security group          |
| Database security group    | Inbound TCP 5432 from application security group  |
| Outbound rules             | All outbound traffic allowed for all three groups |
| HTTPS                      | Not configured                                    |
| Database instance          | Not deployed                                      |

## Key Learning

Security groups should permit only the traffic required by each tier.

Referencing another security group provides a maintainable way to express tier-to-tier access. However, secure communication also depends on routing, resource configuration, and the availability of the destination service.
