#!/bin/bash -x

# Verificar se as dependências estão instaladas
if ! command -v zenity &> /dev/null || ! command -v sha256sum &> /dev/null || ! command -v realpath &> /dev/null || ! command -v xdg-open &> /dev/null; then
    echo "Certifique-se de que zenity, sha256sum, realpath e xdg-open estão instalados."
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
DATE=$(date +%Y-%m-%d_%H-%M-%S)
OUTPUT_FILE="$OUTPUT_FOLDER/hashes_${FOLDER_NAME}_${DATE}.xls"

# Cabeçalho do arquivo XLS
echo -e "Nome\tTamanho(Bites)\tCaminho\tHash" > "$OUTPUT_FILE"

# Contar o número total de arquivos para a barra de progresso
total_files=$(find "$FOLDER" -type f | wc -l)
current_file=0

# Percorrer todas as subpastas do diretório fornecido
(
find "$FOLDER" -type f | while read -r file; do
    filename=$(basename "$file")
    filesize=$(stat -c%s "$file")
    filepath=$(realpath "$file")
    hash=$(sha256sum "$file" | awk '{print $1}')
    echo -e "$filename\t$filesize\t$filepath\t$hash" >> "$OUTPUT_FILE"
    
    # Atualizar a barra de progresso
    current_file=$((current_file + 1))
    progress=$((current_file * 100 / total_files))
    echo $progress
    echo "# Processando arquivo $current_file de $total_files: $file"
done
) | zenity --progress --title="Calculando Hashes" --text="Aguarde enquanto os hashes estão sendo calculados..." --percentage=0 --auto-close

# Informar ao usuário que o relatório foi gerado
zenity --info --text="Hashes salvos em $OUTPUT_FILE"

# Abrir o arquivo XLS gerado com a aplicação padrão
xdg-open "$OUTPUT_FILE"