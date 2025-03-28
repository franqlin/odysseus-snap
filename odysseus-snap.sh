#!/bin/bash
#(
  # Exibir a splash screen com a imagem logo.png por 3 segundos usando yad
#yad --image="assets/images/logo.png" --timeout=3 --no-buttons --title="Bem-vindo" --text="Carregando..." --center --undecorated --fixed --skip-taskbar --no-escape  
#) &

(for ((i=1; i<=100; i++)) {
    echo $i
    echo "# $((i))%"
    sleep 0.1
} | yad --splash \
  --progress \
  --pulsate \
  --image="assets/images/logo.png" \
  --text-align=center \
  --auto-close \
  --skip-taskbar \
  --center \
  --no-buttons) &
sleep 10

# Define the variable 'pasta' with the appropriate path
pasta="$(dirname "$0")"

source "$pasta/actions/form-data.sh"
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
source "$pasta/actions/downloads.sh"


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
        "🎥  Gravar Tela" \
        "📥 Registrar Download"\
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
        "🎥  Gravar Tela")
            if ! verificar_caso_fechado; then
                gravar_tela
            fi
            ;;
        "📥 Registrar Download")
            if ! verificar_caso_fechado; then
                selecionar_arquivo_e_copiar
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
