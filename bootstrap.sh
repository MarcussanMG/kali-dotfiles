#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════════════
#  bootstrap.sh — install every dependency, then link the configuration.
#  Safe to re-run.
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

GREEN=$'\e[1;32m'; DIM=$'\e[2;37m'; RESET=$'\e[0m'
step() { printf '\n%s▸ %s%s\n' "$GREEN" "$1" "$RESET"; }
info() { printf '%s  %s%s\n' "$DIM" "$1" "$RESET"; }

[[ $EUID -eq 0 ]] && { echo "Run as your normal user, not root." >&2; exit 1; }

PACKAGES=(
    rlwrap peass powersploit mimikatz sharphound chisel ncat-w32 webshells
    rlwrap peass powersploit mimikatz sharphound chisel ncat-w32 webshells
    # ── Window manager and desktop ──
    i3 i3lock i3blocks suckless-tools dex
    picom feh rofi lxappearance
    network-manager-gnome dunst libnotify-bin
    # ── Terminal ──
    kitty tmux zsh
    zsh-autosuggestions zsh-syntax-highlighting
    # ── Shell tooling ──
    bat eza fd-find ripgrep fzf zoxide btop
    # ── X utilities ──
    x11-utils xclip maim imagemagick xss-lock libnss3-tools
    # ── Fonts and icons ──
    fonts-font-awesome papirus-icon-theme
    # ── Offensive tooling ──
    seclists
    # ── VMware guest integration ──
    open-vm-tools open-vm-tools-desktop
    # ── Base ──
    git curl wget unzip
)

step "Updating package lists"
sudo apt-get update

step "Installing packages"
# Installed one at a time so a single unavailable package cannot abort the run.
missing=()
for pkg in "${PACKAGES[@]}"; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
        info "already present  $pkg"
    elif sudo apt-get install -y --no-install-recommends "$pkg" >/dev/null 2>&1; then
        printf '  installed       %s\n' "$pkg"
    else
        missing+=("$pkg")
        printf '  UNAVAILABLE     %s\n' "$pkg"
    fi
done

step "Installing JetBrainsMono Nerd Font"
FONT_DIR="$HOME/.local/share/fonts"
if fc-list 2>/dev/null | grep -qi "JetBrainsMono Nerd Font"; then
    info "already present"
else
    mkdir -p "$FONT_DIR"
    tmp="$(mktemp -d)"
    url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    if curl -fsSL "$url" -o "$tmp/JetBrainsMono.zip"; then
        unzip -qo "$tmp/JetBrainsMono.zip" -d "$FONT_DIR/JetBrainsMono" \
            -x "*.txt" "*.md" "LICENSE*"
        fc-cache -f "$FONT_DIR" >/dev/null
        printf '  installed       JetBrainsMono Nerd Font\n'
    else
        info "download failed — install it manually from nerdfonts.com"
    fi
    rm -rf "$tmp"
fi

step "Linking configuration"

step "Building /tools/ arsenal"
TOOLS="$HOME/tools"
mkdir -p "$TOOLS"/{recon,windows-privesc,linux-privesc,ad-exploitation,shells-payloads,tunneling-pivoting}

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
if [[ -d /usr/share/peass/winpeas ]]; then
    ln -sf /usr/share/peass/winpeas/winPEAS.bat     "$TOOLS/windows-privesc/WinPEAS.bat"
    ln -sf /usr/share/peass/winpeas/winPEASx64.exe  "$TOOLS/windows-privesc/WinPEASx64.exe"
    ln -sf /usr/share/peass/winpeas/winPEASx86.exe  "$TOOLS/windows-privesc/WinPEASx86.exe"
    info "linked           WinPEAS (bat, x64, x86) from apt package peass"
else
    info "UNAVAILABLE      peass not installed -- winpeas skipped"
fi

if [[ -f /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 ]]; then
    ln -sf /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 "$TOOLS/windows-privesc/PowerUp.ps1"
    info "linked           PowerUp.ps1 from apt package powersploit"
else
    info "UNAVAILABLE      powersploit not installed -- PowerUp.ps1 skipped"
fi

if [[ ! -f "$TOOLS/windows-privesc/PrivescCheck.ps1" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1" \
        -o "$TOOLS/windows-privesc/PrivescCheck.ps1" \
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

if [[ ! -f "$TOOLS/windows-privesc/accesschk64.exe" ]]; then
    TMPZIP="$(mktemp --suffix=.zip)"
    if curl -fsSL "https://download.sysinternals.com/files/AccessChk.zip" -o "$TMPZIP"; then
        unzip -oq "$TMPZIP" -d "$TOOLS/windows-privesc/accesschk-tmp"
        mv "$TOOLS/windows-privesc/accesschk-tmp"/*.exe "$TOOLS/windows-privesc/" 2>/dev/null
        rm -rf "$TOOLS/windows-privesc/accesschk-tmp" "$TMPZIP"
        info "downloaded       accesschk (official Sysinternals)"
    else
        info "UNAVAILABLE      accesschk"
        missing+=("accesschk")
    fi
else
    info "already present  accesschk"
fi

for bin in Rubeus.exe SharpUp.exe; do
    if [[ ! -f "$TOOLS/windows-privesc/$bin" ]]; then
        curl -fsSL "https://raw.githubusercontent.com/r3motecontrol/Ghostpack-CompiledBinaries/master/$bin" \
            -o "$TOOLS/windows-privesc/$bin" \
            && info "downloaded       $bin (community-compiled -- GhostPack is source-only upstream)" \
            || { info "UNAVAILABLE      $bin"; missing+=("$bin"); }
    else
        info "already present  $bin"
    fi
done

# -- linux-privesc (linpeas from apt, lse.sh + les.sh from source) --
if [[ -d /usr/share/peass/linpeas ]]; then
    ln -sf /usr/share/peass/linpeas/linpeas.sh "$TOOLS/linux-privesc/linpeas.sh"
    info "linked           linpeas.sh from apt package peass"
else
    info "UNAVAILABLE      peass not installed -- linpeas skipped"
fi

if [[ ! -f "$TOOLS/linux-privesc/lse.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" \
        -o "$TOOLS/linux-privesc/lse.sh" && chmod +x "$TOOLS/linux-privesc/lse.sh" \
        && info "downloaded       lse.sh" \
        || { info "UNAVAILABLE      lse.sh"; missing+=("lse.sh"); }
else
    info "already present  lse.sh"
fi

if [[ ! -f "$TOOLS/linux-privesc/linux-exploit-suggester.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
        -o "$TOOLS/linux-privesc/linux-exploit-suggester.sh" && chmod +x "$TOOLS/linux-privesc/linux-exploit-suggester.sh" \
        && info "downloaded       linux-exploit-suggester.sh" \
        || { info "UNAVAILABLE      linux-exploit-suggester.sh"; missing+=("linux-exploit-suggester.sh"); }
else
    info "already present  linux-exploit-suggester.sh"
fi

# -- ad-exploitation (mimikatz/sharphound from apt, impacket already default on Kali) --
[[ -d /usr/share/windows-resources/mimikatz ]] && \
    ln -sf /usr/share/windows-resources/mimikatz "$TOOLS/ad-exploitation/mimikatz" && \
    info "linked           mimikatz/ from apt package mimikatz"

if [[ -d /usr/share/sharphound ]]; then
    ln -sf /usr/share/sharphound/SharpHound.exe "$TOOLS/ad-exploitation/SharpHound.exe"
    ln -sf /usr/share/sharphound/SharpHound.ps1 "$TOOLS/ad-exploitation/SharpHound.ps1"
    info "linked           SharpHound.exe + .ps1 from apt package sharphound"
fi

for script in GetNPUsers.py GetUserSPNs.py secretsdump.py psexec.py wmiexec.py; do
    real="$(command -v "$script" 2>/dev/null || true)"
    [[ -n "$real" ]] && ln -sf "$real" "$TOOLS/ad-exploitation/$script"
done
info "linked           impacket scripts (already installed by default on Kali)"

if ! command -v certipy >/dev/null; then
    command -v pipx >/dev/null || sudo apt-get install -y pipx >/dev/null 2>&1
    pipx install certipy-ad >/dev/null 2>&1 \
        && info "installed        certipy (via pipx)" \
        || { info "UNAVAILABLE      certipy-ad"; missing+=("certipy-ad"); }
else
    info "already present  certipy"
fi

# -- shells-payloads (webshells from apt, plink official) --
if [[ -d /usr/share/webshells ]]; then
    ln -sf /usr/share/webshells/php/php-reverse-shell.php "$TOOLS/shells-payloads/php-shell.php"
    ln -sf /usr/share/webshells/asp/cmdasp.asp            "$TOOLS/shells-payloads/asp-shell.asp"
    info "linked           php-shell.php + asp-shell.asp from apt package webshells"
fi

if [[ ! -f "$TOOLS/shells-payloads/plink.exe" ]]; then
    curl -fsSL "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" \
        -o "$TOOLS/shells-payloads/plink.exe" \
        && info "downloaded       plink.exe (official PuTTY)" \
        || { info "UNAVAILABLE      plink.exe"; missing+=("plink.exe"); }
else
    info "already present  plink.exe"
fi

# -- tunneling-pivoting (chisel from apt for Linux, GitHub for the Windows build) --
if [[ ! -f "$TOOLS/tunneling-pivoting/chisel.exe" ]]; then
    CHISEL_WIN_URL="$(curl -fsSL https://api.github.com/repos/jpillora/chisel/releases/latest \
        | grep browser_download_url | grep -i windows | grep -i amd64 | cut -d '"' -f4)"
    if [[ -n "$CHISEL_WIN_URL" ]]; then
        TMPGZ="$(mktemp --suffix=.gz)"
        curl -fsSL "$CHISEL_WIN_URL" -o "$TMPGZ" \
            && gunzip -c "$TMPGZ" > "$TOOLS/tunneling-pivoting/chisel.exe" \
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
    ln -sf "$(command -v chisel)" "$TOOLS/tunneling-pivoting/chisel" && \
    info "linked           chisel (Linux, from apt)"

[[ -f /etc/proxychains4.conf ]] && \
    ln -sf /etc/proxychains4.conf "$TOOLS/tunneling-pivoting/proxychains4.conf" && \
    info "linked           proxychains4.conf (edit the real /etc/proxychains4.conf -- this is a shortcut, not a copy)"

# -- ligolo-ng (proxy for Kali, agents for Windows/Linux targets) --
LIGOLO_RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest)"

LIGOLO_PROXY_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i proxy | grep -i linux | grep -i amd64 | grep -i tar.gz | cut -d '"' -f4)"
if [[ -n "$LIGOLO_PROXY_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo-proxy" ]]; then
    TMPTGZ="$(mktemp --suffix=.tar.gz)"
    curl -fsSL "$LIGOLO_PROXY_URL" -o "$TMPTGZ" \
        && tar -xzf "$TMPTGZ" -C "$TOOLS/tunneling-pivoting" proxy \
        && mv "$TOOLS/tunneling-pivoting/proxy" "$TOOLS/tunneling-pivoting/ligolo-proxy" \
        && chmod +x "$TOOLS/tunneling-pivoting/ligolo-proxy" \
        && rm -f "$TMPTGZ" \
        && info "downloaded       ligolo-proxy"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo-proxy" ]]; then
    info "already present  ligolo-proxy"
else
    info "UNAVAILABLE      ligolo-proxy (couldn't resolve latest Linux asset)"
    missing+=("ligolo-proxy")
fi

LIGOLO_AGENT_WIN_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i agent | grep -i windows | grep -i amd64 | grep -i zip | cut -d '"' -f4)"
if [[ -n "$LIGOLO_AGENT_WIN_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo-agent.exe" ]]; then
    TMPZIP="$(mktemp --suffix=.zip)"
    curl -fsSL "$LIGOLO_AGENT_WIN_URL" -o "$TMPZIP" \
        && unzip -oq "$TMPZIP" agent.exe -d "$TOOLS/tunneling-pivoting" \
        && mv "$TOOLS/tunneling-pivoting/agent.exe" "$TOOLS/tunneling-pivoting/ligolo-agent.exe" \
        && rm -f "$TMPZIP" \
        && info "downloaded       ligolo-agent.exe"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo-agent.exe" ]]; then
    info "already present  ligolo-agent.exe"
else
    info "UNAVAILABLE      ligolo-agent.exe (couldn't resolve latest Windows asset)"
    missing+=("ligolo-agent.exe")
fi

LIGOLO_AGENT_LINUX_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i agent | grep -i linux | grep -i amd64 | grep -i tar.gz | cut -d '"' -f4)"
if [[ -n "$LIGOLO_AGENT_LINUX_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo-agent" ]]; then
    TMPTGZ2="$(mktemp --suffix=.tar.gz)"
    curl -fsSL "$LIGOLO_AGENT_LINUX_URL" -o "$TMPTGZ2" \
        && tar -xzf "$TMPTGZ2" -C "$TOOLS/tunneling-pivoting" agent \
        && mv "$TOOLS/tunneling-pivoting/agent" "$TOOLS/tunneling-pivoting/ligolo-agent" \
        && chmod +x "$TOOLS/tunneling-pivoting/ligolo-agent" \
        && rm -f "$TMPTGZ2" \
        && info "downloaded       ligolo-agent (Linux target build)"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo-agent" ]]; then
    info "already present  ligolo-agent"
else
    info "UNAVAILABLE      ligolo-agent (couldn't resolve latest Linux asset)"
    missing+=("ligolo-agent")
fi

info "dnscat2 has no official Windows .exe -- the client side is dnscat2.ps1, PowerShell-only. Not linked."
info "BloodHound UI is now Docker/web-based (Community Edition). Run: sudo apt install bloodhound && sudo bloodhound-setup"


step "Building /tools/ arsenal"
TOOLS="$HOME/tools"
mkdir -p "$TOOLS"/{recon,windows-privesc,linux-privesc,ad-exploitation,shells-payloads,tunneling-pivoting}

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

if [[ -d /usr/share/peass/winpeas ]]; then
    ln -sf /usr/share/peass/winpeas/winPEAS.bat     "$TOOLS/windows-privesc/WinPEAS.bat"
    ln -sf /usr/share/peass/winpeas/winPEASx64.exe  "$TOOLS/windows-privesc/WinPEASx64.exe"
    ln -sf /usr/share/peass/winpeas/winPEASx86.exe  "$TOOLS/windows-privesc/WinPEASx86.exe"
    info "linked           WinPEAS (bat, x64, x86) from apt package peass"
else
    info "UNAVAILABLE      peass not installed -- winpeas skipped"
fi

if [[ -f /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 ]]; then
    ln -sf /usr/share/windows-resources/powersploit/Privesc/PowerUp.ps1 "$TOOLS/windows-privesc/PowerUp.ps1"
    info "linked           PowerUp.ps1 from apt package powersploit"
else
    info "UNAVAILABLE      powersploit not installed -- PowerUp.ps1 skipped"
fi

if [[ ! -f "$TOOLS/windows-privesc/PrivescCheck.ps1" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/itm4n/PrivescCheck/master/PrivescCheck.ps1" \
        -o "$TOOLS/windows-privesc/PrivescCheck.ps1" \
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

if [[ ! -f "$TOOLS/windows-privesc/accesschk64.exe" ]]; then
    TMPZIP="$(mktemp --suffix=.zip)"
    if curl -fsSL "https://download.sysinternals.com/files/AccessChk.zip" -o "$TMPZIP"; then
        unzip -oq "$TMPZIP" -d "$TOOLS/windows-privesc/accesschk-tmp"
        mv "$TOOLS/windows-privesc/accesschk-tmp"/*.exe "$TOOLS/windows-privesc/" 2>/dev/null
        rm -rf "$TOOLS/windows-privesc/accesschk-tmp" "$TMPZIP"
        info "downloaded       accesschk (official Sysinternals)"
    else
        info "UNAVAILABLE      accesschk"
        missing+=("accesschk")
    fi
else
    info "already present  accesschk"
fi

for bin in Rubeus.exe SharpUp.exe; do
    if [[ ! -f "$TOOLS/windows-privesc/$bin" ]]; then
        curl -fsSL "https://raw.githubusercontent.com/r3motecontrol/Ghostpack-CompiledBinaries/master/$bin" \
            -o "$TOOLS/windows-privesc/$bin" \
            && info "downloaded       $bin (community-compiled -- GhostPack is source-only upstream)" \
            || { info "UNAVAILABLE      $bin"; missing+=("$bin"); }
    else
        info "already present  $bin"
    fi
done

if [[ -d /usr/share/peass/linpeas ]]; then
    ln -sf /usr/share/peass/linpeas/linpeas.sh "$TOOLS/linux-privesc/linpeas.sh"
    info "linked           linpeas.sh from apt package peass"
else
    info "UNAVAILABLE      peass not installed -- linpeas skipped"
fi

if [[ ! -f "$TOOLS/linux-privesc/lse.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/diego-treitos/linux-smart-enumeration/master/lse.sh" \
        -o "$TOOLS/linux-privesc/lse.sh" && chmod +x "$TOOLS/linux-privesc/lse.sh" \
        && info "downloaded       lse.sh" \
        || { info "UNAVAILABLE      lse.sh"; missing+=("lse.sh"); }
else
    info "already present  lse.sh"
fi

if [[ ! -f "$TOOLS/linux-privesc/linux-exploit-suggester.sh" ]]; then
    curl -fsSL "https://raw.githubusercontent.com/mzet-/linux-exploit-suggester/master/linux-exploit-suggester.sh" \
        -o "$TOOLS/linux-privesc/linux-exploit-suggester.sh" && chmod +x "$TOOLS/linux-privesc/linux-exploit-suggester.sh" \
        && info "downloaded       linux-exploit-suggester.sh" \
        || { info "UNAVAILABLE      linux-exploit-suggester.sh"; missing+=("linux-exploit-suggester.sh"); }
else
    info "already present  linux-exploit-suggester.sh"
fi

[[ -d /usr/share/windows-resources/mimikatz ]] && \
    ln -sf /usr/share/windows-resources/mimikatz "$TOOLS/ad-exploitation/mimikatz" && \
    info "linked           mimikatz/ from apt package mimikatz"

if [[ -d /usr/share/sharphound ]]; then
    ln -sf /usr/share/sharphound/SharpHound.exe "$TOOLS/ad-exploitation/SharpHound.exe"
    ln -sf /usr/share/sharphound/SharpHound.ps1 "$TOOLS/ad-exploitation/SharpHound.ps1"
    info "linked           SharpHound.exe + .ps1 from apt package sharphound"
fi

for script in GetNPUsers.py GetUserSPNs.py secretsdump.py psexec.py wmiexec.py; do
    real="$(command -v "$script" 2>/dev/null || true)"
    [[ -n "$real" ]] && ln -sf "$real" "$TOOLS/ad-exploitation/$script"
done
info "linked           impacket scripts (already installed by default on Kali)"

if ! command -v certipy >/dev/null; then
    command -v pipx >/dev/null || sudo apt-get install -y pipx >/dev/null 2>&1
    pipx install certipy-ad >/dev/null 2>&1 \
        && info "installed        certipy (via pipx)" \
        || { info "UNAVAILABLE      certipy-ad"; missing+=("certipy-ad"); }
else
    info "already present  certipy"
fi

if [[ -d /usr/share/webshells ]]; then
    ln -sf /usr/share/webshells/php/php-reverse-shell.php "$TOOLS/shells-payloads/php-shell.php"
    ln -sf /usr/share/webshells/asp/cmdasp.asp            "$TOOLS/shells-payloads/asp-shell.asp"
    info "linked           php-shell.php + asp-shell.asp from apt package webshells"
fi

if [[ ! -f "$TOOLS/shells-payloads/plink.exe" ]]; then
    curl -fsSL "https://the.earth.li/~sgtatham/putty/latest/w64/plink.exe" \
        -o "$TOOLS/shells-payloads/plink.exe" \
        && info "downloaded       plink.exe (official PuTTY)" \
        || { info "UNAVAILABLE      plink.exe"; missing+=("plink.exe"); }
else
    info "already present  plink.exe"
fi

if [[ ! -f "$TOOLS/tunneling-pivoting/chisel.exe" ]]; then
    CHISEL_WIN_URL="$(curl -fsSL https://api.github.com/repos/jpillora/chisel/releases/latest \
        | grep browser_download_url | grep -i windows | grep -i amd64 | cut -d '"' -f4)"
    if [[ -n "$CHISEL_WIN_URL" ]]; then
        TMPGZ="$(mktemp --suffix=.gz)"
        curl -fsSL "$CHISEL_WIN_URL" -o "$TMPGZ" \
            && gunzip -c "$TMPGZ" > "$TOOLS/tunneling-pivoting/chisel.exe" \
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
    ln -sf "$(command -v chisel)" "$TOOLS/tunneling-pivoting/chisel" && \
    info "linked           chisel (Linux, from apt)"

[[ -f /etc/proxychains4.conf ]] && \
    ln -sf /etc/proxychains4.conf "$TOOLS/tunneling-pivoting/proxychains4.conf" && \
    info "linked           proxychains4.conf (edit the real /etc/proxychains4.conf -- this is a shortcut, not a copy)"

LIGOLO_RELEASE_JSON="$(curl -fsSL https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest)"

LIGOLO_PROXY_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i proxy | grep -i linux | grep -i amd64 | grep -i tar.gz | cut -d '"' -f4)"
if [[ -n "$LIGOLO_PROXY_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo-proxy" ]]; then
    TMPTGZ="$(mktemp --suffix=.tar.gz)"
    curl -fsSL "$LIGOLO_PROXY_URL" -o "$TMPTGZ" \
        && tar -xzf "$TMPTGZ" -C "$TOOLS/tunneling-pivoting" proxy \
        && mv "$TOOLS/tunneling-pivoting/proxy" "$TOOLS/tunneling-pivoting/ligolo-proxy" \
        && chmod +x "$TOOLS/tunneling-pivoting/ligolo-proxy" \
        && rm -f "$TMPTGZ" \
        && info "downloaded       ligolo-proxy"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo-proxy" ]]; then
    info "already present  ligolo-proxy"
else
    info "UNAVAILABLE      ligolo-proxy (couldn't resolve latest Linux asset)"
    missing+=("ligolo-proxy")
fi

LIGOLO_AGENT_WIN_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i agent | grep -i windows | grep -i amd64 | grep -i zip | cut -d '"' -f4)"
if [[ -n "$LIGOLO_AGENT_WIN_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo-agent.exe" ]]; then
    TMPZIP2="$(mktemp --suffix=.zip)"
    curl -fsSL "$LIGOLO_AGENT_WIN_URL" -o "$TMPZIP2" \
        && unzip -oq "$TMPZIP2" agent.exe -d "$TOOLS/tunneling-pivoting" \
        && mv "$TOOLS/tunneling-pivoting/agent.exe" "$TOOLS/tunneling-pivoting/ligolo-agent.exe" \
        && rm -f "$TMPZIP2" \
        && info "downloaded       ligolo-agent.exe"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo-agent.exe" ]]; then
    info "already present  ligolo-agent.exe"
else
    info "UNAVAILABLE      ligolo-agent.exe (couldn't resolve latest Windows asset)"
    missing+=("ligolo-agent.exe")
fi

LIGOLO_AGENT_LINUX_URL="$(printf '%s' "$LIGOLO_RELEASE_JSON" | grep browser_download_url | grep -i agent | grep -i linux | grep -i amd64 | grep -i tar.gz | cut -d '"' -f4)"
if [[ -n "$LIGOLO_AGENT_LINUX_URL" && ! -f "$TOOLS/tunneling-pivoting/ligolo-agent" ]]; then
    TMPTGZ2="$(mktemp --suffix=.tar.gz)"
    curl -fsSL "$LIGOLO_AGENT_LINUX_URL" -o "$TMPTGZ2" \
        && tar -xzf "$TMPTGZ2" -C "$TOOLS/tunneling-pivoting" agent \
        && mv "$TOOLS/tunneling-pivoting/agent" "$TOOLS/tunneling-pivoting/ligolo-agent" \
        && chmod +x "$TOOLS/tunneling-pivoting/ligolo-agent" \
        && rm -f "$TMPTGZ2" \
        && info "downloaded       ligolo-agent (Linux target build)"
elif [[ -f "$TOOLS/tunneling-pivoting/ligolo-agent" ]]; then
    info "already present  ligolo-agent"
else
    info "UNAVAILABLE      ligolo-agent (couldn't resolve latest Linux asset)"
    missing+=("ligolo-agent")
fi

info "dnscat2 has no official Windows .exe -- the client side is dnscat2.ps1, PowerShell-only. Not linked."
info "BloodHound UI is now Docker/web-based (Community Edition). Run: sudo apt install bloodhound && sudo bloodhound-setup"

"$DOTFILES/install.sh"

if ((${#missing[@]})); then
    step "Not available in your repositories"
    printf '  %s\n' "${missing[@]}"
    info "Everything else installed fine; these are optional."
fi

step "Bootstrap complete"
cat <<'MSG'

  1. Log out.
  2. Pick the i3 session at the login screen.
  3. Log back in.

  Set zsh as your login shell if it is not already:

      chsh -s "$(command -v zsh)"

MSG
