#adicional libs
#  bugfix com links e funcionalidades com wkhtmltopdf

# Baixar e instalar libssl1.1
echo "(Re)install wkhtmltopdf"
sudo apt-get remove wkhtmltopdf
wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl1.1/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
sudo dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
rm -rf libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
# Baixar e instalar wkhtmltox
wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6-1/wkhtmltox_0.12.6-1.bionic_amd64.deb
sudo apt install ./wkhtmltox_0.12.6-1.bionic_amd64.deb 
rm -rf wkhtmltox_0.12.6-1.bionic_amd64.deb 
# problemas com screencast(x11grip)
# remover versão anterior do ffmpeg
#sudo snap install ffmpeg