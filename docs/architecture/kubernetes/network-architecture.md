# Kubernetes Network Architecture

## 1. Objective

Define the network architecture for the initial Kubernetes cluster.

## 2. Network Segments

| Network | Effective CIDR | Purpose |
|---|---|---|
| LAN | `192.168.0.0/24` | Physical and VM network |
| Pod Network | `10.0.0.0/8` pool, one `/24` per node (Cilium cluster-pool IPAM) | Pod addressing |
| Service Network | `10.96.0.0/12` (kubeadm default) | ClusterIP addressing |

### Target, configuration and runtime state

The architecture defined in ADR-0002, the configuration in this repository and the state of the running cluster are three different things:

```text
Architectural target (ADR-0002)
        ↓
Repository configuration (Ansible / OpenTofu)
        ↓
Effective runtime state (live cluster)
```

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

## 3. LAN Addressing

Initial infrastructure addresses:

| Component | Address |
|---|---|
| Router (TP-Link Archer C80, DHCP) | `192.168.0.1` |
| Unbound (`dns-01`) | `192.168.0.110` |
| Pi-hole (`node-01`) | `192.168.0.111` |
| Reserved Raspberry Pi (`node-02`) | `192.168.0.112` |
| Proxmox | `192.168.0.120` |
| Kubernetes Control Plane | `192.168.0.130` |
| Kubernetes Worker 01 | `192.168.0.131` |
| Kubernetes Worker 02 | `192.168.0.132` |

## 4. Pod Network

No Pod CIDR is passed to kubeadm. Cilium allocates Pod addresses with its cluster-pool IPAM: one `/24` per node from the `10.0.0.0/8` pool (chart default).

Effective allocation: `k8s-cp-01` `10.0.0.0/24`, `k8s-worker-01` `10.0.2.0/24`, `k8s-worker-02` `10.0.1.0/24`.

The ADR-0002 target `10.244.0.0/16` is not applied.

The CNI is responsible for implementing Pod connectivity.

The CIDR must not overlap with host, LAN, VPN, or other infrastructure networks.

## 5. Service Network

The Kubernetes Service CIDR is the kubeadm default:

```text
10.96.0.0/12
```

It was verified on the live cluster through `--service-cluster-ip-range=10.96.0.0/12` in `/etc/kubernetes/manifests/kube-apiserver.yaml`.

The ADR-0002 target `10.96.0.0/16` is not applied. The DNS Service IP `10.96.0.10` is inside the effective range.

This network provides virtual Service addresses.

## 6. API Server

The Kubernetes API Server uses:

```text
TCP 6443
```

The current endpoint is `https://192.168.0.130:6443`.

Planned (not implemented): the logical endpoint `k8s-api.home.arpa`.

The VMs receive their addresses through DHCP reservations based on the fixed MAC addresses defined in `kubernetes/opentofu`.

## 7. Network Security

Network access should follow least privilege.

Ports should only be opened when required by:

- Kubernetes;
- the selected CNI;
- explicitly deployed platform services.

## 8. Future Considerations

Future networking work may include:

- NetworkPolicy;
- ingress;
- Gateway API;
- load balancing;
- service-to-service security;
- observability;
- eBPF-based troubleshooting.

## 9. Verifying the Effective State

The effective values above were read from the live cluster. Re-check them after any rebuild.

Pod CIDRs allocated by Cilium:

```bash
kubectl get ciliumnodes \
  -o custom-columns=NODE:.metadata.name,PODCIDRS:.spec.ipam.podCIDRs
```

Expected:

```text
NODE            PODCIDRS
k8s-cp-01       [10.0.0.0/24]
k8s-worker-01   [10.0.2.0/24]
k8s-worker-02   [10.0.1.0/24]
```

The per-node assignment can change if the cluster is rebuilt; the `/24` size and the `10.0.0.0/8` pool stay the same while the Cilium IPAM settings are unchanged.

Service CIDR (on `k8s-cp-01`):

```bash
sudo grep "service-cluster-ip-range" /etc/kubernetes/manifests/kube-apiserver.yaml
```

Expected:

```text
--service-cluster-ip-range=10.96.0.0/12
```

Alternative from any machine with `kubectl`:

```bash
kubectl cluster-info dump | grep -m1 service-cluster-ip-range
```

DNS Service IP:

```bash
kubectl -n kube-system get service kube-dns -o jsonpath='{.spec.clusterIP}'
```

Expected:

```text
10.96.0.10
```

API endpoint:

```bash
kubectl cluster-info
```

Expected:

```text
Kubernetes control plane is running at https://192.168.0.130:6443
```
