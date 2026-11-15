# Scenes with BSN (Bevy 0.20)

BSN ("Bevy Scene Notation") landed in 0.19 as `bevy::scene`, and its syntax changed in 0.20. Models
have almost no training data for it, so follow this file and the crate docs (`bevy_scene` crate
root docs, `bsn!` macro docs) rather than memory. Upstream examples: `examples/scene/bsn.rs`,
`examples/3d/3d_scene.rs`, `examples/ui/`.

- The **old** `bevy_scene` (`Scene`, `SceneRoot`, `DynamicScene`) was renamed to
  `bevy::world_serialization` (`WorldAsset`, `WorldAssetRoot`, `DynamicWorld`) in 0.19. Use it for
  glTF scene spawning and save/load-style world serialization. GLTF has not been ported to BSN yet
  (as of 0.20).
- `.bsn` asset files are **not** shipped yet. BSN is written inline with the `bsn!` / `bsn_list!`
  macros.
- Plain `commands.spawn((A, B, children![..]))` is still fully supported. BSN pays off for
  reusable, composable, patchable "objects" and for UI trees.

## Syntax (0.20)

| Want | Write |
|---|---|
| One entity with components | `bsn! { A B { x: 1 } C(2) }` (no commas between components) |
| Several root entities | `bsn_list! { A -- B -- C }` (entities separated by `--`) |
| Children | `Children [ A B -- C ]`. Any `RelationshipTarget` works the same way |
| Name + referenceable entity | `#Player`. Reference it elsewhere in the same macro as `#Player` |
| Include another scene function | `@enemy()` / `@button("Ok")` (`@` prefix required in 0.20) |
| Include a scene expression | `@{some_scene}` |
| Insert a `SceneList` value into a relationship | `Children [ #Header -- {items} -- #Footer ]` |
| Arbitrary Rust expression as a value | `{hp * 2}` |
| Component value from a variable or builder | `transform`, `Transform::from_xyz(1., 2., 3.).looking_at(Vec3::ZERO, Vec3::Y)` (no `template_value(..)` wrapper anymore) |
| Patch only some fields | `Health { max: 200 }` keeps other fields from earlier patches or defaults |
| Entity observer | `on(\|e: On<PointerClick>\| { .. })` |
| Asset by path for a `Handle<T>` field | `Sprite { image: "player.png" }` |
| Inline asset value | `Mesh3d(asset_value(Cuboid::new(1., 1., 1.)))` |
| Cached include of a scene asset | `:"enemy.bsn"` (asset loader required, so not usable out of the box in 0.20) |

Gotchas:

- **Don't** separate entities with `,` or wrap them in `(..)`. Both forms are deprecated in 0.20,
  and some doc comments in the 0.20 crate still show the old comma form.
- Use braces: `bsn_list! { .. }`, not `bsn_list![..]` or `bsn_list!(..)`. rustfmt leaves only the
  brace form alone.
- **Enums must specify every field** (`Foo::A { x: 1, y: 0 }`). There are no per-variant defaults.
- A component is usable in BSN if it derives `Default + Clone` (the normal case) **or**
  `FromTemplate` (needed when a field is a `Handle<T>` or an `Entity` that should accept an asset
  path or a `#Name`). Don't derive both.
- Components should store `Entity`, never `EntityTemplate`. Derive `FromTemplate` so `#Name`
  converts automatically.
- `#Name` scope is one macro invocation. Entities in one `bsn_list!` share a scope.

## Spawning

- From a `Startup` system: `app.add_systems(Startup, my_scene.spawn())`, where
  `fn my_scene() -> impl Scene` (or `-> impl SceneList`).
- From commands: `commands.spawn_scene(scene)` resolves immediately and logs an error if a
  dependency (for example an included scene asset) isn't loaded. `commands.queue_spawn_scene(scene)`
  waits for dependencies and spawns during the `SpawnScene` schedule. There are `_list` variants
  for `SceneList`.
- `#[derive(SceneComponent)]` ties a component to a scene function (`Self::scene()` by default, or
  `#[scene(path)]`). It must be spawned with scene APIs. Plain `spawn` logs an error.

```rust,check
#[derive(Component, Default, Clone)]
struct Health {
    current: u32,
    max: u32,
}

#[derive(Component, Default, Clone)]
struct Enemy;

fn enemy(hp: u32) -> impl Scene {
    bsn! {
        Enemy
        Health { current: hp, max: hp }
        Transform
    }
}

fn level() -> impl SceneList {
    bsn_list! {
        #Goblin
        @enemy(30)
        --
        #Ogre
        @enemy(120)
        Health { max: 150 }
        Transform::from_xyz(4.0, 0.0, 0.0)
        --
        DirectionalLight { shadow_maps_enabled: true }
        Transform::from_xyz(1.0, 4.0, 2.0).looking_at(Vec3::ZERO, Vec3::Y)
        --
        Camera3d
        Transform::from_xyz(0.0, 6.0, 12.0).looking_at(Vec3::ZERO, Vec3::Y)
    }
}

fn spawn_more(mut commands: Commands) {
    commands.spawn_scene(bsn! {
        @enemy(10)
        Children [
            Name::new("loot")
        ]
    });
}

fn plugin(app: &mut App) {
    app.add_systems(Startup, (level.spawn(), spawn_more));
}
```

```rust,check
#[derive(Component, FromTemplate)]
struct Portrait {
    image: Handle<Image>,
    tint: Color,
}

#[derive(Component, FromTemplate)]
struct Follows {
    leader: Entity,
}

fn party() -> impl SceneList {
    bsn_list! {
        #Leader
        Portrait { image: "portraits/leader.png", tint: Color::WHITE }
        Mesh3d(asset_value(Cuboid::new(1.0, 2.0, 1.0)))
        MeshMaterial3d::<StandardMaterial>(asset_value(Color::srgb(0.8, 0.2, 0.2)))
        --
        #Follower
        Follows { leader: #Leader }
        on(|click: On<PointerClick>| info!("clicked {}", click.entity))
    }
}
```
