# Kubernetes DNS Architecture

## 1. Objective

Define the DNS architecture between Kubernetes and the existing lab DNS platform.

## 2. DNS Layers

```text
Pod
 |
 v
CoreDNS 10.96.0.10
 |
 +-- cluster.local     -> answered by CoreDNS (Kubernetes plugin)
 |
 +-- home.arpa         -> Pi-hole 192.168.0.111 (local DNS records)
 |
 +-- other domains     -> node /etc/resolv.conf -> (Pi-hole -> Unbound -> Internet)
```

The CoreDNS configuration is managed by the `kubernetes/dns` Ansible role, which replaces the `coredns` ConfigMap in `kube-system` and waits for the rollout.

## 3. CoreDNS

CoreDNS provides DNS resolution for Kubernetes.

It is responsible for:

- Service discovery;
- Pod-related DNS records;
- `cluster.local` resolution;
- forwarding external queries.

## 4. Kubernetes DNS

The initial Kubernetes DNS Service address is:

```text
10.96.0.10
```

The Kubernetes DNS domain is:

```text
cluster.local
```

## 5. External DNS

External queries are forwarded by CoreDNS to the resolvers in the node `/etc/resolv.conf` (`forward . /etc/resolv.conf`). That file is provided by DHCP; when it points to Pi-hole, the path is:

```text
Pod -> CoreDNS -> Pi-hole 192.168.0.111 -> Unbound 192.168.0.110:5335 -> Internet
```

Only `home.arpa` is forwarded to Pi-hole explicitly:

```text
home.arpa:53 {
    errors
    cache 30
    forward . 192.168.0.111
}
```

## 6. Infrastructure DNS

The infrastructure namespace is:

```text
home.arpa
```

Records validated today (created manually in Pi-hole, not managed by code):

```text
k8s-cp-01.home.arpa      192.168.0.130
k8s-worker-01.home.arpa  192.168.0.131
k8s-worker-02.home.arpa  192.168.0.132
```

Planned examples:

```text
pihole.home.arpa
unbound.home.arpa
proxmox.home.arpa
truenas.home.arpa
k8s-api.home.arpa
```

## 7. Domain Separation

The two DNS namespaces have different responsibilities:

```text
home.arpa
  -> Lab infrastructure

cluster.local
  -> Kubernetes services
```

They should not be mixed.

## 8. Kubernetes API Endpoint

Planned (not implemented): `k8s-api.home.arpa -> 192.168.0.130`.

The cluster currently uses `https://192.168.0.130:6443`. In a future HA topology the name will resolve to the API load balancer.
