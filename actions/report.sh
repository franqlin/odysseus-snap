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
pre { background-color: #f4f4f4; padding: 10px; border: 1px solid #ddd; overflow-x: auto; }
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
<div style="text-align: right;">
    <p><strong>Rio de Janeiro,</strong> $(date +"%d de %B de %Y")</p>
</div>
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
while IFS="|" read -r filename basepath hash description type; do

   
        exif_info=$(exiftool "$filename")
        echo "<h3>Nome do Arquivo: $basepath</h3>" >> "$TEMP_FILE"
        if [[ "$type" -eq 2 ]]; then
            mkdir -p "$pasta_saida/thumbnails"
            thumbnail_file="$pasta_saida/thumbnails/$($basepath "${screenshot_file%.mp4}_thumbnail.png")"
            
            #ffmpeg -i "$screenshot_file" -ss 00:00:01.000 -vframes 1 "$thumbnail_file"
            echo "<img src=\"https://img.icons8.com/ios-filled/50/000000/video.png\" alt=\"Thumbnail\" style=\"width:50px;height:auto;\">" >> "$TEMP_FILE"
            mkdir -p "$pasta_saida/videos"
            cp "$filename" "$pasta_saida/videos/"
            echo "<p><a href=\"./videos/$($basepath)\">Clique aqui para acessar o arquivo</a></p>" >> "$TEMP_FILE"
        else
            echo "<img src=\"file://$(realpath "$filename")\" alt=\"$(basename "$filename")\" style=\"width:300px;height:auto;\">" >> "$TEMP_FILE"
            mkdir -p "$pasta_saida/imagens"
            cp "$filename" "$pasta_saida/imagens/"
            echo "<p><a href=\"./imagens/$(basename "$filename")\"><img src=\"https://img.icons8.com/ios-filled/50/000000/link.png\" alt=\"Link\" style=\"width:20px;height:auto;\"></a></p>" >> "$TEMP_FILE"
        fi

        echo "<p><strong>Descrição:</strong> $description</p>" >> "$TEMP_FILE"

        echo "<h4>Metadados:</h4>" >> "$TEMP_FILE"
        echo "<table style=\"width: 100%; font-family: monospace; font-size: 12px;\">" >> "$TEMP_FILE"
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 10px; background-color: #f2f2f2;\">Tag</th><th style=\"border: 1px solid #ddd; padding: 10px; background-color: #f2f2f2;\">Value</th></tr>" >> "$TEMP_FILE"
        while IFS=" : " read -r tag value; do
            echo "<tr><td style=\"border: 1px solid #ddd; padding: 10px;\">$tag</td><td style=\"border: 1px solid #ddd; padding: 10px;\">$value</td></tr>" >> "$TEMP_FILE"
        done <<< "$exif_info"
        echo "</table>" >> "$TEMP_FILE"
        echo "<p><strong>SHA256 Hash:</strong> $hash</p>" >> "$TEMP_FILE"
        echo "<hr>" >> "$TEMP_FILE"
    
done  < <(sqlite3 "$pasta/screencaption-db.db" "SELECT filename, basepath, hash, description, type FROM screencaption;")

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
cat <<EOF >> "$TEMP_FILE"
<h2>Ferramentas Utilizadas</h2>
<p>Este projeto utiliza diversas ferramentas para realizar a coleta e análise de dados. Abaixo está uma descrição técnica de cada uma delas:</p>
<ul>
    <li><strong>scrot:</strong> Uma ferramenta de linha de comando para capturar screenshots. <a href="https://github.com/resurrecting-open-source-projects/scrot">Repositório</a></li>
    <li><strong>zenity:</strong> Uma ferramenta que permite exibir caixas de diálogo gráficas a partir de scripts de shell. <a href="https://github.com/ncruces/zenity">Repositório</a></li>
    <li><strong>ffmpeg:</strong> Um framework completo para gravar, converter e transmitir áudio e vídeo. <a href="https://github.com/FFmpeg/FFmpeg">Repositório</a></li>
    <li><strong>ImageMagick:</strong> Um software para criar, editar, compor ou converter imagens bitmap. <a href="https://github.com/ImageMagick/ImageMagick">Repositório</a></li>
    <li><strong>exiftool:</strong> Uma ferramenta de linha de comando para leitura, escrita e edição de metadados em arquivos. <a href="https://github.com/exiftool/exiftool">Repositório</a></li>
    <li><strong>pandoc:</strong> Um conversor universal de documentos. <a href="https://github.com/jgm/pandoc">Repositório</a></li>
    <li><strong>slop:</strong> Uma ferramenta para selecionar áreas da tela. <a href="https://github.com/naelstrof/slop">Repositório</a></li>
    <li><strong>maim:</strong> Uma ferramenta de captura de tela. <a href="https://github.com/naelstrof/maim">Repositório</a></li>
    <li><strong>xclip:</strong> Uma ferramenta de linha de comando para interagir com a área de transferência X. <a href="https://github.com/astrand/xclip">Repositório</a></li>
    <li><strong>tinyproxy:</strong> Um proxy HTTP leve. <a href="https://github.com/tinyproxy/tinyproxy">Repositório</a></li>
    <li><strong>mitmproxy:</strong> Um proxy HTTP/HTTPS interativo para depuração e análise de tráfego. <a href="https://github.com/mitmproxy/mitmproxy">Repositório</a></li>
    <li><strong>wkhtmltopdf:</strong> Uma ferramenta para converter HTML em PDF usando Webkit. <a href="https://github.com/wkhtmltopdf/wkhtmltopdf">Repositório</a></li>
    <li><strong>sha256sum:</strong> Uma ferramenta de linha de comando para calcular e verificar hashes SHA-256. <a href="https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html">Documentação</a></li>
</ul>
EOF
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
     --margin-top "20mm" \
     --margin-bottom "20mm" \
     --margin-left "20mm" \
     --margin-right "20mm" \
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