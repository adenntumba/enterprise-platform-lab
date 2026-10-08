# Kubernetes Network Architecture

## 1. Objective

Define the network architecture for the initial Kubernetes cluster.

## 2. Network Segments

| Network | CIDR | Purpose |
|---|---|---|
| LAN | `192.168.0.0/24` | Physical and VM network |
| Pod Network | Cilium cluster-pool IPAM default (`10.0.0.0/8`, one `/24` per node) | Pod addressing |
| Service Network | `10.96.0.0/12` (kubeadm default) | ClusterIP addressing |

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

No Pod CIDR is passed to kubeadm. Cilium allocates Pod addresses with its default cluster-pool IPAM ((`10.0.0.0/8`, one `/24` per node)).

The originally planned Pod CIDR was `10.244.0.0/16`.

The CNI is responsible for implementing Pod connectivity.

The CIDR must not overlap with host, LAN, VPN, or other infrastructure networks.

## 5. Service Network

The Kubernetes Service CIDR is the kubeadm default:

```text
10.96.0.0/12
```

The originally planned value was `10.96.0.0/16`. The DNS Service IP is `10.96.0.10`.

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
