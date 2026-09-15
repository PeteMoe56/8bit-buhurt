# Fighter sprites — one 72 × 72 cell for everything

World art: authored on the 480 × 270 grid, the renderer doubles it.
Two weapon classes, one facing, mirrored. Frames left to right, no padding.

- **Origin is bottom-centre of the cell.** Every pose stands on the same ground
  line however far the weapon reaches.
- **Nothing but the feet may touch the cell edge.** If a pose does not fit, the
  pose is wrong, not the canvas.
- Body is 24 × 36 of the 72. The weapon uses the rest.
  ~19 authored px per metre: a 2 m polearm reaches 38 px from the grip.
- Twelve colours a frame, ceiling fourteen. Nine keys + black, near-black and
  one white spec. **1 px near-black outline** around the whole silhouette.
- Every pixel fully opaque or fully transparent. No anti-aliasing, ever.
- Haft and grip use the **leather** keys; blade and head use **steel**.

| file | draw at | frames |
|---|---|---|
| ss_idle.png | 216 × 72 | 3 |
| ss_walk.png | 288 × 72 | 4 |
| ss_charge.png | 432 × 72 | 6 |
| ss_strike.png | 216 × 72 | 3 |
| ss_clinch.png | 144 × 72 | 2 |
| ss_takedown.png | 216 × 72 | 3 |
| ss_down.png | 144 × 72 | 2 |
| ss_getup.png | 144 × 72 | 2 |
| pa_*.png | same eight, polearm | |

`ss` = sword + heater shield · `pa` = polearm.
The sim has no weapon rules — the two classes are a look, not a mechanic.

See `docs/ART.md` and `docs/RetroBowl-Art-Spec.pdf` §8.
