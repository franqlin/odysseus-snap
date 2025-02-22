# Função para gravar log
gravar_log() {
    local acao=$1
    local arquivo=$2
    {
        obter_info_sistema
        echo "Ação: $acao"
        echo "Arquivo: $arquivo"
        echo "-------------------------"
    } >> "$pasta/odysseus_snap.log"
}