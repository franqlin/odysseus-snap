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

    