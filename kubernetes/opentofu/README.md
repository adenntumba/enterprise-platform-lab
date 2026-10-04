# Kubernetes OpenTofu

Infrastructure as Code layer for the Kubernetes platform of the Enterprise Platform Lab.

This directory contains the OpenTofu configuration responsible for provisioning
the Kubernetes virtual machines on Proxmox VE.

---

## Objective

The goal is to provision the Kubernetes infrastructure using Infrastructure as Code,
following practices commonly used in production environments.

OpenTofu is responsible for defining and provisioning the Kubernetes virtual machines.

Ansible is responsible for configuring the operating systems after the virtual
machines are provisioned.

Kubernetes is responsible for container orchestration.

---

## Architecture

```text
                         GitHub
                            |
                            v
               +-------------------------+
               | enterprise-platform-lab |
               +------------+------------+
                            |
                            v
                        OpenTofu
                            |
                            v
                  bpg/proxmox provider
                            |
                            v
                     Proxmox VE
                    192.168.0.120
                            |
                     kubernetes-pool
                            |
              +-------------+-------------+
              |             |             |
              v             v             v
        k8s-cp-01    k8s-worker-01   k8s-worker-02
        192.168.0.130 192.168.0.131   192.168.0.132
              |             |             |
              +-------------+-------------+
                            |
                            v
                         Ansible
                            |
                            v
                       Kubernetes