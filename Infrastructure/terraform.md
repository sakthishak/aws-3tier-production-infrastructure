# Terraform Infrastructure

## Overview

Terraform is used to define and provision the AWS infrastructure for this project.

The infrastructure is defined as code so that the environment can be:

* Reproduced
* Reviewed
* Version controlled
* Validated before deployment
* Updated consistently

The Terraform configuration is stored separately from the documentation:

```text
terraform/
```

---

## Terraform Version

Current Terraform version:

```text
Terraform v1.14.8
```

The project requires Terraform versions:

```text
>= 1.14.0
< 2.0.0
```

This constraint is defined in:

```text
terraform/versions.tf
```

### Why version constraints are used

Terraform version constraints help prevent the project from being executed with an unsupported major version.

The project currently allows compatible Terraform 1.x versions while preventing an automatic move to Terraform 2.x.

---

## AWS Provider

The project uses the official HashiCorp Amazon Web Services provider.

Provider source:

```text
hashicorp/aws
```

The project uses the provider constraint:

```text
~> 6.0
```

The provider is configured to deploy resources in:

```text
us-east-1
```

The configuration is separated into:

```text
versions.tf
provider.tf
variables.tf
```

This keeps version management, provider configuration, and project variables easier to understand.

---

## Terraform File Organization

The Terraform configuration is divided by infrastructure responsibility.

```text
terraform/
│
├── versions.tf
├── provider.tf
├── variables.tf
│
├── vpc.tf
├── availability-zones.tf
├── subnets.tf
├── internet_gateway.tf
│
├── public-route-table.tf
├── private-app-route-table.tf
├── private-db-route-table.tf
│
├── s3-vpc-endpoint.tf
├── security-groups.tf
│
├── ec2.tf
└── outputs.tf
```

The configuration is separated into multiple files for readability.

Terraform loads all `.tf` files in the same directory as one configuration, so the files do not need to be combined into one large file.

---

## Terraform Configuration Flow

The infrastructure follows a logical dependency chain:

```text
Terraform Configuration
        |
        v
AWS Provider
        |
        v
VPC
        |
        v
Availability Zones
        |
        v
Subnets
        |
        v
Internet Gateway
        |
        v
Route Tables
        |
        v
VPC Endpoint
        |
        v
Security Groups
```

Terraform determines the dependency order automatically from resource references.

For example, the subnet configuration references the VPC:

```text
aws_vpc.main.id
```

Therefore Terraform knows that the VPC must exist before the subnet can be created.

---

## Terraform Initialization

The project is initialized with:

```bash
terraform init
```

Initialization downloads the required provider and prepares the working directory.

The provider dependency is recorded in:

```text
.terraform.lock.hcl
```

The lock file helps maintain consistent provider versions across Terraform runs.

---

## Terraform Formatting

Terraform configuration is formatted using:

```bash
terraform fmt
```

This applies Terraform's standard formatting conventions.

Formatting is useful because it keeps the configuration consistent and easier to review.

---

## Terraform Validation

The configuration is validated using:

```bash
terraform validate
```

This checks whether the Terraform configuration is syntactically and structurally valid.

Validation does not create AWS resources.

---

## Terraform Plan

Before applying infrastructure changes, the configuration is reviewed using:

```bash
terraform plan
```

The plan shows what Terraform intends to:

* Create
* Change
* Destroy

This provides an opportunity to review infrastructure changes before they are applied.

The current configuration was validated with:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the deployed AWS resources currently match the Terraform configuration.

---

## Terraform Apply

Infrastructure changes are deployed using:

```bash
terraform apply
```

Terraform displays the proposed changes before applying them.

For the security group implementation, Terraform reported:

```text
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

The three security groups created were:

```text
aws_security_group.alb
aws_security_group.app
aws_security_group.db
```

---

## Terraform State

Terraform maintains a state file to track the relationship between the configuration and the real AWS infrastructure.

The local state files are:

```text
terraform.tfstate
terraform.tfstate.backup
```

These files are intentionally excluded from Git using:

```text
.gitignore
```

Terraform state can contain infrastructure information that should not be committed to a public repository.

---

## Terraform State Inspection

The resources currently tracked by Terraform can be viewed with:

```bash
terraform state list
```

The project currently tracks resources including:

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

aws_vpc_endpoint.s3

aws_security_group.alb
aws_security_group.app
aws_security_group.db
```

The state is used by Terraform to determine which infrastructure already exists and what changes are required during subsequent plans.

---

## Git and Terraform

The Terraform project is version controlled with Git.

The repository tracks:

```text
*.tf
.terraform.lock.hcl
.gitignore
```

The repository does not track:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
*.tfvars
```

This prevents generated Terraform data and potentially sensitive configuration values from being committed unnecessarily.

---

## Current Terraform Workflow

The current workflow is:

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
Verify AWS resources
      |
      v
terraform plan
      |
      v
Confirm no unexpected changes
```

This workflow is used throughout the project instead of making infrastructure changes manually through the AWS Console.

---

## Engineering Approach

The project uses Terraform as the source of truth for infrastructure configuration.

AWS Console access is useful for:

* Observing resources
* Checking AWS service details
* Troubleshooting
* Verifying deployment results

However, infrastructure changes should be represented in Terraform whenever possible.

This keeps the project reproducible and demonstrates Infrastructure as Code practices.
