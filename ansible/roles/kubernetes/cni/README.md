# Kubernetes CNI — Cilium

## Objetivo

Configurar o **Cilium** como Container Network Interface (CNI) do cluster Kubernetes provisionado pelo laboratório.

O role é responsável por:

- Garantir a instalação do Helm;
- Validar a versão do Helm;
- Instalar ou atualizar o Cilium;
- Configurar o Cilium Operator;
- Garantir configuração compatível com a topologia do laboratório;
- Manter a instalação idempotente;
- Permitir que o estado do Cilium seja reconciliado pelo Ansible.

---

# Contexto

O cluster Kubernetes utiliza:

- Debian 13;
- Kubernetes `v1.37.1`;
- containerd `1.7.24`;
- Cilium `1.20.2`;
- Helm `4.3.0`.

Topologia atual:

```text
                    Kubernetes Cluster
                           │
          ┌────────────────┼────────────────┐
          │                │                │
      k8s-cp-01       k8s-worker-01    k8s-worker-02
     192.168.0.130     192.168.0.131    192.168.0.132
          │                │                │
          └────────────────┼────────────────┘
                           │
                         Cilium
                           │
              ┌────────────┴────────────┐
              │                         │
        Cilium Agent               Cilium Operator
          DaemonSet                   Deployment
              │                         │
           3 nodes                   2 replicas
```

---

# Por que Cilium?

Cilium é utilizado como CNI do cluster para fornecer conectividade de rede entre Pods e nós Kubernetes.

Além da função básica de CNI, o Cilium possui recursos adicionais de rede, segurança e observabilidade.

No laboratório, ele também permite evoluir posteriormente para recursos como:

- NetworkPolicy;
- observabilidade de rede;
- Hubble;
- controle de tráfego;
- políticas baseadas em identidade;
- recursos avançados de networking.

A escolha também mantém o laboratório próximo de arquiteturas modernas de Kubernetes utilizadas em ambientes profissionais.

---

# Arquitetura

A comunicação de rede do cluster segue aproximadamente:

```text
                    Kubernetes API
                          │
                          │
                   Cilium Operator
                    ┌─────┴─────┐
                    │           │
                Operator     Operator
                  Pod           Pod
                    │           │
                    └─────┬─────┘
                          │
                    Cilium Agents
                    DaemonSet
                          │
             ┌────────────┼────────────┐
             │            │            │
          cp-01        worker-01    worker-02
             │            │            │
             └────────────┴────────────┘
```

Cada nó possui um Cilium Agent executado como DaemonSet.

O Cilium Operator é executado como Deployment com duas réplicas.

---

# Componentes

## Helm

O Helm é utilizado para instalar e gerenciar o Cilium.

Versão utilizada:

```text
Helm 4.3.0
```

O role verifica se a versão esperada está instalada antes de continuar.

---

## Cilium

Versão utilizada:

```text
Cilium 1.20.2
```

Chart:

```text
oci://quay.io/cilium/charts/cilium
```

A versão é explicitamente fixada para evitar atualizações inesperadas.

---

## Cilium Operator

O Operator executa funções de controle do Cilium que não precisam estar presentes em todos os nós.

O laboratório utiliza:

```text
2 replicas
```

As réplicas são distribuídas entre os nós do cluster através das regras de afinidade do chart.

---

# Configuração

As principais variáveis estão em:

```text
defaults/main.yml
```

Configuração atual:

```yaml
helm_version: "4.3.0"

cilium_version: "1.20.2"

cilium_namespace: kube-system

cilium_release_name: cilium

cilium_chart: oci://quay.io/cilium/charts/cilium

cilium_kubeconfig: /etc/kubernetes/admin.conf

cilium_operator_host_network: false

cilium_operator_api_serve_addr: ":9234"
```

---

# Cilium Operator e hostNetwork

O Operator utiliza:

```yaml
cilium_operator_host_network: false
```

Isso significa que o Operator utiliza a rede do próprio Pod.

Essa decisão é importante porque o cluster possui múltiplos nós e duas réplicas do Operator.

Utilizar `hostNetwork=true` faria o processo utilizar diretamente a rede do nó Kubernetes.

Isso poderia provocar conflitos de portas quando múltiplas réplicas fossem executadas no mesmo nó.

---

# Operator API

O Operator expõe uma API utilizada pelos probes de saúde.

A configuração utilizada é:

```yaml
cilium_operator_api_serve_addr: ":9234"
```

O argumento efetivamente aplicado ao container é:

```text
--operator-api-serve-addr=:9234
```

## Por que isso é necessário?

Com:

```yaml
operator.hostNetwork: false
```

o Operator utiliza o namespace de rede do Pod.

O Kubernetes realiza os probes utilizando o endereço do Pod.

Inicialmente o Operator estava configurado para escutar somente em:

```text
127.0.0.1:9234
```

Nesse cenário, o processo estava funcionando, porém o probe acessava o endereço IP do Pod:

```text
Pod IP:9234
```

O resultado era:

```text
connection refused
```

O Operator entrava em reinicialização e permanecia em:

```text
CrashLoopBackOff
```

A configuração:

```text
--operator-api-serve-addr=:9234
```

faz o processo escutar na interface do Pod, permitindo que os probes funcionem corretamente.

---

# Containerd e CNI

O Cilium instala o binário CNI:

```text
/opt/cni/bin/cilium-cni
```

O containerd precisa procurar os binários CNI no mesmo diretório.

Por isso o laboratório utiliza:

```text
/opt/cni/bin
```

Configuração:

```yaml
containerd_cni_bin_dir: /opt/cni/bin
```

O containerd é configurado para utilizar:

```text
bin_dir = "/opt/cni/bin"
```

Essa configuração é fundamental para que o runtime consiga executar o Cilium CNI.

---

# Problema encontrado

Durante a instalação inicial, o containerd estava procurando o CNI em:

```text
/usr/lib/cni
```

Enquanto o Cilium instalava:

```text
/opt/cni/bin/cilium-cni
```

O resultado foi o erro:

```text
failed to find plugin "cilium-cni" in path [/usr/lib/cni]
```

Como consequência, Pods como o CoreDNS permaneciam em:

```text
ContainerCreating
```

A solução foi configurar o containerd para utilizar:

```text
/opt/cni/bin
```

Essa configuração foi incorporada ao role do containerd para que o estado não dependa de configuração manual.

---

# Idempotência

O role foi implementado para não executar um `helm upgrade` desnecessariamente.

Antes de alterar o Cilium, o Ansible consulta a release:

```text
helm list
```

Depois consulta os valores:

```text
helm get values
```

O estado atual é comparado com o estado desejado.

São avaliados:

- existência da release;
- versão do chart;
- `operator.hostNetwork`;
- `operator.extraArgs`.

Fluxo:

```text
                 Ansible
                    │
                    ▼
              helm list
                    │
             Release existe?
              │           │
             não         sim
              │           │
              │      helm get values
              │           │
              │      comparar estado
              │           │
              └──────┬────┘
                     │
              Estado diferente?
                 │          │
                sim        não
                 │          │
            helm upgrade   skip
```

---

# Validação de idempotência

Após a implementação, o playbook foi executado novamente sem modificar o cluster.

Resultado:

```text
TASK [kubernetes/cni : Check if Cilium Helm release exists]
ok: [k8s-cp-01]

TASK [kubernetes/cni : Read Cilium Helm release values]
ok: [k8s-cp-01]

TASK [kubernetes/cni : Determine Cilium release state]
ok: [k8s-cp-01]

TASK [kubernetes/cni : Install or upgrade Cilium CNI]
skipping: [k8s-cp-01]
```

Resultado final:

```text
k8s-cp-01      changed=0 failed=0
k8s-worker-01  changed=0 failed=0
k8s-worker-02  changed=0 failed=0
```

Isso confirma que o role consegue executar novamente sem produzir alterações quando o estado desejado já está aplicado.

---

# Validação do cluster

## Nodes

Validar os nós:

```bash
kubectl get nodes -o wide
```

Resultado esperado:

```text
NAME            STATUS   ROLES           VERSION
k8s-cp-01       Ready    control-plane   v1.37.1
k8s-worker-01   Ready    <none>          v1.37.1
k8s-worker-02   Ready    <none>          v1.37.1
```

---

## Pods

Validar todos os Pods:

```bash
kubectl get pods -A -o wide
```

Todos os componentes do `kube-system` devem estar em estado saudável.

---

## Cilium Operator

Validar:

```bash
kubectl -n kube-system get deployment cilium-operator
```

Resultado esperado:

```text
NAME              READY   UP-TO-DATE   AVAILABLE
cilium-operator   2/2     2            2
```

---

## Cilium Agents

Validar:

```bash
kubectl -n kube-system get pods \
  -l k8s-app=cilium \
  -o wide
```

Deve existir um Cilium Agent em cada nó.

---

## Cilium status

Executar:

```bash
kubectl -n kube-system exec ds/cilium -- cilium status
```

Indicadores importantes:

```text
Kubernetes:       Ok
Cilium:           Ok
Cilium health:    Ok
Controller Status: healthy
Proxy Status:     OK
Hubble:           Ok
Cluster health:   3/3 reachable
```

---

# Troubleshooting

## Cilium Operator em CrashLoopBackOff

Verificar:

```bash
kubectl -n kube-system get pods \
  -l io.cilium/app=operator \
  -o wide
```

Ver logs:

```bash
kubectl -n kube-system logs \
  -l io.cilium/app=operator \
  --tail=100
```

Verificar o argumento:

```bash
kubectl -n kube-system get deployment cilium-operator \
  -o jsonpath='{.spec.template.spec.containers[0].args}' \
  | tr ' ' '\n' \
  | grep operator-api
```

Esperado:

```text
--operator-api-serve-addr=:9234
```

---

## Cilium Operator não fica Ready

Verificar:

```bash
kubectl -n kube-system describe deployment cilium-operator
```

E:

```bash
kubectl -n kube-system get events \
  --sort-by=.lastTimestamp
```

Verificar se o Operator está usando:

```yaml
operator.hostNetwork: false
```

---

## Erro `failed to find plugin cilium-cni`

Verificar:

```bash
ls -l /opt/cni/bin/cilium-cni
```

Verificar configuração do containerd:

```bash
containerd config dump | grep -A6 -B2 'bin_dir'
```

Esperado:

```text
bin_dir = "/opt/cni/bin"
```

---

## CoreDNS em ContainerCreating

Verificar:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
```

Se estiver em `ContainerCreating`, verificar os eventos:

```bash
kubectl -n kube-system describe pod <pod>
```

Também verificar o CNI:

```bash
ls -l /opt/cni/bin/
```

---

# Arquivos do role

Estrutura:

```text
ansible/roles/kubernetes/cni/
├── README.md
├── defaults/
│   └── main.yml
├── handlers/
│   └── main.yml
├── meta/
│   └── main.yml
├── tasks/
│   └── main.yml
├── tests/
│   ├── inventory
│   └── test.yml
└── vars/
    └── main.yml
```

---

# Execução

O role é executado através do playbook Kubernetes:

```bash
cd ansible
ansible-playbook playbooks/kubernetes.yml
```

---

# Decisões de arquitetura

| Decisão | Escolha | Motivo |
|---|---|---|
| CNI | Cilium | Networking moderno e recursos avançados |
| Cilium version | 1.20.2 | Versão fixada para reprodutibilidade |
| Helm | 4.3.0 | Versão fixada |
| Operator replicas | 2 | Disponibilidade e distribuição |
| Operator hostNetwork | false | Evitar dependência da rede do host |
| Operator API | `:9234` | Permitir probes através da rede do Pod |
| CNI bin directory | `/opt/cni/bin` | Compatibilidade com o binário instalado pelo Cilium |
| Deployment | Ansible + Helm | IaC e gerenciamento declarativo |
| Namespace | `kube-system` | Componentes de infraestrutura do cluster |

---

# Compatibilidade

O laboratório utiliza:

```text
Kubernetes 1.37.1
Cilium 1.20.2
```

Essa combinação deve ser tratada como uma decisão específica do laboratório.

A versão do Cilium foi fixada para garantir reprodutibilidade e evitar atualizações automáticas.

Antes de atualizar qualquer uma das versões, deve-se validar a matriz oficial de compatibilidade entre Kubernetes e Cilium.

---

# Segurança

O kubeconfig utilizado pelo role é:

```text
/etc/kubernetes/admin.conf
```

Esse arquivo possui privilégios administrativos sobre o cluster.

Por isso:

- não deve ser versionado;
- não deve ser copiado para o Git;
- permissões devem permanecer restritas;
- credenciais do cluster não devem ser armazenadas no repositório.

---

# Boas práticas aplicadas

Este role segue algumas práticas importantes de ambientes profissionais:

- versões fixadas;
- configuração declarativa;
- idempotência;
- validação de pré-requisitos;
- validação pós-instalação;
- separação entre defaults e tasks;
- troubleshooting documentado;
- ausência de credenciais no Git;
- configuração reproduzível;
- integração com Ansible;
- gerenciamento do Cilium através do Helm.

---

# Portfólio

Este componente demonstra conhecimentos em:

- Kubernetes;
- CNI;
- Cilium;
- Helm;
- Ansible;
- containerd;
- Linux networking;
- troubleshooting Kubernetes;
- IaC;
- idempotência;
- observabilidade de rede;
- arquitetura de clusters.

O troubleshooting realizado durante a implementação também demonstra capacidade de diagnosticar problemas entre diferentes camadas da infraestrutura:

```text
Kubernetes
    │
    ├── CNI
    │
    ├── Cilium
    │
    ├── containerd
    │
    ├── Linux
    │
    └── Networking
```

---

# Próximos passos

Evoluções planejadas para o laboratório:

1. Validar DNS interno do Kubernetes;
2. Validar comunicação Pod-to-Pod;
3. Validar comunicação Pod-to-Service;
4. Implementar NetworkPolicies;
5. Explorar Hubble;
6. Integrar métricas do Cilium ao Prometheus;
7. Integrar dashboards ao Grafana;
8. Avaliar recursos avançados do Cilium;
9. Automatizar testes de rede no CI;
10. Documentar a plataforma Kubernetes completa.

---

# Referências

- Cilium Documentation
- Kubernetes Documentation
- Helm Documentation
- containerd Documentation
- Ansible Documentation