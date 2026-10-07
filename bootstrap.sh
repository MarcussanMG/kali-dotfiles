#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  bootstrap.sh — install every dependency, then link the configuration.
#  Safe to re-run.
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN=$'\e[1;32m'; DIM=$'\e[2;37m'; RESET=$'\e[0m'
# Overall-progress phase header: a solid nightgrid bar + [n/total] across the
# whole install. STEP_TOTAL is set once the selected components are known.
STEP_N=0
step() {
    STEP_N=$(( STEP_N + 1 ))
    local total=${STEP_TOTAL:-$STEP_N} width=28 pct filled fbar ebar
    (( total < STEP_N )) && total=$STEP_N
    pct=$(( STEP_N * 100 / total )); (( pct > 100 )) && pct=100
    filled=$(( STEP_N * width / total )); (( filled > width )) && filled=$width
    fbar="$(printf '%*s' "$filled" '' | tr ' ' '#')"; fbar="${fbar//#/█}"
    ebar="$(printf '%*s' "$(( width - filled ))" '' | tr ' ' '-')"; ebar="${ebar//-/░}"
    printf '\n%s▸ %s%s%s%s %3d%%  %s[%d/%d]%s %s%s%s\n' \
        "$GREEN" "$fbar" "$DIM" "$ebar" "$RESET" "$pct" \
        "$DIM" "$STEP_N" "$total" "$RESET" "$GREEN" "$1" "$RESET"
}
# Plain header for non-phase notices (reports, final message) -- no bar/count.
header() { printf '\n%s▸ %s%s\n' "$GREEN" "$1" "$RESET"; }
info() { printf '%s  %s%s\n' "$DIM" "$1" "$RESET"; }

# progress_bar <current> <total> <label> -- redraws a bar in place on a TTY.
# Callers should only use it when stdout is a terminal ([[ -t 1 ]]); when piped
# (e.g. | tee) they should print plain per-item lines instead so the log stays clean.
progress_bar() {
    local cur=$1 total=$2 label=${3:-} width=28 pct filled
    if (( total > 0 )); then pct=$(( cur * 100 / total )); filled=$(( cur * width / total ))
    else pct=100; filled=$width; fi
    local fbar ebar
    fbar="$(printf '%*s' "$filled" '' | tr ' ' '#')"
    ebar="$(printf '%*s' "$(( width - filled ))" '' | tr ' ' '-')"
    fbar="${fbar//#/█}"; ebar="${ebar//-/░}"
    printf '\r  %s%s%s%s%s %3d%%  (%d/%d) %-22.22s' \
        "$GREEN" "$fbar" "$DIM" "$ebar" "$RESET" "$pct" "$cur" "$total" "$label"
}

[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root." >&2; exit 1; }

# ── Component selection ────────────────────────────────────────────────
# All optional components default ON (a plain ./bootstrap.sh installs
# everything). The Custom installer menu flips these before packages build.
OPT_ARSENAL=1     # /tools pentest arsenal + offensive apt packages
OPT_SECLISTS=1    # SecLists wordlists (large)
OPT_NOTES=1       # CherryTree notes sync + the cherrytree app
OPT_POSTMAN=1     # Postman
OPT_NVIM=1        # Neovim config (nightgrid.nvim)

# Core packages: the desktop + shell that make this environment usable. A
# failure in one of these is CRITICAL -- the workstation won't work without it.
PKG_CORE=(
    # ── Window manager and desktop ──
    i3 i3lock i3blocks suckless-tools dex
    picom feh rofi lxappearance
    network-manager-gnome dunst libnotify-bin
    python3-i3ipc
    # ── Terminal ──
    kitty tmux zsh
    zsh-autosuggestions zsh-syntax-highlighting
    # ── Shell tooling ──
    bat eza fd-find ripgrep fzf zoxide btop
    # ── X utilities ──
    x11-utils xclip maim imagemagick xss-lock libnss3-tools
    # ── Fonts and icons ──
    fonts-font-awesome papirus-icon-theme
    # ── VMware guest integration ──
    open-vm-tools open-vm-tools-desktop
    # ── Base (whiptail powers the Custom installer menu) ──
    git curl wget unzip whiptail grc python3-rich
)
# Optional package groups, added to the install list only when enabled.
PKG_ARSENAL=( rlwrap peass powersploit mimikatz sharphound chisel ncat-w32 webshells mitm6 coercer penelope pocl-opencl-icd clinfo )
PKG_SECLISTS=( seclists )
PKG_NOTES=( cherrytree )

# ── Installer mode: Full or Custom ─────────────────────────────────────
# A plain run (or no TTY / no whiptail) installs everything. "Custom" shows a
# checklist: arrows to move, SPACE to toggle, ENTER to confirm.
if [[ -t 0 ]] && command -v whiptail >/dev/null; then
    # nightgrid palette for the newt/whiptail dialogs (green on dark)
    export NEWT_COLORS='
root=,black
window=green,black
border=brightgreen,black
shadow=,black
title=brightgreen,black
button=black,green
actbutton=black,brightgreen
compactbutton=brightgreen,black
checkbox=green,black
actcheckbox=black,brightgreen
entry=brightgreen,black
label=brightgreen,black
listbox=green,black
actlistbox=black,green
sellistbox=brightgreen,black
actsellistbox=black,brightgreen
textbox=green,black
acttextbox=black,green
helpline=green,black
roottext=brightgreen,black
emptyscale=,black
fullscale=,green
'
    _mode=$(whiptail --title "kali-dotfiles installer" --menu \
        "The desktop + shell (core) is always installed. Choose how to proceed:" \
        14 72 2 \
        "full"   "Install everything (core + all optional tools)" \
        "custom" "Choose which optional components to install" \
        3>&1 1>&2 2>&3) || _mode="full"
    if [[ "$_mode" == "custom" ]]; then
        _sel=$(whiptail --title "Optional components" --checklist \
            "SPACE toggles, ENTER confirms. Unchecked components are skipped." \
            16 74 5 \
            "arsenal"  "Pentest arsenal (/tools: recon, privesc, AD, exploits)" ON \
            "seclists" "SecLists wordlists (large download)"                    ON \
            "notes"    "CherryTree notes sync + cherrytree app"                 ON \
            "postman"  "Postman"                                                ON \
            "nvim"     "Neovim config (nightgrid.nvim: LSP, Telescope, theme)"  ON \
            3>&1 1>&2 2>&3) || _sel='arsenal seclists notes postman nvim'
        OPT_ARSENAL=0; OPT_SECLISTS=0; OPT_NOTES=0; OPT_POSTMAN=0; OPT_NVIM=0
        [[ "$_sel" == *arsenal*  ]] && OPT_ARSENAL=1
        [[ "$_sel" == *seclists* ]] && OPT_SECLISTS=1
        [[ "$_sel" == *notes*    ]] && OPT_NOTES=1
        [[ "$_sel" == *postman*  ]] && OPT_POSTMAN=1
        [[ "$_sel" == *nvim*     ]] && OPT_NVIM=1
    fi
fi
info "components -> arsenal:$OPT_ARSENAL seclists:$OPT_SECLISTS notes:$OPT_NOTES postman:$OPT_POSTMAN nvim:$OPT_NVIM"
# 5 always-on phases (apt update, packages, font, fzf-tab, linking) + selected optionals.
STEP_TOTAL=$(( 5 + OPT_ARSENAL + OPT_NOTES + OPT_POSTMAN + OPT_NVIM ))

PACKAGES=( "${PKG_CORE[@]}" )
(( OPT_ARSENAL ))  && PACKAGES+=( "${PKG_ARSENAL[@]}" )
(( OPT_SECLISTS )) && PACKAGES+=( "${PKG_SECLISTS[@]}" )
(( OPT_NOTES ))    && PACKAGES+=( "${PKG_NOTES[@]}" )

step "Updating package lists"
sudo apt-get update

step "Installing packages"
# Installed one at a time so a single unavailable package cannot abort the run.
# On a terminal, show a single in-place progress bar; when piped (| tee), fall
# back to one plain line per package so the log stays readable.
missing=()
missing_core=()
pkg_total=${#PACKAGES[@]}
pkg_i=0
for pkg in "${PACKAGES[@]}"; do
    pkg_i=$(( pkg_i + 1 ))
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        status="already present"
    elif sudo apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1; then
        status="installed"
    elif [[ " ${PKG_CORE[*]} " == *" $pkg "* ]]; then
        missing_core+=("$pkg"); status="UNAVAILABLE"
    else
        missing+=("$pkg"); status="UNAVAILABLE"
    fi
    if [[ -t 1 ]]; then
        progress_bar "$pkg_i" "$pkg_total" "$pkg"
    else
        printf '  %-15s %s\n' "$status" "$pkg"
    fi
done
# close the progress-bar line (it ends in \r without a newline)
[[ -t 1 ]] && printf '\n'

step "Installing JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
# already installed if the font dir exists and is non-empty (covers .ttf/.otf/
# any layout), or fontconfig already knows the family.
if [[ -d "$FONT_DIR/JetBrainsMono" && -n "$(ls -A "$FONT_DIR/JetBrainsMono" 2>/dev/null)" ]] \
    || fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    info "already present"
else
    mkdir -p "$FONT_DIR"
    tmp="$(mktemp -d)"
    url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    # ~30 MB zip with many variants -- show it's working (progress bar on a TTY,
    # silent when piped) so the step doesn't look frozen on first run.
    info "downloading (~30 MB, may take a minute)..."
    if { [[ -t 1 ]] && curl -#fL "$url" -o "$tmp/JetBrainsMono.zip"; } \
        || { [[ ! -t 1 ]] && curl -fsSL "$url" -o "$tmp/JetBrainsMono.zip"; }; then
        info "extracting and refreshing the font cache..."
        unzip -qo "$tmp/JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono" \
            -x "*.txt" "*.md" "LICENSE*"
        fc-cache -f "$FONT_DIR" >/dev/null
        printf '  installed       JetBrainsMono Nerd Font\n'
    else
        info "download failed — install it manually from nerdfonts.com"
    fi
    rm -rf "$tmp"
fi

step "Installing fzf-tab (fzf completion menu)"
# Searchable fzf picker for tab-completion. Not in the Kali repos; clone it.
# Non-fatal: the shell works fine without it.
FZF_TAB_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fzf-tab"
if [[ -d "$FZF_TAB_DIR/.git" ]]; then
    git -C "$FZF_TAB_DIR" pull --quiet --ff-only 2>/dev/null \
        && info "updated          fzf-tab" || info "fzf-tab already present"
elif git clone --quiet --depth 1 https://github.com/Aloxaf/fzf-tab.git "$FZF_TAB_DIR" 2>/dev/null; then
    info "installed        fzf-tab"
else
    info "UNAVAILABLE      fzf-tab (clone failed)"
fi

step "Linking configuration"

if (( OPT_ARSENAL )); then
step "Building /tools/ arsenal"
TOOLS="$HOME/tools"
mkdir -p "$TOOLS"/{recon,ad-exploitation,shells-payloads,tunneling-pivoting}
# privesc tooling lives under privesc/{windows,linux}; drop the old top-level
# windows-privesc/linux-privesc dirs left by earlier bootstrap runs (only if empty)
rmdir "$TOOLS/windows-privesc" "$TOOLS/linux-privesc" 2>/dev/null || true

# -- recon --
if [[ ! -x "$TOOLS/recon/kerbrute" ]]; then
    if curl -fsSL "https://github.com/ropnop/kerbrute/releases/latest/download/kerbrute_linux_amd64" \
        -o "$TOOLS/recon/kerbrute"; then
        chmod +x "$TOOLS/recon/kerbrute"
        info "downloaded       kerbrute"
    else
        info "UNAVAILABLE      kerbrute (download failed)"
        missing+=("kerbrute")
    fi
else
    info "already present  kerbrute"
fi

# -- windows-privesc (winpeas/powerup/privesccheck from apt where possible) --
mkdir -p "$TOOLS/privesc/windows/winpeas"
if [[ -d /usr/share/peass/winpeas ]]; then
    ln -sf /usr/share/peass/winpeas/winPEAS.bat     "$TOOLS/privesc/windows/winpeas/WinPEAS.bat"
    ln -sf /usr/share/peass/winpeas/winPEASx64.exe  "$TOOLS/privesc/windows/winpeas/WinPEASx64.exe"
    ln -sf /usr/share/peass/winpeas/winPEASx86.exe  "$TOOLS/privesc/windows/winpeas/WinPEASx86.exe"
    info "linked           WinPEAS (bat, x64, x86) from apt package peass"
else
    info "UNAVAILABLE      peass not installed -- winpeas skipped"
fi

if [[ -f /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 ]]; then
    ln -sf /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 "$TOOLS/privesc/windows/PowerUp.ps1"
    info "linked           PowerUp.ps1 from apt package powersploit"
else
    info "UNAVAILABLE      powersploit not installed -- PowerUp.ps1 skipped"
fi

if [[ ! -f "$TOOLS/privesc/windows/PrivescCheck.ps1" ]]; then
    curl -fsSL "https://github.com/itm4n/PrivescCheck/releases/latest/download/PrivescCheck.ps1" \
        -o "$TOOLS/privesc/windows/PrivescCheck.ps1" \
        && info "downloaded       PrivescCheck.ps1" \
        || { info "UNAVAILABLE      PrivescCheck.ps1"; missing+=("PrivescCheck.ps1"); }
else
    info "already present  PrivescCheck.ps1"
fi

if [[ -d /usr/share/windows-resources/ncat ]]; then
    ln -sf /usr/share/windows-resources/ncat/ncat.exe "$TOOLS/shells-payloads/ncat.exe"
    info "linked           ncat.exe from apt package ncat-w32 (used in place of unsigned nc.exe mirrors)"
else
    info "UNAVAILABLE      ncat-w32 not installed"
fi

mkdir -p "$TOOLS/privesc/windows/accesschk"
if [[ ! -f "$TOOLS/privesc/windows/accesschk/accesschk64.exe" ]]; then
    TMPZIP="$(mktemp --suffix=.zip)"
    if curl -fsSL "https://download.sysinternals.com/files/AccessChk.zip" -o "$TMPZIP"; then
        unzip -oq "$TMPZIP" -d "$TOOLS/privesc/windows/accesschk-tmp"
        mv "$TOOLS/privesc/windows/accesschk-tmp"/*.exe "$TOOLS/privesc/windows/accesschk/" 2>/dev/null
        rm -rf "$TOOLS/privesc/windows/accesschk-tmp" "$TMPZIP"
        info "downloaded       accesschk (official Sysinternals)"
    else
        info "UNAVAILABLE      accesschk"
        missing+=("accesschk")
    fi
else
    info "already present  accesschk"
fi

# PsExec64 (Sysinternals) -- remote execution / lateral movement. Only that
# one binary is pulled out of the official PSTools.zip, into ad-exploitation/lateral-movement.
mkdir -p "$TOOLS/ad-exploitation/lateral-movement"
if [[ ! -f "$TOOLS/ad-exploitation/lateral-movement/PsExec64.exe" ]]; then
    TMPZIP="$(mktemp --suffix=.zip)"
    if curl -fsSL "https://download.sysinternals.com/files/PSTools.zip" -o "$TMPZIP"; then
        unzip -oqj "$TMPZIP" "PsExec64.exe" -d "$TOOLS/ad-exploitation/lateral-movement" 2>/dev/null
        rm -f "$TMPZIP"
        if [[ -f "$TOOLS/ad-exploitation/lateral-movement/PsExec64.exe" ]]; then
            info "downloaded       PsExec64.exe (official Sysinternals)"
        else
            info "UNAVAILABLE      PsExec64.exe"; missing+=("PsExec64")
        fi
    else
        info "UNAVAILABLE      PsExec64.exe"; missing+=("PsExec64")
    fi
else
    info "already present  PsExec64.exe"
fi

mkdir -p "$TOOLS/privesc/windows/ghostpack"
for bin in Rubeus.exe SharpUp.exe Seatbelt.exe; do
    if [[ ! -f "$TOOLS/privesc/windows/ghostpack/$bin" ]]; then
        curl -fsSL "https://raw.githubusercontent.com/r3motecontrol/Ghostpack-CompiledBinaries/master/$bin" \
            -o "$TOOLS/privesc/windows/ghostpack/$bin" \
            && info "downloaded       $bin (community-compiled -- GhostPack is source-only upstream)" \
            || { info "UNAVAILABLE      $bin"; missing+=("$bin"); }
    else
        info "already present  $bin"
    fi
done

# -- potato attacks (SeImpersonatePrivilege -> SYSTEM) --
mkdir -p "$TOOLS/privesc/windows/potatoes"
declare -A POTATO_URLS=(
    ["PrintSpoofer32.exe"]="https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer32.exe"
    ["PrintSpoofer64.exe"]="https://github.com/itm4n/PrintSpoofer/releases/latest/download/PrintSpoofer64.exe"
    ["GodPotato-NET2.exe"]="https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET2.exe"
    ["GodPotato-NET35.exe"]="https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET35.exe"
    ["GodPotato-NET4.exe"]="https://github.com/BeichenDream/GodPotato/releases/latest/download/GodPotato-NET4.exe"
    ["JuicyPotato.exe"]="https://github.com/ohpe/juicy-potato/releases/latest/download/JuicyPotato.exe"
)
for name in "${!POTATO_URLS[@]}"; do
    if [[ ! -f "$TOOLS/privesc/windows/potatoes/$name" ]]; then
        curl -fsSL "${POTATO_URLS[$name]}" -o "$TOOLS/privesc/windows/potatoes/$name" \
            && info "downloaded       $name" \
            || { info "UNAVAILABLE      $name"; missing+=("$name"); }
    else
        info "already present  $name"
    fi
done

# RoguePotato ships as a zip (RoguePotato.exe + its RogueOxidResolver.exe helper)
if [[ ! -f "$TOOLS/privesc/windows/potatoes/RoguePotato.exe" ]]; then
    RP_ZIP="$(mktemp --suffix=.zip)"
    if curl -fsSL "https://github.com/antonioCoco/RoguePotato/releases/download/1.0/RoguePotato.zip" -o "$RP_ZIP" \
        && unzip -oq "$RP_ZIP" -d "$TOOLS/privesc/windows/potatoes"; then
        info "downloaded       RoguePotato.exe + RogueOxidResolver.exe"
    else
        info "UNAVAILABLE      RoguePotato"; missing+=("RoguePotato")
    fi
    rm -f "$RP_ZIP"
else
    info "already present  RoguePotato.exe"
fi

# -- wesng: Windows Exploit Suggester NG (feed it the target's systeminfo output) --
# single script; run 'python3 wes.py --update' once to fetch the CVE database
if [[ ! -f "$TOOLS/privesc/windows/wes.py" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/bitsadmin/wesng/master/wes.py" \
        -o "$TOOLS/privesc/windows/wes.py" && chmod +x "$TOOLS/privesc/windows/wes.py" \
        && info "downloaded       wes.py (run 'python3 wes.py --update' once to build its DB)" \
        || { info "UNAVAILABLE      wes.py"; missing+=("wes.py"); }
else
    info "already present  wes.py"
fi

# -- linux-privesc (linpeas from apt, lse.sh + les.sh from source) --
mkdir -p "$TOOLS/privesc/linux"
if [[ -d /usr/share/peass/linpeas ]]; then
    ln -sf /usr/share/peass/linpeas/linpeas.sh "$TOOLS/privesc/linux/linpeas.sh"
    info "linked           linpeas.sh from apt package peass"
else
    info "UNAVAILABLE      peass not installed -- linpeas skipped"
fi

if [[ ! -f "$TOOLS/privesc/linux/lse.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" \
        -o "$TOOLS/privesc/linux/lse.sh" && chmod +x "$TOOLS/privesc/linux/lse.sh" \
        && info "downloaded       lse.sh" \
        || { info "UNAVAILABLE      lse.sh"; missing+=("lse.sh"); }
else
    info "already present  lse.sh"
fi

if [[ ! -f "$TOOLS/privesc/linux/linux-exploit-suggester.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
        -o "$TOOLS/privesc/linux/linux-exploit-suggester.sh" && chmod +x "$TOOLS/privesc/linux/linux-exploit-suggester.sh" \
        && info "downloaded       linux-exploit-suggester.sh" \
        || { info "UNAVAILABLE      linux-exploit-suggester.sh"; missing+=("linux-exploit-suggester.sh"); }
else
    info "already present  linux-exploit-suggester.sh"
fi

if [[ ! -f "$TOOLS/privesc/linux/LinEnum.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/rebootuser/LinEnum/master/LinEnum.sh" \
        -o "$TOOLS/privesc/linux/LinEnum.sh" && chmod +x "$TOOLS/privesc/linux/LinEnum.sh" \
        && info "downloaded       LinEnum.sh" \
        || { info "UNAVAILABLE      LinEnum.sh"; missing+=("LinEnum.sh"); }
else
    info "already present  LinEnum.sh"
fi

if command -v unix-privesc-check >/dev/null; then
    ln -sf "$(command -v unix-privesc-check)" "$TOOLS/privesc/linux/unix-privesc-check"
    info "linked           unix-privesc-check (already installed on Kali)"
else
    info "UNAVAILABLE      unix-privesc-check not found on this system"
fi

# pspy: watch processes/cron as an unprivileged user (32- and 64-bit target builds)
for arch in 64 32; do
    if [[ ! -f "$TOOLS/privesc/linux/pspy$arch" ]]; then
        curl -fsSL "https://github.com/DominicBreuker/pspy/releases/latest/download/pspy$arch" \
            -o "$TOOLS/privesc/linux/pspy$arch" && chmod +x "$TOOLS/privesc/linux/pspy$arch" \
            && info "downloaded       pspy$arch" \
            || { info "UNAVAILABLE      pspy$arch"; missing+=("pspy$arch"); }
    else
        info "already present  pspy$arch"
    fi
done

# -- ad-exploitation, organized by attack phase --
mkdir -p "$TOOLS/ad-exploitation"/{kerberos,lateral-movement,credential-dumping,enumeration,bloodhound/ingestors}

for bin in impacket-GetNPUsers impacket-GetUserSPNs impacket-ticketer impacket-getST impacket-getTGT impacket-ticketConverter impacket-goldenPac; do
    real="$(command -v "$bin" 2>/dev/null || true)"
    [[ -n "$real" ]] && ln -sf "$real" "$TOOLS/ad-exploitation/kerberos/$bin"
done
info "linked           impacket kerberos scripts"

for bin in impacket-psexec impacket-wmiexec impacket-smbexec impacket-ntlmrelayx; do
    real="$(command -v "$bin" 2>/dev/null || true)"
    [[ -n "$real" ]] && ln -sf "$real" "$TOOLS/ad-exploitation/lateral-movement/$bin"
done
info "linked           impacket lateral-movement scripts"

real="$(command -v impacket-secretsdump 2>/dev/null || true)"
[[ -n "$real" ]] && ln -sf "$real" "$TOOLS/ad-exploitation/credential-dumping/impacket-secretsdump"
[[ -d /usr/share/windows-resources/mimikatz ]] && \
    ln -sfn /usr/share/windows-resources/mimikatz "$TOOLS/ad-exploitation/credential-dumping/mimikatz" && \
    info "linked           mimikatz/ + impacket-secretsdump into credential-dumping/"

for bin in impacket-GetADUsers impacket-GetADComputers impacket-lookupsid impacket-findDelegation; do
    real="$(command -v "$bin" 2>/dev/null || true)"
    [[ -n "$real" ]] && ln -sf "$real" "$TOOLS/ad-exploitation/enumeration/$bin"
done
if [[ -f /usr/share/windows-resources/powersploit/Recon/PowerView.ps1 ]]; then
    ln -sf /usr/share/windows-resources/powersploit/Recon/PowerView.ps1 "$TOOLS/ad-exploitation/enumeration/PowerView.ps1"
    info "linked           PowerView.ps1 + impacket enumeration scripts"
else
    info "UNAVAILABLE      powersploit not installed -- PowerView.ps1 skipped"
fi

if [[ -d /usr/share/sharphound ]]; then
    ln -sf /usr/share/sharphound/SharpHound.exe "$TOOLS/ad-exploitation/bloodhound/ingestors/SharpHound.exe"
    ln -sf /usr/share/sharphound/SharpHound.ps1 "$TOOLS/ad-exploitation/bloodhound/ingestors/SharpHound.ps1"
    info "linked           SharpHound.exe + .ps1 into bloodhound/ingestors/"
fi

if ! command -v bloodhound-python >/dev/null; then
    sudo apt-get install -y bloodhound.py >/dev/null 2>&1
fi
if command -v bloodhound-python >/dev/null; then
    ln -sf "$(command -v bloodhound-python)" "$TOOLS/ad-exploitation/bloodhound/ingestors/bloodhound-python"
    info "linked           bloodhound-python into bloodhound/ingestors/"
else
    info "UNAVAILABLE      bloodhound.py"
    missing+=("bloodhound.py")
fi

if [[ ! -f "$TOOLS/ad-exploitation/bloodhound/ingestors/rusthound-ce" ]]; then
    TMPTGZ="$(mktemp --suffix=.tar.gz)"
    if curl -fsSL "https://github.com/g0h4n/RustHound-CE/releases/latest/download/rusthound-ce-Linux-gnu-x86_64.tar.gz" \
        -o "$TMPTGZ"; then
        tar -xzf "$TMPTGZ" -C "$TOOLS/ad-exploitation/bloodhound/ingestors" rusthound-ce 2>/dev/null
        chmod +x "$TOOLS/ad-exploitation/bloodhound/ingestors/rusthound-ce" 2>/dev/null
        rm -f "$TMPTGZ"
        info "downloaded       rusthound-ce into bloodhound/ingestors/"
    else
        info "UNAVAILABLE      rusthound-ce"
        missing+=("rusthound-ce")
        rm -f "$TMPTGZ"
    fi
else
    info "already present  rusthound-ce"
fi

if ! command -v netexec >/dev/null && ! command -v nxc >/dev/null; then
    sudo apt-get install -y netexec >/dev/null 2>&1
fi

if [[ ! -f "$TOOLS/ad-exploitation/enumeration/nxcspray" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/NTHSec/nxcspray/main/nxcspray" \
        -o "$TOOLS/ad-exploitation/enumeration/nxcspray" \
        && chmod +x "$TOOLS/ad-exploitation/enumeration/nxcspray" \
        && info "downloaded       nxcspray (needs netexec on PATH)" \
        || { info "UNAVAILABLE      nxcspray"; missing+=("nxcspray"); }
else
    info "already present  nxcspray"
fi

# -- BloodHound CE (Docker Compose) --
if ! command -v docker >/dev/null; then
    sudo apt-get install -y docker.io docker-compose
    sudo systemctl enable --now docker >/dev/null 2>&1
    sudo usermod -aG docker "$USER"
    info "installed        docker.io + docker-compose (log out/in for group membership to apply)"
else
    info "already present  docker"
fi

mkdir -p "$TOOLS/ad-exploitation/bloodhound"
if [[ ! -f "$TOOLS/ad-exploitation/bloodhound/docker-compose.yml" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/SpecterOps/BloodHound/main/examples/docker-compose/docker-compose.yml" \
        -o "$TOOLS/ad-exploitation/bloodhound/docker-compose.yml" \
        && info "downloaded       BloodHound CE docker-compose.yml" \
        || { info "UNAVAILABLE      BloodHound docker-compose.yml"; missing+=("bloodhound-docker-compose"); }
else
    info "already present  BloodHound CE docker-compose.yml"
fi
info "BloodHound CE: cd $TOOLS/ad-exploitation/bloodhound && docker compose pull && docker compose up -d"
info "Login at http://localhost:8080/ui/login as admin -- password is printed once, run: docker compose logs bloodhound | grep -i password"

if ! command -v certipy >/dev/null; then
    command -v pipx >/dev/null || sudo apt-get install -y pipx >/dev/null 2>&1
    pipx install certipy-ad >/dev/null 2>&1 \
        && info "installed        certipy (via pipx)" \
        || { info "UNAVAILABLE      certipy-ad"; missing+=("certipy-ad"); }
else
    info "already present  certipy"
fi

# bloodyAD -- AD privesc / object & DACL abuse. Installed via pipx like
# certipy, then symlinked into ad-exploitation for discoverability.
if ! command -v bloodyAD >/dev/null; then
    command -v pipx >/dev/null || sudo apt-get install -y pipx >/dev/null 2>&1
    pipx install bloodyAD >/dev/null 2>&1 \
        && info "installed        bloodyAD (via pipx)" \
        || { info "UNAVAILABLE      bloodyAD"; missing+=("bloodyAD"); }
else
    info "already present  bloodyAD"
fi
BLOODYAD_BIN="$(command -v bloodyAD 2>/dev/null || true)"
if [[ -n "$BLOODYAD_BIN" ]]; then
    ln -sf "$BLOODYAD_BIN" "$TOOLS/ad-exploitation/bloodyAD"
    info "linked           bloodyAD -> $TOOLS/ad-exploitation/bloodyAD"
fi

if ! command -v git-dumper >/dev/null; then
    command -v pipx >/dev/null || sudo apt-get install -y pipx >/dev/null 2>&1
    pipx install git-dumper >/dev/null 2>&1 \
        && info "installed        git-dumper (via pipx)" \
        || { info "UNAVAILABLE      git-dumper"; missing+=("git-dumper"); }
else
    info "already present  git-dumper"
fi
GIT_DUMPER_BIN="$(command -v git-dumper 2>/dev/null || true)"
[[ -n "$GIT_DUMPER_BIN" ]] && { mkdir -p "$TOOLS/exploits/web"; ln -sf "$GIT_DUMPER_BIN" "$TOOLS/exploits/web/git-dumper" || true; }

if ! command -v autorecon >/dev/null; then
    command -v pipx >/dev/null || sudo apt-get install -y pipx >/dev/null 2>&1
    pipx install autorecon >/dev/null 2>&1 \
        && info "installed        autorecon (via pipx)" \
        || { info "UNAVAILABLE      autorecon"; missing+=("autorecon"); }
else
    info "already present  autorecon"
fi
AUTORECON_BIN="$(command -v autorecon 2>/dev/null || true)"
mkdir -p "$TOOLS/recon"
[[ -n "$AUTORECON_BIN" ]] && ln -sf "$AUTORECON_BIN" "$TOOLS/recon/autorecon"

CERTIPY_BIN="$(command -v certipy 2>/dev/null || true)"
if [[ -n "$CERTIPY_BIN" ]]; then
    ln -sf "$CERTIPY_BIN" "$TOOLS/ad-exploitation/certipy"
    info "linked           certipy -> $TOOLS/ad-exploitation/certipy"
fi

# targetedKerberoast -- targeted Kerberoasting. No PyPI package, so clone it
# with its own venv; that way it carries its own impacket/ldap3 and never
# depends on the system python. A launcher on PATH runs it: targetedKerberoast
TK_DIR="$TOOLS/ad-exploitation/kerberos/targetedKerberoast"
if [[ ! -d "$TK_DIR/.git" ]]; then
    git clone --quiet https://github.com/ShutdownRepo/targetedKerberoast "$TK_DIR" 2>/dev/null \
        && info "cloned           targetedKerberoast" \
        || { info "UNAVAILABLE      targetedKerberoast (clone failed)"; missing+=("targetedKerberoast"); }
else
    git -C "$TK_DIR" pull --quiet --ff-only 2>/dev/null && info "updated repo      targetedKerberoast" || true
fi
if [[ -f "$TK_DIR/requirements.txt" ]]; then
    python3 -m venv "$TK_DIR/.venv" >/dev/null 2>&1 || true
    "$TK_DIR/.venv/bin/pip" install -q --upgrade pip >/dev/null 2>&1 || true
    if "$TK_DIR/.venv/bin/pip" install -q -r "$TK_DIR/requirements.txt" >/dev/null 2>&1; then
        mkdir -p "$HOME/.local/bin"
        printf '#!/usr/bin/env bash\nexec "%s/.venv/bin/python" "%s/targetedKerberoast.py" "$@"\n' "$TK_DIR" "$TK_DIR" > "$HOME/.local/bin/targetedKerberoast"
        chmod +x "$HOME/.local/bin/targetedKerberoast"
        info "installed        targetedKerberoast (venv + launcher in ~/.local/bin)"
    else
        info "UNAVAILABLE      targetedKerberoast deps"; missing+=("targetedKerberoast-deps")
    fi
fi

# -- shells-payloads (webshells from apt, plink official) --
if [[ -d /usr/share/webshells ]]; then
    ln -sf /usr/share/webshells/php/php-reverse-shell.php "$TOOLS/shells-payloads/php-shell.php"
    ln -sf /usr/share/webshells/asp/cmdasp.asp            "$TOOLS/shells-payloads/asp-shell.asp"
    info "linked           php-shell.php + asp-shell.asp from apt package webshells"
fi

command -v penelope >/dev/null && \
    ln -sf "$(command -v penelope)" "$TOOLS/shells-payloads/penelope" && \
    info "linked           penelope (shell handler, from apt)"

if [[ ! -f "$TOOLS/shells-payloads/plink.exe" ]]; then
    curl -fsSL "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" \
        -o "$TOOLS/shells-payloads/plink.exe" \
        && info "downloaded       plink.exe (official PuTTY)" \
        || { info "UNAVAILABLE      plink.exe"; missing+=("plink.exe"); }
else
    info "already present  plink.exe"
fi

# -- tunneling-pivoting (chisel from apt for Linux, GitHub for the Windows build) --
mkdir -p "$TOOLS/tunneling-pivoting/chisel"
if [[ ! -f "$TOOLS/tunneling-pivoting/chisel/chisel.exe" ]]; then
    CHISEL_WIN_URL="$(curl -fsSL https://api.github.com/repos/jpillora/chisel/releases/latest \
        | grep browser_download_url | grep -i windows | grep -i amd64 | cut -d '"' -f4)"
    if [[ -n "$CHISEL_WIN_URL" ]]; then
        TMPGZ="$(mktemp --suffix=.gz)"
        curl -fsSL "$CHISEL_WIN_URL" -o "$TMPGZ" \
            && gunzip -c "$TMPGZ" > "$TOOLS/tunneling-pivoting/chisel/chisel.exe" \
            && rm -f "$TMPGZ" \
            && info "downloaded       chisel.exe"
    else
        info "UNAVAILABLE      chisel.exe (couldn't resolve latest Windows asset)"
        missing+=("chisel.exe")
    fi
else
    info "already present  chisel.exe"
fi

command -v chisel >/dev/null && \
    ln -sf "$(command -v chisel)" "$TOOLS/tunneling-pivoting/chisel/chisel" && \
    info "linked           chisel (Linux, from apt)"

# Only x86_64 is published as a compiled binary in this repo -- the x86
# (32-bit) build script exists upstream but no prebuilt binary ships with it.
if [[ ! -f "$TOOLS/tunneling-pivoting/socat-x86_64" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/andrew-d/static-binaries/master/binaries/linux/x86_64/socat" \
        -o "$TOOLS/tunneling-pivoting/socat-x86_64" \
        && chmod +x "$TOOLS/tunneling-pivoting/socat-x86_64" \
        && info "downloaded       socat-x86_64 (static, for targets without socat)" \
        || { info "UNAVAILABLE      socat-x86_64"; missing+=("socat-x86_64"); }
else
    info "already present  socat-x86_64"
fi

[[ -f /etc/proxychains4.conf ]] && \
    ln -sf /etc/proxychains4.conf "$TOOLS/tunneling-pivoting/proxychains4.conf" && \
    info "linked           proxychains4.conf (edit the real /etc/proxychains4.conf -- this is a shortcut, not a copy)"

# -- ligolo-ng (proxy for Kali, agents for Windows/Linux targets) --
mkdir -p "$TOOLS/tunneling-pivoting/ligolo"
LIGOLO_RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest)"

LIGOLO_PROXY_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i proxy | grep -i linux | grep -i amd64 | grep -i tar.gz | cut -d '"' -f4)"
if [[ -n "$LIGOLO_PROXY_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo/ligolo-proxy" ]]; then
    TMPTGZ="$(mktemp --suffix=.tar.gz)"
    curl -fsSL "$LIGOLO_PROXY_URL" -o "$TMPTGZ" \
        && tar -xzf "$TMPTGZ" -C "$TOOLS/tunneling-pivoting/ligolo" proxy \
        && mv "$TOOLS/tunneling-pivoting/ligolo/proxy" "$TOOLS/tunneling-pivoting/ligolo/ligolo-proxy" \
        && chmod +x "$TOOLS/tunneling-pivoting/ligolo/ligolo-proxy" \
        && rm -f "$TMPTGZ" \
        && info "downloaded       ligolo-proxy"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo/ligolo-proxy" ]]; then
    info "already present  ligolo-proxy"
else
    info "UNAVAILABLE      ligolo-proxy (couldn't resolve latest Linux asset)"
    missing+=("ligolo-proxy")
fi

LIGOLO_AGENT_WIN_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i agent | grep -i windows | grep -i amd64 | grep -i zip | cut -d '"' -f4)"
if [[ -n "$LIGOLO_AGENT_WIN_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent.exe" ]]; then
    TMPZIP="$(mktemp --suffix=.zip)"
    curl -fsSL "$LIGOLO_AGENT_WIN_URL" -o "$TMPZIP" \
        && unzip -oq "$TMPZIP" agent.exe -d "$TOOLS/tunneling-pivoting/ligolo" \
        && mv "$TOOLS/tunneling-pivoting/ligolo/agent.exe" "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent.exe" \
        && rm -f "$TMPZIP" \
        && info "downloaded       ligolo-agent.exe"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent.exe" ]]; then
    info "already present  ligolo-agent.exe"
else
    info "UNAVAILABLE      ligolo-agent.exe (couldn't resolve latest Windows asset)"
    missing+=("ligolo-agent.exe")
fi

LIGOLO_AGENT_LINUX_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i agent | grep -i linux | grep -i amd64 | grep -i tar.gz | cut -d '"' -f4)"
if [[ -n "$LIGOLO_AGENT_LINUX_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent" ]]; then
    TMPTGZ2="$(mktemp --suffix=.tar.gz)"
    curl -fsSL "$LIGOLO_AGENT_LINUX_URL" -o "$TMPTGZ2" \
        && tar -xzf "$TMPTGZ2" -C "$TOOLS/tunneling-pivoting/ligolo" agent \
        && mv "$TOOLS/tunneling-pivoting/ligolo/agent" "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent" \
        && chmod +x "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent" \
        && rm -f "$TMPTGZ2" \
        && info "downloaded       ligolo-agent (Linux target build)"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo/ligolo-agent" ]]; then
    info "already present  ligolo-agent"
else
    info "UNAVAILABLE      ligolo-agent (couldn't resolve latest Linux asset)"
    missing+=("ligolo-agent")
fi

# -- exploits (web / windows / linux) --
mkdir -p "$TOOLS"/exploits/{web,windows,linux}

if [[ ! -d "$TOOLS/exploits/windows/Evil-Macro" ]]; then
    if git clone --quiet "https://github.com/rodolfomarianocy/Evil-Macro.git" \
        "$TOOLS/exploits/windows/Evil-Macro" 2>/dev/null; then
        info "cloned           Evil-Macro into exploits/windows/"
    else
        info "UNAVAILABLE      Evil-Macro (clone failed)"
        missing+=("Evil-Macro")
    fi
else
    info "already present  Evil-Macro"
fi

if [[ ! -d "$TOOLS/exploits/windows/AutoBlue-MS17-010" ]]; then
    if git clone --quiet "https://github.com/3ndG4me/AutoBlue-MS17-010.git" \
        "$TOOLS/exploits/windows/AutoBlue-MS17-010" 2>/dev/null; then
        info "cloned           AutoBlue-MS17-010 into exploits/windows/"
        if python3 -m venv "$TOOLS/exploits/windows/AutoBlue-MS17-010/.venv" 2>/dev/null \
            && "$TOOLS/exploits/windows/AutoBlue-MS17-010/.venv/bin/pip" install -q -r \
                "$TOOLS/exploits/windows/AutoBlue-MS17-010/requirements.txt" 2>/dev/null; then
            info "installed        AutoBlue-MS17-010 python deps (venv -- source .venv/bin/activate before running)"
        else
            info "UNAVAILABLE      AutoBlue-MS17-010 deps (pip install failed)"
            missing+=("AutoBlue-MS17-010 deps")
        fi
    else
        info "UNAVAILABLE      AutoBlue-MS17-010 (clone failed)"
        missing+=("AutoBlue-MS17-010")
    fi
else
    info "already present  AutoBlue-MS17-010"
fi

info "dnscat2 has no official Windows .exe -- the client side is dnscat2.ps1, PowerShell-only. Not linked."
info "BloodHound UI is now Docker/web-based (Community Edition). Run: sudo apt install bloodhound && sudo bloodhound-setup"
fi


if (( OPT_NOTES )); then
step "Syncing pentesting notes (CherryTree)"
NOTES_DIR="$HOME/.notes-repo"
NOTES_REPO="https://github.com/MarcussanMG/PentestingNotes.git"
if [[ -d "$NOTES_DIR/.git" ]]; then
    (
        cd "$NOTES_DIR" || exit 1
        git fetch origin >/dev/null 2>&1
        BRANCH="$(git remote show origin 2>/dev/null | sed -n '/HEAD branch/s/.*: //p')"
        git reset --hard "origin/${BRANCH:-main}" >/dev/null 2>&1
        git clean -fd >/dev/null 2>&1
    )
    info "already present  CherryTreePentestingNotes (synced to origin)"
else
    if git clone --quiet "$NOTES_REPO" "$NOTES_DIR" >/dev/null 2>&1; then
        info "cloned           CherryTreePentestingNotes"
    else
        info "UNAVAILABLE      CherryTreePentestingNotes (clone failed -- private repo?)"
        missing+=("CherryTreePentestingNotes")
    fi
fi
fi


if (( OPT_POSTMAN )); then
step "Installing Postman"
if [[ -x /usr/local/bin/postman ]]; then
    info "already present  postman"
else
    TMPTAR="$(mktemp --suffix=.tar.gz)"
    if curl -fsSL "https://dl.pstmn.io/download/latest/linux_64" -o "$TMPTAR"; then
        sudo rm -rf /opt/Postman
        sudo tar -xzf "$TMPTAR" -C /opt
        rm -f "$TMPTAR"
        sudo ln -sf /opt/Postman/Postman /usr/local/bin/postman
        sudo tee /usr/share/applications/postman.desktop > /dev/null << 'DESKTOP'
[Desktop Entry]
Name=Postman
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
DESKTOP
        info "installed        postman"
    else
        info "UNAVAILABLE      postman (download failed)"
        missing+=("postman")
        rm -f "$TMPTAR"
    fi
fi
fi

if (( OPT_NVIM )); then
step "Installing Neovim config (nightgrid.nvim)"
# Clone the Neovim config repo and run ITS installer, which installs a
# compatible neovim (if needed) plus LSP deps and copies the config into
# ~/.config/nvim. Non-fatal: the workstation works without it.
NVIM_REPO="${XDG_DATA_HOME:-$HOME/.local/share}/nightgrid.nvim"
mkdir -p "$(dirname "$NVIM_REPO")"
if [[ -d "$NVIM_REPO/.git" ]]; then
    git -C "$NVIM_REPO" pull --quiet --ff-only 2>/dev/null \
        && info "updated repo      nightgrid.nvim" || info "repo already present"
elif git clone --quiet https://github.com/MarcussanMG/nightgrid.nvim "$NVIM_REPO" 2>/dev/null; then
    info "cloned           nightgrid.nvim"
else
    info "UNAVAILABLE      nightgrid.nvim (clone failed)"
fi
if [[ -f "$NVIM_REPO/install.sh" ]]; then
    info "running its installer (neovim + config -> ~/.config/nvim)..."
    ( cd "$NVIM_REPO" && bash ./install.sh ) \
        && info "installed        Neovim config (nightgrid.nvim)" \
        || info "UNAVAILABLE      nightgrid.nvim installer failed"
    if command -v nvim >/dev/null; then
        # Let sudo find nvim: symlink the real binary into /usr/bin, which is
        # always in sudo's secure_path. nightgrid.nvim installs it under
        # /opt/nvim and only links /usr/local/bin, which Kali's secure_path
        # may exclude -- so `sudo nvim` breaks without this.
        if [[ ! -x /usr/bin/nvim ]]; then
            NVIM_BIN="$(readlink -f "$(command -v nvim)" 2>/dev/null || true)"
            if [[ -n "$NVIM_BIN" ]] && sudo ln -sf "$NVIM_BIN" /usr/bin/nvim 2>/dev/null; then
                info "linked           nvim into /usr/bin (so sudo nvim works)"
            fi
        fi
        info "syncing Neovim plugins (headless Lazy sync)..."
        nvim --headless "+Lazy! sync" +qa >/dev/null 2>&1 || true
        # LSP servers install themselves on first launch
        # (mason-lspconfig ensure_installed + automatic_installation).
    fi
fi
fi

"$DOTFILES/install.sh"

if [[ ! -L "$HOME/.config/i3/config" ]] || [[ "$(readlink -f "$HOME/.config/i3/config")" != "$(readlink -f "$DOTFILES/i3/config")" ]]; then
    echo
    echo "  !!!  i3/config symlink is missing or wrong. install.sh may have been"
    echo "       interrupted -- run it again manually before logging into i3:"
    echo "       cd $DOTFILES && ./install.sh"
    echo
fi

if ((${#missing[@]})); then
    header "Not available in your repositories"
    printf '  %s\n' "${missing[@]}"
    info "Everything else installed fine; these are optional."
fi

if ((${#missing_core[@]})); then
    printf '\n%s  !!!  CRITICAL: core packages failed to install%s\n' "$GREEN" "$RESET"
    printf '       %s\n' "${missing_core[@]}"
    printf '       The desktop/shell may not work. Fix these and re-run bootstrap.\n\n'
fi

header "Bootstrap complete"
cat <<'MSG'

  1. Log out.
  2. Pick the i3 session at the login screen.
  3. Log back in.

  Set zsh as your login shell if it is not already:

      chsh -s "$(command -v zsh)"

MSG

# Drop into a fresh zsh so the new config is active immediately. This can only
# work by replacing the shell (a 'source' from inside this bash child can't
# touch your interactive shell). Only on a TTY; skipped when piped (| tee).
if [[ -t 1 ]] && command -v zsh >/dev/null; then
    header "Starting zsh with your new configuration"
    exec zsh
fi
