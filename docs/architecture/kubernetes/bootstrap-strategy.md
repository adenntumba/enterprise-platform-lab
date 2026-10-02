# Kubernetes Bootstrap Strategy

## 1. Objective

Define how the initial Kubernetes cluster will be bootstrapped.

## 2. Tools

The bootstrap stack is:

```text
OpenTofu
   |
   v
Proxmox VMs
   |
   v
Ansible
   |
   v
Linux baseline
   |
   v
containerd
   |
   v
Kubernetes packages
   |
   v
kubeadm
```

## 3. Control Plane Bootstrap

The control plane will be initialized using:

```text
kubeadm init
```

The preferred implementation is a declarative kubeadm configuration file rather than a long collection of command-line flags.

## 4. Control Plane Endpoint

The cluster will use:

```text
k8s-api.home.arpa
```

Initially:

```text
k8s-api.home.arpa -> 192.168.0.130
```

The endpoint is established from the beginning to support future HA evolution.

## 5. Pod Network

The initial Pod CIDR is:

```text
10.244.0.0/16
```

The selected CNI must be configured consistently with this network.

## 6. Worker Bootstrap

Workers will join the cluster using:

```text
kubeadm join
```

The initial workers are:

```text
k8s-worker-01
k8s-worker-02
```

## 7. Secret Handling

Join tokens and bootstrap credentials must not be committed to Git.

They must not be stored in public documentation or permanent logs.

## 8. Automation

Manual commands may be used during development and troubleshooting.

The final implementation must encode repeatable configuration in Ansible and declarative Kubernetes/bootstrap configuration where appropriate.

## 9. Execution Order

```text
1. Provision VMs
2. Configure Linux
3. Install containerd
4. Install Kubernetes components
5. Bootstrap control plane
6. Install CNI
7. Join workers
8. Validate DNS
9. Validate cluster
```
