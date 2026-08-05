# 🗺️ Enterprise Platform Lab Roadmap

> **Version:** 1.0.0
>
> **Status:** In Progress
>
> **Last Updated:** 2026-08-05

---

# Purpose

This roadmap defines the strategic evolution of the Enterprise Platform Lab.

Unlike the project backlog, which contains implementation work items, the roadmap provides a high-level view of the platform's evolution through sequential sprints.

Each sprint builds upon the previous one, ensuring that the platform evolves in a structured, reproducible and enterprise-oriented manner.

---

# Platform Evolution

```text
Foundation
      │
      ▼
Edge Infrastructure
      │
      ▼
Linux Baseline
      │
      ▼
Virtualization
      │
      ▼
Infrastructure as Code
      │
      ▼
Kubernetes Platform
      │
      ▼
GitOps
      │
      ▼
Observability
      │
      ▼
DevSecOps
      │
      ▼
Hybrid Cloud
      │
      ▼
Chaos Engineering
```

---

# Roadmap

| Sprint | Name | Objective | Status |
|---------|------|-----------|--------|
| Sprint 00 | Foundation | Establish project standards, documentation and repository structure | 🚧 In Progress |
| Sprint 01 | Edge DNS Platform | Deploy Raspberry Pi Cluster, Pi-hole and Unbound | ⏳ Planned |
| Sprint 02 | Linux Baseline | Create the Linux baseline using Ansible | ⏳ Planned |
| Sprint 03 | Proxmox Platform | Build the virtualization platform and base virtual machines | ⏳ Planned |
| Sprint 04 | Infrastructure as Code | Provision infrastructure using OpenTofu and Terraform | ⏳ Planned |
| Sprint 05 | Kubernetes Platform | Deploy the Kubernetes cluster and platform services | ⏳ Planned |
| Sprint 06 | GitOps | Manage the platform declaratively with ArgoCD | ⏳ Planned |
| Sprint 07 | Observability | Implement metrics, logs and distributed tracing | ⏳ Planned |
| Sprint 08 | DevSecOps | Apply security, secrets management and policy enforcement | ⏳ Planned |
| Sprint 09 | Hybrid Cloud | Integrate LocalStack and AWS-compatible services | ⏳ Planned |
| Sprint 10 | Chaos Engineering | Validate resilience and disaster recovery scenarios | ⏳ Planned |

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

- Enterprise DNS
- Infrastructure as Code
- Automated provisioning
- Kubernetes Platform
- GitOps deployment
- Enterprise observability
- DevSecOps
- Cloud simulation using LocalStack
- Production-inspired architecture
- Comprehensive technical documentation

---

# Success Criteria

The roadmap is considered complete when:

- All roadmap sprints are completed.
- Every deliverable is reproducible.
- All infrastructure is managed as code.
- Platform services are deployed through GitOps.
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

**Sprint 01 — Edge DNS Platform**

The next major objective is to build the Edge Layer using the Raspberry Pi Cluster, deploying Pi-hole and Unbound as the first production-inspired infrastructure services.