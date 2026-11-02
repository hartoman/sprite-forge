# Sprite test prompt: puppet parts (option C-lite)

This tests whether the image AI can deliver what puppet sprites need: **one static image** of a character, plus the same character split into separate parts, each part complete. There are no animation frames. The game animates the parts itself, using shared motions per body type.

**The rule for this test:** one attempt, in a **fresh conversation**, nothing else in it. If the first result fails the checklist at the bottom, we reconsider the whole approach rather than re-rolling.

**How to use:** copy the block below into a new chat. Attach `src/assets/sprites/lizardman.png` as a style reference if the AI accepts images. Save the result as `lizardfolk-line-parts.jpg` in `_incoming/`.

```text
Create ONE pixel-art image for a fantasy strategy game: a "paper doll" parts sheet of one character, so that a game engine can animate the parts separately.

CHARACTER: a lizardfolk warrior. Green scales (main #4F9A3A, shadow #2F6B2A, highlight #8CCB5E), a cream belly (#D8D27A), a red-orange crest along the head (#E0622A), small yellow eyes, a long tail, a red loincloth (#A8322D). He holds a long wooden spear with a grey iron tip in his front hand. A 1-pixel dark outline (#1B1F1A) around every shape. Light from the top left. Side view, facing RIGHT, standing upright.

THE IMAGE:
- A wide image, about 2048 x 1024 pixels.
- The background is ONE flat solid colour: pure magenta, #FF00FF, everywhere. No grid lines, no borders, no labels, no text, no numbers, no shadows, no ground line.
- Never use magenta, pink or purple in the character.
- Pixel art with chunky, clearly visible square pixels (each art pixel about 8 x 8 image pixels), so the whole character is about 40 art pixels tall.

LEFT HALF of the image: the COMPLETE character, assembled, standing in a relaxed ready pose, facing right, with the spear held upright in front of him.

RIGHT HALF of the image: the SAME character taken apart into exactly 7 separate pieces, at EXACTLY the same size and pixel scale as on the left and in the same orientation (do not rotate anything). Leave a wide gap of plain magenta around every piece so that no two pieces touch. Lay them out in this order, left to right, top to bottom:
1. TAIL: from the hip to the tip.
2. BACK LEG: the leg further from the viewer (a slightly darker shade), from the hip down to the foot.
3. BACK ARM: the arm further from the viewer, from the shoulder to the hand, empty-handed.
4. TORSO: the body from the hips up to the neck, including the loincloth, WITHOUT head, arms, legs or tail. Draw the torso COMPLETE where the arms and legs would normally cover it.
5. HEAD: the head with the crest and the neck.
6. FRONT LEG: the leg nearer the viewer, from the hip down to the foot.
7. FRONT ARM WITH SPEAR: the arm nearer the viewer, from the shoulder to the hand, holding the whole spear upright.

PIECES MUST BE COMPLETE: every piece is drawn whole, including the parts normally hidden behind other pieces. Where a piece joins the body (hip, shoulder, neck, tail root), give it a rounded end that extends a little further than needed, so that no gap appears when the piece turns slightly. Each piece has its own full outline.

Before answering, check: magenta everywhere except the character and the pieces; no text or lines; the assembled character on the left; exactly 7 separate, non-touching pieces on the right in the listed order; the pieces at the same scale as the assembled character and not rotated; the torso complete without the limbs.
```

## Pass or fail (first try only)

| Check | Pass |
|---|---|
| Background | Flat magenta, nothing else: no grid, text or numbers |
| Assembled character | One complete warrior on the left, facing right |
| Pieces | **Exactly 7**, separate and not touching, in the listed order |
| Scale | The pieces are the same size as the assembled character (a piece laid over the assembled figure would fit) |
| Completeness | The torso is whole without the limbs; the limbs have rounded joint ends |
| Consistency | The same colours, outline and pixel size in the assembled character and the pieces |

If the scale, the 7 pieces or the complete torso fail, this route doesn't work with this AI either.

---

# Blueprint: lizardman warrior (biped rig)

This is what the game does with the parts once they pass. It's here so the test can be judged against what will actually be needed. Units are in **game pixels**: the character is about 32 px tall, with the feet anchor at (0, 0); x grows to the right (facing) and y grows downwards, so negative y is up.

## Parts, drawing order and pivots

Parts are drawn back to front. The pivot is the joint each part turns around; the attach point is where that pivot sits on its parent.

| # | Part | Parent | Pivot (on the part) | Attach point on the parent | Notes |
|---|---|---|---|---|---|
| 1 | Tail | Torso | Tail root | Torso back-bottom, about (-4, -12) | Sways; drags on the ground in walk |
| 2 | Back leg | Torso | Hip | Torso bottom, about (-1, -12) | Drawn slightly darker |
| 3 | Back arm | Torso | Shoulder | Torso top-back, about (-2, -22) | Counter-swings in walk |
| 4 | Torso | *(root)* | Hips | The rig root, about (0, -12) above the feet | Bobs up and down; leans |
| 5 | Head | Torso | Neck | Torso top, about (1, -25) | Nods, tilts; looks down in death |
| 6 | Front leg | Torso | Hip | Torso bottom, about (1, -12) | |
| 7 | Front arm + spear | Torso | Shoulder | Torso top-front, about (2, -22) | Carries the weapon; the attack motion |

Exact pivots are set by hand once per unit in the pivot editor. The AI only has to draw.

## Motions

Angles are in degrees (positive turns clockwise, so a limb on the right side swings forward and down); offsets are in game pixels; times are as a fraction of the motion.

**Idle** (loop, 1.6 s)
- Torso: y 0 → -1 → 0
- Head: tilt 0 → -3° → 0
- Front arm: 0 → +3° → 0 (the spear sways)
- Tail: -4° → +4° → -4°

**Walk** (loop, 0.6 s per stride)
- Front leg: +22° → -22° → +22°
- Back leg: the opposite (-22° → +22°)
- Torso: y bobs -1 at mid-stride and lean +3°
- Back arm counter-swings ±12°
- Front arm ±6° (the spear stays mostly upright)
- Tail: ±8°, half a beat behind

**Attack, spear thrust** (once, 0.6 s; **the blow lands at 0.45**)
- 0 → 0.3, wind-up:
  - torso lean -6° and x -2
  - front arm -35° (spear drawn back)
  - head -4°
- 0.3 → 0.45, thrust:
  - torso lean +8° and x +4
  - front arm +20° (spear level, forward)
  - front leg +15° (lunge step)
- 0.45 → 1, recover to the idle pose.

**Hit** (once, 0.35 s)
- Torso lean -10° and x -3
- Head -8°
- Red flash
- Return to idle

**Death** (once, 0.9 s, then hold and fade)
- The whole rig tips over backwards around the feet, to -85°.
- The legs fold: the front leg -30°, the back leg +20°.
- The head drops (+15°).
- The tail lies flat.
- The figure sinks 2 px, then fades out.

## What other rigs reuse

- Every **biped** (about 35 units) uses this same part list and these motions. Only the art and the attack style differ:
  - a thrust for spears;
  - a swing (front arm -60° → +50°) for axes, clubs and swords;
  - a draw-and-release (back arm pulls, nothing swings) for bows and crossbows;
  - an overhead throw for javelins and slings.
- **Rider, quadruped, flier** and **machine** rigs follow the same pattern, each with its own part list.
