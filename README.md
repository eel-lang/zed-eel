# eelang for Zed

Language support for [eelang](https://github.com/eel-lang) (`.eel`) — a superset of Python 3.13+
with assert-patterns, `match def`, and pipelines.

- **Syntax highlighting** via the [tree-sitter-eel](https://github.com/eel-lang/tree-sitter-eel)
  grammar (assert-patterns, `match def`, inline and block pipelines).
- **Linting and formatting** via the eel-aware
  [ruff-eel](https://github.com/eel-lang/ruff-eel) fork (`ruff server`).
- **Type checking and completions** via the eel-aware `ty` from the same fork (`ty server`).

## Usage

Install as a dev extension: `zed: install dev extension` → select this directory
(grammars and the Rust part are compiled by Zed at install time).

Make the forked binaries findable on `PATH`:

```bash
ln -s <ruff-eel>/target/debug/ruff ~/.local/bin/eel-ruff   # lint + format
ln -s <ruff-eel>/target/debug/ty   ~/.local/bin/eel-ty     # types + completions
```

The extension looks up `eel-ruff` (fallback `ruff`) and `eel-ty` (fallback `ty`), so a
stock `ruff`/`ty` installed for Python files is not shadowed.

## Development

- Grammar changes live in the separate
  [tree-sitter-eel](https://github.com/eel-lang/tree-sitter-eel) repository
  (vendored locally under `grammars/tree-sitter-eel` for convenience; `extension.toml`
  pins the published commit). After pushing a new grammar commit, bump the `commit`
  pin in `extension.toml`.
- The Rust part (`src/eel.rs`) is compiled to WebAssembly by Zed when the extension is
  installed.

## License

MIT
