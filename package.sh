#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="${ROOT}/dist"
SUMS="${OUT_DIR}/SHA256SUMS"
TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT

for command_name in python3 zip unzip sha256sum; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required packaging command: ${command_name}" >&2
    exit 1
  fi
done

python3 -m json.tool "${ROOT}/metadata.json" >/dev/null
python3 -m json.tool "${ROOT}/compat/gnome42-44/metadata.json" >/dev/null

rm -rf "${OUT_DIR}"
mkdir -p "${OUT_DIR}"

# Validate the schema when the compiler is available, but do not ship a compiled database.
if command -v glib-compile-schemas >/dev/null 2>&1; then
  SCHEMA_CHECK="${TMP}/schema-check"
  mkdir -p "${SCHEMA_CHECK}"
  cp "${ROOT}/schemas/org.gnome.shell.extensions.pinit.gschema.xml" "${SCHEMA_CHECK}/"
  glib-compile-schemas --strict "${SCHEMA_CHECK}"
fi

# Modern GNOME 45+ package.
MODERN_STAGE="${TMP}/modern"
mkdir -p "${MODERN_STAGE}/schemas"
cp "${ROOT}/extension.js" "${MODERN_STAGE}/extension.js"
cp "${ROOT}/metadata.json" "${MODERN_STAGE}/metadata.json"
cp "${ROOT}/schemas/org.gnome.shell.extensions.pinit.gschema.xml" "${MODERN_STAGE}/schemas/"
(
  cd "${MODERN_STAGE}"
  zip -q -9 -r "${OUT_DIR}/pinit-modern.zip" .
)

# GNOME 42-44 package. The installer compiles the XML schema locally after install.
LEGACY_STAGE="${TMP}/legacy"
mkdir -p "${LEGACY_STAGE}/schemas"
cp "${ROOT}/compat/gnome42-44/extension.js" "${LEGACY_STAGE}/extension.js"
cp "${ROOT}/compat/gnome42-44/metadata.json" "${LEGACY_STAGE}/metadata.json"
cp "${ROOT}/schemas/org.gnome.shell.extensions.pinit.gschema.xml" "${LEGACY_STAGE}/schemas/"
(
  cd "${LEGACY_STAGE}"
  zip -q -9 -r "${OUT_DIR}/pinit-legacy.zip" .
)

(
  cd "${OUT_DIR}"
  sha256sum pinit-modern.zip pinit-legacy.zip > SHA256SUMS
)

echo "Created ${OUT_DIR}/pinit-modern.zip"
echo "Created ${OUT_DIR}/pinit-legacy.zip"
echo "Created ${SUMS}"
