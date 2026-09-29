# PinIt

PinIt is a deliberately small GNOME Shell extension for Ubuntu/GNOME. It manually toggles **Always on Top** for the currently focused application window.

## Product rule
**Nothing automatic.**

PinIt does not remember applications, create rules, auto-pin windows, move windows between workspaces, or change size, position, or opacity. A window changes only after an explicit user action. Disabling PinIt does not automatically unpin windows.

## Usage

### Keyboard
1. Focus an application window.
2. Press `Ctrl+Alt+P` to pin it.
3. Press `Ctrl+Alt+P` again to unpin it.

### Mouse
1. Focus an application window.
2. Click the PinIt icon in the GNOME top panel.
3. Choose `Pin focused window` or `Unpin focused window`.

PinIt ignores special/override-redirect and skip-taskbar windows rather than trying to modify Shell/internal surfaces.

## Requirements
- GNOME Shell 45–50 is the current compatibility target.
- Real runtime verification should be performed on each version before advertising it as tested.
- `gnome-extensions` is required for installation.

## Local validation

```bash
./validate.sh
```

The release package is created as:

```text
dist/pinit.zip
dist/SHA256SUMS
```

The archive intentionally contains only:

```text
extension.js
metadata.json
schemas/org.gnome.shell.extensions.pinit.gschema.xml
```

For GNOME Shell 44+, the schema XML should be shipped and the installer/extension manager compiles it. `gschemas.compiled` is not included in the release archive.

## Install from local source

```bash
chmod +x install.sh package.sh validate.sh uninstall.sh install-github.sh
./install.sh
```

If GNOME does not see the new extension immediately, log out and back in once, then run:

```bash
gnome-extensions enable "$(python3 -c 'import json; print(json.load(open("metadata.json"))["uuid"])')"
```

## Install later from GitHub Releases

Once this project is pushed to a public GitHub repository and a release exists, users can install the latest release from Terminal.

Safer two-step method:

```bash
curl -fsSLO https://raw.githubusercontent.com/OWNER/REPOSITORY/main/install-github.sh
chmod +x install-github.sh
./install-github.sh OWNER/REPOSITORY
```

Or, if you accept running the repository installer directly:

```bash
curl -fsSL https://raw.githubusercontent.com/OWNER/REPOSITORY/main/install-github.sh | bash -s -- OWNER/REPOSITORY
```

The installer downloads `pinit.zip` and `SHA256SUMS` from the latest GitHub Release, verifies the SHA-256 checksum, reads the UUID from the package, installs it with `gnome-extensions install --force`, and attempts to enable it.

## Official GNOME distribution

After runtime testing, PinIt can also be submitted to **extensions.gnome.org**. That is the official GNOME Shell extension distribution channel and includes review.

Before that public submission, `metadata.json` must have:
- a permanent globally unique UUID using a namespace you control;
- a valid project/repository `url`.

Do not publicly release using the development UUID `pinit@local.dev`.

## Uninstall

```bash
./uninstall.sh
```

## Debugging

```bash
gnome-shell --version
echo "$XDG_SESSION_TYPE"
gnome-extensions info pinit@local.dev
journalctl --user -f -o cat /usr/bin/gnome-shell
```

When the public UUID changes, use that UUID in the `gnome-extensions info` command.

## Project docs
- `PRD.md`
- `IMPLEMENTATION-CHECKLIST.md`
- `CODE-REVIEW.md`
- `PUBLISHING.md`
