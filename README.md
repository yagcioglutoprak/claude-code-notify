# claude-code-notify

Get notified when Claude Code finishes responding. Sound, notification banner, or both.

Uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to detect when a response is complete, with debounce to avoid false triggers during intermediate tool calls.

**macOS only** (uses `afplay` and `osascript`).

## Install

```bash
git clone https://github.com/toprakyagcioglu/claude-code-notify.git
cd claude-code-notify
chmod +x install.sh
./install.sh
```

Then add the hook to your `~/.claude/settings.json`:

```json
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
```

Restart Claude Code.

## Configure

Edit `~/.claude/hooks/notify.conf`:

```bash
# MODE: sound | banner | both
MODE=sound

# SOUND: Ping, Glass, Blow, Pop, Hero, Purr, Sosumi, Submarine, Tink
SOUND=Ping

# Seconds to wait after last stop before notifying.
# Prevents false triggers during multi-step tool calls.
DEBOUNCE=3
```

| Mode | Behavior |
|------|----------|
| `sound` | System sound only |
| `banner` | macOS notification banner only |
| `both` | Banner with sound |

## How it works

Claude Code fires a `Stop` hook every time the model stops — including between tool calls. A naive hook would ping you dozens of times per response.

This hook uses **debounce**: each Stop event cancels the previous pending notification and starts a fresh timer. The notification only fires after `DEBOUNCE` seconds of silence, meaning Claude is truly done.

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

Then remove the `Stop` hook entry from `~/.claude/settings.json`.

## License

MIT
