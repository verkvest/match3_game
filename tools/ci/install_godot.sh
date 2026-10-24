#!/usr/bin/env bash
# Download Godot 4.7.2 and, with "full", the matching export templates.
# Prints nothing secret. Writes GODOT_BIN into GITHUB_ENV when that file exists.
set -euo pipefail

VER=4.7.2
MODE="${1:-editor}"
ROOT="${GODOT_ROOT:-$HOME/.cache/godot-$VER}"
mkdir -p "$ROOT"

if [[ "$(uname -s)" == "Darwin" ]]; then
  ZIP="Godot_v${VER}-stable_macos.universal.zip"
  BIN="$ROOT/Godot.app/Contents/MacOS/Godot"
  TMPL_DEST="$HOME/Library/Application Support/Godot/export_templates/${VER}.stable"
else
  ZIP="Godot_v${VER}-stable_linux.x86_64.zip"
  BIN="$ROOT/Godot_v${VER}-stable_linux.x86_64"
  TMPL_DEST="${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/${VER}.stable"
fi

if [[ ! -x "$BIN" ]]; then
  echo "Downloading Godot ${VER} editor"
  curl -fL --retry 3 -o "$ROOT/godot.zip" \
    "https://github.com/godotengine/godot/releases/download/${VER}-stable/${ZIP}"
  unzip -q -o "$ROOT/godot.zip" -d "$ROOT"
  rm -f "$ROOT/godot.zip"
  if [[ "$(uname -s)" == "Darwin" ]]; then
    xattr -dr com.apple.quarantine "$ROOT/Godot.app" || true
  else
    chmod +x "$BIN"
  fi
fi

if [[ "$MODE" == "full" ]]; then
  if [[ ! -e "$TMPL_DEST/version.txt" && ! -e "$TMPL_DEST/android_source.zip" && ! -e "$TMPL_DEST/ios.zip" ]]; then
    echo "Downloading Godot ${VER} export templates"
    mkdir -p "$TMPL_DEST"
    curl -fL --retry 3 -o "$ROOT/templates.tpz" \
      "https://github.com/godotengine/godot/releases/download/${VER}-stable/Godot_v${VER}-stable_export_templates.tpz"
    rm -rf "$ROOT/tpl"
    mkdir -p "$ROOT/tpl"
    unzip -q -o "$ROOT/templates.tpz" -d "$ROOT/tpl"
    cp -a "$ROOT/tpl/templates/." "$TMPL_DEST/"
    rm -f "$ROOT/templates.tpz"
  fi
  echo "Templates: $TMPL_DEST"
  ls "$TMPL_DEST" | head
fi

echo "Godot: $BIN"
"$BIN" --version
if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "GODOT_BIN=$BIN" >> "$GITHUB_ENV"
fi
