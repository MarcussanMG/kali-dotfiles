#!/usr/bin/env bash
# Renders every tmux session as a colored box, bright green for the one
# this status line belongs to, dark for the rest -- same visual language
# as window-status-format/current-format.
set -uo pipefail

current="${1:-}"
out=""

while IFS= read -r sess; do
    if [[ "$sess" == "$current" ]]; then
        out+="#[fg=#0a0f0c,bg=#22c55e,bold] ${sess} #[fg=#22c55e,bg=#05070a]"
    else
        out+="#[fg=#0a0f0c,bg=#1a2e22] ${sess} #[fg=#1a2e22,bg=#05070a]"
    fi
done < <(tmux list-sessions -F "#{session_name}" 2>/dev/null)

printf '%s' "$out"
