# Kubernetes Resource Sizing

## 1. Objective

Define the initial compute and storage allocation for Kubernetes virtual machines.

## 2. Initial Sizing

| Node | vCPU | RAM | Disk |
|---|---:|---:|---:|
| `k8s-cp-01` | 4 | 6 GiB | 40 GiB |
| `k8s-worker-01` | 2 | 4 GiB | 40 GiB |
| `k8s-worker-02` | 2 | 4 GiB | 40 GiB |
| **Total** | **8** | **14 GiB** | **120 GiB** |

## 3. Control Plane

Initial allocation:

```text
4 vCPU
6 GiB RAM
40 GiB disk
```

The additional resources account for control plane components and etcd.

## 4. Workers

Each worker receives:

```text
2 vCPU
4 GiB RAM
40 GiB disk
```

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
