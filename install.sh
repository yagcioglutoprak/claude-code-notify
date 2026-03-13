#!/bin/bash
set -e

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing claude-code-notify..."

# Create hooks directory
mkdir -p "$HOOKS_DIR"

# Copy hook script
cp "$SCRIPT_DIR/notify-on-stop.sh" "$HOOKS_DIR/notify-on-stop.sh"
chmod +x "$HOOKS_DIR/notify-on-stop.sh"

# Copy config only if not already present (preserve user settings)
if [ ! -f "$HOOKS_DIR/notify.conf" ]; then
  cp "$SCRIPT_DIR/notify.conf" "$HOOKS_DIR/notify.conf"
  echo "Created config at $HOOKS_DIR/notify.conf"
else
  echo "Config already exists at $HOOKS_DIR/notify.conf (kept existing)"
fi

# Add hook to settings.json
if [ ! -f "$SETTINGS_FILE" ]; then
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify-on-stop.sh"
          }
        ]
      }
    ]
  }
}
EOF
  echo "Created $SETTINGS_FILE with Stop hook"
else
  # Check if hook is already configured
  if grep -q "notify-on-stop" "$SETTINGS_FILE" 2>/dev/null; then
    echo "Hook already configured in $SETTINGS_FILE"
  else
    echo ""
    echo "Add the following to your $SETTINGS_FILE under \"hooks\":"
    echo ""
    echo '  "hooks": {'
    echo '    "Stop": ['
    echo '      {'
    echo '        "hooks": ['
    echo '          {'
    echo '            "type": "command",'
    echo '            "command": "~/.claude/hooks/notify-on-stop.sh"'
    echo '          }'
    echo '        ]'
    echo '      }'
    echo '    ]'
    echo '  }'
    echo ""
    echo "Or run: claude-code-notify --inject to auto-add it."
  fi
fi

echo ""
echo "Done! Restart Claude Code to activate."
echo "Edit $HOOKS_DIR/notify.conf to customize (sound, banner, debounce)."
