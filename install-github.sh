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

for command_name in curl sha256sum unzip gnome-extensions; do
  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Missing required command: ${command_name}" >&2
    exit 1
  fi
done

TMP="$(mktemp -d)"
trap 'rm -rf "${TMP}"' EXIT
ZIP="${TMP}/pinit.zip"
SUMS="${TMP}/SHA256SUMS"
BASE="https://github.com/${REPO}/releases/latest/download"

curl --fail --location --silent --show-error --connect-timeout 10 --max-time 120 \
  "${BASE}/pinit.zip" -o "${ZIP}"
curl --fail --location --silent --show-error --connect-timeout 10 --max-time 30 \
  "${BASE}/SHA256SUMS" -o "${SUMS}"

(
  cd "${TMP}"
  sha256sum --check SHA256SUMS
)

UUID="$(unzip -p "${ZIP}" metadata.json | python3 -c 'import json,sys; print(json.load(sys.stdin)["uuid"])')"
if [[ -z "${UUID}" ]]; then
  echo "Could not read extension UUID from release package." >&2
  exit 1
fi

gnome-extensions install --force "${ZIP}"

echo "Installed ${UUID}."
if gnome-extensions enable "${UUID}" 2>/dev/null; then
  echo "Enabled ${UUID}."
else
  echo "GNOME may need a logout/login before loading the extension." >&2
  echo "After logging back in, run:" >&2
  echo "  gnome-extensions enable ${UUID}" >&2
fi
