# Applies the config: a GNOME Terminal profile and a tmux config in the theme colors.
#
# GNOME Terminal keeps profiles in dconf:
#   .../profiles:/list     -> ['uuid1', 'uuid2', ...]   only listed profiles exist
#   .../profiles:/default  -> 'uuid1'
#   .../profiles:/:<uuid>/ -> settings of each profile
# A fresh Ubuntu has no list, just a built-in profile, so it is kept in the list too.

PROFILES=/org/gnome/terminal/legacy/profiles:
BUILTIN_PROFILE=b1dcc9dd-5262-4d8d-a863-c897e6d979b9

# "foreground dim" colors of each theme
theme_colors() {
  case "$1" in
    green) echo "#33FF33 #1A801A" ;;
    amber) echo "#FFB000 #805800" ;;
    white) echo "#E0E0E0 #707070" ;;
    *) fail "unknown theme '$1' (use green, amber or white)" ;;
  esac
}

profile_uuids() {
  dconf read "$PROFILES/list" | tr -d "[]'," | tr ' ' '\n' | grep -v '^$'
}

find_profile() {
  local uuid
  for uuid in $(profile_uuids); do
    [[ "$(dconf read "$PROFILES/:$uuid/visible-name")" == "'$RC_PROFILE'" ]] && { echo "$uuid"; return 0; }
  done
  return 1
}

add_profile() {
  local uuid uuids
  uuid="$(uuidgen)"
  uuids="$(profile_uuids)"
  [[ -n "$uuids" ]] || uuids="$BUILTIN_PROFILE"
  dconf write "$PROFILES/list" "[$(printf "'%s', " $uuids)'$uuid']"
  [[ -n "$(dconf read "$PROFILES/default")" ]] || dconf write "$PROFILES/default" "'${uuids%%$'\n'*}'"
  echo "$uuid"
}

# Every palette entry uses the theme color so colored output keeps the retro look
write_profile() {
  local fg="$1" dim="$2" uuid key
  uuid="$(find_profile)" || uuid="$(add_profile)"
  key="$PROFILES/:$uuid"
  dconf load "$key/" <<EOF
[/]
visible-name='$RC_PROFILE'
use-theme-colors=false
foreground-color='$fg'
background-color='#000000'
bold-color-same-as-fg=true
palette=['#000000', '$fg', '$fg', '$fg', '$fg', '$fg', '$fg', '$fg', '$dim', '$fg', '$fg', '$fg', '$fg', '$fg', '$fg', '$fg']
use-system-font=false
font='${CONFIG[font]}'
cursor-shape='block'
cursor-colors-set=true
cursor-background-color='$fg'
cursor-foreground-color='#000000'
scrollbar-policy='never'
default-size-columns=${CONFIG[size]%x*}
default-size-rows=${CONFIG[size]#*x}
EOF
}

write_tmux_conf() {
  local fg="$1"
  mkdir -p "$RC_HOME"
  sed "s/@FG@/$fg/g" "$RC_LIB/tmux.conf.template" >"$RC_TMUX_CONF"
}

setup() {
  local fg dim
  read -r fg dim <<<"$(theme_colors "${CONFIG[theme]}")"
  write_profile "$fg" "$dim"
  write_tmux_conf "$fg"
  ok "theme '${CONFIG[theme]}' applied (terminal profile '$RC_PROFILE')"
}
