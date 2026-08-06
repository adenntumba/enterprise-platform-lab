# Base Linux Role

## Overview

This role performs the initial bootstrap of Debian-based Linux systems used by the Enterprise Platform Lab.

The role is responsible for providing a consistent baseline configuration across every Linux host before platform-specific roles are executed.

## Responsibilities

- Update package cache
- Upgrade installed packages
- Install common administration tools
- Provide a reusable Linux baseline

## Supported Platforms

- Debian
- Raspberry Pi OS

## Variables

| Variable | Description |
|-----------|-------------|
| common_packages | Packages installed on every Linux host |
| update_cache | Update apt cache |
| upgrade_packages | Upgrade installed packages |

## Dependencies

None.

## Example

```yaml
- hosts: raspberry

  become: true

  roles:

    - role: base/linux