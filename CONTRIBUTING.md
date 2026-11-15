# Contributing

Work follows the same process as the rest of the project: open an issue with a spec, get it
approved, then open a PR that links the issue. Nothing is pushed straight to `main`.

## What belongs in a skill

- **Yes:** things models get wrong for this version. That means removed or renamed APIs, new
  idioms, quiet behaviour changes, setup gotchas, and pointers to the right upstream example.
- **No:** copies of the API reference, tutorials, or anything game-specific. The agent reads the
  locked crate source for full API detail.
- Keep each topic file short (aim for under ~300 lines) so loading one is cheap.
- Every claim must be checked against the crate source for the targeted patch version. Cite the
  release notes or migration guide you used.

## Snippet rules

- A Rust block fenced as ```` ```rust,check ```` must compile against `checks/<crate>-<minor>/`.
  `cargo xtask check-snippets` extracts every such block into that crate's `src/generated.rs`
  (gitignored) and runs `cargo check` with `#![deny(deprecated)]`.
- Each block becomes its own module with `use bevy::prelude::*;` already imported. So a block holds
  items (functions, types, impls), and anything else it needs it imports itself. Put statements
  inside a `fn`.
- Use ```` ```rust,ignore ```` (or no tag) for examples of what *not* to write, and for snippets
  that need crates the checks crate doesn't have.
- The files scanned for each checks crate are listed in its `Cargo.toml` under
  `[package.metadata.snippets] sources`.

## Stale-API entries

Each row in `references/<minor>/stale-apis.md` has the old form, the release that removed or
deprecated it, and the replacement. Before adding a row, confirm the old form is absent or
`#[deprecated]` in the targeted source, and that the replacement exists there. Add a `rust,check`
example when the replacement isn't obvious.

## Outdated sources

`references/<minor>/outdated-sources.md` is both documentation and data. The plugin's web hook reads
the table rows. Keep the first column a single regular expression in backticks (write a literal `|`
as `\|`), and only list a source after checking which Bevy version it actually matches.

## Adding a new Bevy minor version

1. Wait until the ecosystem crates this repo covers support the new minor. The weekly staleness
   workflow opens an issue when crates.io has one.
2. Open a spec issue for the upgrade.
3. In the upgrade PR:
   - add `references/<new>/`, starting from a copy of the previous minor's folder;
   - write `migrations/<old>-to-<new>.md` from the official migration guide (it ships in the crate as
     `_release-content/`, and on bevy.org);
   - move still-relevant rows from the previous `migrations/*.md` into `references/<new>/stale-apis.md`,
     then delete that older migration file;
   - add `checks/bevy-<new>/` pinned to `=<new>.<patch>`, and point its snippet sources at the new
     folder;
   - update `SKILL.md` metadata (`target-version`, `supported-versions`, `verified-against`,
     `skill-version`) and the plugin and marketplace `version` fields;
   - update the CI toolchain if the new Bevy needs a newer rustc.
4. Before that PR merges, tag the current `main` as `bevy-<old>` so games on the old version can pin it.
5. Drop `references/<older>/` and its checks crate once two minors are on `main`. Only the current
   and previous minors are kept.

## Adding a crate (bevy_egui, avian, …)

One plugin per crate, so a game installs only what it uses:

```text
plugins/<crate>/.claude-plugin/plugin.json
plugins/<crate>/skills/<crate>/SKILL.md          (same metadata keys as the bevy skill)
plugins/<crate>/skills/<crate>/references/<crate-minor>/
```

Then add the plugin to `.claude-plugin/marketplace.json`, and add a checks crate (or extend an
existing one) that depends on the crate and the matching Bevy.

## Versioning

- `skill-version` in `SKILL.md` and `version` in `plugin.json` are semver for the skill content:
  patch for fixes, minor for new entries or topics, major for a new Bevy minor.
- `target-version` is the library version the content describes. It's independent of
  `skill-version`.
