#!/bin/bash
# Display splash screen with Zenity
(
  # Exibir a splash screen com a imagem logo.png por 3 segundos usando yad
yad --image="assets/images/logo.png" --timeout=3 --no-buttons --title="Bem-vindo" --text="Carregando..." --center --undecorated --fixed --skip-taskbar --no-escape  
) &
sleep 5

# Define the variable 'pasta' with the appropriate path
pasta="$(dirname "$0")"

source "$pasta/database/report-data-db.sh"
source "$pasta/database/screencaption.sh"
source "$pasta/configurations/config.sh"
source "$pasta/configurations/programsList.sh"
source "$pasta/actions/chooseFile.sh"
source "$pasta/actions/sysInfo.sh"
source "$pasta/actions/logger.sh"
source "$pasta/actions/screenshot.sh"
source "$pasta/actions/report.sh"
source "$pasta/actions/screencast.sh"
source "$pasta/actions/httpproxyintersept.sh"
source "$pasta/actions/requestmonitor.sh"
source "$pasta/actions/actions.sh"


# Função para abrir um formulário no yad e obter os valores
abrir_formulario() {
    
    
  
        
        # Verifica se já existe um registro com id 1
        registro_existente=$(sqlite3 $pasta/reportdata-db.db "SELECT COUNT(*) FROM report WHERE id=1;")
        
        if [ "$registro_existente" -gt 0 ]; then
            # Carrega os dados do registro com id 1
            alterar_registro=$(sqlite3 $pasta/reportdata-db.db "SELECT referencia, solicitacao, registro FROM report WHERE id=1;")
            referencia=$(echo "$alterar_registro" | awk -F '|' '{print $1}')
            solicitacao=$(echo "$alterar_registro" | awk -F '|' '{print $2}')
            registro=$(echo "$alterar_registro" | awk -F '|' '{print $3}')
            
            # Abre o formulário para editar os dados
            yad --form --title="Editar Registro" --height=400 --width=500 --field="Referência" --field="Solicitação" --field="Registro" --center --button="Salvar:0" --button="Cancelar:1" \
                -- "$referencia" "$solicitacao" "$registro" | {
                read -r referencia solicitacao registro
                alterar_dados_tabela_report_data "$referencia" "$solicitacao" "$registro"
            }
        else
            # Salva os dados no banco de dados
            formulario=$(yad --form --title="Formulário de Registro" --height=400 --width=500 --field="Referência" --field="Solicitação" --field="Registro" --center)
               if [ $? -eq 0 ]; then
                referencia=$(echo "$formulario" | awk -F '|' '{print $1}')
                solicitacao=$(echo "$formulario" | awk -F '|' '{print $2}')
                registro=$(echo "$formulario" | awk -F '|' '{print $3}')
                echo "Referência: $referencia"
                echo "Solicitação: $solicitacao"
                echo "Registro: $registro"
                salvar_dados_tabela_report_data "$referencia" "$solicitacao" "$registro"
             fi
        fi
   
    
}

alterar_dados_tabela_report_data() {
    local referencia="$1"
    local solicitacao="$2"
    local registro="$3"
    
    # Comando SQL para alterar os dados na tabela report-data
    sqlite3 $pasta/reportdata-db.db <<EOF
UPDATE "report" SET referencia='$referencia', solicitacao='$solicitacao', registro='$registro' WHERE id=1;      
EOF
}
# Função para salvar os dados na tabela report-data
salvar_dados_tabela_report_data() {
    local referencia="$1"
    local solicitacao="$2"
    local registro="$3"
    
    # Comando SQL para inserir os dados na tabela report-data
    sqlite3 $pasta/reportdata-db.db <<EOF

INSERT INTO "report" (referencia, solicitacao, registro)
VALUES ('$referencia', '$solicitacao', '$registro');
EOF
}   
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

# Interface gráfica principal
while true; do
    acao=$(zenity --list --title="Odysseus OSINT Report" --column="Ação" \
        "📝 Editar Referências do Relatório" \
        "📸 Capturar Área da Tela" \
        "🎥 Gravar Tela" \
        "✏️ Editar dados das Capturas" \
        "🗑️ Deletar dados das Capturas" \
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
        "📝 Editar Referências do Relatório")
            if ! verificar_caso_fechado; then
                abrir_formulario
            fi
            ;;
        "✏️ Editar dados das Capturas")
            if ! verificar_caso_fechado; then
                exibir_dados_tabela_screen
            fi
            ;;
         "🗑️ Deletar dados das Capturas")
            if ! verificar_caso_fechado; then
                exibir_deletar_dados_tabela_screen
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
