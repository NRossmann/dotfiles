#!/bin/bash
sudo apt update;
sudo apt upgrade -y;
sudo apt install zsh tmux stow python3 python3-pip nodejs npm ruby gem libfuse2 -y;
cd;
mkdir .appImage;
cd .appImage;
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage;
chmod u+x nvim.appimage;
cd;
mkdir ~/.config;
mkdir ~/.config/zsh;
cd;
git clone https://github.com/NRossmann/dotfiles.git;
cd dotfiles;
stow */;
chsh -s $(which zsh);
curl -d "Initial Setup Complete" 139-162-144-34.ip.linodeusercontent.com/UjLbKJDfEc6qnvrG;
