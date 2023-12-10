#!/bin/bash

#APT Update/Install
sudo apt update;
sudo apt upgrade -y;
sudo apt install zsh tmux stow python3 python3-pip nodejs npm ruby gem libfuse2 -y;

#Neovim Install
cd;
mkdir .appImage;
cd .appImage;
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage;
chmod u+x nvim.appimage;
sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'

#Erstelle config Ordner
cd;
mkdir ~/.config;
mkdir ~/.config/zsh;


#Git Repo mit Submodulen init
git clone https://github.com/NRossmann/dotfiles.git;
git submodule init;
git submodule update;
cd dotfiles;
stow */;

#ZSH als Shell
chsh -s $(which zsh);

#Benachrichtigung Setup fertig
curl -d "Initial Setup Complete" 139-162-144-34.ip.linodeusercontent.com/UjLbKJDfEc6qnvrG;
