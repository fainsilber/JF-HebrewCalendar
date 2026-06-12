#!/usr/bin/env bash
set -euo pipefail

DEFAULT_GARMIN_DEVICE="fenix7"
OUTPUT_DIR="build"
OUTPUT_FILE="${OUTPUT_DIR}/JF-HebrewCalendar.prg"

if [[ -z "${CONNECTIQ_HOME:-}" ]]; then
  if [[ -n "${CIQ_HOME:-}" ]]; then
    CONNECTIQ_HOME="${CIQ_HOME}"
  else
    cat >&2 <<'MSG'
Error: CONNECTIQ_HOME is not set.
Set CONNECTIQ_HOME to your Garmin Connect IQ SDK path, or set CIQ_HOME as a fallback.
MSG
    exit 1
  fi
fi

MONKEYC="${CONNECTIQ_HOME}/bin/monkeyc"
if [[ ! -x "${MONKEYC}" ]]; then
  cat >&2 <<MSG
Error: monkeyc was not found or is not executable at:
  ${MONKEYC}
Check CONNECTIQ_HOME/CIQ_HOME and ensure the Connect IQ SDK is installed.
MSG
  exit 1
fi

if [[ -z "${GARMIN_DEVELOPER_KEY:-}" ]]; then
  cat >&2 <<'MSG'
Error: GARMIN_DEVELOPER_KEY is not set.
Set GARMIN_DEVELOPER_KEY to the path of your Garmin developer key (.der) file.
MSG
  exit 1
fi

if [[ ! -f "${GARMIN_DEVELOPER_KEY}" ]]; then
  cat >&2 <<MSG
Error: GARMIN_DEVELOPER_KEY does not point to an existing file:
  ${GARMIN_DEVELOPER_KEY}
MSG
  exit 1
fi

GARMIN_DEVICE="${GARMIN_DEVICE:-${DEFAULT_GARMIN_DEVICE}}"

mkdir -p "${OUTPUT_DIR}"

"${MONKEYC}" \
  -f monkey.jungle \
  -o "${OUTPUT_FILE}" \
  -y "${GARMIN_DEVELOPER_KEY}" \
  -d "${GARMIN_DEVICE}"
