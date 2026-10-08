# Kubernetes CNI — Cilium

## Objective

Configure **Cilium** as the Container Network Interface (CNI) of the Kubernetes cluster provisioned by the lab.

The role is responsible for:

- ensuring Helm is installed;
- validating the Helm version;
- installing or upgrading Cilium;
- configuring the Cilium Operator;
- keeping the configuration compatible with the lab topology;
- keeping the installation idempotent;
- letting Ansible reconcile the Cilium state.

The role runs on the `control_plane` group in `playbooks/kubernetes.yml`, after `kubernetes/worker` and before `kubernetes/dns`. It was created for Issue #32.

---

# Context

The Kubernetes cluster uses:

- Debian 13;
- Kubernetes `v1.37.1`;
- containerd `1.7.24`;
- Cilium `1.20.2`;
- Helm `4.3.0`.

Current topology:

```text
                    Kubernetes Cluster
                           │
          ┌────────────────┼────────────────┐
          │                │                │
      k8s-cp-01       k8s-worker-01    k8s-worker-02
     192.168.0.130     192.168.0.131    192.168.0.132
          │                │                │
          └────────────────┼────────────────┘
                           │
                         Cilium
                           │
              ┌────────────┴────────────┐
              │                         │
        Cilium Agent               Cilium Operator
          DaemonSet                   Deployment
              │                         │
           3 nodes                   2 replicas
```

---

# Why Cilium?

Cilium is the cluster CNI and provides network connectivity between Pods and Kubernetes nodes.

Beyond the basic CNI function, Cilium provides additional networking, security and observability features.

In the lab, it allows later evolution towards:

- NetworkPolicy;
- network observability;
- Hubble Relay and UI;
- traffic control;
- identity-based policies;
- advanced networking features.

The choice also keeps the lab close to modern Kubernetes architectures used in professional environments. The decision is recorded in ADR-0002 and `docs/architecture/kubernetes/cni-decision.md`.

---

# Architecture

The cluster networking roughly follows:

```text
                    Kubernetes API
                          │
                          │
                   Cilium Operator
                    ┌─────┴─────┐
                    │           │
                Operator     Operator
                  Pod           Pod
                    │           │
                    └─────┬─────┘
                          │
                    Cilium Agents
                    DaemonSet
                          │
             ┌────────────┼────────────┐
             │            │            │
          cp-01        worker-01    worker-02
             │            │            │
             └────────────┴────────────┘
```

Each node runs a Cilium Agent as part of a DaemonSet.

The Cilium Operator runs as a Deployment with two replicas (chart default).

---

# Components

## Helm

Helm is used to install and manage Cilium.

Version:

```text
Helm 4.3.0
```

The role runs `helm version --short`. If Helm is missing or the version differs, it downloads the official installer `https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4`, runs it with `--version v4.3.0`, removes it, and asserts the installed version.

---

## Cilium

Version:

```text
Cilium 1.20.2
```

Chart:

```text
oci://quay.io/cilium/charts/cilium
```

The version is pinned to avoid unexpected upgrades.

---

## Cilium Operator

The Operator runs Cilium control functions that do not need to run on every node.

The lab uses the chart default:

```text
2 replicas
```

The replicas are spread across the cluster nodes by the chart affinity rules.

---

# Configuration

The main variables are in:

```text
defaults/main.yml
```

Current configuration:

```yaml
helm_version: "4.3.0"

cilium_version: "1.20.2"

cilium_namespace: kube-system

cilium_release_name: cilium

cilium_chart: oci://quay.io/cilium/charts/cilium

cilium_kubeconfig: /etc/kubernetes/admin.conf

cilium_operator_host_network: false

cilium_operator_api_serve_addr: ":9234"
```

The Helm command run by the role is:

```bash
helm upgrade --install cilium oci://quay.io/cilium/charts/cilium \
  --version 1.20.2 \
  --namespace kube-system \
  --kubeconfig /etc/kubernetes/admin.conf \
  --set operator.hostNetwork=false \
  --set-string operator.extraArgs[0]=--operator-api-serve-addr=:9234 \
  --wait
```

All other values use the chart defaults. In particular:

| Setting | Value |
|---|---|
| kube-proxy replacement | not enabled (kube-proxy is kept) |
| IPAM | Cilium cluster-pool (chart default `10.0.0.0/8`, one `/24` per node) |
| Hubble | enabled by default; Relay and UI not deployed |

No Pod CIDR is passed to `kubeadm init`, so the Pod addresses come from the Cilium IPAM settings above. The planned `10.244.0.0/16` from ADR-0002 is not applied.

Effective Pod CIDRs (verified 2026-10-08):

```bash
kubectl get ciliumnodes \
  -o custom-columns=NODE:.metadata.name,PODCIDRS:.spec.ipam.podCIDRs
```

```text
NODE            PODCIDRS
k8s-cp-01       [10.0.0.0/24]
k8s-worker-01   [10.0.2.0/24]
k8s-worker-02   [10.0.1.0/24]
```

---

# Cilium Operator and hostNetwork

The Operator uses:

```yaml
cilium_operator_host_network: false
```

This means the Operator uses the Pod network.

This matters because the cluster has multiple nodes and two Operator replicas.

With `hostNetwork=true`, the process would use the node network directly.

That could cause port conflicts when multiple replicas run on the same node.

---

# Operator API

The Operator exposes an API used by the health probes.

The configuration is:

```yaml
cilium_operator_api_serve_addr: ":9234"
```

The argument applied to the container is:

```text
--operator-api-serve-addr=:9234
```

## Why is this needed?

With:

```yaml
operator.hostNetwork: false
```

the Operator uses the Pod network namespace.

Kubernetes runs the probes against the Pod address.

Initially the Operator listened only on:

```text
127.0.0.1:9234
```

The process was working, but the probe targeted the Pod IP:

```text
Pod IP:9234
```

The result was:

```text
connection refused
```

The Operator kept restarting and stayed in:

```text
CrashLoopBackOff
```

The setting:

```text
--operator-api-serve-addr=:9234
```

makes the process listen on the Pod interface, so the probes work.

---

# containerd and CNI

Cilium installs the CNI binary:

```text
/opt/cni/bin/cilium-cni
```

containerd must look for CNI binaries in the same directory.

The lab therefore uses:

```text
/opt/cni/bin
```

Configuration (in the `kubernetes/containerd` role):

```yaml
containerd_cni_bin_dir: /opt/cni/bin
```

containerd is configured with:

```text
bin_dir = "/opt/cni/bin"
```

This setting is required for the runtime to execute the Cilium CNI.

---

# Problem Found

During the initial installation, containerd was looking for CNI plugins in:

```text
/usr/lib/cni
```

While Cilium installed:

```text
/opt/cni/bin/cilium-cni
```

The result was the error:

```text
failed to find plugin "cilium-cni" in path [/usr/lib/cni]
```

As a consequence, Pods such as CoreDNS stayed in:

```text
ContainerCreating
```

The solution was to configure containerd to use:

```text
/opt/cni/bin
```

This setting was added to the containerd role so the state does not depend on manual configuration.

---

# Idempotency

The role avoids running `helm upgrade` unnecessarily.

Before changing Cilium, Ansible queries the release:

```text
helm list
```

Then it reads the values:

```text
helm get values
```

The current state is compared with the desired state.

The comparison covers:

- whether the release exists;
- the chart version;
- `operator.hostNetwork`;
- `operator.extraArgs`.

Flow:

```text
                 Ansible
                    │
                    ▼
              helm list
                    │
             Release exists?
              │           │
             no          yes
              │           │
              │      helm get values
              │           │
              │      compare state
              │           │
              └──────┬────┘
                     │
              State differs?
                 │          │
                yes         no
                 │          │
            helm upgrade   skip
```

---

# Idempotency Validation

After the implementation, the playbook was run again without changing the cluster.

Result:

```text
TASK [kubernetes/cni : Check if Cilium Helm release exists]
ok: [k8s-cp-01]

TASK [kubernetes/cni : Read Cilium Helm release values]
ok: [k8s-cp-01]

TASK [kubernetes/cni : Determine Cilium release state]
ok: [k8s-cp-01]

TASK [kubernetes/cni : Install or upgrade Cilium CNI]
skipping: [k8s-cp-01]
```

Final result:

```text
k8s-cp-01      changed=0 failed=0
k8s-worker-01  changed=0 failed=0
k8s-worker-02  changed=0 failed=0
```

This confirms the role can run again without changes when the desired state is already applied.

---

# Cluster Validation

The automated checks are in the `kubernetes/validation` role (`playbooks/kubernetes-validation.yml`). The manual commands below are useful for troubleshooting.

## Nodes

```bash
kubectl get nodes -o wide
```

Expected:

```text
NAME            STATUS   ROLES           VERSION
k8s-cp-01       Ready    control-plane   v1.37.1
k8s-worker-01   Ready    <none>          v1.37.1
k8s-worker-02   Ready    <none>          v1.37.1
```

---

## Pods

```bash
kubectl get pods -A -o wide
```

All `kube-system` components must be healthy.

---

## Cilium Operator

```bash
kubectl -n kube-system get deployment cilium-operator
```

Expected:

```text
NAME              READY   UP-TO-DATE   AVAILABLE
cilium-operator   2/2     2            2
```

---

## Cilium Agents

```bash
kubectl -n kube-system get pods \
  -l k8s-app=cilium \
  -o wide
```

There must be one Cilium Agent per node.

---

## Cilium status

```bash
kubectl -n kube-system exec ds/cilium -- cilium status
```

Key indicators:

```text
Kubernetes:       Ok
Cilium:           Ok
Cilium health:    Ok
Controller Status: healthy
Proxy Status:     OK
Hubble:           Ok
Cluster health:   3/3 reachable
```

---

# Troubleshooting

## Cilium Operator in CrashLoopBackOff

Check:

```bash
kubectl -n kube-system get pods \
  -l io.cilium/app=operator \
  -o wide
```

Logs:

```bash
kubectl -n kube-system logs \
  -l io.cilium/app=operator \
  --tail=100
```

Check the argument:

```bash
kubectl -n kube-system get deployment cilium-operator \
  -o jsonpath='{.spec.template.spec.containers[0].args}' \
  | tr ' ' '\n' \
  | grep operator-api
```

Expected:

```text
--operator-api-serve-addr=:9234
```

---

## Cilium Operator is not Ready

Check:

```bash
kubectl -n kube-system describe deployment cilium-operator
```

And:

```bash
kubectl -n kube-system get events \
  --sort-by=.lastTimestamp
```

Check that the Operator uses:

```yaml
operator.hostNetwork: false
```

---

## Error `failed to find plugin cilium-cni`

Check:

```bash
ls -l /opt/cni/bin/cilium-cni
```

Check the containerd configuration:

```bash
containerd config dump | grep -A6 -B2 'bin_dir'
```

Expected:

```text
bin_dir = "/opt/cni/bin"
```

---

## CoreDNS in ContainerCreating

Check:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
```

If it is in `ContainerCreating`, check the events:

```bash
kubectl -n kube-system describe pod <pod>
```

Also check the CNI:

```bash
ls -l /opt/cni/bin/
```

---

# Role Files

Structure:

```text
ansible/roles/kubernetes/cni/
├── README.md
├── defaults/
│   └── main.yml
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
```

---

# Execution

The role runs through the Kubernetes playbook:

```bash
cd ansible
ansible-playbook playbooks/kubernetes.yml
```

---

# Architecture Decisions

| Decision | Choice | Reason |
|---|---|---|
| CNI | Cilium | Modern networking and advanced features |
| Cilium version | 1.20.2 | Pinned for reproducibility |
| Helm | 4.3.0 | Pinned |
| Operator replicas | 2 (chart default) | Availability and distribution |
| Operator hostNetwork | false | Avoid dependency on the host network |
| Operator API | `:9234` | Allow probes through the Pod network |
| CNI bin directory | `/opt/cni/bin` | Compatibility with the binary installed by Cilium |
| kube-proxy | kept | kube-proxy replacement deferred (ADR-0002) |
| IPAM | chart default cluster-pool | No Pod CIDR configured |
| Deployment | Ansible + Helm | IaC and declarative management |
| Namespace | `kube-system` | Cluster infrastructure components |

---

# Compatibility

The lab uses:

```text
Kubernetes 1.37.1
Cilium 1.20.2
```

This combination is a lab-specific decision.

The Cilium version is pinned for reproducibility and to avoid automatic upgrades.

Before upgrading either version, check the official Kubernetes and Cilium compatibility matrix.

---

# Security

The role uses the kubeconfig:

```text
/etc/kubernetes/admin.conf
```

This file has administrative privileges over the cluster.

Therefore:

- it must not be versioned;
- it must not be copied to Git;
- its permissions must stay restricted;
- cluster credentials must not be stored in the repository.

The Helm installer script is downloaded from the `main` branch of the Helm repository at run time; the installed Helm version is pinned and asserted afterwards.

---

# Practices Applied

- pinned versions;
- declarative configuration;
- idempotency;
- prerequisite validation;
- post-installation validation;
- separation between defaults and tasks;
- documented troubleshooting;
- no credentials in Git;
- reproducible configuration;
- Ansible integration;
- Cilium managed through Helm.

---

# Portfolio

This component demonstrates knowledge of:

- Kubernetes;
- CNI;
- Cilium;
- Helm;
- Ansible;
- containerd;
- Linux networking;
- Kubernetes troubleshooting;
- IaC;
- idempotency;
- network observability;
- cluster architecture.

The troubleshooting done during the implementation also shows the ability to diagnose problems across infrastructure layers:

```text
Kubernetes
    │
    ├── CNI
    │
    ├── Cilium
    │
    ├── containerd
    │
    ├── Linux
    │
    └── Networking
```

---

# Next Steps

Planned evolution:

1. Validate Pod-to-Pod connectivity in the `kubernetes/validation` role;
2. Validate Pod-to-Service connectivity in the `kubernetes/validation` role;
3. Implement NetworkPolicies;
4. Deploy Hubble Relay and UI;
5. Integrate Cilium metrics with Prometheus;
6. Integrate dashboards with Grafana;
7. Evaluate kube-proxy replacement and other advanced Cilium features;
8. Automate network tests in CI.

Internal DNS validation (Issue #34/#35) is done.

---

# References

- Cilium Documentation
- Kubernetes Documentation
- Helm Documentation
- containerd Documentation
- Ansible Documentation
