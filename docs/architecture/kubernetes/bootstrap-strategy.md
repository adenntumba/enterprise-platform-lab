# Kubernetes Bootstrap Strategy

## 1. Objective

Define how the initial Kubernetes cluster is bootstrapped.

Status: implemented in Sprint 02 by the `kubernetes/control_plane` and `kubernetes/worker` Ansible roles.

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

The control plane is initialized by the `kubernetes/control_plane` role using:

```text
kubeadm init --cri-socket unix:///run/containerd/containerd.sock
```

The role skips `kubeadm init` when `/etc/kubernetes/admin.conf` already exists, and copies the admin kubeconfig to `/home/debian/.kube/config`.

Planned (not implemented): a declarative kubeadm configuration file instead of command-line flags.

## 4. Control Plane Endpoint

The cluster currently uses the control-plane IP address:

```text
https://192.168.0.130:6443
```

No `--control-plane-endpoint` is passed to `kubeadm init`.

Planned (not implemented): `k8s-api.home.arpa -> 192.168.0.130`, set as `controlPlaneEndpoint` to support future HA evolution.

## 5. Pod Network

No Pod CIDR is passed to kubeadm.

Pod addresses are allocated by Cilium using its cluster-pool IPAM: one `/24` per node from the `10.0.0.0/8` pool (chart default).

Effective allocation: `k8s-cp-01` `10.0.0.0/24`, `k8s-worker-01` `10.0.2.0/24`, `k8s-worker-02` `10.0.1.0/24`.

No Service CIDR is passed either, so the Service CIDR is the kubeadm default `10.96.0.0/12`.

The ADR-0002 targets (`10.244.0.0/16` for Pods, `10.96.0.0/16` for Services) are not applied. See [network-architecture.md](network-architecture.md#target-configuration-and-runtime-state).

## 6. Worker Bootstrap

Workers join the cluster using `kubeadm join`.

The `kubernetes/worker` role generates a fresh join command on the control plane with `kubeadm token create --print-join-command` (delegated, `run_once`, `no_log`) and runs it on every worker that does not yet have `/etc/kubernetes/kubelet.conf`.

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
1. Provision VMs                  kubernetes/opentofu
2. Configure Linux                base/linux, kubernetes/common
3. Install containerd             kubernetes/containerd
4. Install Kubernetes components  kubernetes/packages
5. Bootstrap control plane        kubernetes/control_plane
6. Join workers                   kubernetes/worker
7. Install CNI                    kubernetes/cni
8. Configure DNS                  kubernetes/dns
9. Validate cluster and DNS       kubernetes/validation (separate playbook)
```

Workers join before the CNI is installed; all nodes stay `NotReady` until Cilium is running.
