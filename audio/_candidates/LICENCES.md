# Free-licence music candidates — auditioned 11 Sep 2026

**None of this is in the game.** These are comparison candidates, kept so the
audition can be repeated. The shipping score is the synthesised set in
`audio/music/` — see `_archive/2026-09-11-v3-three-signatures/`.

Every licence below was read off the asset page itself on 11 Sep 2026, not from
a directory listing or a blog post. **If you ship any of these, archive a dated
copy of its licence page next to it first** — CC0 is irrevocable but
unverifiable, and one of these packs has already had a fraudulent copyright
claim filed against it (OpenGameArt investigated and dismissed it).

## What's here

| file | track | composer | licence | source |
|---|---|---|---|---|
| `auditioned/free_menu.mp3` | Title Screen | Juhani Junkala | **CC0** | https://opengameart.org/content/5-chiptunes-action |
| `auditioned/free_club.mp3` | The Old Tower Inn | RandomMind | **CC0** | https://opengameart.org/content/chiptune-medieval-the-old-tower-inn |
| `auditioned/free_fight.mp3` | Level 1 | Juhani Junkala | **CC0** | https://opengameart.org/content/5-chiptunes-action |
| `auditioned/free_hosted.mp3` | Chibi Ninja | Eric Skiff | **CC-BY 4.0** | https://ericskiff.com/music/ |
| `auditioned/free_cup.mp3` | Mars | SketchyLogic | **CC0** | https://opengameart.org/content/nes-shooter-music-5-tracks-3-jingles |
| `auditioned/free_worlds.mp3` | The Bard's Tale | RandomMind | **CC0** | https://opengameart.org/content/chiptune-medieval-the-bards-tale |
| `auditioned/free_final.mp3` | Boss | SketchyLogic | **CC0** | https://opengameart.org/content/nes-shooter-music-5-tracks-3-jingles |
| `auditioned/free_champion.mp3` | Win Jingle | SketchyLogic | **CC0** | https://opengameart.org/content/nes-shooter-music-5-tracks-3-jingles |

These are 96k mono re-encodes for auditioning. **Re-download the originals
before shipping anything** — the sources ship WAV, and RandomMind ships a
dedicated `CHIPTUNE_Loop_*.wav` build per track.

### The one attribution string that would be required

Eric Skiff is the only CC-BY item above. If `Chibi Ninja` ever ships, the
credits must carry, verbatim:

```
Music: Eric Skiff - Chibi Ninja - Resistor Anthems - Available at http://EricSkiff.com/music
```

## `sources/` — the thing actually worth having

`SketchyLogic_NES_Shooter_FamiTracker_CC0.zip` is the **FamiTracker project
files** for the NES Shooter pack — the scores, channel by channel, editable.
CC0, 52 KB, nothing to attribute.

This is a different class of asset from a finished mp3: it is how somebody else
voiced an NES boss track, readable. The technique is portable into
`tools/music/buhurt_music.py` without any of the audio going near the game.
Nothing else in the free pool ships its sources.

## Rejected, and why

- **HeatleyBros** — free with credit, and they are *Retro Bowl's actual
  composer*. Using the same library in a game already in that mould is
  derivative in the one dimension we have worked hardest to make original.
  Their terms also forbid using the music to train any AI system.
- **Abstraction (abstractionmusic.com)** — widely listed as free; the real terms
  ask for "at least $2 of your monthly income" via Patreon for any project that
  earns. That is a revenue share.
- **Kevin MacLeod / incompetech** — **CC-BY, not CC0**, despite what half the
  internet says. Usable, just not free of obligation. Orchestral, not 8-bit.
- **Blacis "Fantasy Music Mega Pack", Duckhive "CC0 Game Music Vol. 1"** —
  AI-generated. Duckhive's own creator calls the licensing "a grey area" with a
  "microscopic chance" of similarity to existing work. You cannot dedicate to the
  public domain what you may not own.
- **Pixabay** — permits paid-game use but bars redistributing a track "on a
  standalone basis", which an OST release would breach.
- **Free Music Archive** — no site-wide grant; per-track, and much of it is
  BY-NC, which is unusable here.

## The finding

Eight best-in-class free tracks, hand-picked to our eight moods, come from
**five composers and land on seven different tonal centres**. Ours are on one
root by design. Measured the same way:

| | ours | free slate |
|---|---|---|
| distinct tonal centres | **2 of 8** | 7 of 8 |
| loudness spread | **4.9 LU**, climbs with the occasion | 14.1 LU, *inverted* — the bout is loudest, the championship quietest |
| brightness spread | **413 Hz** | 1420 Hz |
| lengths | 28.9–65.1 s, all loop | 4.4–123.4 s |

Re-mastering fixes the loudness. Nothing fixes seven tonal centres, because it
is not a mastering problem — it is the difference between a soundtrack and a
playlist.
