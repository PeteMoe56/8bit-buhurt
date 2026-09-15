# Fighter sprites — one 72 × 72 cell for everything

World art: authored on the 480 × 270 grid, the renderer doubles it.
Two weapon classes, one facing, mirrored. Frames left to right, no padding.

**`ss` = falchion or axe + heater shield · `pa` = polearm.**

## The rules of the canvas

- **Origin is dead centre at the bottom** of the cell — that is what makes
  mirroring a straight flip.
- **Nothing but the feet may touch the cell edge.** If a pose does not fit, the
  pose is wrong, not the canvas.
- The body is 24 × 36 of the 72. The weapon uses the rest.
- ~18.9 authored px per metre: a 120 cm polearm is 23 px, a 90 cm falchion 17,
  a 60 cm heater shield 11 across. The binding pose is a level polearm swing —
  the head reaches ~32 px from the body centre, so a centred origin needs twice
  that. 64 leaves 1 px of margin; 72 leaves 5.

## The rules of the sport — read before drawing a pose

- **NO THRUSTS.** "No stabs. Not with a sword, not with an axe, not with a
  polearm." Every strike here is a swing. This is the rule that sized the canvas.
- **Illegal target zones:** neck, groin, back of the knee, spine, back of the
  head, feet. Do not show a swing or throw landing on one.
- **A downed man is out** — third point of contact and he does not get up. There
  is no get-up sheet on purpose.
- No dual-wielding, no war hammers, no flails. **Shield punches are legal** and
  are the natural second frame of `ss_swing`.

## The palette

Twelve colours a frame, ceiling fourteen: the nine keys, plus black, near-black
and one white spec. **1 px near-black outline** around the whole silhouette.
Every pixel fully opaque or fully transparent — no anti-aliasing, ever.
Haft and grip use the **leather** keys; blade and head use **steel**.

| file | draw at | frames | what |
|---|---|---|---|
| ss_idle.png / pa_idle.png | 216 × 72 | 3 | guard, weapon up |
| ss_walk.png / pa_walk.png | 288 × 72 | 4 | moving to a spot |
| ss_charge.png / pa_charge.png | 432 × 72 | 6 | bullrush |
| ss_swing.png / pa_swing.png | 288 × 72 | 4 | a blow thrown |
| ss_clinch.png / pa_clinch.png | 144 × 72 | 2 | bound up |
| ss_takedown.png / pa_takedown.png | 216 × 72 | 3 | a throw going in |
| ss_recover.png / pa_recover.png | 144 × 72 | 2 | giving ground, breathing |
| ss_down.png / pa_down.png | 144 × 72 | 2 | on the ground, staying there |

52 frames, 26 a class. The sim has no weapon rules — the classes are a look.

See `docs/ART.md` and `docs/RetroBuhurt-Art-Specification.pdf` §8.
