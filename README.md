# Foot for Omarchy

Use `foot` as your Omarchy terminal without losing Omarchy's theme flow, terminal detection, or screensaver behavior.

This repository packages the full Foot-first Omarchy setup as:

- a set of mirrored config files you can inspect or copy into place
- a reference implementation for optional live recolor and `footclient` support

## What This Repo Gives You

If you want Omarchy to feel like it was built around Foot, this repo covers the full path:

- `xdg-terminal-exec` resolves to `foot` or `footclient`
- Omarchy theme rendering writes Foot colors into the active theme output
- Foot can live-recolor on theme changes without a restart
- Omarchy's screensaver launcher can open inside Foot

## Start Here

| Page | What it's for |
| --- | --- |
| [`docs/omarchy-foot-setup.md`](docs/omarchy-foot-setup.md) | Main guide. Install, wire Foot into Omarchy, verify it, and optionally enable live recolor or `footclient`. |

## Implementation Index

Think of `implementation/` as the file map behind the guide.

| Repo path | Target path | Purpose |
| --- | --- | --- |
| [`implementation/.config/xdg-terminals.list`](implementation/.config/xdg-terminals.list) | `~/.config/xdg-terminals.list` | Makes `xdg-terminal-exec` prefer Foot. |
| [`implementation/.config/foot/foot.ini`](implementation/.config/foot/foot.ini) | `~/.config/foot/foot.ini` | Base Foot config that includes Omarchy-generated theme colors. |
| [`implementation/.config/omarchy/themed/foot.ini.tpl`](implementation/.config/omarchy/themed/foot.ini.tpl) | `~/.config/omarchy/themed/foot.ini.tpl` | Omarchy template used to render the active Foot palette. |
| [`implementation/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh`](implementation/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh) | `~/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh` | Optional live recolor hook for already-open Foot terminals. |
| [`implementation/.local/bin/omarchy-launch-screensaver`](implementation/.local/bin/omarchy-launch-screensaver) | `~/.local/bin/omarchy-launch-screensaver` | Screensaver launcher override with Foot support. |

## Recommended Flow

1. Read [`docs/omarchy-foot-setup.md`](docs/omarchy-foot-setup.md).
2. Copy or adapt the files under [`implementation/`](implementation/).
3. Run `omarchy-theme-set "$(omarchy-theme-current)"`.
4. Verify with `xdg-terminal-exec --print-id`.
5. Optionally test `omarchy-launch-screensaver force`.

## Feature Map

### Default Terminal

Foot becomes the terminal Omarchy resolves through `xdg-terminal-exec`.

Primary file:
[`implementation/.config/xdg-terminals.list`](implementation/.config/xdg-terminals.list)

### Theme Integration

Omarchy remains the source of truth for colors. Foot reads the rendered theme output instead of hardcoding a separate palette.

Primary files:
[`implementation/.config/foot/foot.ini`](implementation/.config/foot/foot.ini)
[`implementation/.config/omarchy/themed/foot.ini.tpl`](implementation/.config/omarchy/themed/foot.ini.tpl)

### Live Recolor

If you use Omarchy theme hooks, the optional hook can push new colors into running Foot terminals after `omarchy-theme-set`.

Primary file:
[`implementation/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh`](implementation/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh)

### Screensaver Support

Omarchy's screensaver launcher keeps its existing behavior but gains a Foot branch.

Primary file:
[`implementation/.local/bin/omarchy-launch-screensaver`](implementation/.local/bin/omarchy-launch-screensaver)

## Quick Validation

Use these after setup:

```bash
xdg-terminal-exec --print-id
omarchy-theme-set "$(omarchy-theme-current)"
omarchy-launch-screensaver force
```

If live recolor is enabled:

```bash
tail -f /tmp/foot-theme-hook.log
```

## Who This Is For

This repo is for Omarchy users who want:

- Foot as the default terminal
- Omarchy-managed terminal colors instead of a separate Foot theme workflow
- a documented, inspectable setup instead of one-off local tweaks

If you only need one piece of the setup, use the index above and take just the relevant file.
