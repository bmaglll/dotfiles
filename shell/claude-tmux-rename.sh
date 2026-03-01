#!/usr/bin/env bash
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' | tail -c 7)
tmux rename-window "claude[$SESSION_ID]"
