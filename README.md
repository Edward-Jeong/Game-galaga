# Starline Defender

Starline Defender is an original, portrait-first arcade shooter built with Godot 4.7.1. It runs in desktop and mobile browsers through Godot's Web export.

## Game loop

- Clear two enemy formations and destroy the flagship in wave three.
- You start with three lives. A hit removes one weapon level and grants brief invulnerability.
- Weapon pickups upgrade auto fire from one shot to two and then three.
- The game ends when all lives are lost or the flagship is destroyed.
- The best score and mute preference are stored locally in the browser.

## Controls

| Device | Move | Fire | Pause |
| --- | --- | --- | --- |
| Mobile | Drag anywhere in the play field | Automatic | Bottom-right button |
| Desktop | WASD, arrow keys, or mouse drag | Automatic | P or Escape |

The mobile drag target is offset above the finger so the ship remains visible.

## Open in Godot

1. Install the standard GDScript build of [Godot 4.7.1](https://godotengine.org/download/archive/).
2. Install the matching export templates from **Editor → Manage Export Templates**.
3. Import `project.godot`, then press **F6** or **F5**.

The project uses the Compatibility renderer because Godot Web exports require WebGL 2.0.

## Verify rules

```powershell
godot --headless --path . --script tests/test_game_rules.gd
godot --headless --path . --script tests/test_game_flow.gd
```

## Build and run the Web version

```powershell
New-Item -ItemType Directory -Force build/web
godot --headless --path . --export-release Web build/web/index.html
python -m http.server 5317 --directory build/web
```

Open `http://127.0.0.1:5317/`. Do not open the generated HTML file directly; WebAssembly needs an HTTP server.

## GitHub Pages

Pushing `main` runs `.github/workflows/pages.yml`. The workflow installs Godot and the matching Web export templates, runs the rule checks, exports to `build/web`, and deploys only that folder to GitHub Pages.

## Supported scope

- Primary target: current iPhone Safari, Android Chrome/Samsung Internet, and current desktop browsers.
- Portrait orientation is the designed layout. Landscape uses a centered 9:16 play area.
- No original commercial game artwork, names, music, or level layouts are included.
