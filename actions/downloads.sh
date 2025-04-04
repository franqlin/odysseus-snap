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


# Função para selecionar uma pasta, copiar arquivos individualmente para $pasta/downloads e salvar no banco de dados
selecionar_pasta_e_processar_arquivos() {
    # Inicializa coleções para arquivos processados com sucesso e erros
    arquivos_processados=()
    erros=()
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta de trabalho selecionada. Selecione uma pasta primeiro."
        return 1
    fi

    # Seleciona a pasta usando o Zenity
    pasta_origem=$(zenity --file-selection --directory --title="Selecione uma pasta contendo os arquivos")
    if [ -z "$pasta_origem" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Operação cancelada."
        return 1
    fi

    # Solicita a descrição e o URL via formulário
    formulario=$(zenity --forms --title="Informações dos Arquivos" \
        --text="Insira as informações que serão aplicadas a todos os arquivos:" \
        --add-entry="Descrição" \
        --add-entry="URL de Registro")
    
    if [ $? -ne 0 ]; then
        zenity --error --text="Formulário cancelado. Operação abortada."
        return 1
    fi
 

    # Extrai os valores do formulário
    description=$(echo "$formulario" | awk -F'|' '{print $1}')
    urlRegistro=$(echo "$formulario" | awk -F'|' '{print $2}')

    # Define o diretório de destino
    destino="$pasta/downloads"

    # Verifica se a pasta de destino existe
    if [ ! -d "$destino" ]; then
        mkdir -p "$destino"
        echo "Pasta 'downloads' criada em: $destino"
    fi

    # Conta o número total de arquivos para a barra de progresso
    total_arquivos=$(find "$pasta_origem" -type f | wc -l)
    progresso=0

    # Exibe uma barra de progresso
    (
        # Processa cada arquivo na pasta selecionada
        for arquivo in "$pasta_origem"/*; do
            if [ -f "$arquivo" ]; then
                # Copia o arquivo para a pasta de destino
                cp "$arquivo" "$destino"
                if [ $? -eq 0 ]; then
                    arquivos_processados+=("$(basename "$arquivo")")
                    echo "Arquivo $(basename "$arquivo") copiado com sucesso para: $destino" >> "$pasta/odysseus_snap.log"
                else
                    # Adiciona o arquivo com erro à pilha de erros
                    erros+=("$(basename "$arquivo")")
                    echo "Erro ao copiar o arquivo $(basename "$arquivo") para: $destino" >> "$pasta/odysseus_snap.log"
                    zenity --error --text="Erro ao copiar o arquivo $(basename "$arquivo") para: $destino"
                    continue
                fi

                # Lê os dados do arquivo na nova pasta de destino
                novo_arquivo="$destino/$(basename "$arquivo")"
                local filename=$(basename "$novo_arquivo")
                local basepath="$destino"
                local hash=$(sha256sum "$novo_arquivo" | awk '{print $1}')
                local type="3"

                # Salvar os dados no banco de dados
                salvar_dados_tabela "$novo_arquivo" "$filename" "$hash" "$description" "$type" "$urlRegistro"
                if [ $? -eq 0 ]; then
                    echo "Dados do arquivo $(basename "$arquivo") salvos no banco de dados com sucesso." >> "$pasta/odysseus_snap.log"
                else 
                    echo "Erro ao salvar os dados do arquivo $(basename "$arquivo") no banco de dados." >> "$pasta/odysseus_snap.log"
                    continue
                fi

                # Gravar log para o arquivo
                gravar_log "Arquivo Copiado" "Arquivo: $novo_arquivo\nDescrição: $description\nURL Registro: $urlRegistro"
            fi

            # Atualiza o progresso
            progresso=$((progresso + 1))
            echo $((progresso * 100 / total_arquivos))
        done
    ) | zenity --progress --title="Processando Arquivos" --text="Esse processo pode demorar..." --percentage=0 --auto-close

    # Exibe mensagem final
    if [ ${#erros[@]} -eq 0 ]; then
        zenity --info --text="Todos os arquivos foram processados com sucesso."
    else
        zenity --warning --text="Alguns arquivos não foram processados. Verifique o log para mais detalhes."
    fi


}