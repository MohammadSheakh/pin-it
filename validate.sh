#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZIP="${ROOT}/dist/pinit.zip"

python3 -m json.tool "${ROOT}/metadata.json" >/dev/null
bash -n \
  "${ROOT}/install.sh" \
  "${ROOT}/install-github.sh" \
  "${ROOT}/uninstall.sh" \
  "${ROOT}/package.sh" \
  "${ROOT}/validate.sh"

if command -v node >/dev/null 2>&1; then
  node --check "${ROOT}/extension.js" >/dev/null
fi

if command -v glib-compile-schemas >/dev/null 2>&1; then
  TMP="$(mktemp -d)"
  trap 'rm -rf "${TMP}"' EXIT
  cp "${ROOT}/schemas/org.gnome.shell.extensions.pinit.gschema.xml" "${TMP}/"
  glib-compile-schemas --strict "${TMP}"
else
  echo "Warning: glib-compile-schemas unavailable; schema compilation was not validated." >&2
fi

"${ROOT}/package.sh" >/dev/null

if unzip -Z1 "${ZIP}" | grep -Fq 'gschemas.compiled'; then
  echo "Error: package must not ship gschemas.compiled for GNOME Shell 44+." >&2
  exit 1
fi

for required in extension.js metadata.json schemas/org.gnome.shell.extensions.pinit.gschema.xml; do
  if ! unzip -Z1 "${ZIP}" | grep -Fxq "${required}"; then
    echo "Error: package is missing ${required}" >&2
    exit 1
  fi
done

COUNT="$(unzip -Z1 "${ZIP}" | sed '/^$/d' | wc -l | tr -d ' ')"
if [[ "${COUNT}" != "3" ]]; then
  echo "Error: release package contains unexpected files:" >&2
  unzip -Z1 "${ZIP}" >&2
  exit 1
fi

(
  cd "${ROOT}/dist"
  sha256sum --check SHA256SUMS >/dev/null
)

echo "Static validation passed. Real GNOME Shell runtime testing is still required."
