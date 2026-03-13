#!/bin/bash

# Claude Code Stop Notification Hook
# Plays a sound / shows a banner when Claude finishes responding.
# Uses debounce to ignore intermediate stops between tool calls.
# Skips notification if the terminal is already focused.

CONFIG_FILE="$HOME/.claude/hooks/notify.conf"
PID_FILE="/tmp/claude-notify-debounce.pid"

# Defaults
MODE="sound"
SOUND="Ping"
DEBOUNCE=3
ONLY_WHEN_UNFOCUSED=true

# Load user config
if [ -f "$CONFIG_FILE" ]; then
  source "$CONFIG_FILE"
fi

# Prevent infinite loops
input=$(cat)
if echo "$input" | grep -q '"stop_hook_active":true'; then
  exit 0
fi

# Kill any previous pending notification (debounce)
if [ -f "$PID_FILE" ]; then
  old_pid=$(cat "$PID_FILE" 2>/dev/null)
  if [ -n "$old_pid" ]; then
    kill "$old_pid" 2>/dev/null
  fi
fi

# Schedule notification in background after debounce delay
(
  echo $$ > "$PID_FILE"
  sleep "$DEBOUNCE"

  # Skip if terminal is focused
  if [ "$ONLY_WHEN_UNFOCUSED" = true ]; then
    frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null)
    case "$frontmost" in
      Terminal|iTerm2|iTerm|Alacritty|kitty|WezTerm|Hyper|Warp|Ghostty)
        rm -f "$PID_FILE"
        exit 0
        ;;
    esac
  fi

  case "$MODE" in
    sound)
      afplay "/System/Library/Sounds/${SOUND}.aiff"
      ;;
    banner)
      osascript -e 'display notification "Claude finished responding" with title "Claude Code"'
      ;;
    both)
      osascript -e "display notification \"Claude finished responding\" with title \"Claude Code\" sound name \"${SOUND}\""
      ;;
  esac

  rm -f "$PID_FILE"
) &
disown

exit 0
