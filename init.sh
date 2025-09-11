#!/usr/bin/env bash
# Universal setup script:
# - updates system & installs base tools (git, gh/github-cli, zsh, tmux, stow, curl)
# - installs Neovim from tarball (Linux x86_64)
# - preflights and stows dotfiles packages safely (auto-backup conflicts)
# - sets Zsh as the default shell

set -u

#----- Config ----------------------------------------------------------------#
NEOVIM_URL="https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.tar.gz"
NEOVIM_DEST_DIR="/usr/local/nvim"
NEOVIM_BIN_SYMLINK="/usr/local/bin/nvim"
BACKUP_ROOT="${HOME}/.dotfiles_backup"

#----- Helpers ---------------------------------------------------------------#
is_root() { [ "${EUID:-$(id -u)}" -eq 0 ]; }
have()    { command -v "$1" >/dev/null 2>&1; }
ts()      { date +"%Y%m%d-%H%M%S"; }

SUDO=""
if ! is_root; then
  if have sudo; then
    SUDO="sudo"
  else
    echo "This script needs root privileges for package installs. Install 'sudo' or run as root."
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
    echo "Homebrew not found; installing..."
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
  echo "Unsupported or undetected distribution. Please install manually: git, gh/github-cli, zsh, tmux, stow, curl."
  exit 1
fi
echo "Detected OS: ${OS}  | Using package manager: ${PM}"

#----- Update & Install base packages ---------------------------------------#
UCMD="$(update_cmd "$PM")"
if [[ -n "$UCMD" ]]; then
  echo "Updating system..."
  bash -c "$UCMD"
fi

ICMD="$(install_cmd_many "$PM" "${BASE_PKGS[@]}")"
if [[ -n "$ICMD" ]]; then
  echo "Installing base packages: ${BASE_PKGS[*]}"
  bash -c "$ICMD" || true
fi

# Ensure downloader
if ! have curl && ! have wget; then
  echo "curl/wget not found after install attempt; trying to install curl..."
  GCMD="$(install_cmd_one "$PM" "curl")"
  [[ -n "$GCMD" ]] && bash -c "$GCMD" || true
fi

# Install GitHub CLI with fallbacks
for ghpkg in "${GH_CANDIDATES[@]}"; do
  echo "Attempting to install GitHub CLI package: $ghpkg"
  GCMD="$(install_cmd_one "$PM" "$ghpkg")"
  if [[ -n "$GCMD" ]]; then
    if bash -c "$GCMD"; then
      break
    else
      echo "Package '$ghpkg' not available via $PM. Trying next candidate..."
    fi
  fi
done

#----- Neovim: install from tarball (Linux x86_64 only) ---------------------#
install_neovim_tarball() {
  local url="$1"
  local tmpdir; tmpdir="$(mktemp -d)"
  echo "Installing Neovim from tarball: $url"

  local tarball="$tmpdir/nvim.tar.gz"
  if have curl; then
    curl -L --fail -o "$tarball" "$url"
  elif have wget; then
    wget -O "$tarball" "$url"
  else
    echo "Neither curl nor wget is available. Cannot download Neovim."
    rm -rf "$tmpdir"; return 1
  fi

  echo "Extracting..."
  tar -C "$tmpdir" -xzf "$tarball"

  local topdir; topdir="$(tar tzf "$tarball" | head -1 | cut -d/ -f1)"
  if [[ -z "$topdir" || ! -d "$tmpdir/$topdir" ]]; then
    echo "Failed to detect extracted directory."
    rm -rf "$tmpdir"; return 1
  fi

  echo "Installing to $NEOVIM_DEST_DIR"
  $SUDO rm -rf "$NEOVIM_DEST_DIR"
  $SUDO mkdir -p "$(dirname "$NEOVIM_DEST_DIR")"
  $SUDO mv "$tmpdir/$topdir" "$NEOVIM_DEST_DIR"

  $SUDO ln -sf "$NEOVIM_DEST_DIR/bin/nvim" "$NEOVIM_BIN_SYMLINK"

  if "$NEOVIM_BIN_SYMLINK" --version | head -n1 | grep -q "v0.11.4"; then
    echo "Neovim v0.11.4 installed successfully at $NEOVIM_BIN_SYMLINK"
  else
    echo "Neovim installed, but version check did not match v0.11.4."
  fi

  rm -rf "$tmpdir"
}
if [[ "$(uname -s)" == "Linux" && "$(uname -m)" == "x86_64" ]]; then
  install_neovim_tarball "$NEOVIM_URL" || echo "Neovim tarball install failed."
else
  echo "Skipping Neovim tarball (requires Linux x86_64)."
  [[ "$OS" == "darwin" ]] && echo "On macOS, you can: brew install neovim"
fi

#----- Stow preflight: backup conflicts -------------------------------------#
# We assume repository layout like:
# dotfiles/
#   zsh/.zshrc, .oh-my-zsh/...
#   tmux/.config/...
#   neovim/.config/...
#
# For every package directory under $DOTDIR/*, we compute the would-be targets in $HOME.
shopt -s nullglob dotglob
realpath_f() {
  # portable-ish realpath fallback
  if have realpath; then realpath "$1"; else
    printf '%s\n' "$(cd "$(dirname "$1")" 2>/dev/null && pwd -P)/$(basename "$1")"
  fi
}
preflight_backup_pkg() {
  local pkgdir="$1" rel src target backupdir stamp
  stamp="$(ts)"
  while IFS= read -r -d '' src; do
    # Skip if directory and empty; still consider as potential conflict
    rel="${src#$pkgdir/}"
    target="${HOME}/${rel}"

    # If target doesn't exist, no conflict.
    [[ -e "$target" || -L "$target" ]] || continue

    # If target is a symlink already (assume it's fine and points to our repo or user knows), skip.
    if [[ -L "$target" ]]; then
      continue
    fi

    # If target is a regular file/dir, back it up.
    backupdir="${BACKUP_ROOT}/${stamp}/$(dirname "$rel")"
    mkdir -p "$backupdir"
    echo "Backing up existing: $target -> ${backupdir}/$(basename "$rel")"
    mv "$target" "${backupdir}/" || {
      echo "Failed to move $target to backup. Check permissions."; continue;
    }
  done < <(find "$pkgdir" -mindepth 1 \( -type f -o -type d \) -print0)
}

DOTDIR=""
if [[ -d "./dotfiles" ]]; then
  DOTDIR="./dotfiles"
elif [[ -d "$HOME/dotfiles" ]]; then
  DOTDIR="$HOME/dotfiles"
else
  DOTDIR="$(pwd)"
fi

if [[ ! -d "$DOTDIR" ]]; then
  echo "No dotfiles directory found; skipping stow."
else
  echo "Preparing to stow from: $DOTDIR"
  pushd "$DOTDIR" >/dev/null || exit 1

  for pkg in */ ; do
    # Skip git metadata and non-package dirs
    [[ "$pkg" == ".git/" ]] && continue
    [[ ! -d "$pkg" ]] && continue

    # Preflight: backup conflicts for this package
    echo "Preflighting package: ${pkg%/}"
    preflight_backup_pkg "$pkg"

    # Stow with explicit target = $HOME
    echo "Stowing: ${pkg%/}"
    stow -t "$HOME" -R "$pkg"
  done

  popd >/dev/null
fi

#----- Set default shell to zsh ---------------------------------------------#
get_shell_path() { getent passwd "$USER" 2>/dev/null | cut -d: -f7; }
if have zsh; then
  CURRENT_SHELL="$(get_shell_path || true)"
  [[ -z "$CURRENT_SHELL" ]] && CURRENT_SHELL="${SHELL:-}"
  ZSH_BIN="$(command -v zsh)"
  if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
    echo "Changing default shell to: $ZSH_BIN"
    if chsh -s "$ZSH_BIN"; then
      echo "Default shell changed to zsh. Log out and back in to take effect."
    else
      echo "chsh failed; try: chsh -s \"$ZSH_BIN\""
    fi
  else
    echo "zsh is already the default shell."
  fi
else
  echo "zsh not found after installation attempt; skipping shell change."
fi

echo "✅ All done."
