# Publishing PinIt

## Public identity

PinIt now uses its permanent public UUID:

```text
pinit@mohammadsheakh.github.io
```

Repository:

```text
https://github.com/MohammadSheakh/pin-it
```

Do not change the UUID after public release. GNOME treats a different UUID as a different extension.

## GitHub Releases

Every release must contain:

```text
pinit-legacy.zip
pinit-modern.zip
SHA256SUMS
```

Compatibility:

- `pinit-legacy.zip` — GNOME 42–44
- `pinit-modern.zip` — GNOME 45–50

The remote installer selects the correct package automatically.

## Release procedure

Before tagging:

```bash
./validate.sh
```

Commit and push all source changes, then create a tag:

```bash
git add .
git commit -m "release: PinIt v0.2.0"
git push origin main
git tag v0.2.0
git push origin v0.2.0
```

The workflow in `.github/workflows/release.yml` validates the project, creates both packages, generates checksums, and publishes the GitHub Release.

## Migration from development UUID

Early development builds used:

```text
pinit@local.dev
```

The current local and GitHub installers automatically disable and uninstall that old development UUID before installing the permanent public UUID.

Users can also remove it manually:

```bash
gnome-extensions disable pinit@local.dev 2>/dev/null || true
gnome-extensions uninstall pinit@local.dev 2>/dev/null || true
```

## Official GNOME distribution

After runtime verification on supported Shell versions, submit the validated package(s) to extensions.gnome.org according to the GNOME extension review process.

The metadata already contains the permanent UUID and public repository URL required for public distribution.

## Runtime release gate

Do not describe a release as production-ready until these pass on real GNOME sessions:

- Clean install succeeds.
- Extension enables without `ERROR` or `OUT OF DATE`.
- Panel icon renders.
- `Ctrl+Alt+P` pins the focused window.
- Repeating the shortcut unpins it.
- Panel menu toggles the focused window.
- State updates if GNOME's own Always on Top action changes the window.
- Disabling/re-enabling PinIt does not alter existing window state.
- Logout/login preserves installation.
- Uninstall works cleanly.
- GNOME Shell journal contains no PinIt errors.

At minimum, verify one real machine from the legacy line (GNOME 42–44) and one from the modern line (GNOME 45+).
