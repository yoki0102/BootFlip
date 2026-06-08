# BootFlip

![License](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-orange)
![Platform](https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-blue)
![PowerShell](https://img.shields.io/badge/PowerShell-5%2B-5391FE)

A tiny Windows system tray utility for **Windows + Ubuntu dual-boot users**: reboot into Ubuntu with one click — no BIOS keys, no manual menu picking — and stop fighting the clock-drift bug while you're at it.

<p align="center">
  <img src="assets/icon-256.png" alt="BootFlip icon" width="128"/>
</p>

## What it does

- **Switch to Ubuntu** — one click in the tray reboots straight into Ubuntu (one-time, next boot returns to Windows).
- **Switch to Windows** — cancels a pending one-time switch (no reboot).
- **Dual-boot clock fix** — applied automatically by the installer so the system time stays correct after switching back from Ubuntu.

## Why

In a UEFI Windows/Ubuntu dual-boot setup, switching to the other OS usually means:

1. Reboot.
2. Press a function key for the boot menu in the half-second window the firmware allows.
3. Arrow-key to the right entry.

Miss the window — wait through another full boot. BootFlip removes that friction by setting the UEFI `BootNext` variable directly from the running OS, so the next reboot already knows where to go.

The bonus: dual-boot Windows/Linux systems are infamous for showing the wrong time after switching, because Linux stores UTC in the hardware clock and Windows stores local time. BootFlip's installer applies the standard registry fix once, and it's done forever.

## Requirements

- Windows 10 or 11
- UEFI boot (not legacy BIOS — the tool exits with a clear error otherwise)
- Ubuntu installed via its standard UEFI installer (creates an `\EFI\ubuntu\` entry in firmware)
- Administrator access for installation

## Install

1. Clone or download this repo.
2. Move the folder somewhere stable (suggested: `C:\Program Files\BootFlip\`).
3. Double-click `install.bat`. No need to "Run as administrator" — the installer elevates only the steps that require it (one UAC prompt for the clock fix).

The installer:

1. Creates a `BootFlip.lnk` shortcut in your Startup folder (auto-launch on login).
2. Optionally creates a desktop shortcut.
3. **One UAC prompt** to apply the dual-boot clock fix (writes `HKLM\...\TimeZoneInformation\RealTimeIsUniversal = 1`, then forces an NTP resync).
4. Optionally launches the tray immediately.

## Use

Left- or right-click the BootFlip tray icon (the BF logo). Menu:

| Item | Action |
|---|---|
| **Switch to Ubuntu** | Confirm → UAC → 5-second countdown → reboot into Ubuntu. |
| **Switch to Windows** | Cancels a pending one-time switch. No reboot. |
| **Exit** | Quit the tray. |

To abort the 5-second reboot, open an admin command prompt and run `shutdown /a`.

## How it works

| Action | Underlying command |
|---|---|
| Switch to Ubuntu | `bcdedit /set {fwbootmgr} bootsequence {<Ubuntu UEFI GUID>}` then `shutdown /r /t 5` |
| Switch to Windows | `bcdedit /deletevalue {fwbootmgr} bootsequence` |
| Clock fix | Set `HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\RealTimeIsUniversal = 1` (DWORD) + `w32tm /resync /force` |

The Ubuntu UEFI entry is identified by content (the `\EFI\ubuntu\` path or a `description` of `ubuntu`/`GRUB`), **not by the localized field labels in `bcdedit` output**, so it works on Chinese, Japanese, and other non-English Windows installations.

The tray itself runs as a normal user. Only the action scripts elevate via UAC, so you only see a UAC prompt when you actually flip the switch — not at every login.

A single-instance mutex (`BootFlip-Tray-SingleInstance-<username>`) prevents duplicate tray icons if the launcher fires twice.

## Files

```
BootFlip.ps1     Tray UI (PowerShell + WinForms NotifyIcon)
BootFlip.vbs     Silent launcher (no console flash)
do-switch.ps1    Elevated worker (bcdedit / registry / shutdown)
bootflip.ico     Multi-resolution icon (16-256 px)
install.bat      Setup
uninstall.bat    Removes shortcuts
debug.bat        Runs BootFlip.ps1 in a visible PowerShell window for troubleshooting
assets/          Icon previews used in this README
```

## Troubleshooting

**Tray icon not showing.** Click the `^` arrow in the system tray to expand hidden icons. Drag it out to keep it visible. Or double-click `debug.bat` to launch in a visible window and see errors.

**"Ubuntu entry not found" error.** Open `%TEMP%\bcdedit-firmware-dump.txt` for the full `bcdedit /enum firmware` output. If there's truly no `\EFI\ubuntu\` entry, GRUB's UEFI registration has been wiped (common after Windows feature updates or BIOS resets). Boot an Ubuntu Live USB and run `boot-repair`.

**Switch to Ubuntu reboots but lands back in Windows.** A few OEM firmware implementations don't honor UEFI `BootNext` reliably. Workaround: press your boot-menu key (commonly F12, F8, or Esc) at power-on and select Ubuntu manually.

**Time is still wrong after using the clock fix.** Some antivirus blocks PowerShell from writing to `HKLM`. Allow it and re-run `install.bat`, or manually:
```powershell
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\TimeZoneInformation' `
                 -Name RealTimeIsUniversal -Value 1 -Type DWord -Force
w32tm /resync /force
```

## Uninstall

Run `uninstall.bat`. It removes the Startup and desktop shortcuts. The program files are left in place — delete the folder yourself. The clock fix is **not** reverted; set the registry value back to `0` if you need to.

## License

[PolyForm Noncommercial 1.0.0](LICENSE). Free for personal, academic, charitable, and other noncommercial use. Commercial use requires a separate agreement.
