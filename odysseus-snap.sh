#!/bin/bash

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
}
# Função para interceptar endereços
interceptar_enderecos() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    output_log="$pasta/odysseus_firefox.log"

    # Verifica se o httpry está instalado
    if ! command -v httpry &> /dev/null; then
        zenity --error --text="httpry não está instalado. Instale-o usando 'sudo apt-get install httpry'."
        return
    fi
    
     zenity --error --text="Digite a senha (sudo) para iniciar a interceptação de endereços."
    # Inicia o httpry para capturar o tráfego HTTP
    sudo httpry -i any -o "$output_log" &
    httpry_pid=$!
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
# Função para parar a interceptação de endereços
parar_interceptacao() {
    if [ -n "$httpry_pid" ]; then
        kill $httpry_pid
        zenity --info --text="Interceptação parada. Arquivo salvo em $output_log"
    fi
}

trap parar_interceptacao EXIT 
# Interface gráfica principal
while true; do
    acao=$(zenity --list --title="Odysseus SNAP" --column="Ação" "Selecionar Pasta de Trabalho" "Capturar Área da Tela" "Gravar Tela" "Interceptar Endereços" "Abrir Pasta de Trabalho" "Criar Relatório em PDF" "Sair" --height=300 --width=400 --text="Selecione uma ação:" --cancel-label="Sair" --hide-header)
    if [ $? -ne 0 ]; then
        break
    fi
    case $acao in
        "Selecionar Pasta de Trabalho")
            selecionar_pasta
            ;;
        "Capturar Área da Tela")
            capturar_area
            ;;
        "Gravar Tela")
            gravar_tela
            ;;
        "Abrir Pasta de Trabalho")
            abrir_pasta
            ;;
        "Criar Relatório em PDF")
            criar_relatorio
            ;;
        "Interceptar Endereços")
            interceptar_enderecos
            ;;
        "Sair")
            break
            ;;
        *)
            zenity --error --text="Opção inválida. Tente novamente."
            ;;
    esac
done