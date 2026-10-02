# Kubernetes Worker Topology

## 1. Objective

Define the topology of the initial Kubernetes worker nodes.

## 2. Initial Topology

The cluster starts with two worker nodes:

```text
                  Kubernetes Cluster
                         |
              +----------+----------+
              |                     |
              v                     v
       +-------------+       +-------------+
       | worker-01   |       | worker-02   |
       | 192.168.0.131|      | 192.168.0.132|
       +-------------+       +-------------+
```

## 3. Worker 01

| Attribute | Value |
|---|---|
| Hostname | `k8s-worker-01` |
| IP | `192.168.0.131` |
| Role | Worker |
| Runtime | containerd |

## 4. Worker 02

| Attribute | Value |
|---|---|
| Hostname | `k8s-worker-02` |
| IP | `192.168.0.132` |
| Role | Worker |
| Runtime | containerd |

## 5. Responsibilities

Workers are responsible for running Kubernetes workloads, including:

- application Pods;
- platform workloads;
- DaemonSets;
- supporting services.

## 6. Scaling

Additional workers can be added without changing the fundamental cluster architecture.

```text
worker-01
worker-02
worker-03
worker-04
...
```

Worker provisioning will be automated with OpenTofu and Ansible.
