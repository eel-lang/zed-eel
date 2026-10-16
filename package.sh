#!/bin/sh
# Packages the compiled Zed extension into `eel-extension.tgz` for a GitHub Release.
#
# Run from the extension directory. Requires:
#   - cargo with the wasm32-wasip2 target (installed by Zed or `rustup target add wasm32-wasip2`)
#   - a tree-sitter-eel checkout at grammars/tree-sitter-eel (its `src/` must be generated)
#   - wasi-sdk clang on PATH (Zed downloads it; or set WASI_SDK_PATH)
set -eu

CLANG="${CLANG:-${WASI_SDK_PATH:+$WASI_SDK_PATH/bin/clang}}"
CLANG="${CLANG:-clang}"

echo "Building the extension wasm component (release) ..."
RUSTC_WRAPPER= cargo build --release --target wasm32-wasip2
cp target/wasm32-wasip2/release/zed_eel.wasm extension.wasm

echo "Compiling the eel grammar to wasm ..."
$CLANG -fPIC -shared -Os \
    -Wl,--export=tree_sitter_eel \
    -o grammars/eel.wasm \
    -I grammars/tree-sitter-eel/src \
    grammars/tree-sitter-eel/src/parser.c \
    grammars/tree-sitter-eel/src/scanner.c

echo "Packaging ..."
TARBALL="eel-extension.tgz"
tar -czf "$TARBALL" \
    extension.toml \
    extension.wasm \
    grammars/eel.wasm \
    languages \
    snippets

echo "Wrote $TARBALL"
echo "Attach it to a GitHub Release of eel-lang/zed-eel as 'eel-extension.tgz'."
