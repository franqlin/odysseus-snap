# Função para gravar a tela
gravar_tela() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi


    yad --info --text="Selecione a área da tela que deseja gravar." --window-icon="dialog-warning"

    # Obtém a geometria da área selecionada
    geometry=$(slop -f "%x %y %w %h" -b 5 -c 0.8,0,0,0.5 )
    read -r x y width height <<< "$geometry"

    # Obtém informações da janela selecionada
    window_info=$(xwininfo)
    window_id=$(echo "$window_info" | grep 'Window id:' | awk '{print $4}')
    window_name=$(xprop -id "$window_id" | grep 'WM_NAME(STRING)' | cut -d '"' -f 2)

    # Encontra o próximo número disponível para o screencast
    timestamp=$(date +"%Y%m%d_%H%M%S")
    mkdir -p "$pasta/videos"
    screencast_file="$pasta/videos/screencast_$timestamp.mp4"
    # Inicia a gravação em segundo plano
    audio_option=$(zenity --list --title="Opção de Áudio" --column="Opção" "Com Áudio" "Sem Áudio" --height=200 --width=300 --text="Deseja capturar com áudio?" --hide-header)

    if [ "$audio_option" == "Com Áudio" ]; then
        ffmpeg -video_size "${width}x${height}" -framerate 25 -f x11grab -i :0.0+$x,$y -f alsa -i default \
            "$screencast_file" &
    else
        ffmpeg -video_size "${width}x${height}" -framerate 25 -f x11grab -i :0.0+$x,$y \
            "$screencast_file" &
    fi
    ffmpeg_pid=$!

    # Mostra uma splash screen enquanto grava
    (
        zenity --info --text="Gravando tela!" --title="Gravação em andamento" --no-wrap &
        zenity_pid=$!
        wait $ffmpeg_pid
        kill $zenity_pid
    ) &

    # Cria um botão flutuante para interromper a gravação
    zenity --info --text="Clique em OK para parar a gravação." --title="Parar Gravação"
    
    # Interrompe a gravação
    kill $ffmpeg_pid
    xdg-open "$screencast_file"

   # yad --text-info --wrap --margins=20 --width=600 --height=400 --title="Descrição da Captura de Tela" --text="Descreva a captura de tela:" --button="gtk-ok:0" --button="gtk-cancel:1" --entry
    description=$(yad --text-info --wrap --margins=10 --width=300 --height=200 --title="Descrição da Captura de Tela" --text="Descreva a captura de tela:" --button="SALVAR:0" --button="DELETAR:1" --entry) 
    ret=$?
    echo "DEBUG: " $description
    if [ $ret -eq 1 ]; then
        rm "$screencast_file"
        yad --info --text="Captura de tela cancelada." --button="gtk-ok:0"
    else
     

    # Calcula o hash do arquivo de captura de tela
    hash=$(sha256sum "$screencast_file" | awk '{print $1}')
    
    echo "Hash: $hash"
    
    
    # Salva os dados na tabela screenshot
    salvar_dados_tabela "$screencast_file" "$(basename $screencast_file)" "$hash" "$description" "2"
    echo "DEBUG: SALVANDO NA TABELA__"      
        
        yad --info --text="Captura de tela salva em $screencast_file" --button="gtk-ok:0"
    fi

    # Grava log da ação
    {
        echo "Janela Selecionada: $window_name"
        echo "Informações da Janela:"
        echo "$window_info"
        echo "URL: $url"
    } >> "$pasta/odysseus_snap.log"
    gravar_log "Captura de Tela" "$screencast_file \n $window_info \n JANELA: $url"
    #echo "CAPTURA_DE_TELA__: $$screencast_file" >> "$pasta/report_build.txt"
}