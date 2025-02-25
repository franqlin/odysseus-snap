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
    type TEXT NOT NULL,
    urlRegistro TEXT  NULL   
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
        local urlRegistro="$6"
        
        # Comando SQL para inserir os dados na tabela screenshot
        sqlite3 $pasta/screencaption-db.db <<EOF
INSERT INTO screencaption (filename, basepath, hash, description,type,urlRegistro)
VALUES ('$filename','$basepath', '$hash', '$description', '$type','$urlRegistro');
EOF
}

exibir_dados_tabela_screen() {
    db_path="$pasta/screencaption-db.db"
    dados=$(sqlite3 "$db_path" "SELECT id,filename FROM screencaption;")
    
    # Formata os dados para exibição no yad
    formatted_data=""
    while IFS="|" read -r id filename; do
        formatted_data+="$id $filename "
    done <<< "$dados"
    
    # Exibe os dados no yad e permite selecionar um registro para edição
    selected=$(yad --list --title="Dados da Tabela Screencaption" --column="ID" --column="Filename" --width=800 --height=600 --text-align=center --dclick-action="deletar_dados_tabela_screen" --button="Editar:0" --button="Deletar:3" $formatted_data)
    
    if [ $? -eq 0 ]; then
        editar_dados_tabela_screen "$selected"
    fi
}
deletar_dados_tabela_screen(){
    IFS="|" read -r id  <<< "$1"
    echo "Linha recebida: $1"
   
    # Extraindo o valor do id da linha recebida, considerando que os campos são separados por "|"
    id=$(echo "$1" | cut -d'|' -f1)
    echo "Parametro id: $id"
    sqlite3 "$pasta/screencaption-db.db" <<EOF
DELETE FROM screencaption WHERE id=$id;
EOF
    yad --info --text="Registro deletado com sucesso!" --button="OK"
}

editar_dados_tabela_screen() {
    IFS="|" read -r id  <<< "$1"
    echo "Linha recebida: $1"
   
    # Extraindo o valor do id da linha recebida, considerando que os campos são separados por "|"
    id=$(echo "$1" | cut -d'|' -f1)
    echo "Parametro id: $id"
    # Busca os valores atuais dos campos para o registro com o id fornecido
    record=$(sqlite3 "$pasta/screencaption-db.db" "SELECT filename, basepath, hash, description, urlRegistro FROM screencaption WHERE id=$id;")
    IFS="|" read -r filename_ basepath_ hash_ description_  urlRegistro_ <<< "$record"
    echo "Dados atuais do registro:"
    echo "Filename: $filename_"
    echo "Basepath: $basepath_"
    echo "Hash: $hash_"
    echo "Description: $description_"
    echo "URL Registro: $urlRegistro_"

filename="$filename_"
basepath="$basepath_"
hash="$hash_"
description="$description_"
urlRegistro="$urlRegistro_"
    
    # Abre uma janela yad para editar os dados
edited=$(yad --form --title="Editar Dados"  --field="Filename":RO --field="Basepath":RO --field="Hash":RO --field="Description"  --field="URL Registro" --width=400 --height=300  --  "$filename" "$basepath" "$hash" "$description" "$urlRegistro")
    
if [ $? -ne 0 ]; then
    return
fi    
IFS="|" read -r filename basepath hash description  urlRegistro <<< "$edited"
# Atualiza os dados no banco de dados
echo "Dados Editados:"
echo "Filename: $filename"
echo "Basepath: $basepath"
echo "Hash: $hash"
echo "Description: $description"
echo "URL Registro: $urlRegistro"
sqlite3 "$pasta/screencaption-db.db" <<EOF
UPDATE screencaption SET description='$description', urlRegistro='$urlRegistro' WHERE id=$id;
EOF

yad --info --text="Dados atualizados com sucesso!" --button="OK"
}