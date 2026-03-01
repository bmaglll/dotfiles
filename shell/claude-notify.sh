#!/usr/bin/env bash
# Claude Code notification with click-to-open action
# Usage: claude-notify.sh "message"

MESSAGE="${1:-Needs your attention}"
ICON="/home/bmag/nixos-config/icons/claude.svg"

# Send notification with action, run in background so hook doesn't block
(
    ACTION=$(notify-send -a 'Claude Code' -i "$ICON" 'Claude Code' "$MESSAGE" \
        --action='open=Open' 2>/dev/null)

    if [ "$ACTION" = "open" ]; then
        ghostty --class=ghostty.claude -e tmux attach -t Main
    fi
) &
