###############################################################################
# Aliases & Functions (Oh My Zsh custom)
# File: ~/.config/zsh/aliases.zsh
# Purpose: Aliases for ZSH
###############################################################################

# -----------------------------------------------------------------------------
# Navigation & Basics
# -----------------------------------------------------------------------------
alias ..='cd ..'
alias cd-dotfiles="cd ~/dotfiles"
alias c='clear'
alias la="ls -la"
alias ls='ls --color'

# -----------------------------------------------------------------------------
# Editor & Configs
# -----------------------------------------------------------------------------
alias nvimconfig="nvim ~/.config/nvim/init.lua"
alias tmuxconfig="nvim ~/.config/tmux/tmux.conf"
alias zshconfig="nvim ~/.zshrc"
alias zshaliasconfig="nvim ~/.config/zsh/aliases.zsh"
alias zshreload="source ~/.zshrc"

# -----------------------------------------------------------------------------
# Utilities
# -----------------------------------------------------------------------------
alias sudoedit="sudo -e"
alias venvactivate="source venv/bin/activate"
alias vim='nvim'

###############################################################################
# End of file
###############################################################################
