#!/bin/bash

#APT Update/Install
sudo dnf update -y;
sudo apt install git gh zsh tmux stow neovim -y;

#Stow Files
cd dotfiles;
stow */;

#ZSH als Shell
chsh -s $(which zsh);

# Git Setup
git --global user.email "nrossmann@gmx.de"
git --global user.name " NRossmann"
