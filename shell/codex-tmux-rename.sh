#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)
SESSION_ID=$(printf '%s' "$INPUT" | jq -r '.session_id // empty')
SHORT_ID=${SESSION_ID: -6}

[ -n "$SHORT_ID" ] || exit 0

tmux rename-window "codex[$SHORT_ID]"
