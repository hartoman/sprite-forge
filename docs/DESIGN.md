# Sprite Forge: design notes

The working design for a standalone tool that turns **one AI-made parts image** into **animated pixel-art sprite sheets** of any chosen size, for use in any game. It starts from discussions held while building Map Wars, and gets updated as decisions are made. Nothing has been built yet.

## Getting started (for the new project)

**Files to copy from Map Wars into the new repo:**

| From Map Wars | To | Why |
|---|---|---|
| `docs/sprite-forge/SPRITE_FORGE.md` | `docs/DESIGN.md` | This document |
| `docs/sprites/TEST_PROMPT_PARTS.md` | `docs/parts-prompt.md` | The parts-sheet prompt that worked, plus the biped blueprint |
| `_incoming/92ac5147-….jfif` | `samples/lizardman-parts.jpg` | A real parts sheet: the first test input |
| `src/assets/sprites/lizardman.png` | `samples/lizardman-frames.png` | A hand-drawn style reference (3 rows: walk, attack, hit + death) |

**Prerequisites:**
- **Godot 4.x, standard build** (not .NET), latest stable. Portable is fine; note the path to `godot.exe`.

**First milestone** (the smallest useful thing):
- Open the sample parts sheet.
- Key out the magenta and find the 7 pieces.
- Assign them to the biped preset.
- Drag the pivots into place.
- Play an idle and a walk from the blueprint.
- Bake a 68×42 sheet.

That proves the whole pipeline end to end on one creature.

## Goal

- Input: **one image** of a creature, drawn as a "parts sheet": the assembled creature plus its moving parts laid out separately, on a flat background colour.
- Output: **sprite sheets** (PNG) plus **metadata** (JSON) in a layout chosen per game: cell size, anchor point, rows, frame counts and timing.
- Reusable across games. Each game gets a **profile**; each body type gets a **preset**.
- **Self-standing:** no AI models inside the tool, and no external AI services or downloads (no Segment Anything, no AI inpainting, no APIs). Everything is classic image processing plus manual tools. Where the input art comes from is the user's business: their own drawing, bought art, or an image AI used separately. For the last case the tool can show a ready-made prompt as a convenience, but never depends on it.

## Why not draw frames with AI

Tested with an image AI (Gemini; it exports JPEG only, about 1024 px wide):

- Full animation sheets fail every time: it ignores grid and frame counts, gear changes between frames, cells overflow, and grid lines and frame numbers get drawn in.
- Asking for several sheets in one chat makes it copy the previous image: the same death row appeared in every sheet.
- A **parts sheet** (one static image: the assembled character plus its pieces, separated) **mostly worked on the first try**:
  - 7 separate pieces;
  - complete torso;
  - rounded joint ends;
  - consistent colours.

  Issues: piece scale was about 15% off on some parts, it drew a 3/4 view instead of a side view, and the tail piece didn't match the assembled one.
- A **flat magenta background (#FF00FF)** works with JPEG. It keys out cleanly; use another colour if the creature itself uses magenta.

Conclusion: let the AI draw **one static parts image**; do all the animation in the tool.

## Pipeline

```
preset prompt ──► AI (outside) ──► parts image (JPEG/PNG, flat background)
      │
      ▼
 [1] key out background ──► [2] find pieces ──► [3] assign pieces to parts
      ──► [4] pivots (auto-guess + manual drag) ──► [5] pose & animate
      ──► [6] bake: render big, shrink to pixel size ──► PNG sheet + JSON
```

1. **Background removal:** chroma-key the flat colour, with a tolerance for JPEG blur and fringe. Already prototyped for Map Wars.
2. **Finding pieces:** connected regions of non-background pixels. Small loose bits, such as a spark or a crest spike, merge into the nearest big piece, or the user merges them.
3. **Assigning pieces:** first a guess from the order and position the prompt asked for, then the user confirms or reassigns by clicking ("this is the head").
4. **Pivots:**
   - Auto-guessed from shape: limbs pivot at their rounded top end, the head at the neck, a tail at its thick end.
   - Positions on the body come from matching each piece against the assembled figure.
   - The user drags a dot to correct.
5. **Pose and animate:** see Q2 below.
6. **Bake:**
   - Each frame is rendered at the image's full resolution, so rotations stay smooth, then shrunk to the target cell size with pixel cleanup (majority sampling, optional palette lock).
   - Frames are packed into the profile's layout, and the JSON records frame counts, timings and the impact frame.

## Presets and profiles

- **Preset** (one per body type, made once):
  - a parts list;
  - a bone hierarchy with default pivots;
  - motion templates (idle, walk, attack variants, hit, death);
  - the AI prompt and layout template for the parts image.

  Planned presets: biped, quadruped, rider (mount + rider), flier, serpent, blob (shader wobble instead of bones).
- **Profile** (one per game): cell size, anchor, rows and their order, frames per row, fps, background and palette rules, file naming.
  Example: Map Wars uses 68×42 cells, feet at (20,38), 6 rows (idle 4, walk 8, attack 6 with impact on frame 4, ranged 6, hit 2, death 4).

## Architecture: **B, the tool is a Godot app** (decided)

The whole tool is a Godot 4 project (GDScript, standard build, not .NET), exported as a desktop program with the engine bundled, so users need nothing installed. Godot handles the UI, image loading, rigging (Skeleton2D/Bone2D or a plain Node2D hierarchy), animation (AnimationPlayer), shaders, rendering frames off-screen (SubViewport) and writing PNG and JSON. Presets can still be opened and fine-tuned in the Godot editor.

The options that were compared:

| | A: web app + Godot | B: the tool is a Godot app |
|---|---|---|
| UI | Browser (local Vite app) | Godot UI, exported as a desktop program |
| Rendering and animation | Godot via command line (`godot --script`) | Godot, natively |
| User needs | Godot + Node installed | Nothing: the engine is bundled (MIT licence allows it) |
| Moving parts | 2, plus glue | 1 |

Why B: Godot gives 2D bones, mesh deformation (bending tentacles), an animation editor for fine-tuning, shaders (blob wobble) and image export. Note: for rigid parts alone a plain web canvas would also do; Godot earns its place for deformation, editor tuning and robustness.

## Questions answered

### Q1. Can the tool give the AI fixed grid coordinates for each part, then remove the background, separate the parts and let me set pivots by hand?

**Yes, with one caveat.**

- **Pros:**
  - The tool can generate the prompt with a **layout template**, e.g. "the assembled figure in the left half; the head in the top-right slot; the front arm in the slot below it…".
  - Background removal, piece separation and manual pivots are all simple and reliable.
- **Caveat:** image AIs follow layout instructions only loosely. In the tests they ignored exact grids and sizes, but did keep pieces separate and roughly in the requested order. So the tool must **not depend on exact coordinates**:
  - it finds pieces wherever they are (connected regions);
  - it uses the requested slots only to **guess** which piece is which;
  - the user fixes wrong guesses with a click.
- **Requirements on the image:** pieces don't touch; a flat background; each piece complete (including areas hidden by other parts); rounded joint ends.

### Q2. Once the parts are set up, can the animation be made without AI, by rotating parts and taking "snapshots" of each stance, and can those become presets?

**Yes. This is classic pose-to-pose animation, and it's the heart of the tool.**

- **Pose editor:** drag a part to rotate it around its pivot (shift-drag to move it); the hierarchy follows, so the forearm and weapon move with the arm. Extras: mirroring, onion skin (the previous pose shown faintly), resetting a part.
- **Snapshots:** "Add frame" stores the current pose as a keyframe in a timeline strip. Two modes:
  - **frame by frame:** each snapshot is exactly one output frame. Full control, matches the profile's frame counts directly.
  - **key poses + in-betweens:** take only the key poses (e.g. walk contact, passing, contact) and let the tool interpolate the frames between them, with easing.
- **Marking:** flag the impact frame on attacks; set per-frame timing.
- **Motion presets:** a pose is stored as **bone angles and offsets, not pixels**, so a saved animation, such as "biped spear thrust", applies to **every character on the same rig preset**. You animate once, then reuse it for every spearman of every game.
  - Presets can be scaled (stronger or weaker motion) and retimed per character.
  - **Procedural motions** (sway, breathe, bob, tentacle wave) can be layered on top, set with sliders, with no keyframing.
- **Result:** a library of reusable motions per rig. A new creature costs one AI parts image, a few minutes of pivots, and picking motions from the library.

### Q3. Can the tool cut the parts out of one ordinary image, from rough (not precise) user selections?

**Yes.** That makes the AI parts sheet optional: any single drawing of a character works (your own art, bought art or AI art). There are two sub-problems:

**1. Cutting a part from a rough selection: doable, about 1–2 weeks.**
- The user scribbles over a part or drags a loose box around it; the tool snaps the selection to the part's real outline.
- Pixel art makes this easier: hard edges, a 1-pixel dark outline around every shape, few colours.
- Methods, no AI needed:
  - flood fill bounded by outline pixels and big colour changes;
  - graph cut / GrabCut (quick-select style: "in" strokes and "out" strokes, best boundary between them);
  - refine brushes (add, remove);
  - a **cut-line tool** for where no outline separates two parts (e.g. a shoulder blending into the torso).

**2. Hidden areas: the real difficulty.** Cutting a limb off leaves a hole in the body behind it. Options, from cheap to hard:

| Fix | Notes |
|---|---|
| **Joint caps** (automatic) | A rounded cap at each pivot (edge colour + outline), and the parent extended under the joint. Covers shoulders, hips and necks. |
| **Smear fill** (automatic) | Inpaint the hole from the neighbouring colours. Good for small holes. |
| **Paint tools** | Pencil and colour picker, for touching up by hand. |

With **small motions** (≤ 30°, Battle Brothers style) only a thin sliver behind each joint ever shows, so joint caps plus smear fill cover most cases.

**Estimate:** selection and snapping 1–2 weeks; caps, smear fill and a minimal paint tool about 1 week. GDScript is fast enough for images around 1024 px; move hot loops to C++ only if needed.

**Two input paths:**
- **Parts-sheet path:** the AI draws the pieces complete. Best quality.
- **Single-image path:** the tool cuts the pieces and patches the holes. Works with any art.

### Q4. What if the art is a pencil sketch, not pixel art?

**Still doable.** Pixel art's advantages (hard edges, unbroken outlines, flat colours) disappear, while rotation and scaling get easier.

**Harder:**
- **Background:** paper is off-white, textured and unevenly lit, and the inside of a line drawing is the same colour as the paper. Keying out "paper" would make the character see-through. The tool must:
  - find the **silhouette** (close small outline gaps, then fill the enclosed area);
  - keep the inside opaque;
  - offer levels and smudge cleanup.
- **Cutting parts:** outlines are broken or doubled, and hatching sits inside shapes, so outline flood fill leaks. Graph cut is weaker on low-contrast grey. More manual refining is needed: rough lasso, graph cut, add and remove brushes, and the cut-line tool.
- **Hole patching:** smear fill looks wrong on pencil texture. Use a **pencil-style brush** and sketchy joint caps instead; sketches forgive imperfect patches.

**Easier:**
- **Rotation:** no pixel grid to protect, so bigger motions, squash and stretch, and mesh bending all look natural.
- **Baking:** plain smooth downscaling with soft edges, and semi-transparency allowed.

**The catch:** sketches turn to mush when shrunk. Below roughly 150 px tall the lines vanish, so the sketch style suits games with large characters (about 150–400 px), not tiny units.

**Bonus:** fake "line boil" (a slight per-frame line wobble) with a jitter shader, so cutout sketches look hand-animated instead of stiff.

**Style mode per project:**

| Step | Pixel art | Painted / clean art | Sketch |
|---|---|---|---|
| Background | Flat colour key | Flat colour key | Paper levels + silhouette fill |
| Part snapping | Outline flood fill, graph cut | Graph cut | Graph cut + manual refining |
| Hole patching | Caps + smear | Smear + paint | Sketch brush + caps |
| Motion range | Small (≤ 30°) | Medium | Large, bending OK |
| Bake | Majority downscale, hard alpha | Smooth downscale | Smooth + line-boil jitter |

**Extra effort for sketch support:** about 1–2 weeks (silhouette fill, sketch brush, smooth bake, jitter).

## Open decisions

- The first presets after biped.
- ~~Mesh deformation in the first version~~ **Decided:** v1 uses a plain Node2D hierarchy (rigid parts). Skeleton2D + Polygon2D bending may come later as a per-part "bendy" option (good for sketches, tails, tentacles); the rig data (bones + angles) stays the same either way.
- File formats: the project file (JSON + images), motion preset format, export JSON schema.
- Repo name and location (working name: `sprite-forge`).

## Reference: biped blueprint (from the Map Wars lizardman test)

Units are game pixels for a figure about 32 px tall, with the feet at (0, 0) and negative y up.

| Part (back to front) | Parent | Pivot | Attach on parent |
|---|---|---|---|
| Tail | Torso | Tail root | about (-4, -12) |
| Back leg | Torso | Hip | about (-1, -12) |
| Back arm | Torso | Shoulder | about (-2, -22) |
| Torso | root | Hips | about (0, -12) |
| Head | Torso | Neck | about (1, -25) |
| Front leg | Torso | Hip | about (1, -12) |
| Front arm + weapon | Torso | Shoulder | about (2, -22) |

**Motions** (degrees, positive is clockwise; times are a fraction of the motion):
- **Idle** (1.6 s loop):
  - torso bob 1 px
  - head ±3°
  - weapon ±3°
  - tail ±4°
- **Walk** (0.6 s per stride):
  - legs ±22° in opposition
  - torso bob 1 px, lean +3°
  - back arm ±12°
  - tail ±8°, half a beat behind
- **Spear thrust** (0.6 s, impact at 0.45):
  - wind-up: torso -6°, x -2; arm -35°
  - thrust: torso +8°, x +4; arm +20°; front leg +15°
  - then recover.
- **Swing:** arm -60° → +50°.
- **Bow:** the back arm draws.
- **Throw:** overhead arm arc.
- **Hit** (0.35 s): torso -10°, x -3; head -8°; flash.
- **Death** (0.9 s): the rig tips -85° around the feet, the legs fold, the head drops, it sinks 2 px and fades.

The parts-sheet prompt that worked is in `docs/parts-prompt.md` (copied from Map Wars' `docs/sprites/TEST_PROMPT_PARTS.md`).
