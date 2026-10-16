# eelang for Zed

Language support for [eelang](https://github.com/eel-lang) (`.eel`) — a superset of Python 3.13+
with assert-patterns, `match def`, and pipelines.

- **Syntax highlighting** via the [tree-sitter-eel](https://github.com/eel-lang/tree-sitter-eel)
  grammar (assert-patterns, `match def`, inline and block pipelines).
- **Linting and formatting** via the eel-aware
  [ruff-eel](https://github.com/eel-lang/ruff-eel) fork (`ruff server`).
- **Type checking and completions** via the eel-aware `ty` from the same fork (`ty server`).

## Install (one command)

```sh
curl -fsSL https://raw.githubusercontent.com/eel-lang/zed-eel/main/install.sh | sh
```

Installs `eel-ruff` and `eel-ty` into `~/.local/bin` (from
[ruff-eel releases](https://github.com/eel-lang/ruff-eel/releases)) and the compiled extension
into Zed's extensions directory. Then restart Zed.

Requires: `curl`, `tar`, and a supported platform (Linux/macOS on x86_64/aarch64).

## Development

Install as a dev extension: `zed: install dev extension` → select this directory. Then make the
forked binaries findable on `PATH`:

```bash
ln -s <ruff-eel>/target/debug/ruff ~/.local/bin/eel-ruff
ln -s <ruff-eel>/target/debug/ty   ~/.local/bin/eel-ty
```

The extension looks up `eel-ruff` (fallback `ruff`) and `eel-ty` (fallback `ty`), so a stock
`ruff`/`ty` installed for Python files is not shadowed.

- Grammar changes live in the separate
  [tree-sitter-eel](https://github.com/eel-lang/tree-sitter-eel) repository
  (vendored locally under `grammars/tree-sitter-eel`; `extension.toml` pins the published
  commit — bump it after pushing a new grammar commit).
- `./package.sh` builds and packages `eel-extension.tgz` for a GitHub Release.
- The Rust part (`src/eel.rs`) is compiled to WebAssembly by Zed when the extension is
  installed as a dev extension.

## License

MIT
