# Função para gravar a tela
gravar_tela() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    zenity --info --text="Selecione a área da tela que deseja gravar."

    # Obtém a geometria da área selecionada
    geometry=$(slop -f "%x %y %w %h" -b 5 -c 0.8,0,0,0.5 )
    read -r x y width height <<< "$geometry"

    # Obtém informações da janela selecionada
    window_info=$(xwininfo)
    window_id=$(echo "$window_info" | grep 'Window id:' | awk '{print $4}')
    window_name=$(xprop -id "$window_id" | grep 'WM_NAME(STRING)' | cut -d '"' -f 2)

    # Encontra o próximo número disponível para o screencast
    for i in $(seq 1 10000); do
        if [ ! -f "$pasta/screencast_$i.mp4" ]; then
            # Inicia a gravação em segundo plano
            audio_option=$(zenity --list --title="Opção de Áudio" --column="Opção" "Com Áudio" "Sem Áudio" --height=200 --width=300 --text="Deseja capturar com áudio?" --hide-header)

            if [ "$audio_option" == "Com Áudio" ]; then
                ffmpeg -video_size "${width}x${height}" -framerate 25 -f x11grab -i :0.0+$x,$y -f alsa -i default \
                    "$pasta/screencast_$i.mp4" &
            else
                ffmpeg -video_size "${width}x${height}" -framerate 25 -f x11grab -i :0.0+$x,$y \
                    "$pasta/screencast_$i.mp4" &
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
            zenity --info --text="Gravação de tela salva em $pasta/screencast_$i.mp4"
            
            # Grava log da ação
            {
                echo "Janela Selecionada: $window_name"
                echo "Informações da Janela:"
                echo "$window_info"
            } >> "$pasta/odysseus_snap.log"
            gravar_log "Gravação de Tela" "$pasta/screencast_$i.mp4 \n $window_info \n JANELA: $window_name"
            echo "CAPTURA_DE_TELA__: $pasta/screencast_$i.mp4" >> "$pasta/report_build.txt"
            break
        fi
    done
}