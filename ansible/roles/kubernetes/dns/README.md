# Kubernetes Internal DNS

## Objetivo

Configurar e validar o DNS interno do cluster Kubernetes e sua integração com a plataforma de DNS da borda do laboratório.

O objetivo deste role é garantir que:

- CoreDNS esteja operacional;
- Pods consigam resolver nomes internos do Kubernetes;
- Pods consigam resolver domínios externos;
- Kubernetes consiga consultar a plataforma de DNS da borda;
- o fluxo de resolução DNS seja documentado;
- procedimentos de troubleshooting estejam documentados.

## Contexto

A arquitetura de DNS do laboratório deverá evoluir para:

```text
                         Internet
                            │
                            ▼
                         Router
                            │
                            ▼
                      Edge DNS Platform
                       ┌─────────────┐
                       │   Pi-hole   │
                       │   Unbound   │
                       └──────┬──────┘
                              │
                              │ DNS
                              ▼
                         Kubernetes
                              │
                         ┌────┴────┐
                         │ CoreDNS │
                         └────┬────┘
                              │
                 ┌────────────┼────────────┐
                 │            │            │
               Pod          Pod          Pod