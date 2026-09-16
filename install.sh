#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  install.sh — link the configuration into place.
#  Idempotent. Anything it would overwrite is backed up first.
#  Use this when the packages are already installed; otherwise run
#  ./bootstrap.sh, which calls this at the end.
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

GREEN=$'\e[1;32m'; DIM=$'\e[2;37m'; YELLOW=$'\e[1;33m'; RESET=$'\e[0m'
ok()   { printf '%s  %s%s\n' "$GREEN" "$RESET$1" ""; }
info() { printf '%s  %s%s\n' "$DIM" "$1" "$RESET"; }
warn() { printf '%s  %s%s\n' "$YELLOW" "$1" "$RESET"; }

mkdir -p \
    "$HOME/.config/i3" \
    "$HOME/.config/i3blocks" \
    "$HOME/.config/kitty" \
    "$HOME/.config/rofi" \
    "$HOME/.config/picom" \
    "$HOME/.local/bin" \
    "$HOME/.cache"

link() {
    local src="$1" dst="$2"

    if [[ -L "$dst" ]]; then
        [[ "$(readlink -f "$dst")" == "$(readlink -f "$src")" ]] && {
            info "already linked  ${dst/#$HOME/~}"
            return
        }
        rm -f "$dst"
    elif [[ -e "$dst" ]]; then
        mv "$dst" "${dst}.backup.${TIMESTAMP}"
        warn "backed up       ${dst/#$HOME/~}.backup.${TIMESTAMP}"
    fi

    ln -sfn "$src" "$dst"
    ok "linked          ${dst/#$HOME/~}"
}

echo
echo "  nightgrid — installing into ${HOME/#$HOME/~}"
echo

link "$DOTFILES/i3/config"            "$HOME/.config/i3/config"
link "$DOTFILES/i3blocks/config"      "$HOME/.config/i3blocks/config"
link "$DOTFILES/i3blocks/scripts"     "$HOME/.config/i3blocks/scripts"
link "$DOTFILES/kitty/kitty.conf"     "$HOME/.config/kitty/kitty.conf"
link "$DOTFILES/kitty/nightgrid.conf" "$HOME/.config/kitty/nightgrid.conf"
link "$DOTFILES/picom/picom.conf"     "$HOME/.config/picom/picom.conf"
link "$DOTFILES/tmux/tmux.conf"       "$HOME/.tmux.conf"
link "$DOTFILES/zsh/.zshrc"           "$HOME/.zshrc"
link "$DOTFILES/cherrytree/config.cfg"     "$HOME/.config/cherrytree/config.cfg"

for f in "$DOTFILES"/rofi/*.rasi; do
    [[ -e "$f" ]] || continue
    link "$f" "$HOME/.config/rofi/$(basename "$f")"
done

for f in "$DOTFILES"/bin/*; do
    [[ -f "$f" ]] || continue
    chmod +x "$f"
    link "$f" "$HOME/.local/bin/$(basename "$f")"
done

chmod +x "$DOTFILES"/i3blocks/scripts/* 2>/dev/null || true

# ─── ~/.local/bin on PATH ──────────────────────────────────────────────
if ! grep -q '.local/bin' <<<"$PATH"; then
    warn "~/.local/bin is not on PATH — add it to ~/.zshenv if scripts do not resolve"
fi

# ─── Pre-render the lock screen ────────────────────────────────────────
WALLPAPER="$DOTFILES/wallpapers/nightgrid.png"
LOCK_IMAGE="${XDG_CACHE_HOME:-$HOME/.cache}/i3lock/blurred.png"
MAGICK="$(command -v magick || command -v convert || true)"

# Apply the desktop background immediately — i3's exec_always only fires on
# (re)start, so without this the wallpaper stays stale until the next reload.
if [[ -n "${DISPLAY:-}" && -f "$WALLPAPER" ]] && command -v feh >/dev/null; then
    feh --bg-fill "$WALLPAPER"
    ok "wallpaper       applied"
fi

# Reload tmux config for any already-running server, so window/status
# styling doesn't stay stuck on whatever config was active when the
# session was first created.
if command -v tmux >/dev/null && tmux info &>/dev/null; then
    tmux source-file "$DOTFILES/tmux/tmux.conf" 2>/dev/null && ok "tmux            reloaded"
fi

if [[ -n "$MAGICK" && -n "${DISPLAY:-}" && -f "$WALLPAPER" ]] && command -v xdpyinfo >/dev/null; then
    RESOLUTION="$(xdpyinfo 2>/dev/null | awk '/dimensions/{print $2; exit}' || true)"
    mkdir -p "$(dirname "$LOCK_IMAGE")"
    "$MAGICK" "$WALLPAPER" \
        -resize "${RESOLUTION}^" -gravity center -extent "$RESOLUTION" \
        -blur 0x14 -modulate 70 "$LOCK_IMAGE"
    ok "lock screen     pre-rendered at $RESOLUTION"
else
    info "lock screen     will be rendered on first use"
fi

# ─── Firefox extensions (FoxyProxy, Wappalyzer) ───────────────────────
FF_POLICY_SRC="$DOTFILES/firefox/policies.json"
if [[ -f "$FF_POLICY_SRC" ]]; then
    FF_DIST_DIR=""
    for d in /usr/lib/firefox-esr/distribution /usr/lib/firefox/distribution; do
        [[ -d "$(dirname "$d")" ]] && FF_DIST_DIR="$d" && break
    done

    if [[ -n "$FF_DIST_DIR" ]]; then
        sudo mkdir -p "$FF_DIST_DIR"
        if sudo cp "$FF_POLICY_SRC" "$FF_DIST_DIR/policies.json"; then
            ok "linked          $FF_DIST_DIR/policies.json"
            info "FoxyProxy + Wappalyzer install on next Firefox launch"
        else
            warn "could not write Firefox policy — install manually"
        fi
    else
        warn "Firefox not found — skipping extension policy"
    fi
fi

# ─── Default shell ─────────────────────────────────────────────────────
if [[ "${SHELL##*/}" != "zsh" ]] && command -v zsh >/dev/null; then
    warn "default shell is ${SHELL##*/} — run: chsh -s \$(command -v zsh)"
fi

echo
ok "done"
echo
echo "  Reload i3 with Super+Shift+R, or log out and back in."
echo
