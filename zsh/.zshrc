# ═══════════════════════════════════════════════════════════════════════
#  ~/.zshrc — Kali OSCP Workstation
#  Theme: nightgrid.  All previous keybindings are preserved verbatim.
# ═══════════════════════════════════════════════════════════════════════

# ─── Options ───────────────────────────────────────────────────────────
setopt autocd
setopt interactivecomments
setopt magicequalsubst
setopt nonomatch
setopt notify
setopt numericglobsort
setopt promptsubst

WORDCHARS='_-'
PROMPT_EOL_MARK=""

# ─── Keybindings ───────────────────────────────────────────────────────
bindkey -e                                        # emacs key bindings
bindkey ' ' magic-space                           # history expansion on space
bindkey '^U' backward-kill-line                   # ctrl + U
bindkey '^[[3;5~' kill-word                       # ctrl + Supr
bindkey '^[[3~' delete-char                       # delete
bindkey '^[[1;5C' forward-word                    # ctrl + ->
bindkey '^[[1;5D' backward-word                   # ctrl + <-
bindkey '^[[5~' beginning-of-buffer-or-history    # page up
bindkey '^[[6~' end-of-buffer-or-history          # page down
bindkey '^[[H' beginning-of-line                  # home
bindkey '^[[F' end-of-line                        # end
bindkey '^[[Z' undo                               # shift + tab

# ─── Completion ────────────────────────────────────────────────────────
autoload -Uz compinit
compinit -d ~/.cache/zcompdump

zstyle ':completion:*' menu select
zstyle ':completion:*' completer _expand _complete _ignored _approximate
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-compctl false
zstyle ':completion:*' verbose true
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list-prompt   '%S %p %s'
zstyle ':completion:*' select-prompt '%S %p %s'
zstyle ':completion:*:descriptions' format '%F{#166534}󰅂%f %F{#4b5e54}%d%f'
zstyle ':completion:*:messages'     format '%F{#fbbf24}󰋼%f %F{#4b5e54}%d%f'
zstyle ':completion:*:warnings'     format '%F{#f87171}󰀦%f %F{#4b5e54}no matches%f'
zstyle ':completion:*:corrections'  format '%F{#fbbf24}󰁨%f %F{#4b5e54}%d%f'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

# ─── History ───────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_verify
setopt hist_reduce_blanks
setopt share_history
setopt inc_append_history

alias history="history 0"

TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S\ncpu\t%P'

if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ═══════════════════════════════════════════════════════════════════════
#  Prompt — nightgrid
# ═══════════════════════════════════════════════════════════════════════

typeset -g NG_BG='#05070a'
typeset -g NG_GREEN='#22c55e'
typeset -g NG_GREEN_HI='#4ade80'
typeset -g NG_GREEN_DIM='#166534'
typeset -g NG_FG='#d1fae5'
typeset -g NG_FG_DIM='#86efac'
typeset -g NG_GRAY='#4b5e54'
typeset -g NG_RED='#f87171'
typeset -g NG_YELLOW='#fbbf24'

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' stagedstr   "%F{$NG_GREEN_HI}+%f"
zstyle ':vcs_info:git:*' unstagedstr "%F{$NG_YELLOW}!%f"
zstyle ':vcs_info:git:*' formats     "%F{$NG_GREEN_DIM}─[%f%F{$NG_FG_DIM}󰘬 %b%f%u%c%F{$NG_GREEN_DIM}]%f"
zstyle ':vcs_info:git:*' actionformats "%F{$NG_GREEN_DIM}─[%f%F{$NG_YELLOW}󰘬 %b|%a%f%F{$NG_GREEN_DIM}]%f"

# tun0 address, cached so the prompt never shells out more than once
# every 10 seconds.
typeset -g NG_TUN=""
typeset -g NG_TUN_AT=-99   # negative so the first prompt fetches immediately
ng_tun_ip() {
    # $SECONDS is a shell builtin — no module required.
    if (( SECONDS - NG_TUN_AT >= 10 )); then
        NG_TUN=$(ip -4 -brief address show tun0 2>/dev/null | awk '{print $3}' | cut -d/ -f1)
        NG_TUN_AT=$SECONDS
    fi
    [[ -n "$NG_TUN" ]] && \
        print -n "%F{$NG_GREEN_DIM}─[%f%F{$NG_GREEN_HI}󰦝 ${NG_TUN}%f%F{$NG_GREEN_DIM}]%f"
}

# Current engagement target, if one is set.
ng_target() {
    local f="${XDG_CACHE_HOME:-$HOME/.cache}/oscp-target"
    [[ -s "$f" ]] || return
    local t="${$(<$f)//[[:space:]]/}"
    [[ -n "$t" ]] && \
        print -n "%F{$NG_GREEN_DIM}─[%f%F{$NG_YELLOW} ${t}%f%F{$NG_GREEN_DIM}]%f"
}

# tun0 and physical-interface addresses, exposed as plain variables ($V, $E)
# the same way $T holds the current target. Refreshed at most once every
# 10 seconds, in precmd, so no shell subprocess runs on every keystroke.
typeset -g NG_ETH=""
typeset -g NG_ETH_AT=-99
ng_refresh_net_vars() {
    if (( SECONDS - NG_TUN_AT >= 10 )); then
        NG_TUN=$(ip -4 -brief address show tun0 2>/dev/null | awk '{print $3}' | cut -d/ -f1)
        NG_TUN_AT=$SECONDS
    fi
    export V="$NG_TUN"

    if (( SECONDS - NG_ETH_AT >= 10 )); then
        NG_ETH=$(ip -4 -brief address show up 2>/dev/null \
            | awk '$1 !~ /^(lo|tun|docker|br-|veth)/ && $3 != "" {print $3; exit}' \
            | cut -d/ -f1)
        NG_ETH_AT=$SECONDS
    fi
    export E="$NG_ETH"
}

configure_prompt() {
    local user_colour="%(#.$NG_RED.$NG_GREEN_HI)"
    local rail="%(#.$NG_RED.$NG_GREEN_DIM)"

    case "$PROMPT_ALTERNATIVE" in
        twoline)
            PROMPT='%F{'$rail'}┌─[%f'
            PROMPT+='%B%F{'$user_colour'}%n%f%F{'$NG_GREEN_DIM'}㉿%f%F{'$NG_FG_DIM'}%m%b%f'
            PROMPT+='%F{'$rail'}]%f'
            PROMPT+='%F{'$rail'}─[%f%B%F{'$NG_FG'}%(6~.%-1~/…/%4~.%5~)%b%f%F{'$rail'}]%f'
            PROMPT+='${vcs_info_msg_0_}$(ng_tun_ip)$(ng_target)'
            PROMPT+=$'\n%F{'$rail'}└─%f%B%(#.%F{'$NG_RED'}#.%F{'$NG_GREEN'}❯)%b%f '
            RPROMPT='%(?..%F{'$NG_RED'}󰅗 %?%f)%(1j. %F{'$NG_YELLOW'}󰑮 %j%f.)'
            ;;
        oneline)
            PROMPT='%B%F{'$user_colour'}%n%f%F{'$NG_GREEN_DIM'}@%f%F{'$NG_FG_DIM'}%m%b%f'
            PROMPT+='%F{'$NG_GREEN_DIM'}:%f%B%F{'$NG_FG'}%~%b%f'
            PROMPT+='%B%(#.%F{'$NG_RED'} #.%F{'$NG_GREEN'} ❯)%b%f '
            RPROMPT='%(?..%F{'$NG_RED'}%?%f)'
            ;;
        backtrack)
            PROMPT='%B%F{'$NG_RED'}%n@%m%b%f:%B%F{'$NG_FG'}%~%b%f%(#.#.$) '
            RPROMPT=
            ;;
    esac
}

# START KALI CONFIG VARIABLES
PROMPT_ALTERNATIVE=twoline
NEWLINE_BEFORE_PROMPT=yes
# STOP KALI CONFIG VARIABLES

VIRTUAL_ENV_DISABLE_PROMPT=1
configure_prompt

toggle_oneline_prompt() {
    if [ "$PROMPT_ALTERNATIVE" = oneline ]; then
        PROMPT_ALTERNATIVE=twoline
    else
        PROMPT_ALTERNATIVE=oneline
    fi
    configure_prompt
    zle reset-prompt
}
zle -N toggle_oneline_prompt
bindkey ^P toggle_oneline_prompt

case "$TERM" in
xterm*|rxvt*|Eterm|aterm|kterm|gnome*|alacritty|xterm-kitty)
    TERM_TITLE=$'\e]0;${debian_chroot:+($debian_chroot)}${VIRTUAL_ENV:+($(basename $VIRTUAL_ENV))}%n@%m: %~\a'
    ;;
*)
    TERM_TITLE=''
    ;;
esac

typeset -g NG_TAB_LOCKED=0

precmd() {
    vcs_info
    ng_refresh_net_vars
    (( NG_TAB_LOCKED )) || print -Pnr -- "$TERM_TITLE"
    if [ "$NEWLINE_BEFORE_PROMPT" = yes ]; then
        if [ -z "$_NEW_LINE_BEFORE_PROMPT" ]; then
            _NEW_LINE_BEFORE_PROMPT=1
        else
            print ""
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════
#  Colours
# ═══════════════════════════════════════════════════════════════════════

if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    export LS_COLORS="$LS_COLORS:ow=30;42:di=1;32:ln=1;36:ex=1;92"
    zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
fi

export LESS_TERMCAP_mb=$'\E[1;32m'
export LESS_TERMCAP_md=$'\E[1;92m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;30;42m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_us=$'\E[1;36m'
export LESS_TERMCAP_ue=$'\E[0m'
export MANROFFOPT="-c"
export LESS="-R"

# batcat follows the terminal palette instead of shipping its own.
export BAT_THEME="ansi"
export BAT_STYLE="header,numbers,grid"

# ═══════════════════════════════════════════════════════════════════════
#  Plugins
# ═══════════════════════════════════════════════════════════════════════

[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#4b5e54'

if [[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)
    ZSH_HIGHLIGHT_STYLES[default]=none
    ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#f87171,bold'
    ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#34d399,bold'
    ZSH_HIGHLIGHT_STYLES[alias]='fg=#4ade80'
    ZSH_HIGHLIGHT_STYLES[suffix-alias]='fg=#4ade80,underline'
    ZSH_HIGHLIGHT_STYLES[global-alias]='fg=#4ade80,bold'
    ZSH_HIGHLIGHT_STYLES[builtin]='fg=#22c55e'
    ZSH_HIGHLIGHT_STYLES[function]='fg=#22c55e,bold'
    ZSH_HIGHLIGHT_STYLES[command]='fg=#22c55e'
    ZSH_HIGHLIGHT_STYLES[precommand]='fg=#22c55e,underline'
    ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=#166534,bold'
    ZSH_HIGHLIGHT_STYLES[autodirectory]='fg=#4ade80,underline'
    ZSH_HIGHLIGHT_STYLES[path]='fg=#d1fae5'
    ZSH_HIGHLIGHT_STYLES[path_pathseparator]='fg=#4b5e54'
    ZSH_HIGHLIGHT_STYLES[globbing]='fg=#60a5fa'
    ZSH_HIGHLIGHT_STYLES[history-expansion]='fg=#60a5fa,bold'
    ZSH_HIGHLIGHT_STYLES[single-hyphen-option]='fg=#86efac'
    ZSH_HIGHLIGHT_STYLES[double-hyphen-option]='fg=#86efac'
    ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#fbbf24'
    ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#fbbf24'
    ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#fbbf24'
    ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=#c4b5fd'
    ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=#c4b5fd'
    ZSH_HIGHLIGHT_STYLES[command-substitution-delimiter]='fg=#c4b5fd,bold'
    ZSH_HIGHLIGHT_STYLES[redirection]='fg=#60a5fa,bold'
    ZSH_HIGHLIGHT_STYLES[comment]='fg=#4b5e54'
    ZSH_HIGHLIGHT_STYLES[bracket-error]='fg=#f87171,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-1]='fg=#22c55e,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-2]='fg=#34d399,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-3]='fg=#60a5fa,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=#fbbf24,bold'
    ZSH_HIGHLIGHT_STYLES[bracket-level-5]='fg=#c4b5fd,bold'
    ZSH_HIGHLIGHT_STYLES[cursor-matchingbracket]=standout
fi

[[ -f /etc/zsh_command_not_found ]] && source /etc/zsh_command_not_found

# ═══════════════════════════════════════════════════════════════════════
#  fzf — Ctrl+R unchanged, nightgrid colours
# ═══════════════════════════════════════════════════════════════════════

export FZF_DEFAULT_OPTS="
  --height 45% --layout=reverse --border=rounded --info=inline
  --prompt='  ' --pointer='▌' --marker='󰄲 '
  --color=bg+:#0d1410,bg:-1,spinner:#22c55e,hl:#4ade80
  --color=fg:#86efac,header:#166534,info:#4b5e54,pointer:#22c55e
  --color=marker:#fbbf24,fg+:#d1fae5,prompt:#22c55e,hl+:#4ade80
  --color=border:#166534
"

[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && \
    source /usr/share/doc/fzf/examples/key-bindings.zsh
[[ -f /usr/share/doc/fzf/examples/completion.zsh ]] && \
    source /usr/share/doc/fzf/examples/completion.zsh

# ─── zoxide ────────────────────────────────────────────────────────────
command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# ═══════════════════════════════════════════════════════════════════════
#  Aliases
# ═══════════════════════════════════════════════════════════════════════

if command -v eza >/dev/null; then
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lah --icons --group-directories-first --git'
    alias la='eza -a --icons --group-directories-first'
    alias tree='eza --tree --icons --level=2'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah --color=auto'
    alias la='ls -A --color=auto'
fi

alias l='ls -CF'
alias cat='batcat --paging=never'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias diff='diff --color=auto'
alias ip='ip --color=auto'

alias cls='clear'
alias c='clear'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ─── Engagement helpers ────────────────────────────────────────────────
alias tun='ip -4 -brief address show tun0'

# BloodHound CE (Docker Compose) -- up / down / creds
BLOODHOUND_COMPOSE="$HOME/tools/ad-exploitation/bloodhound/docker-compose.yml"
bloodhound() {
    case "$1" in
        up)
            docker compose -f "$BLOODHOUND_COMPOSE" up -d
            ;;
        down)
            docker compose -f "$BLOODHOUND_COMPOSE" down
            ;;
        creds)
            docker compose -f "$BLOODHOUND_COMPOSE" logs bloodhound 2>/dev/null \
                | grep -i "Initial Password Set To" \
                || print -P "%F{#f87171}%f no password line found -- container may still be starting, or the password was already rotated"
            ;;
        *)
            print -P "%F{#86efac}Usage:%f bloodhound up|down|creds"
            ;;
    esac
}
alias myip='ip -4 -brief address show | grep -v " lo "'
alias ports='ss -tulpn'
alias serve='python3 -m http.server 80'

# target            → print the current target
# target 10.10.11.5 → set it, export $T, refresh the i3 bar
target() {
    local f="${XDG_CACHE_HOME:-$HOME/.cache}/oscp-target"
    if [[ -z "$1" ]]; then
        [[ -s "$f" ]] && cat "$f" || echo "no target set"
        return
    fi
    mkdir -p "${f:h}"
    print -r -- "$1" > "$f"
    export T="$1"
    pkill -RTMIN+11 i3blocks 2>/dev/null
    print -P "%F{#22c55e}%f target set to %F{#fbbf24}$1%f  (\$T)"
}
[[ -s "${XDG_CACHE_HOME:-$HOME/.cache}/oscp-target" ]] && \
    export T="$(<${XDG_CACHE_HOME:-$HOME/.cache}/oscp-target)"

# mkt box → scaffold ~/engagements/box/{nmap,web,loot,exploits,notes.md}
mkt() {
    local root="$HOME/engagements/${1:?usage: mkt <name>}"
    mkdir -p "$root"/{nmap,web,loot,exploits}
    [[ -f "$root/notes.md" ]] || printf '# %s\n\n## Enumeration\n\n## Foothold\n\n## Privilege escalation\n\n' "$1" > "$root/notes.md"
    cd "$root"
}

# ═══════════════════════════════════════════════════════════════════════
#  tmux — attach to the persistent session
# ═══════════════════════════════════════════════════════════════════════
#  tmux — attach to the persistent session, or spin up an independent one
#  if "main" is already in use by another window
if command -v tmux >/dev/null && [[ -z "$TMUX" ]] && [[ -n "$PS1" ]]; then
    if tmux has-session -t main 2>/dev/null; then
        if [[ -z "$(tmux list-clients -t main 2>/dev/null)" ]]; then
            tmux attach-session -t main
        else
            tmux new-session
        fi
    else
        tmux new-session -s main
    fi
fi

# tabname Nmap → renombra la pestaña y evita que el prompt lo sobreescriba
# tabname (sin argumento) → vuelve al título automático
tabname() {
    if [[ -z "$1" ]]; then
        NG_TAB_LOCKED=0
        return
    fi
    print -n "\e]0;${1}\a"
    NG_TAB_LOCKED=1
}

# cleartarget → clears the current target and refreshes i3blocks
cleartarget() {
    local f="${XDG_CACHE_HOME:-$HOME/.cache}/oscp-target"
    rm -f "$f"
    unset T
    pkill -RTMIN+11 i3blocks 2>/dev/null
    print -P "%F{#f87171}%f target cleared"
}

# extractports <file.gnmap|.oG> → pulls open ports and copies them to clipboard
extractports() {
    local f="${1:?usage: extractports <file.gnmap|.oG>}"
    [[ -f "$f" ]] || { print -P "%F{#f87171}%f file not found: $f"; return 1 }

    local ports
    ports=$(grep -oP '(?<=Ports: ).*?(?=\tIgnored|$)' "$f" \
        | tr ',' '\n' \
        | awk -F'/' '{gsub(/^[ \t]+|[ \t]+$/,"",$1); if ($2=="open") print $1}' \
        | sort -n -u \
        | paste -sd, -)

    if [[ -z "$ports" ]]; then
        print -P "%F{#f87171}%f no open ports found in $f"
        return 1
    fi

    print -P "%F{#22c55e}[+] Open Ports:%f"
    print -r -- "      $ports"

    if command -v xclip >/dev/null; then
        print -rn -- "$ports" | xclip -selection clipboard
        print -P "%F{#4b5e54}(copied to clipboard)%f"
    elif command -v xsel >/dev/null; then
        print -rn -- "$ports" | xsel --clipboard --input
        print -P "%F{#4b5e54}(copied to clipboard)%f"
    else
        print -P "%F{#fbbf24}xclip/xsel not installed, nothing was copied%f"
    fi
}

# Hashcat CPU backend for VMware
export RUSTICL_ENABLE=llvmpipe

hashcat() {
    command /usr/bin/hashcat -D 1 "$@"
}
