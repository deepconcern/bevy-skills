# bevy-skills

Version-aware AI skills for the [Bevy](https://bevy.org) game engine and its ecosystem, packaged as
a Claude Code plugin marketplace.

> **Unofficial.** This project isn't affiliated with or endorsed by the Bevy project. The
> authority on Bevy is always the [official docs](https://bevy.org/learn/), the
> [migration guides](https://bevy.org/learn/migration-guides/introduction/) and the crate source for
> the version you use.

## Why

Bevy breaks its API every minor release, and AI models have seen about ten versions of it. Left
alone, an agent confidently writes removed APIs: `*Bundle` structs, `EventReader`, `Trigger<T>`,
`despawn_recursive`, and so on. These skills give the agent what its training data gets wrong:

- a **stale-API list** ("don't write this, write that"), going back several releases;
- **current idioms** for the version in your `Cargo.lock`, with every snippet compiled in CI;
- **migration notes** for the newest upgrade;
- a **source-trust policy**, so outdated tutorials (for example the unofficial Cheat Book) are
  used for ideas only.

They deliberately don't copy the API reference. For full API detail the agent reads the locked crate
source and examples on disk, which always match your version exactly.

## What's included

| Plugin | Targets | Contents |
|---|---|---|
| `bevy` | Bevy 0.20 | Skill (`stale-apis`, ECS, app/plugins/states, BSN scenes, UI, assets, rendering, 0.19→0.20 migration, recommended `clippy.toml`) and two hooks |

Planned as separate plugins: `bevy_egui`, `avian`, `leafwing-input-manager`, `bevy_asset_loader`.

Hooks shipped with the `bevy` plugin (no network, no `jq`, never blocking):

- **SessionStart:** if `Cargo.lock` has a Bevy minor the skill doesn't cover, it tells the agent to
  rely on the locked source instead. It stays silent otherwise.
- **After WebFetch/WebSearch:** if a result comes from a known outdated or mismatched source (the
  Cheat Book, Bevy's unreleased `main` branch, `docs.rs/bevy/latest`), it adds a one-line reminder.

## Install

In Claude Code:

```text
/plugin marketplace add deepconcern/bevy-skills
/plugin install bevy@bevy-skills
```

On Claude Code 2.1.275 or later you can do it in one step:

```text
/plugin install bevy --marketplace deepconcern/bevy-skills
```

To share it with everyone working on a game repo, declare the marketplace in that repo's
`.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "bevy-skills": {
      "source": { "source": "github", "repo": "deepconcern/bevy-skills" }
    }
  },
  "enabledPlugins": { "bevy@bevy-skills": true }
}
```

### Pinning to an older Bevy

`main` covers the current Bevy minor (and the previous one during a transition). When a new minor
lands, the old state is tagged `bevy-<minor>` (for example `bevy-0.20`). A game that stays on an old
Bevy pins that tag:

```text
/plugin marketplace add deepconcern/bevy-skills#bevy-0.20
```

or in settings: `"source": { "source": "github", "repo": "deepconcern/bevy-skills", "ref": "bevy-0.20" }`.

## Recommended game-repo setup

- Copy `plugins/bevy/skills/bevy/references/<minor>/clippy.toml` to your workspace root.
- Run `cargo clippy --all-targets -- -D deprecated -D warnings` in CI. Removed APIs already fail to
  compile, and this catches deprecated ones and other traps.
- Keep game-specific rules (your architecture, scripting conventions, game rules) in the game repo's
  own `CLAUDE.md` / `.claude/skills/`, not here.

## Repository layout

```text
.claude-plugin/marketplace.json     marketplace manifest
plugins/bevy/                       the bevy plugin
  .claude-plugin/plugin.json
  hooks/hooks.json                  SessionStart + PostToolUse hooks
  scripts/                          hook scripts (bash)
  skills/bevy/SKILL.md              router: finds the locked version, loads matching references
  skills/bevy/references/0.20/      stale-apis, topic files, outdated-sources, clippy.toml
  skills/bevy/migrations/           newest upgrade only
checks/bevy-0.20/                   crate pinned to bevy =0.20.1 that compiles every snippet
xtask/                              `cargo xtask check-snippets`
scripts/staleness.sh                compares skill targets with crates.io (weekly workflow)
tests/hooks.sh                      hook script tests
```

## Development

```sh
cargo xtask check-snippets   # extract ```rust,check blocks and cargo check them (needs rustc 1.97.1+)
bash tests/hooks.sh          # hook script tests
bash scripts/staleness.sh    # is any skill behind crates.io?
claude plugin validate .     # marketplace and plugin manifests
```

On Linux, compiling Bevy needs `pkg-config libudev-dev libwayland-dev libxkbcommon-dev`.
See [CONTRIBUTING.md](CONTRIBUTING.md) for snippet rules, adding a crate and moving to a new Bevy
minor.

## License

Dual-licensed under [MIT](LICENSE-MIT) or [Apache-2.0](LICENSE-APACHE), at your option, the same as
Bevy. The stale-API tables and migration notes are distilled from Bevy's official migration guides
([bevyengine/bevy-website](https://github.com/bevyengine/bevy-website), MIT, © Bevy Engine), and each
file links its sources.
