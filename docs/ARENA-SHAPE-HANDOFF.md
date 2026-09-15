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

## Two more, added 15 Sep — and TAKEN, later the same day

These were left for you as questions 5 and 6. Pete asked for both directly on 15 Sep, so
they were built rather than left. **Both touched `melee_scene.gd`.** What follows is what
changed and where, so you can see it coming in a diff rather than find it.

Nothing else in that file was touched. The fight's own drawing, the pixel scale, the
camera, `SCREEN` and its twenty-eight references: all still yours and all untouched.

**5. `MeleeSim.cancel_order(idx)` now has a caller — a tap.**

In `melee_scene._release()`, in the branch that already handles a tap rather than a drag.
That branch had exactly one meaning before ("this man is clinched, give me his options")
and now has two, decided by his state:

```
if   man.state == GRAPPLED              -> sim.request_prompt(idx)
elif man.under_orders() and not from_play -> sim.cancel_order(idx)
```

The tap was the right gesture because it is the one that already means *this man, and I am
not drawing*. **Only a route the player drew can be taken back** — a called play's routes
arrive with `from_play` set and are the plan the whole line is running; one man tapped out
of that is a different call, and the screen for a different call is the corner.

No message is drawn and none is needed: the route line goes, the card border drops from
ROUTE back to EDGE, and the card stops saying "on a route". Three things change in the
frame the tap lands on.

Checked in `test_melee.gd` — `_test_a_route_can_be_taken_back`, five checks: the verb
works, a second cancel on a man with no order is quiet, and two source checks that a
screen calls it at all and still asks about `from_play`.

**6. Favourites can be reordered — and the control is NOT in the corner.**

This is a decision against the note that used to be here, which suggested up/down taps
beside each card on the corner. Two reasons:

- **The corner has a clock.** `corner_t` is running. A control that costs seconds of the
  round to tidy a list is a control that punishes being used.
- **A two-by-two grid has no up and down.** It has four positions. Arrows on it would be
  arrows against a direction that is not on the screen.

So the control is a strip under the playbook, in starring mode — `_build_fav_strip()` in
`melee_scene.gd`. No clock, the mode is already called "picking favourites", and the strip
reads left to right in exactly the order the corner grid fills (slot 1 top-left, 2
top-right, 3 bottom-left, 4 bottom-right). One tap moves a chip one place towards the
front; the front chip is dead rather than absent. A strip of fewer than two is not drawn.

**One thing this cost you:** the strip is paid for out of the book's height, not added to
the panel. `panel_box` grows downward from a fixed y and `_draw` frames whatever height it
ends up with, so the first cut pushed "Done picking favourites" half off a 540-pixel
frame. `const FAV_STRIP_H := 68.0` is subtracted from `BOOK_H` while `starring` — so **in
starring mode the playbook page is 68 pixels shorter**. It scrolls, so nothing is lost. If
your pixel-scale pass changes `BOOK_H` or the panel's origin, that subtraction is the line
to look at.

Shots: `shots/favs_before.png`, `shots/favs_after.png`, `shots/favs_corner.png` — the strip
before a move, after it, and the corner grid in the new order.

## One thing found and NOT fixed, 15 Sep

On the pre-fight screen the crowd line ("Louisville's crowd.") draws **over** the playbook
panel — see `shots/favs_after.png`, centre. So does a fragment of the distance line at the
right edge. It is a draw-order question in `_draw()`: `UiKit.panel()` goes down before
those strings do. It was there before either of the changes above and it is in the part of
the file that is yours, so it was left alone rather than fixed in passing.

## Reference shots in the repo

`shots/aspect_1170x540.png`, `shots/aspect_1260x540.png`, `shots/aspect_720x540.png`
— the season screen at phone, ultrawide and tablet shapes after the fix.
