# 🚀 Enterprise Platform Lab

> **An Enterprise-grade Platform Engineering Lab built from the ground up using Proxmox, Kubernetes, GitOps, Infrastructure as Code, DevSecOps and Observability.**

![Status](https://img.shields.io/badge/Status-In%20Development-blue)
![Platform](https://img.shields.io/badge/Platform-Engineering-success)
![IaC](https://img.shields.io/badge/IaC-OpenTofu-purple)
![Automation](https://img.shields.io/badge/Automation-Ansible-red)
![Kubernetes](https://img.shields.io/badge/Kubernetes-v1.37%20(kubeadm)-326CE5)
![CNI](https://img.shields.io/badge/CNI-Cilium-F8C517)
![License](https://img.shields.io/badge/License-MIT-green)

---

# Enterprise Platform Lab

Enterprise Platform Lab is a long-term Platform Engineering project that reproduces how modern companies design, automate and operate enterprise infrastructure.

Rather than simply deploying technologies, this project focuses on **engineering practices**, **architecture decisions**, **automation**, **documentation** and **operational excellence**.

Every component of the platform is built incrementally, fully documented and reproducible.

The ultimate goal is to create an enterprise-grade home lab that anyone can reproduce using compatible hardware.

---

# Vision

Build a complete Platform Engineering ecosystem where infrastructure, Kubernetes, GitOps, automation, observability, security and cloud-native services work together exactly as they would inside a modern technology company.

---

# Objectives

- Build an enterprise-grade home lab
- Apply Infrastructure as Code from day one
- Automate infrastructure provisioning
- Implement GitOps workflows
- Adopt Platform Engineering best practices
- Build a production-inspired Kubernetes platform
- Implement enterprise observability
- Apply DevSecOps principles
- Simulate AWS services locally using LocalStack
- Produce high-quality technical documentation
- Make the entire platform reproducible

---

# Target Architecture

```text
                                         Enterprise Platform Lab

┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                            Edge Layer                                                      │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                            │
│   Internet                                                                           Remote Access         │
│      │                                                                                 (Tailscale)         │
│      ▼                                                                                     │               │
│  ISP / ONU                                                                                 │               │
│      │                                                                                     │               │
│      ▼                                                                                     │               │
│  TP-Link Router ───────────────────────────────────────────────────────────────────────────┘               │
│      │                                                                                                     │
│      ▼                                                                                                     │
│  Raspberry Pi Cluster                                                                                      │
│      │                                                                                                     │
│      ├──────────── dns-01  (192.168.0.110) ── Unbound (recursive DNS :5335)                                │
│      ├──────────── node-01 (192.168.0.111) ── Pi-hole (LAN DNS :53)                                        │
│      └──────────── node-02 (192.168.0.112) ── Reserved                                                     │
│                                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                      Virtualization Layer                                                  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                            │
│                                            Proxmox VE                                                      │
│                                                                                                            │
│       ┌──────────────────────────────┬──────────────────────────────┬──────────────────────────────┐       │
│       │                              │                              │                              │       │
│       ▼                              ▼                              ▼                              ▼       │
│ Management VM              Kubernetes Cluster                   Storage VM                    Future VMs   │
│                                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                         Platform Layer                                                     │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                            │
│ GitOps                  Observability              Security                 Platform Services              │
│                                                                                                            │
│ • ArgoCD                • Prometheus              • Vault                  • Harbor                        │
│ • Helm                  • Grafana                 • External Secrets       • PostgreSQL                    │
│ • Kustomize             • Loki                    • Kyverno                • Redis                         │
│ • Applications          • Tempo                   • Trivy                  • RabbitMQ                      │
│                         • OpenTelemetry                                    • MinIO                         │
│                                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             Automation & Infrastructure as Code                                            │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                            │
│              OpenTofu • Terraform • Ansible • GitHub Actions • GitHub MCP                                  │
│                                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                                   │
                                                   ▼
┌────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    Cloud Simulation Layer                                                  │
├────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                            │
│                    LocalStack (AWS Services Simulation)                                                    │
│                                                                                                            │
│        S3 • IAM • Lambda • SQS • SNS • DynamoDB • Secrets Manager • CloudWatch                             │
│                                                                                                            │
└────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

# Platform Layers

## Edge Layer

Responsible for network services located at the edge of the infrastructure.

Implemented today (Sprint 01):

- Pi-hole on `node-01` (`192.168.0.111`) — LAN DNS and filtering
- Unbound on `dns-01` (`192.168.0.110`, port `5335`) — recursive DNS
- Local DNS zone `home.arpa` (records currently created manually in Pi-hole)

DHCP and gateway remain on the TP-Link Archer C80 router.

Planned: VPN / remote access (Tailscale).

---

## Virtualization Layer

Proxmox VE (`pve`, `192.168.0.120`) hosts the lab virtual machines.

Implemented today (Sprint 02):

- VM pool `kubernetes-pool`, managed by OpenTofu (`infrastructure/proxmox`)
- Three Debian 13 Kubernetes VMs cloned from a Cloud-Init template, managed by OpenTofu (`kubernetes/opentofu`)

---

## Platform Layer

Implemented today (Sprint 02): an upstream Kubernetes cluster bootstrapped with kubeadm.

| Node | IP | Role |
|---|---|---|
| `k8s-cp-01` | `192.168.0.130` | Control plane (stacked etcd) |
| `k8s-worker-01` | `192.168.0.131` | Worker |
| `k8s-worker-02` | `192.168.0.132` | Worker |

- Kubernetes `v1.37.1` (kubeadm, kubelet, kubectl from `pkgs.k8s.io`)
- containerd `1.7.24` (Debian package, systemd cgroup driver)
- Cilium `1.20.2` deployed with Helm `4.3.0`, kube-proxy kept
- CoreDNS with conditional forwarding of `home.arpa` to Pi-hole

Planned for later Sprints: platform services, observability, security and PKI, storage, GitOps, applications.

---

## Automation Layer

Provisioning and configuration are automated with OpenTofu and Ansible.

GitOps and CI pipelines are planned (see [ADR-0001](docs/adr/ADR-0001-engineering-quality-platform.md)); there are no GitHub Actions workflows yet.

---

## Cloud Simulation Layer (planned)

LocalStack will provide a local implementation of AWS services, enabling cloud-native development without requiring an AWS account for every scenario.

---

# Technology Stack

## In use today

| Area | Technology |
|---|---|
| Edge hardware | Raspberry Pi (Raspberry Pi OS, Debian 13 based, `aarch64`) |
| Virtualization | Proxmox VE |
| VM operating system | Debian 13 (Cloud-Init template) |
| Infrastructure as Code | OpenTofu with the `bpg/proxmox` provider (`~> 0.114.0`) |
| Configuration management | Ansible (collections `community.general`, `kubernetes.core`) |
| DNS | Pi-hole, Unbound, CoreDNS |
| Container runtime | containerd |
| Kubernetes | Upstream Kubernetes with kubeadm |
| CNI | Cilium |
| Package management | Helm |

## Planned

| Area | Technology |
|---|---|
| GitOps | ArgoCD, Kustomize |
| Ingress | NGINX or Traefik, Gateway API |
| Observability | Prometheus, Grafana, Loki, Tempo, OpenTelemetry |
| Security | Vault, External Secrets Operator, Kyverno, Trivy, internal PKI |
| Storage | MinIO, CSI storage |
| Data and messaging | PostgreSQL, Redis, RabbitMQ |
| Registry | Harbor |
| Cloud simulation | LocalStack, AWS CLI |
| CI | GitHub Actions, pre-commit |

---

# Repository Structure

```text
enterprise-platform-lab
│
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/              # empty — CI not implemented yet
├── ai/
│   └── prompts/                # prompts used to generate GitHub planning artifacts
├── ansible/
│   ├── ansible.cfg
│   ├── inventories/lab/        # hosts.ini + group_vars
│   ├── playbooks/              # bootstrap, pihole, unbound, kubernetes, kubernetes-validation
│   └── roles/
│       ├── base/               # linux, raspberry
│       ├── pihole/
│       ├── unbound/
│       └── kubernetes/         # common, containerd, packages, control_plane,
│                               # worker, cni, dns, validation
├── docs/
│   ├── adr/                    # Architecture Decision Records
│   ├── architecture/kubernetes/
│   ├── backlog/                # Sprint and Epic documents
│   ├── diagrams/
│   ├── PROJECT_BACKLOG.md
│   ├── PROJECT_CHARTER.md
│   └── ROADMAP.md
├── infrastructure/
│   └── proxmox/                # OpenTofu: shared Proxmox resources (VM pools)
├── kubernetes/
│   └── opentofu/               # OpenTofu: Kubernetes VMs
├── .env.example
├── LICENSE
└── README.md
```

---

# Documentation

| Document | Description |
|----------|-------------|
| [docs/PROJECT_CHARTER.md](docs/PROJECT_CHARTER.md) | Vision, mission and engineering principles |
| [docs/PROJECT_BACKLOG.md](docs/PROJECT_BACKLOG.md) | Project backlog (Single Source of Truth) |
| [docs/ROADMAP.md](docs/ROADMAP.md) | High-level implementation roadmap |
| [docs/backlog](docs/backlog) | Sprint and Epic planning |
| [docs/adr](docs/adr) | Architecture Decision Records |
| [docs/architecture/kubernetes](docs/architecture/kubernetes) | Kubernetes architecture documentation |
| [docs/diagrams](docs/diagrams) | Architecture diagrams |
| [infrastructure/proxmox/README.md](infrastructure/proxmox/README.md) | Proxmox foundation (OpenTofu) |
| [kubernetes/opentofu/README.md](kubernetes/opentofu/README.md) | Kubernetes VM provisioning (OpenTofu) |
| `ansible/roles/**/README.md` | One README per Ansible role |

---

# Project Roadmap

The project evolves incrementally through sequential Sprints. See [ROADMAP.md](docs/ROADMAP.md) for details.

| Sprint | Name | Status |
|---------|------|--------|
| Sprint 00 | Foundation | ✅ Completed |
| Sprint 01 | Edge DNS Platform | ✅ Completed |
| Sprint 02 | Kubernetes Platform Foundation | ✅ Completed |
| Sprint 03 | Kubernetes Platform Services | ⏳ Planned |
| Sprint 04 | Observability Platform | ⏳ Planned |
| Sprint 05 | Security & PKI | ⏳ Planned |
| Sprint 06 | Storage Platform | ⏳ Planned |
| Sprint 07 | GitOps Platform | ⏳ Planned |
| Sprint 08 | Platform Applications | ⏳ Planned |
| Sprint 09 | Hybrid Cloud | ⏳ Planned |
| Sprint 10 | Chaos Engineering | ⏳ Planned |

The [Engineering Quality Platform](docs/backlog/Epic-Engineering-Quality-Platform.md) Epic (CI, pre-commit, linting) is accepted but not started.

---

# Engineering Principles

- Documentation First
- Automation First
- Infrastructure as Code
- GitOps
- Security by Design
- Small Iterations
- Enterprise Mindset
- Reproducibility

---

# Getting Started

The project is intentionally built in small, reproducible iterations.

Follow the documentation and sprint backlog to recreate the platform step by step.

The current build order is:

```bash
# 1. Edge DNS (Raspberry Pi)
cd ansible
ansible-playbook playbooks/bootstrap.yml
ansible-playbook playbooks/unbound.yml
ansible-playbook playbooks/pihole.yml

# 2. Proxmox foundation and Kubernetes VMs (OpenTofu)
#    Export PROXMOX_VE_ENDPOINT / PROXMOX_VE_API_TOKEN (see .env.example)
cd ../infrastructure/proxmox && tofu init && tofu apply
cd ../../kubernetes/opentofu && cp terraform.tfvars.example terraform.tfvars && tofu init && tofu apply

# 3. Kubernetes cluster (Ansible)
cd ../../ansible
ansible-playbook playbooks/kubernetes.yml
ansible-playbook playbooks/kubernetes-validation.yml
```

Manual prerequisites that are not automated yet:

- Raspberry Pi OS installation and SSH access (user `pi`)
- DHCP reservations on the router for every host
- Debian 13 Cloud-Init template on Proxmox (VMID `9000` in the example)
- `home.arpa` local DNS records in Pi-hole (`k8s-cp-01`, `k8s-worker-01`, `k8s-worker-02`)
- Ansible collections `community.general` and `kubernetes.core` on the control machine

---

# Contributing

Suggestions, discussions and contributions are always welcome.

---

# License

This project is licensed under the MIT License.