# Kubernetes Platform Architecture

## 1. Objective

This document defines the technical architecture of the first upstream Kubernetes cluster in the Enterprise Platform Lab.

The platform is designed to be reproducible, automated, documented, and capable of evolving toward a production-like architecture.

## 2. Architecture Overview

The Kubernetes platform runs as virtual machines on Proxmox VE.

Status: implemented in Sprint 02.

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

Current versions:

| Component | Version | Source |
|---|---|---|
| Debian | 13 | Proxmox Cloud-Init template |
| Kubernetes (kubeadm, kubelet, kubectl) | `v1.37.1` | `pkgs.k8s.io`, minor `v1.37`, packages held |
| containerd | `1.7.24` | Debian package |
| Cilium | `1.20.2` | Helm OCI chart `oci://quay.io/cilium/charts/cilium` |
| Helm | `4.3.0` | official install script |

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
| Pods | Cilium cluster-pool IPAM default (`10.0.0.0/8`, one `/24` per node) | Kubernetes Pod network |
| Services | `10.96.0.0/12` (kubeadm default) | Kubernetes Service network |

The Pod and Service CIDRs are not set explicitly: `kubeadm init` receives no `--pod-network-cidr` or `--service-cidr`, and the Cilium Helm release does not override its IPAM settings. The originally planned values were `10.244.0.0/16` (Pods) and `10.96.0.0/16` (Services); see the Implementation Notes in ADR-0002.

The Pod and Service CIDRs must not overlap with the LAN or other networks used by the lab.

## 6. DNS Model

Kubernetes DNS is provided by CoreDNS.

CoreDNS resolves names as follows:

```text
Pod
 |
 v
CoreDNS 10.96.0.10
 |
 +-- cluster.local      -> Kubernetes Services and Pods
 |
 +-- home.arpa          -> Pi-hole 192.168.0.111 -> local DNS records
 |
 +-- any other domain   -> /etc/resolv.conf of the node
```

The node `/etc/resolv.conf` is provided by DHCP. When it points to Pi-hole, external queries continue to Unbound (`192.168.0.110:5335`) and then to the Internet.

The infrastructure DNS namespace is `home.arpa`.

The Kubernetes service namespace remains `cluster.local`.

## 7. API Endpoint

The current Kubernetes API endpoint is:

```text
https://192.168.0.130:6443
```

The cluster was initialized without `--control-plane-endpoint`, so the generated kubeconfig files use the control-plane IP address.

Planned (not implemented): a stable logical name

```text
k8s-api.home.arpa -> 192.168.0.130
```

that can later point to a load balancer when the cluster evolves to high availability. kubeadm requires `controlPlaneEndpoint` to be set at `kubeadm init` time to add more control-plane nodes later.

## 8. Automation Model

The implemented flow is:

```text
OpenTofu (kubernetes/opentofu)
  |
  +--> Create VMs
          |
          v
       Ansible (playbooks/kubernetes.yml)
          |
          +--> base/linux               Linux baseline
          +--> kubernetes/common        Kubernetes node prerequisites
          +--> kubernetes/containerd    Container runtime
          +--> kubernetes/packages      kubeadm, kubelet, kubectl
          +--> kubernetes/control_plane kubeadm init
          +--> kubernetes/worker        kubeadm join
          +--> kubernetes/cni           Helm + Cilium
          +--> kubernetes/dns           CoreDNS configuration
          |
          v
       Ansible (playbooks/kubernetes-validation.yml)
          |
          +--> kubernetes/validation    End-to-end checks
```

Manual configuration should not become a permanent part of the platform.

Current manual steps: the Debian Cloud-Init template on Proxmox, DHCP reservations on the router and the `home.arpa` records in Pi-hole.

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
