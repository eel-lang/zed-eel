#!/bin/sh
# One-command installer for eelang in Zed (builds everything from source):
#   curl -fsSL https://raw.githubusercontent.com/eel-lang/zed-eel/main/install.sh | sh
#
# 1. Clones the ruff-eel fork and builds `eel-ruff` + `eel-ty` from source
#    (release by default; the first build takes a while).
# 2. Symlinks the binaries into ~/.local/bin.
# 3. Clones the Zed extension and prints the one GUI step to enable it.
#
# Requirements: git, cargo (Rust), x86_64 Linux/macOS.
# Set EEL_PROFILE=debug for a much faster build (the tools run slower, though).
set -eu

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ;;
    *) echo "eelang: unsupported architecture: $ARCH (only x86_64 is supported)" >&2; exit 1 ;;
esac

BASE="${EEL_BASE_DIR:-$HOME/.local/share/eelang}"
BIN_DIR="${EEL_BIN_DIR:-$HOME/.local/bin}"
REPO_URL="${EEL_REPO_URL:-https://github.com/eel-lang}"
PROFILE="${EEL_PROFILE:-release}"

for tool in git cargo; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "eelang: missing required tool: $tool (install git and Rust first)" >&2
        exit 1
    }
done

mkdir -p "$BASE" "$BIN_DIR"

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

echo "eelang: fetching the Zed extension ..."
if [ -d "$BASE/zed-eel/.git" ]; then
    git -C "$BASE/zed-eel" pull --quiet --ff-only
else
    git clone --quiet "$REPO_URL/zed-eel" "$BASE/zed-eel"
fi

echo
echo "eelang: enable the extension in Zed:"
echo "  zed: install dev extension  ->  select  $BASE/zed-eel"
echo
echo "eelang: done. Restart Zed and open a .eel file."
echo "  binaries:  $BIN_DIR/eel-ruff, $BIN_DIR/eel-ty"
echo "  extension: $BASE/zed-eel"
