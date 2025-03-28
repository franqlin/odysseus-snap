

# Função para selecionar a pasta de trabalho
selecionar_pasta() {
    pasta=$(zenity --file-selection --directory --title="Selecione a pasta de trabalho")
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Saindo..."
        exit 1
    fi
    echo "Pasta selecionada: $pasta"
    # Verifica se o arquivo oculto .odysseus_osint_report_session existe
    session_file="$pasta/.odysseus_osint_report_session"    
    # Verifica se a pasta está vazia ou contém o arquivo de sessão
    if [ "$(ls -A "$pasta")" ] && [ ! -f "$session_file" ]; then
        zenity --error --text="A pasta deve estar vazia ou conter ou sessão do Odysseus Report. "
        exit 1
    fi
    #echo "Pasta selecionada: $pasta"
     
    if [ ! -f "$session_file" ]; then
        # Cria o arquivo se não existir
        touch "$session_file"
        echo "opensession: F $(date)" >> "$session_file"
        # Verifica se o arquivo report_build.txt existe
        gravar_log "opensession" "$session_file" "INFO"
        report_file="$pasta/report_build.txt"
        if [ ! -f "$report_file" ]; then
            touch "$report_file"
            echo "Arquivo report_build.txt criado."
        fi
        # Verifica se o banco de dados screencaption-db.db existe
        db_path="$pasta/screencaption-db.db"
        if [ ! -f "$db_path" ]; then
            criar_tabela_screencaption
        fi

        db_path_snap="$pasta/odysseus_snap.db"

        if [ ! -f "$db_path_snap" ]; then
            criar_tabela_odysseus_snap
        fi
                
        db_path_report="$pasta/reportdata-db.db"
        if [ ! -f "db_path_report" ]; then
            criar_tabela_report_data
        fi
                     # Verifica se a pasta "download" existe, caso contrário, cria a pasta
       download_dir="$pasta/downloads"
        if [ ! -d "$download_dir" ]; then
            mkdir "$download_dir"
            echo "Pasta 'downloads' criada em: $download_dir"
        fi 
            

    else
        # Verifica se o arquivo contém a linha "closedsession"
        if grep -q "closedsession:" "$session_file"; then
            last_closed_session=$(grep "closedsession:" "$session_file" | tail -n 1 | cut -d ' ' -f 2-)
            zenity --info --text="Sessão anterior foi fechada em: $last_closed_session"
            #echo "opensession: F $(date)" >> "$session_file"
            #exit 1
    
        else
            echo "opensession: R $(date)" >> "$session_file" 
            gravar_log "opensession" "*" "INFO"
            last_session=$(grep "opensession:" "$session_file" | tail -n 1 | cut -d ' ' -f 3-)
            zenity --info --text="⚠️ Última sessão: $last_session\n\n📂 Pasta de trabalho: $pasta"
            #zenity --info --text=""
        fi
    fi
}
# Função para abrir a pasta de trabalho
abrir_pasta() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
    else
    gravar_log "abrir_pasta" "$pasta" "INFO"
        xdg-open "$pasta"
    fi
}