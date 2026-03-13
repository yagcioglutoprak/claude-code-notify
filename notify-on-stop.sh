#!/bin/bash

# Claude Code Stop Notification Hook
# Plays a sound / shows a banner when Claude finishes responding.
# Uses debounce to ignore intermediate stops between tool calls.
# Skips notification if the terminal is already focused.
# Uses terminal-notifier for rich banners with Claude icon if available.

CONFIG_FILE="$HOME/.claude/hooks/notify.conf"
PID_FILE="/tmp/claude-notify-debounce.pid"
START_FILE="/tmp/claude-notify-start.txt"

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

# Track response start time for elapsed calculation
if [ ! -f "$START_FILE" ]; then
  date +%s > "$START_FILE"
fi

# Kill any previous pending notification (debounce)
if [ -f "$PID_FILE" ]; then
  old_pid=$(cat "$PID_FILE" 2>/dev/null)
  if [ -n "$old_pid" ]; then
    kill "$old_pid" 2>/dev/null
  fi
  # Reset start time on each intermediate stop
else
  date +%s > "$START_FILE"
fi

# Schedule notification in background after debounce delay
(
  echo $$ > "$PID_FILE"
  sleep "$DEBOUNCE"

  # Skip if terminal is focused
  if [ "$ONLY_WHEN_UNFOCUSED" = true ]; then
    frontmost=$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null | tr '[:upper:]' '[:lower:]')
    case "$frontmost" in
      terminal|iterm2|iterm|alacritty|kitty|wezterm|hyper|warp|ghostty)
        rm -f "$PID_FILE" "$START_FILE"
        exit 0
        ;;
    esac
  fi

  # Calculate elapsed time
  elapsed=""
  if [ -f "$START_FILE" ]; then
    start_ts=$(cat "$START_FILE")
    now_ts=$(date +%s)
    diff=$((now_ts - start_ts))
    if [ "$diff" -ge 60 ]; then
      mins=$((diff / 60))
      secs=$((diff % 60))
      elapsed="${mins}m ${secs}s"
    else
      elapsed="${diff}s"
    fi
  fi

  # Build notification message
  message="Claude finished responding"
  if [ -n "$elapsed" ]; then
    message="Completed in ${elapsed}"
  fi

  # Notify
  notify_banner() {
    if command -v terminal-notifier &>/dev/null; then
      terminal-notifier \
        -title "Claude Code" \
        -subtitle "Response complete" \
        -message "$message" \
        -appIcon "/Applications/Claude.app/Contents/Resources/AppIcon.icns" \
        -sound "$SOUND" \
        -group "claude-code-notify" \
        2>/dev/null
    else
      osascript -e "display notification \"$message\" with title \"Claude Code\" subtitle \"Response complete\" sound name \"$SOUND\""
    fi
  }

  notify_banner_silent() {
    if command -v terminal-notifier &>/dev/null; then
      terminal-notifier \
        -title "Claude Code" \
        -subtitle "Response complete" \
        -message "$message" \
        -appIcon "/Applications/Claude.app/Contents/Resources/AppIcon.icns" \
        -group "claude-code-notify" \
        2>/dev/null
    else
      osascript -e "display notification \"$message\" with title \"Claude Code\" subtitle \"Response complete\""
    fi
  }

  case "$MODE" in
    sound)
      afplay "/System/Library/Sounds/${SOUND}.aiff"
      ;;
    banner)
      notify_banner_silent
      ;;
    both)
      notify_banner
      ;;
  esac

  rm -f "$PID_FILE" "$START_FILE"
) &
disown

exit 0
