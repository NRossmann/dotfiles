#Init Oh my ZSH
export ZSH=$HOME/.config/zsh/.oh-my-zsh
ZSH_THEME="fino-time"
# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

#My Sources
source ~/.config/zsh/aliases.zsh
source ~/.config/zsh/fns.zsh

#Plugins
source ~/.config/zsh/.oh-my-zsh-plugins/zsh-autosuggestion/zsh-autosuggestions.zsh
source ~/.config/zsh/.oh-my-zsh-plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
