# Unbound Role

Ansible role responsible for installing and configuring Unbound as a recursive DNS resolver.

## Responsibilities

This role:

- Installs Unbound.
- Configures the Unbound service.
- Configures DNS listening parameters.
- Configures DNS access control.
- Enables DNSSEC trust anchor configuration.
- Validates the generated configuration.
- Enables and starts the Unbound service.

## Non-Responsibilities

This role does not:

- Install Pi-hole.
- Configure Pi-hole.
- Configure client DNS.
- Configure the home router.
- Configure firewall policies outside the Unbound requirements.

## Architecture

```text
Pi-hole
   |
   | DNS upstream
   v
Unbound
   |
   v
Recursive DNS