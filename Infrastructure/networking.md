# AWS Networking Infrastructure

## Overview

The project uses an Amazon Virtual Private Cloud (VPC) with separate public, application, and database subnets. Terraform defines the network resources and routing configuration.

## VPC Configuration

| Setting            | Value                      |
| ------------------ | -------------------------- |
| VPC CIDR           | `10.0.0.0/16`              |
| AWS Region         | `us-east-1`                |
| Availability Zones | `us-east-1a`, `us-east-1b` |
| DNS support        | Enabled                    |
| DNS hostnames      | Enabled                    |

## Subnet Design

Six subnets divide the network into three tiers.

| Subnet   | Availability Zone | CIDR           | Purpose                 |
| -------- | ----------------- | -------------- | ----------------------- |
| public-a | us-east-1a        | `10.0.1.0/24`  | Public-facing resources |
| public-b | us-east-1b        | `10.0.2.0/24`  | Public-facing resources |
| app-a    | us-east-1a        | `10.0.11.0/24` | Application workloads   |
| app-b    | us-east-1b        | `10.0.12.0/24` | Application workloads   |
| db-a     | us-east-1a        | `10.0.21.0/24` | Database workloads      |
| db-b     | us-east-1b        | `10.0.22.0/24` | Database workloads      |

The public subnets enable automatic public IPv4 address assignment. The application and database subnets do not.

The subnet layout provides separation between tiers and prepares the network for workloads distributed across two Availability Zones. It does not, by itself, guarantee high availability.

## Internet Gateway

An Internet Gateway is attached to the VPC.

The public route table contains this route:

```text
Destination: 0.0.0.0/0
Target:      Internet Gateway
```

Both public subnets are associated with the public route table.

An Internet Gateway route alone does not make a resource publicly accessible. Appropriate subnet configuration, public addressing where required, security-group rules, and network paths must also be in place.

## Route Tables

Separate route tables are defined for the public, application, and database tiers.

### Public Route Table

Associated subnets:

* `public-a`
* `public-b`

The default route sends internet-bound IPv4 traffic to the Internet Gateway.

### Application Route Table

Associated subnets:

* `app-a`
* `app-b`

The application route table does not contain a default route to the Internet Gateway or a NAT Gateway.

It uses an Amazon S3 Gateway VPC Endpoint route for private connectivity to S3.

**Important:** This does not provide general internet access to application instances.

### Database Route Table

Associated subnets:

* `db-a`
* `db-b`

The database route table contains the local VPC route. It does not have a default route to the Internet Gateway or a NAT Gateway.

No database instance is included in the current implementation.

## S3 Gateway VPC Endpoint

The project defines an S3 Gateway VPC Endpoint for the `us-east-1` region.

```text
Service: com.amazonaws.us-east-1.s3
Type:    Gateway
```

The endpoint is associated with the application route table.

### Why use it?

An S3 Gateway VPC Endpoint allows eligible traffic from associated subnets to reach Amazon Simple Storage Service (S3) without requiring a NAT Gateway or an internet-facing route.

Potential use cases include accessing application files, logs, backups, and static assets stored in S3.

Actual access also depends on the endpoint policy, identity permissions, bucket policy, and other applicable controls.

A Gateway Endpoint does not provide connectivity to other AWS services.

## NAT Gateway Decision

A NAT Gateway is not included in the current network configuration.

This avoids the recurring cost of NAT Gateway resources while keeping the initial infrastructure focused on the required application traffic path.

If private instances later require general outbound internet access, a NAT Gateway and suitable route-table entries can be added.

Alternatively, specific AWS services can be accessed privately through appropriate VPC endpoints where supported.

The correct choice depends on the application's connectivity requirements and cost constraints.

## Private EC2 and Systems Manager Connectivity

The application EC2 instance is designed to run in a private subnet without a public IP address.

The instance's IAM role includes the `AmazonSSMManagedInstanceCore` policy. However, IAM permissions alone do not establish network connectivity to AWS Systems Manager.

For Systems Manager Session Manager to work from a private subnet, the instance must be able to reach the required Systems Manager service endpoints. This can be achieved through suitable VPC interface endpoints or an appropriate outbound network path, such as a NAT Gateway.

The S3 Gateway Endpoint does not replace these Systems Manager connectivity requirements.

This is an important verification point when operating private EC2 instances.

## Network Traffic Model

Routing and traffic authorization perform different jobs.

### Routing

Route tables determine the network path a packet can take.

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

### Security Groups

Security groups control which inbound and outbound traffic is permitted for associated resources.

For the application traffic path:

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

The application security group restricts application traffic to the ALB security group.

Both routing and security rules must permit the intended communication for traffic to succeed.

## Validation Approach

Validate networking changes using Terraform and AWS service checks.

### Terraform checks

```bash
terraform fmt
terraform validate
terraform plan
```

* `terraform fmt` formats Terraform configuration files.
* `terraform validate` checks the configuration's syntax and structure.
* `terraform plan` previews proposed infrastructure changes.

### AWS checks

Use the AWS Console or AWS Command Line Interface (CLI) to verify:

* VPC and subnet CIDR blocks.
* Subnet Availability Zone assignments.
* Route-table associations and routes.
* Internet Gateway attachment.
* S3 Gateway Endpoint association.
* Security-group rules.
* Application Load Balancer connectivity to the private EC2 instance.

A successful Terraform validation does not prove that application traffic or private service connectivity works. Those require appropriate runtime checks.

## Key Learning

A reliable networking troubleshooting process separates three questions:

1. **Routing:** Is there a valid network path to the destination?
2. **Authorization:** Do security groups and other applicable policies permit the traffic?
3. **Service connectivity:** Is the destination service reachable and configured to respond?

A subnet does not have a port. Applications listen on ports, while security groups and other network controls determine whether traffic can reach them.
