# Kubernetes Platform Runbook

## Purpose

Provision, configure, validate, and perform first-line diagnosis of the lab Kubernetes cluster. The documented topology has one control plane and two workers; it is not highly available.

## Prerequisites

- Access to the Proxmox VE host (`pve`, `192.168.0.120`) and its API.
- Debian 13 Cloud-Init template ID `9000`, `kubernetes-pool`, `vmdata`, and bridge `vmbr0` available in Proxmox.
- OpenTofu provider credentials supplied locally, and the SSH key expected by the VM configuration.
- DHCP reservations for the Kubernetes VM MAC addresses matching `ansible/inventories/lab/hosts.ini`, or inventory addresses updated to match DHCP.
- Ansible with the collections `community.general` and `kubernetes.core`, SSH access as `debian`, and network access to package/chart registries. This checkout does not currently include an Ansible collections requirements file.
- `home.arpa` records in Pi-hole for `k8s-cp-01` (`192.168.0.130`), `k8s-worker-01` (`.131`) and `k8s-worker-02` (`.132`). They are created manually today, and the validation playbook fails without `k8s-cp-01.home.arpa`.
- A local `terraform.tfvars` in `kubernetes/opentofu/`; do not commit it or any secret values.

Before applying changes, review [the architecture and known gaps](../architecture/kubernetes/platform.md), especially node IPs, pod CIDR, and DNS upstream behavior.

## Provision and Configure

1. If the shared Proxmox foundation is not already present, initialize and review `infrastructure/proxmox/` separately. Do not destroy shared pools, storage, or networking to recreate Kubernetes VMs.
2. Configure the Kubernetes VM variables locally from `kubernetes/opentofu/terraform.tfvars.example`. Confirm the template, node, pool, storage, MAC addresses, and address reservations.
3. Plan and apply the VM root only after review:

   ```sh
   cd kubernetes/opentofu
   tofu init
   tofu fmt -check
   tofu validate
   tofu plan
   tofu apply
   ```

4. Confirm the VM addresses in Proxmox or DHCP and ensure they match `ansible/inventories/lab/hosts.ini`. Confirm SSH connectivity before running configuration management.
5. From `ansible/`, check connectivity and syntax:

   ```sh
   ansible -i inventories/lab/hosts.ini kubernetes -m ping
   ansible-playbook -i inventories/lab/hosts.ini playbooks/kubernetes.yml --syntax-check
   ```

6. Apply the cluster configuration:

   ```sh
   ansible-playbook -i inventories/lab/hosts.ini playbooks/kubernetes.yml
   ```

7. Run the full validation playbook:

   ```sh
   ansible-playbook -i inventories/lab/hosts.ini playbooks/kubernetes-validation.yml
   ```

8. Record the result and any approved deviations. Do not publish kubeconfigs, private keys, API credentials, or kubeadm join tokens.

The Linux baseline playbook is separate and targets Raspberry Pi hosts:

```sh
cd ansible
ansible-playbook -i inventories/lab/hosts.ini playbooks/bootstrap.yml --syntax-check
ansible-playbook -i inventories/lab/hosts.ini playbooks/bootstrap.yml
```

## Health Checks

Run on the control plane using its administrator kubeconfig:

```sh
kubectl get nodes -o wide
kubectl get pods -A
kubectl -n kube-system get pods -o wide
kubectl -n kube-system exec ds/cilium -- cilium status
kubectl -n kube-system get configmap coredns -o yaml
```

Expected results: all three nodes are `Ready`; the Cilium status is healthy; CoreDNS pods are ready; and the validation playbook's internal, `home.arpa`, and external DNS tests pass. The validation role creates and cleans up a temporary `dns-validation` pod.

Network state checks:

```sh
kubectl get ciliumnodes -o custom-columns=NODE:.metadata.name,PODCIDRS:.spec.ipam.podCIDRs
sudo grep "service-cluster-ip-range" /etc/kubernetes/manifests/kube-apiserver.yaml
kubectl -n kube-system get service kube-dns -o jsonpath='{.spec.clusterIP}'
```

Expected (verified 2026-10-08):

```text
NODE            PODCIDRS
k8s-cp-01       [10.0.0.0/24]
k8s-worker-01   [10.0.2.0/24]
k8s-worker-02   [10.0.1.0/24]

--service-cluster-ip-range=10.96.0.0/12

10.96.0.10
```

These are the effective runtime values. The ADR-0002 targets (`10.244.0.0/16` for Pods, `10.96.0.0/16` for Services) are not deployed; see [the architecture](../architecture/kubernetes/platform.md#target-configuration-and-runtime-state).

## Troubleshooting

| Symptom | Checks | Recovery direction |
| --- | --- | --- |
| Ansible cannot connect | Compare DHCP/Proxmox addresses with `hosts.ini`; check SSH as `debian`, key, route, and host reachability. | Correct the DHCP reservation or inventory address, then rerun `ansible ... -m ping`. |
| OpenTofu plan cannot find a resource/provider | Check local variables, provider credentials, Proxmox API reachability, provider lock file, template ID, pool, datastore, and bridge. | Fix local configuration and rerun `tofu init`, `tofu validate`, and `tofu plan`; review the complete plan before apply. |
| Node remains `NotReady` | Run `kubectl describe node <node>` and inspect `systemctl status kubelet containerd` and `journalctl -u kubelet -u containerd`. | Resolve runtime, kubelet, time sync, or CNI issues on the affected host; rerun validation. |
| Cilium is not healthy | Check `kubectl -n kube-system get pods -o wide`, `kubectl -n kube-system describe pod <cilium-pod>`, and `kubectl -n kube-system logs ds/cilium`. | Verify kernel prerequisites, CNI files (`/opt/cni/bin/cilium-cni` and containerd `bin_dir`), node connectivity, and actual pod IP allocation with `kubectl get ciliumnodes`. Pods use Cilium cluster-pool `/24` ranges from `10.0.0.0/8`, not the ADR target `10.244.0.0/16`. |
| Internal DNS lookup fails | Inspect CoreDNS pods and ConfigMap; test `kubernetes.default.svc.cluster.local` from a pod. | Restore CoreDNS readiness/configuration, then rerun the validation playbook. |
| `*.home.arpa` lookup fails | Test reachability to `192.168.0.111:53` from the cluster and inspect the CoreDNS `home.arpa` forward block and Pi-hole service. | Restore Pi-hole and edge DNS reachability; verify the expected record exists. |
| External DNS lookup fails | Inspect the CoreDNS pod's `/etc/resolv.conf`, its forwarder, Pi-hole upstream `192.168.0.110#5335`, and Unbound access control/listeners. | Restore the configured upstream chain. Remember that general CoreDNS queries use `/etc/resolv.conf`, not the `home.arpa` forward rule. |
| Worker is absent from the cluster | Check kubelet logs, `/etc/kubernetes/kubelet.conf`, control-plane reachability, and whether kubeadm join completed. | Reconcile the node's join state through approved kubeadm operations; never paste join tokens into shared logs or tickets. |

For all incidents, capture sanitized command output, node name, timestamp, and the failing validation assertion. Redact IP-independent secrets, tokens, private key material, and kubeconfig credentials before sharing.

## Change and Recovery Safety

- Prefer rerunning the idempotent Ansible playbooks after correcting the source configuration.
- Review OpenTofu plans before any apply or destroy. Never use a broad destroy as a cluster recovery shortcut.
- Preserve the Proxmox foundation and other workloads when replacing Kubernetes VMs.
- Back up cluster state and application data before disruptive maintenance; this repository does not currently define an etcd or workload backup procedure.
- Revalidate all nodes, Cilium, and DNS after any infrastructure, runtime, CNI, or resolver change.
