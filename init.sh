#!/bin/bash

#DNF Update/Install
sudo dnf update -y;
sudo dnf install git gh zsh tmux stow neovim -y;

#Stow Files
cd dotfiles;
stow */;

#ZSdnffs Shell
chsh -s $(which zsh);
