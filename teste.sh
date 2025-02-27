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

# create the notification icon
yad --notification \
  --listen \
  --image="gnome-info" \
  --text="Notification tooltip" \
  --command="bash -c on_click" <&3