# Kubernetes Internal DNS

## Overview

The `kubernetes/dns` role configures CoreDNS, the Kubernetes cluster DNS, and integrates it with the Edge DNS Platform (Pi-hole and Unbound).

It runs on the `control_plane` group as the last play of `playbooks/kubernetes.yml`, after the CNI is deployed.

The role was created for Issue #34.

## Responsibilities

- Replace the `coredns` ConfigMap in `kube-system` with a declarative Corefile, using `kubernetes.core.k8s` and `/etc/kubernetes/admin.conf`.
- Add a dedicated server block that forwards `home.arpa` to Pi-hole.
- Wait for the `coredns` Deployment rollout (`kubectl rollout status`, timeout `120s`).

DNS resolution tests from a Pod are done by the `kubernetes/validation` role.

## DNS Flow

```text
Pod
 │
 ▼
10.96.0.10 (kube-dns Service)
 │
 ▼
CoreDNS
 ├── cluster.local   → Kubernetes Services and Pods
 ├── home.arpa       → Pi-hole 192.168.0.111
 └── other domains   → /etc/resolv.conf of the node
```

When the node `/etc/resolv.conf` (provided by DHCP) points to Pi-hole, external queries continue to Unbound (`192.168.0.110:5335`).

## Corefile

```text
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153
    forward . /etc/resolv.conf {
       max_concurrent 1000
    }
    cache 30 {
       disable success cluster.local
       disable denial cluster.local
    }
    loop
    reload
    loadbalance
}

home.arpa:53 {
    errors
    cache 30
    forward . 192.168.0.111
}
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `kubernetes_dns_namespace` | `kube-system` | CoreDNS namespace |
| `kubernetes_dns_configmap` | `coredns` | ConfigMap name |
| `kubernetes_dns_deployment` | `coredns` | Deployment name |
| `kubernetes_dns_service` | `kube-dns` | Service name |
| `kubernetes_dns_domain` | `cluster.local` | Cluster DNS domain |
| `kubernetes_dns_edge_domain` | `home.arpa` | Infrastructure DNS zone |
| `kubernetes_dns_edge_server` | `192.168.0.111` | Pi-hole address |

## Requirements

- Collection `kubernetes.core`.
- `python3-kubernetes` on the control plane (installed by `kubernetes/common`).
- `home.arpa` records in Pi-hole for the Kubernetes nodes. These records are currently created manually in Pi-hole and are not managed by any role:

```text
k8s-cp-01.home.arpa      192.168.0.130
k8s-worker-01.home.arpa  192.168.0.131
k8s-worker-02.home.arpa  192.168.0.132
```

## Troubleshooting

### `home.arpa` returns NXDOMAIN

CoreDNS has no forwarding rule for `home.arpa`, or the record does not exist in Pi-hole.

```bash
kubectl -n kube-system get configmap coredns -o yaml
dig @192.168.0.111 k8s-cp-01.home.arpa
```

### CoreDNS does not pick up the new configuration

```bash
kubectl -n kube-system rollout restart deployment/coredns
kubectl -n kube-system rollout status deployment/coredns
```

### Test from a Pod

```bash
kubectl run dns-test --image=busybox:1.36 --restart=Never --command -- sleep 300
kubectl exec dns-test -- nslookup kubernetes.default.svc.cluster.local
kubectl exec dns-test -- nslookup k8s-cp-01.home.arpa
kubectl exec dns-test -- nslookup google.com
kubectl delete pod dns-test
```
