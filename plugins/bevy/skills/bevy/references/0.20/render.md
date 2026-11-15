# Rendering, 2D and 3D (Bevy 0.20)

Upstream examples: `examples/3d/`, `examples/2d/`, `examples/shader/`, `examples/camera/`,
`examples/gizmos/`. The example *assets* (shaders, textures) are not in the crates.io package. Read
them from the bevy repo at tag `v0.20.1`.

## Cameras

- Spawn `Camera3d::default()` or `Camera2d` with a `Transform`. Required components fill in
  `Camera`, `Projection`, `Tonemapping` and the rest.
- HDR is the `Hdr` marker component (0.17+), not a `Camera` field. Neither `Hdr`
  (`bevy::camera::Hdr`) nor `Tonemapping` (`bevy::render::view::Tonemapping` since 0.20) is in the
  prelude, so import them.
- `Tonemapping::None` is a full passthrough in 0.20 (no grading, dither or clamp). Use
  `Tonemapping::Linear` for "no tone curve". `Camera2d` defaults to `Linear`.
- `ScreenSpaceTransmission` is opt-in on `Camera3d` in 0.20. Without it, transmissive materials
  look different than in 0.19.
- Render to a texture or another window with the `RenderTarget` component (0.18+).
- Per-camera ambient light is the `AmbientLight` component. The world default is the
  `GlobalAmbientLight` resource.

## Meshes, materials and lights

- `Mesh3d(handle)` + `MeshMaterial3d(handle)`. In 2D, `Mesh2d` + `MeshMaterial2d`. Primitive
  shapes (`Cuboid`, `Sphere`, `Circle`, `Capsule3d`, …) convert into meshes with
  `meshes.add(shape)`. They moved to `bevy_shape` in 0.20 but are still in the prelude.
- `materials.add(Color)` works for `StandardMaterial` / `ColorMaterial`.
- Light shadows: `shadow_maps_enabled` (renamed from `shadows_enabled` in 0.19).
  `contact_shadows_enabled` and `soft_shadows_enabled` are separate fields.
- `MeshTag::new(x)` replaces the `MeshTag(x)` tuple constructor (0.20).

## Sprites and 2D

- `Sprite::from_image(handle)`, `Sprite::from_color(color, size)`, or `Sprite { image, .. }`.
  `Anchor` is a separate required component.
- Since 0.20, sprites render through `Mesh2d` + `SpriteMaterial` and have an `alpha_mode` field
  (default `Blend`). Sprites at the **same Z can draw in a different order than before**, so always
  give overlapping sprites distinct Z values.
- `Text2d` lives in `bevy::sprite`.

## Custom materials and shaders

- `#[derive(Asset, TypePath, AsBindGroup, Clone)]` + `impl Material` (3D) or `impl Material2d`
  (2D), registered with `MaterialPlugin::<M>::default()` / `Material2dPlugin::<M>::default()`.
- **Shaders are WESL in 0.20.** Name files `.wesl`. Imports are `import bevy_pbr::render::forward_io::VertexOutput;`
  (with a semicolon, before any declaration). Conditionals are `@if(FLAG)` on declarations or
  statements. Integer defs are read as `constants::NAME`. `#import`, `#ifdef`,
  `#define_import_path` and GLSL are gone. Plain WGSL with no preprocessor directives still loads.
- Bevy shader module paths now match file paths: `bevy_pbr::mesh_view_bindings` →
  `bevy_pbr::render::mesh_view_bindings`, `bevy_pbr::prepass_utils` → `bevy_pbr::prepass::utils`.
- OIT in custom shaders is gated on `MATERIAL_OIT_ENABLED` (per material) in 0.20, and
  `oit_draw` expects premultiplied colour.
- The render graph is plain systems since 0.19 (`Core3d`/`Core2d` schedules, `RenderSystems`
  sets). For custom passes, start from `examples/shader_advanced/` at this version, not older blog
  posts.

```rust,check
use bevy::{
    camera::Hdr,
    render::{render_resource::AsBindGroup, view::Tonemapping},
    shader::ShaderRef,
};

#[derive(Asset, TypePath, AsBindGroup, Debug, Clone)]
struct Glow {
    #[uniform(0)]
    color: LinearRgba,
    #[texture(1)]
    #[sampler(2)]
    mask: Option<Handle<Image>>,
}

impl Material for Glow {
    fn fragment_shader() -> ShaderRef {
        "shaders/glow.wesl".into()
    }

    fn alpha_mode(&self) -> AlphaMode {
        AlphaMode::Blend
    }
}

fn scene(
    mut commands: Commands,
    mut meshes: ResMut<Assets<Mesh>>,
    mut standard: ResMut<Assets<StandardMaterial>>,
    mut glow: ResMut<Assets<Glow>>,
) {
    commands.spawn((
        Camera3d::default(),
        Hdr,
        Tonemapping::TonyMcMapface,
        Transform::from_xyz(-3.0, 3.0, 6.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
    commands.spawn((
        Mesh3d(meshes.add(Plane3d::default().mesh().size(10.0, 10.0))),
        MeshMaterial3d(standard.add(Color::srgb(0.3, 0.5, 0.3))),
    ));
    commands.spawn((
        Mesh3d(meshes.add(Sphere::new(0.5))),
        MeshMaterial3d(glow.add(Glow {
            color: LinearRgba::rgb(4.0, 1.0, 0.2),
            mask: None,
        })),
        Transform::from_xyz(0.0, 0.5, 0.0),
    ));
    commands.spawn((
        DirectionalLight {
            shadow_maps_enabled: true,
            ..default()
        },
        Transform::from_xyz(2.0, 6.0, 3.0).looking_at(Vec3::ZERO, Vec3::Y),
    ));
}

fn plugin(app: &mut App) {
    app.add_plugins(MaterialPlugin::<Glow>::default())
        .add_systems(Startup, scene);
}
```

```rust,check
fn sprites(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.spawn(Camera2d);
    // Same-Z ordering is not guaranteed in 0.20: give overlapping sprites distinct Z.
    commands.spawn((
        Sprite::from_image(asset_server.load("tiles/floor.png")),
        Transform::from_xyz(0.0, 0.0, 0.0),
    ));
    commands.spawn((
        Sprite::from_color(Color::srgba(1.0, 0.0, 0.0, 0.5), Vec2::splat(32.0)),
        Transform::from_xyz(0.0, 0.0, 1.0),
    ));
}

fn debug_draw(mut gizmos: Gizmos) {
    gizmos.cube(Transform::from_xyz(0.0, 1.0, 0.0), Color::WHITE);
    gizmos.circle_2d(Vec2::ZERO, 16.0, Color::srgb(0.2, 0.8, 0.2));
}
```
