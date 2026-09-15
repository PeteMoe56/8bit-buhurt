# Retro Buhurt — original score, v3 "three signatures"
Archived 11 Sep 2026 (US Central). **This is the shipping set** as of this date.

Everything here was synthesised from scratch by `tools/buhurt_music.py` —
2A03-style pulse/triangle/noise, no samples, no soundfont, no third-party
material. **Pete owns it outright.** There is nothing to license and nobody to
attribute.

## What's in it
| | |
|---|---|
| `ogg/` | the eight music loops + as shipped in `audio/music/` |
| `mp3/` | the same eight, for listening outside the engine |
| `sfx/` | the eight one-shots as shipped in `audio/sfx/` |
| `tools/` | the generator, the one-shot generator, and the mastering script |

## The set
| track | tempo | mode | loudness | its own signature |
|---|---|---|---|---|
| `club` | 118 | D Dorian | −18.0 | thin: 25% duty, sparsest kit — built to be ignored |
| `menu` | 124 | D Dorian | −17.5 | plain staccato lead, octave-doubled, walking bass, call-and-response, march kit |
| `fight` | 152 | D Dorian | −17.1 | lead sits *behind* the groove (lead/harmony 1.07) |
| `hosted` | 132 swung | D Dorian | −16.5 | **the only track that swings**; handclaps; harmony a third above |
| `cup` | 146 | D Dorian | −16.0 | war drums; lead in front (lead/harmony 3.01) |
| `worlds` | 138 | D Dorian | −14.5 | **the drone** — a sustained open fifth, D and A, never moving |
| `final` | 172 | D **Phrygian** | −13.1 | a different song: riff, not melody |
| `champion` | 152 | D **major** | −13.7 | the melody lifted into the bright mode; one-shot |

## To rebuild
```
python3 tools/buhurt_music.py /tmp/music   # renders + runs every check
cd /tmp/music && bash master.sh            # two-pass loudnorm -> ogg + mp3
```
The build **gates itself**: register ceiling, no drums-only bars, no harsh
section, clean voices, no arpeggios, and — new in v3 — no two tracks scoring
above 0.88 similarity, with a manufactured twin as a positive control.

## History
- v1 — tailed off into drums-only for 75% of every loop
- v2 — arpeggio phase reset, the "gun ray" warble; menu too slow; final was cup sped up
- **v3** — register ceiling (§34), and three tracks that were one arrangement at three tempos pulled apart (§35)

See `docs/REGISTER.md` §29–35 for the full account.
