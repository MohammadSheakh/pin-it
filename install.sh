#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UUID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["uuid"])' "${ROOT}/metadata.json")"

for command_name in python3 gnome-extensions gnome-shell; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    echo "PinIt must be installed from a GNOME desktop session with GNOME Shell tools available." >&2
    exit 1
  fi
done

if [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* && "${XDG_CURRENT_DESKTOP:-}" != *Ubuntu* ]]; then
  echo "Warning: current desktop does not report GNOME/Ubuntu (${XDG_CURRENT_DESKTOP:-unknown})." >&2
fi

SHELL_VERSION="$(gnome-shell --version 2>/dev/null || true)"
SHELL_MAJOR="$(printf '%s\n' "${SHELL_VERSION}" | sed -nE 's/.* ([0-9]+)(\.[0-9]+)?.*/\1/p')"

if [[ -z "${SHELL_MAJOR}" ]]; then
  echo "Could not determine GNOME Shell version from: ${SHELL_VERSION}" >&2
  exit 1
fi

"${ROOT}/package.sh"

if (( SHELL_MAJOR >= 42 && SHELL_MAJOR <= 44 )); then
  ZIP="${ROOT}/dist/pinit-legacy.zip"
elif (( SHELL_MAJOR >= 45 && SHELL_MAJOR <= 50 )); then
  ZIP="${ROOT}/dist/pinit-modern.zip"
else
  echo "Unsupported GNOME Shell major version: ${SHELL_MAJOR}" >&2
  echo "PinIt currently supports GNOME 42 through 50." >&2
  exit 1
fi

echo "Detected ${SHELL_VERSION}; installing $(basename "${ZIP}")."

# Remove the pre-public development UUID if it is still installed.
OLD_UUID="pinit@local.dev"
if [[ "${UUID}" != "${OLD_UUID}" ]] && gnome-extensions list 2>/dev/null | grep -Fxq "${OLD_UUID}"; then
  echo "Removing previous development install ${OLD_UUID}."
  gnome-extensions disable "${OLD_UUID}" 2>/dev/null || true
  gnome-extensions uninstall "${OLD_UUID}" 2>/dev/null || true
fi

gnome-extensions install --force "${ZIP}"

if (( SHELL_MAJOR >= 42 && SHELL_MAJOR <= 44 )); then
  if ! command -v glib-compile-schemas >/dev/null 2>&1; then
    echo "GNOME 42-44 requires glib-compile-schemas (package: libglib2.0-bin)." >&2
    exit 1
  fi
  EXT_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"
  if [[ -d "${EXT_DIR}/schemas" ]]; then
    glib-compile-schemas "${EXT_DIR}/schemas"
  fi
fi

echo "Installed ${UUID}."
if gnome-extensions enable "${UUID}" 2>/dev/null; then
  echo "Enabled ${UUID}."
else
  echo "GNOME may need a logout/login before loading a newly installed extension." >&2
  echo "After logging back in, run:" >&2
  echo "  gnome-extensions enable ${UUID}" >&2
fi
