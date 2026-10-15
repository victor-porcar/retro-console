# Desktop launchers. Each one stores its tab and command in its own .desktop file
# (X-RetroConsole-* keys) and runs `retro-console launch <file>`, so commands never
# need escaping in the Exec line.

desktop_dir() {
  xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop"
}

launcher_file() {
  local slug
  slug="$(tr '[:upper:]' '[:lower:]' <<<"$1" | tr -cs 'a-z0-9' '-' | sed 's/^-//; s/-$//')"
  echo "$(desktop_dir)/$RC_LAUNCHER_PREFIX$slug.desktop"
}

launcher_key() {
  sed -n "s/^$2=//p" "$1" | head -n1
}

parse_add_options() {
  local -n options="$1"
  shift
  while [[ $# -gt 0 ]]; do
    [[ $# -ge 2 ]] || fail "option '$1' needs a value"
    case "$1" in
      --run | --tab | --icon) options[${1#--}]="$2" ;;
      *) fail "unknown option '$1'" ;;
    esac
    shift 2
  done
}

# usage: add <name> --run <command> [--tab <tab>] [--icon <icon>]
add() {
  local name="${1:-}"
  shift || true
  local -A opts=([icon]=utilities-terminal)
  parse_add_options opts "$@"
  [[ -n "$name" && -n "${opts[run]:-}" ]] || fail "usage: retro-console add <name> --run <command> [--tab <tab>] [--icon <icon>]"
  opts[icon]="$(icon_value "${opts[icon]}")" || exit 1
  write_launcher "$name" "${opts[run]}" "${opts[tab]:-$name}" "${opts[icon]}"
}

# An image path must be absolute in a .desktop file; icon theme names pass through
icon_value() {
  local icon="$1"
  [[ "$icon" == "~/"* ]] && icon="$HOME/${icon#"~/"}"
  if [[ "$icon" == */* ]]; then
    [[ -f "$icon" ]] || fail "icon image not found: $1"
    icon="$(readlink -f "$icon")"
  fi
  echo "$icon"
}

write_launcher() {
  local file
  file="$(launcher_file "$1")"
  mkdir -p "$(dirname "$file")"
  printf '%s\n' "[Desktop Entry]" "Type=Application" "Name=$1" "Comment=$2 (tab: $3)" \
    "Exec=\"$RC_BIN\" launch \"$file\"" "Icon=$4" "Terminal=false" \
    "X-RetroConsole-Tab=$3" "X-RetroConsole-Run=$2" >"$file"
  chmod +x "$file"
  gio set "$file" metadata::trusted true 2>/dev/null
  ok "launcher '$1' -> tab '$3': $2"
}

launch() {
  [[ -f "${1:-}" ]] || fail "launcher not found: ${1:-}"
  run "$(launcher_key "$1" X-RetroConsole-Tab)" "$(launcher_key "$1" X-RetroConsole-Run)"
}

list() {
  local file
  for file in "$(desktop_dir)/$RC_LAUNCHER_PREFIX"*.desktop; do
    [[ -e "$file" ]] || continue
    printf '  %-20s tab: %-15s %s\n' "$(launcher_key "$file" Name)" \
      "$(launcher_key "$file" X-RetroConsole-Tab)" "$(launcher_key "$file" X-RetroConsole-Run)"
  done
}

remove() {
  local file
  file="$(launcher_file "${1:-}")"
  [[ -f "$file" ]] || fail "no launcher named '${1:-}' (see: retro-console list)"
  rm "$file"
  ok "launcher '$1' removed"
}
