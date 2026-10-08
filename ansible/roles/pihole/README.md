# Pi-hole

Ansible role responsible for installing, configuring and validating **Pi-hole** as the DNS layer of the Edge DNS Platform of the Enterprise Platform Lab.

---

## Objective

Deploy Pi-hole in an automated and reproducible way using Ansible.

Pi-hole is responsible for:

- receiving DNS queries from LAN clients;
- DNS filtering;
- forwarding queries to Unbound;
- acting as the central DNS server of the local network;
- providing the web interface for administration;
- providing basic observability of DNS queries;
- serving the `home.arpa` local DNS records used by the lab (records are created manually today, see [Local DNS records](#local-dns-records)).

Pi-hole is **not** responsible for DHCP.

DHCP is provided by the TP-Link Archer C80 router.

---

## Context

The Edge DNS Platform uses a two-layer architecture:

```text
                    LAN
                     |
                     | DNS :53
                     v
          +-----------------------+
          |       Pi-hole         |
          |                       |
          | node-01               |
          | 192.168.0.111         |
          | DNS :53               |
          +-----------+-----------+
                      |
                      | DNS :5335
                      v
          +-----------------------+
          |       Unbound         |
          |                       |
          | dns-01                |
          | 192.168.0.110         |
          | DNS :5335             |
          +-----------+-----------+
                      |
                      | Recursive DNS
                      v
                   Internet
```

Responsibilities are clearly separated:

| Component | Responsibility |
|---|---|
| Archer C80 | Gateway, NAT and DHCP |
| Pi-hole | DNS filtering and DNS forwarding |
| Unbound | Recursive DNS and DNSSEC validation |

---

## Network Architecture

### Archer C80

```text
IP: 192.168.0.1
```

Responsibilities:

- LAN gateway;
- NAT;
- DHCP;
- DHCP reservations.

The Raspberry Pi that hosts Pi-hole uses DHCP.

Its address is kept stable through a DHCP reservation on the router.

### Pi-hole

```text
Inventory host: node-01 (group: pihole)
Hostname:       cluster-02
IP:             192.168.0.111
Interface:      eth0
DNS:            53/TCP
DNS:            53/UDP
```

DHCP reservation:

```text
MAC: b8:27:eb:08:bf:4a
IP:  192.168.0.111
```

The IP configuration is not managed by this role.

NetworkManager remains responsible for the network configuration of the Raspberry Pi.

### Unbound

```text
Inventory host: dns-01 (group: unbound)
Hostname:       cluster-01
IP:             192.168.0.110
DNS:            5335/TCP
DNS:            5335/UDP
```

Pi-hole uses Unbound as its only upstream DNS server:

```text
192.168.0.110#5335
```

---

## DNS Flow

The expected flow is:

```text
Client
   |
   | UDP/TCP 53
   v
Pi-hole
192.168.0.111
   |
   | UDP/TCP 5335
   v
Unbound
192.168.0.110
   |
   | Recursive DNS
   v
Root Servers
   |
   v
TLD Servers
   |
   v
Authoritative DNS Servers
```

Clients do not query Unbound directly.

Unbound must not be used directly by LAN clients.

This creates a clear separation between:

```text
DNS Filtering
      |
      v
   Pi-hole
      |
      v
DNS Recursion
      |
      v
   Unbound
```

Kubernetes CoreDNS forwards the `home.arpa` zone to Pi-hole (see `ansible/roles/kubernetes/dns`).

---

## Role Responsibilities

The `pihole` role:

- validates the operating system (Debian 13 or later);
- validates the architecture (`aarch64`);
- validates that the network interface exists;
- validates that the expected IP address is present on the host;
- validates that at least one upstream DNS server is configured;
- installs dependencies;
- checks whether Pi-hole is already installed (`/usr/local/bin/pihole`);
- on a fresh install only: checks that port 53 is free, clones the official Pi-hole repository, renders a bootstrap `pihole.toml` and runs the unattended installer;
- verifies the `pihole` and `pihole-FTL` binaries;
- configures upstream DNS, listening mode, interface, port, query logging and DNSSEC through `pihole-FTL --config`;
- enables and starts the `pihole-FTL` service;
- validates the configuration, the DNS listener on port 53 and the service state.

---

## Prerequisites

### Operating system

```text
Debian GNU/Linux 13 (trixie)
```

The role validates Debian 13 or later (Raspberry Pi OS reports `Debian`).

### Architecture

```text
aarch64
```

Only `aarch64` is accepted by the validation task.

### Interface

```text
eth0
```

### IP address

```text
192.168.0.111
```

This address must be present on the host before the role runs.

### DHCP reservation

The router must keep:

```text
MAC: b8:27:eb:08:bf:4a
IP:  192.168.0.111
```

### Unbound

Unbound must be available at:

```text
192.168.0.110:5335
```

---

## Role Structure

```text
roles/
└── pihole/
    ├── defaults/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── meta/
    │   └── main.yml
    ├── tasks/
    │   └── main.yml
    ├── templates/
    │   └── pihole.toml.j2
    ├── tests/
    ├── vars/
    │   └── main.yml
    └── README.md
```

---

## Main Variables

### Interface

```yaml
pihole_interface: "eth0"
```

Interface used by Pi-hole. It is also used for `dns.interface` (`pihole_dns_interface`).

---

### IPv4 address

```yaml
pihole_ipv4_address: "192.168.0.111"
```

Expected address of the host.

The role does not configure this address. It is provided by the Archer C80 DHCP server through a DHCP reservation.

---

### Upstream DNS

```yaml
pihole_upstream_dns:
  - "192.168.0.110#5335"
```

Pi-hole forwards DNS queries to Unbound.

Public DNS servers are not used as upstream in this architecture, for example:

```text
1.1.1.1
8.8.8.8
```

This keeps the DNS flow as:

```text
Client
  |
  v
Pi-hole
  |
  v
Unbound
  |
  v
Internet
```

---

### Variables declared but not used

The following defaults are declared but are not used by any task or template:

| Variable | Default |
|---|---|
| `pihole_ipv4_cidr` | `192.168.0.111/24` |
| `pihole_ipv4_network` | `192.168.0.0/24` |
| `pihole_gateway` | `192.168.0.1` |
| `pihole_ipv6_enabled` | `false` |
| `pihole_dhcp_enabled` | `false` |

---

## DNS Listening Mode

```yaml
pihole_dns_listening_mode: "LOCAL"
```

`LOCAL` mode answers queries from the local network.

`ALL` mode is not used.

This prevents Pi-hole from becoming an open resolver for external sources.

---

## DHCP

The Pi-hole DHCP server is not enabled. The role does not configure DHCP (`pihole_dhcp_enabled` is not applied), so Pi-hole keeps its default, which is disabled.

DHCP remains the responsibility of the Archer C80:

```text
Archer C80
    |
    +--- DHCP
    |
    +--- NAT
    |
    +--- Gateway
```

While:

```text
Pi-hole
    |
    +--- DNS
    |
    +--- Filtering
```

---

## IPv6

The first implementation of the Edge DNS Platform uses IPv4 as the main path.

The role does not configure any IPv6 setting (`pihole_ipv6_enabled` is not applied). This does not mean IPv6 is disabled on the operating system.

A later implementation may handle:

- LAN IPv6;
- AAAA records;
- DHCPv6;
- Router Advertisements;
- DNS over IPv6;
- IPv6 connectivity validation.

---

## DNSSEC

DNSSEC is enabled:

```yaml
pihole_dnssec: true
```

DNSSEC validation follows the path:

```text
Client
   |
   v
Pi-hole
   |
   v
Unbound
   |
   v
Authoritative DNS
```

Unbound is responsible for recursive validation.

---

## Installation

The role uses the official Pi-hole installer from the Pi-hole Git repository.

On a fresh install (when `/usr/local/bin/pihole` does not exist), the role:

1. clones `https://github.com/pi-hole/pi-hole.git` (`pihole_repository_version: master`, `depth: 1`) into `/opt/pihole-installer`;
2. renders `/etc/pihole/pihole.toml` from `templates/pihole.toml.j2` so that the Pi-hole v6 installer can run unattended;
3. runs:

```bash
"/opt/pihole-installer/automated install/basic-install.sh" --unattended
```

The role does not use:

```bash
curl -sSL https://install.pi-hole.net | bash
```

Download and execution are separated, which improves the auditability of the automation.

After installation, the configuration is managed with the `pihole-FTL --config` CLI.

Note: `master` is not a pinned version. A new installation may get a different Pi-hole version.

---

## Execution

Deployment is done by the playbook:

```text
ansible/playbooks/pihole.yml
```

The playbook applies `base/linux` and then `pihole` to the `pihole` group.

Syntax check:

```bash
ansible-playbook playbooks/pihole.yml --syntax-check
```

Inventory:

```bash
ansible-inventory --host node-01
```

Connectivity:

```bash
ansible pihole -m ansible.builtin.ping
```

Check mode (configuration and service tasks are skipped in check mode):

```bash
ansible-playbook playbooks/pihole.yml --check
```

Deployment:

```bash
ansible-playbook playbooks/pihole.yml
```

---

## Validation

After installation, validate the service:

```bash
sudo systemctl status pihole-FTL --no-pager
```

Expected:

```text
Active: active (running)
```

Check that the service is enabled:

```bash
sudo systemctl is-enabled pihole-FTL
```

Expected:

```text
enabled
```

---

## Validate the DNS port

```bash
sudo ss -lntup | grep ':53'
```

TCP and UDP listeners are expected on port:

```text
53
```

---

## Validate Pi-hole

```bash
sudo pihole -v
```

Validate FTL:

```bash
sudo pihole-FTL --version
```

Validate status:

```bash
sudo pihole status
```

---

## Local DNS test

Run on the Pi-hole host:

```bash
dig @127.0.0.1 example.com
```

Expected:

```text
status: NOERROR
```

---

## DNS test through the Pi-hole IP

From another LAN host:

```bash
dig @192.168.0.111 example.com
```

Expected:

```text
status: NOERROR
```

---

## TCP test

```bash
dig +tcp @192.168.0.111 example.com
```

Expected:

```text
status: NOERROR
```

The TCP test matters because DNS can use TCP in addition to UDP.

---

## Upstream test

Pi-hole must use:

```text
192.168.0.110#5335
```

The goal is to confirm:

```text
Pi-hole
    |
    | :5335
    v
Unbound
```

and not:

```text
Pi-hole
    |
    +----> 1.1.1.1
    |
    +----> 8.8.8.8
```

---

## DNSSEC test

```bash
dig @192.168.0.111 cloudflare.com +dnssec
```

The response must show:

```text
status: NOERROR
```

and DNSSEC-related records when provided in the response.

---

## DNSSEC failure test

To validate the validation chain:

```bash
dig @192.168.0.111 dnssec-failed.org
```

The expected result is `SERVFAIL`: invalid DNSSEC responses must not be accepted silently.

---

## Local DNS records

The Kubernetes platform relies on these `home.arpa` records in Pi-hole:

```text
k8s-cp-01.home.arpa      192.168.0.130
k8s-worker-01.home.arpa  192.168.0.131
k8s-worker-02.home.arpa  192.168.0.132
```

They were created manually in the Pi-hole web interface. This role does not manage local DNS records yet, so they are not reproducible from the repository.

Check:

```bash
dig @192.168.0.111 k8s-cp-01.home.arpa
```

---

## Troubleshooting

### Pi-hole does not start

Check:

```bash
sudo systemctl status pihole-FTL --no-pager -l
```

Logs:

```bash
sudo journalctl -u pihole-FTL --no-pager -n 100
```

---

### Port 53 in use

Check:

```bash
sudo ss -lntup | grep ':53'
```

Identify the process:

```bash
sudo lsof -i :53
```

Before installation, port 53 must be free. The role fails on a fresh install if it is not.

---

### Pi-hole cannot query Unbound

Test Unbound directly:

```bash
dig @192.168.0.110 -p 5335 example.com
```

Test TCP:

```bash
dig +tcp @192.168.0.110 -p 5335 example.com
```

If Unbound does not answer, the problem is in the layer:

```text
Pi-hole
    X
Unbound
```

and not necessarily in Pi-hole.

---

### Unbound returns REFUSED

Check the `access-control` configured in Unbound.

Unbound must allow queries from Pi-hole:

```text
192.168.0.111/32
```

---

### Pi-hole does not answer on the LAN

Check:

```bash
ip -4 addr show eth0
```

Expected:

```text
192.168.0.111/24
```

Check:

```bash
sudo ss -lntup | grep ':53'
```

Check connectivity:

```bash
ping 192.168.0.111
```

---

### The IP address changed

Check:

```bash
ip -4 addr show eth0
```

If the address is not:

```text
192.168.0.111
```

check the DHCP reservation on the Archer C80.

The expected reservation is:

```text
MAC: b8:27:eb:08:bf:4a
IP:  192.168.0.111
```

---

## Security

Pi-hole is a critical component of the local network.

Therefore:

- DNS must not be exposed directly to the Internet;
- `dns.listeningMode=LOCAL` is used;
- Pi-hole DHCP is not enabled;
- the upstream is controlled;
- Unbound is used as the recursive resolver;
- the router remains responsible for gateway and NAT.

Architecture:

```text
Internet
   |
   X
   |
Pi-hole
   |
   v
Unbound
```

The goal is to prevent Pi-hole from becoming an open resolver.

---

## Future Observability

The role currently validates the basic service state.

A future integration may include:

```text
Pi-hole
   |
   +--> Metrics
   |
   v
Prometheus
   |
   v
Grafana
```

Possible metrics:

- total queries;
- blocked queries;
- allowed queries;
- clients;
- latency;
- DNS responses;
- errors;
- availability.

---

## Infrastructure as Code

The Pi-hole installation should be reproducible through:

```text
Git
 |
 v
Ansible
 |
 v
Raspberry Pi
 |
 v
Pi-hole
```

No persistent manual configuration should be needed on the server after deployment.

Exception today: the `home.arpa` local DNS records are created manually.

Environment-specific settings must stay versioned in the repository.

---

## Engineering Principles

### Idempotency

Running the playbook repeatedly should not produce unnecessary changes.

Current limitation: the six `pihole-FTL --config` tasks use `changed_when: true`. Every run reports them as `changed` and restarts `pihole-FTL` through the handler, even when nothing changed.

### Reproducibility

A new compatible Raspberry Pi should be configurable with the same playbook.

### Separation of responsibilities

```text
base/linux
    |
    +--- Linux baseline

pihole
    |
    +--- DNS filtering

unbound
    |
    +--- Recursive DNS
```

### Fail fast

The role validates prerequisites before making critical changes.

### Secure by default

Potentially dangerous settings, such as an open resolver, are not used.

---

## Out of Scope

The following items are not part of this implementation:

- Archer C80 configuration;
- Pi-hole DHCP;
- static IP configuration on the Raspberry Pi;
- advanced firewall;
- Pi-hole HA;
- Unbound HA;
- full IPv6;
- DNS over HTTPS;
- DNS over TLS;
- reverse DNS;
- local DNS records (created manually today);
- custom blocklists;
- Prometheus monitoring;
- Grafana dashboards;
- alerts.

These items may be handled in future Issues.

---

## Dependencies

This role conceptually depends on:

```text
base/linux
    |
    v
Raspberry Linux baseline
    |
    v
pihole
    |
    v
Unbound
```

Unbound must be deployed and validated before the final validation of the DNS chain.

---

## Next Steps

1. Manage the `home.arpa` local DNS records with Ansible.
2. Make the `pihole-FTL --config` tasks idempotent (compare the current value before changing it).
3. Pin `pihole_repository_version` to a release tag.
4. Validate DNS blocking.
5. Integrate Pi-hole DNS with the Archer C80 DHCP (if not already done) and validate a real LAN client.
6. Integrate observability.

---

## References

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole FTL Configuration](https://docs.pi-hole.net/ftldns/configfile/)
- [Pi-hole Installation Documentation](https://docs.pi-hole.net/main/basic-install/)
- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [Ansible Documentation](https://docs.ansible.com/)

---

## Status

```text
Implementation: Completed (Sprint 01)
Environment:    Home Lab
Architecture:   Edge DNS Platform
Service:        Pi-hole
Upstream:       Unbound
Deployment:     Ansible
```
