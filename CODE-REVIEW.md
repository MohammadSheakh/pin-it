# PinIt — Brutal Code Review

## Verdict
The original draft was a good prototype, not a production-ready extension.

The core architecture was correct: use a GNOME Shell extension and Mutter's `Meta.Window.make_above()` / `unmake_above()` rather than Electron or an external Wayland automation tool.

However, several gaps needed correction before the project could honestly be called release-quality.

## Fixed gaps

### 1. Packaging shipped the wrong schema artifact
The old packager could include `schemas/gschemas.compiled`.

For the GNOME 44+ installation flow we target, the package should ship the schema XML and let GNOME's extension tooling compile it during installation.

**Fixed:** the ZIP now contains only the schema XML.

### 2. Installer depended on `rsync`
That was unnecessary and could fail on otherwise valid Ubuntu systems.

**Fixed:** installation now uses `gnome-extensions install --force`.

### 3. Installer could claim success without a usable schema
The old installer only warned when `glib-compile-schemas` was unavailable while directly copying source files.

**Fixed:** installation delegates schema compilation to GNOME's official extension installer.

### 4. Stale panel state
If Always on Top was changed outside PinIt, the menu could remain stale until focus changed or the menu was reopened.

**Fixed:** PinIt now watches `notify::above` for the focused window and updates the menu state.

### 5. Long window titles could make the menu ugly
The original code printed arbitrary title length.

**Fixed:** panel display labels are bounded and ellipsized.

### 6. Toggle failure could bubble out
The original controller assumed every Mutter operation would succeed.

**Fixed:** toggle errors are contained and logged rather than crashing the extension path.

### 7. Deprecated metadata field
The original metadata included a manual `version` field even though modern E.G.O. treats it as internal/deprecated.

**Fixed:** removed.

### 8. Compatibility claims were too confident
The project listed GNOME Shell 45–50 without making clear that this environment had not runtime-tested those releases.

**Fixed:** documentation now distinguishes a metadata compatibility target from verified support, and runtime compatibility is a release gate.

### 9. Static validation was ad hoc
There was no repeatable one-command validation.

**Fixed:** `validate.sh` now checks metadata JSON, shell syntax, JavaScript syntax when available, package contents, and schema compilation when GLib tools are available.

## Things intentionally NOT added
These would violate the agreed product scope:

- automatic pinning;
- remembered apps;
- per-app rules;
- startup restore;
- workspace stickiness;
- opacity/position controls;
- background daemon;
- Electron/Node runtime;
- notification spam;
- preferences UI.

## Remaining gaps before a real v1 release
These cannot be truthfully closed inside a non-GNOME container:

1. Real Wayland runtime test.
2. Real GNOME panel rendering test.
3. Shortcut conflict test on Ubuntu.
4. Test external state changes using GNOME's native Always on Top action.
5. Journal check for GJS warnings/errors.
6. Verify every GNOME version retained in `metadata.json`, or remove versions we do not test.
7. Test install → enable → disable → re-enable → uninstall lifecycle.

Until those pass, call this **release candidate / implementation complete**, not production-verified.
