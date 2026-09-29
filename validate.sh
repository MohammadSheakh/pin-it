#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

python3 -m json.tool "${ROOT}/metadata.json" >/dev/null
python3 -m json.tool "${ROOT}/compat/gnome42-44/metadata.json" >/dev/null
bash -n "${ROOT}/install.sh"
bash -n "${ROOT}/install-github.sh"
bash -n "${ROOT}/uninstall.sh"
bash -n "${ROOT}/package.sh"
bash -n "${ROOT}/validate.sh"

if command -v node >/dev/null 2>&1; then
  node --check "${ROOT}/extension.js" >/dev/null
  node --check "${ROOT}/compat/gnome42-44/extension.js" >/dev/null
fi

if command -v glib-compile-schemas >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  cp "${ROOT}/schemas/org.gnome.shell.extensions.pinit.gschema.xml" "${TMP}/"
  glib-compile-schemas --strict "${TMP}"
fi

"${ROOT}/package.sh"

for archive in pinit-modern.zip pinit-legacy.zip; do
  unzip -t "${ROOT}/dist/${archive}" >/dev/null
  unzip -p "${ROOT}/dist/${archive}" metadata.json | python3 -m json.tool >/dev/null
done

if unzip -Z1 "${ROOT}/dist/pinit-modern.zip" | grep -Fxq 'schemas/gschemas.compiled'; then
  echo "Modern package must not contain schemas/gschemas.compiled" >&2
  exit 1
fi

if unzip -Z1 "${ROOT}/dist/pinit-legacy.zip" | grep -Fxq 'schemas/gschemas.compiled'; then
  echo "Legacy package must not contain a precompiled schema database" >&2
  exit 1
fi

echo "Validation passed."
