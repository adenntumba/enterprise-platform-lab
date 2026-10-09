# Kubernetes Validation Role

## Overview

The `kubernetes/validation` role runs end-to-end checks against the Kubernetes cluster.

It is executed by its own playbook, separate from the deployment:

```bash
cd ansible
ansible-playbook playbooks/kubernetes-validation.yml
```

The role was created for Issue #35.

## Checks

| Check | Hosts | How |
|---|---|---|
| `kubelet` is active | all `kubernetes` hosts | `systemd` module + assert |
| `containerd` is active | all `kubernetes` hosts | `systemd` module + assert |
| All nodes are `Ready` | control plane | `kubectl get nodes -o json` |
| Cilium is healthy | control plane | `cilium status -o json` inside `ds/cilium`; asserts `cilium`, `kubernetes`, `cluster.ciliumHealth`, `cni-file` and `hubble` are `Ok` |
| Internal DNS | control plane | `nslookup kubernetes.default.svc.cluster.local` from a Pod; the output must contain `10.96.0.10` |
| Edge DNS | control plane | `nslookup k8s-cp-01.home.arpa` from a Pod returns `192.168.0.130` |
| External DNS | control plane | `nslookup google.com` from a Pod succeeds |

The DNS checks use an ephemeral Pod named `dns-validation` (`busybox:1.36`). The Pod is deleted before the checks and always deleted at the end, even when a check fails.

Not covered yet: Pod-to-Pod and Pod-to-Service connectivity tests, and control-plane component health beyond node readiness.

## Variables

| Variable | Default |
|---|---|
| `kubernetes_validation_kubeconfig` | `/etc/kubernetes/admin.conf` |
| `kubernetes_validation_control_plane_host` | `{{ groups['control_plane'][0] }}` |
| `kubernetes_validation_cilium_namespace` | `kube-system` |
| `kubernetes_validation_cilium_daemonset` | `cilium` |
| `kubernetes_validation_kubelet_service` | `kubelet` |
| `kubernetes_validation_containerd_service` | `containerd` |
| `kubernetes_validation_dns_service` | `kube-dns` |
| `kubernetes_validation_dns_service_ip` | `10.96.0.10` |
| `kubernetes_validation_edge_dns` | `192.168.0.111` |
| `kubernetes_validation_test_image` | `busybox:1.36` |
| `kubernetes_validation_test_pod` | `dns-validation` |

The edge DNS hostname (`k8s-cp-01.home.arpa`) and expected address (`192.168.0.130`) are hardcoded in `tasks/main.yml`. `kubernetes_validation_dns_service` and `kubernetes_validation_edge_dns` are defined but not used by the tasks.

## Requirements

- The `home.arpa` record `k8s-cp-01.home.arpa` must exist in Pi-hole (created manually today).
- The cluster nodes must be able to pull `busybox:1.36`.

## Expected Result

```text
failed=0  unreachable=0
```

The playbook reports `changed` for the creation and removal of the validation Pod on every run.
