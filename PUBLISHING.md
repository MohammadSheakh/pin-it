# Publishing PinIt

## Recommended distribution strategy

Use two channels:

1. **GitHub Releases** first — source hosting, version history, checksums, and easy terminal installation.
2. **extensions.gnome.org** after runtime testing — the official reviewed GNOME extension channel.

## Before the first public release

The current UUID, `pinit@local.dev`, is development-only.

GNOME requires a globally unique UUID in the form `extension-id@namespace`, and the namespace should be under your control. Good examples are based on a GitHub account namespace such as:

```text
pinit@YOUR_GITHUB_USERNAME.github.io
```

Before public release:

1. Change only `metadata.json` to the permanent UUID.
2. Add the public repository URL to `metadata.json` as `url`.
3. Run `./validate.sh`.
4. Perform the runtime release checklist.

The scripts no longer hardcode the UUID; local install/uninstall read it from `metadata.json`, and the remote installer reads it from the release package.

## GitHub Releases

This repository contains `.github/workflows/release.yml`.

After pushing the source to GitHub, creating a tag such as:

```bash
git tag v0.1.0
git push origin v0.1.0
```

will run validation and publish these stable release assets:

```text
pinit.zip
SHA256SUMS
```

Stable asset names are intentional: terminal installation can always target the latest release without knowing the version number.

### Terminal installation

```bash
curl -fsSLO https://raw.githubusercontent.com/OWNER/REPOSITORY/main/install-github.sh
chmod +x install-github.sh
./install-github.sh OWNER/REPOSITORY
```

The installer verifies `SHA256SUMS` before installing the archive.

## extensions.gnome.org

For an official release, submit the exact validated `dist/pinit.zip` package to extensions.gnome.org.

On GNOME versions that provide the upload command, this can be done with:

```bash
gnome-extensions upload --accept-tos dist/pinit.zip
```

Interactive credentials are safer than passing a password on the command line.

GNOME review requires accurate metadata. In particular, the `url` must point to the real public project/repository, and the UUID must use a namespace under your control.

## Runtime release gate

Do not publish a version as production-ready until all of these pass on a real GNOME session:

- Install from a clean user profile.
- Enable successfully.
- Panel icon renders correctly.
- `Ctrl+Alt+P` pins the focused app window.
- Repeating the shortcut unpins it.
- Panel menu pin/unpin works.
- State updates if GNOME's own Always on Top action changes the window.
- Special/Shell windows are not modified.
- Disable/re-enable does not alter existing window state.
- Logout/login preserves extension installation.
- Uninstall removes the extension cleanly.
- GNOME Shell journal contains no PinIt errors during the above tests.

## Compatibility release assets

Every GitHub release must include:

- `pinit-legacy.zip` for GNOME 42-44
- `pinit-modern.zip` for GNOME 45-50
- `SHA256SUMS` covering both ZIP files

Do not rename these assets without updating `install-github.sh`.
