# Raspberry Pi Base Role

## Overview

The `base/raspberry` role provides Raspberry Pi platform-specific
validation for the Enterprise Platform Lab.

The role is responsible for identifying and validating Raspberry Pi
hosts before platform-specific workloads are deployed.

## Responsibilities

- Validate the operating system.
- Validate the expected architecture.
- Detect the Raspberry Pi hardware model.
- Validate that the target host is a Raspberry Pi.
- Expose Raspberry Pi platform information.

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