# Função para monitorar requests.txt em uma thread separada
monitorar_requests() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    tail -f "$pasta/requests.txt" | zenity --text-info --title="Monitorar requests.txt" --width=800 --height=600 &
    tail_pid=$!
}