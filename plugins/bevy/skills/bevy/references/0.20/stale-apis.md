# Stale Bevy APIs: do not write these (Bevy 0.20)

Models have seen roughly ten Bevy versions, and most wrong Bevy code comes from versions before
0.19. Before writing Bevy code, scan the table for the area you're working in. If you are about to
write something in the "Don't write" column, use the "Write instead" column.

"Since" is the release that removed or deprecated the old form. Every old form here is absent or
`#[deprecated]` in the bevy 0.20.1 source. Every replacement was checked against that source, and
the `rust,check` blocks compile in CI.

Coverage goes back to the 0.14 migration guide, plus a few 0.11 and 0.13 renames that models still
write. Each "Since" value was checked against the official migration guide for that release, or by
diffing the published crate sources of the two versions.

## ECS, app and scheduling

| Don't write | Since | Write instead |
|---|---|---|
| `app.add_system(f)`, `add_startup_system(f)`, `add_plugin(p)` | 0.11 | `app.add_systems(Update, f)`, `add_systems(Startup, f)`, `add_plugins(p)` |
| `IntoSystemConfigs` | 0.16 | `IntoScheduleConfigs` (it's in the prelude, so usually no import needed) |
| Any `*Bundle` struct: `SpriteBundle`, `PbrBundle`, `Camera3dBundle`, `NodeBundle`, `TextBundle`, `SpatialBundle`, … | 0.15 | Spawn the main component. Required components add the rest: `commands.spawn((Camera3d::default(), Transform::from_xyz(..)))` |
| `app.observe(f)`, `world.observe(f)`, `commands.observe(f)`, `entity.observe_entity(f)` | 0.15 | `add_observer(f)` for global observers, `entity.observe(f)` for one entity |
| `commands.add(cmd)`, `commands.push(cmd)` | 0.15 | `commands.queue(cmd)` |
| `commands.register_one_shot_system(f)` | 0.15 | `commands.register_system(f)` |
| `commands.get_or_spawn(e)` | 0.15 | `commands.entity(e)` for an existing entity, or `spawn(..)` for a new one |
| `insert_or_spawn_batch(..)` | 0.16 | `spawn_batch(..)`, or keep entities alive with `Disabled` instead of respawning them |
| Run conditions called with `()`: `run_once()`, `on_event::<T>()`, `resource_removed::<T>()` | 0.15 | Pass the function itself: `run_if(run_once)`, `run_if(on_message::<T>)`, `run_if(resource_removed::<T>)` |
| `cond_a.and(cond_b)`, `cond_a.or(cond_b)` (the 0.15 to 0.18 names) | 0.19 | `and_then` / `or_else` to short-circuit, or `and_eager` / `or_eager` to evaluate both. The names went `and_then` → `and` (0.15) → `and_then` again (0.19), so code from 0.15 to 0.18 is the stale one |
| `Handle<T>` used directly as a component | 0.15 | Use the wrapper component: `Mesh3d(h)`, `MeshMaterial3d(h)`, `Sprite { image: h, .. }`, `AudioPlayer(h)`, `WorldAssetRoot(h)`, or your own newtype |
| `query.get_single()`, or `query.single()` expected to panic | 0.16 | `query.single()` returns `Result`. Use `?` in a system that returns `Result`, or take a `Single<D, F>` parameter |
| `despawn_recursive()` | 0.16 | `despawn()` (it's recursive now) |
| `despawn_descendants()` | 0.16 | `despawn_children()` or `despawn_related::<Children>()` |
| `with_children(\|b: &mut ChildBuilder\| ..)`, `b.parent_entity()` | 0.16 | The closure gets `&mut ChildSpawnerCommands`, and the parent is `b.target_entity()` |
| `query.many([a, b])`, `many_mut` | 0.16 | `query.get_many([a, b])?`, `get_many_mut` |
| `query.to_readonly()` | 0.16 | `query.as_readonly()` |
| Hooks as `fn(DeferredWorld, Entity, ComponentId)` | 0.16 | `fn(DeferredWorld, HookContext)`. Destructure `HookContext { entity, .. }` |
| `#[require(A(make_a))]`, `#[require(A(\|\| A(10)))]` | 0.16 | `#[require(A = make_a())]`, `#[require(A(10))]` |
| `apply_deferred` (the function system) | 0.16 | `ApplyDeferred` |
| `bevy::core::Name`, `bevy::core::FrameCount` | 0.16 | `bevy::ecs::name::Name` (also in the prelude), `bevy::diagnostic::FrameCount` |
| `Parent`, `parent.get()` | 0.16 | `ChildOf`, `child_of.parent()` |
| `set_parent(p)`, `push_children` | 0.16 | `insert(ChildOf(p))`, `add_children(&[..])`, or `children![..]` when spawning |
| `clear_children()`, `remove_children(..)`, `remove_child(..)` | 0.18 | `detach_all_children()`, `detach_children(..)`, `detach_child(..)` (they detach, they don't despawn) |
| `ManualEventReader`, `EventCursor`, `EventMutator` | 0.15 / 0.17 | `MessageCursor`, `MessageMutator` |
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
| `writer.send(AppExit)` (unit struct) | 0.14 | `AppExit::Success` or `AppExit::Error(code)`. `App::run()` returns `AppExit`, so `fn main() -> AppExit` works |
| `fn sys(world: &mut World, ..)` "must be first" rule | 0.20 | `&mut World` is a normal `SystemParam` now and can appear anywhere in the parameter list |

## States

| Don't write | Since | Write instead |
|---|---|---|
| `app.add_state::<S>()` | 0.13 | `app.init_state::<S>()` or `insert_state(S::Variant)` |
| `use bevy::ecs::schedule::{States, NextState, OnEnter, ..}` | 0.14 | `bevy::state::state::{..}` and `bevy::state::condition::in_state`, or just the prelude. Needs the `bevy_state` feature |
| `next.0 = Some(s)` | 0.14 | `NextState` is an enum: call `next.set(s)` |
| Expecting `Startup` to run before the initial `OnEnter(S::Default)` | 0.14 | Initial `OnEnter` now runs **before** `Startup`. Move setup into an `OnEnter` of a dedicated setup state, or a sub-state |
| `StateScoped(S::A)` | 0.17 | `DespawnOnExit(S::A)` (or `DespawnOnEnter`) |
| `next.set_if_neq(s)` | 0.20 | `next.set_if_different(s)`. The old name is deprecated |
| Expecting `next.set(s)` to do nothing when already in `s` | 0.18 | `set` always runs `OnExit`/`OnEnter` now. Use `set_if_different` to skip same-state transitions |

## Time and input

| Don't write | Since | Write instead |
|---|---|---|
| `time.delta_seconds()`, `elapsed_seconds()` | 0.15 | `time.delta_secs()`, `elapsed_secs()` |
| `stopwatch.paused()` | 0.15 | `stopwatch.is_paused()` |
| `timer.finished()`, `timer.paused()` | 0.17 | `timer.is_finished()`, `timer.is_paused()` |
| `Res<Input<KeyCode>>` | 0.13 | `Res<ButtonInput<KeyCode>>` |
| `KeyCode::W`, `KeyCode::Key1` | 0.13 | `KeyCode::KeyW`, `KeyCode::Digit1` |
| `ReceivedCharacter` for typed text | 0.14 | Read `KeyboardInput` messages and match `logical_key` (`Key::Character(..)`, `Key::Space`, …) |
| `Res<Gamepads>`, `ButtonInput<GamepadButton>` with `GamepadButton::new(pad, GamepadButtonType::South)` | 0.15 | Gamepads are entities: `Query<&Gamepad>`, then `gamepad.just_pressed(GamepadButton::South)`, `gamepad.get(GamepadAxis::LeftStickX)` |

## Math and gizmos

| Don't write | Since | Write instead |
|---|---|---|
| `Direction2d`, `Direction3d` | 0.14 | `Dir2`, `Dir3` (in `bevy::math` and the prelude) |
| `bevy::utils::FloatOrd` | 0.14 | `bevy::math::FloatOrd` |
| `rect.inset(x)` | 0.14 | `rect.inflate(x)` |
| `.segments(n)` on gizmo builders | 0.14 | `.resolution(n)` |
| `Ray3d::new(origin, Vec3)` | 0.15 | Pass a `Dir3` (for example `Dir3::new(v)?` or `Dir3::NEG_Z`) |
| `rot2.angle_between(other)` | 0.15 | `rot2.angle_to(other)` |

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
| `bevy_mod_picking` crate | 0.15 | Picking is built in: `bevy::picking` |
| `PickingBehavior` | 0.16 | `Pickable` |
| `Pointer<Down>`, `Pointer<Up>`, then `Pointer<Pressed>`, `Pointer<Released>` | 0.16 / 0.17 | Renamed twice. In 0.20: `PointerPress`, `PointerRelease` |
| `Pointer<Drop>` | 0.15 | In 0.20: `PointerDragDrop` |
| `On<Pointer<Click>>`, `click.pointer_location.position` | 0.20 | `On<PointerClick>`, `click.pointer.position` (`Vec2`). Same for `PointerPress`, `PointerOver`, `PointerDrag`, … |
| Generic `On<Pointer<E>>` handlers | 0.20 | `fn h<E: PointerEvent>(e: On<E>)` |

## UI and text

| Don't write | Since | Write instead |
|---|---|---|
| `Style { .. }` component | 0.15 | Those fields live on `Node { .. }` |
| `UiImage` | 0.15 | `ImageNode` |
| `TargetCamera` | 0.16 | `UiTargetCamera` |
| `Query<&Node>` to read the computed size or position | 0.15 | `Query<&ComputedNode>`. `Node` is now the style input |
| `BreakLineOn` | 0.15 | `LineBreak` |
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
| `AssetLoader::load` returning `BoxedFuture` with `Box::pin(async move { .. })` | 0.14 | `async fn load(&self, reader: &mut dyn Reader, ..)` |
| `Handle::weak_from_u128(..)` | 0.16 | `uuid_handle!("…")` |
| `weak_handle!("…")`, `Handle::Weak` | 0.17 | `uuid_handle!("…")`, `Handle::Uuid` |
| `assets.insert(id, asset)` ignoring the result | 0.17 | It returns `Result` now: handle or `?` it |
| `load_with_settings`, `load_untyped`, `load_acquire`, `load_*_override*` | 0.19 | `asset_server.load_builder().with_settings(..).load(path)` (also `.load_untyped(path)`, `.override_unapproved()`) |
| `load_context.loader().immediate().load(p)` | 0.19 | `load_context.load_builder().load_value(p)` |

## Audio and windowing

| Don't write | Since | Write instead |
|---|---|---|
| `AudioBundle { source, settings }` | 0.15 | `(AudioPlayer::new(handle), PlaybackSettings::ONCE)` |
| `sink.toggle()` | 0.16 | `sink.toggle_playback()` (and `toggle_mute()`) |
| `WindowMode::SizedFullscreen(..)`, `WindowMode::Fullscreen(monitor)` | 0.16 | `WindowMode::Fullscreen(MonitorSelection::Primary, VideoModeSelection::Current)` |

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

```rust,check
use bevy::{
    ecs::lifecycle::HookContext,
    ecs::world::DeferredWorld,
    input::keyboard::{Key, KeyboardInput},
    math::FloatOrd,
    time::Stopwatch,
    window::{MonitorSelection, VideoModeSelection, WindowMode},
};

#[derive(Component)]
#[require(Health(100), Transform)]
#[component(on_add = on_add_unit)]
struct Unit;

#[derive(Component)]
struct Health(u32);

fn on_add_unit(_world: DeferredWorld, HookContext { entity, .. }: HookContext) {
    let _ = entity;
}

#[derive(Message)]
struct Ping;

fn typed_text(mut keys: MessageReader<KeyboardInput>) {
    for key in keys.read() {
        if let (true, Key::Character(c)) = (key.state.is_pressed(), &key.logical_key) {
            info!("typed {c}");
        }
    }
}

fn pads(gamepads: Query<&Gamepad>) {
    for pad in &gamepads {
        if pad.just_pressed(GamepadButton::South) {
            info!("left stick x: {:?}", pad.get(GamepadAxis::LeftStickX));
        }
    }
}

fn pair(units: Query<&Transform, With<Unit>>, pair: Local<Option<[Entity; 2]>>) -> Result {
    if let Some(entities) = *pair {
        let [a, b] = units.get_many(entities)?;
        let _ = a.translation.distance(b.translation);
    }
    Ok(())
}

fn spawn(mut commands: Commands) {
    commands.spawn(Unit).with_children(|children| {
        let parent = children.target_entity();
        children.spawn(Name::new(format!("child of {parent}")));
    });
    let ray = Ray3d::new(Vec3::ZERO, Dir3::NEG_Z);
    let _ = (ray, Rot2::degrees(90.0).angle_to(Rot2::IDENTITY), FloatOrd(1.0));
}

fn exit_on_escape(keys: Res<ButtonInput<KeyCode>>, mut exit: MessageWriter<AppExit>, watch: Local<Stopwatch>) {
    if keys.just_pressed(KeyCode::Escape) && !watch.is_paused() {
        exit.write(AppExit::Success);
    }
}

fn fullscreen(mut window: Single<&mut Window>) {
    window.mode = WindowMode::Fullscreen(MonitorSelection::Primary, VideoModeSelection::Current);
}

fn plugin(app: &mut App) {
    app.add_message::<Ping>()
        .add_systems(Startup, spawn.run_if(run_once))
        .add_systems(Update, (typed_text, pads, pair, exit_on_escape).run_if(on_message::<Ping>.or_else(run_once)))
        .add_systems(Update, fullscreen.run_if(resource_exists::<Time>.and_then(run_once)));
}
```
