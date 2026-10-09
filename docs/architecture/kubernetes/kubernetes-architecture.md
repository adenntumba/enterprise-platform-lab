# Kubernetes Platform Architecture

## 1. Objective

This document defines the technical architecture of the first upstream Kubernetes cluster in the Enterprise Platform Lab.

For an operational overview see [platform.md](platform.md) and the [Kubernetes platform runbook](../../runbooks/kubernetes-platform.md).

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

The architecture target (ADR-0002), the repository configuration and the effective runtime state differ. This table is the reference:

| Item | Architectural target (ADR-0002) | Repository configuration | Effective runtime state (verified 2026-10-08) |
|---|---|---|---|
| Pod CIDR | `10.244.0.0/16` | not set: no `--pod-network-cidr` / `podSubnet` in `kubeadm init` | allocated by Cilium per node (see below) |
| Cilium IPAM | not specified | chart defaults: no IPAM values passed to Helm | `cluster-pool`, one `/24` per node from `10.0.0.0/8` |
| Service CIDR | `10.96.0.0/16` | not set: no `--service-cidr` / `serviceSubnet` | `10.96.0.0/12` (kubeadm default), from `--service-cluster-ip-range` in the kube-apiserver manifest |
| DNS Service IP | `10.96.0.10` | not set (derived from the Service CIDR) | `10.96.0.10` |
| API endpoint | `k8s-api.home.arpa:6443` | not set: no `--control-plane-endpoint` / `controlPlaneEndpoint` | `https://192.168.0.130:6443` |
| DNS | CoreDNS → Pi-hole → Unbound | `kubernetes/dns` Corefile: `home.arpa` → `192.168.0.111`, other domains → `/etc/resolv.conf` | as configured; validated by `kubernetes/validation` |

Effective Pod CIDRs per node:

| Node | Pod CIDR |
|---|---|
| `k8s-cp-01` | `10.0.0.0/24` |
| `k8s-worker-01` | `10.0.2.0/24` |
| `k8s-worker-02` | `10.0.1.0/24` |

The ADR values `10.244.0.0/16`, `10.96.0.0/16` and `k8s-api.home.arpa` are **architectural targets**. They are not deployed.

`kubeadm init` receives no `--pod-network-cidr`, `--service-cidr` or `--control-plane-endpoint`, and the Cilium Helm release does not override its IPAM settings. Verification commands are in [network-architecture.md](network-architecture.md#9-verifying-the-effective-state).

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
