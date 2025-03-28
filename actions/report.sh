relatorio_final() {

    # Criar uma thread para chamar a função criar_log_sistema_operacional e esperar até que termine
    (
        criar_log_sistema_operacional
    ) 
   
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
    db_config_path="./database/global-config.db"
    LOGO_READER_="$(sqlite3 "$db_config_path" "SELECT logo FROM global_report WHERE id=1")"

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

    <img src="$LOGO_READER_"><br> 
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
EOF

    while IFS="|" read -r referencia solicitacao registro; do
        echo "<p><strong>Referência:</strong> $referencia</p>" >> "$TEMP_FILE"
        echo "<p><strong>Solicitação:</strong> $solicitacao</p>" >> "$TEMP_FILE"
        echo "<p><strong>Registro Interno:</strong> $registro</p>" >> "$TEMP_FILE"
    done < <(sqlite3 "$pasta/reportdata-db.db" "SELECT referencia, solicitacao, registro FROM report;")

cat <<EOF >> "$TEMP_FILE"
</div>
<h2 style="text-align: center;">Relatório de Evidências Digitais</h2>
<h2>Informações do Sistema</h2>
<pre>$(obter_info_sistema)</pre>
<h2>Introdução Técnica</h2>
<p> O relatório contém informações sobre arquivos, metadados e capturas de tela capturadas durante a investigação.além de aplicar funções hash conhecidas para garantir a integridade dos dados. </p>
<h2>Funções Hash e Integridade</h2>
<p>As funções hash são sequências alfanuméricas geradas por operações matemáticas e lógicas, produzindo um código de tamanho fixo que, em regra, é único para cada arquivo. Qualquer mínima alteração no arquivo resulta em um hash completamente diferente, garantindo a detecção de modificações.</p>
<h2>Lista de Arquivos</h2>
EOF

    while IFS="|" read -r filename basepath hash description type urlRegistro; do
       # exif_info=$(exiftool "$filename")
        

        echo "<h3>Nome do Arquivo: $basepath</h3> " >> "$TEMP_FILE"
            if [ -n "$urlRegistro" ]; then
                echo "<p>Referência: <a href=\"$urlRegistro\">$urlRegistro</a></p>" >> "$TEMP_FILE"
            fi   

        if [[ "$type" == "1" ]]; then
            echo "<img src=\"file://$(realpath "$filename")\" alt=\"$(basename "$filename")\" style=\"width:300px;height:auto;\">" >> "$TEMP_FILE"
            mkdir -p "$pasta_saida/imagens"
            cp "$filename" "$pasta_saida/imagens/"
            echo "<p><a href=\"./imagens/$(basename "$filename")\">$basepath</a></p>" >> "$TEMP_FILE"
            
            if [ -n "$description" ]; then
                echo "<p><strong>Descrição:</strong> $description</p>" >> "$TEMP_FILE"
            fi
        fi

        if [[ "$type" == "2" ]]; then
            echo "<img src=\"https://img.icons8.com/ios-filled/50/000000/video.png\" alt=\"Thumbnail\" style=\"width:50px;height:auto;\">" >> "$TEMP_FILE"
            mkdir -p "$pasta_saida/videos"
            cp "$filename" "$pasta_saida/videos/"
            echo "<p><a href=\"./videos/$(basename "$filename")\">$basepath</a></p>" >> "$TEMP_FILE"
        fi

        if [[ "$type" == "3" ]]; then
            mkdir -p "$pasta_saida/downloads"
            cp "$filename" "$pasta_saida/downloads/"
            echo "<p><a href=\"./downloads/$(basename "$filename")\">$basepath</a></p>" >> "$TEMP_FILE"
        fi
       

        if [ -n "$urlRegistro" ]; then
            host=$(echo "$urlRegistro" | awk -F/ '{print $3}')
            if [[ "$host" =~ ^(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}|[0-9]{1,3}(\.[0-9]{1,3}){3})$ ]]; then
                traceroute_output=$(traceroute "$host")
                echo "<h4>Traceroute para $host:</h4>" >> "$TEMP_FILE"
                echo "<pre>$traceroute_output</pre>" >> "$TEMP_FILE"
                        whois_output=$(whois "$host")
                        echo "<h4>WHOIS para $host:</h4>" >> "$TEMP_FILE"
                        echo "<pre>$whois_output</pre>" >> "$TEMP_FILE"
            fi
            
        fi
        
        echo "<h4>Metadados:</h4>" >> "$TEMP_FILE"
        exif_data=$(exiftool "$filename" | awk -F': ' '{printf "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">%s</td><td style=\"border: 1px solid #ddd; padding: 8px;\">%s</td></tr>", $1, $2}')
        echo "<table style=\"border-collapse: collapse; width: 100%; font-family: monospace; font-size: 12px;\">$exif_data</table>" >> "$TEMP_FILE"
        echo "<p><strong>SHA256 Hash:</strong> $hash</p>" >> "$TEMP_FILE"
        echo "<hr>" >> "$TEMP_FILE"
    done < <(sqlite3 "$pasta/screencaption-db.db" "SELECT DISTINCT filename, basepath, hash, description, type, urlRegistro FROM screencaption WHERE filename IS NOT NULL AND basepath IS NOT NULL AND hash IS NOT NULL AND type IS NOT NULL;")

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
    echo "<table style=\"border-collapse: collapse; width: 100%; font-family: monospace; font-size: 12px;\">" >> "$TEMP_FILE"
    echo "<tr style=\"background-color: #f2f2f2; text-align: left;\"><th style=\"border: 1px solid #ddd; padding: 8px;\">Arquivo</th><th style=\"border: 1px solid #ddd; padding: 8px;\">Hash SHA-256</th></tr>" >> "$TEMP_FILE"
    for log_file in "$pasta/requests.txt" "$pasta/odysseus_snap.log" "$pasta/LogSistemaOperacional.log"; do
        if [ -f "$log_file" ]; then
            hash=$(sha256sum "$log_file" | awk '{print $1}')
            echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href=\"./logs/$(basename "$log_file")\">$(basename "$log_file")</a></td><td style=\"border: 1px solid #ddd; padding: 8px;\">$hash</td></tr>" >> "$TEMP_FILE"
        fi
    done
    echo "</table>" >> "$TEMP_FILE"
     
    echo "<h2>Ações</h2>" >> "$TEMP_FILE"
    echo "<table style=\"border-collapse: collapse; width: 100%; font-family: monospace; font-size: 12px;\">" >> "$TEMP_FILE"
    echo "<tr style=\"background-color: #f2f2f2; text-align: left;\">" >> "$TEMP_FILE"
    echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">ID</th>" >> "$TEMP_FILE"
    echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Ação</th>" >> "$TEMP_FILE"
    echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Arquivo</th>" >> "$TEMP_FILE"
    echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Informações do Sistema</th>" >> "$TEMP_FILE"
    echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Data e Hora</th>" >> "$TEMP_FILE"
    echo "</tr>" >> "$TEMP_FILE"
    sqlite3 "$pasta/odysseus_snap.db" "SELECT id, acao, arquivo, info_sistema, data_hora FROM logs;" | while IFS="|" read -r id acao arquivo info_sistema data_hora; do
        echo "<tr>" >> "$TEMP_FILE"
        echo "<td style=\"border: 1px solid #ddd; padding: 8px;\">$id</td>" >> "$TEMP_FILE"
        echo "<td style=\"border: 1px solid #ddd; padding: 8px;\">$acao</td>" >> "$TEMP_FILE"
        echo "<td style=\"border: 1px solid #ddd; padding: 8px;\">$arquivo</td>" >> "$TEMP_FILE"
        echo "<td style=\"border: 1px solid #ddd; padding: 8px;\">$info_sistema</td>" >> "$TEMP_FILE"
        echo "<td style=\"border: 1px solid #ddd; padding: 8px;\">$data_hora</td>" >> "$TEMP_FILE"
        echo "</tr>" >> "$TEMP_FILE"
    done
    echo "</table>" >> "$TEMP_FILE"

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

    # Converter o relatório para PDF usando wkhtmltopdf
    wkhtmltopdf --enable-local-file-access --keep-relative-links \
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

    # Remover o arquivo temporário
    mv "$TEMP_FILE" "$pasta_saida/relatorio_final_$(date +"%Y%m%d_%H%M%S").html"

    # Informar ao usuário que o relatório foi gerado
    zenity --info --text="Relatório final gerado em $OUTPUT_FILE_PDF"
     
    # Criar as pastas de saída
    mkdir -p "$pasta_saida/logs"

    # Copiar arquivos para as respectivas pastas
    cp "$pasta/requests.txt" "$pasta_saida/logs/"
    cp "$pasta/odysseus_snap.log" "$pasta_saida/logs/"
    cp "$pasta/LogSistemaOperacional.log" "$pasta_saida/logs/"

    # Abrir o relatório PDF gerado com a aplicação padrão
    xdg-open "$OUTPUT_FILE_PDF"
    gravar_log "Criação de Relatório Final" "$OUTPUT_FILE_PDF"
}