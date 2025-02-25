#!/bin/bash
# Display splash screen with Zenity
(
  # Exibir a splash screen com a imagem logo.png por 3 segundos usando yad
yad --image="assets/images/logo.png" --timeout=3 --no-buttons --title="Bem-vindo" --text="Carregando..." --center --undecorated --fixed --skip-taskbar --no-escape  
) &
sleep 5
source "$(dirname "$0")/database/report-data-db.sh"
source "$(dirname "$0")/database/screencaption.sh"
source "$(dirname "$0")/configurations/config.sh"
source "$(dirname "$0")/configurations/programsList.sh"
source "$(dirname "$0")/actions/chooseFile.sh"
source "$(dirname "$0")/actions/sysInfo.sh"
source "$(dirname "$0")/actions/logger.sh"
source "$(dirname "$0")/actions/screenshot.sh"
source "$(dirname "$0")/actions/report.sh"
source "$(dirname "$0")/actions/screencast.sh"
source "$(dirname "$0")/actions/httpproxyintersept.sh"
source "$(dirname "$0")/actions/requestmonitor.sh"
source "$(dirname "$0")/actions/actions.sh"


# Função para abrir um formulário no yad e obter os valores
abrir_formulario() {
    formulario=$(yad --form --title="Formulário de Registro" --height=400 --width=500  --field="Referência" --field="Solicitação" --field="Registro" --center)
    if [ $? -eq 0 ]; then
        referencia=$(echo "$formulario" | awk -F '|' '{print $1}')
        solicitacao=$(echo "$formulario" | awk -F '|' '{print $2}')
        registro=$(echo "$formulario" | awk -F '|' '{print $3}')
        echo "Referência: $referencia"
        echo "Solicitação: $solicitacao"
        echo "Registro: $registro"
    else
        echo "Formulário cancelado."
    fi
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
        "🔗 Editar dados das Capturas" \
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
        "🔗 Editar dados das Capturas")
            if ! verificar_caso_fechado; then
                exibir_dados_tabela_screen
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
