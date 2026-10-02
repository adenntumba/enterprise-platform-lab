# CNI Decision

## 1. Objective

Select the Container Network Interface (CNI) for the initial Kubernetes cluster.

## 2. Decision

The selected CNI is:

```text
Cilium
```

## 3. Responsibility

The CNI provides:

- Pod-to-Pod networking;
- node networking integration;
- Service networking integration;
- NetworkPolicy capabilities;
- Kubernetes networking integration.

## 4. Why Cilium

Cilium provides a networking and security platform based on eBPF.

This aligns with the laboratory goal of studying:

- Kubernetes networking;
- Linux networking;
- eBPF;
- NetworkPolicy;
- network observability;
- modern Kubernetes networking capabilities.

Architecture:

```text
Kubernetes
    |
    v
Cilium
    |
    v
eBPF
    |
    v
Linux Kernel
```

## 5. Initial Approach

The first implementation will use:

```text
Cilium
+
kube-proxy
```

Cilium's kube-proxy replacement will not be enabled as part of the initial bootstrap.

That capability can be evaluated later after the baseline cluster is stable.

## 6. Pod CIDR

The initial Pod CIDR is:

```text
10.244.0.0/16
```

The final Cilium configuration must match the cluster networking model.

## 7. Alternative: Calico

Calico was considered because it is a mature Kubernetes networking and NetworkPolicy solution.

It remains a valid future comparison target.

Cilium was selected because eBPF and Linux networking are explicit learning objectives of this laboratory.

## 8. Trade-offs

### Cilium

Advantages:

- eBPF-based architecture;
- networking and security capabilities;
- NetworkPolicy;
- network observability;
- future Gateway API exploration.

Trade-offs:

- broader technology surface;
- additional eBPF concepts;
- troubleshooting may require Linux kernel knowledge.

### Calico

Advantages:

- mature networking stack;
- strong NetworkPolicy capabilities;
- broad Kubernetes adoption.

Trade-offs:

- does not provide the same eBPF-centered learning path selected for this lab.

## 9. Future Evaluation

The following may be evaluated after the baseline cluster is operational:

- kube-proxy replacement;
- Hubble;
- Gateway API;
- advanced NetworkPolicy;
- network observability.
