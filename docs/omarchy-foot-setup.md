## Use `footclient` as Omarchy default terminal (TUI + screensaver)

### 1) Install `foot`
```bash
omarchy-pkg-install foot || yay -S foot
```

Start the Foot server (first-time setup):
```bash
systemctl --user enable --now foot-server
```

### 2) Set default terminal for `xdg-terminal-exec`
```bash
cat > ~/.config/xdg-terminals.list <<'EOF'
# Terminal emulator preference order for xdg-terminal-exec
# The first found and valid terminal will be used
footclient.desktop
EOF
```

### 3) Create Foot Omarchy theme wiring
Create the Foot template used by Omarchy theme rendering:

```bash
mkdir -p ~/.config/omarchy/themed
cat > ~/.config/omarchy/themed/foot.ini.tpl <<'EOF'
[colors]
background={{ background_strip }}
foreground={{ foreground_strip }}
cursor={{ background_strip }} {{ cursor_strip }}
selection-background={{ selection_background_strip }}
selection-foreground={{ selection_foreground_strip }}

regular0={{ color0_strip }}
regular1={{ color1_strip }}
regular2={{ color2_strip }}
regular3={{ color3_strip }}
regular4={{ color4_strip }}
regular5={{ color5_strip }}
regular6={{ color6_strip }}
regular7={{ color7_strip }}

bright0={{ color8_strip }}
bright1={{ color9_strip }}
bright2={{ color10_strip }}
bright3={{ color11_strip }}
bright4={{ color12_strip }}
bright5={{ color13_strip }}
bright6={{ color14_strip }}
bright7={{ color15_strip }}
EOF
```

Create Foot base config that includes Omarchy-generated colors:

```bash
mkdir -p ~/.config/foot
cat > ~/.config/foot/foot.ini <<'EOF'
# Foot base config (Omarchy-wired)
# Dynamic theme colors are loaded from Omarchy current theme output.
include=~/.config/omarchy/current/theme/foot.ini

font=Hack Nerd Font:size=13.5
pad=14x14

[colors]
# alpha=1.0

[cursor]
style=block
blink=no

[key-bindings]
primary-paste=Shift+Insert
clipboard-copy=Control+Insert
EOF
```

Apply once to render current theme output:

```bash
omarchy-theme-set "$(omarchy-theme-current)"
```

### 4) Override screensaver launcher
Create `~/.local/bin/omarchy-launch-screensaver`:

```bash
cat > ~/.local/bin/omarchy-launch-screensaver <<'EOF'
#!/bin/bash

if ! command -v tte &>/dev/null; then exit 1; fi
pgrep -f org.omarchy.screensaver && exit 0
if [[ -f ~/.local/state/omarchy/toggles/screensaver-off ]] && [[ $1 != "force" ]]; then exit 1; fi

walker -q
focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')
terminal=$(xdg-terminal-exec --print-id)

for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
  hyprctl dispatch focusmonitor "$m"
  case $terminal in
    *Alacritty*)
      hyprctl dispatch exec -- \
        alacritty --class=org.omarchy.screensaver \
        --config-file ~/.local/share/omarchy/default/alacritty/screensaver.toml \
        -e omarchy-cmd-screensaver
      ;;
    *ghostty*)
      hyprctl dispatch exec -- \
        ghostty --class=org.omarchy.screensaver \
        --config-file=~/.local/share/omarchy/default/ghostty/screensaver \
        --font-size=18 \
        -e omarchy-cmd-screensaver
      ;;
    *kitty*)
      hyprctl dispatch exec -- \
        kitty --class=org.omarchy.screensaver \
        --override font_size=18 \
        --override window_padding_width=0 \
        -e omarchy-cmd-screensaver
      ;;
    *foot*)
      hyprctl dispatch exec -- \
        footclient -F -a org.omarchy.screensaver \
        omarchy-cmd-screensaver
      ;;
    *)
      notify-send "✋  Screensaver runs in Alacritty, Ghostty, Kitty, or Foot"
      ;;
  esac
done

hyprctl dispatch focusmonitor "$focused"
EOF
```

Make it executable:
```bash
chmod +x ~/.local/bin/omarchy-launch-screensaver
```

### 5) Verify
```bash
xdg-terminal-exec --print-id
```

Expected:
```text
footclient.desktop
```

Test screensaver immediately (no waiting):
```bash
omarchy-launch-screensaver force
```

### 6) Optional (terminal styling in Hyprland)
Add to `~/.config/hypr/looknfeel.conf`:

```conf
windowrule = tag +terminal, match:class (foot|footclient)
```

Reload Hyprland:
```bash
hyprctl reload
```

### 7) Fix Tab completion in Foot (Omarchy-safe, no `inputrc` override)
Create `~/.config/omarchy/bash/init`:

```bash
cat > ~/.config/omarchy/bash/init <<'EOF'
if [ -f "$HOME/.local/share/omarchy/default/bash/init" ]; then
  # shellcheck disable=SC1091
  source "$HOME/.local/share/omarchy/default/bash/init"
fi
EOF
```

Then edit `~/.bashrc` and add this line inside the interactive block, **after** the `bind -f ...inputrc` logic:

```bash
bind '"\C-i": menu-complete'
```

Resulting block:

```bash
if [[ $- == *i* ]]; then
  if [ -f "$OMARCHY_USER_BASH_DIR/inputrc" ]; then
    bind -f "$OMARCHY_USER_BASH_DIR/inputrc"
  else
    [ -f "$OMARCHY_DEFAULT_BASH_DIR/inputrc" ] && bind -f "$OMARCHY_DEFAULT_BASH_DIR/inputrc"
  fi
  bind '"\C-i": menu-complete'
fi
```

Remove user `inputrc` override if present:

```bash
rm -f ~/.config/omarchy/bash/inputrc
```

Apply now:

```bash
source ~/.bashrc
```

Result: Foot keeps Omarchy defaults, and `Tab` uses Omarchy-style menu completion (including file/dir cycling).

### 8) Optional: Foot live recolor on theme change (`@iambypass` Theme-Hook flow)
If you use Omarchy Theme-Hook style `theme-set.d` hooklettes, add this hook:

- `~/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh`

What it does:
- Runs during `omarchy-theme-set`.
- Sends OSC color updates to active Foot terminals (no Foot restart required).
- Reads colors from Omarchy-exported hook vars, with fallback to `~/.config/omarchy/current/theme/foot.ini`.

Enable:
```bash
chmod +x ~/.config/omarchy/hooks/theme-set.d/26-foot-live-colors.sh
```

Test:
```bash
omarchy-theme-set "$(omarchy-theme-current)"
tail -f /tmp/foot-theme-hook.log
```

Disable quickly (without removing script):
```bash
FOOT_LIVE_THEME=0 omarchy-theme-set "$(omarchy-theme-current)"
```
