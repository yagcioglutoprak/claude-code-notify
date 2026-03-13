#!/bin/bash
set -e

HOOKS_DIR="$HOME/.claude/hooks"

echo "Uninstalling claude-code-notify..."

# Remove hook script
if [ -f "$HOOKS_DIR/notify-on-stop.sh" ]; then
  rm "$HOOKS_DIR/notify-on-stop.sh"
  echo "Removed $HOOKS_DIR/notify-on-stop.sh"
fi

# Remove config
if [ -f "$HOOKS_DIR/notify.conf" ]; then
  rm "$HOOKS_DIR/notify.conf"
  echo "Removed $HOOKS_DIR/notify.conf"
fi

# Clean up debounce pid file
rm -f /tmp/claude-notify-debounce.pid

echo ""
echo "Done! Remember to remove the Stop hook entry from ~/.claude/settings.json manually."
