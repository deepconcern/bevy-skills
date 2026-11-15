# ECS idioms (Bevy 0.20)

Read `stale-apis.md` first. This file covers current patterns and the gotchas that trip people up.
Upstream examples at this version: `examples/ecs/` in the `bevy-0.20.1` crate source.

## Components and required components

- Spawn the "main" component and let `#[require(..)]` add the rest. There are no `*Bundle` structs
  for built-in types anymore.
- Tuples are still bundles, and `#[derive(Bundle)]` still exists for your own groupings. Prefer
  required components when one component always implies others.
- Use `#[component(immutable)]` for components that should only change through re-insertion. Hooks
  and observers then see every change.
- Lifecycle hooks are `on_add`, `on_insert`, `on_discard` (formerly `on_replace`) and `on_remove`.
  They take `(DeferredWorld, HookContext)`.

```rust,check
use bevy::ecs::{lifecycle::HookContext, world::DeferredWorld};

#[derive(Component, Default)]
#[require(Transform, Visibility, Health)]
struct Enemy;

#[derive(Component)]
struct Health(u32);

impl Default for Health {
    fn default() -> Self {
        Health(100)
    }
}

#[derive(Component)]
#[component(on_add = announce)]
struct Boss;

fn announce(world: DeferredWorld, ctx: HookContext) {
    let _ = (world, ctx.entity);
}

fn spawn(mut commands: Commands) {
    // Transform, Visibility and Health(100) come along automatically.
    commands.spawn((Enemy, Boss));
}
```

## Queries and system params

- `query.single()` and `single_mut()` return `Result`. Systems can return `Result` (alias for
  `Result<(), BevyError>`) and use `?`. Errors go to the `FallbackErrorHandler`, which panics by
  default.
- `Single<D, F>` skips the system (no panic) unless exactly one entity matches.
  `Option<Single<..>>` accepts zero or one. `Populated<D, F>` skips the system when nothing matches.
- `iter_many` / `iter_many_mut` yield `Result` in 0.20. Add `.matched()` to keep the old
  "skip missing" behaviour.
- Use `Has<T>` for a cheap bool, `Ref<T>` for change ticks, and `Changed<T>` / `Added<T>` as filters.
- Resources are stored as components on resource entities since 0.19. Broad queries such as
  `Query<EntityMut>` or `Query<Entity>` now match resource entities too, so add
  `Without<IsResource>` if one conflicts with a `Res`/`ResMut` param.
- `&mut World` is an ordinary `SystemParam` in 0.20 and may appear anywhere in the parameter list.

```rust,check
#[derive(Component)]
struct Player;

#[derive(Component)]
struct Speed(f32);

fn move_player(
    time: Res<Time>,
    keys: Res<ButtonInput<KeyCode>>,
    mut player: Single<(&mut Transform, &Speed), With<Player>>,
) {
    let (transform, speed) = &mut *player;
    if keys.pressed(KeyCode::KeyD) {
        transform.translation.x += speed.0 * time.delta_secs();
    }
}

fn report(players: Query<(Entity, Has<Speed>, Ref<Transform>), With<Player>>) -> Result {
    let (entity, has_speed, transform) = players.single()?;
    if transform.is_changed() {
        info!("{entity} moved (has speed: {has_speed})");
    }
    Ok(())
}

#[derive(Resource)]
struct Squad(Vec<Entity>);

fn squad_speeds(squad: Res<Squad>, speeds: Query<&Speed>) {
    for speed in speeds.iter_many(&squad.0).matched() {
        let _ = speed.0;
    }
}
```

## Messages vs events vs observers

- **Messages** are buffered and pulled: `#[derive(Message)]`, `app.add_message::<M>()`,
  `MessageWriter<M>::write`, `MessageReader<M>::read`, and `MessageMutator<M>` to edit in flight.
  They are read once per reader, and are good for high-volume, frame-ordered data.
- **Events** are pushed to observers immediately: `#[derive(Event)]` for global events and
  `#[derive(EntityEvent)]` (with an `entity: Entity` field, or `#[event_target]` on a field) for
  targeted ones. Trigger with `commands.trigger(e)` or `world.trigger(e)`.
- **Observers**: `app.add_observer(f)` is global. `entity_commands.observe(f)` (or `on(f)` inside
  `bsn!`) watches one entity. The first param is `On<E>`. Lifecycle events take the component as a
  generic: `On<Add<T>>`, `On<Insert<T>>`, `On<Discard<T>>`, `On<Remove<T>>`, `On<Despawn<T>>`.
- Observers accept run conditions: `app.add_observer(f.run_if(cond))`.
- Propagation: `#[entity_event(propagate)]` bubbles up `ChildOf`. Call `event.propagate(false)` to stop it.

```rust,check
#[derive(EntityEvent)]
#[entity_event(propagate)]
struct Interact {
    entity: Entity,
}

#[derive(Event)]
struct RoundOver;

#[derive(Component)]
struct Door;

fn setup(mut commands: Commands) {
    commands
        .spawn((Door, children![Name::new("handle")]))
        .observe(|mut interact: On<Interact>| {
            info!("door got interaction from {}", interact.entity);
            interact.propagate(false);
        });
}

fn on_door_removed(remove: On<Remove<Door>>) {
    info!("{} lost its Door", remove.entity);
}

fn on_round_over(_: On<RoundOver>, mut commands: Commands) {
    commands.trigger(RoundOver);
}

fn plugin(app: &mut App) {
    app.add_systems(Startup, setup)
        .add_observer(on_door_removed)
        .add_observer(on_round_over);
}
```

## Hierarchy and relationships

- `ChildOf(parent)` is the source of truth. `Children` is maintained for you.
- When spawning, use `children![..]` (or `related!`). After spawning, use `with_children(|p| ..)`,
  `add_child`, or `insert(ChildOf(p))`.
- `despawn()` is recursive. `detach_*` methods unlink without despawning.
- Custom relationships: `#[relationship(relationship_target = Targets)]` on the source component
  and `#[relationship_target(relationship = TargetedBy)]` on the target collection.

```rust,check
#[derive(Component)]
#[relationship(relationship_target = TargetedBy)]
struct Targeting(Entity);

#[derive(Component)]
#[relationship_target(relationship = Targeting)]
struct TargetedBy(Vec<Entity>);

fn spawn(mut commands: Commands) {
    let goblin = commands.spawn(Name::new("goblin")).id();
    commands.spawn((Name::new("hero"), Targeting(goblin)));
    commands.spawn((Name::new("party"), children![Name::new("hero"), Name::new("cleric")]));
}

fn who_is_targeted(targets: Query<(&Name, &TargetedBy)>) {
    for (name, by) in &targets {
        info!("{name} is targeted by {} entities", by.len());
    }
}
```

## Commands, one-shot systems, entity disabling

- Commands queued through `commands.entity(e)` fail when they're applied if `e` is gone by then.
  The failure goes to the error handler, which panics by default. Use `commands.get_entity(e)`
  (returns `Result`) when the entity may not exist, or `try_insert` / `try_despawn` to ignore a
  missing entity.
- One-shot systems: `commands.run_system_cached(f)`, or register once with
  `world.register_system(f)` and run the `SystemId`.
- `Disabled` hides an entity from queries by default (default query filters). Query
  `Has<Disabled>` / `With<Disabled>` explicitly to see disabled entities.

```rust,check
use bevy::ecs::entity_disabling::Disabled;

fn pause_enemy(mut commands: Commands, target: Local<Option<Entity>>) {
    if let Some(e) = *target {
        if let Ok(mut entity) = commands.get_entity(e) {
            entity.insert(Disabled);
        }
    }
    commands.run_system_cached(log_once);
}

fn log_once() {
    info!("one-shot system ran");
}
```
