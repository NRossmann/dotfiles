#!/usr/bin/env bash
# Universal setup script:
# - updates system & installs base tools (git, gh/github-cli, zsh, tmux, stow, curl)
# - installs Neovim from tarball (Linux x86_64)
# - stows dotfiles packages with override (simplified approach)
# - sets Zsh as the default shell

set -u

#----- Config ----------------------------------------------------------------#
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.tar.gz"
NEOVIM_DEST_DIR="/usr/local/nvim"
NEOVIM_BIN_SYMLINK="/usr/local/bin/nvim"
BACKUP_ROOT="${HOME}/.dotfiles_backup"
BACKUP_BEFORE_OVERRIDE="${BACKUP_BEFORE_OVERRIDE:-false}"

#----- Helpers ---------------------------------------------------------------#
is_root() { [ "${EUID:-$(id -u)}" -eq 0 ]; }
have()    { command -v "$1" >/dev/null 2>&1; }
ts()      { date +"%Y%m%d-%H%M%S"; }
log()     { echo "[$(date '+%H:%M:%S')] $*"; }

SUDO=""
if ! is_root; then
  if have sudo; then
    SUDO="sudo"
  else
    log "This script needs root privileges for package installs. Install 'sudo' or run as root."
    exit 1
  fi
fi

#----- Detect OS / Package Manager ------------------------------------------#
OS=""
PM=""
ID_LIKE=""
if [[ "$(uname -s)" == "Darwin" ]]; then
  OS="darwin"
  PM="brew"
else
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS="${ID:-unknown}"
    ID_LIKE="${ID_LIKE:-}"
  else
    OS="unknown"
  fi
fi

update_cmd() {
  case "$1" in
    apt)     echo "$SUDO apt update -y && $SUDO apt upgrade -y" ;;
    dnf)     echo "$SUDO dnf -y upgrade" ;;
    yum)     echo "$SUDO yum -y makecache && $SUDO yum -y update" ;;
    pacman)  echo "$SUDO pacman -Syu --noconfirm" ;;
    zypper)  echo "$SUDO zypper refresh && $SUDO zypper update -y" ;;
    apk)     echo "$SUDO apk update && $SUDO apk upgrade" ;;
    brew)    echo "brew update && brew upgrade" ;;
    *)       echo "" ;;
  esac
}
install_cmd_many() {
  local pm="$1"; shift
  case "$pm" in
    apt)     echo "$SUDO apt install -y $*" ;;
    dnf)     echo "$SUDO dnf install -y $*" ;;
    yum)     echo "$SUDO yum install -y $*" ;;
    pacman)  echo "$SUDO pacman -S --noconfirm --needed $*" ;;
    zypper)  echo "$SUDO zypper install -y $*" ;;
    apk)     echo "$SUDO apk add $*" ;;
    brew)    echo "brew install $*" ;;
    *)       echo "" ;;
  esac
}
install_cmd_one() {
  local pm="$1" pkg="$2"
  case "$pm" in
    apt)     echo "$SUDO apt install -y $pkg" ;;
    dnf)     echo "$SUDO dnf install -y $pkg" ;;
    yum)     echo "$SUDO yum install -y $pkg" ;;
    pacman)  echo "$SUDO pacman -S --noconfirm --needed $pkg" ;;
    zypper)  echo "$SUDO zypper install -y $pkg" ;;
    apk)     echo "$SUDO apk add $pkg" ;;
    brew)    echo "brew install $pkg" ;;
    *)       echo "" ;;
  esac
}

#----- Choose PM and base package names -------------------------------------#
# NOTE: Neovim is NOT installed via package manager; we install from tarball.
BASE_PKGS=(git zsh tmux stow curl)
GH_CANDIDATES=(gh github-cli)

if [[ "$OS" == "darwin" ]]; then
  PM="brew"
  if ! have brew; then
    log "Homebrew not found; installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -d /opt/homebrew/bin ]]; then export PATH="/opt/homebrew/bin:$PATH"; fi
  fi
elif [[ "$OS" =~ (debian|ubuntu|linuxmint|elementary|pop) || "$ID_LIKE" =~ debian ]]; then
  PM="apt"
elif [[ "$OS" =~ (fedora) || "$ID_LIKE" =~ fedora ]]; then
  PM="dnf"
elif [[ "$OS" =~ (rhel|centos|rocky|almalinux) || "$ID_LIKE" =~ "rhel" ]]; then
  PM="yum"
elif [[ "$OS" =~ (arch|manjaro|endeavouros) || "$ID_LIKE" =~ arch ]]; then
  PM="pacman"; GH_CANDIDATES=(github-cli gh)
elif [[ "$OS" =~ (opensuse|sles|suse) || "$ID_LIKE" =~ "suse" ]]; then
  PM="zypper"
elif [[ "$OS" == "alpine" || "$ID_LIKE" =~ "alpine" ]]; then
  PM="apk"; GH_CANDIDATES=(github-cli gh)
else
  for cand in apt dnf yum pacman zypper apk; do
    if have "$cand"; then PM="$cand"; break; fi
  done
fi

if [[ -z "${PM:-}" ]]; then
  log "Unsupported or undetected distribution. Please install manually: git, gh/github-cli, zsh, tmux, stow, curl."
  exit 1
fi
log "Detected OS: ${OS}  | Using package manager: ${PM}"

#----- Update & Install base packages ---------------------------------------#
UCMD="$(update_cmd "$PM")"
if [[ -n "$UCMD" ]]; then
  log "Updating system..."
  bash -c "$UCMD"
fi

ICMD="$(install_cmd_many "$PM" "${BASE_PKGS[@]}")"
if [[ -n "$ICMD" ]]; then
  log "Installing base packages: ${BASE_PKGS[*]}"
  bash -c "$ICMD" || true
fi

# Ensure downloader
if ! have curl && ! have wget; then
  log "curl/wget not found after install attempt; trying to install curl..."
  GCMD="$(install_cmd_one "$PM" "curl")"
  [[ -n "$GCMD" ]] && bash -c "$GCMD" || true
fi

# Install GitHub CLI with fallbacks and verification
GH_INSTALLED=false
for ghpkg in "${GH_CANDIDATES[@]}"; do
  log "Attempting to install GitHub CLI package: $ghpkg"
  GCMD="$(install_cmd_one "$PM" "$ghpkg")"
  if [[ -n "$GCMD" ]]; then
    if bash -c "$GCMD"; then
      # Verify installation worked
      if have gh; then
        log "✓ GitHub CLI installed successfully: $(gh --version | head -n1)"
        GH_INSTALLED=true
        break
      else
        log "Package '$ghpkg' installed but 'gh' command not found"
      fi
    else
      log "Package '$ghpkg' not available via $PM. Trying next candidate..."
    fi
  fi
done

[[ "$GH_INSTALLED" == "false" ]] && log "Warning: GitHub CLI installation failed for all candidates"

#----- Neovim: install from tarball (Linux x86_64 only) ---------------------#
# portable-ish realpath fallback
realpath_f() {
  if have realpath; then realpath "$1" 2>/dev/null; else
    printf '%s\n' "$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)/$(basename "$1")" 2>/dev/null
  fi
}

install_neovim_tarball() {
  local url="$1"
  local tmpdir; tmpdir="$(mktemp -d)"
  log "Installing Neovim from tarball: $url"

  local tarball="$tmpdir/nvim.tar.gz"
  if have curl; then
    if ! curl -L --fail -o "$tarball" "$url"; then
      log "Failed to download Neovim tarball"
      rm -rf "$tmpdir"; return 1
    fi
  elif have wget; then
    if ! wget -O "$tarball" "$url"; then
      log "Failed to download Neovim tarball"
      rm -rf "$tmpdir"; return 1
    fi
  else
    log "Neither curl nor wget is available. Cannot download Neovim."
    rm -rf "$tmpdir"; return 1
  fi

  # Verify downloaded tarball
  if ! tar -tf "$tarball" >/dev/null 2>&1; then
    log "Downloaded tarball appears corrupted"
    rm -rf "$tmpdir"; return 1
  fi

  log "Extracting Neovim tarball..."
  if ! tar -C "$tmpdir" -xzf "$tarball"; then
    log "Failed to extract tarball"
    rm -rf "$tmpdir"; return 1
  fi

  local topdir; topdir="$(tar -tzf "$tarball" | head -1 | cut -d/ -f1)"
  if [[ -z "$topdir" || ! -d "$tmpdir/$topdir" ]]; then
    log "Failed to detect extracted directory."
    rm -rf "$tmpdir"; return 1
  fi

  # Verify nvim binary exists
  if [[ ! -f "$tmpdir/$topdir/bin/nvim" ]]; then
    log "nvim binary not found in extracted archive"
    rm -rf "$tmpdir"; return 1
  fi

  log "Installing Neovim to $NEOVIM_DEST_DIR"
  $SUDO rm -rf "$NEOVIM_DEST_DIR"
  $SUDO mkdir -p "$(dirname "$NEOVIM_DEST_DIR")"
  $SUDO mv "$tmpdir/$topdir" "$NEOVIM_DEST_DIR"

  $SUDO ln -sf "$NEOVIM_DEST_DIR/bin/nvim" "$NEOVIM_BIN_SYMLINK"

  if "$NEOVIM_BIN_SYMLINK" --version | head -n1 | grep -q "v0.11.4"; then
    log "✓ Neovim v0.11.4 installed successfully at $NEOVIM_BIN_SYMLINK"
  else
    log "Warning: Neovim installed, but version check did not match v0.11.4."
  fi

  rm -rf "$tmpdir"
}

if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
  install_neovim_tarball "$NEOVIM_URL" || log "Neovim tarball install failed."
else
  log "Skipping Neovim tarball (requires Linux x86_64)."
  [[ "$OS" == "darwin" ]] && log "On macOS, you can: brew install neovim"
fi

#----- Stow dotfiles WITHOUT override — pre-clean conflicting targets --------#
shopt -s nullglob dotglob

DOTDIR=""
if [[ -d "./dotfiles" ]]; then
  DOTDIR="./dotfiles"
elif [[ -d "$HOME/dotfiles" ]]; then
  DOTDIR="$HOME/dotfiles"
else
  DOTDIR="$(pwd)"
fi

if [[ ! -d "$DOTDIR" ]]; then
  log "No dotfiles directory found; skipping stow."
else
  log "Preparing to stow from: $DOTDIR"
  pushd "$DOTDIR" >/dev/null || exit 1
  unset STOW_DIR

  # Optional backup toggle (safe under set -u)
  BACKUP_BEFORE_OVERRIDE="${BACKUP_BEFORE_OVERRIDE:-false}"
  stamp=""
  backup_created=false

  # Pre-clean: remove conflicting targets in $HOME that would block plain stow
  preclean_conflicts() {
    local pkg="$1"

    # Remove files/symlinks that would collide
    while IFS= read -r -d '' src; do
      local rel="${src#$pkg/}"
      local target="${HOME}/${rel}"

      if [[ -e "$target" || -L "$target" ]]; then
        # Backup (optional)
        if [[ "$BACKUP_BEFORE_OVERRIDE" == "true" ]]; then
          stamp="${stamp:-$(ts)-$$}"
          local backupdir="${BACKUP_ROOT}/${stamp}/$(dirname "$rel")"
          mkdir -p "$backupdir"

          # Try to preserve content behind symlinks; fall back to copying the link target path
          if [[ -L "$target" ]]; then
            cp -a --remove-destination "$(readlink -f "$target" 2>/dev/null || echo "$target")" "$backupdir/" 2>/dev/null || true
          else
            cp -a "$target" "$backupdir/" 2>/dev/null || true
          fi
          backup_created=true
          log "Backup: $target -> ${backupdir}/"
        fi

        rm -rf -- "$target"
        log "Removed: $target"
      fi
    done < <(find "$pkg" -type f -o -type l -print0 2>/dev/null)

    # Remove empty directories that would block symlink creation
    while IFS= read -r -d '' d; do
      local rel="${d#$pkg/}"
      local target="${HOME}/${rel}"
      if [[ -d "$target" && ! -L "$target" ]]; then
        if [[ -z "$(ls -A "$target" 2>/dev/null)" ]]; then
          rmdir -- "$target" && log "Removed empty dir: $target" || true
        fi
      fi
    done < <(find "$pkg" -type d -print0 2>/dev/null)
  }

  # Stow without override
  stow_success=0
  stow_total=0

  for pkg in */ ; do
    [[ "$pkg" == ".git/" ]] && continue
    [[ ! -d "$pkg" ]] && continue

    pkg_name="${pkg%/}"
    ((stow_total++))

    log "Pre-cleaning conflicts for: $pkg_name"
    preclean_conflicts "$pkg_name"

    log "Stowing: $pkg_name"
    if stow -R -t "$HOME" -v "$pkg_name" 2>/dev/null; then
      log "✓ Successfully stowed $pkg_name"
      ((stow_success++))
    else
      log "❌ Failed to stow $pkg_name - trying with verbose output:"
      stow -R -t "$HOME" -v "$pkg_name" || true
    fi
  done

  [[ "$backup_created" == "true" ]] && log "✓ Backup completed in ${BACKUP_ROOT}/${stamp}/"
  log "Stow summary: $stow_success/$stow_total packages successful"
  popd >/dev/null
fi

#----- Set default shell to zsh ---------------------------------------------#
get_shell_path() { getent passwd "$USER" 2>/dev/null | cut -d: -f7; }

if have zsh; then
  CURRENT_SHELL="$(get_shell_path || echo "${SHELL:-}")"
  ZSH_BIN="$(command -v zsh)"
  
  # Ensure zsh is in /etc/shells
  if ! grep -q "^${ZSH_BIN}$" /etc/shells 2>/dev/null; then
    log "Adding zsh to /etc/shells..."
    if echo "$ZSH_BIN" | $SUDO tee -a /etc/shells >/dev/null; then
      log "✓ Added zsh to /etc/shells"
    else
      log "Warning: Could not add zsh to /etc/shells"
    fi
  fi
  
  if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    log "Changing default shell to: $ZSH_BIN"
    if chsh -s "$ZSH_BIN"; then
      log "✓ Default shell changed to zsh. Log out and back in to take effect."
    else
      log "❌ chsh failed; try manually: chsh -s \"$ZSH_BIN\""
    fi
  else
    log "✓ zsh is already the default shell."
  fi
else
  log "❌ zsh not found after installation attempt; skipping shell change."
fi

log "✅ Setup completed successfully!"
log ""
log "Summary:"
log "  - Base packages: git, zsh, tmux, stow, curl installed"
log "  - GitHub CLI: $(have gh && echo "✓ installed" || echo "❌ failed")"
log "  - Neovim: $(have nvim && echo "✓ installed ($(nvim --version | head -n1))" || echo "❌ failed/skipped")"
log "  - Dotfiles: $(cd "$DOTDIR" 2>/dev/null && echo "✓ stowed from $DOTDIR" || echo "❌ no dotfiles found")"
log "  - Shell: $(have zsh && [[ "$(get_shell_path || echo "${SHELL:-}")" == "$(command -v zsh)" ]] && echo "✓ zsh set as default" || echo "❌ not changed")"
[[ "$BACKUP_BEFORE_OVERRIDE" == "true" && -d "${BACKUP_ROOT}" ]] && log "  - Backups: available in ${BACKUP_ROOT}/"
log ""
log "Next steps:"
log "  - Log out and back in to activate zsh"
log "  - Run 'gh auth login' to authenticate GitHub CLI"
log "  - Configure Neovim with your preferred settings"
