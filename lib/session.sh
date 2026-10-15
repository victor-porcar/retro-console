# Runs commands as tabs of one shared terminal window (a tmux session):
#   - first command: opens the terminal with the session and its tab
#   - a new tab name: adds a tab, no new window
#   - an existing tab name: reuses that tab; its command gets SIGHUP and the new one
#     runs there, so start/stop launchers can share one tab
#   - closing the window destroys the session: every command gets SIGHUP and stops

open_terminal() {
  gnome-terminal --profile="$RC_PROFILE" --title="${CONFIG[title]}" -- "$@"
}

# Interactive bash so aliases work; the tab stays open so the output can be read
tab_command() {
  printf 'bash -ic %q' "$*; read -rp 'Press Enter to close this tab'"
}

new_session() {
  open_terminal tmux -L "$RC_SOCKET" -f "$RC_TMUX_CONF" new-session -s "$RC_SESSION" -n "$1" "$2"
}

# Index of the tab with exactly this name, if there is one
tab_index() {
  rc_tmux list-windows -t "=$RC_SESSION" -F '#{window_index} #{window_name}' \
    | awk -v name="$1" '{ i = $1; $1 = ""; if (substr($0, 2) == name) { print i; exit } }'
}

run_in_tab() {
  local name="$1" command="$2" index
  index="$(tab_index "$name")"
  if [[ -n "$index" ]]; then
    rc_tmux respawn-window -k -t "=$RC_SESSION:$index" "$command" \; select-window -t "=$RC_SESSION:$index"
  else
    rc_tmux new-window -t "=$RC_SESSION:" -n "$name" "$command"
  fi
  if [[ "$(rc_tmux display-message -p -t "=$RC_SESSION" '#{session_attached}')" == 0 ]]; then
    open_terminal tmux -L "$RC_SOCKET" -f "$RC_TMUX_CONF" attach-session -t "=$RC_SESSION"
  fi
}

run() {
  [[ $# -ge 2 ]] || fail "usage: retro-console run <tab> <command...>"
  [[ -f "$RC_TMUX_CONF" ]] || setup >/dev/null
  local name="$1" command
  shift
  command="$(tab_command "$@")"
  if rc_tmux has-session -t "=$RC_SESSION" 2>/dev/null; then run_in_tab "$name" "$command"; else new_session "$name" "$command"; fi
}
