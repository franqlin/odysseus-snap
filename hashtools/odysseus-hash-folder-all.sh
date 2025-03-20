#!/bin/bash -x

# Exibir a splash screen com a imagem logo.png por 5 segundos usando yad
yad --image="logo.png" --timeout=5 --no-buttons --title="Bem-vindo" --text="Carregando..." --center --undecorated --fixed --skip-taskbar --no-escape &

# Verificar se as dependências estão instaladas
if ! command -v zenity &> /dev/null || ! command -v exiftool &> /dev/null || ! command -v sha256sum &> /dev/null || ! command -v wkhtmltopdf &> /dev/null || ! command -v pandoc &> /dev/null; then
    echo "Certifique-se de que zenity, exiftool, sha256sum, wkhtmltopdf e pandoc estão instalados."
    exit 1
fi

# Obter a pasta de entrada usando zenity
FOLDER=$(zenity --file-selection --directory --title="Selecione a pasta de entrada")

# Verificar se o usuário forneceu uma pasta
if [ -z "$FOLDER" ]; then
  zenity --error --text="Nenhuma pasta fornecida."
  exit 1
fi

# Obter a pasta de saída usando zenity
OUTPUT_FOLDER=$(zenity --file-selection --directory --title="Selecione a pasta de saída")

# Verificar se o usuário forneceu uma pasta de saída
if [ -z "$OUTPUT_FOLDER" ]; then
  zenity --error --text="Nenhuma pasta de saída fornecida."
  exit 1
fi

# Nome do arquivo de saída
FOLDER_NAME=$(basename "$FOLDER")
DATE=$(date +%Y-%m-%d)
OUTPUT_FILE_PDF="$OUTPUT_FOLDER/relatorio_${FOLDER_NAME}_${DATE}.pdf"
OUTPUT_FILE_ODT="$OUTPUT_FOLDER/relatorio_${FOLDER_NAME}_${DATE}.odt"
TEMP_FILE=$(mktemp /tmp/relatorio.XXXXXX.html)

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
<img src="file://$(realpath logo.png)" alt="Logo" style="width:100px;height:auto;">
<h1>Relatório de Arquivos</h1>
EOF

# Contar o número total de arquivos para a barra de progresso
total_files=$(find "$FOLDER" -type f | wc -l)
current_file=0

# Percorrer todas as subpastas do diretório fornecido
(
find "$FOLDER" -type d | while read -r subfolder; do
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