# Screen Score #1: a blind review of every screen (8 Oct 2026, US Central)

**For:** Codex (ChatGPT) and Claude, each working blind. Pete judges.
**Snapshot:** `d5ce8a9`. Renders made with `tools/shot_screenscore.sh` (Godot
4.6.2 headless under xvfb, English).

## Step 1: agree the rubric: DONE (locked 8 Oct, 12:35 CT)

Pete wants the rubric agreed **before** either of us looks at the renders as a
reviewer. Codex: read `RUBRIC.md` and reply through Pete with "agree" or your
changes. Pete settles it. Then step 2.

## Step 2: the review

Score every screen in `renders/MANIFEST.tsv` against the agreed `RUBRIC.md`, and
offer design, format and any other suggestions.

- **Inputs:**
  - `renders/`: 132 PNGs. `MANIFEST.tsv` gives each one's viewport, canvas,
    device, screen and state.
  - The code, if you want to trace a finding to its source (`scripts/game/ui.gd`
    is the UI kit; screens are in `scenes/` and `scripts/game/season_tab_*.gd`).
- **Deliverable:** `docs/screenscore-1/codex-score.md`, in the format at the end of
  `RUBRIC.md`.
- **Allowed changes:** none to game code. Add files in this folder only.
- **Keep it blind:** don't read `Claude outputs/`, or anything in `docs/` written
  about screens before today. `docs/REGISTER.md` holds old layout decisions, so use
  it to *check* a finding, not to *find* one. Claude's sealed score's SHA-256 goes
  at the bottom of this file once the rubric is agreed and Claude has scored.

## Viewports

| folder | canvas | stands for | what's in it |
|---|---|---|---|
| `v16x9` | 960×540 | PC 1080p, 16:9 phones and tablets | menus, fight, overlays (55) |
| `v19x9n` | 1170×540 | iPhone 11-class, notch faked at 63/63 | menus only (22). The fight tools have no inset hook. |
| `v19x9` | 1170×540 | wide phone, no notch (S24 Ultra class) | fight and overlays (33) |
| `v16x10` | 960×600 | Steam Deck (1280×800) | menus only (22) |

The game's logical canvas is 960×540 with `stretch/aspect = expand`, so a wider or
taller screen gets more canvas, not a bigger picture. Art is authored on a 480×270
grid and drawn ×2.

## What isn't covered (so you don't score an absence as a defect)

- **Languages:** English only. The game ships nine languages (en es fr de it pt_BR pl
  uk ja). `test_layout` and `test_ink` already sweep all nine for clipping, so flag
  anything that *looks* tight in English and will be worse in German or Polish.
- **Scrolling states:** only the two-pane playbook (`26b`, `38`, `38b`) shows a
  scrolled or long list. Other lists are shown at the top.
- **Motion, sound and touch feel** can't be shown in a still.
- **Controller focus rings** (Steam Deck) aren't rendered.
- **`v19x9n` and `v16x10` have no fight renders.**
- **Some states come from dev tools with test money**, for example `34`'s 9048 CC.
  The number isn't a defect; the layout is fair game.

## Constraints the game won't move (Pete's rulings)

- **8-bit is a hard constraint:** NES-sized figures, SNES-sized palette, binary
  alpha, flat fills.
- **The list (the fighting area) is locked at 1.70:1.**
- Every visible string goes through translation, so expect 30–40% longer strings in
  de and pl.
- Buhurt has no thrusts, illegal targets exist, and a downed man is out. If a
  suggestion touches the sport, check it.

---

Claude's sealed score (written 8 Oct, about 12:40 CT, against the LOCKED rubric; an earlier note here said 12:55, read off nothing — corrected), SHA-256:
`e5609a609aab2a9038c92706d8676f7d8b2e4c18fc42f09f681d5979ea5f3ffc`

**Step 2 is open:** Codex, score all 132 renders into `codex-score.md`.
