//! Repository tasks.
//!
//! - `cargo xtask check-snippets [--no-build]`: extract every ```` ```rust,check ```` block from the
//!   markdown files each `checks/<name>` crate lists, write them into that crate's
//!   `src/generated.rs`, then run `cargo check` on it.
//!
//! Each block becomes its own module with `use bevy::prelude::*;` already in scope, so a snippet
//! must be made of items (functions, types, impls). Put statements inside a function.

use std::{
    fmt::Write as _,
    fs,
    path::{Path, PathBuf},
    process::{Command, ExitCode},
};

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    match args.first().map(String::as_str) {
        Some("check-snippets") => {
            let build = !args.iter().any(|a| a == "--no-build");
            match check_snippets(build) {
                Ok(()) => ExitCode::SUCCESS,
                Err(e) => {
                    eprintln!("error: {e}");
                    ExitCode::FAILURE
                }
            }
        }
        _ => {
            eprintln!("usage: cargo xtask check-snippets [--no-build]");
            ExitCode::FAILURE
        }
    }
}

fn repo_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("xtask lives one level below the repo root")
        .to_path_buf()
}

struct Snippet {
    source: PathBuf,
    line: usize,
    code: String,
}

fn check_snippets(build: bool) -> Result<(), String> {
    let root = repo_root();
    let crates = glob::glob(&root.join("checks/*/Cargo.toml").to_string_lossy())
        .map_err(|e| e.to_string())?
        .filter_map(Result::ok)
        .collect::<Vec<_>>();
    if crates.is_empty() {
        return Err("no checks/*/Cargo.toml found".into());
    }

    let mut failed = Vec::new();
    for manifest in crates {
        let dir = manifest.parent().unwrap().to_path_buf();
        let name = dir.file_name().unwrap().to_string_lossy().into_owned();
        let sources = snippet_sources(&manifest)?;
        let mut snippets = Vec::new();
        for pattern in &sources {
            let full = root.join(pattern);
            let mut matched = 0;
            for path in glob::glob(&full.to_string_lossy()).map_err(|e| e.to_string())? {
                let path = path.map_err(|e| e.to_string())?;
                matched += 1;
                snippets.extend(extract(&path)?);
            }
            if matched == 0 {
                return Err(format!("{name}: source pattern `{pattern}` matched no files"));
            }
        }

        let generated = render(&root, &snippets);
        fs::write(dir.join("src/generated.rs"), generated).map_err(|e| e.to_string())?;
        println!("{name}: {} snippets from {} patterns", snippets.len(), sources.len());

        if build {
            let status = Command::new(env!("CARGO"))
                .args(["check", "--quiet", "--manifest-path"])
                .arg(&manifest)
                .status()
                .map_err(|e| e.to_string())?;
            if !status.success() {
                failed.push(name);
            }
        }
    }

    if failed.is_empty() {
        Ok(())
    } else {
        Err(format!(
            "snippets failed to compile in: {}. Each module in src/generated.rs names its source file and line.",
            failed.join(", ")
        ))
    }
}

fn snippet_sources(manifest: &Path) -> Result<Vec<String>, String> {
    let text = fs::read_to_string(manifest).map_err(|e| e.to_string())?;
    let value: toml::Table = text.parse().map_err(|e| format!("{}: {e}", manifest.display()))?;
    value
        .get("package")
        .and_then(|p| p.get("metadata"))
        .and_then(|m| m.get("snippets"))
        .and_then(|s| s.get("sources"))
        .and_then(|s| s.as_array())
        .ok_or_else(|| format!("{}: missing [package.metadata.snippets] sources", manifest.display()))?
        .iter()
        .map(|v| {
            v.as_str()
                .map(str::to_owned)
                .ok_or_else(|| "snippet sources must be strings".to_string())
        })
        .collect()
}

/// Pull ```` ```rust,check ```` fenced blocks out of a markdown file.
fn extract(path: &Path) -> Result<Vec<Snippet>, String> {
    let text = fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))?;
    let mut out = Vec::new();
    let mut current: Option<(usize, String, String)> = None; // (line, fence, code)
    for (i, line) in text.lines().enumerate() {
        let trimmed = line.trim_start();
        match &mut current {
            None => {
                let fence_len = trimmed.chars().take_while(|&c| c == '`').count();
                if fence_len >= 3 {
                    let info = trimmed[fence_len..].trim();
                    let tags: Vec<&str> = info.split(',').map(str::trim).collect();
                    if tags.first() == Some(&"rust") && tags.contains(&"check") {
                        current = Some((i + 1, "`".repeat(fence_len), String::new()));
                    }
                }
            }
            Some((start, fence, code)) => {
                if trimmed.starts_with(fence.as_str()) && trimmed.trim_start_matches('`').trim().is_empty() {
                    out.push(Snippet {
                        source: path.to_path_buf(),
                        line: *start,
                        code: std::mem::take(code),
                    });
                    current = None;
                } else {
                    code.push_str(line);
                    code.push('\n');
                }
            }
        }
    }
    if let Some((start, ..)) = current {
        return Err(format!("{}:{start}: unterminated rust,check block", path.display()));
    }
    Ok(out)
}

fn render(root: &Path, snippets: &[Snippet]) -> String {
    let mut s = String::from("// @generated by `cargo xtask check-snippets`. Do not edit.\n\n");
    for (i, snip) in snippets.iter().enumerate() {
        let rel = snip.source.strip_prefix(root).unwrap_or(&snip.source);
        let _ = writeln!(s, "/// {}:{}", rel.display(), snip.line);
        let _ = writeln!(s, "#[allow(unused, dead_code, clippy::all)]");
        let _ = writeln!(s, "mod snippet_{i:03} {{");
        let _ = writeln!(s, "    use bevy::prelude::*;");
        for line in snip.code.lines() {
            if line.is_empty() {
                s.push('\n');
            } else {
                let _ = writeln!(s, "    {line}");
            }
        }
        s.push_str("}\n\n");
    }
    s
}
