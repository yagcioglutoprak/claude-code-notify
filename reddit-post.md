# Title: I built a one-command notification hook for Claude Code (sound/banner when it's done responding)

# Body:

I kept alt-tabbing back to my terminal to check if Claude was done, especially during long multi-tool responses. So I built a tiny hook that pings you when it's actually finished.

**The problem with a naive approach:** Claude Code fires the `Stop` hook between *every* tool call, not just at the end. So a simple "play sound on Stop" would ping you 10+ times per response.

**The fix:** Debounce. Each Stop event cancels the previous pending notification and starts a fresh 3-second timer. You only get pinged once — when Claude is truly done.

## Install (one command)

```bash
git clone https://github.com/yagcioglutoprak/claude-code-notify.git /tmp/claude-code-notify && /tmp/claude-code-notify/install.sh && rm -rf /tmp/claude-code-notify
```

That's it. Restart Claude Code and you'll hear a ping when it finishes.

## Configure

Edit `~/.claude/hooks/notify.conf`:

```
MODE=sound       # sound | banner | both
SOUND=Ping       # Ping, Glass, Pop, Hero, Purr, etc.
DEBOUNCE=3       # seconds
```

It's one bash script, no binaries, no compilation, no runtime dependencies beyond `jq`.

GitHub: https://github.com/yagcioglutoprak/claude-code-notify

Happy to take PRs — Linux support (`notify-send`) would be a great addition if anyone wants to contribute.
