#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$ROOT_DIR/third_party/libarchive/linux"

mkdir -p "$DEST_DIR"

mapfile -t libs < <(ldconfig -p 2>/dev/null | awk '/libarchive\.so/ {print $NF}' | sort -u)

if [[ "${#libs[@]}" -eq 0 ]]; then
  printf 'libarchive was not found by ldconfig. Install libarchive first.\n' >&2
  exit 1
fi

for lib in "${libs[@]}"; do
  if [[ -f "$lib" ]]; then
    cp -L "$lib" "$DEST_DIR/$(basename "$lib")"
  fi
done

if compgen -G "$DEST_DIR/libarchive.so*" >/dev/null; then
  printf 'Vendored libarchive files:\n'
  find "$DEST_DIR" -maxdepth 1 -type f -name 'libarchive.so*' -printf '  %f\n' | sort
else
  printf 'No libarchive files were copied.\n' >&2
  exit 1
fi
