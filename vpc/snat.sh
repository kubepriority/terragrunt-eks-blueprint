#!/bin/bash
# Amazon Linux NAT Instance User Data
set -x

# Variáveis
VPC=10.212.0.0/16

check_success() {
    if [ $? -ne 0 ]; then
        echo "Error: $1" >&2
        exit 1
    fi
}

# Habilitando IP Forwarding permanentemente
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sysctl -p
check_success "Falha ao habilitar o IP forwarding."

# Instalação do iptables-services
yum install iptables-services -y
check_success "Falha ao instalar iptables-services."

# Configuração do iptables
iptables -t nat -A POSTROUTING -s $VPC -j MASQUERADE
check_success "Falha ao configurar regras do iptables."

iptables-save > /etc/sysconfig/iptables
check_success "Falha ao salvar regras do iptables."

systemctl enable iptables
systemctl restart iptables
check_success "Falha ao reiniciar iptables."

# Ajuste para um grande número de conexões simultâneas
echo "fs.file-max = 1048576" >> /etc/sysctl.conf
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
sysctl -p
check_success "Falha ao ajustar parâmetros do sistema para conexões simultâneas."

retries=5
until [[ $retries == 0 ]] || curl -s http://google.com; do
    let retries--
    sleep 5
done

if [ $retries -eq 0 ]; then
    echo "Conectividade de rede falhou, saindo."
    exit 1
fi

# Reiniciar serviços necessários
systemctl restart amazon-ssm-agent.service
check_success "Falha ao reiniciar o amazon-ssm-agent."

echo "Configuração da NAT Instance concluída com sucesso."