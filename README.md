# Starline Defender

Starline Defender is an original, portrait-first arcade shooter built with Godot 4.7.1. It runs in desktop and mobile browsers through Godot's Web export.

[Play Starline Defender in your browser](https://edward-jeong.github.io/Game-galaga/)

## Game loop

- Clear two enemy formations and destroy the flagship in wave three.
- You start with three lives. A hit removes one weapon level and grants brief invulnerability.
- Weapon pickups upgrade auto fire from one shot to two and then three.
- The game ends when all lives are lost or the flagship is destroyed.
- The best score and mute preference are stored locally in the browser.

## Controls

- Use the arrow keys or WASD to move during PC testing, including diagonal movement.
- Drag with the mouse or touch to move.
- Auto-fire is always enabled.
- Press P/Escape or tap the bottom-right pause button to pause.
- Tap the bottom-left music button to mute or enable sound.
- Press Enter or Space to start, resume, or restart with a keyboard.
- On mobile, the drag target stays above your finger so the ship remains visible.

## Open in Godot

1. Install the standard GDScript build of [Godot 4.7.1](https://godotengine.org/download/archive/).
2. Install the matching export templates from **Editor > Manage Export Templates**.
3. Import `project.godot`, then press **F6** or **F5**.

You can also start the project from a terminal:

```powershell
godot --path .
```

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

## Test on iPhone without a Mac

After the repository setup below, every push to `main` is automatically tested, exported to Web, and deployed with GitHub Pages. Open the Pages URL in iPhone Safari, keep the phone in portrait orientation, tap **Start Mission** once to unlock browser audio, and test touch dragging.

The run has two formation waves followed by a flagship battle. Losing all three lives ends the mission. Destroying the flagship completes the run, and the victory or game-over screen can immediately start a new game.

Expected Pages URL:

<https://edward-jeong.github.io/Game-galaga/>

GitHub Pages must be configured once for the workflow:

1. Open **Settings > Pages** and set **Build and deployment > Source** to **GitHub Actions**.
2. Open **Settings > Environments > github-pages** and allow deployments from `main`.
3. Open **Actions > Build and deploy Godot Web** and run the workflow.

The workflow installs Godot and its matching Web export templates, runs both headless tests, exports to `build/web`, and deploys only the generated Web files.

## Supported scope

- Primary target: current iPhone Safari, Android Chrome/Samsung Internet, and current desktop browsers.
- Portrait orientation is the designed layout. Landscape uses a centered 9:16 play area.
- No original commercial game artwork, names, music, or level layouts are included.
