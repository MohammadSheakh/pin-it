#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT}/dist"
OUT="${OUT_DIR}/pinit.zip"
SUMS="${OUT_DIR}/SHA256SUMS"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

for command_name in python3 zip sha256sum; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required packaging command: ${command_name}" >&2
    exit 1
  fi
done

python3 -m json.tool "${ROOT}/metadata.json" >/dev/null

if command -v glib-compile-schemas >/dev/null 2>&1; then
  SCHEMA_TMP="${TMP}/schema-check"
  mkdir -p "${SCHEMA_TMP}"
  cp "${ROOT}/schemas/org.gnome.shell.extensions.pinit.gschema.xml" "${SCHEMA_TMP}/"
  glib-compile-schemas --strict "${SCHEMA_TMP}"
else
  echo "Warning: glib-compile-schemas unavailable; schema compilation was not validated." >&2
fi

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

# GNOME Shell 44+ compiles schemas at install time. Ship only the XML source.
(
  cd "${ROOT}"
  zip -q -9 "${OUT}" \
    extension.js \
    metadata.json \
    schemas/org.gnome.shell.extensions.pinit.gschema.xml
)

if unzip -Z1 "${OUT}" | grep -Fxq 'schemas/gschemas.compiled'; then
  echo "Error: release archive unexpectedly contains schemas/gschemas.compiled" >&2
  exit 1
fi

(
  cd "${OUT_DIR}"
  sha256sum pinit.zip > SHA256SUMS
)

echo "Created ${OUT}"
echo "Created ${SUMS}"
