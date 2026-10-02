# Container Runtime Decision

## 1. Objective

Document the container runtime selected for the Kubernetes nodes.

## 2. Decision

The selected runtime is:

```text
containerd
```

## 3. Architecture

```text
Kubernetes
    |
    | CRI
    v
containerd
    |
    v
Containers
```

## 4. CRI

Kubernetes communicates with the runtime through the Container Runtime Interface (CRI).

The expected containerd socket is:

```text
unix:///var/run/containerd/containerd.sock
```

## 5. Cgroups

The runtime will use the:

```text
systemd
```

cgroup driver.

The kubelet configuration must use the same cgroup model.

## 6. Docker Engine

Docker Engine is not selected as the Kubernetes container runtime.

Docker may still be used elsewhere in the lab for development workloads, but it is not the kubelet runtime.

## 7. Alternative

CRI-O was considered as an alternative.

containerd was selected because it provides a straightforward CRI-based runtime suitable for the laboratory architecture.

## 8. Automation

Ansible will manage:

- installation;
- configuration;
- CRI configuration;
- cgroup configuration;
- service state;
- runtime validation.
