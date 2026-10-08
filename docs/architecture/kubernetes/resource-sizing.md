# Kubernetes Resource Sizing

## 1. Objective

Define the initial compute and storage allocation for Kubernetes virtual machines.

## 2. Initial Sizing

Current sizing, as provisioned by `kubernetes/opentofu` (see `terraform.tfvars.example`):

| Node | vCPU | RAM | Disk |
|---|---:|---:|---:|
| `k8s-cp-01` | 2 | 4 GiB | 20 GiB |
| `k8s-worker-01` | 2 | 2 GiB | 20 GiB |
| `k8s-worker-02` | 2 | 2 GiB | 20 GiB |
| **Total** | **6** | **8 GiB** | **60 GiB** |

The originally planned sizing was 4 vCPU / 6 GiB / 40 GiB for the control plane and 2 vCPU / 4 GiB / 40 GiB per worker (8 vCPU, 14 GiB, 120 GiB in total). It can be applied by changing `kubernetes_vms` in `terraform.tfvars`.

## 3. Control Plane

Current allocation:

```text
2 vCPU
4 GiB RAM
20 GiB disk
```

The control plane runs the control plane components and stacked etcd.

## 4. Workers

Each worker currently receives:

```text
2 vCPU
2 GiB RAM
20 GiB disk
```

2 GiB is the kubeadm minimum memory per node; workers have little headroom for workloads.

## 5. Disk Scope

The initial VM disk is intended for:

- operating system;
- containerd;
- container images;
- local logs;
- Kubernetes components.

Persistent application storage is outside this sizing decision.

## 6. Scaling

Scaling can be performed vertically or horizontally.

Vertical:

```text
Increase vCPU / RAM / disk
```

Horizontal:

```text
Add worker nodes
```

Workload scaling decisions should eventually be based on observed metrics.

## 7. Lab Constraint

This sizing is intended for the home laboratory.

It is not a production capacity recommendation.

Future sizing should be based on actual CPU, memory, disk, Pod density, and control plane metrics.
