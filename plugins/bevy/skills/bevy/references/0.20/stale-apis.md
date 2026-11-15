# Stale Bevy APIs: do not write these (Bevy 0.20)

Models have seen roughly ten Bevy versions, and most wrong Bevy code comes from versions before
0.19. Before writing Bevy code, scan the table for the area you're working in. If you are about to
write something in the "Don't write" column, use the "Write instead" column.

"Since" is the release that removed or deprecated the old form. Every old form here is absent or
`#[deprecated]` in the bevy 0.20.1 source. Every replacement was checked against that source, and
the `rust,check` blocks compile in CI.

PR 2 extends this table with a full pass over the 0.14 to 0.17 migration guides. The "Since"
values for 0.13 to 0.15 entries come from memory of those releases, and that pass will audit them.

## ECS, app and scheduling

| Don't write | Since | Write instead |
|---|---|---|
| `app.add_system(f)`, `add_startup_system(f)`, `add_plugin(p)` | 0.11 | `app.add_systems(Update, f)`, `add_systems(Startup, f)`, `add_plugins(p)` |
| `IntoSystemConfigs` | 0.16 | `IntoScheduleConfigs` (it's in the prelude, so usually no import needed) |
| Any `*Bundle` struct: `SpriteBundle`, `PbrBundle`, `Camera3dBundle`, `NodeBundle`, `TextBundle`, `SpatialBundle`, … | 0.15 | Spawn the main component. Required components add the rest: `commands.spawn((Camera3d::default(), Transform::from_xyz(..)))` |
| `query.get_single()`, or `query.single()` expected to panic | 0.16 | `query.single()` returns `Result`. Use `?` in a system that returns `Result`, or take a `Single<D, F>` parameter |
| `despawn_recursive()` | 0.16 | `despawn()` (it's recursive now). Use `despawn_children()` for children only |
| `Parent`, `parent.get()` | 0.16 | `ChildOf`, `child_of.parent()` |
| `set_parent(p)`, `push_children` | 0.16 | `insert(ChildOf(p))`, `add_children(&[..])`, or `children![..]` when spawning |
| `clear_children()`, `remove_children(..)`, `remove_child(..)` | 0.18 | `detach_all_children()`, `detach_children(..)`, `detach_child(..)` (they detach, they don't despawn) |
| `#[derive(Event)]` + `EventReader`/`EventWriter`/`Events<T>`/`add_event` for buffered events | 0.17 | `#[derive(Message)]` + `MessageReader`/`MessageWriter`/`Messages<T>`/`add_message` |
| `writer.send(e)` on a message writer, `world.send_event(e)`, `commands.send_event(e)` | 0.16 / 0.17 | `writer.write(e)`, `world.write_message(e)`, `commands.write_message(e)` |
| `Trigger<E>` in observers, `trigger.target()`, `trigger.entity()` | 0.17 | `On<E>`, then read the target field on the event: `event.entity` |
| `OnAdd`, `OnInsert`, `OnReplace`, `OnRemove`, `OnDespawn` | 0.17 | `Add`, `Insert`, `Discard`, `Remove`, `Despawn` |
| `Replace`, `on_replace` hooks, `#[component(on_replace = ..)]` | 0.19 | `Discard`, `on_discard`, `#[component(on_discard = ..)]` |
| `On<Add, MyComponent>` (bundle as second generic) | 0.20 | `On<Add<MyComponent>>`. Dynamic components use `On<Add<()>>` |
| `world.trigger_targets(E, entity)` | 0.17 | `#[derive(EntityEvent)] struct E { entity: Entity }`, then `commands.trigger(E { entity })` |
| `#[event(traversal = ..)]`, `#[event(auto_propagate)]` | 0.17 | `#[derive(EntityEvent)] #[entity_event(propagate)]` (defaults to `ChildOf`) |
| `Condition` trait | 0.17 | `SystemCondition` |
| `*Set` / `*System` set names: `TransformSystem`, `UiSystem`, `RenderSet`, `PickSet`, `InputSystem`, … | 0.17 | `TransformSystems`, `UiSystems`, `RenderSystems`, `PickingSystems`, `InputSystems`, … |
| `#[derive(Component, Resource)]` on one type | 0.19 | Resources are components now. Split into two types, one `Component` and one `Resource` |
| `init_non_send_resource`, `insert_non_send_resource` | 0.19 | `init_non_send`, `insert_non_send` |
| `DefaultErrorHandler`, `default_error_handler` | 0.19 | `FallbackErrorHandler`, `fallback_error_handler` |
| `impl Command<Result> for T` | 0.19 | `impl Command for T { type Out = Result; .. }` |
| `for item in query.iter_many(list)` yielding items directly | 0.20 | It yields `Result` now. Use `.iter_many(list).matched()` to skip non-matching entities as before |
| `DeferredWorld::query(&mut state)` | 0.20 | `state.query_mut(&mut world)` |
| `Name::from(non_static_str)` | 0.20 | `Name::new(s.to_owned())`. `From` only accepts `&'static str` |
| `fn sys(world: &mut World, ..)` "must be first" rule | 0.20 | `&mut World` is a normal `SystemParam` now and can appear anywhere in the parameter list |

## States

| Don't write | Since | Write instead |
|---|---|---|
| `app.add_state::<S>()` | 0.13 | `app.init_state::<S>()` or `insert_state(S::Variant)` |
| `StateScoped(S::A)` | 0.17 | `DespawnOnExit(S::A)` (or `DespawnOnEnter`) |
| `next.set_if_neq(s)` | 0.20 | `next.set_if_different(s)`. The old name is deprecated |
| Expecting `next.set(s)` to do nothing when already in `s` | 0.18 | `set` always runs `OnExit`/`OnEnter` now. Use `set_if_different` to skip same-state transitions |

## Time and input

| Don't write | Since | Write instead |
|---|---|---|
| `time.delta_seconds()`, `elapsed_seconds()` | 0.15 | `time.delta_secs()`, `elapsed_secs()` |
| `timer.finished()`, `timer.paused()` | 0.17 | `timer.is_finished()`, `timer.is_paused()` |
| `Res<Input<KeyCode>>` | 0.13 | `Res<ButtonInput<KeyCode>>` |
| `KeyCode::W`, `KeyCode::Key1` | 0.13 | `KeyCode::KeyW`, `KeyCode::Digit1` |

## Rendering, 2D and 3D

| Don't write | Since | Write instead |
|---|---|---|
| `Color::rgb(..)`, `Color::rgba(..)` | 0.14 | `Color::srgb(..)`, `Color::srgba(..)`, `Color::srgb_u8(..)` |
| `PbrBundle { mesh, material, .. }` | 0.15 | `(Mesh3d(mesh), MeshMaterial3d(material), Transform::..)` |
| `SpriteBundle { texture, .. }` | 0.15 | `Sprite::from_image(handle)` or `Sprite { image: handle, .. }` |
| `Mesh2dHandle`, `MaterialMesh2dBundle` | 0.15 | `Mesh2d(handle)`, `MeshMaterial2d(handle)` |
| `Camera { hdr: true, .. }` | 0.17 | Add the `Hdr` component to the camera entity |
| `transform.compute_matrix()` | 0.17 | `transform.to_matrix()` |
| `insert_resource(AmbientLight { .. })` | 0.18 | `insert_resource(GlobalAmbientLight { .. })`. `AmbientLight` is now a per-camera component |
| `gizmos.cuboid(..)` | 0.18 | `gizmos.cube(..)` |
| `PointLight { shadows_enabled: true, .. }` (also spot/directional) | 0.19 | `shadow_maps_enabled: true` |
| `SceneRoot(asset_server.load("x.gltf#Scene0"))`, `SceneBundle`, `DynamicScene` | 0.19 | `WorldAssetRoot(..)`, `DynamicWorld`. The old scene crate is `bevy::world_serialization`, and `bevy::scene` is now BSN (see `scenes.md`) |
| `Tonemapping::None` to mean "no tone curve" | 0.20 | `Tonemapping::Linear`. `None` is now a full passthrough with no grading or dither |
| Expecting screen-space transmission on `Camera3d` by default | 0.20 | Add `ScreenSpaceTransmission` to the camera explicitly |
| `naga_oil` shaders: `#import a::b`, `#ifdef`, `#define_import_path`, `.wgsl` with directives | 0.20 | WESL: `import a::b;`, `@if(FLAG)`, file renamed to `.wesl`. GLSL support is removed |
| `bevy::math::primitives::Cuboid` and similar | 0.20 | Primitives moved to `bevy_shape`. Use `bevy::prelude::*` or `bevy::shape::*` |

## Picking

| Don't write | Since | Write instead |
|---|---|---|
| `Pointer<Pressed>`, `Pointer<Released>` | 0.17 | (then renamed again in 0.20, see below) |
| `On<Pointer<Click>>`, `click.pointer_location.position` | 0.20 | `On<PointerClick>`, `click.pointer.position` (`Vec2`). Same for `PointerPress`, `PointerOver`, `PointerDrag`, … |
| Generic `On<Pointer<E>>` handlers | 0.20 | `fn h<E: PointerEvent>(e: On<E>)` |

## UI and text

| Don't write | Since | Write instead |
|---|---|---|
| `Style { .. }` component | 0.15 | Those fields live on `Node { .. }` |
| `UiImage` | 0.15 | `ImageNode` |
| `TargetCamera` | 0.15 | `UiTargetCamera` |
| `Text::from_section(..)`, `TextSection`, `TextStyle` | 0.15 | `Text::new("..")` + `TextFont` + `TextColor`. Child `TextSpan` entities for extra runs |
| `JustifyText` | 0.17 | `Justify` |
| `BorderColor(color)` | 0.17 | `BorderColor::all(color)` (each side has its own colour now) |
| `BorderRadius` as its own component | 0.18 | `Node { border_radius: BorderRadius::all(px(8)), .. }` |
| `TextFont { font: handle, font_size: 24.0, .. }` | 0.19 | `TextFont { font: handle.into(), font_size: FontSize::Px(24.0), .. }` |
| `FontSource::SansSerif`, `FontSource::Monospace` | 0.20 | `FontSource::sans_serif()`, `FontSource::monospace()` |
| `Interaction` component, prelude `Button`, polling `Changed<Interaction>` | 0.20 | `bevy::ui_widgets::Button` + `Hovered` + `Pressed`, and observe `Activate` for clicks. See `ui.md` |
| Assuming `TextFont::default()` is 20px fixed | 0.20 | Its default is `FontSize::Rem(1.)`, which scales with the `RemSize` resource. Set `FontSize::Px(..)` for a fixed size |
| `EditableText` alone as a text input | 0.20 | `EditableText` + `TextInput` together |

## Assets

| Don't write | Since | Write instead |
|---|---|---|
| `weak_handle!("…")`, `Handle::Weak` | 0.17 | `uuid_handle!("…")`, `Handle::Uuid` |
| `assets.insert(id, asset)` ignoring the result | 0.17 | It returns `Result` now: handle or `?` it |
| `load_with_settings`, `load_untyped`, `load_acquire`, `load_*_override*` | 0.19 | `asset_server.load_builder().with_settings(..).load(path)` (also `.load_untyped(path)`, `.override_unapproved()`) |
| `load_context.loader().immediate().load(p)` | 0.19 | `load_context.load_builder().load_value(p)` |

## Toolchain

| Don't write | Since | Write instead |
|---|---|---|
| Older stable toolchains for Bevy 0.20 | 0.20 | Bevy 0.20.1 and its WESL crates need **rustc 1.97.1 or newer** |

## Correct 0.20 forms, compiled

```rust,check
#[derive(Component)]
struct Player;

#[derive(Message)]
struct Damage {
    amount: u32,
}

#[derive(EntityEvent)]
struct Hit {
    entity: Entity,
}

fn spawn(mut commands: Commands) {
    commands.spawn((Camera3d::default(), Transform::from_xyz(0.0, 5.0, 10.0)));
    commands
        .spawn((Player, Transform::default(), children![Name::new("weapon")]))
        .observe(|hit: On<Hit>| info!("{} was hit", hit.entity));
}

fn on_player_added(add: On<Add<Player>>, names: Query<&Name>) {
    let _ = names.get(add.entity);
}

fn read_damage(mut damage: MessageReader<Damage>, player: Single<Entity, With<Player>>, mut commands: Commands) {
    for d in damage.read() {
        if d.amount > 0 {
            commands.trigger(Hit { entity: *player });
        }
    }
}

fn fallible(query: Query<&Transform, With<Player>>) -> Result {
    let transform = query.single()?;
    info!("player at {}", transform.translation);
    Ok(())
}

fn plugin(app: &mut App) {
    app.add_message::<Damage>()
        .add_observer(on_player_added)
        .add_systems(Startup, spawn)
        .add_systems(Update, (read_damage, fallible));
}
```

```rust,check
#[derive(States, Debug, Clone, Copy, Default, PartialEq, Eq, Hash)]
enum GameState {
    #[default]
    Menu,
    Playing,
}

fn start(keys: Res<ButtonInput<KeyCode>>, mut next: ResMut<NextState<GameState>>) {
    if keys.just_pressed(KeyCode::KeyW) {
        next.set_if_different(GameState::Playing);
    }
}

fn menu(mut commands: Commands) {
    commands.spawn((Text::new("Menu"), DespawnOnExit(GameState::Menu)));
}

fn tick(time: Res<Time>, mut timer: Local<Timer>) {
    if timer.tick(time.delta()).is_finished() {
        info!("{}", time.delta_secs());
    }
}

fn plugin(app: &mut App) {
    app.init_state::<GameState>()
        .add_systems(OnEnter(GameState::Menu), menu)
        .add_systems(Update, (start, tick).run_if(in_state(GameState::Menu)));
}
```

```rust,check
fn lights_and_text(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.insert_resource(GlobalAmbientLight {
        brightness: 200.0,
        ..default()
    });
    commands.spawn((
        PointLight {
            shadow_maps_enabled: true,
            ..default()
        },
        Transform::from_xyz(4.0, 8.0, 4.0),
    ));
    commands.spawn((
        Text::new("Score"),
        TextFont {
            font: asset_server.load("fonts/Inter.ttf").into(),
            font_size: FontSize::Px(24.0),
            ..default()
        },
        TextColor(Color::srgb(0.9, 0.9, 0.9)),
    ));
    commands.spawn(WorldAssetRoot(asset_server.load("level.gltf#Scene0")));
}
```
