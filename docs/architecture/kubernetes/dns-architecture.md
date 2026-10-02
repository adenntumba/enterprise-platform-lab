# Kubernetes DNS Architecture

## 1. Objective

Define the DNS architecture between Kubernetes and the existing lab DNS platform.

## 2. DNS Layers

```text
Kubernetes
    |
    v
CoreDNS
    |
    v
Pi-hole
    |
    v
Unbound
    |
    v
Internet
```

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

External queries follow:

```text
Pod
 |
 v
CoreDNS
 |
 v
Pi-hole 192.168.0.111
 |
 v
Unbound 192.168.0.110:5335
 |
 v
Internet
```

## 6. Infrastructure DNS

The infrastructure namespace is:

```text
home.arpa
```

Examples:

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

```text
k8s-api.home.arpa
```

Initially resolves to:

```text
192.168.0.130
```

In a future HA topology it will resolve to the API load balancer.
