# Kubernetes Node Responsibilities

## 1. Objective

Define the responsibility boundaries between control plane and worker nodes.

## 2. Responsibility Matrix

| Node | Role | Primary Responsibilities |
|---|---|---|
| `k8s-cp-01` | Control Plane | API, scheduler, controllers, etcd |
| `k8s-worker-01` | Worker | Application and platform workloads |
| `k8s-worker-02` | Worker | Application and platform workloads |

## 3. Control Plane

The control plane manages the desired and observed state of the Kubernetes cluster.

Components:

- kube-apiserver;
- kube-scheduler;
- kube-controller-manager;
- etcd.

## 4. Workers

Workers execute workloads and contain:

- kubelet;
- containerd;
- CNI components;
- workload Pods.

## 5. Shared Node Requirements

All nodes require:

- Linux;
- systemd;
- containerd;
- kubelet;
- required kernel configuration;
- time synchronization;
- network connectivity;
- access to required package repositories.

## 6. Automation Boundaries

```text
OpenTofu
  -> VM lifecycle

Ansible
  -> Operating system configuration
  -> containerd
  -> Kubernetes packages
  -> Node preparation

kubeadm
  -> Cluster bootstrap and node joining
```

Permanent manual configuration should be avoided.
