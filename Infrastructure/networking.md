# Networking Infrastructure

## Overview

The networking foundation of the AWS 3-tier infrastructure was built using Terraform.

The goal was to create a network that separates public, application, and database workloads while controlling how traffic moves between them.

---

## VPC

A single Amazon Virtual Private Cloud (VPC) was created:

```text
CIDR: 10.0.0.0/16
```

The VPC has:

* DNS support enabled
* DNS hostnames enabled

Terraform resource:

```text
aws_vpc.main
```

---

## Availability Zones

Two Availability Zones are used:

```text
us-east-1a
us-east-1b
```

Using two Availability Zones allows the infrastructure to distribute resources across separate Availability Zone failure domains.

Terraform obtains the available Availability Zones dynamically using:

```text
data.aws_availability_zones.available
```

---

## Subnet Design

Six subnets were created.

### Public Subnets

| Subnet   | Availability Zone | CIDR        |
| -------- | ----------------- | ----------- |
| public-a | us-east-1a        | 10.0.1.0/24 |
| public-b | us-east-1b        | 10.0.2.0/24 |

These subnets are intended for resources that require public-facing connectivity, such as the Application Load Balancer.

Public IP address assignment is enabled for these subnets.

---

### Private Application Subnets

| Subnet | Availability Zone | CIDR         |
| ------ | ----------------- | ------------ |
| app-a  | us-east-1a        | 10.0.11.0/24 |
| app-b  | us-east-1b        | 10.0.12.0/24 |

These subnets are intended for application workloads.

Automatic public IP assignment is disabled.

---

### Private Database Subnets

| Subnet | Availability Zone | CIDR         |
| ------ | ----------------- | ------------ |
| db-a   | us-east-1a        | 10.0.21.0/24 |
| db-b   | us-east-1b        | 10.0.22.0/24 |

These subnets are intended for database workloads.

Automatic public IP assignment is disabled.

---

## Internet Gateway

An Internet Gateway was created and attached to the VPC.

Terraform resource:

```text
aws_internet_gateway.main
```

The Internet Gateway provides the path between the VPC and the public Internet for resources whose subnet route table permits that traffic.

---

## Route Tables

Separate route tables were created for the public, application, and database tiers.

### Public Route Table

Terraform resource:

```text
aws_route_table.public
```

The public route table contains:

```text
0.0.0.0/0 → Internet Gateway
```

It is associated with:

```text
public-a
public-b
```

This makes the public subnets internet-routable.

---

### Application Route Table

Terraform resource:

```text
aws_route_table.app
```

It is associated with:

```text
app-a
app-b
```

The application route table does not contain a direct Internet Gateway route.

An S3 Gateway VPC Endpoint route has been added so application resources can access Amazon Simple Storage Service (S3) through the AWS network without requiring a NAT Gateway.

---

### Database Route Table

Terraform resource:

```text
aws_route_table.db
```

It is associated with:

```text
db-a
db-b
```

The database route table currently contains only the local VPC route.

This keeps the database tier isolated from direct Internet routing.

---

## S3 Gateway VPC Endpoint

An S3 Gateway VPC Endpoint was created:

```text
aws_vpc_endpoint.s3
```

Service:

```text
com.amazonaws.us-east-1.s3
```

Endpoint type:

```text
Gateway
```

The endpoint is associated with the application route table.

### Why we used an S3 Gateway Endpoint

The application tier may need access to S3, for example for:

* Application files
* Backups
* Logs
* Static assets

A Gateway VPC Endpoint provides private connectivity to S3 without requiring Internet Gateway or NAT Gateway connectivity.

It also avoids the hourly and data-processing costs associated with a NAT Gateway.

---

## NAT Gateway Decision

A NAT Gateway was intentionally not created during the initial networking implementation.

The application subnets are private, but the current project does not yet require general outbound Internet access from those subnets.

For the current implementation, S3 access can be handled through the S3 Gateway VPC Endpoint.

This avoids introducing an additional recurring AWS cost while the infrastructure is being developed.

The decision can be revisited if the application later requires outbound Internet access from private subnets.

---

## Network Traffic Model

The current network design separates routing from traffic authorization.

### Routing

Route tables determine where network traffic can go.

```text
Public Subnet
     |
     v
Public Route Table
     |
     v
Internet Gateway
```

Private application and database subnets do not receive a direct Internet Gateway route.

### Security

Security groups determine whether traffic is allowed to reach resources.

Therefore:

* Route tables control the network path.
* Security groups control allowed traffic.
* Both must allow the intended communication for traffic to succeed.

---

## Validation

Terraform validation was performed after implementing the networking resources.

The following command returned no pending changes:

```bash
terraform plan
```

Result:

```text
No changes. Your infrastructure matches the configuration.
```

The Terraform state also contains the implemented networking resources, including:

```text
aws_vpc.main
aws_internet_gateway.main

aws_subnet.public-a
aws_subnet.public-b
aws_subnet.app-a
aws_subnet.app-b
aws_subnet.db-a
aws_subnet.db-b

aws_route_table.public
aws_route_table.app
aws_route_table.db

aws_route_table_association.public_a
aws_route_table_association.public_b
aws_route_table_association.app_a
aws_route_table_association.app_b
aws_route_table_association.db_a
aws_route_table_association.db_b

aws_vpc_endpoint.s3
```

---

## Key Learning

The networking design demonstrates the difference between:

```text
VPC
 ↓
Subnets
 ↓
Route Tables
 ↓
Network Paths
```

and:

```text
Security Groups
 ↓
Allowed Traffic
 ↓
Resource Access
```

A subnet does not have a port.

Applications listen on ports, while security groups control access to those ports.

This distinction is important when troubleshooting AWS networking problems.
