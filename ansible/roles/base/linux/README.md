# Base Linux Role

## Overview

This role performs the initial bootstrap of Debian-based Linux systems used by the Enterprise Platform Lab.

The role is responsible for providing a consistent baseline configuration across every Linux host before platform-specific roles are executed.

## Responsibilities

- Update the APT cache (`cache_valid_time: 3600`).
- Upgrade installed packages (`dist-upgrade`), only when `upgrade_packages` is `true` (default `false`).
- Install common administration tools.
- Configure the system timezone.

## Used By

| Playbook | Hosts |
|---|---|
| `playbooks/bootstrap.yml` | `raspberry` (together with `base/raspberry`) |
| `playbooks/pihole.yml` | `pihole` |
| `playbooks/kubernetes.yml` | `kubernetes` |

## Supported Platforms

- Debian 13 (Kubernetes VMs)
- Raspberry Pi OS (Raspberry Pi hosts)

## Variables

The values are defined in `inventories/lab/group_vars/all.yml`.

| Variable | Default | Description |
|---|---|---|
| `common_packages` | see `group_vars/all.yml` | Packages installed on every Linux host |
| `linux_packages` | `{{ common_packages }}` | Package list used by the role (role default) |
| `update_cache` | `true` | Update the APT cache |
| `upgrade_packages` | `false` | Run a `dist-upgrade` |
| `timezone` | `America/Bahia` | System timezone (`community.general.timezone`) |

`group_vars/all.yml` also defines `locale`, `reboot_if_required` and `configure_firewall`, but this role does not use them yet. The role defines a `Reboot system` handler that is not notified by any task.

## Dependencies

- Collection `community.general` (timezone module).

## Example

```yaml
- hosts: raspberry
  become: true

  roles:
    - role: base/linux
```
