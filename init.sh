#!/bin/zsh
sudo apt update;
sudo apt upgrade -y;
sudo apt install zsh tmux stow guix -y;
guix package --install neovim;
GUIX_PROFILE="/root/.guix-profile";
. "$GUIX_PROFILE/etc/profile";
stow */;
