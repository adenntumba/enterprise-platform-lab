# Kubernetes Network Architecture

## 1. Objective

Define the network architecture for the initial Kubernetes cluster.

## 2. Network Segments

| Network | CIDR | Purpose |
|---|---|---|
| LAN | `192.168.0.0/24` | Physical and VM network |
| Pod Network | `10.244.0.0/16` | Pod addressing |
| Service Network | `10.96.0.0/16` | ClusterIP addressing |

## 3. LAN Addressing

Initial infrastructure addresses:

| Component | Address |
|---|---|
| Router | `192.168.0.1` |
| Unbound | `192.168.0.110` |
| Pi-hole | `192.168.0.111` |
| Proxmox | `192.168.0.120` |
| Kubernetes Control Plane | `192.168.0.130` |
| Kubernetes Worker 01 | `192.168.0.131` |
| Kubernetes Worker 02 | `192.168.0.132` |

## 4. Pod Network

The initial Pod CIDR is:

```text
10.244.0.0/16
```

The CNI is responsible for implementing Pod connectivity.

The CIDR must not overlap with host, LAN, VPN, or other infrastructure networks.

## 5. Service Network

The initial Kubernetes Service CIDR is:

```text
10.96.0.0/16
```

This network provides virtual Service addresses.

## 6. API Server

The Kubernetes API Server uses:

```text
TCP 6443
```

The logical endpoint is:

```text
k8s-api.home.arpa
```

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
