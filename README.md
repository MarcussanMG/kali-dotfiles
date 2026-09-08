<div align="center">

# Kali OSCP Workstation

**A minimal, fast, and reproducible Kali Linux environment for PEN-200 and the OSCP exam.**

`i3` · `kitty` · `tmux` · `rofi` · `zsh` — themed with **nightgrid**

</div>

---

## Install

```bash
git clone https://github.com/MarcussanMG/kali-oscp-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap.sh
```

Log out, select the **i3** session, log back in.

![image alt](https://github.com/MarcussanMG/kali-dotfiles/blob/b89781c8300c107c8b5bed5dc778c3f02f0c9eb7/i3_config.png)

---

## Burp Suite setup

```bash
sudo apt install -y libnss3-tools   # needed once, for certutil
~/.dotfiles/bin/setup-burp.sh
```
Starts Burp, waits for `127.0.0.1:8080`, trusts its CA cert in Firefox, copies a FoxyProxy import string to the clipboard (paste into FoxyProxy → Options → Import Proxy List).

---

### Aliases
```bash
ls        eza --icons --group-directories-first
ll        eza -lah --icons --git
la        eza -a --icons
tree      eza --tree --level=2
cat       batcat --paging=never
cls / c   clear
.. ... .... cd up N levels
```

Helpers:
```bash
tun            # tun0 address
myip           # every non-loopback address
ports          # ss -tulpn
serve          # python3 -m http.server 80
extractports   # pull open ports from nmap .gnmap/.oG, copy to clipboard
mkt <name>     # scaffold ~/engagements/<name>/{nmap,web,loot,exploits,notes.md}
notes          # Pulls clean notes from github and opens cherrytree
```

Target tracking:
```bash
target 10.10.11.42   # set — shows in i3 bar, tmux, prompt, $T
target               # print current
```

Live network vars (auto-refresh every 10s, no shell latency):
```bash
echo $T   # target's address
echo $V   # tun0 address, empty if VPN down
echo $E   # first physical interface address
```

BloodHound CE (Docker, in `~/tools/ad-exploitation/bloodhound/`):
```bash
bloodhound up      # start postgres + neo4j + bloodhound
bloodhound down    # stop
bloodhound creds   # print admin password from container logs
```
Login at `http://localhost:8080/ui/login`, user `admin`. One-time password, forces reset on first login. Port conflict on 7474/7687 usually means a native Neo4j is already running — check with `sudo ss -tulpn | grep 7474`.

Pentesting notes (CherryTree, synced from [CherryTreePentestingNotes](https://github.com/MarcussanMG/CherryTreePentestingNotes)):
```bash
notes   # resets to origin/main and opens the .ctb in CherryTree
```
Anything edited inside CherryTree is disposable — every `notes` call hard-resets the
local clone to whatever is on GitHub before opening. Maintain the actual notes from
wherever you edit that repo, not from inside Kali.


---

## Components

| Piece | What it does |
| --- | --- |
| i3 | Tiling WM, gaps, rounded focus borders |
| picom | Compositor — `xrender` backend (see note below) |
| kitty | Terminal, GPU-accelerated, 3 clipboards |
| i3blocks | Status bar: tun0, target, IP, CPU, RAM, volume, clock |
| rofi | Launcher + power menu |
| tmux | Persistent sessions, VPN/target/path status line |
| zsh | Shell, two-line prompt with tunnel IP |
| batcat / fzf / zoxide / eza | Better cat / history search / cd / ls |
| JetBrainsMono Nerd Font | Terminal font + bar icons |
| FoxyProxy + Wappalyzer | Auto-install and pin via Firefox policy |

---

## Repository structure

```
~/.dotfiles/
├── bin/                  lockscreen, powermenu, screenshot, set-target,
│                         setup-burp.sh, start-picom, toggle-effects
├── i3/config
├── i3blocks/{config, scripts/}
├── kitty/{kitty.conf, nightgrid.conf}
├── picom/picom.conf
├── rofi/{config.rasi, theme.rasi, powermenu.rasi}
├── tmux/{tmux.conf, scripts/shorten-path.sh}
├── zsh/.zshrc
├── wallpapers/nightgrid.png
├── firefox/policies.json
├── bootstrap.sh
└── install.sh
```

---

## /tools/ arsenal

Built by `bootstrap.sh` into `~/tools/`:

| Category | Contents |
| --- | --- |
| `recon/` | kerbrute |
| `windows-privesc/` | WinPEAS (x64, x86, bat), PowerUp.ps1, PrivescCheck.ps1, accesschk, Rubeus.exe, SharpUp.exe |
| `linux-privesc/` | linpeas.sh, lse.sh, linux-exploit-suggester.sh |
| `ad-exploitation/` | Mimikatz, SharpHound (.exe + .ps1), PowerView.ps1, GetNPUsers.py, GetUserSPNs.py, secretsdump.py, psexec.py, wmiexec.py, Certipy, BloodHound CE (Docker) |
| `shells-payloads/` | ncat.exe, php-reverse-shell.php, cmdasp.asp, plink.exe |
| `tunneling-pivoting/` | chisel (+ .exe), ligolo-ng (proxy + agents), proxychains4.conf |

Notes:
- WinPEAS/PowerUp/linpeas come from apt (`peass`, `powersploit`) — auto-updated with `apt upgrade`.
- Rubeus.exe/SharpUp.exe are community-compiled (GhostPack ships source-only upstream).
- `ncat.exe` is used instead of unsigned `nc.exe` mirrors — official Nmap project binary via apt (`ncat-w32`).
- BloodHound CE is Docker-based now, not a standalone `.exe`.

---

# Keyboard shortcuts

## i3 — `Super` (Mod) key = Windows key

| Shortcut | Action |
| --- | --- |
| `Super+Enter` | Open Kitty |
| `Super+D` | Rofi launcher |
| `Super+Shift+F` | Firefox |
| `Super+Shift+B` | Burp Suite |
| `Super+Shift+X` | Power menu |
| `Super+Shift+L` | Lock screen |
| `Super+arrows` | Focus window |
| `Super+A` | Focus parent container |
| `Super+Space` | Focus tiling ↔ floating |
| `Super+Shift+arrows` | Move window |
| `Super+Shift+Space` | Toggle floating |
| `Super+1-9` | Switch workspace |
| `Super+Shift+1-9` | Move window to workspace |
| `Super+Shift+Q` | Close window |
| `Super+H` / `Super+V` | Next split horizontal/vertical |
| `Super+F` | Fullscreen |
| `Super+S` / `Super+W` | Stacking / tabbed layout |
| `Super+E` | Toggle split layout |
| `Super+R` | Resize mode (`Escape` to exit) |
| `Super+Shift+C` | Reload config |
| `Super+Shift+R` | Restart i3 |
| `Super+Shift+E` | Exit i3 |
| `Super+Shift+P` | Toggle exam mode (kills compositor, kitty 100% opaque) |
| `Super+Shift+S` | Region screenshot → `~/screenshots` + clipboard |
| `Super+Shift+T` | Set target (Rofi prompt) |

Exam mode is sticky across reboots until toggled off again.

## tmux — prefix `Ctrl+A`

| Shortcut | Action |
| --- | --- |
| `Ctrl+A /` | Split left/right |
| `Ctrl+A -` | Split top/bottom |
| `Ctrl+A` arrows | Focus pane |
| `Ctrl+A T` | Rename pane |
| `Ctrl+A C` | New window |
| `Ctrl+A ,` | Rename window |
| `Ctrl+A N` / `P` | Next / previous window |
| `Ctrl+A W` | List all sessions/windows |
| `Ctrl+A D` | Detach |
| `Ctrl+A R` | Reload config |
| `Ctrl+A S` | Toggle status line |

```bash
tmux ls
tmux attach-session -t main
tmux new-session -s recon
tmux select-pane -T "Nmap"        # pane title
```

`main` auto-attaches on first Kitty window; a second window gets its own session if `main` already has a client. Survives closing Kitty, not reboot.

Status line: session name · window boxes (bright green = active) · `vpn down`/tun0 IP · target · shortened cwd.

## Kitty

| Shortcut | Action |
| --- | --- |
| `Ctrl+Shift+C/V` | System clipboard |
| `Ctrl+Alt+Shift+C/V` | Private buffer 2 |
| `Ctrl+Alt+Shift+X/P` | Private buffer 3 |
| `Ctrl+Shift+F` | Search output |

## Rofi

`Super+D` launcher, `Super+Shift+X` power menu, arrows to navigate, `Enter` to select.

## Zsh

| Shortcut | Action |
| --- | --- |
| `Ctrl+R` | Fuzzy history search |
| `→` | Accept autosuggestion |
| `Ctrl+P` | Toggle 1-line/2-line prompt |
| `Ctrl+U` | Delete to start of line |
| `Shift+Tab` | Undo last edit |


Reload:
```bash
source ~/.zshrc
zsh -n ~/.zshrc   # syntax check
```

---

## Wallpaper

Both desktop and lock screen read `~/.dotfiles/wallpapers/nightgrid.png`:
```bash
cp /path/to/image.jpg ~/.dotfiles/wallpapers/nightgrid.png   # must be .png — convert if needed
feh --bg-fill ~/.dotfiles/wallpapers/nightgrid.png
rm -f ~/.cache/i3lock/blurred.png
```
---

## picom: `xrender`, not `glx`

Deliberate. `vmwgfx` (VMware's guest GPU driver) has a real kernel-crash bug under `glx` on recent Kali kernels — can freeze the whole VM. Don't switch back unless you've confirmed your VMware/kernel combo doesn't hit it. `Super+Shift+P` kills the compositor entirely if in doubt.

---

## Wordlists

```bash
ls /usr/share/seclists/Discovery/Web-Content/
```

---

## Validation

```bash
i3 -C -c ~/.config/i3/config
zsh -n ~/.zshrc
tmux source-file ~/.tmux.conf
bash -n ~/.dotfiles/install.sh
bash -n ~/.dotfiles/bootstrap.sh
for f in ~/.dotfiles/bin/* ~/.dotfiles/i3blocks/scripts/* ~/.dotfiles/tmux/scripts/*; do bash -n "$f"; done
```

---

## Security

Never commit: SSH keys, VPN configs, passwords/tokens, browser profiles/cookies, Burp CA certs, shell history, exam data.

```bash
grep -RniE 'password|passwd|token|secret|api[_-]?key|BEGIN .*PRIVATE KEY' ~/.dotfiles --exclude-dir=.git
```

`burp/` is gitignored. `target` is stored in `~/.cache/oscp-target`, outside the repo.
