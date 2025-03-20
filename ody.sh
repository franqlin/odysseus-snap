#!/bin/bash

LOCKFILE="$HOME/ody.lock"

# Verificar se o lock file já existe
echo "Verificando se o programa já está em execução..."

if [ -e "$LOCKFILE" ]; then
    echo "O programa já está em execução."
    exit 1
fi

# Criar o lock file com o PID do processo
echo $$ > "$LOCKFILE"

# Remover o lock file ao sair
trap sair EXIT

# Função para sair do programa
sair() {
    echo "Saindo...$LOCKFILE"
    rm -f "$LOCKFILE"
    pkill -f "yad --notification"
    echo " kill "
    
    exit 0
}

# Função para executar odysseusreport
odysseusreport() {
    /bin/odysseusreport
}

# Função para executar odysseusreporthashpdf
odysseusreporthashpdf() {
    /bin/odysseusreporthashpdf
}

# Função para executar odysseusreporthashsheet
odysseusreporthashsheet() {
    /bin/odysseusreporthashsheet
}

export -f sair odysseusreport odysseusreporthashpdf odysseusreporthashsheet

# Criar o menu do system tray com yad
yad --notification \
    --listen \
    --image=ody \
    --text="Odysseus OSINT Tools" \
    --menu="📝 Odysseus Report!bash -c odysseusreport|\
    📝 Hash Report PDF!bash -c odysseusreporthashpdf|\
    📝 Hash Report XLS!bash -c odysseusreporthashsheet|\
    ❌ Sair!bash -c sair" &

# Manter o script em execução
while true; do
    sleep 60
done