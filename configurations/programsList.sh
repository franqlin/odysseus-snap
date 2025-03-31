
# Verifica se o tkinter está instalado
if ! python3 -c "import tkinter" &> /dev/null
then
    echo "tkinter não está instalado. Instalando..."
    sudo apt-get install python3-tk -y
fi

#sudo apt-get install python3-tk

# Verifica se o scrot está instalado
if ! command -v scrot &> /dev/null
then
    echo "scrot não está instalado. Instalando..."
    sudo apt-get install scrot -y
fi

# Verifica se o zenity está instalado
if ! command -v zenity &> /dev/null
then
    echo "zenity não está instalado. Instalando..."
    sudo apt-get install zenity -y
fi

# Verifica se o ffmpeg está instalado
if ! command -v ffmpeg &> /dev/null
then
    echo "ffmpeg não está instalado. Instalando..."
    sudo apt-get install ffmpeg -y
fi

# Verifica se o ImageMagick está instalado
if ! command -v convert &> /dev/null
then
    echo "ImageMagick não está instalado. Instalando..."
    sudo apt-get install imagemagick -y
fi

# Verifica se o exiftool está instalado
if ! command -v exiftool &> /dev/null
then
    echo "exiftool não está instalado. Instalando..."
    sudo apt-get install exiftool -y
fi

# Verifica se o pandoc está instalado
if ! command -v pandoc &> /dev/null
then
    echo "pandoc não está instalado. Instalando..."
    sudo apt-get install pandoc -y
fi

# Verifica se o slop está instalado
if ! command -v slop &> /dev/null
then
    echo "slop não está instalado. Instalando..."
    sudo apt-get install slop -y
fi
# Verifica se o maim está instalado
if ! command -v maim &> /dev/null
then
    echo "maim não está instalado. Instalando..."
    sudo apt-get install maim -y
fi
if ! command -v xclip &> /dev/null
then
    echo "xclip não está instalado. Instalando..."
    sudo apt-get install xclip -y
fi
# Verifica se o Tinyproxy está instalado
if ! command -v tinyproxy &> /dev/null
then
    echo "Tinyproxy não está instalado. Instalando..."
    sudo apt-get install tinyproxy -y
fi
# Verifica se o yad está instalado
if ! command -v yad &> /dev/null
then
    echo "yad não está instalado. Instalando..."
    sudo apt-get install yad -y
fi