# Oh My Zsh Configuration

# Path to your Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme for Oh My Zsh
ZSH_THEME="simple"

# Set custom folder for Oh My Zsh (for plugins, aliases, etc.)
ZSH_CUSTOM="$HOME/.config/zsh"

# Load plugins (add wisely, too many slow down startup)
plugins=(git gh)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# User Configuration

# Set default editor (used for commands like visudo, git commit, etc.)
export EDITOR=nvim
export VISUAL=nvim

# Start tmux session on shell startup unless already inside tmux
if command -v tmux &> /dev/null; then
  if [ -z "$TMUX" ]; then
    tmux attach || tmux new-session
  fi
fi
eval "$(zoxide init zsh)"
# Aliases and customizations:
# You are encouraged to place custom aliases and shell functions in $ZSH_CUSTOM/aliases.zsh or other files in $ZSH_CUSTOM

# For a full list of active aliases, run `alias`

# Useful tips:
# - To update Oh My Zsh, run: omz update
# - To see available plugins: ls $ZSH/plugins
# - To see available themes: ls $ZSH/themes

# Uncomment and adjust the following lines as needed:
# export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"   # Add custom paths
# export LANG=en_US.UTF-8                                         # Set language environment
# export MANPATH="/usr/local/man:$MANPATH"                        # Set manual path
# export ARCHFLAGS="-arch $(uname -m)"                            # Set compilation flags
