# Kubernetes Common Role

## Overview

Provides common configuration required by all Kubernetes nodes in the
Enterprise Platform Lab.

This role is applied to both control plane and worker nodes.

## Responsibilities

This role contains configuration shared by all Kubernetes nodes.

Platform-specific configuration is intentionally kept in dedicated roles.

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