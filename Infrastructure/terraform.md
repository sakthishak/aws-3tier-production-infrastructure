# Terraform Infrastructure

## Overview

Terraform defines the AWS infrastructure for this project as code. It allows infrastructure changes to be reviewed, validated, version-controlled, and reproduced.

All Terraform configuration files are stored in the `terraform/` directory.

## Tools and Configuration

| Item                    | Configuration   |
| ----------------------- | --------------- |
| Infrastructure as Code  | Terraform       |
| AWS provider            | `hashicorp/aws` |
| AWS region              | `us-east-1`     |
| Terraform version used  | 1.14.8          |
| AWS provider constraint | `~> 6.0`        |

Terraform and provider version constraints are defined in `versions.tf`. The AWS provider configuration is defined in `provider.tf`.

## Repository Structure

```text
terraform/
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
├── alb.tf
├── target-group.tf
├── listener.tf
├── target-group-attachment.tf
├── outputs.tf
├── .terraform.lock.hcl
└── .gitignore
```

Each Terraform file groups related configuration by responsibility. Terraform loads the `.tf` files in the same directory as a single configuration.

## Infrastructure Components

| Component                    | Purpose                                                               |
| ---------------------------- | --------------------------------------------------------------------- |
| `vpc.tf`                     | Defines the Virtual Private Cloud (VPC).                              |
| `availability-zones.tf`      | Retrieves available Availability Zones.                               |
| `subnets.tf`                 | Defines public, application, and database subnets.                    |
| `internet_gateway.tf`        | Defines the Internet Gateway.                                         |
| `public-route-table.tf`      | Defines public subnet routing.                                        |
| `private-app-route-table.tf` | Defines application subnet routing.                                   |
| `private-db-route-table.tf`  | Defines database subnet routing.                                      |
| `s3-vpc-endpoint.tf`         | Provides private routing to Amazon S3 through a Gateway VPC Endpoint. |
| `security-groups.tf`         | Defines security groups for the ALB, application, and database tiers. |
| `ec2.tf`                     | Defines the private application EC2 instance.                         |
| `alb.tf`                     | Defines the Application Load Balancer.                                |
| `target-group.tf`            | Defines the application target group and health check.                |
| `listener.tf`                | Defines the ALB listener.                                             |
| `target-group-attachment.tf` | Registers the application instance with the target group.             |
| `outputs.tf`                 | Defines any Terraform outputs.                                        |
| `variables.tf`               | Defines input variables.                                              |
| `versions.tf`                | Defines Terraform and provider requirements.                          |
| `provider.tf`                | Configures the AWS provider.                                          |

## Terraform Workflow

Use the following workflow when changing the infrastructure.

### 1. Initialize

```bash
terraform init
```

Initializes the working directory and downloads the required provider plugins.

### 2. Format

```bash
terraform fmt
```

Formats Terraform files consistently.

### 3. Validate

```bash
terraform validate
```

Checks whether the configuration is syntactically and structurally valid. It does not deploy resources.

### 4. Review the plan

```bash
terraform plan
```

Shows the changes Terraform proposes to make before they are applied.

Review the plan carefully, especially when it proposes replacing or deleting resources.

### 5. Apply changes

```bash
terraform apply
```

Applies the reviewed infrastructure changes after confirmation.

### 6. Verify

Verify the resulting infrastructure using the AWS Console, AWS CLI, application endpoint, health check, or other appropriate checks.

The verification method depends on the resource being changed.

## Dependency Management

Terraform determines resource creation order from references between resources.

For example, subnet resources reference the VPC ID. Terraform can therefore determine that the VPC must exist before those subnets are created.

The configuration is split into multiple files for readability, but the files are evaluated together as one Terraform configuration.

## Provider Lock File

The file `.terraform.lock.hcl` records the selected provider versions and package checksums.

Commit this file to Git so that subsequent Terraform initialization can use the recorded provider selections consistently.

The lock file does not lock the AWS infrastructure itself.

## Terraform State and Git

Terraform state records the relationship between Terraform configuration and the infrastructure managed by Terraform.

Local state files can include:

```text
terraform.tfstate
terraform.tfstate.backup
```

These files should not be committed to a public Git repository. The Terraform `.gitignore` excludes generated files and other files that should remain local.

The repository tracks the Terraform configuration and provider lock file rather than local generated state.

## Infrastructure Design

The Terraform configuration defines:

* One VPC using CIDR `10.0.0.0/16`.
* Six subnets across two Availability Zones.
* Separate public, application, and database routing.
* An Internet Gateway and an S3 Gateway VPC Endpoint.
* Security groups for the ALB, application, and database tiers.
* A private EC2 application instance.
* An Application Load Balancer with a target group, listener, and health check.

The database tier currently consists of networking and a security group. No database instance is included in the implemented scope.

The application configuration uses HTTP port 80 at the ALB and forwards requests to the application on port 8080.

## Engineering Practices

The project follows these practices:

* Define infrastructure changes in Terraform rather than relying on manual configuration.
* Format and validate changes before applying them.
* Review Terraform plans before making changes.
* Keep the provider lock file under version control.
* Exclude state files and generated Terraform data from Git.
* Verify infrastructure behavior after changes.

These practices make the configuration easier to review, maintain, and reproduce.
