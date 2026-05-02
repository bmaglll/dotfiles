#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell-keep-awake.state"
DEFAULT_DURATION=3600

cleanup_state() {
  rm -f "$STATE_FILE"
}

read_state() {
  if [[ ! -f "$STATE_FILE" ]]; then
    return 1
  fi

  # shellcheck disable=SC1090
  source "$STATE_FILE"

  if [[ -z "${pid:-}" || -z "${expires_at:-}" ]]; then
    cleanup_state
    return 1
  fi

  if ! kill -0 "$pid" 2>/dev/null; then
    cleanup_state
    return 1
  fi

  return 0
}

cmd_start() {
  local duration="${1:-$DEFAULT_DURATION}"
  local expires_at

  if read_state; then
    cmd_stop >/dev/null
  fi

  expires_at=$(( $(date +%s) + duration ))

  (
    child_pid=""

    cleanup() {
      if [[ -n "$child_pid" ]]; then
        kill "$child_pid" 2>/dev/null || true
        wait "$child_pid" 2>/dev/null || true
      fi
      cleanup_state
    }

    trap cleanup INT TERM EXIT

    printf 'pid=%s\nexpires_at=%s\nduration=%s\n' "$$" "$expires_at" "$duration" > "$STATE_FILE"

    systemd-inhibit \
      --what=idle \
      --who="quickshell" \
      --why="Keep the screen awake temporarily" \
      sleep "$duration" &
    child_pid=$!

    wait "$child_pid"
  ) >/dev/null 2>&1 &

  disown || true
  echo started
}

cmd_stop() {
  if ! read_state; then
    echo inactive
    return 0
  fi

  kill "$pid" 2>/dev/null || true
  cleanup_state
  echo stopped
}

cmd_status() {
  local now remaining

  if ! read_state; then
    echo "active:0 remaining:0"
    return 0
  fi

  now=$(date +%s)
  remaining=$(( expires_at - now ))
  if (( remaining < 0 )); then
    remaining=0
  fi

  echo "active:1 remaining:${remaining}"
}

case "${1:-status}" in
  start)
    cmd_start "${2:-$DEFAULT_DURATION}"
    ;;
  stop)
    cmd_stop
    ;;
  status)
    cmd_status
    ;;
  *)
    echo "usage: $0 {start|stop|status} [seconds]" >&2
    exit 1
    ;;
esac
