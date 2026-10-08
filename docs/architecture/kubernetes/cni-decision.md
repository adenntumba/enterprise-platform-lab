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

The Cilium Helm release does not override its IPAM settings, so Pods use the Cilium cluster-pool IPAM default ((`10.0.0.0/8`, one `/24` per node)).

The originally planned Pod CIDR was `10.244.0.0/16`; it is not configured.

## 7. Implementation

Implemented in Sprint 02 by the `kubernetes/cni` Ansible role:

| Setting | Value |
|---|---|
| Cilium | `1.20.2` |
| Chart | `oci://quay.io/cilium/charts/cilium` |
| Helm | `4.3.0` |
| Namespace / release | `kube-system` / `cilium` |
| kube-proxy | kept (no kube-proxy replacement) |
| Operator `hostNetwork` | `false` |
| Operator API address | `:9234` |
| containerd CNI `bin_dir` | `/opt/cni/bin` |

Hubble is enabled by the chart defaults; the `kubernetes/validation` role checks that its state is `Ok`. Hubble Relay and UI are not deployed.

## 8. Alternative: Calico

Calico was considered because it is a mature Kubernetes networking and NetworkPolicy solution.

It remains a valid future comparison target.

Cilium was selected because eBPF and Linux networking are explicit learning objectives of this laboratory.

## 9. Trade-offs

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

## 10. Future Evaluation

The following may be evaluated now that the baseline cluster is operational:

- kube-proxy replacement;
- Hubble Relay and UI;
- Gateway API;
- advanced NetworkPolicy;
- network observability.
