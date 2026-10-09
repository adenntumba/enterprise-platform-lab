# Raspberry Pi Base Role

## Overview

The `base/raspberry` role provides Raspberry Pi platform-specific
validation for the Enterprise Platform Lab.

The role is responsible for identifying and validating Raspberry Pi
hosts before platform-specific workloads are deployed.

It is applied to the `raspberry` group by `playbooks/bootstrap.yml`, after `base/linux`.

## Responsibilities

- Validate that the operating system is Linux.
- Validate the expected architecture (`aarch64`).
- Read the hardware model from `/proc/device-tree/model`.
- Validate that the model contains `Raspberry Pi`.
- Display platform information (model, architecture, kernel, distribution).

The role only validates and reports. It does not change the host.

## Variables

| Variable | Default | Description |
|---|---|---|
| `raspberry_expected_architecture` | `aarch64` | Architecture required by the role |
| `raspberry_model_path` | `/proc/device-tree/model` | File used to detect the hardware model |

## Design Principles

This role intentionally does not:

- install common Linux packages;
- configure Pi-hole;
- configure Unbound;
- configure Docker;
- configure Kubernetes;
- modify firmware;
- perform hardware tuning.

Those responsibilities belong to other layers of the platform.

## Architecture

```text
Linux Host
    |
    v
base/linux
    |
    v
base/raspberry
    |
    +-- Platform validation
    +-- Hardware identification
    |
    v
Platform-specific services
```

## Example

```yaml
- hosts: raspberry
  become: true
  gather_facts: true

  roles:
    - role: base/linux
    - role: base/raspberry
```
