# Função para verificar se o caso já foi fechado
verificar_caso_fechado() {
    if grep -q "closedsession:" "$session_file"; then
        zenity --info --text="O caso já foi fechado."
        return 0
    else
        return 1
    fi
}


abrir_url() {
    url=$(zenity --entry --title="Abrir URL" --text="Digite a URL que deseja abrir:")
    if [ -n "$url" ]; then
        firefox --new-tab "$url"
        echo "$url" >> "$pasta/report_build.txt"
        zenity --info --text="URL aberta em uma nova aba do Firefox."
    else
        zenity --error --text="Nenhuma URL fornecida."
    fi
}
fechar_e_abrir_firefox() {
    # Verifica se há instâncias do Firefox em execução
    if ! verificar_caso_fechado; then
        
        if pgrep google-chrome > /dev/null; then
            # Fecha todas as instâncias do Firefox
            pkill google-chrome
            #zenity --info --text="Todas as instâncias do Firefox foram fechadas."
        fi

        # Abre uma nova sessão do Firefox sem abas abertas
        google-chrome --proxy-server="http://localhost:8080" --new-instance about:blank &
        # Cria o arquivo requests.txt na pasta de trabalho e escreve a primeira linha
        #echo "Relatório de Requisição" >> "$pasta/requests.txt"
        echo "" >> "$pasta/report_build.txt"
        #zenity --info --text="Nova sessão do Firefox iniciada."
    fi
}
closedsession() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi
    session_file="$pasta/.odysseus_osint_report_session"
    if [ ! -f "$session_file" ]; then
        zenity --error --text="Arquivo de sessão não encontrado."
        return
    fi
    if grep -q "closedsession:" "$session_file"; then
        zenity --info --text="Sessão já foi fechada."
    else
        echo "closedsession: $(date)" >> "$session_file"
        zenity --info --text="Sessão fechada com sucesso."
        gravar_log "Sessão" "Sessão fechada com sucesso."
        parar_interceptacao; 
        
    fi
}