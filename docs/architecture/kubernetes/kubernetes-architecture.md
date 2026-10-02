# Kubernetes Platform Architecture

## 1. Objective

This document defines the technical architecture of the first upstream Kubernetes cluster in the Enterprise Platform Lab.

The platform is designed to be reproducible, automated, documented, and capable of evolving toward a production-like architecture.

## 2. Architecture Overview

The Kubernetes platform will run as virtual machines on Proxmox VE.

```text
OpenTofu
   |
   v
Proxmox VMs
   |
   v
Ansible
   |
   v
Linux baseline
   |
   v
containerd
   |
   v
Kubernetes
   |
   v
CNI
   |
   v
CoreDNS
   |
   v
Platform Services
```

## 3. Initial Topology

The first cluster consists of:

- one control plane;
- two worker nodes;
- local etcd on the control plane;
- containerd as the container runtime;
- kubeadm as the bootstrap tool;
- Cilium as the CNI;
- CoreDNS for Kubernetes DNS.

```text
LAN 192.168.0.0/24
|
+-- Proxmox VE 192.168.0.120
    |
    +-- k8s-cp-01      192.168.0.130
    |
    +-- k8s-worker-01  192.168.0.131
    |
    +-- k8s-worker-02  192.168.0.132
```

## 4. Infrastructure Responsibilities

| Technology | Responsibility |
|---|---|
| Proxmox VE | Virtualization |
| OpenTofu | VM lifecycle and infrastructure provisioning |
| Ansible | Operating system and node configuration |
| containerd | Container runtime |
| kubeadm | Kubernetes bootstrap |
| Kubernetes | Container orchestration |
| Cilium | Pod networking and network policy |
| CoreDNS | Kubernetes DNS |
| Pi-hole | LAN DNS and filtering |
| Unbound | Recursive DNS |

## 5. Network Model

The initial networks are:

| Network | CIDR | Purpose |
|---|---|---|
| LAN | `192.168.0.0/24` | Physical and VM network |
| Pods | `10.244.0.0/16` | Kubernetes Pod network |
| Services | `10.96.0.0/16` | Kubernetes Service network |

The selected Pod and Service CIDRs must not overlap with the LAN or other networks used by the lab.

## 6. DNS Model

Kubernetes DNS is provided by CoreDNS.

External DNS resolution follows:

```text
Pod
 |
 v
CoreDNS
 |
 v
Pi-hole
192.168.0.111
 |
 v
Unbound
192.168.0.110:5335
 |
 v
Internet
```

The infrastructure DNS namespace is `home.arpa`.

The Kubernetes service namespace remains `cluster.local`.

## 7. API Endpoint

The logical Kubernetes API endpoint is:

```text
k8s-api.home.arpa
```

Initially:

```text
k8s-api.home.arpa -> 192.168.0.130
```

The endpoint is intentionally defined as a stable logical name so it can later point to a load balancer when the cluster evolves to high availability.

## 8. Automation Model

The intended implementation flow is:

```text
OpenTofu
  |
  +--> Create VMs
          |
          v
       Ansible
          |
          +--> Linux baseline
          +--> containerd
          +--> Kubernetes packages
          |
          v
       kubeadm
          |
          +--> Control plane
          +--> CNI
          +--> Worker nodes
```

Manual configuration should not become a permanent part of the platform.

## 9. Initial Scope

The first implementation does not include:

- high availability;
- load balancing;
- ingress;
- Gateway API;
- distributed storage;
- GitOps;
- observability;
- platform applications;
- service mesh.

These capabilities will be introduced in later sprints.

## 10. Future Evolution

The architecture is expected to evolve toward:

```text
3 Control Planes
+
N Worker Nodes
+
Kubernetes API Load Balancer
+
Cilium
+
CoreDNS
+
Observability
+
GitOps
+
Storage
+
Security Platform
```
