#!/usr/bin/env bash
set -euo pipefail

DEFAULT_GARMIN_DEVICE="fenix7"
OUTPUT_DIR="build"
OUTPUT_FILE="${OUTPUT_DIR}/JF-HebrewCalendar.prg"

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

if [[ -z "${CONNECTIQ_HOME:-}" && -z "${CIQ_HOME:-}" ]]; then
  fail "CONNECTIQ_HOME or CIQ_HOME must be set to your Garmin Connect IQ SDK path."
fi

CONNECTIQ_HOME="${CONNECTIQ_HOME:-${CIQ_HOME}}"
MONKEYC="${CONNECTIQ_HOME}/bin/monkeyc"

if [[ ! -e "${MONKEYC}" ]]; then
  fail "monkeyc was not found at ${MONKEYC}. Check your CONNECTIQ_HOME/CIQ_HOME setting."
fi

if [[ ! -x "${MONKEYC}" ]]; then
  fail "monkeyc is not executable at ${MONKEYC}. Check the file permissions or SDK installation."
fi

if [[ -z "${GARMIN_DEVELOPER_KEY:-}" ]]; then
  fail "GARMIN_DEVELOPER_KEY must be set to the path of your Garmin developer key (.der) file."
fi

if [[ ! -f "${GARMIN_DEVELOPER_KEY}" ]]; then
  fail "GARMIN_DEVELOPER_KEY does not point to an existing file: ${GARMIN_DEVELOPER_KEY}"
fi

GARMIN_DEVICE="${GARMIN_DEVICE:-${DEFAULT_GARMIN_DEVICE}}"

mkdir -p "${OUTPUT_DIR}"

"${MONKEYC}" \
  -f monkey.jungle \
  -o "${OUTPUT_FILE}" \
  -y "${GARMIN_DEVELOPER_KEY}" \
  -d "${GARMIN_DEVICE}"
