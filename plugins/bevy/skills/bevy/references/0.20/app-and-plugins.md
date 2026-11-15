# App, plugins and scheduling (Bevy 0.20)

Upstream examples: `examples/app/`, `examples/ecs/ecs_guide.rs`, `examples/ecs/system_sets*`,
`examples/state/`.

## App setup and plugins

- A plain `fn(&mut App)` is a plugin. Prefer it over a unit struct plus `impl Plugin`, unless the
  plugin carries configuration.
- `add_systems(Schedule, systems)` takes tuples. Order systems with `.chain()`, `.before(x)` and
  `.after(x)`, and gate them with `.run_if(cond)`.
- Group systems with a `#[derive(SystemSet)]` enum and order the sets once with `configure_sets`.
  Built-in sets end in `Systems` (`TransformSystems::Propagate`, `UiSystems::Layout`, …).
- In 0.20 several built-in schedules order their top-level sets *weakly* (`chain_weak`). Systems
  only stay ordered where their data access conflicts. If you depend on another system's side
  effects through a channel, atomic or interior mutability, add an explicit `.after(..)`.
- `FixedUpdate` runs at `Time<Fixed>` rate (64 Hz by default). Put simulation there and read
  `Res<Time>`, which is the fixed clock inside `FixedUpdate`.
- **Cargo features:** since 0.19 `3d`, `2d` and `ui` no longer imply each other, and none of them
  implies `audio`. Default features are `2d`, `3d`, `ui` and `audio`. With
  `default-features = false`, list each collection you need.

```rust,check
#[derive(SystemSet, Debug, Clone, PartialEq, Eq, Hash)]
enum GameplaySystems {
    Input,
    Simulate,
    Present,
}

#[derive(Resource, Default)]
struct Paused(bool);

fn not_paused(paused: Res<Paused>) -> bool {
    !paused.0
}

fn read_input() {}
fn step_physics() {}
fn apply_damage() {}
fn update_hud() {}

pub fn gameplay_plugin(app: &mut App) {
    app.init_resource::<Paused>()
        .configure_sets(
            Update,
            (
                GameplaySystems::Input,
                GameplaySystems::Simulate,
                GameplaySystems::Present,
            )
                .chain(),
        )
        .add_systems(Update, read_input.in_set(GameplaySystems::Input))
        .add_systems(
            Update,
            update_hud.in_set(GameplaySystems::Present).run_if(not_paused),
        )
        .add_systems(FixedUpdate, (step_physics, apply_damage).chain());
}

fn main_like() {
    App::new()
        .add_plugins((DefaultPlugins, gameplay_plugin))
        .run();
}
```

## States

- `#[derive(States)]` plus `init_state::<S>()`. Add systems with `OnEnter(S::X)`, `OnExit(S::X)`,
  `OnTransition { .. }` and `run_if(in_state(S::X))`.
- Change state with `ResMut<NextState<S>>`. `set(s)` *always* runs exit/enter, even for the same
  state (0.18+). `set_if_different(s)` (0.20 name) skips same-state transitions.
- `#[derive(SubStates)]` with `#[source(Parent = Parent::X)]` exists only while the parent is in
  `X`. `ComputedStates` derive from other states.
- `DespawnOnExit(S::X)` / `DespawnOnEnter(S::X)` despawn tagged entities on transition.
- State logging lives in `bevy::dev_tools::states::log_transitions::<S>` (feature `bevy_dev_tools`).

```rust,check
#[derive(States, Debug, Clone, Copy, Default, PartialEq, Eq, Hash)]
enum AppState {
    #[default]
    Loading,
    InGame,
}

#[derive(SubStates, Debug, Clone, Copy, Default, PartialEq, Eq, Hash)]
#[source(AppState = AppState::InGame)]
enum Turn {
    #[default]
    Player,
    Enemies,
}

fn finish_loading(mut next: ResMut<NextState<AppState>>) {
    next.set(AppState::InGame);
}

fn spawn_level(mut commands: Commands) {
    commands.spawn((Name::new("level"), DespawnOnExit(AppState::InGame)));
}

fn end_turn(mut next: ResMut<NextState<Turn>>) {
    next.set_if_different(Turn::Enemies);
}

pub fn states_plugin(app: &mut App) {
    app.init_state::<AppState>()
        .add_sub_state::<Turn>()
        .add_systems(Update, finish_loading.run_if(in_state(AppState::Loading)))
        .add_systems(OnEnter(AppState::InGame), spawn_level)
        .add_systems(Update, end_turn.run_if(in_state(Turn::Player)));
}
```

## Error handling

- Systems, observers and commands can return `Result`. Unhandled errors go to the
  `FallbackErrorHandler` (renamed from `DefaultErrorHandler` in 0.19), which panics by default.
- Set the handler on the app with `app.set_error_handler(bevy::ecs::error::warn)` (or `error`,
  `ignore`, `panic`), or insert `FallbackErrorHandler(handler)` as a resource.

```rust,check
use bevy::ecs::error::warn;

fn configure(app: &mut App) {
    app.set_error_handler(warn);
}
```
