# Projeto Terragrunt EKS Blueprint

## Descrição

Este projeto utiliza o Terragrunt e Terraform para provisionar um ambiente Kubernetes na AWS usando o Amazon EKS. Ele inclui a configuração de uma VPC, um cluster EKS, um Application Load Balancer (ALB) configurado com o Nginx Ingress Controller para roteamento de tráfego, e a instalação do Rancher para gerenciamento do cluster.

## Estrutura do Repositório

O repositório está organizado nas seguintes pastas e arquivos principais:

- `eks-blueprint-prd`: Contém os arquivos de configuração do Terragrunt para provisionar o cluster EKS no ambiente de produção.
- `load-balancer`: Configura um ALB e instala o Nginx Ingress Controller.
- `rancher`: Responsável pela instalação e configuração do Rancher.
- `vpc`: Define a rede VPC onde o cluster EKS e outros recursos serão implantados.
- `.gitignore`: Lista de arquivos e pastas ignorados pelo Git.
- `LICENSE`: O arquivo de licença do projeto.
- `README.md`: Este arquivo, com informações sobre o projeto, como usar, etc.
- `locals.hcl`: Arquivo com definições de variáveis locais usadas em várias configurações do Terragrunt.
- `terragrunt.hcl`: Arquivo de configuração principal do Terragrunt.
- `version.tf`: Define as versões do Terraform e dos provedores utilizados.

## Pré-requisitos

- Terraform >= 1.7.3
- Terragrunt >= v0.48.1
- AWS CLI configurado com credenciais apropriadas

## Como Usar

Para utilizar este projeto, siga os passos abaixo, começando obrigatoriamente pelo módulo de VPC seguido pelo EKS:

### Provisionando a VPC

Navegue até o diretório da VPC e execute:

```sh
cd vpc
terragrunt apply --var-file=terraform.tfvar
```

### Provisionando o Cluster EKS

```sh
cd eks-blueprint-prd
terragrunt apply --var-file=terraform.tfvar
``` 

### Configurando o ALB e o Nginx Ingress Controller

```sh
cd load-balancer
terragrunt apply
```

### Instalando o Rancher

```sh
cd rancher
terragrunt apply --var-file=terraform.tfvar
```
>Repita o processo para outros componentes conforme necessário, ajustando o caminho para o diretório correspondente.