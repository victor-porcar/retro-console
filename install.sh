#!/usr/bin/env bash
# Installs retro-console for the current user: links the command into ~/.local/bin,
# creates a default config and applies it. Safe to run again (e.g. after git pull).
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/retro-console"

check_dependencies() {
  local missing=() tool
  for tool in tmux gnome-terminal dconf gio uuidgen; do
    command -v "$tool" >/dev/null || missing+=("$tool")
  done
  [[ ${#missing[@]} -eq 0 ]] && return
  echo "Missing: ${missing[*]}. On Ubuntu: sudo apt install tmux gnome-terminal dconf-cli" >&2
  exit 1
}

write_default_config() {
  [[ -f "$CONFIG_DIR/config" ]] && return
  mkdir -p "$CONFIG_DIR"
  cat >"$CONFIG_DIR/config" <<EOF
# retro-console settings. Apply changes with: retro-console setup
title = Consoles             # window title
theme = green                # green | amber | white
font  = DejaVu Sans Mono 8
size  = 110x20               # columns x rows
EOF
}

check_dependencies
mkdir -p "$HOME/.local/bin"
ln -sfn "$REPO_DIR/bin/retro-console" "$HOME/.local/bin/retro-console"
echo "  ✔ ~/.local/bin/retro-console -> $REPO_DIR/bin/retro-console"
write_default_config
"$HOME/.local/bin/retro-console" setup
echo "Done. Try: retro-console add \"Top\" --run htop --icon utilities-system-monitor"
