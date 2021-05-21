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

navigate=$(sed '1,/^exit #.*$/d; s/^ *#.*//; /^$/d' "$0")
navigate_left=" $navigate L 'tmux select-pane -L'  'tmux send-keys C-w h'"
navigate_down=" $navigate D 'tmux select-pane -D'  'tmux send-keys C-w j'"
navigate_up="   $navigate U 'tmux select-pane -U'  'tmux send-keys C-w k'"
navigate_right="$navigate R 'tmux select-pane -R'  'tmux send-keys C-w l'"
navigate_back=" $navigate l 'tmux select-pane -l || tmux select-pane -t1'\
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

exit #------------------------------------------------------------------------

# interpolate tmux values ONCE at "compile time"
# (this is the reason for the double ## escapes)
pane_title="#{q:pane_title}"
pane_current_command="#{q:pane_current_command}"
window_zoomed_flag=#{window_zoomed_flag}

pane_is_zoomed() {
  test $window_zoomed_flag -eq 1
}

command_is_vim() {
  case "${1%% *}" in
    (vi|?vi|vim*|?vim*|view|?view|vi??*)
      true
      ;;
    (*)
      false
      ;;
  esac
}

pane_contains_vim() {
  command_is_vim "$pane_current_command" ||
  command_is_vim "$pane_title"
}

pane_contains_neovim_terminal() {
  case "$pane_title" in
    (nvim?term://*)
      true
      ;;
    (*)
      false
      ;;
  esac
}

navigate() {
  tmux_navigation_direction=$1
  tmux_navigation_command=$2
  vim_navigation_command=$3
  vim_navigation_only_if=${4:-true}

  # try navigating Vim
  if pane_contains_vim && eval "$vim_navigation_only_if"; then

    # parse navigable directions from Vim's title
    vim_navigable_directions=${pane_title####* }

    # if desired direction is navigable in Vim...
    case "l$vim_navigable_directions" in (*$tmux_navigation_direction*)

      # leave insert mode in NeoVim terminal
      if pane_contains_neovim_terminal; then
        tmux send-keys C-\\ C-n
      fi

      # navigate Vim and don't fall through
      eval "$vim_navigation_command"
      return

      ;;
    esac

    # otherwise fall through into tmux navigation
  fi

  # try navigating tmux
  if ! pane_is_zoomed; then
    eval "$tmux_navigation_command"
  fi
}

navigate
