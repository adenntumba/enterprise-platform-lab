# Kubernetes Control Plane Topology

## 1. Objective

Define the topology and responsibilities of the initial Kubernetes control plane.

## 2. Initial Topology

The initial cluster contains one control plane:

```text
+--------------------------------+
|          k8s-cp-01             |
|          192.168.0.130         |
|                                |
|  kube-apiserver                |
|  kube-controller-manager       |
|  kube-scheduler                |
|  etcd                          |
|                                |
+--------------------------------+
```

## 3. Node Specification

| Attribute | Value |
|---|---|
| Hostname | `k8s-cp-01` |
| IP | `192.168.0.130` |
| Role | Control Plane |
| Runtime | containerd |
| Bootstrap | kubeadm |
| etcd | Local / stacked |

## 4. Control Plane Components

The control plane contains:

- kube-apiserver;
- kube-controller-manager;
- kube-scheduler;
- etcd.

## 5. Kubernetes API

The Kubernetes API is exposed through:

```text
TCP 6443
```

The current endpoint is:

```text
https://192.168.0.130:6443
```

Planned (not implemented): the logical endpoint `k8s-api.home.arpa -> 192.168.0.130`.

## 6. Availability

The initial control plane is not highly available.

Failure of `k8s-cp-01` affects the Kubernetes API, etcd, scheduler, and controllers.

## 7. Future Topology

The future HA architecture is expected to use three control planes:

```text
                    k8s-api.home.arpa
                           |
                           v
                    +-------------+
                    | Load Balancer|
                    +-------------+
                      |    |    |
                      v    v    v
                    cp-01 cp-02 cp-03
                    etcd  etcd  etcd
```

The HA architecture is documented separately.
