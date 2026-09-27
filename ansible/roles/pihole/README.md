# Pi-hole

Ansible Role responsável pela instalação, configuração e validação do **Pi-hole** como camada de DNS da Edge DNS Platform do Enterprise Platform Lab.

---

## Objetivo

Implantar o Pi-hole de forma automatizada, reproduzível e idempotente utilizando Ansible.

O Pi-hole será responsável por:

- receber consultas DNS dos clientes da LAN;
- realizar filtragem de DNS;
- encaminhar consultas para o Unbound;
- atuar como ponto central de DNS da rede local;
- disponibilizar a interface web para administração;
- fornecer observabilidade básica das consultas DNS.

O Pi-hole **não será responsável pelo DHCP**.

O DHCP continuará sendo fornecido pelo Archer C80.

---

## Contexto

O Edge DNS Platform utiliza uma arquitetura em duas camadas:

```text
                    LAN
                     |
                     | DNS :53
                     v
          +-----------------------+
          |       Pi-hole         |
          |                       |
          | 192.168.0.111         |
          | DNS :53               |
          +-----------+-----------+
                      |
                      | DNS :5335
                      v
          +-----------------------+
          |       Unbound         |
          |                       |
          | 192.168.0.110         |
          | DNS :5335             |
          +-----------+-----------+
                      |
                      | Recursive DNS
                      v
                   Internet
```

O objetivo é separar claramente as responsabilidades:

| Componente | Responsabilidade |
|---|---|
| Archer C80 | Gateway, NAT e DHCP |
| Pi-hole | DNS filtering e DNS forwarding |
| Unbound | DNS recursivo e validação DNSSEC |

---

## Arquitetura de rede

### Archer C80

```text
IP: 192.168.0.1
```

Responsabilidades:

- gateway da LAN;
- NAT;
- DHCP;
- DHCP reservations.

O Raspberry que hospeda o Pi-hole utiliza DHCP.

O endereço é mantido estável através de uma DHCP reservation configurada no roteador.

### Pi-hole

```text
Hostname:  cluster-02
IP:        192.168.0.111
Interface: eth0
DNS:       53/TCP
DNS:       53/UDP
```

DHCP reservation:

```text
MAC: b8:27:eb:08:bf:4a
IP:  192.168.0.111
```

A configuração de IP não é gerenciada por esta role.

O NetworkManager continua responsável pela configuração de rede do Raspberry.

### Unbound

```text
Hostname:  cluster-01
IP:        192.168.0.110
DNS:       5335/TCP
DNS:       5335/UDP
```

O Pi-hole utiliza o Unbound como seu único upstream DNS:

```text
192.168.0.110#5335
```

---

## Fluxo DNS

O fluxo esperado é:

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

O cliente não acessa diretamente o Unbound.

O Unbound também não deve ser utilizado diretamente pelos clientes da LAN.

Isso cria uma separação clara entre:

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

---

## Responsabilidades da Role

A role `pihole` é responsável por:

- validar o sistema operacional;
- validar a arquitetura;
- validar a interface de rede;
- validar o endereço IP esperado;
- validar a disponibilidade da porta 53;
- instalar dependências;
- baixar o instalador oficial do Pi-hole;
- instalar o Pi-hole;
- configurar o upstream DNS;
- configurar o modo de escuta DNS;
- configurar a interface DNS;
- configurar a porta DNS;
- configurar query logging;
- configurar DNSSEC;
- habilitar o serviço `pihole-FTL`;
- iniciar o serviço;
- validar a configuração;
- validar a porta DNS;
- validar o estado do serviço.

---

## Pré-requisitos

O host deve atender aos seguintes requisitos.

### Sistema operacional

```text
Debian GNU/Linux 13 (trixie)
```

A role atualmente valida Debian 13 ou superior.

### Arquitetura

```text
aarch64
```

ou:

```text
arm64
```

### Interface

```text
eth0
```

### Endereço IP

```text
192.168.0.111
```

Esse endereço deve estar presente no host antes da execução da role.

### DHCP Reservation

O roteador deve manter:

```text
MAC: b8:27:eb:08:bf:4a
IP:  192.168.0.111
```

### Unbound

O Unbound deve estar disponível em:

```text
192.168.0.110:5335
```

---

## Estrutura da Role

```text
roles/
└── pihole/
    ├── defaults/
    │   └── main.yml
    ├── handlers/
    │   └── main.yml
    ├── tasks/
    │   └── main.yml
    └── README.md
```

---

## Variáveis principais

### Interface

```yaml
pihole_interface: "eth0"
```

Interface utilizada pelo Pi-hole.

---

### Endereço IPv4

```yaml
pihole_ipv4_address: "192.168.0.111"
```

Endereço esperado do host.

A role não configura esse endereço.

Ele é fornecido pelo DHCP do Archer C80 através de uma DHCP reservation.

---

### Upstream DNS

```yaml
pihole_upstream_dns:
  - "192.168.0.110#5335"
```

O Pi-hole encaminha as consultas DNS para o Unbound.

Não são utilizados DNS públicos como upstream nesta arquitetura.

Exemplos que não fazem parte da configuração atual:

```text
1.1.1.1
8.8.8.8
```

Essa decisão garante que o fluxo DNS permaneça:

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

## DNS Listening Mode

A configuração utilizada é:

```yaml
pihole_dns_listening_mode: "LOCAL"
```

O modo `LOCAL` permite atender consultas originadas da rede local.

O modo `ALL` não é utilizado.

Isso evita transformar o Pi-hole em um DNS resolver aberto para origens externas.

---

## DHCP

O DHCP do Pi-hole permanece desabilitado:

```yaml
pihole_dhcp_enabled: false
```

A responsabilidade pelo DHCP continua no Archer C80.

```text
Archer C80
    |
    +--- DHCP
    |
    +--- NAT
    |
    +--- Gateway
```

Enquanto:

```text
Pi-hole
    |
    +--- DNS
    |
    +--- Filtering
```

---

## IPv6

A primeira implementação da Edge DNS Platform utiliza IPv4 como caminho principal.

```yaml
pihole_ipv6_enabled: false
```

Isso não significa que IPv6 esteja desabilitado no sistema operacional.

Significa que a configuração inicial do serviço Pi-hole não depende de IPv6.

Uma implementação posterior poderá tratar:

- IPv6 da LAN;
- DNS AAAA;
- DHCPv6;
- Router Advertisements;
- DNS via IPv6;
- validação de conectividade IPv6.

---

## DNSSEC

DNSSEC permanece habilitado:

```yaml
pihole_dnssec: true
```

A validação DNSSEC será realizada pelo caminho:

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

O Unbound é responsável pela validação recursiva.

---

## Instalação

A role utiliza o instalador oficial do Pi-hole.

O instalador é baixado separadamente:

```text
https://install.pi-hole.net
```

e executado posteriormente.

A role não utiliza:

```bash
curl -sSL https://install.pi-hole.net | bash
```

O objetivo é separar:

```text
Download
   |
   v
Installer
   |
   v
Execution
```

Isso melhora a auditabilidade da automação.

---

## Execução

O deployment é realizado através do playbook:

```text
ansible/playbooks/pihole.yml
```

Executar syntax check:

```bash
ansible-playbook playbooks/pihole.yml --syntax-check
```

Validar inventário:

```bash
ansible-inventory --host node-01
```

Testar conectividade:

```bash
ansible pihole -m ansible.builtin.ping
```

Executar em check mode:

```bash
ansible-playbook playbooks/pihole.yml --check
```

Executar deployment:

```bash
ansible-playbook playbooks/pihole.yml
```

---

## Validação

Após a instalação, validar o serviço:

```bash
sudo systemctl status pihole-FTL --no-pager
```

Esperado:

```text
Active: active (running)
```

Validar se o serviço está habilitado:

```bash
sudo systemctl is-enabled pihole-FTL
```

Esperado:

```text
enabled
```

---

## Validar porta DNS

```bash
sudo ss -lntup | grep ':53'
```

Esperamos encontrar listeners TCP e UDP na porta:

```text
53
```

---

## Validar Pi-hole

```bash
sudo pihole -v
```

Validar FTL:

```bash
sudo pihole-FTL --version
```

Validar status:

```bash
sudo pihole status
```

---

## Teste DNS local

Executar no próprio Pi-hole:

```bash
dig @127.0.0.1 example.com
```

Esperado:

```text
status: NOERROR
```

---

## Teste DNS através do IP do Pi-hole

A partir de outro host da LAN:

```bash
dig @192.168.0.111 example.com
```

Esperado:

```text
status: NOERROR
```

---

## Teste TCP

```bash
dig +tcp @192.168.0.111 example.com
```

Esperado:

```text
status: NOERROR
```

O teste TCP é importante porque DNS pode utilizar TCP além de UDP.

---

## Teste do upstream

O Pi-hole deve utilizar:

```text
192.168.0.110#5335
```

O objetivo é confirmar:

```text
Pi-hole
    |
    | :5335
    v
Unbound
```

e não:

```text
Pi-hole
    |
    +----> 1.1.1.1
    |
    +----> 8.8.8.8
```

---

## Teste DNSSEC

Executar:

```bash
dig @192.168.0.111 cloudflare.com +dnssec
```

A resposta deve apresentar:

```text
status: NOERROR
```

e registros relacionados a DNSSEC quando fornecidos pela resposta.

---

## Teste de falha DNSSEC

Para validar a cadeia de validação:

```bash
dig @192.168.0.111 dnssec-failed.org
```

Esse teste deve ser interpretado de acordo com a resposta e o comportamento configurado do resolver.

O objetivo é confirmar que respostas DNSSEC inválidas não sejam aceitas silenciosamente.

---

## Troubleshooting

### Pi-hole não inicia

Verificar:

```bash
sudo systemctl status pihole-FTL --no-pager -l
```

Verificar logs:

```bash
sudo journalctl -u pihole-FTL --no-pager -n 100
```

---

### Porta 53 ocupada

Verificar:

```bash
sudo ss -lntup | grep ':53'
```

Identificar o processo:

```bash
sudo lsof -i :53
```

Antes da instalação, a porta 53 deve estar livre.

---

### Pi-hole não consegue consultar o Unbound

Testar o Unbound diretamente:

```bash
dig @192.168.0.110 -p 5335 example.com
```

Testar TCP:

```bash
dig +tcp @192.168.0.110 -p 5335 example.com
```

Se o Unbound não responder, o problema está na camada:

```text
Pi-hole
    X
Unbound
```

e não necessariamente no Pi-hole.

---

### Unbound retorna REFUSED

Verificar o `access-control` configurado no Unbound.

O Unbound deve permitir consultas originadas pelo Pi-hole:

```text
192.168.0.111/32
```

---

### Pi-hole não responde na LAN

Verificar:

```bash
ip -4 addr show eth0
```

Esperado:

```text
192.168.0.111/24
```

Verificar:

```bash
sudo ss -lntup | grep ':53'
```

Verificar conectividade:

```bash
ping 192.168.0.111
```

---

### Endereço IP mudou

Verificar:

```bash
ip -4 addr show eth0
```

Se o endereço não for:

```text
192.168.0.111
```

verificar a DHCP reservation no Archer C80.

A reservation esperada é:

```text
MAC: b8:27:eb:08:bf:4a
IP:  192.168.0.111
```

---

## Segurança

O Pi-hole é um componente crítico da rede local.

Por isso:

- DNS não deve ficar exposto diretamente à Internet;
- `dns.listeningMode=LOCAL` é utilizado;
- o DHCP do Pi-hole permanece desabilitado;
- o upstream é controlado;
- Unbound é utilizado como resolver recursivo;
- o roteador continua responsável pelo gateway e NAT.

Arquitetura:

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

O objetivo é evitar que o Pi-hole se transforme em um open resolver.

---

## Observabilidade futura

A role atualmente valida o estado básico do serviço.

A integração futura poderá incluir:

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

Possíveis métricas:

- queries totais;
- queries bloqueadas;
- queries permitidas;
- clientes;
- latência;
- respostas DNS;
- erros;
- disponibilidade.

Essa integração está fora do escopo atual da Issue de deployment.

---

## Infraestrutura como Código

A instalação do Pi-hole deve ser reproduzível através de:

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

Não devem ser necessárias configurações manuais persistentes no servidor após o deployment.

Configurações específicas do ambiente devem permanecer versionadas no repositório.

---

## Princípios de Engenharia

Esta role segue os seguintes princípios.

### Idempotência

Executar o playbook repetidamente não deve produzir mudanças desnecessárias.

### Reprodutibilidade

Um novo Raspberry compatível deve poder ser configurado através do mesmo playbook.

### Separação de responsabilidades

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

### Fail Fast

A role valida pré-requisitos antes de executar mudanças críticas.

### Segurança por padrão

Configurações potencialmente perigosas, como resolver aberto, não são utilizadas.

---

## Fora do escopo

Os seguintes itens não fazem parte desta implementação:

- configuração do Archer C80;
- configuração de DHCP pelo Pi-hole;
- configuração de IP estático no Raspberry;
- firewall avançado;
- HA do Pi-hole;
- HA do Unbound;
- IPv6 completo;
- DNS over HTTPS;
- DNS over TLS;
- reverse DNS;
- local DNS records;
- custom blocklists;
- monitoramento Prometheus;
- dashboards Grafana;
- alertas;
- integração com Kubernetes.

Esses itens podem ser tratados em Issues futuras.

---

## Dependências

Esta role depende conceitualmente de:

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

O Unbound deve estar implantado e validado antes da validação final da cadeia DNS.

---

## Próximos passos

Após o deployment:

1. Validar Pi-hole localmente.
2. Validar Pi-hole a partir do `cluster-01`.
3. Validar comunicação Pi-hole → Unbound.
4. Validar DNSSEC.
5. Validar bloqueio DNS.
6. Validar disponibilidade.
7. Integrar o DNS do Pi-hole ao DHCP do Archer C80.
8. Validar resolução DNS de um cliente real da LAN.
9. Documentar a Edge DNS Platform.
10. Integrar observabilidade.

---

## Referências

- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Pi-hole FTL Configuration](https://docs.pi-hole.net/ftldns/configfile/)
- [Pi-hole Installation Documentation](https://docs.pi-hole.net/main/basic-install/)
- [Unbound Documentation](https://unbound.docs.nlnetlabs.nl/)
- [Ansible Documentation](https://docs.ansible.com/)

---

## Status

```text
Implementation: In Progress
Environment:    Home Lab
Architecture:   Edge DNS Platform
Service:        Pi-hole
Upstream:       Unbound
Deployment:     Ansible
```