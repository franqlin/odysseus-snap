KEY=$RANDOM
# Função para capturar uma área da tela
capturar_area() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    urlRegistro=$(yad --form --title="Captura de Tela" --window-icon="dialog-warning" --text="Selecione uma área da tela para capturar. \nRegistre a URL caso necessário." --field="URL: " | awk -F'|' '{print $1}')
    
    echo "DEBUG URL: $urlRegistro"

    # Define o nome do arquivo como screenshot_data_hora
    timestamp=$(date +"%Y%m%d_%H%M%S")
    
    # Cria a pasta images na pasta de trabalho, se não existir
    mkdir -p "$pasta/images"
    
    # Define o caminho completo do arquivo de captura de tela
    screenshot_file="$pasta/images/screenshot_$timestamp.png"
   

    # Captura a área selecionada e desenha uma linha vermelha de 3 pixels de largura ao redor da área selecionada
     maim -s -u -b 3 -c 0.8,0,0,0.5 "$screenshot_file" 

    # Copia a imagem para a área de transferência
    xclip -selection clipboard -t image/png -i "$screenshot_file"
    
    # Obtém informações da janela selecionada
    window_info=$(xwininfo)
    window_id=$(echo "$window_info" | grep 'Window id:' | awk '{print $4}')
    window_name=$(xprop -id "$window_id" | grep 'WM_NAME(STRING)' | cut -d '"' -f 2)
    
    # Obtém a URL da aba ativa se for um navegador
    
    
    # Exibe mensagem de confirmação
    #zenity --info --text="Captura de tela salva em $screenshot_file"
    
    # Abre a captura de tela com o visualizador de imagens padrão
    #xdg-open "$screenshot_file"
    # Abre a captura de tela com yad e solicita uma descrição
    #yad --image="$screenshot_file" --title="Captura de Tela" --text="Descreva a captura de tela:" --button="gtk-ok:0" --button="gtk-cancel:1" --entry
    #description=$(yad --image="$screenshot_file" --title="Captura de Tela" --button="gtk-cancel:1" --button="gtk-ok:0" --text="Descreva a captura de tela:" --entry)
    description=$(yad --plug=$KEY --tabnum=1 --form --field="Descrição" &\
    yad --plug=$KEY --tabnum=2 --picture --width=700 --height=500 --file-op size-fit --filename="$screenshot_file" & \
    yad --paned --key=$KEY --button="Continue:0" --width=700 --height=500 \
    --title="Screencaption - Save" --window-icon="find" | awk -F'|' '{print $1}' | sed 's/|$//')
    
    yad --image="dialog-question" \
  --title "Alert" \
  --text "Deseja salvar os dados da captura de Tela " \
  --button="Sim:0" \
  --button="Não:1" \

    ret=$?
    echo "Descrição: $description" >> "$pasta/odysseus_snap.log"
    echo "Valor de retorno do yad: $yad_exit_status"
    if [ $ret -eq 1 ]; then
        rm "$screenshot_file"
        yad --info --text="Captura de tela cancelada." --button="gtk-ok:0"
    else
     

    # Calcula o hash do arquivo de captura de tela
    hash=$(sha256sum "$screenshot_file" | awk '{print $1}')
    
    echo "Hash: $hash"
    
    
    # Salva os dados na tabela screenshot
    description=$(echo "$description" | sed 's/|//g')
    echo "DEBUG: SALVANDO NA TABELA__: $screenshot_file" >> "$pasta/odysseus_snap.log"
        echo "Arquivo de Captura de Tela: $screenshot_file"
        echo "Nome do Arquivo: $(basename $screenshot_file)"
        echo "Hash: $hash"
        echo "Descrição: $description"
        echo "URL Registro: $urlRegistro"
    salvar_dados_tabela "$screenshot_file" "$(basename $screenshot_file)" "$hash" "$description" "1" "$urlRegistro"
          
        
        yad --info --text="Captura de tela salva em $screenshot_file" --button="gtk-ok:0"
    fi

    # Grava log da ação
    {
        echo "Janela Selecionada: $window_name"
        echo "Informações da Janela:"
        echo "$window_info"
        echo "URL: $url"
    } >> "$pasta/odysseus_snap.log"
    gravar_log "Captura de Tela" "$screenshot_file \n $window_info \n JANELA: $url"
    #echo "CAPTURA_DE_TELA__: $screenshot_file" >> "$pasta/report_build.txt"
}