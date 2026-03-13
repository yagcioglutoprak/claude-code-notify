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

# Copy hook script and icon
cp "$SCRIPT_DIR/notify-on-stop.sh" "$HOOKS_DIR/notify-on-stop.sh"
cp "$SCRIPT_DIR/icon.png" "$HOOKS_DIR/icon.png"
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

# Enable notifications for terminal-notifier in macOS
if command -v terminal-notifier &>/dev/null; then
  # Send a test notification to register with Notification Center
  terminal-notifier \
    -title "Claude Code Notify" \
    -subtitle "Setup complete" \
    -message "You'll be notified when Claude finishes responding." \
    -appIcon "$HOOKS_DIR/icon.png" \
    -sound "Ping" \
    2>/dev/null

  # Auto-enable notifications via defaults
  BUNDLE_ID="nl.superalloy.oss.terminal-notifier"
  # Get current flags (if any) and ensure alerts are enabled
  defaults write com.apple.notificationcenterui bannerStyle -int 1 2>/dev/null || true
  # Set notification style to Alerts (persistent) for terminal-notifier
  NCPREFS="$HOME/Library/Preferences/com.apple.ncprefs.plist"
  if [ -f "$NCPREFS" ]; then
    # Use plutil to check if we can modify notification preferences
    python3 -c "
import plistlib, sys
prefs_path = '$NCPREFS'
try:
    with open(prefs_path, 'rb') as f:
        prefs = plistlib.load(f)
    apps = prefs.get('apps', [])
    found = False
    for app in apps:
        bid = app.get('bundle-id', '')
        if bid == '$BUNDLE_ID':
            app['flags'] = app.get('flags', 0) | 0x4000  # Enable notifications
            found = True
            break
    if not found:
        apps.append({
            'bundle-id': '$BUNDLE_ID',
            'flags': 0x4000 | 0x8,  # Enabled + banners
        })
        prefs['apps'] = apps
    with open(prefs_path, 'wb') as f:
        plistlib.dump(prefs, f)
except Exception as e:
    pass  # Silently fail — user can enable manually
" 2>/dev/null || true
    # Restart notification center to pick up changes
    killall NotificationCenter 2>/dev/null || true
  fi

  echo ""
  echo "If you don't see the test notification above, enable notifications:"
  echo "  System Settings > Notifications > terminal-notifier > Allow Notifications"
fi

echo ""
echo "Done! Restart Claude Code to activate."
echo ""
echo "Config: $HOOKS_DIR/notify.conf"
echo "  MODE=sound|banner|both  (default: sound)"
echo "  SOUND=Ping|Glass|Pop|Hero|...  (default: Ping)"
echo "  DEBOUNCE=3  (seconds, default: 3)"
echo "  ONLY_WHEN_UNFOCUSED=true|false  (default: true)"
