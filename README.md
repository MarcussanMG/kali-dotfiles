<div align="center">

# Kali OSCP Workstation

**A minimal, fast, and reproducible Kali Linux environment for PEN-200 and the OSCP exam.**

`i3` · `kitty` · `tmux` · `rofi` · `zsh` — themed with **nightgrid**

</div>

---

> The wallpaper was updated so the GIF is not exactly the same as the repo but the functionality stays the same

<img width="2048" height="856" alt="Kali-i3-workflow" src="https://github.com/user-attachments/assets/07b58550-7786-4954-9d37-3685a029b168" />

---


## What this is

A keyboard-driven Kali setup built around a single idea: nothing on screen should cost
you time. Windows tile, sessions persist, and the only numbers in the status bars are
the ones you actually need during an engagement — your tunnel address and your current
target.

The theme is **nightgrid**, the same black-and-green palette as
[nightgrid.nvim](https://github.com/MarcussanMG/nightgrid.nvim), so the editor, the shell,
the launcher and the window manager all agree with each other.

### Palette

| Token | Hex | Used for |
| --- | --- | --- |
| `bg` | `#05070a` | Terminal and bar background |
| `bg-panel` | `#0d1410` | Input fields, inactive elements |
| `green` | `#22c55e` | Focus, prompts, active borders |
| `green-hi` | `#4ade80` | Selection, tunnel address |
| `green-dim` | `#166534` | Rails, separators, icons |
| `fg` | `#d1fae5` | Body text |
| `fg-dim` | `#86efac` | Secondary text |
| `gray` | `#4b5e54` | Disabled, comments, autosuggestions |
| `yellow` | `#fbbf24` | Current target, warnings |
| `red` | `#f87171` | Errors, urgent windows, root prompt |

---

## Components

| Piece | What it does |
| --- | --- |
| **i3** | Tiling window manager. Gaps, rounded focus borders, no title bars. |
| **picom** | Compositor. Fast fades and soft shadows — killable with one key. |
| **kitty** | Terminal. GPU-accelerated, 50k lines of scrollback, three independent clipboards. |
| **i3blocks** | Status bar. tun0, target, local IP, CPU, RAM, volume, clock. |
| **rofi** | Launcher and power menu. |
| **tmux** | Persistent sessions, named panes, and a status line with a live VPN/target/path readout. |
| **zsh** | Shell, with a two-line prompt that carries your tunnel IP. |
| **NetworkManager applet** | Wi-Fi and VPN from the tray. |
| **batcat / fzf / zoxide / eza** | Syntax-highlighted `cat`, fuzzy history, faster `cd`, better `ls`. |
| **JetBrainsMono Nerd Font** | Terminal font and every icon in the bar. |
| **Firefox policy** | FoxyProxy and Wappalyzer install and pin themselves — no manual add-on hunting. |

---

## Installation

Clone the repository:

```bash
git clone https://github.com/MarcussanMG/kali-oscp-dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

Install packages and apply the configuration:

```bash
./bootstrap.sh
```

Then:

1. Log out.
2. Select the **i3** session at the login screen.
3. Log back in.

`bootstrap.sh` installs every package one at a time, so a single unavailable package
cannot abort the run — anything missing is listed at the end instead. It also calls
`install.sh` for you at the end, so there is no second step.

### Apply the configuration only

When the packages are already installed:

```bash
cd ~/.dotfiles
./install.sh
```

`install.sh` symlinks everything from this repository into your home directory. It is
idempotent — re-running it is harmless. Any real file it would overwrite is renamed to
`<file>.backup.<timestamp>` first. It also applies the wallpaper immediately, pre-renders
the lock screen, installs the Firefox extension policy, and reloads any already-running
tmux server so the status bar picks up the current theme without a manual reload.

---

## Changing the wallpaper

Both the desktop background (`i3/config`) and the lock screen (`bin/lockscreen`) read the
same file:

```
~/.dotfiles/wallpapers/nightgrid.png
```

To swap it, replace that file — keep the exact filename `nightgrid.png` so nothing else
needs editing:

```bash
cp /path/to/your-image.jpg ~/.dotfiles/wallpapers/nightgrid.png
```

If your image isn't already a PNG, convert it first:

```bash
convert /path/to/your-image.jpg ~/.dotfiles/wallpapers/nightgrid.png
```

Then apply it:

```bash
feh --bg-fill ~/.dotfiles/wallpapers/nightgrid.png   # desktop, immediately
rm -f ~/.cache/i3lock/blurred.png                    # force the lock screen to re-render
```

Re-running `./install.sh` also re-renders the cached lock screen automatically, since it
regenerates `~/.cache/i3lock/blurred.png` whenever the source wallpaper is newer than the
cached copy.

A higher-resolution source (matching or exceeding your monitor's resolution) looks best —
`feh --bg-fill` crops to fit rather than stretching, and the lock screen blur is generated
at your screen's native resolution.

---

## Burp Suite setup

`bin/setup-burp.sh` automates the two things you'd otherwise do by hand on every fresh
install: trusting Burp's CA certificate in Firefox, and preparing FoxyProxy's proxy entry.

```bash
~/.dotfiles/bin/setup-burp.sh
```

What it does:

1. Starts Burp Suite if it isn't already running, and waits for its proxy listener on
   `127.0.0.1:8080`. The first time Burp launches, click through its project wizard
   (**Temporary project** → **Use Burp defaults** → **Start Burp**) — that part can't be
   scripted away.
2. Downloads Burp's CA certificate and imports it as trusted into your default Firefox
   profile with `certutil`, so intercepted HTTPS traffic doesn't throw certificate
   warnings.
3. Copies a ready-to-paste FoxyProxy import string to the clipboard. Open FoxyProxy →
   **Options** → **Import Proxy List** and paste — FoxyProxy's full JSON import/export is
   unreliable, so this plain-text list format is the dependable path.

Requires `libnss3-tools` for `certutil`:

```bash
sudo apt install -y libnss3-tools
```

The downloaded certificate is written to `~/.dotfiles/burp/`, which is excluded from
version control by `.gitignore` — it's machine-specific and regenerated on every run.

---

## Repository structure

```
~/.dotfiles/
├── bin/
│   ├── lockscreen          i3lock with a blurred wallpaper
│   ├── powermenu           rofi power menu
│   ├── screenshot           region capture to ~/screenshots and the clipboard
│   ├── set-target           prompt for the target shown in the bar
│   ├── setup-burp.sh        Burp CA trust + FoxyProxy proxy setup
│   ├── start-picom          compositor launcher
│   └── toggle-effects       exam mode on/off
├── i3/
│   └── config
├── i3blocks/
│   ├── config
│   └── scripts/             clock  cpu  mem  net  target  volume  vpn
├── kitty/
│   ├── kitty.conf
│   └── nightgrid.conf       colour scheme, included by kitty.conf
├── picom/
│   └── picom.conf
├── rofi/
│   ├── config.rasi
│   ├── theme.rasi
│   └── powermenu.rasi
├── tmux/
│   ├── tmux.conf
│   └── scripts/
│       └── shorten-path.sh  truncates the working directory shown in the status bar
├── zsh/
│   └── .zshrc
├── wallpapers/
│   └── nightgrid.png
├── firefox/
│   └── policies.json        force-installs FoxyProxy and Wappalyzer
├── bootstrap.sh
├── install.sh
├── .gitignore
└── README.md
```

`burp/` is created at runtime by `setup-burp.sh` and is not tracked — it holds a
machine-specific certificate, not configuration.

---

# Keyboard shortcuts

## i3

The `Mod` key is the **Super/Windows key**.

### Applications

| Shortcut | Action |
| --- | --- |
| `Super + Enter` | Open Kitty |
| `Super + D` | Open the Rofi application launcher |
| `Super + Shift + F` | Open Firefox |
| `Super + Shift + B` | Open Burp Suite |
| `Super + Shift + X` | Open the Rofi power menu |
| `Super + Shift + L` | Lock the screen |

### Window focus

| Shortcut | Action |
| --- | --- |
| `Super + Left` | Focus the window on the left |
| `Super + Right` | Focus the window on the right |
| `Super + Up` | Focus the window above |
| `Super + Down` | Focus the window below |
| `Super + A` | Focus the parent container |
| `Super + Space` | Switch focus between tiling and floating |

### Move windows

| Shortcut | Action |
| --- | --- |
| `Super + Shift + Left` | Move the current window left |
| `Super + Shift + Right` | Move the current window right |
| `Super + Shift + Up` | Move the current window up |
| `Super + Shift + Down` | Move the current window down |
| `Super + Shift + Space` | Toggle floating |

### Workspaces

| Shortcut | Action |
| --- | --- |
| `Super + 1–9` | Switch to workspace 1–9 |
| `Super + Shift + 1–9` | Move the current window to workspace 1–9 |

Workspaces are intentionally not assigned fixed names or applications. If you want icons
in the bar, uncomment the second `$ws` block in `i3/config`.

### Window management

| Shortcut | Action |
| --- | --- |
| `Super + Shift + Q` | Close the focused window |
| `Super + H` | Set the next split to horizontal |
| `Super + V` | Set the next split to vertical |
| `Super + F` | Toggle fullscreen |
| `Super + S` | Stacking layout |
| `Super + W` | Tabbed layout |
| `Super + E` | Toggle split layout |
| `Super + R` | Enter resize mode |
| `Escape` | Exit resize mode |
| `Super + Ctrl + Shift + arrows` | Resize without entering resize mode |

In resize mode: `j` `k` `l` `;` or the arrow keys resize; `Enter`, `Escape` or
`Super + R` leaves.

### i3 session

| Shortcut | Action |
| --- | --- |
| `Super + Shift + C` | Reload the configuration |
| `Super + Shift + R` | Restart i3 in place |
| `Super + Shift + E` | Exit the i3 session |

Validate the configuration before reloading it:

```bash
i3 -C -c ~/.config/i3/config
```

Reload it from a terminal:

```bash
export I3SOCK="$(i3 --get-socketpath)"
i3-msg reload
```

### Extras

| Shortcut | Action |
| --- | --- |
| `Super + Shift + P` | Toggle **exam mode** — kills the compositor and makes kitty fully opaque |
| `Super + Shift + S` | Region screenshot to `~/screenshots`, also copied to the clipboard |
| `Super + Shift + T` | Set the engagement target shown in the bar |

Exam mode is sticky: once enabled, the compositor stays off across i3 restarts and
reboots until you press `Super + Shift + P` again.

---

## tmux

The prefix is:

```
Ctrl + A
```

Press `Ctrl + A`, release it, then press the second key.

### Panes

| Shortcut | Action |
| --- | --- |
| `Ctrl + A`, then `/` | Split into left and right panes |
| `Ctrl + A`, then `-` | Split into top and bottom panes |
| `Ctrl + A`, then `Left` | Focus the pane on the left |
| `Ctrl + A`, then `Right` | Focus the pane on the right |
| `Ctrl + A`, then `Up` | Focus the pane above |
| `Ctrl + A`, then `Down` | Focus the pane below |
| `Ctrl + A`, then `T` | Rename the current pane |
| `exit` | Close the current pane |

New splits open in the current pane's directory.

### Sessions and windows

| Shortcut | Action |
| --- | --- |
| `Ctrl + A`, then `C` | Create a new tmux window |
| `Ctrl + A`, then `,` | Rename the current window |
| `Ctrl + A`, then `N` | Move to the next tmux window |
| `Ctrl + A`, then `P` | Move to the previous tmux window |
| `Ctrl + A`, then `W` | Show an interactive list of every session and window |
| `Ctrl + A`, then `D` | Detach from the current session |
| `Ctrl + A`, then `R` | Reload `~/.tmux.conf` |
| `Ctrl + A`, then `?` | Display all tmux shortcuts |
| `Ctrl + A`, then `S` | Show or hide the status line |

Useful commands:

```bash
tmux ls                              # list sessions
tmux attach-session -t main          # attach to the persistent session
tmux new-session -s recon            # start a separate, independent session
tmux display-message -p '#S'         # current session name
tmux source-file ~/.tmux.conf        # reload manually
```

The `main` session is created automatically the first time Kitty starts and every window
you open attaches to it — sharing history, panes and windows across every terminal on
screen. If a second Kitty window opens while `main` already has a client attached, it
gets its own independent session instead of mirroring the first one, so two terminals
never step on each other. Sessions survive closing Kitty, but not rebooting Kali.

### Status line

On by default, along the bottom:

```
  main   1:recon   2:web        vpn down   no target   …/htb/dmz/web
```

- **Session name**, on the left.
- **Windows**, each shown as a filled box: bright green for the one you're in, dark for
  every other one — so you always know at a glance which pane you're about to type into.
- **VPN / target / current path**, on the right, as chevron-style segments:
  - the `tun0` address, or `vpn down` in gray if the tunnel isn't up
  - whatever you last set with `target` (see below), or `no target`
  - the current pane's working directory, shortened to its last three path components

The path segment is generated by `tmux/scripts/shorten-path.sh`; the VPN and target
segments shell out directly in `tmux.conf` and refresh automatically.

### Pane titles

Each pane shows its title in the border, which is how you keep track of what is running
where:

```
 1 Nmap                             2 Listener
──────────────────────────────────────────────────
 nmap -sC -sV target                nc -lvnp 4444
```

Press `Ctrl + A`, then `T`, type a title, press `Enter`. Or from the shell:

```bash
tmux select-pane -T "Nmap"
```

The active pane's title is highlighted in green. Pane titles are separate from window
names (`Ctrl + A`, then `,`) — a pane title labels what's running inside it, a window
name labels the tab itself in the status line.

---

## Kitty

| Shortcut | Action |
| --- | --- |
| `Ctrl + Shift + C` | Copy to the system clipboard |
| `Ctrl + Shift + V` | Paste from the system clipboard |
| `Ctrl + Alt + Shift + C` | Copy to private clipboard buffer 2 (kitty-only) |
| `Ctrl + Alt + Shift + V` | Paste from private clipboard buffer 2 |
| `Ctrl + Alt + Shift + X` | Copy to private clipboard buffer 3 (kitty-only) |
| `Ctrl + Alt + Shift + P` | Paste from private clipboard buffer 3 |
| `Ctrl + Shift + F` | Search terminal output |
| `Shift + mouse selection` | Select text through tmux mouse capture |

Three independent clipboards in total. The system clipboard (`Ctrl + Shift + C/V`) is the
one every other application reads and writes — Firefox, Burp, and any shell helper that
pipes into `xclip`, including `extractports` (see the Zsh section below). The other two
live only inside kitty and never touch anything outside it, which is useful for holding a
payload and a piece of loot at the same time without one overwriting the other.

Kitty is configured with the nightgrid palette, JetBrainsMono Nerd Font, 50 000 lines of
scrollback, no audio bell, no cursor blink, no close confirmation, and 95 % opacity.
`Super + Shift + P` sets opacity back to 100 % for exam conditions. To make that
permanent, set `background_opacity 1.0` in `kitty/kitty.conf`.

After editing the configuration, close and reopen Kitty.

---

## Rofi

| Shortcut | Action |
| --- | --- |
| `Super + D` | Open the application launcher |
| `Super + Shift + X` | Open the power menu |
| `Arrow keys` | Move through results |
| `Enter` | Select an item |
| `Escape` | Close Rofi |

Matching is fuzzy and case-smart. The power menu offers shutdown, reboot, logout and
lock as four icons. Run it manually with:

```bash
~/.local/bin/powermenu
```

---

## Zsh

### History and completion

| Shortcut | Action |
| --- | --- |
| `Ctrl + R` | Search command history interactively with fzf |
| `Right Arrow` | Accept an autosuggestion |
| `Ctrl + P` | Toggle between the one-line and two-line prompt |
| `Ctrl + U` | Delete to the start of the line |
| `Shift + Tab` | Undo the last edit |

History is shared across panes and holds 100 000 entries.

### The prompt

```
┌─[marc㉿kali]─[~/engagements/box]─[󰘬 main]─[󰦝 10.10.14.7]─[ 10.10.11.42]
└─❯
```

Segments appear only when they apply: the git branch when you are in a repository, the
tunnel address when `tun0` is up, the target when you have set one. The tunnel lookup is
cached for ten seconds, so the prompt never costs you a subprocess per keystroke.

### Aliases

```bash
ls        eza --icons --group-directories-first
ll        eza -lah --icons --git
la        eza -a --icons
tree      eza --tree --level=2
cat       batcat --paging=never
grep      grep --color=auto
cls / c   clear
.. ... ....   cd up one, two, three levels
```

Engagement helpers:

```bash
tun          show the tun0 address
myip         show every non-loopback address
ports        ss -tulpn
serve        python3 -m http.server 80
extractports pull open ports out of an nmap .gnmap/.oG file and copy them to the clipboard
```

Use the real `cat` when you need it:

```bash
/usr/bin/cat filename
```

### Target tracking

Set the box you are working on once and it shows up in the i3 bar, in the tmux status
line, in the prompt, and in `$T`:

```bash
target 10.10.11.42     # set it
target                 # print it
ping -c1 $T            # use it
```

`Super + Shift + T` does the same thing through a Rofi prompt.

### Network variables

Two more live variables, refreshed automatically at most once every 10 seconds so they
never add shell latency:

```bash
echo $V     # tun0 address, empty if the VPN is down
echo $E     # address of the first physical interface (matches the i3 bar)
```

Unlike `$T`, these update on their own as the VPN connects or drops — no need to open a
new shell.

### BloodHound CE (Docker)

`docker-compose.yml` lives at `~/tools/ad-exploitation/bloodhound/`, installed automatically
by `bootstrap.sh` along with Docker itself.

```bash
bloodhound up       # start the stack (postgres, neo4j, bloodhound)
bloodhound down     # stop it
bloodhound creds    # print the admin password from the container logs
```

Log in at `http://localhost:8080/ui/login` with user `admin` and the password from
`bloodhound creds`. It's a one-time password, printed only on the container's first
ever start — after logging in you'll be forced to set a new one. If `bloodhound creds`
comes back empty, the container may still be starting; wait a few seconds and retry.

Common gotcha: `docker compose up` failing with `address already in use` on port `7474`
or `7687` almost always means a native Neo4j install (not Docker) is already listening
on that port. Find and stop it with `sudo ss -tulpn | grep 7474` before retrying.

### Scaffolding a box

```bash
mkt oscp-box
```

Creates and enters `~/engagements/oscp-box/` with `nmap/`, `web/`, `loot/`, `exploits/`
and a `notes.md` skeleton.

### Reloading

```bash
source ~/.zshrc        # apply changes
zsh -n ~/.zshrc         # check syntax
```

---

## Status bar (i3)

Left to right:

| Block | Shows |
| --- | --- |
|  | Current target — hidden until you set one |
|  | `tun0` address, or `vpn down` |
| 󰈀 | Address of the first physical interface |
|  | CPU usage — amber above 60 %, red above 90 % |
|  | Memory in use |
|  | Volume, or `muted` |
|  | Date and time |

The tray sits at the right end and holds `nm-applet`.

To add a block, drop an executable in `i3blocks/scripts/` and add a matching section to
`i3blocks/config` — the `command` line resolves `$BLOCK_NAME` to the filename.

The tmux status line duplicates the VPN address and current target on purpose — you see
one or the other depending on whether a terminal is focused, so the information is never
more than a glance away.

---

## Network management

The NetworkManager applet starts with i3. Click the tray icon to manage Ethernet, Wi-Fi,
VPN profiles and connection settings.

Restart it manually:

```bash
pkill nm-applet
nm-applet &
```

If the tray does not reappear after restarting i3, log out and back in.

---

## VMware integration

Guest integration comes from:

```
open-vm-tools
open-vm-tools-desktop
```

Check the service:

```bash
systemctl status open-vm-tools
```

Clipboard sharing works between the Windows host and Kali. File transfers go through SSH
and WinSCP rather than shared folders:

```bash
sudo systemctl start ssh     # start it when you need it
ip -br address                # find your address
sudo systemctl stop ssh      # stop it when you are done
```

### picom uses `xrender`, not `glx` — this is deliberate

`vmwgfx`, the VMware guest graphics driver, has a real, reproducible kernel-level bug on
recent Kali kernels: heavier GPU-accelerated rendering — from picom's `glx` backend, or
even from Xorg itself under load — can trigger a kernel NULL pointer dereference and
freeze the entire VM, requiring a hard reset. `picom.conf` is pinned to the `xrender`
backend to avoid that code path entirely, not as a fallback for weaker hardware.

**Don't switch it back to `glx`** unless you've confirmed your specific VMware/kernel
combination doesn't hit this bug. `xrender` is slightly less GPU-accelerated but is
correctness-tested against this exact failure mode, and the visual difference is
negligible for a tiling window manager with no blur.

If the VM still feels sluggish, press `Super + Shift + P` to kill the compositor
entirely. Nothing else depends on it.

---

## Wordlists

SecLists installs under:

```
/usr/share/seclists/
```

```
Discovery/  Fuzzing/  Miscellaneous/  Passwords/
Pattern-Matching/  Payloads/  Usernames/  Web-Shells/
```

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

No output from the zsh, tmux or bash checks means no syntax errors.

---

## Security

This repository must never contain:

- SSH private keys
- VPN configuration files
- Passwords or API tokens
- Browser profiles, cookies or active sessions
- Burp project files or CA certificates
- Shell history
- Exam files or target information

`.gitignore` already excludes `burp/`, where `setup-burp.sh` writes the downloaded CA
certificate. Check anyway before every commit:

```bash
grep -RniE \
  'password|passwd|token|secret|api[_-]?key|BEGIN .*PRIVATE KEY' \
  ~/.dotfiles --exclude-dir=.git
```

Note that the target you set with `target` is stored in `~/.cache/oscp-target`, outside
this repository, so it is never committed.

---

## Design philosophy

Every component earns its place by improving speed, stability or usability during
penetration-testing work. What that rules out:

- Blur, animation frameworks and heavyweight compositors
- Plugin collections you do not use
- Workspaces tied to fixed applications
- Background services that are not doing anything
- Any rendering path with a known crash risk in a VM guest, even at the cost of a small
  amount of visual polish

What it allows, and why:

- **A compositor, tuned defensively.** Rounded corners and a 110 ms fade cost a few
  milliseconds and make the whole thing legible at a glance — but only through a backend
  that's been checked against the `vmwgfx` crash above. One keystroke removes the
  compositor entirely if it's ever in doubt.
- **95 % terminal opacity.** Enough to see the grid behind, not enough to hurt a
  screenshot. Also one keystroke away from opaque.
- **A slightly dimmed inactive window.** Firefox, Burp, Wireshark and anything fullscreen
  are excluded, so nothing you read output from is ever dimmed.
- **Status information duplicated across tools, not centralized.** The VPN address and
  current target show up in the i3 bar, the tmux status line, and the shell prompt
  independently, so whichever one is in front of you always has the answer.

