#!/usr/bin/env bash
set -u

LOG_FILE="/tmp/foot-theme-hook.log"
FOOT_THEME_FILE="$HOME/.config/omarchy/current/theme/foot.ini"
ENABLED="${FOOT_LIVE_THEME:-1}"

log() {
  printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE"
}

normalize_hex() {
  local value="${1:-}"
  value="${value#\#}"
  value="${value,,}"
  if [[ "$value" =~ ^[0-9a-f]{6}$ ]]; then
    printf '%s' "$value"
    return 0
  fi
  return 1
}

parse_foot_color() {
  local key="$1"
  awk -F= -v wanted="$key" '
    BEGIN { in_colors = 0 }
    /^[[:space:]]*\[/ {
      in_colors = ($0 ~ /^[[:space:]]*\[colors\][[:space:]]*$/)
      next
    }
    in_colors {
      k = $1
      gsub(/[[:space:]]/, "", k)
      if (k == wanted) {
        v = $2
        sub(/^[[:space:]]+/, "", v)
        sub(/[[:space:]]+$/, "", v)
        print v
        exit
      }
    }
  ' "$FOOT_THEME_FILE" 2>/dev/null
}

read_cursor_fallback() {
  local raw
  raw="$(parse_foot_color "cursor")"
  raw="${raw#\#}"
  raw="${raw%% *}"
  normalize_hex "$raw" || true
}

load_color() {
  local var_name="$1"
  local fallback_key="$2"
  local current="${!var_name:-}"

  if current="$(normalize_hex "$current" 2>/dev/null)"; then
    printf -v "$var_name" '%s' "$current"
    return 0
  fi

  local parsed
  parsed="$(parse_foot_color "$fallback_key")"
  parsed="${parsed#\#}"
  parsed="${parsed%% *}"
  if parsed="$(normalize_hex "$parsed" 2>/dev/null)"; then
    printf -v "$var_name" '%s' "$parsed"
    return 0
  fi
  return 1
}

collect_foot_ttys() {
  ps -eo pid=,ppid=,tty=,comm= | awk '
    {
      pid = $1
      ppid[pid] = $2
      tty[pid] = $3
      comm[pid] = $4
      pids[++n] = pid
    }
    END {
      for (i = 1; i <= n; i++) {
        p = pids[i]
        t = tty[p]
        if (t == "?" || t == "" || t !~ /^pts\//) {
          continue
        }
        q = p
        is_foot = 0
        while (q != "" && q != "0") {
          c = comm[q]
          if (c == "foot" || c == "footclient") {
            is_foot = 1
            break
          }
          q = ppid[q]
        }
        if (is_foot) {
          print "/dev/" t
        }
      }
    }
  ' | sort -u
}

if [[ "$ENABLED" == "0" ]]; then
  log "disabled via FOOT_LIVE_THEME=0"
  exit 0
fi

if [[ ! -f "$FOOT_THEME_FILE" ]]; then
  log "missing theme file: $FOOT_THEME_FILE"
  exit 0
fi

if ! load_color primary_background "background"; then
  log "missing background color"
  exit 0
fi
if ! load_color primary_foreground "foreground"; then
  log "missing foreground color"
  exit 0
fi
if ! load_color cursor_color "cursor"; then
  cursor_color="$(read_cursor_fallback)"
fi
if ! cursor_color="$(normalize_hex "${cursor_color:-}" 2>/dev/null)"; then
  cursor_color="$primary_foreground"
fi

declare -a palette=()
for idx in $(seq 0 15); do
  var_name=""
  if (( idx < 8 )); then
    case "$idx" in
      0) var_name="normal_black" ;;
      1) var_name="normal_red" ;;
      2) var_name="normal_green" ;;
      3) var_name="normal_yellow" ;;
      4) var_name="normal_blue" ;;
      5) var_name="normal_magenta" ;;
      6) var_name="normal_cyan" ;;
      7) var_name="normal_white" ;;
    esac
  else
    case "$idx" in
      8) var_name="bright_black" ;;
      9) var_name="bright_red" ;;
      10) var_name="bright_green" ;;
      11) var_name="bright_yellow" ;;
      12) var_name="bright_blue" ;;
      13) var_name="bright_magenta" ;;
      14) var_name="bright_cyan" ;;
      15) var_name="bright_white" ;;
    esac
  fi

  fallback_key="regular$idx"
  if (( idx >= 8 )); then
    fallback_key="bright$((idx-8))"
  fi

  value=""
  if [[ -n "$var_name" ]]; then
    value="${!var_name:-}"
  fi
  if ! value="$(normalize_hex "$value" 2>/dev/null)"; then
    parsed="$(parse_foot_color "$fallback_key")"
    parsed="${parsed#\#}"
    if value="$(normalize_hex "$parsed" 2>/dev/null)"; then
      :
    else
      value="$primary_foreground"
    fi
  fi
  palette[idx]="$value"
done

payload=""
osc_end=$'\e\\'
payload+=$'\e]10;#'"$primary_foreground""$osc_end"
payload+=$'\e]11;#'"$primary_background""$osc_end"
payload+=$'\e]12;#'"$cursor_color""$osc_end"
for idx in $(seq 0 15); do
  payload+=$'\e]4;'"$idx"';#'"${palette[idx]}""$osc_end"
done

updated=0
while IFS= read -r tty; do
  [[ -n "$tty" ]] || continue
  if [[ ! -w "$tty" ]]; then
    log "cannot write to $tty"
    continue
  fi
  if { printf '%b' "$payload" > "$tty"; } 2>/dev/null; then
    updated=$((updated + 1))
  else
    log "write failed: $tty"
  fi
done < <(collect_foot_ttys)

if (( updated > 0 )); then
  log "updated $updated foot tty(s)"
  if declare -f success >/dev/null 2>&1; then
    success "Foot live colors updated!"
  fi
else
  log "no active foot tty to update"
fi

exit 0
