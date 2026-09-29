#!/usr/bin/env bash
set -euo pipefail

REPO="${1:-${P_INIT_GITHUB_REPO:-}}"

if [[ -z "${REPO}" ]]; then
  echo "Usage: $0 OWNER/REPOSITORY" >&2
  echo "Or set P_INIT_GITHUB_REPO=OWNER/REPOSITORY." >&2
  exit 2
fi

if [[ ! "${REPO}" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  echo "Repository must be in OWNER/REPOSITORY form." >&2
  exit 2
fi

for command_name in curl sha256sum unzip python3 gnome-extensions gnome-shell; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
done

SHELL_VERSION="$(gnome-shell --version 2>/dev/null || true)"
SHELL_MAJOR="$(printf '%s\n' "${SHELL_VERSION}" | sed -nE 's/.* ([0-9]+)(\.[0-9]+)?.*/\1/p')"

if [[ -z "${SHELL_MAJOR}" ]]; then
  echo "Could not determine GNOME Shell version from: ${SHELL_VERSION}" >&2
  exit 1
fi

if (( SHELL_MAJOR >= 42 && SHELL_MAJOR <= 44 )); then
  ASSET="pinit-legacy.zip"
elif (( SHELL_MAJOR >= 45 && SHELL_MAJOR <= 50 )); then
  ASSET="pinit-modern.zip"
else
  echo "Unsupported GNOME Shell major version: ${SHELL_MAJOR}" >&2
  echo "PinIt currently supports GNOME 42 through 50." >&2
  exit 1
fi

echo "Detected ${SHELL_VERSION}; installing ${ASSET}."

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
ZIP="${TMP}/${ASSET}"
SUMS="${TMP}/SHA256SUMS"
BASE="https://github.com/${REPO}/releases/latest/download"

curl --fail --location --silent --show-error --connect-timeout 10 --max-time 120 \
  "${BASE}/${ASSET}" -o "${ZIP}"
curl --fail --location --silent --show-error --connect-timeout 10 --max-time 30 \
  "${BASE}/SHA256SUMS" -o "${SUMS}"

(
  cd "${TMP}"
  grep " ${ASSET}$" SHA256SUMS | sha256sum --check -
)

UUID="$(unzip -p "${ZIP}" metadata.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["uuid"])')"
if [[ -z "${UUID}" ]]; then
  echo "Could not read extension UUID from release package." >&2
  exit 1
fi

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
  echo "GNOME may need a logout/login before loading the extension." >&2
  echo "After logging back in, run:" >&2
  echo "  gnome-extensions enable ${UUID}" >&2
fi
