# 🗺️ Enterprise Platform Lab Roadmap

> **Version:** 1.2.0
>
> **Status:** In Progress
>
> **Owner:** Adenn Tumba
>
> **Last Updated:** 2026-10-08

---

# Purpose

This roadmap defines the strategic evolution of the Enterprise Platform Lab.

Unlike the project backlog, which contains implementation work items, the roadmap provides a high-level view of the platform's evolution through sequential Sprints.

Each Sprint builds upon the previous one, ensuring that the platform evolves in a structured, reproducible and enterprise-oriented manner.

The roadmap intentionally remains at a strategic level.

Implementation details belong to the corresponding Sprint documents.

---

# Platform Evolution

Foundation
↓
Edge DNS Platform
↓
Kubernetes Platform Foundation
↓
Kubernetes Platform Services
↓
Observability Platform
↓
Security & PKI
↓
Storage Platform
↓
GitOps Platform
↓
Platform Applications
↓
Hybrid Cloud
↓
Chaos Engineering

---

# Roadmap

| Sprint | Name | Objective | Status |
|---------|------|-----------|--------|
| Sprint 00 | Foundation | Establish project standards, documentation and repository structure | ✅ Completed |
| Sprint 01 | Edge DNS Platform | Build the Edge DNS platform using Pi-hole and Unbound | ✅ Completed |
| Sprint 02 | Kubernetes Platform Foundation | Provision the Kubernetes VMs with OpenTofu and build an upstream Kubernetes cluster (kubeadm, containerd, Cilium, CoreDNS) with Ansible | ✅ Completed |
| Sprint 03 | Kubernetes Platform Services | Establish the core services required by the Kubernetes platform | ⏳ Planned |
| Sprint 04 | Observability Platform | Implement metrics, logs and distributed tracing | ⏳ Planned |
| Sprint 05 | Security & PKI | Implement security controls, internal PKI and certificate management | ⏳ Planned |
| Sprint 06 | Storage Platform | Establish persistent storage and integration with the storage platform | ⏳ Planned |
| Sprint 07 | GitOps Platform | Manage platform configuration and workloads declaratively with ArgoCD | ⏳ Planned |
| Sprint 08 | Platform Applications | Deploy and operate platform applications and workloads | ⏳ Planned |
| Sprint 09 | Hybrid Cloud | Integrate local cloud simulation and AWS-compatible services | ⏳ Planned |
| Sprint 10 | Chaos Engineering | Validate resilience, failure recovery and disaster scenarios | ⏳ Planned |

---

# Sprint Dependencies

| Sprint | Depends On |
|----------|------------|
| Sprint 00 | None |
| Sprint 01 | Sprint 00 |
| Sprint 02 | Sprint 01 |
| Sprint 03 | Sprint 02 |
| Sprint 04 | Sprint 03 |
| Sprint 05 | Sprint 04 |
| Sprint 06 | Sprint 05 |
| Sprint 07 | Sprint 06 |
| Sprint 08 | Sprint 07 |
| Sprint 09 | Sprint 08 |
| Sprint 10 | Sprint 09 |

---

# Target Platform

At the end of the roadmap, the platform will provide:

- Enterprise Edge DNS
- Proxmox virtualization
- Infrastructure as Code
- Automated infrastructure provisioning
- Ansible-based configuration management
- Upstream Kubernetes Platform
- Kubernetes networking
- Kubernetes platform services
- GitOps deployment
- Enterprise observability
- Internal PKI
- Persistent storage
- Platform applications
- DevSecOps practices
- Cloud simulation using LocalStack
- Production-inspired architecture
- Comprehensive technical documentation

---

# Success Criteria

The roadmap is considered complete when:

- All roadmap Sprints are completed.
- Every deliverable is reproducible.
- All infrastructure is managed as code.
- Platform services are deployed through GitOps where applicable.
- Documentation is complete.
- The platform can be reproduced by other engineers using compatible hardware.

---

# Related Documents

- PROJECT_CHARTER.md
- PROJECT_BACKLOG.md
- README.md
- docs/backlog/
- docs/architecture/
- docs/adr/

---

# Next Milestone

**Sprint 03 — Kubernetes Platform Services**

Sprint 02 delivered the first upstream Kubernetes cluster on Proxmox: one control-plane node and two workers running Kubernetes `v1.37.1`, containerd, Cilium and CoreDNS, provisioned with OpenTofu and configured with Ansible.

The next objective is to establish the core services required by the Kubernetes platform. The Sprint 03 document has not been created yet.

Open items carried over from Sprint 02:

- Release `v0.3.0` (only `v0.1.0` has been published; `v0.2.0` for Sprint 01 is also pending).
- Kubernetes runbook and troubleshooting guide in `docs/runbooks/`.
- Automation of the `home.arpa` DNS records, which are currently created manually in Pi-hole.
- The [Engineering Quality Platform](backlog/Epic-Engineering-Quality-Platform.md) Epic (CI), accepted in ADR-0001 but not started.

High availability, persistent storage, observability, GitOps and application workloads will be addressed in subsequent Sprints.