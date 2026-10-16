#!/bin/sh
# Installs eelang tooling for Zed in one command:
#   curl -fsSL https://raw.githubusercontent.com/eel-lang/zed-eel/main/install.sh | sh
#
# Installs:
#   1. eel-ruff — the eel-aware ruff fork (linting + formatting)   -> ~/.local/bin
#   2. eel-ty   — the eel-aware ty fork (type checking + completions) -> ~/.local/bin
#   3. the eel Zed extension (grammar + language servers)          -> Zed's extensions dir
set -eu

VERSION="${EEL_VERSION:-v0.1.0}"
BASE_URL="${EEL_BASE_URL:-https://github.com/eel-lang}"

# --- platform detection -----------------------------------------------------
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)
case "$OS-$ARCH" in
    linux-x86_64)            TARGET="linux-x86_64" ;;
    linux-aarch64|linux-arm64) TARGET="linux-aarch64" ;;
    darwin-x86_64)           TARGET="macos-x86_64" ;;
    darwin-arm64)            TARGET="macos-aarch64" ;;
    *) echo "eelang: unsupported platform: $OS-$ARCH" >&2; exit 1 ;;
esac

# --- binaries ---------------------------------------------------------------
BIN_DIR="${EEL_BIN_DIR:-$HOME/.local/bin}"
mkdir -p "$BIN_DIR"

echo "eelang: installing eel-ruff and eel-ty into $BIN_DIR"
curl -fsSL -o "$BIN_DIR/eel-ruff" "$BASE_URL/ruff-eel/releases/download/$VERSION/ruff-$TARGET"
chmod +x "$BIN_DIR/eel-ruff"
curl -fsSL -o "$BIN_DIR/eel-ty"   "$BASE_URL/ruff-eel/releases/download/$VERSION/ty-$TARGET"
chmod +x "$BIN_DIR/eel-ty"

# --- Zed extension ----------------------------------------------------------
case "$OS" in
    linux) ZED_EXTENSIONS_DIR="${ZED_EXTENSIONS_DIR:-$HOME/.local/share/zed/extensions/installed}" ;;
    darwin) ZED_EXTENSIONS_DIR="${ZED_EXTENSIONS_DIR:-$HOME/Library/Application Support/Zed/extensions/installed}" ;;
esac
EXT_DIR="$ZED_EXTENSIONS_DIR/eel"

echo "eelang: installing the Zed extension into $EXT_DIR"
# Remove a dev-extension symlink, if present, so the archive extracts into a real dir.
if [ -L "$EXT_DIR" ]; then
    rm -f "$EXT_DIR"
fi
mkdir -p "$EXT_DIR"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/eel-extension.tgz" "$BASE_URL/zed-eel/releases/download/$VERSION/eel-extension.tgz"
tar -xzf "$TMP/eel-extension.tgz" -C "$EXT_DIR"

echo
echo "eelang: done."
echo "  * binaries:   $BIN_DIR/eel-ruff, $BIN_DIR/eel-ty"
echo "  * extension:  $EXT_DIR"
echo
echo "Restart Zed and open a .eel file — highlighting, linting, and completions should work."
