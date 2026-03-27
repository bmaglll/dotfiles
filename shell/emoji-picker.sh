#!/usr/bin/env bash
selected=$(cat ~/nixos-config/shell/emoji-data.txt | fzf --prompt="emoji> " --layout=reverse --no-info)
[ -n "$selected" ] && echo "$selected" | cut -d' ' -f1 | tr -d '\n' | wl-copy
