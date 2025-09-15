###############################################################################
# Aliases & Functions (Oh My Zsh custom)
# File: ~/.oh-my-zsh/custom/aliases.zsh
# Purpose: Git QOL + your shortcuts, compatible with oh-my-zsh `git` plugin
###############################################################################

# -----------------------------------------------------------------------------
# Editor & dotfiles
# -----------------------------------------------------------------------------
alias zshconfig="nvim ~/.zshrc"
alias nvimconfig="nvim ~/.config/nvim/init.lua"
alias zshreload="source ~/.zshrc"
alias tmuxconfig="nvim ~/.config/tmux/tmux.conf"

# -----------------------------------------------------------------------------
# Git: compact status & readable logs
# -----------------------------------------------------------------------------
alias gss='git status -sb'                                  # compact status
alias glg="git log --oneline --decorate --graph --all"      # pretty graph
alias glp='git log --pretty=format:"%C(auto)%h %ad %d %s %C(blue)[%an]" --date=relative'

# -----------------------------------------------------------------------------
# Git: safe fetch & pull
# -----------------------------------------------------------------------------
alias gfp='git fetch --prune --all'                         # prune dead remotes
alias gpf='git pull --ff-only'                              # avoid merge commits on pull

# -----------------------------------------------------------------------------
# Git: stash helpers
# -----------------------------------------------------------------------------
alias gstm='git stash push -u -m'                           # usage: gstm "msg"
alias gstp='git stash pop'

# -----------------------------------------------------------------------------
# Git: worktree helpers
# -----------------------------------------------------------------------------
alias gwtl='git worktree list'
alias gwta='git worktree add'                               # usage: gwta ../path branch
alias gwtp='git worktree prune'

# -----------------------------------------------------------------------------
# Git: repo navigation
# -----------------------------------------------------------------------------
alias groot='cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"'
alias gedit='${EDITOR:-nvim} "$(git rev-parse --show-toplevel 2>/dev/null)"/'

# -----------------------------------------------------------------------------
# Git: branch utilities
# -----------------------------------------------------------------------------
# Create a new branch from HEAD, or from the default remote branch with -m
gnew() { # usage: gnew <branch> [-m]
  local base=""
  if [[ "$2" == "-m" ]]; then
    base="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
    base="${base:-main}"
    git fetch origin "$base" --quiet
    git switch -c "$1" "origin/$base"
  else
    git switch -c "$1"
  fi
}


# Delete local branches already merged into the default branch (dry-run by default)
gprune_branches() {
  local base dry=1
  [[ "$1" == "-f" ]] && dry=0
  base="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')"
  base="${base:-main}"
  git fetch origin --prune
  git for-each-ref --format='%(refname:short)' refs/heads/ \
  | grep -vE "^(HEAD|$base|master|main|dev)$" \
  | while read -r br; do
      [[ -z "$br" ]] && continue
      if git merge-base --is-ancestor "$br" "origin/$base" 2>/dev/null; then
        if (( dry )); then
          echo "[dry-run] would delete: $br"
        else
          git branch -d "$br"
        fi
      fi
    done
}
alias gprune='gprune_branches'            # dry-run
alias gprunef='gprune_branches -f'        # actually delete

# -----------------------------------------------------------------------------
# Git: commit surgery (fixup/squash/undo/WIP)
# -----------------------------------------------------------------------------
# Make a fixup commit then autosquash interactively
gfix() { # usage: gfix <commit-ish>
  git commit --fixup "$1" && git rebase -i --autosquash "${1}~1"
}

# Squash the last N commits into one
gsquash() { # usage: gsquash <N> "message"
  local n="${1:-2}"; shift
  git reset --soft "HEAD~$n" && git commit -m "${*:-squash $n commits}"
}

# Undo last commit but keep changes staged
alias gundo='git reset --soft HEAD~1'

# Quick WIP helpers
alias gwip='git commit -am "WIP" --no-verify || true'
alias gunwip='git reset --soft HEAD~1'

# -----------------------------------------------------------------------------
# Git: safer pushes (block force to protected branches)
# -----------------------------------------------------------------------------
_protected_branch() {
  git symbolic-ref --quiet --short HEAD 2>/dev/null
}
_default_branch() {
  git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'
}

gpush() { # like 'git push' but blocks force to protected branches
  local cur="$(_protected_branch)" def="$(_default_branch)"; def="${def:-main}"
  if [[ "$1" == "--force" || "$1" == "-f" ]]; then
    if [[ "$cur" == "$def" || "$cur" == "main" || "$cur" == "master" ]]; then
      echo "✋ Refusing to force-push to protected branch: $cur"
      return 1
    fi
  fi
  git push "$@"
}

# Explicit force push, only when naming a non-protected branch
gpF() {
  local br="${2:-$(_protected_branch)}" remote="${1:-origin}"
  local def="$(_default_branch)"; def="${def:-main}"
  if [[ "$br" == "main" || "$br" == "master" || "$br" == "$def" ]]; then
    echo "✋ Refusing to force-push to protected branch: $br"
    return 1
  fi
  git push --force "$remote" "$br"
}

# -----------------------------------------------------------------------------
# GitHub CLI integrations (renamed to avoid clash with `gpr`)
# -----------------------------------------------------------------------------
if command -v gh >/dev/null 2>&1; then
  alias ghpr='gh pr create -f'            # create PR from current branch
  alias ghprv='gh pr view -w'             # open PR in browser
  alias ghprc='gh pr checkout'            # checkout PR by number/url
fi

###############################################################################
# End of file
###############################################################################
