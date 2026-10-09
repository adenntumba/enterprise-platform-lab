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

The containerd socket used by kubeadm is:

```text
unix:///run/containerd/containerd.sock
```

(`/var/run` is a symlink to `/run` on Debian.)

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

The `kubernetes/containerd` Ansible role manages:

- installation of the Debian package `containerd` (`1.7.24` on Debian 13);
- generation of `/etc/containerd/config.toml` with `containerd config default` when it does not exist;
- `SystemdCgroup = true`;
- CNI `bin_dir = "/opt/cni/bin"`, required by Cilium;
- service state (enabled and started, restarted on configuration changes).

Runtime validation (service active) is done by the `kubernetes/validation` role.

Note: Kubernetes v1.35 was announced as the last release to support containerd 1.x. The cluster runs Kubernetes `v1.37.1` with containerd `1.7.24`; this combination should be reviewed.
