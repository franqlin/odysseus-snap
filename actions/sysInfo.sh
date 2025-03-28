# Função para obter informações do sistema
obter_info_sistema() {
   
    echo "Host: $(hostname)"
    echo "Usuário: $(whoami)"
    echo "IP: $(hostname -I | awk '{print $1}')"
    echo "Sistema Operacional: $(uname -o)"
    echo "Kernel: $(uname -r)"
    echo "Arquitetura: $(uname -m)"
    echo "DNS configurado: $(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}')"
    echo "Gateway padrão: $(ip route | grep 'default' | awk '{print $3}')"
}

obter_processos(){
    echo "Processos em execução: $(ps -e | wc -l)"
    echo "Processos em execução: $(ps -e)"
}