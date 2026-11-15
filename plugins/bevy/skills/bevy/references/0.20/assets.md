# Assets (Bevy 0.20)

Upstream examples: `examples/asset/` (`asset_loading.rs`, `custom_asset.rs`, `asset_settings.rs`,
`embedded_asset.rs`, `hot_asset_reloading.rs`).

## Loading

- `asset_server.load("path/to/file.png")` returns a strong `Handle<T>` right away. Loading happens
  in the background, and the asset is freed when the last strong handle drops.
- Advanced loads go through the builder (0.19+). The old `load_with_settings`, `load_untyped`,
  `load_acquire` and similar are deprecated:
  `asset_server.load_builder().with_settings(|s: &mut ImageLoaderSettings| ..).load(path)`,
  `.load_untyped(path)`, `.override_unapproved()`.
- Check progress with `asset_server.is_loaded_with_dependencies(&handle)` or
  `asset_server.load_state(&handle)`. React with `MessageReader<AssetEvent<T>>` (`Added`,
  `Modified`, `LoadedWithDependencies`, …).
- Constant handles for built-in/embedded assets use `uuid_handle!("…")`. `weak_handle!` is
  deprecated and `Handle::Weak` is gone.
- `Assets<T>::add(asset)` returns a handle. `Assets<T>::insert(id, asset)` returns `Result` (0.17+).
- In BSN, a `Handle<T>` field accepts a string path (`Sprite { image: "a.png" }`) or
  `asset_value(value)` for an inline asset. See `scenes.md`.
- The glTF scene root is `WorldAssetRoot(asset_server.load("m.gltf#Scene0"))` (0.19+), or build
  the label with `GltfAssetLabel::Scene(0).from_asset("m.gltf")`.

## Custom assets and loaders

- `#[derive(Asset, TypePath)]` on the asset. The loader must also derive `TypePath` (0.18+).
- `AssetLoader` has the associated types `Asset`, `Settings` and `Error`, an `async fn load(&self,
  reader: &mut dyn Reader, settings: &Self::Settings, ctx: &mut LoadContext<'_>)`, and
  `fn extensions(&self)`.
- Inside a loader, use `ctx.load_builder()` for dependent loads (`.load(p)`, `.load_value(p)` for
  an immediate nested load). `LoadContext::loader()` is gone.
- Register with `app.init_asset::<A>().init_asset_loader::<L>()` (or `register_asset_loader(l)`).

```rust,check
use bevy::asset::{io::Reader, AssetLoader, LoadContext};

#[derive(Asset, TypePath, Debug)]
struct Dialogue {
    lines: Vec<String>,
}

#[derive(Default, TypePath)]
struct DialogueLoader;

impl AssetLoader for DialogueLoader {
    type Asset = Dialogue;
    type Settings = ();
    type Error = std::io::Error;

    async fn load(
        &self,
        reader: &mut dyn Reader,
        _settings: &(),
        _ctx: &mut LoadContext<'_>,
    ) -> Result<Self::Asset, Self::Error> {
        let mut bytes = Vec::new();
        reader.read_to_end(&mut bytes).await?;
        let text = String::from_utf8_lossy(&bytes);
        Ok(Dialogue {
            lines: text.lines().map(str::to_owned).collect(),
        })
    }

    fn extensions(&self) -> &[&str] {
        &["dialogue"]
    }
}

#[derive(Resource)]
struct Intro(Handle<Dialogue>);

fn load_intro(mut commands: Commands, asset_server: Res<AssetServer>) {
    commands.insert_resource(Intro(asset_server.load("intro.dialogue")));
}

fn play_when_ready(
    intro: Res<Intro>,
    asset_server: Res<AssetServer>,
    dialogues: Res<Assets<Dialogue>>,
    mut done: Local<bool>,
) {
    if *done || !asset_server.is_loaded_with_dependencies(&intro.0) {
        return;
    }
    if let Some(dialogue) = dialogues.get(&intro.0) {
        info!("{} lines", dialogue.lines.len());
        *done = true;
    }
}

fn on_dialogue_changed(mut events: MessageReader<AssetEvent<Dialogue>>) {
    for event in events.read() {
        if let AssetEvent::Modified { id } = event {
            info!("dialogue {id} hot-reloaded");
        }
    }
}

fn plugin(app: &mut App) {
    app.init_asset::<Dialogue>()
        .init_asset_loader::<DialogueLoader>()
        .add_systems(Startup, load_intro)
        .add_systems(Update, (play_when_ready, on_dialogue_changed));
}
```

```rust,check
use bevy::image::{ImageLoaderSettings, ImageSampler};

fn pixel_art(mut commands: Commands, asset_server: Res<AssetServer>) {
    let image: Handle<Image> = asset_server
        .load_builder()
        .with_settings(|s: &mut ImageLoaderSettings| s.sampler = ImageSampler::nearest())
        .load("sprites/hero.png");
    commands.spawn(Sprite::from_image(image));
    commands.spawn(WorldAssetRoot(
        asset_server.load(GltfAssetLabel::Scene(0).from_asset("models/tavern.glb")),
    ));
}
```
