# 🧹 CleanerMenu

> **A STAGSTER LABS product** — [github.com/stagster/CleanerMenu](https://github.com/stagster/CleanerMenu)

**macOS menu bar app** — live system stats + one-click cleanup. Made for developers, designers, and especially **vibe coders** running AI tools (Claude Code, Cursor, ChatGPT) that eat RAM and leave stale dev servers running.

## Features

### 📊 Live Stats (refreshes every 3s)
- **CPU** — current utilization %
- **Memory** — free / total with usage %
- **Disk** — used / total with usage %
- **Uptime** — system uptime
- **Top 3 processes** — sorted by memory

Memory % shown right in the menu bar with a color indicator (🟢/🟡).

### 🧹 One-Click Cleanup

| Action | Shortcut | What it does |
|--------|----------|-------------|
| Clear Inactive Memory | `⌘P` | Runs `purge` to free cached/inactive RAM |
| Auto Free Memory (>80%) | `⌘M` | Purge + auto-kill biggest memory hogs |
| Free Purgeable Disk Space | `⌘D` | Reclaims purgeable APFS space |
| Empty Trash | `⌘T` | Empties `~/.Trash` |
| Clear DNS Cache | `⌘N` | Flushes DNS resolver cache |
| Deep Clean | `⌘L` | Purge + trash + disk purge + caches + DerivedData |
| Restart Finder | `⌘R` | Kills & relaunches Finder (fixes memory leaks) |
| Reduce Animations | `⌘V` | Toggles macOS animations for snappier UI |

### 💀 Kill Processes

| Action | Shortcut | What it does |
|--------|----------|-------------|
| Kill Heavy Apps | `⌘K` | Kills Chrome, Slack, Spotify, Discord, Zoom, VS Code, Docker, etc. |
| Kill Dev Servers | `⌘Z` | Kills npm run, next-server, node dev, esbuild, workerd, vite, tsx, turbo |
| Kill Everything | `⌘E` | Mass-kill user processes + purge + clear caches |

**Kill Dev Servers** is perfect when you have orphaned `npm run dev`, `next-server`, or Cloudflare `workerd` processes eating memory in the background.

## Who is this for?

- **Vibe coders** — AI tools (Claude Code, Cursor, ChatGPT) leave processes behind. Kill them in one click.
- **Devs** — stale dev servers, node_modules cache, npm cache hogging space
- **Anyone on macOS** — quick system cleanup without opening Activity Monitor

## Requirements

- macOS 11.0+ (Big Sur)
- Apple Silicon or Intel Mac

## Install

[Download the latest release](https://github.com/stagster/CleanerMenu/releases) or build from source:

```bash
git clone https://github.com/stagster/CleanerMenu.git
cd CleanerMenu
./build.sh   # compiles, signs, creates .app
```

Move `CleanerMenu.app` to `/Applications` and run it. Add to Login Items to auto-start.

## Sudo Setup (recommended)

To avoid password prompts for `purge` and `diskutil`:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /usr/sbin/purge, /usr/sbin/diskutil" | sudo tee /etc/sudoers.d/cleanermenu
```

## Notes

- Runs in menu bar only — no Dock icon
- ~212 KB binary, minimal memory footprint
- Not on the Mac App Store (requires sudo for shell commands)
