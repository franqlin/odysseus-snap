criar_tabela_report_data() {
    db_path_report="$pasta/reportdata-db.db"
    sqlite3 "$db_path_report" <<EOF
CREATE TABLE IF NOT EXISTS "report" (
    id INTEGER PRIMARY KEY CHECK (id = 1),
    referencia TEXT NOT NULL,
    solicitacao TEXT NOT NULL,
    registro TEXT NOT NULL
);
EOF
    echo "Tabela reportdata criada no banco de dados reportdata-db.db."
}

# Função para criar o banco de dados e a tabela de logs
criar_banco_de_dados() {
    db_path="$pasta/odysseus_snap.db"
    sqlite3 "$db_path" <<EOF
CREATE TABLE IF NOT EXISTS logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    acao TEXT NOT NULL,
    arquivo TEXT,
    info_sistema TEXT NOT NULL,
    data_hora TEXT NOT NULL
);
EOF

    if [ $? -eq 0 ]; then
        echo "Banco de dados e tabela 'logs' criados com sucesso."
    else
        echo "Erro ao criar o banco de dados ou a tabela."
    fi
}    