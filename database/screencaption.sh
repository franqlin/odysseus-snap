# Função para criar a tabela screencaption no banco de dados screencaption-db
criar_tabela_screencaption() {
    db_path="$pasta/screencaption-db.db"
    sqlite3 "$db_path" <<EOF
CREATE TABLE IF NOT EXISTS screencaption (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    filename TEXT NOT NULL,
    basepath TEXT NOT NULL,
    hash TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL
);
EOF
    echo "Tabela screencaption criada no banco de dados screencaption-db.db."
}
salvar_dados_tabela() {
        local filename="$1"
        local basepath="$2"
        local hash="$3"
        local description="$4"
        local type="$5"
        
        # Comando SQL para inserir os dados na tabela screenshot
        sqlite3 $pasta/screencaption-db.db <<EOF
INSERT INTO screencaption (filename, basepath, hash, description,type)
VALUES ('$filename','$basepath', '$hash', '$description', '$type');
EOF
}