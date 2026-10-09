# Sprint 01 — Edge DNS Platform

> **Sprint:** 01
>
> **Status:** ✅ Completed
>
> **Milestone:** Sprint 01 - Edge DNS Platform
>
> **Version:** v0.2.0
>
> **Estimated Duration:** 1 Sprint

---

# Goal

Build the Edge DNS Platform that will become the entry point of the Enterprise Platform Lab.

The objective of this Sprint is to provision the first Raspberry Pi as an enterprise-grade DNS appliance using Infrastructure as Code and Ansible.

No manual configuration should be required after the initial operating system installation.

---

# Architecture

```
                          Internet
                              │
                              ▼
                        ISP Router
                              │
                              ▼
                 ┌─────────────────────┐
                 │ Raspberry Pi Cluster │
                 └─────────────────────┘
                    │        │        │
                    │        │        │
                    ▼        ▼        ▼
                 dns-01    node-01  node-02
                 Unbound   Pi-hole  Reserved
                 .110      .111     .112
                    │
                    ▼
              Internal Network
                    │
                    ▼
              Proxmox Platform
                    │
                    ▼
           Kubernetes Platform
```

---

# Epic

## EPIC-0101

Enterprise Edge DNS Platform

---

# Objective

Provision and automate the first infrastructure component of the platform.

Everything must be reproducible using Ansible.

---

# Issues

---

## Issue

### Title

Prepare Raspberry Pi Operating System

### Goal

Install Raspberry Pi OS Lite and perform the initial operating system preparation.

### Labels

- raspberry-pi
- linux
- documentation

### Acceptance Criteria

- Raspberry Pi OS installed
- SSH enabled
- Hostname configured
- Static IP configured
- System updated
- Documentation completed

---

## Issue

### Title

Create Ansible Project Structure

### Goal

Create the Ansible repository structure that will manage every Raspberry Pi.

### Labels

- ansible
- automation

### Acceptance Criteria

- inventories created
- playbooks created
- roles created
- repository structure documented

---

## Issue

### Title

Bootstrap Raspberry Pi using Ansible

### Goal

Provision the Raspberry Pi using Ansible.

### Labels

- ansible
- automation
- linux

### Acceptance Criteria

- SSH connectivity validated
- Initial packages installed
- Common configuration applied
- Idempotency validated

---

## Issue

### Title

Deploy Pi-hole using Ansible

### Goal

Install and configure Pi-hole automatically.

### Labels

- pihole
- ansible
- dns

### Acceptance Criteria

- Pi-hole installed
- Web interface accessible
- DNS service operational
- Ansible role documented

---

## Issue

### Title

Deploy Unbound using Ansible

### Goal

Install and configure Unbound as recursive DNS.

### Labels

- unbound
- ansible
- dns

### Acceptance Criteria

- Unbound installed
- Pi-hole forwarding configured
- Recursive DNS validated
- Documentation updated

---

## Issue

### Title

Validate Edge DNS Platform

### Goal

Validate the complete Edge DNS Platform.

### Labels

- networking
- documentation

### Acceptance Criteria

- DNS resolution validated
- Recursive resolution validated
- Pi-hole statistics working
- Troubleshooting guide created

---

# Deliverables

- Raspberry Pi OS
- Raspberry Pi Baseline
- Ansible Repository
- Bootstrap Playbook
- Pi-hole Role
- Unbound Role
- Edge DNS Documentation
- Architecture Diagram
- Runbook
- Troubleshooting Guide

---

# Definition of Done

- Raspberry Pi provisioned
- Configuration fully automated
- No manual configuration required
- Ansible playbooks are idempotent
- Documentation completed
- Pull Requests reviewed
- Issues closed
- Sprint reviewed
- Release v0.2.0 published

---

# Implementation Outcome

> This section records how the Sprint was actually implemented. The planning content above is kept as the original plan.

## Delivered

| Host (inventory) | IP | Service | Playbook / role |
|---|---|---|---|
| `dns-01` | `192.168.0.110` | Unbound, recursive DNS on port `5335` | `playbooks/unbound.yml` / `unbound` |
| `node-01` | `192.168.0.111` | Pi-hole v6, LAN DNS on port `53` | `playbooks/pihole.yml` / `base/linux`, `pihole` |
| `node-02` | `192.168.0.112` | Reserved | — |

All Raspberry Pi hosts receive `base/linux` and `base/raspberry` through `playbooks/bootstrap.yml`.

- Pi-hole forwards to Unbound only (`192.168.0.110#5335`), listens in `LOCAL` mode on `eth0`, with DNSSEC and query logging enabled. The role does not manage DHCP or IPv6 settings; Pi-hole DHCP stays at its default (disabled).
- Unbound listens on `127.0.0.1` and `192.168.0.110` and only accepts queries from `127.0.0.0/8` and `192.168.0.111/32`.
- Pi-hole is installed from a shallow clone of `https://github.com/pi-hole/pi-hole.git` (branch `master`) using the unattended installer.

## Deviations from the plan

- Pi-hole and Unbound run on two different Raspberry Pis instead of both on `RPI-01`.
- Host IP addresses come from DHCP reservations on the router (TP-Link Archer C80); they are not configured by Ansible.

## Not delivered / open items

- Edge DNS runbook and standalone troubleshooting guide (`docs/runbooks/` has only the Kubernetes runbook). Troubleshooting content exists in the `pihole` role README.
- Release `v0.2.0` has not been published.
- Known limitation: the Pi-hole configuration tasks always report `changed` and restart `pihole-FTL` on every run.

