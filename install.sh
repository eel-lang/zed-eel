#!/bin/sh
# One-command installer for eelang in Zed (builds everything from source and
# installs the extension into Zed):
#   curl -fsSL https://raw.githubusercontent.com/eel-lang/zed-eel/main/install.sh | sh
#
# 1. Clones the ruff-eel fork and builds `eel-ruff` + `eel-ty` from source
#    (release by default; the first build takes a while).
# 2. Symlinks the binaries into ~/.local/bin.
# 3. Clones the Zed extension, compiles it (Rust -> wasm, grammar -> wasm), and
#    installs it into Zed's extensions directory — no GUI steps required.
#
# Requirements: git, cargo (Rust), x86_64 Linux/macOS.
# Set EEL_PROFILE=debug for a much faster binary build (the tools run slower).
# The wasi-sdk compiler for the grammar is reused from Zed's own cache if
# present, or downloaded (set WASI_SDK_PATH to use an existing install).
set -eu

ARCH=$(uname -m)
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS-$ARCH" in
    linux-x86_64)  WASI_PLATFORM="x86_64-linux"; ZED_DATA="$HOME/.local/share/zed" ;;
    darwin-x86_64) WASI_PLATFORM="x86_64-macos"; ZED_DATA="$HOME/Library/Application Support/Zed" ;;
    *) echo "eelang: unsupported platform: $OS-$ARCH (only x86_64 Linux/macOS is supported)" >&2; exit 1 ;;
esac

BASE="${EEL_BASE_DIR:-$HOME/.local/share/eelang}"
BIN_DIR="${EEL_BIN_DIR:-$HOME/.local/bin}"
REPO_URL="${EEL_REPO_URL:-https://github.com/eel-lang}"
PROFILE="${EEL_PROFILE:-release}"
ZED_EXTENSIONS_DIR="${ZED_EXTENSIONS_DIR:-$ZED_DATA/extensions/installed}"
WASI_SDK_VERSION="34"

for tool in git cargo; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "eelang: missing required tool: $tool (install git and Rust first)" >&2
        exit 1
    }
done

mkdir -p "$BASE" "$BIN_DIR"

# --- 1. eel-ruff and eel-ty -------------------------------------------------

echo "eelang: fetching the ruff-eel fork ..."
if [ -d "$BASE/ruff-eel/.git" ]; then
    git -C "$BASE/ruff-eel" fetch --quiet origin
    git -C "$BASE/ruff-eel" checkout --quiet eel
    git -C "$BASE/ruff-eel" pull --quiet --ff-only
else
    git clone --quiet "$REPO_URL/ruff-eel" "$BASE/ruff-eel"
    git -C "$BASE/ruff-eel" checkout --quiet eel
fi

echo "eelang: building eel-ruff and eel-ty ($PROFILE; the first build takes a while) ..."
BUILD_FLAG=
[ "$PROFILE" = release ] && BUILD_FLAG=--release
RUSTC_WRAPPER= cargo build $BUILD_FLAG -p ruff -p ty \
    --manifest-path "$BASE/ruff-eel/Cargo.toml"

ln -sf "$BASE/ruff-eel/target/$PROFILE/eel-ruff" "$BIN_DIR/eel-ruff"
ln -sf "$BASE/ruff-eel/target/$PROFILE/eel-ty"   "$BIN_DIR/eel-ty"

# --- 2. Zed extension -------------------------------------------------------

echo "eelang: fetching the Zed extension ..."
if [ -d "$BASE/zed-eel/.git" ]; then
    git -C "$BASE/zed-eel" pull --quiet --ff-only
else
    git clone --quiet "$REPO_URL/zed-eel" "$BASE/zed-eel"
fi

EXT="$BASE/zed-eel"
GRAMMAR_NAME=$(sed -n 's/^\[grammars\.\([^]]*\)\]$/\1/p' "$EXT/extension.toml" | head -1)
GRAMMAR_REPO="${EEL_GRAMMAR_URL:-$(sed -n 's/^repository = "\(.*\)"$/\1/p' "$EXT/extension.toml" | head -1)}"
GRAMMAR_COMMIT="${EEL_GRAMMAR_COMMIT:-$(sed -n 's/^commit = "\(.*\)"$/\1/p' "$EXT/extension.toml" | head -1)}"

echo "eelang: compiling the extension (Rust -> wasm) ..."
if command -v rustup >/dev/null 2>&1; then
    rustup target add wasm32-wasip2 >/dev/null 2>&1 || true
fi
RUSTC_WRAPPER= cargo build --release --target wasm32-wasip2 \
    --manifest-path "$EXT/Cargo.toml"
cp "$EXT/target/wasm32-wasip2/release/zed_eel.wasm" "$EXT/extension.wasm"

echo "eelang: compiling the grammar ($GRAMMAR_NAME -> wasm) ..."
if [ -n "${WASI_SDK_PATH:-}" ] && [ -x "$WASI_SDK_PATH/bin/clang" ]; then
    CLANG="$WASI_SDK_PATH/bin/clang"
elif [ -x "$ZED_DATA/extensions/build/wasi-sdk/bin/clang" ]; then
    CLANG="$ZED_DATA/extensions/build/wasi-sdk/bin/clang"
else
    echo "eelang: downloading wasi-sdk (used by Zed to compile grammars) ..."
    SDK_URL="https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$WASI_SDK_VERSION/wasi-sdk-$WASI_SDK_VERSION.0-$WASI_PLATFORM.tar.gz"
    mkdir -p "$ZED_DATA/extensions/build"
    curl -fsSL -o "$BASE/wasi-sdk.tar.gz" "$SDK_URL"
    tar -xzf "$BASE/wasi-sdk.tar.gz" -C "$ZED_DATA/extensions/build"
    rm -f "$BASE/wasi-sdk.tar.gz"
    CLANG="$ZED_DATA/extensions/build/wasi-sdk-$WASI_SDK_VERSION.0/bin/clang"
fi

GRAMMAR_DIR="$EXT/grammars/$GRAMMAR_NAME"
if [ -d "$GRAMMAR_DIR/.git" ]; then
    git -C "$GRAMMAR_DIR" fetch --quiet origin
    git -C "$GRAMMAR_DIR" checkout --quiet "$GRAMMAR_COMMIT"
else
    git clone --quiet "$GRAMMAR_REPO" "$GRAMMAR_DIR"
    git -C "$GRAMMAR_DIR" checkout --quiet "$GRAMMAR_COMMIT"
fi

"$CLANG" -fPIC -shared -Os \
    -Wl,--export="tree_sitter_$GRAMMAR_NAME" \
    -o "$EXT/grammars/$GRAMMAR_NAME.wasm" \
    -I "$GRAMMAR_DIR/src" \
    "$GRAMMAR_DIR/src/parser.c" \
    "$GRAMMAR_DIR/src/scanner.c"

echo "eelang: installing the extension into Zed ($ZED_EXTENSIONS_DIR/eel) ..."
EXT_INSTALL="$ZED_EXTENSIONS_DIR/eel"
if [ -L "$EXT_INSTALL" ] || [ -e "$EXT_INSTALL" ]; then
    rm -rf "$EXT_INSTALL"
fi
mkdir -p "$ZED_EXTENSIONS_DIR"
ln -s "$EXT" "$EXT_INSTALL"

echo
echo "eelang: done."
echo "  binaries:   $BIN_DIR/eel-ruff, $BIN_DIR/eel-ty"
echo "  extension:  $EXT  (installed as a dev extension)"
echo
echo "Restart Zed (it usually hot-reloads new extensions) and open a .eel file."
