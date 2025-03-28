# Função para gravar log
gravar_log() {
    local acao=$1
    local arquivo=$2

    local data_hora=$(date '+%Y-%m-%d %H:%M:%S')
    local inicio_periodo=$(date --date="7 days ago" '+%Y-%m-%d %H:%M:%S')
    local fim_periodo=$(date '+%Y-%m-%d %H:%M:%S')
    
    local username=$(whoami)
    local ip=$(hostname -I | awk '{print $1}')
    local host=$(hostname)
    local info_sistema+=" | Username: $username | IP: $ip | Host: $host"

    # Captura os logs do sistema no período especificado
   
    {
        echo "Data e Hora: $data_hora"
        obter_info_sistema
        echo "Ação: $acao"
        echo "Arquivo: $arquivo"
        
    } >> "$pasta/odysseus_snap.log"
    

    echo "Log registrado com sucesso no arquivo odysseus_snap.log."
    db_path="$pasta/odysseus_snap.db"

    #criar_log_sistema_operacional


    # Verifica se o banco de dados existe
    if [ ! -f "$db_path" ]; then
        echo "Banco de dados não encontrado. Criando banco de dados..."
        criar_banco_de_dados
    fi

    # Insere o log no banco de dados
    sqlite3 "$db_path" <<EOF
INSERT INTO logs (acao, arquivo, info_sistema, data_hora)
VALUES ('$acao', '$arquivo', '$info_sistema', '$data_hora');
EOF

    if [ $? -eq 0 ]; then
        echo "Log registrado com sucesso no banco de dados."
    else
        echo "Erro ao registrar o log no banco de dados."
    fi
}

# Função para criar log do sistema operacional
criar_log_sistema_operacional() {
    db_path="$pasta/odysseus_snap.db"
    local inicio_periodo=$(sqlite3 "$db_path" "SELECT MIN(data_hora) FROM logs;" )
    local fim_periodo=$(sqlite3 "$db_path" "SELECT MAX(data_hora) FROM logs;")
    local log_file="LogSistemaOperacional.log"

    echo "Criando log do sistema operacional..."
    logs_sistema=$(journalctl --since "$inicio_periodo" --until "$fim_periodo" --no-pager)
    echo "$logs_sistema" > "$pasta/$log_file"

    echo "Arquivo de log do sistema operacional criado: $log_file"
    echo "----------Logs do Sistema (Período Especificado)-------------"
    echo "$logs_sistema"
    echo "-------------------------------------------------------------"
}