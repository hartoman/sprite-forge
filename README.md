# Sprite Forge

A desktop tool (a Godot 4 app) that turns one parts image of a creature into animated sprite sheets (PNG + JSON) for any game.

See [docs/DESIGN.md](docs/DESIGN.md) for the design.

## Layout

| Folder | Contents |
|---|---|
| `src/core/model/` | Project, preset, profile, rig, pose and motion data; JSON load/save |
| `src/core/imaging/` | Background key, piece finding, pivot guessing, downscaling |
| `src/rig/` | Builds the Node2D part hierarchy and applies poses |
| `src/bake/` | Renders frames off-screen and writes sheets + metadata |
| `src/ui/` | The editor screens, built in code |
| `presets/` | Body-type presets (parts, bones, motions, prompt) as JSON |
| `profiles/` | Per-game output profiles as JSON |
| `samples/` | Test inputs (not imported by Godot) |
| `docs/` | Design notes (not imported by Godot) |
| `tests/` | Test scripts |

## Running

Open the folder in Godot 4.x (standard build), or run `godot --path .`
