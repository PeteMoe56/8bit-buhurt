# Audio

**Sixteen of sixteen recorded. Nothing borrows.** All five music tracks and all eight
one-shots are in and playing; the rest fall back to a neighbour (see below) so no screen is silent. The rig is in
`scripts/game/audio.gd` and is **silent and harmless until they exist** — every
entry point checks `ResourceLoader.exists` and returns quietly, so the game can
call `Audio.for_mood()` on every frame of every screen a year before anybody
writes a note. `tests/test_audio.gd` proves that and prints a stocktake.

Ported from ACRTW's `autoload/audio_director.gd`. What came across and what had
to change is documented at the top of `audio.gd`.

## music/ — one per occasion

**The same melody, differently arranged.** That is the whole plan, and it is what
makes the boss-battle idea work: you recognise the tune and the room has changed
around it. `UiKit.Mood` picks the palette and `Audio.for_mood()` picks the
arrangement, off one read, so they cannot disagree.

| file | what it is |
|---|---|
| `menu.ogg` | **in** — 124 BPM, the catchiest version. The game's calling card. |
| `club.ogg` | The clubhouse on an ordinary week. **The base melody, acoustic.** |
| `fight.ogg` | **in** — a groove with the tune *behind* it. Plays under gameplay. |
| `cup.ogg` | **in** — cup night. Same melody, faster, war drums arrive. |
| `hosted.ogg` | **in** — brightest in the set. A party, not a fight. |
| `worlds.ogg` | **in** — grand rather than fast. See the drone, below. |
| `final.ogg` | **in** — and it is NOT the melody. See below. |
| `champion.ogg` | **in** — the melody lifted out of Dorian into major. One-shot. |

## The final is its own song, on purpose

The set's conceit is one melody arranged several ways, and for the clubhouse,
cup night and the champion cue that is exactly right — it is the club's theme,
and hearing it change is the point.

It was wrong for the boss. Pete, on the first version: *"literally just Cup
Night sped up"* — which it was: same phrases, same form, 24 BPM faster. **A boss
should not sound like your own theme.** So the final is written in **D Phrygian**
against the set's D Dorian: same root, but a flat second instead of a raised
sixth, which is the most menacing interval in common use. And it is a **riff**
rather than a melody — an eight-beat ostinato that hammers and never resolves.

The two themes share four pitch classes. The boss has two the rest of the set
never uses: the flat second and the flat seventh.

## The loudness ladder

The occasion ladder, in one direction, as a number:

| | |
|---|---|
| club | −17.9 LUFS |
| menu | −17.4 |
| fight | −17.0 |
| hosted | −16.4 |
| cup | −16.0 |
| worlds | −14.5 |
| final | −13.1 |

4.9 LU across the ladder. `champion` sits at −13.5 and is a
one-shot, so it is outside the ladder.

`Audio.FALLBACK` still exists and `resolve()` still walks it — nothing needs it
today, and it is what keeps a future added mood from being silent.

## Worlds is grand, not fast

The escalation is **not** one axis. Cup night is 146 and driving; the final is 172
and vicious; **Worlds is 138** — the slowest of the three big tracks and the
widest. Escalating by tempo alone would have made it a halfway house between the
other two.

**The drone belongs to Worlds and to nothing else.** For one version the menu
borrowed it, and the title screen ended up wearing the fingerprint of the biggest
tournament in the game. A signature in two places is worth less than half of a
signature in one. The check is a grep, not a listen: which arrangements use this
device, and is the answer one?

What makes it sound far from home is that **drone**: a sustained open fifth running
under the whole piece, D and A, never moving. Every bagpipe, hurdy-gurdy and
organum that predates functional harmony by six hundred years. Nothing else in
the set has one. The harmony still moves above it — a chord that changes over a
bass that will not.

## ui/ and fight/ — one-shots

`tap`, `confirm`, `refuse`, `coin` · `down`, `clash`, `whistle`, `crowd`

## Notes for whoever records these

- **Ogg Vorbis.** The rig handles WAV too, but WAV loops through a different
  property than Ogg does and it is the one gotcha that has already cost an
  afternoon on ACRTW — see `_loop()`.
- **Loop cleanly.** `club`, `cup`, `worlds`, `final` and `fight` all loop for as
  long as the player sits on the screen, which on a clubhouse can be minutes.
- **Levels are set in the catalog, not in the file.** Each entry carries its own
  `db`, so balancing the mix is a diff of one dictionary. Record at a sensible
  level and let `audio.gd` do the trimming.
- `anthropic-skills:event-music` already does PD medieval tunes → MIDI →
  acoustic and metal treatments → mastered OGG, which is exactly this shape.
