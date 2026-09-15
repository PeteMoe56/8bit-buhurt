# Arena hand-off — the shape of the screen

Written 15 Sep 2026 by the balance/UI chat, for whoever is settling the fight
screen's pixel scale. Nothing in `scripts/melee/melee_scene.gd` was touched.

## What changed everywhere else

`project.godot` is 960x540 with `stretch/aspect = "expand"`, which does **not**
letterbox — it hands the game a bigger canvas. Measured, not assumed
(`tools/probe_viewport.gd`):

| device shape | canvas the game gets |
|---|---|
| 16:9 | 960 x 540 |
| 19.5:9 (iPhone) | 1170 x 540 |
| 20:9 (most Android) | 1200 x 540 |
| 21:9 | 1260 x 540 |
| 4:3 (tablet) | 960 x 720 |

The design is never squeezed — it always gets at least 960x540 and gains the
rest in one axis.

Every management screen now reads that live canvas:

- `UiKit.SCREEN` (the old `const Vector2(960, 540)`) is **gone**. Use
  `UiKit.screen()`, `UiKit.right_edge(margin)`, `UiKit.span(margin)`,
  `UiKit.bottom(margin)`. `UiKit.DESIGN` is still there as the 960x540 baseline.
- `display/window/handheld/orientation` was **1 — portrait** — under a landscape
  game. It is now 4, `SENSOR_LANDSCAPE`. Verified against the engine's own enum.
- `tests/test_ink.gd` measures the live frame and the runner runs it at four
  shapes. New `tests/test_shapes.gd` renders 16 screens and samples pixels down
  the far right, failing on any that is still the clear colour.

## Four decisions that are yours

**1. `melee_scene.gd` keeps its own `const SCREEN := Vector2(960.0, 540.0)`** —
28 references. It is self-contained and nothing above reached into it. The
corner, the fight HUD, the report and the splash are all laid out against it
(`SKIP_AT` included), so every fight screen currently stops at x=960 on a
handset — the same bare strip the management screens had. The `UiKit` helpers
above are there when you want them.

**2. The full-screen art slot.** `list_ground` is drawn at melee_scene.gd:1036
into `Rect2(Vector2.ZERO, SCREEN)`. `ArtBank.fit()` scales-to-fit and **centres**,
so a 960x540 backdrop on a 1170 canvas sits centred with ~105px bare each side.
Wider source art, tiling, or a crop — an art call. `art_bank.gd` declares three
960x540 slots: `venue_away`, `venue_neutral`, `list_ground`.

**3. What the camera shows on a wider screen.** Retro Bowl's shipped answer,
measured off its App Store assets: more world horizontally on a wide screen
(~35 yards across at 19.5:9 with the sidelines cropped, ~30 yards at 4:3 with
the whole field visible), and the HUD pinned to the real screen edges in both.
Ours is the same question and the melee sim owns it.

**4. `display/window/stretch/scale_mode` is `fractional`** — the pixel scale
lever, and a real tension:

- `fractional` (current): no bars, but a non-integer device scale on almost
  every phone — 2532/1170 = 2.164 — so one art pixel does not land on a whole
  number of device pixels. The project runs nearest-neighbour filtering with
  `snap_2d_transforms_to_pixel` and `snap_2d_vertices_to_pixel` on, which is
  what keeps it crisp.
- `integer`: a perfect pixel grid, and the bars come back.

Retro Bowl took the no-bars route. **Changing this changes every screen in the
game, not just the fight** — so if you want `integer`, say so and the management
screens get re-checked against it.

## Reference shots in the repo

`shots/aspect_1170x540.png`, `shots/aspect_1260x540.png`, `shots/aspect_720x540.png`
— the season screen at phone, ultrawide and tablet shapes after the fix.
