# Dotfiles — zsh · tmux · Neovim

Opinionated, minimal dotfiles managed with **GNU Stow**.  
Includes configs for:

- **zsh** (shell)
- **tmux** (terminal multiplexing)
- **Neovim** (editor)

There’s also an `init.sh` to (eventually) bootstrap everything. **Note:** right now that script **does not** remove or back up existing configs before stowing, so it will fail if files already exist. Workarounds below.

---

## Prerequisites

- **git**
- **GNU Stow** (`stow`)
- macOS or Linux (WSL is fine)

Install Stow (examples):
```bash
# macOS
brew install stow

# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y stow

# Fedora
sudo dnf install -y stow

# Arch
sudo pacman -S stow
```

---

## Layout

This repo is organized so Stow can re-create the correct paths under `$HOME`.

```
dotfiles/
├─ zsh/
│  └─ .zshrc
├─ tmux/
│  └─ .tmux.conf
└─ nvim/
   └─ .config/
      └─ nvim/
         ├─ init.lua
         └─ lua/...
```

> If your structure differs, adjust the `stow` commands accordingly.

---

## Quick start (manual, recommended for now)

1) **Clone:**
```bash
git clone https://github.com/yourname/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

2) **Back up** any existing configs to avoid collisions:
```bash
# Zsh
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.backup.$(date +%Y%m%d%H%M%S)

# tmux
[ -f ~/.tmux.conf ] && mv ~/.tmux.conf ~/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)

# Neovim
[ -d ~/.config/nvim ] && mv ~/.config/nvim ~/.config/nvim.backup.$(date +%Y%m%d%H%M%S)
```

3) **Stow** each package into `$HOME`:
```bash
stow -v -t "$HOME" zsh
stow -v -t "$HOME" tmux
stow -v -t "$HOME" nvim
```

That’s it. Open a new terminal for zsh to pick up changes; start `tmux`; launch `nvim`.

---

## Using `init.sh` (current limitation)

There is an `init.sh` intended to automate the steps above. **At the moment it doesn’t remove or back up existing configs**, so Stow will refuse to overwrite files and you’ll see errors like:

> `stow: warning: existing target is not a link: ~/.zshrc`

### Workarounds

**Option A — manual backups first (recommended):**  
Run the “Back up” commands from the Quick Start, then re-run `init.sh` or use the manual `stow` commands.

**Option B — adopt existing files into the repo:**  
If you know what you’re doing, `--adopt` will move existing files under Stow’s control **into** the package directory.
```bash
stow --adopt -v -t "$HOME" zsh tmux nvim
git status  # review moved files, commit as needed
```
> Careful: this changes your working tree by moving files into the repo.

---

## Update

Pull latest changes and restow (idempotent):
```bash
cd ~/.dotfiles
git pull
stow -v -R -t "$HOME" zsh tmux nvim
```

---

## Uninstall (de-stow)

Remove symlinks created by Stow:
```bash
cd ~/.dotfiles
stow -v -D -t "$HOME" zsh tmux nvim
```
Then restore any backups you made.

---

## Troubleshooting

- **“existing target is not a link”**  
  You still have a real file there. Back it up or remove it, or use `--adopt`.

- **Wrong paths created**  
  Stow mirrors the directory layout. Ensure files that should end up at `~/.config/nvim/...` live inside `nvim/.config/nvim/...` in the repo.

- **Neovim can’t see plugins/config**  
  Check `:checkhealth` in Neovim. Verify `$XDG_CONFIG_HOME` (defaults to `~/.config`) and your `runtimepath`.

---

## Roadmap / TODO

- [ ] Fix `init.sh` to:
  - [ ] Detect collisions and interactively **backup** or **remove** existing files.
  - [ ] Support a `--force` flag (non-interactive).
  - [ ] Offer `--adopt` mode for taking over existing files.
  - [ ] Verify prerequisites (git, stow) and OS.
- [ ] Add CI linting (shellcheck) for scripts.
- [ ] Document optional extras (fonts, themes, plugin managers).

---

## License

MIT. See `LICENSE`.

---

## Notes

These dotfiles are tailored for my workflow but should be easy to adapt. PRs and issues welcome if you spot something off.
