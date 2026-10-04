# Proxmox Infrastructure

Infrastructure as Code layer responsible for managing the foundational
resources of the Proxmox VE environment used by the Enterprise Platform Lab.

This directory contains the OpenTofu configuration for resources that are
shared by multiple workloads and should not belong to a specific platform
or application.

---

## Objective

The purpose of this layer is to establish and manage the foundational
resources required by the lab's Proxmox VE environment.

These resources form the infrastructure foundation consumed by higher-level
platforms such as Kubernetes, storage services and other virtual machines.

The infrastructure is managed using OpenTofu following Infrastructure as Code
principles.

The main goals are:

- reproducibility
- declarative infrastructure management
- version control
- predictable changes
- separation of infrastructure responsibilities
- reduced dependency on manual configuration through the Proxmox UI

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
                       Proxmox VE
                      192.168.0.120
                            |
             +--------------+--------------+
             |              |              |
             v              v              v
          Network         Storage         Pools
          vmbr0           vmdata      kubernetes-pool
                                         |
                              +----------+----------+
                              |                     |
                              v                     v
                         Kubernetes              Other VMs
                           VMs
```

---

## Scope

This OpenTofu root module is responsible for the foundational resources
of the Proxmox VE environment.

These resources are shared by multiple workloads and platforms running
on the lab.

### Managed resources

Currently, this layer manages:

- Proxmox provider configuration
- Proxmox VM pools
- network-related infrastructure definitions
- storage-related infrastructure definitions

### Workload-specific resources

Workload-specific resources are intentionally managed by separate
OpenTofu roots.

For example:

```text
infrastructure/proxmox/
    |
    +-- Proxmox foundation
    |
    +-- pools
    +-- network
    +-- storage
            |
            v
kubernetes/opentofu/
    |
    +-- Kubernetes VMs
```

This separation keeps the Proxmox foundation independent from
workload-specific implementations.

---

## Responsibility Boundary

The repository follows a layered infrastructure model:

```text
                    Proxmox VE
                        |
          +-------------+-------------+
          |                           |
          v                           v
 infrastructure/proxmox/       kubernetes/opentofu/
          |                           |
          |                           |
     Foundation                 Kubernetes VMs
          |                           |
          v                           v
   Pools / Network /           Control Plane /
      Storage                    Workers
```

### `infrastructure/proxmox`

Responsible for:

- Proxmox pools
- storage definitions
- network definitions
- shared Proxmox infrastructure

### `kubernetes/opentofu`

Responsible for:

- Kubernetes VM provisioning
- VM resources
- CPU and memory
- disks
- network interfaces
- MAC addresses
- Cloud-Init
- VM lifecycle

### Ansible

Responsible for:

- operating system configuration
- packages
- hostname
- security baseline
- container runtime
- Kubernetes prerequisites

### Kubernetes

Responsible for:

- cluster orchestration
- workloads
- services
- deployments
- platform components

---

## Proxmox Environment

The current lab uses a Proxmox VE node:

```text
Hostname: pve
IP:       192.168.0.120
```

The Proxmox environment currently provides:

```text
Proxmox VE
    |
    +-- Network
    |    |
    |    +-- vmbr0
    |
    +-- Storage
    |    |
    |    +-- local
    |    +-- local-lvm
    |    +-- vmdata
    |
    +-- Pools
         |
         +-- kubernetes-pool
         +-- truenas-pool
```

---

## Pools

Proxmox pools provide logical grouping of virtual machines.

The lab uses pools to separate workloads and make the infrastructure easier
to manage.

Current pools include:

```text
kubernetes-pool
truenas-pool
```

For example:

```text
kubernetes-pool
    |
    +-- k8s-cp-01
    +-- k8s-worker-01
    +-- k8s-worker-02
```

The Kubernetes OpenTofu configuration consumes the Kubernetes pool instead
of creating it.

This establishes a clear dependency:

```text
infrastructure/proxmox
        |
        | creates
        v
kubernetes-pool
        |
        | consumed by
        v
kubernetes/opentofu
```

---

## Storage

The current Proxmox environment contains the following storage resources:

| Storage | Type | Purpose |
|---|---|---|
| `local` | Directory | ISO, templates and backups |
| `local-lvm` | LVM Thin | VM disks |
| `vmdata` | LVM Thin | VM disks |

The `vmdata` storage is currently used by the Kubernetes VMs.

The separation between infrastructure and workload configuration allows the
storage layer to evolve independently from Kubernetes.

---

## Network

The Proxmox virtual machines use the Linux bridge:

```text
vmbr0
```

The bridge connects the virtual machines to the physical network through
the Proxmox host.

```text
                 Physical Network
                        |
                        v
                    Proxmox
                        |
                      vmbr0
                        |
          +-------------+-------------+
          |             |             |
          v             v             v
       VM 101        VM 102        VM 103
```

IP address assignment is handled by the external DHCP infrastructure.

MAC addresses for workload VMs are defined by the workload-specific
OpenTofu configuration.

---

## OpenTofu Structure

The directory is organized by infrastructure responsibility:

```text
infrastructure/proxmox/
├── provider.tf
├── versions.tf
├── variables.tf
├── terraform.tfvars
├── pools.tf
├── network.tf
├── storage.tf
└── README.md
```

### `provider.tf`

Defines the Proxmox VE provider and authentication configuration.

### `versions.tf`

Defines the OpenTofu and provider version requirements.

### `variables.tf`

Defines configurable infrastructure parameters.

### `terraform.tfvars`

Contains environment-specific values.

Sensitive credentials must never be committed to the repository.

### `pools.tf`

Defines Proxmox VM pools.

### `network.tf`

Defines network-related infrastructure configuration.

### `storage.tf`

Defines storage-related infrastructure configuration.

---

## Authentication

Authentication with Proxmox is performed using an API token.

The credentials are provided through environment variables rather than
being stored in the OpenTofu configuration.

The repository uses a single `.env` file at the repository root.

Load the environment variables into the current shell:

```bash
set -a
source .env
set +a
```

The `.env` file is intentionally excluded from Git.

A sanitized `.env.example` is maintained in the repository to document
the required variables.

Example:

```text
PROXMOX_VE_ENDPOINT=https://192.168.0.120:8006/
PROXMOX_VE_API_TOKEN=<secret>
PROXMOX_VE_INSECURE=true
```

Never commit the real API token.

---

## OpenTofu Workflow

The infrastructure follows the standard OpenTofu workflow:

```text
                 Configuration
                       |
                       v
                  tofu fmt
                       |
                       v
                 tofu validate
                       |
                       v
                   tofu plan
                       |
                  Review
                       |
                       v
                  tofu apply
                       |
                       v
                Proxmox VE
```

### Initialize

```bash
tofu init
```

### Format

```bash
tofu fmt
```

### Validate

```bash
tofu validate
```

### Plan

```bash
tofu plan
```

### Apply

```bash
tofu apply
```

---

## State Management

OpenTofu maintains a state file representing the resources managed by this
configuration.

The state is currently local because this is a homelab environment.

Typical local state files include:

```text
terraform.tfstate
terraform.tfstate.backup
```

These files must not be committed to Git.

The state represents the relationship between the OpenTofu configuration
and the real infrastructure.

As the lab evolves, remote state management may be introduced to provide:

- centralized state
- state locking
- recovery
- collaboration
- improved operational safety

---

## Design Principles

### Infrastructure is declarative

The desired state is defined as code.

Instead of manually creating resources through the Proxmox UI:

```text
Manual configuration
        |
        v
     Proxmox
```

the desired approach is:

```text
OpenTofu configuration
        |
        v
      Plan
        |
        v
      Apply
        |
        v
     Proxmox
```

This allows infrastructure changes to be:

- reviewed
- versioned
- reproduced
- audited
- automated

---

### Shared infrastructure is separated from workloads

Foundation resources belong to:

```text
infrastructure/proxmox/
```

Workload-specific resources belong to their respective platform directories.

Example:

```text
infrastructure/proxmox/
        |
        +-- kubernetes-pool
        |
        v
kubernetes/opentofu/
        |
        +-- k8s-cp-01
        +-- k8s-worker-01
        +-- k8s-worker-02
```

This prevents the Kubernetes implementation from owning resources that are
actually part of the Proxmox foundation.

---

## Resource Dependency Model

The architecture intentionally separates resource ownership.

```text
                 infrastructure/proxmox
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
           Network       Storage        Pools
             |             |             |
             +-------------+-------------+
                           |
                           v
                  kubernetes/opentofu
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
        k8s-cp-01    k8s-worker-01   k8s-worker-02
```

The Kubernetes OpenTofu root does not recreate the Proxmox pool.

Instead, it consumes the existing pool as a dependency.

This keeps ownership explicit:

```text
infrastructure/proxmox
        owns
          |
          v
  kubernetes-pool

kubernetes/opentofu
        consumes
          |
          v
  kubernetes-pool
```

---

## Validation

After applying changes, verify the Proxmox environment.

### Virtual machines

List the virtual machines:

```bash
ssh root@192.168.0.120 qm list
```

### Pools

Verify the Proxmox pools:

```bash
ssh root@192.168.0.120 pvesh get /pools
```

### Storage

Verify storage status:

```bash
ssh root@192.168.0.120 pvesm status
```

### Network

Verify network interfaces:

```bash
ssh root@192.168.0.120 ip -br link
```

The validation should confirm that the resources represented in OpenTofu
exist and are operational in Proxmox.

---

## Troubleshooting

### Authentication errors

Verify that the environment variables are loaded:

```bash
env | grep '^PROXMOX_VE_'
```

Do not print or expose the API token value.

If authentication fails, verify:

- Proxmox endpoint
- API token identifier
- API token permissions
- `.env` variables
- shell environment

---

### Provider initialization fails

Run:

```bash
tofu init
```

If provider dependencies have changed:

```bash
tofu init -upgrade
```

Review the provider lock file:

```text
.terraform.lock.hcl
```

The lock file should be committed to Git to make provider versions
reproducible.

---

### Unexpected infrastructure changes

Always inspect:

```bash
tofu plan
```

before applying changes.

Never use `tofu apply` blindly in a production-style workflow.

The plan should be reviewed before approving infrastructure changes.

---

### State inconsistency

Inspect the current state:

```bash
tofu state list
```

Compare the OpenTofu state with the actual Proxmox environment before
performing corrective actions.

Avoid manually editing the state file.

---

## Security

The Proxmox API token is treated as a secret.

The following files must never be committed:

```text
.env
terraform.tfstate
terraform.tfstate.backup
```

Terraform/OpenTofu state can contain infrastructure metadata and potentially
sensitive information.

Secrets should be supplied through environment variables or a dedicated
secret management solution.

As the lab evolves, secret management can be integrated into the CI/CD
pipeline.

---

## Git and Change Management

Infrastructure changes should follow the same engineering practices used
for application code.

Recommended workflow:

```text
Create branch
     |
     v
Modify OpenTofu
     |
     v
tofu fmt
     |
     v
tofu validate
     |
     v
tofu plan
     |
     v
Review
     |
     v
Commit
     |
     v
Pull Request
     |
     v
CI validation
     |
     v
Merge
```

Future GitHub Actions workflows can automatically execute:

- `tofu fmt -check`
- `tofu validate`
- static analysis
- security scanning
- plan generation
- policy validation

Actual infrastructure changes should remain protected by an explicit
approval workflow.

---

## Portfolio Value

This layer demonstrates several practices used in production infrastructure
environments:

- Infrastructure as Code
- declarative resource management
- provider-based infrastructure automation
- separation of foundation and workload layers
- version-controlled infrastructure
- explicit resource dependencies
- infrastructure validation
- secret separation
- reproducible environments
- infrastructure change review

The architecture intentionally demonstrates the separation between
infrastructure provisioning and workload configuration.

This is similar to patterns commonly found in enterprise infrastructure
teams, where foundational infrastructure is managed independently from
platform workloads.

---

## Current Infrastructure

The current Proxmox foundation includes:

```text
Proxmox VE
|
+-- Node
|    |
|    +-- pve
|         |
|         +-- 192.168.0.120
|
+-- Network
|    |
|    +-- vmbr0
|
+-- Storage
|    |
|    +-- local
|    +-- local-lvm
|    +-- vmdata
|
+-- Pools
     |
     +-- kubernetes-pool
     |
     +-- truenas-pool
```

The Kubernetes workload currently consumes:

```text
kubernetes-pool
        |
        +-- k8s-cp-01
        +-- k8s-worker-01
        +-- k8s-worker-02
```

---

## Current Status

The Proxmox foundation has been successfully established using OpenTofu.

Validated components include:

- Proxmox provider authentication
- Proxmox connectivity
- VM pools
- network configuration
- storage configuration
- Kubernetes pool availability
- consumption of the Kubernetes pool by the Kubernetes OpenTofu layer

The Kubernetes VM provisioning is implemented separately under:

```text
kubernetes/opentofu/
```

---

## Next Steps

Planned evolution of the Proxmox infrastructure layer:

- improve network abstraction
- improve storage abstraction
- add additional Proxmox pools as required
- introduce stronger state management
- integrate validation into GitHub Actions
- add infrastructure security checks
- evaluate remote state
- document disaster recovery procedures
- document Proxmox backup strategy
- document infrastructure recovery procedures
- introduce policy-as-code validation

---

## References

- OpenTofu documentation
- Proxmox VE documentation
- bpg/proxmox provider documentation
- Enterprise Platform Lab architecture documentation