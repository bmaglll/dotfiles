#!/usr/bin/env bash

set -euo pipefail

STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell-keep-awake.state"
DEFAULT_DURATION=3600

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send -a "quickshell" "$1" "$2"
  fi
}

lock_session() {
  if command -v loginctl >/dev/null 2>&1; then
    loginctl lock-session >/dev/null 2>&1 && return 0
  fi

  if command -v hyprlock >/dev/null 2>&1; then
    pidof hyprlock >/dev/null 2>&1 || hyprlock >/dev/null 2>&1
  fi
}

format_duration() {
  local duration="$1"

  if (( duration < 60 )); then
    printf '%s seconds' "$duration"
  elif (( duration % 3600 == 0 )); then
    printf '%s hour%s' "$(( duration / 3600 ))" "$([[ $(( duration / 3600 )) -eq 1 ]] && echo '' || echo 's')"
  elif (( duration % 60 == 0 )); then
    printf '%s minutes' "$(( duration / 60 ))"
  else
    printf '%s seconds' "$duration"
  fi
}

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
  local pid
  local mode="timed"
  local label

  if read_state; then
    cmd_stop >/dev/null
  fi

  if [[ "$duration" == "indefinite" ]]; then
    mode="indefinite"
    expires_at=0
    label="until turned off"
  else
    expires_at=$(( $(date +%s) + duration ))
    label="$(format_duration "$duration")"
  fi

  if [[ "$mode" == "indefinite" ]]; then
    systemd-inhibit \
      --what=idle:sleep:handle-lid-switch \
      --who="quickshell" \
      --why="Keep the screen awake temporarily" \
      bash -lc 'while :; do sleep 3600; done' >/dev/null 2>&1 &
    pid=$!
  else
    (
      trap 'cleanup_state' EXIT
      systemd-inhibit \
        --what=idle:sleep:handle-lid-switch \
        --who="quickshell" \
        --why="Keep the screen awake temporarily" \
        bash -lc "sleep $duration; loginctl lock-session >/dev/null 2>&1 || { pidof hyprlock >/dev/null 2>&1 || hyprlock >/dev/null 2>&1; }"
    ) >/dev/null 2>&1 &
    pid=$!
  fi

  sleep 0.2

  if ! kill -0 "$pid" 2>/dev/null; then
    cleanup_state
    notify "Keep awake failed" "systemd-inhibit could not start."
    echo failed
    return 1
  fi

  printf 'pid=%s\nexpires_at=%s\nduration=%s\nmode=%s\n' "$pid" "$expires_at" "$duration" "$mode" > "$STATE_FILE"
  disown "$pid" || true
  if [[ "$mode" == "indefinite" ]]; then
    notify "Auto-lock disabled" "Screen sleep and auto-lock are paused until you turn them back on."
  else
    notify "Keep awake enabled" "Screen sleep and auto-lock paused for ${label}."
  fi
  echo started
}

cmd_stop() {
  if ! read_state; then
    notify "Keep awake already off" "No active keep-awake timer was running."
    echo inactive
    return 0
  fi

  kill "$pid" 2>/dev/null || true
  cleanup_state
  notify "Keep awake disabled" "Screen sleep and auto-lock restored."
  echo stopped
}

cmd_status() {
  local now remaining

  if ! read_state; then
    echo "active:0 remaining:0 mode:off"
    return 0
  fi

  if [[ "${mode:-timed}" == "indefinite" ]]; then
    echo "active:1 remaining:0 mode:indefinite"
    return 0
  fi

  now=$(date +%s)
  remaining=$(( expires_at - now ))
  if (( remaining < 0 )); then
    remaining=0
  fi

  echo "active:1 remaining:${remaining} mode:timed"
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
