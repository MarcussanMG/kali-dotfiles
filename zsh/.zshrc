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

# ─── Complete command flags from their --help / man ───────────────────
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

# ─── Per-machine overrides (optional) ──────────────────────────────────
# Copy zsh/local.conf.example to ~/.config/ng/local.conf to override these
# per machine without touching the tracked dotfiles.
[[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/ng/local.conf" ]] && \
    source "${XDG_CONFIG_HOME:-$HOME/.config}/ng/local.conf"
: "${NG_VPN_IF:=tun0}"
: "${NG_HASHCAT_OPTS:=-D 1}"

# VPN interface address, cached so the prompt never shells out more than
# once every 10 seconds.
typeset -g NG_TUN=""
typeset -g NG_TUN_AT=-99   # negative so the first prompt fetches immediately
ng_tun_ip() {
    # $SECONDS is a shell builtin — no module required.
    if (( SECONDS - NG_TUN_AT >= 10 )); then
        NG_TUN=$(ip -4 -brief address show "$NG_VPN_IF" 2>/dev/null | awk '{print $3}' | cut -d/ -f1)
        NG_TUN_AT=$SECONDS
    fi
    [[ -n "$NG_TUN" ]] && \
        print -n "%F{$NG_GREEN_DIM}─[%f%F{$NG_GREEN_HI}󰦝 ${NG_TUN}%f%F{$NG_GREEN_DIM}]%f"
}

# Current engagement target. Shows $T -- the target THIS shell will actually
# use in commands -- not the global file, so the prompt never disagrees with
# the value your commands expand. Each shell keeps its own $T.
ng_target() {
    [[ -n "$T" ]] && \
        print -n "%F{$NG_GREEN_DIM}─[%f%F{$NG_YELLOW} ${T}%f%F{$NG_GREEN_DIM}]%f"
}

# tun0 and physical-interface addresses, exposed as plain variables ($V, $E)
# the same way $T holds the current target. Refreshed at most once every
# 10 seconds, in precmd, so no shell subprocess runs on every keystroke.
typeset -g NG_ETH=""
typeset -g NG_ETH_AT=-99
ng_refresh_net_vars() {
    if (( SECONDS - NG_TUN_AT >= 10 )); then
        NG_TUN=$(ip -4 -brief address show "$NG_VPN_IF" 2>/dev/null | awk '{print $3}' | cut -d/ -f1)
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

# Pentesting notes (CherryTree) -- always resets to origin before opening,
# so anything typed inside CherryTree is disposable unless it's pushed
# to the notes repo from wherever you actually maintain it.
notes() {
    local NOTES_DIR="$HOME/.notes-repo"
    if [[ ! -d "$NOTES_DIR/.git" ]]; then
        print -P "%F{#f87171}%f notes repo not found -- sync-notes.sh runs on i3 start, or run it manually"
        return 1
    fi
    local CT_FILE
    CT_FILE="$(find "$NOTES_DIR" -maxdepth 1 \( -name '*.ctb' -o -name '*.ctd' \) | head -1)"
    if [[ -z "$CT_FILE" ]]; then
        print -P "%F{#f87171}%f no .ctb/.ctd file found in $NOTES_DIR"
        return 1
    fi
    cherrytree "$CT_FILE" &>/dev/null &
    disown
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
    # keep $T in sync with the shared target file so every tab shows (and
    # uses) the same target -- setting it in one tab updates them all next prompt
    local _tf="${XDG_CACHE_HOME:-$HOME/.cache}/oscp-target"
    if [[ -s "$_tf" ]]; then export T="${$(<$_tf)//[[:space:]]/}"; else unset T; fi
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

# fzf-tab: show completions in an fzf picker (searchable, nightgrid colours).
# Loads after compinit and BEFORE autosuggestions/syntax-highlighting. It only
# reshapes completions that already exist -- it is not a source of new ones.
# Installed by bootstrap.sh into $XDG_DATA_HOME/fzf-tab.
FZF_TAB_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/fzf-tab"
if [[ -f "$FZF_TAB_HOME/fzf-tab.plugin.zsh" ]]; then
    source "$FZF_TAB_HOME/fzf-tab.plugin.zsh"
    zstyle ':completion:*' menu no                 # hand the menu to fzf-tab
    zstyle ':fzf-tab:*' use-fzf-default-opts yes    # inherit the nightgrid palette
    zstyle ':fzf-tab:*' prefix ''
    zstyle ':fzf-tab:*' continuous-trigger '/'      # keep drilling into paths with /
    zstyle ':fzf-tab:complete:cd:*' fzf-preview \
        'eza -1 --color=always --icons $realpath 2>/dev/null || ls -1 $realpath'
fi

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
    alias tree='eza --tree --icons --level=20'
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

alias tools='cd ~/tools'

# ─── Engagement helpers ────────────────────────────────────────────────
alias tun='ip -4 -brief address show "$NG_VPN_IF"'

# BloodHound CE (Docker Compose) -- up / down / creds
BLOODHOUND_COMPOSE="$HOME/tools/ad-exploitation/bloodhound/docker-compose.yml"
bloodhound() {
    local dir="${BLOODHOUND_COMPOSE:h}"
    case "$1" in
        up)
            (cd "$dir" && docker compose up -d)
            print -P "%F{#86efac}Waiting for the admin password to appear in the logs...%f"
            local line="" tries=0
            while (( tries < 30 )); do
                line="$( (cd "$dir" && docker compose logs bloodhound 2>/dev/null) | grep -i "Initial Password Set To")"
                [[ -n "$line" ]] && break
                sleep 2
                (( tries++ ))
            done
            if [[ -n "$line" ]]; then
                print -P "%F{#4ade80}%f $line"
            else
                print -P "%F{#f87171}%f password not visible yet -- run 'bloodhound creds' once the container finishes starting"
            fi
            ;;
        down)
            (cd "$dir" && docker compose down)
            ;;
        creds)
            (cd "$dir" && docker compose logs bloodhound 2>/dev/null) \
                | grep -i "Initial Password Set To" \
                || print -P "%F{#f87171}%f no password in the logs -- BloodHound only prints this ONCE, when the admin account is first created. If you already set your own password, use that. If you're truly locked out, 'bloodhound reset' wipes the databases and gives you a fresh one (destroys all imported data)."
            ;;
        reset)
            print -P "%F{#f87171}%fThis destroys ALL BloodHound data (every imported host/edge/session) and generates a brand-new admin password."
            local confirm
            read "confirm?Type YES to continue: "
            if [[ "$confirm" == "YES" ]]; then
                (cd "$dir" && docker compose down -v)
                bloodhound up
            else
                print -P "%F{#86efac}%fCancelled, nothing was touched."
            fi
            ;;
        *)
            print -P "%F{#86efac}Usage:%f bloodhound up|down|creds|reset"
            ;;
    esac
}
alias myip='ip -4 -brief address show | grep -v " lo "'
alias ports='ss -tulpn'
alias serve='python3 -m http.server 80'

# ─── grc: colourise nmap & network tools ───────────────────────────────
# Only colourises on a TTY (--colour=auto), so piped/redirected output
# (nmap -oG, | tee, extractports) stays plain. The sudo alias lets the
# word after sudo be alias-expanded, so `sudo nmap` colourises too.
if command -v grc >/dev/null; then
    alias sudo='sudo '
    alias nmap='grc --colour=auto nmap'
    alias ping='grc --colour=auto ping'
    alias traceroute='grc --colour=auto traceroute'
    alias dig='grc --colour=auto dig'
fi

# grc wraps nmap/ping/dig/traceroute, so zsh would complete "grc" instead of
# the real tool. Skip grc and its flags and complete the wrapped command.
_grc() {
    shift words; (( CURRENT-- ))
    while [[ ${words[1]} == -* ]]; do shift words; (( CURRENT-- )); done
    _normal
}
compdef _grc grc

# ─── Universal option completion from --help / man ─────────────────────
# For ANY command without a richer completion of its own, read the program's
# own help -- trying --help, -h, -help, a `help` subcommand, then the man page
# -- and offer its flags WITH their descriptions. Handles sub-commands
# (`gobuster dir`, `nxc smb`, ...). Nothing is hardcoded: every option comes
# from the tool itself. Cached per command for the session. Non-flag words
# still complete hosts/files. Shown through fzf-tab like any other completion.
typeset -gA _help_opts_cache
_help_opts_awk() {
awk 'function emit(   j){ if(length(d)>70)d=substr(d,1,69) "…"
  for(j=1;j<=m;j++) print opt[j] ":" d; m=0 }
{ raw=$0
  if (raw ~ /^[[:space:]]*-/) { emit()
    line=raw; sub(/^[[:space:]]+/,"",line)
    sp=match(line,/  +/); co=index(line,": ")
    if (sp>0 && co>0) cut=(sp<co?sp:co); else if (sp>0) cut=sp; else if (co>0) cut=co; else cut=0
    if (cut>0){ spec=substr(line,1,cut-1); d=substr(line,cut); sub(/^[: ]+/,"",d) } else { spec=line; d="" }
    sub(/[[:space:]]+$/,"",spec); nw=split(spec,w,/[ ,]+/)
    for(i=1;i<=nw;i++){ tok=w[i]
      gsub(/<[^>]*>/,"",tok); gsub(/\[[^]]*\]/,"",tok); sub(/=.*/,"",tok); gsub(/[.:]/,"",tok)
      if(tok=="")continue; ns=split(tok,ss,"/"); pre=""
      for(s=1;s<=ns;s++){ o=ss[s]; if(o=="")continue
        if(o ~ /^--/){pre="--";key=o} else if(o ~ /^-/){pre="-";key=o} else if(pre!=""){key=pre o} else continue
        if(!(key in seen)){seen[key]=1;opt[++m]=key} } }
    next }
  if (m && raw ~ /^[[:space:]]{5,}[^[:space:]-]/){ s=raw; sub(/^[[:space:]]+/,"",s); d=d " " s; next }
  emit() }
END{ emit() }'
}
_help_opts() {
    [[ ${words[CURRENT]} == -* ]] || return 1
    local cmd=${words[1]}
    [[ -n ${commands[$cmd]} ]] || return 1
    local -a sub; local w
    for w in ${words[2,CURRENT-1]}; do
        [[ $w == [a-z][a-z-]# ]] || break
        sub+=$w
    done
    local key="$cmd ${(j: :)sub}"
    local -a opts
    if (( ${+_help_opts_cache[$key]} )); then
        opts=( ${(f)_help_opts_cache[$key]} )
    else
        local h try
        for try in '--help' '-h' '-help' 'help'; do
            h="$(timeout 3 "$cmd" ${sub} ${=try} 2>&1 </dev/null)"
            opts=( ${(f)"$(print -r -- "$h" | _help_opts_awk)"} )
            (( ${#opts} )) && break
        done
        if (( ! ${#opts} )) && (( ${+commands[man]} )); then
            opts=( ${(f)"$(man "$cmd" 2>/dev/null | col -b 2>/dev/null | _help_opts_awk)"} )
        fi
        _help_opts_cache[$key]=${(pj:\n:)opts}
    fi
    (( ${#opts} )) || return 1
    _describe -t options "${cmd} option" opts
}
# Hook zsh's _default so EVERY command with no specific completion uses it.
if (( ! ${+functions[_default_orig]} )); then
    autoload +X _default 2>/dev/null
    functions[_default_orig]=$functions[_default]
    _default() { _help_opts && return 0; _default_orig "$@" }
fi
# nmap ships a (stale) bundled completion, so _default won't fire -- force it,
# keeping host/file completion for the non-flag arguments.
_nmap_help() { _help_opts && return 0; _alternative 'hosts:host:_hosts' 'files:file:_files' }
compdef _nmap_help nmap

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
    mkdir -p "$root"/privesc/{windows,linux}
    [[ -f "$root/notes.md" ]] || printf '# %s\n\n## Enumeration\n\n## Foothold\n\n## Privilege escalation\n\n' "$1" > "$root/notes.md"
    cd "$root"
}

# ═══════════════════════════════════════════════════════════════════════
#  tmux — one independent tmux SERVER per Kitty window, no exceptions.
#  "-L kitty-$$" keys the socket to THIS shell's own PID, which is unique
#  per Kitty window launch -- true isolation regardless of workspace or
#  monitor (workspace-based detection broke with multiple monitors, since
#  i3 reports one focused workspace PER OUTPUT, not one globally).
#  Super+Enter always opens a brand new, empty session on its own server.
#  To recover an old session from any window, Super+Shift+Enter
#  (bin/tmux-attach-picker) scans every leftover socket.
# ═══════════════════════════════════════════════════════════════════════
if command -v tmux >/dev/null && [[ -z "$TMUX" ]] && [[ -n "$PS1" ]]; then
    tmux -L "kitty-$$" new-session
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

# clearcache [-y] -> wipe regenerable tool output + caches (penelope/nxc dumps,
# msf logs, pip/thumbnail/browser caches, Trash). NEVER touches ~/engagements,
# cracked creds (john.pot / potfiles), the nxc workspace DB, Burp, or your
# target. A built-in guard refuses anything that isn't strictly under $HOME.
# Add your own dirs in ~/.config/ng/local.conf:  NG_CACHE_EXTRA+=( ~/.foo )
typeset -ga NG_CACHE_DIRS=(
    "$HOME/.penelope/sessions"
    "$HOME/.nxc/logs"
    "$HOME/.nxc/modules"
    "$HOME/.msf4/logs"
    "$HOME/.cache/pip"
    "$HOME/.cache/thumbnails"
    "$HOME/.cache/mozilla"
    "$HOME/.cache/chromium"
    "$HOME/.local/share/Trash"
)
clearcache() {
    local -a all=( "${NG_CACHE_DIRS[@]}" "${NG_CACHE_EXTRA[@]}" )
    local -a present=()
    local d r
    for d in "${all[@]}"; do
        [[ -n "$d" ]] || continue
        r=${d:A}                               # absolutise / resolve
        [[ -e "$r" && "$r" == "$HOME"/?* ]] && present+=("$r")   # only under $HOME
    done
    present=(${(u)present})                     # dedupe
    if (( ! ${#present[@]} )); then
        print -P "%F{#4b5e54}clearcache: nothing to clean%f"; return 0
    fi
    print -P "%F{#fbbf24}clearcache%f will wipe the contents of:"
    for d in "${present[@]}"; do
        printf '  %s  \e[2;37m(%s)\e[0m\n' "${d/#$HOME/~}" "$(du -sh "$d" 2>/dev/null | cut -f1)"
    done
    if [[ "$1" != "-y" ]]; then
        print -n "Proceed? [y/N] "; local ans; read -r ans
        [[ "$ans" == [yY]* ]] || { print -P "%F{#4b5e54}aborted%f"; return 1 }
    fi
    for d in "${present[@]}"; do find "$d" -mindepth 1 -delete 2>/dev/null; done
    print -P "%F{#22c55e}[+] clearcache: done%f"
}

# Hashcat CPU backend for VMware
export RUSTICL_ENABLE=llvmpipe

hashcat() {
    command /usr/bin/hashcat ${=NG_HASHCAT_OPTS} "$@"
}
