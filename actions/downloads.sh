# Função para selecionar um arquivo, copiá-lo para a pasta $pasta/downloads e salvar os dados no banco de dados
selecionar_arquivo_e_copiar() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta de trabalho selecionada. Selecione uma pasta primeiro."
        return 1
    fi

    # Seleciona o arquivo usando o Zenity
    arquivo=$(zenity --file-selection --title="Selecione um arquivo para copiar para downloads")
    if [ -z "$arquivo" ]; then
        zenity --error --text="Nenhum arquivo selecionado. Operação cancelada."
        return 1
    fi

    # Verifica se o arquivo selecionado existe
    if [ ! -f "$arquivo" ]; then
        zenity --error --text="O arquivo selecionado não existe. Operação cancelada."
        return 1
    fi

    # Define o diretório de destino
    destino="$pasta/downloads"

    # Verifica se a pasta de destino existe
    if [ ! -d "$destino" ]; then
        mkdir -p "$destino"
        echo "Pasta 'downloads' criada em: $destino"
    fi
    
    # Copia o arquivo para a pasta de destino
    cp "$arquivo" "$destino"
    if [ $? -eq 0 ]; then
        zenity --info --text="Arquivo copiado com sucesso para: $destino"
    else
        zenity --error --text="Erro ao copiar o arquivo para: $destino"
        return 1
    fi

    # Solicita a descrição e o URL via formulário
    formulario=$(zenity --forms --title="Informações do Arquivo" \
        --text="Insira as informações do arquivo:" \
        --add-entry="Descrição" \
        --add-entry="URL de Registro")
    
    if [ $? -ne 0 ]; then
        zenity --error --text="Formulário cancelado. Operação abortada."
        return 1
    fi

    # Extrai os valores do formulário
    description=$(echo "$formulario" | awk -F'|' '{print $1}')
    urlRegistro=$(echo "$formulario" | awk -F'|' '{print $2}')
    
    # Lê os dados do arquivo na nova pasta de destino
    novo_arquivo="$destino/$(basename "$arquivo")"
   
    # Salvar os dados no banco de dados
    # $screenshot_file" "$(basename $screenshot_file)"
    local filename="$novo_arquivo"
    local basepath=$(basename "$novo_arquivo")
    local hash=$(sha256sum "$novo_arquivo" | awk '{print $1}')
    local type="3"

    salvar_dados_tabela "$filename" "$basepath" "$hash" "$description" "$type" "$urlRegistro"
    if [ $? -eq 0 ]; then
        zenity --info --text="Dados do arquivo salvos no banco de dados com sucesso."
    else
        zenity --error --text="Erro ao salvar os dados no banco de dados."
    fi
    gravar_log "Arquivo Copiado" "$novo_arquivo    \n Descrição: $description \n URL Registro: $urlRegistro"
}