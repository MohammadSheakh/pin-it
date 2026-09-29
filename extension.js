import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import St from 'gi://St';

import {Extension, gettext as _} from 'resource:///org/gnome/shell/extensions/extension.js';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';

const KEYBINDING = 'toggle-pin';
const MAX_WINDOW_LABEL_LENGTH = 80;

class PinController {
    getFocusedWindow() {
        return global.display.get_focus_window();
    }

    describe(window) {
        if (!window)
            return _('None');

        const title = window.get_title()?.trim();
        const appClass = window.get_wm_class()?.trim();
        const rawLabel = title || appClass || _('Application window');

        if (rawLabel.length <= MAX_WINDOW_LABEL_LENGTH)
            return rawLabel;

        return `${rawLabel.slice(0, MAX_WINDOW_LABEL_LENGTH - 1)}…`;
    }

    isPinnable(window) {
        if (!window)
            return false;

        if (window.is_override_redirect?.())
            return false;

        if (window.is_skip_taskbar?.())
            return false;

        return true;
    }

    isPinned(window) {
        return this.isPinnable(window) && Boolean(window.is_above?.());
    }

    toggleFocused() {
        const window = this.getFocusedWindow();
        if (!this.isPinnable(window))
            return false;

        try {
            if (this.isPinned(window))
                window.unmake_above();
            else
                window.make_above();

            return true;
        } catch (error) {
            console.error(`PinIt: failed to toggle focused window: ${error}`);
            return false;
        }
    }
}

class PinIndicator extends PanelMenu.Button {
    constructor(controller) {
        super(0.0, 'PinIt', false);

        this._controller = controller;
        this._focusSignal = 0;
        this._aboveSignal = 0;
        this._trackedWindow = null;

        this.add_child(new St.Icon({
            icon_name: 'view-pin-symbolic',
            style_class: 'system-status-icon',
        }));

        this._statusItem = new PopupMenu.PopupMenuItem('', {
            reactive: false,
            can_focus: false,
        });
        this.menu.addMenuItem(this._statusItem);

        this._toggleItem = new PopupMenu.PopupMenuItem(_('Pin focused window'));
        this._toggleItem.connect('activate', () => {
            this._controller.toggleFocused();
            this.refresh();
        });
        this.menu.addMenuItem(this._toggleItem);

        this.menu.connect('open-state-changed', (_menu, isOpen) => {
            if (isOpen)
                this.refresh();
        });

        this._focusSignal = global.display.connect(
            'notify::focus-window',
            () => this.refresh()
        );

        this.refresh();
    }

    _trackWindow(window) {
        if (window === this._trackedWindow)
            return;

        if (this._trackedWindow && this._aboveSignal) {
            this._trackedWindow.disconnect(this._aboveSignal);
            this._aboveSignal = 0;
        }

        this._trackedWindow = window;

        if (this._trackedWindow) {
            this._aboveSignal = this._trackedWindow.connect(
                'notify::above',
                () => this.refresh()
            );
        }
    }

    refresh() {
        const window = this._controller.getFocusedWindow();
        this._trackWindow(window);

        const pinnable = this._controller.isPinnable(window);
        const name = this._controller.describe(window);
        this._statusItem.label.text = pinnable
            ? `${_('Focused')}: ${name}`
            : _('No pinnable application window focused');
        this._toggleItem.label.text = this._controller.isPinned(window)
            ? _('Unpin focused window')
            : _('Pin focused window');
        this._toggleItem.setSensitive(pinnable);
    }

    destroy() {
        if (this._trackedWindow && this._aboveSignal) {
            this._trackedWindow.disconnect(this._aboveSignal);
            this._aboveSignal = 0;
        }
        this._trackedWindow = null;

        if (this._focusSignal) {
            global.display.disconnect(this._focusSignal);
            this._focusSignal = 0;
        }

        this._controller = null;
        super.destroy();
    }
}

export default class PinItExtension extends Extension {
    enable() {
        this._settings = this.getSettings();
        this._controller = new PinController();
        this._indicator = new PinIndicator(this._controller);

        Main.wm.addKeybinding(
            KEYBINDING,
            this._settings,
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            () => {
                this._controller.toggleFocused();
                this._indicator?.refresh();
            }
        );

        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        Main.wm.removeKeybinding(KEYBINDING);

        this._indicator?.destroy();
        this._indicator = null;
        this._controller = null;
        this._settings = null;
    }
}
