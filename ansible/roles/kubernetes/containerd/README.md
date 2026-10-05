```markdown
# Kubernetes Containerd Role

## Overview

This Ansible role installs and configures **containerd** as the container runtime for Kubernetes nodes.

The role is responsible only for the container runtime layer. Kubernetes components such as `kubelet`, `kubeadm`, and `kubectl` are intentionally handled by subsequent stages of the platform.

## Architecture

```text
Kubernetes
    │
    │ CRI
    ▼
containerd
    │
    │ OCI runtime
    ▼
runc
    │
    ▼
Linux Kernel
```

The role is applied to all hosts in the `kubernetes` inventory group.

## Responsibilities

The role performs the following operations:

- Install containerd.
- Create the containerd configuration directory.
- Generate the default containerd configuration.
- Configure containerd to use systemd cgroups.
- Enable the containerd systemd service.
- Ensure the containerd service is running.
- Restart containerd when its configuration changes.
- Maintain idempotent configuration management.

## Why containerd?

containerd is an Open Source container runtime designed to manage the complete container lifecycle.

Using containerd provides a dedicated runtime layer for Kubernetes without requiring Docker Engine.

The architecture is intentionally separated:

```text
Kubernetes
    │
    ▼
containerd
    │
    ▼
runc
    │
    ▼
Linux
```

This keeps the Kubernetes node runtime simple and aligned with modern Kubernetes architectures.

## Systemd Cgroups

The role configures:

```toml
SystemdCgroup = true
```

Kubernetes nodes use Linux cgroups to manage resources such as CPU and memory.

Using systemd as the cgroup manager keeps the container runtime aligned with the operating system's init and resource-management system.

```text
Linux
  │
  └── systemd
        │
        └── cgroups
              │
              └── containerd
                    │
                    └── Kubernetes workloads
```

## Configuration

Default variables are defined in:

```text
defaults/main.yml
```

Current defaults:

```yaml
containerd_package: containerd
containerd_service: containerd
containerd_config_file: /etc/containerd/config.toml
containerd_config_version: 2
containerd_systemd_cgroup: true
```

### Configuration file

The generated configuration is stored at:

```text
/etc/containerd/config.toml
```

The role generates the default configuration only when the configuration file does not already exist.

This prevents subsequent Ansible executions from overwriting existing configuration.

## Idempotency

The role is designed to be idempotent.

After the initial configuration, subsequent executions should report:

```text
changed=0
failed=0
```

The configuration is only modified when the desired state differs from the current state.

A configuration change triggers the following handler:

```text
Configure containerd
       │
       ▼
Restart containerd
```

## Validation

Verify the installed containerd version:

```bash
containerd --version
```

Verify the service:

```bash
systemctl is-enabled containerd
systemctl is-active containerd
```

Expected:

```text
enabled
active
```

Verify the cgroup configuration:

```bash
grep -A6 -B3 "SystemdCgroup" /etc/containerd/config.toml
```

Expected:

```text
SystemdCgroup = true
```

## Ansible Validation

Run the Kubernetes playbook:

```bash
cd ansible

ansible-playbook playbooks/kubernetes.yml
```

The role should be applied to:

```text
k8s-cp-01
k8s-worker-01
k8s-worker-02
```

Validate all nodes:

```bash
ansible kubernetes -b -m shell -a '
containerd --version
systemctl is-enabled containerd
systemctl is-active containerd
grep -A6 -B3 "SystemdCgroup" /etc/containerd/config.toml
'
```

## Troubleshooting

### containerd service is not running

Check the service:

```bash
systemctl status containerd
```

Check logs:

```bash
journalctl -u containerd --no-pager
```

### Invalid containerd configuration

Validate the configuration file:

```bash
containerd config dump
```

Check the configuration:

```bash
cat /etc/containerd/config.toml
```

### SystemdCgroup is false

Check:

```bash
grep "SystemdCgroup" /etc/containerd/config.toml
```

Expected:

```text
SystemdCgroup = true
```

If the configuration was changed, restart containerd:

```bash
systemctl restart containerd
```

However, configuration changes should preferably be performed through this Ansible role rather than manually on the nodes.

## Scope

This role does **not** install or configure:

- kubelet
- kubeadm
- kubectl
- Kubernetes control plane
- Kubernetes workers
- CNI plugins

Those components belong to subsequent stages of the Kubernetes platform implementation.

## Next Steps

The next stage is to install the Kubernetes node components:

```text
containerd
    │
    ▼
kubelet
    │
    ├── kubeadm
    │
    └── kubectl
```

After the node packages are available, the next stage will configure the Kubernetes control plane and workers.
```