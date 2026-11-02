# Sprite Forge: notes for Claude

A Godot 4 desktop app (GDScript, standard build, not .NET) that turns one parts image into animated sprite sheets. Read `docs/DESIGN.md` for the design; `docs/parts-prompt.md` has the parts-sheet prompt and the biped blueprint.

## Conventions
- **UI is built in code.** `.tscn` files stay a bare root node plus a script (`src/main.tscn`). Don't hand-write scenes with many nodes.
- **No `class_name`.** Scripts reference each other with `const X := preload("res://…")` and `extends "res://…"`, so nothing depends on Godot's global class cache.
- **Layers:** `src/core/` (model, imaging) has no UI code; `src/ui/` calls into it. The rig is a plain Node2D hierarchy (decided; Skeleton2D maybe later as a per-part option).
- **UI actions:** every inspector and timeline control emits `request(action, value)`. `src/ui/main_window.gd` `_on_request` handles them; unhandled actions show "Not built yet: <action>" in the status bar. A new feature = a new `match` branch there plus the code in `src/core/`.
- Tabs for indentation, typed GDScript, Godot 4.3+ API (e.g. `Image.create_empty`).
- `docs/` and `samples/` have `.gdignore`; samples are loaded from disk at runtime, not imported.
- No AI-attribution lines in commit messages.

## Status (as of 2026-11-02)
- Done: folder structure, `project.godot` (4.3, Compatibility renderer, nearest filtering), the UI shell (menu, 7 step panels, canvas with zoom/pan, timeline, status bar), image loading by magic bytes (`src/core/imaging/image_io.gd`).
- **Never run yet.** All of it was written on a machine without Godot.

## Next session (at home, Linux, Godot installed)
1. **Find the Godot binary** (ask the user for the path if it isn't on `PATH`), then check the version: `godot --version`. Needs 4.3+.
2. **Import and parse-check without a window:** `godot --headless --path . --import` then `godot --headless --path . --quit`. Read every `SCRIPT ERROR` / `Parse Error` and fix it. Repeat until clean.
3. **Run it:** `godot --path .` (needs the desktop session). Ask the user to check:
   - File > Open image opens `samples/lizardman-parts.jpg` (the dialog should start in `samples/`); drag-and-drop works too.
   - Wheel zoom at the cursor, middle-drag / Space+drag pan, F fits; pixels stay crisp.
   - Steps 2–7 unlock after loading; each shows its panel; the timeline appears only in Animate.
   - Buttons report "Not built yet: …" in the status bar.
   - Status bar shows cursor pixel, image size, zoom.
4. Fix whatever they report, commit.
5. **Then start the first milestone** (see DESIGN.md "First milestone"), in this order:
   1. Chroma key in `src/core/imaging/` (loop over `get_data()` bytes, not `get_pixel`), wired to the Background step; preview on the canvas.
   2. Piece finding (connected regions + merge of small bits), listed in the Pieces step, outlined on the canvas.
   3. Biped preset as JSON in `presets/` (parts, parents, attach points from the blueprint), parts assignment.
   4. Pivots, rig (Node2D), idle + walk from the blueprint, bake a 68×42 sheet.

## User notes
- The user will bring their **own pencil sketch** to test with; the lizardman files in `samples/` are only test inputs. Sketch support (paper levels, silhouette fill, smooth bake) comes after the first milestone. Advise drawing the parts separately on the paper; that avoids cutting and hole patching.
- Expected sketch output size: about 150–400 px tall; smaller turns to mush.
