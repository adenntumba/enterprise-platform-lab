# Unbound Role

Ansible role responsible for installing and configuring Unbound as a recursive DNS resolver.

It is applied to the `unbound` group (`dns-01`, `192.168.0.110`) by `playbooks/unbound.yml`.

## Responsibilities

This role:

- Installs the `unbound` package.
- Renders `/etc/unbound/unbound.conf.d/enterprise-platform.conf` from `templates/unbound.conf.j2`.
- Configures DNS listening addresses and port.
- Configures DNS access control.
- Applies privacy and hardening options.
- Validates the configuration with `unbound-checkconf`.
- Enables and starts the Unbound service.
- Restarts Unbound when the configuration changes.

DNSSEC validation relies on the trust anchor configuration shipped by the Debian `unbound` package. The role does not manage the trust anchor itself.

## Non-Responsibilities

This role does not:

- Install Pi-hole.
- Configure Pi-hole.
- Configure client DNS.
- Configure the home router.
- Configure firewall policies.

## Architecture

```text
Pi-hole (node-01, 192.168.0.111)
   |
   | DNS upstream 192.168.0.110#5335
   v
Unbound (dns-01, 192.168.0.110:5335)
   |
   v
Recursive DNS (root servers)
```

## Variables

| Variable | Default | Description |
|---|---|---|
| `unbound_package_name` | `unbound` | Package name |
| `unbound_service_name` | `unbound` | systemd service |
| `unbound_service_enabled` | `true` | Enable the service |
| `unbound_service_state` | `started` | Service state |
| `unbound_listen_port` | `5335` | Listening port |
| `unbound_listen_addresses` | `127.0.0.1`, `192.168.0.110` | Listening interfaces |
| `unbound_allowed_networks` | `127.0.0.0/8`, `192.168.0.111/32` | Clients allowed by `access-control` (localhost and Pi-hole only) |
| `unbound_num_threads` | `2` | Worker threads |
| `unbound_enable_ipv4` / `unbound_enable_ipv6` | `true` / `false` | IP families |
| `unbound_hide_identity` / `unbound_hide_version` | `true` / `true` | Hide server identity and version |
| `unbound_use_caps_for_id` | `false` | 0x20 query randomization |
| `unbound_cache_min_ttl` / `unbound_cache_max_ttl` | `0` / `86400` | Cache TTL limits |

The template also sets `qname-minimisation`, `harden-below-nxdomain`, `harden-referral-path` and `verbosity: 1`.

## Known Limitations

- `unbound-checkconf` runs after the new configuration file is deployed. An invalid template is detected, but the file is already in place.

## Validation

```bash
dig @192.168.0.110 -p 5335 example.com
dig @192.168.0.110 -p 5335 dnssec-failed.org   # expected: SERVFAIL
```
