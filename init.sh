#!/bin/bash
sudo apt update;
sudo apt upgrade -y;
sudo apt install zsh tmux stow guix -y;
sudo guix pull;
sudo guix package --install neovim;
GUIX_PROFILE="$HOME/.guix-profile";
. "$GUIX_PROFILE/etc/profile";
mkdir ~/.config;
mkdir ~/.config/zsh;
cd;
git clone https://github.com/NRossmann/dotfiles.git;
cd dotfiles;
stow */;
chsh -s $(which zsh);
curl -d "Initial Setup Complete" 139-162-144-34.ip.linodeusercontent.com/UjLbKJDfEc6qnvrG;
