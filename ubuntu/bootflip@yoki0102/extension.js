'use strict';

const { GObject, St } = imports.gi;
const Gio = imports.gi.Gio;
const Main = imports.ui.main;
const PanelMenu = imports.ui.panelMenu;
const PopupMenu = imports.ui.popupMenu;
const Util = imports.misc.util;
const ExtensionUtils = imports.misc.extensionUtils;
const Me = ExtensionUtils.getCurrentExtension();

let _indicator = null;

const BootFlip = GObject.registerClass(
class BootFlip extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'BootFlip', false);

        this.add_child(new St.Icon({
            gicon: Gio.icon_new_for_string(Me.path + '/icon.png'),
            style_class: 'system-status-icon',
        }));

        const winItem = new PopupMenu.PopupMenuItem('Switch to Windows');
        winItem.connect('activate', () => {
            Util.spawnCommandLine('sudo /usr/local/bin/bootflip win -r');
        });
        this.menu.addMenuItem(winItem);

        // Mirror of the Windows side: "Switch to Ubuntu" here cancels any
        // pending one-shot switch (next boot stays on the default — Ubuntu).
        const ubuntuItem = new PopupMenu.PopupMenuItem('Switch to Ubuntu');
        ubuntuItem.connect('activate', () => {
            Util.spawnCommandLine('sudo /usr/local/bin/bootflip cancel');
        });
        this.menu.addMenuItem(ubuntuItem);
    }
});

function init() {}

function enable() {
    _indicator = new BootFlip();
    Main.panel.addToStatusArea('bootflip', _indicator);
}

function disable() {
    if (_indicator !== null) {
        _indicator.destroy();
        _indicator = null;
    }
}
