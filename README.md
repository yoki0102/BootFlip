# BootFlip

![License](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-orange)
![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11%20%7C%20Ubuntu%20(GNOME)-blue)

One-click reboot to the *other* OS on a Windows + Ubuntu UEFI dual-boot machine. No BIOS keys, no firmware menu, no missed half-second countdown.

<p align="center">
  <img src="assets/icon-256.png" alt="BootFlip icon" width="128"/>
</p>

Two halves of the same idea:

| Side | Lives in | What it adds |
|---|---|---|
| **Windows** | system tray (bottom-right) | tray menu → reboot into Ubuntu |
| **Ubuntu**  | GNOME top bar (top-right)   | panel menu → reboot into Windows |

Both work by writing the UEFI **one-shot boot variable**. The choice applies to the *next* reboot only — the default boot order is never modified.

## How it works

| Action | Underlying command |
|---|---|
| Windows → Ubuntu | `bcdedit /set {fwbootmgr} bootsequence {<ubuntu GUID>}` then `shutdown /r /t 5` |
| Windows: cancel  | `bcdedit /deletevalue {fwbootmgr} bootsequence` |
| Ubuntu → Windows | `efibootmgr -n <Windows entry>` then `systemctl reboot` |
| Ubuntu: cancel   | `efibootmgr -N` |

Entry detection is locale-agnostic — it matches `\EFI\ubuntu\` / `Windows Boot Manager` / `GRUB`, not localized labels — so it works on Chinese, Japanese, and other non-English Windows installations.

## Requirements

- UEFI firmware (not legacy BIOS). The installers refuse to run otherwise.
- Both OSes installed via their standard UEFI installers (firmware has `\EFI\Microsoft\` *and* `\EFI\ubuntu\` entries).
- **Windows side:** Windows 10 or 11, PowerShell 5+, administrator access for install.
- **Ubuntu side:** GNOME Shell 3.36+ (tested on Ubuntu 20.04), `efibootmgr` installed.

---

## Windows

### Install

1. Clone or download this repo.
2. Move the `windows/` folder somewhere stable (suggested: `C:\Program Files\BootFlip\`).
3. Double-click `windows/install.bat`. The installer elevates only the steps that need it (one UAC prompt for the optional clock fix).

The installer:

1. Creates a startup shortcut so the tray launches on login.
2. Optionally creates a desktop shortcut.
3. Optionally applies the **dual-boot clock fix** — sets `HKLM\...\TimeZoneInformation\RealTimeIsUniversal = 1` so Windows reads the hardware clock as UTC (matching Ubuntu). Stops the time-drift that dual-boot setups are notorious for.
4. Optionally launches the tray immediately.

### Use

Click the BootFlip tray icon (BF logo, bottom-right of the screen).

| Menu item | Action |
|---|---|
| **Switch to Ubuntu** | Confirm → UAC → 5-second countdown → reboot into Ubuntu. |
| **Switch to Windows** | Cancels any pending one-shot switch. No reboot. |
| **Exit** | Quit the tray. |

To abort the 5-second countdown: open an admin command prompt and run `shutdown /a`.

### Uninstall

Run `windows/uninstall.bat`. It removes the shortcuts. The program files are left in place — delete the folder yourself. The clock-fix registry value is left intact.

### Files

```
windows/
├── BootFlip.ps1     Tray UI (PowerShell + WinForms NotifyIcon)
├── BootFlip.vbs     Silent launcher (no console flash)
├── do-switch.ps1    Elevated worker (bcdedit / registry / shutdown)
├── bootflip.ico     Multi-resolution tray icon (16–256 px)
├── install.bat      Setup
├── uninstall.bat    Removes shortcuts
└── debug.bat        Runs the tray in a visible PowerShell window
```

---

## Ubuntu

A GNOME Shell extension that adds a BootFlip icon to the right side of the top bar.

### Install

```bash
git clone https://github.com/yoki0102/BootFlip.git
cd BootFlip/ubuntu
./install.sh
```

Then restart GNOME Shell:

- **X11**: press `Alt+F2`, type `r`, press Enter.
- **Wayland**: log out and log back in.

The installer:

1. Installs `/usr/local/bin/bootflip` (root-owned) — runs `efibootmgr -n` for the right entry.
2. Drops a scoped sudoers rule at `/etc/sudoers.d/bootflip` so the extension can invoke the script without a password prompt.
3. Copies the extension to `~/.local/share/gnome-shell/extensions/bootflip@yoki0102/` and enables it.

### Use

Click the BootFlip icon (top-right of the panel).

| Menu item | Action |
|---|---|
| **Switch to Windows**     | Sets the one-shot `BootNext` to Windows and reboots immediately. |
| **Cancel pending switch** | Clears any pending `BootNext`. No reboot. |

### Uninstall

```bash
cd BootFlip/ubuntu && ./uninstall.sh
```

### Files

```
ubuntu/
├── install.sh            Installer
├── uninstall.sh          Reverses the install
├── bootflip              Root-only CLI: efibootmgr -n + reboot
└── bootflip@yoki0102/    GNOME Shell extension
    ├── metadata.json
    ├── extension.js
    └── icon.png
```

---

## Troubleshooting

**Windows: tray icon not showing.** Click the `^` arrow in the system tray to expand hidden icons, and drag BootFlip out. To see errors, run `windows/debug.bat` (launches the tray in a visible PowerShell window).

**Windows: "Ubuntu entry not found".** Open `%TEMP%\bcdedit-firmware-dump.txt` for the full `bcdedit /enum firmware` output. If there really is no `\EFI\ubuntu\` entry, GRUB's UEFI registration has been wiped (common after a Windows feature update or BIOS reset). Boot an Ubuntu Live USB and run `boot-repair`.

**Either side: switch reboots but lands back where you started.** A few OEM firmwares ignore the one-shot variable. Workaround: at power-on, press the boot-menu key (often F12, F8, or Esc) and pick manually.

**Ubuntu: clicking the menu does nothing.** Check the journal: `journalctl -t bootflip -n 20`. If there is no entry at all, the sudoers rule isn't loading — verify `/etc/sudoers.d/bootflip` exists and is mode `0440`.

**Windows time is wrong after switching back from Ubuntu.** Re-run `windows/install.bat` (the clock-fix step), or apply it manually in an admin PowerShell:

```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' `
                 -Name RealTimeIsUniversal -Value 1 -Type DWord -Force
w32tm /resync /force
```

## License

[PolyForm Noncommercial 1.0.0](LICENSE). Free for personal, academic, charitable, and other noncommercial use. Commercial use requires a separate agreement.
