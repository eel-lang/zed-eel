#!/bin/sh
# Installs eelang support for Zed (source-only; nothing prebuilt is downloaded):
#   curl -fsSL https://raw.githubusercontent.com/eel-lang/zed-eel/main/install.sh | sh
#
# 1. Clones the eel Zed extension into ~/.local/share/eelang/zed-eel.
# 2. Prints the one GUI step to enable it (Zed compiles the extension locally).
# 3. Checks for eel-ruff/eel-ty; if missing, prints the build instructions for the
#    ruff-eel fork (currently built for x86_64 Linux/macOS).
set -eu

EXT_DIR="${EEL_EXT_DIR:-$HOME/.local/share/eelang/zed-eel}"
BIN_DIR="${EEL_BIN_DIR:-$HOME/.local/bin}"

echo "eelang: fetching the Zed extension into $EXT_DIR"
if [ -d "$EXT_DIR/.git" ]; then
    git -C "$EXT_DIR" pull --ff-only
else
    git clone --depth 1 https://github.com/eel-lang/zed-eel "$EXT_DIR"
fi

echo
echo "eelang: enable the extension in Zed:"
echo "  zed: install dev extension  ->  select  $EXT_DIR"
echo "  (Zed compiles the grammar and the extension locally; nothing to build here.)"
echo

missing=0
for bin in eel-ruff eel-ty; do
    if command -v "$bin" >/dev/null 2>&1 || [ -x "$BIN_DIR/$bin" ]; then
        echo "  * $bin: found"
    else
        echo "  * $bin: MISSING"
        missing=1
    fi
done

if [ "$missing" -eq 1 ]; then
    cat <<'EOF'

The eel-aware ruff and ty provide linting/formatting and type-aware
completions. They are built from source (x86_64 Linux or macOS, ~25 min
for a release build):

    git clone https://github.com/eel-lang/ruff-eel
    cd ruff-eel && git checkout eel
    cargo build --release -p ruff -p ty

Then link the binaries (adjust the path):

    ln -s /path/to/ruff-eel/target/release/ruff ~/.local/bin/eel-ruff
    ln -s /path/to/ruff-eel/target/release/ty   ~/.local/bin/eel-ty
EOF
fi

echo
echo "eelang: done. Restart Zed and open a .eel file."
