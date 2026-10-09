# Kubernetes Common Role

## Overview

Provides common configuration required by all Kubernetes nodes in the
Enterprise Platform Lab.

This role is applied to both control plane and worker nodes by `playbooks/kubernetes.yml`, after `base/linux`.

## Responsibilities

- Set the hostname to the Ansible `inventory_hostname`.
- Install the Kubernetes node prerequisite packages.
- Install, enable and start `chrony` for time synchronization.
- Load the `overlay` and `br_netfilter` kernel modules and persist them in `/etc/modules-load.d/kubernetes.conf`.
- Write the Kubernetes sysctl settings to `/etc/sysctl.d/99-kubernetes.conf` and apply them with `sysctl --system`.
- Disable active swap and comment out swap entries in `/etc/fstab`.

## Scope

```text
Kubernetes nodes
      |
      v
kubernetes/common
      |
      +-- Control Plane
      |
      +-- Workers
```

Platform-specific configuration is intentionally kept in dedicated roles (`containerd`, `packages`, `control_plane`, `worker`, `cni`, `dns`).

## Variables

| Variable | Default |
|---|---|
| `kubernetes_required_packages` | `apt-transport-https`, `ca-certificates`, `curl`, `gpg`, `conntrack`, `socat`, `ipset`, `ethtool`, `util-linux`, `python3-kubernetes` |
| `kubernetes_kernel_modules` | `overlay`, `br_netfilter` |
| `kubernetes_sysctl_settings` | `net.bridge.bridge-nf-call-iptables: 1`, `net.bridge.bridge-nf-call-ip6tables: 1`, `net.ipv4.ip_forward: 1` |
| `kubernetes_sysctl_config_file` | `/etc/sysctl.d/99-kubernetes.conf` |
| `kubernetes_time_sync_package` | `chrony` |
| `kubernetes_time_sync_service` | `chrony` |

`python3-kubernetes` is required by the `kubernetes.core.k8s` module used in the `kubernetes/dns` role.

## Dependencies

- Collection `community.general` (`modprobe` module).

## Validation

```bash
hostnamectl
swapon --show            # no output expected
lsmod | grep -E 'overlay|br_netfilter'
sysctl net.ipv4.ip_forward net.bridge.bridge-nf-call-iptables
chronyc tracking
```
