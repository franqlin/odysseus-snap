relatorio_final() {
     
    (
   
        (
            for i in {1..100}; do
                echo $i
                sleep 0.1
            done
        ) | zenity --progress --title="Gerando Relatório" --text="Aguarde enquanto o relatório é elaborado..." --percentage=0 --auto-close --no-cancel
    ) &
    # Criar uma thread para chamar a função criar_log_sistema_operacional e esperar até que termine
    (
        criar_log_sistema_operacional
        
    )
    # Espera a thread terminar
    echo " log do SO Criado .." 
    gravar_log "Criação de Relatório Final" "$OUTPUT_FILE_PDF"
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
p{ font-size: 12px; text-indent: 40px;align: justify; }
li{ font-size: 12px; text-indent: 40px;align: justify; }

</style>
</head>
<body>
<div style="text-align: center; font-size: 12px;">

    <img src="${LOGO_READER_:-default_logo.png}"><br> 
    <strong>COORDENADORIA DE SEGURANÇA E INTELIGÊNCIA</strong><br>
    DIVISÃO ESPECIAL DE INTELIGÊNCIA CIBERNÉTICA<br>
    Av. General Justo, 375/5º andar, Centro, Rio de Janeiro – RJ.<br>
    Telefones: (21) 2292-8459 - e-mail: <a href="mailto:csi.deic@mprj.mp.br">csi.deic@mprj.mp.br</a>
</div>
<div style="text-align: right;">
    <p><strong>Rio de Janeiro,</strong> $(date +"%d de %B de %Y")</p>
</div>
<br>
<div style="font-family: monospace; line-height: .9; white-space: pre-wrap;">
EOF

    while IFS="|" read -r referencia solicitacao registro; do
        echo "<p style=\"text-indent: 1px;\"  ><strong>Referência:</strong> $referencia</p>" >> "$TEMP_FILE"
        echo "<p style=\"text-indent: 1px;\" ><strong>Solicitação:</strong> $solicitacao</p>" >> "$TEMP_FILE"
        echo "<p style=\"text-indent: 1px;\"><strong>Registro Interno:</strong> $registro</p>" >> "$TEMP_FILE"
    done < <(sqlite3 "$pasta/reportdata-db.db" "SELECT referencia, solicitacao, registro FROM report;")

cat <<EOF >> "$TEMP_FILE"
</div>
<br>
<br>
<h2 style="text-align: center;">Relatório de Coleta de Vestígios Digitais</h2>
<br>
<h2>Informações do Sistema</h2>
<pre>$(obter_info_sistema)</pre>
<p>As Informações do Sistema descrevem o ambiente técnico onde a coleta de vestígios digitais foi realizada, incluindo o nome do host, usuário logado, endereço IP,
 sistema operacional, arquitetura do processador e o servidor DNS configurado. Esses dados são essenciais para garantir a rastreabilidade, integridade e contextualização 
 da análise, assegurando que os resultados sejam confiáveis e replicáveis.</p> 
<h2>Introdução Técnica</h2>
<p> Este relatório apresenta uma análise detalhada dos arquivos, metadados, logs e capturas de tela coletados durante o processo de coleta. 
Para assegurar a integridade e a autenticidade dos dados, foram aplicadas funções hash amplamente reconhecidas, como SHA-256, garantindo que nenhuma alteração não autorizada tenha ocorrido após a coleta.</p>
<h2>Estrutura do Relatório</h2>
    <p>A estrutura do relatório foi organizada para fornecer uma visão abrangente e sistemática dos elementos analisados, incluindo:</p>
    
    <ul>
        <li><strong>Arquivos Coletados:</strong> Descrição dos arquivos, com foco em tipo, tamanho, data de criação e localização.</li>
        <li><strong>Metadados:</strong> Informações técnicas associadas, como autor, histórico de modificações e permissões de acesso.</li>
        <li><strong>Logs:</strong> Análise de registros de sistema ou aplicativos, identificando eventos e atividades relevantes.</li>
        <li><strong>Capturas de Tela:</strong> Registros visuais obtidos, organizados por ordem cronológica e contextualizados.</li>
        <li><strong>Verificação de Integridade:</strong> Resultados das funções hash aplicadas, comprovando a consistência dos dados.</li>
    </ul>
<h2>Funções Hash</h2>
    <p><strong>As funções hash </strong> são algoritmos matemáticos que transformam dados de qualquer tamanho em uma sequência alfanumérica de comprimento fixo, 
    conhecida como <strong>valor hash</strong>. Esse código é único para cada conjunto de dados, funcionando como uma <strong> "impressão digital"</strong>. 
    <strong> Qualquer alteração</strong>, por menor que seja, nos dados originais — como a modificação de um único bit — gera um valor hash completamente diferente. 
    Essa característica torna as funções hash uma ferramenta essencial para <strong>verificar a integridade</strong> de arquivos, detectar adulterações e garantir a autenticidade dos dados.</p>
<h2>Arquivos coletados</h2>
EOF

    while IFS="|" read -r filename basepath hash description type urlRegistro; do
    
    echo "<table style=\"border-collapse: collapse; width: 100%; font-family: monospace; font-size: 12px; border: 1px solid #ddd;\">" >> "$TEMP_FILE"
    echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Nome do Arquivo</th><td style=\"border: 1px solid #ddd; padding: 8px;\">$(basename "$filename")</td></tr>" >> "$TEMP_FILE"
    
    if [ -n "$urlRegistro" ]; then
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Referência</th><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href=\"$urlRegistro\">$urlRegistro</a></td></tr>" >> "$TEMP_FILE"
    fi   

    if [[ "$type" == "1" ]]; then
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Imagem</th><td style=\"border: 1px solid #ddd; padding: 8px;\"><img src=\"file://$(realpath "$filename")\" alt=\"$(basename "$filename")\" style=\"width:300px;height:auto;\"></td></tr>" >> "$TEMP_FILE"
        mkdir -p "$pasta_saida/imagens"
        cp "$filename" "$pasta_saida/imagens/"
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Link</th><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href=\"./imagens/$(basename "$filename")\">$(basename "$filename")</a></td></tr>" >> "$TEMP_FILE"
        
        if [ -n "$description" ]; then
            echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Descrição</th><td style=\"border: 1px solid #ddd; padding: 8px;\">$description</td></tr>" >> "$TEMP_FILE"
        fi
    fi

    if [[ "$type" == "2" ]]; then
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Vídeo</th><td style=\"border: 1px solid #ddd; padding: 8px;\"><img src=\"https://img.icons8.com/ios-filled/50/000000/video.png\" alt=\"Thumbnail\" style=\"width:50px;height:auto;\"></td></tr>" >> "$TEMP_FILE"
        mkdir -p "$pasta_saida/videos"
        cp "$filename" "$pasta_saida/videos/"
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Link</th><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href=\"./videos/$(basename "$filename")\">$(basename "$filename")</a></td></tr>" >> "$TEMP_FILE"
        if [ -n "$description" ]; then
            echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Descrição</th><td style=\"border: 1px solid #ddd; padding: 8px;\">$description</td></tr>" >> "$TEMP_FILE"
        fi
    fi

    if [[ "$type" == "3" ]]; then
        mkdir -p "$pasta_saida/downloads"
        cp "$filename" "$pasta_saida/downloads/"
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Download</th><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href=\"./downloads/$(basename "$filename")\">$(basename "$filename")</a></td></tr>" >> "$TEMP_FILE"
        if [ -n "$description" ]; then
            echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Descrição</th><td style=\"border: 1px solid #ddd; padding: 8px;\">$description</td></tr>" >> "$TEMP_FILE"
        fi
        
    
        echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Observações Técnicas</th><td style=\"border: 1px solid #ddd; padding: 8px;\">Os arquivos classificados como 'downloads' são aqueles obtidos diretamente por meio de extensões ou plugins do navegador. Esses arquivos podem incluir dados relevantes para a análise, como documentos, imagens ou outros tipos de mídia baixados durante a navegação. A rastreabilidade desses downloads é garantida pelos logs de requisições, que documentam as URLs de origem e os parâmetros associados a cada download.</td></tr>" >> "$TEMP_FILE"
    fi

    echo "<tr><th style=\"border: 1px solid #ddd; padding: 8px;\">Hash SHA-256</th><td style=\"border: 1px solid #ddd; padding: 8px;\">$hash</td></tr>" >> "$TEMP_FILE"

    echo "</table>" >> "$TEMP_FILE"

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
    exif_data=$(exiftool "$filename" | awk -F': ' '{printf "<tr><td style=\"padding: 2px; font-weight: bold; font-size: 9px;  border: 1px solid #ddd; \">%s</td><td style=\"padding: 2px; font-size: 9px;border: 1px solid #ddd;\">%s</td></tr>", $1, $2}')
    echo "<table style=\"border-collapse: collapse; width: 280px; font-family: monospace; font-size: 9px; background-color: #f4f4f4; border: none;\">$exif_data</table>" >> "$TEMP_FILE"

    echo "<hr>" >> "$TEMP_FILE"
    done < <(sqlite3 "$pasta/screencaption-db.db" "SELECT DISTINCT filename,1 basepath, hash, description, type, urlRegistro FROM screencaption WHERE filename IS NOT NULL AND basepath IS NOT NULL AND hash IS NOT NULL AND type IS NOT NULL;")

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
    cat <<EOF >> "$TEMP_FILE"
<h2>Ferramentas Utilizadas</h2>
<p>Este projeto utiliza diversas ferramentas para realizar a coleta e análise de dados. Abaixo está uma descrição técnica de cada uma delas:</p>
<table style="border-collapse: collapse; width: 100%; font-family: monospace; font-size: 12px;">
    <tr style="background-color: #f2f2f2; text-align: left;">
        <th style="border: 1px solid #ddd; padding: 8px;">Ferramenta</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Descrição</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Link</th>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">scrot</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta de linha de comando para capturar screenshots.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/resurrecting-open-source-projects/scrot">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">zenity</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta que permite exibir caixas de diálogo gráficas a partir de scripts de shell.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/ncruces/zenity">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">ffmpeg</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Um framework completo para gravar, converter e transmitir áudio e vídeo.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/FFmpeg/FFmpeg">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">ImageMagick</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Um software para criar, editar, compor ou converter imagens bitmap.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/ImageMagick/ImageMagick">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">exiftool</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta de linha de comando para leitura, escrita e edição de metadados em arquivos.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/exiftool/exiftool">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">pandoc</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Um conversor universal de documentos.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/jgm/pandoc">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">slop</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta para selecionar áreas da tela.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/naelstrof/slop">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">maim</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta de captura de tela.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/naelstrof/maim">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">xclip</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta de linha de comando para interagir com a área de transferência X.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/astrand/xclip">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">tinyproxy</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Um proxy HTTP leve.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/tinyproxy/tinyproxy">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">mitmproxy</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Um proxy HTTP/HTTPS interativo para depuração e análise de tráfego.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/mitmproxy/mitmproxy">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">wkhtmltopdf</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta para converter HTML em PDF usando Webkit.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://github.com/wkhtmltopdf/wkhtmltopdf">Acessar</a></td>
    </tr>
    <tr>
        <td style="border: 1px solid #ddd; padding: 8px;">sha256sum</td>
        <td style="border: 1px solid #ddd; padding: 8px;">Uma ferramenta de linha de comando para calcular e verificar hashes SHA-256.</td>
        <td style="border: 1px solid #ddd; padding: 8px;"><a href="https://www.gnu.org/software/coreutils/manual/html_node/sha2-utilities.html">Acessar</a></td>
    </tr>
</table>
EOF
echo "<h2>Referências Técnicas</h2>" >> "$TEMP_FILE"
echo "<table style=\"border-collapse: collapse; width: 100%; font-family: monospace; font-size: 12px;\">" >> "$TEMP_FILE"
echo "<tr style=\"background-color: #f2f2f2; text-align: left;\">" >> "$TEMP_FILE"
echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Referência</th>" >> "$TEMP_FILE"
echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Descrição</th>" >> "$TEMP_FILE"
echo "<th style=\"border: 1px solid #ddd; padding: 8px;\">Link</th>" >> "$TEMP_FILE"
echo "</tr>" >> "$TEMP_FILE"

echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">ISO/IEC 27037:2012</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Information technology — Security techniques — Guidelines for identification, collection, acquisition, and preservation of digital evidence.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.iso.org/standard/44381.html' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">ISO/IEC 27001:2013</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Information technology — Security techniques — Information security management systems — Requirements.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.iso.org/standard/54534.html' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">ISO/IEC 27002:2013</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Information technology — Security techniques — Code of practice for information security controls.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.iso.org/standard/54533.html' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">ISO/IEC 27035:2016</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Information technology — Security techniques — Information security incident management.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.iso.org/standard/63026.html' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">Marco Civil da Internet (Lei Nº 12.965/2014)</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Estabelece princípios, garantias, direitos e deveres para o uso da Internet no Brasil.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2014/lei/l12965.htm' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">Artigo 7º</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Estabelece os direitos dos usuários da Internet.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2014/lei/l12965.htm#art7' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">Artigo 10º</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Trata da guarda e proteção dos registros de conexão e de acesso a aplicações de Internet.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2014/lei/l12965.htm#art10' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"
echo "<tr><td style=\"border: 1px solid #ddd; padding: 8px;\">Artigo 11º</td><td style=\"border: 1px solid #ddd; padding: 8px;\">Estabelece que a coleta, guarda, armazenamento e tratamento de dados pessoais ou de comunicações devem respeitar a legislação brasileira.</td><td style=\"border: 1px solid #ddd; padding: 8px;\"><a href='https://www.planalto.gov.br/ccivil_03/_ato2011-2014/2014/lei/l12965.htm#art11' target='_blank'>Acessar</a></td></tr>" >> "$TEMP_FILE"

echo "</table>" >> "$TEMP_FILE"

echo "<p>Para fins de esclarecimentos e informações adicionais, consulte o <a href=\"./glossario.pdf\"> Glossário Técnico</a>.</p>" >> "$TEMP_FILE"

echo "<h2>Considerações Finais</h2>" >> "$TEMP_FILE"
echo "<p>O presente relatório foi elaborado para fornecer uma visão abrangente e técnica dos vestígios digitais coletados, com foco na integridade e autenticidade dos dados.
 A análise de logs de navegação e metadados permite uma compreensão detalhada das atividades no sistema, fundamentando investigações mais eficazes. Além disso, 
o relatório segue rigorosamente as diretrizes do Marco Civil da Internet, assegurando a proteção dos dados pessoais, o respeito aos direitos dos usuários e a legalidade e 
ética nas investigações digitais.</p>" >> "$TEMP_FILE"

echo "<p>Frente ao exposto e considerando os elementos de informações preliminares coligidos, a  <strong> MPRJ/CSI/DEIC </strong> submete o presente <strong> Relatório de Coleta de Vestígios Digitais</strong>, elaborado em estrita conformidade com os protocolos técnicos e normativos vigentes, garantindo a <string> integralidade</strong> e a <strong> precisão</strong> 
das informações apresentadas. Nada mais havendo a relatar, encerra-se este relatório, que, lido e achado conforme, segue devidamente assinado pelo técnico pericial, colocando-se à disposição para eventuais demandas complementares que possam assegurar a <strong> completude</strong> e a <strong> confiabilidade</strong> do trabalho realizado.</p>" >> "$TEMP_FILE"
echo "<br><br>" >> "$TEMP_FILE"

echo "<div style=\"text-align: center; margin-top: 100px; font-family: monospace; line-height: 0.3;\">" >> "$TEMP_FILE"
echo "<p>__________________________________________</p>" >> "$TEMP_FILE"
echo "<p><strong>Franqlin Soares dos Santos</strong></p>" >> "$TEMP_FILE"
echo "<p><em>Mat.:3564</em></p>" >> "$TEMP_FILE"
echo "</div>" >> "$TEMP_FILE"

cat <<EOF >> "$TEMP_FILE"
</body>
</html>

EOF

    (
        # Exibir barra de progresso enquanto os processos são executados
        (
            echo "10"; sleep 1
            echo "# Convertendo o relatório para PDF..."
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
            echo "50"; sleep 1
            echo "# Movendo o arquivo temporário..."
            mv "$TEMP_FILE" "$pasta_saida/relatorio_final_$(date +"%Y%m%d_%H%M%S").html"
            echo "70"; sleep 1
            echo "# Criando pastas de saída e copiando arquivos..."
            mkdir -p "$pasta_saida/logs"
            cp "$pasta/requests.txt" "$pasta_saida/logs/"
            cp "$pasta/odysseus_snap.log" "$pasta_saida/logs/"
            cp "$pasta/LogSistemaOperacional.log" "$pasta_saida/logs/"
            echo "90"; sleep 1
            echo "# Gerando glossário técnico..."
            imprimir_glossario
            echo "100"; sleep 1
        ) | zenity --progress --title="Processando Relatório" --text="Aguarde enquanto o relatório é gerado..." --percentage=0 --auto-close --no-cancel
    )

    # Informar ao usuário que o relatório foi gerado
    zenity --info --text="Relatório final gerado em $OUTPUT_FILE_PDF"

    # Abrir o relatório PDF gerado com a aplicação padrão
    xdg-open "$OUTPUT_FILE_PDF"
   

}
imprimir_glossario() {
    GLOSSARIO_FILE="$pasta_saida/glossario.html"
    OUTPUT_FILE_PDF="$pasta_saida/glossario.pdf"
    cat <<EOF > "$GLOSSARIO_FILE"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Glossário Técnico</title>
<style>
body { font-family: Arial, sans-serif; }
h2 { color: #782c24; text-align: center; }
ul { list-style-type: none; padding: 0; }
li { margin-bottom: 10px; }
strong { color: #333; }
img { max-width: 100%; height: auto; }
</style>
</head>
<body>
<div style="text-align: center; font-size: 12px;">
    <img src="${LOGO_READER_:-default_logo.png}"><br> 
    <strong>COORDENADORIA DE SEGURANÇA E INTELIGÊNCIA</strong><br>
    DIVISÃO ESPECIAL DE INTELIGÊNCIA CIBERNÉTICA<br>
    Av. General Justo, 375/5º andar, Centro, Rio de Janeiro – RJ.<br>
    Telefones: (21) 2292-8459 - e-mail: <a href="mailto:csi.deic@mprj.mp.br">csi.deic@mprj.mp.br</a>
</div>
<h2>Glossário Técnico</h2>
<ul>
    <li><strong>Arquitetura (x86_64):</strong> Refere-se ao tipo de processador e ao conjunto de instruções que ele suporta. x86_64 é uma arquitetura de 64 bits.</li>
    <li><strong>Capturas de Tela:</strong> Registros visuais obtidos durante a análise, organizados por ordem cronológica e contextualizados.</li>
    <li><strong>DNS (Domain Name System):</strong> Sistema que traduz nomes de domínio (como www.instagram.com) em endereços IP.</li>
    <li><strong>ExifTool:</strong> Ferramenta de linha de comando para leitura de metadados em arquivos.</li>
    <li><strong>Funções Hash:</strong> Algoritmos matemáticos que transformam dados em uma sequência alfanumérica de comprimento fixo, usados para verificar a integridade de arquivos.</li>
    <li><strong>Gateway Padrão:</strong> O endereço IP do dispositivo que atua como ponto de acesso para outras redes.</li>
    <li><strong>Host:</strong> O nome do computador ou dispositivo onde a análise foi realizada.</li>
    <li><strong>IP (Internet Protocol):</strong> Endereço único atribuído a cada dispositivo conectado a uma rede.</li>
    <li><strong>Kernel:</strong> O núcleo do sistema operacional, responsável por gerenciar recursos do sistema e facilitar a comunicação entre hardware e software.</li>
    <li><strong>Logs:</strong> Registros de eventos ou atividades realizadas em um sistema ou aplicativo.</li>
    <li><strong>Metadados:</strong> Informações técnicas associadas a arquivos, como autor, histórico de modificações e permissões de acesso.</li>
    <li><strong>MP4 (MPEG-4 Part 14):</strong> Formato de arquivo de vídeo que armazena áudio, vídeo e outros dados.</li>
    <li><strong>PNG (Portable Network Graphics):</strong> Formato de arquivo de imagem que suporta compressão sem perda de qualidade.</li>
    <li><strong>SHA-256:</strong> Algoritmo de hash que gera um valor de 256 bits, usado para verificar a integridade de arquivos.</li>
    <li><strong>Sistema Operacional (GNU/Linux):</strong> O software básico que gerencia os recursos de hardware e software de um computador.</li>
    <li><strong>Traceroute:</strong> Ferramenta que rastreia o caminho que os pacotes de dados seguem de um dispositivo para outro na internet.</li>
    <li><strong>WHOIS:</strong> Protocolo usado para consultar informações sobre domínios registrados, como proprietário e data de registro.</li>
    <li><strong>Google Chrome:</strong> Um navegador web desenvolvido pela Google, conhecido por sua velocidade, simplicidade e suporte a extensões. Ele utiliza o motor de renderização Blink e é amplamente utilizado para navegação na internet. Para mais informações, consulte a <a href="https://pt.wikipedia.org/wiki/Google_Chrome" target="_blank">página do Google Chrome na Wikipédia</a>.</li>
    <li><strong>Firefox:</strong> Um navegador web de código aberto desenvolvido pela Mozilla Foundation, conhecido por sua privacidade e personalização. Ele utiliza o motor de renderização Gecko e é amplamente utilizado para navegação na internet. Para mais informações, consulte a <a href="https://pt.wikipedia.org/wiki/Firefox" target="_blank">página do Firefox na Wikipédia</a>.</li>
    <li><strong>Extensões do Google Chrome:</strong> Ferramentas adicionais que podem ser instaladas no navegador Google Chrome para adicionar funcionalidades ou modificar o comportamento do navegador. Elas podem ser usadas para capturar dados, modificar páginas da web ou melhorar a experiência do usuário. Para mais informações, consulte a <a href="https://support.google.com/chrome_webstore/answer/2664769?hl=pt-BR" target="_blank">página de suporte do Google Chrome Web Store</a>.</li>
    <li><strong>Extensões do Firefox:</strong> Ferramentas adicionais que podem ser instaladas no navegador Firefox para adicionar funcionalidades ou modificar o comportamento do navegador. Elas podem ser usadas para capturar dados, modificar páginas da web ou melhorar a experiência do usuário. Para mais informações, consulte a <a href="https://support.mozilla.org/pt-BR/kb/instalar-extensoes-firefox" target="_blank">página de suporte do Firefox</a>.</li>
    <li><strong>Captura de Tela:</strong> Uma imagem do que está sendo exibido na tela de um dispositivo em um determinado momento. É frequentemente usada para documentar atividades ou compartilhar informações visuais.</li>
    <li><strong>Captura de Vídeo:</strong> Um registro em movimento do que está sendo exibido na tela de um dispositivo. É frequentemente usada para documentar atividades ou compartilhar informações visuais em tempo real.</li>
    <li><strong>Captura de Dados:</strong> O processo de coletar informações de um dispositivo ou sistema, que pode incluir arquivos, logs, metadados e outros dados relevantes.</li>
    <li><strong>Captura de Rede:</strong> O processo de monitorar e registrar o tráfego de dados que passa por uma rede, permitindo a análise de comunicações e atividades online.</li> 
    <li><strong>Captura de Pacotes:</strong> O processo de interceptar e registrar pacotes de dados que trafegam em uma rede, permitindo a análise detalhada do tráfego de rede.</li>
    <li><strong>Captura de Tráfego:</strong> O processo de monitorar e registrar o tráfego de dados que passa por uma rede, permitindo a análise de comunicações e atividades online.</li>
    <li><strong>Captura de Dados de Navegação:</strong> O processo de coletar informações sobre as atividades de um usuário em um navegador, incluindo URLs acessadas, cookies e downloads.</li>            
    <li><strong>Captura de Dados de Extensões:</strong> O processo de coletar informações sobre as atividades de um usuário em extensões do navegador, incluindo URLs acessadas, cookies e downloads.</li>
    <li><strong>Captura de Dados de Cookies:</strong> O processo de coletar informações armazenadas em cookies, que são pequenos arquivos de texto usados por sites para armazenar informações sobre o usuário.</li>    
    <li><strong>Captura de Dados de Downloads:</strong> O processo de coletar informações sobre arquivos baixados por um usuário, incluindo nomes de arquivos, tamanhos e locais de armazenamento.</li>
    <li><strong>Captura de Dados de Histórico:</strong> O processo de coletar informações sobre as páginas visitadas por um usuário em um navegador, incluindo URLs, horários e durações de visita.</li>    
    <li><strong>Captura de Dados de Favoritos:</strong> O processo de coletar informações sobre os sites marcados como favoritos por um usuário em um navegador, incluindo URLs e nomes de páginas.</li>    
    
</ul>
</body>
</html>
EOF

    # Converter o glossário para PDF usando wkhtmltopdf
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
     "$GLOSSARIO_FILE" "$OUTPUT_FILE_PDF"

    # Informar ao usuário que o glossário foi gerado
    #zenity --info --text="Glossário técnico gerado em $OUTPUT_FILE_PDF"

    # Abrir o glossário PDF gerado com a aplicação padrão
    #xdg-open "$OUTPUT_FILE_PDF"
}