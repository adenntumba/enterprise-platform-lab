# ADR-0002 — Kubernetes Platform Architecture

## Status

Accepted

## Date

2026-10-01

## Decision Type

Architecture

## Context

The Enterprise Platform Lab requires an upstream Kubernetes platform that is reproducible, automated, documented, and capable of evolving toward production-like architecture.

The cluster will run as virtual machines on Proxmox VE.

## Decisions

### Kubernetes Distribution

Use upstream Kubernetes.

### Virtualization

Run Kubernetes nodes as VMs on Proxmox VE.

### Initial Topology

Use:

```text
1 Control Plane
2 Workers
```

Nodes:

```text
k8s-cp-01       192.168.0.130
k8s-worker-01   192.168.0.131
k8s-worker-02   192.168.0.132
```

### Infrastructure as Code

Use OpenTofu for VM lifecycle and infrastructure provisioning.

### Configuration Management

Use Ansible for operating system and Kubernetes node configuration.

### Container Runtime

Use containerd with the systemd cgroup driver.

### Bootstrap

Use kubeadm.

### CNI

Use Cilium.

The initial implementation will keep kube-proxy enabled. Kube-proxy replacement is a future evaluation.

### Pod Network

Use:

```text
10.244.0.0/16
```

### Service Network

Use:

```text
10.96.0.0/16
```

### DNS

Use CoreDNS for Kubernetes DNS.

External DNS flow:

```text
CoreDNS
   |
   v
Pi-hole
   |
   v
Unbound
```

### API Endpoint

Use:

```text
k8s-api.home.arpa
```

Initially:

```text
k8s-api.home.arpa -> 192.168.0.130
```

The endpoint is intentionally stable to support future HA.

### Future HA

The planned HA architecture is:

```text
3 Control Planes
+
Stacked etcd
+
API Load Balancer
```

## Alternatives Considered

### K3s

Not selected because this lab is intended to study upstream Kubernetes components and architecture directly.

### Docker Engine

Not selected as the kubelet container runtime.

### CRI-O

Considered, but containerd was selected for the initial implementation.

### Calico

Considered as a CNI, but Cilium was selected because eBPF and Linux networking are explicit learning objectives.

### External etcd

Considered for HA, but stacked etcd reduces infrastructure complexity for the planned future HA topology.

## Consequences

### Positive

- reproducible architecture;
- clear separation of responsibilities;
- OpenTofu and Ansible automation;
- direct upstream Kubernetes experience;
- Cilium and eBPF learning path;
- future HA path.

### Trade-offs

- more components than a lightweight Kubernetes distribution;
- additional automation maintenance;
- Cilium introduces additional networking concepts;
- the initial cluster is not highly available.

## Future Evolution

The platform may evolve toward:

```text
3 Control Planes
N Workers
API Load Balancer
Cilium
CoreDNS
Observability
GitOps
Storage
Security
```

## Implementation Notes

> Added 2026-10-08 after Sprint 02. The decisions above are unchanged; this section records where the implementation differs from them. Each difference should be resolved either by changing the code or by a new ADR that supersedes the decision.

| Decision | Implemented as | Where |
|---|---|---|
| Upstream Kubernetes | Kubernetes `v1.37.1` from `pkgs.k8s.io`, packages held | `ansible/roles/kubernetes/packages` |
| containerd with systemd cgroups | Debian package `containerd` `1.7.24`, `SystemdCgroup = true` | `ansible/roles/kubernetes/containerd` |
| kubeadm bootstrap | `kubeadm init --cri-socket unix:///run/containerd/containerd.sock` (flags only, no kubeadm config file) | `ansible/roles/kubernetes/control_plane` |
| Cilium with kube-proxy | Cilium `1.20.2` via Helm `4.3.0`, kube-proxy kept | `ansible/roles/kubernetes/cni` |
| Pod network `10.244.0.0/16` | **Not applied.** No `--pod-network-cidr` is passed to kubeadm and Cilium uses its default cluster-pool IPAM | `control_plane`, `cni` |
| Service network `10.96.0.0/16` | **Differs.** kubeadm default `10.96.0.0/12`; DNS Service IP `10.96.0.10` | `control_plane` |
| API endpoint `k8s-api.home.arpa` | **Not applied.** No `--control-plane-endpoint`; the API is `https://192.168.0.130:6443` | `control_plane` |
| CoreDNS → Pi-hole → Unbound | `home.arpa` is forwarded to Pi-hole `192.168.0.111`; other domains use the node `/etc/resolv.conf` | `ansible/roles/kubernetes/dns` |

Note on HA: kubeadm only supports adding control-plane nodes when `controlPlaneEndpoint` was set at `kubeadm init`. The planned HA evolution requires either re-initializing the cluster with the endpoint or a documented migration.

Note on versions: Kubernetes v1.35 was announced as the last release to support containerd 1.x. The cluster runs and validates with containerd `1.7.24` and Kubernetes `v1.37.1`, but the combination should be reviewed.

