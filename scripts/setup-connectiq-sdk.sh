#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_SOURCE="${CONNECTIQ_SDK_ARCHIVE:-}"
INSTALL_DIR="${CONNECTIQ_SDK_INSTALL_DIR:-$ROOT_DIR/.local/connectiq-sdk}"
DOWNLOAD_DIR="$ROOT_DIR/.local/downloads"

usage() {
  cat <<USAGE
Usage:
  CONNECTIQ_SDK_ARCHIVE=/path/to/connectiq-sdk.zip scripts/setup-connectiq-sdk.sh
  CONNECTIQ_SDK_ARCHIVE=https://example.com/connectiq-sdk.zip scripts/setup-connectiq-sdk.sh

Environment:
  CONNECTIQ_SDK_ARCHIVE      Required. Local SDK archive path or URL.
  CONNECTIQ_SDK_INSTALL_DIR  Optional. Install directory (default: .local/connectiq-sdk).

The Garmin Connect IQ SDK license may restrict redistribution. This script does not
vendor SDK binaries; it only unpacks the archive you provide.
USAGE
}

if [[ -z "$ARCHIVE_SOURCE" ]]; then
  usage >&2
  exit 64
fi

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

archive_name="$(basename "${ARCHIVE_SOURCE%%\?*}")"
if [[ -z "$archive_name" || "$archive_name" == "." || "$archive_name" == "/" ]]; then
  archive_name="connectiq-sdk-archive"
fi

mkdir -p "$DOWNLOAD_DIR"

if [[ "$ARCHIVE_SOURCE" =~ ^https?:// ]]; then
  archive_path="$DOWNLOAD_DIR/$archive_name"
  if command_exists curl; then
    curl --fail --location --show-error --output "$archive_path" "$ARCHIVE_SOURCE"
  elif command_exists wget; then
    wget --output-document="$archive_path" "$ARCHIVE_SOURCE"
  else
    echo "Error: downloading URLs requires curl or wget." >&2
    exit 69
  fi
else
  archive_path="$ARCHIVE_SOURCE"
  if [[ ! -f "$archive_path" ]]; then
    echo "Error: CONNECTIQ_SDK_ARCHIVE does not point to a file: $archive_path" >&2
    exit 66
  fi
fi

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

case "$archive_path" in
  *.zip)
    if ! command_exists unzip; then
      echo "Error: unzip is required to extract $archive_path." >&2
      exit 69
    fi
    unzip -q "$archive_path" -d "$tmp_dir"
    ;;
  *.tar|*.tar.gz|*.tgz|*.tar.bz2|*.tbz2|*.tar.xz|*.txz)
    tar -xf "$archive_path" -C "$tmp_dir"
    ;;
  *)
    echo "Error: unsupported SDK archive format: $archive_path" >&2
    echo "Supported formats: .zip, .tar, .tar.gz, .tgz, .tar.bz2, .tbz2, .tar.xz, .txz" >&2
    exit 65
    ;;
esac

sdk_root=""
while IFS= read -r -d '' candidate; do
  sdk_root="$(dirname "$(dirname "$candidate")")"
  break
done < <(find "$tmp_dir" -type f \( -name monkeyc -o -name monkeyc.exe \) -path '*/bin/*' -print0)

if [[ -z "$sdk_root" ]]; then
  echo "Error: could not find bin/monkeyc in the extracted SDK archive." >&2
  exit 65
fi

rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"
cp -R "$sdk_root" "$INSTALL_DIR"

compiler="$INSTALL_DIR/bin/monkeyc"
runner="$INSTALL_DIR/bin/monkeydo"
if [[ -e "${compiler}.exe" && ! -e "$compiler" ]]; then
  compiler="${compiler}.exe"
fi
if [[ -e "${runner}.exe" && ! -e "$runner" ]]; then
  runner="${runner}.exe"
fi

if [[ ! -x "$compiler" ]]; then
  chmod +x "$compiler" 2>/dev/null || true
fi
if [[ -e "$runner" && ! -x "$runner" ]]; then
  chmod +x "$runner" 2>/dev/null || true
fi

version="unknown"
for version_file in \
  "$INSTALL_DIR/sdk.version" \
  "$INSTALL_DIR/VERSION" \
  "$INSTALL_DIR/version.txt" \
  "$INSTALL_DIR/manifest.xml"; do
  if [[ -f "$version_file" ]]; then
    version_line="$(sed -n '1,20p' "$version_file" | tr -d '\r' | grep -Eo '[0-9]+(\.[0-9]+)+' | head -1 || true)"
    if [[ -n "$version_line" ]]; then
      version="$version_line"
      break
    fi
  fi
done

if [[ "$version" == "unknown" && -x "$compiler" ]]; then
  version_line="$($compiler --version 2>&1 | grep -Eo '[0-9]+(\.[0-9]+)+' | head -1 || true)"
  if [[ -n "$version_line" ]]; then
    version="$version_line"
  fi
fi

cat <<SUMMARY
Connect IQ SDK installed.
Version: $version
CONNECTIQ_HOME=$INSTALL_DIR
CIQ_HOME=$INSTALL_DIR
Compiler: $compiler
Simulator runner: $runner
SUMMARY
