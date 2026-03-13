#!/bin/bash
set -e

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"

echo "Uninstalling claude-code-notify..."

# Remove hook script and config
rm -f "$HOOKS_DIR/notify-on-stop.sh"
rm -f "$HOOKS_DIR/notify.conf"
rm -f /tmp/claude-notify-debounce.pid

# Remove hook from settings.json
if [ -f "$SETTINGS_FILE" ] && command -v jq &>/dev/null; then
  if grep -q "notify-on-stop" "$SETTINGS_FILE" 2>/dev/null; then
    jq '(.hooks.Stop // []) |= map(select(.hooks | any(.command | contains("notify-on-stop")) | not)) | if .hooks.Stop == [] then del(.hooks.Stop) else . end | if .hooks == {} then del(.hooks) else . end' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
    mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
    echo "Removed hook from settings.json"
  fi
fi

echo "Done!"
