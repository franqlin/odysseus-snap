#!/usr/bin/bash

# create a FIFO file, used to manage the I/O redirection from shell
PIPE=$(mktemp -u --tmpdir ${0##*/}.XXXXXXXX)
mkfifo $PIPE

# attach a file descriptor to the file
exec 3<> $PIPE

# add handler to manage process shutdown
function on_exit() {
  echo "quit" >&3
  rm -f $PIPE
}
trap on_exit EXIT

# add handler for tray icon left click
function on_click() {
  firefox &
}
export -f on_click

# add handler for menu actions
function editar_referencias() {
  echo "Editar Referências do Relatório"
  # Adicione aqui a lógica para editar referências do relatório
}
export -f editar_referencias

function capturar_area() {
  echo "Capturar Área da Tela"
  # Adicione aqui a lógica para capturar área da tela
}
export -f capturar_area

function gravar_tela() {
  echo "Gravar Tela"
  # Adicione aqui a lógica para gravar tela
}
export -f gravar_tela

function abrir_pasta() {
  xdg-open "$HOME"
}
export -f abrir_pasta

# create the notification icon with menu
yad --notification \
  --listen \
  --image="gnome-info" \
  --text="Odysseus OSINT Report" \
 --command="bash -c on_click" \
  --menu="📝 Editar Referências do Relatório!bash -c editar_referencias|📸 Capturar Área da Tela!bash -c capturar_area|🎥 Gravar Tela!bash -c gravar_tela|📂 Abrir Pasta de Trabalho!bash -c abrir_pasta" <&3 