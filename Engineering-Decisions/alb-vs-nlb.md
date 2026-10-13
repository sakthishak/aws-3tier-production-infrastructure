# Application Load Balancer vs Network Load Balancer

## Decision Context

This project uses an Application Load Balancer (ALB) to provide a public entry point for an HTTP application while keeping the application server in a private subnet.

The two load-balancing options considered were:

* **Application Load Balancer (ALB):** Designed for HTTP and HTTPS traffic.
* **Network Load Balancer (NLB):** Designed for TCP, UDP, TLS, and other network-layer use cases.

## Selected Design: Application Load Balancer

An ALB was selected because the application uses HTTP traffic and requires application-level health checks.

### Implemented Traffic Flow

```text
Internet
   |
   | HTTP : 80
   v
Application Load Balancer
   |
   | HTTP : 8080
   v
Private EC2 Application Server
```

The ALB is deployed in the public subnets. The EC2 application server runs in a private application subnet without a public IP address.

The ALB forwards requests to a target group configured for port 8080. The health check uses the `/health` endpoint.

## Why ALB Fits This Application

The ALB supports the requirements of this HTTP-based application:

* HTTP and HTTPS listeners
* Host-based and path-based routing
* Target groups
* Application-level health checks
* Integration with Amazon EC2 and container workloads

The current implementation uses an HTTP listener on port 80 and forwards traffic to the application on port 8080.

**HTTPS is not currently configured.**

## Why NLB Was Not Selected

An NLB would be appropriate if the workload required capabilities such as TCP or UDP load balancing, static IP addresses, or network-layer performance characteristics.

Those requirements are not part of the current application implementation. An NLB would add complexity without addressing a demonstrated requirement.

ALB and NLB can also be used together when an architecture has distinct application-layer and network-layer traffic requirements. That is unnecessary for this project.

## Security Group Design

The implemented traffic rules follow this model:

```text
Internet
   |
   | HTTP : 80
   v
ALB Security Group
   |
   | Application : 8080
   v
Application Security Group
```

The application security group allows application traffic from the ALB security group rather than permitting direct public access to the application port.

A database security group is also defined for the database tier. However, an actual database instance and application-to-database connection have not been implemented.

## Validation

The implementation was validated by:

* Accessing the application through the ALB.
* Receiving a successful HTTP response from the application.
* Checking the application's `/health` endpoint.
* Confirming that the ALB target health was healthy.

These checks validate the implemented HTTP traffic path. They do not establish production-level high availability or database functionality.

## Current Project Scope

| Component                      | Status          |
| ------------------------------ | --------------- |
| Application Load Balancer      | Implemented     |
| HTTP listener on port 80       | Implemented     |
| Target group on port 8080      | Implemented     |
| Private EC2 application server | Implemented     |
| `/health` health check         | Implemented     |
| Network Load Balancer          | Not required    |
| HTTPS listener                 | Not configured  |
| Database instance              | Not deployed    |
| Auto Scaling Group             | Not implemented |

## Engineering Decision

Choose the simplest component that meets the workload's actual requirements.

For this project, an ALB provides the required HTTP entry point, routes requests to the private application server, and checks application health without introducing an unnecessary NLB.
