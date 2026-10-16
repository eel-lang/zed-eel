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

The script does everything (no downloads besides the git repos):

1. Clones the [ruff-eel](https://github.com/eel-lang/ruff-eel) fork and **builds the
   `eel-ruff` and `eel-ty` binaries from source** (release by default, ~25 min on the first
   run; `EEL_PROFILE=debug` for a faster build).
2. Symlinks them into `~/.local/bin`.
3. Clones this extension into `~/.local/share/eelang/zed-eel` and prints the one GUI step
   (`zed: install dev extension` — Zed compiles the grammar and the extension locally).

Requirements: git, cargo (Rust), x86_64 Linux/macOS.

The extension looks up `eel-ruff` (fallback `ruff`) and `eel-ty` (fallback `ty`), so a stock
`ruff`/`ty` installed for Python files is not shadowed.

### Manual build

If you prefer to build by hand:

```bash
git clone https://github.com/eel-lang/ruff-eel
cd ruff-eel && git checkout eel
cargo build --release -p ruff -p ty
ln -s "$PWD/target/release/eel-ruff" ~/.local/bin/eel-ruff
ln -s "$PWD/target/release/eel-ty"   ~/.local/bin/eel-ty
```

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
