#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$ROOT_DIR/third_party/libarchive/macos"

mkdir -p "$DEST_DIR"

candidates=(
  "/opt/homebrew/opt/libarchive/lib/libarchive.dylib"
  "/usr/local/opt/libarchive/lib/libarchive.dylib"
  "/usr/lib/libarchive.dylib"
)

for lib in "${candidates[@]}"; do
  if [[ -f "$lib" ]]; then
    cp -L "$lib" "$DEST_DIR/libarchive.dylib"
    printf 'Vendored libarchive.dylib from %s\n' "$lib"
    exit 0
  fi
done

if command -v brew >/dev/null 2>&1; then
  prefix="$(brew --prefix libarchive 2>/dev/null || true)"
  if [[ -n "$prefix" && -f "$prefix/lib/libarchive.dylib" ]]; then
    cp -L "$prefix/lib/libarchive.dylib" "$DEST_DIR/libarchive.dylib"
    printf 'Vendored libarchive.dylib from %s\n' "$prefix/lib/libarchive.dylib"
    exit 0
  fi
fi

printf 'libarchive.dylib was not found. Install libarchive with Homebrew first.\n' >&2
exit 1
