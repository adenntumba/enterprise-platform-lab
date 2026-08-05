# 🚀 Enterprise Platform Lab

> **An Enterprise-grade Platform Engineering Lab built from the ground up using Proxmox, Kubernetes, GitOps, Infrastructure as Code, DevSecOps and Observability.**

![Status](https://img.shields.io/badge/Status-In%20Development-blue)
![Platform](https://img.shields.io/badge/Platform-Engineering-success)
![IaC](https://img.shields.io/badge/IaC-OpenTofu-purple)
![Automation](https://img.shields.io/badge/Automation-Ansible-red)
![GitOps](https://img.shields.io/badge/GitOps-ArgoCD-orange)
![Kubernetes](https://img.shields.io/badge/Kubernetes-K3s-326CE5)
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
│      ├──────────── Raspberry-01 ── Pi-hole + Unbound                                                       │
│      ├──────────── Raspberry-02 ── Reserved                                                                │
│      └──────────── Raspberry-03 ── Reserved                                                                │
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

Current and future services include:

- Pi-hole
- Unbound
- DNS
- DHCP (future)
- VPN (future)

---

## Virtualization Layer

Proxmox VE provides the virtualization platform that hosts all virtual machines required by the lab.

---

## Platform Layer

The Kubernetes platform hosts all enterprise services, including:

- GitOps
- Observability
- Security
- Storage
- Messaging
- Applications

---

## Automation Layer

All infrastructure provisioning and configuration is fully automated using Infrastructure as Code and GitOps.

---

## Cloud Simulation Layer

LocalStack provides a local implementation of AWS services, enabling cloud-native development without requiring an AWS account for every scenario.

---

# Technology Stack

## Infrastructure

- Raspberry Pi
- Proxmox VE
- Ubuntu Server
- Debian Linux

## Infrastructure as Code

- OpenTofu
- Terraform
- Ansible

## Container Platform

- Docker
- Kubernetes (K3s)
- Helm
- Kustomize

## GitOps

- ArgoCD

## Networking

- Pi-hole
- Unbound
- NGINX
- Traefik

## Observability

- Prometheus
- Grafana
- Loki
- Tempo
- OpenTelemetry

## Security

- Vault
- External Secrets Operator
- Kyverno
- Trivy

## Storage

- MinIO

## Databases

- PostgreSQL
- Redis

## Messaging

- RabbitMQ

## Cloud

- LocalStack
- AWS CLI

## Automation

- GitHub Actions
- GitHub MCP

---

# Repository Structure

```text
enterprise-platform-lab
│
├── .github/
├── ai/
│   └── prompts/
├── ansible/
├── docs/
│   ├── adr/
│   ├── architecture/
│   ├── backlog/
│   └── diagrams/
├── infrastructure/
│   ├── opentofu/
│   └── terraform/
├── kubernetes/
├── scripts/
├── README.md
├── LICENSE
└── .gitignore
```

---

# Documentation

| Document | Description |
|----------|-------------|
| PROJECT_CHARTER.md | Vision, mission and engineering principles |
| PROJECT_BACKLOG.md | Project backlog (Single Source of Truth) |
| ROADMAP.md | High-level implementation roadmap |
| docs/backlog | Sprint planning |
| docs/adr | Architecture Decision Records |
| docs/architecture | Architecture documentation |
| docs/diagrams | Infrastructure diagrams |

---

# Project Roadmap

The project evolves incrementally through independent sprints.

| Sprint | Description |
|---------|-------------|
| Sprint 00 | Foundation |
| Sprint 01 | Edge DNS Platform |
| Sprint 02 | Linux Baseline |
| Sprint 03 | Proxmox Platform |
| Sprint 04 | Infrastructure as Code |
| Sprint 05 | Kubernetes Platform |
| Sprint 06 | GitOps |
| Sprint 07 | Observability |
| Sprint 08 | DevSecOps |
| Sprint 09 | Hybrid Cloud |
| Sprint 10 | Chaos Engineering |

---

# Current Progress

| Sprint | Status |
|---------|--------|
| Sprint 00 | 🚧 In Progress |
| Sprint 01 | ⏳ Planned |
| Sprint 02 | ⏳ Planned |
| Sprint 03 | ⏳ Planned |
| Sprint 04 | ⏳ Planned |
| Sprint 05 | ⏳ Planned |
| Sprint 06 | ⏳ Planned |
| Sprint 07 | ⏳ Planned |
| Sprint 08 | ⏳ Planned |
| Sprint 09 | ⏳ Planned |
| Sprint 10 | ⏳ Planned |

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

---

# Contributing

Suggestions, discussions and contributions are always welcome.

---

# License

This project is licensed under the MIT License.