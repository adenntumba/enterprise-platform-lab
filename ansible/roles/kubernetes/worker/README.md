# Kubernetes Worker Role

## Overview

The `kubernetes/worker` role joins worker nodes to an existing Kubernetes cluster using `kubeadm join`.

It runs on the `workers` group in `playbooks/kubernetes.yml`, after `kubernetes/control_plane` and before `kubernetes/cni`.

The role was created for Issue #33.

---

## Context

The Kubernetes cluster uses:

- Kubernetes `v1.37.1`
- Debian 13
- containerd
- kubeadm
- kubelet
- kubectl
- Cilium as CNI

Node preparation is done by:

- `base/linux`
- `kubernetes/common`
- `kubernetes/containerd`
- `kubernetes/packages`

The control plane bootstrap is done by `kubernetes/control_plane`.

---

## Architecture

```text
                    Kubernetes Control Plane
                    k8s-cp-01
                    192.168.0.130
                         │
                         │ kubeadm token create --print-join-command
                         │
                         ▼
                ┌──────────────────┐
                │  Join Command    │
                └────────┬─────────┘
                         │
                ┌────────┴─────────┐
                │                  │
                ▼                  ▼
        k8s-worker-01       k8s-worker-02
        192.168.0.131       192.168.0.132
```

---

## Tasks

1. Check whether `/etc/kubernetes/kubelet.conf` exists. If it does, the worker is already joined and the join is skipped.
2. Generate a join command on the first host of the `control_plane` group with `kubeadm token create --print-join-command` (`delegate_to`, `run_once`, `no_log`).
3. Run the join command with `--cri-socket unix:///run/containerd/containerd.sock` (`no_log`, `creates: /etc/kubernetes/kubelet.conf`).
4. Ensure the `kubelet` service is enabled and started.

No join command is copied manually between machines, and the token is not written to Git or logs.

---

## Variables

| Variable | Default | Description |
|---|---|---|
| `kubernetes_worker_kubelet_config` | `/etc/kubernetes/kubelet.conf` | File that marks a joined worker |
| `kubernetes_worker_cri_socket` | `unix:///run/containerd/containerd.sock` | CRI socket |
| `kubernetes_worker_control_plane_host` | `{{ groups['control_plane'][0] }}` | Host that generates the join command |

---

## Expected State

After this role, the workers are registered but `NotReady` until the `kubernetes/cni` role deploys Cilium.

Worker labels (for example `node-role.kubernetes.io/worker`) are not set by this role.

---

## Validation

```bash
kubectl get nodes -o wide
systemctl status kubelet        # on each worker
```

---

## Troubleshooting

### Join fails with an expired or invalid token

Run the playbook again: a new token is generated on every run for workers that are not joined yet.

### Worker stays `NotReady`

The CNI is not running yet, or Cilium failed on that node:

```bash
kubectl -n kube-system get pods -o wide -l k8s-app=cilium
```

### Re-join a worker

```bash
sudo kubeadm reset -f
sudo rm -f /etc/kubernetes/kubelet.conf
```

Then run `playbooks/kubernetes.yml` again.
