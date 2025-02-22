# Função para obter informações do sistema
obter_info_sistema() {
    echo "Data e Hora: $(date)"
    echo "Host: $(hostname)"
    echo "Usuário: $(whoami)"
    echo "IP: $(hostname -I | awk '{print $1}')"
}