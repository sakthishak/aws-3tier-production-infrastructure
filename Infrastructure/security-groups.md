# Security Groups

## Overview

Security groups are used to control network traffic to the resources in the 3-tier architecture.

The project uses separate security groups for:

* Application Load Balancer
* Application tier
* Database tier

The security model follows a tier-to-tier access pattern:

```text id="s5x2pe"
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

---

## Security Group Design

The security groups were intentionally created separately rather than using one security group for all resources.

This provides a security boundary between each tier.

### Traffic Model

| Source      | Destination | Port | Protocol |
| ----------- | ----------- | ---: | -------- |
| Internet    | ALB         |   80 | TCP      |
| ALB         | Application | 8080 | TCP      |
| Application | Database    | 5432 | TCP      |

---

## ALB Security Group

Terraform resource:

```text id="c4m2w9"
aws_security_group.alb
```

Purpose:

Allow public HTTP traffic to reach the Application Load Balancer.

### Inbound Rule

```text id="v9t5pj"
Protocol: TCP
Port: 80
Source: 0.0.0.0/0
```

This allows HTTP traffic from the Internet to the load balancer.

The load balancer is the public entry point of the application architecture.

### Outbound Rule

The current implementation allows outbound traffic:

```text id="u0m8sc"
All protocols
Destination: 0.0.0.0/0
```

This keeps the initial lab configuration simple while the application path is being established.

---

## Application Security Group

Terraform resource:

```text id="j6q2dx"
aws_security_group.app
```

Purpose:

Allow application traffic only from the Application Load Balancer.

### Inbound Rule

```text id="fxs0jp"
Protocol: TCP
Port: 8080
Source: ALB Security Group
```

The source is the ALB security group rather than the public Internet.

This means application resources should not accept direct Internet traffic on port 8080.

The intended traffic path is:

```text id="5w8o2m"
Internet
   |
   v
ALB
   |
   v
Application
```

rather than:

```text id="fj3g1t"
Internet
   |
   X
Application
```

### Outbound Rule

The current implementation allows outbound traffic:

```text id="n7c0qk"
All protocols
Destination: 0.0.0.0/0
```

---

## Database Security Group

Terraform resource:

```text id="z7y4ax"
aws_security_group.db
```

Purpose:

Allow PostgreSQL traffic only from the application tier.

### Inbound Rule

```text id="7w2r8n"
Protocol: TCP
Port: 5432
Source: Application Security Group
```

The database does not allow PostgreSQL access directly from the Internet.

The intended traffic path is:

```text id="5z7m3c"
Application
    |
    | TCP 5432
    v
Database
```

### Outbound Rule

The current implementation allows outbound traffic:

```text id="2z9g4k"
All protocols
Destination: 0.0.0.0/0
```

---

## Why Security Groups Reference Other Security Groups

The application security group allows traffic from the ALB security group:

```text id="h4m8wv"
ALB Security Group → Application Security Group
```

The database security group allows traffic from the application security group:

```text id="y1s6qe"
Application Security Group → Database Security Group
```

This is preferable to allowing large IP ranges between tiers because the access relationship follows the application architecture.

If application instances change their private IP addresses, the security relationship does not need to be manually updated.

---

## Security Groups vs Route Tables

Security groups and route tables perform different functions.

### Route Tables

Route tables determine the network path.

For example:

```text id="f5k8ne"
0.0.0.0/0
      |
      v
Internet Gateway
```

This establishes a possible path to the Internet.

### Security Groups

Security groups determine whether traffic is allowed to reach the resource.

For example:

```text id="n0h6cs"
TCP 8080
Source: ALB Security Group
```

This controls which traffic can reach the application.

Therefore, a working network path requires both:

```text id="x9m3dy"
Routing
   +
Security Rules
   =
Allowed Communication
```

---

## Security Groups Are Stateful

AWS security groups are stateful.

When an allowed inbound connection is established, the response traffic is automatically allowed back to the originating source.

For example:

```text id="8b7t4s"
ALB
 |
 | TCP 8080 request
 v
Application
 |
 | response
 v
ALB
```

A separate inbound rule for the response traffic is not required.

---

## Port Design

The project uses:

```text id="s4t2rc"
TCP 80    → HTTP traffic to ALB
TCP 8080  → Application traffic
TCP 5432  → PostgreSQL database traffic
```

These ports represent the communication contracts between the tiers.

Port numbers are not assigned to subnets.

Instead:

* Applications listen on ports.
* Security groups control access to those ports.
* Route tables determine network paths.

For example, an application may listen on port 8080, while the subnet simply provides the IP address range in which the application resource exists.

---

## Current Security Implementation

The following security groups have been created and verified:

```text id="z8h3xk"
aws_security_group.alb
aws_security_group.app
aws_security_group.db
```

Terraform reported:

```text id="g1m4pj"
Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

A subsequent Terraform plan returned:

```text id="3n8d6v"
No changes. Your infrastructure matches the configuration.
```

This confirms that the deployed security groups currently match the Terraform configuration.

---

## Current Security Model

The current model can be summarized as:

```text id="p7f4ky"
                    INTERNET
                       |
                    TCP 80
                       |
                       v
               ┌──────────────┐
               │     ALB      │
               │    SG-ALB    │
               └──────┬───────┘
                      |
                   TCP 8080
                      |
                      v
               ┌──────────────┐
               │ APPLICATION  │
               │    SG-APP    │
               └──────┬───────┘
                      |
                   TCP 5432
                      |
                      v
               ┌──────────────┐
               │   DATABASE   │
               │    SG-DB     │
               └──────────────┘
```

This creates a controlled communication path between the tiers rather than allowing unrestricted access between them.

---

## Security Considerations

The current implementation uses open outbound rules for simplicity:

```text
0.0.0.0/0
```

This is acceptable for the current learning environment but is not a strict least-privilege outbound design.

The inbound rules are more restrictive because access between tiers is explicitly limited to the required source security group and port.

Security hardening should b
