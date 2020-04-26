#!/bin/sh
#
# Intelligently navigate tmux panes and Vim splits using the same keys.
# This also supports SSH tunnels where Vim is running on a remote host.
#
#      +-------------+------------+-----------------------------+
#      | inside Vim? | is Zoomed? | Action taken by key binding |
#      +-------------+------------+-----------------------------+
#      | No          | No         | Focus directional tmux pane |
#      | No          | Yes        | Nothing: ignore key binding |
#      | Yes         | No         | Seamlessly focus Vim / tmux |
#      | Yes         | Yes        | Focus directional Vim split |
#      +-------------+------------+-----------------------------+
#
# See https://sunaku.github.io/tmux-select-pane.html for documentation.

get_tmux_option() { tmux show-option -gqv "$@" | grep . ;}

timeout=$(get_tmux_option '@navigate-timeout') || timeout=0.05 # seconds
navigate="                                                             \
  vim_navigation_timeout=$timeout;                                     \
"'                                                                     \
  pane_title="#{q:pane_title}";                                        \
  pane_current_command="#{q:pane_current_command}";                    \
  pane_is_zoomed() {                                                   \
    test #{window_zoomed_flag} -eq 1;                                  \
  };                                                                   \
  pane_title_changed() {                                               \
    test "$pane_title" != "$(tmux display -p "##{q:pane_title}")";     \
  };                                                                   \
  command_is_vim() {                                                   \
    case "${1%% *}" in                                                 \
      (vi|?vi|vim*|?vim*|view|?view|vi??*) true ;;                     \
      (*) false ;;                                                     \
    esac;                                                              \
  };                                                                   \
  pane_contains_vim() {                                                \
    case "$pane_current_command" in                                    \
      (git|*sh) command_is_vim "$pane_title" ;;                        \
      (*) command_is_vim "$pane_current_command" ;;                    \
    esac;                                                              \
  };                                                                   \
  pane_contains_neovim_terminal() {                                    \
    case "$pane_title" in                                              \
      (nvim?term://*) true ;;                                          \
      (*) false ;;                                                     \
    esac;                                                              \
  };                                                                   \
  navigate() {                                                         \
    tmux_navigation_command=$1;                                        \
    vim_navigation_command=$2;                                         \
    vim_navigation_only_if=${3:-true};                                 \
    if pane_contains_vim && eval "$vim_navigation_only_if"; then       \
      if pane_contains_neovim_terminal; then                           \
        tmux send-keys C-\\ C-n;                                       \
      fi;                                                              \
      eval "$vim_navigation_command";                                  \
      if ! pane_is_zoomed; then                                        \
        sleep $vim_navigation_timeout; : wait for Vim to change title; \
        if ! pane_title_changed; then                                  \
          tmux send-keys BSpace;                                       \
          eval "$tmux_navigation_command";                             \
        fi;                                                            \
      fi;                                                              \
    elif ! pane_is_zoomed; then                                        \
      eval "$tmux_navigation_command";                                 \
    fi;                                                                \
  };                                                                   \
navigate '
navigate_left=" $navigate 'tmux select-pane -L'  'tmux send-keys C-w h'"
navigate_down=" $navigate 'tmux select-pane -D'  'tmux send-keys C-w j'"
navigate_up="   $navigate 'tmux select-pane -U'  'tmux send-keys C-w k'"
navigate_right="$navigate 'tmux select-pane -R'  'tmux send-keys C-w l'"
navigate_back=" $navigate 'tmux select-pane -l || tmux select-pane -t1'\
                          'tmux send-keys C-w p'                       \
                          'pane_is_zoomed'                             "

for direction in left down up right back; do
  option="@navigate-$direction"
  handler="navigate_$direction"
  if key=$(get_tmux_option "$option"); then
    eval "action=\$$handler" # resolve handler variable
    tmux bind-key $key run-shell -b ": $option; $action"
  fi
done
