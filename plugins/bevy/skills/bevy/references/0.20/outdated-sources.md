# Outdated and mismatched sources (checked 2026-11-15)

Rank sources like this, and only copy code from tiers 1 to 3:

1. The crate source for the version in `Cargo.lock` (`~/.cargo/registry/src/*/bevy_*-<ver>/`) and
   `cargo doc`.
2. Upstream `examples/` at the same version (they ship inside the `bevy-<ver>` crate source), or
   the bevy repo at tag `v<ver>`.
3. Official docs and guides for that version: bevy.org release notes and migration guides, and
   docs.rs pinned to the exact version (`docs.rs/bevy/<ver>/`).
4. Everything else: blogs, tutorials, videos, Stack Overflow, Reddit, Discord logs, old GitHub
   issues and the sources below. Use these for **ideas only**. Before writing any API from them,
   check it against tier 1 and run it through `stale-apis.md`. A source that doesn't name its
   Bevy version counts as old.

The table is also read by the plugin's web hook. The first column is a regular expression matched
against fetched URLs, so keep it one pattern per row, wrapped in backticks.

| URL pattern | Why it doesn't match Bevy 0.20 |
|---|---|
| `bevy-cheatbook\.github\.io` | Unofficial Bevy Cheat Book. Unmaintained by its author's own notice. Each page states the version it was written for (pages are marked between 0.11 and 0.16, and core ECS pages say 0.13 or 0.14). Predates required components, messages, observers-as-`On`, BSN and more. |
| `github\.com/bevy-cheatbook/` | Source of the Cheat Book above. Same caveat. |
| `docs\.rs/bevy/latest` | "latest" may be newer than the project's lock. Use `docs.rs/bevy/<locked version>/` instead. |
| `github\.com/bevyengine/bevy/(blob\|tree)/main` | Bevy's `main` branch holds **unreleased** APIs that are newer than 0.20. Use tag `v0.20.1` (or the crate source) instead. |
| `raw\.githubusercontent\.com/bevyengine/bevy/main` | Same as above: unreleased `main`, not 0.20. |
