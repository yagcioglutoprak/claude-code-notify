# claude-code-notify

Get notified when Claude Code finishes responding. Sound, notification banner, or both.

Uses Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) to detect when a response is complete, with debounce to avoid false triggers during intermediate tool calls.

**macOS only** (uses `afplay` and `osascript`). Requires `jq` (`brew install jq`).

## Install

One command. That's it.

```bash
git clone https://github.com/yagcioglutoprak/claude-code-notify.git /tmp/claude-code-notify && /tmp/claude-code-notify/install.sh && rm -rf /tmp/claude-code-notify
```

Restart Claude Code and you'll hear a ping every time Claude finishes.

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
git clone https://github.com/yagcioglutoprak/claude-code-notify.git /tmp/claude-code-notify && /tmp/claude-code-notify/uninstall.sh && rm -rf /tmp/claude-code-notify
```

Removes the script, config, and hook entry from `settings.json` automatically.

## License

MIT
