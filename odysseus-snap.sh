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
# Função para selecionar a pasta de trabalho
selecionar_pasta() {
    pasta=$(zenity --file-selection --directory --title="Selecione a pasta de trabalho")
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Saindo..."
        exit 1
    fi
    echo "Pasta selecionada: $pasta"
}

# Função para capturar uma área da tela
capturar_area() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    zenity --info --text="Selecione uma área da tela para capturar."
    
    # Encontra o próximo número disponível para o screenshot
    for i in $(seq 1 10000); do
        if [ ! -f "$pasta/screenshot_$i.png" ]; then
            scrot -s "$pasta/screenshot_$i.png"
            zenity --info --text="Captura de tela salva em $pasta/screenshot_$i.png"
            break
        fi
    done
}

# Função para gravar a tela
gravar_tela() {
    if [ -z "$pasta" ]; then
        zenity --error --text="Nenhuma pasta selecionada. Selecione uma pasta primeiro."
        return
    fi

    zenity --info --text="Selecione a área da tela que deseja gravar."

    # Obtém a geometria da área selecionada
    geometry=$(slop -f "%x %y %w %h")
    read -r x y width height <<< "$geometry"

    # Encontra o próximo número disponível para o screencast
    for i in $(seq 1 10000); do
        if [ ! -f "$pasta/screencast_$i.mp4" ]; then
            # Inicia a gravação em segundo plano
            ffmpeg -video_size "${width}x${height}" -framerate 25 -f x11grab -i :0.0+$x,$y \
                -vf "drawbox=x=0:y=0:w=${width}:h=${height}:color=red@0.5:t=5" \
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
<title>Relatório de Arquivos</title>
<style>
body { font-family: Arial, sans-serif; }
h2 { color: #2E8B57; }
pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; }
img { max-width: 100%; height: auto; }
</style>
</head>
<body>
<!--img src="file://$(realpath logo.png)" alt="Logo" style="width:100px;height:auto;"-->
<h1>Relatório de Arquivos</h1>
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
}

# Interface gráfica principal
while true; do
    acao=$(zenity --list --title="Odysseus SNAP" --column="Ação" "Selecionar Pasta de Trabalho" "Capturar Área da Tela" "Gravar Tela" "Abrir Pasta de Trabalho" "Criar Relatório em PDF" "Sair" --height=300 --width=400 --text="Selecione uma ação:" --cancel-label="Sair")
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
        "Sair")
            break
            ;;
        *)
            zenity --error --text="Opção inválida. Tente novamente."
            ;;
    esac
done