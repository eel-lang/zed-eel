# eelang for Zed

Language support for [eelang](https://github.com/eel-lang) (`.eel`) — a superset of Python 3.13+
with assert-patterns, `match def`, and pipelines.

- **Syntax highlighting** via the [tree-sitter-eel](https://github.com/eel-lang/tree-sitter-eel)
  grammar (assert-patterns, `match def`, inline and block pipelines).
- **Linting and formatting** via the eel-aware
  [ruff-eel](https://github.com/eel-lang/ruff-eel) fork (`ruff server`).
- **Type checking and completions** via the eel-aware `ty` from the same fork (`ty server`).

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/eel-lang/zed-eel/main/install.sh | sh
```

The script clones this extension and tells you the one GUI step (`zed: install dev extension`).
Zed compiles the grammar and the extension locally.

The `eel-ruff` and `eel-ty` binaries are **built from source** (they are not distributed
as downloads). The script prints the build instructions if the binaries are missing — in short:

```bash
git clone https://github.com/eel-lang/ruff-eel
cd ruff-eel && git checkout eel
cargo build --release -p ruff -p ty
ln -s "$PWD/target/release/ruff" ~/.local/bin/eel-ruff
ln -s "$PWD/target/release/ty"   ~/.local/bin/eel-ty
```

Supported: x86_64 Linux and macOS.

The extension looks up `eel-ruff` (fallback `ruff`) and `eel-ty` (fallback `ty`), so a stock
`ruff`/`ty` installed for Python files is not shadowed.

## Development

- Grammar changes live in the separate
  [tree-sitter-eel](https://github.com/eel-lang/tree-sitter-eel) repository
  (vendored locally under `grammars/tree-sitter-eel`; `extension.toml` pins the published
  commit — bump it after pushing a new grammar commit).
- `./package.sh` builds and packages `eel-extension.tgz` (for publishing the extension with
  prebuilt artifacts, if ever needed).
- The Rust part (`src/eel.rs`) is compiled to WebAssembly by Zed when the extension is
  installed as a dev extension.

## License

MIT
