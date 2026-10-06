# ART.md — every picture this game will load

**Nothing here is drawn yet, and the game is complete without it.** Every slot
has a primitive fallback already on screen. Drop a file at the path below and it
appears — no code change, no rebuild, no setting.

Pete, 10 Sep 2026: *"Let's not use your art for any of this, just placeholders.
I'll get ChatGPT to do that work."* This document is the brief for that work.

The slot table is mirrored from `ArtBank.SLOTS` in
`scripts/game/art_bank.gd`, and `test_arena.gd` asserts the two agree — so this
file cannot quietly describe a slot the game does not look for, or miss one it
does.

---

## Read this part first

**The locked style.** Constraint 05.1: *8-bit, load-bearing rather than
decorative.* Pixel art, limited palette, readable at a glance on a phone. The
reason it is locked is not nostalgia — heraldry is already low-res, it solves
the gray-blob problem of telling two armored clubs apart, and it keeps the art
scope survivable for one person.

**Four rules that apply to every slot.**

1. **No text of any kind.** No club names, no scoreboards with numbers, no
   sponsor boards with words, no signage. The game draws all text itself, in its
   own font, and a picture with baked-in words will be wrong in every language
   and stale the day a name changes.
2. **No logos, badges, or crests.** The player picks their mark out of the icon
   bank and the game draws it on top. A crest painted into the artwork is
   somebody else's club standing in your ground.
3. **PNG, exact size or the same proportion.** Anything at the listed
   proportion works and looks better on a large screen. Anything else is
   letterboxed with bars — never stretched, because a squashed shield is a
   shield nobody drew.
4. **Nothing important in the bottom-right corner** of an arena slot. The club
   badge is drawn there, at a quality that climbs with the level.

**Two slots must be grayscale. This is the one that is easy to get wrong.**

The fight screen changes color with the occasion — a Worlds final does not look
like a Tuesday. It does that by *multiplying* the fighting surface by a mood
color. Multiply a brown texture by a brown tint and you get mud.

So `list_surface` and `list_ground` must be delivered **grayscale, mid-value,
nothing near pure white or pure black** — texture and detail only, no color of
their own. The game supplies the color. Every other slot is full color.


---

## Fighter portraits — 20 slots, full color, **64 × 64**

**This is the biggest win per image in the whole document.** Four harnesses and
sixteen heads make **sixty-four different men from twenty pictures**, and a save
holds well over a thousand fighters. Nobody is drawing a thousand portraits; a
game that draws the same one on all of them has not added a portrait, it has
added a decoration.

### The two rules that make the compositing work

**1. Both layers are the same 64 × 64 canvas, with a transparent background.**
Not a head drawn at its own size and placed against an anchor — that requires
every generated head to agree with every generated harness about where a neck
is, and an image model will not do that reliably twice in a row. One canvas,
each layer drawn in its own region of it, stacked with a straight overlay and no
arithmetic. If you take one thing from this section, take this.

**2. The harness is drawn with the head area EMPTY, and the head is drawn with
no armor on it.** The harness layer is shoulders, chest and gorget. The head
layer is a head and a neck. They meet at the gorget line. A harness that includes
a helmet will cover every head you own; a head that includes pauldrons will stick
out past every harness.

### The regions, on that shared 64 × 64 canvas

```
        ┌────────────────┐  y=0
        │                │
        │   HEAD LAYER   │   head + neck live here
        │    y 6 → 38    │   roughly 26px wide, centerd
        │                │
        ├────────────────┤  y=38  ← the gorget line, where they meet
        │ HARNESS LAYER  │   shoulders, chest, gorget
        │    y 34 → 64   │   full 64px wide at the shoulders
        └────────────────┘  y=64
```

The two overlap by four pixels at the gorget on purpose — a butt joint shows a
seam at every scale the game draws these at.

### The four harnesses

**They are not random.** The game reads the harness off the fighter's rating
(`ArtBank.harness_for`), so the four are four real grades of kit in the order a
club can afford them. A scruffy man in a kit-bash brigandine *looks* like a
Backyard fighter and a man in Milanese plate looks like he belongs at Worlds —
the player reads a squad's quality off the cards before he reads a number. That
is constraint 05.1 doing its job: load-bearing, not decorative.

| file | grade | rating | what it is |
|---|---|---|---|
| `art/fighter/harness_0.png` | Kit-bash | under 45 | Borrowed and mismatched. Brigandine over a gambeson, an open gorget, one pauldron that does not match the other. Scuffed, honest, clearly somebody else's. |
| `art/fighter/harness_1.png` | Transitional | 45–57 | Coat-of-plates, mail voiders showing at the armpit, small rounded pauldrons. Early, functional, complete. |
| `art/fighter/harness_2.png` | Gothic | 58–71 | Fluted German plate. Sharp ridges catching the light, spiked couters, big asymmetric pauldrons. Aggressive silhouette. |
| `art/fighter/harness_3.png` | Milanese | 72+ | Smooth heavy Italian export plate. Rounded, polished, large besagews at the armpit. Expensive and looks it. |

> **Prompt to paste, per harness.** Replace the description:
>
> *"8-bit pixel art sprite on a 64×64 transparent canvas. The shoulders, chest
> and gorget of a suit of medieval armor — [DESCRIPTION FROM THE TABLE] — viewed
> straight on from the front, as a bust. THE HEAD AND NECK ARE ABSENT: the armor
> occupies only the bottom half of the canvas, from about 34 pixels down to the
> bottom edge, and the space above the gorget is fully transparent. No helmet. No
> face. No head. Limited palette, flat pixel shading, crisp hard pixels, no
> anti-aliasing, no gradients, no outline glow. Transparent background. No text,
> no letters, no numbers, no heraldry, no crest, no badge, no logo."*

### The sixteen heads

Variety here is the whole point — a roster of thirteen should not contain two men
who look alike. Vary **age, build of face, hair, beard and skin tone** across the
set, and keep every one of them plausible as a person who fights in armor on a
weekend. These are club fighters in their twenties to forties, not fantasy
heroes.

| file | the man |
|---|---|
| `art/fighter/head_00.png` | 20s, clean-shaven, short dark hair, pale |
| `art/fighter/head_01.png` | 30s, heavy black beard, shaved head, olive |
| `art/fighter/head_02.png` | 20s, red hair, freckles, thin moustache, pale |
| `art/fighter/head_03.png` | 40s, gray stubble, receding, weathered, tan |
| `art/fighter/head_04.png` | 30s, long brown hair tied back, clean-shaven, brown |
| `art/fighter/head_05.png` | 20s, blond, square jaw, broken nose, pale |
| `art/fighter/head_06.png` | 30s, full ginger beard, broad face, ruddy |
| `art/fighter/head_07.png` | 40s, bald, thick gray moustache, scarred brow, dark |
| `art/fighter/head_08.png` | 20s, black curly hair, no beard, dark brown |
| `art/fighter/head_09.png` | 30s, shaved sides, topknot, goatee, tan |
| `art/fighter/head_10.png` | 20s, mousy brown, gaunt, missing a tooth, pale |
| `art/fighter/head_11.png` | 30s, jet black hair, heavy brows, clean-shaven, olive |
| `art/fighter/head_12.png` | 40s, silver hair, close beard, lined, pale |
| `art/fighter/head_13.png` | 20s, buzz cut, cauliflower ear, thick neck, tan |
| `art/fighter/head_14.png` | 30s, braided beard, long fair hair, ruddy |
| `art/fighter/head_15.png` | 40s, scarred cheek, eyepatch-free, short gray, dark |

> **Prompt to paste, per head.** Replace the description:
>
> *"8-bit pixel art sprite on a 64×64 transparent canvas. The head and neck of a
> man — [DESCRIPTION FROM THE TABLE] — facing straight forward, neutral
> expression, looking at the viewer. THE HEAD OCCUPIES ONLY THE UPPER HALF of the
> canvas, roughly from 6 pixels down to 38 pixels down, centerd, about 26 pixels
> wide, with the neck ending in a flat cut at the bottom. Everything below and
> around it is fully transparent. NO ARMOR, no helmet, no shoulders, no
> clothing, no collar. Limited palette, flat pixel shading, crisp hard pixels, no
> anti-aliasing, no gradients. Transparent background. No text, no letters, no
> numbers."*

### Before you generate: the free packs are worth an hour

There is a large CC0 pixel-art scene and some of it fits this shape directly.
Searched 12 Sep 2026, and worth checking before spending a weekend prompting:

- **OpenGameArt** is the strongest source for *licence clarity*, which is the
  thing that actually matters. [Character portrait
  kit](https://opengameart.org/content/character-portrait-kit), [Helmets
  CC0](https://opengameart.org/content/helmets-cc0), [CC0
  Portraits](https://opengameart.org/content/cc0-portraits) and the [CC0
  resources index](https://opengameart.org/content/cc0-resources) are all
  layer-friendly and unambiguous about reuse.
- **LPC character bases** ([here](https://opengameart.org/content/lpc-character-bases))
  are the best-known layered set in the scene — heads, bodies and gear designed
  from the start to composite. Their licensing is usually CC-BY-SA / GPL rather
  than CC0, which matters: **share-alike on art can reach further than you want
  it to on a paid game.** Read the specific file's licence, not the collection's.
- **itch.io** has the volume: [CC0 assets](https://itch.io/game-assets/assets-cc0/free),
  [64×64 pixel art](https://itch.io/game-assets/free/tag-64x64/tag-pixel-art),
  [portrait-tagged](https://itch.io/game-assets/free/tag-pixel-art/tag-portrait)
  and the [medieval CC0](https://itch.io/game-assets/newest/assets-cc0/free/tag-medieval)
  feed. Licences vary per pack and some "free" packs are non-commercial.

**Three things to check on any pack before it goes in the repo**, because all
three have bitten real projects:

1. **Commercial use, explicitly.** "Free" on itch means free to download. It does
   not mean free to sell a $4.99 game with.
2. **Share-alike.** CC-BY-SA obliges you to license derivatives the same way.
   CC0 and CC-BY do not. For a paid game, prefer CC0, accept CC-BY with credit,
   and think hard before CC-BY-SA.
3. **Attribution, recorded at the time.** If a pack needs credit, it goes in the
   credits screen **the day it lands**, not the week before launch when nobody
   remembers which of forty files came from where.

**The honest expectation:** free packs are very likely to furnish the *heads*,
because a generic 64×64 medieval head is a thing hundreds of people have drawn.
They are much less likely to furnish the four harnesses, because "brigandine vs
transitional vs gothic vs Milanese, as busts, at the same canvas, with the head
cut out" is a specific enough request that it probably does not exist. Plan on
raiding for heads and prompting for harnesses.

### Checking a batch before you commit to it

Drop any two files in and open the roster screen. Both layers land at the same
box automatically, so a head that sits too low or a harness that reaches too high
is visible in one glance at a card. The three things that go wrong, in the order
they usually go wrong:

1. **A head with shoulders on it.** The model adds clothing unasked. Say "no
   shoulders, no clothing, no collar" every time.
2. **A harness that grew a helmet.** Same reflex, other layer.
3. **An opaque background.** Check the corners before you save. A white square
   behind a head is the most common failure of all and does not show up until it
   is drawn over something.

---

## The slots

### Arena grounds — 6 slots, full color, 520 × 300

One image per level of ground. These are the club's home, seen as a picture on
the Arena screen — not played on. Each should read instantly as bigger and
better funded than the one before it: that progression *is* the reward for a
season of gate money.

| file | ground | holds | what it is |
|---|---|---|---|
| `art/arena/arena_0.png` | Back field | 40 | A rope around a patch of grass, a hedge, cars parked on the verge. Somebody's dad with a folding chair. |
| `art/arena/arena_1.png` | Club gym | 120 | Indoors, strip lights, mats stacked against a breeze-block wall. Functional, slightly grim, clearly loved. |
| `art/arena/arena_2.png` | Fenced ground | 400 | Proper barriers, a few rows of temporary seating, a marshal's tent. The first one that looks like an event. |
| `art/arena/arena_3.png` | Sports hall | 1,200 | A real roof, real lighting rigs, retractable seating pulled out on both sides. |
| `art/arena/arena_4.png` | Arena | 4,000 | Tiered stands all the way round, a lighting truss, a big blank screen (**no numbers on it**). |
| `art/arena/arena_5.png` | National Arena | 12,000 | The biggest room in the game. Steep tiers, dark ceiling, the floor lit like a stage. |

> **Prompt to paste, per ground.** Replace the description:
>
> *"8-bit pixel art, landscape 520×300, a [DESCRIPTION FROM THE TABLE ABOVE],
> seen from a raised corner view. Limited palette, warm earthy tones, dark
> muted background. Medieval armored combat venue, empty of fighters. No text,
> no words, no numbers, no logos, no signage, no letters anywhere. Nothing
> important in the bottom-right corner. Flat pixel-art shading, crisp pixels, no
> anti-aliasing, no gradients."*

---

### The two away grounds — 2 slots, full color, 960 × 540

**Full frame, not a picture on a screen.** These are the splash that runs before
every bout you do not host, with the two badges, both club names, both records
and the venue name drawn on top of them — so the art is a backdrop and the
bottom third and the top strip both have text over them.

Two pieces carry every fixture the player does not host, and that is deliberate:
he builds his own ground through six tiers and looks at it all season; he sees
somebody else's for the length of a splash. The other club's colors and badge go
on top, which is what makes an away day at Harrow look different from one at
Yarrow.

| file | venue | what it is |
|---|---|---|
| `art/venue/away.png` | Somebody else's ground | From the tunnel mouth, looking out at a list that is not yours. Their banners on the far rail, the near stands backs-to-camera, colder light than the home grounds. It should read as NOT YOURS in half a second, before anybody reads a word. |
| `art/venue/neutral.png` | Tournament ground | A cup or the Worlds. Bunting, a federation banner, several lists roped off in a row, a marshal's table with paperwork on it. **No club colors anywhere in it** — it is nobody's home, and any badge in the art would contradict the two the game draws on top. |

> **Prompt to paste, per venue.** Replace the description:
>
> *"8-bit pixel art, landscape 960×540, a [DESCRIPTION FROM THE TABLE ABOVE],
> medieval armored combat venue, empty of fighters. Limited palette, dark muted
> tones, the middle of the frame darker and quieter than the edges so text reads
> over it. No text, no words, no numbers, no logos, no heraldry, no signage, no
> letters anywhere. Flat pixel-art shading, crisp pixels, no anti-aliasing, no
> gradients."*

**Keep the middle band quiet.** The club names, the records and the venue line
are drawn across the center of the frame. A busy crowd or a bright banner through
the middle third makes all of it unreadable, and unlike the arena pictures there
is no panel behind this one.

**There is no `venue_home.png`.** The home splash reuses the club's own
`arena_0..5`, scaled to the full frame — a third piece of art for the ground the
player has already bought would be the same room drawn twice.

---

### The fighting surface — 2 slots, **grayscale**

This is the one that matters most. It is under the player's eyes for three
rounds of up to two minutes each, with men walking over it the whole time — so
it has to be **quiet**. Anything with strong pattern or high contrast competes
with the thing the player is actually reading, which is where five men are
standing relative to five other men.

**`art/list/surface.png` — 701 × 369, grayscale.**

The list floor, rail to rail, seen from **directly above**. No perspective, no
horizon, no vanishing point — the game is a top-down plan view and a surface
drawn at an angle will not line up with the men standing on it.

The game draws on top of this: five lane dividers, two set-up lines, and a
6-pixel rail border. Leave room for them to read — a busy floor swallows them.

> *"8-bit pixel art texture, 701×369, seen from directly overhead, a flat
> packed-earth and trodden-grass surface for a medieval combat arena.
> GREYSCALE ONLY — no color, mid-tones, nothing near pure white or pure black.
> Subtle texture, scuffs and wear, low contrast, no strong pattern. Top-down
> orthographic plan view with no perspective and no horizon. No text, no
> numbers, no markings, no lines, no logos."*

**`art/list/ground.png` — 960 × 540, grayscale.**

What surrounds the list — whatever the fight is happening *in*. Seen from the
same overhead angle. The list itself is drawn over the middle of this, so the
center can be anything; the edges are what shows.

> *"8-bit pixel art background texture, 960×540, seen from directly overhead,
> the ground surrounding a medieval combat arena — grass, dirt, timber boarding.
> GREYSCALE ONLY, dark mid-tones, low contrast, quiet. Top-down orthographic,
> no perspective. No text, no numbers, no logos, no figures, no people."*

---

## The fighter on the list — key-coloured sprites, **24 × 32**

The first frame is in: `art/fighter/body_idle.png`, **24 × 32**, facing right,
feet on the bottom row. It is a **mask in key colours**, not a finished figure —
the game swaps each key for the club's kit, so one drawing serves every club.

| key | hex | paints |
|---|---|---|
| surcoat_a | `#FF00FF` | surcoat, the club's main colour |
| surcoat_b | `#800080` | second colour (a split, never shading) |
| trim | `#FFFF00` | edging, belt, straps, helm rim |
| helm | `#FF0000` | helm dome / cover |
| steel | `#8080FF` | plate, face plate, weapon |
| steel_b | `#0000FF` | plate shadow |
| leather | `#00FF00` | gambeson, gloves, boots |
| leather_b | `#008000` | leather shadow |
| mark | `#808080` | the chest badge panel ONLY |

Black is the outline and the eye slit. Type every hex; never eyedrop, and
switch colour management off on export — a key one step off is not swapped.
Every pixel fully opaque or fully clear.

## What is deliberately NOT art

**The fighters.** Men are drawn by the game as silhouettes carrying their
club's kit color and their club's mark. That is not a placeholder waiting for
sprites — it is the answer to the problem the whole art direction exists to
solve. Two armored clubs are two gray blobs; the kit color and the mark are
what make a four-man pile readable on a phone, and they have to be generated per
club because the player invents their club. A fixed sprite cannot carry a color
the player picked.

If fighter sprites ever happen they need to be **colorable** — a silhouette
mask the game tints — not finished colored figures. That is a different and
much larger job, and it is not specified here.

**The heraldry.** `IconBank` draws every mark in code, on purpose: the marks
appear on the table, on the surcoat and on the ground badge, and they were
already drawn by two slightly different functions once, which is how a club
ended up wearing one mark in one place and another elsewhere. One function, and
it stays code.

**Anything with a number on it.** Scores, crowd counts, ratings, timers. All
game-drawn.

---

## Dropping files in

1. Put the PNG at the path in the table.
2. Open the project once so Godot imports it.
3. It appears. Nothing else.

To check what the game can see:

```
godot --headless --path . --script res://tests/test_arena.gd
```

It prints an art stocktake — how many slots are filled, and which are not.
