#!/bin/bash
$tinyproxy_pid
# Verifica se o scrot está instalado
if ! command -v scrot &> /dev/null
then
    echo "scrot não está instalado. Instalando..."
    sudo apt-get install scrot -y
fi

# Verifica se o zenity está instalado
if ! command -v zenity &> /dev/null
then
    echo "zenity não está instalado. Instalando..."
    sudo apt-get install zenity -y
fi

# Verifica se o ffmpeg está instalado
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg não está instalado. Instalando..."
    sudo apt-get install ffmpeg -y
fi

# Verifica se o ImageMagick está instalado
if ! command -v convert &> /dev/null
then
    echo "ImageMagick não está instalado. Instalando..."
    sudo apt-get install imagemagick -y
fi

# Verifica se o exiftool está instalado
if ! command -v exiftool &> /dev/null
then
    echo "exiftool não está instalado. Instalando..."
    sudo apt-get install exiftool -y
fi

# Verifica se o pandoc está instalado
if ! command -v pandoc &> /dev/null
then
    echo "pandoc não está instalado. Instalando..."
    sudo apt-get install pandoc -y
fi

# Verifica se o slop está instalado
if ! command -v slop &> /dev/null
then
    echo "slop não está instalado. Instalando..."
    sudo apt-get install slop -y
fi
# Verifica se o maim está instalado
if ! command -v maim &> /dev/null
then
    echo "maim não está instalado. Instalando..."
    sudo apt-get install maim -y
fi
if ! command -v xclip &> /dev/null
then
    echo "xclip não está instalado. Instalando..."
    sudo apt-get install xclip -y
fi
# Verifica se o Tinyproxy está instalado
if ! command -v tinyproxy &> /dev/null
then
    echo "Tinyproxy não está instalado. Instalando..."
    sudo apt-get install tinyproxy -y
fi
# Função para selecionar a pasta de trabalho
selecionar_pasta() {
    pasta=$(zenity --file-selection --directory --title="Selecione a pasta de trabalho")
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Saindo..."
        exit 1
    fi
    echo "Pasta selecionada: $pasta"
}
# Função para obter informações do sistema
obter_info_sistema() {
    echo "Data e Hora: $(date)"
    echo "Host: $(hostname)"
    echo "Usuário: $(whoami)"
    echo "IP: $(hostname -I | awk '{print $1}')"
}

# Função para gravar log
gravar_log() {
    local acao=$1
    local arquivo=$2
    {
        obter_info_sistema
        echo "Ação: $acao"
        echo "Arquivo: $arquivo"
        echo "-------------------------"
    } >> "$pasta/odysseus_snap.log"
}
# Função para capturar uma área da tela
capturar_area() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    zenity --info --text="Selecione uma área da tela para capturar."
    
    # Define o nome do arquivo como screenshot_data_hora
    timestamp=$(date +"%Y%m%d_%H%M%S")
    screenshot_file="$pasta/screenshot_$timestamp.png"

    # Captura a área selecionada e desenha uma linha vermelha de 3 pixels de largura ao redor da área selecionada
     maim -s -u -b 3 -c 0.8,0,0,0.5 "$screenshot_file" 

    # Copia a imagem para a área de transferência
    xclip -selection clipboard -t image/png -i "$screenshot_file"
    
    # Obtém informações da janela selecionada
    window_info=$(xwininfo)
    window_id=$(echo "$window_info" | grep 'Window id:' | awk '{print $4}')
    window_name=$(xprop -id "$window_id" | grep 'WM_NAME(STRING)' | cut -d '"' -f 2)
    
    # Obtém a URL da aba ativa se for um navegador
    url=$(xdotool getactivewindow getwindowname | awk -F' - ' '{print $1}')
    
    # Exibe mensagem de confirmação
    zenity --info --text="Captura de tela salva em $screenshot_file"
    
    # Abre a captura de tela com o visualizador de imagens padrão
    xdg-open "$screenshot_file"
    
    # Grava log da ação
    {
        echo "Janela Selecionada: $window_name"
        echo "Informações da Janela:"
        echo "$window_info"
        echo "URL: $url"
    } >> "$pasta/odysseus_snap.log"
    gravar_log "Captura de Tela" "$screenshot_file \n $window_info \n JANELA: $url"
    echo "CAPTURA DE TELA: $screenshot_file" >> "$pasta/report_build.txt"
}

relatorio_final() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    report_file="$pasta/report_build.txt"
    if [ ! -f "$report_file" ]; then
        zenity --error --text="Arquivo report_build.txt não encontrado na pasta de trabalho."
        return
    fi

    pasta_saida=$(zenity --file-selection --directory --title="Selecione a pasta de saída do relatório final")
    if [ -z "$pasta_saida" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Saindo..."
        return
    fi

    TEMP_FILE=$(mktemp /tmp/relatorio_final.XXXXXX.html)
    OUTPUT_FILE_PDF="$pasta_saida/relatorio_final.pdf"

    # Cabeçalho do arquivo HTML
    cat <<EOF > "$TEMP_FILE"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Relatório Final</title>
<style>
body { font-family: Arial, sans-serif; }
h2 { color: #2E8B57; }
pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
img { max-width: 100%; height: auto; }
</style>
</head>
<body>
<h1>Relatório Automático de Evidência(s) Digital(is) </h1>
<h2>Informações do Sistema</h2>
<pre>$(obter_info_sistema)</pre>
<h2>Introdução Técnica</h2>
<p>Este relatório foi gerado automaticamente pelo Odysseus SNAP, uma ferramenta de coleta de evidências digitais para investigações forenses. O relatório contém informações sobre arquivos, metadados e capturas de tela capturadas durante a investigação.além de aplicar funções hash conhecidas para garantir a integridade dos dados. </p>
<h2>Funções Hash e Integridade</h2>
<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>
<h2>Lista de Arquivos</h2>
EOF

    while IFS= read -r line; do
        if [[ "$line" == URL:* ]]; then
            url="${line#URL: }"
            echo "<h2>URL: <a href=\"$url\">$url</a></h2>" >> "$TEMP_FILE"
        elif [[ "$line" == CAPTURA\ DE\ TELA:* ]]; then
            screenshot_file="${line#CAPTURA DE TELA: }"
            exif_info=$(exiftool "$screenshot_file")
            hash=$(sha256sum "$screenshot_file" | awk '{print $1}')
            echo "<h3>$(basename "$screenshot_file")</h3>" >> "$TEMP_FILE"
            if [[ "$screenshot_file" =~ \.mp4$ ]]; then
                mkdir -p "$pasta/thumbnails"
                thumbnail_file="$pasta/thumbnails/$(basename "${screenshot_file%.mp4}_thumbnail.png")"
                ffmpeg -i "$screenshot_file" -ss 00:00:01.000 -vframes 1 "$thumbnail_file"
                echo "<video controls style=\"width:300px;height:auto;\"><source src=\"file://$(realpath "$screenshot_file")\" type=\"video/mp4\"></video>" >> "$TEMP_FILE"
                echo "<img src=\"file://$(realpath "$thumbnail_file")\" alt=\"Thumbnail\" style=\"width:300px;height:auto;\">" >> "$TEMP_FILE"
                mkdir -p "$pasta_saida/imagens"
                cp "$screenshot_file" "$pasta_saida/imagens/"
            else
                echo "<img src=\"file://$(realpath "$screenshot_file")\" alt=\"$(basename "$screenshot_file")\" style=\"width:300px;height:auto;\">" >> "$TEMP_FILE"
                mkdir -p "$pasta_saida/imagens"
                cp "$screenshot_file" "$pasta_saida/imagens/"
                echo "<p><a href=\"file://$(realpath "./imagens/$(basename "$screenshot_file")")\">Clique aqui para acessar o arquivo</a></p>" >> "$TEMP_FILE"
            fi
            echo "<pre>$exif_info</pre>" >> "$TEMP_FILE"
            echo "<p><strong>SHA256 Hash:</strong> $hash</p>" >> "$TEMP_FILE"
            echo "<hr>" >> "$TEMP_FILE"
        fi
    done < "$report_file"

    # Rodapé do arquivo HTML
    echo "<h2>Logs de Navegação</h2>" >> "$TEMP_FILE"
    echo "<p>Os logs de navegação são registros detalhados das atividades realizadas por um usuário em um navegador ou dispositivo. Eles incluem informações como URLs acessadas, horários de acesso, cookies, downloads e interações com páginas web. Sua importância para o OSINT pode ser resumida em:</p>" >> "$TEMP_FILE"
    echo "<ul>" >> "$TEMP_FILE"
    echo "<li><strong>Rastreamento de Atividades:</strong> Permitem identificar quais sites foram visitados, o tempo gasto em cada página e as ações realizadas, ajudando a traçar um perfil de comportamento do usuário.</li>" >> "$TEMP_FILE"
    echo "<li><strong>Identificação de Padrões:</strong> Através da análise de logs, é possível detectar padrões de navegação, como horários de acesso frequentes ou preferências de conteúdo.</li>" >> "$TEMP_FILE"
    echo "<li><strong>Investigação de Incidentes:</strong> Em casos de cibercrimes, os logs podem fornecer evidências sobre atividades suspeitas, como tentativas de acesso a sites maliciosos ou compartilhamento de informações sensíveis.</li>" >> "$TEMP_FILE"
    echo "<li><strong>Coleta de Metadados:</strong> Informações como endereços IP, geolocalização e tipo de dispositivo podem ser extraídas dos logs, auxiliando na identificação de usuários ou sistemas.</li>" >> "$TEMP_FILE"
    echo "</ul>" >> "$TEMP_FILE"
    echo "<h2>Arquivos de Logs</h2>" >> "$TEMP_FILE"
    echo "<table border=\"1\">" >> "$TEMP_FILE"
    echo "<tr><th>Arquivo</th><th>Hash SHA-256</th></tr>" >> "$TEMP_FILE"
    for log_file in "$pasta/requests.txt" "$pasta/odysseus_snap.log"; do
        if [ -f "$log_file" ]; then
            hash=$(sha256sum "$log_file" | awk '{print $1}')
            echo "<tr><td>$(basename "$log_file")</td><td>$hash</td></tr>" >> "$TEMP_FILE"
        fi
    done
    echo "</table>" >> "$TEMP_FILE"
    # Rodapé do arquivo HTML
echo "<h2>Funções Hash e Integridade</h2>" >> "$TEMP_FILE"
echo "<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>" >> "$TEMP_FILE"
echo "<h2>Referências Técnicas</h2>" >> "$TEMP_FILE"
echo "<ol>" >> "$TEMP_FILE"
echo "<li><strong>Vecchia, Evandro Dalla.</strong> <em>Perícia Digital. Da Investigação à Análise Forense.</em> 2ª edição. Campinas: SP - Millennium Editora Ltda, 2019.</li>" >> "$TEMP_FILE"
echo "<li><strong>Eleutério, Pedro Monteiro da Silva e Machado, Márcio Pereira.</strong> <em>Desvendando a Computação Forense.</em> 1ª Edição. São Paulo: SP - Novatec Editora Ltda, 2011.</li>" >> "$TEMP_FILE"
echo "<li><strong>Velho, Jesus Antônio.</strong> <em>Tratado da Computação Forense.</em> 1ª Edição. Campinas: SP - Millennium Editora Ltda, 2016.</li>" >> "$TEMP_FILE"
echo "<li><strong>STJ, AgRg no HC 828054/RN.</strong> Julgado em 23/04/2024.</li>" >> "$TEMP_FILE"
echo "</ol>" >> "$TEMP_FILE"
cat <<EOF >> "$TEMP_FILE"
</body>
</html>
EOF

    # Converter o relatório para PDF usando wkhtmltopdf
    wkhtmltopdf --enable-local-file-access "$TEMP_FILE" "$OUTPUT_FILE_PDF"

    # Remover o arquivo temporário
    rm "$TEMP_FILE"

    # Informar ao usuário que o relatório foi gerado
    zenity --info --text="Relatório final gerado em $OUTPUT_FILE_PDF"
     
    # Criar as pastas de saída
    #mkdir -p "$pasta_saida/imagens"
    #mkdir -p "$pasta_saida/videos"
    mkdir -p "$pasta_saida/logs"

    # Copiar arquivos para as respectivas pastas
    cp "$pasta"/*.png "$pasta_saida/imagens/"
    cp "$pasta"/*.mp4 "$pasta_saida/videos/"
    cp "$pasta/requests.txt" "$pasta_saida/logs/"
    cp "$pasta/odysseus_snap.log" "$pasta_saida/logs/"
    # Copiar arquivos *.png, *.mp4, requests.txt, odysseus_snap.log para a pasta do relatório
    # Renomear a pasta de thumbs para thumbs_old
    if [ -d "$pasta/thumbnails" ]; then
        mv "$pasta/thumbnails" "$pasta/thumbnails_old"
    fi
    # Abrir o relatório PDF gerado com a aplicação padrão
    xdg-open "$OUTPUT_FILE_PDF"
    gravar_log "Criação de Relatório Final" "$OUTPUT_FILE_PDF"
}
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
            ffmpeg -video_size "${width}x${height}" -framerate 25 -f x11grab -i :0.0+$x,$y \
                -vf "drawbox=x=0:y=0:w=${width}:h=${height}:color=red@1:t=3" \
                "$pasta/screencast_$i.mp4" &
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
            echo "CAPTURA DE TELA: $pasta/screencast_$i.mp4" >> "$pasta/report_build.txt"
            break
        fi
    done
}
iniciar_sniffer() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    # Obtém o PID do Firefox
    firefox_pid=$(pgrep firefox)
    if [ -z "$firefox_pid" ]; then
        zenity --error --text="Firefox não está em execução."
        return
    fi

    # Exibe o PID do Firefox
    zenity --info --text="PID do Firefox: $firefox_pid"

    # Inicia o tcpdump para capturar o tráfego do Firefox e exibir as requisições em tempo real
    sudo tcpdump -i any -w "$pasta/firefox_traffic.pcap" -l | while read -r line; do
        echo "$line" | zenity --text-info --title="Requisições do Firefox" --width=800 --height=600 --timeout=1
    done &
    sniffer_pid=$!
    zenity --info --text="Sniffer iniciado. Clique em OK para parar o sniffer." --title="Parar Sniffer"
    kill $sniffer_pid
    zenity --info --text="Sniffer parado. Arquivo salvo em $pasta/firefox_traffic.pcap"
}

# Função para abrir a pasta de trabalho
abrir_pasta() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
    else
        xdg-open "$pasta"
    fi
}

# Função para criar relatório em PDF
criar_relatorio() {

pasta_saida=$(zenity --file-selection --directory --title="Selecione a pasta de saída do relatório")
if [ -z "$pasta_saida" ]; then
    zenity --error --text="Nenhuma pasta selecionada. Saindo..."
    return
fi

TEMP_FILE=$(mktemp /tmp/relatorio.XXXXXX.html)
OUTPUT_FILE_PDF="$pasta_saida/relatorio.pdf"
OUTPUT_FILE_ODT="$pasta_saida/relatorio.odt"

# Cabeçalho do arquivo HTML
cat <<EOF > "$TEMP_FILE"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Relatório Automático de Evidência(s) Digital(is) </title>
<style>
body { font-family: Arial, sans-serif; }
h2 { color: #2E8B57; }
pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
img { max-width: 100%; height: auto; }
</style>
</head>
<body>
<h1>Relatório Automático de Evidência(s) Digital(is) </h1>
<h2>Informações do Sistema</h2>
<pre>$(obter_info_sistema)</pre>
<h2>Introdução Técnica</h2>
<p>Este relatório foi gerado automaticamente pelo Odysseus SNAP, uma ferramenta de coleta de evidências digitais para investigações forenses. O relatório contém informações sobre arquivos, metadados e capturas de tela capturadas durante a investigação.além de aplicar funções hash conhecidas para garantir a integridade dos dados. </p>
<h2>Funções Hash e Integridade</h2>
<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>
<h2>Lista de Arquivos</h2>
EOF

# Contar o número total de arquivos para a barra de progresso
total_files=$(find "$pasta" -type f | wc -l)
current_file=0

# Percorrer todas as subpastas do diretório fornecido
(
find "$pasta" -type d | while read -r subfolder; do
    echo "<h2>Diretório: $subfolder</h2>" >> "$TEMP_FILE"
    FILES=($(find "$subfolder" -maxdepth 1 -type f))
    for file in "${FILES[@]}"; do
        exif_info=$(exiftool "$file")
        hash=$(sha256sum "$file" | awk '{print $1}')
        echo "<h3>$(basename "$file")</h3>" >> "$TEMP_FILE"
        if [[ "$file" =~ \.(jpg|jpeg|png|gif)$ ]]; then
            echo "<img src=\"file://$(realpath "$file")\" alt=\"$(basename "$file")\" style=\"width:300px;height:auto;\">" >> "$TEMP_FILE"
        fi
        echo "<pre>$exif_info</pre>" >> "$TEMP_FILE"
        echo "<p><strong>SHA256 Hash:</strong> $hash</p>" >> "$TEMP_FILE"
        echo "<hr>" >> "$TEMP_FILE"
        
        # Atualizar a barra de progresso
        current_file=$((current_file + 1))
        progress=$((current_file * 100 / total_files))
        echo $progress
        echo "# Processando arquivo $current_file de $total_files: $file"
    done
done
) | zenity --progress --title="Gerando Relatório" --text="Aguarde enquanto o relatório está sendo gerado..." --percentage=0 --auto-close

# Rodapé do arquivo HTML
echo "<h2>Funções Hash e Integridade</h2>" >> "$TEMP_FILE"
echo "<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>" >> "$TEMP_FILE"
echo "<h2>Referências Técnicas</h2>" >> "$TEMP_FILE"
echo "<ol>" >> "$TEMP_FILE"
echo "<li><strong>Vecchia, Evandro Dalla.</strong> <em>Perícia Digital. Da Investigação à Análise Forense.</em> 2ª edição. Campinas: SP - Millennium Editora Ltda, 2019.</li>" >> "$TEMP_FILE"
echo "<li><strong>Eleutério, Pedro Monteiro da Silva e Machado, Márcio Pereira.</strong> <em>Desvendando a Computação Forense.</em> 1ª Edição. São Paulo: SP - Novatec Editora Ltda, 2011.</li>" >> "$TEMP_FILE"
echo "<li><strong>Velho, Jesus Antônio.</strong> <em>Tratado da Computação Forense.</em> 1ª Edição. Campinas: SP - Millennium Editora Ltda, 2016.</li>" >> "$TEMP_FILE"
echo "<li><strong>STJ, AgRg no HC 828054/RN.</strong> Julgado em 23/04/2024.</li>" >> "$TEMP_FILE"
echo "</ol>" >> "$TEMP_FILE"
cat <<EOF >> "$TEMP_FILE"
</body>
</html>
EOF

# Converter o relatório para PDF usando wkhtmltopdf
wkhtmltopdf --enable-local-file-access "$TEMP_FILE" "$OUTPUT_FILE_PDF"

# Converter o relatório para ODT usando pandoc
pandoc "$TEMP_FILE" -o "$OUTPUT_FILE_ODT"

# Remover o arquivo temporário
rm "$TEMP_FILE"

# Informar ao usuário que o relatório foi gerado
zenity --info --text="Relatório gerado em $OUTPUT_FILE_PDF e $OUTPUT_FILE_ODT"

# Abrir o relatório PDF gerado com a aplicação padrão
xdg-open "$OUTPUT_FILE_PDF"
gravar_log "Criação de Relatório" "$OUTPUT_FILE_PDF"
}


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
      
}
criar_relatorio_navegacao() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    requisicao_file="$pasta/requests.txt"
    if [ ! -f "$requisicao_file" ]; then
        zenity --error --text="Arquivo requests.txt não encontrado na pasta de trabalho."
        return
    fi

    pasta_saida=$(zenity --file-selection --directory --title="Selecione a pasta de saída do relatório")
    if [ -z "$pasta_saida" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Saindo..."
        return
    fi

    TEMP_FILE=$(mktemp /tmp/relatorio_navegacao.XXXXXX.html)
    OUTPUT_FILE_PDF="$pasta_saida/relatorio_navegacao.pdf"

    # Calcular o hash SHA-256 do arquivo requests.txt
    hash=$(sha256sum "$requisicao_file" | awk '{print $1}')

    # Cabeçalho do arquivo HTML
    cat <<EOF > "$TEMP_FILE"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Relatório de Navegação na Internet</title>
<style>
body { font-family: Arial, sans-serif; }
h2 { color: #2E8B57; }
pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
</style>
</head>
<body>
<h2>Relatório de Navegação na Internet</h2>
<p>Este relatório contém informações sobre a navegação na internet capturadas pelo Odysseus SNAP.</p>
<h2>Referência ao Arquivo requests.txt</h2>
<p><strong>SHA-256 Hash:</strong> $hash</p>
<h2>Detalhes da Navegação</h2>
<pre>$(cat "$requisicao_file")</pre>
</body>
</html>
EOF

    # Converter o relatório para PDF usando wkhtmltopdf
    wkhtmltopdf --enable-local-file-access "$TEMP_FILE" "$OUTPUT_FILE_PDF"

    # Remover o arquivo temporário
    rm "$TEMP_FILE"

    # Informar ao usuário que o relatório foi gerado
    zenity --info --text="Relatório de navegação gerado em $OUTPUT_FILE_PDF"

    # Abrir o relatório PDF gerado com a aplicação padrão
    xdg-open "$OUTPUT_FILE_PDF"
    gravar_log "Criação de Relatório de Navegação" "$OUTPUT_FILE_PDF"
}
# Função para monitorar requests.txt em uma thread separada
monitorar_requests() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    tail -f "$pasta/requests.txt" | zenity --text-info --title="Monitorar requests.txt" --width=800 --height=600 &
    tail_pid=$!
}
abrir_url() {
    url=$(zenity --entry --title="Abrir URL" --text="Digite a URL que deseja abrir:")
    if [ -n "$url" ]; then
        firefox --new-tab "$url"
        echo "URL: $url" >> "$pasta/report_build.txt"
        zenity --info --text="URL aberta em uma nova aba do Firefox."
    else
        zenity --error --text="Nenhuma URL fornecida."
    fi
}
fechar_e_abrir_firefox() {
    # Verifica se há instâncias do Firefox em execução
    if pgrep firefox > /dev/null; then
        # Fecha todas as instâncias do Firefox
        pkill firefox
        zenity --info --text="Todas as instâncias do Firefox foram fechadas."
    fi

    # Abre uma nova sessão do Firefox sem abas abertas
    firefox --new-instance --no-remote about:blank &
    # Cria o arquivo requests.txt na pasta de trabalho e escreve a primeira linha
    echo "Relatório de Requisição" > "$pasta/requests.txt"
     echo "" > "$pasta/report_build.txt"
    zenity --info --text="Nova sessão do Firefox iniciada."
}
# Configura o manipulador de sinal para encerrar o processo de monitoramento ao sair
trap "parar_interceptacao; [ -n \"$tail_pid\" ] && kill $tail_pid" EXIT

# Seleciona a pasta de trabalho
selecionar_pasta

# Inicia a interceptação de endereços em uma thread
interceptar_enderecos &
# Inicia o monitoramento do arquivo requests.txt em uma thread
fechar_e_abrir_firefox


# Interface gráfica principal
while true; do
    acao=$(zenity --list --title="Odysseus SNAP" --column="Ação"  "Capturar Área da Tela" "Gravar Tela"  "Abrir Pasta de Trabalho" "Registrar Endereços" "Criar Relatório em PDF" "Monitorar requests.txt" "Sair" --height=300 --width=400 --text="Selecione uma ação:" --cancel-label="Sair" --hide-header)
    if [ $? -ne 0 ]; then
        break
    fi
    case $acao in
        "Registrar Endereços")
            abrir_url
            ;;
        "Capturar Área da Tela")
            capturar_area
            ;;
        "Gravar Tela")
            gravar_tela
            ;;
        "Abrir Pasta de Trabalho")
            xdg-open "$pasta"
            ;;
        "Criar Relatório Navegação")
            criar_relatorio_navegacao
            ;;
        "Criar Relatório em PDF")
            relatorio_final
            ;;    
        "Interceptar Endereços")
            interceptar_enderecos
            ;;
        "Monitorar requests.txt")
              monitorar_requests
            ;;    
        "Sair")
            break
            ;;
        *)
            zenity --error --text="Opção inválida. Tente novamente."
            ;;
    esac
done
