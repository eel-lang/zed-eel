use zed_extension_api::{self as zed, LanguageServerId, Result};

struct EelExtension;

impl zed::Extension for EelExtension {
    fn new() -> Self {
        Self
    }

    fn language_server_command(
        &mut self,
        language_server_id: &LanguageServerId,
        worktree: &zed::Worktree,
    ) -> Result<zed::Command> {
        match language_server_id.as_ref() {
            // Lint and format via the eel-aware ruff fork (`ruff server`).
            //
            // `eel-ruff` is preferred so that an eel-aware fork can coexist with a
            // stock `ruff` on the same PATH (e.g. installed via uv).
            "eel" => {
                let binary_path = worktree
                    .which("eel-ruff")
                    .or_else(|| worktree.which("ruff"))
                    .ok_or_else(|| {
                        "could not find `eel-ruff` or `ruff` on PATH; symlink your eel-aware \
                         ruff fork into PATH (e.g. `ln -s <fork>/target/debug/ruff \
                         ~/.local/bin/eel-ruff`) to use eelang linting and formatting"
                            .to_string()
                    })?;

                Ok(zed::Command {
                    command: binary_path,
                    args: vec!["server".to_string()],
                    env: Default::default(),
                })
            }
            // Semantic analysis (type checking, completions) via the eel-aware ty fork
            // (`ty server`).
            //
            // Declared as a separate server (not the built-in `ty`) so that the stock
            // ty used for Python files is not shadowed by our fork.
            "eel-ty" => {
                let binary_path = worktree
                    .which("eel-ty")
                    .or_else(|| worktree.which("ty"))
                    .ok_or_else(|| {
                        "could not find `eel-ty` or `ty` on PATH; symlink your eel-aware ty fork \
                         into PATH (e.g. `ln -s <fork>/target/debug/ty ~/.local/bin/eel-ty`) to \
                         use eelang semantic analysis and completions"
                            .to_string()
                    })?;

                Ok(zed::Command {
                    command: binary_path,
                    args: vec!["server".to_string()],
                    env: Default::default(),
                })
            }
            other => Err(format!("unknown language server id: {other}")),
        }
    }
}

zed::register_extension!(EelExtension);
