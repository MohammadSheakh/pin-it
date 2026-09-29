#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP="${ROOT}/dist/pinit.zip"
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

"${ROOT}/package.sh"
gnome-extensions install --force "${ZIP}"

echo "Installed ${UUID}."
if gnome-extensions enable "${UUID}" 2>/dev/null; then
  echo "Enabled ${UUID}."
else
  echo "GNOME may need a logout/login before loading a newly installed extension." >&2
  echo "After logging back in, run:" >&2
  echo "  gnome-extensions enable ${UUID}" >&2
fi
