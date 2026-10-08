# Kubernetes Worker Role

## Objetivo

A role `kubernetes/worker` configura um node worker para ingressar em um cluster Kubernetes existente utilizando `kubeadm join`.

A role foi criada como parte da Issue #33 do projeto `enterprise-platform-lab`.

---

## Contexto

O cluster Kubernetes utiliza:

- Kubernetes `v1.37.1`
- Debian 13
- containerd
- kubeadm
- kubelet
- kubectl
- Cilium como CNI

A preparação dos nodes é realizada pelas roles:

- `base/linux`
- `kubernetes/common`
- `kubernetes/containerd`
- `kubernetes/packages`

O bootstrap do control plane é responsabilidade da role:

- `kubernetes/control_plane`

O ingresso dos workers é responsabilidade desta role.

---

## Arquitetura

```text
                    Kubernetes Control Plane
                    k8s-cp-01
                    192.168.0.130
                         │
                         │ kubeadm token
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