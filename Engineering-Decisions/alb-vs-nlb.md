# Application Load Balancer vs Network Load Balancer

## Decision Context

The project requires a load balancer for a production-style 3-tier web application.

The expected application traffic is HTTP/HTTPS, with users accessing the application through a public entry point before traffic reaches private application resources.

The main AWS load-balancer options considered were:

* Application Load Balancer (ALB)
* Network Load Balancer (NLB)

---

## Selected Design

The target architecture uses an:

```text
Application Load Balancer (ALB)
```

The intended traffic flow is:

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
```

The ALB is intended to be placed in the public subnets, while application resources remain in the private application subnets.

---

## Why ALB Fits This Application

The project represents a conventional HTTP/HTTPS application.

An ALB operates at the application layer and provides features designed for HTTP/HTTPS workloads.

These include:

* HTTP/HTTPS listeners
* Host-based routing
* Path-based routing
* Target groups
* Application-level health checks
* Integration with services such as Amazon EC2 and containers

For this project, the application traffic is HTTP-based, so these capabilities align with the workload.

---

## Why NLB Was Not Selected as the Primary Load Balancer

A Network Load Balancer operates at the network/transport layer and is designed for high-performance TCP, UDP, and TLS traffic.

NLB is useful when the application requires characteristics such as:

* TCP or UDP load balancing
* Very high connection rates
* Low network-level latency
* Static IP addresses
* Protocols that are not HTTP/HTTPS

Those requirements are not part of the current application design.

Therefore, introducing an NLB would add another component without solving a requirement in the current architecture.

---

## ALB and NLB Can Be Used Together

ALB and NLB are not mutually exclusive.

A production architecture can use both when there is a specific requirement for both application-layer and network-layer load balancing.

For example, different workloads may require different traffic handling:

```text
HTTP/HTTPS Workload
        |
        v
       ALB
        |
        v
Application Services
```

and:

```text
TCP/UDP Workload
        |
        v
       NLB
        |
        v
Network Services
```

However, using both simply because both are available would increase architectural complexity and cost.

The design should be driven by application and networking requirements.

---

## Port Design

The selected application traffic model is:

```text
Internet
   |
   | TCP 80
   v
ALB
   |
   | TCP 8080
   v
Application
   |
   | TCP 5432
   v
PostgreSQL Database
```

Port 80 is used for the public HTTP listener.

Port 8080 represents the internal application listener.

Port 5432 is the standard PostgreSQL port.

The port numbers are part of the communication contract between the components. They are not properties of the subnets themselves.

---

## Security Group Relationship

The load-balancer decision also affects the security model.

The intended security-group relationship is:

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

This means the application tier does not need to accept direct HTTP traffic from the Internet.

Only traffic originating from the ALB security group is permitted on the application port.

---

## Design Principle

The decision follows a simple engineering principle:

> Choose the simplest AWS component that satisfies the actual workload requirements.

For this project:

```text
HTTP/HTTPS web application
        +
Application-layer routing
        +
Application health checks
        |
        v
       ALB
```

An NLB remains a valid AWS option for workloads requiring network-layer load balancing, but it is not required for the current application design.

---

## Current Project Status

The ALB security group has already been created as part of the security foundation.

The Application Load Balancer itself has not yet been provisioned.

When the load balancer is implemented, its configuration and validation results will be documented alongside this decision.
