# Kubernetes Future High Availability Strategy

## 1. Objective

Define the planned evolution from the initial single-control-plane cluster to a highly available Kubernetes control plane.

## 2. Current State

The initial topology is:

```text
1 Control Plane
2 Workers
```

The control plane contains local etcd.

The cluster was initialized without `controlPlaneEndpoint`; the API is reached at `https://192.168.0.130:6443`.

## 3. Current Limitation

The initial control plane is a single point of failure.

If `k8s-cp-01` becomes unavailable, the Kubernetes API and control plane components are unavailable.

## 4. Future Architecture

The planned HA topology is:

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

## 5. Stacked etcd

The planned topology uses stacked etcd:

```text
Control Plane
    +
  etcd
```

Each control plane hosts its own etcd member.

## 6. Control Plane Endpoint

The logical endpoint remains:

```text
k8s-api.home.arpa
```

In the HA architecture:

```text
k8s-api.home.arpa
        |
        v
Load Balancer
        |
   +----+----+
   |    |    |
 cp-01 cp-02 cp-03
```

## 7. Load Balancer

The Load Balancer must forward Kubernetes API traffic to:

```text
TCP 6443
```

The specific implementation will be selected when HA is implemented.

## 8. Control Plane Count

The future topology will use three control planes.

The odd number supports etcd quorum behavior.

## 9. Additional Requirements

HA implementation will require:

- three control plane VMs;
- a `controlPlaneEndpoint` (kubeadm only allows joining more control planes when it was set at `kubeadm init`; the current cluster will need to be re-initialized or migrated);
- API load balancing;
- stable DNS;
- etcd backup strategy;
- failure testing;
- recovery procedures;
- additional compute resources.

## 10. Scope

HA is not part of the initial Kubernetes bootstrap.

It is a planned future architecture and will be implemented as a separate change.
