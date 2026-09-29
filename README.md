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

PinIt ignores override-redirect windows rather than trying to modify Shell/internal surfaces.

## Compatibility

PinIt publishes two builds under the same permanent extension UUID:

- `pinit-legacy.zip` — GNOME Shell 42–44
- `pinit-modern.zip` — GNOME Shell 45–50

Ubuntu 22.04 / GNOME 42 uses the legacy package. The GitHub installer detects `gnome-shell --version` automatically and downloads the correct package.

Permanent UUID:

```text
pinit@mohammadsheakh.github.io
```

Project repository:

```text
https://github.com/MohammadSheakh/pin-it
```

## Install from GitHub Releases

Recommended two-step method:

```bash
curl -fsSLO https://raw.githubusercontent.com/MohammadSheakh/pin-it/main/install-github.sh
chmod +x install-github.sh
./install-github.sh MohammadSheakh/pin-it
```

Or one command:

```bash
curl -fsSL https://raw.githubusercontent.com/MohammadSheakh/pin-it/main/install-github.sh \
  | bash -s -- MohammadSheakh/pin-it
```

The installer:

1. Detects the GNOME Shell major version.
2. Downloads `pinit-legacy.zip` or `pinit-modern.zip` from the latest release.
3. Downloads `SHA256SUMS`.
4. Verifies the selected package.
5. Removes the old development install `pinit@local.dev` if present.
6. Installs the permanent extension UUID.
7. Compiles the local schema on GNOME 42–44.
8. Attempts to enable the extension.

A logout/login may be required after first installation.

## Local development

Validate and package:

```bash
./validate.sh
```

Generated release artifacts:

```text
dist/pinit-legacy.zip
dist/pinit-modern.zip
dist/SHA256SUMS
```

Install the correct local build for the current GNOME version:

```bash
chmod +x install.sh package.sh validate.sh uninstall.sh install-github.sh
./install.sh
```

## Verify

```bash
gnome-shell --version
gnome-extensions info pinit@mohammadsheakh.github.io
```

For logs:

```bash
journalctl --user -f -o cat /usr/bin/gnome-shell
```

## Uninstall

From the source repository:

```bash
./uninstall.sh
```

Or directly:

```bash
gnome-extensions disable pinit@mohammadsheakh.github.io 2>/dev/null || true
gnome-extensions uninstall pinit@mohammadsheakh.github.io
```

## Release

The GitHub Actions workflow publishes both compatibility packages whenever a `v*` tag is pushed.

Example:

```bash
git tag v0.2.0
git push origin v0.2.0
```

The release should contain:

```text
pinit-legacy.zip
pinit-modern.zip
SHA256SUMS
```

## Project docs

- `PRD.md`
- `IMPLEMENTATION-CHECKLIST.md`
- `CODE-REVIEW.md`
- `PUBLISHING.md`
