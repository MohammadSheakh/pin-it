#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UUID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["uuid"])' "${ROOT}/metadata.json")"

if ! command -v gnome-extensions >/dev/null 2>&1; then
  echo "gnome-extensions was not found." >&2
  exit 1
fi

gnome-extensions disable "${UUID}" 2>/dev/null || true
gnome-extensions uninstall "${UUID}" 2>/dev/null || true

echo "Uninstalled ${UUID}."
