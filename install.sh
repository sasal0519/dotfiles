#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_SRC="$REPO_DIR/config"
BACKUP_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
MODE="link"
INSTALL_PACKAGES="no"
ORIGINAL_HOME="/home/salomaof"

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

Options:
  --copy              Copy files instead of creating symlinks.
  --install-packages  Install packages from packages/pacman-explicit.txt with pacman.
  -h, --help          Show this help.

By default the script backs up existing config paths and symlinks this repo into ~/.config.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --copy)
      MODE="copy"
      ;;
    --install-packages)
      INSTALL_PACKAGES="yes"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

target_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$target_config_dir"

configs=(
  DankMaterialShell
  alacritty
  cava
  fastfetch
  gtk-3.0
  gtk-4.0
  kitty
  micro
  nvim
  shelly
  spicetify
)

backup_path() {
  local path="$1"
  local name
  name="$(basename "$path")"

  mkdir -p "$BACKUP_DIR"
  mv "$path" "$BACKUP_DIR/$name"
  echo "Backed up $path -> $BACKUP_DIR/$name"
}

install_config() {
  local name="$1"
  local src="$CONFIG_SRC/$name"
  local dest="$target_config_dir/$name"

  [[ -e "$src" ]] || return 0

  if [[ -L "$dest" ]]; then
    rm "$dest"
  elif [[ -e "$dest" ]]; then
    backup_path "$dest"
  fi

  if [[ "$MODE" == "copy" ]]; then
    cp -a "$src" "$dest"
    echo "Copied $name"
  else
    ln -s "$src" "$dest"
    echo "Linked $name"
  fi
}

for config in "${configs[@]}"; do
  install_config "$config"
done

dms_settings="$target_config_dir/DankMaterialShell/settings.json"
if [[ -f "$dms_settings" ]]; then
  sed -i "s#${ORIGINAL_HOME}#${HOME}#g" "$dms_settings"
fi

if [[ "$INSTALL_PACKAGES" == "yes" ]]; then
  if command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --needed - < "$REPO_DIR/packages/pacman-explicit.txt"
  else
    echo "pacman not found; skipping package install" >&2
  fi
fi

echo
echo "Done. Restart the shell/session apps that read these configs."
