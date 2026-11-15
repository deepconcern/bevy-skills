---
name: bevy
description: Use when writing, reviewing, debugging or upgrading Rust code that uses the Bevy game engine (ECS, systems, observers, BSN scenes, UI, assets, rendering, states). Loads the stale-API list and current idioms for the Bevy version in Cargo.lock.
license: MIT OR Apache-2.0
metadata:
  skill-version: "0.2.0"
  target-crate: "bevy"
  target-version: "0.20"
  supported-versions: "0.20"
  verified-against: "bevy 0.20.1, 2026-11-15"
---

# Bevy

Bevy changes its API every minor release, roughly every four months, and your training data mixes
about ten versions of it. Treat your memory of Bevy APIs as **unreliable by default**. This skill
gives you the version-specific facts. The locked crate source gives you the full API.

## 1. Find the project's Bevy version

```sh
grep -A1 '^name = "bevy"$' Cargo.lock
```

Use the minor version (`0.20.1` means `0.20`). With no `Cargo.lock`, read the `bevy` requirement in
`Cargo.toml`. A brand-new project should use the newest version listed in `supported-versions`.

## 2. Load the matching references

If the minor version is listed in `supported-versions` above:

1. **Always read `references/<minor>/stale-apis.md` first**, before writing any Bevy code.
2. Then read only the topic file you need:
   - `ecs.md`: components, required components, queries, messages vs events vs observers,
     hierarchy and relationships, commands
   - `app-and-plugins.md`: plugins, schedules, system sets, run conditions, states, error handling,
     cargo features
   - `scenes.md`: BSN (`bsn!`, `bsn_list!`), scene composition, glTF via world serialization
   - `ui.md`: `Node` layout, text and fonts, buttons and widgets, picking events
   - `assets.md`: loading, the load builder, custom assets and loaders
   - `render.md`: cameras, meshes, materials, lights, sprites, WESL shaders
3. Before using code from the web, check `outdated-sources.md`.
4. To upgrade a project, follow `migrations/<old>-to-<new>.md` if one exists for that hop.

If the minor version is **not** listed: say so plainly to the user. Don't guess from memory. Work
from the sources in step 3, and treat `stale-apis.md` from the nearest listed version as a hint
only.

## 3. Ground truth for anything not covered here

In order of trust:

1. **The locked crate source**: `~/.cargo/registry/src/*/bevy_<crate>-<version>/src/`. Run
   `cargo fetch` if it's missing. `grep` it for the type or method before using it. `cargo doc
   --open -p bevy` builds docs for the exact version.
2. **Upstream examples at the same version.** They ship inside the crate:
   `~/.cargo/registry/src/*/bevy-<version>/examples/`. The official migration guides ship there too,
   in `_release-content/`.
3. **Official docs pinned to the version**: `docs.rs/bevy/<version>/`, and bevy.org release notes and
   migration guides.
4. **Anything else is ideas only.** Never copy code from blogs, tutorials, Stack Overflow, the
   unofficial Bevy Cheat Book or Bevy's `main` branch without checking every API against (1).
   See `outdated-sources.md`.

## 4. Before you finish

- `cargo check` must pass. Prefer `cargo clippy -- -D deprecated`, because deprecated Bevy APIs
  still compile but are on their way out.
- If you wrote an API that isn't in these references, confirm it exists in the locked source.
- If you find a mistake or a missing stale API in this skill, tell the user so it can be fixed
  upstream in the `bevy-skills` repo.

Recommended lint setup for a game repo: `references/<minor>/clippy.toml`.
