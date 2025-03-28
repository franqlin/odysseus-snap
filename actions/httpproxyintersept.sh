
# Função para interceptar endereços
interceptar_enderecos() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    output_log="$pasta/requests.txt"

    # Verifica se o mitmproxy está instalado
    if ! command -v mitmproxy &> /dev/null; then
        zenity --error --text="mitmproxy não está instalado. Instale-o usando 'sudo apt-get install mitmproxy'."
        return
    fi

    # Cria o script de filtro Python dinamicamente com o caminho correto do arquivo de log
    filtro_py="$pasta/filter.py"
    cat <<EOF > "$filtro_py"
from mitmproxy import http
from datetime import datetime

def request(flow: http.HTTPFlow) -> None:
    # Verifica se é uma requisição de clique em um link
    if (
        "Referer" in flow.request.headers  # Tem cabeçalho Referer (indicando que veio de uma página anterior)
        and flow.request.method == "GET"   # Método GET
        and not flow.request.headers.get("Content-Type", "").startswith(("text/css", "image/", "application/javascript"))  # Exclui recursos secundários
        and not any(ext in flow.request.pretty_url for ext in [".js", ".css", ".png", ".jpg", ".gif", ".ico", ".svg",".mp4"])  # Exclui recursos secundários
    ):
        # Loga a requisição de clique em um link
        log_message = f"Data e Hora: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n"
        log_message += f"link: {flow.request.pretty_url}\n"
        log_message += f"Referer: {flow.request.headers['Referer']}\n"
        #log_message += f"Cabeçalho: {flow.request.headers}\n\n"
        
        # Escreve no arquivo request.txt
        with open("$output_log", "a") as file:
            file.write(log_message)
        
        # Exemplo de modificação da requisição
        flow.request.headers["X-Link-Click"] = "True"
EOF
    chmod +777 "$filtro_py"
    # Inicia o mitmproxy com o script de filtro
    xterm -e "mitmproxy -s \"$filtro_py\" --set output_log=\"$output_log\"; exec bash &"& 
    mitmproxy_pid=$!
    echo $mitmproxy_pid > /tmp/mitmproxy_pid
    #zenity --info --text="Interceptação de endereços iniciada. PID: $mitmproxy_pid"
}
# Função para parar a interceptação de endereços
parar_interceptacao() {
    if [ -f /tmp/mitmproxy_pid ]; then
        mitmproxy_pid=$(cat /tmp/mitmproxy_pid)
        if [ -n "$mitmproxy_pid" ]; then
            kill $mitmproxy_pid
            rm /tmp/mitmproxy_pid
            #zenity --info --text="Interceptação parada. Arquivo salvo em $output_log"
        fi
    fi
# Fecha a instância aberta do Firefox
if pgrep firefox > /dev/null; then
    pkill firefox
    #zenity --info --text="Instância do Firefox fechada."
fi
if  pgrep tail > /dev/null; then
    pkill tail
    #zenity --info --text="Instância do Firefox fechada."
fi
if pgrep zenity > /dev/null; then
    pkill zenity
    echo
fi
   gravar_log "Interceptação" "Sessão encerrada."   
}