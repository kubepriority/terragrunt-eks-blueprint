# Exemplo de terraform-aws-nat-instance

Este exemplo mostra as seguintes coisas:

- Criar uma VPC e sub-redes usando o módulo `vpc`.
- Criar uma instância NAT usando este módulo.
- Criar uma instância na sub-rede privada.
- Adicionar scripts personalizados à instância NAT.
Neste exemplo, a porta http da instância privada será exposta.

## Começando
Provisione o stack.


```console
% terragrunt init
% terragrunt apply
...

Outputs:

nat_public_ip = 54.xx.155.xx
private_instance_id = i-07c076946c514xxxx
```

Certifique-se de ter acesso à instância na sub-rede privada.

```console
% aws ssm start-session --region sa-east-1 --target i-07c076946c514xxxx
```

Certifique-se de que você possa acessar a porta http da instância NAT.

```console
% curl http://54.xx.155.xx
```

Você pode destruir completamente o stack.

```console
% terragrunt destroy
```