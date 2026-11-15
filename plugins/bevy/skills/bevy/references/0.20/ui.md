# UI and text (Bevy 0.20)

Upstream examples: `examples/ui/` (especially `ui/widgets/button.rs`,
`ui/widgets/standard_widgets.rs`, `ui/text/`), plus `examples/scene/bsn.rs` for UI written in BSN.

## Layout

- Everything layout-related is a field on `Node` (flexbox and grid). There is no `Style`
  component. `border_radius` is a `Node` field since 0.18.
- Length helpers: `px(10)`, `percent(50)`, `vw(..)`, `vh(..)`, and since 0.20 `em(..)` / `rem(..)`.
  They return `Val`. `Val::Px(10.0)` still works.
- `Val::Em` resolves against the node's `EmSize`. `Val::Rem` resolves against the `RemSize`
  resource (default 20 logical px).
- `BorderColor::all(c)` sets every side. Per-side colours are fields.
- Draw UI to a specific camera with `UiTargetCamera(camera_entity)`. Images use `ImageNode`.
- UI rendering is retained since 0.20, so only changed nodes are re-extracted. This only matters
  for custom UI render code.

## Text

- `Text::new("..")` on a UI node, or `Text2d::new("..")` in the world. Style with `TextFont`,
  `TextColor`, `TextLayout`, `LineHeight` and `TextShadow`.
- Extra styled runs are child entities with `TextSpan`.
- `TextFont.font` is a `FontSource`. Use `handle.into()` for a loaded font, or
  `FontSource::sans_serif()` / `FontSource::monospace()` / `FontSource::family("Name")`.
- `TextFont.font_size` is a `FontSize`: `Px(..)`, `Rem(..)`, `Vw(..)` or `Vh(..)`. The default is
  `Rem(1.)` in 0.20, which follows `RemSize`.
- Text is laid out with `parley` (0.19+), not `cosmic-text`. There are no `cosmic_text`
  re-exports.
- Text input: insert `EditableText` **and** `TextInput` (they were split in 0.20). `Escape`
  releases focus.

## Buttons and interaction

- The `Interaction` component and the prelude `Button` are **deprecated** in 0.20. Use
  `bevy::ui_widgets::Button` with `Hovered` (from `bevy::picking::hover`) and `Pressed` (from
  `bevy::ui`). React to clicks by observing `Activate`, an `EntityEvent` that also fires from the
  keyboard when the button has focus.
- Importing `ui_widgets::Button` explicitly shadows the deprecated prelude `Button`. Glob-importing
  only the prelude gets you the deprecated one.
- `bevy::ui_widgets::observe(..)` lets you attach an observer inside a bundle tuple (and so inside
  `children![..]`). In BSN, use `on(..)`.
- Low-level pointer events are flat types in 0.20: `On<PointerClick>`, `On<PointerPress>`,
  `On<PointerOver>`, `On<PointerOut>`, `On<PointerDrag>`. Read position from `event.pointer.position`.
- `bevy_feathers` contains opinionated editor-style widgets built on `ui_widgets` and BSN. Prefer
  it for tool/editor UIs, and prefer `ui_widgets` + your own styling for game UI.

```rust,check
use bevy::{
    picking::hover::Hovered,
    ui::Pressed,
    ui_widgets::{observe, Activate, Button},
};

const IDLE: Color = Color::srgb(0.15, 0.15, 0.15);
const HOVER: Color = Color::srgb(0.25, 0.25, 0.25);
const DOWN: Color = Color::srgb(0.35, 0.75, 0.35);

fn menu(mut commands: Commands) {
    commands.spawn(Camera2d);
    commands.spawn((
        Node {
            width: percent(100),
            height: percent(100),
            align_items: AlignItems::Center,
            justify_content: JustifyContent::Center,
            ..default()
        },
        children![(
            Button,
            Hovered::default(),
            Node {
                padding: UiRect::all(px(12)),
                border: UiRect::all(px(2)),
                border_radius: BorderRadius::all(px(8)),
                ..default()
            },
            BorderColor::all(Color::BLACK),
            BackgroundColor(IDLE),
            observe(|activate: On<Activate>| info!("start game from {}", activate.entity)),
            children![(
                Text::new("Start"),
                TextFont {
                    font: FontSource::sans_serif(),
                    font_size: FontSize::Px(28.0),
                    ..default()
                },
                TextColor(Color::WHITE),
            )],
        )],
    ));
}

fn style_buttons(mut buttons: Query<(&Hovered, Has<Pressed>, &mut BackgroundColor), With<Button>>) {
    for (hovered, pressed, mut bg) in &mut buttons {
        bg.0 = match (pressed, hovered.get()) {
            (true, _) => DOWN,
            (false, true) => HOVER,
            (false, false) => IDLE,
        };
    }
}
```

```rust,check
fn hud(mut commands: Commands) {
    commands.spawn((
        Text::new("HP: "),
        TextFont {
            font_size: FontSize::Rem(1.2),
            ..default()
        },
        Node {
            position_type: PositionType::Absolute,
            top: rem(1.0),
            left: rem(1.0),
            ..default()
        },
        children![(TextSpan::new("42"), TextColor(Color::srgb(0.9, 0.2, 0.2)))],
    ));
}
```
