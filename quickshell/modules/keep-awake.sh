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

# Shell snippet the inhibitor's inner process runs when a timed session
# expires naturally. Kept as a string so it can be embedded in the detached
# `bash -c` payload. On a manual stop we SIGTERM the whole group before the
# sleep finishes, so this only ever runs on genuine expiry.
LOCK_SNIPPET='loginctl lock-session >/dev/null 2>&1 || { pidof hyprlock >/dev/null 2>&1 || hyprlock >/dev/null 2>&1; }'

# SIGTERM an entire process group (leader pid == pgid for our setsid'd
# inhibitors), then belt-and-braces the pid itself. Killing the group takes
# down systemd-inhibit AND its child bash/sleep, releasing the lock at once.
kill_group() {
  local target="$1"
  [[ -n "$target" ]] || return 0
  kill -TERM -"$target" 2>/dev/null || true
  kill -TERM "$target" 2>/dev/null || true
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

  local inner
  if [[ "$mode" == "indefinite" ]]; then
    # Hold the lock until explicitly stopped; no auto-lock on the way out.
    inner='while :; do sleep 3600; done'
  else
    # Hold for exactly `duration`, then auto-lock. A manual stop kills the
    # whole group before this sleep returns, so the lock is skipped.
    inner="sleep $duration; $LOCK_SNIPPET"
  fi

  # setsid puts systemd-inhibit in a fresh session (leader pid == pgid), so
  # cmd_stop can tear the entire tree down with a single group SIGTERM. The
  # tracked pid is systemd-inhibit itself, whose death releases the lock.
  setsid systemd-inhibit \
    --what=idle:sleep:handle-lid-switch \
    --who="quickshell" \
    --why="Keep the screen awake temporarily" \
    bash -c "$inner" >/dev/null 2>&1 &
  pid=$!

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

  kill_group "$pid"
  cleanup_state
  notify "Keep awake disabled" "Screen sleep and auto-lock restored."
  echo stopped
}

# Reap any orphaned quickshell inhibitors (e.g. left by a previous session or
# the old detached-sleep implementation) so a fresh shell never inherits a
# stuck lid lock. Best-effort: find the systemd-inhibit holder processes and
# kill each one's process group.
cmd_cleanup() {
  local pids p pg

  # Ask logind which processes actually hold an inhibitor and keep the ones
  # registered as who=quickshell. Columns: WHO UID USER PID COMM WHAT WHY MODE.
  # This is authoritative (real lock holders only) and never false-matches an
  # editor or shell that merely mentions our why string.
  pids=$(systemd-inhibit --list --no-pager 2>/dev/null \
    | awk '$1 == "quickshell" && $4 ~ /^[0-9]+$/ { print $4 }' || true)

  for p in $pids; do
    # Prefer killing the whole group; fall back to the process (and its
    # immediate children) for legacy orphans that share an old group.
    pg=$(ps -o pgid= -p "$p" 2>/dev/null | tr -d ' ')
    if [[ -n "$pg" ]]; then
      kill -TERM -"$pg" 2>/dev/null || true
    fi
    pkill -TERM -P "$p" 2>/dev/null || true
    kill -TERM "$p" 2>/dev/null || true
  done

  cleanup_state
  echo cleaned
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
  cleanup)
    cmd_cleanup
    ;;
  status)
    cmd_status
    ;;
  *)
    echo "usage: $0 {start|stop|cleanup|status} [seconds]" >&2
    exit 1
    ;;
esac
