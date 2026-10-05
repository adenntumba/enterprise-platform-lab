# Kubernetes Packages

Ansible role responsible for installing and configuring the Kubernetes node packages required by the cluster.

This role is applied to all Kubernetes nodes, including the control plane and worker nodes.

---

## Overview

The `kubernetes/packages` role installs the Kubernetes command-line and node components:

- `kubeadm`
- `kubelet`
- `kubectl`

The role also configures the official Kubernetes APT repository and places the installed Kubernetes packages on hold to prevent accidental upgrades through the operating system package manager.

---

## Architecture

The Kubernetes node preparation is divided into independent Ansible roles:

```text
Kubernetes Node
│
├── kubernetes/common
│   ├── Hostname
│   ├── Kernel modules
│   ├── Sysctl
│   ├── Swap
│   └── Time synchronization
│
├── kubernetes/containerd
│   └── Container runtime
│
└── kubernetes/packages
    ├── Kubernetes APT repository
    ├── kubeadm
    ├── kubelet
    └── kubectl
```

The separation keeps operating system preparation, container runtime configuration, and Kubernetes package management as independent responsibilities.

---

## Responsibilities

This role is responsible for:

1. Creating the APT keyrings directory.
2. Downloading the Kubernetes repository signing key.
3. Converting the repository key into a GPG keyring.
4. Configuring the official Kubernetes APT repository.
5. Installing the Kubernetes packages.
6. Holding the Kubernetes packages to prevent unintended upgrades.

The role does **not** initialize the Kubernetes control plane or join worker nodes to the cluster.

Those responsibilities belong to the `control_plane` and `worker` roles.

---

## Kubernetes Repository

The role uses the official Kubernetes package repository:

```text
https://pkgs.k8s.io/
```

The repository is configured per Kubernetes minor version.

The current configuration uses:

```yaml
kubernetes_version: "1.37"
```

Which results in:

```text
https://pkgs.k8s.io/core:/stable:/v1.37/deb/
```

The repository configuration is generated at:

```text
/etc/apt/sources.list.d/kubernetes.list
```

---

## Repository Signing Key

The Kubernetes repository signing key is stored separately from the system-wide APT trust configuration.

The role creates:

```text
/etc/apt/keyrings/
```

The downloaded repository key is stored as:

```text
/etc/apt/keyrings/kubernetes-release.key
```

The key is then converted to a GPG keyring:

```text
/etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

The APT repository uses the keyring through the `signed-by` option.

Example:

```text
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /
```

This limits the signing key's scope to the Kubernetes repository.

---

## Installed Packages

The role installs:

```yaml
kubernetes_packages:
  - kubeadm
  - kubelet
  - kubectl
```

### kubeadm

`kubeadm` is used to bootstrap and configure the Kubernetes cluster.

It will be used in a later stage to initialize the control plane and generate the configuration required for worker nodes to join the cluster.

### kubelet

`kubelet` is the Kubernetes node agent.

It is responsible for communicating with the Kubernetes control plane and managing workloads running on the node.

### kubectl

`kubectl` is the Kubernetes command-line client.

It will be used to interact with and administer the cluster.

---

## Package Version

The role currently targets Kubernetes minor version:

```yaml
kubernetes_version: "1.37"
```

The repository currently provides:

```text
kubeadm  v1.37.1
kubelet  v1.37.1
kubectl  v1.37.1
```

All Kubernetes nodes were validated with the same version.

Expected result:

```text
k8s-cp-01       v1.37.1
k8s-worker-01   v1.37.1
k8s-worker-02   v1.37.1
```

Keeping the Kubernetes packages aligned across nodes simplifies cluster bootstrap and upgrade management.

---

## Package Hold

Kubernetes packages are placed on APT hold after installation:

```text
kubeadm
kubelet
kubectl
```

Validation:

```bash
apt-mark showhold
```

Expected:

```text
kubeadm
kubectl
kubelet
```

The purpose of the hold is to prevent a regular operating system package upgrade from unintentionally changing the Kubernetes version.

Kubernetes upgrades should be deliberate operations that consider:

- Control plane version
- kubeadm version
- kubelet version
- Worker node versions
- Kubernetes version skew rules
- Cluster upgrade procedure

---

## Defaults

The main configurable variables are defined in:

```text
defaults/main.yml
```

Current configuration:

```yaml
---
# Kubernetes packages role defaults

kubernetes_version: "1.37"

kubernetes_packages:
  - kubeadm
  - kubelet
  - kubectl

kubernetes_apt_repository: "https://pkgs.k8s.io/core:/stable:/v{{ kubernetes_version }}/deb/"

kubernetes_apt_keyring: /etc/apt/keyrings/kubernetes-apt-keyring.gpg

kubernetes_apt_source: /etc/apt/sources.list.d/kubernetes.list
```

---

## Implementation

The role performs the following sequence:

```text
Create keyrings directory
        │
        ▼
Download repository signing key
        │
        ▼
Convert key to GPG keyring
        │
        ▼
Configure APT repository
        │
        ▼
Install Kubernetes packages
        │
        ▼
Hold Kubernetes packages
```

---

## Ansible Integration

The role is executed as part of the Kubernetes node preparation play:

```yaml
- name: Prepare Kubernetes nodes
  hosts: kubernetes
  become: true

  roles:
    - role: base/linux
    - role: kubernetes/common
    - role: kubernetes/containerd
    - role: kubernetes/packages
```

This guarantees that all Kubernetes nodes receive the same package configuration.

---

## Validation

### Ansible Syntax

From the `ansible/` directory:

```bash
ansible-playbook --syntax-check playbooks/kubernetes.yml
```

Expected:

```text
playbook: playbooks/kubernetes.yml
```

---

### Kubernetes Versions

```bash
ansible kubernetes -b -m shell -a '
echo "=== kubeadm ==="
kubeadm version -o short
echo "=== kubelet ==="
kubelet --version
echo "=== kubectl ==="
kubectl version --client=true
'
```

Validated result:

```text
kubeadm  v1.37.1
kubelet  Kubernetes v1.37.1
kubectl  Client Version: v1.37.1
```

The three Kubernetes nodes were validated successfully.

---

### Package Hold

```bash
ansible kubernetes -b -m shell -a '
apt-mark showhold | grep -E "^(kubeadm|kubelet|kubectl)$"
'
```

Expected:

```text
kubeadm
kubectl
kubelet
```

---

### Repository Configuration

```bash
ansible kubernetes -b -m shell -a '
cat /etc/apt/sources.list.d/kubernetes.list
'
```

Expected repository:

```text
https://pkgs.k8s.io/core:/stable:/v1.37/deb/
```

---

## Idempotency

The playbook was executed twice.

The first execution installed and configured the Kubernetes packages:

```text
changed=5
failed=0
```

The second execution produced:

```text
k8s-cp-01       ok=24  changed=0  failed=0
k8s-worker-01   ok=24  changed=0  failed=0
k8s-worker-02   ok=24  changed=0  failed=0
```

This confirms that the role is idempotent in the current environment.

---

## Troubleshooting

### Repository Configuration

Check the configured repository:

```bash
cat /etc/apt/sources.list.d/kubernetes.list
```

Expected:

```text
deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.37/deb/ /
```

---

### Check Installed Versions

```bash
kubeadm version -o short
kubelet --version
kubectl version --client=true
```

---

### Check Package Hold

```bash
apt-mark showhold
```

---

### Check Installed Packages

```bash
dpkg -l | grep -E 'kubeadm|kubelet|kubectl'
```

---

### Check APT Repository

```bash
apt-cache policy kubeadm kubelet kubectl
```

This can be used to verify the configured repository and available package versions.

---

## Design Decisions

### Why use `pkgs.k8s.io`?

The Kubernetes project moved its package distribution to the `pkgs.k8s.io` infrastructure.

Using the official repository provides a supported source for Kubernetes packages.

### Why configure a specific minor version?

Kubernetes package repositories are organized by minor version.

Pinning the repository to:

```text
v1.37
```

makes the intended Kubernetes release line explicit and avoids unintentionally consuming packages from another minor version.

### Why hold the packages?

Kubernetes upgrades require coordination between cluster components.

Allowing a normal system upgrade to modify Kubernetes packages could create version mismatches or an uncontrolled upgrade.

Therefore package upgrades should be explicitly planned.

---

## Scope

This role intentionally does not perform:

- Kubernetes control plane initialization
- Worker node joining
- CNI installation
- Kubernetes networking configuration
- Cluster configuration
- `kubectl` user configuration
- Application deployment
- Ingress configuration

Those responsibilities belong to subsequent stages of the Kubernetes implementation.

---

## Current Status

```text
Kubernetes Packages
│
├── APT repository             ✓
├── Repository keyring         ✓
├── kubeadm                    ✓
├── kubelet                    ✓
├── kubectl                    ✓
├── Version alignment          ✓
├── Package hold               ✓
├── Ansible syntax             ✓
└── Idempotency                ✓
```

Current Kubernetes package version:

```text
v1.37.1
```

Nodes:

```text
k8s-cp-01
k8s-worker-01
k8s-worker-02
```

All nodes are prepared for the next Kubernetes bootstrap stage.

---

## Next Steps

The next stage is the Kubernetes control plane bootstrap.

The `kubernetes/control_plane` role will be responsible for:

```text
kubeadm
   │
   ▼
Control Plane Initialization
   │
   ├── Kubernetes API Server
   ├── Controller Manager
   ├── Scheduler
   └── etcd
```

After the control plane is operational, the worker role will be responsible for joining:

```text
k8s-worker-01
k8s-worker-02
```

to the cluster.

---

## Related Roles

```text
roles/kubernetes/
├── common/
├── containerd/
├── packages/
├── control_plane/
└── worker/
```

The roles are intentionally separated to keep the Kubernetes infrastructure modular, testable, and maintainable.
