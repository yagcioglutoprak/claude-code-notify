#!/bin/bash
set -e

HOOKS_DIR="$HOME/.claude/hooks"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "Installing claude-code-notify..."

# Ensure jq is available
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install it with: brew install jq"
  exit 1
fi

# Install terminal-notifier for rich notifications (optional but recommended)
if ! command -v terminal-notifier &>/dev/null; then
  if command -v brew &>/dev/null; then
    echo "Installing terminal-notifier for rich notification banners..."
    brew install terminal-notifier
  else
    echo "Note: Install terminal-notifier for rich banners (brew install terminal-notifier)"
    echo "Falling back to basic osascript notifications."
  fi
fi

# Create directories
mkdir -p "$HOOKS_DIR"
mkdir -p "$HOME/.claude"

# Copy hook script
cp "$SCRIPT_DIR/notify-on-stop.sh" "$HOOKS_DIR/notify-on-stop.sh"
chmod +x "$HOOKS_DIR/notify-on-stop.sh"

# Copy config only if not already present (preserve user settings)
if [ ! -f "$HOOKS_DIR/notify.conf" ]; then
  cp "$SCRIPT_DIR/notify.conf" "$HOOKS_DIR/notify.conf"
fi

# Auto-inject hook into settings.json
HOOK_ENTRY='{"hooks":[{"type":"command","command":"~/.claude/hooks/notify-on-stop.sh"}]}'

if [ ! -f "$SETTINGS_FILE" ]; then
  # No settings file — create one
  echo "{}" | jq --argjson hook "$HOOK_ENTRY" '.hooks.Stop = [$hook]' > "$SETTINGS_FILE"
elif grep -q "notify-on-stop" "$SETTINGS_FILE" 2>/dev/null; then
  echo "Hook already configured — skipping settings.json"
else
  # Merge into existing settings
  if jq -e '.hooks.Stop' "$SETTINGS_FILE" &>/dev/null; then
    jq --argjson hook "$HOOK_ENTRY" '.hooks.Stop += [$hook]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
  elif jq -e '.hooks' "$SETTINGS_FILE" &>/dev/null; then
    jq --argjson hook "$HOOK_ENTRY" '.hooks.Stop = [$hook]' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
  else
    jq --argjson hook "$HOOK_ENTRY" '.hooks = {"Stop": [$hook]}' "$SETTINGS_FILE" > "${SETTINGS_FILE}.tmp"
  fi
  mv "${SETTINGS_FILE}.tmp" "$SETTINGS_FILE"
fi

echo ""
echo "Done! Restart Claude Code to activate."
echo ""
echo "Config: $HOOKS_DIR/notify.conf"
echo "  MODE=sound|banner|both  (default: sound)"
echo "  SOUND=Ping|Glass|Pop|Hero|...  (default: Ping)"
echo "  DEBOUNCE=3  (seconds, default: 3)"
echo "  ONLY_WHEN_UNFOCUSED=true|false  (default: true)"
