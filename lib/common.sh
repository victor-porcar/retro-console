# Paths, settings and helpers shared by every retro-console command

RC_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/retro-console"
RC_CONFIG="$RC_HOME/config"
RC_TMUX_CONF="$RC_HOME/tmux.conf"
RC_BIN="$HOME/.local/bin/retro-console"
# Own tmux server and session, so the user's tmux and its config are never touched
RC_SOCKET=retro-console
RC_SESSION=console
RC_PROFILE="Retro Console"
RC_LAUNCHER_PREFIX=retro-console-

declare -A CONFIG=([title]=Consoles [theme]=green [font]="DejaVu Sans Mono 8" [size]=110x20)

fail() {
  echo "retro-console: $*" >&2
  exit 1
}

ok() {
  echo "  ✔ $*"
}

trim() {
  local text="$1"
  text="${text#"${text%%[![:space:]]*}"}"
  echo "${text%"${text##*[![:space:]]}"}"
}

# key = value lines; anything after # is a comment
load_config() {
  [[ -f "$RC_CONFIG" ]] || return 0
  local key value
  while IFS='=' read -r key value; do
    key="$(trim "$key")"
    [[ -z "$key" || "$key" == \#* ]] && continue
    CONFIG[$key]="$(trim "${value%%#*}")"
  done <"$RC_CONFIG"
}

rc_tmux() {
  tmux -L "$RC_SOCKET" -f "$RC_TMUX_CONF" "$@"
}
