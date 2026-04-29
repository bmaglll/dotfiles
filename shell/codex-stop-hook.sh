#!/usr/bin/env bash
set -euo pipefail

INPUT=$(cat)

printf '%s' "$INPUT" | bash /home/bmag/nixos-config/shell/codex-notify-stop.sh
printf '%s' "$INPUT" | bash /home/bmag/nixos-config/shell/codex-agent-buddy-hook.sh stop
