#!/bin/bash
source "$(dirname "$0")/config.sh"
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
        report_file="$pasta/report_build.txt"
        if [ ! -f "$report_file" ]; then
            touch "$report_file"
            echo "Arquivo report_build.txt criado."
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
            last_session=$(grep "opensession:" "$session_file" | tail -n 1 | cut -d ' ' -f 3-)
            zenity --info --text="⚠️ Última sessão: $last_session\n\n📂 Pasta de trabalho: $pasta"
            #zenity --info --text=""
        fi
    fi
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
    echo "CAPTURA_DE_TELA__: $screenshot_file" >> "$pasta/report_build.txt"
}

relatorio_final() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    pasta_saida="$pasta/relatorio_$(date +"%Y%m%d_%H%M%S")"
    mkdir -p "$pasta_saida"
    
    report_file="$pasta/report_build.txt"
    if [ ! -f "$report_file" ]; then
        zenity --error --text="Arquivo report_build.txt não encontrado na pasta de trabalho."
        return
    fi

    # Remove linhas em branco do arquivo report_build.txt
    sed -i '/^$/d' "$report_file"

    TEMP_FILE="$pasta/relatorio_final.html"
    OUTPUT_FILE_PDF="$pasta_saida/relatorio_final.pdf"

    # Lê o atributo "report_reader" do arquivo ody.config e armazena em uma variável
    #report_reader=$(grep -oP '(?<=^report_reader=).*' "$(dirname "$0")/ody.config")
    # Cabeçalho do arquivo HTML
    cat <<EOF > "$TEMP_FILE"

<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Relatório Final</title>
<style>
body { font-family: Arial, sans-serif; }
h2 { color: #782c24; }
pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
img { max-width: 100%; height: auto; }
table { border-collapse: collapse; width: 100%; }
table, th, td { border: 1px solid black; }
th, td { padding: 10px; text-align: left; }
th { background-color: #f2f2f2; }
</style>
</head>
<body>
<div style="text-align: center; font-size: 12px;">
    <img src="$REPORT_READER" alt="Logo MPRJ" style="width: 711px; height: 106px;"><br> 
    <strong>COORDENADORIA DE SEGURANÇA E INTELIGÊNCIA</strong><br>
    DIVISÃO ESPECIAL DE INTELIGÊNCIA CIBERNÉTICA<br>
    Av. Marechal Câmara, 350/8º andar, Centro, Rio de Janeiro – RJ.<br>
    Telefones: 2292-8459 / 2550-1010 - e-mail: <a href="mailto:deic.csi@mprj.mp.br">deic.csi@mprj.mp.br</a>
</div>
<hr>
<br>
<div style="text-align: left; font-family: monospace; line-height: 1.2;">
    <p><strong>Referência:</strong> 0802185-58.2024.8.19.0025</p>
    <p><strong>Solicitação:</strong> FORM5389</p>
    <p><strong>Registro Interno:</strong> 35-2024</p>
</div>
<h2 style="text-align: center;">Relatório de Evidências Digitais</h2>
<h2>Informações do Sistema</h2>
<pre>$(obter_info_sistema)</pre>
<h2>Introdução Técnica</h2>
<p>Este relatório foi gerado automaticamente pelo Odysseus SNAP, uma ferramenta de coleta de evidências digitais para investigações forenses. O relatório contém informações sobre arquivos, metadados e capturas de tela capturadas durante a investigação.além de aplicar funções hash conhecidas para garantir a integridade dos dados. </p>
<h2>Funções Hash e Integridade</h2>
<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>
<h2>Lista de Arquivos</h2>
EOF
while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == URL__:* ]]; then
        url="${line#URL__: }"
        echo "<h2>URL: <a href=\"$url\">$url</a></h2>" >> "$TEMP_FILE"
    elif [[ "$line" == CAPTURA_DE_TELA__:* ]]; then
        screenshot_file="${line#CAPTURA_DE_TELA__: }"
        exif_info=$(exiftool "$screenshot_file")
        hash=$(sha256sum "$screenshot_file" | awk '{print $1}')
        echo "<h3>Nome do Arquivo: $(basename "$screenshot_file")</h3>" >> "$TEMP_FILE"
        if [[ "$screenshot_file" =~ \.mp4$ ]]; then
            mkdir -p "$pasta_saida/thumbnails"
            thumbnail_file="$pasta_saida/thumbnails/$(basename "${screenshot_file%.mp4}_thumbnail.png")"
            
            #ffmpeg -i "$screenshot_file" -ss 00:00:01.000 -vframes 1 "$thumbnail_file"
            echo "<img src=\"https://img.icons8.com/ios-filled/50/000000/video.png\" alt=\"Thumbnail\" style=\"width:50px;height:auto;\">" >> "$TEMP_FILE"
            mkdir -p "$pasta_saida/videos"
            cp "$screenshot_file" "$pasta_saida/videos/"
            echo "<p><a href=\"./videos/$(basename "$screenshot_file")\">Clique aqui para acessar o arquivo</a></p>" >> "$TEMP_FILE"
        else
            echo "<img src=\"file://$(realpath "$screenshot_file")\" alt=\"$(basename "$screenshot_file")\" style=\"width:300px;height:auto;\">" >> "$TEMP_FILE"
            mkdir -p "$pasta_saida/imagens"
            cp "$screenshot_file" "$pasta_saida/imagens/"
            echo "<p><a href=\"./imagens/$(basename "$screenshot_file")\">Clique aqui para acessar o arquivo</a></p>" >> "$TEMP_FILE"
        fi
        echo "<pre>$exif_info</pre>" >> "$TEMP_FILE"
        echo "<p><strong>SHA256 Hash:</strong> $hash</p>" >> "$TEMP_FILE"
        echo "<hr>" >> "$TEMP_FILE"
    fi
done < <(cat "$report_file"; echo)

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
            echo "<tr><td><a href=\"./logs/$(basename "$log_file")\">$(basename "$log_file")</a></td><td>$hash</td></tr>" >> "$TEMP_FILE"
        fi
    done
    echo "</table>" >> "$TEMP_FILE"
    # Rodapé do arquivo HTML
echo "<h2>Funções Hash e Integridade</h2>" >> "$TEMP_FILE"
echo "<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>" >> "$TEMP_FILE"
echo "<h2>Referências Técnicas</h2>" >> "$TEMP_FILE"
echo "<ol>" >> "$TEMP_FILE"
echo "<li><strong>ISO/IEC 27037:2012.</strong> <em>Information technology — Security techniques — Guidelines for identification, collection, acquisition, and preservation of digital evidence.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>ISO/IEC 27001:2013.</strong> <em>Information technology — Security techniques — Information security management systems — Requirements.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>ISO/IEC 27002:2013.</strong> <em>Information technology — Security techniques — Code of practice for information security controls.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>ISO/IEC 27035:2016.</strong> <em>Information technology — Security techniques — Information security incident management.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>Marco Civil da Internet (Lei Nº 12.965/2014).</strong> <em>Estabelece princípios, garantias, direitos e deveres para o uso da Internet no Brasil.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>Artigo 7º.</strong> <em>Estabelece os direitos dos usuários da Internet.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>Artigo 10º.</strong> <em>Trata da guarda e proteção dos registros de conexão e de acesso a aplicações de Internet.</em></li>" >> "$TEMP_FILE"
echo "<li><strong>Artigo 11º.</strong> <em>Estabelece que a coleta, guarda, armazenamento e tratamento de dados pessoais ou de comunicações devem respeitar a legislação brasileira.</em></li>" >> "$TEMP_FILE"
echo "</ol>" >> "$TEMP_FILE"
    cat <<EOF >> "$TEMP_FILE"
</body>
</html>
EOF
    #--keep-relative-links  
    # Converter o relatório para PDF usando wkhtmltopdf
     
    wkhtmltopdf --enable-local-file-access  --keep-relative-links \
     --footer-left "MPRJ" \
     --footer-right "[page]/[toPage]" \
     --footer-center "Divisão Especial de Inteligência Cibernética" \
     --footer-font-size 8 \
     --footer-spacing 5 \
     --footer-line \
     "$TEMP_FILE" "$OUTPUT_FILE_PDF"
     #--header-center "$cabecalho" \

    # Remover o arquivo temporário
    mv "$TEMP_FILE" "$pasta_saida/relatorio_final_$(date +"%Y%m%d_%H%M%S").html"

    # Informar ao usuário que o relatório foi gerado
    zenity --info --text="Relatório final gerado em $OUTPUT_FILE_PDF"
     
    # Criar as pastas de saída
    #mkdir -p "$pasta_saida/imagens"
    #mkdir -p "$pasta_saida/videos"
    mkdir -p "$pasta_saida/logs"

    # Copiar arquivos para as respectivas pastas
    #cp "$pasta"/*.png "$pasta_saida/imagens/"
    #cp "$pasta"/*.mp4 "$pasta_saida/videos/"
    cp "$pasta/requests.txt" "$pasta_saida/logs/"
    cp "$pasta/odysseus_snap.log" "$pasta_saida/logs/"
    # Copiar arquivos *.png, *.mp4, requests.txt, odysseus_snap.log para a pasta do relatório
    # Renomear a pasta de thumbs para thumbs_old
  #  if [ -d "$pasta/thumbnails" ]; then
   #     mv "$pasta/thumbnails" "$pasta/thumbnails_old"
   # fi
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
# Função para abrir a pasta de trabalho
abrir_pasta() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
    else
        xdg-open "$pasta"
    fi
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
# Função para verificar se o caso já foi fechado
verificar_caso_fechado() {
    if grep -q "closedsession:" "$session_file"; then
        zenity --info --text="O caso já foi fechado."
        return 0
    else
        return 1
    fi
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
        echo "URL__: $url" >> "$pasta/report_build.txt"
        zenity --info --text="URL aberta em uma nova aba do Firefox."
    else
        zenity --error --text="Nenhuma URL fornecida."
    fi
}
fechar_e_abrir_firefox() {
    # Verifica se há instâncias do Firefox em execução
    if ! verificar_caso_fechado; then
        
        if pgrep firefox > /dev/null; then
            # Fecha todas as instâncias do Firefox
            pkill firefox
            #zenity --info --text="Todas as instâncias do Firefox foram fechadas."
        fi

        # Abre uma nova sessão do Firefox sem abas abertas
        firefox --new-instance --no-remote about:blank &
        # Cria o arquivo requests.txt na pasta de trabalho e escreve a primeira linha
        echo "Relatório de Requisição" >> "$pasta/requests.txt"
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
        parar_interceptacao; 
        
    fi
}
# Processos em segundo plano

# Configura o manipulador de sinal para encerrar o processo de monitoramento ao sair
trap "parar_interceptacao; [ -n \"$tail_pid\" ] && kill $tail_pid" EXIT
# Seleciona a pasta de trabalho
selecionar_pasta
# Inicia a interceptação de endereços em uma thread
if ! verificar_caso_fechado; then
    interceptar_enderecos &
    # Inicia o monitoramento do arquivo requests.txt em uma thread
    fechar_e_abrir_firefox
fi


# Verifica se o caso já foi fechado antes de iniciar a interface gráfica
#if verificar_caso_fechado; then
    #exit 0
#fi

# Interface gráfica principal
while true; do
    acao=$(zenity --list --title="Odysseus OSINT Report" --column="Ação" \
         "🔗 Registrar URL" \
        "📸 Capturar Área da Tela" \
        "🎥 Gravar Tela" \
        "📂 Abrir Pasta de Trabalho" \
        "📈 Monitorar Requisições" \
        "📄 Criar Relatório em PDF" \
        "🚪 Sair" \
        "🔒 Fechar Sessão"\
        --height=400 --width=500 --text="Selecione uma ação:" --cancel-label="Sair" --hide-header)
    if [ $? -ne 0 ]; then
        break
    fi
    case $acao in
        "🔗 Registrar URL")
            if ! verificar_caso_fechado; then
                abrir_url
            fi
            ;;
        "📸 Capturar Área da Tela")
            if ! verificar_caso_fechado; then
                capturar_area
            fi
            ;;
        "🎥 Gravar Tela")
            if ! verificar_caso_fechado; then
                gravar_tela
            fi
            ;;
        "📂 Abrir Pasta de Trabalho")
            if ! verificar_caso_fechado; then
                xdg-open "$pasta"
            fi
            ;;
        "📄 Criar Relatório em PDF")
            if ! verificar_caso_fechado; then
                relatorio_final
            fi
            ;;    
        "📈 Monitorar Requisições")
            if ! verificar_caso_fechado; then
                monitorar_requests
            fi
            ;;
        "🔒 Fechar Sessão")
            closedsession
            ;;
        "🚪 Sair")
            break
            ;;
        *)
            zenity --error --text="Opção inválida. Tente novamente."
            ;;
    esac
done
