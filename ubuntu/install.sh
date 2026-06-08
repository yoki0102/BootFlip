#!/usr/bin/env bash
# BootFlip — Ubuntu installer
# Installs the bootflip CLI, a scoped sudoers rule, and the GNOME Shell extension.
set -euo pipefail

[ "$EUID" -ne 0 ] || { echo "Run as a normal user. Sudo is invoked only for the privileged steps." >&2; exit 1; }
[ -d /sys/firmware/efi ] || { echo "Not booted in UEFI mode. BootFlip needs UEFI." >&2; exit 1; }
command -v efibootmgr >/dev/null || { echo "efibootmgr missing. Install with: sudo apt install efibootmgr" >&2; exit 1; }
command -v gnome-shell >/dev/null || { echo "GNOME Shell not found. BootFlip Ubuntu is a GNOME extension." >&2; exit 1; }

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UUID="bootflip@yoki0102"
EXT_DIR="$HOME/.local/share/gnome-shell/extensions/$UUID"
USER_NAME="$(id -un)"

echo "[1/4] Checking UEFI entries..."
EFI=$(sudo efibootmgr)
echo "$EFI" | grep -qi 'Windows Boot Manager'  || { echo "  Windows Boot Manager entry not found — aborting." >&2; exit 2; }
echo "$EFI" | grep -qiE 'ubuntu|GRUB'           || { echo "  Ubuntu/GRUB entry not found — aborting." >&2; exit 2; }
echo "  Windows  OK"
echo "  Ubuntu   OK"

echo "[2/4] Installing /usr/local/bin/bootflip..."
sudo install -m 0755 -o root -g root "$DIR/bootflip" /usr/local/bin/bootflip

echo "[3/4] Installing sudoers rule (/etc/sudoers.d/bootflip)..."
TMP=$(mktemp); trap 'rm -f "$TMP"' EXIT
printf '%s ALL=(root) NOPASSWD: /usr/local/bin/bootflip\n' "$USER_NAME" > "$TMP"
sudo visudo -cf "$TMP" >/dev/null
sudo install -m 0440 -o root -g root "$TMP" /etc/sudoers.d/bootflip

echo "[4/4] Installing GNOME Shell extension ($UUID)..."
mkdir -p "$EXT_DIR"
cp -r "$DIR/$UUID/." "$EXT_DIR/"
gnome-extensions enable "$UUID" 2>/dev/null || true

echo
echo "Installed."
echo "Restart GNOME Shell to load the icon:"
echo "  X11    : press Alt+F2, type 'r', press Enter."
echo "  Wayland: log out and log back in."
echo "Then click the BootFlip icon on the top-right of the panel."
