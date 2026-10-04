# Sprint 02 — Kubernetes Platform Foundation

> **Sprint:** 02
>
> **Status:** Planned
>
> **Milestone:** Sprint 02 - Kubernetes Platform Foundation
>
> **Version:** v0.3.0
>
> **Estimated Duration:** 1 Sprint

---

# Goal

Build the first Kubernetes platform of the Enterprise Platform Lab using upstream Kubernetes.

The objective of this Sprint is to provision the virtual machines required for the Kubernetes cluster using Infrastructure as Code and prepare the operating systems using Ansible.

The Kubernetes cluster must be built using upstream Kubernetes components and should serve as the foundation for the platform services that will be deployed in future Sprints.

The cluster must be reproducible.

No manual configuration should be required after the initial Proxmox installation.

---

# Architecture

                              Internet
                                  │
                                  ▼
                            ISP Router
                                  │
                                  ▼
                         Edge DNS Platform
                         Pi-hole + Unbound
                                  │
                                  ▼
                           Proxmox VE
                         192.168.0.120
                                  │
              ┌───────────────────┼───────────────────┐
              │                   │                   │
              ▼                   ▼                   ▼
         k8s-cp-01          k8s-worker-01       k8s-worker-02
         Control Plane         Worker               Worker
        192.168.0.130        192.168.0.131        192.168.0.132
              │                   │                   │
              └───────────────────┼───────────────────┘
                                  │
                                  ▼
                       Upstream Kubernetes
                                  │
                ┌─────────────────┼─────────────────┐
                │                 │                 │
                ▼                 ▼                 ▼
             Control           Workloads          Networking
             Plane             / Services             │
                                                    CNI

---

# Platform Architecture

The Kubernetes platform will initially contain:

    Kubernetes Cluster
    │
    ├── Control Plane
    │   └── k8s-cp-01
    │
    ├── Worker Nodes
    │   ├── k8s-worker-01
    │   └── k8s-worker-02
    │
    ├── Container Runtime
    │   └── containerd
    │
    ├── Kubernetes Bootstrap
    │   └── kubeadm
    │
    └── Networking
        └── CNI

The initial cluster will intentionally use a single control-plane node.

High availability will be addressed in a future Sprint after the base platform is validated.

---

# Infrastructure

## Proxmox

Proxmox VE is the virtualization platform for the Kubernetes cluster.

The Kubernetes nodes will run as virtual machines.

    Proxmox VE
    │
    ├── k8s-cp-01
    │   ├── 4 vCPU
    │   └── 6 GB RAM
    │
    ├── k8s-worker-01
    │   ├── 2 vCPU
    │   └── 4 GB RAM
    │
    └── k8s-worker-02
        ├── 2 vCPU
        └── 4 GB RAM

The initial sizing must be validated against the available physical resources before deployment.

The configuration must remain flexible enough to be adjusted through Infrastructure as Code.

---

# Network

Initial proposed addresses:

| Host | Address | Role |
|---|---|---|
| Proxmox | `192.168.0.120` | Virtualization |
| k8s-cp-01 | `192.168.0.130` | Kubernetes Control Plane |
| k8s-worker-01 | `192.168.0.131` | Kubernetes Worker |
| k8s-worker-02 | `192.168.0.132` | Kubernetes Worker |

The IP allocation must be documented.

DHCP reservations may be used for the Kubernetes nodes, while the actual network configuration must remain reproducible and documented.

---

# DNS

The Edge DNS Platform created in Sprint 01 will provide DNS resolution for the Kubernetes infrastructure.

The following names should be introduced:

    k8s-cp-01.home.arpa
    k8s-worker-01.home.arpa
    k8s-worker-02.home.arpa
    k8s-api.home.arpa

The Kubernetes API endpoint should use a DNS name instead of embedding an IP address throughout the configuration.

The initial implementation may point the API name to the single control-plane node.

Future high availability will introduce a virtual IP or load balancer.

---

# Operating System

The Kubernetes nodes will use a Linux distribution supported by the upstream Kubernetes ecosystem.

The selected operating system must be documented together with:

- version
- kernel
- package manager
- container runtime compatibility
- Kubernetes compatibility
- lifecycle/support considerations

The operating system configuration must be automated using Ansible.

---

# Kubernetes Architecture

The cluster will use:

    kubeadm
        │
        ▼
    Upstream Kubernetes
        │
        ├── kube-apiserver
        ├── kube-controller-manager
        ├── kube-scheduler
        ├── etcd
        │
        └── kubelet
              │
              ▼
          containerd

---

# Container Runtime

The cluster will use:

    containerd

The runtime must be configured consistently across all Kubernetes nodes.

The configuration must be automated through Ansible.

---

# Kubernetes Bootstrap

The Kubernetes cluster will be created using:

    kubeadm

The bootstrap process must be reproducible.

The implementation should separate:

1. Node preparation
2. Container runtime installation
3. Kubernetes package installation
4. Control plane initialization
5. Worker node joining
6. CNI deployment
7. Cluster validation

---

# Infrastructure as Code

Proxmox virtual machines must be provisioned using Infrastructure as Code.

Preferred workflow:

    Git
     │
     ▼
    OpenTofu
     │
     ▼
    Proxmox
     │
     ├── k8s-cp-01
     ├── k8s-worker-01
     └── k8s-worker-02
     │
     ▼
    Ansible
     │
     ▼
    Kubernetes

The infrastructure configuration must not depend on manually creating the Kubernetes VMs.

---

# Ansible Architecture

The existing Ansible project from Sprint 01 must be extended rather than replaced.

The Kubernetes automation should introduce dedicated roles.

Expected structure:

    ansible/
    ├── inventories/
    │   └── lab/
    │       ├── hosts.ini
    │       └── group_vars/
    │
    ├── playbooks/
    │   ├── bootstrap.yml
    │   ├── pihole.yml
    │   ├── unbound.yml
    │   └── kubernetes.yml
    │
    └── roles/
        ├── base/
        │   └── linux/
        │
        ├── pihole/
        │
        ├── unbound/
        │
        └── kubernetes/
            ├── common/
            ├── containerd/
            ├── control_plane/
            └── worker/

The existing `base/linux` role should remain reusable.

---

# Kubernetes Node Baseline

Every Kubernetes node must receive a common baseline.

The baseline should include:

- hostname
- package configuration
- required packages
- time synchronization
- required kernel modules
- required sysctl configuration
- swap configuration
- container runtime prerequisites
- Kubernetes repository configuration
- Kubernetes packages

The configuration must be idempotent.

---

# Control Plane

The control-plane node must be provisioned automatically.

Expected workflow:

    Prepare node
         │
         ▼
    Install containerd
         │
         ▼
    Install kubeadm
         │
         ▼
    Install kubelet
         │
         ▼
    Initialize control plane
         │
         ▼
    Configure kubectl
         │
         ▼
    Install CNI
         │
         ▼
    Validate cluster

---

# Worker Nodes

Worker nodes must join the cluster automatically.

Expected workflow:

    Prepare node
         │
         ▼
    Install containerd
         │
         ▼
    Install kubeadm
         │
         ▼
    Install kubelet
         │
         ▼
    Join cluster
         │
         ▼
    Validate node

The worker join process must not depend on manually copying commands between machines.

The bootstrap mechanism must be documented.

---

# CNI

The cluster requires a Container Network Interface.

The CNI must be selected based on documented technical criteria.

The decision must consider:

- Kubernetes compatibility
- operational complexity
- observability
- networking capabilities
- resource consumption
- learning value
- future production relevance

The selected CNI must be documented in an ADR.

---

# Cluster Validation

The following commands must be validated:

    kubectl get nodes
    kubectl get pods -A
    kubectl cluster-info

Expected initial state:

    k8s-cp-01       Ready
    k8s-worker-01   Ready
    k8s-worker-02   Ready

System components must be running.

The CNI must be operational.

Pods must be able to communicate across nodes.

DNS resolution from inside the cluster must work.

---

# Issues

---

## Issue

### Title

Define Kubernetes Platform Architecture

### Goal

Define the technical architecture for the first upstream Kubernetes cluster.

### Labels

- kubernetes
- architecture
- documentation

### Acceptance Criteria

- Kubernetes architecture documented
- Control plane topology documented
- Worker topology documented
- Node responsibilities documented
- Network architecture documented
- DNS architecture documented
- Resource sizing documented
- Container runtime decision documented
- Bootstrap strategy documented
- CNI decision documented
- Future HA strategy documented
- Architecture diagram created
- ADR created for relevant architectural decisions

---

## Issue

### Title

Provision Kubernetes Virtual Machines with OpenTofu

### Goal

Provision the Kubernetes virtual machines on Proxmox using Infrastructure as Code.

### Labels

- kubernetes
- terraform
- proxmox
- automation

### Acceptance Criteria

- OpenTofu configuration created
- Proxmox provider configured
- Control plane VM defined
- Worker VM definitions created
- CPU configuration defined
- Memory configuration defined
- Disk configuration defined
- Network configuration defined
- VM naming convention defined
- VM lifecycle managed by OpenTofu
- `tofu fmt` validated
- `tofu validate` validated
- `tofu plan` validated
- Documentation completed

---

## Issue

### Title

Create Kubernetes Ansible Structure

### Goal

Extend the existing Ansible repository with the structure required to manage Kubernetes nodes.

### Labels

- kubernetes
- ansible
- automation

### Acceptance Criteria

- Kubernetes inventory created
- Kubernetes playbook created
- Common Kubernetes role created
- containerd role created
- control-plane role created
- worker role created
- Existing `base/linux` role reused
- Variables documented
- Repository structure documented

---

## Issue

### Title

Prepare Kubernetes Node Baseline

### Goal

Configure the Linux operating system required by Kubernetes.

### Labels

- kubernetes
- linux
- ansible
- automation

### Acceptance Criteria

- Hostnames configured
- Required packages installed
- Time synchronization configured
- Required kernel modules configured
- Required sysctl parameters configured
- Swap disabled
- Kubernetes prerequisites configured
- Configuration applied to all Kubernetes nodes
- Idempotency validated
- Documentation completed

---

## Issue

### Title

Install and Configure containerd

### Goal

Install and configure containerd as the Kubernetes container runtime.

### Labels

- kubernetes
- containerd
- ansible

### Acceptance Criteria

- containerd installed on all nodes
- containerd service enabled
- containerd service running
- Configuration automated
- Kubernetes-compatible configuration validated
- CRI functionality validated
- Idempotency validated
- Documentation completed

---

## Issue

### Title

Install Kubernetes Components

### Goal

Install the Kubernetes node components required by kubeadm.

### Labels

- kubernetes
- ansible
- automation

### Acceptance Criteria

- Kubernetes package repository configured
- kubeadm installed
- kubelet installed
- kubectl installed where required
- Versions pinned/documented
- Package installation automated
- Idempotency validated
- Documentation completed

---

## Issue

### Title

Bootstrap Kubernetes Control Plane

### Goal

Initialize the first Kubernetes control-plane node using kubeadm.

### Labels

- kubernetes
- ansible
- automation

### Acceptance Criteria

- Control plane initialized
- kube-apiserver operational
- scheduler operational
- controller-manager operational
- etcd operational
- kubelet operational
- kubectl configured
- Cluster API reachable
- Bootstrap automated
- Bootstrap process documented

---

## Issue

### Title

Deploy Kubernetes CNI

### Goal

Deploy the selected Container Network Interface.

### Labels

- kubernetes
- networking
- ansible

### Acceptance Criteria

- CNI selected through documented ADR
- CNI deployed
- CNI pods operational
- Node networking operational
- Pod-to-pod communication validated
- Configuration documented

---

## Issue

### Title

Join Kubernetes Worker Nodes

### Goal

Automatically join worker nodes to the Kubernetes cluster.

### Labels

- kubernetes
- ansible
- automation

### Acceptance Criteria

- Worker nodes join automatically
- No manual join command required
- kubelet operational
- Nodes report Ready
- Worker labels documented
- Join process automated
- Join process documented

---

## Issue

### Title

Configure Kubernetes Internal DNS

### Goal

Validate integration between Kubernetes DNS and the Edge DNS Platform.

### Labels

- kubernetes
- dns
- networking

### Acceptance Criteria

- CoreDNS operational
- Pods resolve internal Kubernetes names
- Pods resolve external domains
- Kubernetes DNS can reach the Edge DNS Platform
- DNS flow documented
- Troubleshooting procedure documented

---

## Issue

### Title

Validate Kubernetes Cluster

### Goal

Perform an end-to-end validation of the Kubernetes platform.

### Labels

- kubernetes
- networking
- documentation

### Acceptance Criteria

- All Kubernetes nodes Ready
- Control-plane components healthy
- Worker nodes healthy
- CNI healthy
- CoreDNS healthy
- Pod-to-pod connectivity validated
- Pod-to-service connectivity validated
- External DNS resolution validated
- Kubernetes API validated
- Cluster validation documented
- Troubleshooting guide created

---

## Issue

### Title

Document Kubernetes Platform

### Goal

Create the technical documentation for the Kubernetes platform.

### Labels

- kubernetes
- documentation

### Acceptance Criteria

- Kubernetes architecture documented
- Infrastructure architecture documented
- Network architecture documented
- Node inventory documented
- Bootstrap process documented
- Ansible automation documented
- OpenTofu automation documented
- CNI documented
- DNS flow documented
- Validation procedures documented
- Troubleshooting guide created
- Runbook created

---

# Deliverables

- Kubernetes Architecture
- Kubernetes ADRs
- Proxmox Kubernetes VMs
- OpenTofu configuration
- Kubernetes Ansible roles
- Kubernetes Node Baseline
- containerd configuration
- kubeadm configuration
- Kubernetes Control Plane
- Kubernetes Worker Nodes
- CNI
- CoreDNS
- Kubernetes Validation
- Kubernetes Runbook
- Kubernetes Troubleshooting Guide
- Architecture Diagrams
- GitHub Documentation

---

# Definition of Done

- Kubernetes architecture documented
- Proxmox VMs provisioned using OpenTofu
- Kubernetes nodes configured using Ansible
- No manual node configuration required
- containerd operational
- kubeadm operational
- Kubernetes control plane operational
- Worker nodes joined automatically
- CNI operational
- CoreDNS operational
- Cluster networking validated
- External DNS resolution validated
- Ansible playbooks are idempotent
- OpenTofu configuration validated
- Documentation completed
- Pull Requests reviewed
- Issues closed
- Sprint reviewed
- Release `v0.3.0` published

---

# Future Work

The following items are intentionally outside the scope of Sprint 02:

- Kubernetes High Availability
- Load Balancer for Kubernetes API
- ArgoCD
- Helm platform
- Prometheus
- Grafana
- Loki
- Tempo
- OpenTelemetry
- Harbor
- cert-manager
- Internal PKI integration
- Persistent Storage / CSI
- Longhorn
- TrueNAS CSI
- Ingress Controller
- Gateway API
- Network Policies
- GitOps
- Application workloads
- Immich
- PostgreSQL
- Redis
- RabbitMQ

These capabilities will be implemented in subsequent Sprints.

---

# Sprint Review

At the end of the Sprint, the platform should provide:

    Internet
       │
       ▼
    Router
       │
       ▼
    Pi-hole
       │
       ▼
    Unbound
       │
       ▼
    Proxmox
       │
       ├── k8s-cp-01
       │
       ├── k8s-worker-01
       │
       └── k8s-worker-02
               │
               ▼
       Upstream Kubernetes
               │
               ├── CoreDNS
               ├── CNI
               └── Kubernetes API

The resulting platform must be reproducible from code and documented sufficiently for another engineer to understand, provision and validate the environment.