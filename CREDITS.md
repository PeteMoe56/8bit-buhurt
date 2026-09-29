# 8-Bit Buhurt: Combat Club — credits

> **The credits screen exists.** It is on the Settings screen and it generates
> itself from `Audio.LICENSED` — see `scripts/game/settings.gd`, which walks that
> map rather than holding a copy of any of this, so attribution cannot go stale
> when a track changes. `test_audio.gd` checks the map and the files agree.
>
> This file used to open *"SHIP BLOCKER. There is no credits screen in the game
> yet"*, which stopped being true some time before 15 Sep 2026 and stayed on the
> page — a solved problem still advertised as a blocker, which costs exactly as
> much attention as a real one.
>
> The HeatleyBros licence makes attribution a **condition**, not a courtesy —
> failure to attribute is "a material breach of this License". What remains
> outstanding is not the screen: it is that this track is on a licence that can
> be revoked, and the mitigation is built but empty. `menu_own` is a drop-in slot
> waiting for a track we own. Until it has one, a revocation is a rebuild.

## Music

**Title screen** — "Game On" by HeatleyBros, from *HeatleyBros IV*.
Used under the [HeatleyBros Attribution License](https://heatleybros.com/index.php/heatleybros-attribution-license/).

Required credit, to appear in an in-game credit, menu, or end-credit reel:

```
Music: HeatleyBros — "Game On"
https://heatleybros.com
```

Their terms prefer a song-specific or channel link over a bare name.

**Everything else** — written for this game and rendered by
`tools/music/buhurt_music.py`. Original 2A03-style synthesis, no samples, no
third-party material. Nothing to attribute.

| slot | file | source |
|---|---|---|
| menu | `menu.ogg` | **HeatleyBros — Game On** (licensed) |
| menu (fallback) | `menu_own.ogg` | ours |
| club, fight, hosted, cup, worlds, final, champion | | ours |
| all 12 one-shots (tap, wipe and type rendered 29 Sep 2026) | | ours, `tools/music/buhurt_sfx.py` |

## Two standing constraints from the HeatleyBros licence

1. **It is revocable.** Verbatim: *"The Owner may terminate this License at any
   time, with or without cause,"* and *"Upon termination, all rights granted
   under this License immediately cease."* There is no clause covering a game
   already released. The mitigation is built in — delete `audio/music/menu.ogg`
   and `Audio.resolve()` walks to `menu_own`, which is ours. One file, no code
   change. `test_audio.gd` asserts the chain holds.
2. **No AI or ML use, at all.** Verbatim: the music *"may not be used to train,
   fine-tune, validate, test, or improve any artificial intelligence, machine
   learning, neural network, algorithmic, or generative system."* Shipping it in
   the game is fine. Using it as reference material to shape
   `buhurt_music.py` is not — keep that separation.

## What was done to the file

Source: `HeatleyBros - HeatleyBros IV - 19 Game On.mp3`, 210.0 s, −8.9 LUFS.

The album track is not a loop — it ends quieter than it starts and its wrap
discontinuity measures 0.215 of peak, which is an audible click. Shipped as a
**29.72 s loop cut from 139.32 s**, the strongest-opening 16-bar section with
the cleanest join (tempo 129.2 BPM, bar 1.858 s), then mastered flat to
**−17.55 LUFS** — the same slot the synthesised menu occupied, so the loudness
ladder is unchanged. No baked fade: `Audio._begin()` already tweens the
entrance, and a fade in the file would dip every time the loop came round.

Wrap discontinuity after the cut: **0.011 of peak** — in line with our own
tracks (0.006–0.009).
