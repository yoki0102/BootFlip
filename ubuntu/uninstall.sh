#!/usr/bin/env bash
# BootFlip — Ubuntu uninstaller
set -euo pipefail

UUID="bootflip@yoki0102"

gnome-extensions disable "$UUID" 2>/dev/null || true
rm -rf "$HOME/.local/share/gnome-shell/extensions/$UUID"
sudo rm -f /usr/local/bin/bootflip /etc/sudoers.d/bootflip

echo "Uninstalled."
echo "Restart GNOME Shell (Alt+F2, r, Enter on X11) to remove the icon."
