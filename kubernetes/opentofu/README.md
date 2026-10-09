# Kubernetes OpenTofu

Infrastructure as Code layer for the Kubernetes platform of the Enterprise Platform Lab.

This directory contains the OpenTofu configuration responsible for provisioning
the Kubernetes virtual machines on Proxmox VE.

---

## Objective

The goal is to provision the Kubernetes infrastructure using Infrastructure as Code,
following practices commonly used in production environments.

OpenTofu is responsible for defining and provisioning the Kubernetes virtual machines.

Ansible is responsible for configuring the operating systems after the virtual
machines are provisioned.

Kubernetes is responsible for container orchestration.

---

## Architecture

```text
                         GitHub
                            |
                            v
               +-------------------------+
               | enterprise-platform-lab |
               +------------+------------+
                            |
                            v
                        OpenTofu
                            |
                            v
                  bpg/proxmox provider
                            |
                            v
                     Proxmox VE
                    192.168.0.120
                            |
                     kubernetes-pool
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
        k8s-cp-01    k8s-worker-01   k8s-worker-02
        192.168.0.130 192.168.0.131   192.168.0.132
              |             |             |
              +-------------+-------------+
                            |
                            v
                         Ansible
                            |
                            v
                       Kubernetes
```

---

## Prerequisites

- The `kubernetes-pool` pool must exist. It is created by `infrastructure/proxmox`, so apply that root first.
- A Debian 13 Cloud-Init template must exist on Proxmox (`kubernetes_template_id`, `9000` in the example). The template is created manually.
- The datastore `vmdata` and the bridge `vmbr0` must exist on the Proxmox node.
- The public key `~/.ssh/id_ed25519.pub` must exist on the machine running OpenTofu.
- Proxmox credentials are read from environment variables (see the repository `.env.example`):

```bash
set -a
source ../../.env
set +a
```

---

## Files

| File | Purpose |
|---|---|
| `versions.tf` | OpenTofu `>= 1.6.0`, provider `bpg/proxmox` `~> 0.114.0` |
| `provider.tf` | Empty `proxmox` provider block; configuration comes from `PROXMOX_VE_*` environment variables |
| `data.tf` | Reads the existing `kubernetes-pool` pool |
| `variables.tf` | `proxmox_node`, `kubernetes_template_id`, `kubernetes_vms` |
| `main.tf` | One `proxmox_virtual_environment_vm` per entry in `kubernetes_vms` |
| `outputs.tf` | VM IDs, names and MAC addresses |
| `terraform.tfvars.example` | Example values; copy to `terraform.tfvars` (ignored by Git) |

---

## Variables

| Variable | Type | Description |
|---|---|---|
| `proxmox_node` | `string` | Proxmox node name (`pve`) |
| `kubernetes_template_id` | `number` | VMID of the Debian Cloud-Init template |
| `kubernetes_vms` | `map(object)` | One entry per VM: `role`, `cores`, `memory` (MiB), `disk` (GiB), `mac` |

The `pool` attribute in `terraform.tfvars.example` is not declared in `variables.tf` and is ignored; the pool is always `kubernetes-pool`.

Current values (from `terraform.tfvars.example`):

| VM | Role | vCPU | Memory | Disk | MAC |
|---|---|---:|---:|---:|---|
| `k8s-cp-01` | control-plane | 2 | 4096 MiB | 20 GiB | `BC:24:11:01:00:01` |
| `k8s-worker-01` | worker | 2 | 2048 MiB | 20 GiB | `BC:24:11:01:00:02` |
| `k8s-worker-02` | worker | 2 | 2048 MiB | 20 GiB | `BC:24:11:01:00:03` |

---

## VM Configuration

Every VM is created with:

| Setting | Value |
|---|---|
| Clone source | `kubernetes_template_id` |
| Pool | `kubernetes-pool` |
| Disk | `scsi0` on datastore `vmdata`, size from `disk` |
| Cloud-Init datastore | `vmdata` |
| Network | bridge `vmbr0`, fixed MAC from `mac` |
| IPv4 | DHCP |
| User | `debian`, SSH key `~/.ssh/id_ed25519.pub` |
| QEMU Guest Agent | disabled |
| OS type | `l26` |
| Started | `true` |

The datastore, bridge, user and SSH key path are hardcoded in `main.tf`.

---

## Networking

IP addresses are not configured by OpenTofu. Each VM uses DHCP, and the router maps the fixed MAC addresses to the expected IPs through DHCP reservations:

```text
BC:24:11:01:00:01 -> 192.168.0.130  k8s-cp-01
BC:24:11:01:00:02 -> 192.168.0.131  k8s-worker-01
BC:24:11:01:00:03 -> 192.168.0.132  k8s-worker-02
```

Because the QEMU Guest Agent is disabled, OpenTofu cannot read the VM IP addresses; the IPv4 output in `outputs.tf` is commented out.

---

## Workflow

```bash
cp terraform.tfvars.example terraform.tfvars
tofu init
tofu fmt -check
tofu validate
tofu plan
tofu apply
```

The state is local (`terraform.tfstate`, ignored by Git).

---

## Next Stage

After the VMs are running, the nodes are configured by Ansible:

```bash
cd ../../ansible
ansible-playbook playbooks/kubernetes.yml
```
